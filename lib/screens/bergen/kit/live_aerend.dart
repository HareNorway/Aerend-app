import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';

// ── Live-ærend (prototype L9598, `liveVals`/`liveData`) ────────────────────
// The floating pill while an order is under way: Ægil in a progress ring,
// the stage, the countdown to the door, four stage segments and an arrow
// into the tracking. It floats (`liveSvev`), glows, and a sheen passes now
// and then. Wired to the order flow in Step 8; here it shows the order the
// home-track-order API reports.

class HjemLiveData {
  const HjemLiveData({required this.stadie, required this.restSek, this.henting = false});

  /// `spStadie` 0–3: Bekreftet, Tilberedes, På vei / Klar for henting, Levert.
  final int stadie;
  final int restSek;
  final bool henting;
}

/// The order under way, as Hjem last heard it from `home-track-order`
/// (null when there is none); the shell shows the pill from it.
final ValueNotifier<({int orderId, HjemLiveData data})?> hjemLiveOrdre = ValueNotifier(null);

class HjemLiveAerend extends StatefulWidget {
  const HjemLiveAerend({super.key, required this.data, required this.onTap});

  final HjemLiveData data;
  final VoidCallback onTap;

  @override
  State<HjemLiveAerend> createState() => _HjemLiveAerendState();
}

class _HjemLiveAerendState extends State<HjemLiveAerend> {
  late final DateTime _t0 = DateTime.now();
  Timer? _tikk;

  @override
  void initState() {
    super.initState();
    _tikk = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && TickerMode.of(context)) setState(() {});
    });
  }

  @override
  void dispose() {
    _tikk?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final s = math.min(3, d.stadie);
    final hent = d.henting;
    final start = hent ? const [960, 600, 0, 0] : const [1080, 780, 540, 0];
    final gaatt = DateTime.now().difference(_t0).inSeconds;
    final rest = d.restSek <= 0 ? 0 : math.max(45, d.restSek - gaatt);
    final ferdig = s >= 3, klar = hent && s == 2, snart = !ferdig && !klar && rest <= 120;
    final navn = (hent ? const ['Bekreftet', 'Tilberedes', 'Klar for henting', 'Hentet'] : const ['Bekreftet', 'Tilberedes', 'På vei', 'Levert'])[s];
    String mmss(int v) => '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';
    final ring = ferdig ? 1.0 : klar ? .82 : math.max(const [.08, .32, .58][s], 1 - rest / start[0]).clamp(0.0, 1.0);
    final aeg = ferdig ? 'popup' : s == 0 ? 'front' : (s == 1 || hent) ? 'store' : 'bike';
    final tid = ferdig ? (hent ? 'Hentet!' : 'Levert!') : klar ? 'Klar nå!' : mmss(rest);
    final sub = ferdig ? 'åpne' : klar ? 'i disken' : snart ? 'snart!' : (hent ? 'til klar' : 'til døra');
    final gront = ferdig || klar;

    return Semantics(
      button: true,
      label: 'Bestillingen din: $navn${gront ? '' : ', $tid igjen'}. Trykk for å åpne sporingen.',
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 234,
          height: 64,
          child: LfLoop(
            // liveSvev / liveSkygge 4.4s
            builder: (context, t, child) {
              final p = (t / 4400) % 1.0;
              final y = kf(p, const [0, .5, 1], const [0, -3, 0], cssEaseInOut);
              final sk = kf(p, const [0, .5, 1], const [1, .86, 1], cssEaseInOut);
              final so = kf(p, const [0, .5, 1], const [.9, .6, .9], cssEaseInOut);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: -17,
                    height: 14,
                    child: Opacity(
                      opacity: so,
                      child: Transform.scale(
                        scale: sk,
                        child: const CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(2, 10, 16, .6), Color.fromRGBO(2, 10, 16, 0)])]),
                      ),
                    ),
                  ),
                  Positioned.fill(child: Transform.translate(offset: Offset(0, y), child: child)),
                ],
              );
            },
            child: _Bump(
              nokkel: s,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Glow behind (liveGlod 2.8s).
                  Positioned(
                    left: -12,
                    right: -12,
                    top: -10,
                    bottom: -14,
                    child: LfLoop(
                      builder: (context, t, child) => Opacity(
                        opacity: kf((t / 2800) % 1.0, const [0, .5, 1], const [.35, .95, .35], cssEaseInOut),
                        child: child,
                      ),
                      child: CssBox(
                        radius: BorderRadius.circular(34),
                        bg: [
                          CssRadial(
                            [snart ? const Color.fromRGBO(255, 148, 102, .5) : const Color.fromRGBO(92, 224, 184, .42), const Color.fromRGBO(92, 224, 184, 0)],
                            stops: const [0, .72],
                            rx: .55,
                            ry: .7,
                            cx: .22,
                            cy: .5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snart)
                    Positioned(
                      left: -3,
                      right: -3,
                      top: -3,
                      bottom: -8,
                      child: LfLoop(
                        builder: (context, t, child) {
                          final p = (t / 1300) % 1.0;
                          return Opacity(
                            opacity: kf(p, const [0, .5, 1], const [.25, 1, .25], cssEaseInOut),
                            child: Transform.scale(scale: kf(p, const [0, .5, 1], const [1, 1.025, 1], cssEaseInOut), child: child),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27),
                            border: Border.all(color: const Color(0xFFFF9466), width: 2),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 148, 102, .75), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ),
                  // The pill's edge under it.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 6,
                    bottom: -5,
                    child: CssBox(
                      radius: BorderRadius.circular(24),
                      bg: [
                        gront
                            ? const CssLinear(180, [Color(0xFF147A5C), Color(0xFF0C5340)])
                            : const CssLinear(180, [Color(0xFF103C47), Color(0xFF082730)]),
                      ],
                      shadows: const [
                        CssShadow.inset(0, -1.5, 0, 0, Color.fromRGBO(255, 255, 255, .08)),
                        CssShadow(0, 18, 26, -10, Color.fromRGBO(3, 14, 20, .9)),
                        CssShadow(0, 5, 9, -3, Color.fromRGBO(3, 14, 20, .55)),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: CssBox(
                      radius: BorderRadius.circular(24),
                      clip: true,
                      bg: gront
                          ? const [
                              CssRadial([Color(0xFF9AF5D8), Color(0x009AF5D8)], stops: [0, .55], rx: 1.2, ry: .9, cx: .18, cy: 0),
                              CssLinear(165, [Color(0xFF3FCDA1), Color(0xFF22A47F), Color(0xFF198466)], [0, .55, 1]),
                            ]
                          : const [
                              CssRadial([Color(0xFF4A97A9), Color(0x004A97A9)], stops: [0, .55], rx: 1.2, ry: .9, cx: .18, cy: 0),
                              CssLinear(165, [Color(0xFF33788A), Color(0xFF1F5363), Color(0xFF173F4B)], [0, .55, 1]),
                            ],
                      shadows: const [
                        CssShadow.inset(0, 2, 0, 0, Color.fromRGBO(255, 255, 255, .44)),
                        CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .2)),
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .15)),
                        CssShadow.inset(0, -12, 18, -12, Color.fromRGBO(2, 12, 18, .6)),
                      ],
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 14,
                            right: 58,
                            top: 3,
                            height: 19,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.elliptical(16, 16),
                                  topRight: Radius.elliptical(16, 16),
                                  bottomLeft: Radius.elliptical(40, 12),
                                  bottomRight: Radius.elliptical(40, 12),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color.fromRGBO(255, 255, 255, .26), Color.fromRGBO(255, 255, 255, 0)],
                                ),
                              ),
                            ),
                          ),
                          // liveSveip 6.5s (1.6s delay)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, box) => LfLoop(
                                builder: (context, t, child) {
                                  final e = t - 1600;
                                  if (e < 0) return const SizedBox.shrink();
                                  final x = kf((e / 6500) % 1.0, const [0, .7, 1], const [-1.3, -1.3, 2.6], cssEaseInOut);
                                  return Transform.translate(offset: Offset(x * box.maxWidth * .4, 0), child: child);
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: box.maxWidth * .4,
                                    child: const CssBox(bg: [CssLinear(100, [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, 0)])]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 9, 0),
                            child: Row(
                              children: [
                                _Avatar(ring: ring, aeg: aeg, merke: ferdig ? '✓' : '${s + 1}/4', gront: gront),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _Puls(farge: gront ? Colors.white : const Color(0xFFFF8A57)),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: _Flipp(
                                              nokkel: s,
                                              child: Text(
                                                navn.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: inter(9, weight: FontWeight.w800, em: .12, color: gront ? const Color(0xFFF2FFFA) : const Color(0xFF9FF0D4)).copyWith(
                                                  shadows: const [Shadow(color: Color.fromRGBO(3, 14, 20, .45), offset: Offset(0, 1))],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            tid,
                                            style: jakarta(
                                              23,
                                              em: -.035,
                                              height: 1,
                                              shadows: const [
                                                Shadow(color: Color.fromRGBO(4, 22, 30, .6), offset: Offset(0, 2)),
                                                Shadow(color: Color.fromRGBO(3, 14, 20, .45), offset: Offset(0, 7), blurRadius: 12),
                                              ],
                                            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              sub,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: inter(9.5, weight: FontWeight.w700, color: gront ? const Color(0xFFEFFFF9) : const Color(0xFFBFD8DF)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(2, 12, 18, .4),
                                          borderRadius: BorderRadius.circular(5),
                                          boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 255, 255, .14), offset: Offset(0, 1))],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (var k = 0; k < 4; k++) ...[
                                              if (k > 0) const SizedBox(width: 3),
                                              _Segment(ferdig: k < s || ferdig, naa: k == s && !ferdig, gront: gront),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 36,
                                  height: 39,
                                  child: Stack(
                                    children: [
                                      const Positioned(
                                        left: 0,
                                        top: 3,
                                        width: 36,
                                        height: 36,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA3B8BE), Color(0xFF6F878E)]),
                                            boxShadow: [BoxShadow(color: Color.fromRGBO(3, 16, 24, .65), offset: Offset(0, 6), blurRadius: 5, spreadRadius: -3)],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        width: 36,
                                        height: 36,
                                        child: CssBox(
                                          radius: BorderRadius.circular(18),
                                          bg: const [
                                            CssRadial([Color(0xFFFFFFFF), Color(0xFFEEF4F5), Color(0xFFD5E1E4)], stops: [0, .55, 1], rx: .7, ry: .6, cx: .4, cy: .25),
                                          ],
                                          shadows: const [
                                            CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
                                            CssShadow.inset(0, -2, 3, 0, Color.fromRGBO(30, 79, 92, .2)),
                                          ],
                                          child: Center(
                                            child: SvgPicture.string(
                                              ferdig
                                                  ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1A7E62" stroke-width="3.4" stroke-linecap="round"><path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/></svg>'
                                                  : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1E4F5C" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 17L17 7M9 7h8v8"/></svg>',
                                              width: 13,
                                              height: 13,
                                            ),
                                          ),
                                        ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ægil in the progress ring with the bead and the "2/4" badge.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.ring, required this.aeg, required this.merke, required this.gront});

  final double ring;
  final String aeg, merke;
  final bool gront;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: CssBox(
              radius: BorderRadius.all(Radius.circular(26)),
              bg: [CssRadial([Color(0xFF123C47), Color(0xFF0A2530)], stops: [0, .72], circle: true, cx: .5, cy: .3, farthestCorner: true)],
              shadows: [
                CssShadow.inset(0, 2.5, 4, 0, Color.fromRGBO(0, 0, 0, .6)),
                CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .16)),
                CssShadow(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
              ],
            ),
          ),
          // The ring (and its bead) eases to each new value over 1.2s.
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: ring),
              duration: const Duration(milliseconds: 1200),
              curve: const Cubic(.3, 1.2, .4, 1),
              builder: (context, v, _) => CustomPaint(painter: _Ring(v)),
            ),
          ),
          Positioned(
            left: 9,
            top: 9,
            width: 34,
            height: 34,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color.fromRGBO(255, 255, 255, .92), spreadRadius: 1.5),
                  BoxShadow(color: Color.fromRGBO(0, 0, 0, .45), offset: Offset(0, 2), blurRadius: 2, spreadRadius: 1.5),
                ],
              ),
              child: CssBox(
                radius: BorderRadius.circular(17),
                clip: true,
                bg: const [CssRadial([Color(0xFFCFE3EC), Color(0xFF7FA3B2), Color(0xFF4E7383)], stops: [0, .62, 1], circle: true, cx: .4, cy: .28, farthestCorner: true)],
                shadows: const [
                  CssShadow.inset(0, 2, 3, 0, Color.fromRGBO(0, 0, 0, .35)),
                  CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(4, 20, 28, .3)),
                ],
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 17 - 21,
                      bottom: -5,
                      width: 42,
                      height: 42,
                      child: LfLoop(
                        builder: (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3200), child: child),
                        child: Image.asset('assets/images/dashboard/$aeg.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                      ),
                    ),
                    const Positioned.fill(
                      child: CssBox(bg: [CssRadial([Color.fromRGBO(255, 255, 255, .6), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .7], rx: .6, ry: .45, cx: .3, cy: .2)]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -8,
            bottom: -5,
            child: CssBox(
              height: 20,
              radius: BorderRadius.circular(10),
              bg: [
                gront
                    ? const CssLinear(180, [Color(0xFF6BEBC4), Color(0xFF1F9C77)])
                    : const CssLinear(180, [Color(0xFFFFA77C), Color(0xFFE95C2C)]),
              ],
              shadows: [
                const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .55)),
                const CssShadow.inset(0, -1.5, 0, 0, Color.fromRGBO(0, 0, 0, .14)),
                const CssShadow(0, 0, 0, 2, Color(0xFF10343E)),
                CssShadow(0, 3, 0, 2, gront ? const Color(0xFF0F5C46) : const Color(0xFFA63A12)),
                const CssShadow(0, 7, 9, 1, Color.fromRGBO(3, 14, 20, .5)),
              ],
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 15),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    merke,
                    style: jakarta(10, shadows: const [Shadow(color: Color.fromRGBO(80, 25, 6, .5), offset: Offset(0, 1))]).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

class _Ring extends CustomPainter {
  const _Ring(this.v);

  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    const c = Offset(26, 26);
    const r = 22.0;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..color = const Color.fromRGBO(255, 255, 255, .1),
    );
    // liveRingG runs along the diagonal of the ring's box, which the SVG
    // turns −90°: bottom-left → top-right on screen.
    final shader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFFFFB089), Color(0xFFFF8A57), Color(0xFF5CE0B8)],
      stops: [0, .5, 1],
    ).createShader(Offset.zero & size);
    final sweep = 2 * math.pi * v;
    if (v > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..shader = shader
          ..color = const Color.fromRGBO(0, 0, 0, .26),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..shader = shader,
      );
    }
    // The bead rides the end of the ring.
    final a = -math.pi / 2 + sweep;
    final b = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(b, 6.5, Paint()..color = const Color.fromRGBO(255, 255, 255, .22));
    canvas.drawCircle(b + const Offset(0, .8), 3.9, Paint()..color = const Color.fromRGBO(90, 30, 8, .45));
    canvas.drawCircle(
      b,
      3.9,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.24, -.36),
          radius: .7,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF1E8), Color(0xFFF2B694)],
          stops: [0, .6, 1],
        ).createShader(Rect.fromCircle(center: b, radius: 3.9)),
    );
  }

  @override
  bool shouldRepaint(covariant _Ring old) => old.v != v;
}

class _Segment extends StatelessWidget {
  const _Segment({required this.ferdig, required this.naa, required this.gront});

  final bool ferdig, naa, gront;

  @override
  Widget build(BuildContext context) {
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 14,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: ferdig
            ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA6F8DD), Color(0xFF3CC79F)])
            : naa
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gront ? const [Color(0xFFFFFFFF), Color(0xFFDDF7EE)] : const [Color(0xFFFFC6A8), Color(0xFFF26D3D)],
              )
            : null,
        color: ferdig || naa ? null : const Color.fromRGBO(255, 255, 255, .12),
        boxShadow: ferdig
            ? const [BoxShadow(color: Color.fromRGBO(92, 224, 184, .5), blurRadius: 2.5)]
            : naa
            ? [BoxShadow(color: gront ? const Color.fromRGBO(255, 255, 255, .8) : const Color.fromRGBO(255, 148, 102, .85), blurRadius: 3.5)]
            : null,
      ),
    );
    if (!naa) return box;
    // liveSegPuls 1.4s
    return LfLoop(
      builder: (context, t, child) => Opacity(opacity: kf((t / 1400) % 1.0, const [0, .5, 1], const [.7, 1, .7], cssEaseInOut), child: child),
      child: box,
    );
  }
}

/// The status dot with its `livePuls` ring.
class _Puls extends StatelessWidget {
  const _Puls({required this.farge});

  final Color farge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 7,
      height: 7,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(center: const Alignment(-.3, -.4), colors: [const Color(0xFFFFE0D0), farge, const Color(0xFFB9441A)], stops: const [0, .55, 1]),
                boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, .4), offset: Offset(0, 1), blurRadius: 1)],
              ),
            ),
          ),
          Positioned.fill(
            child: LfLoop(
              builder: (context, t, child) {
                final p = cssEaseOut.transform((t / 1800) % 1.0);
                return Opacity(opacity: .9 * (1 - p), child: Transform.scale(scale: .6 + 1.3 * p, child: child));
              },
              child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: farge)),
            ),
          ),
        ],
      ),
    );
  }
}

/// `liveBumpA/B` (.7s) when the stage changes.
class _Bump extends StatelessWidget {
  const _Bump({required this.nokkel, required this.child});

  final int nokkel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LfOnce(
      key: ValueKey('bump$nokkel'),
      ms: 700,
      builder: (context, t, child) {
        final p = const Cubic(.3, 1.4, .5, 1).transform((t / 700).clamp(0.0, 1.0));
        final sign = nokkel.isOdd ? -1.0 : 1.0;
        final sc = kf(p, const [0, .3, .6, 1], const [1, 1.12, .96, 1]);
        final r = kf(p, const [0, .3, .6, 1], [0, 2.5 * sign, -1.2 * sign, 0]);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(sc, sc, 1, 1)
            ..rotateZ(rad(r)),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// `liveFlipA/B` (.5s) on the stage label.
class _Flipp extends StatelessWidget {
  const _Flipp({required this.nokkel, required this.child});

  final int nokkel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LfOnce(
      key: ValueKey('flipp$nokkel'),
      ms: 500,
      builder: (context, t, child) {
        final e = cssEaseOut.transform((t / 500).clamp(0.0, 1.0));
        final rx = (nokkel.isOdd ? 90 : -90) * (1 - e);
        return Opacity(
          opacity: e,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, -1 / 200)
              ..rotateX(rad(rx)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
