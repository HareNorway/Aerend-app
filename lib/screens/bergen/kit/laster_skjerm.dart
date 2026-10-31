import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../onboarding/onb_runde.dart';

import '../../common/auth/launch/lf_css.dart';
import 'bergen_perf.dart';
import 'merke_3d.dart';

// ── Lasting mellom skjermer (Bergen 29 Oct, `skjermLaster`, L19133–19193) ───
// A teal glass veil over the whole screen; the 3D Æ block flies in from far
// back (−700), settles, and leaves toward the viewer (+600), under a mint
// light with a shadow; the screen's name and a 72px bar. The design plays the
// 1.25s cycle on every screen change. Here (the user's choice, 2026-10-29) it
// is the loading state of a pushed screen: it shows while the screen fetches
// (never between tabs, never on Sporing), holds with a gentle float until the
// data is there, and always plays at least the full cycle. Reduced motion and
// the `still` tier skip it (`ldrRolig`), as the design does.
//
// A screen wraps its body in [BergenSkjermLaster] with [aktiv] true while it
// loads; the veil lives in the root overlay, above the route transition.

class BergenSkjermLaster extends StatefulWidget {
  const BergenSkjermLaster({super.key, required this.aktiv, required this.navn, required this.child});

  final bool aktiv;

  /// `NAVN[s]`: what the veil says («Butikken», «Bestillinger» …).
  final String navn;
  final Widget child;

  /// The design's names per screen.
  static const Map<String, String> navnFor = {
    'hjem': 'Hjem',
    'utforsk': 'Utforsk',
    'kategori': 'Kategori',
    'butikk': 'Butikken',
    'kurv': 'Kurven',
    'meg': 'Meg',
    'fiske': 'Fjordfiske',
    'agent': 'Ærend AI',
    'hurtig': 'Hurtigbestilling',
    'velger': 'Ægil velger',
    'opprykk': 'Nytt nivå',
    'sok': 'Søk',
    'bestillinger': 'Bestillinger',
    'ordrer': 'Bestillinger',
    'aiKurv': 'Kurven',
  };

  /// Test seam: whether a veil is up.
  static bool get erOppe => _SkjermLaster._entry != null;

  /// Test seam: forget any veil (between tests).
  static void nullstill() => _SkjermLaster._nullstill();

  @override
  State<BergenSkjermLaster> createState() => _BergenSkjermLasterState();
}

class _BergenSkjermLasterState extends State<BergenSkjermLaster> {
  _Hold? _hold;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BergenSkjermLaster old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    // Onboarding Step 2: never under Ægil-runden (the design's `ldrSkjermKan` is false while `rt` is up).
    if (widget.aktiv && _hold == null && !OnbRunde.instance.aktiv) {
      if (MediaQuery.disableAnimationsOf(context) || BergenPerf.of(context) == BergenTier.still) return;
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) return;
      _hold = _SkjermLaster.hold(overlay, widget.navn);
    } else if (!widget.aktiv && _hold != null) {
      _hold!.slipp();
      _hold = null;
    }
  }

  @override
  void dispose() {
    _hold?.slipp();
    _hold = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Hold {
  _Hold(this.navn);
  final String navn;
  bool sluppet = false;
  void slipp() {
    if (sluppet) return;
    sluppet = true;
    _SkjermLaster._slipp(this);
  }
}

/// One veil at a time (`_ldrSk`): holds join it, the veil runs until the
/// last hold is released and the cycle is complete.
abstract final class _SkjermLaster {
  static OverlayEntry? _entry;
  static final Set<_Hold> _holds = {};
  static final ValueNotifier<String> navn = ValueNotifier<String>('Ærend');
  static final ValueNotifier<bool> holder = ValueNotifier<bool>(false);

  static _Hold hold(OverlayState overlay, String n) {
    final h = _Hold(n);
    _holds.add(h);
    navn.value = n;
    holder.value = true;
    if (_entry == null) {
      final e = _entry = OverlayEntry(builder: (context) => _Veil(navn: navn, holder: holder, onFerdig: _fjern));
      // A hold starts in a build (didChangeDependencies): the overlay takes
      // the entry after the frame.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_entry == e && overlay.mounted) overlay.insert(e);
      });
    }
    return h;
  }

  /// The veil's widget went away with its overlay: forget the entry.
  static void _borte() {
    _entry = null;
    _holds.clear();
    holder.value = false;
  }

  static void _nullstill() {
    final e = _entry;
    _entry = null;
    _holds.clear();
    holder.value = false;
    if (e != null && e.mounted) e.remove();
  }

  static void _slipp(_Hold h) {
    _holds.remove(h);
    if (_holds.isEmpty) holder.value = false;
  }

  static void _fjern() {
    final e = _entry;
    _entry = null;
    _holds.clear();
    holder.value = false;
    if (e != null && e.mounted) e.remove();
  }
}

/// `data-lsskjerm`: the 1250ms timeline, paused at .70 while held.
class _Veil extends StatefulWidget {
  const _Veil({required this.navn, required this.holder, required this.onFerdig});

  final ValueNotifier<String> navn;
  final ValueNotifier<bool> holder;
  final VoidCallback onFerdig;

  @override
  State<_Veil> createState() => _VeilState();
}

double _e(Curve c, double x) => c.transform(x.clamp(0.0, 1.0));

class _VeilState extends State<_Veil> with SingleTickerProviderStateMixin {
  static const double _d = 1250, _hold = .70;
  late final Ticker _tikk = createTicker(_onTikk);
  double _ms = 0;

  /// Time spent waiting at the hold point (not part of the cycle).
  double _vent = 0;
  double? _sist;
  bool _ferdig = false;

  @override
  void initState() {
    super.initState();
    _tikk.start();
  }

  @override
  void dispose() {
    _tikk.dispose();
    if (!_ferdig) _SkjermLaster._borte();
    super.dispose();
  }

  void _onTikk(Duration e) {
    final now = e.inMicroseconds / 1000;
    final dt = _sist == null ? 0.0 : now - _sist!;
    _sist = now;
    // Held: the cycle stops at the hold point (never skipped by a long
    // frame) and the wait runs its own clock.
    const holdMs = _hold * _d;
    if (widget.holder.value && _ms < holdMs) {
      final rom = holdMs - _ms;
      if (dt <= rom) {
        _ms += dt;
      } else {
        _ms = holdMs;
        _vent += dt - rom;
      }
    } else if (widget.holder.value && _ms >= holdMs) {
      _vent += dt;
    } else {
      _ms += dt;
    }
    if (_ms >= _d && !_ferdig) {
      _ferdig = true;
      _tikk.stop();
      SchedulerBinding.instance.addPostFrameCallback((_) => widget.onFerdig());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = (_ms / _d).clamp(0.0, 1.0);
    final size = MediaQuery.sizeOf(context);
    final w = size.width, h = size.height;
    final cy = h * .44;
    // The veil (effect easing linear; per-keyframe ease-out / ease-in).
    final op = p < .12
        ? _e(cssEaseOut, p / .12)
        : p < .82
        ? 1.0
        : 1 - _e(cssEaseIn, (p - .82) / .18);
    final scene = p < .76 ? 1.0 : (p < .96 ? 1 - (p - .76) / .2 : 0.0);
    // The block: translate3d / rotateX / rotateY per keyframe.
    final double lx, ly, lz, rx, ry;
    if (p < .42) {
      final u = _e(const Cubic(.16, .8, .25, 1), p / .42);
      lx = 0;
      ly = 24 + (-4 - 24) * u;
      lz = -700 + (20 + 700) * u;
      rx = 24 + (-6 - 24) * u;
      ry = -38 + (14 + 38) * u;
    } else if (p < .56) {
      final u = _e(const Cubic(.4, 0, .4, 1), (p - .42) / .14);
      lx = 0;
      ly = -4 + 4 * u;
      lz = 20 - 20 * u;
      rx = -6 + 9 * u;
      ry = 14 - 20 * u;
    } else if (p < .72) {
      final u = _e(cssEaseInOut, (p - .56) / .16);
      lx = 0;
      ly = -3 * u;
      lz = 0;
      rx = 3 - 3 * u;
      ry = -6 + 8 * u;
    } else {
      final u = _e(const Cubic(.6, 0, .9, .4), (p - .72) / .28);
      lx = 0;
      ly = -3 - 7 * u;
      lz = 600 * u;
      rx = -10 * u;
      ry = 2 - 2 * u;
    }
    // The float while held: a slow bob and a sheen every 1.6s.
    final vent = _vent;
    final bob = p >= _hold && widget.holder.value ? math.sin(vent / 1600 * 2 * math.pi) : 0.0;
    final glansVent = (vent % 1600) < 450 ? 230 * _e(cssEaseInOut, (vent % 1600) / 450) : 230.0;
    // The sheen: 0 until .5, to 230 at .76 (effect ease-in-out).
    final gp = _e(cssEaseInOut, p);
    final glans = p >= _hold && widget.holder.value ? glansVent : kf(gp, const [0, .5, .76, 1], const [0, 0, 230, 230]);
    final lp = _e(cssEaseOut, p);
    final lysOp = kf(lp, const [0, .45, .72, 1], const [0, 1, .8, 0]);
    final lysS = kf(lp, const [0, .45, .72, 1], const [.4, 1, 1.05, 1.8]);
    final skOp = kf(p, const [0, .44, .72, 1], const [0, 1, 1, 0]);
    final skS = kf(p, const [0, .44, .72, 1], const [.2, 1.08, 1, 1.6]);
    final tp = _e(cssEaseOut, p);
    final txOp = kf(tp, const [0, .3, .5, .74, 1], const [0, 0, 1, 1, 0]);
    final txY = kf(tp, const [0, .3, .5, .74, 1], const [10, 10, 0, 0, -6]);
    final txEm = kf(tp, const [0, .3, .5, 1], const [.2, .2, -.01, -.01]);
    final fp = _e(const Cubic(.4, 0, .2, 1), p);
    final fyll = kf(fp, const [0, .28, .74, 1], const [0, 0, 1, 1]);

    // Taps are blocked while the screen is still loading (as the design
    // does); once the data is in and the veil only leaves, they go through.
    // (The ticker rebuilds every frame, so the release is seen at once.)
    return IgnorePointer(
      ignoring: !widget.holder.value,
      child: Opacity(
        opacity: op.clamp(0, 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              enabled: BergenPerf.blurOn(context),
              filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: const CssBox(
                bg: [
                  CssRadial([Color.fromRGBO(92, 224, 184, .14), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .7], rx: .7, ry: .44, cx: .5, cy: .44),
                  CssLinear(180, [Color.fromRGBO(42, 98, 114, .9), Color.fromRGBO(30, 79, 92, .95), Color.fromRGBO(19, 52, 62, .98)], [0, .52, 1]),
                ],
              ),
            ),
            Opacity(
              opacity: scene.clamp(0, 1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: w / 2 - 170,
                    top: cy - 170,
                    width: 340,
                    height: 340,
                    child: Opacity(
                      opacity: lysOp.clamp(0, 1),
                      child: Transform.scale(
                        scale: lysS,
                        child: const CssBox(
                          radius: BorderRadius.all(Radius.circular(170)),
                          bg: [
                            CssRadial.closestSide([Color.fromRGBO(150, 240, 212, .34), Color.fromRGBO(92, 224, 184, .12), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .45, 1]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w / 2 - 85,
                    top: cy + 86 - 15,
                    width: 170,
                    height: 30,
                    child: Opacity(
                      opacity: skOp.clamp(0, 1),
                      child: Transform.scale(
                        scale: skS,
                        child: const CssBox(
                          radius: BorderRadius.all(Radius.circular(15)),
                          bg: [
                            CssRadial.closestSide([Color.fromRGBO(3, 14, 20, .6), Color.fromRGBO(3, 14, 20, 0)]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w / 2 - 66,
                    top: cy - 53,
                    child: Merke3D(width: 132, height: 106, lag: kMerkeLagSkjerm, perspektiv: 760, x: lx, y: ly + 3 * bob, z: lz, rx: rx, ry: ry + 3 * bob, glansX: glans, glansZ: .6),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: cy + 108,
              child: Column(
                children: [
                  Opacity(
                    opacity: txOp.clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(0, txY),
                      child: ValueListenableBuilder<String>(
                        valueListenable: widget.navn,
                        builder: (context, n, _) => Text(n, key: const Key('skjerm_laster_navn'), style: jakarta(17, em: txEm, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 72,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .16))),
                          Positioned.fill(
                            child: Transform(
                              alignment: Alignment.centerLeft,
                              transform: Matrix4.diagonal3Values(math.max(fyll, .0001), 1, 1),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                  gradient: LinearGradient(colors: [Color(0xFF5CE0B8), Color(0xFFB8F5E2)]),
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
          ],
        ),
      ),
    );
  }
}
