import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_kit.dart';
import '../kit/svg_sti.dart';
import '../meg/a3_services.dart' show a3Pref;
import '../meg/a3_services.dart';
import '../meg/meg_ark.dart';
import '../meg/meg_copy_a4.dart';
import '../meg/meg_nav.dart';
import '../meg/meg_sheets.dart';
import 'poeng_copy.dart';

/// Fløyen-ligaen (`erLigaSide`, L7771–7839 in `Ærend Kunde Launch.dc.html`,
/// design px): the night header with the aurora, «Vilkår», your place, and
/// the month's top ten climbing the Fløyen slope (you in orange, the top
/// three mint); the cream sheet — «Hele Bergen» / «Din bydel» on a springing
/// thumb, the table (medals for the top three, your row lit), «Månedens
/// premier» with «Se månedsslutten», «Navn i ligaen», and join / leave.
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
  bool _bydel = false;
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
    final updated = await MegSheets.ligaNavn(context, api: _api, league: l, firstName: _fornavn, bydel: l.bydel ?? A4MegCopy.a4_meg_bydel);
    if (!mounted || updated == null) return;
    showBergenToast(context, l.optedIn ? A4MegCopy.a4_meg_lagret : A3PoengCopy.a3_poeng_liga_med_toast, icon: Icons.check_rounded);
    _load();
  }

  /// `ligaAv`: what leaving means, «Meld meg av».
  Future<void> _av() async {
    final ok = await showMegArk<bool>(
      context,
      key: const Key('liga-av-sheet'),
      title: A3PoengCopy.a3_poeng_liga_av_title,
      subtitle: A3PoengCopy.a3_poeng_liga_av_linje,
      body: (ctx, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegArkRow(title: A3PoengCopy.a3_poeng_liga_av_poeng, sub: A3PoengCopy.a3_poeng_liga_av_poeng_sub),
          MegArkRow(title: A3PoengCopy.a3_poeng_liga_av_premie, sub: A3PoengCopy.a3_poeng_liga_av_premie_sub),
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

  void _vilkaar() => showMegArk<void>(
    context,
    title: A3PoengCopy.a3_poeng_liga_vilkaar_title,
    subtitle: A3PoengCopy.a3_poeng_liga_vilkaar_linje,
    body: (ctx, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final r in A3PoengCopy.a3_poeng_liga_vilkaar_rader) MegArkRow(title: r[0], sub: r[1])],
    ),
  );

  void _seremoni() => showMegArk<void>(
    context,
    title: A3PoengCopy.a3_poeng_liga_seremoni_title,
    subtitle: A3PoengCopy.a3_poeng_liga_seremoni_sub,
    body: (ctx, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final p in A3PoengCopy.a3_poeng_liga_premie_liste) MegArkRow(title: p)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = _league;
    final med = l?.optedIn == true;
    final rows = _bydel ? (l?.bydelStandings ?? const <LeagueStanding>[]) : (l?.top ?? const <LeagueStanding>[]);
    final ownId = l?.own?.userId;
    final plass = med && l?.own != null ? A3PoengCopy.a3_poeng_liga_min_plass(l!.own!.rank, l.displayName ?? _fornavn) : A3PoengCopy.a3_poeng_liga_ute;
    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: LfFrame(
        child: Builder(
          builder: (context) {
            final top = MediaQuery.paddingOf(context).top;
            final hode = 250 + top - 12;
            return AeOnce(
              kind: AeInn.skjermInn,
              ms: 340,
              curve: const Cubic(.2, .9, .3, 1),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: hode,
                    child: _Hode(top: top, plass: plass, klatrere: l?.top ?? const [], ownId: ownId, onTilbake: () => Navigator.of(context).maybePop(), onVilkaar: _vilkaar),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: hode - 4,
                    bottom: 0,
                    child: CssBox(
                      radius: const BorderRadius.vertical(top: Radius.circular(28)),
                      clip: true,
                      bg: const [
                        CssLinear(180, [Color(0xFFFCFBF8), Color(0xFFF5F3EF)]),
                      ],
                      shadows: const [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .55)),
                        CssShadow(0, -1, 0, 0, Color.fromRGBO(35, 32, 29, .1)),
                        CssShadow(0, -12, 18, -10, Color.fromRGBO(18, 28, 38, .4)),
                        CssShadow(0, -34, 52, -26, Color.fromRGBO(18, 28, 38, .5)),
                      ],
                      child: _loading
                          ? const Center(child: CircularProgressIndicator(color: BergenTokens.teal))
                          : ListView(
                              key: const Key('liga-list'),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
                              children: [
                                _Vender(bydel: _bydel, onAlle: () => setState(() => _bydel = false), onBydel: () => setState(() => _bydel = true)),
                                const SizedBox(height: 12),
                                _Tabell(rader: rows, ownId: ownId, medaljer: !_bydel, maaned: l?.month),
                                const SizedBox(height: 14),
                                _Premier(onSeremoni: _seremoni),
                                const SizedBox(height: 12),
                                _HvitRad(
                                  key: const Key('liga-navn'),
                                  tile: const _Tile(farger: [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], d: 'M12 4.4a3.6 3.6 0 1 0 .01 0zM4.8 20c1.2-3.8 3.8-5.8 7.2-5.8s6 2 7.2 5.8'),
                                  tittel: A3PoengCopy.a3_poeng_liga_navn_rad(med ? (l?.displayName ?? _fornavn) : A3PoengCopy.a3_poeng_liga_ikke_valgt),
                                  under: med ? A3PoengCopy.a3_poeng_liga_syn(_syn(l?.visibility)) : A3PoengCopy.a3_poeng_liga_navn_ute,
                                  onTap: _navn,
                                ),
                                const SizedBox(height: 10),
                                _HvitRad(
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

/// The night header (`height:250px`): the aurora (`sway 9s`), two stars, the
/// back key and «Vilkår», the title, your place and the slope.
class _Hode extends StatelessWidget {
  const _Hode({required this.top, required this.plass, required this.klatrere, required this.ownId, required this.onTilbake, required this.onVilkaar});

  final double top;
  final String plass;
  final List<LeagueStanding> klatrere;
  final int? ownId;
  final VoidCallback onTilbake;
  final VoidCallback onVilkaar;

  static final Path _nordlys = svgSti('M0 96 C80 44 170 78 250 34 C310 2 356 16 410 -10');
  static final Path _sti = svgSti('M20 120 C76 112 130 96 184 72 C240 48 294 30 346 10');
  static const List<double> _xs = [318, 288, 258, 226, 196, 166, 136, 106, 74, 40];
  static const List<double> _ys = [12, 22, 32, 44, 56, 68, 82, 96, 106, 114];

  @override
  Widget build(BuildContext context) {
    final dy = top - 12;
    final k = klatrere.take(10).toList();
    return ClipRect(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F1F2B), Color(0xFF1A3345), Color(0xFF23405C), Color(0xFF1E4F5C)],
                  stops: [0, .44, .74, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: -16,
            top: -14 + dy,
            width: 390,
            height: 120,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: LfLoop(
                  builder: (context, t, _) {
                    final q = (t / 9000) % 1.0;
                    return Opacity(
                      opacity: .75,
                      child: Transform.translate(
                        offset: Offset(kf(q, const [0, .5, 1], const [0, 9, 0], cssEaseInOut), 0),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.skewX(rad(kf(q, const [0, .5, 1], const [-4, 3, -4], cssEaseInOut))),
                          child: ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: CustomPaint(size: const Size(390, 120), painter: _Strek(_nordlys, 26)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(left: 390 * .18, top: 20 + dy, child: const _Stjerne(.85)),
          Positioned(left: 390 * .72, top: 15 + dy, child: const _Stjerne(.7)),
          Positioned(
            left: 16,
            right: 16,
            top: top,
            child: Row(
              children: [
                _GlassKnapp(
                  key: const Key('liga-tilbake'),
                  onTap: onTilbake,
                  width: 40,
                  child: const AeIkon('M15 6l-6 6 6 6', size: 15, stroke: 2.2, color: Color(0xFFF5F3EF)),
                ),
                const Spacer(),
                _GlassKnapp(
                  key: const Key('liga-vilkaar'),
                  onTap: onVilkaar,
                  height: 34,
                  child: Text(
                    A3PoengCopy.a3_poeng_liga_vilkaar,
                    style: inter(12, weight: FontWeight.w800, color: const Color(0xFFF5F3EF)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: top + 46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AeOnce(
                  kind: AeInn.ord,
                  ms: 900,
                  curve: cssEaseOut,
                  child: Text(A3PoengCopy.a3_poeng_liga_title, style: jakarta(25, em: -.03, color: const Color(0xFFF5F3EF))),
                ),
                const SizedBox(height: 3),
                Text(
                  plass,
                  key: const Key('liga-plass'),
                  style: inter(12, weight: FontWeight.w700, color: const Color(0xFF9FB6C2)),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 118 + dy,
            width: 358,
            height: 124,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: _Stiplet(_sti))),
                for (final (i, s) in k.indexed)
                  Positioned(
                    left: (30 + (_xs[i] - 40) * .86) - 40,
                    top: _ys[i] - (s.userId == ownId ? 22 : 15) - 14,
                    width: 80,
                    child: _Klatrer(navn: s.label, egen: s.userId == ownId, topp: i < 3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(410, 0), const [kAeMint, Color(0xFF9C7BE8)]),
  );

  @override
  bool shouldRepaint(_Strek old) => false;
}

/// The slope: `rgba(255,255,255,.28)`, 2 px, dashed 3 / 5.
class _Stiplet extends CustomPainter {
  _Stiplet(this.p);
  final Path p;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color.fromRGBO(255, 255, 255, .28);
    for (final m in p.computeMetrics()) {
      for (double d = 0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Stiplet old) => false;
}

class _Stjerne extends StatelessWidget {
  const _Stjerne(this.a);
  final double a;

  @override
  Widget build(BuildContext context) => Container(
    width: 2,
    height: 2,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(220, 233, 236, a)),
  );
}

/// A climber on the slope: the dot (22 px and glowing orange for you, mint
/// for the top three) over the name.
class _Klatrer extends StatelessWidget {
  const _Klatrer({required this.navn, required this.egen, required this.topp});
  final String navn;
  final bool egen;
  final bool topp;

  @override
  Widget build(BuildContext context) {
    final s = egen ? 22.0 : 15.0;
    final farger = egen ? const [Color(0xFFFCAE84), Color(0xFFE95C2C)] : (topp ? const [Color(0xFFA8F0DB), Color(0xFF3FC7A2)] : const [Color(0xFFC8D8E0), Color(0xFF8CA3AF)]);
    Widget prikk = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.32, -.44), radius: .9, colors: farger),
        boxShadow: [
          const BoxShadow(color: Color.fromRGBO(255, 255, 255, .9), spreadRadius: 1.5),
          const BoxShadow(color: Color.fromRGBO(0, 0, 0, .55), offset: Offset(0, 5), blurRadius: 4.5, spreadRadius: -2),
          if (egen) const BoxShadow(color: Color.fromRGBO(242, 109, 61, .85), blurRadius: 7),
        ],
      ),
    );
    if (egen) {
      final p = prikk;
      prikk = RepaintBoundary(
        child: LfLoop(
          child: p,
          builder: (context, t, child) => Opacity(opacity: kf((t / 2800) % 1.0, const [0, .5, 1], const [.7, 1, .7], cssEaseInOut), child: child),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        prikk,
        const SizedBox(height: 2),
        Text(
          navn.split(' · ').first,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: inter(9.5, weight: FontWeight.w800, color: egen ? Colors.white : const Color(0xFFCFE3E9)).copyWith(
            shadows: const [Shadow(color: Color.fromRGBO(0, 0, 0, .6), blurRadius: 3, offset: Offset(0, 1))],
          ),
        ),
      ],
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

/// «Hele Bergen» / «Din bydel» on the sunken track with the springing teal
/// thumb (`.45s cubic-bezier(.34,1.56,.64,1)`).
class _Vender extends StatelessWidget {
  const _Vender({required this.bydel, required this.onAlle, required this.onBydel});
  final bool bydel;
  final VoidCallback onAlle;
  final VoidCallback onBydel;

  @override
  Widget build(BuildContext context) => CssBox(
    height: 48,
    radius: BorderRadius.circular(999),
    bg: const [CssSolid(Color.fromRGBO(30, 79, 92, .08))],
    shadows: const [CssShadow.inset(0, 1, 3, 0, Color.fromRGBO(30, 79, 92, .2)), CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .85))],
    padding: const EdgeInsets.all(4),
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          AeTw(
            v: bydel ? 1 : 0,
            ms: 450,
            curve: const Cubic(.34, 1.56, .64, 1),
            builder: (f) => Positioned(
              left: f * box.maxWidth / 2,
              top: 0,
              bottom: 0,
              width: box.maxWidth / 2,
              child: const CssBox(
                radius: BorderRadius.all(Radius.circular(999)),
                bg: [
                  CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
                ],
                shadows: [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
                  CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(4, 20, 28, .35)),
                  CssShadow(0, 8, 12, -6, Color.fromRGBO(8, 24, 32, .5)),
                ],
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, (t, on)) in [(A3PoengCopy.a3_poeng_liga_hele, !bydel), (A3PoengCopy.a3_poeng_liga_bydel, bydel)].indexed)
                Expanded(
                  child: GestureDetector(
                    key: Key(i == 0 ? 'liga-hele' : 'liga-din-bydel'),
                    behavior: HitTestBehavior.opaque,
                    onTap: i == 0 ? onAlle : onBydel,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: inter(12.5, weight: FontWeight.w800, color: on ? Colors.white : const Color(0xFF57534B)),
                        child: Text(t),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// The table (L7795–7808): PL. / KLATRER / POENG I {MÅNED}, then the rows —
/// medals for the top three in «Hele Bergen», your row in orange.
class _Tabell extends StatelessWidget {
  const _Tabell({required this.rader, required this.ownId, required this.medaljer, required this.maaned});

  final List<LeagueStanding> rader;
  final int? ownId;
  final bool medaljer;
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
    final kol = inter(9, weight: FontWeight.w800, em: .12, color: const Color(0xFF6E6862));
    return CssBox(
      key: const Key('liga-tabell'),
      radius: BorderRadius.circular(24),
      bg: const [
        CssLinear(180, [Colors.white, Color(0xFFFAF8F4)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
        CssShadow(0, 0, 0, 1, Color.fromRGBO(35, 32, 29, .04)),
        CssShadow(0, 18, 30, -18, Color.fromRGBO(8, 24, 32, .45)),
      ],
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 7),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color.fromRGBO(35, 32, 29, .1))),
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
                style: inter(12.5, weight: FontWeight.w700, color: const Color(0xFF8C847C)),
              ),
            ),
          for (final (i, r) in rader.indexed)
            Builder(
              builder: (context) {
                final deg = r.userId == ownId;
                final med = medaljer && i < 3;
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
                        Positioned(
                          left: -6,
                          right: -6,
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(242, 109, 61, .12), Color.fromRGBO(242, 109, 61, .05)]),
                              border: Border.all(color: const Color.fromRGBO(242, 109, 61, .35), width: 1.5),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: med
                                  ? Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(center: const Alignment(-.32, -.44), radius: .9, colors: _med[i], stops: const [0, .58, 1]),
                                        boxShadow: const [BoxShadow(color: Color.fromRGBO(35, 32, 29, .45), offset: Offset(0, 3), blurRadius: 3, spreadRadius: -2)],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('${r.rank}', style: jakarta(12, color: _medC[i])),
                                    )
                                  : Text(
                                      '${r.rank}',
                                      textAlign: TextAlign.center,
                                      style: aeTab(jakarta(13, color: deg ? const Color(0xFFC2461A) : const Color(0xFF8C847C))),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: const Alignment(-.34, -.94),
                                  end: const Alignment(.34, .94),
                                  colors: deg ? const [Color(0xFFF68450), Color(0xFFE65A28)] : _av[i % _av.length],
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.white, spreadRadius: 2),
                                  BoxShadow(color: Color.fromRGBO(35, 32, 29, .4), offset: Offset(0, 5), blurRadius: 4.5, spreadRadius: -3),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                del.first.isEmpty ? '?' : del.first[0].toUpperCase(),
                                style: jakarta(14).copyWith(
                                  shadows: const [Shadow(color: Color.fromRGBO(0, 0, 0, .25), offset: Offset(0, 1), blurRadius: 1)],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    del.first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: inter(13.5, weight: FontWeight.w800, color: kAeInk),
                                  ),
                                  if ((r.bydel ?? (del.length > 1 ? del[1] : '')).isNotEmpty) Text(r.bydel ?? del[1], style: inter(11, color: const Color(0xFF8C847C))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(A4MegCopy.nf(r.points), style: aeTab(jakarta(14.5, em: -.01, color: kAeTeal))),
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

/// «Månedens premier» (L7809–7822): the teal card, the trophy key, the three
/// medals and «4–10», «Se månedsslutten».
class _Premier extends StatelessWidget {
  const _Premier({required this.onSeremoni});
  final VoidCallback onSeremoni;

  @override
  Widget build(BuildContext context) {
    Widget medalje(int n, List<Color> c, Color fg) => Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.32, -.44), radius: .9, colors: c, stops: const [0, .58, 1]),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, .5), offset: Offset(0, 4), blurRadius: 4, spreadRadius: -3)],
      ),
      alignment: Alignment.center,
      child: Text('$n', style: jakarta(12.5, color: fg)),
    );
    final rader = A3PoengCopy.a3_poeng_liga_premie_liste;
    return CssBox(
      key: const Key('liga-premier'),
      radius: BorderRadius.circular(24),
      bg: const [
        CssLinear(160, [Color(0xFF245C6B), Color(0xFF1A4654), Color(0xFF123440)], [0, .55, 1]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .2)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .06)),
        CssShadow(0, 22, 38, -18, Color.fromRGBO(15, 31, 43, .7)),
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
                    Text(
                      A3PoengCopy.a3_poeng_liga_kan_ikke,
                      style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF9FE0C8)),
                    ),
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
                Expanded(
                  child: Text(
                    _uten(rader[i]),
                    style: inter(13, weight: FontWeight.w700, height: 1.4, color: const Color(0xFFF5F3EF)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .1)),
                alignment: Alignment.center,
                child: Text(
                  '4–10',
                  style: aeTab(inter(11, weight: FontWeight.w800, color: const Color(0xFFCFE3E9))),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _uten(rader.length > 3 ? rader[3] : ''),
                  style: inter(13, weight: FontWeight.w700, color: const Color(0xFFDCE9EC)),
                ),
              ),
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
                  Text(
                    A3PoengCopy.a3_poeng_liga_se_slutt,
                    style: inter(12.5, weight: FontWeight.w800, color: kAeMint),
                  ),
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

/// The white rows under the table («Navn i ligaen», join / leave).
class _HvitRad extends StatelessWidget {
  const _HvitRad({super.key, required this.tile, required this.tittel, this.under, required this.onTap});
  final Widget tile;
  final String tittel;
  final String? under;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 0,
    scale: .98,
    child: CssBox(
      radius: BorderRadius.circular(20),
      bg: const [
        CssLinear(180, [Colors.white, Color(0xFFFAF8F4)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
        CssShadow(0, 0, 0, 1, Color.fromRGBO(35, 32, 29, .04)),
        CssShadow(0, 12, 20, -14, Color.fromRGBO(8, 24, 32, .45)),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          tile,
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tittel,
                  style: inter(13.5, weight: FontWeight.w800, color: kAeInk),
                ),
                if (under != null) ...[const SizedBox(height: 2), Text(under!, style: inter(10.5, height: 1.35, color: const Color(0xFF6E6862)))],
              ],
            ),
          ),
          const SizedBox(width: 11),
          const CssBox(
            width: 30,
            height: 30,
            radius: BorderRadius.all(Radius.circular(999)),
            bg: [
              CssLinear(180, [Colors.white, Color(0xFFE9EEED)]),
            ],
            shadows: [CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(30, 79, 92, .14)), CssShadow(0, 4, 8, -4, Color.fromRGBO(8, 24, 32, .4))],
            child: Center(child: AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3, color: kAeTeal)),
          ),
        ],
      ),
    ),
  );
}
