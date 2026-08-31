import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../blocs/bloc.dart';
import '../../../data/feed/feed_post.dart';
import '../../../data/feed/feed_store_profile.dart';
import '../../../exceptions/feed/feed_api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../utils/utils.dart';
import 'store_profile_event.dart';
import 'store_profile_state.dart';

class StoreProfileBloc extends Bloc {
  StoreProfileBloc(
    this.context,
    this.state,
    this.storeId, {
    FeedRepo? repo,
  }) : _repo = repo ?? FeedRepo() {
    postsPagingController =
        PagingController<String?, FeedPost>(firstPageKey: null);
    postsPagingController.addPageRequestListener(_onPostsPageRequest);
    _stateSubject.add(const StoreProfileInitial());
  }

  final BuildContext context;
  final State state;
  final String storeId;
  final FeedRepo _repo;

  late final PagingController<String?, FeedPost> postsPagingController;

  final _stateSubject = BehaviorSubject<StoreProfileState>.seeded(
    const StoreProfileInitial(),
  );

  Stream<StoreProfileState> get stateStream => _stateSubject.stream;
  StoreProfileState get currentState => _stateSubject.value;

  FeedStoreProfile? _profile;

  void handleEvent(StoreProfileEvent event) {
    switch (event) {
      case StoreProfileInitRequested():
        init();
      case StoreProfileRefreshRequested():
        refresh();
      case StoreProfileFollowToggleRequested():
        toggleFollow();
      case StoreProfileVisitStoreRequested():
        visitStore();
    }
  }

  Future<void> init() async {
    _emit(const StoreProfileLoading());
    try {
      final profile = await _repo.fetchStoreProfile(storeId);
      _profile = profile;
      _emit(StoreProfileLoaded(
        profile: profile,
        storiesLoading: profile.hasActiveStories,
      ));
      if (profile.hasActiveStories) {
        await _loadStories();
      }
      postsPagingController.refresh();
    } catch (e) {
      _emit(StoreProfileError(_messageForError(e)));
    }
  }

  Future<void> refresh() async {
    if (_profile == null) {
      await init();
      return;
    }
    final loaded = currentState;
    if (loaded is StoreProfileLoaded && loaded.profile.hasActiveStories) {
      _emit(loaded.copyWith(storiesLoading: true));
      await _loadStories();
    }
    postsPagingController.refresh();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _repo.fetchStoreStories(storeId);
      final loaded = currentState;
      if (loaded is StoreProfileLoaded) {
        _emit(loaded.copyWith(stories: stories, storiesLoading: false));
      }
    } catch (_) {
      final loaded = currentState;
      if (loaded is StoreProfileLoaded) {
        _emit(loaded.copyWith(storiesLoading: false));
      }
    }
  }

  Future<void> _onPostsPageRequest(String? cursor) async {
    try {
      final page = await _repo.fetchStorePosts(storeId, cursor: cursor, limit: 21);
      if (!state.mounted) return;
      final isLast = page.nextCursor == null || page.nextCursor!.isEmpty;
      if (isLast) {
        postsPagingController.appendLastPage(page.items);
      } else {
        postsPagingController.appendPage(page.items, page.nextCursor);
      }
    } catch (e) {
      postsPagingController.error = e;
    }
  }

  Future<void> toggleFollow() async {
    final loaded = currentState;
    if (loaded is! StoreProfileLoaded) return;
    if (loaded.followInFlight) return;

    final profile = loaded.profile;
    final wasFollowing = profile.isFollowing;
    final optimistic = profile.copyWith(
      isFollowing: !wasFollowing,
      followerCount: profile.followerCount + (wasFollowing ? -1 : 1),
    );
    _profile = optimistic;
    _emit(loaded.copyWith(profile: optimistic, followInFlight: true));

    try {
      final result = wasFollowing
          ? await _repo.unfollowStore(storeId)
          : await _repo.followStore(storeId);
      final updated = optimistic.copyWith(
        isFollowing: result.isFollowing,
        followerCount: result.followerCount ?? optimistic.followerCount,
      );
      _profile = updated;
      _emit(loaded.copyWith(profile: updated, followInFlight: false));
    } catch (e) {
      _profile = profile;
      _emit(loaded.copyWith(profile: profile, followInFlight: false));
      if (state.mounted) openSimpleSnackbar(_messageForError(e));
    }
  }

  Future<void> visitStore() async {
    final loaded = currentState;
    if (loaded is! StoreProfileLoaded || loaded.visitInFlight) return;
    _emit(loaded.copyWith(visitInFlight: true));

    try {
      final posts = postsPagingController.itemList;
      final postId = posts != null && posts.isNotEmpty ? posts.first.id : null;
      if (postId == null) {
        if (state.mounted) {
          openSimpleSnackbar(
            AppLocalizations.of(context)!.store_profile_visit_store_failed,
          );
        }
        return;
      }
      final cta = await _repo.resolveCta(postId);
      await openUrl(cta.webUrl);
    } catch (e) {
      if (state.mounted) {
        openSimpleSnackbar(
          AppLocalizations.of(context)!.store_profile_visit_store_failed,
        );
      }
    } finally {
      final cur = currentState;
      if (cur is StoreProfileLoaded) {
        _emit(cur.copyWith(visitInFlight: false));
      }
    }
  }

  String _messageForError(Object e) {
    if (e is FeedApiException) return e.message;
    return AppLocalizations.of(context)!.feed_error_generic;
  }

  void _emit(StoreProfileState next) {
    if (!_stateSubject.isClosed) _stateSubject.add(next);
  }

  @override
  void dispose() {
    postsPagingController.dispose();
    _stateSubject.close();
  }
}

extension on FeedStoreProfile {
  FeedStoreProfile copyWith({
    bool? isFollowing,
    int? followerCount,
  }) {
    return FeedStoreProfile(
      id: id,
      name: name,
      slug: slug,
      logoUrl: logoUrl,
      coverUrl: coverUrl,
      isActive: isActive,
      isSportsClub: isSportsClub,
      isFollowing: isFollowing ?? this.isFollowing,
      followerCount: followerCount ?? this.followerCount,
      postCount: postCount,
      bio: bio,
      description: description,
      hasActiveStories: hasActiveStories,
      deeplinkPath: deeplinkPath,
    );
  }
}
