import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_state.dart';

/// Animated price tag — mirrors `.mk-pricetag` + `mk-tag-swing` / `mk-tag-sheen`.
class MkPriceTag extends StatefulWidget {
  const MkPriceTag({
    super.key,
    required this.amount,
    required this.gradient,
  });

  final int amount;
  final Gradient gradient;

  /// `.mk-pricetag` carries its own gradient: two stops, 135deg, purple-500 ->
  /// purple-700. `shinyGradient` is three stops at ~150deg with different
  /// endpoints -- a neighbouring token, not this one. Browsing without a club
  /// swaps in slate, matching the rest of the card chrome in that mode.
  static LinearGradient gradientFor(BuildContext context) {
    final theme = context.aeTheme;
    final browseNoClub = !DugnadState.instance.hasClub;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        browseNoClub ? const Color(0xFFA8B7C9) : theme.primarySoft,
        browseNoClub ? const Color(0xFF6F87A4) : theme.primary,
      ],
    );
  }

  @override
  State<MkPriceTag> createState() => MkPriceTagState();
}

class MkPriceTagState extends State<MkPriceTag>
    with TickerProviderStateMixin {
  AnimationController? _swingCtrl;
  AnimationController? _sheenCtrl;
  Animation<double>? _swing;
  bool _started = false;

  void _ensureControllers() {
    // Hot reload can keep this State while adding new fields — never assume
    // `late` controllers from initState alone.
    if (_swingCtrl != null && _sheenCtrl != null && _swing != null) return;
    _swingCtrl?.dispose();
    _sheenCtrl?.dispose();
    // `mk-tag-swing 3.6s` — gentle hang.
    _swingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    // Diagonal sheen — same keyframes as `mk-tag-sheen`, faster loop.
    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _swing = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.052, end: 0.024)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.024, end: -0.052)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_swingCtrl!);
    _started = false;
  }

  @override
  void initState() {
    super.initState();
    _ensureControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureControllers();
    final swing = _swingCtrl!;
    final sheen = _sheenCtrl!;
    if (MediaQuery.disableAnimationsOf(context)) {
      if (swing.isAnimating) swing.stop();
      if (sheen.isAnimating) sheen.stop();
      swing.value = 0;
      sheen.value = 0;
      _started = false;
      return;
    }
    if (_started) return;
    _started = true;
    swing.repeat();
    sheen.repeat();
  }

  @override
  void dispose() {
    _swingCtrl?.dispose();
    _sheenCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fromLabel = languages.campaignFromPrice;
    final sheenCtrl = _sheenCtrl!;
    final swingAnim = _swing!;

    final tag = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: const _TagShadowPainter()),
        ),
        ClipPath(
          clipper: const _PriceTagClipper(),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  context.dp(17),
                  context.dp(6),
                  context.dp(11),
                  context.dp(6),
                ),
                decoration: BoxDecoration(gradient: widget.gradient),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fromLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 9 * 0.03,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    SizedBox(width: context.dp(5)),
                    Text(
                      '${widget.amount} kr',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 15 * -0.02,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (!reduceMotion)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: sheenCtrl,
                      builder: (context, _) {
                        final t = sheenCtrl.value;
                        if (t >= 0.39) return const SizedBox.shrink();
                        final o = t <= 0.10 ? t / 0.10 : 1.0;
                        return LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth * 0.46;
                            final p = (t / 0.38).clamp(0.0, 1.0);
                            return Stack(
                              children: [
                                Positioned(
                                  left: (-2.0 + p * 4.8) * w,
                                  top: 0,
                                  bottom: 0,
                                  width: w,
                                  child: Opacity(
                                    opacity: o.clamp(0.0, 1.0),
                                    child: Transform(
                                      transform: Matrix4.skewX(-0.2867),
                                      alignment: Alignment.center,
                                      child: const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0x00FFFFFF),
                                              Color(0x99FFFFFF),
                                              Color(0x00FFFFFF),
                                            ],
                                            stops: [0.28, 0.5, 0.72],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 4.5,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              width: context.dp(6),
              height: context.dp(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.5,
                  color: const Color(0x474A2E80),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (reduceMotion) {
      return Transform.rotate(angle: -0.035, child: tag);
    }

    return AnimatedBuilder(
      animation: swingAnim,
      builder: (context, child) {
        return Transform.rotate(
          angle: swingAnim.value,
          alignment: const Alignment(-0.9, 0.5),
          child: child,
        );
      },
      child: tag,
    );
  }
}

class _PriceTagClipper extends CustomClipper<Path> {
  const _PriceTagClipper();

  /// The one definition of the tag silhouette. The shadow painter fills the
  /// same path -- two copies of a polygon is the shared-constant problem in
  /// geometry form.
  static Path pathFor(Size size) {
    const notch = 12.0;
    return Path()
      ..moveTo(notch, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
  }

  @override
  Path getClip(Size size) => pathFor(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TagShadowPainter extends CustomPainter {
  const _TagShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // A CSS drop-shadow blur of 9 is a Gaussian sigma of ~4.5, not a
    // blurRadius of 9 -- the conversion most ports get wrong.
    final paint = Paint()
      ..color = const Color(0xFF7F5FC4).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9 / 2);
    canvas.save();
    canvas.translate(0, 5);
    canvas.drawPath(_PriceTagClipper.pathFor(size), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TagShadowPainter oldDelegate) => false;
}
