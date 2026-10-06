import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import '../kit/svg_sti.dart';
import 'kasse_copy.dart';
import 'kurv_parts.dart';

/// IBM Plex Mono with the paper's ink bleed (`text-shadow 0 0 .6px
/// rgba(43,42,39,.45)`).
TextStyle kvMono(
  BuildContext c,
  double px, {
  FontWeight weight = FontWeight.w500,
  Color color = const Color(0xFF3A3833),
  double letterSpacingEm = 0,
  double? height,
}) => GoogleFonts.ibmPlexMono(
  fontSize: c.bx(px),
  fontWeight: weight,
  color: color,
  letterSpacing: c.bx(px) * letterSpacingEm,
  height: height,
  fontFeatures: const [FontFeature.tabularFigures()],
  shadows: const [Shadow(color: Color.fromRGBO(43, 42, 39, .45), blurRadius: .6)],
);

/// The receipt (L6331): a paper slip with torn zig-zag edges, tilted −0.7°,
/// lifted by two drop shadows, rain drops on it (one running, `kvDrypp 9s`)
/// and a sheen sweeping across (`kvGlans 8s`). KVITTERING · n varer, the
/// dotted rows, Ægil's notes, the door card, the perforation, Å BETALE NÅ ·
/// Totalt and the big total, the double rule with «Alt inkl. mva», the
/// barcode and the gold «+N kr tilbake» tag.
class KurvKvittering extends StatelessWidget {
  const KurvKvittering({
    super.key,
    required this.antall,
    required this.rader,
    required this.total,
    required this.kode,
    required this.tilbake,
    this.notater = const [],
  });

  final int antall;

  /// The rows between the header and the perforation (see [KvRad]).
  final List<Widget> rader;

  /// Ægil's notes and the door card, under the rows.
  final List<Widget> notater;
  final double total;

  /// The slip's code under the barcode (`Æ-42K`).
  final String kode;

  /// «+N kr tilbake i Ærend-kroner»; hidden at 0.
  final int tilbake;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      key: const Key('a1_kasse_kvittering'),
      padding: EdgeInsets.only(top: 16 * s),
      child: CustomPaint(
        painter: _PapirSkygge(s),
        child: Transform.rotate(
          angle: -.7 * math.pi / 180,
          child: ClipPath(
            clipper: _Takker(s),
            child: Stack(
              children: [
                const Positioned.fill(child: _Papir()),
                const Positioned.fill(
                  child: IgnorePointer(child: RepaintBoundary(child: _Glans())),
                ),
                ..._draaper(s),
                Padding(
                  padding: EdgeInsets.fromLTRB(18 * s, 22 * s, 18 * s, 26 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hode(context, s),
                      SizedBox(height: 8 * s),
                      ...rader,
                      ...notater,
                      Container(
                        height: 8 * s,
                        margin: EdgeInsets.fromLTRB(0, 14 * s, 0, 10 * s),
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          child: Transform.scale(
                            scaleX: 1,
                            child: CustomPaint(size: Size(1000 * s, 8 * s), painter: _Perf(s)),
                          ),
                        ),
                      ),
                      _total(context, s),
                      _inkl(context, s),
                      SizedBox(height: 14 * s),
                      _bunn(context, s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hode(BuildContext context, double s) => Container(
    padding: EdgeInsets.only(bottom: 11 * s),
    decoration: const BoxDecoration(),
    foregroundDecoration: _Stiplet(s),
    child: Column(
      children: [
        // `#merke` with `grayscale(1) contrast(1.4)`, opacity .75.
        CustomPaint(size: Size(30 * s, 24 * s), painter: const _Merke()),
        SizedBox(height: 3 * s),
        Text(
          KasseCopy.a1_kasse_kvittering,
          style: kvMono(context, 11, weight: FontWeight.w700, letterSpacingEm: .26, color: const Color(0xFF24231F)),
        ),
        SizedBox(height: 3 * s),
        Text(KasseCopy.a1_kasse_best_antall(antall), style: kvMono(context, 10.5, color: const Color(0xFF6E6A62))),
      ],
    ),
  );

  Widget _total(BuildContext context, double s) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              KasseCopy.a1_kasse_a_betale,
              style: kvMono(
                context,
                10.5,
                weight: FontWeight.w600,
                letterSpacingEm: .18,
                color: const Color(0xFF6E6A62),
              ),
            ),
            SizedBox(height: 3 * s),
            Text(
              KasseCopy.a1_kasse_totalt,
              style: bDisplay(context, 17, letterSpacingEm: -.02, color: const Color(0xFF24231F)),
            ),
          ],
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            KasseCopy.tall(total),
            key: const Key('a1_kasse_total'),
            style: kvMono(
              context,
              40,
              weight: FontWeight.w700,
              letterSpacingEm: -.05,
              height: .9,
              color: const Color(0xFF1B2A2E),
            ).copyWith(shadows: const [Shadow(color: Color.fromRGBO(27, 42, 46, .4), blurRadius: 1.2)]),
          ),
          SizedBox(width: 4 * s),
          Text(
            'kr',
            style: kvMono(context, 14, weight: FontWeight.w700, color: const Color(0xFF1B2A2E)),
          ),
        ],
      ),
    ],
  );

  Widget _inkl(BuildContext context, double s) => Container(
    margin: EdgeInsets.only(top: 11 * s),
    padding: EdgeInsets.only(top: 9 * s),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: rgba(43, 42, 39, .32), width: 1)),
    ),
    foregroundDecoration: _DobbelStrek(s),
    child: Row(
      children: [
        KurvIcon(13 * s, KurvIcons.check, color: const Color(0xFF2E6B47), width: 2.8),
        SizedBox(width: 7 * s),
        Expanded(
          child: Text(
            KasseCopy.a1_kasse_inkl,
            style: kvMono(context, 11, weight: FontWeight.w600, color: const Color(0xFF4A473F)),
          ),
        ),
      ],
    ),
  );

  Widget _bunn(BuildContext context, double s) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Opacity(
            opacity: .82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomPaint(size: Size(118 * s, 30 * s), painter: _Strekkode(s)),
                SizedBox(height: 4 * s),
                Text(kode, style: kvMono(context, 10.5, weight: FontWeight.w600, letterSpacingEm: .32)),
              ],
            ),
          ),
        ),
      ),
      SizedBox(width: 12 * s),
      if (tilbake > 0)
        Transform.rotate(
          angle: -4 * math.pi / 180,
          child: Container(
            key: const Key('a1_kasse_tilbake_kr'),
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12 * s),
              gradient: cssLinear(180, const [Color(0xFFFFDB6E), Color(0xFFF2C14E)]),
              boxShadow: [
                BoxShadow(
                  color: rgba(90, 60, 10, .6),
                  offset: Offset(0, 7 * s),
                  blurRadius: onbBlur(10 * s),
                  spreadRadius: -6 * s,
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12 * s),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [rgba(150, 100, 10, 0), rgba(150, 100, 10, 0), rgba(150, 100, 10, .25)],
                stops: const [0, .8, 1],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                bergenInsetTop(
                  radius: 12 * s,
                  height: 1.5 * s,
                  alpha: .65,
                  pad: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
                ),
                // The dog-ear in the corner.
                Positioned(
                  right: -12 * s,
                  top: -8 * s,
                  width: 12 * s,
                  height: 12 * s,
                  child: CustomPaint(painter: _Hjorne(s)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      KasseCopy.a1_kasse_kr_tilbake(tilbake),
                      style: bDisplay(context, 13, letterSpacingEm: -.01, height: 1.15, color: const Color(0xFF4A3305)),
                    ),
                    SizedBox(height: 1 * s),
                    Text(KasseCopy.a1_kasse_i_kroner, style: bText(context, 10.5, color: const Color(0xFF6B4C0E))),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );

  List<Widget> _draaper(double s) => [
    Positioned(right: 20 * s, top: 24 * s, width: 13 * s, height: 13 * s, child: const _Draape()),
    Positioned(right: 48 * s, top: 44 * s, width: 6 * s, height: 6 * s, child: const _Draape()),
    Positioned(
      right: 30 * s,
      top: 78 * s,
      width: 7 * s,
      height: 9 * s,
      child: _Drypp(s: s),
    ),
    Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, k) => Stack(
            children: [
              Positioned(left: k.maxWidth * .52, top: 12 * s, width: 7 * s, height: 7 * s, child: const _Draape()),
              Positioned(left: 9 * s, top: k.maxHeight * .46, width: 9 * s, height: 13 * s, child: const _Draape()),
              Positioned(right: 12 * s, top: k.maxHeight * .56, width: 10 * s, height: 10 * s, child: const _Draape()),
              Positioned(left: 26 * s, bottom: 34 * s, width: 8 * s, height: 8 * s, child: const _Draape()),
            ],
          ),
        ),
      ),
    ),
  ];
}

/// A receipt row: label, the dotted leader, the value (L6345).
class KvRad extends StatelessWidget {
  const KvRad({super.key, required this.label, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5 * s),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .6),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: kvMono(context, 12.5)),
            ),
            SizedBox(width: 8 * s),
            // `border-bottom: 1.5px dotted`, lifted 3px off the baseline.
            Expanded(
              child: Transform.translate(
                offset: Offset(0, 2 * s),
                child: SizedBox(
                  height: 2 * s,
                  child: CustomPaint(painter: _Prikker(s)),
                ),
              ),
            ),
            SizedBox(width: 8 * s),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child:
                    trailing ??
                    Text(
                      value ?? '',
                      style: kvMono(context, 12.5, weight: FontWeight.w700, color: const Color(0xFF24231F)),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «39 kr» struck and the green stamp («Gratis over 300 kr» / «Gratis — du
/// henter selv»), tilted −5°.
class KvStempel extends StatelessWidget {
  const KvStempel({super.key, required this.tekst, this.foer});

  final String tekst;
  final String? foer;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (foer != null) ...[
          Text(
            foer!,
            style: kvMono(
              context,
              11.5,
              weight: FontWeight.w600,
              color: const Color(0xFF8C877C),
            ).copyWith(decoration: TextDecoration.lineThrough, decorationColor: const Color(0xFF8C877C)),
          ),
          SizedBox(width: 8 * s),
        ],
        Transform.rotate(
          angle: -5 * math.pi / 180,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 1 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6 * s),
              border: Border.all(color: rgba(46, 107, 71, .78), width: 1.5 * s),
            ),
            child: Text(
              tekst.toUpperCase(),
              style: kvMono(
                context,
                10.5,
                weight: FontWeight.w700,
                letterSpacingEm: .06,
                color: rgba(46, 107, 71, .92),
              ).copyWith(shadows: const [Shadow(color: Color.fromRGBO(46, 107, 71, .5), blurRadius: .8)]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ægil's note on the slip: «Du mangler N kr til gratis levering hos …» with
/// its suggestion (`kMot`, orange), or the lines Ægil put in (teal, with
/// «Angre»).
class KvNotat extends StatelessWidget {
  const KvNotat({super.key, required this.tekst, required this.cta, required this.onTap, this.oransje = true});

  final String tekst;
  final String cta;
  final VoidCallback onTap;
  final bool oransje;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      margin: EdgeInsets.only(top: 8 * s),
      padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: (oransje ? 10 : 9) * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * s),
        color: oransje ? rgba(242, 109, 61, .1) : rgba(30, 79, 92, .08),
        border: Border.all(color: oransje ? rgba(242, 109, 61, .25) : rgba(30, 79, 92, .14)),
      ),
      child: Row(
        crossAxisAlignment: oransje ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/dashboard/invitation.png', width: 26 * s, height: 26 * s, fit: BoxFit.contain),
          SizedBox(width: 10 * s),
          Expanded(
            child: oransje
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tekst, style: bText(context, 12.5, height: 1.4, color: const Color(0xFF23201D))),
                      SizedBox(height: 5 * s),
                      GestureDetector(
                        key: const Key('a1_kasse_mot_cta'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: Text(
                          cta,
                          style: bText(context, 12, weight: FontWeight.w800, color: const Color(0xFF1E4F5C)),
                        ),
                      ),
                    ],
                  )
                : Text(
                    tekst,
                    style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                  ),
          ),
          if (!oransje)
            GestureDetector(
              key: const Key('a1_kasse_aegil_angre'),
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Text(
                cta,
                style: bText(context, 12, weight: FontWeight.w800, color: const Color(0xFF1E4F5C)),
              ),
            ),
        ],
      ),
    );
  }
}

/// «Døren · for budet» (L6352): the white card with the note field and
/// «Tolk», and the two switches (share with couriers, code at the door).
class KvDor extends StatelessWidget {
  const KvDor({
    super.key,
    required this.controller,
    required this.onTolk,
    required this.delt,
    required this.onDelt,
    required this.kode,
    required this.onKode,
    required this.kodeLinje,
  });

  final TextEditingController controller;
  final VoidCallback onTolk;
  final bool delt;
  final VoidCallback onDelt;
  final bool kode;
  final VoidCallback onKode;
  final String kodeLinje;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: const Key('a1_kasse_dor_kort'),
      margin: EdgeInsets.only(top: 12 * s),
      padding: EdgeInsets.fromLTRB(13 * s, 12 * s, 13 * s, 6 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * s),
        color: Colors.white,
        border: Border.all(color: rgba(35, 32, 29, .05)),
        boxShadow: [
          BoxShadow(
            color: rgba(90, 60, 30, .55),
            offset: Offset(0, 12 * s),
            blurRadius: onbBlur(22 * s),
            spreadRadius: -18 * s,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            KasseCopy.a1_kasse_doren,
            style: bText(context, 10.5, weight: FontWeight.w800, letterSpacingEm: .1, color: const Color(0xFF8C847C)),
          ),
          Container(
            height: 46 * s,
            margin: EdgeInsets.only(top: 8 * s),
            padding: EdgeInsets.fromLTRB(14 * s, 4 * s, 4 * s, 4 * s),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFF4F1EA)),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [rgba(35, 32, 29, .14), rgba(35, 32, 29, 0), rgba(255, 255, 255, 0), rgba(255, 255, 255, .9)],
                stops: const [0, .1, .96, 1],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('a1_kasse_dor'),
                    controller: controller,
                    cursorColor: const Color(0xFFE65A28),
                    style: bText(context, 12.5, color: const Color(0xFF23201D)),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: KasseCopy.a1_kasse_dor_hint,
                      hintStyle: bText(context, 12.5, color: rgba(35, 32, 29, .4)),
                    ),
                  ),
                ),
                SizedBox(width: 6 * s),
                OnbPressable(
                  key: const Key('a1_kasse_tolk'),
                  onTap: onTolk,
                  pressDy: 1.5,
                  child: Container(
                    height: 38 * s,
                    padding: EdgeInsets.symmetric(horizontal: 15 * s),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: cssLinear(180, const [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomPaint(size: Size.square(13 * s), painter: _Gnist()),
                        SizedBox(width: 6 * s),
                        Text(KasseCopy.a1_kasse_tolk, style: bText(context, 12, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _bryterRad(
            context,
            s,
            KasseCopy.a1_kasse_dor_del,
            null,
            delt,
            onDelt,
            const Key('a1_kasse_dor_del'),
            48,
            false,
          ),
          _bryterRad(
            context,
            s,
            KasseCopy.a1_kasse_kode,
            kodeLinje,
            kode,
            onKode,
            const Key('a1_kasse_kode_switch'),
            56,
            true,
          ),
        ],
      ),
    );
  }

  Widget _bryterRad(
    BuildContext context,
    double s,
    String tittel,
    String? linje,
    bool on,
    VoidCallback onTap,
    Key key,
    double h,
    bool strek,
  ) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      constraints: BoxConstraints(minHeight: h * s),
      margin: EdgeInsets.only(top: strek ? 0 : 6 * s),
      decoration: BoxDecoration(
        border: strek ? Border(top: BorderSide(color: rgba(35, 32, 29, .07))) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tittel,
                  style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                ),
                if (linje != null)
                  Padding(
                    padding: EdgeInsets.only(top: 1 * s),
                    child: Text(
                      linje,
                      style: bText(context, 11, weight: FontWeight.w600, height: 1.35, color: const Color(0xFF6E6862)),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12 * s),
          KvBryter(key: key, on: on, onTap: onTap),
        ],
      ),
    ),
  );
}

/// The 48×28 switch: mint when on, the white thumb springing over with its
/// check (`.42s cubic-bezier(.34,1.56,.64,1)`).
class KvBryter extends StatelessWidget {
  const KvBryter({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48 * s,
        height: 28 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: on
              ? cssLinear(180, const [Color(0xFF5CE0B8), Color(0xFF2FB893)])
              : LinearGradient(colors: [rgba(35, 32, 29, .14), rgba(35, 32, 29, .14)]),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: BergenTokens.motion(context, const Duration(milliseconds: 420)),
              curve: const Cubic(.34, 1.56, .64, 1),
              left: (on ? 23 : 3) * s,
              top: 3 * s,
              width: 22 * s,
              height: 22 * s,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFEEF2F1)]),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(35, 32, 29, .4),
                      offset: Offset(0, 2 * s),
                      blurRadius: onbBlur(5 * s),
                      spreadRadius: -1 * s,
                    ),
                  ],
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: on ? 1 : 0,
                  child: KurvIcon(11 * s, KurvIcons.check, color: const Color(0xFF1E4F5C), width: 3.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── the paper ───────────────────────────────────────────────────────────────

class _Papir extends StatelessWidget {
  const _Papir();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, k) {
        final w = k.maxWidth, h = k.maxHeight;
        RadialGradient flekk(double x, double y, double rx, double ry, double a) => RadialGradient(
          center: Alignment(x * 2 - 1, y * 2 - 1),
          radius: .5,
          colors: [rgba(120, 150, 158, a), rgba(120, 150, 158, 0)],
          stops: const [0, .72],
        );
        Widget lag(Gradient g, double x, double y, double rx, double ry) => Positioned(
          left: x * w - rx,
          top: y * h - ry,
          width: rx * 2,
          height: ry * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: g),
          ),
        );
        return Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFF6F2E8))),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      rgba(255, 255, 255, .7),
                      rgba(255, 255, 255, 0),
                      rgba(60, 50, 30, 0),
                      rgba(60, 50, 30, .05),
                    ],
                    stops: const [0, .22, .8, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rgba(60, 50, 30, .07), rgba(60, 50, 30, 0), rgba(60, 50, 30, 0), rgba(60, 50, 30, .08)],
                    stops: const [0, .07, .93, 1],
                  ),
                ),
              ),
            ),
            // Damp patches on the paper.
            lag(flekk(.5, .5, 70, 46, .2), .86, .14, 70, 46),
            lag(flekk(.5, .5, 110, 70, .16), .08, .58, 110, 70),
            lag(flekk(.5, .5, 90, 50, .18), .62, .96, 90, 50),
          ],
        );
      },
    );
  }
}

/// `kvGlans 8s ease-in-out`: a 115° light band sweeping across and back.
class _Glans extends StatelessWidget {
  const _Glans();

  @override
  Widget build(BuildContext context) {
    return BergenLoop(
      durationMs: 8000,
      builder: (context, p, _) {
        final q = p == null ? 0.0 : kf(p, const [0, .5, 1], const [1, 0, 1], Curves.easeInOut);
        return LayoutBuilder(
          builder: (context, k) {
            // background-size 260 %: the band's span moves by 160 % of the
            // width between its two ends.
            final dx = (q - .5) * 1.6 * k.maxWidth;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: OverflowBox(
                maxWidth: k.maxWidth * 2.6,
                child: SizedBox(
                  width: k.maxWidth * 2.6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: cssLinear(
                        115,
                        [rgba(255, 255, 255, 0), rgba(255, 255, 255, .42), rgba(255, 255, 255, 0)],
                        const [.38, .5, .62],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A rain drop on paper: the highlight, the tinted body and its shadows.
class _Draape extends StatelessWidget {
  const _Draape();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(.24, .44),
          colors: [rgba(30, 79, 92, .2), rgba(30, 79, 92, .06), rgba(30, 79, 92, 0)],
          stops: const [0, .58, .74],
        ),
        boxShadow: [
          BoxShadow(color: rgba(30, 79, 92, .25), offset: const Offset(1.5, 2.5), blurRadius: 2, spreadRadius: -.5),
        ],
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-.32, -.44),
            radius: .3,
            colors: [
              Color.fromRGBO(255, 255, 255, .98),
              Color.fromRGBO(255, 255, 255, .98),
              Color.fromRGBO(255, 255, 255, 0),
            ],
            stops: [0, .53, 1],
          ),
        ),
      ),
    );
  }
}

/// `kvDrypp 9s ease-in`: a drop sliding 38px down with its trail.
class _Drypp extends StatelessWidget {
  const _Drypp({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    return BergenLoop(
      durationMs: 9000,
      builder: (context, p, child) {
        if (p == null) return const SizedBox.shrink();
        final e = Curves.easeIn.transform(p);
        final y = kf(e, const [0, .12, .85, 1], const [0, 0, 34, 38]);
        final o = kf(e, const [0, .12, .2, .85, 1], const [0, 0, 1, 1, 0]);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, y * s), child: child),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 2 * s,
            bottom: 6 * s,
            width: 3 * s,
            height: 22 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2 * s),
                gradient: cssLinear(180, [rgba(120, 150, 158, 0), rgba(120, 150, 158, .22)]),
              ),
            ),
          ),
          const Positioned.fill(child: _Draape()),
        ],
      ),
    );
  }
}

/// The torn edges: 12px teeth, 6px deep, top and bottom.
class _Takker extends CustomClipper<Path> {
  const _Takker(this.s);

  final double s;

  @override
  Path getClip(Size size) {
    final t = 12 * s, d = 6 * s;
    final p = Path()..moveTo(0, d);
    for (var x = 0.0; x < size.width; x += t) {
      p.lineTo(math.min(size.width, x + t / 2), 0);
      p.lineTo(math.min(size.width, x + t), d);
    }
    p.lineTo(size.width, size.height - d);
    for (var x = size.width; x > 0; x -= t) {
      p.lineTo(math.max(0, x - t / 2), size.height);
      p.lineTo(math.max(0, x - t), size.height - d);
    }
    return p..close();
  }

  @override
  bool shouldReclip(_Takker old) => old.s != s;
}

/// `drop-shadow(0 20px 16px rgba(3,16,24,.42)) drop-shadow(0 2px 2px
/// rgba(3,16,24,.28))` under the torn slip.
class _PapirSkygge extends CustomPainter {
  const _PapirSkygge(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-.7 * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);
    final slip = _Takker(s).getClip(size);
    canvas.drawPath(
      slip.shift(Offset(0, 20 * s)),
      Paint()
        ..color = rgba(3, 16, 24, .42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, onbBlur(16 * s) / 2),
    );
    canvas.drawPath(
      slip.shift(Offset(0, 2 * s)),
      Paint()
        ..color = rgba(3, 16, 24, .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, onbBlur(2 * s) / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PapirSkygge old) => old.s != s;
}

/// `border-bottom: 1.5px dashed rgba(43,42,39,.24)` under the header.
class _Stiplet extends Decoration {
  const _Stiplet(this.s);

  final double s;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _StipletMaler(s);
}

class _StipletMaler extends BoxPainter {
  _StipletMaler(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size!;
    final y = offset.dy + size.height - .75 * s;
    final paint = Paint()
      ..color = rgba(43, 42, 39, .24)
      ..strokeWidth = 1.5 * s;
    for (var x = offset.dx; x < offset.dx + size.width; x += 6 * s) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 3 * s, offset.dx + size.width), y), paint);
    }
  }
}

/// `border-top: 3px double` — the second of the two lines.
class _DobbelStrek extends Decoration {
  const _DobbelStrek(this.s);

  final double s;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DobbelMaler(s);
}

class _DobbelMaler extends BoxPainter {
  _DobbelMaler(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size!;
    canvas.drawRect(
      Rect.fromLTWH(offset.dx, offset.dy + 2 * s, size.width, 1 * s),
      Paint()..color = rgba(43, 42, 39, .32),
    );
  }
}

/// The dotted leader (`1.5px dotted rgba(43,42,39,.3)`).
class _Prikker extends CustomPainter {
  const _Prikker(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = rgba(43, 42, 39, .3);
    for (var x = 0.0; x < size.width; x += 3 * s) {
      canvas.drawCircle(Offset(x + .75 * s, size.height / 2), .75 * s, paint);
    }
  }

  @override
  bool shouldRepaint(_Prikker old) => old.s != s;
}

/// The perforation: 1.8px teal dots every 9px.
class _Perf extends CustomPainter {
  const _Perf(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = rgba(30, 79, 92, .4);
    for (var x = 3 * s + 4.5 * s; x < size.width; x += 9 * s) {
      canvas.drawCircle(Offset(x, size.height / 2), 1.8 * s, paint);
    }
  }

  @override
  bool shouldRepaint(_Perf old) => old.s != s;
}

/// `repeating-linear-gradient(90deg, …)`: bars at 0–2, 3–4, 7–10, 11–12,
/// 15–16 of every 17px.
class _Strekkode extends CustomPainter {
  const _Strekkode(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF24231F);
    const bars = [(0.0, 2.0), (3.0, 4.0), (7.0, 10.0), (11.0, 12.0), (15.0, 16.0)];
    for (var x0 = 0.0; x0 < size.width; x0 += 17 * s) {
      for (final (a, b) in bars) {
        final l = x0 + a * s, r = math.min(size.width, x0 + b * s);
        if (l < r) canvas.drawRect(Rect.fromLTRB(l, 0, r, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Strekkode old) => old.s != s;
}

/// The dog-ear: paper over gold, cut on the diagonal.
class _Hjorne extends CustomPainter {
  const _Hjorne(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndCorners(r, topRight: Radius.circular(12 * s)));
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = const Color(0xFFF6F2E8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFFD9A93A),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Hjorne old) => old.s != s;
}

/// The mint sparkle on «Tolk».
class _Gnist extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      svgSti('M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z'),
      Paint()..color = const Color(0xFF5CE0B8),
    );
  }

  @override
  bool shouldRepaint(_Gnist old) => false;
}

/// The Æ mark (`#merke`, viewBox −30 −14 172 138, turned −5° about 60,53),
/// in the grey the receipt's `grayscale(1) contrast(1.4)` makes of it.
class _Merke extends CustomPainter {
  const _Merke();

  static final _bokstav = svgSti('M14 90 L60 16 V90 M34 58 H60 M62 16 H104 M62 53 H96 M62 90 H104');
  static final _fart = svgSti('M-14 60 H8 M-8 76 H4');

  /// Rec. 709 luma through contrast 1.4, then .75 alpha.
  static Color _gra(Color c) {
    final l = (.2126 * c.r + .7152 * c.g + .0722 * c.b);
    final k = ((l - .5) * 1.4 + .5).clamp(0.0, 1.0);
    return Color.from(alpha: .75 * c.a, red: k, green: k, blue: k);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sk = math.min(size.width / 172, size.height / 138);
    canvas.translate((size.width - 172 * sk) / 2, (size.height - 138 * sk) / 2);
    canvas.scale(sk);
    canvas.translate(30, 14);
    canvas.translate(60, 53);
    canvas.rotate(-5 * math.pi / 180);
    canvas.translate(-60, -53);
    Paint strek(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _gra(c);
    canvas.drawPath(_bokstav, strek(Colors.white, 25));
    canvas.drawPath(_fart, strek(Colors.white, 16));
    canvas.drawPath(_bokstav, strek(const Color(0xFFDFE5E8), 22.4));
    canvas.drawPath(_fart, strek(const Color(0xFFDFE5E8), 13.6));
    canvas.drawPath(_bokstav, strek(Colors.white, 21));
    canvas.drawPath(_fart, strek(Colors.white, 12.4));
    canvas.drawPath(_bokstav, strek(const Color(0xFF3A7D8C), 15));
    canvas.drawPath(_fart, strek(const Color(0xFFF26D3D), 6.5));
    canvas.save();
    canvas.translate(-1.6, -2.2);
    canvas.drawPath(_bokstav, strek(const Color(0xBF8FC2CF), 3));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Merke old) => false;
}
