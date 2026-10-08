import 'package:flutter/material.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../data/feed/feed_comment.dart';
import '../../../data/feed/feed_config.dart';
import '../../../data/feed/feed_post.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart';
import '../components/feed_comment_input_panel.dart';
import '../components/feed_comment_tile.dart';
import '../components/feed_error_state.dart';
import '../components/feed_post_kebab_sheet.dart';
import '../components/feed_post_detail_card.dart';
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
  final _commentInputKey = GlobalKey<FeedCommentInputPanelState>();

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
  /// kommentar» for anyone else's (Step 13).
  void _showCommentSheet(FeedComment comment) {
    final l10n = AppLocalizations.of(context)!;
    final own = isOwnFeedComment(comment);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (own)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l10n.comment_delete_confirm_yes),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(comment);
                },
              )
            else
              ListTile(
                key: const Key('post-detail-report-comment'),
                leading: const Icon(Icons.outlined_flag),
                title: const Text('Rapporter kommentar'),
                onTap: () {
                  Navigator.pop(ctx);
                  reportFeedComment(context, comment.id, repo: _bloc?.repo);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(FeedComment comment) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.comment_delete_confirm_title),
        content: Text(l10n.comment_delete_confirm_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.comment_delete_confirm_no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc?.handleEvent(
                PostDetailCommentDeleteRequested(comment.id),
              );
            },
            child: Text(l10n.comment_delete_confirm_yes),
          ),
        ],
      ),
    );
  }

  String _avatarLetter() {
    final name = prefGetString(prefUserName);
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  String? _avatarUrl() {
    final url = prefGetString(prefProfileImage).trim();
    return url.isNotEmpty ? url : null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewPost != null) {
      return _PostDetailBody(
        post: widget.previewPost!,
        bloc: null,
        comments: widget.previewComments ?? const [],
        autoFocusComment: widget.autoFocusComment,
        commentInputKey: _commentInputKey,
        avatarLetter: '?',
        onLikeTap: () {},
        onStoreTap: () {},
        onCommentSubmit: (_) {},
        onCommentLongPress: (_) {},
        commentSending: false,
        rateLimited: false,
        likeInFlight: false,
      );
    }

    final bloc = _bloc;
    if (bloc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<PostDetailState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const PostDetailInitial();
        final l10n = AppLocalizations.of(context)!;

        if (state is PostDetailLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.post_detail_title)),
            body: Center(child: Text(l10n.post_detail_loading)),
          );
        }

        // A post that is gone says so, and offers the way out rather than a
        // retry that would fail identically every time (T8).
        if (state is PostDetailNotFound) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.post_detail_title)),
            body: Center(
              key: const Key('post_detail_not_found'),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hide_source_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      l10n.post_detail_unavailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      key: const Key('post_detail_go_back'),
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l10n.post_detail_go_back),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is PostDetailError) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.post_detail_title)),
            body: FeedErrorState(
              message: l10n.post_detail_error,
              onRetry: () =>
                  bloc.handleEvent(const PostDetailRefreshRequested()),
            ),
          );
        }

        if (state is! PostDetailLoaded) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<FeedConfig>(
          valueListenable: bloc.config,
          builder: (context, config, _) => _PostDetailBody(
            post: state.post,
            bloc: bloc,
            autoFocusComment: widget.autoFocusComment,
            commentInputKey: _commentInputKey,
            avatarLetter: _avatarLetter(),
            avatarUrl: _avatarUrl(),
            onLikeTap: () =>
                bloc.handleEvent(const PostDetailLikeToggleRequested()),
            // Ærend's own post without a shop: nothing to open (Step 13).
            onStoreTap: state.post.hasStore
                ? () => _openStore(state.post.store.id)
                : null,
            onCommentSubmit: (body) =>
                bloc.handleEvent(PostDetailCommentSubmitRequested(body)),
            onCommentLongPress: _showCommentSheet,
            commentSending: state.commentSending,
            rateLimited: state.isRateLimited,
            likeInFlight: state.likeInFlight,
            commentsEnabled: config.comments,
            showLikeCount: config.likeCounts,
            showShare: config.sharing,
          ),
        );
      },
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  final FeedPost post;
  final PostDetailBloc? bloc;
  final List<FeedComment> comments;
  final bool autoFocusComment;
  final GlobalKey<FeedCommentInputPanelState> commentInputKey;
  final String avatarLetter;
  final String? avatarUrl;
  final VoidCallback onLikeTap;
  final VoidCallback? onStoreTap;
  final void Function(String body) onCommentSubmit;
  final void Function(FeedComment comment) onCommentLongPress;
  final bool commentSending;
  final bool rateLimited;
  final bool likeInFlight;

  /// The admin panel's switches (Step 13).
  final bool commentsEnabled;
  final bool showLikeCount;
  final bool showShare;

  const _PostDetailBody({
    required this.post,
    required this.bloc,
    this.comments = const [],
    required this.autoFocusComment,
    required this.commentInputKey,
    required this.avatarLetter,
    this.avatarUrl,
    required this.onLikeTap,
    required this.onStoreTap,
    required this.onCommentSubmit,
    required this.onCommentLongPress,
    this.commentSending = false,
    this.rateLimited = false,
    this.likeInFlight = false,
    this.commentsEnabled = true,
    this.showLikeCount = true,
    this.showShare = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l10n.post_detail_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // «Rapporter» (backend plan Step 9): asks why, then reports.
            IconButton(
              key: const Key('post-detail-report'),
              tooltip: 'Rapporter innlegget',
              icon: const Icon(Icons.outlined_flag),
              onPressed: () => reportFeedPost(context, post.id),
            ),
            if (showShare)
              IconButton(
                key: const Key('post-detail-share'),
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.post_detail_share_action)),
                  );
                },
              ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FeedPostDetailCard(
                post: post,
                onLikeTap: onLikeTap,
                onStoreTap: onStoreTap,
                isLikeInFlight: likeInFlight,
                showLikeCount: showLikeCount,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  l10n.post_detail_comments,
                  style: aeH3().copyWith(fontSize: 16),
                ),
              ),
            ),
            if (bloc != null)
              PagedSliverList<String?, FeedComment>(
                pagingController: bloc!.commentsPagingController,
                builderDelegate: PagedChildBuilderDelegate<FeedComment>(
                  itemBuilder: (context, comment, index) => FeedCommentTile(
                    comment: comment,
                    onLongPress: () => onCommentLongPress(comment),
                  ),
                  firstPageProgressIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  noItemsFoundIndicatorBuilder: (_) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        l10n.post_detail_no_comments,
                        style: TextStyle(color: ScSaasThemeTokens.muted),
                      ),
                    ),
                  ),
                ),
              )
            else if (comments.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.post_detail_no_comments,
                      style: TextStyle(color: ScSaasThemeTokens.muted),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FeedCommentTile(
                    comment: comments[index],
                    onLongPress: () => onCommentLongPress(comments[index]),
                  ),
                  childCount: comments.length,
                ),
              ),
          ],
        ),
        // «Kommentarer» switched off in the admin panel (Step 13): a quiet
        // line where the input was.
        bottomNavigationBar: commentsEnabled
            ? FeedCommentInputPanel(
                key: commentInputKey,
                avatarUrl: avatarUrl,
                avatarLetter: avatarLetter,
                autoFocus: autoFocusComment,
                sending: commentSending,
                rateLimited: rateLimited,
                onSubmit: onCommentSubmit,
              )
            : const SafeArea(
                key: Key('post-detail-comments-off'),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    'Kommentarer er slått av',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ScSaasThemeTokens.muted),
                  ),
                ),
              ),
      ),
    );
  }
}
