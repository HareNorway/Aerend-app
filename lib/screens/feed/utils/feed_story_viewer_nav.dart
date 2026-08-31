import 'package:flutter/material.dart';

import '../../../data/feed/feed_story.dart';
import '../storyViewer/story_viewer_screen.dart';

const Duration _storyViewerTransitionDuration = Duration(milliseconds: 320);

/// Full-screen story viewer with slide-up + fade transition.
void openFeedStoryViewer(
  BuildContext context, {
  required List<FeedStoreStories> stores,
  required int initialStoreIndex,
  int initialStoryIndex = 0,
}) {
  final filtered =
      stores.where((s) => s.stories.isNotEmpty).toList(growable: false);
  if (filtered.isEmpty) return;

  final targetId = stores[initialStoreIndex.clamp(0, stores.length - 1)].store.id;
  var storeIndex = filtered.indexWhere((s) => s.store.id == targetId);
  if (storeIndex < 0) storeIndex = 0;

  final stories = filtered[storeIndex].stories;
  final storyIndex = stories.isEmpty
      ? 0
      : initialStoryIndex.clamp(0, stories.length - 1);

  Navigator.of(context).push(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      opaque: true,
      transitionDuration: _storyViewerTransitionDuration,
      reverseTransitionDuration: _storyViewerTransitionDuration,
      pageBuilder: (_, __, ___) => StoryViewerScreen(
        stores: filtered,
        initialStoreIndex: storeIndex,
        initialStoryIndex: storyIndex,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}
