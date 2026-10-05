import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;

// ── Kategorirad · the 3D wheel (`katHjul`, prototype L2783–2806) ────────────
// The categories stand on a ring (r 116) tilted 68° back in a 760px
// perspective; the focused one is at the front, scaled 1.4 with an orange
// ring. Drag sideways to spin, tap an orb to bring it forward, tap the
// focused one to open it. In launch mode every category but restaurants is
// "Kommer snart": a dashed gold ring and a clock badge, and the name row
// shows the "Kommer snart · Varsle meg" chip.

class HjemHjulKat {
  const HjemHjulKat({required this.navn, required this.live, required this.ikon, required this.snart, this.varsles = false});

  final String navn;
  final String live;

  /// 0 restaurant, 1 mat & fisk, 2 mote, 3 interiør, 4 gaver.
  final int ikon;
  final bool snart;

  /// "Varsle meg" already tapped (bell badge, mint chip).
  final bool varsles;
}

/// `STI` and `SIDE` per icon.
const List<String> _kSti = [
  'M3 17h18M5 17a7 7 0 0 1 14 0M12 8V6M10 6h4M2 20h20',
  'M3 12c3-5 9-6 13-3l4-3v12l-4-3c-4 3-10 2-13-3zM8 11.5h.01',
  'M8 4L3 7l2 4 3-1v10h8V10l3 1 2-4-5-3c-.5 1.5-2 2.5-4 2.5S8.5 5.5 8 4z',
  'M5 10V8a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v2M3 12a2 2 0 0 1 4 0v2h10v-2a2 2 0 0 1 4 0v5H3zM5 17v2M19 17v2',
  'M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7C10.5 4 7 4 7 6s3 1 5 1zM12 7c1.5-3 5-3 5-1s-3 1-5 1z',
];
const List<String> _kSide = ['#8F3414', '#0F4A5A', '#4A2E6E', '#5E4428', '#7A5408'];

/// Which of the prototype's five wheel slots an API category fills.
int hjemHjulIkon(String name) {
  final n = name.toLowerCase();
  if (n.contains('restaur') || n.contains('takeaway') || n.contains('kafe')) return 0;
  if (n.contains('fisk') || n.contains('dagligvare') || n.contains('mat')) return 1;
  if (n.contains('mote') || n.contains('klær') || n.contains('sport')) return 2;
  if (n.contains('interi') || n.contains('kunst') || n.contains('hjem') || n.contains('møbel')) return 3;
  if (n.contains('gave') || n.contains('souvenir') || n.contains('blomst')) return 4;
  return 3;
}

class HjemKategoriHjul extends StatefulWidget {
  const HjemKategoriHjul({super.key, required this.kategorier, required this.index, required this.onIndex, required this.onOpen, required this.onSnart});

  final List<HjemHjulKat> kategorier;
  final int index;
  final ValueChanged<int> onIndex;

  /// The focused category was tapped (open it).
  final ValueChanged<int> onOpen;

  /// "Kommer snart · Varsle meg" (or a tap on a coming-soon orb).
  final ValueChanged<int> onSnart;

  @override
  State<HjemKategoriHjul> createState() => _HjemKategoriHjulState();
}

class _HjemKategoriHjulState extends State<HjemKategoriHjul> with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  /// One tap animation at a time: the lift (480ms) on a side orb, or the
  /// jump (600ms) plus the splash (from 440ms) on the focused one.
  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150));
  int _hopK = -1;
  bool _hopJump = false;
  Offset _plaskAt = Offset.zero;
  List<(double, double, double)> _drops = const [];

  /// `transition: transform .6s` on each orb's scale when the focus moves.
  late final AnimationController _skC = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..value = 1;
  List<double> _skFra = const [];
  final Map<int, double> _skNaa = {};

  double _from = 0, _to = 0;
  double _dx = 0, _kdx = 0, _v = 0;
  bool _aktiv = false, _drar = false, _flyttet = false;
  Offset _p0 = Offset.zero;
  Duration _kt = Duration.zero;
  final Stopwatch _klokke = Stopwatch()..start();

  static const Cubic _ease = Cubic(.3, 1.15, .4, 1);
  static const Cubic _skEase = Cubic(.34, 1.56, .64, 1);

  int get _n => math.max(1, widget.kategorier.length);
  double get _step => 360 / _n;

  @override
  void initState() {
    super.initState();
    _from = _to = -widget.index * _step;
    _spin.value = 1;
  }

  @override
  void didUpdateWidget(HjemKategoriHjul old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index || old.kategorier.length != widget.kategorier.length) {
      _skFra = [for (var k = 0; k < widget.kategorier.length; k++) _skNaa[k] ?? 1];
      if (MediaQuery.disableAnimationsOf(context)) {
        _skC.value = 1;
      } else {
        _skC.forward(from: 0);
      }
      _glid();
    }
  }

  /// Slides the wheel from where it is now to the focused category, the
  /// shortest way round.
  void _glid() {
    final mal = -widget.index * _step;
    final fo = _vk;
    final df = ((((mal - fo) % 360) + 540) % 360) - 180;
    _from = fo;
    _to = fo + df;
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.value = 1;
    } else {
      _spin.forward(from: 0);
    }
  }

  double get _vk => _from + (_to - _from) * _ease.transform(_spin.value);

  @override
  void dispose() {
    _spin.dispose();
    _hop.dispose();
    _skC.dispose();
    super.dispose();
  }

  int _mod(int a) => ((a % _n) + _n) % _n;

  void _bytt(int d) {
    HapticFeedback.selectionClick();
    widget.onIndex(_mod(widget.index + d));
  }

  // katNed / katFlytt / katSlipp
  void _ned(PointerDownEvent e) {
    _p0 = e.localPosition;
    _aktiv = true;
    _flyttet = false;
    _v = 0;
    _kdx = 0;
    _kt = _klokke.elapsed;
  }

  void _flytt(PointerMoveEvent e) {
    if (!_aktiv) return;
    final dx = e.localPosition.dx - _p0.dx, dy = e.localPosition.dy - _p0.dy;
    if (!_drar) {
      if (dy.abs() > 12 && dy.abs() > dx.abs()) {
        _aktiv = false;
        return;
      }
      if (dx.abs() < 9) return;
      _flyttet = true;
      // Freeze the wheel where it is; the finger takes over.
      _from = _to = _vk;
      _spin.value = 1;
      _drar = true;
    }
    final nt = _klokke.elapsed;
    final dt = math.max(1.0, (nt - _kt).inMicroseconds / 1000);
    _v = _v * .6 + ((dx - _kdx) / dt) * .4;
    _kt = nt;
    _kdx = dx;
    const lim = 160.0;
    setState(() => _dx = dx.abs() < lim ? dx : dx.sign * (lim + (dx.abs() - lim) * .3));
  }

  void _slipp() {
    _aktiv = false;
    if (!_drar) return;
    final dx = _dx;
    var steg = -((dx + _v * 120) / 74).round();
    steg = steg.clamp(-2, 2);
    if (steg == 0 && dx.abs() > 26) steg = dx < 0 ? 1 : -1;
    // The arc glides on from where the finger let go.
    _from = _to = _vk + dx * .97;
    _drar = false;
    _v = 0;
    setState(() => _dx = 0);
    if (steg != 0) {
      HapticFeedback.selectionClick();
      widget.onIndex(_mod(widget.index + steg));
    } else {
      _glid();
    }
    Future.delayed(const Duration(milliseconds: 80), () => _flyttet = false);
  }

  /// `katTrykk`.
  void _trykk(int k, Matrix4 flat) {
    if (_flyttet || (_hopJump && _hop.isAnimating)) return;
    final kat = widget.kategorier[k];
    final akt = k == widget.index;
    void gjor() => akt ? (kat.snart ? widget.onSnart(k) : widget.onOpen(k)) : widget.onIndex(k);
    HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) {
      gjor();
      return;
    }
    if (!akt) {
      gjor();
      _hopK = k;
      _hopJump = false;
      _hop.duration = const Duration(milliseconds: 480);
      _hop.forward(from: 0);
      return;
    }
    // The orb's on-screen box: splash at its bottom centre, 6px up.
    final pts = [
      for (final p in const [Offset(0, 0), Offset(60, 0), Offset(0, 60), Offset(60, 60)]) MatrixUtils.transformPoint(flat, p),
    ];
    final xs = pts.map((p) => p.dx), ys = pts.map((p) => p.dy);
    _plaskAt = Offset((xs.reduce(math.min) + xs.reduce(math.max)) / 2, ys.reduce(math.max) - 6);
    final r = math.Random();
    _drops = [for (var j = 0; j < 6; j++) (math.pi + (j / 5) * math.pi, 5 + r.nextDouble() * 4, 26 + r.nextDouble() * 18)];
    _hopK = k;
    _hopJump = true;
    _hop.duration = const Duration(milliseconds: 1150);
    _hop.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 520), () {
      if (mounted) gjor();
    });
  }

  /// The tap animation added on top of orb [k]'s own transform.
  Matrix4? _hopM(int k) {
    if (k != _hopK || !_hop.isAnimating) return null;
    final ms = _hop.value * _hop.duration!.inMilliseconds;
    if (!_hopJump) {
      final p = const Cubic(.3, .9, .3, 1).transform((ms / 480).clamp(0.0, 1.0));
      return Matrix4.translationValues(0, kf(p, const [0, .35, 1], const [0, -8, 0]), 0);
    }
    final p = (ms / 600).clamp(0.0, 1.0);
    if (p >= 1) return null;
    const st = [0.0, .12, .5, .84, 1.0];
    const curves = [Cubic(.3, 0, .5, 1), Cubic(.2, .7, .3, 1), Cubic(.5, 0, .7, .4), Cubic(.3, .7, .3, 1)];
    var s = 0;
    while (s < 3 && p > st[s + 1]) {
      s++;
    }
    final e = curves[s].transform(((p - st[s]) / (st[s + 1] - st[s])).clamp(0.0, 1.0));
    double lerp(List<double> v) => v[s] + (v[s + 1] - v[s]) * e;
    final ty = lerp(const [0, 3, -30, 2, 0]);
    final ry = lerp(const [0, 0, 180, 360, 360]);
    final sx = lerp(const [1, 1.08, .98, 1.06, 1]);
    final sy = lerp(const [1, .92, 1.04, .95, 1]);
    return Matrix4.identity()
      ..setEntry(3, 2, -1 / 500)
      ..translateByDouble(0, ty, 0, 1)
      ..rotateY(rad(ry))
      ..scaleByDouble(sx, sy, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final kat = widget.kategorier;
    final i = math.min(math.max(0, widget.index), math.max(0, kat.length - 1));
    final aktiv = kat.isEmpty ? null : kat[i];
    return Listener(
      onPointerDown: _ned,
      onPointerMove: _flytt,
      onPointerUp: (_) => _slipp(),
      onPointerCancel: (_) => _slipp(),
      child: RawGestureDetector(
        // Claims the horizontal drag so the sheet doesn't scroll sideways
        // gestures; vertical ones still scroll the sheet.
        gestures: {HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(HorizontalDragGestureRecognizer.new, (r) => r.onUpdate = (_) {})},
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: 224,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 178,
                child: RepaintBoundary(
                  child: AnimatedBuilder(animation: Listenable.merge([_spin, _hop, _skC]), builder: (context, _) => _ring(kat, i)),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(animation: _hop, builder: (context, _) => _plask()),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 172,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pil(true),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 132),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            aktiv?.navn ?? '',
                            style: jakarta(
                              16,
                              em: -.01,
                              shadows: const [Shadow(color: Color.fromRGBO(6, 22, 30, .6), blurRadius: 6, offset: Offset(0, 1))],
                            ),
                          ),
                          if (aktiv != null && !aktiv.snart)
                            Text(
                              aktiv.live,
                              style: inter(11, weight: FontWeight.w700, color: const Color(0xFF9FE0C8)).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          if (aktiv != null && aktiv.snart)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _SnartChip(varsles: aktiv.varsles, onTap: () => widget.onSnart(i)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _pil(false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The landing splash: two rings and six drops (from 440ms).
  Widget _plask() {
    if (!_hopJump || !_hop.isAnimating) return const SizedBox.shrink();
    final ms = _hop.value * 1150 - 440;
    if (ms < 0) return const SizedBox.shrink();
    final c = _plaskAt;
    final barn = <Widget>[];
    for (var r = 0; r < 2; r++) {
      final p = ((ms - r * 90) / 620).clamp(0.0, 1.0);
      if (ms - r * 90 < 0 || p >= 1) continue;
      final e = const Cubic(.1, .7, .2, 1).transform(p);
      final sk = .3 + ((r == 1 ? 2.4 : 1.9) - .3) * e;
      barn.add(
        Positioned(
          left: c.dx - 40,
          top: c.dy - 10,
          width: 80,
          height: 20,
          child: Opacity(
            opacity: (1 - e).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: sk,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.elliptical(40, 10)),
                  border: Border.all(width: 2, color: r == 1 ? const Color.fromRGBO(255, 255, 255, .7) : const Color.fromRGBO(92, 224, 184, .95)),
                  boxShadow: r == 1 ? null : [BoxShadow(color: const Color.fromRGBO(92, 224, 184, .6), blurRadius: cssSigma(14) * 2)],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final pd = (ms / 520).clamp(0.0, 1.0);
    if (pd < 1) {
      final e = const Cubic(.2, .7, .3, 1).transform(pd);
      for (var j = 0; j < _drops.length; j++) {
        final (ang, sz, dist) = _drops[j];
        final x = kf(e, const [0, .45, 1], [0, math.cos(ang) * dist * .6, math.cos(ang) * dist]);
        final y = kf(e, const [0, .45, 1], [0, math.sin(ang) * dist - 10, math.sin(ang) * dist * .3 + 8]);
        final s = kf(e, const [0, .45, 1], const [.4, 1, .3]);
        final o = kf(e, const [0, .45, 1], const [0, 1, 0]);
        barn.add(
          Positioned(
            left: c.dx - sz / 2 + x,
            top: c.dy - sz / 2 + y,
            width: sz,
            height: sz,
            child: Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: s,
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: j.isOdd ? const Color(0xFF7FF0CB) : const Color.fromRGBO(214, 242, 250, .95)),
                ),
              ),
            ),
          ),
        );
      }
    }
    return Stack(clipBehavior: Clip.none, children: barn);
  }

  Widget _pil(bool forrige) => LfPress(
    onTap: () => _bytt(forrige ? -1 : 1),
    child: CssBox(
      width: 38,
      height: 38,
      radius: BorderRadius.circular(999),
      bg: const [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .24), Color.fromRGBO(255, 255, 255, .08)]),
      ],
      shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .38)), CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(0, 0, 0, .2)), CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 0, 0, .6))],
      child: Center(
        child: SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="${forrige ? 'M15 6l-6 6 6 6' : 'M9 6l6 6-6 6'}"/></svg>',
          width: 13,
          height: 13,
        ),
      ),
    ),
  );

  /// The tilted ring and the orbs, sorted back to front.
  Widget _ring(List<HjemHjulKat> kat, int i) {
    final vk = _vk + _dx * .97;
    // perspective-origin 50% 0% of the 390×178 box; the ring centre at (195, 92).
    Matrix4 base() => Matrix4.identity()
      ..translateByDouble(195, 0, 0, 1)
      ..multiply(Matrix4.identity()..setEntry(3, 2, -1 / 760))
      ..translateByDouble(-195, 0, 0, 1)
      ..translateByDouble(195, 92, 0, 1)
      ..rotateX(rad(68));

    final orbs = <(double, Widget)>[];
    final skT = _skEase.transform(_skC.value);
    for (var k = 0; k < kat.length; k++) {
      final v = k * _step;
      final c = math.cos(rad((v + vk) % 360));
      final akt = k == i;
      final mal = akt ? 1.4 : .8 + .12 * (c + 1) / 2;
      final fra = k < _skFra.length ? _skFra[k] : mal;
      final sk = fra + (mal - fra) * skT;
      _skNaa[k] = sk;
      final op = .35 + .65 * (c + 1) / 2;
      // The orb's own box lies flat on the ring: rotateZ(v) translateY(116)
      // rotateZ(-(v+vk)).
      final flat = base()
        ..rotateZ(rad(vk))
        ..rotateZ(rad(v))
        ..translateByDouble(0, 116, 0, 1)
        ..rotateZ(rad(-(v + vk)));
      // Then it stands up: translateY(-30) rotateX(-68) scale(sk) about its
      // bottom centre (0, 30), plus the tap animation added on top.
      final m = flat.clone()
        ..translateByDouble(0, 30, 0, 1)
        ..translateByDouble(0, -30, 0, 1)
        ..rotateX(rad(-68))
        ..scaleByDouble(sk, sk, 1, 1);
      final hop = _hopM(k);
      if (hop != null) m.multiply(hop);
      m
        ..translateByDouble(0, -30, 0, 1)
        ..translateByDouble(-30, -30, 0, 1);
      final flatBox = flat..translateByDouble(-30, -30, 0, 1);
      orbs.add((
        c,
        Positioned(
          left: 0,
          top: 0,
          child: Transform(
            transform: m,
            child: AnimatedOpacity(
              opacity: op.clamp(0.0, 1.0),
              curve: cssEase,
              duration: const Duration(milliseconds: 500),
              child: GestureDetector(
                onTap: () => _trykk(k, flatBox),
                child: _Orb(kat: kat[k], aktiv: akt, delay: k * 900.0),
              ),
            ),
          ),
        ),
      ));
    }
    orbs.sort((a, b) => a.$1.compareTo(b.$1));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The ring on the floor (r 128) and its ripple (r 150, `skvulp`).
        Positioned(
          left: 0,
          top: 0,
          child: Transform(
            transform: base()..translateByDouble(-128, -128, 0, 1),
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, .24), width: 1.5),
                gradient: const RadialGradient(colors: [Color(0x00A0E6DC), Color(0x00A0E6DC), Color(0x1FA0E6DC)], stops: [0, .8, 1]),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Transform(
            transform: base()..translateByDouble(-150, -150, 0, 1),
            child: LfLoop(
              builder: (context, t, child) {
                final p = (t / 3200) % 1.0;
                final e = cssEaseOut.transform(p);
                return Opacity(
                  opacity: (.8 * (1 - e)).clamp(0.0, 1.0),
                  child: Transform.scale(scale: .55 + .95 * e, child: child),
                );
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
                ),
              ),
            ),
          ),
        ),
        for (final o in orbs) o.$2,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.kat, required this.aktiv, required this.delay});

  final HjemHjulKat kat;
  final bool aktiv;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final ring = aktiv ? (kat.snart ? const Color(0xFFF2C14E) : const Color(0xFFF26D3D)) : const Color(0x00FFFFFF);
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            // `transition: box-shadow .4s ease` on the focus ring.
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: ring),
              duration: const Duration(milliseconds: 400),
              curve: cssEase,
              builder: (context, rc, _) => CssBox(
                radius: BorderRadius.circular(30),
                bg: const [
                  CssLinear(180, [Color.fromRGBO(255, 255, 255, .3), Color.fromRGBO(255, 255, 255, .08)]),
                ],
                shadows: [
                  const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .55)),
                  const CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .2)),
                  if ((rc ?? ring).a > 0) CssShadow(0, 0, 0, 3, rc ?? ring),
                  const CssShadow(0, 16, 22, -10, Color.fromRGBO(0, 10, 14, .75)),
                ],
              ),
            ),
          ),
          // The extruded icon, swaying (`hjulIkon`).
          Positioned(
            left: 13,
            top: 13,
            child: HjemKatIkon(ikon: kat.ikon, size: 34, dybde: .9, perspektiv: 760, delayMs: delay),
          ),
          if (kat.snart) ...[
            Positioned(
              left: -5,
              top: -5,
              right: -5,
              bottom: -5,
              child: IgnorePointer(
                child: LfLoop(
                  builder: (context, t, child) => Transform.rotate(angle: (t / 16000) * 2 * math.pi, child: child),
                  child: const CustomPaint(painter: HjemDashRing()),
                ),
              ),
            ),
            Positioned(
              right: -7,
              top: -6,
              width: 22,
              height: 22,
              child: IgnorePointer(
                child: CssBox(
                  radius: BorderRadius.circular(11),
                  bg: [
                    kat.varsles ? const CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF3CC79F)]) : const CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)]),
                  ],
                  shadows: [
                    const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .65)),
                    const CssShadow(0, 0, 0, 2, Color.fromRGBO(20, 60, 70, .9)),
                    CssShadow(0, 2, 0, 2, kat.varsles ? const Color(0xFF23946F) : const Color(0xFFA87418)),
                    const CssShadow(0, 6, 8, 0, Color.fromRGBO(0, 0, 0, .4)),
                  ],
                  child: Center(
                    child: SvgPicture.string(
                      kat.varsles
                          ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#0F3A40" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/></svg>'
                          : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#5A3C10" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></svg>',
                      width: 12,
                      height: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The category icon extruded in 3D: nine layers in the side colour
/// stepping back [dybde]px each, the white face on top, swaying with
/// `hjulIkon` (4.5s).
class HjemKatIkon extends StatelessWidget {
  const HjemKatIkon({super.key, required this.ikon, required this.size, required this.dybde, required this.perspektiv, this.delayMs = 0});

  final int ikon;
  final double size, dybde, perspektiv, delayMs;

  @override
  Widget build(BuildContext context) {
    String layer(String stroke) =>
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="${_kSti[ikon]}" fill="none" stroke="$stroke" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    final side = SvgPicture.string(layer(_kSide[ikon]), width: size, height: size);
    final top = SvgPicture.string(layer('#FFFFFF'), width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: LfLoop(
        builder: (context, t, _) {
          final p = (((t + delayMs) / 4500) % 1.0);
          final ry = kf(p, const [0, .5, 1], const [-24, 24, -24], cssEaseInOut);
          final rx = kf(p, const [0, .5, 1], const [6, -4, 6], cssEaseInOut);
          Matrix4 m(double z) => Matrix4.identity()
            ..setEntry(3, 2, -1 / perspektiv)
            ..rotateY(rad(ry))
            ..rotateX(rad(rx))
            ..translateByDouble(0, 0, z, 1);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var l = 8; l >= 0; l--) Transform(alignment: Alignment.center, transform: m(-dybde * l), child: side),
              Transform(alignment: Alignment.center, transform: m(0), child: top),
            ],
          );
        },
      ),
    );
  }
}

/// `border: 1.5px dashed rgba(255,231,168,.6)` on a circle.
class HjemDashRing extends CustomPainter {
  const HjemDashRing({this.width = 1.5, this.color = const Color.fromRGBO(255, 231, 168, .6), this.dash = 3.75});

  final double width, dash;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    final r = size.width / 2 - width / 2, c = size.center(Offset.zero);
    final n = (2 * math.pi * r / (dash * 2)).floor();
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, math.pi / n, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "Kommer snart · Varsle meg" / "Du får beskjed".
class _SnartChip extends StatelessWidget {
  const _SnartChip({required this.varsles, required this.onTap});

  final bool varsles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LfPress(
      dy: 2,
      onTap: onTap,
      child: CssBox(
        height: 26,
        radius: BorderRadius.circular(999),
        bg: [
          varsles ? const CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF3CC79F)]) : const CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)]),
        ],
        shadows: [
          const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .65)),
          const CssShadow.inset(0, -1.5, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
          CssShadow(0, 2.5, 0, 0, varsles ? const Color(0xFF23946F) : const Color(0xFFA87418)),
          const CssShadow(0, 8, 12, -5, Color.fromRGBO(3, 16, 24, .7)),
        ],
        padding: const EdgeInsets.fromLTRB(4, 0, 11, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, .15), offset: Offset(0, 1))],
              ),
              alignment: Alignment.center,
              child: varsles
                  ? SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1F8A66" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>',
                      width: 10,
                      height: 10,
                    )
                  : LfLoop(
                      // snartPling: the bell rings every 3.2s.
                      builder: (context, t, child) {
                        final p = (t / 3200) % 1.0;
                        final r = kf(p, const [0, .6, .66, .72, .78, .84, 1], const [0, 0, 16, -14, 9, 0, 0], cssEaseInOut);
                        return Transform.rotate(alignment: const Alignment(0, -.7), angle: rad(r), child: child);
                      },
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#8A5A10" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/></svg>',
                        width: 11,
                        height: 11,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              varsles ? 'Du får beskjed' : 'Kommer snart · Varsle meg',
              style: inter(11, weight: FontWeight.w800, color: varsles ? const Color(0xFF0F3A40) : const Color(0xFF5A3C10)),
            ),
          ],
        ),
      ),
    );
  }
}
