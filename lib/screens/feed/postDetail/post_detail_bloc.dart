import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../blocs/bloc.dart';
import '../../../data/feed/feed_comment.dart';
import '../../../data/feed/feed_post.dart';
import '../../../data/feed/feed_post_detail.dart';
import '../../../exceptions/feed/feed_api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart';
import 'post_detail_event.dart';
import 'post_detail_state.dart';

class PostDetailBloc extends Bloc {
  PostDetailBloc(
    this.context,
    this.state,
    this.postId, {
    FeedRepo? repo,
  }) : _repo = repo ?? FeedRepo() {
    commentsPagingController =
        PagingController<String?, FeedComment>(firstPageKey: null);
    commentsPagingController.addPageRequestListener(_onCommentsPageRequest);
    _stateSubject.add(const PostDetailInitial());
  }

  final BuildContext context;
  final State state;
  final String postId;
  final FeedRepo _repo;

  late final PagingController<String?, FeedComment> commentsPagingController;

  final _stateSubject = BehaviorSubject<PostDetailState>.seeded(
    const PostDetailInitial(),
  );

  Stream<PostDetailState> get stateStream => _stateSubject.stream;
  PostDetailState get currentState => _stateSubject.value;

  FeedPostDetail? _initialDetail;
  Timer? _rateLimitTimer;
  bool _likeInFlight = false;

  void handleEvent(PostDetailEvent event) {
    switch (event) {
      case PostDetailInitRequested():
        init();
      case PostDetailRefreshRequested():
        refresh();
      case PostDetailLikeToggleRequested():
        toggleLike();
      case PostDetailCommentSubmitRequested(:final body):
        submitComment(body);
      case PostDetailCommentDeleteRequested(:final commentId):
        deleteComment(commentId);
    }
  }

  Future<void> _syncCommentAuthorProfile() async {
    final name = prefGetString(prefUserName).trim();
    if (name.isEmpty) return;
    final avatar = prefGetString(prefProfileImage).trim();
    try {
      await _repo.syncFeedProfile(
        displayName: name,
        avatarUrl: avatar.isNotEmpty ? avatar : null,
      );
    } catch (_) {
      // Non-fatal: comments still work; profile may update on next successful sync.
    }
  }

  Future<void> init() async {
    _emit(const PostDetailLoading());
    try {
      await _syncCommentAuthorProfile();
      final detail = await _repo.fetchPostDetail(postId);
      if (!state.mounted) return;
      _initialDetail = detail;
      _emit(PostDetailLoaded(post: detail));
      commentsPagingController.refresh();
    } catch (e) {
      _emit(PostDetailError(_messageForError(e)));
    }
  }

  Future<void> refresh() async {
    _initialDetail = null;
    commentsPagingController.refresh();
    await init();
  }

  Future<void> _onCommentsPageRequest(String? cursor) async {
    try {
      if (cursor == null && _initialDetail != null) {
        final detail = _initialDetail!;
        _initialDetail = null;
        final page = detail.comments;
        final isLast =
            page.nextCursor == null || page.nextCursor!.isEmpty;
        if (isLast) {
          commentsPagingController.appendLastPage(page.items);
        } else {
          commentsPagingController.appendPage(page.items, page.nextCursor);
        }
        return;
      }

      final page = await _repo.fetchPostComments(postId, cursor: cursor, limit: 20);
      if (!state.mounted) return;
      final isLast = page.nextCursor == null || page.nextCursor!.isEmpty;
      if (isLast) {
        commentsPagingController.appendLastPage(page.items);
      } else {
        commentsPagingController.appendPage(page.items, page.nextCursor);
      }
    } catch (e) {
      commentsPagingController.error = e;
    }
  }

  Future<void> toggleLike() async {
    final loaded = currentState;
    if (loaded is! PostDetailLoaded || _likeInFlight) return;

    final post = loaded.post;
    final like = !post.isLiked;
    _likeInFlight = true;
    _emit(loaded.copyWith(likeInFlight: true));

    final optimistic = _copyPost(
      post,
      isLiked: like,
      likeCount: post.likeCount + (like ? 1 : -1),
    );
    _emit(loaded.copyWith(post: optimistic, likeInFlight: true));

    try {
      final result =
          like ? await _repo.likePost(postId) : await _repo.unlikePost(postId);
      final cur = currentState;
      if (cur is PostDetailLoaded) {
        _emit(cur.copyWith(
          post: _copyPost(
            cur.post,
            isLiked: result.isLiked,
            likeCount: result.likeCount ?? cur.post.likeCount,
          ),
          likeInFlight: false,
        ));
      }
    } catch (e) {
      _emit(loaded.copyWith(post: post, likeInFlight: false));
      if (state.mounted) openSimpleSnackbar(_messageForError(e));
    } finally {
      _likeInFlight = false;
    }
  }

  Future<void> submitComment(String body) async {
    final loaded = currentState;
    if (loaded is! PostDetailLoaded) return;
    if (loaded.commentSending || loaded.isRateLimited) return;

    _emit(loaded.copyWith(commentSending: true));
    try {
      final displayName = prefGetString(prefUserName).trim();
      final avatarUrl = prefGetString(prefProfileImage).trim();
      final comment = await _repo.createComment(
        postId,
        body,
        displayName: displayName.isNotEmpty ? displayName : null,
        avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
      );
      final list = commentsPagingController.itemList ?? [];
      commentsPagingController.itemList = [comment, ...list];
      _emit(loaded.copyWith(
        post: _copyPost(
          loaded.post,
          commentCount: loaded.post.commentCount + 1,
        ),
        commentSending: false,
      ));
      onCommentSubmitted?.call();
    } on FeedProhibitedContentException {
      final cur = currentState;
      if (cur is PostDetailLoaded) {
        _emit(cur.copyWith(commentSending: false));
      }
      if (state.mounted) {
        openSimpleSnackbar(
          AppLocalizations.of(context)!.comment_prohibited_message,
        );
      }
      onCommentCleared?.call();
    } on FeedRateLimitException catch (e) {
      final until = _parseResetAt(e.resetAt);
      final cur = currentState;
      if (cur is PostDetailLoaded) {
        _emit(cur.copyWith(commentSending: false, rateLimitUntil: until));
      }
      _scheduleRateLimitClear(until);
      if (state.mounted) {
        openSimpleSnackbar(
          AppLocalizations.of(context)!.comment_rate_limit_message,
        );
      }
    } catch (e) {
      final cur = currentState;
      if (cur is PostDetailLoaded) {
        _emit(cur.copyWith(commentSending: false));
      }
      if (state.mounted) {
        openSimpleSnackbar(
          AppLocalizations.of(context)!.comment_send_failed,
        );
      }
    }
  }

  Future<void> deleteComment(String commentId) async {
    final list = commentsPagingController.itemList;
    if (list == null) return;
    final index = list.indexWhere((c) => c.id == commentId);
    if (index < 0) return;
    final removed = list[index];
    final updated = List<FeedComment>.from(list)..removeAt(index);
    commentsPagingController.itemList = updated;

    final loaded = currentState;
    if (loaded is PostDetailLoaded) {
      _emit(loaded.copyWith(
        post: _copyPost(
          loaded.post,
          commentCount: (loaded.post.commentCount - 1).clamp(0, 1 << 30),
        ),
      ));
    }

    try {
      final result = await _repo.deleteComment(commentId);
      final cur = currentState;
      if (cur is PostDetailLoaded) {
        _emit(cur.copyWith(
          post: _copyPost(cur.post, commentCount: result.postCommentCount),
        ));
      }
    } on FeedNotCommentAuthorException {
      _restoreComment(index, removed);
      if (state.mounted) {
        openSimpleSnackbar(
          AppLocalizations.of(context)!.comment_delete_not_author,
        );
      }
    } catch (e) {
      _restoreComment(index, removed);
      if (state.mounted) {
        openSimpleSnackbar(
          AppLocalizations.of(context)!.comment_delete_failed,
        );
      }
    }
  }

  void _restoreComment(int index, FeedComment comment) {
    final list = commentsPagingController.itemList ?? [];
    final updated = List<FeedComment>.from(list);
    final safeIndex = index.clamp(0, updated.length);
    updated.insert(safeIndex, comment);
    commentsPagingController.itemList = updated;
    final loaded = currentState;
    if (loaded is PostDetailLoaded) {
      _emit(loaded.copyWith(
        post: _copyPost(
          loaded.post,
          commentCount: loaded.post.commentCount + 1,
        ),
      ));
    }
  }

  void _scheduleRateLimitClear(DateTime? until) {
    _rateLimitTimer?.cancel();
    if (until == null) return;
    final delay = until.difference(DateTime.now());
    if (delay.isNegative) {
      _clearRateLimit();
      return;
    }
    _rateLimitTimer = Timer(delay, _clearRateLimit);
  }

  void _clearRateLimit() {
    final loaded = currentState;
    if (loaded is PostDetailLoaded) {
      _emit(loaded.copyWith(clearRateLimit: true));
    }
  }

  DateTime? _parseResetAt(int? resetAt) {
    if (resetAt == null) return null;
    if (resetAt > 1e12) {
      return DateTime.fromMillisecondsSinceEpoch(resetAt);
    }
    return DateTime.fromMillisecondsSinceEpoch(resetAt * 1000);
  }

  FeedPost _copyPost(
    FeedPost p, {
    bool? isLiked,
    int? likeCount,
    int? commentCount,
  }) {
    return FeedPost(
      id: p.id,
      store: p.store,
      caption: p.caption,
      locationName: p.locationName,
      media: p.media,
      likeCount: likeCount ?? p.likeCount,
      commentCount: commentCount ?? p.commentCount,
      isLiked: isLiked ?? p.isLiked,
      publishedAt: p.publishedAt,
    );
  }

  String _messageForError(Object e) {
    if (e is FeedApiException) return e.message;
    return AppLocalizations.of(context)!.feed_error_generic;
  }

  void _emit(PostDetailState next) {
    if (!_stateSubject.isClosed) _stateSubject.add(next);
  }

  VoidCallback? onCommentSubmitted;
  VoidCallback? onCommentCleared;

  @override
  void dispose() {
    _rateLimitTimer?.cancel();
    commentsPagingController.dispose();
    _stateSubject.close();
  }
}
