import 'package:flutter/material.dart';

import '../../theme/sc_saas_theme.dart';
import 'circle_painter.dart';
import 'curve_wave.dart';

class RipplesAnimationView extends StatefulWidget {
  const RipplesAnimationView({
    super.key,
    this.size = 80.0,
    this.color = ScSaasThemeTokens.primary,
    this.onPressed,
    required this.child,
  });
  final double size;
  final Color color;
  final Widget child;
  final VoidCallback? onPressed;

  @override
  State createState() => _RipplesAnimationState();
}

class _RipplesAnimationState extends State<RipplesAnimationView> with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Animation disabled to remove blinking effect
    // ..repeat();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  Widget _button() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: <Color>[
                widget.color,
                widget.color,
                // Color.lerp(widget.color, Colors.black, .05)
              ],
            ),
          ),
          child: ScaleTransition(
              scale: Tween(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller!,
                  curve: const CurveWave(),
                ),
              ),
              child: widget.child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: CirclePainter(
          _controller!,
          color: widget.color,
        ),
        child: SizedBox(
          width: widget.size * 4.125,
          height: widget.size * 4.125,
          child: _button(),
        ),
      ),
    );
  }
}
