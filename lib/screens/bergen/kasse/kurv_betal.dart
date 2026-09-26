import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import 'kasse_copy.dart';
import 'kurv_parts.dart';

/// «Dra for å betale» (design L5232–5240): the 60-px orange trough
/// (`180deg #C94A20 → #E0662C 55% → #F2884E`, inset shadows), the teal fill
/// that grows with the knob (`90deg #2E7E8F → #46A3B4`, stripes on `vannRenn
/// 1.1s`), the label with three `pilVink` arrows, the price pill that fades
/// past 35 %, and the 50-px knob (`radial #4F9AAB → #2A6272 → #1E4F5C →
/// #143C46`, white ring, `0 3px 0 2px #0F2E36`) on `knappHint 4.2s` while
/// idle, with the `spPuls` ring and three `betBoble` bubbles while dragged.
/// Release past 62 % snaps to the end and calls [onPay]; otherwise it
/// springs back (`.5s cubic-bezier(.32,1.35,.45,1)`).
class KurvBetal extends StatefulWidget {
  const KurvBetal({super.key, required this.total, required this.onPay, this.busy = false});

  final double total;
  final Future<bool> Function() onPay;
  final bool busy;

  @override
  State<KurvBetal> createState() => _KurvBetalState();
}

class _KurvBetalState extends State<KurvBetal> with SingleTickerProviderStateMixin {
  double _x = 0;
  double _max = 250;
  bool _drag = false;
  late final AnimationController _snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _snap.addListener(() {
      setState(() => _x = _from + (_to - _from) * const Cubic(.32, 1.35, .45, 1).transform(_snap.value));
    });
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _animateTo(double to) {
    _from = _x;
    _to = to;
    final d = BergenTokens.motion(context, const Duration(milliseconds: 500));
    if (d == Duration.zero) {
      setState(() => _x = to);
      return;
    }
    _snap
      ..duration = d
      ..forward(from: 0);
  }

  Future<void> _release() async {
    if (!_drag) return;
    setState(() => _drag = false);
    if (_x >= _max * .62) {
      HapticFeedback.mediumImpact();
      _animateTo(_max);
      final ok = await widget.onPay();
      if (!mounted) return;
      if (!ok) _animateTo(0);
    } else {
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final klar = _x >= _max * .62;
    final tekstOp = klar ? 1.0 : (1 - _x / (_max * .5)).clamp(0.0, 1.0);
    final prisOp = _x > _max * .35 ? 0.0 : 1.0;
    final priceText = KasseCopy.tall(widget.total);
    return Semantics(
      button: true,
      label: KasseCopy.a1_kasse_dra_betal_label(priceText),
      child: LayoutBuilder(
        builder: (context, box) {
          _max = box.maxWidth - 60 * s;
          return GestureDetector(
            key: const Key('a1_kasse_betal'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: widget.busy
                ? null
                : (_) {
                    _snap.stop();
                    HapticFeedback.selectionClick();
                    setState(() {
                      _drag = true;
                      _x = 0;
                    });
                  },
            onHorizontalDragUpdate: widget.busy ? null : (d) => setState(() => _x = (_x + d.delta.dx).clamp(0, _max)),
            onHorizontalDragEnd: (_) => _release(),
            onHorizontalDragCancel: _release,
            child: Container(
              height: 60 * s,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20 * s),
                gradient: cssLinear(180, const [Color(0xFFC94A20), Color(0xFFE0662C), Color(0xFFF2884E)], const [0, .55, 1]),
                boxShadow: [
                  BoxShadow(color: rgba(255, 255, 255, .55), offset: Offset(0, 1.5 * s)),
                  BoxShadow(color: rgba(120, 50, 10, .75), offset: Offset(0, 16 * s), blurRadius: onbBlur(28 * s), spreadRadius: -14 * s),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // inset 0 3px 7px rgba(110,35,8,.7) / inset 0 -2px 0 white .22
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [rgba(110, 35, 8, .7), rgba(110, 35, 8, 0), rgba(255, 255, 255, 0), rgba(255, 255, 255, .22)],
                          stops: const [0, .18, .96, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5 * s,
                    top: 5 * s,
                    bottom: 5 * s,
                    width: 50 * s + _x,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16 * s),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(gradient: cssLinear(90, const [Color(0xFF2E7E8F), Color(0xFF46A3B4)])),
                          ),
                          BergenLoop(
                            durationMs: 1100,
                            builder: (context, p, _) => Opacity(
                              opacity: .45,
                              child: CustomPaint(painter: _StripesPainter(40 * s * (p ?? 0), s)),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [rgba(255, 255, 255, .35), rgba(255, 255, 255, 0), rgba(6, 30, 38, 0), rgba(6, 30, 38, .4)],
                                stops: const [0, .06, .9, 1],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 66 * s,
                    right: 16 * s,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: tekstOp,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                klar ? KasseCopy.a1_kasse_slipp_betal : KasseCopy.a1_kasse_dra_betal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bText(context, 14, weight: FontWeight.w800),
                              ),
                            ),
                            SizedBox(width: 8 * s),
                            for (final (a, d) in [(.55, 0.0), (.4, 180.0), (.26, 360.0)])
                              BergenLoop(
                                durationMs: 1600,
                                delayMs: d,
                                builder: (context, p, _) {
                                  final q = p == null ? 0.0 : kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                                  return Opacity(
                                    opacity: .35 + .65 * q,
                                    child: Transform.translate(
                                      offset: Offset(3 * q * s, 0),
                                      child: SizedBox(
                                        width: 9 * s,
                                        height: 12 * s,
                                        child: FittedBox(child: KurvIcon(12 * s, KurvIcons.chevron, color: rgba(255, 255, 255, a), width: 3.4)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const Spacer(),
                            AnimatedOpacity(
                              opacity: prisOp,
                              duration: BergenTokens.motion(context, const Duration(milliseconds: 200)),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10 * s),
                                  color: rgba(110, 35, 8, .32),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [rgba(90, 30, 5, .55), rgba(110, 35, 8, .32), rgba(110, 35, 8, .32), rgba(255, 255, 255, .2)],
                                    stops: const [0, .3, .95, 1],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(priceText, style: bDisplay(context, 15, letterSpacingEm: -.02, height: 1)),
                                    SizedBox(width: 3 * s),
                                    Text('kr', style: bText(context, 10.5, weight: FontWeight.w800, color: const Color(0xFFFFE0CC))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5 * s + _x,
                    top: 5 * s,
                    width: 50 * s,
                    height: 50 * s,
                    child: IgnorePointer(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: -6 * s,
                            top: -6 * s,
                            right: -6 * s,
                            bottom: -6 * s,
                            child: BergenLoop(
                              durationMs: 2400,
                              builder: (context, p, _) {
                                final q = Curves.easeOut.transform(p ?? 0);
                                return Opacity(
                                  opacity: .6 * (1 - q),
                                  child: Transform.scale(
                                    scale: .7 + .8 * q,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(21 * s),
                                        border: Border.all(color: rgba(255, 255, 255, .55), width: 1.5 * s),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_drag)
                            for (final (l, t, d, a, delay) in [(2.0, 20.0, 7.0, .7, 0.0), (-2.0, 28.0, 5.0, .55, 300.0), (4.0, 34.0, 4.0, .45, 600.0)])
                              Positioned(
                                left: l * s,
                                top: t * s,
                                width: d * s,
                                height: d * s,
                                child: BergenLoop(
                                  durationMs: 900,
                                  delayMs: delay,
                                  builder: (context, p, _) {
                                    if (p == null) return const SizedBox();
                                    final q = Curves.easeOut.transform(p);
                                    return Opacity(
                                      opacity: kf(q, const [0, .25, 1], const [0, .7, 0]),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..translate(-16 * q * s, -9 * q * s)
                                          ..scale(.5 + .65 * q),
                                        child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, a))),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          Positioned.fill(
                            child: BergenLoop(
                              durationMs: 4200,
                              builder: (context, p, child) {
                                final q = _drag ? 0.0 : (p ?? 0);
                                const st = [0.0, .82, .88, .94, 1.0];
                                return Transform.translate(
                                  offset: Offset(kf(q, st, const [0, 0, 8, 2, 0], Curves.easeInOut) * s, 0),
                                  child: child,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16 * s),
                                  gradient: const RadialGradient(
                                    center: Alignment(-.28, -.48),
                                    radius: 1.1,
                                    colors: [Color(0xFF4F9AAB), Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF143C46)],
                                    stops: [0, .4, .78, 1],
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 2 * s),
                                    BoxShadow(color: const Color(0xFF0F2E36), offset: Offset(0, 3 * s), spreadRadius: 2 * s),
                                    BoxShadow(color: rgba(0, 20, 30, .75), offset: Offset(0, 10 * s), blurRadius: onbBlur(16 * s), spreadRadius: -4 * s),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      left: 6 * s,
                                      right: 6 * s,
                                      top: 3 * s,
                                      height: 16 * s,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(12 * s), bottom: Radius.circular(8 * s)),
                                          gradient: cssLinear(180, [rgba(255, 255, 255, .4), rgba(255, 255, 255, 0)]),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      height: 8 * s,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16 * s)),
                                          gradient: cssLinear(180, [rgba(4, 20, 28, 0), rgba(4, 20, 28, .5)]),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Opacity(opacity: .55, child: KurvIcon(15 * s, KurvIcons.chevron, width: 3.4)),
                                        Transform.translate(offset: Offset(-5 * s, 0), child: KurvIcon(17 * s, KurvIcons.chevron, width: 3.4)),
                                      ],
                                    ),
                                    bergenInsetTop(radius: 16 * s, height: 2 * s, alpha: .4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// `repeating-linear-gradient(115deg, white .18 0 8px, transparent 8px 20px)`
/// on a 40-px tile, shifted by `vannRenn`.
class _StripesPainter extends CustomPainter {
  const _StripesPainter(this.shift, this.s);

  final double shift;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()..color = rgba(255, 255, 255, .18);
    final period = 20 * s;
    final skew = size.height / 2.14; // tan(115° − 90°) ≈ .466
    for (var x = -size.height - period * 2 + shift % period; x < size.width + size.height; x += period) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + skew, 0)
          ..lineTo(x + skew + 8 * s, 0)
          ..lineTo(x + 8 * s, size.height)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.shift != shift || old.s != s;
}
