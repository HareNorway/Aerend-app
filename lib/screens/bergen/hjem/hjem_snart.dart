import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../../snurre/snurre_launcher_policy.dart' show snurreLauncherHiddenRoutePrefix;
import 'hjem_hjul.dart';

// ── Kommer snart · <kategori> (prototype L9548–9596, `snartVals`) ─────────
// The sheet a coming-soon category opens: a spinning sunburst behind the
// category's 3D icon, the KOMMER SNART stamp, how many shops are ready, a
// word from Ægil, "Varsle meg når det åpner" and a way back to restaurants.

/// One coming category, from `GET catalog/launch-categories` (backend plan
/// Step 8): the sheet's text, Ægil's line, how many shops are ready (counted
/// on the server) and how many it opens at.
class HjemSnartInfo {
  const HjemSnartInfo({required this.tekst, required this.klar, required this.maal, required this.aeg, this.id, this.navn, this.varsles = false});
  final String tekst;
  final int klar, maal;
  final String aeg;

  /// The launch category's id (for «Varsle meg»), its title, and whether this
  /// customer already asked to be told.
  final int? id;
  final String? navn;
  final bool varsles;

  /// The wheel slot this entry belongs to, from the API row.
  static (int, HjemSnartInfo)? fraJson(Map<String, dynamic> j) {
    final slot = (j['slot'] as num?)?.toInt();
    if (slot == null || j['state'] != 'coming') return null;
    return (
      slot,
      HjemSnartInfo(
        id: (j['id'] as num?)?.toInt(),
        navn: '${j['title'] ?? ''}'.trim().isEmpty ? null : '${j['title']}',
        tekst: '${j['description'] ?? ''}',
        klar: (j['ready_count'] as num?)?.toInt() ?? 0,
        maal: (j['target_count'] as num?)?.toInt() ?? 0,
        aeg: '${j['aegil_quote'] ?? ''}',
        varsles: j['notify'] == true,
      ),
    );
  }
}

/// The prototype's texts, kept only for the widget tests.
@visibleForTesting
const List<HjemSnartInfo?> kHjemSnartPrototype = [
  null,
  HjemSnartInfo(
    tekst: 'Fersk fisk fra Fisketorget, bakst fra bydelen og dagligvarer, rett på døra.',
    klar: 8,
    maal: 10,
    aeg: 'Fiskerne på Torget er nesten klare. Jeg sier fra så fort garnet er ute!',
  ),
  HjemSnartInfo(tekst: 'Klær og sko fra butikkene i sentrum, levert samme dag.', klar: 6, maal: 12, aeg: 'Jeg har snakket med butikkene i Strandgaten. Snart får du regnjakka levert før neste byge.'),
  HjemSnartInfo(tekst: 'Lamper, puter og småmøbler fra Bergens egne interiørbutikker.', klar: 5, maal: 10, aeg: 'Jeg måler opp hyllene på Bryggen. Det blir koselig, lover!'),
  HjemSnartInfo(tekst: 'Blomster, gavekort og små overraskelser, levert innen timen.', klar: 9, maal: 12, aeg: 'Snart kan du sende blomster til noen du er glad i, uten å gå ut i regnet.'),
];

const List<String> kHjemKatNavn = ['Restaurant', 'Mat & fisk', 'Mote', 'Interiør', 'Gaver'];

/// Opens the sheet for design category [k] (1–4) with [info] from the
/// server. [varsles] is the current "Varsle meg" state; [onVarsle] stores a
/// change; [onRestauranter] runs after "Bestill fra restauranter i
/// mellomtiden" closes the sheet.
Future<void> visKommerSnart(BuildContext context, {required int k, required HjemSnartInfo info, required bool varsles, required ValueChanged<bool> onVarsle, required VoidCallback onRestauranter}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      // A sheet over the shell: the floating Snurre launcher stays out.
      settings: const RouteSettings(name: '${snurreLauncherHiddenRoutePrefix}kommer-snart'),
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: reduce ? 0 : 500),
      reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 280),
      pageBuilder: (context, a, _) => _SnartRute(anim: a, k: k, info: info, varsles: varsles, onVarsle: onVarsle, onRestauranter: onRestauranter),
    ),
  );
}

class _SnartRute extends StatelessWidget {
  const _SnartRute({required this.anim, required this.k, required this.info, required this.varsles, required this.onVarsle, required this.onRestauranter});

  final Animation<double> anim;
  final int k;
  final HjemSnartInfo info;
  final bool varsles;
  final ValueChanged<bool> onVarsle;
  final VoidCallback onRestauranter;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: LfFrame(
        child: Builder(
          builder: (context) {
            final h = MediaQuery.sizeOf(context).height;
            return Stack(
              children: [
                // snartScrim .3s
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: const Interval(0, .6, curve: cssEase),
                      ),
                      child: const ColoredBox(color: Color.fromRGBO(6, 18, 24, .55)),
                    ),
                  ),
                ),
                // snartInn .5s cubic(.2,1.05,.3,1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: anim,
                    builder: (context, child) {
                      final v = anim.status == AnimationStatus.reverse ? Curves.easeIn.transform(anim.value) : const Cubic(.2, 1.05, .3, 1).transform(anim.value);
                      return FractionalTranslation(translation: Offset(0, 1 - v), child: child);
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: h * .92),
                      child: _SnartArk(k: k, info: info, varsles: varsles, onVarsle: onVarsle, onRestauranter: onRestauranter),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SnartArk extends StatefulWidget {
  const _SnartArk({required this.k, required this.info, required this.varsles, required this.onVarsle, required this.onRestauranter});

  final int k;
  final HjemSnartInfo info;
  final bool varsles;
  final ValueChanged<bool> onVarsle;
  final VoidCallback onRestauranter;

  @override
  State<_SnartArk> createState() => _SnartArkState();
}

class _SnartArkState extends State<_SnartArk> {
  late bool _vs = widget.varsles;
  final GlobalKey _varsleKey = GlobalKey();
  final GlobalKey _arkKey = GlobalKey();

  /// `snartGnist` bursts (centre in the sheet's box, start time).
  final List<(Offset, int)> _gnister = [];

  void _sett(bool v) {
    setState(() => _vs = v);
    widget.onVarsle(v);
  }

  void _varsle() {
    HapticFeedback.mediumImpact();
    final b = _varsleKey.currentContext?.findRenderObject() as RenderBox?;
    final ark = _arkKey.currentContext?.findRenderObject() as RenderBox?;
    if (b != null && ark != null && !MediaQuery.disableAnimationsOf(context)) {
      final c = ark.globalToLocal(b.localToGlobal(b.size.center(Offset.zero)));
      _gnister.add((c, DateTime.now().millisecondsSinceEpoch));
    }
    _sett(true);
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.k, info = widget.info;
    final navn = info.navn ?? kHjemKatNavn[k];
    final rest = info.maal - info.klar;
    return CssBox(
      key: _arkKey,
      radius: const BorderRadius.vertical(top: Radius.circular(30)),
      clip: true,
      bg: const [
        CssRadial([Color(0xFF3A8296), Color(0x003A8296)], stops: [0, .62], rx: 1.2, ry: .55, cx: .5, cy: 0),
        CssLinear(180, [Color(0xFF25606F), Color(0xFF1A4652), Color(0xFF133844)], [0, .6, 1]),
      ],
      shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)), CssShadow(0, -30, 60, -20, Color.fromRGBO(3, 14, 20, .7))],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .28), borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                SizedBox(height: 196, child: _hero(k)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
                  child: Column(
                    children: [
                      LfBalanced(
                        '$navn kommer til Ærend',
                        align: TextAlign.center,
                        style: jakarta(
                          25,
                          em: -.03,
                          height: 1.1,
                          shadows: const [Shadow(color: Color.fromRGBO(4, 22, 30, .45), offset: Offset(0, 2))],
                        ),
                      ),
                      const SizedBox(height: 8),
                      LfPretty(
                        info.tekst,
                        align: TextAlign.center,
                        style: inter(13.5, height: 1.5, color: const Color(0xFFD3E6EA)),
                      ),
                    ],
                  ),
                ),
                // BUTIKKER PÅ PLASS
                Container(
                  margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: CssBox(
                    radius: BorderRadius.circular(20),
                    bg: const [
                      CssLinear(180, [Color.fromRGBO(4, 20, 28, .34), Color.fromRGBO(4, 20, 28, .34)]),
                    ],
                    shadows: const [CssShadow.inset(0, 2, 5, 0, Color.fromRGBO(0, 0, 0, .35)), CssShadow(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .12))],
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'BUTIKKER PÅ PLASS',
                              style: inter(10, weight: FontWeight.w800, em: .14, color: const Color(0xFF9FF0D4)),
                            ),
                            const Spacer(),
                            Text('${info.klar} av ${info.maal}', style: jakarta(16, em: -.02).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (var n = 0; n < info.maal; n++) ...[
                              if (n > 0) const SizedBox(width: 4),
                              Expanded(
                                child: _Segment(fylt: n < info.klar, delayMs: 350 + n * 60.0),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          rest <= 0
                              ? 'Alle butikkene er klare. Vi åpner snart.'
                              : 'Vi åpner når ${rest == 1 ? 'den siste butikken' : 'de siste $rest butikkene'} er klare.',
                          style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFFBFD8DF)),
                        ),
                      ],
                    ),
                  ),
                ),
                // Ægil
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CssBox(
                        width: 50,
                        height: 50,
                        radius: BorderRadius.circular(25),
                        clip: true,
                        bg: const [
                          CssRadial([Color(0xFFCFE3EC), Color(0xFF7FA3B2), Color(0xFF4E7383)], stops: [0, .62, 1], circle: true, cx: .4, cy: .28, farthestCorner: true),
                        ],
                        shadows: const [
                          CssShadow.inset(0, 2, 3, 0, Color.fromRGBO(0, 0, 0, .35)),
                          CssShadow(0, 0, 0, 2, Color.fromRGBO(255, 255, 255, .9)),
                          CssShadow(0, 6, 10, -4, Color.fromRGBO(0, 0, 0, .55)),
                        ],
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -5,
                              bottom: -6,
                              width: 60,
                              height: 60,
                              child: LfLoop(
                                builder: (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3200), child: child),
                                child: Image.asset('assets/images/dashboard/wait.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CssBox(
                          radius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(6)),
                          bg: const [
                            CssLinear(180, [Color.fromRGBO(255, 255, 255, .17), Color.fromRGBO(255, 255, 255, .08)]),
                          ],
                          shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1))],
                          padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
                          child: LfPretty(
                            _vs ? 'Notert! Du er blant de første som får vite det når $navn åpner.' : info.aeg,
                            style: inter(12.5, weight: FontWeight.w700, height: 1.45, color: const Color(0xFFF2F8F9)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_vs) _VarsleKnapp(key: _varsleKey, onTap: _varsle),
                      if (_vs) ...[
                        const _VarslerKnapp(),
                        const SizedBox(height: 9),
                        Center(
                          child: GestureDetector(
                            onTap: () => _sett(false),
                            child: Text(
                              'Slå av varselet',
                              style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFFBFD8DF)).copyWith(decoration: TextDecoration.underline, decorationColor: const Color(0xFFBFD8DF)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _RestKnapp(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onRestauranter();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 21,
            child: _GlassKnapp(
              size: 40,
              radius: 14,
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>',
                width: 14,
                height: 14,
              ),
            ),
          ),
          for (final g in _gnister)
            Positioned.fill(
              child: IgnorePointer(
                child: _Gnist(senter: g.$1, key: ValueKey(g.$2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero(int k) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Sunburst: repeating-conic 6°/20°, faded out from 20% radius, 60s.
        Positioned(
          left: 195 - 190,
          top: 104 - 190,
          width: 380,
          height: 380,
          child: RepaintBoundary(
            child: LfLoop(
              builder: (context, t, child) => Transform.rotate(angle: (t / 60000) * 2 * math.pi, child: child),
              child: const CustomPaint(painter: _Solstraaler()),
            ),
          ),
        ),
        const Positioned(
          left: 195 - 120,
          top: 104 - 120,
          width: 240,
          height: 240,
          child: CssBox(
            bg: [
              CssRadial.closestSide([Color.fromRGBO(242, 193, 78, .3), Color.fromRGBO(242, 193, 78, 0)]),
            ],
          ),
        ),
        Positioned(
          left: 195 - 82,
          top: 104 - 82,
          width: 164,
          height: 164,
          child: LfLoop(
            builder: (context, t, child) => Transform.rotate(angle: (t / 18000) * 2 * math.pi, child: child),
            child: const CustomPaint(painter: HjemDashRing(width: 2, color: Color.fromRGBO(255, 231, 168, .55), dash: 5)),
          ),
        ),
        const Positioned(
          left: 195 - 60,
          top: 180,
          width: 120,
          height: 18,
          child: CssBox(
            bg: [
              CssRadial.closestSide([Color.fromRGBO(2, 10, 16, .6), Color.fromRGBO(2, 10, 16, 0)]),
            ],
          ),
        ),
        // The orb, floating (`snartSvev` 4.6s).
        Positioned(
          left: 195 - 56,
          top: 48,
          width: 112,
          height: 112,
          child: LfLoop(
            builder: (context, t, child) {
              final p = (t / 4600) % 1.0;
              return Transform.translate(offset: Offset(0, kf(p, const [0, .5, 1], const [0, -7, 0], cssEaseInOut)), child: child);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: CssBox(
                    radius: BorderRadius.all(Radius.circular(56)),
                    bg: [
                      CssRadial([Color.fromRGBO(255, 255, 255, .4), Color.fromRGBO(255, 255, 255, .1), Color.fromRGBO(255, 255, 255, .05)], stops: [0, .6, 1], rx: .7, ry: .6, cx: .4, cy: .25),
                    ],
                    shadows: [
                      CssShadow.inset(0, 2, 0, 0, Color.fromRGBO(255, 255, 255, .55)),
                      CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .2)),
                      CssShadow.inset(0, -6, 12, 0, Color.fromRGBO(4, 20, 28, .3)),
                      CssShadow(0, 0, 0, 3, Color(0xFFF2C14E)),
                      CssShadow(0, 0, 0, 6, Color.fromRGBO(242, 193, 78, .18)),
                      CssShadow(0, 22, 30, -14, Color.fromRGBO(0, 10, 14, .85)),
                    ],
                  ),
                ),
                Positioned(left: 27, top: 27, child: HjemKatIkon(ikon: k, size: 58, dybde: 1.4, perspektiv: 300)),
              ],
            ),
          ),
        ),
        // KOMMER SNART stamp (`snartStempel` .55s, .25s delay).
        Positioned(
          left: 195 - 72,
          top: 146,
          child: LfOnce(
            ms: 800,
            builder: (context, t, child) {
              final p = ((t - 250) / 550).clamp(0.0, 1.0);
              const c = Cubic(.3, 1.3, .5, 1);
              final s = kf(p, const [0, .6, 1], const [2.2, .92, 1], c);
              final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
              return Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateZ(rad(-9))
                    ..scaleByDouble(s, s, 1, 1),
                  child: child,
                ),
              );
            },
            child: CssBox(
              radius: BorderRadius.circular(11),
              bg: const [
                CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .7)),
                CssShadow.inset(0, -1.5, 0, 0, Color.fromRGBO(0, 0, 0, .1)),
                CssShadow(0, 3, 0, 0, Color(0xFFA87418)),
                CssShadow(0, 10, 14, -6, Color.fromRGBO(3, 14, 20, .7)),
              ],
              padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#5A3C10" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></svg>',
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 5),
                  Text('KOMMER SNART', style: jakarta(11, em: .12, color: const Color(0xFF5A3C10))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Solstraaler extends CustomPainter {
  const _Solstraaler();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2;
    const gul = Color.fromRGBO(255, 231, 168, .12);
    final p = Paint()..shader = RadialGradient(colors: [gul, gul, gul.withValues(alpha: 0)], stops: const [0, .2, 1]).createShader(Rect.fromCircle(center: c, radius: r));
    // conic "from 0deg" starts at 12 o'clock.
    for (var i = 0; i < 18; i++) {
      final a0 = -math.pi / 2 + rad(i * 20.0);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..arcTo(Rect.fromCircle(center: c, radius: r), a0, rad(6), false)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fylt, required this.delayMs});

  final bool fylt;
  final double delayMs;

  @override
  Widget build(BuildContext context) {
    final box = CssBox(
      height: 13,
      radius: BorderRadius.circular(4),
      bg: [
        fylt ? const CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF3CC79F)]) : const CssLinear(180, [Color.fromRGBO(255, 255, 255, .08), Color.fromRGBO(255, 255, 255, .08)]),
      ],
      shadows: fylt
          ? const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .6)), CssShadow(0, 0, 6, 0, Color.fromRGBO(92, 224, 184, .45))]
          : const [CssShadow.inset(0, 1, 2, 0, Color.fromRGBO(0, 0, 0, .4)), CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .08))],
    );
    if (!fylt) return box;
    // snartFyll .45s cubic(.3,1.4,.5,1)
    return LfOnce(
      ms: delayMs + 450,
      builder: (context, t, child) {
        final p = const Cubic(.3, 1.4, .5, 1).transform(((t - delayMs) / 450).clamp(0.0, 1.0));
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.diagonal3Values(1, p, 1), child: child),
        );
      },
      child: box,
    );
  }
}

/// The orange "Varsle meg når det åpner" key.
class _VarsleKnapp extends StatelessWidget {
  const _VarsleKnapp({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LfPress(
      dy: 3.5,
      onTap: onTap,
      child: CssBox(
        height: 56,
        radius: BorderRadius.circular(18),
        clip: true,
        bg: const [
          CssLinear(180, [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFE95C2C)], [0, .55, 1]),
        ],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
          CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
          CssShadow(0, 4, 0, 0, Color(0xFFA63A12)),
          CssShadow(0, 14, 20, -8, Color.fromRGBO(120, 40, 10, .6)),
        ],
        child: Stack(
          children: [
            const _Glans(),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LfLoop(
                    builder: (context, t, child) {
                      final p = (t / 2600) % 1.0;
                      final r = kf(p, const [0, .6, .66, .72, .78, .84, .9, 1], const [0, 0, 16, -14, 9, -5, 2, 0], cssEaseInOut);
                      return Transform.rotate(alignment: const Alignment(0, -.7), angle: rad(r), child: child);
                    },
                    child: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/></svg>',
                      width: 17,
                      height: 17,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Varsle meg når det åpner',
                    style: jakarta(
                      15,
                      shadows: const [Shadow(color: Color.fromRGBO(120, 40, 10, .4), offset: Offset(0, 1))],
                    ),
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

/// The mint "Du får beskjed" key (`snartPop`).
class _VarslerKnapp extends StatelessWidget {
  const _VarslerKnapp();

  @override
  Widget build(BuildContext context) {
    return LfOnce(
      ms: 450,
      builder: (context, t, child) {
        final s = kf(t / 450, const [0, .55, 1], const [.9, 1.05, 1], const Cubic(.3, 1.4, .5, 1));
        return Transform.scale(scale: s, child: child);
      },
      child: CssBox(
        height: 56,
        radius: BorderRadius.circular(18),
        clip: true,
        bg: const [
          CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF5CE0B8), Color(0xFF3CC79F)], [0, .55, 1]),
        ],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .65)),
          CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .06)),
          CssShadow(0, 4, 0, 0, Color(0xFF23946F)),
          CssShadow(0, 14, 20, -8, Color.fromRGBO(20, 110, 80, .6)),
        ],
        child: Stack(
          children: [
            const _Glans(),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Color(0xFF23946F), offset: Offset(0, 2))],
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1F8A66" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>',
                      width: 13,
                      height: 13,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text('Du får beskjed', style: jakarta(15, color: const Color(0xFF0F3A40))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The glossy top half of the big keys.
class _Glans extends StatelessWidget {
  const _Glans();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 12,
      right: 12,
      top: 2,
      height: 56 * .46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.elliptical(14, 14), topRight: Radius.elliptical(14, 14), bottomLeft: Radius.elliptical(30, 10), bottomRight: Radius.elliptical(30, 10)),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .32), Color.fromRGBO(255, 255, 255, 0)]),
        ),
      ),
    );
  }
}

/// "Bestill fra restauranter i mellomtiden".
class _RestKnapp extends StatelessWidget {
  const _RestKnapp({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LfPress(
      dy: 2.5,
      onTap: onTap,
      child: CssBox(
        height: 52,
        radius: BorderRadius.circular(17),
        bg: _kGlass,
        shadows: _kGlassShadow,
        padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
        child: Row(
          children: [
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#9FF0D4" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17h18M5 17a7 7 0 0 1 14 0M12 8V6M10 6h4M2 20h20"/></svg>',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Bestill fra restauranter i mellomtiden', style: inter(13.5, weight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            CssBox(
              width: 34,
              height: 34,
              radius: BorderRadius.circular(17),
              bg: const [
                CssRadial([Color(0xFFFFFFFF), Color(0xFFEEF4F5), Color(0xFFD5E1E4)], stops: [0, .55, 1], rx: .7, ry: .6, cx: .4, cy: .25),
              ],
              shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 2, 0, 0, Color.fromRGBO(4, 20, 28, .4))],
              child: Center(
                child: SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1E4F5C" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5.5l6.5 6.5-6.5 6.5"/></svg>',
                  width: 12,
                  height: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The prototype's frosted keys (`backdrop-filter: blur(16px)`) sit on the
// sheet's smooth gradient, where the blur adds nothing visible; drawn
// without it to stay within one blur layer per screen.
const List<CssBg> _kGlass = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, .07)]),
];
const List<CssShadow> _kGlassShadow = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .42)),
  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
  CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(4, 20, 28, .2)),
  CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .55)),
  CssShadow(0, 12, 18, -10, Color.fromRGBO(3, 14, 20, .85)),
];

class _GlassKnapp extends StatelessWidget {
  const _GlassKnapp({required this.size, required this.radius, required this.onTap, required this.child});

  final double size, radius;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LfPress(
      dy: 2.5,
      onTap: onTap,
      child: CssBox(
        width: size,
        height: size,
        radius: BorderRadius.circular(radius),
        bg: _kGlass,
        shadows: _kGlassShadow,
        child: Center(child: child),
      ),
    );
  }
}

/// `snartGnist`: 18 confetti bits bursting from the key.
class _Gnist extends StatefulWidget {
  const _Gnist({super.key, required this.senter});

  final Offset senter;

  @override
  State<_Gnist> createState() => _GnistState();
}

class _GnistState extends State<_Gnist> {
  late final List<(double, double, double, double)> _p = () {
    final r = math.Random();
    return [for (var i = 0; i < 18; i++) ((i / 18) * math.pi * 2 + r.nextDouble() * .3, 60 + r.nextDouble() * 70, 5 + r.nextDouble() * 5, 800 + r.nextDouble() * 300)];
  }();

  static const _farger = [Color(0xFF5CE0B8), Color(0xFFFF9466), Color(0xFFFFFFFF), Color(0xFFF2C14E)];

  @override
  Widget build(BuildContext context) {
    final c = widget.senter;
    return LfOnce(
      ms: 1100,
      builder: (context, t, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < _p.length; i++)
            () {
              final (a, dist, sz, dur) = _p[i];
              final e = const Cubic(.2, .7, .3, 1).transform((t / dur).clamp(0.0, 1.0));
              final h = i % 3 != 0 ? sz : sz * .5;
              return Positioned(
                left: c.dx - sz / 2 + math.cos(a) * dist * 1.3 * e,
                top: c.dy - sz / 2 + (math.sin(a) * dist * .6 - 30) * e,
                width: sz,
                height: h,
                child: Opacity(
                  opacity: (1 - e).clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(rad((200 + i * 40) * e))
                      ..scaleByDouble(1 - .8 * e, 1 - .8 * e, 1, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: _farger[i % 4], borderRadius: BorderRadius.circular(i % 3 != 0 ? sz : 2)),
                    ),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}
