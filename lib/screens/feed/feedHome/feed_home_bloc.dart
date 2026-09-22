import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../blocs/bloc.dart';
import '../../../data/feed/feed_post.dart';
import '../../../exceptions/feed/feed_api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../services/feed_jwt_service.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart';
import 'feed_home_event.dart';
import 'feed_home_state.dart';

class FeedHomeBloc extends Bloc {
  FeedHomeBloc(
    this.context,
    this.state, {
    FeedRepo? repo,
    FeedJwtService? jwtService,
  })  : _repo = repo ?? FeedRepo(),
        _jwtService = jwtService ?? FeedJwtService.instance {
    pagingController = PagingController<String?, FeedPost>(firstPageKey: null);
    pagingController.addPageRequestListener(_onPageRequest);
    _stateSubject.add(const FeedHomeInitial());
  }

  final BuildContext context;
  final State state;
  final FeedRepo _repo;
  final FeedJwtService _jwtService;

  late final PagingController<String?, FeedPost> pagingController;

  final _stateSubject = BehaviorSubject<FeedHomeState>.seeded(
    const FeedHomeInitial(),
  );

  Stream<FeedHomeState> get stateStream => _stateSubject.stream;

  FeedHomeState get currentState => _stateSubject.value;

  final Set<String> _likeInFlight = {};
  bool _sessionReady = false;

  void handleEvent(FeedHomeEvent event) {
    switch (event) {
      case FeedHomeInitRequested():
        init();
      case FeedHomeRefreshRequested():
        refresh();
      case FeedHomeLikeToggle(:final postId):
        _toggleLike(postId, like: true);
      case FeedHomeUnlikeToggle(:final postId):
        _toggleLike(postId, like: false);
    }
  }

  Future<void> init() async {
    _emit(const FeedHomeLoading());
    try {
      await _jwtService.getValidToken();
      final name = prefGetString(prefUserName).trim();
      final avatar = prefGetString(prefProfileImage).trim();
      if (name.isNotEmpty) {
        try {
          await _repo.syncFeedProfile(
            displayName: name,
            avatarUrl: avatar.isNotEmpty ? avatar : null,
          );
        } catch (_) {}
      }
    } on FeedJwtUnauthenticatedException {
      _emit(const FeedHomeLoginRequired());
      return;
    } catch (e) {
      _emit(FeedHomeError(_messageForError(e)));
      return;
    }

    _sessionReady = true;
    _emit(FeedHomeLoaded(stories: const [], storiesLoading: true));
    await _loadStories();
    await _loadFollowingCount();
    pagingController.refresh();
  }

  /// Fetch the follow count so an empty feed can be explained correctly.
  ///
  /// A failure here leaves `hasFollows` null rather than guessing. Null falls
  /// back to the Explore call to action, which is the safer of the two wrong
  /// answers: offering a way forward beats telling someone who follows nobody
  /// to wait for posts that can never arrive.
  Future<void> _loadFollowingCount() async {
    try {
      final count = await _repo.fetchFollowingCount();
      if (!state.mounted) return;
      final loaded = currentState;
      if (loaded is FeedHomeLoaded) {
        _emit(loaded.copyWith(hasFollows: count > 0));
      }
    } catch (_) {
      // Left unknown on purpose; see above.
    }
  }

  Future<void> refresh() async {
    if (!_sessionReady) {
      await init();
      return;
    }
    final loaded = currentState;
    if (loaded is FeedHomeLoaded) {
      _emit(loaded.copyWith(storiesLoading: true));
    }
    await _loadStories();
    // Re-read on pull-to-refresh: a customer may have followed a shop since.
    await _loadFollowingCount();
    pagingController.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _loadStories() async {
    try {
      final feed = await _repo.fetchFollowedStories();
      if (!state.mounted) return;
      final loaded = currentState;
      if (loaded is FeedHomeLoaded) {
        _emit(loaded.copyWith(
          stories: feed.items,
          storiesLoading: false,
        ));
      }
    } catch (e) {
      if (!state.mounted) return;
      if (_handleAuthFailure(e)) return;
      final loaded = currentState;
      if (loaded is FeedHomeLoaded) {
        _emit(loaded.copyWith(storiesLoading: false));
      }
    }
  }

  Future<void> _onPageRequest(String? cursor) async {
    try {
      final page = await _repo.fetchFeed(cursor: cursor, limit: 20);
      if (!state.mounted) return;

      final isLastPage = page.nextCursor == null || page.nextCursor!.isEmpty;
      if (isLastPage) {
        pagingController.appendLastPage(page.items);
      } else {
        pagingController.appendPage(page.items, page.nextCursor);
      }

      if (cursor == null) {
        final prior =
            currentState is FeedHomeLoaded ? currentState as FeedHomeLoaded : null;
        _emit(FeedHomeLoaded(
          stories: prior?.stories ?? const [],
          storiesLoading: prior?.storiesLoading ?? false,
          likeInFlight: Set.unmodifiable(_likeInFlight),
          // Carried over rather than rebuilt: losing it here would make the
          // first page's empty state fall back to the wrong copy.
          hasFollows: prior?.hasFollows,
        ));
      } else if (currentState is FeedHomeLoaded) {
        _emit((currentState as FeedHomeLoaded)
            .copyWith(likeInFlight: Set.unmodifiable(_likeInFlight)));
      }
    } catch (e) {
      if (!state.mounted) return;
      if (_handleAuthFailure(e)) return;
      pagingController.error = e;
      _emit(FeedHomeError(_messageForError(e)));
    }
  }

  Future<void> _toggleLike(String postId, {required bool like}) async {
    if (_likeInFlight.contains(postId)) return;
    final items = pagingController.itemList;
    if (items == null) return;
    final index = items.indexWhere((p) => p.id == postId);
    if (index < 0) return;

    final original = items[index];
    if (original.isLiked == like) return;

    _likeInFlight.add(postId);
    _syncLoadedLikeInFlight();

    final optimistic = _copyPost(
      original,
      isLiked: like,
      likeCount: original.likeCount + (like ? 1 : -1),
    );
    _replacePostAt(index, optimistic);

    try {
      final result =
          like ? await _repo.likePost(postId) : await _repo.unlikePost(postId);
      final current = pagingController.itemList;
      final idx = current?.indexWhere((p) => p.id == postId) ?? -1;
      if (idx >= 0 && current != null) {
        _replacePostAt(
          idx,
          _copyPost(
            current[idx],
            isLiked: result.isLiked,
            likeCount: result.likeCount ?? current[idx].likeCount,
          ),
        );
      }
    } catch (e) {
      final current = pagingController.itemList;
      final idx = current?.indexWhere((p) => p.id == postId) ?? -1;
      if (idx >= 0) {
        _replacePostAt(idx, original);
      }
      if (state.mounted) {
        openSimpleSnackbar(_messageForError(e));
      }
      if (_handleAuthFailure(e)) return;
    } finally {
      _likeInFlight.remove(postId);
      _syncLoadedLikeInFlight();
    }
  }

  void onLikeTap(FeedPost post) {
    if (post.isLiked) {
      handleEvent(FeedHomeUnlikeToggle(post.id));
    } else {
      handleEvent(FeedHomeLikeToggle(post.id));
    }
  }

  bool _handleAuthFailure(Object e) {
    if (e is FeedJwtUnauthenticatedException) {
      _emit(const FeedHomeLoginRequired());
      return true;
    }
    if (e is FeedAuthMissingException ||
        e is FeedAuthInvalidException ||
        e is FeedAuthExpiredException) {
      if (state.mounted) {
        logout(context);
      }
      return true;
    }
    return false;
  }

  String _messageForError(Object e) {
    if (e is FeedApiException) return e.message;
    return AppLocalizations.of(context)!.feed_error_generic;
  }

  void _replacePostAt(int index, FeedPost post) {
    final list = pagingController.itemList;
    if (list == null) return;
    final updated = List<FeedPost>.from(list);
    updated[index] = post;
    pagingController.itemList = updated;
  }

  FeedPost _copyPost(
    FeedPost p, {
    bool? isLiked,
    int? likeCount,
  }) {
    return FeedPost(
      id: p.id,
      store: p.store,
      caption: p.caption,
      locationName: p.locationName,
      media: p.media,
      likeCount: likeCount ?? p.likeCount,
      commentCount: p.commentCount,
      isLiked: isLiked ?? p.isLiked,
      publishedAt: p.publishedAt,
    );
  }

  void _emit(FeedHomeState next) {
    if (!_stateSubject.isClosed) {
      _stateSubject.add(next);
    }
  }

  void _syncLoadedLikeInFlight() {
    if (currentState is FeedHomeLoaded) {
      _emit((currentState as FeedHomeLoaded)
          .copyWith(likeInFlight: Set.unmodifiable(_likeInFlight)));
    }
  }

  @override
  void dispose() {
    pagingController.dispose();
    _stateSubject.close();
  }
}
