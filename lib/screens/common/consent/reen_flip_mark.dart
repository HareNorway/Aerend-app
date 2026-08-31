import 'package:flutter/material.dart';

/// Shared rect handoff for the Reen wordmark — ports `window.__reenSplashMark`
/// / `__reenConsentMark` from `DesignNew/dugnad/consent-gate.jsx`.
class ReenMarkHandoff {
  ReenMarkHandoff._();

  static Rect? splashMark;
  static Rect? consentMark;

  static Rect? takeSplash() {
    final rect = splashMark;
    splashMark = null;
    return rect;
  }

  static Rect? takeConsent() {
    final rect = consentMark;
    consentMark = null;
    return rect;
  }

  /// Visual rect including paint transforms (so a still-scaling splash logo
  /// hands off the on-screen box, not the untransformed layout box).
  static Rect? measure(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final bottomRight = box.localToGlobal(
      Offset(box.size.width, box.size.height),
    );
    if ((bottomRight - topLeft).distance < 1) return null;
    return Rect.fromPoints(topLeft, bottomRight);
  }
}

/// `dgcFlipMark` — invert a previously measured rect onto [child], then play
/// to identity. Scale is around the child's center, matching CSS
/// `transform-origin: 50% 50%`.
class ReenFlipMark extends StatefulWidget {
  const ReenFlipMark({
    super.key,
    required this.child,
    this.from,
    this.duration = const Duration(milliseconds: 560),
    this.byHeight = false,
    this.fadeFrom = 1,
    this.curve = const Cubic(0.3, 0.85, 0.28, 1),
  });

  final Widget child;
  final Rect? from;
  final Duration duration;
  final bool byHeight;
  final double fadeFrom;
  final Curve curve;

  @override
  State<ReenFlipMark> createState() => _ReenFlipMarkState();
}

class _ReenFlipMarkState extends State<ReenFlipMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  Offset _delta = Offset.zero;
  double _scale = 1;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    if (widget.from == null) _controller.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || widget.from == null) {
      _controller.value = 1;
      return;
    }
    if (_armed) return;
    _armed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  void _play() {
    if (!mounted) return;
    final from = widget.from;
    final box = context.findRenderObject() as RenderBox?;
    if (from == null || from.width <= 0 || box == null || !box.hasSize) {
      _controller.value = 1;
      return;
    }
    final topLeft = box.localToGlobal(Offset.zero);
    final bottomRight = box.localToGlobal(
      Offset(box.size.width, box.size.height),
    );
    final to = Rect.fromPoints(topLeft, bottomRight);
    if (to.width <= 0 || to.height <= 0) {
      _controller.value = 1;
      return;
    }
    final dx = (from.left + from.width / 2) - (to.left + to.width / 2);
    final dy = (from.top + from.height / 2) - (to.top + to.height / 2);
    final s = widget.byHeight ? from.height / to.height : from.width / to.width;
    setState(() {
      _delta = Offset(dx, dy);
      _scale = s;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        final dx = _delta.dx * (1 - t);
        final dy = _delta.dy * (1 - t);
        final s = _scale + (1 - _scale) * t;
        final opacity = widget.fadeFrom + (1 - widget.fadeFrom) * t;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(scale: s, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
