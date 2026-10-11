import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../data/ops/tracking_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../common/home/bergen/bergen_kit.dart' show bergenSvg;
import 'leveringskode_card.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';

// ── Sporing · the bottom panel and the Bestillingsdetaljer sheet ────────────
// Prototype L7098–7277 (panel) and L7007–7097 (sheet).

/// One order line for the Detaljer sheet.
class SpLinje {
  const SpLinje({required this.navn, required this.antall, required this.sum, this.valg = '', this.tillegg = ''});

  final String navn;
  final int antall;
  final double sum;
  final String valg;
  final String tillegg;
}

/// What the sheet prints about the order, from `ops.customer.orders` and
/// the store record.
class SpOrdre {
  const SpOrdre({
    this.linjer = const [],
    this.total = 0,
    this.adresse = '',
    this.bestilt,
    this.betalt = true,
    this.butikk = '',
    this.butikkAdresse = '',
    this.logo,
    this.ordreNr = '',
    this.kode = '',
    this.dorNotat = '',
  });

  final List<SpLinje> linjer;
  final double total;
  final String adresse;
  final DateTime? bestilt;
  final bool betalt;
  final String butikk;
  final String butikkAdresse;
  final String? logo;
  final String ordreNr;
  final String kode;
  final String dorNotat;

  int get antall => linjer.fold(0, (a, l) => a + l.antall);

  /// `Pizza margherita · Pad thai`.
  String get vareLinje => linjer.map((l) => l.navn).join(' · ');

  /// `1× Classic` lines.
  List<String> get korteLinjer => linjer.map((l) => '${l.antall}× ${l.navn}').toList();

  static SpOrdre fraJson(Map<String, dynamic> j, {String? butikkAdresse, String? logo}) {
    final rows = j['items'];
    final linjer = <SpLinje>[];
    if (rows is List) {
      for (final r in rows) {
        if (r is! Map) continue;
        final navn = '${r['name'] ?? r['product_name'] ?? ''}';
        if (navn.isEmpty) continue;
        final antall = ((r['quantity'] ?? r['num_of_items'] ?? r['qty'] ?? 1) as num).toInt();
        final pris = ((r['unit_price'] ?? r['price'] ?? r['price_for_one'] ?? 0) as num).toDouble();
        linjer.add(SpLinje(navn: navn, antall: antall, sum: pris * antall, valg: '${r['options'] ?? r['valg'] ?? ''}'));
      }
    }
    return SpOrdre(
      linjer: linjer,
      total: ((j['total_pay'] ?? j['total'] ?? 0) as num).toDouble(),
      adresse: '${j['delivery_address'] ?? ''}',
      bestilt: DateTime.tryParse('${j['ordered_at'] ?? ''}')?.toLocal(),
      betalt: j['paid'] != false,
      butikk: '${j['store_name'] ?? j['store']?['name'] ?? ''}',
      butikkAdresse: butikkAdresse ?? '${j['store']?['address'] ?? ''}',
      logo: logo,
      ordreNr: '${j['order_no'] ?? j['order_id'] ?? ''}',
      kode: '${j['code'] ?? ''}',
    );
  }
}

/// The dark bottom panel: the slot (vervebillett / Leveringskode /
/// Ægil-veileder), the four stages, Sammendrag · Detaljer, and «Avslutt
/// bestillingen» or the Fjordfiske · chat · ring row.
class SpPanel extends StatelessWidget {
  const SpPanel({
    super.key,
    required this.tracking,
    required this.linje,
    required this.offline,
    required this.slotKode,
    required this.slotVerv,
    required this.onSammendrag,
    required this.onDetaljer,
    required this.onAvslutt,
    required this.onFjordfiske,
    required this.onVisVeien,
    required this.onChat,
    required this.onRing,
    required this.onLukkVerv,
    required this.onDelBillett,
    required this.onKopierBillett,
    this.vervKode = '',
    this.bunn = 0,
    this.poengNeste,
  });

  final OpsTracking tracking;
  final String linje;
  final bool offline;
  final bool slotKode, slotVerv;
  final String vervKode;
  final VoidCallback onSammendrag, onDetaljer, onAvslutt, onFjordfiske, onVisVeien, onChat, onRing, onLukkVerv, onDelBillett, onKopierBillett;

  /// Extra padding under the panel (the safe area).
  final double bunn;

  /// Points per stage for «Neste: X · +N poeng»: the order's real total
  /// split over the stages (`splitPointsByStage`). Null: no numbers.
  final List<int>? poengNeste;

  static const Color _fyll1 = Color(0xFFE95C2C);
  static const Color _fyll2 = Color(0xFFF58A55);

  @override
  Widget build(BuildContext context) {
    final t = tracking;
    final s = t.stage.clamp(0, 3);
    final hent = t.isPickup;
    final navn = SporingCopy.stages(hent);
    final hentKlar = hent && s == 2;
    final kode = t.deliveryCode;
    // The screen's one blur layer: `backdrop-filter: blur(30px)` on the panel.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: CssBox(
          radius: const BorderRadius.vertical(top: Radius.circular(28)),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bunn),
          border: Border(top: BorderSide(color: rgba(255, 255, 255, .22))),
          bg: [
            CssLinear(180, [rgba(42, 98, 114, .92), rgba(23, 62, 72, .96)]),
          ],
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)), CssShadow(0, -20, 46, -20, rgba(4, 18, 26, .8))],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: rgba(255, 255, 255, .3), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 12),
              if (slotVerv) ...[
                _Vervebillett(kode: vervKode, onLukk: onLukkVerv, onDel: onDelBillett, onKopier: onKopierBillett),
                const SizedBox(height: 14),
              ] else if (slotKode && kode != null) ...[
                LeveringskodeCard(code: kode, offline: offline, tracking: t),
                const SizedBox(height: 14),
              ] else ...[
                _Veileder(tracking: t, linje: linje, navn: navn, poeng: poengNeste),
                const SizedBox(height: 14),
              ],
              _Stadier(key: const Key('a1_sporing_stepper'), steg: s, navn: navn, henting: hent),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Nokkel(
                      key: const Key('a1_sporing_sammendrag'),
                      tile: kSpTileVarm,
                      ikon: kSpIkonPose,
                      ikonFarge: const Color(0xFF6E4212),
                      tekst: SporingCopy.a1_sporing_sammendrag,
                      onTap: onSammendrag,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _Nokkel(
                      key: const Key('a1_sporing_detaljer'),
                      tile: kSpTileTeal,
                      ikon: kSpIkonKvittering,
                      ikonFarge: kSpPaperInk,
                      tekst: SporingCopy.a1_sporing_detaljer,
                      onTap: onDetaljer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              if (s == 3)
                _Avslutt(onTap: onAvslutt)
              else
                Row(
                  children: [
                    Expanded(
                      child: hentKlar
                          ? _BredNokkel(
                              key: const Key('a1_sporing_vis_veien'),
                              ikon: spIkon(kSpIkonPin, size: 17, color: const Color(0xFF1B4A57), extra: kSpIkonPinExtra),
                              tittel: SporingCopy.a1_sporing_vis_veien_knapp,
                              under: (t.store?.address ?? '').split(',').first.trim(),
                              pil: true,
                              onTap: onVisVeien,
                            )
                          : _BredNokkel(
                              key: const Key('a1_sporing_fjordfiske'),
                              ikon: bergenSvg('sveipstakk', width: 20, height: 18),
                              tittel: SporingCopy.a1_sporing_fjordfiske,
                              under: SporingCopy.a1_sporing_mens_du_venter_kort,
                              onTap: onFjordfiske,
                            ),
                    ),
                    const SizedBox(width: 11),
                    if (!hent)
                      SpGlass(
                        key: const Key('a1_sporing_chat'),
                        width: 54,
                        height: 54,
                        onTap: onChat,
                        semantics: SporingCopy.a1_sporing_chat_bud,
                        child: Center(child: spIkon(kSpIkonChat, size: 18, width: 2)),
                      )
                    else if (!hentKlar)
                      SpGlass(
                        key: const Key('a1_sporing_vis_veien'),
                        width: 54,
                        height: 54,
                        onTap: onVisVeien,
                        semantics: SporingCopy.a1_sporing_vis_veien_knapp,
                        child: Center(child: spIkon(kSpIkonPin, size: 18, width: 2, extra: kSpIkonPinExtra)),
                      ),
                    if (!hent || !hentKlar) const SizedBox(width: 11),
                    Semantics(
                      button: true,
                      label: SporingCopy.a1_sporing_ring_butikken,
                      child: LfPress(
                        key: const Key('a1_sporing_ring'),
                        onTap: onRing,
                        dy: 2.5,
                        child: CssBox(
                          width: 54,
                          height: 54,
                          radius: BorderRadius.circular(16),
                          bg: const [
                            CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                          ],
                          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .4)), const CssShadow(0, 3, 0, 0, Color(0xFFC4491A)), CssShadow(0, 12, 18, -9, rgba(200, 70, 25, .9))],
                          child: Center(child: spIkon(kSpIkonTelefon, size: 17, width: 2)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Ægil-veileder**: the avatar with the gold ring glowing, «Ægil · følger
/// ærendet ditt», the line and the «Neste: …» chip.
class _Veileder extends StatelessWidget {
  const _Veileder({required this.tracking, required this.linje, required this.navn, required this.poeng});

  final OpsTracking tracking;
  final String linje;
  final List<String> navn;
  final List<int>? poeng;

  @override
  Widget build(BuildContext context) {
    final t = tracking;
    final s = t.stage.clamp(0, 3);
    final bilde = s == 3
        ? 'popup'
        : s == 2 && !t.isPickup && !t.isPartner
        ? ((t.courier?.onBike ?? true) ? 'bike' : 'van')
        : s == 0
        ? 'wait'
        : 'front';
    final hint = t.findingCourier
        ? SporingCopy.a1_sporing_finner_bud_hint
        : s == 3
        ? (poeng == null ? SporingCopy.a1_sporing_fullfort : SporingCopy.a1_sporing_fullfort_poeng(poeng!.fold(0, (a, b) => a + b)))
        : (poeng == null ? SporingCopy.a1_sporing_neste(navn[s + 1]) : SporingCopy.a1_sporing_neste_poeng(navn[s + 1], poeng![s + 1]));
    return CssBox(
      key: const Key('a1_sporing_veileder'),
      radius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      border: Border.all(color: rgba(255, 255, 255, .18)),
      bg: [
        CssLinear(180, [rgba(255, 255, 255, .12), rgba(255, 255, 255, .05)]),
      ],
      shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .25)), CssShadow(0, 10, 18, -12, rgba(4, 18, 26, .8))],
      child: Row(
        children: [
          LfLoop(
            builder: (context, t, child) {
              // guideGlod 2.6s
              final p = (t / 2600) % 1.0;
              final a = kf(p, const [0, .5, 1], const [.35, .7, .35], cssEaseInOut);
              final b = kf(p, const [0, .5, 1], const [.25, .55, .25], cssEaseInOut);
              final r = kf(p, const [0, .5, 1], const [12, 22, 12], cssEaseInOut);
              return DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: rgba(92, 224, 184, a), spreadRadius: 1),
                    BoxShadow(color: rgba(92, 224, 184, b), blurRadius: r),
                  ],
                ),
                child: child,
              );
            },
            child: Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(center: Alignment(0, -.4), colors: [Color(0xFF2A6272), Color(0xFF173E48)], stops: [0, .8]),
                boxShadow: [
                  BoxShadow(color: rgba(255, 255, 255, .3), offset: const Offset(0, 1.5), blurStyle: BlurStyle.inner),
                  const BoxShadow(color: Color(0xFFF2C14E), spreadRadius: 2),
                  BoxShadow(color: rgba(4, 18, 26, .8), offset: const Offset(0, 4), blurRadius: 8, spreadRadius: -3),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 24 - (bilde == 'bike' || bilde == 'van' ? 26 : 25),
                    bottom: bilde == 'bike' || bilde == 'van' ? -2 : -3,
                    child: aegil(bilde, w: bilde == 'bike' || bilde == 'van' ? 52 : 50),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(SporingCopy.a1_sporing_aegil, style: jakarta(11, em: -.01)),
                    const SizedBox(width: 6),
                    Text(
                      SporingCopy.a1_sporing_folger.toUpperCase(),
                      style: inter(9.5, weight: FontWeight.w800, em: .08, color: kSpMintLight),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SpBobleInn(
                  key: ValueKey(linje),
                  child: Text(
                    linje,
                    key: const Key('a1_sporing_linje'),
                    style: inter(12, weight: FontWeight.w700, height: 1.35, color: kSpSub),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                  decoration: BoxDecoration(
                    color: rgba(92, 224, 184, .14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: rgba(92, 224, 184, .4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kSpMint,
                          boxShadow: [BoxShadow(color: kSpMint, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hint,
                        key: const Key('a1_sporing_neste_hint'),
                        style: inter(10, weight: FontWeight.w800, color: kSpMintLight),
                      ),
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
}

/// **Sporing · stadier**: the bar, the fill and four nodes with labels.
class _Stadier extends StatelessWidget {
  const _Stadier({super.key, required this.steg, required this.navn, required this.henting});

  final int steg;
  final List<String> navn;
  final bool henting;

  @override
  Widget build(BuildContext context) {
    final s = steg;
    final labels = [navn[0], navn[1], henting ? SporingCopy.a1_sporing_klar_knapp : navn[2], navn[3]];
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final fyll =
            (w * .75) *
            (s <= 0
                ? 0
                : s >= 3
                ? 1
                : s / 3);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: w * .125,
              right: w * .125,
              top: 9,
              height: 6,
              child: CssBox(
                radius: BorderRadius.circular(99),
                bg: [CssSolid(rgba(0, 0, 0, .3))],
                shadows: [CssShadow.inset(0, 1.5, 3, 0, rgba(0, 0, 0, .5)), CssShadow.inset(0, -1, 0, 0, rgba(255, 255, 255, .14))],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: const Cubic(.3, .9, .3, 1),
              left: w * .125,
              top: 9,
              height: 6,
              width: fyll,
              child: CssBox(
                radius: BorderRadius.circular(99),
                bg: const [
                  CssLinear(90, [SpPanel._fyll1, SpPanel._fyll2, kSpMint], [0, .4, 1]),
                ],
                shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .45)), CssShadow(0, 0, 10, 0, rgba(92, 224, 184, .35))],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Column(
                      children: [
                        _Node(ferdig: s > i, naa: s == i),
                        const SizedBox(height: 9),
                        Text(
                          labels[i],
                          key: Key('a1_sporing_stadie_$i'),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: inter(
                            10.5,
                            weight: FontWeight.w800,
                            color: s == i
                                ? const Color(0xFFFFB27A)
                                : s > i
                                ? kSpMintLight
                                : rgba(255, 255, 255, .55),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.ferdig, required this.naa});

  final bool ferdig, naa;

  @override
  Widget build(BuildContext context) {
    final bg = ferdig
        ? const CssLinear(180, [Color(0xFF5CE0B8), Color(0xFF2FB893)])
        : naa
        ? const CssLinear(180, [Color(0xFFF58A55), Color(0xFFE95C2C)])
        : const CssLinear(180, [Color(0xFF2A6272), Color(0xFF173E48)]);
    final sh = ferdig
        ? [
            CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .6)),
            CssShadow(0, 0, 0, 3.5, rgba(15, 45, 55, .7)),
            CssShadow(0, 2, 0, 0, rgba(20, 90, 70, .8)),
            CssShadow(0, 6, 9, -5, rgba(6, 40, 30, .8)),
          ]
        : naa
        ? [
            CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .5)),
            CssShadow(0, 0, 0, 4, rgba(15, 45, 55, .75)),
            CssShadow(0, 2, 0, 0, rgba(150, 55, 20, .9)),
            CssShadow(0, 8, 12, -5, rgba(200, 80, 35, .85)),
            CssShadow(0, 0, 0, 8, rgba(242, 109, 61, .24)),
          ]
        : [
            CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .22)),
            CssShadow(0, 0, 0, 2, rgba(255, 255, 255, .28)),
            CssShadow(0, 0, 0, 4, rgba(15, 45, 55, .7)),
            CssShadow(0, 1.5, 0, 0, rgba(0, 0, 0, .3)),
          ];
    return CssBox(
      width: 24,
      height: 24,
      radius: BorderRadius.circular(99),
      bg: [bg],
      shadows: sh,
      child: ferdig ? Center(child: spIkon(kSpIkonHake, size: 12, color: const Color(0xFF0F3A32), width: 3.2)) : null,
    );
  }
}

/// A Sammendrag / Detaljer key (46 tall, radius 16).
class _Nokkel extends StatelessWidget {
  const _Nokkel({super.key, required this.tile, required this.ikon, required this.ikonFarge, required this.tekst, required this.onTap});

  final List<Color> tile;
  final String ikon;
  final Color ikonFarge;
  final String tekst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SpGlass(
    height: 46,
    onTap: onTap,
    semantics: tekst,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpTile(
          size: 28,
          radius: 9,
          colors: tile,
          inner: tile == kSpTileTeal ? rgba(20, 60, 72, .3) : rgba(90, 60, 20, .3),
          child: spIkon(ikon, size: 14, color: ikonFarge, width: 2.4),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            tekst,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: inter(12.5, weight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

/// The Fjordfiske / Vis veien key with its tile and two lines.
class _BredNokkel extends StatelessWidget {
  const _BredNokkel({super.key, required this.ikon, required this.tittel, required this.under, required this.onTap, this.pil = false});

  final Widget ikon;
  final String tittel, under;
  final VoidCallback onTap;
  final bool pil;

  @override
  Widget build(BuildContext context) => SpGlass(
    onTap: onTap,
    semantics: tittel,
    padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
    child: Row(
      children: [
        CssBox(
          width: 34,
          height: 34,
          radius: BorderRadius.circular(12),
          bg: const [
            CssLinear(180, [Color(0xFFEAF2F4), Color(0xFFD2E1E5)]),
          ],
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .95)), CssShadow.inset(0, -2, 4, 0, rgba(30, 79, 92, .18))],
          child: Center(child: ikon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tittel, maxLines: 1, softWrap: false, style: inter(11.5, weight: FontWeight.w800, em: -.01)),
              Text(
                under,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(9.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .62)),
              ),
            ],
          ),
        ),
        if (pil) spIkon(kSpIkonPil, size: 14, color: kSpMintLight, width: 2.8),
      ],
    ),
  );
}

/// «Avslutt bestillingen» — the floating orange pill (`stigOpp` in,
/// `aeKnSvev` forever).
class _Avslutt extends StatelessWidget {
  const _Avslutt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 700,
    builder: (context, t, child) {
      final p = cssKlistre.transform(kfP(t, 200, 500));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 26 * (1 - p)), child: child),
      );
    },
    child: SpSvev(
      phase: 1600,
      child: Semantics(
        button: true,
        label: SporingCopy.a1_sporing_avslutt_bestillingen,
        child: LfPress(
          key: const Key('a1_sporing_avslutt'),
          onTap: onTap,
          dy: 2,
          child: CssBox(
            height: 54,
            radius: BorderRadius.circular(999),
            bg: const [
              CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)]),
            ],
            shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .4)), CssShadow.inset(0, -3, 6, 0, rgba(150, 40, 10, .3))],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                spIkon(kSpIkonHake, size: 18, width: 2.6),
                const SizedBox(width: 10),
                Text(SporingCopy.a1_sporing_avslutt_bestillingen, style: jakarta(15, em: -.01)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// **Levert · vervebillett** (L7100): the ticket, «VERV EN VENN», Del /
/// Kopier — shown in the slot right after a purchase.
class _Vervebillett extends StatelessWidget {
  const _Vervebillett({required this.kode, required this.onLukk, required this.onDel, required this.onKopier});

  final String kode;
  final VoidCallback onLukk, onDel, onKopier;

  @override
  Widget build(BuildContext context) => SpBobleInn(
    dur: 450,
    child: CssBox(
      key: const Key('a1_sporing_verv'),
      radius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(12),
      border: Border.all(color: rgba(255, 255, 255, .2)),
      bg: [
        CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .06)]),
      ],
      shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .25)), CssShadow(0, 10, 18, -12, rgba(4, 18, 26, .8))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Transform.rotate(
                  angle: rad(-4),
                  child: SizedBox(
                    width: 108,
                    height: 50,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CssBox(
                            radius: BorderRadius.circular(9),
                            bg: const [CssSolid(Color(0xFFFBF7EE))],
                            shadows: [const CssShadow(0, 0, 0, 2, Color(0xFFFFFFFF)), CssShadow(0, 3, 0, 0, rgba(180, 170, 150, .9)), CssShadow(0, 8, 14, -8, rgba(0, 8, 12, .7))],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: rgba(35, 32, 29, .3), width: 1.5)),
                            ),
                            child: Center(child: spMerkeFlat(w: 14, h: 12)),
                          ),
                        ),
                        Positioned(
                          left: 30,
                          right: 5,
                          top: 9,
                          child: Text(
                            'ÆREND-BILLETT',
                            maxLines: 1,
                            style: inter(7, weight: FontWeight.w800, em: .06, color: const Color(0xFF8C847C)),
                          ),
                        ),
                        Positioned(
                          left: 30,
                          right: 5,
                          top: 21,
                          child: Text(kode, maxLines: 1, style: jakarta(12.5, em: -.01, height: 1.2, color: kSpInk)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VERV EN VENN',
                      style: inter(10, weight: FontWeight.w800, em: .08, color: kSpMintLight),
                    ),
                    const SizedBox(height: 2),
                    Text('Gi 100 kr, få 100 kr', style: jakarta(15, em: -.015, height: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      'Begge får 100 kr når vennens første ordre er levert.',
                      style: inter(11, weight: FontWeight.w600, height: 1.35, color: kSpSub),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: LfPress(
                  onTap: onLukk,
                  scale: .9,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rgba(255, 255, 255, .14),
                      border: Border.all(color: rgba(255, 255, 255, .22)),
                    ),
                    child: Center(child: spIkon(kSpIkonKryss, size: 10, width: 3)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LfPress(
                  onTap: onDel,
                  dy: 2,
                  child: CssBox(
                    height: 42,
                    radius: BorderRadius.circular(999),
                    bg: const [
                      CssLinear(180, [Color(0xFFF58A55), Color(0xFFE95C2C)]),
                    ],
                    shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .35)), CssShadow(0, 3, 0, 0, rgba(150, 60, 15, .85)), CssShadow(0, 10, 16, -6, rgba(120, 50, 10, .75))],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        spIkon(kSpIkonDel, size: 15, width: 2.4),
                        const SizedBox(width: 8),
                        Text('Del billetten', style: inter(13, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              LfPress(
                onTap: onKopier,
                scale: .95,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: rgba(255, 255, 255, .12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: rgba(255, 255, 255, .25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      spIkon(kSpIkonKopier, size: 14, width: 2.2, extra: kSpIkonKopierExtra),
                      const SizedBox(width: 6),
                      Text('Kopier', style: inter(12.5, weight: FontWeight.w800)),
                    ],
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

// ── Bestillingsdetaljer ─────────────────────────────────────────────────────

/// Which sheet: the short summary or the full details.
enum SpArk { sammendrag, detaljer }

/// **Bestillingsdetaljer** (L7007): the paper sheet over the screen —
/// Ordresammendrag (58 %: Leveres til / Bestilling / Betalt med Vipps, Klar)
/// or Bestillingsdetaljer (80 %: ORDRESTATUS, Din bestilling, Betaling,
/// Butikken, the info grid, Kontakt kundeservice). Lives inside the screen's
/// Stack so everything stays in design px.
class SpDetaljerArk extends StatelessWidget {
  const SpDetaljerArk({
    super.key,
    required this.ark,
    required this.tracking,
    required this.ordre,
    required this.height,
    required this.onLukk,
    required this.onDetaljer,
    required this.onKvittering,
    required this.onKundeservice,
    required this.onRingButikk,
  });

  final SpArk ark;
  final OpsTracking tracking;
  final SpOrdre? ordre;

  /// The screen height in design px.
  final double height;
  final VoidCallback onLukk, onDetaljer, onKvittering, onKundeservice, onRingButikk;

  @override
  Widget build(BuildContext context) {
    final detaljer = ark == SpArk.detaljer;
    final t = tracking;
    final o = ordre ?? const SpOrdre();
    final hent = t.isPickup;
    final navn = SporingCopy.stages(hent);
    final kode = t.code ?? o.kode;
    final butikk = t.store?.name ?? o.butikk;
    final bestilt = o.bestilt;
    final dato = bestilt == null ? '' : '${bestilt.day.toString().padLeft(2, '0')}.${bestilt.month.toString().padLeft(2, '0')}.${bestilt.year}';
    final klokke = bestilt == null ? '' : spKlokke(bestilt);
    final adr = hent ? '$butikk · ${t.store?.address ?? o.butikkAdresse}' : (o.adresse.isEmpty ? '' : '${o.adresse.split(',').first.trim()} · ${SporingCopy.a1_sporing_hjem_etikett}');
    final adrSub = hent ? SporingCopy.a1_sporing_du_henter(butikk) : (o.dorNotat.isEmpty ? SporingCopy.a1_sporing_ring_paa : o.dorNotat);
    final total = spKr(o.total);
    const mnd = ['jan', 'feb', 'mar', 'apr', 'mai', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'des'];
    final over = detaljer
        ? [butikk, if (bestilt != null) '${bestilt.day}. ${mnd[bestilt.month - 1]} kl. $klokke'].join(' · ')
        : SporingCopy.a1_sporing_ordre_over(kode, hent ? SporingCopy.a1_sporing_henting_ord : SporingCopy.a1_sporing_levering_ord);
    return Stack(
      key: const Key('a1_sporing_ark'),
      children: [
        Positioned.fill(
          child: LfOnce(
            ms: 240,
            builder: (context, t, child) => Opacity(opacity: kfP(t, 0, 240), child: child),
            child: GestureDetector(
              key: const Key('a1_sporing_ark_lukk'),
              behavior: HitTestBehavior.opaque,
              onTap: onLukk,
              child: ColoredBox(color: rgba(8, 24, 32, .45)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LfOnce(
            ms: 340,
            builder: (context, t, child) {
              final p = cssSkjerm.transform(kfP(t, 0, 340));
              return Opacity(
                opacity: .6 + .4 * p,
                child: Transform.translate(offset: Offset(0, 26 * (1 - p)), child: child),
              );
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height * (detaljer ? .8 : .58)),
              child: CssBox(
                radius: const BorderRadius.vertical(top: Radius.circular(30)),
                clip: true,
                bg: const [
                  CssLinear(180, [Color(0xFFFDFBF6), Color(0xFFF5F0E6)]),
                ],
                shadows: [const CssShadow.inset(0, 2, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 0, 0, 1, rgba(255, 255, 255, .8)), CssShadow(0, -24, 50, -20, rgba(8, 24, 32, .7))],
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 120,
                      child: IgnorePointer(
                        child: CssBox(
                          bg: [
                            CssRadial([rgba(255, 255, 255, .9), rgba(255, 255, 255, 0)], stops: const [0, .7], rx: 1.2, ry: .9, cx: .5, cy: 0),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Column(
                            children: [
                              CssBox(
                                width: 44,
                                height: 5,
                                radius: BorderRadius.circular(3),
                                bg: const [
                                  CssLinear(180, [Color(0xFFD6CDBB), Color(0xFFBFB5A1)]),
                                ],
                                shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .7))],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  SpTile(
                                    size: 44,
                                    radius: 15,
                                    colors: kSpTileMat,
                                    inner: rgba(60, 48, 30, .3),
                                    child: detaljer ? spIkon(kSpIkonKvittering, size: 20, color: const Color(0xFF8A4A1E), width: 2.4) : bergenSvg('ico_mat', width: 30, height: 27),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          over.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: inter(9.5, weight: FontWeight.w800, em: .09, color: const Color(0xFF8C847C)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(detaljer ? SporingCopy.a1_sporing_bestillingsdetaljer : SporingCopy.a1_sporing_ordresammendrag, style: jakarta(20, em: -.03, height: 1.1, color: kSpInk)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _LysKnapp(
                                    size: 34,
                                    onTap: onLukk,
                                    child: spIkon(kSpIkonKryss, size: 12, color: kSpInk, width: 2.8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                            child: detaljer ? _detaljer(t, o, navn, kode, butikk, adr, dato, klokke, total) : _sammendrag(t, o, adr, adrSub, klokke, total),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sammendrag(OpsTracking t, SpOrdre o, String adr, String adrSub, String klokke, String total) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _Kort(
        tile: SpTile(
          size: 42,
          radius: 14,
          colors: kSpTileTeal,
          inner: rgba(20, 60, 72, .3),
          child: spIkon(kSpIkonPin, size: 19, color: kSpPaperInk, width: 2.3, extra: kSpIkonPinExtra),
        ),
        eyebrow: t.isPickup ? SporingCopy.a1_sporing_hentes_hos_stor : SporingCopy.a1_sporing_leveres_til,
        tittel: adr,
        under: adrSub,
      ),
      const SizedBox(height: 10),
      _Kort(
        onTap: onDetaljer,
        tile: SpTile(
          size: 42,
          radius: 14,
          colors: kSpTileVarm,
          child: spIkon(kSpIkonPose, size: 19, color: const Color(0xFF6E4212), width: 2.3),
        ),
        eyebrow: SporingCopy.a1_sporing_bestilling_stor,
        tittel: o.vareLinje,
        under: '${SporingCopy.a1_sporing_varer(o.antall)} · $total',
        hale: _Chip(tekst: SporingCopy.a1_sporing_se_alt, farge: kSpTeal, pil: true),
      ),
      const SizedBox(height: 10),
      _Kort(
        tile: const _VippsTile(size: 42, radius: 14),
        eyebrow: SporingCopy.a1_sporing_betalt_med_vipps,
        tittel: total,
        underWidget: Row(
          children: [
            spIkon(kSpIkonHake, size: 10, color: const Color(0xFF2E7E4F), width: 3.2),
            const SizedBox(width: 4),
            Text(
              SporingCopy.a1_sporing_betalt_kl(klokke),
              style: inter(11, weight: FontWeight.w600, color: const Color(0xFF2E7E4F)),
            ),
          ],
        ),
        hale: _Chip(tekst: SporingCopy.a1_sporing_kvittering, farge: kSpInk, ikon: kSpIkonKvitteringEnkel, onTap: onKvittering),
      ),
      const SizedBox(height: 16),
      LfPress(
        key: const Key('a1_sporing_ark_klar'),
        onTap: onLukk,
        dy: 3,
        child: CssBox(
          height: 50,
          radius: BorderRadius.circular(18),
          bg: const [
            CssLinear(180, [Color(0xFFF58F58), Color(0xFFEE7238), Color(0xFFE0662C)], [0, .55, 1]),
          ],
          shadows: [
            CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .35)),
            const CssShadow(0, 0, 0, 1.5, Color(0xFFFFFFFF)),
            const CssShadow(0, 4, 0, 1.5, Color(0xFFB84A1E)),
            CssShadow(0, 14, 22, -10, rgba(184, 74, 30, .7)),
          ],
          child: Center(
            child: Text(
              SporingCopy.a1_sporing_klar_knapp,
              style: jakarta(
                15,
                em: -.01,
                shadows: [Shadow(color: rgba(120, 40, 10, .3), offset: const Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _detaljer(OpsTracking t, SpOrdre o, List<String> navn, String kode, String butikk, String adr, String dato, String klokke, String total) {
    final s = t.stage.clamp(0, 3);
    final ordreNr = kode.isNotEmpty ? kode : o.ordreNr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ORDRESTATUS
        CssBox(
          radius: BorderRadius.circular(20),
          clip: true,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          bg: const [
            CssLinear(165, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1]),
          ],
          shadows: [
            CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)),
            const CssShadow(0, 0, 0, 1.5, Color(0xFFFFFFFF)),
            CssShadow(0, 3, 0, 1.5, rgba(11, 38, 45, .9)),
            CssShadow(0, 16, 26, -14, rgba(15, 45, 55, .8)),
          ],
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -44,
                top: -53,
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: CssBox(
                    radius: BorderRadius.circular(75),
                    bg: [
                      CssRadial([rgba(92, 224, 184, .28), rgba(92, 224, 184, 0)], stops: const [0, .7]),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              SporingCopy.a1_sporing_ordrestatus,
                              style: inter(9, weight: FontWeight.w800, em: .09, color: const Color(0xFF9FD3DE)),
                            ),
                            const SizedBox(height: 2),
                            Text(t.isCancelled ? SporingCopy.a1_sporing_avbestilt : navn[s], style: jakarta(17, em: -.02)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        decoration: BoxDecoration(
                          color: rgba(255, 255, 255, .14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: rgba(255, 255, 255, .26)),
                        ),
                        child: Text(ordreNr, style: inter(10.5, weight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CssBox(bg: [CssSolid(rgba(0, 0, 0, .28))], shadows: [CssShadow.inset(0, 1, 2, 0, rgba(0, 0, 0, .4))]),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor:
                                    (.75 *
                                            (s <= 0
                                                ? 0
                                                : s >= 3
                                                ? 1
                                                : s / 3))
                                        .clamp(0.001, 1.0),
                                heightFactor: 1,
                                child: CssBox(
                                  radius: BorderRadius.circular(99),
                                  bg: const [
                                    CssLinear(90, [Color(0xFF5CE0B8), Color(0xFF9FE8D3)]),
                                  ],
                                  shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .6)), CssShadow(0, 0, 10, 0, rgba(92, 224, 184, .6))],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      spIkon(kSpIkonHus, size: 14, color: const Color(0xFF9FD3DE)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t.isPickup ? SporingCopy.a1_sporing_henting_ord[0].toUpperCase() + SporingCopy.a1_sporing_henting_ord.substring(1) : SporingCopy.a1_sporing_levering_ord[0].toUpperCase() + SporingCopy.a1_sporing_levering_ord.substring(1)} · $adr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(11.5, weight: FontWeight.w700, color: kSpSub),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Din bestilling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(SporingCopy.a1_sporing_din_bestilling, style: jakarta(15, em: -.02, color: kSpInk)),
              ),
              Text(
                SporingCopy.a1_sporing_varer(o.antall),
                style: inter(11, weight: FontWeight.w700, color: const Color(0xFF8C847C)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _Papir(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          child: Column(
            children: [
              for (final l in o.linjer)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: rgba(35, 32, 29, .07))),
                  ),
                  child: Row(
                    children: [
                      SpTile(
                        size: 30,
                        radius: 10,
                        colors: kSpTileVarm,
                        child: Text(
                          '${l.antall}×',
                          style: inter(11, weight: FontWeight.w800, color: const Color(0xFF6E4212)),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.navn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: inter(12.5, weight: FontWeight.w800, color: kSpInk),
                            ),
                            if (l.valg.isNotEmpty)
                              Text(
                                l.valg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: inter(10.5, weight: FontWeight.w600, color: const Color(0xFF6E6862)),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            spKr(l.sum),
                            style: inter(12.5, weight: FontWeight.w800, color: kSpInk),
                          ),
                          if (l.tillegg.isNotEmpty)
                            Text(
                              l.tillegg,
                              style: inter(10.5, weight: FontWeight.w600, color: const Color(0xFF8C847C)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 11, 0, 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        SporingCopy.a1_sporing_totalsum,
                        style: inter(13, weight: FontWeight.w800, color: kSpInk),
                      ),
                    ),
                    Text(total, style: jakarta(18, em: -.02, color: kSpInk)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Betaling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(SporingCopy.a1_sporing_betaling, style: jakarta(15, em: -.02, color: kSpInk)),
        ),
        const SizedBox(height: 9),
        _Kort(
          tile: const _VippsTile(size: 42, radius: 14),
          tittel: 'Vipps',
          under: [dato, klokke].where((x) => x.isNotEmpty).join(' · '),
          hale: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total,
                style: inter(13.5, weight: FontWeight.w800, color: kSpInk),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  spIkon(kSpIkonHake, size: 9, color: const Color(0xFF2E7E4F), width: 3.2),
                  const SizedBox(width: 3),
                  Text(
                    SporingCopy.a1_sporing_betalt_ord,
                    style: inter(10.5, weight: FontWeight.w700, color: const Color(0xFF2E7E4F)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Butikken
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(SporingCopy.a1_sporing_butikken_tittel, style: jakarta(15, em: -.02, color: kSpInk)),
        ),
        const SizedBox(height: 9),
        _Kort(
          tile: SpTile(size: 42, radius: 14, colors: kSpTileMat, inner: rgba(60, 48, 30, .3), child: bergenSvg('ico_mat', width: 28, height: 25)),
          tittel: butikk,
          under: t.store?.address ?? o.butikkAdresse,
          hale: _LysKnapp(
            size: 36,
            radius: 12,
            onTap: onRingButikk,
            child: spIkon(kSpIkonTelefon2, size: 15, color: kSpTeal),
          ),
        ),
        const SizedBox(height: 16),
        // The info grid.
        CssBox(
          radius: BorderRadius.circular(20),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          bg: [CssSolid(rgba(255, 255, 255, .55))],
          shadows: [CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .9))],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _Info(SporingCopy.a1_sporing_ordrenummer, ordreNr)),
                  const SizedBox(width: 12),
                  Expanded(child: _Info(SporingCopy.a1_sporing_aerend_id, o.ordreNr.isEmpty ? t.orderId : o.ordreNr)),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: _Info(SporingCopy.a1_sporing_tidsstempel, [dato, klokke].where((x) => x.isNotEmpty).join(' · '))),
                  const SizedBox(width: 12),
                  Expanded(child: _Info(SporingCopy.a1_sporing_kvittering_stor, SporingCopy.a1_sporing_meg_bestillinger)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SpSvev(
          phase: 900,
          child: LfPress(
            key: const Key('a1_sporing_ark_kundeservice'),
            onTap: onKundeservice,
            dy: 2,
            child: CssBox(
              height: 48,
              radius: BorderRadius.circular(999),
              bg: const [
                CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)]),
              ],
              shadows: [CssShadow.inset(0, -3, 6, 0, rgba(30, 79, 92, .14))],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  spIkon(kSpIkonChatBoble, size: 15, color: kSpTeal),
                  const SizedBox(width: 8),
                  Text(
                    SporingCopy.a1_sporing_kontakt_kundeservice,
                    style: inter(13, weight: FontWeight.w800, color: kSpTeal),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The paper card (radius 20, the stacked rims).
class _Papir extends StatelessWidget {
  const _Papir({required this.child, this.padding = const EdgeInsets.fromLTRB(13, 11, 13, 11), this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = CssBox(
      radius: BorderRadius.circular(20),
      padding: padding,
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF8F4EC)]),
      ],
      shadows: [
        const CssShadow(0, 0, 0, 1.5, Color(0xFFFFFFFF)),
        const CssShadow(0, 2, 0, 1.5, Color(0xFFE6DCCB)),
        CssShadow(0, 4, 0, 1.5, rgba(120, 100, 70, .22)),
        CssShadow(0, 14, 22, -14, rgba(35, 32, 29, .45)),
      ],
      child: child,
    );
    if (onTap == null) return box;
    return LfPress(onTap: onTap, dy: 1, child: box);
  }
}

class _Kort extends StatelessWidget {
  const _Kort({required this.tile, this.eyebrow, required this.tittel, this.under, this.underWidget, this.hale, this.onTap});

  final Widget tile;
  final String? eyebrow;
  final String tittel;
  final String? under;
  final Widget? underWidget;
  final Widget? hale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Papir(
    onTap: onTap,
    child: Row(
      children: [
        tile,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: inter(9, weight: FontWeight.w800, em: .08, color: const Color(0xFF8C847C)),
                ),
              if (eyebrow != null) const SizedBox(height: 1),
              Text(
                tittel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: eyebrow != null ? jakarta(13.5, em: -.015, color: kSpInk) : inter(12.5, weight: FontWeight.w800, color: kSpInk),
              ),
              const SizedBox(height: 1),
              if (underWidget != null)
                underWidget!
              else if (under != null && under!.isNotEmpty)
                Text(
                  under!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(11, weight: FontWeight.w600, color: const Color(0xFF6E6862)),
                ),
            ],
          ),
        ),
        if (hale != null) ...[const SizedBox(width: 10), hale!],
      ],
    ),
  );
}

/// The Vipps tile with its V.
class _VippsTile extends StatelessWidget {
  const _VippsTile({required this.size, required this.radius});

  final double size, radius;

  @override
  Widget build(BuildContext context) => SpTile(
    size: size,
    radius: radius,
    colors: kSpTileVipps,
    inner: rgba(120, 40, 30, .3),
    child: Text(
      'V',
      style: jakarta(
        14,
        em: -.04,
        color: const Color(0xFF5A1E14),
        shadows: [Shadow(color: rgba(255, 255, 255, .6), offset: const Offset(0, 1))],
      ),
    ),
  );
}

/// A small light chip («Se alt», «Kvittering»).
class _Chip extends StatelessWidget {
  const _Chip({required this.tekst, required this.farge, this.pil = false, this.ikon, this.onTap});

  final String tekst;
  final Color farge;
  final bool pil;
  final String? ikon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = CssBox(
      radius: BorderRadius.circular(999),
      padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF3EEE2)]),
      ],
      shadows: const [CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 0, 0, 1, Color(0xFFFFFFFF)), CssShadow(0, 2, 0, 1, Color(0xFFE3D5BE))],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[spIkon(ikon!, size: 12, color: farge), const SizedBox(width: 5)],
          Text(
            tekst,
            style: inter(11, weight: FontWeight.w800, color: farge),
          ),
          if (pil) ...[const SizedBox(width: 4), spIkon(kSpIkonPil, size: 9, color: farge, width: 3.2)],
        ],
      ),
    );
    if (onTap == null) return box;
    return LfPress(onTap: onTap, dy: 1, child: box);
  }
}

/// A round light key (close, phone).
class _LysKnapp extends StatelessWidget {
  const _LysKnapp({required this.size, required this.child, required this.onTap, this.radius});

  final double size;
  final double? radius;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    onTap: onTap,
    scale: .92,
    dy: 1,
    child: CssBox(
      width: size,
      height: size,
      radius: BorderRadius.circular(radius ?? 99),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF3EEE2)]),
      ],
      shadows: [
        const CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)),
        const CssShadow(0, 0, 0, 1, Color(0xFFFFFFFF)),
        const CssShadow(0, 2, 0, 1, Color(0xFFE3D5BE)),
        CssShadow(0, 6, 10, -6, rgba(60, 48, 30, .45)),
      ],
      child: Center(child: child),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.verdi);

  final String label, verdi;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: inter(9, weight: FontWeight.w800, em: .08, color: const Color(0xFF8C847C)),
      ),
      const SizedBox(height: 2),
      Text(
        verdi,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: inter(12, weight: FontWeight.w800, color: kSpInk),
      ),
    ],
  );
}
