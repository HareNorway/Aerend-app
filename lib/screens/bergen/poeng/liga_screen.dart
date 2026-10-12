import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../aegil/aegil_bits.dart';
import '../aegil/aegil_guide.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_perf.dart';
import '../kit/svg_sti.dart';
import '../meg/a3_services.dart';
import '../meg/meg_ark.dart';
import '../meg/meg_copy_a4.dart';
import '../meg/meg_nav.dart';
import '../meg/meg_sheets.dart';
import '../meg/mork_rad.dart';
import 'poeng_copy.dart';

/// Bergen-ligaen (new Bergen `erLigaSide`, L7949–8030, + `ligaVals` L19669–
/// 19732, design px): the night over Ulriken — aurora, stars, the lit peak
/// with its lantern, the city lights — «N dager igjen», «Vilkår», your place,
/// «Topp 3 · Ulriken-toppen», the month's top ten on the path up, you
/// climbing to your place (`ligaKlatr` / `ligaSti` / `ligaGnist`) with the
/// bubble; then the dark sheet: the table (medals, your row lit), «Månedens
/// premier», «Navn i ligaen», join / leave. The «Hele Bergen / Din bydel»
/// filter is gone, as in the design.
///
/// Left out (no data, or not true): the ticker («Kari klatret 2 plasser …»
/// — the league has no events feed) and, before you join, «Du ville vært
/// nr. 8 · Med poengene du alt har» — joining starts the month at 0 points
/// (`LeagueService::optIn`). The bubble then only carries «Bli med».
/// Data: `points/league`, `points/me/league` (opt-in, name).
class LigaScreen extends StatefulWidget {
  const LigaScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<LigaScreen> createState() => _LigaScreenState();
}

class _LigaScreenState extends State<LigaScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  League? _league;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await a3Try(_api.league);
    if (!mounted) return;
    setState(() {
      _league = l;
      _loading = false;
    });
  }

  String get _fornavn => a3Pref(prefUserName).trim().split(' ').firstOrNull ?? '';

  /// `ligaBli` / «Navn i ligaen»: the name and who sees it; joining when not in.
  Future<void> _navn() async {
    final l = _league;
    if (l == null) return;
    final updated = await MegSheets.ligaNavn(context, api: _api, league: l, firstName: _fornavn, bydel: l.bydel ?? A4MegCopy.a4_meg_bydel, onMeldAv: _av);
    if (!mounted || updated == null) return;
    showBergenToast(context, l.optedIn ? A4MegCopy.a4_meg_lagret : A3PoengCopy.a3_poeng_liga_med_toast, icon: Icons.check_rounded);
    _load();
  }

  /// `ligaAv`: what leaving means, «Meld meg av».
  Future<void> _av() async {
    final ok = await showMegArk<bool>(
      context,
      key: const Key('liga-av-sheet'),
      mork: true,
      title: A3PoengCopy.a3_poeng_liga_av_title,
      subtitle: A3PoengCopy.a3_poeng_liga_av_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MorkRad(delayMs: 0, ikon: MorkIk.stjerne, navn: A3PoengCopy.a3_poeng_liga_av_poeng, under: A3PoengCopy.a3_poeng_liga_av_poeng_sub, onTap: () {}),
          const SizedBox(height: 8),
          MorkRad(delayMs: 40, ikon: MorkIk.pokal, navn: A3PoengCopy.a3_poeng_liga_av_premie, under: A3PoengCopy.a3_poeng_liga_av_premie_sub, onTap: () {}),
        ],
      ),
      primary: MegArkButton(key: const Key('liga-av-cta'), label: A3PoengCopy.a3_poeng_liga_meld_meg_av, onTap: () => Navigator.of(context).pop(true)),
    );
    if (ok != true) return;
    final done = await _api.leagueOptIn(false);
    if (!mounted) return;
    if (done) {
      showBergenToast(context, A3PoengCopy.a3_poeng_liga_av_toast);
      _load();
    }
  }

  void _vilkaar() => MegSheets.ligaVilkaar(context);

  void _seremoni() => showMegArk<void>(
    context,
    mork: true,
    title: A3PoengCopy.a3_poeng_liga_seremoni_title,
    subtitle: A3PoengCopy.a3_poeng_liga_seremoni_sub,
    body: (ctx, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, p) in A3PoengCopy.a3_poeng_liga_premie_liste.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          MorkRad(delayMs: i * 40.0, ikon: MorkIk.pokal, navn: p, onTap: () {}),
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = _league;
    final med = l?.optedIn == true;
    final own = med ? l?.own : null;
    final top = l?.top ?? const <LeagueStanding>[];
    final rader = [...top, if (own != null && !top.any((s) => s.userId == own.userId)) own];
    final plass = own != null ? A3PoengCopy.a3_poeng_liga_min_plass(own.rank, l?.displayName ?? _fornavn) : A3PoengCopy.a3_poeng_liga_ute;
    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: LfFrame(
        child: Builder(
          builder: (context) {
            final topPad = MediaQuery.paddingOf(context).top;
            final dy = topPad - 12;
            return AeOnce(
              kind: AeInn.skjermInn,
              ms: 340,
              curve: const Cubic(.2, .9, .3, 1),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CssBox(
                      bg: [
                        CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
                        CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .42, 1]),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 336 + dy,
                    child: _loading
                        ? _Natt(dy: dy, child: const SizedBox.shrink())
                        : _Hode(
                            dy: dy,
                            plass: plass,
                            top: top,
                            own: own,
                            med: med,
                            participants: l?.participants ?? 0,
                            onTilbake: () => Navigator.of(context).maybePop(),
                            onVilkaar: _vilkaar,
                            onBliMed: _navn,
                          ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 326 + dy,
                    bottom: 0,
                    child: CssBox(
                      radius: const BorderRadius.vertical(top: Radius.circular(28)),
                      clip: true,
                      bg: const [
                        CssLinear(180, [Color(0xFF1E4F5C), Color(0xFF173E48), Color(0xFF122F3A)], [0, .55, 1]),
                      ],
                      shadows: const [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .08)),
                        CssShadow(0, -20, 40, -18, Color.fromRGBO(4, 18, 26, .7)),
                      ],
                      child: _loading
                          ? const Center(child: CircularProgressIndicator(color: BergenTokens.mint))
                          : ListView(
                              key: const Key('liga-list'),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
                              children: [
                                _Tabell(rader: rader, ownId: own?.userId, maaned: l?.month),
                                const SizedBox(height: 14),
                                _Premier(onSeremoni: _seremoni),
                                const SizedBox(height: 12),
                                _GlassRad(
                                  key: const Key('liga-navn'),
                                  tile: const _Tile(farger: [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], d: 'M12 4.4a3.6 3.6 0 1 0 .01 0zM4.8 20c1.2-3.8 3.8-5.8 7.2-5.8s6 2 7.2 5.8'),
                                  tittel: A3PoengCopy.a3_poeng_liga_navn_rad(med ? (l?.displayName ?? _fornavn) : A3PoengCopy.a3_poeng_liga_ikke_valgt),
                                  under: med ? A3PoengCopy.a3_poeng_liga_syn(_syn(l?.visibility)) : A3PoengCopy.a3_poeng_liga_navn_ute,
                                  onTap: _navn,
                                ),
                                const SizedBox(height: 10),
                                _GlassRad(
                                  key: const Key('liga-bli-av'),
                                  tile: const _Tile(farger: [Color(0xFFF68450), Color(0xFFE65A28)], d: 'M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4M10 16l-4-4 4-4M6 12h10'),
                                  tittel: med ? A3PoengCopy.a3_poeng_liga_av_title : A3PoengCopy.a3_poeng_liga_bli_med_tittel,
                                  onTap: med ? _av : _navn,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const Positioned(left: 0, right: 0, bottom: 0, child: MegNav()),
                  Positioned.fill(child: AegilGuide(skjerm: 'liga', tips: aegilGuideTips('liga'))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _syn(String? s) {
    for (final v in A4MegCopy.a4_meg_ligasyn) {
      if (v[0] == s) return v[1].toLowerCase();
    }
    return A4MegCopy.a4_meg_ligasyn.first[1].toLowerCase();
  }
}

// ── The path ──────────────────────────────────────────────────────────────

/// `M26 296 C150 292 196 170 332 108`, measured by length as the design does
/// (`ligaKlatrere`: 200 samples).
abstract final class _Sti {
  static const Offset _a = Offset(26, 296), _b = Offset(150, 292), _c = Offset(196, 170), _d = Offset(332, 108);
  static final Path path = Path()
    ..moveTo(26, 296)
    ..cubicTo(150, 292, 196, 170, 332, 108);

  static Offset _bez(double u) {
    final v = 1 - u;
    return _a * (v * v * v) + _b * (3 * v * v * u) + _c * (3 * v * u * u) + _d * (u * u * u);
  }

  static final List<Offset> _p = [for (var n = 0; n <= 200; n++) _bez(n / 200)];
  static final List<double> _len = () {
    final c = <double>[0];
    for (var n = 1; n <= 200; n++) {
      c.add(c.last + (_p[n] - _p[n - 1]).distance);
    }
    return c;
  }();

  /// The point [f] of the way along (0 … 1).
  static Offset pos(double f) {
    final l = f.clamp(0.0, 1.0) * _len[200];
    var n = 1;
    while (n < 200 && _len[n] < l) {
      n++;
    }
    final d = _len[n] - _len[n - 1];
    return Offset.lerp(_p[n - 1], _p[n], d == 0 ? 0 : (l - _len[n - 1]) / d)!;
  }

  /// Where rank [r] stands: the top ten from 6 % to 94 %; below them, the foot.
  static double plass(int r) => r <= 10 ? .06 + (10 - r) / 9 * .88 : .02;
}

// ── The night ─────────────────────────────────────────────────────────────

/// The sky, the aurora (`sway 9s` / `13s -4s reverse`, blurred 6), the stars
/// (`ligaGlimt`), the shooting star (`ligaSkudd 9s 3s`), the mountains, the
/// lantern (`ligaLykt 2.6s`), the dotted path, your orange path (`ligaSti`)
/// and the city lights — under [child].
class _Natt extends StatelessWidget {
  const _Natt({required this.dy, required this.child, this.sti});

  final double dy;
  final Widget child;

  /// The orange path's length now (0 … 1), or null when you are not in.
  final double? sti;

  static final Path _nord1 = svgSti('M0 96 C80 44 170 78 250 34 C310 2 356 16 410 -10');
  static final Path _nord2 = svgSti('M-20 64 C60 26 150 54 230 18 C290 -6 350 6 420 -22');

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A1622), Color(0xFF122638), Color(0xFF1A3A50), Color(0xFF1E4F5C)],
                stops: [0, .32, .62, 1],
              ),
            ),
          ),
        ),
        for (final (p, w, op, farger, stopp, ms, fra, rev) in [
          (_nord1, 26.0, .7, const [kAeMint, Color(0xFF9C7BE8)], const [0.0, 1.0], 9000.0, 0.0, false),
          (
            _nord2,
            15.0,
            .55,
            const [Color.fromRGBO(92, 224, 184, 0), Color.fromRGBO(127, 240, 203, .6), Color.fromRGBO(156, 140, 240, .4)],
            const [0.0, .45, 1.0],
            13000.0,
            4000.0,
            true,
          ),
        ])
          Positioned(
            left: -30,
            top: dy - 40,
            width: 390 + 60,
            height: 160,
            child: IgnorePointer(
              // The stroke is blurred once (cached in its own layer); the
              // sway only moves that layer (`sway` on the SVG path, origin 0 0).
              child: LfLoop(
                child: Opacity(
                  opacity: op,
                  child: RepaintBoundary(
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: CustomPaint(size: const Size(450, 160), painter: _Nordlys(p, w, farger, stopp)),
                    ),
                  ),
                ),
                builder: (context, t, child) {
                  var q = ((t + fra) / ms) % 1.0;
                  if (rev) q = 1 - q;
                  final sx = kf(q, const [0, .5, 1], const [-4, 3, -4], cssEaseInOut);
                  final tx = kf(q, const [0, .5, 1], const [0, 9, 0], cssEaseInOut);
                  return Transform(
                    alignment: Alignment.topLeft,
                    origin: const Offset(30, 40),
                    transform: Matrix4.skewX(rad(sx))..translateByDouble(tx, 0, 0, 1),
                    child: child,
                  );
                },
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: LfLoop(
                builder: (context, t, _) => CustomPaint(painter: _Fjell(t: t, dy: dy, sti: sti)),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    ),
  );
}

class _Nordlys extends CustomPainter {
  _Nordlys(this.p, this.w, this.farger, this.stopp);
  final Path p;
  final double w;
  final List<Color> farger;
  final List<double> stopp;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(30, 40);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = ui.Gradient.linear(const Offset(-20, 0), const Offset(420, 0), farger, stopp),
    );
  }

  @override
  bool shouldRepaint(_Nordlys o) => false;
}

/// One twinkle (`ligaGlimt`): (x, y, size, colour, glow, glow px, s, delay s).
typedef _Glimt = (double, double, double, Color, Color, double, double, double);

class _Fjell extends CustomPainter {
  _Fjell({required this.t, required this.dy, required this.sti});
  final double t;
  final double dy;
  final double? sti;

  static final Path _bak = svgSti('M200 336 L200 196 C246 168 300 150 350 154 C368 156 380 160 390 164 L390 336 Z');
  static final Path _foran = svgSti('M0 262 C70 250 120 228 168 200 C214 172 262 128 302 110 C318 103 330 100 342 104 C360 110 376 120 390 128 L390 336 L0 336 Z');
  static final Path _rygg = svgSti('M0 262 C70 250 120 228 168 200 C214 172 262 128 302 110 C318 103 330 100 342 104 C360 110 376 120 390 128');
  static final Path _bakke = svgSti('M0 302 C80 296 160 302 240 298 C300 295 350 300 390 296 L390 336 L0 336 Z');

  static const Color _s = Color(0xFFE6F2F4);
  static const Color _sg = Color.fromRGBO(230, 242, 244, .8);
  static const Color _lys1 = Color(0xFFFFF1D6), _lys1g = Color.fromRGBO(255, 241, 214, .9);
  static const Color _lys2 = Color(0xFFFFD79A), _lys2g = Color.fromRGBO(255, 190, 110, .9);

  /// The twelve stars (% of 390 × 336) and the city lights (px).
  static const List<_Glimt> _stjerner = [
    (.22 * 390, .07 * 336, 3, _s, _sg, 4, 2.2, 0), (.38 * 390, .16 * 336, 2, _s, _sg, 4, 3.1, .6),
    (.57 * 390, .05 * 336, 2, _s, _sg, 4, 2.6, 1.2), (.66 * 390, .22 * 336, 3, _s, _sg, 4, 3.6, .3),
    (.81 * 390, .11 * 336, 2, _s, _sg, 4, 2.4, 1.8), (.90 * 390, .26 * 336, 2, _s, _sg, 4, 3.3, .9),
    (.12 * 390, .30 * 336, 3, _s, _sg, 4, 2.8, 1.4), (.47 * 390, .34 * 336, 2, _s, _sg, 4, 3.9, 2.1),
    (.74 * 390, .40 * 336, 2, _s, _sg, 4, 2.5, .5), (.30 * 390, .44 * 336, 3, _s, _sg, 4, 3.4, 1.1),
    (.94 * 390, .46 * 336, 2, _s, _sg, 4, 2.9, 1.6), (.62 * 390, .13 * 336, 2, _s, _sg, 4, 3.2, 2.4),
    (8, 306, 3, _lys1, _lys1g, 5, 2.0, 0), (22, 312, 2, _lys2, _lys2g, 5, 2.5, .37), (37, 304, 2, _lys2, _lys2g, 5, 3.0, .74),
    (55, 314, 2, _lys1, _lys1g, 5, 3.5, 1.11), (71, 308, 3, _lys2, _lys2g, 5, 4.0, 1.48), (90, 316, 2, _lys2, _lys2g, 5, 2.0, 1.85),
    (108, 305, 2, _lys1, _lys1g, 5, 2.5, 2.22), (126, 311, 2, _lys2, _lys2g, 5, 3.0, .19), (150, 307, 3, _lys2, _lys2g, 5, 3.5, .56),
    (173, 315, 2, _lys1, _lys1g, 5, 4.0, .93), (196, 304, 2, _lys2, _lys2g, 5, 2.0, 1.30), (220, 311, 2, _lys2, _lys2g, 5, 2.5, 1.67),
    (246, 306, 3, _lys1, _lys1g, 5, 3.0, 2.04), (268, 314, 2, _lys2, _lys2g, 5, 3.5, .01), (292, 303, 2, _lys2, _lys2g, 5, 4.0, .38),
    (318, 310, 2, _lys1, _lys1g, 5, 2.0, .75), (344, 305, 3, _lys2, _lys2g, 5, 2.5, 1.12), (366, 313, 2, _lys2, _lys2g, 5, 3.0, 1.49),
    (382, 307, 2, _lys1, _lys1g, 5, 3.5, 1.86),
  ];

  static double _glimt(double t, double s, double d) {
    final q = ((t / 1000 + s - d % s) / s) % 1.0;
    return kf(q, const [0, .5, 1], const [.25, 1, .25], cssEaseInOut);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, dy);
    // The stars above the mountains (the design's spans come after the SVG;
    // the ones over the ridge sit in the sky anyway).
    for (final (x, y, s, c, g, gpx, sek, d) in _stjerner.take(12)) {
      _prikk(canvas, x, y, s, c, g, gpx, _glimt(t, sek, d));
    }
    // ligaSkudd 9s ease-out 3s: from 86 % a 70 px streak at 152°.
    if (t > 3000) {
      final q = ((t - 3000) / 9000) % 1.0;
      if (q > .86) {
        final e = cssEaseOut.transform((q - .86) / .14);
        final op = q < .89 ? (q - .86) / .03 : 1 - (q - .89) / .11;
        canvas
          ..save()
          ..translate(318, 34 + .75)
          ..rotate(rad(152))
          ..translate(150 * e, 0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(0, -.75, 70, 1.5), const Radius.circular(99)),
          Paint()
            ..shader = ui.Gradient.linear(Offset.zero, const Offset(70, 0), [Color.fromRGBO(255, 255, 255, .95 * op.clamp(0, 1)), const Color.fromRGBO(255, 255, 255, 0)]),
        );
        canvas.restore();
      }
    }
    canvas.drawPath(_bak, Paint()..color = const Color.fromRGBO(36, 74, 92, .5));
    canvas.drawPath(
      _foran,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 100), const Offset(0, 336), const [Color(0xFF21495A), Color(0xFF173845), Color(0xFF0E2531)], const [0, .45, 1]),
    );
    canvas.drawPath(
      _rygg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color.fromRGBO(127, 240, 203, .34),
    );
    // The lantern's glow (`ligaLykt 2.6s`).
    final lq = (t / 2600) % 1.0;
    final lo = kf(lq, const [0, .3, .55, .75, 1], const [.8, 1, .7, .95, .8], cssEaseInOut);
    final ls = kf(lq, const [0, .3, .55, .75, 1], const [1, 1.1, .96, 1.05, 1], cssEaseInOut);
    canvas.drawCircle(
      const Offset(337, 96),
      36 * ls,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(337, 96), 36 * ls, [
          Color.fromRGBO(255, 230, 174, .95 * lo),
          Color.fromRGBO(242, 193, 78, .42 * lo),
          const Color.fromRGBO(242, 193, 78, 0),
        ], const [0, .35, 1]),
    );
    canvas.drawLine(
      const Offset(336, 108),
      const Offset(336, 99),
      Paint()
        ..color = const Color(0xFFC9D8DE)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    final lykt = RRect.fromRectAndRadius(const Rect.fromLTWH(332.5, 89, 7, 10), const Radius.circular(2));
    canvas
      ..drawRRect(lykt, Paint()..color = const Color(0xFFFFE6AE))
      ..drawRRect(
        lykt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFFF2C14E),
      );
    // The path: dotted (2 / 6, round), then yours in orange.
    final prikk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color.fromRGBO(255, 255, 255, .32);
    for (final m in _Sti.path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, d + 2), prikk);
      }
      final s = sti;
      if (s != null && s > 0) {
        canvas.drawPath(
          m.extractPath(0, m.length * s),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round
            ..shader = ui.Gradient.linear(const Offset(26, 296), const Offset(332, 108), const [Color(0xFFFFC29E), Color(0xFFF26D3D)]),
        );
      }
    }
    canvas.drawPath(_bakke, Paint()..color = const Color(0xFF0B1F2A));
    for (final (x, y, s, c, g, gpx, sek, d) in _stjerner.skip(12)) {
      _prikk(canvas, x, y, s, c, g, gpx, _glimt(t, sek, d));
    }
  }

  /// The dot and its `box-shadow: 0 0 Npx` glow, drawn as a radial fade
  /// (cheaper per frame than a mask blur for thirty dots).
  static void _prikk(Canvas canvas, double x, double y, double s, Color c, Color g, double gpx, double op) {
    final o = Offset(x + s / 2, y + s / 2);
    final r = s / 2 + gpx;
    canvas
      ..drawCircle(
        o,
        r,
        Paint()..shader = ui.Gradient.radial(o, r, [g.withValues(alpha: g.a * op), g.withValues(alpha: 0)], [s / 2 / r, 1]),
      )
      ..drawCircle(o, s / 2, Paint()..color = c.withValues(alpha: op));
  }

  @override
  bool shouldRepaint(_Fjell o) => o.t != t || o.dy != dy || o.sti != sti;
}

// ── The header ────────────────────────────────────────────────────────────

class _Hode extends StatelessWidget {
  const _Hode({
    required this.dy,
    required this.plass,
    required this.top,
    required this.own,
    required this.med,
    required this.participants,
    required this.onTilbake,
    required this.onVilkaar,
    required this.onBliMed,
  });

  final double dy;
  final String plass;
  final List<LeagueStanding> top;
  final LeagueStanding? own;
  final bool med;
  final int participants;
  final VoidCallback onTilbake;
  final VoidCallback onVilkaar;
  final VoidCallback onBliMed;

  /// `ligaDagerTx`: days left in the month.
  static String dager(DateTime n) {
    final igjen = DateTime(n.year, n.month + 1, 0).day - n.day;
    return igjen <= 0 ? A3PoengCopy.a3_poeng_liga_siste_dag : A3PoengCopy.a3_poeng_liga_dager(igjen);
  }

  @override
  Widget build(BuildContext context) {
    // You: your place when you are in; outside, where joining starts you
    // (the foot of the path — the month starts at 0 points).
    final rang = own?.rank ?? (participants + 1);
    final maal = _Sti.plass(rang);
    final fra = math.max(0.0, maal - .88 / 9);
    final over = top.where((s) => s.rank == rang - 1).firstOrNull;
    final under = top.where((s) => s.rank == rang + 1).firstOrNull;
    final klatrere = [
      for (final s in top.take(10))
        if (!(med && s.userId == own?.userId) && s.rank >= 1 && s.rank <= 10) s,
    ];
    final gnister = BergenPerf.count(context, 1);
    return LfOnce(
      ms: 5400,
      builder: (context, t, _) {
        final k = const Cubic(.45, 0, .2, 1).transform(kfP(t, 350, 1600));
        final her = fra + (maal - fra) * k;
        final p = _Sti.pos(her);
        return _Natt(
          dy: dy,
          sti: med ? her : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Back, «N dager igjen», «Vilkår».
              Positioned(
                left: 16,
                right: 16,
                top: 12 + dy,
                child: Row(
                  children: [
                    _GlassKnapp(
                      key: const Key('liga-tilbake'),
                      onTap: onTilbake,
                      width: 40,
                      child: const AeIkon('M15 6l-6 6 6 6', size: 15, stroke: 2.2, color: Color(0xFFF5F3EF)),
                    ),
                    const Spacer(),
                    CssBox(
                      key: const Key('liga-dager'),
                      height: 30,
                      radius: BorderRadius.circular(999),
                      bg: const [CssSolid(Color.fromRGBO(0, 0, 0, .3))],
                      shadows: const [
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
                        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .12)),
                      ],
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AeIkon(MorkIk.klokke, size: 13, stroke: 2.4, color: Color(0xFFF2C14E)),
                          const SizedBox(width: 6),
                          Text(dager(DateTime.now()), style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFFF5F3EF))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _GlassKnapp(
                      key: const Key('liga-vilkaar'),
                      onTap: onVilkaar,
                      height: 34,
                      child: Text(A3PoengCopy.a3_poeng_liga_vilkaar, style: inter(12, weight: FontWeight.w800, color: const Color(0xFFF5F3EF))),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: 12 + 40 + 8 + dy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // `vekt .9s ease-out`: from .6 to full.
                    Opacity(
                      opacity: .6 + .4 * cssEaseOut.transform(kfP(t, 0, 900)),
                      child: Text(A3PoengCopy.a3_poeng_liga_title, style: jakarta(25, em: -.03, color: const Color(0xFFF5F3EF))),
                    ),
                    const SizedBox(height: 3),
                    Text(plass, key: const Key('liga-plass'), style: inter(12, weight: FontWeight.w700, color: const Color(0xFF9FB6C2))),
                  ],
                ),
              ),
              // «Topp 3 · Ulriken-toppen».
              Positioned(
                right: 14,
                top: 62 + dy,
                child: CssBox(
                  height: 24,
                  radius: BorderRadius.circular(999),
                  bg: const [
                    CssLinear(180, [Color.fromRGBO(242, 193, 78, .32), Color.fromRGBO(242, 193, 78, .12)]),
                  ],
                  shadows: const [
                    CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(242, 193, 78, .55)),
                    CssShadow(0, 0, 16, -4, Color.fromRGBO(242, 193, 78, .7)),
                  ],
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AeIkon('M12 2l2.9 6.6 7.1.6-5.4 4.7 1.6 7L12 17.3 5.8 20.9l1.6-7L2 9.2l7.1-.6z', size: 10, stroke: 0, fill: Color(0xFFF2C14E)),
                      const SizedBox(width: 5),
                      Text(A3PoengCopy.a3_poeng_liga_topp3, style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFFFFE6AE))),
                    ],
                  ),
                ),
              ),
              // The climbers (`ligaPop .45s`, from the foot up).
              for (final s in klatrere)
                _Klatrer(
                  key: Key('liga-klatrer-${s.rank}'),
                  t: t,
                  at: _Sti.pos(_Sti.plass(s.rank)).translate(0, dy),
                  i: s.rank - 1,
                  navn: s.label.split(' · ').first,
                  maal: s.rank == rang - 1,
                ),
              // The spark up to the top (`ligaGnist 3.2s ease-in 2.2s`).
              if (gnister > 0 && t > 2200 && t < 5400)
                Builder(
                  builder: (context) {
                    final q = kfP(t, 2200, 3200);
                    final g = _Sti.pos(maal + (1 - maal) * Curves.easeIn.transform(q)).translate(0, dy);
                    final op = q < .12 ? q / .12 : (q < .8 ? 1.0 : 1 - (q - .8) / .2);
                    return Positioned(
                      left: g.dx - 3,
                      top: g.dy - 3,
                      child: Opacity(
                        opacity: op.clamp(0.0, 1.0),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Color.fromRGBO(127, 240, 203, .9), blurRadius: 6 / 2 / .57735, spreadRadius: 2),
                              BoxShadow(color: Color.fromRGBO(92, 224, 184, .45), blurRadius: 14 / 2 / .57735, spreadRadius: 5),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // You.
              Positioned(
                left: p.dx - 14,
                top: p.dy + dy - 14,
                child: _Deg(key: const Key('liga-deg'), t: t, med: med, rang: rang),
              ),
              // The bubble (`ligaInn .5s 1.9s`).
              if (!med || (own != null && rang > 1 && over != null))
                _Boble(
                  t: t,
                  marker: _Sti.pos(maal).translate(0, dy),
                  med: med,
                  tittel: med ? A3PoengCopy.a3_poeng_liga_til_plass(over!.points - own!.points, rang - 1) : null,
                  fyll: med ? ((own!.points - (under?.points ?? 0)) / math.max(1, over!.points - (under?.points ?? 0))).clamp(.08, .96) : null,
                  onBliMed: onBliMed,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A climber (`ligaKlatrere`): 17 px for the top three (mint), 14 below,
/// the one just above you paler with a dashed ring; names on the top three
/// and on that one.
class _Klatrer extends StatelessWidget {
  const _Klatrer({super.key, required this.t, required this.at, required this.i, required this.navn, required this.maal});

  final double t;
  final Offset at;
  final int i;
  final String navn;
  final bool maal;

  @override
  Widget build(BuildContext context) {
    final s = i < 3 ? 17.0 : 14.0;
    final farger = i < 3 ? const [Color(0xFFA8F0DB), Color(0xFF3FC7A2)] : (maal ? const [Color(0xFFE3EDF1), Color(0xFF9FB6C2)] : const [Color(0xFFC8D8E0), Color(0xFF8CA3AF)]);
    // `ligaPop .45s cubic-bezier(.3,1.6,.5,1) <.15 + (9 − i) · .05>s both`.
    final pp = kfP(t, (150 + (9 - i) * 50).toDouble(), 450);
    final sc = const Cubic(.3, 1.6, .5, 1).transform(pp);
    return Positioned(
      left: at.dx - 40,
      top: at.dy - 15,
      width: 80,
      height: 60,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            if (maal)
              const Positioned(
                top: 0,
                child: CustomPaint(size: Size(30, 30), painter: _Ring(Color.fromRGBO(249, 162, 115, .55), 1.5)),
              ),
            Positioned(
              top: 15 - s / 2,
              child: Opacity(
                opacity: pp <= 0 ? 0 : 1,
                child: Transform.scale(
                  scale: sc,
                  child: Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(center: const Alignment(-.32, -.44), radius: .9, colors: farger),
                      boxShadow: [
                        const BoxShadow(color: Color.fromRGBO(255, 255, 255, .9), spreadRadius: 1.5),
                        if (i < 3)
                          const BoxShadow(color: Color.fromRGBO(92, 224, 184, .4), blurRadius: 6 / 2 / .57735)
                        else
                          const BoxShadow(color: Color.fromRGBO(0, 0, 0, .45), offset: Offset(0, 4), blurRadius: 7 / 2 / .57735, spreadRadius: -2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i < 3 || maal)
              Positioned(
                top: 15 + s / 2 + 3,
                child: Opacity(
                  opacity: pp <= 0 ? 0 : 1,
                  child: Text(
                    navn,
                    maxLines: 1,
                    softWrap: false,
                    style: inter(9.5, weight: FontWeight.w800, color: maal ? const Color(0xFFFFC8A8) : const Color(0xFFCFE3E9)).copyWith(
                      shadows: const [Shadow(color: Color.fromRGBO(0, 0, 0, .7), blurRadius: 3, offset: Offset(0, 1))],
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

/// A dashed ring.
class _Ring extends CustomPainter {
  const _Ring(this.c, this.w);
  final Color c;
  final double w;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.shortestSide - w) / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c;
    final o = size.center(Offset.zero);
    final n = (2 * math.pi * r / 4.5).floor();
    for (var k = 0; k < n; k++) {
      final a = 2 * math.pi * k / n;
      canvas.drawArc(Rect.fromCircle(center: o, radius: r), a, 2 * math.pi / n / 2, false, p);
    }
  }

  @override
  bool shouldRepaint(_Ring o) => false;
}

/// You on the path: orange with your place (`Deg`), or the dashed «?»
/// (`Du?`); `ligaLand .6s 1.9s`, the ring `ligaRing 5s 2.6s`.
class _Deg extends StatelessWidget {
  const _Deg({super.key, required this.t, required this.med, required this.rang});

  final double t;
  final bool med;
  final int rang;

  @override
  Widget build(BuildContext context) {
    final lp = kfP(t, 1900, 600);
    final land = kf(lp, const [0, .35, .65, 1], const [1, 1.32, .92, 1], const Cubic(.3, 1.6, .5, 1));
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // `ligaRing 5s ease-out 2.6s infinite`.
          if (t >= 2600)
            Positioned.fill(
              child: LfLoop(
                builder: (context, lt, _) {
                  final q = cssEaseOut.transform((lt / 5000) % 1.0);
                  return Transform.scale(
                    scale: 1 + 1.4 * q,
                    child: Opacity(
                      opacity: .9 * (1 - q),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: Color.fromRGBO(249, 162, 115, .45), width: 1.5, strokeAlign: BorderSide.strokeAlignOutside)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Positioned.fill(
            child: Transform.scale(
              scale: land,
              child: med
                  ? Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(center: Alignment(-.32, -.44), radius: .9, colors: [Color(0xFFFFC29E), Color(0xFFF26D3D), Color(0xFFD9531F)], stops: [0, .55, 1]),
                        boxShadow: [
                          BoxShadow(color: Colors.white, spreadRadius: 2),
                          BoxShadow(color: Color.fromRGBO(242, 109, 61, .4), blurRadius: 10 / 2 / .57735),
                        ],
                      ),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(2), child: Text('$rang', style: jakarta(12)))),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromRGBO(242, 109, 61, .28),
                              boxShadow: [BoxShadow(color: Color.fromRGBO(242, 109, 61, .3), blurRadius: 10 / 2 / .57735)],
                            ),
                          ),
                        ),
                        const Positioned.fill(child: CustomPaint(painter: _Ring(Color.fromRGBO(255, 255, 255, .85), 1.5))),
                        Center(child: Text('?', style: jakarta(12))),
                      ],
                    ),
            ),
          ),
          Positioned(
            left: -30,
            right: -30,
            top: 31,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFE95C2C)]),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, .6), offset: Offset(0, 4), blurRadius: 8 / 2 / .57735, spreadRadius: -3)],
                ),
                child: Text(med ? A3PoengCopy.a3_poeng_liga_deg : A3PoengCopy.a3_poeng_liga_du, style: inter(9.5, weight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bubble (148 wide, blurred glass, the tail toward you): in, «N poeng
/// til N. plass» and the bar (`ligaFyll 1.2s 2.1s`, `ligaGlans 2.8s 3.2s`);
/// out, «Bli med». Placed over you, or under you when you stand high.
class _Boble extends StatelessWidget {
  const _Boble({required this.t, required this.marker, required this.med, required this.tittel, required this.fyll, required this.onBliMed});

  final double t;
  final Offset marker;
  final bool med;
  final String? tittel;
  final double? fyll;
  final VoidCallback onBliMed;

  static const double _b = 148;

  @override
  Widget build(BuildContext context) {
    final h = med ? 8 + 15 + 7 + 5 + 9.0 : 8 + 7 + 28 + 9.0;
    final left = (marker.dx - 97).clamp(14.0, 390 - 14 - _b);
    var top = marker.dy - 30 - h;
    // Too high (rank 2–3 near the peak): under you instead, without the tail.
    final under = top < 104;
    if (under) top = marker.dy + 50;
    final hale = (marker.dx - left - 5).clamp(16.0, _b - 26);
    final ip = kfP(t, 1900, 500);
    final e = const Cubic(.3, 1.4, .5, 1).transform(ip);
    final blur = BergenPerf.blurOn(context, secondary: true);
    final kort = Container(
      width: _b,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, .09)]),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tittel != null) Text(tittel!, style: inter(12, weight: FontWeight.w800, height: 1.25)),
          if (med && fyll != null) ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, .32))),
                    FractionallySizedBox(
                      widthFactor: fyll! * const Cubic(.3, .9, .3, 1).transform(kfP(t, 2100, 1200)),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                          gradient: LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)]),
                        ),
                      ),
                    ),
                    // `ligaGlans 2.8s ease-in-out 3.2s 1`.
                    if (t > 3200 && t < 6000)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: _b * .34,
                        child: Transform.translate(
                          offset: Offset(_b * .34 * kf(kfP(t, 3200, 2800), const [0, .55, 1], const [-1.2, -1.2, 3.2], cssEaseInOut), 0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .65), Color.fromRGBO(255, 255, 255, 0)]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (!med) ...[
            const SizedBox(height: 7),
            AePress(
              key: const Key('liga-bli-med'),
              onTap: onBliMed,
              dy: 0,
              scale: .95,
              child: CssBox(
                height: 28,
                radius: BorderRadius.circular(999),
                bg: const [
                  CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                ],
                shadows: const [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                  CssShadow(0, 4, 0, 0, Color(0xFFB8461C)),
                  CssShadow(0, 8, 14, -6, Color.fromRGBO(242, 109, 61, .8)),
                ],
                child: Center(child: Text(A3PoengCopy.a3_poeng_liga_bli_med, style: inter(11.5, weight: FontWeight.w800))),
              ),
            ),
          ],
        ],
      ),
    );
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, 10 * (1 - e), 0)..scaleByDouble(.9 + .1 * e, .9 + .1 * e, 1, 1),
          child: Stack(
            key: const Key('liga-boble'),
            clipBehavior: Clip.none,
            children: [
              CssBox(
                radius: BorderRadius.circular(14),
                shadows: const [
                  CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .34)),
                  CssShadow(0, 12, 22, -12, Color.fromRGBO(0, 0, 0, .75)),
                ],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: blur ? BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: kort) : kort,
                ),
              ),
              if (!under)
                Positioned(
                  left: hale,
                  bottom: -5,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, .1),
                        border: Border(right: BorderSide(color: Color.fromRGBO(255, 255, 255, .14)), bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .14))),
                      ),
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

class _GlassKnapp extends StatelessWidget {
  const _GlassKnapp({super.key, required this.onTap, required this.child, this.width, this.height = 40});
  final VoidCallback onTap;
  final Widget child;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 0,
    scale: .94,
    child: CssBox(
      width: width,
      height: height,
      radius: BorderRadius.circular(999),
      bg: const [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .24), Color.fromRGBO(255, 255, 255, .08)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .38)),
        CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(0, 0, 0, .22)),
        CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 0, 0, .6)),
      ],
      padding: width == null ? const EdgeInsets.symmetric(horizontal: 14) : null,
      child: Center(child: child),
    ),
  );
}

// ── The sheet ─────────────────────────────────────────────────────────────

/// The sheet's glass (`.14 → .05`, white .18, top light .22, the drop).
const List<CssBg> _glassBg = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
];
const List<CssShadow> _glassSh = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
  CssShadow(0, 18, 30, -18, Color.fromRGBO(4, 18, 26, .8)),
];

/// The table (L8000–8011): PL. / KLATRER / POENG I {MÅNED}, then the rows —
/// medals for the top three, your row in orange glass, points in mint.
class _Tabell extends StatelessWidget {
  const _Tabell({required this.rader, required this.ownId, required this.maaned});

  final List<LeagueStanding> rader;
  final int? ownId;
  final String? maaned;

  static const List<List<Color>> _med = [
    [Color(0xFFFFE9A3), Color(0xFFF2C14E), Color(0xFFC9971F)],
    [Color(0xFFFFFFFF), Color(0xFFC9D3D7), Color(0xFF94A3A9)],
    [Color(0xFFFBD2AE), Color(0xFFD98E52), Color(0xFFA6602E)],
  ];
  static const List<Color> _medC = [Color(0xFF5A3D06), Color(0xFF3A4A50), Color(0xFF5A2F10)];
  static const List<List<Color>> _av = [
    [Color(0xFF4FA3B3), kAeTeal],
    [Color(0xFF7FE6C6), Color(0xFF2FB893)],
    [Color(0xFF9DB8C4), Color(0xFF5E7F8C)],
    [Color(0xFF6FB6C4), Color(0xFF2A6272)],
    [Color(0xFFC7B59A), Color(0xFF8C7A5E)],
  ];

  @override
  Widget build(BuildContext context) {
    final kol = inter(9, weight: FontWeight.w800, em: .12, color: const Color.fromRGBO(255, 255, 255, .55));
    return CssBox(
      key: const Key('liga-tabell'),
      radius: BorderRadius.circular(24),
      bg: _glassBg,
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
      shadows: _glassSh,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 7),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .14))),
            ),
            child: Row(
              children: [
                SizedBox(width: 22, child: Text(A3PoengCopy.a3_poeng_liga_pl, style: kol)),
                const SizedBox(width: 10),
                Expanded(child: Text(A3PoengCopy.a3_poeng_liga_klatrer, style: kol)),
                Text(A3PoengCopy.a3_poeng_liga_poeng_i(maaned), style: kol),
              ],
            ),
          ),
          if (rader.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                A3PoengCopy.a3_poeng_liga_tom,
                textAlign: TextAlign.center,
                style: inter(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6)),
              ),
            ),
          for (final (i, r) in rader.indexed)
            Builder(
              builder: (context) {
                final deg = r.userId == ownId;
                final med = r.rank <= 3;
                final m = (r.rank - 1).clamp(0, 2);
                final del = r.label.split(' · ');
                // `margin: 2px -6px 0`: the row's own tint reaches 6px past the
                // table's padding on both sides; the content stays in line.
                return Padding(
                  key: Key('liga-rad-${r.rank}'),
                  padding: const EdgeInsets.only(top: 2),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (deg)
                        const Positioned(
                          left: -6,
                          right: -6,
                          top: 0,
                          bottom: 0,
                          child: CssBox(
                            radius: BorderRadius.all(Radius.circular(16)),
                            bg: [
                              CssLinear(180, [Color.fromRGBO(242, 109, 61, .3), Color.fromRGBO(242, 109, 61, .12)]),
                            ],
                            shadows: [
                              CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(242, 109, 61, .6)),
                              CssShadow(0, 0, 18, -4, Color.fromRGBO(242, 109, 61, .5)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: med
                                  ? CssBox(
                                      width: 26,
                                      height: 26,
                                      radius: BorderRadius.circular(13),
                                      bg: [CssRadial(_med[m], stops: const [0, .58, 1], cx: .34, cy: .28)],
                                      shadows: const [
                                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
                                        CssShadow.inset(0, -2, 3, 0, Color.fromRGBO(0, 0, 0, .18)),
                                        CssShadow(0, 3, 6, -2, Color.fromRGBO(35, 32, 29, .45)),
                                      ],
                                      child: Center(child: Text('${r.rank}', style: jakarta(12, color: _medC[m]))),
                                    )
                                  : Text(
                                      '${r.rank}',
                                      textAlign: TextAlign.center,
                                      style: aeTab(jakarta(13, color: deg ? const Color(0xFFFFC8A8) : const Color.fromRGBO(255, 255, 255, .6))),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            CssBox(
                              width: 36,
                              height: 36,
                              radius: BorderRadius.circular(18),
                              bg: [CssLinear(160, deg ? const [Color(0xFFF68450), Color(0xFFE65A28)] : _av[i % _av.length])],
                              shadows: const [
                                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                                CssShadow.inset(0, -3, 4, 0, Color.fromRGBO(0, 0, 0, .18)),
                                CssShadow(0, 0, 0, 2, Color.fromRGBO(255, 255, 255, .85)),
                                CssShadow(0, 5, 9, -3, Color.fromRGBO(0, 0, 0, .5)),
                              ],
                              child: Center(
                                child: Text(
                                  del.first.isEmpty ? '?' : del.first[0].toUpperCase(),
                                  style: jakarta(14).copyWith(shadows: const [Shadow(color: Color.fromRGBO(0, 0, 0, .25), offset: Offset(0, 1), blurRadius: 1)]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(del.first, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(13.5, weight: FontWeight.w800)),
                                  if ((r.bydel ?? (del.length > 1 ? del[1] : '')).isNotEmpty)
                                    Text(r.bydel ?? del[1], style: inter(11, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .6))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(A4MegCopy.nf(r.points), style: aeTab(jakarta(14.5, em: -.01, color: const Color(0xFF7FF0CB)))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// «Månedens premier» (L8013–8022): gold-lit glass, the trophy key, the
/// three medals and «4–10», «Se månedsslutten».
class _Premier extends StatelessWidget {
  const _Premier({required this.onSeremoni});
  final VoidCallback onSeremoni;

  @override
  Widget build(BuildContext context) {
    Widget medalje(int n, List<Color> c, Color fg) => CssBox(
      width: 28,
      height: 28,
      radius: BorderRadius.circular(14),
      bg: [CssRadial(c, stops: const [0, .58, 1], cx: .34, cy: .28)],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
        CssShadow.inset(0, -2, 3, 0, Color.fromRGBO(0, 0, 0, .2)),
        CssShadow(0, 4, 8, -3, Color.fromRGBO(0, 0, 0, .5)),
      ],
      child: Center(child: Text('$n', style: jakarta(12.5, color: fg))),
    );
    const rader = A3PoengCopy.a3_poeng_liga_premie_liste;
    return CssBox(
      key: const Key('liga-premier'),
      radius: BorderRadius.circular(24),
      clip: true,
      bg: const [
        CssRadial([Color.fromRGBO(242, 193, 78, .2), Color.fromRGBO(242, 193, 78, 0)], stops: [0, .7], rx: .8, ry: .6, cx: .85, cy: 0),
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
      ],
      border: Border.all(color: const Color.fromRGBO(242, 193, 78, .32)),
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
        CssShadow(0, 0, 30, -12, Color.fromRGBO(242, 193, 78, .4)),
        CssShadow(0, 22, 38, -18, Color.fromRGBO(4, 18, 26, .8)),
      ],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CssBox(
                width: 42,
                height: 42,
                radius: BorderRadius.all(Radius.circular(14)),
                bg: [
                  CssLinear(160, [Color(0xFFF68450), Color(0xFFE65A28)]),
                ],
                shadows: [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                  CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(150, 40, 10, .35)),
                  CssShadow(0, 9, 14, -7, Color.fromRGBO(3, 16, 24, .8)),
                ],
                child: Center(child: AeIkon('M8 4h8v5a4 4 0 0 1-8 0zM8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4M12 13v4M9 20h6', size: 21, stroke: 2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(A3PoengCopy.a3_poeng_liga_maanedens, style: jakarta(16, em: -.02)),
                    const SizedBox(height: 1),
                    Text(A3PoengCopy.a3_poeng_liga_kan_ikke, style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFFF2C14E))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final (i, (n, c, fg)) in [
            (1, const [Color(0xFFFFE9A3), Color(0xFFF2C14E), Color(0xFFC9971F)], const Color(0xFF5A3D06)),
            (2, const [Color(0xFFFFFFFF), Color(0xFFC9D3D7), Color(0xFF94A3A9)], const Color(0xFF3A4A50)),
            (3, const [Color(0xFFFBD2AE), Color(0xFFD98E52), Color(0xFFA6602E)], const Color(0xFF5A2F10)),
          ].indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                medalje(n, c, fg),
                const SizedBox(width: 11),
                Expanded(child: Text(_uten(rader[i]), style: inter(13, weight: FontWeight.w700, height: 1.4, color: const Color(0xFFF5F3EF)))),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              CssBox(
                height: 24,
                radius: BorderRadius.circular(999),
                bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .1))],
                shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .18))],
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Center(child: Text('4–10', style: aeTab(inter(11, weight: FontWeight.w800, color: const Color(0xFFCFE3E9))))),
              ),
              const SizedBox(width: 11),
              Expanded(child: Text(_uten(rader.length > 3 ? rader[3] : ''), style: inter(13, weight: FontWeight.w700, color: const Color(0xFFDCE9EC)))),
            ],
          ),
          const SizedBox(height: 14),
          AePress(
            key: const Key('liga-seremoni'),
            onTap: onSeremoni,
            dy: 2,
            child: CssBox(
              height: 38,
              radius: BorderRadius.circular(999),
              bg: const [
                CssLinear(180, [Color.fromRGBO(130, 242, 210, .3), Color.fromRGBO(92, 224, 184, .1)]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(4, 30, 26, .32)),
                CssShadow(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .38)),
                CssShadow(0, 9, 12, -7, Color.fromRGBO(3, 16, 24, .85)),
              ],
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(A3PoengCopy.a3_poeng_liga_se_slutt, style: inter(12.5, weight: FontWeight.w800, color: kAeMint)),
                  const SizedBox(width: 6),
                  const AeIkon('M9 5l7 7-7 7', size: 11, stroke: 3.2, color: kAeMint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// «1. Kveld på Fløyen …» → «Kveld på Fløyen …».
  static String _uten(String s) => s.replaceFirst(RegExp(r'^\s*[\d–-]+\.?\s*'), '');
}

class _Tile extends StatelessWidget {
  const _Tile({required this.farger, required this.d});
  final List<Color> farger;
  final String d;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 38,
    height: 38,
    radius: BorderRadius.circular(13),
    bg: [CssLinear(160, farger)],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
      CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(4, 20, 28, .4)),
      CssShadow(0, 9, 12, -6, Color.fromRGBO(8, 24, 32, .6)),
    ],
    child: Center(child: AeIkon(d, size: 17, stroke: 2.1)),
  );
}

/// The glass rows under the table («Navn i ligaen», join / leave).
class _GlassRad extends StatelessWidget {
  const _GlassRad({super.key, required this.tile, required this.tittel, this.under, required this.onTap});
  final Widget tile;
  final String tittel;
  final String? under;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 0,
    scale: .985,
    child: CssBox(
      radius: BorderRadius.circular(20),
      bg: _glassBg,
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
      shadows: _glassSh,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          tile,
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tittel, style: inter(13.5, weight: FontWeight.w800)),
                if (under != null) ...[
                  const SizedBox(height: 2),
                  Text(under!, style: inter(11, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .62))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 11),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(255, 255, 255, .12),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
            ),
            child: const Center(child: AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3)),
          ),
        ],
      ),
    ),
  );
}
