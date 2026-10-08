import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../kit/bergen_css.dart' show rgba;
import 'feed_icons.dart';
import 'utforsk_copy.dart';

/// One feed post, as the Launch prototype draws it (`{{ poster }}` L5498–5560
/// in `Ærend Kunde Launch.dc.html`, design px): a glass card with the media on
/// top — the shop's logo, name, meta and «Følg» over a scrim, and for a video
/// the play button, the duration pill, the mute disc and the progress line —
/// and under it the like pill, share and the post's kind in mint, the title
/// with its chevron, the text, the «Du bestilte …» hint, a rule, and the price
/// with the shop's open state beside the CTA.
///
/// Presentation only: every tap is a callback, so the tab decides what a like
/// or a follow means and the card never talks to the network.
///
/// The flag beside share reports the post (backend plan Step 9; the design
/// has no report button, and app stores expect one for user content).
class FeedPostCard extends StatefulWidget {
  const FeedPostCard({
    super.key,
    required this.item,
    this.store,
    this.orderedDaysAgo,
    this.liked,
    this.likeCount,
    this.following,
    this.playing = false,
    this.onOpen,
    this.onLike,
    this.onComments,
    this.onShare,
    this.onReport,
    this.onFollow,
    this.onCta,
    this.onPlay,
    this.onStop,
    this.showLikeCount = true,
    this.showShare = true,
  });

  final FeedTabItem item;

  /// The shop behind the post, once the store read has answered: open state,
  /// delivery minutes and distance. Null renders the card without them.
  final BergenStoreInfo? store;

  /// Days since the customer last ordered from this shop; null when never.
  final int? orderedDaysAgo;

  /// Optimistic overrides; null falls back to the item.
  final bool? liked;
  final int? likeCount;
  final bool? following;

  /// True while this card's video is the one playing.
  final bool playing;

  final VoidCallback? onOpen;
  final VoidCallback? onLike;
  final VoidCallback? onComments;
  final VoidCallback? onShare;

  /// «Rapporter»: the flag beside share; hidden when null.
  final VoidCallback? onReport;
  final VoidCallback? onFollow;
  final VoidCallback? onCta;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  /// The admin panel's feed switches (Step 13): «Antall likes» off keeps the
  /// heart but drops the number; «Deling» off drops the share button.
  final bool showLikeCount;
  final bool showShare;

  /// Test kill-switch: widget tests have no image host, so the media area
  /// keeps its tint and skips the network image.
  static bool loadImages = true;

  /// Design tint behind the media while it loads, by category.
  static LinearGradient tintFor(String? category, {required bool video}) {
    if (video) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF22414C), Color(0xFF1B333C)],
      );
    }
    final (a, b) = switch (category) {
      'restaurant' => (const Color(0xFFF6D9B4), const Color(0xFFD2854A)),
      'bakeri' => (const Color(0xFFFBEFDA), const Color(0xFFEBD3A6)),
      'gront' => (const Color(0xFFEAF3E6), const Color(0xFFCFE3D0)),
      'mote' => (const Color(0xFFEFE6F2), const Color(0xFFB79BC4)),
      _ => (const Color(0xFFEAF3F5), const Color(0xFFC9DFE5)),
    };
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [a, b],
    );
  }

  /// `p.h` — the media height on the 390 frame, from the media's own ratio.
  static double mediaHeightFor(FeedTabItem item) {
    final m = item.media;
    if (m.width <= 0 || m.height <= 0) return 230;
    final h = 358 * m.height / m.width;
    // The design's cards run 220–250px (`p.h`).
    return h.clamp(220.0, 250.0);
  }

  /// `400 m` / `1,4 km`.
  static String? distanceLabel(double? km) {
    if (km == null || km <= 0) return null;
    if (km < 1) return UtforskCopy.a1_feed_distance_m((km * 1000).round());
    final text = km < 10
        ? km.toStringAsFixed(1).replaceAll('.', ',')
        : km.round().toString();
    return UtforskCopy.a1_feed_distance_km(text);
  }

  /// `i dag 09:10` / `for 1 t` / `i går` / `for 3 d`.
  static String whenLabel(DateTime? at, {DateTime? now}) {
    if (at == null) return '';
    final local = at.toLocal();
    final ref = now ?? DateTime.now();
    final diff = ref.difference(local);
    if (diff.inMinutes < 60) {
      return UtforskCopy.a1_feed_time_minutes(diff.inMinutes.clamp(1, 59));
    }
    if (diff.inHours < 6) return UtforskCopy.a1_feed_time_hours(diff.inHours);
    final sameDay =
        local.year == ref.year &&
        local.month == ref.month &&
        local.day == ref.day;
    if (sameDay) {
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return UtforskCopy.a1_feed_time_today('$hh:$mm');
    }
    final yesterday = ref.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return UtforskCopy.a1_feed_time_yesterday;
    }
    return UtforskCopy.a1_feed_time_days(diff.inDays.clamp(2, 999));
  }

  /// `Du bestilte herfra for to uker siden`.
  static String? hintFor(int? daysAgo) {
    if (daysAgo == null || daysAgo < 0) return null;
    if (daysAgo < 14) return UtforskCopy.a1_feed_hint_ordered_days(daysAgo);
    return UtforskCopy.a1_feed_hint_ordered_weeks(daysAgo ~/ 7);
  }

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  // `hjertePop .42s cubic-bezier(.3,1.4,.5,1)`: 1 → 1.45 at 45 % → 1, the
  // timing function applied per keyframe segment, as CSS does.
  late final Animation<double> _popScale = _pop.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.45).chain(CurveTween(curve: _spring)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 1).chain(CurveTween(curve: _spring)),
        weight: 55,
      ),
    ]),
  );
  static const Cubic _spring = Cubic(.3, 1.4, .5, 1);

  /// `#ae-mark`.
  static const String _aeMark = 'assets/svgs/dashboard/ae_mark.svg';

  VideoPlayerController? _video;
  double _progress = 0;

  bool get _liked => widget.liked ?? widget.item.isLiked;
  bool get _following =>
      widget.following ?? widget.item.store?.isFollowing ?? false;
  int get _likes => widget.likeCount ?? widget.item.likeCount;

  @override
  void initState() {
    super.initState();
    if (widget.playing) WidgetsBinding.instance.addPostFrameCallback((_) => _startVideo());
  }

  @override
  void didUpdateWidget(FeedPostCard old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) _startVideo();
    if (!widget.playing && old.playing) _stopVideo();
    if (widget.liked == true && old.liked != true) _bump();
  }

  void _bump() {
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) return;
    _pop.forward(from: 0);
  }

  Future<void> _startVideo() async {
    final url = widget.item.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    try {
      await c.initialize();
      if (!mounted || _video != c) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.setVolume(0); // the design plays muted («stumt»)
      c.addListener(_onTick);
      await c.play();
      setState(() {});
    } catch (_) {
      // A video that will not load falls back to its poster; the tab is told
      // so the play button returns.
      if (mounted) widget.onStop?.call();
    }
  }

  void _onTick() {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    final total = c.value.duration.inMilliseconds;
    if (total <= 0) return;
    final p = c.value.position.inMilliseconds / total;
    if ((p - _progress).abs() > .01 && mounted) setState(() => _progress = p);
  }

  Future<void> _stopVideo() async {
    final c = _video;
    _video = null;
    _progress = 0;
    if (c != null) {
      c.removeListener(_onTick);
      await c.dispose();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pop.dispose();
    final c = _video;
    _video = null;
    if (c != null) {
      c.removeListener(_onTick);
      c.dispose();
    }
    super.dispose();
  }

  static const _glassBg = [
    CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .06)]),
  ];

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final h = FeedPostCard.mediaHeightFor(item);

    return Padding(
      key: Key('a1_feed_post_${item.id}'),
      padding: const EdgeInsets.only(top: 14),
      child: CssBox(
        radius: BorderRadius.circular(26),
        bg: _glassBg,
        border: Border.all(color: rgba(255, 255, 255, .2)),
        shadows: [
          CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)),
          CssShadow(0, 2, 0, 0, rgba(4, 18, 26, .25)),
          CssShadow(0, 28, 44, -22, rgba(4, 18, 26, .85)),
        ],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: h, child: _media(context, h)),
              _body(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Media ───────────────────────────────────────────────────────────────

  Widget _media(BuildContext context, double h) {
    final item = widget.item;
    final video = item.media.isVideo;
    final poster = item.media.posterUrl(FeedCloudinaryConfig.cloudName);
    final playing =
        widget.playing && _video != null && _video!.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: FeedPostCard.tintFor(item.category, video: video),
          ),
        ),
        // The tint's light and depth, under the photo.
        CssBox(
          bg: [
            CssRadial(
              [rgba(255, 255, 255, .22), rgba(255, 255, 255, 0)],
              stops: const [0, .6],
              rx: .9,
              ry: .8,
              cx: .28,
              cy: .22,
            ),
            CssLinear(180, [rgba(18, 40, 50, .38), rgba(10, 26, 34, .72)]),
          ],
        ),
        // «Bilde fra …» while the photo is on its way (or missing).
        Align(
          alignment: Alignment(0, (video ? .76 : .54) * 2 - 1),
          child: _placeholderChip(item.publisherName),
        ),
        if (poster.isNotEmpty && FeedPostCard.loadImages)
          CachedNetworkImage(
            imageUrl: poster,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        if (playing)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _video!.value.size.width,
              height: _video!.value.size.height,
              child: VideoPlayer(_video!),
            ),
          ),
        // The scrim; a tap on it opens the shop (or stops a playing video).
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: playing ? widget.onStop : widget.onOpen,
          child: CssBox(
            bg: [
              CssLinear(
                180,
                [
                  rgba(10, 24, 32, .5),
                  rgba(10, 24, 32, .12),
                  rgba(10, 24, 32, 0),
                  rgba(10, 24, 32, 0),
                  rgba(10, 24, 32, .28),
                ],
                const [0, .24, .44, .72, 1],
              ),
            ],
          ),
        ),
        Positioned(top: 10, left: 10, right: 10, child: _header(context)),
        if (video) ...[
          if (!widget.playing)
            Center(
              child: LfPress(
                key: Key('a1_feed_play_${item.id}'),
                onTap: widget.onPlay,
                scale: .92,
                ms: 180,
                child: Semantics(
                  button: true,
                  label: UtforskCopy.a1_feed_video_play,
                  child: CssBox(
                    width: 52,
                    height: 52,
                    radius: BorderRadius.circular(26),
                    bg: [CssSolid(rgba(10, 26, 34, .38))],
                    border: Border.all(color: rgba(255, 255, 255, .7), width: 1.5),
                    shadows: [CssShadow(0, 10, 22, -10, rgba(0, 10, 16, .7))],
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Center(child: feedIcon(FeedIcons.playBig, 19)),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: widget.playing ? widget.onStop : widget.onPlay,
              child: _durationPill(playing: widget.playing),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Semantics(
              label: widget.playing
                  ? UtforskCopy.a1_feed_video_muted_stop
                  : UtforskCopy.a1_feed_video_muted,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: rgba(10, 26, 34, .55),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: feedIcon(FeedIcons.mute, 15),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 2.5,
            child: ColoredBox(color: rgba(255, 255, 255, .16)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 2.5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: playing ? _progress.clamp(0.0, 1.0) : 0,
                heightFactor: 1,
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholderChip(String name) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    decoration: BoxDecoration(
      color: rgba(10, 26, 34, .32),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: rgba(255, 255, 255, .22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        feedIcon(FeedIcons.camera, 14),
        const SizedBox(width: 7),
        Text(
          UtforskCopy.a1_feed_image_from(name),
          style: inter(11.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .88)),
        ),
      ],
    ),
  );

  Widget _durationPill({required bool playing}) => Container(
    padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
    decoration: BoxDecoration(
      color: rgba(10, 26, 34, .55),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (playing)
          // `glod 1.2s ease-in-out infinite`.
          LfLoop(
            frozenMs: 600,
            builder: (context, t, child) => Opacity(
              opacity: kf((t % 1200) / 1200, const [0, .5, 1], const [.7, 1, .7], cssEaseInOut),
              child: child,
            ),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Color(0xFFF26D3D), shape: BoxShape.circle),
            ),
          )
        else
          feedIcon(FeedIcons.playBig, 9),
        const SizedBox(width: 6),
        Text(
          widget.item.media.durationLabel,
          style: inter(11, weight: FontWeight.w800).copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );

  Widget _header(BuildContext context) {
    final item = widget.item;
    final store = widget.store;
    final shadow = [Shadow(color: rgba(0, 10, 16, .6), blurRadius: 6, offset: const Offset(0, 1))];
    final metaParts = <String>[
      if ((item.bydel ?? item.locationName ?? '').isNotEmpty)
        (item.bydel ?? item.locationName)!,
      if (FeedPostCard.distanceLabel(store?.distanceKm) case final d?) d,
      if (item.publishedAt != null) FeedPostCard.whenLabel(item.publishedAt),
    ];
    var meta = metaParts.join(' · ');
    if (item.isFromAerend) meta += ' · ${UtforskCopy.a1_feed_published_by_aerend}';

    return Row(
      children: [
        _logo(context),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.publisherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(14.5, em: -0.01, shadows: shadow),
                    ),
                  ),
                  if (item.store != null) ...[
                    const SizedBox(width: 5),
                    // The «bergensk» dot: a Bergen shop behind the post.
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2C14E),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: rgba(242, 193, 78, .9), blurRadius: 6)],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(10.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .85)).copyWith(
                  shadows: [Shadow(color: rgba(0, 10, 16, .6), blurRadius: 5, offset: const Offset(0, 1))],
                ),
              ),
            ],
          ),
        ),
        if (item.store != null) ...[
          const SizedBox(width: 9),
          _followPill(context),
        ],
      ],
    );
  }

  Widget _logo(BuildContext context) {
    final item = widget.item;
    final url = item.store?.logoUrl ?? item.publisherLogoUrl;
    final name = item.publisherName.trim();
    final initials = name.isEmpty
        ? 'Æ'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w.characters.first.toUpperCase())
              .join();

    Widget tile;
    if (url != null && url.isNotEmpty && FeedPostCard.loadImages) {
      tile = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _initialsTile(initials),
      );
    } else if (item.store == null) {
      tile = Container(
        color: const Color(0xFF1E4F5C),
        alignment: Alignment.center,
        child: SvgPicture.asset(_aeMark, width: 22, height: 14, colorFilter: const ColorFilter.mode(Color(0xFFF5F3EF), BlendMode.srcIn)),
      );
    } else {
      tile = _initialsTile(initials);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: rgba(0, 10, 16, .7), offset: const Offset(0, 6), blurRadius: 12, spreadRadius: -6)],
          ),
          child: tile,
        ),
        // `p.avAerend`: published by Ærend on the shop's behalf.
        if (item.isFromAerend && item.store != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF1E4F5C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(_aeMark, width: 10, height: 6, colorFilter: const ColorFilter.mode(Color(0xFFF5F3EF), BlendMode.srcIn)),
            ),
          ),
      ],
    );
  }

  Widget _initialsTile(String initials) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A6272), Color(0xFF1E4F5C)],
      ),
    ),
    alignment: Alignment.center,
    child: Text(initials, style: jakarta(13)),
  );

  Widget _followPill(BuildContext context) {
    final on = _following;
    return Semantics(
      button: true,
      selected: on,
      label: on ? UtforskCopy.a1_feed_following : UtforskCopy.a1_feed_follow,
      child: LfPress(
        onTap: widget.onFollow,
        scale: .94,
        child: AnimatedContainer(
          key: Key('a1_feed_follow_${widget.item.id}'),
          duration: const Duration(milliseconds: 200),
          curve: cssEase,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            gradient: on ? _orange : null,
            color: on ? null : rgba(255, 255, 255, .2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? rgba(255, 255, 255, .35) : rgba(255, 255, 255, .55)),
          ),
          child: Text(
            on ? UtforskCopy.a1_feed_following : UtforskCopy.a1_feed_follow,
            style: inter(11, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _body(BuildContext context) {
    final item = widget.item;
    final store = widget.store;
    final hint = FeedPostCard.hintFor(widget.orderedDaysAgo);
    final open = store?.open ?? true;
    final price = item.priceOre;

    final String status;
    if (store == null) {
      status = '';
    } else if (!open) {
      status = store.openTime != null
          ? UtforskCopy.a1_feed_status_opens(store.openTime!)
          : UtforskCopy.a1_feed_status_closed;
    } else if (store.deliveryMinutes != null) {
      final a = store.deliveryMinutes!;
      status = UtforskCopy.a1_feed_status_open(UtforskCopy.a1_feed_eta(a, a + 10));
    } else {
      status = UtforskCopy.a1_feed_status_open_plain;
    }

    final toCart = item.hasProduct && open;
    final String ctaLabel;
    if (toCart) {
      ctaLabel = widget.orderedDaysAgo != null
          ? UtforskCopy.a1_feed_cta_add_again
          : UtforskCopy.a1_feed_cta_add;
    } else if (item.store != null) {
      ctaLabel = UtforskCopy.a1_feed_cta_store;
    } else {
      ctaLabel = UtforskCopy.a1_feed_cta_post;
    }
    final merke = UtforskCopy.a1_feed_badge(item.postType, today: item.isFromToday);
    final body = item.headline != null && item.caption.trim().isNotEmpty ? item.caption : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _likePill(),
              if (widget.showShare) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: UtforskCopy.a1_feed_share,
                child: LfPress(
                  key: Key('a1_feed_share_${item.id}'),
                  onTap: widget.onShare,
                  dy: 1.5,
                  scale: .96,
                  ms: 140,
                  child: CssBox(
                    width: 34,
                    height: 34,
                    radius: BorderRadius.circular(17),
                    bg: [CssLinear(180, [rgba(255, 255, 255, .2), rgba(255, 255, 255, .07)])],
                    shadows: _keyShadow,
                    child: Center(child: feedIcon(FeedIcons.shareLaunch, 16)),
                  ),
                ),
              ),
              ],
              if (widget.onReport != null) ...[
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: UtforskCopy.a1_feed_report,
                  child: LfPress(
                    key: Key('a1_feed_report_${item.id}'),
                    onTap: widget.onReport,
                    dy: 1.5,
                    scale: .96,
                    ms: 140,
                    child: CssBox(
                      width: 34,
                      height: 34,
                      radius: BorderRadius.circular(17),
                      bg: [CssLinear(180, [rgba(255, 255, 255, .2), rgba(255, 255, 255, .07)])],
                      shadows: _keyShadow,
                      child: const Center(child: Icon(Icons.outlined_flag, size: 17, color: Colors.white)),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              // Shrinks rather than overflow beside the three round buttons.
              Expanded(
                child: Text(
                  merke.toUpperCase(),
                  key: Key('a1_feed_merke_${item.id}'),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(10.5, weight: FontWeight.w800, em: .06, color: const Color(0xFF5CE0B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(item.title, style: jakarta(18, em: -0.02, height: 1.2)),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: feedIcon(FeedIcons.chevronLaunch, 16),
                ),
              ],
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 3),
            Text(
              body,
              style: inter(13.5, weight: FontWeight.w500, height: 1.45, color: const Color(0xFFDCE9EC)),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: 8),
            Row(
              key: Key('a1_feed_hint_${item.id}'),
              children: [
                feedIcon(FeedIcons.clockLaunch, 13),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    hint,
                    style: inter(12, weight: FontWeight.w700, color: const Color(0xFF9FE8CF)),
                  ),
                ),
              ],
            ),
          ],
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(0, 13, 0, 12),
            color: rgba(255, 255, 255, .1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (price != null)
                      Text(
                        UtforskCopy.a1_feed_price(price ~/ 100),
                        style: jakarta(19, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    if (status.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: open ? const Color(0xFF5CE0B8) : rgba(255, 255, 255, .4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: inter(11, weight: FontWeight.w700, color: const Color(0xFF9FD3DE)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _cta(label: ctaLabel, primary: toCart),
            ],
          ),
        ],
      ),
    );
  }

  static const List<CssShadow> _keyShadow = [
    CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
    CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
    CssShadow(0, 2.5, 0, 0, Color.fromRGBO(6, 22, 30, .5)),
    CssShadow(0, 8, 12, -8, Color.fromRGBO(3, 16, 24, .8)),
  ];

  Widget _likePill() {
    final on = _liked;
    return Semantics(
      button: true,
      selected: on,
      label: widget.showLikeCount ? UtforskCopy.a1_feed_likes(_likes) : UtforskCopy.a1_feed_like,
      child: LfPress(
        key: Key('a1_feed_like_${widget.item.id}'),
        onTap: widget.onLike,
        dy: 1.5,
        scale: .96,
        ms: 140,
        child: CssBox(
          height: 34,
          radius: BorderRadius.circular(17),
          padding: EdgeInsets.fromLTRB(9, 0, widget.showLikeCount ? 12 : 9, 0),
          bg: [
            on
                ? const CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])
                : CssLinear(180, [rgba(255, 255, 255, .2), rgba(255, 255, 255, .07)]),
          ],
          shadows: on
              ? [
                  CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .45)),
                  const CssShadow(0, 2.5, 0, 0, Color(0xFFA63A12)),
                  CssShadow(0, 8, 12, -6, rgba(3, 16, 24, .7)),
                ]
              : _keyShadow,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _popScale,
                child: feedIcon(FeedIcons.heartLaunch(filled: on), 18),
              ),
              if (widget.showLikeCount) ...[
                const SizedBox(width: 6),
                Text(
                  '$_likes',
                  key: Key('a1_feed_like_count_${widget.item.id}'),
                  style: inter(12.5, weight: FontWeight.w800).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const LinearGradient _orange = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
    stops: [0, .56, 1],
  );

  Widget _cta({required String label, required bool primary}) {
    return Semantics(
      button: true,
      label: label,
      child: LfPress(
        key: Key('a1_feed_cta_${widget.item.id}'),
        onTap: widget.onCta,
        dy: 2,
        scale: .98,
        ms: 160,
        child: CssBox(
          height: 44,
          radius: BorderRadius.circular(22),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          bg: [
            primary
                ? const CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])
                : CssLinear(180, [rgba(255, 255, 255, .18), rgba(255, 255, 255, .08)]),
          ],
          border: Border.all(color: primary ? rgba(255, 255, 255, .3) : rgba(255, 255, 255, .22)),
          shadows: primary
              ? [
                  CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .45)),
                  CssShadow(0, 4, 0, 0, rgba(160, 60, 20, .55)),
                  CssShadow(0, 14, 24, -10, rgba(242, 109, 61, .8)),
                ]
              : [
                  CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)),
                  CssShadow(0, 3, 0, 0, rgba(4, 18, 26, .4)),
                  CssShadow(0, 12, 20, -14, rgba(4, 18, 26, .9)),
                ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (primary) ...[
                feedIcon(FeedIcons.bagLaunch, 16),
                const SizedBox(width: 7),
              ],
              Text(label, maxLines: 1, style: inter(14, weight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
