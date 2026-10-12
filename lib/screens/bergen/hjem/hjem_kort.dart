import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;

// ── Hjem sheet cards, in design px (prototype L2841–3298) ──────────────────

const String _kLyn = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M13.6 2L4.4 13.6h6.3L9.4 22l10.2-12.8h-6.5z" fill="#FFFFFF"/></svg>';

const String _kStjerne = 'M12 2.6l2.4 6.6 7 .3-5.5 4.3 1.9 6.7L12 16.6l-5.8 3.9 1.9-6.7-5.5-4.3 7-.3z';

/// The teal "button card" of new Bergen (L2900 Hurtigbestilling, L3023
/// Utforsk, L3201 Forundringspose): a 50 px picture tile with a star (or
/// bolt) badge that wiggles now and then (`hbLyn 3.2s`, each card at its
/// own delay), a 15 px title, an 11.5 px line, and the orange 3D key.
/// Pressed, the card sinks 2 px (.14 s).
class HjemKnappKort extends StatelessWidget {
  const HjemKnappKort({
    super.key,
    required this.flisFarger,
    this.flisLys = .55,
    required this.flis,
    required this.merkeFarger,
    required this.merkeSvg,
    this.merkeForsinkelse = 0,
    required this.tittel,
    required this.under,
    required this.knapp,
    this.knappPad = const EdgeInsets.fromLTRB(15, 0, 13, 0),
    required this.onTap,
  });

  /// The tile's top → bottom colours (0 / 55 / 100 %).
  final List<Color> flisFarger;

  /// The tile's inner top light (`inset 0 1.5px 0 rgba(255,255,255,…)`).
  final double flisLys;

  /// What stands in the tile (Ægil, the bag), laid out in its 50 × 50 box.
  final Widget flis;

  /// The badge's top → bottom colours, and its 24-unit glyph.
  final List<Color> merkeFarger;
  final String merkeSvg;

  /// `hbLyn`'s animation-delay in ms.
  final double merkeForsinkelse;

  final String tittel;
  final Widget under;

  /// The key's content (text, arrow …) and its padding.
  final Widget knapp;
  final EdgeInsets knappPad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LfPress(
      dy: 2,
      ms: 140,
      onTap: onTap,
      child: CssBox(
        radius: BorderRadius.circular(22),
        bg: const [CssLinear(160, [Color(0xFF2F6C7D), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .58, 1])],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
          CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .5)),
          CssShadow(0, 16, 26, -16, Color.fromRGBO(4, 18, 26, .8)),
        ],
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CssBox(
                      radius: BorderRadius.circular(16),
                      clip: true,
                      bg: [CssLinear(180, flisFarger, const [0, .55, 1])],
                      shadows: [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, flisLys)),
                        const CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
                      ],
                      child: flis,
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -4,
                    width: 22,
                    height: 22,
                    child: CssBox(
                      radius: BorderRadius.circular(11),
                      bg: [CssLinear(180, merkeFarger)],
                      shadows: const [CssShadow(0, 0, 0, 2.5, Color(0xFF1E4F5C)), CssShadow(0, 2, 0, 2.5, Color(0xFF0F2F38))],
                      child: Center(
                        child: LfLoop(
                          // hbLyn 3.2s (origin 50% 55%), from its delay on.
                          builder: (context, t, child) {
                            final p = (math.max(0, t - merkeForsinkelse) / 3200) % 1.0;
                            const st = [0.0, .62, .66, .71, .76, .82, 1.0];
                            final s = kf(p, st, const [1, 1, 1.22, .92, 1.12, 1, 1], cssEaseInOut);
                            final r = kf(p, st, const [0, 0, -8, 4, -3, 0, 0], cssEaseInOut);
                            return Transform(
                              alignment: const Alignment(0, .1),
                              transform: Matrix4.identity()
                                ..scaleByDouble(s, s, 1, 1)
                                ..rotateZ(rad(r)),
                              child: child,
                            );
                          },
                          child: SvgPicture.string(merkeSvg, width: 11, height: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tittel, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: jakarta(15, em: -.015, height: 1.2)),
                  const SizedBox(height: 2),
                  under,
                ],
              ),
            ),
            const SizedBox(width: 12),
            CssBox(
              height: 40,
              radius: BorderRadius.circular(14),
              clip: true,
              bg: const [CssLinear(180, [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFE95C2C)], [0, .55, 1])],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
                CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                CssShadow(0, 10, 14, -8, Color.fromRGBO(120, 40, 10, .6)),
              ],
              padding: knappPad,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The key's gloss: left/right 8 px of the key, top 2, 45 % high.
                  Positioned(
                    left: 8 - knappPad.left,
                    right: 8 - knappPad.right,
                    top: 2,
                    height: 40 * .45,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.elliptical(11, 11),
                          topRight: Radius.elliptical(11, 11),
                          bottomLeft: Radius.elliptical(20, 8),
                          bottomRight: Radius.elliptical(20, 8),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.fromRGBO(255, 255, 255, .32), Color.fromRGBO(255, 255, 255, 0)],
                        ),
                      ),
                    ),
                  ),
                  knapp,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The key's label (13.5 px, white, a 1 px brown drop).
TextStyle _knappTekst() => jakarta(13.5, shadows: const [Shadow(color: Color.fromRGBO(120, 40, 10, .35), offset: Offset(0, 1))]);

/// The card's line (11.5 px, `#C4D8DE`, tabular).
TextStyle _underTekst({Color farge = const Color(0xFFC4D8DE), FontWeight vekt = FontWeight.w600}) =>
    inter(11.5, weight: vekt, color: farge).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// Ægil in a tile, standing (`aegStaa 3.8s`, origin 50% 100%).
Widget _aegilFlis(String bilde, {required double bredde, required double bunn}) => Stack(
  clipBehavior: Clip.none,
  children: [
    Positioned(
      left: 25 - bredde / 2,
      bottom: bunn,
      width: bredde,
      child: LfLoop(
        builder: (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3800), child: child),
        child: Image.asset(bilde, width: bredde, cacheWidth: (bredde * 3).round(), filterQuality: FilterQuality.medium),
      ),
    ),
  ],
);

/// Hurtigbestilling · inngang (L2900): Ægil with the bolt, the usual order,
/// and «Bestill».
class HjemHurtigInngang extends StatelessWidget {
  const HjemHurtigInngang({super.key, required this.linje, required this.onTap});

  final String linje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HjemKnappKort(
    flisFarger: const [Color(0xFFA9C5D9), Color(0xFF7E9DAD), Color(0xFF4E7383)],
    flis: _aegilFlis('assets/images/dashboard/popup.png', bredde: 62, bunn: -7),
    merkeFarger: const [Color(0xFFFFA77C), Color(0xFFE95C2C)],
    merkeSvg: _kLyn,
    tittel: 'Hurtigbestilling',
    under: Text(linje, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: _underTekst()),
    knappPad: const EdgeInsets.fromLTRB(13, 0, 15, 0),
    knapp: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(_kLyn, width: 13, height: 13),
        const SizedBox(width: 6),
        Text('Bestill', style: _knappTekst()),
      ],
    ),
    onTap: onTap,
  );
}

/// «Butikker i Bergen» / «Populært i kveld» (Bergen L2933–2940, L3214–3216):
/// the title and, for the stores, the category dots under it. New Bergen
/// dropped the bydel, the «Bergensk» / bydel chip and the «Se alle» pill.
class HjemSeksjonHode extends StatelessWidget {
  const HjemSeksjonHode({
    super.key,
    required this.tittel,
    this.em = -.01,
    this.prikker,
    this.prikk = 0,
    this.topp = 12,
  });

  final String tittel;

  /// Letter spacing in em (the stores' title is -0.02, Populært's -0.01).
  final double em;

  /// Number of category dots under the title (null: none).
  final int? prikker;
  final int prikk;
  final double topp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topp, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tittel, maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: jakarta(15, em: em)),
          if (prikker != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  for (var n = 0; n < prikker!; n++) ...[
                    if (n > 0) const SizedBox(width: 4),
                    Container(
                      width: n == 0 ? 14 : 4,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: n == prikk ? const LinearGradient(colors: [Color(0xFFF58A55), Color(0xFFE95C2C)]) : null,
                        color: n == prikk ? null : const Color.fromRGBO(242, 138, 85, .4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The carousel position dots (22px pill for the focused card, else 6px).
class HjemPrikker extends StatelessWidget {
  const HjemPrikker({super.key, required this.antall, required this.indeks, this.onTap});

  final int antall, indeks;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var n = 0; n < antall; n++) ...[
          if (n > 0) const SizedBox(width: 6),
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(n),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: const Cubic(.3, 1.2, .5, 1),
              width: n == indeks ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: n == indeks
                      ? const [Color(0xFFF58A55), Color(0xFFE95C2C)]
                      : const [Color.fromRGBO(242, 138, 85, .35), Color.fromRGBO(242, 138, 85, .35)],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Utforsk-kort (new Bergen L3023, `visUtforskMellom`): Ægil exploring on a
/// sky tile with the mint star, «Fjordfiske, poser og nytt», the line about
/// new posts from followed stores (left out when there are none), «Åpne ›».
class HjemUtforskKort extends StatelessWidget {
  const HjemUtforskKort({super.key, required this.tittel, this.linje, required this.onTap});

  final String tittel;

  /// «N nye innlegg fra butikker du følger»; null hides the line.
  final String? linje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HjemKnappKort(
    flisFarger: const [Color(0xFFA9C5D9), Color(0xFF7E9DAD), Color(0xFF4E7383)],
    flis: _aegilFlis('assets/images/dashboard/explore.png', bredde: 58, bunn: -6),
    merkeFarger: const [Color(0xFF9FF0D4), Color(0xFF3FCB9F)],
    merkeSvg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="$_kStjerne" fill="#0E4A3A"/></svg>',
    merkeForsinkelse: 800,
    tittel: tittel,
    under: linje == null ? const SizedBox.shrink() : Text(linje!, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: _underTekst()),
    knapp: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Åpne', style: _knappTekst()),
        const SizedBox(width: 6),
        SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>',
          width: 12,
          height: 12,
        ),
      ],
    ),
    onTap: onTap,
  );
}

/// Forundringspose (new Bergen L3198, lunch and dinner hours only): the
/// button card rocking on the water with a ring spreading under it — the 3D
/// bag on a sand tile with the gold star, «Forundringspose», «N igjen i
/// kveld · verdi minst … kr», and the price as the key.
class HjemPoseKort extends StatelessWidget {
  const HjemPoseKort({
    super.key,
    required this.tittel,
    required this.igjen,
    required this.verdi,
    required this.kr,
    required this.onTap,
  });

  final String tittel, igjen, verdi, kr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LfLoop(
      // sjoVugg2 6.5s (.5s delay), origin 50% 100%
      builder: (context, t, child) {
        final p = ((t - 500) / 6500) % 1.0;
        final y = kf(p, const [0, .5, 1], const [0, -3, 0], cssEaseInOut);
        final r = kf(p, const [0, .5, 1], const [.35, -.35, .35], cssEaseInOut);
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translateByDouble(0, y, 0, 1)
            ..rotateZ(rad(r)),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // sjoRing 5.5s (.8s delay)
          Positioned(
            left: 8,
            right: 8,
            bottom: -12,
            height: 30,
            child: LfLoop(
              builder: (context, t, child) {
                final e = t - 800;
                if (e < 0) return const SizedBox.shrink();
                final p = cssEaseOut.transform((e / 5500) % 1.0);
                return Opacity(opacity: (.7 * (1 - p)).clamp(0.0, 1.0), child: Transform.scale(scale: .7 + .65 * p, child: child));
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.elliptical(999, 999)),
                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16), width: 1.5),
                ),
              ),
            ),
          ),
          // sjoSkygge 6.5s — the blurred shadow drawn as a soft radial.
          Positioned(
            left: 6,
            right: 6,
            bottom: -10,
            height: 24,
            child: LfLoop(
              builder: (context, t, child) {
                final p = ((t - 500) / 6500) % 1.0;
                final sx = kf(p, const [0, .5, 1], const [1, .92, 1], cssEaseInOut);
                final o = kf(p, const [0, .5, 1], const [.55, .4, .55], cssEaseInOut);
                return Opacity(opacity: o, child: Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(sx, 1, 1), child: child));
              },
              child: const CssBox(
                bg: [CssRadial.closestSide([Color.fromRGBO(3, 14, 20, .55), Color.fromRGBO(3, 14, 20, .3), Color.fromRGBO(3, 14, 20, 0)], stops: [0, .5, 1])],
              ),
            ),
          ),
          HjemKnappKort(
            flisFarger: const [Color(0xFFF6EAD2), Color(0xFFE6D3AE), Color(0xFFC9AE7E)],
            flisLys: .6,
            flis: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 3,
                  top: 6,
                  width: 44,
                  height: 40,
                  child: LfLoop(
                    builder: (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3800), child: child),
                    child: SvgPicture.asset('assets/svgs/hjem/hjem_pose_kort.svg', width: 44, height: 40),
                  ),
                ),
              ],
            ),
            merkeFarger: const [Color(0xFFFFE7A8), Color(0xFFE9AC3C)],
            merkeSvg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="$_kStjerne" fill="#5A3C10"/></svg>',
            merkeForsinkelse: 1600,
            tittel: tittel,
            under: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: igjen, style: _underTekst(farge: const Color(0xFFFFC9A8), vekt: FontWeight.w800)),
                  if (verdi.isNotEmpty) ...[
                    TextSpan(text: ' · ', style: _underTekst()),
                    TextSpan(text: verdi, style: _underTekst(farge: const Color(0xFF7FF0CB), vekt: FontWeight.w800)),
                  ],
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            knappPad: const EdgeInsets.symmetric(horizontal: 15),
            knapp: Text('$kr kr', style: _knappTekst().copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// Gavepapir (L2887, `snRail`): a coming-soon category's cards are wrapped —
/// dotted teal paper, orange ribbons with a bow (`gpSloyfe`), a sheen
/// (`gpGlans`) and a swinging KOMMER SNART tag (`gpLapp`). Laid out for the
/// 238px banner; [w]/[h] scale it to the card at hand.
class HjemGavepapir extends StatelessWidget {
  const HjemGavepapir({super.key, this.produkt = false});

  /// The product card's picture (126 high): ribbons at 167/42, bow 148/30.
  final bool produkt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final kx = w / 238;
        final bx = produkt ? 167.0 : 159.0, by = produkt ? 42.0 : 74.0;
        final sx = produkt ? 148.0 : 140.0, sy = produkt ? 30.0 : 62.0, hh = produkt ? 126.0 : 125.0;
        return CssBox(
          radius: BorderRadius.circular(20 * kx),
          clip: true,
          bg: const [CssRadial([Color(0xFF3A8296), Color(0xFF1E4F5C), Color(0xFF173E48)], stops: [0, .6, 1], rx: 1.2, ry: 1, cx: .2, cy: 0)],
          shadows: const [
            CssShadow.inset(0, 2, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
            CssShadow.inset(0, -14, 22, -10, Color.fromRGBO(2, 12, 18, .55)),
            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
          ],
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(child: CustomPaint(painter: _Prikker())),
              // gpGlans 5.5s (1s delay)
              Positioned.fill(
                child: LfLoop(
                  builder: (context, t, child) {
                    final e = t - 1000;
                    if (e < 0) return const SizedBox.shrink();
                    final x = kf((e / 5500) % 1.0, const [0, .55, 1], const [-1.2, -1.2, 3.2], cssEaseInOut);
                    return Transform(
                      transform: Matrix4.translationValues(x * w * .26, 0, 0)..multiply(Matrix4.skewX(rad(-18))),
                      child: child,
                    );
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: w * .26,
                      height: h,
                      child: const CssBox(bg: [CssLinear(90, [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)])]),
                    ),
                  ),
                ),
              ),
              Positioned(left: bx * kx, top: 0, bottom: 0, width: 22 * kx, child: const _Baand(loddrett: true)),
              Positioned(left: 0, right: 0, top: by / hh * h, height: 20 * kx, child: const _Baand(loddrett: false)),
              Positioned(
                left: sx * kx,
                top: sy / hh * h,
                width: 60 * kx,
                height: 44 * kx,
                child: LfLoop(
                  builder: (context, t, child) {
                    final p = (t / 3600) % 1.0;
                    final r = kf(p, const [0, .5, 1], const [0, -4, 0], cssEaseInOut);
                    final sk = kf(p, const [0, .5, 1], const [1, 1.05, 1], cssEaseInOut);
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(rad(r))
                        ..scaleByDouble(sk, sk, 1, 1),
                      child: child,
                    );
                  },
                  child: FittedBox(child: SizedBox(width: 60, height: 44, child: _Sloyfe())),
                ),
              ),
              Positioned(
                left: 12 * kx,
                top: 12 * kx,
                child: LfLoop(
                  builder: (context, t, child) => Transform.rotate(
                    alignment: Alignment.centerLeft,
                    angle: rad(kf((t / 4400) % 1.0, const [0, .5, 1], const [-7, -3, -7], cssEaseInOut)),
                    child: child,
                  ),
                  child: Transform.scale(
                    scale: kx,
                    alignment: Alignment.topLeft,
                    child: CssBox(
                      height: 26,
                      radius: const BorderRadius.horizontal(left: Radius.circular(7), right: Radius.circular(9)),
                      bg: const [CssLinear(180, [Color(0xFFFFF3D2), Color(0xFFF2D48A)])],
                      shadows: const [
                        CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)),
                        CssShadow(0, 2, 0, 0, Color(0xFFB8902E)),
                        CssShadow(0, 8, 12, -5, Color.fromRGBO(2, 12, 18, .6)),
                      ],
                      padding: const EdgeInsets.fromLTRB(7, 0, 10, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E4F5C)),
                          ),
                          const SizedBox(width: 5),
                          SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#5A3C10" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></svg>',
                            width: 10,
                            height: 10,
                          ),
                          const SizedBox(width: 5),
                          Text('KOMMER SNART', style: jakarta(10.5, em: .1, color: const Color(0xFF5A3C10))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Prikker extends CustomPainter {
  const _Prikker();

  @override
  void paint(Canvas canvas, Size size) {
    // repeating-linear-gradient(135deg, … rgba(92,224,184,.13) 13px 15px)
    final linje = Paint()
      ..color = const Color.fromRGBO(92, 224, 184, .13)
      ..strokeWidth = 2;
    final d = size.width + size.height;
    for (var o = -d; o < d; o += 15 * math.sqrt2) {
      canvas.drawLine(Offset(o, 0), Offset(o + size.height, size.height), linje);
    }
    // two dot grids, 16px apart
    final hvit = Paint()..color = const Color.fromRGBO(255, 255, 255, .2);
    final gull = Paint()..color = const Color.fromRGBO(255, 206, 120, .4);
    for (var y = 0.0; y < size.height; y += 16) {
      for (var x = 0.0; x < size.width; x += 16) {
        canvas.drawCircle(Offset(x + 4, y + 4.8), 1.6, hvit);
        canvas.drawCircle(Offset(x + 12, y + 12.8), 1.3, gull);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Baand extends StatelessWidget {
  const _Baand({required this.loddrett});

  final bool loddrett;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: loddrett ? Alignment.centerLeft : Alignment.topCenter,
          end: loddrett ? Alignment.centerRight : Alignment.bottomCenter,
          colors: const [Color(0xFFB9441A), Color(0xFFF26D3D), Color(0xFFFF9C70), Color(0xFFF26D3D), Color(0xFFB9441A)],
          stops: const [0, .22, .48, .74, 1],
        ),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(2, 12, 18, .35), blurRadius: 4)],
      ),
    );
  }
}

class _Sloyfe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget sloyfe(bool venstre) => Transform.rotate(
      angle: rad(venstre ? -14 : 14),
      child: Container(
        width: 28,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: venstre
              ? const BorderRadius.horizontal(left: Radius.elliptical(17, 15), right: Radius.elliptical(8, 9))
              : const BorderRadius.horizontal(left: Radius.elliptical(8, 9), right: Radius.elliptical(17, 15)),
          gradient: RadialGradient(
            center: Alignment(venstre ? -.3 : .3, -.3),
            radius: .9,
            colors: const [Color(0xFFFFB089), Color(0xFFF26D3D), Color(0xFFB9441A)],
            stops: const [0, .55, 1],
          ),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(2, 12, 18, .45), offset: Offset(0, 4), blurRadius: 3)],
        ),
      ),
    );
    Widget hale(bool venstre) => Transform.rotate(
      alignment: Alignment.topCenter,
      angle: rad(venstre ? 24 : -24),
      child: Container(
        width: 10,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(colors: venstre ? const [Color(0xFFB9441A), Color(0xFFF26D3D)] : const [Color(0xFFF26D3D), Color(0xFFB9441A)]),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(left: 12, top: 24, child: hale(true)),
        Positioned(right: 12, top: 24, child: hale(false)),
        Positioned(left: 1, top: 6, child: sloyfe(true)),
        Positioned(right: 1, top: 6, child: sloyfe(false)),
        Positioned(
          left: 22,
          top: 11,
          width: 16,
          height: 15,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const RadialGradient(
                center: Alignment(-.2, -.4),
                radius: .9,
                colors: [Color(0xFFFFC2A3), Color(0xFFF26D3D), Color(0xFFC2481C)],
                stops: [0, .6, 1],
              ),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(2, 12, 18, .5), offset: Offset(0, 2), blurRadius: 1.5)],
            ),
          ),
        ),
      ],
    );
  }
}
