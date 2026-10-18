import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../aegil/aegil_bits.dart';
import '../hjem/hjem_harness.dart';
import 'meg_mark.dart';
import 'meg_nivaa_card.dart' show medalFor;

// ── Meg in new Bergen (Bergen Step 8, L7425–7650) ──────────────────────────
// The gold ticket under the name, the «Poeng, nivå og konkurranser» card that
// opens to the Poeng card and the Nivå / Liga / Gullbillett rows, the head
// of the group the design took out of Meg (D2), and «Logg ut» with its
// confirm.

abstract final class MegB8Copy {
  static const String gullbilletten = 'GULLBILLETTEN';
  static const String delingskode = 'DIN DELINGSKODE';
  static const String duOgVennen = 'Du og vennen får 200 poeng hver';
  static String duOgVennenN(int n) => 'Du og vennen får $n poeng hver';
  static const String del = 'Del';
  static const String kopier = 'Kopier';
  static const String poengKicker = 'POENG, NIVÅ OG KONKURRANSER';
  static const String poeng = 'poeng';
  static String liga(int plass) => 'Liga · $plass. plass';
  static const String ikkeILiga = 'Ikke i ligaen';
  static const String loggUt = 'Logg ut';
  static const String loggeUt = 'Logge ut?';
  static const String loggeUtLinje = 'Poengene, Min Bio og bestillingene dine ligger trygt her til du kommer tilbake.';
  static const String avbryt = 'Avbryt';
  static String loggetInn(String navn, String kontakt) => kontakt.isEmpty ? 'Logget inn som $navn' : 'Logget inn som $navn · $kontakt';

  /// The head over the rows the design took out of Meg (D2): kept until the
  /// manager approves removing them.
  static const String flere = 'FLERE INNSTILLINGER';
}

// ── shared motion ───────────────────────────────────────────────────────────

/// `skinnSveip3 <ms> <delay>`: a light band [frac] of the box wide sweeps
/// −140 % → 240 % (skewed −18°) in the first third of each period, fading
/// in to .7 by 6.67 % and out by 33.33 %. Rests (hidden) in lite / still.
class MegSveip3 extends StatelessWidget {
  const MegSveip3({super.key, required this.ms, this.delay = 0, this.frac = .3, this.alpha = .7, this.deg = 90, this.skew = true});

  final double ms;
  final double delay;
  final double frac;
  final double alpha;
  final double deg;
  final bool skew;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, box) => RepaintBoundary(
        child: LfLoop(
          frozenMs: -1,
          builder: (context, t, _) {
            if (t < 0) return const SizedBox.shrink();
            final p = kfLoop(t, delay, ms);
            if (p == null || p > 1 / 3) return const SizedBox.shrink();
            final x = kf(p, const [0, 1 / 3], const [-1.4, 2.4], const Cubic(.4, 0, .2, 1));
            final o = kf(p, const [0, .0667, 1 / 3], const [0, .7, 0]);
            final w = box.maxWidth * frac;
            Widget band = DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-math.sin(deg * math.pi / 180), math.cos(deg * math.pi / 180)),
                  end: Alignment(math.sin(deg * math.pi / 180), -math.cos(deg * math.pi / 180)),
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: alpha),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            );
            if (skew) band = Transform(alignment: Alignment.center, transform: Matrix4.skewX(math.tan(-18 * math.pi / 180)), child: band);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: x * w,
                  top: skew ? -box.maxHeight * .3 : 0,
                  bottom: skew ? -box.maxHeight * .3 : 0,
                  width: w,
                  child: Opacity(opacity: (o / .7).clamp(0.0, 1.0), child: band),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// `bioPuls`: scale .92 ↔ 1.08, opacity .6 ↔ 1.
class MegPuls extends StatelessWidget {
  const MegPuls({super.key, required this.child, this.ms = 3400, this.lo = .92, this.hi = 1.08});

  final Widget child;
  final double ms;
  final double lo, hi;

  @override
  Widget build(BuildContext context) => LfLoop(
    child: child,
    builder: (context, t, child) {
      final p = kfLoop(t, 0, ms) ?? 0;
      final s = kf(p, const [0, .5, 1], [lo, hi, lo], cssEaseInOut);
      final o = kf(p, const [0, .5, 1], const [.6, 1, .6], cssEaseInOut);
      return Opacity(
        opacity: o,
        child: Transform.scale(scale: s, child: child),
      );
    },
  );
}

// ── the gold ticket ─────────────────────────────────────────────────────────

/// The ticket's outline: a rounded rectangle with two half-round notches
/// at [ved] of the width, top and bottom (`mask: radial-gradient(circle 10px
/// at 72% 0 …)`).
class _BillettKant extends CustomClipper<Path> {
  const _BillettKant();
  static const double ved = .72, r = 20, hakk = 10;

  @override
  Path getClip(Size s) {
    final kropp = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r)));
    final x = s.width * ved;
    final hull = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: hakk))
      ..addOval(Rect.fromCircle(center: Offset(x, s.height), radius: hakk));
    return Path.combine(PathOperation.difference, kropp, hull);
  }

  @override
  bool shouldReclip(_BillettKant o) => false;
}

/// `repeating-linear-gradient(135deg, white .16 0 1.5px, transparent 1.5px 8px)`.
class _Striper extends CustomPainter {
  const _Striper();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, .16)
      ..strokeWidth = 1.5 * math.sqrt2 / math.sqrt2;
    // Lines of the 135° gradient run from bottom-left to top-right, 8px apart
    // along the gradient (8·√2 along each axis).
    const step = 8 * math.sqrt2;
    for (var c = 0.0; c < size.width + size.height; c += step) {
      final path = Path()
        ..moveTo(c, 0)
        ..lineTo(c + 1.5 * math.sqrt2, 0)
        ..lineTo(c + 1.5 * math.sqrt2 - size.height, size.height)
        ..lineTo(c - size.height, size.height)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_Striper o) => false;
}

/// The vertical tear line at the notch: `border-left: 2px dashed`.
class _Riv extends CustomPainter {
  const _Riv(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var y = 0.0; y < size.height; y += 12) {
      canvas.drawLine(Offset(1, y), Offset(1, math.min(y + 6, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(_Riv o) => o.color != color;
}

/// The gold ticket (`Gullbilletten · Meg` L7439–7457, and the code card of
/// the Gullbillett sheet L9805–9843): gold gradient, notches at 72 %, fine
/// stripes, the sweep, the label with its star, the code, the line, the tear
/// line and the right stub (Meg: the orange «Del» key; the sheet: «Kopier»).
class MegGullBillett extends StatelessWidget {
  const MegGullBillett({super.key, required this.kode, required this.linje, required this.onTap, required this.onStubb, this.ark = false});

  final String kode;
  final String linje;
  final VoidCallback onTap;
  final VoidCallback onStubb;

  /// The sheet's version: 100 px, «DIN DELINGSKODE», «Kopier», no inner
  /// frame or watermark.
  final bool ark;

  static const String _stjerne = 'M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4l-5.9 3.1 1.2-6.5L2.5 9.4l6.6-.9z';
  static const String _delIk = 'M12 15V4M12 4l-4 4M12 4l4 4M5 14v4a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-4';
  static const String _kopierIk = 'M10.5 8.5h9v11h-11v-9a2 2 0 0 1 2-2z M15.5 8.5V6a1.5 1.5 0 0 0-1.5-1.5H6A1.5 1.5 0 0 0 4.5 6v8A1.5 1.5 0 0 0 6 15.5h2.5';

  @override
  Widget build(BuildContext context) {
    final h = ark ? 100.0 : 96.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The gold glow under the ticket (`bioPuls 4.2s` on Meg).
        Positioned(
          left: 0,
          right: 0,
          bottom: -10,
          height: 44,
          child: FractionallySizedBox(
            widthFactor: ark ? .76 : .8,
            child: IgnorePointer(
              child: _glod(
                ark,
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: RadialGradient(colors: [Color.fromRGBO(242, 193, 78, .45), Color.fromRGBO(242, 193, 78, 0)])),
                ),
              ),
            ),
          ),
        ),
        AePress(
          key: Key(ark ? 'meg-billett-kode' : 'meg-gullbillett'),
          onTap: onTap,
          dy: 2,
          scale: .99,
          child: ClipPath(
            clipper: const _BillettKant(),
            child: CssBox(
              height: h,
              bg: const [
                CssLinear(140, [Color(0xFFFFF4CF), Color(0xFFF6D27A), Color(0xFFE6B347), Color(0xFFC98E22)], [0, .36, .68, 1]),
              ],
              shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .8)), CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(120, 70, 0, .25))],
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: CustomPaint(painter: _Striper())),
                  ),
                  if (!ark)
                    Positioned.fill(
                      left: 5,
                      top: 5,
                      right: 5,
                      bottom: 5,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color.fromRGBO(120, 80, 10, .22)),
                          ),
                        ),
                      ),
                    ),
                  // The Æ watermark: 96 px wide from 43 % of the ticket, 8 px down.
                  if (!ark)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: LayoutBuilder(
                          builder: (context, box) => Stack(
                            children: [
                              Positioned(
                                left: box.maxWidth * .43,
                                top: 8,
                                child: const Opacity(opacity: .13, child: MegMark(color: Color(0xFF5A4010), medAksent: false, size: 96)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: MegSveip3(ms: ark ? 6000 : 7000, delay: ark ? 1000 : 1400, frac: .4, deg: 100, skew: false),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 72,
                        // Centred in the ticket and scaled down when the fonts run
                        // taller than the design's (font metrics, OS text size up to
                        // 1.15): the bottom line («Gi 200 · få 200 poeng») never
                        // falls out of the fixed-height ticket.
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                          child: LayoutBuilder(
                            builder: (context, box) => FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: box.maxWidth,
                                child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const AeIkon(_stjerne, size: 11, stroke: 0, fill: Color(0xFF7A5414)),
                                  const SizedBox(width: 6),
                                  Text(
                                    ark ? MegB8Copy.delingskode : MegB8Copy.gullbilletten,
                                    style: inter(10, weight: FontWeight.w800, em: .16, color: const Color(0xFF7A5414)),
                                  ),
                                ],
                              ),
                              SizedBox(height: ark ? 6 : 5),
                              Text(
                                kode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: jakarta(ark ? 24 : 23, em: -.01, color: const Color(0xFF3A2708)),
                              ),
                              SizedBox(height: ark ? 4 : 3),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      linje,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: inter(11, weight: FontWeight.w700, color: const Color(0xFF6B4A12)),
                                    ),
                                  ),
                                  if (!ark) ...[const SizedBox(width: 5), const AeIkon('M9 6l6 6-6 6', size: 10, stroke: 3, color: Color(0xFF6B4A12))],
                                ],
                              ),
                            ],
                          ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 2,
                        height: h - 28,
                        child: const CustomPaint(painter: _Riv(Color.fromRGBO(90, 60, 10, .35))),
                      ),
                      Expanded(
                        flex: 28,
                        child: AePress(
                          key: Key(ark ? 'meg-billett-kopier' : 'meg-del'),
                          onTap: onStubb,
                          dy: 0,
                          scale: .94,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (ark)
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A3410), Color(0xFF2E1F06)]),
                                    boxShadow: [BoxShadow(color: Color.fromRGBO(40, 25, 0, .8), offset: Offset(0, 4), blurRadius: 8 / 2 / .57735, spreadRadius: -4)],
                                  ),
                                  child: const AeIkon(_kopierIk, size: 15, stroke: 2.3, color: Color(0xFFF6D27A)),
                                )
                              else
                                CssBox(
                                  width: 38,
                                  height: 38,
                                  radius: BorderRadius.circular(19),
                                  bg: const [
                                    CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                                  ],
                                  shadows: const [
                                    CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                                    CssShadow(0, 2, 0, 0, Color(0xFFA63A12)),
                                    CssShadow(0, 6, 10, -4, Color.fromRGBO(120, 45, 15, .7)),
                                  ],
                                  child: const Center(child: AeIkon(_delIk, size: 16, stroke: 2.6)),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                ark ? MegB8Copy.kopier : MegB8Copy.del,
                                style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFF3A2708)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _glod(bool ark, Widget child) => ark ? child : MegPuls(ms: 4200, child: child);
}

// ── «Poeng, nivå og konkurranser» ───────────────────────────────────────────

/// The collapsible points card (`Poeng-knapp` L7480–7507): the gold ring
/// around the tier coin, «POENG, NIVÅ OG KONKURRANSER», the points (gold,
/// with a slow glint), the Liga pill, the chevron key, and the sunken tier
/// bar. A tap opens [innhold] below (the Poeng card and the Nivå / Liga /
/// Gullbillett rows): rows .55 s, fade .4 s, lift and scale .55 s.
class MegPoengKort extends StatefulWidget {
  const MegPoengKort({super.key, required this.poeng, required this.tierName, required this.pct, required this.avstand, required this.ligaPlass, required this.innhold, this.apen = false});

  final int poeng;
  final String tierName;

  /// Through the current tier, 0–1 (`NV.pct`).
  final double pct;

  /// «380 til Gull» / «Høyeste nivå».
  final String avstand;

  /// The league place, or null when not in the league.
  final int? ligaPlass;
  final Widget innhold;

  /// Opened from the start (debug harness).
  final bool apen;

  @override
  State<MegPoengKort> createState() => _MegPoengKortState();
}

class _MegPoengKortState extends State<MegPoengKort> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 580), value: widget.apen ? 1 : 0);
  late bool _apen = widget.apen;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _bytt() {
    setState(() => _apen = !_apen);
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = _apen ? 1 : 0;
    } else {
      _apen ? _c.forward() : _c.reverse();
    }
  }

  static String _nf(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

  @override
  Widget build(BuildContext context) {
    final m = medalFor(widget.tierName);
    final med = widget.ligaPlass != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AePress(
          key: const Key('meg-poeng-knapp'),
          onTap: _bytt,
          dy: 2,
          scale: .994,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _apen ? 1 : 0),
            duration: const Duration(milliseconds: 350),
            curve: cssEase,
            builder: (context, a, child) => CssBox(
              radius: BorderRadius.circular(24),
              clip: true,
              bg: const [
                CssRadial([Color.fromRGBO(242, 193, 78, .17), Color.fromRGBO(242, 193, 78, 0)], stops: [0, .55], rx: 1.2, ry: 1, cx: 0, cy: 0),
                CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .06)]),
              ],
              border: Border.all(color: Color.lerp(const Color.fromRGBO(255, 255, 255, .2), const Color.fromRGBO(92, 224, 184, .55), a)!),
              shadows: [
                const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                CssShadow(0, 0, 0, 3, Color.fromRGBO(92, 224, 184, .14 * a)),
                const CssShadow(0, 20, 30, -20, Color.fromRGBO(4, 18, 26, .9)),
              ],
              child: child,
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: MegSveip3(ms: 9000, delay: 1000, frac: .3, alpha: .14)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 13, 13, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _Ring(pct: widget.pct, tierName: widget.tierName),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MegB8Copy.poengKicker,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: inter(9.5, weight: FontWeight.w800, em: .03, color: const Color.fromRGBO(255, 255, 255, .66)),
                                ),
                                const SizedBox(height: 3),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        _GullTall(_nf(widget.poeng)),
                                        const SizedBox(width: 5),
                                        Text(
                                          MegB8Copy.poeng,
                                          style: inter(12, weight: FontWeight.w800, color: const Color(0xFFF6D27A)),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 22,
                                      padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        color: med ? const Color.fromRGBO(92, 224, 184, .14) : const Color.fromRGBO(255, 255, 255, .06),
                                        border: Border.all(color: med ? const Color.fromRGBO(92, 224, 184, .4) : const Color.fromRGBO(255, 255, 255, .16)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AeIkon(
                                            'M7 4h10v4a5 5 0 0 1-10 0z M7 6H4a3 3 0 0 0 3 4 M17 6h3a3 3 0 0 1-3 4 M12 13v4 M8.5 20h7',
                                            size: 11,
                                            stroke: 2.6,
                                            color: med ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .78),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            med ? MegB8Copy.liga(widget.ligaPlass!) : MegB8Copy.ikkeILiga,
                                            style: aeTab(inter(10.5, weight: FontWeight.w800, color: med ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .78))),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 11),
                          _Pil(apen: _apen),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CssBox(
                        radius: BorderRadius.circular(14),
                        bg: const [CssSolid(Color.fromRGBO(0, 0, 0, .18))],
                        shadows: const [CssShadow.inset(0, 1, 3, 0, Color.fromRGBO(0, 0, 0, .3)), CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .06))],
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(center: const Alignment(-.32, -.48), colors: m.gradient, stops: m.stops),
                                border: Border.all(color: m.ring),
                                boxShadow: const [BoxShadow(color: Color.fromRGBO(242, 193, 78, .45), blurRadius: 8 / 2 / .57735)],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(widget.tierName, style: inter(11.5, weight: FontWeight.w800)),
                            const SizedBox(width: 9),
                            Expanded(child: _Stang(pct: widget.pct)),
                            const SizedBox(width: 9),
                            Text(
                              widget.avstand,
                              style: aeTab(inter(11, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .78))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // `grid-template-rows: 0fr → 1fr` .55 s cubic-bezier(.3,1,.4,1).
        AnimatedBuilder(
          animation: _c,
          child: Padding(padding: const EdgeInsets.fromLTRB(0, 12, 0, 2), child: widget.innhold),
          builder: (context, child) {
            final v = _c.value;
            if (v == 0) return const SizedBox.shrink();
            final h = const Cubic(.3, 1, .4, 1).transform(v);
            final o = cssEase.transform((v * 580 / 400).clamp(0.0, 1.0));
            final y = const Cubic(.3, 1.2, .5, 1).transform(v);
            final inner = Opacity(
              opacity: o,
              child: Transform(alignment: Alignment.topCenter, transform: Matrix4.translationValues(0, -14 * (1 - y), 0)..scaleByDouble(.97 + .03 * y, .97 + .03 * y, 1, 1), child: child),
            );
            // `overflow: visible` once it is open, so the shadows show.
            if (v >= 1) return inner;
            return ClipRect(
              child: Align(alignment: Alignment.topCenter, heightFactor: h.clamp(0.0, 1.0), child: inner),
            );
          },
        ),
      ],
    );
  }
}

/// The points in gold with the slow glint (`megGullGlans 6s 1.4s`: the
/// light part of the 250 %-wide gradient slides across from 72 % to 100 %).
class _GullTall extends StatelessWidget {
  const _GullTall(this.tx);
  final String tx;

  @override
  Widget build(BuildContext context) {
    final stil = aeTab(jakarta(25, em: -.035, height: 1.05));
    return LfLoop(
      builder: (context, t, _) {
        final p = kfLoop(t, 1400, 6000) ?? 0;
        // background-position 100 % → −60 % over 72 %–100 %, ease-in-out.
        final pos = kf(p, const [0, .72, 1], const [1, 1, -.6], cssEaseInOut);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) {
            final w = r.width * 2.5;
            final left = (r.width - w) * pos;
            return LinearGradient(
              colors: const [Color(0xFFF6D27A), Color(0xFFF6D27A), Color(0xFFFFF6D8), Color(0xFFF6D27A), Color(0xFFF6D27A)],
              stops: const [0, .38, .5, .62, 1],
              transform: _Skyv(left / w),
            ).createShader(Rect.fromLTWH(0, 0, w, r.height));
          },
          child: Text(tx, style: stil),
        );
      },
    );
  }
}

class _Skyv extends GradientTransform {
  const _Skyv(this.f);
  final double f;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * f, 0, 0);
}

/// The ring around the coin: a 3.5 px gold arc for the tier progress that
/// fills in (`megRingFyll 1.3s .25s`), the breathing glow, and the 42 px
/// coin (tier metal, dashed ring, the Æ mark, `medGlod`, the sweep).
class _Ring extends StatelessWidget {
  const _Ring({required this.pct, required this.tierName});

  final double pct;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(tierName);
    final mal = math.max(.04, math.min(1.0, pct));
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        children: [
          const Positioned.fill(
            left: 4,
            top: 4,
            right: 4,
            bottom: 4,
            child: MegPuls(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color.fromRGBO(242, 193, 78, .35), Color.fromRGBO(242, 193, 78, 0)]),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LfOnce(
              ms: 1550,
              builder: (context, t, _) {
                final p = const Cubic(.3, 1, .4, 1).transform(kfP(t, 250, 1300));
                return CustomPaint(painter: _RingMaler(mal * p));
              },
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: LfLoop(
              builder: (context, t, child) {
                // `medGlod 2.8s`: a gold ring grows out (0 → 9px) as the glow
                // swells (18 → 30px).
                final p = kfLoop(t, 0, 2800) ?? 0;
                final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color.fromRGBO(242, 193, 78, .55 * (1 - k)), spreadRadius: 9 * k),
                      BoxShadow(color: Color.fromRGBO(242, 193, 78, .35 + .35 * k), blurRadius: (18 + 12 * k) / 2 / .57735),
                    ],
                  ),
                  child: child,
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(center: const Alignment(-.32, -.48), colors: m.gradient, stops: m.stops),
                  boxShadow: [
                    BoxShadow(color: m.ring, spreadRadius: 1.5),
                    const BoxShadow(color: Color.fromRGBO(3, 16, 24, .75), offset: Offset(0, 5), blurRadius: 10 / 2 / .57735, spreadRadius: -4),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color.fromRGBO(255, 255, 255, .85), Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(90, 60, 10, 0), Color.fromRGBO(90, 60, 10, .25)],
                              stops: [0, .05, .7, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(left: 4, top: 4, right: 4, bottom: 4, child: CustomPaint(painter: _Stiplet(const Color.fromRGBO(90, 60, 10, .4)))),
                      MegMark(color: m.ink, size: 25),
                      const Positioned.fill(child: MegSveip3(ms: 10200, delay: 600, frac: .36, alpha: .9)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingMaler extends CustomPainter {
  const _RingMaler(this.f);
  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 26.5;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = const Color.fromRGBO(255, 255, 255, .13),
    );
    if (f <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * f,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF6D27A),
    );
  }

  @override
  bool shouldRepaint(_RingMaler o) => o.f != f;
}

/// `border: 1.2px dashed`.
class _Stiplet extends CustomPainter {
  const _Stiplet(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    const n = 22;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, math.pi / n, false, p);
    }
  }

  @override
  bool shouldRepaint(_Stiplet o) => o.color != color;
}

/// The tier bar: fills in (`upFyll 1.1s .35s`) with a glint (`upGlans 3.2s
/// 1.6s`).
class _Stang extends StatelessWidget {
  const _Stang({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) => CssBox(
    height: 8,
    radius: BorderRadius.circular(999),
    clip: true,
    bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .12))],
    shadows: const [CssShadow.inset(0, 1, 2, 0, Color.fromRGBO(0, 0, 0, .35))],
    child: LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth * pct.clamp(0.0, 1.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: LfOnce(
            ms: 1450,
            builder: (context, t, child) =>
                Transform(alignment: Alignment.centerLeft, transform: Matrix4.diagonal3Values(const Cubic(.3, 1.1, .5, 1).transform(kfP(t, 350, 1100)), 1, 1), child: child),
            child: Container(
              width: w,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(colors: [Color(0xFFE9AC3C), Color(0xFFF6D27A), Color(0xFFFFF1C4)], stops: [0, .7, 1]),
                boxShadow: const [BoxShadow(color: Color.fromRGBO(242, 193, 78, .55), blurRadius: 8 / 2 / .57735)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LfLoop(
                  frozenMs: -1,
                  builder: (context, t, _) {
                    if (t < 0) return const SizedBox.shrink();
                    final p = kfLoop(t, 1600, 3200) ?? 0;
                    final x = kf(p, const [0, .6, 1], const [0, 3.6, 3.6], cssEaseInOut);
                    return Stack(
                      children: [
                        Positioned(
                          left: -w * .4 + x * w * .4,
                          top: 0,
                          bottom: 0,
                          width: w * .4,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .6), Color.fromRGBO(255, 255, 255, 0)])),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// The chevron key: glass, mint once open; the arrow turns 180°
/// (.5 s `cubic-bezier(.3,1.4,.5,1)`).
class _Pil extends StatelessWidget {
  const _Pil({required this.apen});
  final bool apen;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 350),
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: apen ? null : const Color.fromRGBO(255, 255, 255, .12),
      gradient: apen ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]) : null,
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
    ),
    alignment: Alignment.center,
    child: AnimatedRotation(
      turns: apen ? .5 : 0,
      duration: const Duration(milliseconds: 500),
      curve: const Cubic(.3, 1.4, .5, 1),
      child: AeIkon('M6 9l6 6 6-6', size: 14, stroke: 2.8, color: apen ? const Color(0xFF0F2B33) : Colors.white),
    ),
  );
}

// ── Logg ut ─────────────────────────────────────────────────────────────────

/// «Logg ut» (L7630–7648): the glass key with the peach door, which turns
/// into «Logge ut?» with Ægil, «Avbryt» / «Logg ut» (it falls back after
/// 8 s); and «Logget inn som …» under it.
class MegLoggUt extends StatefulWidget {
  const MegLoggUt({super.key, required this.konto, required this.onLoggUt});

  final String konto;
  final Future<void> Function() onLoggUt;

  @override
  State<MegLoggUt> createState() => _MegLoggUtState();
}

class _MegLoggUtState extends State<MegLoggUt> {
  bool _sporr = false;
  bool _jobber = false;
  Timer? _tilbake;

  @override
  void initState() {
    super.initState();
    // Debug harness only: open on the question (no fallback timer).
    if (kDebugMode && HjemHarness.loggUt) _sporr = true;
  }

  void _start() {
    setState(() => _sporr = true);
    _tilbake?.cancel();
    // `lgStart`: the question falls back after 8 s.
    _tilbake = Timer(const Duration(seconds: 8), () {
      if (mounted && !_jobber) setState(() => _sporr = false);
    });
  }

  @override
  void dispose() {
    _tilbake?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 14),
      AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _sporr ? _bekreft() : _knapp()),
      const SizedBox(height: 10),
      Text(
        widget.konto,
        key: const Key('meg-logget-inn'),
        textAlign: TextAlign.center,
        style: inter(11, color: const Color.fromRGBO(255, 255, 255, .5)),
      ),
    ],
  );

  Widget _knapp() => AePress(
    key: const Key('meg-logg-ut'),
    onTap: _start,
    dy: 2,
    scale: .99,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .05)]),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AeIkon('M10 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h4 M15 8l4 4-4 4 M19 12H9', size: 17, stroke: 2.3, color: Color(0xFFFFB08A)),
          const SizedBox(width: 8),
          Text(MegB8Copy.loggUt, style: inter(14, weight: FontWeight.w800)),
        ],
      ),
    ),
  );

  Widget _bekreft() => CssBox(
    key: const Key('meg-logg-ut-bekreft'),
    radius: BorderRadius.circular(22),
    bg: const [
      CssLinear(180, [Color.fromRGBO(255, 255, 255, .13), Color.fromRGBO(255, 255, 255, .05)]),
    ],
    border: Border.all(color: const Color.fromRGBO(255, 176, 138, .35)),
    shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .22)), CssShadow(0, 18, 28, -18, Color.fromRGBO(4, 18, 26, .9))],
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ClipOval(
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment(-.3, -1), end: Alignment(.3, 1), colors: [Color(0xFF2F6E80), Color(0xFF173E48)]),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [Positioned(left: 1, bottom: -8, width: 42, child: Image.asset(aePose('front'), width: 42, fit: BoxFit.fitWidth))],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(MegB8Copy.loggeUt, style: jakarta(14.5, em: -.01)),
                  const SizedBox(height: 2),
                  Text(MegB8Copy.loggeUtLinje, style: inter(11.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .72))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AePress(
                key: const Key('meg-logg-ut-avbryt'),
                onTap: () {
                  _tilbake?.cancel();
                  setState(() => _sporr = false);
                },
                dy: 2,
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color.fromRGBO(255, 255, 255, .1),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
                  ),
                  child: Text(MegB8Copy.avbryt, style: inter(13.5, weight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AePress(
                key: const Key('meg-logg-ut-ja'),
                onTap: _jobber
                    ? null
                    : () async {
                        setState(() => _jobber = true);
                        await widget.onLoggUt();
                        if (mounted) setState(() => _jobber = false);
                      },
                dy: 2,
                child: CssBox(
                  height: 46,
                  radius: BorderRadius.circular(999),
                  bg: const [
                    CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                  ],
                  shadows: const [CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .4)), CssShadow(0, 2, 0, 0, Color(0xFFC4491A)), CssShadow(0, 10, 16, -8, Color.fromRGBO(200, 70, 25, .85))],
                  child: Center(
                    child: Text(MegB8Copy.loggUt, style: inter(13.5, weight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// The small head over the D2 group (same look as the design's section
/// kickers: 11 px, 800, .12 em, white .55).
class MegGruppeHode extends StatelessWidget {
  const MegGruppeHode(this.tx, {super.key});
  final String tx;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Text(
      tx,
      style: inter(11, weight: FontWeight.w800, em: .12, color: const Color.fromRGBO(255, 255, 255, .55)),
    ),
  );
}
