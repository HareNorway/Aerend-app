import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../onboarding/onb_runde.dart';
import '../onboarding/onb_tips.dart';

import '../../common/auth/launch/lf_css.dart';
import 'bergen_perf.dart';
import 'merke_3d.dart';

// ── Dra for å oppdatere (Bergen 29 Oct, `scrollLaster`, L18987–19120) ───────
// Pull down at the top of a screen: a dark glass puck with the 3D Æ block
// comes down with the content, an orange ring fills as you pull (66px to
// arm, mint when armed, a pop and a tick), a pill says what to do. Released
// armed, the content holds 62px down while the block wobbles and the ring
// spins (1.6s, longer while the host is still fetching); then «Oppdatert»,
// a pop with a sheen, and everything settles back (420ms, a little
// overshoot). The pull is `150·(1 − e^(−d/200))` of the finger's travel.
//
// Wrap the scrollable in [BergenDraLaster] and give the scrollable
// [BergenDraLaster.physics] (bouncing, but blocked at the top so the pull is
// ours: the design never shows the native bounce there). Hosts whose
// content must move in their own way (Hjem: the sheet moves and the hero
// grows) take [onY] and set [flyttInnhold] false.

class BergenDraLaster extends StatefulWidget {
  const BergenDraLaster({
    super.key,
    required this.child,
    this.onRefresh,
    this.aktiv = true,
    this.onY,
    this.flyttInnhold = true,
    this.topp = 0,
  });

  final Widget child;

  /// The host's reload; the spin lasts at least the design's 1.6s.
  final Future<void> Function()? onRefresh;

  /// `ldrDraKan`: off while a sheet, the splash or the onboarding is up.
  final bool aktiv;

  /// The content's displacement (pull + hold), every frame.
  final ValueChanged<double>? onY;

  /// Translate [child] by the displacement (false: the host does it).
  final bool flyttInnhold;

  /// Where the scrollable's top edge is, from this widget's top (`top0`).
  final double topp;

  /// The platform's physics, stopped at the top (the pull is drawn by us).
  static const ScrollPhysics physics = _DraPhysics(parent: AlwaysScrollableScrollPhysics());

  /// Debug: `"demo"` plays the design's `ldrDemo` (a 620ms pull to 175 and
  /// a release) on every mounted pull; `"hold"` the same but stays at
  /// «Oppdaterer …».
  static final ValueNotifier<String?> demo = ValueNotifier<String?>(null);

  @override
  State<BergenDraLaster> createState() => _BergenDraLasterState();
}

/// The platform's own physics (the iOS bounce, Android's clamp) with the top
/// edge blocked, so the pull is drawn by us and the bottom stays as it was.
class _DraPhysics extends ScrollPhysics {
  const _DraPhysics({super.parent});

  @override
  _DraPhysics applyTo(ScrollPhysics? ancestor) => _DraPhysics(parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels && position.pixels <= position.minScrollExtent) return value - position.pixels;
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) return value - position.minScrollExtent;
    return super.applyBoundaryConditions(position, value);
  }
}

enum _Fase { av, ned, oppdater, ferdig, tilbake }

class _BergenDraLasterState extends State<BergenDraLaster> with TickerProviderStateMixin {
  static const double _g = 66, _h = 62;
  static const Color _oransje = Color(0xFFF26D3D), _mint = Color(0xFF5CE0B8);

  _Fase _fase = _Fase.av;

  /// The finger's travel (d) and the pull it gives (y).
  double _d = 0, _y = 0;

  /// Overscroll from a scrollable with plain bouncing physics (fallback).
  double _over = 0;
  bool _klar = false, _drar = false;

  /// The clock for the spin, the done pop and the return (the ticker's own
  /// elapsed time, so it follows the frame clock).
  late final Ticker _tikk;
  double _t0 = 0, _tF = 0;

  /// Block angles when the spin started (`ax0`/`ay0`).
  double _ax0 = 12, _ay0 = 0;
  double _ax = 18, _ay = -36, _skala = 1, _ring = 0, _ringSkala = 1, _glans = 0;

  /// The puck's pop when the pull arms (`scale 1 → 1.14 → .97 → 1`, 360ms).
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  /// The return: content 62 → 0 (420ms, cubic(.25,1.25,.4,1)), puck away
  /// (300ms, cubic(.5,0,.75,0)).
  late final AnimationController _retur = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  double _returFra = 0, _puckFraY = 0, _puckFraS = 1, _puckFraOp = 1;

  bool _refreshFerdig = true;
  // Onboarding Step 2: no pull while Ægil-runden is up (the design's `ldrDraKan`).
  bool get _kan => widget.aktiv && !OnbRunde.instance.aktiv && OnbTips.instance.naa == null && !MediaQuery.disableAnimationsOf(context) && !BergenPerf.calmOf(context);

  @override
  void initState() {
    super.initState();
    _tikk = createTicker(_onTikk);
    BergenDraLaster.demo.addListener(_onDemo);
  }

  /// `ldrDemo`: the finger's travel eases to 175 over 620ms, 140ms later it
  /// lets go.
  bool _demoHold = false;
  void _onDemo() {
    final d = BergenDraLaster.demo.value;
    if (d == null || !mounted || !_kan || _fase != _Fase.av) return;
    _demoHold = d == 'hold';
    _start();
    final sw = Stopwatch()..start();
    late final Ticker t;
    t = createTicker((_) {
      if (!mounted || _fase != _Fase.ned) {
        t.dispose();
        return;
      }
      final p = math.min(1.0, sw.elapsedMilliseconds / 620);
      _d = 175 * (1 - math.pow(1 - p, 3).toDouble());
      _tegn();
      if (p >= 1) {
        t.dispose();
        Future.delayed(const Duration(milliseconds: 140), () {
          if (mounted && _fase == _Fase.ned) _slipp();
        });
      }
    });
    t.start();
  }

  @override
  void dispose() {
    BergenDraLaster.demo.removeListener(_onDemo);
    _tikk.dispose();
    _pop.dispose();
    _retur.dispose();
    super.dispose();
  }

  // ── The pull ────────────────────────────────────────────────────────────

  bool _onNotification(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (_fase != _Fase.av && _fase != _Fase.ned) return false;
    if (n is OverscrollNotification) {
      if (!_kan) return false;
      if (n.dragDetails == null) return false;
      if (n.overscroll < 0 && n.metrics.pixels <= n.metrics.minScrollExtent) {
        _start();
        _d = math.max(0, _d - n.overscroll);
        _tegn();
      } else if (n.overscroll > 0 && _fase == _Fase.ned) {
        _d = math.max(0, _d - n.overscroll);
        _tegn();
      }
      return false;
    }
    if (n is ScrollUpdateNotification) {
      final px = n.metrics.pixels;
      if (px < n.metrics.minScrollExtent && n.dragDetails != null && _kan) {
        // Plain bouncing physics: the physics moves the content, we draw.
        _start();
        _over = n.metrics.minScrollExtent - px;
        _tegn();
      } else if (_fase == _Fase.ned && (n.dragDetails == null || px >= n.metrics.minScrollExtent) && _over > 0) {
        _over = math.max(0, n.metrics.minScrollExtent - px);
        if (n.dragDetails == null) {
          _slipp();
        } else {
          _tegn();
        }
      } else if (_fase == _Fase.ned && _d > 0 && n.dragDetails != null && px > n.metrics.minScrollExtent) {
        // The finger went back up past the top: the pull is over.
        _d = 0;
        _tegn();
      }
      return false;
    }
    if (n is ScrollEndNotification && _fase == _Fase.ned) _slipp();
    if (n is UserScrollNotification && n.direction == ScrollDirection.idle && _fase == _Fase.ned && _drar) _slipp();
    return false;
  }

  void _start() {
    if (_fase == _Fase.ned) return;
    _retur.stop();
    _fase = _Fase.ned;
    _drar = true;
    _d = 0;
    _over = 0;
    _klar = false;
    _ax0 = 12;
    _ay0 = 0;
  }

  /// `ldrTegn`.
  void _tegn() {
    final y = _over > 0 ? _over : 150 * (1 - math.exp(-_d / 200));
    final p = math.min(1.0, y / _g), over = math.max(0.0, y - _g);
    final klar = y >= _g;
    if (klar != _klar) {
      _klar = klar;
      if (klar) {
        _pop.forward(from: 0);
        HapticFeedback.lightImpact();
      }
    }
    setState(() {
      _y = y;
      _ax = 18 * (1 - p) - math.min(over, 40) * .25;
      _ay = -36 * (1 - p) + math.min(over, 40) * .5;
      _ring = p * .999;
    });
    widget.onY?.call(_visY);
  }

  /// `ldrSlipp`.
  void _slipp() {
    if (_fase != _Fase.ned) return;
    _drar = false;
    if (_y >= _g) {
      _oppdater();
    } else {
      _tilbake();
    }
  }

  // ── Oppdaterer … → Oppdatert → back ─────────────────────────────────────

  void _oppdater() {
    _fase = _Fase.oppdater;
    _ax0 = _ax;
    _ay0 = _ay;
    _t0 = 0;
    _refreshFerdig = widget.onRefresh == null && !_demoHold;
    if (_tikk.isActive) _tikk.stop();
    _tikk.start();
    widget.onRefresh?.call().catchError((Object _) {}).whenComplete(() {
      if (!_demoHold) _refreshFerdig = true;
    });
    setState(() {});
  }

  double _io(double x) => x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
  double _l(double a, double b, double u) => a + (b - a) * u;
  double _kl(double x) => x.clamp(0.0, 1.0);

  /// `ldrLoop`: the wobble and the spinning ring while updating; the pop,
  /// the ring's swell and the sheen when done.
  void _onTikk(Duration e) {
    final n = e.inMicroseconds / 1000;
    if (_fase == _Fase.oppdater) {
      final ms = n - _t0;
      const k = [
        [0.0, 0.0, 0.0],
        [200.0, 12.0, 0.0],
        [550.0, 6.0, -32.0],
        [1250.0, 16.0, 32.0],
        [1600.0, 12.0, 0.0],
      ];
      final loop = ms % 1600, first = ms < 1600;
      var i = 1;
      while (i < k.length - 1 && loop > k[i][0]) {
        i++;
      }
      final p = k[i - 1], q = k[i], u = _io(_kl((loop - p[0]) / (q[0] - p[0])));
      final ax = _l(i == 1 && first ? _ax0 : (i == 1 ? 12 : p[1]), q[1], u);
      final ay = _l(i == 1 && first ? _ay0 : (i == 1 ? 0 : p[2]), q[2], u);
      setState(() {
        _ax = ax;
        _ay = ay;
        _ring = (ms / 720 * 360) % 360;
      });
      // A hanging reload never holds the puck past 15s (the demo's «hold»
      // does, on purpose).
      if (ms >= 1600 && (_refreshFerdig || (ms >= 15000 && !_demoHold))) _ferdig(n);
      return;
    }
    if (_fase == _Fase.ferdig) {
      final ms = n - _tF, u = _kl(ms / 560), opp = _io(_kl(u / .4)), ned = _io(_kl((u - .4) / .6));
      final r = _kl(ms / 460), ro = _io(_kl(r / .35)), rn = _io(_kl((r - .35) / .65));
      setState(() {
        _ax = _l(_l(12, -12, opp), 0, ned);
        _ay = _l(_l(0, -14, opp), 0, ned);
        _skala = _l(_l(1, 1.18, opp), 1, ned);
        _ringSkala = _l(_l(1, 1.16, ro), 1, rn);
        _glans = 230 * _io(_kl((ms - 250) / 450));
        if (ms > 760) {
          _ax = 0;
          _ay = 0;
          _skala = 1;
          _ringSkala = 1;
        }
      });
      if (ms >= 950) _tilbake();
    }
  }

  void _ferdig(double n) {
    _fase = _Fase.ferdig;
    _tF = n;
    setState(() {});
  }

  /// `ldrTilbake`.
  void _tilbake() {
    final fra = _fase;
    _fase = _Fase.tilbake;
    if (_tikk.isActive) _tikk.stop();
    _returFra = _visY;
    _puckFraY = _puckY(_returFra);
    _puckFraS = _puckSkala;
    _puckFraOp = _puckOp;
    _glans = 0;
    _ringSkala = 1;
    _retur.duration = Duration(milliseconds: fra == _Fase.ned && _over > 0 ? 300 : 420);
    _retur.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _fase = _Fase.av;
        _d = 0;
        _over = 0;
        _y = 0;
        _ax = 18;
        _ay = -36;
        _skala = 1;
      });
      widget.onY?.call(0);
    });
    setState(() {});
  }

  // ── Geometry ────────────────────────────────────────────────────────────

  /// The content's displacement: the pull, or the 62px hold.
  double get _visY => switch (_fase) {
    _Fase.ned => _over > 0 ? 0 : _y,
    _Fase.oppdater || _Fase.ferdig => math.max(0, _h - _over),
    _Fase.tilbake => _over > 0 ? 0 : _returFra * (1 - const Cubic(.25, 1.25, .4, 1).transform(_retur.value)),
    _Fase.av => 0,
  };

  /// Where the puck sits for displacement [y] (`top0 − 20 + y·.62`).
  double _puckY(double y) => widget.topp - 20 + y * .62;
  double get _puckSkala => switch (_fase) {
    _Fase.ned => .45 + .55 * math.min(1, _y / _g),
    _Fase.oppdater || _Fase.ferdig => 1,
    _ => 1,
  };
  double get _puckOp => switch (_fase) {
    _Fase.ned => math.min(1, math.min(1, _y / _g) * 1.8),
    _Fase.oppdater || _Fase.ferdig => 1,
    _ => 1,
  };

  String get _tekst => switch (_fase) {
    _Fase.oppdater => 'Oppdaterer …',
    _Fase.ferdig => 'Oppdatert',
    _ => _klar ? 'Slipp for å oppdatere' : 'Dra for å oppdatere',
  };

  @override
  Widget build(BuildContext context) {
    final vis = _fase != _Fase.av;
    // The same tree shape whether or not a pull is on: a new wrapper would
    // rebuild the scrollable and drop the drag that started the pull.
    final innhold = AnimatedBuilder(
      animation: _retur,
      builder: (context, child) => Transform.translate(offset: Offset(0, widget.flyttInnhold && vis ? _visY : 0), child: child),
      child: widget.child,
    );
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: innhold),
          if (vis)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_retur, _pop]),
                  builder: (context, _) {
                    double top, skala, op;
                    if (_fase == _Fase.tilbake) {
                      final e = const Cubic(.5, 0, .75, 0).transform(_kl(_retur.value * 420 / 300));
                      top = _l(_puckFraY, widget.topp - 80, e);
                      skala = _l(_puckFraS, .4, e);
                      op = _l(_puckFraOp, 0, e);
                    } else {
                      final y = _fase == _Fase.ned ? (_over > 0 ? _over : _y) : _h;
                      top = _puckY(y);
                      skala = _puckSkala;
                      op = _puckOp;
                    }
                    final pp = const Cubic(0, 0, .58, 1).transform(_pop.value);
                    final pops = _pop.isAnimating ? kf(pp, const [0, .35, .7, 1], const [1, 1.14, .97, 1]) : 1.0;
                    return Transform.translate(
                      offset: Offset(0, top),
                      child: Opacity(
                        opacity: op.clamp(0, 1),
                        child: Transform.scale(
                          scale: skala,
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: [
                              Transform.scale(scale: pops, child: _puck(context)),
                              const SizedBox(height: 10),
                              Opacity(
                                opacity: _fase == _Fase.ned ? _kl((math.min(1, _y / _g) - .35) * 2.4) : 1,
                                child: _pill(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// `data-lsd-puck`: the 68px dark glass disc, the ring and the block.
  Widget _puck(BuildContext context) {
    final spinn = _fase == _Fase.oppdater;
    final ferdig = _fase == _Fase.ferdig;
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CssBox(
              radius: BorderRadius.circular(34),
              bg: const [
                CssRadial([Color.fromRGBO(255, 255, 255, .34), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .55], rx: 1.2, ry: .9, cx: .3, cy: .16),
                CssLinear(180, [Color.fromRGBO(42, 98, 114, .84), Color.fromRGBO(20, 56, 66, .92)]),
              ],
              shadows: const [
                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                CssShadow.inset(0, -6, 12, 0, Color.fromRGBO(4, 20, 28, .45)),
                CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .16)),
                CssShadow(0, 16, 28, -10, Color.fromRGBO(3, 16, 24, .75)),
              ],
            ),
          ),
          Positioned.fill(
            child: Transform.rotate(
              angle: spinn ? _ring * math.pi / 180 : 0,
              child: Transform.scale(
                scale: ferdig ? _ringSkala : 1,
                child: CustomPaint(
                  painter: _RingPainter(
                    farge: _klar || spinn || ferdig ? _mint : _oransje,
                    del: spinn ? .26 : (ferdig ? 1 : (_fase == _Fase.ned ? _ring : 1)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 11,
            top: 17.5,
            child: Merke3D(width: 46, height: 37, lag: kMerkeLagPuck, perspektiv: 220, rx: _ax, ry: _ay, skala: _skala, glansX: _glans, glansZ: .4),
          ),
        ],
      ),
    );
  }

  /// `data-lsd-tekst`.
  Widget _pill() => CssBox(
    radius: BorderRadius.circular(999),
    bg: const [CssSolid(Color.fromRGBO(12, 34, 42, .8))],
    shadows: const [
      CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .18)),
      CssShadow(0, 8, 18, -8, Color.fromRGBO(3, 16, 24, .6)),
    ],
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Text(_tekst, key: const Key('dra_laster_tekst'), style: jakarta(12, color: Colors.white)),
  );
}

/// `data-lsd-ring`: the track (white .14, 3px) and the arc (3px, round
/// caps, from the top) covering [del] of the circle.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.farge, required this.del});

  final Color farge;
  final double del;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 30.5;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color.fromRGBO(255, 255, 255, .14),
    );
    if (del <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * del.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = farge,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.farge != farge || old.del != del;
}
