import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import 'hjem_hero.dart';

// ── Vindu (`sone: 'vindu'`, L2514–2540, L9538) ─────────────────────────────
// A tap on the sheet's handle opens the window: the sheet drops to a cream
// stripe at 640, the scene fills the screen, and the categories hang on the
// water as stickers under a frosted search bar. The header shrinks to a
// glass address pill and bell.

const List<String> _kStk = ['restaurant', 'fisk', 'mote', 'interior', 'gaver'];
const List<double> _kRot = [-5, 3, -2, 4, -3];

/// `vaerTekst` — the glass chrome's text colour.
Color hjemVaerTekst(HjemVaer v) => switch (v) {
  HjemVaer.regn || HjemVaer.sol => const Color(0xFF23201D),
  _ => const Color(0xFFF7F2EA),
};

/// `vinduInn` .42s with a delay (s).
Widget _inn(double delay, Widget child) => LfOnce(
  ms: delay * 1000 + 420,
  builder: (context, t, child) {
    final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, delay * 1000, 420));
    final s = .94 + .06 * e;
    return Opacity(
      opacity: e,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(0, 16 * (1 - e), 0, 1)
          ..scaleByDouble(s, s, 1, 1),
        child: child,
      ),
    );
  },
  child: child,
);

/// The frosted glass of the chrome: the scene behind it, pre-blurred
/// (`backdrop-filter: blur(26px) saturate(1.4)`, baked), under white .5.
class _Frost extends StatelessWidget {
  const _Frost({required this.vaer, required this.rect, required this.radius, required this.child});

  final HjemVaer vaer;

  /// The glass's box in the scene (design px from the hero's top-left).
  final Rect rect;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: rect.width,
      height: rect.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .72)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 31, 43, .6), offset: Offset(0, 12), blurRadius: 11, spreadRadius: -12)],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -rect.left,
              top: -rect.top,
              width: 390,
              height: 127,
              child: Image.asset('assets/images/bryggen/hjem_${vaer.name}_frost.jpg', fit: BoxFit.fill, gaplessPlayback: true),
            ),
            if (rect.bottom > 127)
              Positioned(left: 0, right: 0, top: 127 - rect.top, bottom: 0, child: ColoredBox(color: vaer.seaBase)),
            const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .5))),
            const Positioned.fill(child: CssBox(shadows: [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .9))])),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

/// Everything vindu puts over the scene (design frame, hero coordinates).
class HjemVinduLag extends StatelessWidget {
  const HjemVinduLag({
    super.key,
    required this.vaer,
    required this.adresse,
    required this.uleste,
    required this.live,
    required this.opacity,
    required this.onAdresse,
    required this.onBjelle,
    required this.onSok,
    required this.onAegil,
    required this.onKategori,
  });

  final HjemVaer vaer;
  final String adresse;
  final int uleste;

  /// `LIVE` per category ("24 åpne nå" / "Kommer snart").
  final List<String> live;

  /// `vinduOp` — fades while the stripe is dragged.
  final double opacity;
  final VoidCallback onAdresse, onBjelle, onSok, onAegil;
  final ValueChanged<int> onKategori;

  @override
  Widget build(BuildContext context) {
    final tekst = hjemVaerTekst(vaer);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Address pill (top 26, right 80, 28 high).
        Positioned(
          top: 26,
          right: 80,
          child: GestureDetector(
            onTap: onAdresse,
            child: _AdressePille(vaer: vaer, tekst: tekst, adresse: adresse),
          ),
        ),
        // Bell (top 32, right 28, 44×44).
        Positioned(
          top: 32,
          right: 28,
          width: 44,
          height: 44,
          child: LfPress(
            scale: .93,
            onTap: onBjelle,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _Frost(
                  vaer: vaer,
                  rect: const Rect.fromLTWH(390 - 28 - 44, 32, 44, 44),
                  radius: BorderRadius.circular(22),
                  child: Center(
                    child: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#${_hex(tekst)}" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8.6a6 6 0 1 0-12 0c0 5.9-2.2 7.4-2.2 7.4h16.4S18 14.5 18 8.6z"/><path d="M10.3 19.6a2 2 0 0 0 3.4 0"/></svg>',
                      width: 19,
                      height: 19,
                    ),
                  ),
                ),
                if (uleste >= 3)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 19),
                      height: 19,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E4F5C),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 255, 255, .92), spreadRadius: 2)],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        uleste > 9 ? '9+' : '$uleste',
                        style: inter(10.5, weight: FontWeight.w800).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                  )
                else if (uleste > 0)
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF8A5A1E),
                        boxShadow: [BoxShadow(color: Color.fromRGBO(255, 255, 255, .9), spreadRadius: 2)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Search bar (left/right 30, top 236, 54 high).
        Positioned(
          left: 30,
          right: 30,
          top: 236,
          height: 54,
          child: Opacity(
            opacity: opacity,
            child: _inn(
              .06,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .95)),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 31, 43, .55), offset: Offset(0, 18), blurRadius: 17, spreadRadius: -16)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      // Over the water: its blurred colour, under white .72.
                      Positioned.fill(child: ColoredBox(color: vaer.seaBase)),
                      const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .72))),
                      const Positioned.fill(child: CssBox(shadows: [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF))])),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 7, 0),
                        child: Row(
                          children: [
                            SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#F26D3D" stroke-width="2.3" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20.5 20.5l-4.3-4.3"/></svg>',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onSok,
                                child: Text('Hva trenger du i kveld?', style: jakarta(14, weight: FontWeight.w700, color: const Color(0xFF57534B))),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: onAegil,
                              child: CssBox(
                                width: 40,
                                height: 40,
                                radius: BorderRadius.circular(14),
                                bg: const [CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C)])],
                                shadows: const [CssShadow(0, 10, 16, -7, Color.fromRGBO(30, 79, 92, .7))],
                                child: Center(
                                  child: SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21"/></svg>',
                                    width: 15,
                                    height: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Vindu · kategoriene (left/right 24, top 316; 31% wide, gap 10/4).
        Positioned(
          left: 24,
          right: 24,
          top: 316,
          child: Opacity(
            opacity: opacity,
            child: LayoutBuilder(
              builder: (context, box) => Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 10,
                children: [
                  for (var k = 0; k < 5; k++)
                    SizedBox(
                      width: box.maxWidth * .31,
                      child: _inn(
                        .08 + k * .06,
                        LfPress(
                          scale: .95,
                          ms: 300,
                          onTap: () => onKategori(k),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.rotate(
                                angle: rad(_kRot[k]),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    boxShadow: [BoxShadow(color: Color.fromRGBO(8, 24, 32, .3), offset: Offset(0, 8), blurRadius: 10, spreadRadius: -12)],
                                  ),
                                  child: Image.asset('assets/images/dashboard/sok_stk_${_kStk[k]}.png', width: k == 0 ? 96 : 84, height: k == 0 ? 96 : 84),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFDFC4), Color(0xFFF5B981)]),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.white, spreadRadius: 1.5),
                                      BoxShadow(color: Color.fromRGBO(8, 24, 32, .35), offset: Offset(0, 3), blurRadius: 5),
                                    ],
                                  ),
                                  child: Text(live[k], style: inter(9, weight: FontWeight.w800, color: const Color(0xFF23201D)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _hex(Color c) => c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);

class _AdressePille extends StatelessWidget {
  const _AdressePille({required this.vaer, required this.tekst, required this.adresse});

  final HjemVaer vaer;
  final Color tekst;
  final String adresse;

  @override
  Widget build(BuildContext context) {
    final style = inter(10.5, weight: FontWeight.w800, color: tekst);
    final tp = TextPainter(text: TextSpan(text: adresse, style: style), textDirection: TextDirection.ltr, maxLines: 1)..layout();
    final w = 9 + 11 + 5 + tp.width + 11 + 2;
    return _Frost(
      vaer: vaer,
      rect: Rect.fromLTWH(390 - 80 - w, 26, w, 28),
      radius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#${_hex(tekst)}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21.5S5.5 15.5 5.5 10.5a6.5 6.5 0 1 1 13 0c0 5-6.5 11-6.5 11z"/><circle cx="12" cy="10.5" r="2.3"/></svg>',
              width: 11,
              height: 11,
            ),
            const SizedBox(width: 5),
            Text(adresse, maxLines: 1, style: style),
          ],
        ),
      ),
    );
  }
}

/// The cream stripe at 640 (`vinduStripe`): its handle closes the window,
/// and the quickest way back to a shop.
class HjemVinduStripe extends StatelessWidget {
  const HjemVinduStripe({
    super.key,
    required this.onToggle,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onButikk,
    this.butikker = const [],
  });

  final VoidCallback onToggle;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  /// «Bestill igjen»: the shops this customer last ordered from (backend
  /// plan Step 8, `ops.customer.orders`), newest first, at most two. A tap
  /// puts that shop's last order in the basket. Empty: the row is left out.
  final List<String> butikker;
  final ValueChanged<int> onButikk;

  static const _farger = [
    [Color(0xFFF2C9A0), Color(0xFFC97A4A)],
    [Color(0xFFF0B8A8), Color(0xFFA8352E)],
  ];

  @override
  Widget build(BuildContext context) {
    Widget chip(int i, String navn, List<Color> farger) => GestureDetector(
      key: Key('a1_hjem_vindu_igjen_$i'),
      onTap: () => onButikk(i),
      child: CssBox(
        radius: BorderRadius.circular(14),
        bg: const [CssLinear(180, [Color(0xFFFDFCF9), Color(0xFFFDFCF9)])],
        shadows: const [CssShadow(0, 2, 3, -1, Color.fromRGBO(120, 80, 40, .12)), CssShadow(0, 10, 18, -12, Color.fromRGBO(90, 60, 30, .5))],
        padding: const EdgeInsets.fromLTRB(6, 6, 11, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CssBox(
              width: 30,
              height: 30,
              radius: BorderRadius.circular(10),
              bg: [CssLinear(160, farger)],
              child: Center(child: Text(navn.isEmpty ? '·' : navn.characters.first.toUpperCase(), style: inter(13, weight: FontWeight.w800, color: Colors.white))),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFF23201D)))),
          ],
        ),
      ),
    );
    return CssBox(
      height: 150,
      radius: const BorderRadius.vertical(top: Radius.circular(28)),
      bg: const [CssLinear(180, [Color(0xFFF7F3EA), Color(0xFFEDE6D9)])],
      border: const Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .9))),
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
        CssShadow(0, -16, 34, -18, Color.fromRGBO(35, 32, 29, .45)),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            onVerticalDragStart: onDragStart,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: Column(
                children: [
                  Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color.fromRGBO(35, 32, 29, .28), borderRadius: BorderRadius.circular(3))),
                  const SizedBox(height: 3),
                  Text('↑ Trekk opp for butikken', style: inter(9.5, weight: FontWeight.w800, color: const Color(0xFF1E4F5C))),
                ],
              ),
            ),
          ),
          if (butikker.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Bestill igjen', style: inter(12, weight: FontWeight.w800, color: const Color(0xFF23201D))),
              const Spacer(),
              Text('Raskeste vei', style: inter(10.5, weight: FontWeight.w700, color: const Color(0xFF8C847C))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < butikker.length && i < 2; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Flexible(child: chip(i, butikker[i], _farger[i % _farger.length])),
              ],
            ],
          ),
          ],
        ],
      ),
    );
  }
}
