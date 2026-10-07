import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;

// ── Under kaien (prototype L2663–2749) ────────────────────────────────────
// Under the quay, at the bottom of the screen behind the sheet: the
// surface, the planks overhead, light falling through, piles with weed,
// kelp, a fish school, drifting bubbles, net floats and a starfish. When
// the sheet is scrolled to its end its waterline lifts and the three finds
// float up (`kaien`). 390 × 300, design px.

class HjemKaienFunn {
  const HjemKaienFunn({required this.tittel, required this.under, required this.pris, required this.onTap, this.merke});
  final String tittel, under, pris;
  final VoidCallback onTap;

  /// The badge on the card («2 igjen», «I kveld»); the design's when null.
  final String? merke;
}

class HjemUnderKaien extends StatelessWidget {
  const HjemUnderKaien({super.key, required this.vist, this.reker, this.pose, this.frakt});

  /// `kaien`: the sheet is at its end (the finds rise to full opacity).
  final bool vist;

  /// The three finds, each only when it is real (backend plan Step 8): Ægil's
  /// tray, tonight's Forundringspose, and the nearest free-delivery store. A
  /// missing one is left out rather than filled with the design's sample.
  final HjemKaienFunn? reker, pose, frakt;

  int get _antall => [reker, pose, frakt].where((f) => f != null).length;

  /// The prototype's line, counted; «Ingen funn i kveld» when there is none.
  String get _linje => switch (_antall) {
        0 => 'Ingen funn i kveld. Jeg ser etter mer.',
        1 => 'Psst — jeg fant én ting som lå gjemt her.',
        2 => 'Psst — jeg fant to ting som lå gjemt her.',
        _ => 'Psst — jeg fant tre ting som lå gjemt her.',
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: ShaderMask(
        // mask: transparent → opaque over the top 16px
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000)],
          stops: [0, 16 / 300, 1],
        ).createShader(r),
        child: SizedBox(
          width: 390,
          height: 300,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E5064), Color(0xFF143B4D), Color(0xFF0B2634), Color(0xFF05161F), Color(0xFF2A2418)],
                      stops: [0, .26, .58, .84, 1],
                    ),
                  ),
                ),
              ),
              // Light cone from the surface.
              const Positioned(
                left: -390 * .08,
                right: -390 * .08,
                top: 20,
                height: 200,
                child: CssBox(bg: [CssRadial([Color.fromRGBO(152, 216, 234, .36), Color.fromRGBO(152, 216, 234, 0)], stops: [0, .72], rx: .58, ry: 1, cx: .5, cy: 0)]),
              ),
              // God rays (dypLys 9/11/13s), soft-edged instead of blurred.
              const _Straale(left: 52, width: 78, height: 290, sk: 8, a: .55, durMs: 9000, delayMs: 0),
              const _Straale(left: 168, width: 54, height: 270, sk: -6, a: .48, durMs: 11000, delayMs: 1400),
              const _Straale(left: 266, width: 88, height: 300, sk: 13, a: .45, durMs: 13000, delayMs: 800),
              // Seabed and caustics (kaustikk 6s).
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(60, 50, 32, 0), Color(0xFF3A3020), Color(0xFF2A2318)],
                      stops: [0, .3, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 56,
                child: LfLoop(
                  builder: (context, t, child) {
                    final p = (t / 6000) % 1.0;
                    final x = kf(p, const [0, .5, 1], const [0, 18, 0], cssEaseInOut);
                    final sk = kf(p, const [0, .5, 1], const [1, 1.06, 1], cssEaseInOut);
                    final o = kf(p, const [0, .5, 1], const [.55, .85, .55], cssEaseInOut);
                    return Opacity(opacity: o, child: Transform(transform: Matrix4.translationValues(x, 0, 0)..scaleByDouble(sk, sk, 1, 1), child: child));
                  },
                  child: const CustomPaint(painter: _Kaustikk()),
                ),
              ),
              // Piles with weed.
              const Positioned(left: 6, top: 0, width: 38, height: 262, child: _Paal(bunnFrac: .26, toppFrac: .74, alfa: 1, ugress: 40, ugressH: 60, lys: true)),
              const Positioned(right: 10, top: 0, width: 32, height: 246, child: _Paal(bunnFrac: .28, toppFrac: .72, alfa: .9, ugress: 38, ugressH: 56, lys: false)),
              const Positioned(left: 96, top: 0, width: 20, height: 200, child: _Paal(bunnFrac: .28, toppFrac: .72, alfa: .55, mork: true)),
              // Kelp (tareSvai).
              const Positioned(left: 30, bottom: 26, width: 60, height: 120, child: _Tare(durMs: 5500, delayMs: 0, reverse: false, opacity: .85, full: true)),
              const Positioned(right: 40, bottom: 24, width: 50, height: 96, child: _Tare(durMs: 6800, delayMs: 900, reverse: true, opacity: .75, full: false)),
              const Positioned.fill(child: CustomPaint(painter: _Linjer())),
              // Fish school (fiskSvom 18s).
              Positioned(
                left: 0,
                top: 150,
                width: 60,
                height: 24,
                child: LfLoop(
                  builder: (context, t, child) {
                    final p = (t / 18000) % 1.0;
                    final x = kf(p, const [0, .45, .5, 1], const [-60, 200, 220, -60]);
                    final y = kf(p, const [0, .45, .5, 1], const [0, -8, -6, 4]);
                    final o = kf(p, const [0, .08, .45, .5, .92, 1], const [0, .7, .7, .5, .6, 0]);
                    final flip = p >= .5 ? -1.0 : 1.0;
                    return Opacity(
                      opacity: o.clamp(0.0, 1.0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.translationValues(x, y, 0)..scaleByDouble(flip, 1, 1, 1),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Positioned(left: 0, top: 0, child: Opacity(opacity: .55, child: SvgPicture.asset('assets/svgs/hjem/hjem_orb_fisk.svg', width: 22, height: 12))),
                      Positioned(left: 26, top: 9, child: Opacity(opacity: .45, child: SvgPicture.asset('assets/svgs/hjem/hjem_orb_fisk.svg', width: 18, height: 10))),
                      Positioned(left: 14, top: 16, child: Opacity(opacity: .4, child: SvgPicture.asset('assets/svgs/hjem/hjem_orb_fisk.svg', width: 16, height: 9))),
                    ],
                  ),
                ),
              ),
              // Vignette.
              const Positioned.fill(
                child: CssBox(
                  shadows: [
                    CssShadow.inset(0, -40, 60, -20, Color.fromRGBO(0, 0, 0, .7)),
                    CssShadow.inset(40, 0, 60, -40, Color.fromRGBO(0, 0, 0, .6)),
                    CssShadow.inset(-40, 0, 60, -40, Color.fromRGBO(0, 0, 0, .6)),
                  ],
                ),
              ),
              // Bubbles (dypSvev).
              const _Boble(left: 38, top: 206, size: 5, a: .7, durMs: 7000, delayMs: 0, glans: true),
              const _Boble(left: 124, top: 230, size: 3.5, a: .6, durMs: 9000, delayMs: 1800),
              const _Boble(left: 268, top: 216, size: 4.5, a: .55, durMs: 8000, delayMs: 3200),
              const _Boble(left: 332, top: 238, size: 3, a: .5, durMs: 10000, delayMs: 900),
              // Net floats and a starfish.
              Positioned(left: 66, top: 246, width: 34, height: 37, child: _Bob(delayMs: 0, child: Opacity(opacity: .9, child: SvgPicture.asset('assets/svgs/hjem/hjem_garnkule.svg')))),
              Positioned(right: 80, top: 256, width: 22, height: 24, child: _Bob(delayMs: 1400, child: Opacity(opacity: .45, child: SvgPicture.asset('assets/svgs/hjem/hjem_garnkule.svg')))),
              Positioned(
                left: 180,
                top: 270,
                width: 26,
                height: 26,
                child: Opacity(
                  opacity: .8,
                  child: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2l2.2 6.8 7.1.2-5.7 4.3 2.1 6.8L12 16l-5.7 4.1 2.1-6.8L2.7 9l7.1-.2z" fill="#D9865A"/><path d="M12 2l2.2 6.8 7.1.2-5.7 4.3 2.1 6.8L12 16l-5.7 4.1 2.1-6.8L2.7 9l7.1-.2z" fill="none" stroke="#F0A87A" stroke-width=".8"/><g fill="#F6C49A"><circle cx="12" cy="7" r=".8"/><circle cx="12" cy="11" r=".9"/><circle cx="8.5" cy="10.5" r=".7"/><circle cx="15.5" cy="10.5" r=".7"/></g></svg>',
                  ),
                ),
              ),
              // The surface overhead: band, drifting waves, foam, planks.
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(42, 98, 114, 0), Color(0xFF2A6272), Color(0xFF245C6C), Color.fromRGBO(30, 90, 108, 0)],
                      stops: [0, 8 / 30, .58, 1],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 0, right: 0, top: 12, height: 22, child: _Overflate()),
              const Positioned(
                left: 0,
                right: 0,
                top: 28,
                height: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(214, 242, 250, 0), Color.fromRGBO(214, 242, 250, .3), Color.fromRGBO(214, 242, 250, 0)],
                      stops: [0, .3, 1],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 0, right: 0, top: 32, height: 40, child: _Planker()),
              const Positioned(
                left: 0,
                right: 0,
                top: 30,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(2, 12, 18, .55), Color.fromRGBO(2, 12, 18, 0)]),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                top: 36,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(2, 12, 18, .9), Color.fromRGBO(2, 12, 18, .45), Color.fromRGBO(2, 12, 18, 0)],
                      stops: [0, .45, 1],
                    ),
                  ),
                ),
              ),
              // Ægil and the line (funnOpp .5s .06s).
              Positioned(
                left: 16,
                right: 16,
                top: 46,
                child: _Opp(
                  delayMs: 60,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(center: Alignment(0, -.4), colors: [Color(0xFF2A6272), Color(0xFF173E48)], stops: [0, .8]),
                          boxShadow: [
                            BoxShadow(color: Color.fromRGBO(190, 232, 244, .5), spreadRadius: 1.5),
                            BoxShadow(color: Color.fromRGBO(0, 0, 0, .8), offset: Offset(0, 6), blurRadius: 6, spreadRadius: -6),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [Positioned(left: 0, right: 0, bottom: -3, child: Image.asset('assets/images/dashboard/front.png', width: 36))],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UNDER KAIEN', style: inter(9, weight: FontWeight.w800, em: .08, color: const Color(0xFF9FD3DE))),
                            Text(
                              _linje,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(13, em: -.015, height: 1.2, color: const Color(0xFFF5F3EF), shadows: const [Shadow(color: Color.fromRGBO(0, 0, 0, .5), offset: Offset(0, 1), blurRadius: 3)]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The three finds.
              Positioned(
                left: 7.5,
                right: 7.5,
                top: 94,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: vist ? 1 : 0),
                  duration: const Duration(milliseconds: 550),
                  curve: const Cubic(.2, .9, .3, 1),
                  builder: (context, v, child) => Opacity(
                    opacity: .35 + .65 * v,
                    child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reker case final reker?)
                      Expanded(
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.5), child: _Funn(
                          inn: 100,
                          svevMs: 5200,
                          svevDelay: 600,
                          // The design's «+5 poeng» is not something a tray find pays; only a
                          // badge the find itself carries is shown (backend plan Step 8).
                          merke: reker.merke ?? '',
                          merkeBg: const [Color(0xFFFFE7A8), Color(0xFFE9AC3C)],
                          merkeKant: const Color(0xFFA87418),
                          merkeC: const Color(0xFF4A300A),
                          merkeRot: 5,
                          bilde: const _Bilde(
                            bg: [Color(0xFFF7C8AE), Color(0xFFD8745A), Color(0xFF8E3A2A)],
                            glod: Color.fromRGBO(255, 196, 160, .55),
                            skygge: Color.fromRGBO(60, 15, 5, .45),
                            skyggeW: 70,
                            svg: 'assets/svgs/hjem/vare_reker.svg',
                            w: 74,
                            h: 60,
                          ),
                          tag: 'TILBUD',
                          tagIkon: '<path d="M20 12l-8 8-8-8 8-8z"/>',
                          tagC: const Color(0xFFFFB27A),
                          tittel: reker.tittel,
                          under: reker.under,
                          pris: reker.pris,
                          prisBg: const [Color(0xFFFF9466), Color(0xFFE95C2C)],
                          prisKant: const Color(0xFFA63A12),
                          prisC: Colors.white,
                          onTap: reker.onTap,
                        )),
                      ),
                      if (pose case final pose?)
                      Expanded(
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.5), child: _Funn(
                          inn: 220,
                          svevMs: 5800,
                          svevDelay: 1100,
                          merke: pose.merke ?? '',
                          merkeBg: const [Color(0xFF8CF0D2), Color(0xFF3CC79F)],
                          merkeKant: const Color(0xFF1F8A6B),
                          merkeC: const Color(0xFF0F2A30),
                          merkeRot: -4,
                          bilde: const _Bilde(
                            bg: [Color(0xFFF6E3B0), Color(0xFFD9A94E), Color(0xFF8A6420)],
                            glod: Color.fromRGBO(255, 230, 160, .6),
                            skygge: Color.fromRGBO(60, 40, 5, .45),
                            skyggeW: 56,
                            svg: 'assets/svgs/onboarding/onb_pose3d.svg',
                            w: 56,
                            h: 56,
                            boble: true,
                          ),
                          tag: 'POSE',
                          tagIkon: '<path d="M6 8h12l1 13H5zM9 8V6a3 3 0 0 1 6 0v2"/>',
                          tagC: const Color(0xFFFFDD86),
                          tittel: pose.tittel,
                          under: pose.under,
                          pris: pose.pris,
                          prisBg: const [Color(0xFFFFE7A8), Color(0xFFE9AC3C)],
                          prisKant: const Color(0xFFA87418),
                          prisC: const Color(0xFF4A300A),
                          onTap: pose.onTap,
                        )),
                      ),
                      if (frakt case final frakt?)
                      Expanded(
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.5), child: _Funn(
                          inn: 340,
                          svevMs: 6400,
                          svevDelay: 300,
                          merke: frakt.merke ?? 'I kveld',
                          merkeBg: const [Color(0xFFFF9466), Color(0xFFE95C2C)],
                          merkeKant: const Color(0xFFA63A12),
                          merkeC: Colors.white,
                          merkeRot: 4,
                          bilde: const _Bilde(foto: 'assets/images/dashboard/bk-whopper.png'),
                          tag: 'FRAKT',
                          tagIkon: '<path d="M3 7h11v9H3zM14 10h4l3 3v3h-7M7 19a2 2 0 1 0 0-.1M17 19a2 2 0 1 0 0-.1"/>',
                          tagC: const Color(0xFF7FF0CB),
                          tittel: frakt.tittel,
                          under: frakt.under,
                          pris: frakt.pris,
                          prisBg: const [Color(0xFF8CF0D2), Color(0xFF3CC79F)],
                          prisKant: const Color(0xFF1F8A6B),
                          prisC: const Color(0xFF0F2A30),
                          onTap: frakt.onTap,
                        )),
                      ),
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

/// funnOpp .5s with a delay.
class _Opp extends StatelessWidget {
  const _Opp({required this.delayMs, required this.child});
  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delayMs + 500,
    builder: (context, t, child) {
      final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, delayMs, 500));
      return Opacity(opacity: e, child: Transform.translate(offset: Offset(0, 22 * (1 - e)), child: child));
    },
    child: child,
  );
}

class _Bilde {
  const _Bilde({this.bg, this.glod, this.skygge, this.skyggeW = 0, this.svg, this.w = 0, this.h = 0, this.boble = false, this.foto});
  final List<Color>? bg;
  final Color? glod, skygge;
  final double skyggeW, w, h;
  final String? svg, foto;
  final bool boble;
}

class _Funn extends StatelessWidget {
  const _Funn({
    required this.inn,
    required this.svevMs,
    required this.svevDelay,
    required this.merke,
    required this.merkeBg,
    required this.merkeKant,
    required this.merkeC,
    required this.merkeRot,
    required this.bilde,
    required this.tag,
    required this.tagIkon,
    required this.tagC,
    required this.tittel,
    required this.under,
    required this.pris,
    required this.prisBg,
    required this.prisKant,
    required this.prisC,
    required this.onTap,
  });

  final double inn, svevMs, svevDelay, merkeRot;
  final String merke, tag, tagIkon, tittel, under, pris;
  final List<Color> merkeBg, prisBg;
  final Color merkeKant, merkeC, tagC, prisKant, prisC;
  final _Bilde bilde;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = bilde;
    Widget bildet;
    if (b.foto != null) {
      bildet = LfLoop(
        // kenBurnsProd 9s alternate
        builder: (context, t, child) {
          final raw = (t / 9000) % 2.0;
          final p = cssEaseInOut.transform(raw <= 1 ? raw : 2 - raw);
          return Transform.scale(scale: 1.05 + .04 * p, child: child);
        },
        child: Image.asset(b.foto!, fit: BoxFit.cover, alignment: const Alignment(0, .1)),
      );
    } else {
      Widget ikon = SvgPicture.asset(b.svg!, width: b.w, height: b.h);
      if (b.boble) {
        ikon = LfLoop(
          builder: (context, t, child) {
            final p = (t / 4000) % 1.0;
            return Transform.translate(
              offset: Offset(0, kf(p, const [0, .5, 1], const [0, -4, 0], cssEaseInOut)),
              child: Transform.rotate(angle: rad(kf(p, const [0, .5, 1], const [-1, 1, -1], cssEaseInOut)), child: child),
            );
          },
          child: ikon,
        );
      }
      bildet = Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CssBox(
              bg: [
                CssRadial([b.glod!, b.glod!.withValues(alpha: 0)], stops: const [0, .7], rx: .7, ry: .9, cx: .5, cy: 1),
                CssLinear(160, b.bg!, const [0, .55, 1]),
              ],
            ),
          ),
          Positioned(
            bottom: 6,
            width: b.skyggeW,
            height: 10,
            child: CssBox(bg: [CssRadial.closestSide([b.skygge!, b.skygge!.withValues(alpha: b.skygge!.a / 2), b.skygge!.withValues(alpha: 0)], stops: const [0, .5, 1])]),
          ),
          Transform.translate(offset: Offset(0, b.boble ? -2 : -2), child: ikon),
        ],
      );
    }
    final kort = LfPress(
      dy: 3,
      scale: .98,
      onTap: onTap,
      child: CssBox(
        radius: BorderRadius.circular(20),
        bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .17), Color.fromRGBO(255, 255, 255, .07)])],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .34)),
          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .13)),
          CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 18, 26, .6)),
          CssShadow(0, 20, 28, -14, Color.fromRGBO(0, 0, 0, .85)),
        ],
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 62,
              child: CssBox(
                radius: BorderRadius.circular(15),
                clip: true,
                shadows: const [
                  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .25)),
                  CssShadow.inset(0, -6, 10, -6, Color.fromRGBO(0, 0, 0, .4)),
                ],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    bildet,
                    if (b.foto == null)
                      const CssBox(bg: [CssLinear(125, [Color.fromRGBO(255, 255, 255, .35), Color.fromRGBO(255, 255, 255, 0)], [0, .4])]),
                    Positioned(
                      left: 5,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(5, 2.5, 7, 2.5),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(6, 22, 30, .66),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#${_hex(tagC)}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">$tagIkon</svg>',
                              width: 8,
                              height: 8,
                            ),
                            const SizedBox(width: 3),
                            Text(tag, style: inter(7.5, weight: FontWeight.w800, em: .06)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 7, 3, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tittel, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(11.5, em: -.025, height: 1.2)),
                  const SizedBox(height: 1),
                  Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(9.5, weight: FontWeight.w700, color: const Color(0xFFBFD6DD))),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 7, 1, 0),
              child: Row(
                children: [
                  CssBox(
                    radius: BorderRadius.circular(8),
                    bg: [CssLinear(180, prisBg)],
                    shadows: [const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .5)), CssShadow(0, 2, 0, 0, prisKant)],
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    child: Text(pris, maxLines: 1, style: jakarta(11.5, color: prisC).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
                  const Spacer(),
                  CssBox(
                    width: 22,
                    height: 22,
                    radius: BorderRadius.circular(11),
                    bg: const [CssLinear(180, [Color.fromRGBO(130, 242, 210, .32), Color.fromRGBO(92, 224, 184, .12)])],
                    shadows: const [
                      CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                      CssShadow(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .4)),
                    ],
                    child: Center(
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>',
                        width: 9,
                        height: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return SizedBox(
      height: 142,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _Opp(
              delayMs: inn,
              child: LfLoop(
                // funnSvev
                builder: (context, t, child) {
                  final e = t - svevDelay;
                  final p = e < 0 ? 0.0 : (e / svevMs) % 1.0;
                  final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
                  final rx = kf(p, const [0, .5, 1], const [6, 3, 6], cssEaseInOut);
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, -1 / 600)
                      ..translateByDouble(0, y, 0, 1)
                      ..rotateX(rad(rx)),
                    child: child,
                  );
                },
                child: kort,
              ),
            ),
          ),
          // No badge rather than an empty one (backend plan Step 8).
          if (merke.isNotEmpty)
          Positioned(
            right: -5,
            top: -9,
            child: Transform.rotate(
              angle: rad(merkeRot),
              child: CssBox(
                radius: BorderRadius.circular(7),
                bg: [CssLinear(180, merkeBg)],
                shadows: [
                  const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
                  CssShadow(0, 2, 0, 0, merkeKant),
                  const CssShadow(0, 6, 10, -4, Color.fromRGBO(0, 0, 0, .6)),
                ],
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                child: Text(merke, style: inter(9, weight: FontWeight.w800, color: merkeC)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _hex(Color c) => c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);

/// The surface seen from below: two wave rows drifting (bolgeDrift 7s /
/// 11s reverse) and a pale band, faded at both ends.
class _Overflate extends StatelessWidget {
  const _Overflate();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => const LinearGradient(
        colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
        stops: [0, 26 / 390, 1 - 26 / 390, 1],
      ).createShader(r),
      child: Stack(
        children: [
          LfLoop(builder: (context, t, _) => CustomPaint(size: const Size(390, 22), painter: _Bolger((t / 7000) % 1.0, false))),
          LfLoop(builder: (context, t, _) => CustomPaint(size: const Size(390, 22), painter: _Bolger(1 - (t / 11000) % 1.0, true))),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromRGBO(214, 242, 250, 0), Color.fromRGBO(214, 242, 250, .35), Color.fromRGBO(160, 215, 230, .25)],
                  stops: [0, .45, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bolger extends CustomPainter {
  _Bolger(this.p, this.andre);
  final double p;
  final bool andre;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-390 * p, andre ? 3 : 0);
    final path = Path()..moveTo(0, 8);
    if (!andre) {
      // M0 8 C32 2 64 2 96 8 S160 14 192 8 … every 192px
      for (var x = 0.0; x < 780; x += 192) {
        path
          ..cubicTo(x + 32, 2, x + 64, 2, x + 96, 8)
          ..cubicTo(x + 128, 14, x + 160, 14, x + 192, 8);
      }
    } else {
      for (var x = 0.0; x < 780; x += 240) {
        path
          ..cubicTo(x + 40, 14, x + 80, 14, x + 120, 8)
          ..cubicTo(x + 160, 2, x + 200, 2, x + 240, 8);
      }
    }
    path
      ..lineTo(780, 8)
      ..lineTo(780, 22)
      ..lineTo(0, 22)
      ..close();
    canvas.drawPath(path, Paint()..color = Color.fromRGBO(214, 242, 250, andre ? .5 : .42));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Bolger old) => old.p != p;
}

/// The planks overhead (rotateX 62°, stripes), faded at the sides.
class _Planker extends StatelessWidget {
  const _Planker();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => const LinearGradient(
        colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
        stops: [0, 22 / 390, 1 - 22 / 390, 1],
      ).createShader(r),
      child: Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, -1 / 500)
          ..rotateX(rad(62)),
        child: const CustomPaint(painter: _PlankePainter()),
      ),
    );
  }
}

class _PlankePainter extends CustomPainter {
  const _PlankePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const farger = [Color(0xFF4A3520), Color(0xFF2E2012), Color(0xFF5A422C), Color(0xFF26180C)];
    const bredder = [44.0, 3.0, 45.0, 3.0];
    var x = 0.0, k = 0;
    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, bredder[k % 4], size.height), Paint()..color = farger[k % 4]);
      x += bredder[k % 4];
      k++;
    }
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, .6)],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A ray of light (dypLys): a soft strip, rotated and breathing.
class _Straale extends StatelessWidget {
  const _Straale({required this.left, required this.width, required this.height, required this.sk, required this.a, required this.durMs, required this.delayMs});
  final double left, width, height, sk, a, durMs, delayMs;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      width: width,
      height: height,
      child: LfLoop(
        builder: (context, t, child) {
          final e = t - delayMs;
          final p = e < 0 ? 0.0 : (e / durMs) % 1.0;
          final o = kf(p, const [0, .5, 1], const [.16, .34, .16], cssEaseInOut);
          final r = kf(p, const [0, .5, 1], [sk, sk + 2, sk], cssEaseInOut);
          final sy = kf(p, const [0, .5, 1], const [1, 1.05, 1], cssEaseInOut);
          return Opacity(
            opacity: o,
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..rotateZ(rad(r))
                ..scaleByDouble(1, sy, 1, 1),
              child: child,
            ),
          );
        },
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          // The blurred edges, drawn as a horizontal fade.
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
            stops: [0, .3, .7, 1],
          ).createShader(r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromRGBO(198, 238, 248, a), const Color.fromRGBO(198, 238, 248, 0)],
                stops: const [0, .8],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Kaustikk extends CustomPainter {
  const _Kaustikk();

  @override
  void paint(Canvas canvas, Size size) {
    void flekk(double cx, double cy, double rx, double ry, double a) {
      final c = Offset(cx * size.width, cy * size.height);
      final r = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
      canvas.drawOval(
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(200, 235, 245, a), const Color.fromRGBO(200, 235, 245, 0)], stops: const [0, .7]).createShader(r),
      );
    }

    flekk(.2, .4, 60, 14, .22);
    flekk(.55, .6, 80, 16, .18);
    flekk(.85, .35, 70, 14, .2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A pile (clip-path trapezoid, wood gradient) with a band of weed.
class _Paal extends StatelessWidget {
  const _Paal({required this.bunnFrac, required this.toppFrac, required this.alfa, this.ugress, this.ugressH, this.lys = false, this.mork = false});
  final double bunnFrac, toppFrac, alfa;
  final double? ugress, ugressH;
  final bool lys, mork;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: alfa,
      child: ClipPath(
        clipper: _Trapes(bunnFrac, toppFrac),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: mork
                        ? const [Color(0xFF120B05), Color(0xFF332415), Color(0xFF1A1007)]
                        : const [Color(0xFF1A1008), Color(0xFF3E2C19), Color(0xFF6B5034), Color(0xFF4A3421), Color(0xFF1F150B)],
                    stops: mork ? const [0, .46, 1] : const [0, .22, .48, .74, 1],
                  ),
                ),
              ),
            ),
            if (ugress != null)
              Positioned(
                left: 0,
                right: 0,
                top: ugress,
                height: ugressH,
                child: const CustomPaint(painter: _Ugress()),
              ),
            if (lys)
              Positioned(
                left: 0,
                right: 0,
                top: (ugress ?? 0) - 6,
                height: 8,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(230, 240, 235, .35), Color.fromRGBO(230, 240, 235, 0)],
                    ),
                  ),
                ),
              ),
            if (!mork)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 70,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, .55)],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Trapes extends CustomClipper<Path> {
  const _Trapes(this.a, this.b);
  final double a, b;

  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width * b, s.height)
    ..lineTo(s.width * a, s.height)
    ..close();

  @override
  bool shouldReclip(covariant _Trapes old) => false;
}

class _Ugress extends CustomPainter {
  const _Ugress();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(60, 110, 80, .55), Color.fromRGBO(60, 110, 80, 0)],
        ).createShader(r),
    );
    final p = Paint()..color = const Color.fromRGBO(80, 130, 90, .4);
    for (var y = 0.0; y < size.height; y += 9) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Tare extends StatelessWidget {
  const _Tare({required this.durMs, required this.delayMs, required this.reverse, required this.opacity, required this.full});
  final double durMs, delayMs, opacity;
  final bool reverse, full;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: LfLoop(
        builder: (context, t, child) {
          final e = t - delayMs;
          var p = e < 0 ? 0.0 : (e / durMs) % 1.0;
          if (reverse) p = 1 - p;
          return Transform.rotate(
            alignment: Alignment.bottomCenter,
            angle: rad(kf(p, const [0, .5, 1], const [-4, 5, -4], cssEaseInOut)),
            child: child,
          );
        },
        child: SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 120"><path d="M30 120 C26 100 36 90 30 72 C24 54 36 44 30 24 C27 14 32 8 30 0" stroke="#2F6B4A" stroke-width="7" stroke-linecap="round" fill="none"/>'
          '${full ? '<path d="M30 120 C26 100 36 90 30 72 C24 54 36 44 30 24 C27 14 32 8 30 0" stroke="#4F9A6A" stroke-width="2.5" stroke-linecap="round" fill="none" transform="translate(-1.5,0)"/>' : ''}'
          '<path d="M30 96 C40 92 46 84 48 74 M30 60 C20 56 14 48 12 38${full ? ' M30 40 C40 36 44 30 45 22' : ''}" stroke="#3F8A5C" stroke-width="4" stroke-linecap="round" fill="none"/></svg>',
        ),
      ),
    );
  }
}

class _Linjer extends CustomPainter {
  const _Linjer();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(-10, 100)
        ..quadraticBezierTo(195, 88, 400, 100),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color.fromRGBO(190, 232, 244, .14),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 168)
        ..quadraticBezierTo(195, 154, 400, 168),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color.fromRGBO(190, 232, 244, .09),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Boble extends StatelessWidget {
  const _Boble({required this.left, required this.top, required this.size, required this.a, required this.durMs, required this.delayMs, this.glans = false});
  final double left, top, size, a, durMs, delayMs;
  final bool glans;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: LfLoop(
        builder: (context, t, child) {
          final e = t - delayMs;
          if (e < 0) return const SizedBox.shrink();
          final p = cssEaseIn.transform((e / durMs) % 1.0);
          final y = 10 + (-84 - 10) * p;
          final sk = .7 + .3 * p;
          final o = kf(p, const [0, .25, 1], const [0, .6, 0]);
          return Opacity(opacity: o, child: Transform.translate(offset: Offset(0, y), child: Transform.scale(scale: sk, child: child)));
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(206, 240, 250, a),
            boxShadow: glans ? const [BoxShadow(color: Color.fromRGBO(255, 255, 255, .9), offset: Offset(-1, -1), blurRadius: 1)] : null,
          ),
        ),
      ),
    );
  }
}

class _Bob extends StatelessWidget {
  const _Bob({required this.delayMs, required this.child});
  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, t, child) {
      final p = (((t - delayMs) / 4000) % 1.0 + 1) % 1.0;
      return Transform.translate(offset: Offset(0, kf(p, const [0, .5, 1], const [0, -4, 0], cssEaseInOut)), child: child);
    },
    child: child,
  );
}
