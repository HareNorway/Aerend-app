import 'package:flutter/widgets.dart';

/// Fjordløpet v1.3 plan Step 5 (spec v1.3 §12.3; T28): how touches become lane changes.
///
/// The play field reads raw pointer events through a [Listener] — no GestureDetector, so nothing waits for other
/// gestures to be ruled out.
/// - A swipe is recognised the moment the finger has moved [swipePx] logical pixels sideways, finger still down.
/// - A tap is recognised when the finger lifts without having moved that far, for the half where it started.
/// - One lane change per touch, and only the first finger counts until it lifts.
class LopetInput extends StatefulWidget {
  const LopetInput({super.key, required this.onDir, required this.child, this.swipePx = 12});

  /// −1 left, +1 right.
  final ValueChanged<int> onDir;
  final Widget child;
  final double swipePx;

  @override
  State<LopetInput> createState() => _LopetInputState();
}

class _LopetInputState extends State<LopetInput> {
  int? _pointer;
  double _startX = 0;
  bool _used = false;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return; // only the first finger
    _pointer = e.pointer;
    _startX = e.localPosition.dx;
    _used = false;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || _used) return;
    final dx = e.localPosition.dx - _startX;
    if (dx.abs() >= widget.swipePx) {
      _used = true;
      widget.onDir(dx < 0 ? -1 : 1);
    }
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    if (!_used) {
      final w = context.size?.width ?? 0;
      widget.onDir(_startX < w / 2 ? -1 : 1);
    }
    _pointer = null;
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _pointer = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: widget.child,
      );
}
