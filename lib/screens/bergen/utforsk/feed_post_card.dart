import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'feed_icons.dart';
import 'utforsk_copy.dart';

/// One feed post, as the prototype draws it (`utforsk` ≈L4433–4492 in
/// `Ærend Kunde Bergen.dc.html`): a glass card with the media on top — shop
/// header, «Følg», the badge, the like / comment / share rail, and for a video
/// the play button, the duration pill and the progress bar — and under it the
/// title with its chevron, the text, the «Du bestilte …» hint, the CTA and the
/// price with the shop's open state.
///
/// Presentation only: every tap is a callback, so the tab decides what a like
/// or a follow means and the card never talks to the network.
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
    this.onFollow,
    this.onCta,
    this.onPlay,
    this.onStop,
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
  final VoidCallback? onFollow;
  final VoidCallback? onCta;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

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
    // The design's cards run 220–250px; below ~228 the header and the rail
    // meet, so a wide video crops rather than shrinks.
    return h.clamp(230.0, 256.0);
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
  // `hjertePop`: 1 → 1.45 at 45 % → 1, with the design's springy ease on
  // each leg (a curve on the whole sequence would overshoot past t = 1).
  late final Animation<double> _popScale = _pop.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.45,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.45,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 55,
      ),
    ]),
  );

  VideoPlayerController? _video;
  double _progress = 0;

  bool get _liked => widget.liked ?? widget.item.isLiked;
  bool get _following =>
      widget.following ?? widget.item.store?.isFollowing ?? false;
  int get _likes => widget.likeCount ?? widget.item.likeCount;

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

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final item = widget.item;
    final h = FeedPostCard.mediaHeightFor(item) * s;

    return Container(
      key: Key('a1_feed_post_${item.id}'),
      margin: EdgeInsets.only(top: 14 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x24FFFFFF), Color(0x0FFFFFFF)],
        ),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4004121A),
            offset: Offset(0, 2),
            blurRadius: 1,
            blurStyle: BlurStyle.outer,
          ),
          BoxShadow(
            color: Color(0xD904121A),
            offset: Offset(0, 28),
            blurRadius: 44,
            spreadRadius: -22,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26 * s),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: h, child: _media(context, h)),
                _body(context),
              ],
            ),
            bergenInsetTop(radius: 26 * s, alpha: .28),
          ],
        ),
      ),
    );
  }

  // ── Media ───────────────────────────────────────────────────────────────

  Widget _media(BuildContext context, double h) {
    final s = context.bs;
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
        if (poster.isNotEmpty && FeedPostCard.loadImages)
          CachedNetworkImage(
            imageUrl: poster,
            fit: BoxFit.cover,
            fadeInDuration: BergenTokens.motion(
              context,
              const Duration(milliseconds: 300),
            ),
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
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x6B0F1F2B),
                  Color(0x0F0F1F2B),
                  Color(0x000F1F2B),
                  Color(0x570F1F2B),
                ],
                stops: [0, .26, .52, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10 * s,
          left: 10 * s,
          right: 10 * s,
          child: _header(context),
        ),
        Positioned(top: 58 * s, left: 12 * s, child: _badge(context)),
        Positioned(right: 10 * s, bottom: 12 * s, child: _rail(context)),
        if (video) ...[
          if (!widget.playing) Center(child: _playButton(context)),
          Positioned(
            right: 64 * s,
            top: 60 * s,
            child: _durationPill(context, playing: playing),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 3 * s,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0x2EFFFFFF)),
                  ),
                  FractionallySizedBox(
                    widthFactor: playing ? _progress.clamp(0, 1) : 0,
                    child: const ColoredBox(color: BergenTokens.lantern),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(BuildContext context) {
    final s = context.bs;
    final item = widget.item;
    final store = widget.store;
    final shadow = [
      const Shadow(
        color: Color(0x99000A10),
        blurRadius: 6,
        offset: Offset(0, 1),
      ),
    ];
    final metaParts = <String>[
      if ((item.bydel ?? item.locationName ?? '').isNotEmpty)
        (item.bydel ?? item.locationName)!,
      if (FeedPostCard.distanceLabel(store?.distanceKm) case final d?) d,
      if (item.publishedAt != null) FeedPostCard.whenLabel(item.publishedAt),
      if (item.isFromAerend) UtforskCopy.a1_feed_published_by_aerend,
    ];

    return Row(
      children: [
        _logo(context),
        SizedBox(width: 9 * s),
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
                      style: bDisplay(
                        context,
                        14.5,
                        weight: FontWeight.w800,
                        letterSpacingEm: -0.01,
                        shadows: shadow,
                      ),
                    ),
                  ),
                  if (item.store != null) ...[
                    SizedBox(width: 5 * s),
                    // The «bergensk» dot: a Bergen shop behind the post.
                    Container(
                      width: 6 * s,
                      height: 6 * s,
                      decoration: const BoxDecoration(
                        color: BergenTokens.lantern,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xE6F2C14E), blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                metaParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bText(
                  context,
                  10.5,
                  weight: FontWeight.w700,
                  color: const Color(0xD9FFFFFF),
                  shadows: shadow,
                ),
              ),
            ],
          ),
        ),
        if (item.store != null) ...[
          SizedBox(width: 9 * s),
          _followPill(context),
        ],
      ],
    );
  }

  Widget _logo(BuildContext context) {
    final s = context.bs;
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
        errorWidget: (_, __, ___) => _initialsTile(context, initials),
      );
    } else if (item.store == null) {
      tile = Container(
        color: BergenTokens.teal,
        alignment: Alignment.center,
        child: SvgPicture.asset(
          AerendBergenAuthTokens.mark,
          width: 22 * s,
          height: 14 * s,
        ),
      );
    } else {
      tile = _initialsTile(context, initials);
    }

    return SizedBox(
      width: 42 * s,
      height: 42 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38 * s,
            height: 38 * s,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13 * s),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xB3000A10),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: -6,
                  blurStyle: BlurStyle.outer,
                ),
              ],
            ),
            child: tile,
          ),
          if (item.isFromAerend && item.store != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18 * s,
                height: 18 * s,
                decoration: BoxDecoration(
                  color: BergenTokens.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  AerendBergenAuthTokens.mark,
                  width: 9 * s,
                  height: 6 * s,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialsTile(BuildContext context, String initials) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A6272), Color(0xFF1E4F5C)],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: bDisplay(context, 13, weight: FontWeight.w800),
    ),
  );

  Widget _followPill(BuildContext context) {
    final s = context.bs;
    final on = _following;
    return Semantics(
      button: true,
      selected: on,
      label: on ? UtforskCopy.a1_feed_following : UtforskCopy.a1_feed_follow,
      child: OnbPressable(
        onTap: widget.onFollow,
        pressDy: 0,
        pressScale: .94,
        child: AnimatedContainer(
          key: Key('a1_feed_follow_${widget.item.id}'),
          duration: BergenTokens.motion(
            context,
            const Duration(milliseconds: 200),
          ),
          padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 6 * s),
          decoration: BoxDecoration(
            gradient: on ? _orange : null,
            color: on ? null : const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: on ? const Color(0x59FFFFFF) : const Color(0x8CFFFFFF),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000A10),
                offset: Offset(0, 6),
                blurRadius: 14,
                spreadRadius: -8,
                blurStyle: BlurStyle.outer,
              ),
            ],
          ),
          child: Text(
            on ? UtforskCopy.a1_feed_following : UtforskCopy.a1_feed_follow,
            style: bText(context, 11.5, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context) {
    final s = context.bs;
    final item = widget.item;
    final label = UtforskCopy.a1_feed_badge(
      item.postType,
      today: item.isFromToday,
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x99FFFFFF)),
      ),
      child: Text(
        label,
        style: bText(
          context,
          11,
          weight: FontWeight.w800,
          shadows: const [
            Shadow(
              color: Color(0x66000A10),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail(BuildContext context) {
    final s = context.bs;
    final item = widget.item;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _railButton(
          context,
          key: Key('a1_feed_like_${item.id}'),
          icon: ScaleTransition(
            scale: _popScale,
            child: feedIcon(FeedIcons.heart(filled: _liked), 19 * s),
          ),
          label: '$_likes',
          onTap: widget.onLike,
          semantics: UtforskCopy.a1_feed_likes(_likes),
        ),
        SizedBox(height: 8 * s),
        _railButton(
          context,
          key: Key('a1_feed_comments_${item.id}'),
          icon: feedIcon(FeedIcons.comment, 18 * s),
          label: '${item.commentCount}',
          onTap: widget.onComments,
          semantics: UtforskCopy.a1_feed_comments(item.commentCount),
        ),
        SizedBox(height: 8 * s),
        _railButton(
          context,
          key: Key('a1_feed_share_${item.id}'),
          icon: feedIcon(FeedIcons.share, 17 * s),
          label: UtforskCopy.a1_feed_share,
          onTap: widget.onShare,
          semantics: UtforskCopy.a1_feed_share,
          labelSize: 9,
        ),
      ],
    );
  }

  Widget _railButton(
    BuildContext context, {
    required Key key,
    required Widget icon,
    required String label,
    required String semantics,
    VoidCallback? onTap,
    double labelSize = 9.5,
  }) {
    final s = context.bs;
    return Semantics(
      button: true,
      label: semantics,
      child: OnbPressable(
        key: key,
        onTap: onTap,
        pressDy: 0,
        pressScale: .9,
        child: Container(
          width: 44 * s,
          padding: EdgeInsets.fromLTRB(0, 7 * s, 0, 5 * s),
          decoration: BoxDecoration(
            color: const Color(0x57FFFFFF),
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(color: const Color(0x80FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000A10),
                offset: Offset(0, 10),
                blurRadius: 18,
                spreadRadius: -8,
                blurStyle: BlurStyle.outer,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(height: 1 * s),
              Text(
                label,
                style: bText(
                  context,
                  labelSize,
                  weight: FontWeight.w800,
                  shadows: const [
                    Shadow(
                      color: Color(0x80000A10),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playButton(BuildContext context) {
    final s = context.bs;
    return Semantics(
      button: true,
      label: UtforskCopy.a1_feed_video_play,
      child: OnbPressable(
        key: Key('a1_feed_play_${widget.item.id}'),
        onTap: widget.onPlay,
        pressDy: 0,
        pressScale: .92,
        child: _Glow(
          child: Container(
            width: 60 * s,
            height: 60 * s,
            decoration: BoxDecoration(
              color: const Color(0x4DFFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x8CFFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000A10),
                  offset: Offset(0, 12),
                  blurRadius: 22,
                  spreadRadius: -10,
                  blurStyle: BlurStyle.outer,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(left: 3 * s),
              child: feedIcon(FeedIcons.play, 22 * s),
            ),
          ),
        ),
      ),
    );
  }

  Widget _durationPill(BuildContext context, {required bool playing}) {
    final s = context.bs;
    final text =
        '${widget.item.media.durationLabel} · '
        '${playing ? UtforskCopy.a1_feed_video_muted_stop : UtforskCopy.a1_feed_video_muted}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: playing ? widget.onStop : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
        decoration: BoxDecoration(
          color: const Color(0x990F1F2B),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playing) ...[
              _Glow(
                period: const Duration(milliseconds: 1200),
                child: Container(
                  width: 6 * s,
                  height: 6 * s,
                  decoration: const BoxDecoration(
                    color: BergenTokens.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 5 * s),
            ],
            Text(text, style: bText(context, 10, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _body(BuildContext context) {
    final s = context.bs;
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
      status = UtforskCopy.a1_feed_status_open(
        UtforskCopy.a1_feed_eta(a, a + 10),
      );
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

    return Padding(
      padding: EdgeInsets.fromLTRB(15 * s, 13 * s, 15 * s, 15 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: bDisplay(
                      context,
                      19,
                      weight: FontWeight.w800,
                      letterSpacingEm: -0.02,
                      height: 1.15,
                    ),
                  ),
                ),
                SizedBox(width: 10 * s),
                Padding(
                  padding: EdgeInsets.only(top: 3 * s),
                  child: feedIcon(FeedIcons.chevron, 18 * s),
                ),
              ],
            ),
          ),
          if (item.headline != null && item.caption.trim().isNotEmpty) ...[
            SizedBox(height: 4 * s),
            Text(
              item.caption,
              style: bText(
                context,
                13.5,
                weight: FontWeight.w500,
                color: const Color(0xFFDCE9EC),
                height: 1.45,
              ),
            ),
          ],
          if (hint != null) ...[
            SizedBox(height: 10 * s),
            Container(
              key: Key('a1_feed_hint_${item.id}'),
              padding: EdgeInsets.symmetric(
                horizontal: 11 * s,
                vertical: 8 * s,
              ),
              decoration: BoxDecoration(
                color: const Color(0x1F5CE0B8),
                borderRadius: BorderRadius.circular(14 * s),
                border: Border.all(color: const Color(0x595CE0B8)),
              ),
              child: Row(
                children: [
                  feedIcon(FeedIcons.clock, 13 * s),
                  SizedBox(width: 7 * s),
                  Expanded(
                    child: Text(
                      hint,
                      style: bText(
                        context,
                        11.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFFDFF7EE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12 * s),
          Row(
            children: [
              Expanded(
                child: _cta(
                  context,
                  label: ctaLabel,
                  primary: toCart,
                  icon: toCart,
                ),
              ),
              if (price != null || status.isNotEmpty) ...[
                SizedBox(width: 10 * s),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (price != null)
                      Text(
                        UtforskCopy.a1_feed_price(price ~/ 100),
                        style: bDisplay(
                          context,
                          17,
                          weight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    if (status.isNotEmpty) ...[
                      SizedBox(height: 3 * s),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6 * s,
                            height: 6 * s,
                            decoration: BoxDecoration(
                              color: open
                                  ? BergenTokens.mint
                                  : const Color(0x66FFFFFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4 * s),
                          Text(
                            status,
                            style: bText(
                              context,
                              10.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF9FD3DE),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static const LinearGradient _orange = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
    stops: [0, .56, 1],
  );

  Widget _cta(
    BuildContext context, {
    required String label,
    required bool primary,
    required bool icon,
  }) {
    final s = context.bs;
    return Semantics(
      button: true,
      label: label,
      child: OnbPressable(
        key: Key('a1_feed_cta_${widget.item.id}'),
        onTap: widget.onCta,
        pressDy: 2,
        pressScale: .98,
        child: Container(
          height: 46 * s,
          decoration: BoxDecoration(
            gradient: primary
                ? _orange
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x2EFFFFFF), Color(0x14FFFFFF)],
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: primary
                  ? const Color(0x4DFFFFFF)
                  : const Color(0x38FFFFFF),
            ),
            boxShadow: primary
                ? const [
                    BoxShadow(
                      color: Color(0x8CA03C14),
                      offset: Offset(0, 4),
                      blurRadius: 1,
                      blurStyle: BlurStyle.outer,
                    ),
                    BoxShadow(
                      color: Color(0xCCF26D3D),
                      offset: Offset(0, 14),
                      blurRadius: 24,
                      spreadRadius: -10,
                      blurStyle: BlurStyle.outer,
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x6604121A),
                      offset: Offset(0, 3),
                      blurRadius: 1,
                      blurStyle: BlurStyle.outer,
                    ),
                    BoxShadow(
                      color: Color(0xE604121A),
                      offset: Offset(0, 12),
                      blurRadius: 20,
                      spreadRadius: -14,
                      blurStyle: BlurStyle.outer,
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon) ...[
                      feedIcon(FeedIcons.bag, 16 * s),
                      SizedBox(width: 8 * s),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bText(context, 14, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              bergenInsetTop(radius: 999, alpha: primary ? .45 : .28),
            ],
          ),
        ),
      ),
    );
  }
}

/// The design's `glod` keyframes: opacity .7 ↔ 1, looping. Off under reduced
/// motion, where the child simply sits at full opacity.
class _Glow extends StatefulWidget {
  const _Glow({
    required this.child,
    this.period = const Duration(milliseconds: 2600),
  });

  final Widget child;
  final Duration period;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (reduced) {
      _c?.dispose();
      _c = null;
      return;
    }
    _c ??= AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(
        begin: .7,
        end: 1,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
