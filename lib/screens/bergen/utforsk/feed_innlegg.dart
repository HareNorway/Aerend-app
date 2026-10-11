import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../data/feed/feed_comment.dart';
import '../../../data/feed/feed_post.dart';
import '../../../data/feed/feed_tab_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../feed/utils/feed_time_ago.dart';
import '../kit/bergen_css.dart' show rgba;
import '../kit/bergen_perf.dart';
import 'feed_post_card.dart';

// ── The post's own page (not in the prototype: needs design sign-off) ───────
//
// The prototype opens a feed post's shop; a post without one (Ærend's own,
// from a push, the «Fra Ærend» tab) opens this page instead (backend plan
// Steps 9 / 13). Built in the prototype's language: the Utforsk sky, the
// glass back key and title of Poseautomaten, the feed card itself, glass
// comment rows and Hurtig's composer.

const String _svgTilbake =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M15 6l-6 6 6 6"/></svg>';
const String _svgSend =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5.5 11.5L12 5l6.5 6.5"/></svg>';

/// The page around every state: the Utforsk sky (`linear-gradient(180deg,
/// #2A6272, #1E4F5C 42%, #173E48)`) and the header row (back key, title).
class FeedInnleggSide extends StatelessWidget {
  const FeedInnleggSide({super.key, required this.child, this.bunn});

  final Widget child;

  /// Pinned to the bottom (the composer).
  final Widget? bunn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topp = MediaQuery.paddingOf(context).top;
    return Material(
      color: const Color(0xFF173E48),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CssBox(bg: [CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .42, 1])]),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, topp + 6, 18, 10),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: l10n.post_detail_go_back,
                      child: LfPress(
                        key: const Key('post-detail-back'),
                        onTap: () => Navigator.of(context).maybePop(),
                        dy: 2,
                        child: CssBox(
                          width: 38,
                          height: 38,
                          radius: BorderRadius.circular(13),
                          bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, .08)])],
                          shadows: [
                            CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .38)),
                            CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14)),
                            CssShadow(0, 3, 0, 0, rgba(6, 22, 30, .55)),
                            CssShadow(0, 10, 16, -8, rgba(0, 0, 0, .6)),
                          ],
                          child: Center(child: SvgPicture.string(_svgTilbake, width: 15, height: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.post_detail_title, style: jakarta(22, em: -.025)),
                  ],
                ),
              ),
              Expanded(child: child),
              ?bunn,
            ],
          ),
        ],
      ),
    );
  }
}

/// The post as a feed item, so the page shows the same card as the feed.
FeedTabItem feedInnleggItem(FeedPost post) => FeedTabItem(
  id: post.id,
  publisherType: post.publisherType,
  publisherName: post.hasStore ? post.store.name : 'Ærend',
  publisherLogoUrl: post.hasStore ? post.store.logoUrl : null,
  store: post.hasStore ? post.store : null,
  postType: 'generic',
  headline: post.headline,
  caption: post.caption,
  locationName: post.locationName,
  media: post.media,
  likeCount: post.likeCount,
  commentCount: post.commentCount,
  isLiked: post.isLiked,
  publishedAt: post.publishedAt,
);

/// Loading, gone or failed: one glass card in the middle of the page.
class FeedInnleggMelding extends StatelessWidget {
  const FeedInnleggMelding({super.key, required this.tekst, this.knapp, this.knappKey = const Key('post_detail_go_back'), this.onKnapp, this.laster = false});

  final String tekst;
  final String? knapp;
  final Key knappKey;
  final VoidCallback? onKnapp;
  final bool laster;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
      child: CssBox(
        radius: BorderRadius.circular(22),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        bg: [CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .06)])],
        border: Border.all(color: rgba(255, 255, 255, .2)),
        shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)), CssShadow(0, 28, 44, -22, rgba(4, 18, 26, .85))],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (laster) ...[const LfDots(), if (tekst.isNotEmpty) const SizedBox(height: 12)],
            if (tekst.isNotEmpty) Text(tekst, textAlign: TextAlign.center, style: jakarta(16, em: -.01, height: 1.3)),
            if (knapp != null) ...[
              const SizedBox(height: 16),
              LfPress(
                key: knappKey,
                onTap: onKnapp,
                dy: 2,
                child: CssBox(
                  height: 44,
                  radius: BorderRadius.circular(999),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
                  shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .4)), const CssShadow(0, 3, 0, 0, Color(0xFFA63A12))],
                  child: Center(widthFactor: 1, child: Text(knapp!, style: jakarta(14))),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The loaded page: the feed card, «KOMMENTARER», the comments.
class FeedInnleggInnhold extends StatefulWidget {
  const FeedInnleggInnhold({
    super.key,
    required this.post,
    required this.comments,
    this.paging,
    required this.onLike,
    this.onStore,
    this.onShare,
    required this.onReport,
    required this.onCommentLongPress,
    this.showLikeCount = true,
  });

  final FeedPost post;

  /// The paged comments (the bloc's); [comments] when there is none (tests).
  final PagingController<String?, FeedComment>? paging;
  final List<FeedComment> comments;
  final VoidCallback onLike;
  final VoidCallback? onStore;
  final VoidCallback? onShare;
  final VoidCallback onReport;
  final void Function(FeedComment comment) onCommentLongPress;
  final bool showLikeCount;

  @override
  State<FeedInnleggInnhold> createState() => _FeedInnleggInnholdState();
}

class _FeedInnleggInnholdState extends State<FeedInnleggInnhold> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final post = widget.post;
    final tom = Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Text(
        l10n.post_detail_no_comments,
        textAlign: TextAlign.center,
        style: inter(13, weight: FontWeight.w600, color: rgba(220, 233, 236, .7)),
      ),
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _FeedInnleggKort(
              child: FeedPostCard(
                key: const Key('post-detail-card'),
                item: feedInnleggItem(post),
                detalj: true,
                playing: _playing,
                onPlay: () => setState(() => _playing = true),
                onStop: () => setState(() => _playing = false),
                onLike: widget.onLike,
                onShare: widget.onShare,
                onReport: widget.onReport,
                onOpen: widget.onStore,
                onCta: widget.onStore,
                showLikeCount: widget.showLikeCount,
                showShare: widget.onShare != null,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            child: Text(
              '${l10n.post_detail_comments}${post.commentCount > 0 ? ' · ${post.commentCount}' : ''}'.toUpperCase(),
              style: inter(10.5, weight: FontWeight.w800, em: .14, color: const Color(0xFFBFD8DF)),
            ),
          ),
        ),
        if (widget.paging != null)
          PagedSliverList<String?, FeedComment>(
            pagingController: widget.paging!,
            builderDelegate: PagedChildBuilderDelegate<FeedComment>(
              itemBuilder: (context, comment, index) => FeedKommentarRad(comment: comment, onLongPress: () => widget.onCommentLongPress(comment)),
              firstPageProgressIndicatorBuilder: (_) => const Padding(padding: EdgeInsets.all(24), child: Center(child: LfDots())),
              newPageProgressIndicatorBuilder: (_) => const Padding(padding: EdgeInsets.all(16), child: Center(child: LfDots())),
              noItemsFoundIndicatorBuilder: (_) => tom,
            ),
          )
        else if (widget.comments.isEmpty)
          SliverToBoxAdapter(child: tom)
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => FeedKommentarRad(comment: widget.comments[i], onLongPress: () => widget.onCommentLongPress(widget.comments[i])),
              childCount: widget.comments.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// The feed card's own glass (`[data-fpost]`): the gradient, the 1 px rim,
/// the top highlight and the drop shadow; 26 px corners.
class _FeedInnleggKort extends StatelessWidget {
  const _FeedInnleggKort({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(26),
    clip: true,
    bg: [CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .06)])],
    border: Border.all(color: rgba(255, 255, 255, .2)),
    shadows: [
      CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)),
      CssShadow(0, 2, 0, 0, rgba(4, 18, 26, .25)),
      CssShadow(0, 28, 44, -22, rgba(4, 18, 26, .85)),
    ],
    child: child,
  );
}

/// One comment: the round avatar (photo or initial on the teal tile), the
/// name, how long ago, the text — on a glass row like the feed's keys.
/// Long-press: delete (own) or «Rapporter kommentar».
class FeedKommentarRad extends StatelessWidget {
  const FeedKommentarRad({super.key, required this.comment, this.onLongPress});

  final FeedComment comment;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final navn = comment.user.name.trim();
    final bokstav = navn.isNotEmpty ? navn.characters.first.toUpperCase() : '?';
    final bilde = comment.user.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        key: const Key('feed_comment_tile_gesture'),
        behavior: HitTestBehavior.opaque,
        onLongPress: onLongPress,
        child: CssBox(
          radius: BorderRadius.circular(18),
          padding: const EdgeInsets.fromLTRB(12, 11, 14, 12),
          bg: [CssLinear(180, [rgba(255, 255, 255, .12), rgba(255, 255, 255, .05)])],
          border: Border.all(color: rgba(255, 255, 255, .14)),
          shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .18))],
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
                ),
                alignment: Alignment.center,
                child: bilde != null && bilde.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: bilde,
                        memCacheWidth: BergenPerf.decodeWidth,
                        fit: BoxFit.cover,
                        width: 32,
                        height: 32,
                        placeholder: (_, _) => Text(bokstav, style: jakarta(12.5)),
                        errorWidget: (_, _, _) => Text(bokstav, style: jakarta(12.5)),
                      )
                    : Text(bokstav, style: jakarta(12.5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(navn.isEmpty ? '?' : navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13.5, em: -.01)),
                        ),
                        const SizedBox(width: 7),
                        Text(feedTimeAgo(comment.createdAt, context), style: inter(10.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .55))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(comment.body, style: inter(13, weight: FontWeight.w500, height: 1.4, color: const Color(0xFFDCE9EC))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The composer: Hurtig's (`54 px` pill, `#2B5F6E → #1E4F5C`, the round
/// orange send key), at most 2000 characters with the count after 1500,
/// quiet while sending or rate-limited.
class FeedKommentarFelt extends StatefulWidget {
  const FeedKommentarFelt({super.key, required this.onSubmit, this.sending = false, this.rateLimited = false, this.autoFocus = false});

  final void Function(String text) onSubmit;
  final bool sending;
  final bool rateLimited;
  final bool autoFocus;

  @override
  State<FeedKommentarFelt> createState() => FeedKommentarFeltState();
}

class FeedKommentarFeltState extends State<FeedKommentarFelt> {
  final _tekst = TextEditingController();
  final _fokus = FocusNode();
  static const int _maks = 2000;
  static const int _tellerFra = 1500;

  @override
  void initState() {
    super.initState();
    _tekst.addListener(() => setState(() {}));
    if (widget.autoFocus) WidgetsBinding.instance.addPostFrameCallback((_) => _fokus.requestFocus());
  }

  @override
  void dispose() {
    _tekst.dispose();
    _fokus.dispose();
    super.dispose();
  }

  void clear() => _tekst.clear();

  bool get kanSende => _tekst.text.trim().isNotEmpty && !widget.sending && !widget.rateLimited;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bunn = MediaQuery.paddingOf(context).bottom;
    final n = _tekst.text.length;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 18, 14, 12 + bunn),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(23, 62, 72, 0), Color.fromRGBO(23, 62, 72, .96), Color(0xFF173E48)],
          stops: [0, .22, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (n > _tellerFra)
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 6),
              child: Text(
                l10n.comment_char_counter(n),
                textAlign: TextAlign.right,
                style: inter(11, weight: FontWeight.w700, color: n > _maks ? const Color(0xFFFF9466) : rgba(255, 255, 255, .55)),
              ),
            ),
          CssBox(
            radius: BorderRadius.circular(27),
            bg: const [CssLinear(180, [Color(0xFF2B5F6E), Color(0xFF1E4F5C)])],
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .28)),
            shadows: const [
              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
              CssShadow(0, 18, 34, -14, Color.fromRGBO(4, 18, 26, .85)),
            ],
            padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: TextField(
                      key: const Key('feed_comment_input'),
                      controller: _tekst,
                      focusNode: _fokus,
                      enabled: !widget.sending && !widget.rateLimited,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: _maks,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      style: jakarta(14, weight: FontWeight.w700),
                      cursorColor: const Color(0xFF7FF0CB),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: l10n.post_detail_comment_hint,
                        hintStyle: jakarta(14, weight: FontWeight.w700, color: const Color(0xFFA9BCC2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Semantics(
                  button: true,
                  enabled: kanSende,
                  label: 'Send kommentaren',
                  child: LfPress(
                    key: const Key('feed_comment_send_btn'),
                    onTap: kanSende ? () => widget.onSubmit(_tekst.text.trim()) : null,
                    scale: .92,
                    ms: 140,
                    child: Opacity(
                      opacity: kanSende || widget.sending ? 1 : .5,
                      child: CssBox(
                        width: 42,
                        height: 42,
                        radius: BorderRadius.circular(21),
                        bg: const [CssLinear(160, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                        shadows: const [
                          CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                          CssShadow(0, 2.5, 0, 0, Color(0xFFA63A12)),
                          CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .75)),
                        ],
                        child: Center(
                          child: widget.sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : SvgPicture.string(_svgSend, width: 17, height: 17),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Kommentarer» switched off in the admin panel: a quiet line where the
/// composer was.
class FeedKommentarerAv extends StatelessWidget {
  const FeedKommentarerAv({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
    child: Text(
      'Kommentarer er slått av',
      textAlign: TextAlign.center,
      style: inter(12.5, weight: FontWeight.w600, color: rgba(220, 233, 236, .7)),
    ),
  );
}
