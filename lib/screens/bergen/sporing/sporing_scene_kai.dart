import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../common/auth/launch/launch_onboarding.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/svg_sti.dart';
import 'sporing_bits.dart';

/// What the scenes print on their signs, notes and labels.
class SpSceneInfo {
  const SpSceneInfo({
    required this.butikk,
    this.logo,
    this.linjer = const [],
    this.total = '',
    this.adresse = '',
    this.kode = '',
    this.klokke = '',
    this.kunde = '',
    this.sykkel = true,
    this.partner = false,
    this.henting = false,
    this.minIgjen,
    this.pct = .62,
    this.slutt,
    this.totalSek,
    this.meterIgjen,
    this.spartSek,
    this.poeng,
  });

  final String butikk;
  final String? logo;

  /// `1× Classic` lines for the receipt notes.
  final List<String> linjer;
  final String total;
  final String adresse;
  final String kode;
  final String klokke;

  /// The customer's first name (the counter bubble).
  final String kunde;
  final bool sykkel;
  final bool partner;
  final bool henting;

  /// Minutes left in the kitchen (the «På komfyren» pill).
  final int? minIgjen;

  /// Share of the kitchen time spent (the pill's conic ring).
  final double pct;

  /// When the courier is due at the door and the length of the leg in
  /// seconds (the map card's countdown).
  final DateTime? slutt;
  final int? totalSek;

  /// Metres left to the door (`distance_metres`); null: no distance shown.
  final int? meterIgjen;

  /// Seconds delivered before the promised end (SPART TID), when positive.
  final int? spartSek;

  /// Points for the order, when the ledger answered.
  final int? poeng;

  /// The street number, for the house badge.
  String get husnummer {
    final m = RegExp(r'\d+').firstMatch(adresse);
    return m?.group(0) ?? '';
  }

  /// The street without the number and the city.
  String get gate {
    final first = adresse.split(',').first.trim();
    return first.isEmpty ? adresse : first;
  }
}

/// `sceneKamera 1.1s .05s cubic-bezier(.2,.8,.2,1)` — the scene fading in
/// from a slight zoom.
class SpSceneKamera extends StatelessWidget {
  const SpSceneKamera({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 1150,
    child: child,
    builder: (context, t, child) {
      final p = const Cubic(.2, .8, .2, 1).transform(kfP(t, 50, 1100));
      return Opacity(
        opacity: p,
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 8 * (1 - p), 0)..scaleByDouble(1.06 - .06 * p, 1.06 - .06 * p, 1, 1), child: child),
      );
    },
  );
}

/// `sceneInn .7s .9s cubic-bezier(.2,.9,.3,1)` — the later scenes rising in.
class SpSceneInn extends StatelessWidget {
  const SpSceneInn({super.key, required this.child, this.delay = 900});

  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + 700,
    child: child,
    builder: (context, t, child) {
      final p = cssSkjerm.transform(kfP(t, delay, 700));
      return Opacity(
        opacity: p,
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 22 * (1 - p), 0)..scaleByDouble(.96 + .04 * p, .96 + .04 * p, 1, 1), child: child),
      );
    },
  );
}

/// **Sporing · Bekreftet** (L6489): the quay at dusk (baked from the
/// prototype's WebGL canvas), the store's sign, the MOTTATT sticker and the
/// Æ sticker slapped on, the receipt note, Ægil rowing in (`roAnkomst`),
/// stepping out of the boat (`aegUt` / `aegVis`), walking to the door
/// (`aegGaa` with `aegSteg` ×4, `aegInnDoer`) and popping up at it
/// (`aegDorUt`, `aegVink`). 390 × 472.
class SpSceneKai extends StatelessWidget {
  const SpSceneKai({super.key, required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) {
    return SpSceneKamera(
      child: SizedBox(
        width: 390,
        height: 472,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/sporing/kai.jpg', fit: BoxFit.fill, filterQuality: FilterQuality.medium),
              ),
              // The storefront's props (left 92, top 84, 204 × 218).
              Positioned(left: 92, top: 84, width: 204, height: 218, child: _Butikkfront(info: info)),
              // Ægil rowing in (left 96, top 282).
              Positioned(left: 96, top: 282, child: _Baat(dur: 2900, delay: 250)),
              // Ægil walking to the door (left 118, top 226, 60 × 72).
              const Positioned(left: 118, top: 226, width: 60, height: 72, child: _AegilGaar()),
              // The bottom fade.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 160,
                child: IgnorePointer(
                  child: CssBox(
                    bg: [
                      CssLinear(180, [rgba(6, 20, 28, 0), rgba(6, 20, 28, .45)]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Butikkfront extends StatelessWidget {
  const _Butikkfront({required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) {
    final navn = info.butikk.toUpperCase();
    final deler = navn.split(' ');
    final skilt = deler.length >= 2 ? '${deler.first}\n${deler.sublist(1).join(' ')}' : navn;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The sign (left 34, top 22, 136 × 34).
        Positioned(
          left: 34,
          top: 22,
          child: CssBox(
            width: 136,
            height: 34,
            radius: BorderRadius.circular(9),
            clip: true,
            bg: const [
              CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF6F1E8)]),
            ],
            shadows: [
              const CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)),
              CssShadow.inset(0, -2, 4, 0, rgba(122, 58, 34, .12)),
              const CssShadow(0, 0, 0, 3, Color(0xFF7A3A22)),
              CssShadow(0, 0, 0, 4, rgba(0, 0, 0, .25)),
              CssShadow(0, 0, 26, 6, rgba(255, 240, 215, .3)),
              CssShadow(0, 6, 10, 0, rgba(0, 0, 0, .35)),
            ],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpLogo(size: 30, radius: 8, url: info.logo, name: info.butikk),
                const SizedBox(width: 6),
                Text(
                  skilt,
                  textAlign: TextAlign.center,
                  style: jakarta(11, em: -.01, height: 1, color: const Color(0xFF7A3A22)),
                ),
              ],
            ),
          ),
        ),
        // MOTTATT (left 8, top 150), `klistre .6s 5.5s`.
        Positioned(
          left: 8,
          top: 150,
          child: SpKlistre(
            delay: 5500,
            child: CssBox(
              radius: BorderRadius.circular(6),
              padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
              bg: const [
                CssLinear(180, [Color(0xFF7FF0CB), Color(0xFF3FBF9B)]),
              ],
              shadows: [const CssShadow(0, 0, 0, 2.5, Color(0xFFFFFFFF)), CssShadow(0, 4, 8, 0, rgba(4, 18, 26, .5))],
              child: Text('MOTTATT', style: jakarta(12, em: .06, color: const Color(0xFF0F3B2E))),
            ),
          ),
        ),
        // The Æ sticker (left 78, top 172, 46 × 37), `klistre .6s 5.7s`.
        Positioned(
          left: 78,
          top: 172,
          child: SpKlistre(
            delay: 5700,
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: rgba(4, 18, 26, .55), offset: const Offset(0, 4), blurRadius: 5)],
              ),
              child: const LfMerke(w: 46, h: 37),
            ),
          ),
        ),
        // The receipt note (left 138, top 106, 40 wide), `aegDorUt .4s 5.2s`.
        Positioned(
          left: 138,
          top: 106,
          child: _DorUt(
            delay: 5200,
            dur: 400,
            curve: cssEaseOut,
            child: Transform.rotate(
              angle: rad(3),
              child: SpKvitteringLapp(info: info, width: 40),
            ),
          ),
        ),
        // Ægil's shadow and Ægil at the door (left 122, top 128, 76 wide).
        Positioned(
          left: 126,
          top: 208,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              width: 66,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(4, 18, 26, .5)),
            ),
          ),
        ),
        Positioned(
          left: 122,
          top: 128,
          child: _DorUt(
            delay: 5150,
            dur: 500,
            curve: cssKlistre,
            child: _Vink(delay: 5700, child: aegil('popup', w: 76, h: 76)),
          ),
        ),
      ],
    );
  }
}

/// A tiny receipt note (`font-size:4.5px`): the store, the lines, the
/// address and the total.
class SpKvitteringLapp extends StatelessWidget {
  const SpKvitteringLapp({super.key, required this.info, required this.width});

  final SpSceneInfo info;
  final double width;

  @override
  Widget build(BuildContext context) {
    final f = width / 40;
    return Container(
      width: width,
      padding: EdgeInsets.fromLTRB(4 * f, 4 * f, 4 * f, 5 * f),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF6),
        boxShadow: [BoxShadow(color: rgba(0, 0, 0, .4), offset: const Offset(0, 2), blurRadius: 4)],
      ),
      child: DefaultTextStyle(
        style: inter(4.5 * f, weight: FontWeight.w700, height: 1.5, color: kSpInk),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.butikk.toUpperCase(),
              style: inter(5 * f, weight: FontWeight.w800, height: 1.5, color: kSpInk),
            ),
            for (final l in info.linjer.take(3)) Text(l, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (info.adresse.isNotEmpty) Text(info.gate, maxLines: 1, overflow: TextOverflow.ellipsis),
            Container(
              margin: EdgeInsets.only(top: 2 * f),
              padding: EdgeInsets.only(top: 1 * f),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kSpInk, width: 1)),
              ),
              width: double.infinity,
              child: Text(
                info.total,
                style: inter(4.5 * f, weight: FontWeight.w800, height: 1.5, color: kSpInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `aegDorUt` — opacity 0→1, translateY(12→0) scale(.8→1), origin bottom.
class _DorUt extends StatelessWidget {
  const _DorUt({required this.child, required this.delay, required this.dur, required this.curve});

  final Widget child;
  final double delay, dur;
  final Curve curve;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = curve.transform(kfP(t, delay, dur));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.translationValues(0, 12 * (1 - p), 0)..scaleByDouble(.8 + .2 * p, .8 + .2 * p, 1, 1), child: child),
      );
    },
  );
}

/// `aegVink 2.6s` — rotate 0 → −6 → 6 → 0 from the feet.
class _Vink extends StatelessWidget {
  const _Vink({required this.child, this.delay = 0, this.dur = 2600});

  final Widget child;
  final double delay, dur;

  @override
  Widget build(BuildContext context) => LfLoop(
    child: child,
    builder: (context, t, child) {
      final e = t - delay;
      final p = e < 0 ? 0.0 : (e / dur) % 1.0;
      final r = kf(p, const [0, .25, .75, 1], const [0, -6, 6, 0], cssEaseInOut);
      return Transform.rotate(angle: rad(r), alignment: Alignment.bottomCenter, child: child);
    },
  );
}

/// Ægil waving from the feet (`aegVink`), reusable.
Widget spVink(Widget child, {double dur = 2600, double delay = 0}) => _Vink(dur: dur, delay: delay, child: child);

/// The rowing boat (64 × 44): `roAnkomst` in, `roVugg` rocking, three oar
/// strokes (`aareRo` / `aareRoB`) and Ægil fading out when he steps ashore.
class _Baat extends StatelessWidget {
  const _Baat({required this.dur, required this.delay});

  final double dur, delay;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    builder: (context, t, child) {
      final p = const Cubic(.25, .7, .25, 1).transform(kfP(t, delay, dur));
      final x = kf(p, const [0, .55, 1], const [-360, -120, 0]);
      final y = kf(p, const [0, .55, 1], const [14, 5, 0]);
      final k = kf(p, const [0, .55, 1], const [.82, .94, 1]);
      final o = kf(p, const [0, .12, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(x, y, 0)..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
    child: LfLoop(
      builder: (context, t, child) {
        // roVugg 2.2s
        final p = (t / 2200) % 1.0;
        const st = [0.0, .25, .5, .75, 1.0];
        final y = kf(p, st, const [0, -1.2, -1.8, -.6, 0], cssEaseInOut);
        final r = kf(p, st, const [-1.2, .4, 1.4, .2, -1.2], cssEaseInOut);
        return Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, y, 0)..rotateZ(rad(r)), child: child);
      },
      child: SizedBox(
        width: 64,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ægil in the boat, gone at 3.1 s.
            Positioned(
              left: 14,
              top: 2,
              child: LfOnce(
                ms: 3350,
                builder: (context, t, child) => Opacity(opacity: 1 - kfP(t, 3100, 250), child: child),
                child: aegil('front', w: 36, h: 36),
              ),
            ),
            // Oars and hull.
            Positioned.fill(
              child: LfOnce(
                ms: 250 + 1100 * 3,
                builder: (context, t, _) {
                  final e = t - 250;
                  final p = e < 0 || e >= 3300 ? 0.0 : (e / 1100) % 1.0;
                  final a = kf(p, const [0, .5, 1], const [-28, 22, -28], cssEaseInOut);
                  return CustomPaint(painter: _BaatPainter(oar: a));
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BaatPainter extends CustomPainter {
  const _BaatPainter({required this.oar});

  final double oar;

  static final Path _skrog1 = svgSti('M6 24 C10 36 54 36 58 24 L62 22 C60 30 52 40 32 40 C12 40 4 30 2 22 Z');
  static final Path _skrog2 = svgSti('M4 22 C14 33 50 33 60 22 L62 22 C56 34 46 38 32 38 C18 38 8 34 2 22 Z');
  static final Path _skrog3 = svgSti('M6 24 C14 30 50 30 58 24 L61 22 C54 30 10 30 3 22 Z');
  static final Path _ripe = svgSti('M4 23 C14 29 50 29 60 23');

  @override
  void paint(Canvas canvas, Size size) {
    void aare(Offset pivot, Offset tip, Offset blade, double bladeRot, double rot) {
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(rad(rot));
      canvas.translate(-pivot.dx, -pivot.dy);
      canvas.drawLine(
        pivot,
        tip,
        Paint()
          ..color = const Color(0xFF8A5A2B)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.save();
      canvas.translate(blade.dx, blade.dy);
      canvas.rotate(rad(bladeRot));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 6, height: 3.2), Paint()..color = const Color(0xFFB07A3C));
      canvas.restore();
      canvas.restore();
    }

    aare(const Offset(14, 27), const Offset(3, 40), const Offset(2.5, 40.5), -50, oar);
    aare(const Offset(50, 27), const Offset(61, 40), const Offset(61.5, 40.5), 50, -oar);
    canvas.drawPath(_skrog1, Paint()..color = const Color(0xFF6B4A2A));
    canvas.drawPath(_skrog2, Paint()..color = const Color(0xFF8C6338));
    canvas.drawPath(_skrog3, Paint()..color = const Color(0xFFA5763D));
    canvas.drawPath(
      _ripe,
      Paint()
        ..color = const Color(0xFFF2C14E)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BaatPainter old) => old.oar != oar;
}

/// Ægil walking from the boat to the door: `aegGaa 1.5s 3.2s`, `aegVis .2s
/// 3.2s`, `aegSteg .38s ×4`, `aegInnDoer .5s 4.72s`.
class _AegilGaar extends StatelessWidget {
  const _AegilGaar();

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 5300,
    builder: (context, t, _) {
      final g = cssEaseInOut.transform(kfP(t, 3200, 1500));
      final x = kf(g, const [0, .7, 1], const [0, 92, 112]);
      final y = kf(g, const [0, .7, 1], const [0, 0, -6]);
      final vis = cssEaseOut.transform(kfP(t, 3200, 200));
      final e = t - 3200;
      final stegP = e < 0 || e >= 380 * 4 ? 0.0 : (e / 380) % 1.0;
      final sy = kf(stegP, const [0, .5, 1], const [0, -3, 0], cssEaseInOut);
      final sr = kf(stegP, const [0, .5, 1], const [0, -2, 0], cssEaseInOut);
      final inn = cssEaseIn.transform(kfP(t, 4720, 500));
      final k = 1 - .22 * inn;
      return Opacity(
        opacity: (vis * (1 - inn)).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(x, y),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 8,
                top: 64,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(
                    width: 44,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(4, 18, 26, .5)),
                  ),
                ),
              ),
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translateByDouble(0, sy - 8 * inn, 0, 1)
                  ..scaleByDouble(-k, k, 1, 1)
                  ..rotateZ(rad(sr)),
                child: ColorFiltered(colorFilter: ColorFilter.mode(rgba(0, 0, 0, .45 * inn), BlendMode.srcATop), child: aegil('side', w: 60, h: 70)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
