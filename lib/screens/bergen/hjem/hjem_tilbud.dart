import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';

// ── Ærend-tilbud (prototype L3011–3100, `tbVals`) ──────────────────────────
// Paper coupons, one at a time: a cream ticket with the shop, the dish and
// the price, perforated to a coloured stub with the embossed saving. Every
// 11 s the next slides in (the dot fills meanwhile); after the last a copy
// of the first slides in and the row jumps back unseen. Swipe to browse.
// The last coupon is a mystery to reveal.

enum HjemStub { oransje, gull, teal, mint }

class HjemTilbud {
  const HjemTilbud({
    required this.eyebrow,
    required this.navn,
    required this.butikk,
    required this.meta,
    required this.ny,
    required this.gml,
    required this.verdi,
    required this.under,
    required this.stub,
    required this.onTap,
    this.logoUrl,
    this.logoAsset,
    this.fotoUrl,
    this.fotoAsset,
    this.gmlStrek = true,
    this.verdiStr = 28,
  });

  final String eyebrow, navn, butikk, meta, ny, gml, verdi, under;
  final HjemStub stub;
  final VoidCallback onTap;
  final String? logoUrl, logoAsset, fotoUrl, fotoAsset;
  final bool gmlStrek;
  final double verdiStr;
}

class _StubStil {
  const _StubStil(this.bg, this.c, this.verdiC, this.skygge);
  final List<CssBg> bg;
  final Color c, verdiC;
  final List<Shadow> skygge;
}

const _lys = [Shadow(color: Color.fromRGBO(40, 14, 4, .32), offset: Offset(0, 1), blurRadius: 1.5), Shadow(color: Color.fromRGBO(40, 14, 4, .14), blurRadius: 4)];
const _mrk = [Shadow(color: Color.fromRGBO(255, 255, 255, .35), blurRadius: 2)];

const Map<HjemStub, _StubStil> _kStub = {
  HjemStub.oransje: _StubStil(
    [
      CssRadial([Color.fromRGBO(255, 226, 180, .6), Color.fromRGBO(255, 226, 180, 0)], stops: [0, .7], rx: .8, ry: .55, cx: .5, cy: .44),
      CssLinear(165, [Color(0xFFFF9A5E), Color(0xFFF26D3D), Color(0xFFD9531F)], [0, .52, 1]),
    ],
    Colors.white,
    Colors.white,
    _lys,
  ),
  HjemStub.gull: _StubStil([CssLinear(165, [Color(0xFFFFD873), Color(0xFFF2B53A), Color(0xFFD9951C)], [0, .52, 1])], Color(0xFF3A2508), Color(0xFF3A2508), _mrk),
  HjemStub.teal: _StubStil(
    [CssLinear(165, [Color(0xFF3E97AD), Color(0xFF2A7488), Color(0xFF1E5C6C)], [0, .52, 1])],
    Colors.white,
    Colors.white,
    [Shadow(color: Color.fromRGBO(4, 26, 34, .4), offset: Offset(0, 2))],
  ),
  HjemStub.mint: _StubStil([CssLinear(165, [Color(0xFF8AF0D0), Color(0xFF4FD3AA), Color(0xFF2FB893)], [0, .52, 1])], Color(0xFF0B2A26), Color(0xFF0B2A26), _mrk),
};

/// Time left until midnight, "HH:MM:SS" (`tbTid`).
String hjemTilbudTid([DateTime? n]) {
  final now = n ?? DateTime.now();
  final s = math.max(0, DateTime(now.year, now.month, now.day, 23, 59, 59).difference(now).inSeconds);
  String p(int x) => x.toString().padLeft(2, '0');
  return '${p(s ~/ 3600)}:${p((s ~/ 60) % 60)}:${p(s % 60)}';
}

class HjemTilbudRad extends StatefulWidget {
  const HjemTilbudRad({super.key, required this.tilbud, required this.onMysterie});

  final List<HjemTilbud> tilbud;

  /// The revealed mystery coupon's "Til butikken".
  final VoidCallback onMysterie;

  @override
  State<HjemTilbudRad> createState() => _HjemTilbudRadState();
}

class _HjemTilbudRadState extends State<HjemTilbudRad> with TickerProviderStateMixin {
  static const double _w = 358, _gap = 10;
  static const Cubic _ease = Cubic(.65, 0, .35, 1);

  int _i = 0;
  double _dx = 0;
  bool _hold = false, _drar = false;
  double _x0 = 0;
  bool _myst = false;
  DateTime _sist = DateTime.now();
  Timer? _rot, _snapT;

  /// The row's position (in slides) animates over 1.2s.
  late final AnimationController _glid = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..value = 1;
  double _fra = 0, _til = 0;

  /// The focused dot fills over 11s.
  late final AnimationController _prikk = AnimationController(vsync: this, duration: const Duration(seconds: 11));

  int get _n => widget.tilbud.length + 1;

  @override
  void initState() {
    super.initState();
    _prikk.forward();
    _rot = Timer.periodic(const Duration(milliseconds: 400), (_) => _tikk());
  }

  @override
  void dispose() {
    _rot?.cancel();
    _snapT?.cancel();
    _glid.dispose();
    _prikk.dispose();
    super.dispose();
  }

  double get _pos => _fra + (_til - _fra) * _ease.transform(_glid.value);

  void _gaaTil(int i, {bool snap = false}) {
    final from = _pos;
    setState(() => _i = i);
    _fra = snap ? i.toDouble() : from;
    _til = i.toDouble();
    if (snap || MediaQuery.disableAnimationsOf(context)) {
      _glid.value = 1;
    } else {
      _glid.forward(from: 0);
    }
    _prikk.forward(from: 0);
  }

  void _tikk() {
    if (!mounted || _hold || !TickerMode.of(context)) return;
    if (DateTime.now().difference(_sist).inMilliseconds < 11000) return;
    _sist = DateTime.now();
    final n = _n;
    final ny = math.min(n, _i + 1);
    _gaaTil(ny);
    if (ny == n) {
      _snapT?.cancel();
      _snapT = Timer(const Duration(milliseconds: 1250), () {
        if (mounted) _gaaTil(0, snap: true);
      });
    }
  }

  void _ned(PointerDownEvent e) {
    _x0 = e.position.dx;
    _drar = false;
    _hold = true;
    _prikk.stop();
  }

  void _flytt(PointerMoveEvent e) {
    if (!_hold) return;
    final d = (e.position.dx - _x0) / (MediaQuery.sizeOf(context).width / 390);
    if (d.abs() > 6) _drar = true;
    if (_drar) setState(() => _dx = d);
  }

  void _slipp() {
    if (!_hold) return;
    _hold = false;
    _snapT?.cancel();
    final n = _n, ia = _i % n;
    final ny = _dx.abs() > 44 ? ia + (_dx < 0 ? 1 : -1) : ia;
    _sist = DateTime.now();
    // The row continues from where the finger let go.
    final from = _pos - _dx / (_w + _gap);
    setState(() => _dx = 0);
    final m = ny.clamp(0, n - 1);
    if (m != _i) {
      _i = m;
      _fra = from;
      _til = m.toDouble();
      _glid.forward(from: 0);
      _prikk.forward(from: 0);
    } else {
      _fra = from;
      _til = m.toDouble();
      _glid.forward(from: 0);
      _prikk.forward();
    }
    Future.delayed(const Duration(milliseconds: 60), () => _drar = false);
  }

  @override
  Widget build(BuildContext context) {
    final slides = <_Kupong>[
      for (var k = 0; k < widget.tilbud.length; k++) _Kupong(t: widget.tilbud[k], draaper: k % 2 == 0),
      _Kupong(myst: !_myst, avslort: _myst, onMyst: _avslor, onAvslort: widget.onMysterie, draaper: widget.tilbud.length % 2 == 0),
    ];
    final alle = [...slides, slides.first];
    final n = slides.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Ærend-tilbud', style: jakarta(15, em: -.01)),
              const Spacer(),
              const _Nedtelling(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Listener(
          onPointerDown: _ned,
          onPointerMove: _flytt,
          onPointerUp: (_) => _slipp(),
          onPointerCancel: (_) => _slipp(),
          child: SizedBox(
            height: 168,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _glid,
                builder: (context, _) {
                  var dx = _dx;
                  if ((_i == 0 && dx > 0) || (_i >= n - 1 && dx < 0)) dx *= .35;
                  final pos = _pos;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var k = 0; k < alle.length; k++)
                        if ((k - pos).abs() < 1.6)
                          Positioned(
                            left: (k - pos) * (_w + _gap) + dx,
                            top: 0,
                            width: _w,
                            height: 168,
                            child: _tilt(k - pos, k == _i, alle[k]),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var k = 0; k < n; k++) ...[
              if (k > 0) const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  _sist = DateTime.now();
                  _snapT?.cancel();
                  _gaaTil(k);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: _ease,
                  width: k == _i % n ? 22 : 6,
                  height: 6,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Color.fromRGBO(255, 255, 255, k == _i % n ? .28 : .34),
                  ),
                  child: k == _i % n
                      ? AnimatedBuilder(
                          animation: _prikk,
                          builder: (context, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _prikk.value,
                            child: const ColoredBox(color: Colors.white),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Off-focus coupons fade to .4 and turn away (rotateY ±14°, scale .94),
  /// in step with the slide.
  Widget _tilt(double off, bool fokus, Widget child) {
    final a = off.abs().clamp(0.0, 1.0);
    final ry = off.sign * -14 * a;
    final s = 1 - .06 * a;
    return Opacity(
      opacity: 1 - .6 * a,
      child: Transform(
        alignment: const Alignment(0, -.1),
        transform: Matrix4.identity()
          ..setEntry(3, 2, -1 / 900)
          ..rotateY(rad(ry))
          ..scaleByDouble(s, s, 1, 1),
        child: IgnorePointer(ignoring: !fokus || _drar, child: child),
      ),
    );
  }

  void _avslor() {
    HapticFeedback.mediumImpact();
    _sist = DateTime.now().add(const Duration(seconds: 4));
    setState(() => _myst = true);
  }
}

class _Nedtelling extends StatefulWidget {
  const _Nedtelling();

  @override
  State<_Nedtelling> createState() => _NedtellingState();
}

class _NedtellingState extends State<_Nedtelling> {
  late final Timer _t = Timer.periodic(const Duration(seconds: 1), (_) {
    if (mounted && TickerMode.of(context)) setState(() {});
  });

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .62)).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Text.rich(
      TextSpan(
        text: 'Slutter om ',
        style: st,
        children: [TextSpan(text: hjemTilbudTid(), style: st.copyWith(color: Colors.white))],
      ),
    );
  }
}

/// One paper coupon (or the mystery one).
class _Kupong extends StatefulWidget {
  const _Kupong({this.t, this.myst = false, this.avslort = false, this.onMyst, this.onAvslort, required this.draaper});

  final HjemTilbud? t;
  final bool myst, avslort;
  final VoidCallback? onMyst, onAvslort;

  /// Drop pattern A (true) or B.
  final bool draaper;

  @override
  State<_Kupong> createState() => _KupongState();
}

class _KupongState extends State<_Kupong> {
  final List<int> _gnister = [];

  void _trykk() {
    if (widget.t != null) {
      widget.t!.onTap();
    } else if (widget.myst) {
      if (!MediaQuery.disableAnimationsOf(context)) {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _gnister.add(DateTime.now().millisecondsSinceEpoch));
        });
      }
      widget.onMyst?.call();
    } else {
      widget.onAvslort?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final myst = widget.myst, av = widget.avslort;
    // UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
    final eyebrow = t?.eyebrow ?? (myst ? 'Mysterie' : 'Avslørt');
    final navn = t?.navn ?? (myst ? 'Et tilbud bare for deg' : 'Rabatt på hele butikken');
    final butikk = t?.butikk ?? (myst ? 'Ærend' : 'Torgboden');
    final meta = t?.meta ?? (myst ? 'Fra en butikk i nærheten' : 'Fisketorget · 25 min');
    final ny = t?.ny ?? '';
    final gml = t?.gml ?? (myst ? 'Gjelder til midnatt' : 'Til midnatt');
    final strek = t?.gmlStrek ?? false;
    final verdi = t?.verdi ?? (myst ? '?' : '−20 %');
    final under = t?.under ?? (myst ? 'Én per kunde' : 'På kontoen');
    final cta = t != null ? 'Legg til' : (myst ? 'Avslør' : 'Til butikken');
    final stil = t != null
        ? _kStub[t.stub]!
        : myst
        ? const _StubStil([], Color(0xFF4A2E08), Color(0xFF4A2E08), _mrk)
        : _kStub[HjemStub.gull]!;
    final verdiStr = t?.verdiStr ?? (myst ? 44 : 24);
    const dark = Color(0xFF12303B);
    const tekstSkygge = [Shadow(color: Color.fromRGBO(18, 48, 59, .55), blurRadius: .6), Shadow(color: Color.fromRGBO(18, 48, 59, .12), blurRadius: 3)];

    Widget stub = Padding(
      padding: const EdgeInsets.fromLTRB(6, 13, 6, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Opacity(
            opacity: .82,
            child: Text(eyebrow.toUpperCase(), maxLines: 1, style: inter(9, weight: FontWeight.w800, em: .11, color: stil.c)),
          ),
          if (t?.fotoUrl != null || t?.fotoAsset != null)
            SizedBox(
              width: 94,
              height: 60,
              child: DecoratedBox(
                decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(20, 8, 2, .3), offset: Offset(0, 8), blurRadius: 8, spreadRadius: -6)]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(t!.fotoAsset != null ? 0 : 14),
                  child: t.fotoAsset != null
                      ? Image.asset(t.fotoAsset!, fit: BoxFit.contain)
                      : CachedNetworkImage(imageUrl: t.fotoUrl!, fit: BoxFit.cover, errorWidget: (_, _, _) => const SizedBox()),
                ),
              ),
            ),
          Text(
            verdi,
            maxLines: 1,
            style: jakarta(verdiStr, em: -.04, height: 1, color: stil.verdiC, shadows: stil.skygge).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          Opacity(opacity: .8, child: Text(under, maxLines: 1, style: inter(10.5, weight: FontWeight.w700, color: stil.c))),
        ],
      ),
    );
    if (av) {
      // tbFlipp .7s
      stub = LfOnce(
        ms: 700,
        builder: (context, ms, child) {
          final p = (ms / 700).clamp(0.0, 1.0);
          const c = Cubic(.3, 1.1, .5, 1);
          final ry = kf(p, const [0, .6, 1], const [-90, 12, 0], c);
          final sk = kf(p, const [0, .6, 1], const [.9, 1.04, 1], c);
          final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
          return Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, -1 / 420)
                ..rotateY(rad(ry))
                ..scaleByDouble(sk, sk, 1, 1),
              child: child,
            ),
          );
        },
        child: stub,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The coupon's thickness under it.
        const Positioned(
          left: 2,
          right: 2,
          top: 2,
          height: 148,
          child: CssBox(
            radius: BorderRadius.all(Radius.circular(20)),
            shadows: [CssShadow(0, 1, 1.5, 0, Color.fromRGBO(2, 12, 18, .35)), CssShadow(0, 10, 18, -8, Color.fromRGBO(2, 12, 18, .6))],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 150,
          child: GestureDetector(
            onTap: _trykk,
            child: ClipPath(
              clipper: const _Perforert(),
              child: CssBox(
                bg: const [
                  CssRadial([Color.fromRGBO(255, 255, 255, .6), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .62], rx: .64, ry: .7, cx: .12, cy: 0),
                  CssRadial([Color.fromRGBO(128, 138, 124, .3), Color.fromRGBO(128, 138, 124, 0)], stops: [0, .74], rx: .3, ry: .46, cx: .6, cy: .8),
                  CssRadial([Color.fromRGBO(128, 138, 124, .24), Color.fromRGBO(128, 138, 124, 0)], stops: [0, .72], rx: .2, ry: .38, cx: .06, cy: .74),
                  CssRadial([Color.fromRGBO(128, 138, 124, .16), Color.fromRGBO(128, 138, 124, 0)], stops: [0, .72], rx: .36, ry: .26, cx: .38, cy: .04),
                  CssLinear(172, [Color.fromRGBO(249, 246, 236, .96), Color.fromRGBO(234, 230, 217, .93)]),
                ],
                shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .3))],
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _Logo(t: t),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(butikk, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, weight: FontWeight.w800, height: 1.2, color: dark)),
                                          Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, height: 1.2, color: const Color(0xFF6B7C80))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 11),
                                LfPretty(navn, style: jakarta(17, em: -.022, height: 1.18, color: dark, shadows: tekstSkygge)),
                                const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (ny.isNotEmpty)
                                            Text(
                                              ny,
                                              maxLines: 1,
                                              style: jakarta(19, em: -.03, height: 1.05, color: dark, shadows: tekstSkygge).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            gml,
                                            maxLines: 1,
                                            style: inter(10.5, weight: FontWeight.w700, height: 1.05, color: const Color(0xFF8C9A9E)).copyWith(
                                              decoration: strek ? TextDecoration.lineThrough : null,
                                              decorationColor: const Color(0xFF8C9A9E),
                                              fontFeatures: const [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CssBox(
                                      height: 34,
                                      radius: BorderRadius.circular(999),
                                      bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
                                      shadows: const [
                                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                                        CssShadow(0, 2, 0, 0, Color(0xFFC4491A)),
                                        CssShadow(0, 8, 12, -7, Color.fromRGBO(233, 92, 44, .85)),
                                      ],
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Center(widthFactor: 1, child: Text(cta, style: inter(12, weight: FontWeight.w800))),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 108,
                          child: CssBox(
                            bg: stil.bg,
                            shadows: const [
                              CssShadow.inset(8, 0, 10, -8, Color.fromRGBO(0, 0, 0, .3)),
                              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                            ],
                            clip: true,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (myst) ...const [
                                  CssBox(bg: [CssLinear(140, [Color(0xFFFBE3A0), Color(0xFFE9B64A), Color(0xFFF6D27A), Color(0xFFD49528)], [0, .4, .58, 1])]),
                                  Opacity(opacity: .2, child: CustomPaint(painter: _Striper())),
                                  _StubSheen(),
                                ],
                                stub,
                                const IgnorePointer(
                                  child: CssBox(
                                    bg: [
                                      CssRadial([Color.fromRGBO(0, 0, 0, .16), Color.fromRGBO(0, 0, 0, 0)], stops: [0, .72], rx: .6, ry: .34, cx: .66, cy: .86),
                                      CssRadial([Color.fromRGBO(0, 0, 0, .1), Color.fromRGBO(0, 0, 0, 0)], stops: [0, .72], rx: .4, ry: .26, cx: .2, cy: .1),
                                    ],
                                  ),
                                ),
                                const _Drypp(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Wet paper: the baked `vaatRynk` and `vaatSpek` layers.
                    const Positioned.fill(child: IgnorePointer(child: _Vaat())),
                    const Positioned.fill(child: IgnorePointer(child: _Glans())),
                    Positioned.fill(child: IgnorePointer(child: _Draaper(a: widget.draaper))),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (final g in _gnister) Positioned.fill(key: ValueKey(g), child: const IgnorePointer(child: _Gnister())),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.t});

  final HjemTilbud? t;

  @override
  Widget build(BuildContext context) {
    final t = this.t;
    Widget inner;
    if (t?.logoAsset != null) {
      inner = Image.asset(t!.logoAsset!, width: 24, height: 24, fit: BoxFit.contain);
    } else if (t?.logoUrl != null) {
      inner = CachedNetworkImage(imageUrl: t!.logoUrl!, width: 28, height: 28, fit: BoxFit.cover, errorWidget: (_, _, _) => const SizedBox());
    } else {
      inner = SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-3 19 100 62"><circle cx="28" cy="50" r="19" fill="none" stroke="#1E4F5C" stroke-width="13"/><path d="M47 31 V69 M47 50 H85 M85 50 A19 19 0 1 0 78.7 64.1" fill="none" stroke="#1E4F5C" stroke-width="13" stroke-linecap="round"/></svg>',
        width: 17,
        height: 11,
      );
    }
    return Container(
      width: 28,
      height: 28,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(18, 48, 59, .12), spreadRadius: 1),
          BoxShadow(color: Color.fromRGBO(18, 48, 59, .3), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
        ],
      ),
      alignment: Alignment.center,
      child: inner,
    );
  }
}

/// The rounded coupon with the two half-moon notches at the perforation
/// (r 10, 108px from the right) and the punched holes every 10px.
class _Perforert extends CustomClipper<Path> {
  const _Perforert();

  @override
  Path getClip(Size size) {
    final x = size.width - 108;
    final hull = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: 10))
      ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: 10));
    for (var y = 5.0; y < size.height; y += 10) {
      hull.addOval(Rect.fromCircle(center: Offset(x, y), radius: 2.3 * .92));
    }
    return Path.combine(
      PathOperation.difference,
      Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20))),
      hull,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Vaat extends StatelessWidget {
  const _Vaat();

  // Pre-blended: multiply .28 = black at .28·(1−m); screen .55 = white at
  // .55·s, so both draw as plain alpha layers.
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bryggen/vaat_rynk.png', fit: BoxFit.fill),
        Image.asset('assets/images/bryggen/vaat_spek.png', fit: BoxFit.fill),
      ],
    );
  }
}

/// `vaatGlans` 12s: a soft band of light drifting across the paper.
class _Glans extends StatelessWidget {
  const _Glans();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return LfLoop(
          builder: (context, t, child) {
            final p = (t / 12000) % 1.0;
            final x = kf(p, const [0, .5, 1], const [-.14, .44, -.14], cssEaseInOut);
            return Transform.translate(offset: Offset(-.6 * w + x * 1.2 * w, 0), child: child);
          },
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: w * 1.2,
            maxWidth: w * 1.2,
            child: const CssBox(
              bg: [
                CssLinear(104, [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .24), Color.fromRGBO(255, 255, 255, .06), Color.fromRGBO(255, 255, 255, 0)], [.38, .47, .53, .6]),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Raised water drops on the paper (patterns `dA` / `dB`).
class _Draaper extends StatelessWidget {
  const _Draaper({required this.a});

  final bool a;

  @override
  Widget build(BuildContext context) {
    // (left or -right, top, w, h, dark shadow)
    const dA = [(20.0, 60.0, 7.0, 7.0, false), (158.0, 16.0, 5.0, 5.0, false), (204.0, 94.0, 10.0, 8.0, false), (122.0, 128.0, 4.0, 4.0, false), (-76.0, 118.0, 8.0, 7.0, true)];
    const dB = [(236.0, 22.0, 8.0, 7.0, false), (14.0, 118.0, 6.0, 6.0, false), (176.0, 70.0, 11.0, 9.0, false), (-30.0, 62.0, 6.0, 6.0, true)];
    return Stack(
      children: [
        for (final (x, y, w, h, mork) in a ? dA : dB)
          Positioned(
            left: x >= 0 ? x : null,
            right: x < 0 ? -x : null,
            top: y,
            width: w,
            height: h,
            child: _Draape(mork: mork, liten: w <= 4),
          ),
      ],
    );
  }
}

class _Draape extends StatelessWidget {
  const _Draape({required this.mork, required this.liten});

  final bool mork, liten;

  @override
  Widget build(BuildContext context) {
    final skygge = mork ? const Color.fromRGBO(0, 0, 0, .28) : const Color.fromRGBO(30, 24, 12, .24);
    return CssBox(
      radius: const BorderRadius.all(Radius.elliptical(99, 99)),
      bg: [
        const CssRadial([Color.fromRGBO(255, 255, 255, .95), Color.fromRGBO(255, 255, 255, 0)], rx: .4, ry: .36, cx: .34, cy: .3),
        CssRadial([skygge.withValues(alpha: 0), skygge.withValues(alpha: 0), skygge], stops: const [0, .5 / .92, 1], rx: .7 * .92, ry: .7 * .92, cx: .55, cy: .62),
      ],
      shadows: [
        CssShadow(1, liten ? 1.5 : 2, liten ? 1.5 : 2, -.5, mork ? const Color.fromRGBO(0, 0, 0, .3) : const Color.fromRGBO(30, 24, 12, .3)),
        if (!liten) const CssShadow.inset(0, -1, 1.5, 0, Color.fromRGBO(255, 255, 255, .55)),
      ],
    );
  }
}

/// A drop running down the stub now and then (`vaatSpor` / `vaatDrypp`,
/// 16s, 3s delay).
class _Drypp extends StatelessWidget {
  const _Drypp();

  @override
  Widget build(BuildContext context) {
    const c = Cubic(.5, 0, .8, .6);
    return LfLoop(
      builder: (context, t, _) {
        final e = t - 3000;
        if (e < 0) return const SizedBox.shrink();
        final p = (e / 16000) % 1.0;
        if (p < .58) return const SizedBox.shrink();
        final o = kf(p, const [.58, .61, .95, 1], const [0, 1, 1, 0], c);
        final sy = kf(p, const [.58, .95, 1], const [0, 1, 1], c);
        final dy = kf(p, const [.58, .95, 1], const [0, 80, 84], c);
        final dx = kf(p, const [.58, .95, 1], const [0, -1, -1], c);
        final so = kf(p, const [.58, .61, .95, 1], const [0, 1, .9, 0], c);
        return Stack(
          children: [
            Positioned(
              right: 24,
              top: 20,
              width: 3,
              height: 82,
              child: Opacity(
                opacity: so.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.diagonal3Values(1, sy, 1),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, .14)]),
                      boxShadow: [BoxShadow(color: Color.fromRGBO(255, 255, 255, .2), offset: Offset(1, 0))],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 21,
              top: 12,
              width: 9,
              height: 11,
              child: Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform.translate(offset: Offset(dx, dy), child: const _Draape(mork: true, liten: false)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Striper extends CustomPainter {
  const _Striper();

  @override
  void paint(Canvas canvas, Size size) {
    // repeating-linear-gradient(135deg, white .9 0 1.5px, transparent 1.5px 8px)
    final p = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, .9)
      ..strokeWidth = 1.5;
    final d = size.width + size.height;
    for (var o = -d; o < d; o += 8 * math.sqrt2) {
      canvas.drawLine(Offset(o, 0), Offset(o + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `tbSheen` 5s (1s delay) over the mystery stub.
class _StubSheen extends StatelessWidget {
  const _StubSheen();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth / 2;
        return LfLoop(
          builder: (context, t, child) {
            final e = t - 1000;
            if (e < 0) return const SizedBox.shrink();
            final p = (e / 5000) % 1.0;
            final x = kf(p, const [0, .3, 1], const [-1.2, 3.2, 3.2], cssEaseInOut);
            return Transform.translate(offset: Offset(x * w, 0), child: child);
          },
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: w,
              child: const CssBox(bg: [CssLinear(100, [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .6), Color.fromRGBO(255, 255, 255, 0)])]),
            ),
          ),
        );
      },
    );
  }
}

/// `tbGnister`: 26 confetti bits from the coupon's middle.
class _Gnister extends StatefulWidget {
  const _Gnister();

  @override
  State<_Gnister> createState() => _GnisterState();
}

class _GnisterState extends State<_Gnister> {
  static const _f = [Color(0xFFF9A273), Color(0xFF5CE0B8), Color(0xFFF2C14E), Color(0xFFFFFFFF), Color(0xFFF7D57E)];
  late final List<(double, double, double, double, double)> _p = () {
    final r = math.Random();
    return [for (var i = 0; i < 26; i++) (4 + r.nextDouble() * 5, r.nextDouble() * math.pi * 2, 40 + r.nextDouble() * 70, 800 + r.nextDouble() * 500, r.nextDouble() * 360)];
  }();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final c = Offset(box.maxWidth / 2, box.maxHeight * .45);
        return LfOnce(
          ms: 1300,
          builder: (context, t, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _p.length; i++)
                () {
                  final (s, a, v, dur, rot) = _p[i];
                  final e = const Cubic(.2, .7, .3, 1).transform((t / dur).clamp(0.0, 1.0));
                  return Positioned(
                    left: c.dx - s / 2 + math.cos(a) * v * e,
                    top: c.dy - s / 2 + (math.sin(a) * v - 20) * e,
                    width: s,
                    height: s,
                    child: Opacity(
                      opacity: (1 - e).clamp(0.0, 1.0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateZ(rad(rot * e))
                          ..scaleByDouble(.5 + .5 * e, .5 + .5 * e, 1, 1),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: _f[i % _f.length], borderRadius: BorderRadius.circular(i.isOdd ? s : 2)),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        );
      },
    );
  }
}
