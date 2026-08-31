import 'package:flutter/material.dart';

import '../../../main.dart' show navigatorKey;
import 'dugnad_tour_card.dart';
import 'dugnad_tour_controller.dart';

/// Hosts the tour in the ROOT navigator's Overlay (same pattern as
/// global_loading_overlay.dart) so a single entry survives the clubHome →
/// playerCard push and the pop back.
class DugnadTourOverlay {
  DugnadTourOverlay._();

  static OverlayEntry? _entry;
  static DugnadTourController? _controller;

  static void show(DugnadTourController controller) {
    hide();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _controller = controller;
    controller.addListener(_onChange);
    _entry = OverlayEntry(
      builder: (_) => _DugnadTourOverlayView(controller: controller),
    );
    overlay.insert(_entry!);
  }

  static void _onChange() {
    // The view rebuilds itself via its own listener; here we only tear down.
    if (_controller?.isFinished ?? false) {
      hide();
      return;
    }
    _entry?.markNeedsBuild();
  }

  static void hide() {
    final controller = _controller;
    controller?.removeListener(_onChange);
    _controller = null;
    _entry?.remove();
    _entry = null;
    // Dispose AFTER the entry is gone, so the overlay State (and its listeners)
    // are torn down before the controller's notifiers are disposed.
    controller?.dispose();
  }
}

class _DugnadTourOverlayView extends StatefulWidget {
  const _DugnadTourOverlayView({required this.controller});

  final DugnadTourController controller;

  @override
  State<_DugnadTourOverlayView> createState() => _DugnadTourOverlayViewState();
}

class _DugnadTourOverlayViewState extends State<_DugnadTourOverlayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCtrl);
    // [start] often resolves the first step before this State mounts, so the
    // ready notification is missed and the card would stay at opacity 0.
    _syncFade(immediate: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrl);
    _fade.dispose();
    super.dispose();
  }

  void _onCtrl() {
    if (!mounted) return;
    _syncFade(immediate: false);
    setState(() {});
  }

  void _syncFade({required bool immediate}) {
    // C2: the hole + ring + card fade in only once the step is measured (ready).
    // On a step change ready flips false first, so we reset to 0 → nothing at a
    // stale position. The base dim (painter scrim) is unaffected and persists.
    final reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (widget.controller.ready) {
      if (immediate || reduce) {
        _fade.value = 1;
      } else {
        _fade.forward(from: 0);
      }
    } else {
      _fade.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final step = controller.current;

    // Material + expand: same full-screen guarantee as global_loading_overlay —
    // Overlay gives tight constraints, but a Stack of only Positioned children
    // is safer when explicitly expanded; Material supplies directionality defaults.
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // C3: the barrier ABSORBS pointer input (opaque, always present) —
            // taps on the dim or hole do nothing, and it swallows the Cupertino
            // edge-swipe so the page beneath cannot pop mid-tour.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
              ),
            ),
            // Persistent base dim + spotlight hole/ring. ALWAYS rendered while
            // the tour is up (the scrim never fades); only the hole + ring fade
            // via _fade. IgnorePointer so taps fall through to the barrier.
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: DugnadTourSpotlightPainter(
                      rect: controller.rect,
                      reveal: _fade,
                    ),
                  ),
                ),
              ),
            ),
            // Card returns Positioned — must be a direct Stack child. Opacity is
            // applied inside the card around its content.
            if (step != null)
              DugnadTourCard(
                controller: controller,
                step: step,
                rectListenable: controller.rect,
                metrics: controller.metricsTick,
                opacity: _fade,
              ),
          ],
        ),
      ),
    );
  }
}
