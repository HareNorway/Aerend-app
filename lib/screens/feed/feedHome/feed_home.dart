import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../data/feed/feed_post.dart';
import '../../../data/feed/feed_story.dart';
import '../../../data/feed/feed_tab_item.dart';
import '../../../networking/ops/ops_feed_api.dart';
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
import '../components/feed_empty_no_posts.dart';
import '../components/feed_error_state.dart';
import '../components/feed_login_gate.dart';
import '../components/feed_post_card.dart';
import '../components/feed_post_kebab_sheet.dart';
import '../components/feed_post_skeleton.dart';
import '../components/feed_publisher_tabs.dart';
import '../components/feed_stories_row.dart';
import '../components/feed_stories_skeleton.dart';
import '../components/feed_tab_card.dart';
import '../components/vaagen_card.dart';
import 'feed_home_bloc.dart';
import 'feed_home_event.dart';
import 'feed_home_state.dart';

class FeedHome extends StatefulWidget {
  const FeedHome({
    super.key,
    this.embedInShell = false,
    this.onExploreTap,
    this.showPublisherTabs = false,
    this.showVaagen = false,
    this.categoryFilter,
    this.onPostsLoaded,
    this.vaagenApi,
  });

  /// When true, omits the standalone [AppBar] (used inside [FeedShellScreen]).
  final bool embedInShell;

  /// Switches to the Explore tab in the feed shell; falls back to search screen.
  final VoidCallback? onExploreTap;

  /// Mount [FeedPublisherTabs] («Publisert av butikker» / «Publisert av
  /// Ærend») above the posts (feed update spec §3.1; AGIL-1 v2 Phase 2).
  final bool showPublisherTabs;

  /// Mount [VaagenCard] above the first post while today's pull is unspent.
  final bool showVaagen;

  /// Utforsk's shop filter chip. Applied to the Ærend tab's items by their
  /// `category`; the followed-stores feed carries no category per post.
  final String? categoryFilter;

  /// The first page of posts, once — the Utforsk unread badge counts them.
  final ValueChanged<List<FeedPost>>? onPostsLoaded;

  /// Injected in tests.
  final OpsFeedApi? vaagenApi;

  @override
  State<FeedHome> createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> {
  FeedHomeBloc? _bloc;
  final _scrollController = ScrollController();

  FeedPublisherTab _publisher = FeedPublisherTab.stores;
  List<FeedTabItem>? _aerendItems;
  bool _aerendLoading = false;
  bool? _vaagenAvailable;
  bool _vaagenPending = false;
  bool _postsReported = false;

  @override
  void initState() {
    super.initState();
    if (widget.showVaagen) _loadVaagen();
  }

  Future<void> _loadVaagen() async {
    final customerId = prefGetInt(prefUserId);
    if (customerId == 0) return;
    final available = await (widget.vaagenApi ?? OpsFeedApi()).vaagenAvailable(
      customerId,
    );
    if (!mounted) return;
    setState(() => _vaagenAvailable = available);
  }

  Future<void> _reelVaagen() async {
    final customerId = prefGetInt(prefUserId);
    if (customerId == 0 || _vaagenPending) return;
    setState(() => _vaagenPending = true);
    try {
      final result = await (widget.vaagenApi ?? OpsFeedApi()).reel(
        customerId: customerId,
      );
      if (!mounted) return;
      setState(() => _vaagenAvailable = !result.spent);
    } catch (_) {
      // Leave the card as it was: a failed pull is not a spent pull.
    } finally {
      if (mounted) setState(() => _vaagenPending = false);
    }
  }

  void _selectPublisher(FeedPublisherTab tab) {
    if (_publisher == tab) return;
    setState(() => _publisher = tab);
    if (tab == FeedPublisherTab.aerend && _aerendItems == null) {
      _loadAerendTab();
    }
  }

  Future<void> _loadAerendTab() async {
    final bloc = _bloc;
    if (bloc == null || _aerendLoading) return;
    setState(() => _aerendLoading = true);
    try {
      final page = await bloc.repo.fetchFeedTab(tab: 'fra_aerend', limit: 20);
      if (!mounted) return;
      setState(() => _aerendItems = page.items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _aerendItems = const <FeedTabItem>[]);
    } finally {
      if (mounted) setState(() => _aerendLoading = false);
    }
  }

  void _reportPosts() {
    if (_postsReported || widget.onPostsLoaded == null) return;
    final items = _bloc?.pagingController.itemList;
    if (items == null) return;
    _postsReported = true;
    widget.onPostsLoaded!(List<FeedPost>.unmodifiable(items));
  }

  List<FeedTabItem> get _filteredAerend {
    final items = _aerendItems ?? const <FeedTabItem>[];
    final filter = widget.categoryFilter;
    if (filter == null || filter.isEmpty) return items;
    return [
      for (final i in items)
        if ((i.category ?? '').toLowerCase() == filter.toLowerCase()) i,
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc == null) {
      _bloc = FeedHomeBloc(context, this);
      _bloc!.pagingController.addListener(_reportPosts);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openStoreProfile(FeedPost post) {
    openScreen(context, StoreProfileScreen(storeId: post.store.id));
  }

  void _openPostDetail(FeedPost post) {
    openScreen(context, PostDetailScreen(postId: post.id));
  }

  void _visitStore(FeedPost post) {
    final storeId = int.tryParse(post.store.id);
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.store_profile_visit_store_failed,
          ),
        ),
      );
      return;
    }
    openScreen(
      context,
      StoreDetail(storeId: storeId, storeName: post.store.name),
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
    return Scaffold(appBar: _feedAppBar(l10n), body: body);
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
      return const Scaffold(body: Center(child: FeedPostSkeleton()));
    }

    return StreamBuilder<FeedHomeState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const FeedHomeInitial();

        if (state is FeedHomeLoginRequired) {
          return _wrapBody(const FeedLoginGate(), l10n);
        }

        if (state is FeedHomeError && bloc.pagingController.itemList == null) {
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
        final storyLetter = userName.isNotEmpty
            ? userName[0].toUpperCase()
            : '?';

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
                          yourStoryAvatarUrl: profileImage.isNotEmpty
                              ? profileImage
                              : null,
                          yourStoryFallbackLetter: storyLetter,
                          onYourStoryTap: () =>
                              _stubSnack(l10n.feed_coming_soon),
                          onStoreStoriesTap: (entry) =>
                              _openStories(entry, stories),
                        ),
                ),
                if (widget.showPublisherTabs)
                  SliverToBoxAdapter(
                    child: FeedPublisherTabs(
                      active: _publisher,
                      onSelected: _selectPublisher,
                    ),
                  ),
                if (widget.showVaagen && _vaagenAvailable != null)
                  SliverToBoxAdapter(
                    child: VaagenCard(
                      available: _vaagenAvailable!,
                      pending: _vaagenPending,
                      onReel: _vaagenAvailable! ? _reelVaagen : null,
                    ),
                  ),
                if (_publisher == FeedPublisherTab.aerend)
                  _aerendLoading && _aerendItems == null
                      ? const SliverToBoxAdapter(child: FeedPostSkeleton())
                      : SliverList.builder(
                          key: const Key('feed_aerend_tab_list'),
                          itemCount: _filteredAerend.length,
                          itemBuilder: (context, i) => FeedTabCard(
                            item: _filteredAerend[i],
                            onTap: () => openScreen(
                              context,
                              PostDetailScreen(postId: _filteredAerend[i].id),
                            ),
                          ),
                        )
                else
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
                      // Two different empty feeds, two different answers (T4).
                      // `hasFollows == true` means the shops they follow simply
                      // have not posted, and pushing them to follow more would
                      // read as the app not listening. Unknown falls back to the
                      // CTA — the safer of the two wrong answers.
                      noItemsFoundIndicatorBuilder: (_) =>
                          (loaded?.hasFollows ?? false)
                          ? const FeedEmptyNoPosts()
                          : FeedEmptyFollowed(onExploreTap: _openSearch),
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
