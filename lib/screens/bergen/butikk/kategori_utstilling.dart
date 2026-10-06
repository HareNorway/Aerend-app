import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kit/bergen_kit.dart' show BergenCssShadow, showBergenToast;
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_motion.dart';
import '../sok/sok_oversikt.dart' show SokIkon;
import 'kategori_kort.dart';

// ── Gaver-kategori (L5937) and Mote-utstilling (L6015) ──────────────────────
// Both pages are curated: gift shops with their quotes, the week's
// exhibition. Nothing in the API describes them yet.
//
// UI-TEMP: Placeholder data because reference UI currently has no backend/API support.

class _Gavebutikk {
  const _Gavebutikk(
    this.navn,
    this.ini,
    this.bg,
    this.heroTopp,
    this.eta,
    this.lev,
    this.innpakning,
    this.apenTil,
    this.rating,
    this.sitat,
    this.hvem,
    this.varer,
  );

  final String navn;
  final String ini;
  final Color? bg;
  final Color heroTopp;
  final String eta;
  final String lev;
  final bool innpakning;
  final int apenTil;
  final String rating;
  final String sitat;
  final String hvem;
  final List<(String, int, String)> varer;
}

// UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
const List<_Gavebutikk> _kGavebutikker = [
  _Gavebutikk('Blomsterhjørnet', 'BH', Color(0xFFD9A254), Color(0xFFF7E6C2), '35–45 min', 'Gratis levering', true, 18, '4,9 (48)',
      '«Den som alltid får et smil i døra»', 'Ida, Blomsterhjørnet', [
    ('Bukett «Vågen»', 399, 'blomst'),
    ('Tulipaner, 20 stk', 249, 'blomst'),
    ('Orkidé i potte', 349, 'blomst'),
    ('Kort og bånd', 89, 'kort'),
    ('Sjokolade fra Bergen', 199, 'eske'),
    ('Krans i eukalyptus', 649, 'blomst'),
  ]),
  _Gavebutikk('Gavehuset', 'GH', Color(0xFF1E4F5C), Color(0xFFDCE9EC), '30–45 min', '49 kr', true, 20, '4,6 (57)',
      '«Koppen alle spør hvor er fra»', 'Tor, Gavehuset', [
    ('Sjokoladeeske', 199, 'eske'),
    ('Håndlaget kopp', 279, 'eske'),
    ('Lykt i messing', 549, 'eske'),
    ('Fløibanen for to', 690, 'kort'),
    ('Ullpledd «Ulriken»', 899, 'eske'),
    ('Byggesett båt', 329, 'eske'),
  ]),
  _Gavebutikk('Papirbutikken', 'PB', null, Color(0xFFF4F1EA), '35–50 min', '45 kr', false, 17, '4,7 (61)',
      '«Papiret som tåler bergensk fuktighet»', 'Live, Papirbutikken', [
    ('Kort og bånd', 89, 'kort'),
    ('Notatbok i lin', 249, 'eske'),
    ('Fyllepenn', 590, 'eske'),
    ('Kalender 2027 · Bergen', 299, 'eske'),
  ]),
];

const List<String> _kAnledninger = ['Bursdag', 'Jul', 'Takk', 'Nyfødt', 'Bryllup', 'Jubileum', 'Bare fordi'];

class _Gave {
  const _Gave(this.navn, this.pris, this.type, this.but);

  final String navn;
  final int pris;
  final String type;
  final _Gavebutikk but;

  String get prisTekst => '${_tusen(pris)} kr';

  /// `tint(v)`.
  Gradient get tint => switch (type) {
    'blomst' => const RadialGradient(
      center: Alignment(-.2, -.3),
      colors: [Color(0xFFF9D9C4), Color(0xFFE08A6A), Color(0xFF8C3C2C)],
      stops: [0, .55, 1],
    ),
    'kort' => cssLinear(160, const [Color(0xFFFFFFFF), Color(0xFFEDE6D8)]),
    _ => cssLinear(160, [but.heroTopp, const Color(0xFFB8903F)]),
  };

  /// `radius(v)`, as a fraction of the shape's size for the round ones.
  BorderRadius radius(double w) => switch (type) {
    'blomst' => BorderRadius.only(
      topLeft: Radius.elliptical(w / 2, w / 2),
      topRight: Radius.elliptical(w / 2, w / 2),
      bottomLeft: Radius.elliptical(w * .4, w * .4),
      bottomRight: Radius.elliptical(w * .4, w * .4),
    ),
    'kort' => BorderRadius.circular(6 * w / 60),
    _ => BorderRadius.circular(14 * w / 60),
  };

  bool get baand => type == 'eske';
}

String _tusen(int n) {
  final t = '$n';
  final b = StringBuffer();
  for (var i = 0; i < t.length; i++) {
    if (i > 0 && (t.length - i) % 3 == 0) b.write(' ');
    b.write(t[i]);
  }
  return '$b';
}

final List<_Gave> _kAlleGaver = [
  for (final b in _kGavebutikker)
    for (final v in b.varer) _Gave(v.$1, v.$2, v.$3, b),
];

/// `gaveLev(kl, aapenTil)`.
(String, Color) _gaveLev(int time, int apenTil) {
  if (time < apenTil - 1) return ('Rekker fram i dag', const Color(0xFF7FF0CB));
  if (time < 22) return ('Rekker fram lørdag', const Color(0xFF7FF0CB));
  return ('Lever fra torsdag', rgba(255, 255, 255, .7));
}

/// The glass of the Gaver cards: `linear-gradient(180deg,rgba(255,255,255,
/// .14),rgba(255,255,255,.06))`, `inset 0 1.5px 0 rgba(255,255,255,.28)`,
/// `0 0 0 1px rgba(255,255,255,.18)` and a two-step drop.
BoxDecoration _glass(double s, double r, {bool myk = true}) => BoxDecoration(
  borderRadius: BorderRadius.circular(r),
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [rgba(255, 255, 255, .14), rgba(255, 255, 255, .06)],
  ),
  boxShadow: [
    if (myk)
      BoxShadow(
        color: rgba(4, 18, 26, .85),
        offset: Offset(0, 12 * s),
        blurRadius: onbBlur(18 * s),
        spreadRadius: -12 * s,
      ),
    BoxShadow(color: rgba(4, 18, 26, .3), offset: Offset(0, 3 * s)),
    BoxShadow(color: rgba(4, 18, 26, .45), offset: Offset(0, 2 * s)),
    BoxShadow(color: rgba(255, 255, 255, .18), spreadRadius: 1),
  ],
);

/// The gift's teal well (two radials) with its little 3D shape.
class _Bronn extends StatelessWidget {
  const _Bronn({required this.g, required this.hoyde, required this.form, required this.formTopp});

  final _Gave g;
  final double hoyde;
  final double form;
  final double formTopp;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      height: hoyde * s,
      child: Stack(
        children: [
          const Positioned.fill(child: _BronnBg()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 12 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [rgba(0, 0, 0, .2), rgba(0, 0, 0, 0)],
                ),
              ),
            ),
          ),
          Positioned(
            top: formTopp * s,
            left: 0,
            right: 0,
            child: Center(child: _Form(g: g, w: form)),
          ),
        ],
      ),
    );
  }
}

class _BronnBg extends StatelessWidget {
  const _BronnBg();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -1),
        radius: 1.25,
        colors: [Color(0xFF3C7788), Color(0xFF265A6A), Color(0xFF173E48)],
        stops: [0, .55, 1],
      ),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.2),
          radius: .6,
          colors: [Color.fromRGBO(127, 240, 203, .24), Color.fromRGBO(127, 240, 203, 0)],
          stops: [0, .65],
        ),
      ),
    ),
  );
}

/// The gift itself: a tinted shape with a soft top light and, for a box,
/// the orange ribbon and bow.
class _Form extends StatelessWidget {
  const _Form({required this.g, required this.w, this.bue = false});

  final _Gave g;
  final double w;
  final bool bue;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = g.radius(w * s);
    return SizedBox(
      width: w * s,
      height: w * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: g.tint,
                boxShadow: [
                  BoxShadow(
                    color: bue ? rgba(60, 40, 15, .55) : rgba(0, 10, 16, .6),
                    offset: Offset(0, (bue ? 14 : 6) * s),
                    blurRadius: onbBlur((bue ? 18 : 8) * s),
                    spreadRadius: (bue ? -10 : -5) * s,
                  ),
                ],
              ),
            ),
          ),
          // `inset 0 3px 5px rgba(255,255,255,.6), inset 0 -5px 8px rgba(0,0,0,.14)`.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: r,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [rgba(255, 255, 255, .5), rgba(255, 255, 255, 0), rgba(0, 0, 0, 0), rgba(0, 0, 0, .14)],
                    stops: const [0, .12, .84, 1],
                  ),
                ),
              ),
            ),
          ),
          if (g.baand) ...[
            Positioned(
              left: w * s * .43,
              width: w * s * .14,
              top: 0,
              bottom: 0,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFB9441A), Color(0xFFF26D3D), Color(0xFFB9441A)]),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: w * s * .43,
              height: w * s * .14,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB9441A), Color(0xFFF26D3D), Color(0xFFB9441A)],
                  ),
                ),
              ),
            ),
            if (bue)
              Positioned(
                left: w * s / 2 - 15 * s,
                top: -10 * s,
                width: 30 * s,
                height: 16 * s,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.elliptical(15 * s, 8 * s),
                      bottom: Radius.elliptical(12 * s, 6.4 * s),
                    ),
                    border: Border.all(color: const Color(0xFFE95C2C), width: 4 * s),
                  ),
                ),
              ),
          ],
          if (bue)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: cssLinear(125, const [
                      Color.fromRGBO(255, 255, 255, .55),
                      Color.fromRGBO(255, 255, 255, 0),
                    ], const [0, .38]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _overskrift(BuildContext context, String t, {double topp = 22, double bunn = 10, Widget? hoyre}) {
  final s = context.bs;
  return Padding(
    padding: EdgeInsets.fromLTRB(2 * s, topp * s, 2 * s, bunn * s),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(t, style: bDisplay(context, 16, letterSpacingEm: -.015))),
        ?hoyre,
      ],
    ),
  );
}

// ── Gaver-kategori ──────────────────────────────────────────────────────────

class KatGaverSide extends StatelessWidget {
  const KatGaverSide({super.key, required this.onAegil, required this.onSnart});

  /// "La Ægil finne en gave".
  final VoidCallback onAegil;

  /// The gift sheets come with the store step; until then, "Kommer snart".
  final VoidCallback onSnart;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final time = DateTime.now().hour;
    final idag = [
      for (final g in _kAlleGaver)
        if (_gaveLev(time, g.but.apenTil).$1 == 'Rekker fram i dag') g,
    ].take(5).toList();
    final pop = [_kAlleGaver[0], _kAlleGaver[4], _kAlleGaver[7], _kAlleGaver[14]];
    const antall = [41, 28, 19, 12];
    return Column(
      key: const Key('a1_kat_gaver'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (idag.isNotEmpty) ...[
          _overskrift(context, 'Rekker fram i dag', topp: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(0, 2 * s, 0, 6 * s),
            child: Row(
              children: [
                for (var i = 0; i < idag.length; i++) ...[
                  if (i > 0) SizedBox(width: 10 * s),
                  _IdagKort(g: idag[i], onTap: onSnart),
                ],
              ],
            ),
          ),
        ],
        SizedBox(height: 8 * s),
        OnbPressable(
          key: const Key('a1_kat_gave_aegil'),
          onTap: onAegil,
          pressDy: 0,
          pressScale: .98,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
            decoration: _glass(s, 16 * s, myk: false).copyWith(
              boxShadow: [
                BoxShadow(
                  color: rgba(35, 32, 29, .4),
                  offset: Offset(0, 8 * s),
                  blurRadius: onbBlur(14 * s),
                  spreadRadius: -10 * s,
                ),
                BoxShadow(color: rgba(4, 18, 26, .45), offset: Offset(0, 2 * s)),
                BoxShadow(color: rgba(255, 255, 255, .18), spreadRadius: 1),
              ],
            ),
            child: Row(
              children: [
                Image.asset('assets/images/dashboard/invitation.png', width: 30 * s, height: 30 * s),
                SizedBox(width: 10 * s),
                Expanded(
                  child: Text('La Ægil finne en gave', style: bText(context, 12.5, weight: FontWeight.w800)),
                ),
                Text('›', style: bText(context, 14, color: rgba(255, 255, 255, .55))),
              ],
            ),
          ),
        ),
        _overskrift(
          context,
          'Ukens utstilling',
          topp: 20,
          bunn: 0,
          hoyre: Text(
            'Sveip · 3 butikker',
            style: bText(context, 11, weight: FontWeight.w700, color: rgba(255, 255, 255, .62)),
          ),
        ),
        _GaveUtstilling(time: time, onSnart: onSnart),
        _overskrift(context, 'Anledninger'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: EdgeInsets.only(top: 2 * s, bottom: 4 * s),
          child: Row(
            children: [
              for (var i = 0; i < _kAnledninger.length; i++) ...[
                if (i > 0) SizedBox(width: 6 * s),
                OnbPressable(
                  onTap: onSnart,
                  pressDy: 0,
                  pressScale: .95,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 8 * s),
                    decoration: _glass(s, 999, myk: false),
                    child: Stack(
                      children: [
                        Text(_kAnledninger[i], style: bText(context, 11.5, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        _overskrift(context, 'Butikker i nærheten'),
        for (final b in _kGavebutikker) _GaveButikkRad(b: b, onTap: onSnart),
        _overskrift(context, 'Populært til bursdag i Bergenhus', topp: 14),
        for (var i = 0; i < pop.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: 12 * s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PopKort(g: pop[i], antall: antall[i], time: time, onTap: onSnart)),
                SizedBox(width: 12 * s),
                Expanded(child: _PopKort(g: pop[i + 1], antall: antall[i + 1], time: time, onTap: onSnart)),
              ],
            ),
          ),
      ],
    );
  }
}

class _IdagKort extends StatelessWidget {
  const _IdagKort({required this.g, required this.onTap});

  final _Gave g;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .97,
      child: Container(
        width: 136 * s,
        decoration: _glass(s, 18 * s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Bronn(g: g, hoyde: 96, form: 60, formTopp: 16),
              Padding(
                padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 10 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11.5, weight: FontWeight.w800)),
                    SizedBox(height: 2 * s),
                    Text(g.prisTekst, style: bText(context, 12.5, weight: FontWeight.w800)),
                    SizedBox(height: 2 * s),
                    Text(
                      'Innen 18:15',
                      style: bText(context, 10, weight: FontWeight.w700, color: const Color(0xFF7FF0CB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Ukens utstilling": a snapping rail whose centre card faces you while its
/// neighbours turn and fall back (`gkForm`); it glides on by itself every 7s
/// until touched.
class _GaveUtstilling extends StatefulWidget {
  const _GaveUtstilling({required this.time, required this.onSnart});

  final int time;
  final VoidCallback onSnart;

  @override
  State<_GaveUtstilling> createState() => _GaveUtstillingState();
}

class _GaveUtstillingState extends State<_GaveUtstilling> {
  ScrollController? _rail;
  Timer? _auto;
  bool _tatt = false;
  int _vis = 0;
  double _kortB = 222;

  final List<_Gave> _plukk = [_kAlleGaver[0], _kAlleGaver[6], _kAlleGaver[9], _kAlleGaver[12]];

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 7), (_) {
      final r = _rail;
      if (_tatt || r == null || !r.hasClients) return;
      final nx = (r.offset / _kortB).round() + 1;
      r.animateTo(
        (nx >= _plukk.length ? 0 : nx) * _kortB,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _rail?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    _kortB = (208 + 14) * s;
    _rail ??= ScrollController()
      ..addListener(() {
        final v = ((_rail!.offset / _kortB).round()).clamp(0, _plukk.length - 1);
        if (v != _vis) setState(() => _vis = v);
      });
    final bredde = MediaQuery.sizeOf(context).width;
    final kant = bredde / 2 - 104 * s;
    return Column(
      children: [
        // `margin:0 -16px` — the rail spans the screen.
        Transform.translate(
          offset: Offset(-16 * s, 0),
          child: SizedBox(
            width: bredde,
            height: (16 + 268 + 22) * s,
            child: Listener(
              onPointerDown: (_) => _tatt = true,
              child: ListView.builder(
                controller: _rail,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: _SnapFysikk(_kortB),
                padding: EdgeInsets.fromLTRB(kant, 16 * s, kant, 22 * s),
                itemCount: _plukk.length,
                itemBuilder: (context, i) => Padding(
                  padding: EdgeInsets.only(right: i < _plukk.length - 1 ? 14 * s : 0),
                  child: AnimatedBuilder(
                    animation: _rail!,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _UtstillingKort(g: _plukk[i], time: widget.time, onTap: widget.onSnart),
                    ),
                    builder: (context, child) {
                      final off = _rail!.hasClients ? _rail!.offset : 0.0;
                      final d = (i * _kortB - off) / _kortB;
                      final a = math.min(1.4, d.abs());
                      return Opacity(
                        opacity: 1 - a * .38,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: katPerspektiv(900)
                            ..translateByDouble(-d * 18 * s, a * 14 * s, -a * 90 * s, 1)
                            ..rotateY(-d.clamp(-1.0, 1.0) * 22 * math.pi / 180)
                            ..scaleByDouble(1 - a * .08, 1 - a * .08, 1, 1),
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -6 * s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _plukk.length; i++) ...[
                if (i > 0) SizedBox(width: 5 * s),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: const Cubic(.22, 1, .36, 1),
                  width: (i == _vis ? 18 : 5) * s,
                  height: 5 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3 * s),
                    color: i == _vis ? null : rgba(255, 255, 255, .3),
                    gradient: i == _vis
                        ? const LinearGradient(colors: [Color(0xFFF58A55), Color(0xFFE95C2C)])
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 8 * s),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 2 * s),
          padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 11 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * s),
            color: rgba(255, 255, 255, .08),
            border: Border.all(color: rgba(255, 255, 255, .14)),
          ),
          child: Row(
            children: [
              SokIkon('M7 7h10v10H7zM4 12h3M17 12h3', size: 16 * s, color: const Color(0xFF7FF0CB), stroke: 2),
              SizedBox(width: 10 * s),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _plukk[_vis].but.sitat,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(
                        text: ' — ${_plukk[_vis].but.hvem}',
                        style: TextStyle(color: rgba(255, 255, 255, .55)),
                      ),
                    ],
                  ),
                  style: bText(context, 12, weight: FontWeight.w600, height: 1.4, color: rgba(255, 255, 255, .82)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `scroll-snap-type: x mandatory` on a fixed card pitch.
class _SnapFysikk extends ScrollPhysics {
  const _SnapFysikk(this.pitch, {super.parent});

  final double pitch;

  @override
  _SnapFysikk applyTo(ScrollPhysics? ancestor) => _SnapFysikk(pitch, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    var side = position.pixels / pitch;
    if (velocity < -150) {
      side = side.floorToDouble();
    } else if (velocity > 150) {
      side = side.ceilToDouble();
    } else {
      side = side.roundToDouble();
    }
    final mal = (side * pitch).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((mal - position.pixels).abs() < .5) return null;
    return ScrollSpringSimulation(spring, position.pixels, mal, velocity, tolerance: toleranceFor(position));
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _UtstillingKort extends StatelessWidget {
  const _UtstillingKort({required this.g, required this.time, required this.onTap});

  final _Gave g;
  final int time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lev = _gaveLev(time, g.but.apenTil);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 208 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26 * s),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rgba(255, 255, 255, .16), rgba(255, 255, 255, .06)],
          ),
          border: Border.all(color: rgba(255, 255, 255, .22)),
          boxShadow: [
            BoxShadow(
              color: rgba(4, 18, 26, .9),
              offset: Offset(0, 22 * s),
              blurRadius: onbBlur(34 * s),
              spreadRadius: -20 * s,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 150 * s,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _BronnBg()),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 20 * s,
                      height: 22 * s,
                      child: Center(
                        child: Container(
                          width: 120 * s,
                          height: 22 * s,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.elliptical(60 * s, 11 * s)),
                            gradient: RadialGradient(
                              colors: [rgba(90, 64, 30, .45), rgba(90, 64, 30, 0)],
                              stops: const [0, .72],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 26 * s,
                      left: 0,
                      right: 0,
                      child: Center(
                        // `ikSvev 3.8s ease-in-out infinite`.
                        child: RepaintBoundary(
                          child: KatLoop(
                            durationMs: 3800,
                            child: _Form(g: g, w: 84, bue: true),
                            builder: (context, p, child) => Transform.translate(
                              offset: Offset(0, kf(p, const [0, .5, 1], const [0, -6, 0], Curves.easeInOut) * s),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10 * s,
                      top: 10 * s,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [rgba(255, 255, 255, .14), rgba(255, 255, 255, .06)],
                          ),
                        ),
                        child: Text(lev.$1, style: bText(context, 10, weight: FontWeight.w800, color: lev.$2)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(13 * s, 11 * s, 13 * s, 13 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: bDisplay(context, 15, letterSpacingEm: -.02)),
                    SizedBox(height: 2 * s),
                    Text(
                      g.but.navn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bText(context, 11.5, weight: FontWeight.w600, color: rgba(255, 255, 255, .66)),
                    ),
                    SizedBox(height: 10 * s),
                    Row(
                      children: [
                        Expanded(child: Text(g.prisTekst, style: bDisplay(context, 17, letterSpacingEm: -.02))),
                        KatRundKnapp(size: 40, ikon: 'M12 5v14M5 12h14', ikonPx: 15, strek: 2.8, onTap: onTap),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaveButikkRad extends StatelessWidget {
  const _GaveButikkRad({required this.b, required this.onTap});

  final _Gavebutikk b;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final meta = bText(context, 11, weight: FontWeight.w700, color: rgba(255, 255, 255, .7));
    Widget prikk() => Container(
      width: 3 * s,
      height: 3 * s,
      margin: EdgeInsets.symmetric(horizontal: 6 * s),
      decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(4, 18, 26, .45)),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * s),
      child: OnbPressable(
        onTap: onTap,
        pressDy: 0,
        pressScale: .985,
        child: Container(
          padding: EdgeInsets.all(10 * s),
          decoration: _glass(s, 22 * s).copyWith(
            boxShadow: [
              BoxShadow(
                color: rgba(4, 18, 26, .85),
                offset: Offset(0, 16 * s),
                blurRadius: onbBlur(26 * s),
                spreadRadius: -16 * s,
              ),
              BoxShadow(color: rgba(4, 18, 26, .4), offset: Offset(0, 3 * s), spreadRadius: 2 * s),
              BoxShadow(color: rgba(255, 255, 255, .18), spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54 * s,
                height: 54 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 * s),
                  color: b.bg ?? rgba(255, 255, 255, .16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    bergenInsetTop(radius: 16 * s, height: 2 * s, alpha: .4),
                    Text(b.ini, style: bDisplay(context, 15)),
                  ],
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.navn, style: bDisplay(context, 14, letterSpacingEm: -.01)),
                    SizedBox(height: 3 * s),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 2 * s,
                      children: [
                        Text(b.eta, style: meta),
                        prikk(),
                        Text(b.lev, style: meta.copyWith(color: const Color(0xFF7FF0CB))),
                        prikk(),
                        Text(b.rating, style: meta),
                      ],
                    ),
                  ],
                ),
              ),
              if (b.innpakning)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: rgba(127, 240, 203, .14),
                    border: Border.all(color: rgba(127, 240, 203, .35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SokIkon('M4 11h16v9H4zM12 11v9M3 7h18v4H3z', size: 10 * s, color: const Color(0xFF7FF0CB), stroke: 2.6),
                      SizedBox(width: 4 * s),
                      Text('Innpakning', style: bText(context, 10, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopKort extends StatelessWidget {
  const _PopKort({required this.g, required this.antall, required this.time, required this.onTap});

  final _Gave g;
  final int antall;
  final int time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lev = _gaveLev(time, g.but.apenTil);
    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .97,
      child: Container(
        decoration: _glass(s, 18 * s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Bronn(g: g, hoyde: 100, form: 62, formTopp: 18),
              Padding(
                padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 10 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(g.navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11.5, weight: FontWeight.w800)),
                    SizedBox(height: 2 * s),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(child: Text(g.prisTekst, style: bText(context, 12.5, weight: FontWeight.w800))),
                        Text(
                          '$antall i Bergenhus',
                          style: bText(context, 10, weight: FontWeight.w700, color: rgba(255, 255, 255, .7)),
                        ),
                      ],
                    ),
                    SizedBox(height: 2 * s),
                    Text(lev.$1, style: bText(context, 10, weight: FontWeight.w700, color: lev.$2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mote-utstilling ─────────────────────────────────────────────────────────

class _Plagg {
  const _Plagg(this.navn, this.pris, this.bilde, this.y, this.sitat, this.hvem);

  final String navn;
  final String pris;
  final String bilde;

  /// `background-position` y (0–1).
  final double y;
  final String sitat;
  final String hvem;
}

// UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
const List<_Plagg> _kPlagg = [
  _Plagg('Hettejakke «Ives»', '2 499 kr', 'assets/images/dashboard/kat_tos_hoodie.jpg', .18, '«Den jeg tar på hver regndag»', 'Sara, Torgboden Mote'),
  _Plagg('T-skjorte «Dillan»', '899 kr', 'assets/images/dashboard/kat_tos_tee.jpg', .2, '«Tykk bomull, holder formen»', 'Jonas, Filippa K'),
  _Plagg('Jeans «Rosco»', '1 999 kr', 'assets/images/dashboard/kat_tos_jeans.jpg', .3, '«Sitter godt uten å stramme»', 'Mia, Norse Projects'),
];

/// The three plinth places: front, right, left.
class _Plass {
  const _Plass(this.x, this.y, this.w, this.h, this.op, this.rim, this.z, this.rotY, this.dim);

  final double x, y, w, h, op, rim, z, rotY;
  final bool dim;
}

const List<_Plass> _kPlass = [
  _Plass(195, 30, 128, 160, 1, .55, 40, 0, false),
  _Plass(302, 70, 84, 106, .82, 0, -60, -34, true),
  _Plass(88, 70, 84, 106, .82, 0, -60, 34, true),
];

/// "Ukens utstilling · Mote": three garments on a lit plinth that turns to
/// the next every 8s (or with a swipe), dust rising, a dashed ring orbiting.
class KatMoteUtstilling extends StatefulWidget {
  const KatMoteUtstilling({super.key, required this.onSnart});

  /// The size sheet comes with the store step; until then, "Kommer snart".
  final VoidCallback onSnart;

  @override
  State<KatMoteUtstilling> createState() => _KatMoteUtstillingState();
}

class _KatMoteUtstillingState extends State<KatMoteUtstilling> {
  int _idx = 0;
  bool _tatt = false;
  bool _lagret = false;
  Timer? _auto;
  double? _x0;
  DateTime _t0 = DateTime.now();

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_tatt && mounted) setState(() => _idx++);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  void _slipp(double x) {
    final x0 = _x0;
    if (x0 == null) return;
    final d = x - x0;
    final dt = DateTime.now().difference(_t0).inMilliseconds;
    if (d.abs() < 12) return;
    final fart = d.abs() / math.max(1, dt);
    final steg = fart > 1.2 ? 3 : (fart > .7 ? 2 : 1);
    HapticFeedback.selectionClick();
    setState(() {
      _idx += d < 0 ? steg : -steg;
      _tatt = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final n = _kPlagg.length;
    final idx = ((_idx % n) + n) % n;
    final front = _kPlagg[idx];
    return Column(
      key: const Key('a1_kat_mote'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(2 * s, 2 * s, 2 * s, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Ukens utstilling · Mote', style: bDisplay(context, 15, letterSpacingEm: -.015))),
              Text('3 butikker', style: bText(context, 10.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .6))),
            ],
          ),
        ),
        SizedBox(height: 10 * s),
        Listener(
          onPointerDown: (e) {
            _x0 = e.position.dx;
            _t0 = DateTime.now();
          },
          onPointerUp: (e) => _slipp(e.position.dx),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18 * s),
            child: SizedBox(
              height: 250 * s,
              child: LayoutBuilder(
                builder: (context, c) {
                  // The design's stage is 358 wide; place by its centre.
                  final mx = c.maxWidth / 2 - 179 * s;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _plint(s),
                      Positioned(
                        left: mx + (195 - 16 - 125) * s,
                        top: (195 - 125) * s,
                        width: 250 * s,
                        height: 250 * s,
                        child: const IgnorePointer(child: RepaintBoundary(child: _Ring())),
                      ),
                      Positioned(
                        left: 60 * s,
                        right: 60 * s,
                        top: 172 * s,
                        height: 44 * s,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.elliptical(c.maxWidth / 2 - 60 * s, 22 * s)),
                              gradient: RadialGradient(
                                colors: [rgba(92, 224, 184, .5), rgba(92, 224, 184, 0)],
                                stops: const [0, .7],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: _Stov(mx: mx)))),
                      for (final i in _rekkefolge(idx, n))
                        _plagg(context, i, ((i - idx) % n + n) % n, mx),
                      Positioned(
                        right: 22 * s,
                        top: 150 * s,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _lagret = !_lagret);
                            showBergenToast(
                              context,
                              _lagret ? 'Lagret · vi sier fra hvis prisen faller' : 'Fjernet fra lagret',
                            );
                          },
                          child: Container(
                            width: 36 * s,
                            height: 36 * s,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [rgba(255, 255, 255, .2), rgba(255, 255, 255, .1)],
                              ),
                              border: Border.all(color: rgba(255, 255, 255, .35)),
                              boxShadow: [
                                BoxShadow(
                                  color: rgba(0, 0, 0, .8),
                                  offset: Offset(0, 8 * s),
                                  blurRadius: onbBlur(14 * s),
                                  spreadRadius: -8 * s,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_lagret)
                                  SokIkon(
                                    'M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z',
                                    size: 15 * s,
                                    color: const Color(0xFFF26D3D),
                                    stroke: 0,
                                    fill: true,
                                  ),
                                SokIkon(
                                  'M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z',
                                  size: 15 * s,
                                  color: Colors.white,
                                  stroke: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 14 * s),
        Row(
          children: [
            Expanded(
              child: BergenOnce(
                key: ValueKey(idx),
                durationMs: 400,
                builder: (context, p, child) {
                  final e = Curves.easeOut.transform(p);
                  return Opacity(
                    opacity: (p / .55).clamp(0.0, 1.0),
                    child: Transform.translate(offset: Offset(0, 14 * s * (1 - e)), child: child),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      front.navn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bDisplay(context, 20, letterSpacingEm: -.025, height: 1.1),
                    ),
                    SizedBox(height: 4 * s),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: front.sitat),
                          TextSpan(
                            text: ' — ${front.hvem}',
                            style: TextStyle(fontStyle: FontStyle.normal, color: rgba(255, 255, 255, .58)),
                          ),
                        ],
                      ),
                      style: bText(context, 12, weight: FontWeight.w600, height: 1.35, color: rgba(255, 255, 255, .88))
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 14 * s),
            OnbPressable(
              onTap: widget.onSnart,
              pressDy: 0,
              pressScale: .94,
              child: Container(
                padding: EdgeInsets.fromLTRB(13 * s, 12 * s, 16 * s, 12 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 * s),
                  gradient: cssLinear(160, const [Color(0xFFF2884E), Color(0xFFE0662C)]),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(120, 50, 10, .9),
                      offset: Offset(0, 12 * s),
                      blurRadius: onbBlur(20 * s),
                      spreadRadius: -10 * s,
                    ),
                    BoxShadow(color: rgba(150, 60, 15, .8), offset: Offset(0, 3 * s)),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SokIkon('M12 5v14M5 12h14', size: 13 * s, color: Colors.white, stroke: 2.8),
                        SizedBox(width: 6 * s),
                        Text('Velg størrelse', style: bDisplay(context, 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Back to front, so the front garment paints last.
  List<int> _rekkefolge(int idx, int n) {
    final l = List<int>.generate(n, (i) => i);
    l.sort((a, b) {
      final ra = ((a - idx) % n + n) % n, rb = ((b - idx) % n + n) % n;
      return (ra == 0 ? 1 : 0) - (rb == 0 ? 1 : 0);
    });
    return l;
  }

  Widget _plint(double s) => Positioned.fill(
    child: IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 12 * s,
            right: 12 * s,
            top: 150 * s,
            height: 90 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -.2),
                  colors: [rgba(92, 224, 184, .12), rgba(92, 224, 184, 0)],
                  stops: const [0, .7],
                ),
              ),
            ),
          ),
          Positioned(
            left: 22 * s,
            right: 22 * s,
            top: 166 * s,
            height: 78 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(160 * s, 39 * s)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(6, 42, 50, .9), rgba(3, 26, 32, .95)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: rgba(0, 0, 0, .9),
                    offset: Offset(0, 26 * s),
                    blurRadius: onbBlur(40 * s),
                    spreadRadius: -16 * s,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 22 * s,
            right: 22 * s,
            top: 156 * s,
            height: 78 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(160 * s, 39 * s)),
                gradient: RadialGradient(
                  center: const Alignment(0, -.28),
                  colors: [rgba(255, 255, 255, .4), rgba(190, 236, 224, .18), rgba(255, 255, 255, .05)],
                  stops: const [0, .45, 1],
                ),
                border: Border.all(color: rgba(255, 255, 255, .3)),
                boxShadow: [
                  BoxShadow(color: rgba(92, 224, 184, .35), spreadRadius: 7 * s),
                  BoxShadow(color: rgba(6, 42, 50, .9), spreadRadius: 6 * s),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _plagg(BuildContext context, int i, int rel, double mx) {
    final s = context.bs;
    final v = _kPlagg[i];
    final p = _kPlass[math.min(rel, 2)];
    const c = Cubic(.3, 1.25, .5, 1);
    const ms = Duration(milliseconds: 600);
    Widget kort = Stack(
      clipBehavior: Clip.none,
      children: [
        // The back slab (`translateZ(-10px)`, 4/5px down-right).
        Positioned(
          left: 4 * s,
          top: 5 * s,
          right: -4 * s,
          bottom: -5 * s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10 * s),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD9D3C6), Color(0xFF8F887B)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10 * s),
              boxShadow: [
                BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 1.5 * s),
                BoxShadow(
                  color: rgba(0, 0, 0, p.dim ? .55 : .6),
                  offset: Offset(0, (p.dim ? 12 : 22) * s),
                  blurRadius: onbBlur((p.dim ? 12 : 20) * s),
                  spreadRadius: -4 * s,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10 * s),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(v.bilde, fit: BoxFit.cover, alignment: Alignment(0, v.y * 2 - 1)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [rgba(0, 0, 0, .18), rgba(0, 0, 0, 0)],
                        stops: const [0, .25],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: cssLinear(115, const [
                        Color.fromRGBO(255, 255, 255, .4),
                        Color.fromRGBO(255, 255, 255, 0),
                      ], const [0, .4]),
                    ),
                  ),
                  const RepaintBoundary(child: _Glint()),
                ],
              ),
            ),
          ),
        ),
        // The mint rim on the front garment (outside the card only).
        if (p.rim > 0)
          Positioned(
            left: -1,
            top: -1,
            right: -1,
            bottom: -1,
            child: IgnorePointer(
              child: BergenCssShadow(
                radius: 11 * s,
                shadows: [
                  BoxShadow(color: Color.fromRGBO(92, 224, 184, p.rim), blurRadius: onbBlur(22 * s)),
                  BoxShadow(color: Color.fromRGBO(92, 224, 184, p.rim), spreadRadius: 1),
                ],
                child: const SizedBox.expand(),
              ),
            ),
          ),
        if (rel == 0)
          Positioned(
            right: -12 * s,
            bottom: 8 * s,
            child: Transform.rotate(
              angle: -4 * math.pi / 180,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6 * s),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF6DE9E), Color(0xFFC9A24E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(0, 0, 0, .6),
                      offset: Offset(0, 8 * s),
                      blurRadius: onbBlur(12 * s),
                      spreadRadius: -6 * s,
                    ),
                    BoxShadow(color: const Color(0xFF8E6A22), offset: Offset(0, 3 * s)),
                    BoxShadow(color: Colors.white, spreadRadius: 1.5 * s),
                  ],
                ),
                child: Text(
                  v.pris,
                  style: bDisplay(context, 11.5, color: const Color(0xFF3A2E12)),
                ),
              ),
            ),
          ),
      ],
    );
    if (p.dim) {
      // `saturate(.75) brightness(.72)`.
      kort = ColorFiltered(colorFilter: _dim, child: kort);
    }
    return AnimatedPositioned(
      key: ValueKey('plagg-$i'),
      duration: ms,
      curve: c,
      left: mx + (p.x - 16 - p.w / 2) * s,
      top: p.y * s,
      width: p.w * s,
      height: p.h * s,
      child: GestureDetector(
        onTap: widget.onSnart,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: p.op,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: p.rotY),
            duration: ms,
            curve: c,
            child: kort,
            builder: (context, rot, child) {
              final z = p.z;
              final m = katPerspektiv(760)
                ..translateByDouble(0, 0, z * s, 1)
                ..rotateY(rot * math.pi / 180)
                ..rotateX((p.dim ? 3 : 0) * math.pi / 180);
              Widget w = Transform(alignment: Alignment.center, transform: m, child: child);
              if (rel == 0) {
                // `mkSvev 4.5s`: up 7px and back, rotateX 3° → 5°.
                w = KatLoop(
                  durationMs: 4500,
                  child: w,
                  builder: (context, t, child) {
                    final y = kf(t, const [0, .5, 1], const [0, -7, 0], Curves.easeInOut);
                    final rx = kf(t, const [0, .5, 1], const [3, 5, 3], Curves.easeInOut);
                    return Transform(
                      alignment: Alignment.center,
                      transform: katPerspektiv(760)
                        ..translateByDouble(0, y * s, 0, 1)
                        ..rotateX(rx * math.pi / 180),
                      child: child,
                    );
                  },
                );
              }
              return w;
            },
          ),
        ),
      ),
    );
  }

  static const ColorFilter _dim = ColorFilter.matrix(<double>[
    // saturate(.75) then brightness(.72)
    .72 * (.2126 + .7874 * .75), .72 * (.7152 - .7152 * .75), .72 * (.0722 - .0722 * .75), 0, 0,
    .72 * (.2126 - .2126 * .75), .72 * (.7152 + .2848 * .75), .72 * (.0722 - .0722 * .75), 0, 0,
    .72 * (.2126 - .2126 * .75), .72 * (.7152 - .7152 * .75), .72 * (.0722 + .9278 * .75), 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// `mkGlint 6s` — a light band crossing the garment now and then.
class _Glint extends StatelessWidget {
  const _Glint();

  @override
  Widget build(BuildContext context) => KatLoop(
    durationMs: 6000,
    builder: (context, p, _) {
      final x = kf(p, const [0, .7, .9, 1], const [-1.4, -1.4, 1.6, 1.6], Curves.easeInOut);
      final o = kf(p, const [0, .7, .8, .9, 1], const [0, 0, .7, 0, 0], Curves.easeInOut);
      if (o <= 0) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (context, c) => Opacity(
          opacity: o,
          child: Transform(
            transform: Matrix4.translationValues(x * c.maxWidth * .45, 0, 0)
              ..multiply(Matrix4.skewX(-18 * math.pi / 180)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: c.maxWidth * .45,
                height: c.maxHeight * 1.2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0),
                      Color.fromRGBO(255, 255, 255, .55),
                      Color.fromRGBO(255, 255, 255, 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// The dashed ring round the plinth: `rotateX(76deg) rotateZ(…)`, 22s.
class _Ring extends StatelessWidget {
  const _Ring();

  @override
  Widget build(BuildContext context) => KatLoop(
    durationMs: 22000,
    child: const CustomPaint(painter: _RingMaler()),
    builder: (context, p, child) => Transform(
      alignment: Alignment.center,
      transform: katPerspektiv(760)
        ..rotateX(76 * math.pi / 180)
        ..rotateZ(p * 2 * math.pi),
      child: child,
    ),
  );
}

class _RingMaler extends CustomPainter {
  const _RingMaler();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final glod = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color.fromRGBO(92, 224, 184, .4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(c, r, glod);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color.fromRGBO(92, 224, 184, .55);
    const n = 90;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, math.pi / n, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingMaler old) => false;
}

/// `mkStov`: nine motes of dust rising off the plinth.
class _Stov extends StatelessWidget {
  const _Stov({required this.mx});

  final double mx;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbLoopClock(
      builder: (context, t, _) => CustomPaint(painter: _StovMaler(t, s, mx)),
    );
  }
}

class _StovMaler extends CustomPainter {
  _StovMaler(this.t, this.s, this.mx);

  final double t;
  final double s;
  final double mx;

  @override
  void paint(Canvas canvas, Size size) {
    final kjerne = Paint()..color = const Color(0xFFBFF5E6);
    final glod = Paint()
      ..color = const Color(0xFF5CE0B8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s);
    for (var i = 0; i < 9; i++) {
      final x = 70.0 + (i * 53) % 250;
      final y = 186.0 + (i * 17) % 40;
      final r = 2.0 + i % 3;
      final dx = (i % 2 == 1 ? 1 : -1) * (4.0 + (i * 7) % 14);
      final dur = (3.2 + (i % 4) * .7) * 1000;
      final delay = ((i * .53) % 3.2) * 1000;
      if (t < delay) continue;
      final p = ((t - delay) % dur) / dur;
      final e = Curves.easeOut.transform(p);
      final o = p < .25 ? p / .25 * .9 : .9 * (1 - (p - .25) / .75);
      final sc = .6 + .5 * e;
      final c = Offset(mx + (x - 16 + r / 2 + dx * e) * s, (y + r / 2 - 70 * e) * s);
      glod.color = Color.fromRGBO(92, 224, 184, o);
      kjerne.color = Color.fromRGBO(191, 245, 230, o);
      canvas.drawCircle(c, r / 2 * sc * s * 1.6, glod);
      canvas.drawCircle(c, r / 2 * sc * s, kjerne);
    }
  }

  @override
  bool shouldRepaint(_StovMaler old) => old.t != t;
}
