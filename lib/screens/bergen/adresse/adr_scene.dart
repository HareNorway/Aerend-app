import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import 'adr_tegning.dart';

// ── The address sheets' street (prototype L8384–8432, L8498–8562) ──────────
// One timeline per appearance: neighbours rise (`adrReis`), the chosen
// building rises and its windows light up one by one (`adrLysPaa`), the pin
// drops and bounces (`adrPin`), a ring spreads (`adrRing`), Ægil steps in
// (`adrAeg`) and speaks (`adrBoble`); the door sign flips up (`adrSkilt`).

enum AdrType { hus, jobb, hytte }

AdrType adrTypeFor(String merke) => switch (merke) {
  'Jobb' => AdrType.jobb,
  'Hytte' => AdrType.hytte,
  _ => AdrType.hus,
};

const Map<AdrType, String> _kPinIkon = {AdrType.hus: 'M12.5 19.5L19 14l6.5 5.5V25h-13z', AdrType.jobb: 'M13 17h12v8H13zM16.5 17v-2.2h5V17', AdrType.hytte: 'M12 21l7-6 7 6M14 20.5V25h10v-4.5'};

const Cubic _kSpring = Cubic(.3, 1.3, .5, 1);

/// `adrReis`: up from below, overshoot and settle (origin bottom).
Widget adrReis(double t, double delayMs, double durMs, Widget child, {Cubic curve = _kSpring}) {
  final p = ((t - delayMs) / durMs).clamp(0.0, 1.0);
  final ty = kf(p, const [0, .55, .78, 1], const [1.05, -.05, .02, 0], curve);
  final sx = kf(p, const [0, .55, .78, 1], const [.9, 1.02, .99, 1], curve);
  final sy = kf(p, const [0, .55, .78, 1], const [.6, 1.06, .97, 1], curve);
  final o = kf(p, const [0, .55, 1], const [0, 1, 1], curve);
  return Opacity(
    opacity: o.clamp(0.0, 1.0),
    child: FractionalTranslation(
      translation: Offset(0, ty),
      child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.diagonal3Values(sx, sy, 1), child: child),
    ),
  );
}

/// The night sky, hills, road and curb both scenes share.
class _Gate extends StatelessWidget {
  const _Gate({required this.t, required this.h, required this.children, this.stjerner = 4, this.skyTop2 = 58, this.hillsH = 96});

  final double t, h, skyTop2, hillsH;
  final int stjerner;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    Widget blink(double l, double tp, double s, double dur, double delay) => Positioned(
      left: l,
      top: tp,
      width: s,
      height: s,
      child: Opacity(
        opacity: t < delay ? 1 : kf(((t - delay) / dur) % 1.0, const [0, .5, 1], const [.25, 1, .25], cssEaseInOut),
        child: const DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      ),
    );
    double sky(double dur, double delay, bool rev) {
      final e = t - delay;
      if (e < 0) return -24;
      final raw = (e / dur) % 2.0;
      var p = raw <= 1 ? raw : 2 - raw;
      if (rev) p = 1 - p;
      return -24 + 48 * cssEaseInOut.transform(p);
    }

    final stars = [blink(62, 16, 2, 2400, 0), blink(92, 34, 2, 3100, 600), blink(128, 12, 1.5, 2700, 1200), if (stjerner > 3) blink(44, 46, 1.5, 3400, 300)];
    return SizedBox(
      height: h,
      child: CssBox(
        radius: BorderRadius.circular(24),
        clip: true,
        bg: const [
          CssRadial([Color.fromRGBO(255, 190, 120, .28), Color.fromRGBO(255, 190, 120, 0)], stops: [0, .7], rx: .7, ry: .55, cx: .5, cy: 1),
          CssLinear(180, [Color(0xFF1A4553), Color(0xFF2C6C7E), Color(0xFF3E8293)], [0, .58, 1]),
        ],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
          CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
        ],
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 22,
                  top: 18,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(center: Alignment(-.2, -.3), colors: [Colors.white, Color(0xFFE9E4D6), Color(0xFFCFC8B6)], stops: [0, .6, 1]),
                      boxShadow: [BoxShadow(color: Color.fromRGBO(244, 239, 230, .25), blurRadius: 9, spreadRadius: 6)],
                    ),
                  ),
                ),
                ...stars,
                Positioned(
                  left: -30,
                  top: 30,
                  width: 150,
                  height: 26,
                  child: Transform.translate(
                    offset: Offset(sky(14000, 0, false), 0),
                    child: const CssBox(
                      bg: [
                        CssRadial.closestSide([Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, 0)]),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -40,
                  top: skyTop2,
                  width: 180,
                  height: 28,
                  child: Transform.translate(
                    offset: Offset(sky(18000, 2000, true), 0),
                    child: const CssBox(
                      bg: [
                        CssRadial.closestSide([Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, 0)]),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 24,
                  width: w,
                  height: hillsH,
                  child: AdrTegning(bilde: kHills, t: t, width: w, height: hillsH),
                ),
                ...children.take(1),
                // Curb and road (dots 9×7 over the asphalt).
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 22,
                  height: 5,
                  child: CssBox(
                    bg: [
                      CssLinear(180, [Color(0xFF5E7378), Color(0xFF5E7378)]),
                    ],
                    shadows: [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .2))],
                  ),
                ),
                const Positioned(left: 0, right: 0, bottom: 0, height: 22, child: CustomPaint(painter: _Vei())),
                ...children.skip(1),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Vei extends CustomPainter {
  const _Vei();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B4148), Color(0xFF1C2D33)]).createShader(r));
    final dot = Paint()..color = const Color.fromRGBO(255, 255, 255, .07);
    for (var y = 0.0; y < size.height; y += 7) {
      for (var x = 0.0; x < size.width; x += 9) {
        canvas.drawCircle(Offset(x + 4.5, y + 3.5), 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The four neighbours (`adrNaboA–D`), rising in turn.
List<Widget> _naboer(double t, double w, {required bool lys, double delay = 0}) {
  Widget nabo(AdrBilde b, double? left, double? right, double bw, double bh, double d) => Positioned(
    left: left,
    right: right,
    bottom: 22,
    width: bw,
    height: bh,
    child: adrReis(t, delay + d, 600, AdrTegning(bilde: b, t: t, width: bw, height: bh)),
  );
  return [
    nabo(lys ? kNaboA : kNaboNyA, 4, null, 56, 78, 0),
    nabo(lys ? kNaboB : kNaboNyB, 52, null, 48, 67, 60),
    nabo(lys ? kNaboC : kNaboNyC, null, 52, 52, 73, 100),
    nabo(lys ? kNaboD : kNaboNyD, null, -4, 60, 84, 160),
  ];
}

/// The orange pin with the type icon: drops (`adrPin`), then floats.
Widget _pin(double t, AdrType ty, double delay) {
  final p = ((t - delay) / 850).clamp(0.0, 1.0);
  const c = Cubic(.3, 1, .5, 1);
  final y = kf(p, const [0, .4, .58, .76, 1], const [-150, 4, -14, 2, 0], c);
  final sx = kf(p, const [0, .4, .58, .76, 1], const [1, 1.1, .95, 1.04, 1], c);
  final sy = kf(p, const [0, .4, .58, .76, 1], const [1, .84, 1.06, .96, 1], c);
  final o = kf(p, const [0, .4, 1], const [0, 1, 1], c);
  final svev = t < 1600 ? 0.0 : kf(((t - 1600) / 2800) % 1.0, const [0, .5, 1], const [0, -4, 0], cssEaseInOut);
  return Opacity(
    opacity: o.clamp(0.0, 1.0),
    child: Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(sx, sy, 1, 1),
      child: Transform.translate(
        offset: Offset(0, svev),
        child: AdrTegning(bilde: kPin, t: t, stier: {'adrPinIkon': _kPinIkon[ty]!, 'naPinIkon': _kPinIkon[ty]!}),
      ),
    ),
  );
}

/// `adrRing`: the landing ring.
Widget _ring(double t, double delay) {
  final p = ((t - delay) / 900).clamp(0.0, 1.0);
  if (p <= 0 || p >= 1) return const SizedBox.shrink();
  final e = cssEaseOut.transform(p);
  return Opacity(
    opacity: kf(e, const [0, .25, 1], const [0, 1, 0]),
    child: Transform.scale(
      scale: .3 + 2.3 * e,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.elliptical(19, 5.5)),
          border: Border.all(color: const Color(0xFF7FF0CB), width: 2),
        ),
      ),
    ),
  );
}

/// `adrGnist`: eight sparks around the new place.
List<Widget> _gnister(double t, double w, double topp) {
  const s = [
    (-44.0, 30.0, Color(0xFF5CE0B8), 0),
    (40.0, 26.0, Color(0xFFFFD27A), 50),
    (-30.0, 2.0, Colors.white, 100),
    (30.0, -2.0, Color(0xFFFF9466), 80),
    (-52.0, 58.0, Color(0xFFFF9466), 140),
    (50.0, 54.0, Color(0xFF5CE0B8), 120),
    (0.0, -10.0, Color(0xFFFFD27A), 20),
    (-12.0, 72.0, Colors.white, 180),
  ];
  return [
    for (final (dx, top, c, d) in s)
      () {
        final p = ((t - topp - d) / 900).clamp(0.0, 1.0);
        final e = cssEaseOut.transform(p);
        final sc = kf(e, const [0, .35, 1], const [0, 1.3, .4]);
        final ty = kf(e, const [0, .35, 1], const [0, -4, -16]);
        final o = kf(e, const [0, .35, 1], const [0, 1, 0]);
        return Positioned(
          left: w / 2 - 25 + dx,
          top: top + (topp > 1200 ? 0 : 10),
          width: 7,
          height: 7,
          child: Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, ty * sc),
              child: Transform.scale(
                scale: sc,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    boxShadow: [BoxShadow(color: c, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
        );
      }(),
  ];
}

/// Ægil stepping in (`adrAeg`).
Widget _aegil(double t, double w, double aegDelay) {
  final pa = ((t - aegDelay) / 600).clamp(0.0, 1.0);
  final ax = kf(pa, const [0, .7, 1], const [46, -4, 0], _kSpring);
  final ao = kf(pa, const [0, .7, 1], const [0, 1, 1], _kSpring);
  return Positioned(
    left: w / 2 + 32,
    bottom: 10,
    width: 60,
    height: 60,
    child: Opacity(
      opacity: ao.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(ax, 0),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: aegStaa(t, 3200),
          child: Image.asset('assets/images/dashboard/front.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
        ),
      ),
    ),
  );
}

/// Ægil's bubble (`adrBoble` .45s), placed by the caller (right 10, top 12).
Widget _boble(double t, String tekst, double delay, double maxW) {
  final pb = ((t - delay) / 450).clamp(0.0, 1.0);
  const bc = Cubic(.3, 1.4, .5, 1);
  final bs = kf(pb, const [0, .65, 1], const [.4, 1.06, 1], bc);
  final bo = kf(pb, const [0, .65, 1], const [0, 1, 1], bc);
  final by = kf(pb, const [0, .65, 1], const [10, 0, 0], bc);
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxW),
    child: Opacity(
      opacity: bo.clamp(0.0, 1.0),
      child: Transform(
        alignment: const Alignment(-.6, 1),
        transform: Matrix4.identity()
          ..scaleByDouble(bs, bs, 1, 1)
          ..translateByDouble(0, by, 0, 1),
        child: CssBox(
          radius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4)),
          bg: const [
            CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEAF2F2)]),
          ],
          shadows: const [CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 2.5, 0, 0, Color(0xFF9FB2B6)), CssShadow(0, 10, 14, -6, Color.fromRGBO(3, 14, 20, .7))],
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
          child: LfPretty(
            tekst,
            style: inter(10.5, weight: FontWeight.w800, height: 1.35, color: const Color(0xFF173E48)),
          ),
        ),
      ),
    ),
  );
}

/// The chosen building with its smoke and number plate.
Widget _bygg(double t, AdrType ty, {required bool ny, required Map<String, Color> vars, required Map<String, double> ops, required String nr, double roykOp = 1}) {
  switch (ty) {
    case AdrType.jobb:
      return AdrTegning(bilde: ny ? kJobbNy : kJobbAdr, t: t, vars: vars, width: 92, height: 112);
    case AdrType.hytte:
      return AdrTegning(bilde: ny ? kHytteNy : kHytteAdr, t: t, vars: vars, width: 100, height: 86);
    case AdrType.hus:
      Widget royk(double s, Color c, double d) {
        final e = t - d;
        if (e < 0) return const SizedBox.shrink();
        final p = cssEaseOut.transform((e / 3000) % 1.0);
        return Positioned(
          left: 62,
          top: -4,
          width: s,
          height: s,
          child: Opacity(
            opacity: (kf(p, const [0, .2, 1], const [0, .8, 0]) * roykOp).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(12 * p, -38 * p),
              child: Transform.scale(
                scale: .5 + 1.3 * p,
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                ),
              ),
            ),
          ),
        );
      }
      return SizedBox(
        width: 100,
        height: 116,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            royk(12, const Color.fromRGBO(230, 236, 238, .55), 0),
            royk(10, const Color.fromRGBO(230, 236, 238, .5), 1000),
            royk(11, const Color.fromRGBO(230, 236, 238, .45), 2000),
            AdrTegning(bilde: ny ? kHusNy : kHusAdr, t: t, vars: vars, ops: ops),
            Positioned(
              left: 63,
              top: 96,
              width: 13,
              height: 10,
              child: Center(
                child: Text(nr, maxLines: 1, style: jakarta(7.5, height: 1, color: const Color(0xFF1E4F5C))),
              ),
            ),
          ],
        ),
      );
  }
}

// ── Adresse · gatescene ────────────────────────────────────────────────────

class AdrGatescene extends StatelessWidget {
  const AdrGatescene({super.key, required this.type, required this.husFarge, required this.etasje, required this.nr, required this.tekst, required this.ny});

  final AdrType type;
  final Color husFarge;

  /// The home address shows its floor lit (mint) — `adrEtasjeOp`.
  final bool etasje;
  final String nr, tekst;

  /// Just saved (`adrNy`): sparks and the "Nytt sted" line.
  final bool ny;

  static const _topp = {AdrType.hus: (10.0, 53.0), AdrType.jobb: (16.0, 59.0), AdrType.hytte: (44.0, 86.0)};

  @override
  Widget build(BuildContext context) {
    return LfLoop(
      frozenMs: 6000,
      builder: (context, t, _) => LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final (pinTop, ringTop) = _topp[type]!;
          return _Gate(
            t: t,
            h: 190,
            children: [
              // Behind the curb: the warm lights on the hill.
              Stack(
                children: [
                  Positioned(
                    left: w * .58,
                    top: 52,
                    width: 3,
                    height: 3,
                    child: Opacity(
                      opacity: kf((t / 3000) % 1.0, const [0, .5, 1], const [.25, 1, .25], cssEaseInOut),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFD27A),
                          boxShadow: [BoxShadow(color: Color(0xFFFFD27A), blurRadius: 3)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * .61,
                    top: 50,
                    width: 2,
                    height: 2,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFD27A),
                        boxShadow: [BoxShadow(color: Color(0xFFFFD27A), blurRadius: 2.5)],
                      ),
                    ),
                  ),
                  ..._naboer(t, w, lys: true),
                  // The street lamp and its glow.
                  Positioned(
                    left: w / 2 - 94,
                    bottom: 24,
                    width: 3,
                    height: 58,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A2B30), Color(0xFF4C5F64)])),
                    ),
                  ),
                  Positioned(
                    left: w / 2 - 99,
                    bottom: 78,
                    width: 13,
                    height: 12,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(3), bottom: Radius.circular(1)),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B3A40), Color(0xFF1A2B30)]),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w / 2 - 97,
                    bottom: 79,
                    width: 9,
                    height: 8,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE7A8),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        boxShadow: [BoxShadow(color: Color.fromRGBO(255, 214, 120, .55), blurRadius: 5, spreadRadius: 3)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: w / 2 - 128,
                    bottom: 34,
                    width: 70,
                    height: 70,
                    child: Opacity(
                      opacity: kf((t / 3000) % 1.0, const [0, .5, 1], const [1, .55, 1], cssEaseInOut),
                      child: const CssBox(
                        bg: [
                          CssRadial.closestSide([Color.fromRGBO(255, 214, 120, .22), Color.fromRGBO(255, 214, 120, 0)]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // In front of the road.
              Positioned(
                left: w / 2 - 32,
                bottom: 0,
                width: 20,
                height: 22,
                child: const CssBox(
                  bg: [
                    CssRadial.closestSide([Color.fromRGBO(242, 109, 61, .45), Color.fromRGBO(242, 109, 61, 0)]),
                  ],
                ),
              ),
              Positioned(
                left: w / 2 - 72,
                bottom: 22,
                width: 100,
                height: 130,
                child: adrReis(
                  t,
                  120,
                  700,
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _bygg(
                      t,
                      type,
                      ny: false,
                      vars: {'adrHusFarge': husFarge, 'adrEtasjeC': etasje ? const Color(0xFFBFFBE6) : const Color(0xFFFFD27A)},
                      ops: {'adrEtasjeOp': etasje ? 1 : 0},
                      nr: nr,
                    ),
                  ),
                ),
              ),
              Positioned(left: w / 2 - 41, top: ringTop, width: 38, height: 11, child: _ring(t, 950)),
              Positioned(left: w / 2 - 41, top: pinTop, width: 38, height: 48, child: _pin(t, type, 550)),
              if (ny) ..._gnister(t, w, 1200),
              _aegil(t, w, 700),
              Positioned(right: 10, top: 12, child: _boble(t, tekst, 1150, 130)),
            ],
          );
        },
      ),
    );
  }
}

/// Adresse · dørskilt: the enamel sign under the scene (`adrSkilt`).
class AdrDorskilt extends StatelessWidget {
  const AdrDorskilt({super.key, required this.nr, required this.eyebrow, required this.gate, required this.sub, this.delayMs = 300, this.hoyre});

  final String nr, eyebrow, gate, sub;
  final double delayMs;

  /// Replaces the screws on the right ("Endre" in the new-address card).
  final Widget? hoyre;

  @override
  Widget build(BuildContext context) {
    final skilt = CssBox(
      radius: BorderRadius.circular(18),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEDF3F2)]),
      ],
      shadows: const [
        CssShadow.inset(0, 0, 0, 2.5, Color(0xFFFFFFFF)),
        CssShadow.inset(0, 0, 0, 4, Color(0xFF1E4F5C)),
        CssShadow(0, 4, 0, 0, Color(0xFF9FB2B6)),
        CssShadow(0, 18, 26, -12, Color.fromRGBO(3, 14, 20, .85)),
      ],
      padding: EdgeInsets.fromLTRB(10, 10, hoyre == null ? 30 : 10, 11),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              CssBox(
                width: 44,
                height: 44,
                radius: BorderRadius.circular(22),
                bg: const [
                  CssRadial([Color(0xFFFFB089), Color(0xFFF26D3D), Color(0xFFD2501F)], stops: [0, .55, 1], rx: .7, ry: .6, cx: .4, cy: .28),
                ],
                shadows: const [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                  CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .12)),
                  CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                  CssShadow(0, 8, 12, -5, Color.fromRGBO(120, 40, 10, .55)),
                ],
                child: Center(
                  child: Text(
                    nr,
                    maxLines: 1,
                    style: jakarta(
                      19,
                      em: -.03,
                      shadows: const [Shadow(color: Color.fromRGBO(120, 40, 10, .45), offset: Offset(0, 1))],
                    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#1F8A66"><path d="M3 11L12 3.5 21 11v10H3z"/></svg>', width: 10, height: 10),
                        const SizedBox(width: 5),
                        Text(
                          eyebrow,
                          style: inter(9.5, weight: FontWeight.w800, em: .14, color: const Color(0xFF1F8A66)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      gate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(17, em: -.02, height: 1.15, color: const Color(0xFF173E48)),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(11, weight: FontWeight.w700, color: const Color(0xFF57534B)),
                    ),
                  ],
                ),
              ),
              ?hoyre,
            ],
          ),
          if (hoyre == null) ...[const Positioned(right: -19, top: 0, child: _Skrue()), const Positioned(right: -19, bottom: 0, child: _Skrue())],
        ],
      ),
    );
    return LfOnce(
      ms: delayMs + 600,
      builder: (context, t, child) {
        final p = kfP(t, delayMs, 600);
        final y = kf(p, const [0, .6, 1], const [18, -3, 0], _kSpring);
        final rx = kf(p, const [0, .6, 1], const [75, -10, 0], _kSpring);
        final o = kf(p, const [0, .6, 1], const [0, 1, 1], _kSpring);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, -1 / 600)
              ..translateByDouble(0, y, 0, 1)
              ..rotateX(rad(rx)),
            child: child,
          ),
        );
      },
      child: skilt,
    );
  }
}

class _Skrue extends StatelessWidget {
  const _Skrue();

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(center: Alignment(-.3, -.4), colors: [Colors.white, Color(0xFFAEB9BC), Color(0xFF7F8B90)], stops: [0, .6, 1]),
      boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, .2), offset: Offset(0, 1))],
    ),
  );
}

// ── Ny adresse · byggeplass ────────────────────────────────────────────────

class AdrByggeplass extends StatelessWidget {
  const AdrByggeplass({super.key, required this.type, required this.bygd, required this.lys, required this.husFarge, required this.nr, required this.tekst});

  final AdrType type;

  /// An address is chosen: the building stands (`naBygd`); else the plot.
  final bool bygd;

  /// The door note is written: windows and lamp lit (`naWin`, `naLampOp`).
  final bool lys;
  final Color husFarge;
  final String nr, tekst;

  static const _topp = {AdrType.hus: (13.0, 54.0), AdrType.jobb: (20.0, 61.0), AdrType.hytte: (42.0, 83.0)};

  @override
  Widget build(BuildContext context) {
    return LfLoop(
      frozenMs: 6000,
      builder: (context, t, _) => LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final (pinTop, ringTop) = _topp[type]!;
          final win = lys ? const Color(0xFFFFD27A) : const Color(0xFF24434D);
          final winB = lys ? const Color(0xFFBFF5E4) : const Color(0xFF2C5562);
          return _Gate(
            t: t,
            h: 176,
            stjerner: 3,
            skyTop2: 54,
            hillsH: 90,
            children: [
              Stack(children: _naboer(t, w, lys: false)),
              if (!bygd) ...[
                Positioned(
                  left: w / 2 - 76,
                  bottom: 27,
                  width: 108,
                  height: 6,
                  child: const CssBox(
                    bg: [
                      CssRadial.closestSide([Color.fromRGBO(159, 240, 212, .35), Color.fromRGBO(159, 240, 212, 0)]),
                    ],
                  ),
                ),
                for (final l in [w / 2 - 78, w / 2 + 29])
                  Positioned(
                    left: l,
                    bottom: 26,
                    width: 3,
                    height: 17,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                        gradient: LinearGradient(colors: [Color(0xFFE2C08A), Color(0xFFA8834E)]),
                      ),
                    ),
                  ),
                Positioned(
                  left: w / 2 - 76,
                  bottom: 38,
                  width: 106,
                  height: 3,
                  child: const CustomPaint(painter: _Sperrebaand()),
                ),
                Positioned(
                  left: w / 2 - 72,
                  bottom: 30,
                  width: 100,
                  height: 130,
                  child: Transform.scale(
                    scale: .8,
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: Offset(0, kf((t / 3000) % 1.0, const [0, .5, 1], const [0, -5, 0], cssEaseInOut)),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _GhostInn(
                          key: ValueKey(type),
                          child: AdrTegning(
                            bilde: switch (type) {
                              AdrType.hus => kGhostHus,
                              AdrType.jobb => kGhostJobb,
                              AdrType.hytte => kGhostHytte,
                            },
                            t: t,
                            width: switch (type) {
                              AdrType.jobb => 92,
                              _ => 100,
                            },
                            height: switch (type) {
                              AdrType.hus => 116,
                              AdrType.jobb => 112,
                              AdrType.hytte => 86,
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: w / 2 - 46,
                  top: 22,
                  child: Opacity(
                    opacity: kf((t / 2200) % 1.0, const [0, .5, 1], const [.25, 1, .25], cssEaseInOut),
                    child: CssBox(
                      height: 20,
                      radius: BorderRadius.circular(7),
                      bg: const [
                        CssLinear(180, [Color.fromRGBO(4, 20, 28, .55), Color.fromRGBO(4, 20, 28, .55)]),
                      ],
                      shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(159, 240, 212, .4))],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          'LEDIG TOMT',
                          style: inter(9, weight: FontWeight.w800, em: .12, color: const Color(0xFF9FF0D4)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (bygd) ...[
                Positioned(
                  left: w / 2 - 72,
                  bottom: 22,
                  width: 100,
                  height: 130,
                  child: Transform.scale(
                    scale: .86,
                    alignment: Alignment.bottomCenter,
                    child: _Stund(
                      key: ValueKey('bygd-$type'),
                      builder: (bt) => adrReis(
                        bt,
                        100,
                        700,
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _bygg(t, type, ny: true, vars: {'naHusFarge': husFarge, 'naWin': win, 'naWinB': winB}, ops: {'naLampOp': lys ? 1 : 0}, nr: nr, roykOp: lys ? 1 : 0),
                        ),
                        curve: const Cubic(.3, 1.35, .5, 1),
                      ),
                    ),
                  ),
                ),
                _Stund(
                  key: ValueKey('pin-$type'),
                  builder: (bt) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(left: w / 2 - 41, top: ringTop, width: 38, height: 11, child: _ring(bt, 950)),
                      Positioned(left: w / 2 - 41, top: pinTop, width: 38, height: 48, child: _pin(bt, type, 500)),
                      ..._gnister(bt, w, 1150),
                    ],
                  ),
                ),
              ],
              _aegil(t, w, 500),
              // The bubble restarts when Ægil says something new.
              Positioned(
                right: 10,
                top: 12,
                child: _Stund(key: ValueKey(tekst), builder: (bt) => _boble(bt, tekst, 200, 132)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Sperrebaand extends CustomPainter {
  const _Sperrebaand();

  @override
  void paint(Canvas canvas, Size size) {
    final o = Paint()..color = const Color(0xFFF26D3D);
    final h = Paint()..color = Colors.white;
    for (var x = 0.0; x < size.width; x += 14) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 7, size.height), o);
      canvas.drawRect(Rect.fromLTWH(x + 7, 0, 7, size.height), h);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `naGhInn` .5s when the ghost changes type.
class _GhostInn extends StatelessWidget {
  const _GhostInn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 500,
    builder: (context, t, child) {
      final p = (t / 500).clamp(0.0, 1.0);
      const c = Cubic(.3, 1.4, .5, 1);
      final s = kf(p, const [0, .6, 1], const [.6, 1.06, 1], c);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.scale(scale: s, alignment: Alignment.bottomCenter, child: child),
      );
    },
    child: child,
  );
}

/// A clock from the moment this child appeared (ms).
class _Stund extends StatelessWidget {
  const _Stund({super.key, required this.builder});
  final Widget Function(double t) builder;

  @override
  Widget build(BuildContext context) => LfOnce(ms: 2600, builder: (context, t, _) => builder(t));
}
