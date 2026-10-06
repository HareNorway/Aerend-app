import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_kit.dart' show bergenSvg;
import '../aegil/aegil_bits.dart';
import '../kit/bergen_kit.dart';
import '../kit/svg_sti.dart';
import '../meg/a3_services.dart';
import 'poeng_copy.dart';
import 'prize_art.dart';

/// Ægil velger (`erVelger`, L7709–7768 in `Ærend Kunde Launch.dc.html`,
/// design px): night over Vågen — the aurora swaying (`sway`), Bryggen's
/// lit windows and the water (the prototype's backdrop, baked) — while Ægil
/// rows out in the longship, casts, gets a bite, and rows back with a crate
/// (`startVelger`: 1.5 / 3.1 / 4.3 / 6.0 s); then the crate opens under the
/// brighter aurora and «Premien Ægil valgte» lands: the prize from
/// `points/prizes/pick`, its value, why Ægil chose it, «Hent premien»,
/// «Bra» / «Ikke for meg». «Hopp over» from 2 s.
class AegilVelgerScreen extends StatefulWidget {
  const AegilVelgerScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<AegilVelgerScreen> createState() => _AegilVelgerScreenState();
}

class _AegilVelgerScreenState extends State<AegilVelgerScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  AegilPick? _pick;
  int _steg = 0;
  bool _kanSkippe = false;
  String? _svar;
  final List<Timer> _t = [];

  static const List<String> _titler = ['Ægil ror ut på Vågen', 'Leter', 'Noe biter', 'Han drar den inn', 'Ægil valgte'];
  static const List<String> _undre = [
    'Han leter etter noe som passer deg.',
    'Kaster ut ved Nordnes og venter.',
    'Snoren strammer seg.',
    'Ror tilbake til kaien med kassen.',
    'Kassen åpnet seg under nordlyset.',
  ];

  @override
  void initState() {
    super.initState();
    a3Try(_api.pick).then((p) {
      if (mounted) setState(() => _pick = p);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() => _steg = 4);
        return;
      }
      void at(int ms, VoidCallback f) => _t.add(Timer(Duration(milliseconds: ms), () {
        if (mounted) setState(f);
      }));
      at(1500, () => _steg = 1);
      at(2000, () => _kanSkippe = true);
      at(3100, () => _steg = 2);
      at(4300, () => _steg = 3);
      at(6000, () => _steg = 4);
    });
  }

  @override
  void dispose() {
    for (final t in _t) {
      t.cancel();
    }
    super.dispose();
  }

  void _skip() {
    for (final t in _t) {
      t.cancel();
    }
    setState(() => _steg = 4);
  }

  Future<void> _claim() async {
    final id = _pick?.prizeId;
    if (id == null) return;
    final r = await _api.claim(id);
    if (!mounted) return;
    if (r.claim != null) {
      showBergenToast(context, '${_pick?.prizeName} er din', icon: Icons.check_rounded);
      Navigator.of(context).maybePop();
    } else if (r.error != null) {
      showBergenToast(context, r.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _steg;
    return Scaffold(
      backgroundColor: const Color(0xFF081F28),
      body: LfFrame(
        child: Builder(
          builder: (context) {
            final top = MediaQuery.paddingOf(context).top;
            final bunn = math.max(MediaQuery.paddingOf(context).bottom, 0.0);
            return AeOnce(
              kind: AeInn.skjermInn,
              ms: 340,
              curve: const Cubic(.2, .9, .3, 1),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned(left: 0, top: 0, width: 390, height: 844, child: Image(image: AssetImage('assets/images/meg/velger.jpg'), fit: BoxFit.fill)),
                  Positioned(left: 0, top: 0, width: 390, height: 300, child: _Nordlys(sterk: s >= 4)),
                  Positioned(
                    left: 28,
                    right: 28,
                    top: math.max(56, top + 6),
                    child: Column(
                      children: [
                        Text(A3PoengCopy.a3_poeng_velger_kicker, style: inter(11, weight: FontWeight.w800, em: .1, color: kAeMint)),
                        const SizedBox(height: 8),
                        AeOnce(
                          key: ValueKey('t$s'),
                          kind: AeInn.ord,
                          ms: 900,
                          curve: cssEaseOut,
                          child: Text(_titler[s], textAlign: TextAlign.center, style: jakarta(26, em: -.03, height: 1.15, color: const Color(0xFFF5F3EF))),
                        ),
                        const SizedBox(height: 7),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 36),
                          child: Text(_undre[s], textAlign: TextAlign.center, style: inter(12.5, height: 1.45, color: const Color(0xFF9FB6C2))),
                        ),
                      ],
                    ),
                  ),
                  if (s < 4) ...[
                    const Positioned(left: 0, right: 0, top: 430, child: Center(child: _Ringer())),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 1600),
                      curve: const Cubic(.4, 0, .3, 1),
                      left: s == 0 ? 18 : (s >= 3 ? 26 : 132),
                      top: 378,
                      width: 150,
                      height: 160,
                      child: _Baat(steg: s),
                    ),
                  ] else
                    Positioned(left: 22, right: 22, top: 274, child: _Avslort(pick: _pick, svar: _svar, onHent: _claim, onSvar: (v) => setState(() => _svar = v))),
                  if (_kanSkippe && s < 4)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 44 + bunn * .5,
                      child: Center(
                        child: AePress(
                          key: const Key('velger-hopp'),
                          onTap: _skip,
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color.fromRGBO(255, 255, 255, .14),
                              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .28)),
                            ),
                            child: Center(widthFactor: 1, child: Text(A3PoengCopy.a3_poeng_velger_hopp, style: inter(12, weight: FontWeight.w800, color: const Color(0xFFF5F3EF)))),
                          ),
                        ),
                      ),
                    ),
                  if (s >= 4)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 44 + bunn * .5,
                      child: Center(
                        child: GestureDetector(
                          key: const Key('velger-tilbake'),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Text(A3PoengCopy.a3_poeng_velger_tilbake, style: inter(12, weight: FontWeight.w800, color: const Color(0xFF9FB6C2))),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The two aurora bands (`url(#nl-grad)` mint → violet, `#mykt` blur 6),
/// swaying (`sway 8s` / `11s 1.2s`), dim while Ægil fishes, bright when the
/// crate opens (`vNordlys` .28 → .85, `.8s`).
class _Nordlys extends StatelessWidget {
  const _Nordlys({required this.sterk});
  final bool sterk;

  static final Path _a = svgSti('M-20 150 C70 96 150 130 240 84 C300 54 350 66 410 34');
  static final Path _b = svgSti('M-20 196 C80 150 168 176 250 132 C310 100 366 108 410 82');

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AeTw(
      v: sterk ? 1 : 0,
      ms: 800,
      builder: (k) => RepaintBoundary(
        child: LfLoop(
          builder: (context, t, _) {
            Widget band(Path p, double w, double op, double period, double delay) {
              final q = (((t - delay) / period) % 1.0);
              final skew = kf(q, const [0, .5, 1], const [-4, 3, -4], cssEaseInOut);
              final x = kf(q, const [0, .5, 1], const [0, 9, 0], cssEaseInOut);
              return Opacity(
                opacity: op,
                child: Transform.translate(
                  offset: Offset(x, 0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.skewX(rad(skew)),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: CustomPaint(size: const Size(390, 300), painter: _Strek(p, w)),
                    ),
                  ),
                ),
              );
            }

            return Stack(
              children: [
                band(_a, 30, .28 + (.85 - .28) * k, 8000, 0),
                band(_b, 14, .2 + (.6 - .2) * k, 11000, 1200),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Strek extends CustomPainter {
  _Strek(this.p, this.w);
  final Path p;
  final double w;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..shader = ui.Gradient.linear(const Offset(-20, 0), const Offset(410, 0), const [kAeMint, Color(0xFF9C7BE8)]),
  );

  @override
  bool shouldRepaint(_Strek old) => false;
}

/// The two ripple rings at the fishing spot (`rippel 3s`, 1.5 s apart).
class _Ringer extends StatelessWidget {
  const _Ringer();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 36,
    child: RepaintBoundary(
      child: LfLoop(
        builder: (context, t, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (d, a) in const [(0.0, .35), (1500.0, .3)])
              Builder(
                builder: (context) {
                  final p = kfLoop(t, d, 3000);
                  if (p == null) return const SizedBox.shrink();
                  final e = cssEaseOut.transform(p);
                  return Positioned.fill(
                    child: Opacity(
                      opacity: (.8 * (1 - e)).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: .4 + 1.2 * e,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.elliptical(90, 18)),
                            border: Border.all(color: Color.fromRGBO(255, 255, 255, a), width: 2),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// The longship (`bob 4s`) with Ægil (`aegBob 3.4s`, rear → find → shock →
/// explore), the line while fishing, and the crate.
class _Baat extends StatelessWidget {
  const _Baat({required this.steg});
  final int steg;

  @override
  Widget build(BuildContext context) {
    final pose = switch (steg) {
      0 => 'rear',
      1 => 'find',
      2 => 'shock',
      _ => 'explore',
    };
    final k = steg == 2 ? 40.0 : 120.0;
    return RepaintBoundary(
      child: LfLoop(
        builder: (context, t, _) {
          final bob = kf((t / 4000) % 1.0, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
          final aeg = kf((t / 3400) % 1.0, const [0, .5, 1], const [0, -2.5, 0], cssEaseInOut);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: 120,
                height: 68,
                child: Transform.translate(
                  offset: Offset(0, bob),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[.9, 0, 0, 0, 0, 0, .9, 0, 0, 0, 0, 0, .9, 0, 0, 0, 0, 0, 1, 0]),
                    child: bergenSvg('longship3d', fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(left: 38, top: -34 + aeg, width: 58, child: Image.asset(aePose(pose), width: 58, gaplessPlayback: true)),
              if (steg == 1 || steg == 2)
                Positioned(
                  left: 86,
                  top: 22,
                  width: 170,
                  height: 150,
                  child: AeTw(v: k, ms: 300, builder: (kk) => CustomPaint(painter: _Snor(kk))),
                ),
              if (steg >= 2)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 900),
                  curve: cssEase,
                  left: steg == 2 ? 96 : 8,
                  top: steg == 2 ? 92 : -8,
                  width: 54,
                  height: 44,
                  child: bergenSvg('bag3d', fit: BoxFit.contain),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Snor extends CustomPainter {
  _Snor(this.k);
  final double k;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(2, 4)
      ..cubicTo(40, k, 92, k, 118, 96),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color.fromRGBO(255, 255, 255, .6),
  );

  @override
  bool shouldRepaint(_Snor old) => old.k != k;
}

/// «Premien Ægil valgte» (L7740–7760): the tinted art header with the
/// merchant chip, the name, the value, Ægil's reason, «Hent premien» and the
/// two feedback words.
class _Avslort extends StatelessWidget {
  const _Avslort({required this.pick, required this.svar, required this.onHent, required this.onSvar});

  final AegilPick? pick;
  final String? svar;
  final VoidCallback onHent;
  final ValueChanged<String> onSvar;

  @override
  Widget build(BuildContext context) {
    final p = pick;
    final prize = p?.prize;
    final navn = p?.prizeName ?? A3PoengCopy.a3_poeng_velger_tom;
    final art = PrizeArt.of(slug: prize?['slug'] as String?, name: navn);
    final merke = (prize?['partner_name'] as String?) ?? 'Ærend';
    return LfOnce(
      ms: 550,
      builder: (context, t, child) {
        final e = const Cubic(.3, 1.2, .5, 1).transform((t / 550).clamp(0.0, 1.0));
        return Opacity(
          opacity: e.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 140 * (1 - e)), child: Transform.scale(scale: .86 + .14 * e, child: child)),
        );
      },
      child: CssBox(
        key: const Key('velger-premie'),
        radius: BorderRadius.circular(28),
        clip: true,
        bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .94))],
        shadows: const [
          CssShadow.inset(0, 2, 0, 0, Colors.white),
          CssShadow(0, 30, 52, -20, Color.fromRGBO(8, 24, 32, .75)),
        ],
        border: Border.all(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 158,
              child: Stack(
                children: [
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: art.gradient))),
                  const Positioned.fill(
                    child: CssBox(
                      bg: [
                        CssRadial([Color.fromRGBO(255, 255, 255, .6), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .62], rx: 1.2, ry: .9, cx: .3, cy: .08),
                      ],
                    ),
                  ),
                  Center(
                    child: RepaintBoundary(
                      child: LfLoop(
                        child: SizedBox(width: 132, height: 88, child: bergenSvg(art.icon, fit: BoxFit.contain)),
                        builder: (context, t, child) => Transform.translate(
                          offset: Offset(0, kf((t / 4000) % 1.0, const [0, .5, 1], const [0, -5, 0], cssEaseInOut)),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .9)),
                      child: Text(merke, style: inter(9.5, weight: FontWeight.w800, color: kAeInk)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(navn, style: jakarta(19, em: -.025, height: 1.15, color: kAeInk)),
                  if (prize != null) ...[
                    const SizedBox(height: 4),
                    Text(p?.valueHint ?? A3PoengCopy.a3_poeng_velger_verdi, style: inter(12, weight: FontWeight.w800, color: kAeTeal)),
                  ],
                  if ((p?.reason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(aePose('invitation'), width: 26, height: 26, fit: BoxFit.contain),
                        const SizedBox(width: 9),
                        Expanded(child: Text(p!.reason, style: inter(12, height: 1.45, color: const Color(0xFF57534B)))),
                      ],
                    ),
                  ],
                  if (prize != null) ...[
                    const SizedBox(height: 13),
                    _Svevende(
                      child: AePress(
                        key: const Key('velger-hent'),
                        onTap: p!.affordable ? onHent : null,
                        dy: 0,
                        scale: .98,
                        child: Opacity(
                          opacity: p.affordable ? 1 : .5,
                          child: const CssBox(
                            height: 48,
                            radius: BorderRadius.all(Radius.circular(999)),
                            bg: [
                              CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)]),
                            ],
                            shadows: [
                              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                              CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(150, 40, 10, .3)),
                            ],
                            child: Center(child: _HentTekst()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => onSvar('bra'),
                          child: Text(A3PoengCopy.a3_poeng_velger_bra, style: inter(11.5, weight: FontWeight.w800, color: svar == 'bra' ? const Color(0xFF2E6B47) : const Color(0xFF8C847C))),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => onSvar('nei'),
                          child: Text(A3PoengCopy.a3_poeng_velger_ikke, style: inter(11.5, weight: FontWeight.w800, color: svar == 'nei' ? const Color(0xFFB9441A) : const Color(0xFF8C847C))),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HentTekst extends StatelessWidget {
  const _HentTekst();

  @override
  Widget build(BuildContext context) => Text(A3PoengCopy.a3_poeng_velger_hent, style: inter(14, weight: FontWeight.w800));
}

/// `aeKnSvev 3.4s -2.9s` with its soft shadow.
class _Svevende extends StatelessWidget {
  const _Svevende({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      child: child,
      builder: (context, t, child) {
        final p = ((t + 2900) / 3400) % 1.0;
        final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
        final sx = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
        final o = kf(p, const [0, .5, 1], const [1, .6, 1], cssEaseInOut);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 49 + 5 * (1 - (sx - .82) / .18),
              height: 15,
              child: FractionallySizedBox(
                widthFactor: .8 * sx,
                child: Opacity(
                  opacity: o,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(140, 7.5)),
                      gradient: RadialGradient(colors: [Color.fromRGBO(8, 26, 32, .5), Color.fromRGBO(0, 0, 0, 0)], stops: [0, .72]),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(offset: Offset(0, y), child: child),
          ],
        );
      },
    ),
  );
}
