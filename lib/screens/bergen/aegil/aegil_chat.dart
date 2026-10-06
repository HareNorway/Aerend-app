import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/suggestion_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../hurtig/hurtig_data.dart' show HbButikk;
import '../kit/svg_sti.dart';
import 'aegil_bits.dart';
import 'aegil_launch_copy.dart';

// ── Ægil-chat (`vcAktiv`, L4574–4632) ───────────────────────────────────────

/// An app card (`VC_APP`): Fjordfiske, the bag, tracking, points, the
/// basket, Utforsk.
enum AeApp { fiske, pose, sporing, poeng, kurv, utforsk }

/// A button under a reply (`knapper`): the first is orange, the next glass.
class AeKnapp {
  const AeKnapp(this.tekst, {this.si, this.app});
  final String tekst;

  /// Says this to Ægil (`si:`).
  final String? si;

  /// Opens this part of the app (`ga:`).
  final AeApp? app;
}

/// One line of the conversation (`vc[i]`).
class AeMelding {
  AeMelding.meg(this.tekst)
    : meg = true,
      state = null,
      kort = const [],
      kurv = null,
      sammen = null,
      dor = null,
      bytt = null,
      app = const [],
      knapper = const [],
      forslag = const [],
      humor = 'glad';

  AeMelding.aeg({
    required this.tekst,
    this.state,
    this.kort = const [],
    this.kurv,
    this.sammen,
    this.dor,
    this.bytt,
    this.app = const [],
    this.knapper = const [],
    this.forslag = const [],
    this.humor = 'glad',
  }) : meg = false;

  final bool meg;
  final String tekst;

  /// The backend's `agentGaa` state (`agForslag`, `agSammen`, …), or null
  /// for a local line.
  final String? state;
  final List<Suggestion> kort;
  final AegilBasket? kurv;
  final Map<String, dynamic>? sammen;
  final String? dor;
  final String? bytt;
  final List<AeApp> app;
  final List<AeKnapp> knapper;

  /// The chips offered after this reply (`forslag`).
  final List<String> forslag;

  /// `glad` / `spent` / `tenker` / `lei` — Ægil's pose for the reply.
  final String humor;

  final int id = _n++;
  static int _n = 0;
}

/// What the cards and buttons ask the screen to do.
abstract interface class AeHandling {
  void si(String tekst);
  void app(AeApp app);
  Future<void> leggKort(Suggestion s);
  Future<void> leggAlt(AegilBasket kurv);
  Future<void> lagreDor(String note);
  void aapneButikk(int storeId);
  bool erLagt(int suggestionId);
  bool alleLagt(AegilBasket kurv);
  bool dorLagret(String note);
  String? butikkNavn(int? storeId);
  HbButikk? butikk(int? storeId);
  String? bilde(int? storeProductId);

  /// The store's art (`ico_fisk`, `ico_mat`, `ico_mote`, `ico_gaver`).
  String ikon(int? storeId);
  int? poeng();
  bool get handler;
}

/// The user's line (`m.meg`): white, right, `vcMeg .38s`.
class AeMegBoble extends StatelessWidget {
  const AeMegBoble({super.key, required this.tekst, required this.ny});

  final String tekst;
  final bool ny;

  @override
  Widget build(BuildContext context) {
    final boble = CssBox(
      radius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(6)),
      bg: const [
        CssLinear(180, [Colors.white, Color(0xFFEEF2F2)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Colors.white),
        CssShadow(0, 2.5, 0, 0, Color(0xFF9FB3B8)),
        CssShadow(0, 12, 18, -12, Color.fromRGBO(3, 16, 24, .8)),
      ],
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      child: Text(tekst, style: inter(14, weight: FontWeight.w700, height: 1.4, color: kAeTeal)),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Align(
        alignment: Alignment.centerRight,
        child: ny ? AeOnce(kind: AeInn.vcMeg, ms: 380, curve: const Cubic(.2, 1.25, .3, 1), alignment: Alignment.bottomRight, child: boble) : boble,
      ),
    );
  }
}

/// Ægil's reply (`m.aeg`): the avatar on the first of a run, the glass
/// bubble with the words rising in one by one (`vcOrd`), then the cards
/// (`vcKort`) and the buttons (`vcKnapp`).
class AeSvar extends StatelessWidget {
  const AeSvar({super.key, required this.m, required this.forst, required this.ny, required this.h});

  final AeMelding m;
  final bool forst;
  final bool ny;
  final AeHandling h;

  /// When the last piece of this reply has landed (`dSlutt`), in ms.
  static double slutt(AeMelding m) {
    final ord = m.tekst.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final d0 = 250 + ord * 30.0;
    final kort = _antallKort(m);
    final kn = m.knapper.take(2).length;
    return d0 + kort * 90 + kn * 70 + 200;
  }

  static int _antallKort(AeMelding m) => _kortListe(m).length;

  static List<Object> _kortListe(AeMelding m) => [
    if (m.state == 'agIkkeFunnet') 'ingen',
    if (m.state == 'agAldersblokk') 'alder',
    if (m.state == 'agFunn' && m.kort.isNotEmpty) 'funn',
    if (m.dor != null) 'dor',
    if (m.bytt != null) 'bytt',
    if (m.kurv != null && m.kurv!.lines.any((l) => l.storeProductId != null && l.priceOre > 0)) 'kurv',
    if (m.sammen != null) 'sammen',
    // The tray's cards — those in the basket card are not repeated.
    for (final s in m.kort)
      if (m.kurv == null || !m.kurv!.lines.any((l) => l.suggestionId == s.id && l.storeProductId != null && l.priceOre > 0)) s,
    ...m.app,
  ];

  @override
  Widget build(BuildContext context) {
    final ord = m.tekst.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final d0 = 250 + ord.length * 30.0;
    final kort = _kortListe(m);
    final knapper = m.knapper.take(2).toList();

    Widget inn(AeInn k, double ms, double delay, Cubic c, Widget child, [Alignment a = Alignment.center]) =>
        ny ? AeOnce(kind: k, ms: ms, delay: delay, curve: c, alignment: a, child: child) : child;

    final boble = CssBox(
      radius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(6), bottomRight: Radius.circular(20)),
      bg: kAeGlass,
      shadows: kAeGlassSh,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: _Ord(ord: ord, ny: ny),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 32, child: Padding(padding: const EdgeInsets.only(top: 2), child: forst ? const AeAvatar() : const SizedBox(height: 32))),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                inn(AeInn.vcBoble, 420, 0, const Cubic(.2, 1.2, .3, 1), boble, Alignment.bottomLeft),
                for (final (j, k) in kort.indexed) ...[
                  const SizedBox(height: 8),
                  inn(AeInn.vcKort, 500, d0 + j * 90, const Cubic(.2, 1.15, .3, 1), _kort(k)),
                ],
                if (knapper.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (j, b) in knapper.indexed)
                        inn(AeInn.vcKnapp, 450, d0 + kort.length * 90 + 100 + j * 70, const Cubic(.2, 1.3, .3, 1), _Knapp(b: b, primar: j == 0, h: h)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kort(Object k) => switch (k) {
    'ingen' => AeIkkeFunnet(tekst: m.tekst),
    'alder' => const AeAlder(),
    'funn' => AeFunn(s: m.kort.first),
    'dor' => AeDor(note: m.dor!, h: h),
    'bytt' => AeBytt(onske: m.bytt!, alt: m.kort.firstOrNull, h: h),
    'kurv' => AeForslagKort(kurv: m.kurv!, h: h),
    'sammen' => AeSammen(c: m.sammen!, h: h),
    final Suggestion s => AeVareKort(s: s, kurv: m.kurv, h: h),
    final AeApp a => AeAppKort(a: a, h: h),
    _ => const SizedBox.shrink(),
  };
}

/// The words of a reply, each rising in (`vcOrd .38s`, .14 s + .03 s each).
class _Ord extends StatelessWidget {
  const _Ord({required this.ord, required this.ny});

  final List<String> ord;
  final bool ny;

  @override
  Widget build(BuildContext context) {
    final st = inter(14.5, weight: FontWeight.w600, height: 1.45);
    if (!ny) return Text(ord.join(' '), style: st);
    return LfOnce(
      ms: 140 + ord.length * 30.0 + 380,
      builder: (context, t, _) => Text.rich(
        TextSpan(
          children: [
            for (final (j, w) in ord.indexed)
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: aeInn(AeInn.ord, kfP(t, 140 + j * 30.0, 380), const Cubic(.2, .8, .3, 1), Alignment.center, Text(j < ord.length - 1 ? '$w ' : w, style: st)),
              ),
          ],
        ),
        style: st,
      ),
    );
  }
}

/// `knapper` — the orange first key with its chevron, then glass keys.
class _Knapp extends StatelessWidget {
  const _Knapp({required this.b, required this.primar, required this.h});

  final AeKnapp b;
  final bool primar;
  final AeHandling h;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: () => b.si != null ? h.si(b.si!) : (b.app != null ? h.app(b.app!) : null),
    child: CssBox(
      height: 38,
      radius: BorderRadius.circular(13),
      bg: primar ? kAeOransje : kAeSek,
      shadows: primar ? kAeOransjeSh : kAeSekSh,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(b.tekst.length > 28 ? b.tekst.substring(0, 28) : b.tekst, style: inter(12.5, weight: FontWeight.w800)),
          if (primar) ...[const SizedBox(width: 6), const AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3)],
        ],
      ),
    ),
  );
}

// ── Cards (`vcKort`) ────────────────────────────────────────────────────────

/// The card row: tile, title, line, and the orange price key or «I kurven».
class _KortRad extends StatelessWidget {
  const _KortRad({
    required this.tile,
    required this.tittel,
    required this.sub,
    this.pris,
    required this.cta,
    required this.lagt,
    required this.onTap,
  });

  final Widget tile;
  final String tittel;
  final String sub;
  final String? pris;
  final String cta;
  final bool lagt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 0,
    scale: .98,
    child: CssBox(
      radius: BorderRadius.circular(18),
      bg: kAeGlass,
      shadows: kAeGlassSh,
      padding: const EdgeInsets.all(9),
      child: Row(
        children: [
          tile,
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tittel, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13.5, em: -.01)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: aeTab(inter(11, weight: FontWeight.w700, color: kAeSub))),
              ],
            ),
          ),
          const SizedBox(width: 11),
          if (lagt)
            AeOnce(
              kind: AeInn.vcKnapp,
              ms: 400,
              curve: const Cubic(.2, 1.3, .3, 1),
              child: CssBox(
                radius: BorderRadius.circular(12),
                bg: const [
                  CssLinear(180, [Color.fromRGBO(130, 242, 210, .3), Color.fromRGBO(92, 224, 184, .12)]),
                ],
                shadows: const [
                  CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                  CssShadow(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .45)),
                ],
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AeIkon('M5 12l5 5 9-10', size: 11, stroke: 3.4, color: kAeMintLys),
                    const SizedBox(width: 5),
                    Text(AeCopy.lagtIKurven, style: inter(10.5, weight: FontWeight.w800)),
                  ],
                ),
              ),
            )
          else
            CssBox(
              radius: BorderRadius.circular(12),
              bg: kAeOransje,
              shadows: kAeOransjeSh,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pris != null) Text(pris!, style: aeTab(jakarta(13, height: 1))),
                  if (pris != null) const SizedBox(height: 1),
                  Text(cta, style: inter(9.5, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .95))),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// The 46 px tile (`k.tile`): the store's colour with its initials, or the
/// teal tile with an app icon.
class _Tile extends StatelessWidget {
  const _Tile({this.farge, this.ini, this.d});

  final Color? farge;
  final String? ini;
  final String? d;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 46,
    height: 46,
    radius: BorderRadius.circular(14),
    bg: farge != null
        ? [
            CssLinear(160, [farge!, farge!.withValues(alpha: .8)]),
          ]
        : const [
            CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1]),
          ],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
      CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(0, 0, 0, .22)),
      CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .08)),
      CssShadow(0, 8, 10, -6, Color.fromRGBO(3, 16, 24, .8)),
    ],
    child: Center(
      child: d != null ? AeIkon(d!, size: 22, stroke: 2.2) : Text(ini ?? '', style: jakarta(14, em: -.02)),
    ),
  );
}

/// A suggestion (`type:'vare'`): the store's tile, the item, «butikk · why»,
/// the price and «Legg i kurven» — or «Åpne» when it is a post, not an item.
class AeVareKort extends StatelessWidget {
  const AeVareKort({super.key, required this.s, this.kurv, required this.h});

  final Suggestion s;
  final AegilBasket? kurv;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final linje = kurv?.lines.where((l) => l.suggestionId == s.id).firstOrNull;
    final storeId = linje?.storeId ?? s.storeId;
    final navn = linje?.storeName ?? s.storeName ?? h.butikkNavn(storeId);
    final b = h.butikk(storeId);
    final vare = s.storeProductId != null;
    final ore = (linje?.priceOre ?? 0) > 0 ? linje!.priceOre : s.priceOre;
    final tittel = (linje?.name ?? s.headline ?? s.reason).trim();
    final sub = [if (navn != null && navn.isNotEmpty) navn, if (b != null) '${b.min}–${b.min + 10} min' else s.reason].join(' · ');
    final lagt = h.erLagt(s.id);
    return _KortRad(
      tile: _Tile(farge: storeId == null ? null : (b?.bg ?? HbButikk.farge(storeId)), ini: navn == null ? null : HbButikk.initialer(navn), d: navn == null ? 'M5 8h14l-1.5 11h-11zM9 8a3 3 0 0 1 6 0' : null),
      tittel: tittel,
      sub: sub,
      pris: vare && ore != null && ore > 0 ? '${(ore / 100).round()} kr' : null,
      cta: vare ? AeCopy.leggIKurven : AeCopy.aapne,
      lagt: lagt,
      onTap: () {
        if (lagt) return h.app(AeApp.kurv);
        if (vare) {
          h.leggKort(s);
        } else if (storeId != null) {
          h.aapneButikk(storeId);
        } else {
          h.app(AeApp.utforsk);
        }
      },
    );
  }
}

/// An app card (`VC_APP[type]`).
class AeAppKort extends StatelessWidget {
  const AeAppKort({super.key, required this.a, required this.h});

  final AeApp a;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final (t, s, d, cta) = switch (a) {
      AeApp.fiske => (AeCopy.appFiske, AeCopy.appFiskeSub, 'M3 12c3-5 9-6 13-3l4-3v12l-4-3c-4 3-10 2-13-3zM8 11.5h.01', AeCopy.appFiskeCta),
      AeApp.pose => (AeCopy.appPose, AeCopy.appPoseSub, 'M5 8h14l-1 12H6zM9 8V6a3 3 0 0 1 6 0v2', AeCopy.appPoseCta),
      AeApp.sporing => (AeCopy.appSporing, AeCopy.appSporingSub, 'M6 17a3 3 0 1 0 0-.1M18 17a3 3 0 1 0 0-.1M6 17l4-8h5l3 8M10 9l-1-3H7', AeCopy.appSporingCta),
      AeApp.poeng => (
        AeCopy.appPoeng,
        h.poeng() == null ? AeCopy.appPoeng : AeCopy.appPoengSub(h.poeng()!),
        'M12 3l2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.4 6.7 19.4l1.2-6L3.4 9.3l6-.7z',
        AeCopy.se,
      ),
      AeApp.kurv => (AeCopy.appKurv, AeCopy.appKurvSub, 'M5 8h14l-1.5 11h-11zM9 8a3 3 0 0 1 6 0', AeCopy.aapne),
      AeApp.utforsk => (AeCopy.appUtforsk, AeCopy.appUtforskSub, 'M12 3a9 9 0 1 0 .1 0M15.5 8.5l-2 5-5 2 2-5z', AeCopy.appUtforskCta),
    };
    return _KortRad(tile: _Tile(d: d), tittel: t, sub: s, cta: cta, lagt: false, onTap: () => h.app(a));
  }
}

// ── The reply states (`agForslag`, `agSammen`, … L4700–4790) ────────────────

/// `agForslag` — the basket Ægil put together: the store, the items, the
/// sum, «Derfor», «Legg alt i kurven» and «Bytt butikk». One store only: the
/// basket holds one store at a time.
class AeForslagKort extends StatelessWidget {
  const AeForslagKort({super.key, required this.kurv, required this.h});

  final AegilBasket kurv;
  final AeHandling h;

  static const List<List<Color>> _tint = [
    [Color(0xFFFBEFDA), Color(0xFFEBD3A6)],
    [Color(0xFFEAF3F5), Color(0xFFC9DFE5)],
    [Color(0xFFEAF3E6), Color(0xFFCFE3D0)],
  ];

  @override
  Widget build(BuildContext context) {
    final storeId = kurv.storeId;
    final linjer = kurv.lines.where((l) => l.storeProductId != null && l.priceOre > 0 && (storeId == null || l.storeId == storeId)).toList();
    final b = h.butikk(storeId);
    final navn = kurv.storeName ?? h.butikkNavn(storeId) ?? '';
    final ant = linjer.fold<int>(0, (n, l) => n + l.qty);
    final sum = linjer.fold<int>(0, (n, l) => n + l.priceOre * l.qty);
    final vist = linjer.take(linjer.length > 4 ? 3 : 4).toList();
    final rest = linjer.skip(vist.length).toList();
    final lagt = h.alleLagt(kurv);
    return CssBox(
      radius: BorderRadius.circular(24),
      clip: true,
      bg: const [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .06)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
        CssShadow(0, 22, 36, -20, Color.fromRGBO(4, 18, 26, .85)),
      ],
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: const Color.fromRGBO(255, 255, 255, .14),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
                  ),
                  alignment: Alignment.center,
                  child: AeIco(h.ikon(storeId), w: 22, h: 16, viewBox: h.ikon(storeId) == 'ico_fisk' ? '6 6 60 38' : '0 0 60 54'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(16, em: -.02)),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: kAeMint, boxShadow: [BoxShadow(color: kAeMint, blurRadius: 4)]),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              AeCopy.aapenMin(b?.min ?? 25, (b?.min ?? 25) + 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .66)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, l) in vist.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _Vare(navn: l.qty > 1 ? '${l.name} ×${l.qty}' : l.name, pris: '${(l.priceOre * l.qty / 100).round()} kr', tint: _tint[i % 3], bilde: h.bilde(l.storeProductId), ico: h.ikon(storeId) == 'ico_fisk' ? 'ico_mat' : h.ikon(storeId)),
                ],
                if (rest.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _Vare(
                    navn: rest.map((l) => l.name).join(' · '),
                    pris: '${(rest.fold<int>(0, (n, l) => n + l.priceOre * l.qty) / 100).round()} kr',
                    pluss: rest.length,
                  ),
                ],
              ],
            ),
          ),
          Container(margin: const EdgeInsets.fromLTRB(16, 14, 16, 0), height: 1, color: const Color.fromRGBO(255, 255, 255, .14)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(AeCopy.varer(ant), style: inter(12.5, color: const Color.fromRGBO(255, 255, 255, .66)))),
                Text('${(sum / 100).round()} kr', style: aeTab(jakarta(22, em: -.02))),
              ],
            ),
          ),
          if ((kurv.derfor ?? '').isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color.fromRGBO(92, 224, 184, .12),
                border: Border.all(color: const Color.fromRGBO(92, 224, 184, .24)),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${AeCopy.derfor} ', style: inter(11.5, weight: FontWeight.w800, color: kAeMint, height: 1.45)),
                    TextSpan(text: _liten(kurv.derfor!)),
                  ],
                ),
                style: inter(11.5, color: const Color(0xFF9FEBD5), height: 1.45),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: AePress(
                    key: const Key('a1_aegil_legg_alt'),
                    onTap: lagt ? () => h.app(AeApp.kurv) : () => h.leggAlt(kurv),
                    dy: 0,
                    scale: .97,
                    child: CssBox(
                      height: 46,
                      radius: BorderRadius.circular(15),
                      bg: const [
                        CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
                      ],
                      shadows: const [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
                        CssShadow(0, 3, 0, 0, Color.fromRGBO(150, 60, 15, .8)),
                        CssShadow(0, 14, 22, -12, Color.fromRGBO(120, 50, 10, .9)),
                      ],
                      child: Center(
                        child: Text(
                          lagt ? AeCopy.gaaTilKurven : (h.handler ? AeCopy.aegilLeggerAlt : AeCopy.leggAlt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(13.5, weight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                AePress(
                  onTap: () => h.si(AeCopy.sammenlignSi),
                  dy: 0,
                  scale: .95,
                  child: CssBox(
                    height: 46,
                    radius: BorderRadius.circular(15),
                    bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .12))],
                    shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26))],
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(child: Text(AeCopy.byttButikk, style: inter(13.5, weight: FontWeight.w800))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _liten(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}

/// One item in the basket card (64 wide: the 56 px picture, name, price).
class _Vare extends StatelessWidget {
  const _Vare({required this.navn, required this.pris, this.tint, this.bilde, this.pluss, this.ico = 'ico_mat'});

  final String navn;
  final String pris;
  final List<Color>? tint;
  final String? bilde;
  final int? pluss;
  final String ico;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pluss != null)
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color.fromRGBO(255, 255, 255, .1),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
            ),
            alignment: Alignment.center,
            child: Text('+$pluss', style: inter(12, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .75))),
          )
        else
          Container(
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(begin: const Alignment(-.42, -.9), end: const Alignment(.42, .9), colors: tint!),
              boxShadow: [BoxShadow(color: const Color.fromRGBO(4, 18, 26, .8), offset: const Offset(0, 6), blurRadius: cssSigma(12) * 2, spreadRadius: -8)],
            ),
            child: bilde != null
                ? Image.network(bilde!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Center(child: AeIco(ico, w: 32, h: 28)))
                : Center(child: AeIco(ico, w: 32, h: 28)),
          ),
        const SizedBox(height: 5),
        Text(navn, maxLines: 2, overflow: TextOverflow.ellipsis, style: inter(10, weight: FontWeight.w700, height: 1.2, color: const Color.fromRGBO(255, 255, 255, .9))),
        Text(pris, style: aeTab(inter(10, weight: FontWeight.w400, color: const Color.fromRGBO(255, 255, 255, .55)))),
      ],
    ),
  );
}

/// `agSammen` — up to three prices side by side, the cheapest framed.
class AeSammen extends StatelessWidget {
  const AeSammen({super.key, required this.c, required this.h});

  final Map<String, dynamic> c;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final rader = ((c['products'] as List?) ?? const []).whereType<Map>().map((e) => e.cast<String, dynamic>()).where((p) => p['price_ore'] != null).toList();
    final billigst = c['cheapest_id'];
    rader.sort((a, b) => (a['product_identity_id'] == billigst ? 0 : 1).compareTo(b['product_identity_id'] == billigst ? 0 : 1));
    final vis = rader.take(3).toList();
    final note = '${c['note'] ?? ''}'.trim();
    return CssBox(
      radius: BorderRadius.circular(20),
      bg: const [CssSolid(Colors.white)],
      shadows: const [
        CssShadow(0, 2, 3, -1, Color.fromRGBO(120, 80, 40, .12)),
        CssShadow(0, 20, 36, -22, Color.fromRGBO(30, 79, 92, .5)),
      ],
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, p) in vis.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _Kolonne(p: p, best: p['product_identity_id'] == billigst, h: h)),
              ],
              for (var i = vis.length; i < 3; i++) ...[const SizedBox(width: 6), const Expanded(child: SizedBox())],
            ],
          ),
          const SizedBox(height: 8),
          Text(note.isEmpty ? AeCopy.prisNote : note, style: inter(10.5, color: const Color(0xFF57534B))),
        ],
      ),
    );
  }
}

class _Kolonne extends StatelessWidget {
  const _Kolonne({required this.p, required this.best, required this.h});

  final Map<String, dynamic> p;
  final bool best;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final storeId = (p['store_id'] as num?)?.toInt();
    final enhet = [if (p['unit_amount'] != null) '${p['unit_amount']}', if (p['unit'] != null) '${p['unit']}'].join(' ');
    final pris = ((p['price_ore'] as num).toDouble() / 100).round();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: best ? const Color.fromRGBO(220, 233, 236, .7) : const Color(0xFFF5F3EF),
            border: best ? Border.all(color: kAeTeal, width: 1.5) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(h.butikkNavn(storeId) ?? '${p['brand'] ?? p['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, weight: FontWeight.w800, color: kAeInk)),
              Text([enhet, '${p['name'] ?? ''}'].where((x) => x.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(9.5, weight: FontWeight.w400, color: const Color(0xFF57534B))),
              const SizedBox(height: 4),
              Text('$pris kr', style: aeTab(jakarta(15, color: kAeInk))),
              const SizedBox(height: 6),
              AePress(
                onTap: storeId == null ? null : () => h.aapneButikk(storeId),
                dy: 0,
                scale: .96,
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: best ? const Color(0xFFF26D3D) : const Color(0xFFDCE9EC)),
                  child: Text(AeCopy.velg, style: inter(11.5, weight: FontWeight.w800, color: kAeInk)),
                ),
              ),
            ],
          ),
        ),
        if (best)
          Positioned(
            top: -8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: kAeTeal),
              child: Text(AeCopy.billigst, style: inter(8.5, weight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

/// `agIkkeFunnet` — the white card with Ægil saying sorry.
class AeIkkeFunnet extends StatelessWidget {
  const AeIkkeFunnet({super.key, required this.tekst});

  final String tekst;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(20),
    bg: const [CssSolid(Colors.white)],
    shadows: const [
      CssShadow(0, 2, 3, -1, Color.fromRGBO(120, 80, 40, .12)),
      CssShadow(0, 18, 32, -22, Color.fromRGBO(30, 79, 92, .5)),
    ],
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(width: 52, height: 52, color: const Color(0xFFEAF2F4), child: Image.asset(aePose('sorry'), fit: BoxFit.cover)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AeCopy.ikkeFunnet, style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFF8C847C))),
              const SizedBox(height: 2),
              Text(tekst, style: inter(13, weight: FontWeight.w700, height: 1.35, color: kAeInk)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// `agAldersblokk` — 18+, not verified.
class AeAlder extends StatelessWidget {
  const AeAlder({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      border: Border.all(color: const Color.fromRGBO(185, 68, 26, .35), width: 1.5),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color.fromRGBO(185, 68, 26, .1)),
          alignment: Alignment.center,
          child: const AeIkon('M7.5 10h9a2.5 2.5 0 0 1 2.5 2.5v5a2.5 2.5 0 0 1-2.5 2.5h-9A2.5 2.5 0 0 1 5 17.5v-5A2.5 2.5 0 0 1 7.5 10zM8 10V7.5a4 4 0 0 1 8 0V10', size: 18, stroke: 2, color: Color(0xFFB9441A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AeCopy.alderTittel, style: inter(13, weight: FontWeight.w800, color: kAeInk)),
              Text(AeCopy.alderLinje, style: inter(11, color: const Color(0xFF57534B))),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: kAeTeal),
          alignment: Alignment.center,
          child: Text(AeCopy.bankId, style: inter(12, weight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

/// `agFunn` — the teal «Funn» card with the northern-light streak.
class AeFunn extends StatelessWidget {
  const AeFunn({super.key, required this.s});

  final Suggestion s;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(20),
    clip: true,
    bg: const [
      CssLinear(160, [Color(0xFF173E48), kAeTeal]),
    ],
    shadows: const [CssShadow(0, 20, 36, -20, Color.fromRGBO(15, 31, 43, .7))],
    child: Stack(
      children: [
        Positioned(left: -16, top: -30, width: 390, height: 90, child: IgnorePointer(child: _Nordlys())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color.fromRGBO(92, 224, 184, .18),
                  border: Border.all(color: const Color.fromRGBO(92, 224, 184, .4)),
                ),
                alignment: Alignment.center,
                child: const AeIkon('M12 3l2.4 5.6 6 .6-4.5 4 1.4 5.9L12 16l-5.3 3.1 1.4-5.9-4.5-4 6-.6z', size: 18, stroke: 2.2, color: kAeMint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AeCopy.funn, style: inter(11, weight: FontWeight.w800, color: kAeMint)),
                    const SizedBox(height: 1),
                    Text(s.headline ?? s.reason, style: jakarta(15, weight: FontWeight.w700, height: 1.25, color: const Color(0xFFF5F3EF))),
                    const SizedBox(height: 3),
                    Text(s.reason, style: inter(11.5, weight: FontWeight.w500, color: const Color(0xFFB9CBD5))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// `<path d="M0 70 C80 30 160 60 240 26 C300 4 350 20 390 0" stroke="url(#a-nl)"
/// stroke-width="22" opacity=".7" filter:blur(10px); animation: glod 4s>` at
/// opacity .6.
class _Nordlys extends StatelessWidget {
  static final Path _p = svgSti('M0 70 C80 30 160 60 240 26 C300 4 350 20 390 0');

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      frozenMs: 2000,
      builder: (context, t, _) {
        final g = kf((t / 4000) % 1.0, const [0, .5, 1], const [.7, 1, .7], cssEaseInOut);
        return Opacity(
          opacity: .6 * .7 * g,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: CustomPaint(size: const Size(390, 90), painter: _StrekPainter(_p)),
          ),
        );
      },
    ),
  );
}

class _StrekPainter extends CustomPainter {
  _StrekPainter(this.p);
  final Path p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(390, 0), const [kAeMint, Color(0xFF9C7BE8)]),
    );
  }

  @override
  bool shouldRepaint(_StrekPainter old) => false;
}

/// `agFiks` with a door note: the receipt-style line «Beskjed til budet» and
/// «Lagre» (`agent/door-note`).
class AeDor extends StatelessWidget {
  const AeDor({super.key, required this.note, required this.h});

  final String note;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final lagret = h.dorLagret(note);
    return CssBox(
      radius: BorderRadius.circular(18),
      bg: const [CssSolid(Colors.white)],
      shadows: kAePapirSh,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color.fromRGBO(30, 79, 92, .1)),
            alignment: Alignment.center,
            child: const AeIkon('M4 7h16M4 12h10M4 17h7', size: 14, stroke: 2.2, color: kAeTeal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AeCopy.beskjedTilBudet, style: inter(11, weight: FontWeight.w800, color: const Color(0xFF8C847C))),
                const SizedBox(height: 1),
                Text('«$note»', style: inter(12.5, weight: FontWeight.w700, color: lagret ? const Color(0xFF2E6B47) : kAeInk)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AePress(
            onTap: lagret ? null : () => h.lagreDor(note),
            dy: 0,
            scale: .94,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFDCE9EC)),
              child: Text(lagret ? AeCopy.lagret : AeCopy.lagre, style: inter(12, weight: FontWeight.w800, color: kAeInk)),
            ),
          ),
        ],
      ),
    );
  }
}

/// `agFiks` with a swap: «Bytt» — what was asked for → the first match Ægil
/// has, with its reason; «Bytt» puts the match in the basket.
class AeBytt extends StatefulWidget {
  const AeBytt({super.key, required this.onske, required this.alt, required this.h});

  final String onske;
  final Suggestion? alt;
  final AeHandling h;

  @override
  State<AeBytt> createState() => _AeByttState();
}

class _AeByttState extends State<AeBytt> {
  bool _beholdt = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.alt;
    final lagt = a != null && widget.h.erLagt(a.id);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _beholdt ? .55 : 1,
      child: CssBox(
        radius: BorderRadius.circular(18),
        bg: const [CssSolid(Colors.white)],
        shadows: kAePapirSh,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AeCopy.bytt, style: inter(11, weight: FontWeight.w800, color: const Color(0xFF8C847C))),
            const SizedBox(height: 6),
            Row(
              children: [
                Opacity(
                  opacity: .5,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(begin: Alignment(-.42, -.9), end: Alignment(.42, .9), colors: [Color(0xFFF6D9B4), Color(0xFFD2854A)]),
                    ),
                    alignment: Alignment.center,
                    child: const AeIco('ico_mat', w: 26, h: 24, viewBox: '13 5 34 32'),
                  ),
                ),
                const SizedBox(width: 10),
                const AeIkon('M5 12h14M13 6l6 6-6 6', size: 18, color: kAeTeal),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(begin: Alignment(-.42, -.9), end: Alignment(.42, .9), colors: [Color(0xFFDCE9EC), Color(0xFF9FC3CC)]),
                  ),
                  alignment: Alignment.center,
                  child: const AeIco('ico_mat', w: 26, h: 24, viewBox: '13 5 34 32'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a == null ? widget.onske : '${widget.onske} → ${a.headline ?? a.reason}',
                        style: inter(12.5, weight: FontWeight.w700, height: 1.35, color: kAeInk),
                      ),
                      if (a != null) ...[
                        const SizedBox(height: 2),
                        Text(AeCopy.grunn(_liten(a.reason)), style: inter(10.5, color: const Color(0xFF57534B))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (a != null && !_beholdt) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AePress(
                      onTap: lagt ? () => widget.h.app(AeApp.kurv) : () => widget.h.leggKort(a),
                      dy: 0,
                      scale: .97,
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFF26D3D)),
                        child: Text(lagt ? AeCopy.lagtIKurven : AeCopy.bytt, style: inter(12.5, weight: FontWeight.w800, color: kAeInk)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AePress(
                    onTap: () => setState(() => _beholdt = true),
                    dy: 0,
                    scale: .95,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFDCE9EC)),
                      child: Text(AeCopy.behold, style: inter(12.5, weight: FontWeight.w800, color: kAeInk)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _liten(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}

// ── Thinking and the chips (`vcTenker`, `vcHarForslag`) ─────────────────────

/// Ægil thinking: the avatar with its pulsing ring (`vcPuls 1.4s`) and three
/// dots (`vcPrikk 1.1s`).
class AeTenker extends StatelessWidget {
  const AeTenker({super.key});

  @override
  Widget build(BuildContext context) => AeOnce(
    kind: AeInn.vcBoble,
    ms: 350,
    curve: const Cubic(.2, 1.2, .3, 1),
    alignment: Alignment.bottomLeft,
    child: RepaintBoundary(
      child: LfLoop(
        frozenMs: 400,
        builder: (context, t, _) {
          final pp = (t / 1400) % 1.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -4,
                      top: -4,
                      right: -4,
                      bottom: -4,
                      child: Opacity(
                        opacity: kf(pp, const [0, 1], const [.9, 0], cssEaseOut),
                        child: Transform.scale(
                          scale: kf(pp, const [0, 1], const [.9, 1.35], cssEaseOut),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color.fromRGBO(92, 224, 184, .7), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const AeAvatar(),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              CssBox(
                height: 40,
                radius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(6), bottomRight: Radius.circular(20)),
                bg: kAeGlass,
                shadows: kAeGlassSh,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      Builder(
                        builder: (context) {
                          final p = ((t - i * 150) / 1100) % 1.0;
                          return Opacity(
                            opacity: kf(p, const [0, .3, .6, 1], const [.45, 1, .45, .45], cssEaseInOut),
                            child: Transform.translate(
                              offset: Offset(0, kf(p, const [0, .3, .6, 1], const [0, -5, 0, 0], cssEaseInOut)),
                              child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// The chips after a reply (`vcForslagL`): dark pills with the mint
/// return arrow, each sent to Ægil as it reads.
class AeForslag extends StatelessWidget {
  const AeForslag({super.key, required this.forslag, required this.delay, required this.onTap});

  final List<String> forslag;
  final double delay;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 41),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (j, f) in forslag.take(3).indexed)
          AeOnce(
            key: ValueKey('f$f'),
            kind: AeInn.vcKnapp,
            ms: 420,
            delay: delay + j * 70,
            curve: const Cubic(.2, 1.3, .3, 1),
            child: AePress(
              key: Key('a1_aegil_forslag_$j'),
              onTap: () => onTap(f),
              dy: 2,
              child: CssBox(
                radius: BorderRadius.circular(999),
                bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .32))],
                shadows: const [
                  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(159, 240, 212, .38)),
                  CssShadow(0, 6, 10, -8, Color.fromRGBO(3, 16, 24, .8)),
                ],
                padding: const EdgeInsets.fromLTRB(11, 8, 13, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AeIkon('M4 5v6a4 4 0 0 0 4 4h12M15 10l5 5-5 5', size: 10, stroke: 3, color: kAeMintLys),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        f.length > 32 ? f.substring(0, 32) : f,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(12, weight: FontWeight.w800, color: const Color(0xFFDFF8EE)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// «Ny prat med Ægil» (`vcNy`).
class AeNyPrat extends StatelessWidget {
  const AeNyPrat({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: AePress(
      key: const Key('a1_aegil_ny_prat'),
      onTap: onTap,
      dy: 1.5,
      child: CssBox(
        radius: BorderRadius.circular(999),
        bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
        shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14))],
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AeIkon('M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5', size: 11, stroke: 2.8, color: kAeMintLys),
            const SizedBox(width: 6),
            Text(AeCopy.nyPrat, style: inter(11, weight: FontWeight.w800, color: kAeSub)),
          ],
        ),
      ),
    ),
  );
}

/// The allergen line under a basket (`agAllergen`).
class AeAllergen extends StatelessWidget {
  const AeAllergen({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 41, right: 18),
    child: Text(AeCopy.allergen, style: inter(11.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .6))),
  );
}
