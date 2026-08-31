import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../data/feed/feed_post.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import 'feed_post_thumbnail.dart';

class FeedPostGrid extends StatelessWidget {
  final PagingController<String?, FeedPost> pagingController;
  final void Function(FeedPost post) onPostTap;

  const FeedPostGrid({
    super.key,
    required this.pagingController,
    required this.onPostTap,
  });

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 3,
    mainAxisSpacing: 3,
    childAspectRatio: 1,
  );

  static PagedChildBuilderDelegate<FeedPost> _delegate(
    BuildContext context,
    void Function(FeedPost post) onPostTap,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return PagedChildBuilderDelegate<FeedPost>(
      itemBuilder: (context, post, index) => FeedPostThumbnail(
        post: post,
        onTap: () => onPostTap(post),
      ),
      firstPageProgressIndicatorBuilder: (_) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: ScSaasThemeTokens.primary),
        ),
      ),
      noItemsFoundIndicatorBuilder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            l10n.store_profile_no_posts,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ScSaasThemeTokens.muted),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedGridView<String?, FeedPost>(
      pagingController: pagingController,
      gridDelegate: _gridDelegate,
      builderDelegate: _delegate(context, onPostTap),
    );
  }
}

class FeedPostSliverGrid extends StatelessWidget {
  final PagingController<String?, FeedPost> pagingController;
  final void Function(FeedPost post) onPostTap;

  const FeedPostSliverGrid({
    super.key,
    required this.pagingController,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      sliver: PagedSliverGrid<String?, FeedPost>(
        pagingController: pagingController,
        gridDelegate: FeedPostGrid._gridDelegate,
        builderDelegate: FeedPostGrid._delegate(context, onPostTap),
      ),
    );
  }
}
