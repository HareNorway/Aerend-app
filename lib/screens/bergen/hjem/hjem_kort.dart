import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;

// ── Hjem sheet cards, in design px (prototype L2841–3298) ──────────────────

const String _kLyn = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M13.6 2L4.4 13.6h6.3L9.4 22l10.2-12.8h-6.5z" fill="#FFFFFF"/></svg>';

/// Hurtigbestilling · inngang (L2841): Ægil with a lightning badge, the
/// usual order, and the orange "Bestill" key.
class HjemHurtigInngang extends StatelessWidget {
  const HjemHurtigInngang({super.key, required this.linje, required this.onTap});

  final String linje;
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
                      bg: const [CssLinear(180, [Color(0xFFA9C5D9), Color(0xFF7E9DAD), Color(0xFF4E7383)], [0, .55, 1])],
                      shadows: const [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .55)),
                        CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
                      ],
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 25 - 31,
                            bottom: -7,
                            width: 62,
                            child: LfLoop(
                              builder: (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3800), child: child),
                              child: Image.asset('assets/images/dashboard/popup.png', width: 62, filterQuality: FilterQuality.medium),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -4,
                    width: 22,
                    height: 22,
                    child: CssBox(
                      radius: BorderRadius.circular(11),
                      bg: const [CssLinear(180, [Color(0xFFFFA77C), Color(0xFFE95C2C)])],
                      shadows: const [CssShadow(0, 0, 0, 2.5, Color(0xFF1E4F5C)), CssShadow(0, 2, 0, 2.5, Color(0xFF0F2F38))],
                      child: Center(
                        child: LfLoop(
                          // hbLyn 3.2s
                          builder: (context, t, child) {
                            final p = (t / 3200) % 1.0;
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
                          child: SvgPicture.string(_kLyn, width: 11, height: 11),
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
                  Text('Hurtigbestilling', style: jakarta(15, em: -.015, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(
                    linje,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: inter(11.5, color: const Color(0xFFC4D8DE)).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
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
              padding: const EdgeInsets.fromLTRB(13, 0, 15, 0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    left: 8 - 13,
                    right: 8 - 15,
                    top: 2,
                    height: 40 * .45,
                    child: DecoratedBox(
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.string(_kLyn, width: 13, height: 13),
                      const SizedBox(width: 6),
                      Text('Bestill', style: jakarta(13.5, shadows: const [Shadow(color: Color.fromRGBO(120, 40, 10, .35), offset: Offset(0, 1))])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum HjemChip { bergensk, bydel }

/// "Butikker på Bryggen" / "Populært i kveld" with its chip, the category
/// dots (stores only) and the "Se alle" pill.
class HjemSeksjonHode extends StatelessWidget {
  const HjemSeksjonHode({
    super.key,
    required this.tittel,
    required this.chip,
    required this.chipTekst,
    required this.onSeAlle,
    this.prikker,
    this.prikk = 0,
    this.topp = 12,
  });

  final String tittel;
  final HjemChip chip;
  final String chipTekst;
  final VoidCallback onSeAlle;

  /// Number of category dots under the title (null: none).
  final int? prikker;
  final int prikk;
  final double topp;

  @override
  Widget build(BuildContext context) {
    final gull = chip == HjemChip.bergensk;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topp, 0, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(tittel, maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: jakarta(15, em: gull ? -.02 : -.01)),
                    ),
                    SizedBox(width: gull ? 7 : 8),
                    CssBox(
                      height: 24,
                      radius: BorderRadius.circular(999),
                      bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .05)])],
                      shadows: const [
                        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
                      ],
                      padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CssBox(
                            width: 16,
                            height: 16,
                            radius: BorderRadius.circular(8),
                            bg: [
                              gull
                                  ? const CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)])
                                  : const CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
                            ],
                            shadows: [
                              CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, gull ? .7 : .5)),
                              CssShadow(0, 1, 0, 0, gull ? const Color(0xFFA87418) : const Color(0xFFA63A12)),
                            ],
                            child: Center(
                              child: SvgPicture.string(
                                gull
                                    ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#5A3C10"><path d="M12 2.5l9 8.2V21H3V10.7z"/></svg>'
                                    : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFFFFF"><path d="M12 2a7 7 0 0 0-7 7c0 5.2 7 13 7 13s7-7.8 7-13a7 7 0 0 0-7-7zm0 9.6a2.6 2.6 0 1 1 0-5.2 2.6 2.6 0 0 1 0 5.2z"/></svg>',
                                width: 9,
                                height: 9,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(chipTekst, style: inter(10.5, weight: FontWeight.w800, em: .01, color: const Color(0xFFF5F3EF))),
                        ],
                      ),
                    ),
                  ],
                ),
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
          ),
          LfPress(
            scale: .95,
            ms: 140,
            onTap: onSeAlle,
            child: CssBox(
              height: 32,
              radius: BorderRadius.circular(999),
              bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, .08)])],
              shadows: const [
                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .38)),
                CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .16)),
                CssShadow(0, 8, 16, -10, Color.fromRGBO(3, 16, 24, .8)),
              ],
              padding: const EdgeInsets.fromLTRB(13, 0, 5, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Se alle', style: inter(12, weight: FontWeight.w800, em: -.005)),
                  const SizedBox(width: 7),
                  CssBox(
                    width: 22,
                    height: 22,
                    radius: BorderRadius.circular(11),
                    bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE4EEF0)])],
                    shadows: const [CssShadow(0, 1.5, 0, 0, Color.fromRGBO(10, 40, 48, .35)), CssShadow(0, 4, 8, -4, Color.fromRGBO(3, 16, 24, .7))],
                    child: Center(
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1E4F5C" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5.5l6.5 6.5-6.5 6.5"/></svg>',
                        width: 10,
                        height: 10,
                      ),
                    ),
                  ),
                ],
              ),
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

/// Utforsk-kort (L3004, `visUtforskMellom`): Ægil waving, the northern-light
/// streak, "Fjordfiske, poser og nytt" and an orange "Åpne".
class HjemUtforskKort extends StatelessWidget {
  const HjemUtforskKort({super.key, required this.linje, required this.onTap});

  final String linje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LfPress(
      scale: .985,
      ms: 160,
      onTap: onTap,
      child: CssBox(
        radius: BorderRadius.circular(22),
        clip: true,
        bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .08), Color.fromRGBO(255, 255, 255, .08)])],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
        shadows: const [
          CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
          CssShadow(0, 18, 30, -14, Color.fromRGBO(4, 18, 26, .7)),
        ],
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The blurred streak (opacity .35 × .7, `glod` 4.5s), baked once.
            Positioned(
              left: -20 - 13,
              top: -22 - 10,
              width: 360,
              height: 70,
              child: IgnorePointer(
                child: LfLoop(
                  builder: (context, t, child) {
                    final p = (t / 4500) % 1.0;
                    return Opacity(opacity: .35 * kf(p, const [0, .5, 1], const [.7, 1, .7], cssEaseInOut), child: child);
                  },
                  child: const RepaintBoundary(child: CustomPaint(painter: _Nordlys(18, 9, [Offset(0, 60), Offset(70, 24), Offset(140, 50), Offset(210, 20), Offset(260, 2), Offset(310, 16), Offset(360, 0)]))),
                ),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      const Positioned(
                        bottom: 1,
                        width: 30,
                        height: 6,
                        // blur(3px) drawn as a soft radial instead of a filter layer.
                        child: CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(0, 15, 22, .5), Color.fromRGBO(0, 15, 22, .5), Color.fromRGBO(0, 15, 22, 0)], stops: [0, .45, 1])]),
                      ),
                      LfLoop(
                        // aegVink 3.6s
                        builder: (context, t, child) {
                          final p = (t / 3600) % 1.0;
                          return Transform.rotate(
                            alignment: Alignment.bottomCenter,
                            angle: rad(kf(p, const [0, .25, .75, 1], const [0, -6, 6, 0], cssEaseInOut)),
                            child: child,
                          );
                        },
                        child: Image.asset('assets/images/dashboard/explore.png', width: 40, filterQuality: FilterQuality.medium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fjordfiske, poser og nytt', maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13, em: -.015, height: 1.2)),
                      const SizedBox(height: 1),
                      Text(linje, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .6))),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CssBox(
                  radius: BorderRadius.circular(999),
                  bg: const [CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)])],
                  shadows: const [
                    CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
                    CssShadow(0, 4, 10, -5, Color.fromRGBO(120, 50, 10, .7)),
                  ],
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Åpne', style: inter(11.5, weight: FontWeight.w800)),
                      const SizedBox(width: 5),
                      SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>',
                        width: 11,
                        height: 11,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A blurred stroke along a smooth path with the `nl-grad` mint → violet
/// gradient (the prototype's `filter:blur()` on an SVG path).
class _Nordlys extends CustomPainter {
  const _Nordlys(this.bredde, this.blur, this.pkt);

  final double bredde, blur;
  final List<Offset> pkt;

  @override
  void paint(Canvas canvas, Size size) {
    // M p0 C p1 p2 p3 C p4 p5 p6
    final path = Path()
      ..moveTo(pkt[0].dx, pkt[0].dy)
      ..cubicTo(pkt[1].dx, pkt[1].dy, pkt[2].dx, pkt[2].dy, pkt[3].dx, pkt[3].dy)
      ..cubicTo(pkt[4].dx, pkt[4].dy, pkt[5].dx, pkt[5].dy, pkt[6].dx, pkt[6].dy);
    final b = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bredde
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2)
        ..shader = const LinearGradient(colors: [Color(0xFF5CE0B8), Color(0xFF9C7BE8)]).createShader(b),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Forundringspose (L3173, lunch and dinner hours only): the bag rocking on
/// the water with a ring spreading under it, and "Sikre en".
class HjemPoseKort extends StatelessWidget {
  const HjemPoseKort({
    super.key,
    required this.tittel,
    required this.igjen,
    required this.verdi,
    required this.under,
    required this.kr,
    required this.onTap,
  });

  final String tittel, igjen, verdi, under, kr;
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
          LfPress(
            scale: .985,
            ms: 160,
            onTap: onTap,
            child: CssBox(
              radius: BorderRadius.circular(22),
              clip: true,
              bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .08), Color.fromRGBO(255, 255, 255, .08)])],
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
              shadows: const [
                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
                CssShadow(0, 20, 30, -16, Color.fromRGBO(4, 18, 26, .7)),
              ],
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: IgnorePointer(child: _SveipLys())),
                  Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 54,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned(
                              left: 4,
                              right: 4,
                              bottom: 2,
                              height: 10,
                              child: CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(60, 48, 30, .3), Color.fromRGBO(60, 48, 30, .15), Color.fromRGBO(60, 48, 30, 0)], stops: [0, .55, 1])]),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              width: 56,
                              height: 50,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  boxShadow: [BoxShadow(color: Color.fromRGBO(60, 48, 30, .2), offset: Offset(0, 6), blurRadius: 8, spreadRadius: -6)],
                                ),
                                child: SvgPicture.asset('assets/svgs/hjem/hjem_pose_kort.svg', width: 56, height: 50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#F2C14E" stroke-width="3" stroke-linejoin="round"><path d="M12 3l2.6 6.2 6.4.5-4.9 4.2 1.5 6.1L12 16.7 6.4 20l1.5-6.1L3 9.7l6.4-.5z"/></svg>',
                                  width: 9,
                                  height: 9,
                                ),
                                const SizedBox(width: 5),
                                Text('FORUNDRINGSPOSE', style: inter(9, weight: FontWeight.w800, em: .06, color: const Color.fromRGBO(255, 255, 255, .55))),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(tittel, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(14.5, em: -.02)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: const Color.fromRGBO(242, 136, 78, .22), borderRadius: BorderRadius.circular(999)),
                                  child: Text(igjen, style: inter(9.5, weight: FontWeight.w800, color: const Color(0xFFFFC9A8))),
                                ),
                                const SizedBox(width: 6),
                                Text(verdi, style: inter(9.5, weight: FontWeight.w800, color: const Color(0xFF5CE0B8)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(10, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 11),
                      CssBox(
                        radius: BorderRadius.circular(16),
                        bg: const [CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)])],
                        shadows: const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                          CssShadow(0, 2, 0, 0, Color.fromRGBO(150, 60, 15, .9)),
                          CssShadow(0, 9, 16, -8, Color.fromRGBO(120, 50, 10, .7)),
                        ],
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$kr kr', style: jakarta(15, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                            const SizedBox(height: 1),
                            Text('Sikre en', style: inter(8.5, weight: FontWeight.w800, color: const Color(0xFFFFE4D2))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `sveipLysSjelden` 18s (1.4s delay): a rare sweep of light.
class _SveipLys extends StatelessWidget {
  const _SveipLys();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // inset: -40% -60% → 220% × 180% of the card.
        final w = box.maxWidth * 2.2, h = box.maxHeight * 1.8;
        return OverflowBox(
          minWidth: w,
          maxWidth: w,
          minHeight: h,
          maxHeight: h,
          child: LfLoop(
            builder: (context, t, child) {
              final e = t - 1400;
              if (e < 0) return const SizedBox.shrink();
              final p = (e / 18000) % 1.0;
              final x = kf(p, const [0, .15, 1], const [-1.2, 1.2, 1.2], cssEaseInOut);
              return Transform.translate(offset: Offset(x * w, 0), child: child);
            },
            child: const CssBox(
              bg: [CssLinear(100, [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, 0)], [.44, .5, .56])],
            ),
          ),
        );
      },
    );
  }
}
