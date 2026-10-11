import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/feed/feed_comment.dart';
import '../../../data/feed/feed_config.dart';
import '../../../data/feed/feed_post.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart';
import '../../bergen/meg/meg_ark.dart';
import '../../bergen/utforsk/feed_innlegg.dart';
import '../../bergen/utforsk/utforsk_copy.dart';
import '../components/feed_post_kebab_sheet.dart';
import '../storeProfile/store_profile.dart';
import 'post_detail_bloc.dart';
import 'post_detail_event.dart';
import 'post_detail_state.dart';

/// The logged-in customer wrote [comment]: the feed sends the monolith user
/// id as the comment's `user.id`. False for a guest.
bool isOwnFeedComment(FeedComment comment) {
  final me = prefGetInt(prefUserId);
  return me != 0 && comment.user.id == '$me';
}

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final bool autoFocusComment;
  final FeedPost? previewPost;
  final List<FeedComment>? previewComments;

  /// Injected in tests.
  final FeedRepo? repo;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.autoFocusComment = false,
    this.previewPost,
    this.previewComments,
    this.repo,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostDetailBloc? _bloc;
  final _commentInputKey = GlobalKey<FeedKommentarFeltState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc == null && widget.previewPost == null) {
      _bloc = PostDetailBloc(context, this, widget.postId, repo: widget.repo);
      _bloc!.onCommentSubmitted = () => _commentInputKey.currentState?.clear();
      _bloc!.onCommentCleared = () => _commentInputKey.currentState?.clear();
      _bloc!.handleEvent(const PostDetailInitRequested());
    }
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  void _openStore(String storeId) {
    // An Ærend post without a shop has no profile to open (Step 13).
    if (storeId.isEmpty) return;
    openScreen(context, StoreProfileScreen(storeId: storeId));
  }

  /// Long-press on a comment: delete for the customer's own, «Rapporter
  /// kommentar» for anyone else's (Step 13) — in the prototype's Ark.
  void _showCommentSheet(FeedComment comment) {
    final l10n = AppLocalizations.of(context)!;
    final own = isOwnFeedComment(comment);
    showMegArk<void>(
      context,
      title: comment.user.name.trim().isEmpty ? l10n.post_detail_comments : comment.user.name.trim(),
      subtitle: comment.body,
      body: (sheet, _) => Column(
        children: [
          if (own)
            MegArkRow(
              key: const Key('post-detail-delete-comment'),
              title: l10n.comment_delete_confirm_yes,
              onTap: () {
                Navigator.pop(sheet);
                _confirmDelete(comment);
              },
            )
          else
            MegArkRow(
              key: const Key('post-detail-report-comment'),
              title: 'Rapporter kommentar',
              onTap: () {
                Navigator.pop(sheet);
                reportFeedComment(context, comment.id, repo: _bloc?.repo);
              },
            ),
        ],
      ),
    );
  }

  void _confirmDelete(FeedComment comment) {
    final l10n = AppLocalizations.of(context)!;
    showMegArk<void>(
      context,
      title: l10n.comment_delete_confirm_title,
      subtitle: l10n.comment_delete_confirm_message,
      secondary: MegArkButton(label: l10n.comment_delete_confirm_no, onTap: () => Navigator.of(context).pop()),
      primary: MegArkButton(
        key: const Key('post-detail-delete-yes'),
        label: l10n.comment_delete_confirm_yes,
        onTap: () {
          Navigator.of(context).pop();
          _bloc?.handleEvent(PostDetailCommentDeleteRequested(comment.id));
        },
      ),
    );
  }

  void _share(FeedPost post) {
    // iOS 26 refuses a share sheet without an anchor (sharePositionOrigin).
    final box = context.findRenderObject() as RenderBox?;
    final item = feedInnleggItem(post);
    Share.share(
      UtforskCopy.a1_feed_share_text(item.title, item.publisherName),
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Widget _loaded(FeedPost post, {List<FeedComment> comments = const [], bool sending = false, bool rateLimited = false, bool commentsOn = true, bool likeCounts = true, bool sharing = true}) {
    final bloc = _bloc;
    return FeedInnleggSide(
      bunn: commentsOn
          ? FeedKommentarFelt(
              key: _commentInputKey,
              autoFocus: widget.autoFocusComment,
              sending: sending,
              rateLimited: rateLimited,
              onSubmit: (body) => bloc?.handleEvent(PostDetailCommentSubmitRequested(body)),
            )
          : const FeedKommentarerAv(key: Key('post-detail-comments-off')),
      child: FeedInnleggInnhold(
        post: post,
        paging: bloc?.commentsPagingController,
        comments: comments,
        onLike: () => bloc?.handleEvent(const PostDetailLikeToggleRequested()),
        // Ærend's own post without a shop: nothing to open (Step 13).
        onStore: post.hasStore ? () => _openStore(post.store.id) : null,
        onShare: sharing ? () => _share(post) : null,
        onReport: () => reportFeedPost(context, post.id),
        onCommentLongPress: _showCommentSheet,
        showLikeCount: likeCounts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewPost != null) {
      return _loaded(widget.previewPost!, comments: widget.previewComments ?? const []);
    }

    final bloc = _bloc;
    if (bloc == null) {
      return const FeedInnleggSide(child: FeedInnleggMelding(tekst: '', laster: true));
    }

    return StreamBuilder<PostDetailState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const PostDetailInitial();
        final l10n = AppLocalizations.of(context)!;

        if (state is PostDetailLoading) {
          return FeedInnleggSide(child: FeedInnleggMelding(tekst: l10n.post_detail_loading, laster: true));
        }

        // A post that is gone says so, and offers the way out rather than a
        // retry that would fail identically every time (T8).
        if (state is PostDetailNotFound) {
          return FeedInnleggSide(
            child: KeyedSubtree(
              key: const Key('post_detail_not_found'),
              child: FeedInnleggMelding(
                tekst: l10n.post_detail_unavailable,
                knapp: l10n.post_detail_go_back,
                onKnapp: () => Navigator.of(context).maybePop(),
              ),
            ),
          );
        }

        if (state is PostDetailError) {
          return FeedInnleggSide(
            child: FeedInnleggMelding(
              tekst: l10n.post_detail_error,
              knapp: l10n.feed_retry,
              knappKey: const Key('post_detail_retry'),
              onKnapp: () => bloc.handleEvent(const PostDetailRefreshRequested()),
            ),
          );
        }

        if (state is! PostDetailLoaded) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<FeedConfig>(
          valueListenable: bloc.config,
          builder: (context, config, _) => _loaded(
            state.post,
            sending: state.commentSending,
            rateLimited: state.isRateLimited,
            commentsOn: config.comments,
            likeCounts: config.likeCounts,
            sharing: config.sharing,
          ),
        );
      },
    );
  }
}
