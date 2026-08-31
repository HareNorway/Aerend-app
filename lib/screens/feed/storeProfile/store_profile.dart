import 'package:flutter/material.dart';


import '../../../data/feed/feed_post.dart';
import '../../../data/feed/feed_store.dart';
import '../../../data/feed/feed_store_profile.dart';
import '../../../data/feed/feed_story.dart';
import '../../../l10n/app_localizations.dart';
import '../../deliveryService/storeDetail/store_detail.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../components/feed_error_state.dart';
import '../components/feed_post_grid.dart';
import '../components/feed_post_thumbnail.dart';
import '../components/feed_store_profile_header.dart';
import '../postDetail/post_detail.dart';
import '../utils/feed_story_viewer_nav.dart';
import 'store_profile_bloc.dart';
import 'store_profile_event.dart';
import 'store_profile_state.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeId;
  final FeedStoreProfile? previewProfile;

  const StoreProfileScreen({
    super.key,
    required this.storeId,
    this.previewProfile,
  });

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  StoreProfileBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc == null && widget.previewProfile == null) {
      _bloc = StoreProfileBloc(context, this, widget.storeId);
      _bloc!.handleEvent(const StoreProfileInitRequested());
    }
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  void _openPost(FeedPost post) {
    openScreen(
      context,
      PostDetailScreen(postId: post.id),
    );
  }

  void _stubReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.feedReportComingSoon)),
    );
  }

  void _openStoreDetails(FeedStoreProfile profile) {
    final storeId = int.tryParse(profile.id);
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
        storeName: profile.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewProfile != null) {
      return _StoreProfileBody(
        profile: widget.previewProfile!,
        stories: const [],
        bloc: null,
        onFollowTap: () {},
        onVisitStoreTap: () => _openStoreDetails(widget.previewProfile!),
        onPostTap: _openPost,
        onReportTap: _stubReport,
      );
    }

    final bloc = _bloc;
    if (bloc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<StoreProfileState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const StoreProfileInitial();
        final l10n = AppLocalizations.of(context)!;

        if (state is StoreProfileLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                l10n.store_profile_loading,
                style: aeBody(color: ScSaasThemeTokens.muted),
              ),
            ),
          );
        }

        if (state is StoreProfileError) {
          return Scaffold(
            appBar: AppBar(),
            body: FeedErrorState(
              message: l10n.store_profile_error,
              onRetry: () =>
                  bloc.handleEvent(const StoreProfileRefreshRequested()),
            ),
          );
        }

        if (state is! StoreProfileLoaded) {
          return const SizedBox.shrink();
        }

        return _StoreProfileBody(
          profile: state.profile,
          stories: state.stories,
          bloc: bloc,
          followInFlight: state.followInFlight,
          visitInFlight: state.visitInFlight,
          onFollowTap: () =>
              bloc.handleEvent(const StoreProfileFollowToggleRequested()),
          onVisitStoreTap: () => _openStoreDetails(state.profile),
          onPostTap: _openPost,
          onReportTap: _stubReport,
        );
      },
    );
  }
}

class _StoreProfileBody extends StatelessWidget {
  final FeedStoreProfile profile;
  final List<FeedStory> stories;
  final StoreProfileBloc? bloc;
  final bool followInFlight;
  final bool visitInFlight;
  final VoidCallback onFollowTap;
  final VoidCallback onVisitStoreTap;
  final void Function(FeedPost post) onPostTap;
  final VoidCallback onReportTap;

  const _StoreProfileBody({
    required this.profile,
    required this.stories,
    required this.bloc,
    required this.onFollowTap,
    required this.onVisitStoreTap,
    required this.onPostTap,
    required this.onReportTap,
    this.followInFlight = false,
    this.visitInFlight = false,
  });

  void _openStories(BuildContext context) {
    if (stories.isEmpty) return;
    openFeedStoryViewer(
      context,
      stores: [
        FeedStoreStories(
          store: FeedStore(
            id: profile.id,
            name: profile.name,
            slug: profile.slug,
            logoUrl: profile.logoUrl,
            isFollowing: profile.isFollowing,
          ),
          stories: stories,
        ),
      ],
      initialStoreIndex: 0,
      initialStoryIndex: 0,
    );
  }

  Future<void> _onRefresh() async {
    bloc?.handleEvent(const StoreProfileRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      appBar: AppBar(
        backgroundColor: ScSaasThemeTokens.card,
        elevation: 0,
        foregroundColor: ScSaasThemeTokens.text,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          profile.name,
          style: aeH3(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onReportTap,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: ScSaasThemeTokens.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FeedStoreProfileHeader(
                profile: profile,
                followInFlight: followInFlight,
                visitInFlight: visitInFlight,
                onFollowTap: onFollowTap,
                onVisitStoreTap: onVisitStoreTap,
                onStoryTap: profile.hasActiveStories
                    ? () => _openStories(context)
                    : null,
              ),
            ),
            const SliverToBoxAdapter(child: FeedPostsGridDivider()),
            if (bloc != null)
              FeedPostSliverGrid(
                pagingController: bloc!.postsPagingController,
                onPostTap: onPostTap,
              )
            else
              const SliverFillRemaining(
                hasScrollBody: false,
                child: SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
