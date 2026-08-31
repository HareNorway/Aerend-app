import 'dart:async';

import 'package:flutter/material.dart';


import '../../../data/feed/feed_story.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../../utils/utils.dart';
import '../components/feed_avatar.dart';
import '../components/feed_story_progress_bars.dart';
import '../storeProfile/store_profile.dart';
import '../utils/feed_image.dart';
import '../utils/feed_time_ago.dart';

const Duration _kStoryDuration = Duration(seconds: 5);

class StoryViewerScreen extends StatefulWidget {
  final List<FeedStoreStories> stores;
  final int initialStoreIndex;
  final int initialStoryIndex;

  const StoryViewerScreen({
    super.key,
    required this.stores,
    required this.initialStoreIndex,
    this.initialStoryIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late final PageController _storeController;
  late int _storeIndex;
  late int _storyIndex;
  late AnimationController _progressController;
  Timer? _advanceTimer;
  bool _paused = false;
  double _dragDown = 0;

  FeedStoreStories get _currentEntry => widget.stores[_storeIndex];
  List<FeedStory> get _stories => _currentEntry.stories;
  FeedStory? get _currentStory =>
      _stories.isEmpty ? null : _stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _storeIndex = widget.initialStoreIndex.clamp(0, widget.stores.length - 1);
    _storyIndex = widget.initialStoryIndex;
    if (_stories.isNotEmpty) {
      _storyIndex = _storyIndex.clamp(0, _stories.length - 1);
    } else {
      _storyIndex = 0;
    }
    _storeController = PageController(initialPage: _storeIndex);
    _progressController = AnimationController(vsync: this, duration: _kStoryDuration)
      ..addStatusListener(_onProgressStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStoryTimer());
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _progressController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_paused && mounted) {
      _advance();
    }
  }

  void _startStoryTimer() {
    _advanceTimer?.cancel();
    if (_stories.isEmpty || _paused) return;
    _progressController.stop();
    _progressController.value = 0;
    _progressController.forward(from: 0);
  }

  void _pause() {
    if (_paused) return;
    setState(() => _paused = true);
    _advanceTimer?.cancel();
    _progressController.stop();
  }

  void _resume() {
    if (!_paused) return;
    setState(() => _paused = false);
    _progressController.forward();
  }

  void _advance() {
    if (_storyIndex < _stories.length - 1) {
      setState(() => _storyIndex++);
      _startStoryTimer();
      return;
    }
    if (_storeIndex < widget.stores.length - 1) {
      _goToStore(_storeIndex + 1, storyIndex: 0);
      return;
    }
    Navigator.of(context).pop();
  }

  void _rewind() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _startStoryTimer();
      return;
    }
    if (_storeIndex > 0) {
      final prev = widget.stores[_storeIndex - 1];
      _goToStore(_storeIndex - 1, storyIndex: prev.stories.isEmpty ? 0 : prev.stories.length - 1);
    }
  }

  void _goToStore(int index, {required int storyIndex}) {
    if (index < 0 || index >= widget.stores.length) return;
    setState(() {
      _storeIndex = index;
      _storyIndex = storyIndex;
      final len = widget.stores[index].stories.length;
      if (len > 0) _storyIndex = _storyIndex.clamp(0, len - 1);
    });
    _storeController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _startStoryTimer();
  }

  void _openStore() {
    final storeId = _currentEntry.store.id;
    Navigator.of(context).pop();
    openScreen(context, StoreProfileScreen(storeId: storeId));
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final story = _currentStory;
    final mediaUrl = story != null
        ? story.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName)
        : '';
    final timeLabel = story != null ? feedTimeAgo(story.createdAt, context) : '';
    final store = _currentEntry.store;
    final letter =
        store.name.isNotEmpty ? store.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onVerticalDragUpdate: (d) {
              if (d.delta.dy > 0) {
                setState(() => _dragDown += d.delta.dy);
              }
            },
            onVerticalDragEnd: (d) {
              final velocity = d.primaryVelocity ?? 0;
              if (_dragDown > 80 || velocity > 400) {
                _dismiss();
              } else if (velocity < -400) {
                _openStore();
              }
              setState(() => _dragDown = 0);
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _storeController,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.stores.length,
              onPageChanged: (i) {
                setState(() {
                  _storeIndex = i;
                  _storyIndex = 0;
                  final len = widget.stores[i].stories.length;
                  if (len > 0) _storyIndex = 0;
                });
                _startStoryTimer();
              },
              itemBuilder: (context, index) {
                if (index != _storeIndex) {
                  return const ColoredBox(color: Colors.black);
                }
                return story != null
                    ? FeedImage(url: mediaUrl, fit: BoxFit.cover)
                    : const ColoredBox(color: Colors.black);
              },
            ),
          ),
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            bottom: 140,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _rewind,
                    onLongPressStart: (_) => _pause(),
                    onLongPressEnd: (_) => _resume(),
                    onLongPressCancel: _resume,
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _advance,
                    onLongPressStart: (_) => _pause(),
                    onLongPressEnd: (_) => _resume(),
                    onLongPressCancel: _resume,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) => FeedStoryProgressBars(
                      storyCount: _stories.length,
                      currentIndex: _storyIndex,
                      currentProgress: _progressController.value,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const Key('story_viewer_close'),
                      tooltip: l10n.story_viewer_close,
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: _dismiss,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FeedAvatar(
                      imageUrl: store.logoUrl,
                      fallbackLetter: letter,
                      radius: 18,
                      backgroundColor: Colors.white24,
                      fallbackTextColor: Colors.white,
                      useLetterFallback: true,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            store.name,
                            style: aeTitle(color: Colors.white).copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (timeLabel.isNotEmpty)
                            Text(
                              timeLabel,
                              style: aeCaption(color: Colors.white70),
                            ),
                          if (story?.caption != null &&
                              story!.caption!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              story.caption!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: aeLabel(color: Colors.white).copyWith(height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_dragDown > 0)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: (_dragDown / 200).clamp(0, 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
