import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../data/feed/feed_post.dart';
import '../../../data/feed/feed_story.dart';
import '../../../l10n/app_localizations.dart';
import '../../deliveryService/storeDetail/store_detail.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../utils/utils.dart';
import '../postDetail/post_detail.dart';
import '../search/feed_search_screen.dart';
import '../storeProfile/store_profile.dart';
import '../utils/feed_story_viewer_nav.dart';
import '../components/feed_empty_followed.dart';
import '../components/feed_error_state.dart';
import '../components/feed_login_gate.dart';
import '../components/feed_post_card.dart';
import '../components/feed_post_kebab_sheet.dart';
import '../components/feed_post_skeleton.dart';
import '../components/feed_stories_row.dart';
import '../components/feed_stories_skeleton.dart';
import 'feed_home_bloc.dart';
import 'feed_home_event.dart';
import 'feed_home_state.dart';

class FeedHome extends StatefulWidget {
  const FeedHome({
    super.key,
    this.embedInShell = false,
    this.onExploreTap,
  });

  /// When true, omits the standalone [AppBar] (used inside [FeedShellScreen]).
  final bool embedInShell;

  /// Switches to the Explore tab in the feed shell; falls back to search screen.
  final VoidCallback? onExploreTap;

  @override
  State<FeedHome> createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> {
  FeedHomeBloc? _bloc;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc == null) {
      _bloc = FeedHomeBloc(context, this);
      _bloc!.handleEvent(const FeedHomeInitRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bloc?.dispose();
    super.dispose();
  }

  void _stubSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openStoreProfile(FeedPost post) {
    openScreen(
      context,
      StoreProfileScreen(storeId: post.store.id),
    );
  }

  void _openPostDetail(FeedPost post) {
    openScreen(
      context,
      PostDetailScreen(postId: post.id),
    );
  }

  void _visitStore(FeedPost post) {
    final storeId = int.tryParse(post.store.id);
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.store_profile_visit_store_failed),
        ),
      );
      return;
    }
    openScreen(
      context,
      StoreDetail(
        storeId: storeId,
        storeName: post.store.name,
      ),
    );
  }

  void _openSearch() {
    final exploreTap = widget.onExploreTap;
    if (exploreTap != null) {
      exploreTap();
      return;
    }
    openScreen(context, const FeedSearchScreen());
  }

  void _openStories(FeedStoreStories entry, List<FeedStoreStories> all) {
    if (entry.stories.isEmpty) return;
    final index = all.indexWhere((s) => s.store.id == entry.store.id);
    openFeedStoryViewer(
      context,
      stores: all,
      initialStoreIndex: index < 0 ? 0 : index,
    );
  }

  PreferredSizeWidget? _feedAppBar(AppLocalizations l10n) {
    if (widget.embedInShell) return null;
    return AppBar(
      title: Text(l10n.feed_tab_label),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 24),
          tooltip: l10n.search_stores_hint,
          onPressed: _openSearch,
        ),
      ],
    );
  }

  Widget _wrapBody(Widget body, AppLocalizations l10n) {
    if (widget.embedInShell) {
      return body;
    }
    return Scaffold(
      appBar: _feedAppBar(l10n),
      body: body,
    );
  }

  void _showKebab(FeedPost post) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => FeedPostKebabSheet(postId: post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = _bloc;
    if (bloc == null) {
      return const Scaffold(
        body: Center(child: FeedPostSkeleton()),
      );
    }

    return StreamBuilder<FeedHomeState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const FeedHomeInitial();

        if (state is FeedHomeLoginRequired) {
          return _wrapBody(const FeedLoginGate(), l10n);
        }

        if (state is FeedHomeError &&
            bloc.pagingController.itemList == null) {
          return _wrapBody(
            FeedErrorState(
              message: state.message,
              onRetry: () => bloc.handleEvent(const FeedHomeInitRequested()),
            ),
            l10n,
          );
        }

        if (state is FeedHomeLoading &&
            bloc.pagingController.itemList == null) {
          return _wrapBody(
            CustomScrollView(
              controller: _scrollController,
              slivers: const [
                SliverToBoxAdapter(child: FeedStoriesSkeleton()),
                SliverToBoxAdapter(child: FeedPostSkeleton()),
                SliverToBoxAdapter(child: FeedPostSkeleton()),
              ],
            ),
            l10n,
          );
        }

        final loaded = state is FeedHomeLoaded ? state : null;
        final stories = loaded?.stories ?? const <FeedStoreStories>[];
        final storiesLoading = loaded?.storiesLoading ?? false;
        final likeInFlight = loaded?.likeInFlight ?? const <String>{};
        final profileImage = prefGetString(prefProfileImage).trim();
        final userName = prefGetString(prefUserName).trim();
        final storyLetter =
            userName.isNotEmpty ? userName[0].toUpperCase() : '?';

        return _wrapBody(
          RefreshIndicator(
            color: ScSaasThemeTokens.primary,
            onRefresh: () => bloc.refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: storiesLoading
                      ? const FeedStoriesSkeleton()
                      : FeedStoriesRow(
                          storeStories: stories,
                          yourStoryAvatarUrl:
                              profileImage.isNotEmpty ? profileImage : null,
                          yourStoryFallbackLetter: storyLetter,
                          onYourStoryTap: () => _stubSnack(l10n.feed_coming_soon),
                          onStoreStoriesTap: (entry) =>
                              _openStories(entry, stories),
                        ),
                ),
                PagedSliverList<String?, FeedPost>(
                  pagingController: bloc.pagingController,
                  builderDelegate: PagedChildBuilderDelegate<FeedPost>(
                    itemBuilder: (context, post, index) => FeedPostCard(
                      post: post,
                      isLikeInFlight: likeInFlight.contains(post.id),
                      onLikeTap: () => bloc.onLikeTap(post),
                      onStoreTap: () => _openStoreProfile(post),
                      onCommentsTap: () => _openPostDetail(post),
                      onVisitStoreTap: () => _visitStore(post),
                      onKebabTap: () => _showKebab(post),
                    ),
                    firstPageProgressIndicatorBuilder: (_) =>
                        const FeedPostSkeleton(),
                    newPageProgressIndicatorBuilder: (_) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: CommonCircularProgressIndicator(
                          color: ScSaasThemeTokens.primary,
                          size: 28,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    firstPageErrorIndicatorBuilder: (_) => FeedErrorState(
                      message: l10n.feed_error_generic,
                      onRetry: () => bloc.pagingController.refresh(),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => FeedEmptyFollowed(
                      onExploreTap: _openSearch,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          ),
          l10n,
        );
      },
    );
  }
}
