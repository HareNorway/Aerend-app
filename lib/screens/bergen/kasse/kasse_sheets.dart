
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_address_drawer.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../common/auth/launch/lf_css.dart' show LfFrame;
import '../../common/auth/onboarding_kit.dart' show OnbPressable, onbBlur;
import 'package:aerend_customer/utils/route_names.dart';
import '../kit/ae_primitiver.dart';
import '../kit/bergen_css.dart';
import 'kurv_beskjed.dart' show KasseValg;
import '../kit/bergen_kit.dart';
import '../kit/svg_sti.dart';
import 'kasse_copy.dart';
import 'kurv_parts.dart' show kurvLysSkygger;
import '../kit/bergen_perf.dart';
import '../kit/vann_overganger.dart';
import '../adresse/adr_ark.dart' show adrMerke;
import 'package:aerend_customer/screens/bergen/kit/css_decoration.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';

/// The four Kasse sheets (≈L6913–7142 in `Ærend Kunde Bergen.dc.html`) via
/// [BergenArk]: **Adresse** ("Hvor skal ærendet?" + the door note),
/// **Ny adresse** (the existing address drawer inside), **Levering** ("Når vil
/// du ha det?"), **Betaling** (Vipps / Kort — the app's real methods).

/// Adresse: returns the chosen address, or null.
Future<AddressListItem?> showAdresseSheet(
  BuildContext context, {
  required List<AddressListItem> addresses,
  int? selectedId,
  required Future<void> Function() onAddNew,
  Future<Map<String, dynamic>?> Function(AddressListItem)? coverage,
  Future<void> Function(AddressListItem)? onWaitlist,
}) {
  return showBergenArk<AddressListItem>(
    context,
    title: KasseCopy.a1_kasse_adr_sheet_title,
    subtitle: KasseCopy.a1_kasse_adr_sheet_line,
    rows: [
      for (final a in addresses)
        BergenArkRow(
          label: '${a.type.isEmpty ? '' : adrMerke(a.type)} · ${a.address.split(',').first}'.replaceFirst(RegExp(r'^ · '), ''),
          value: [if (a.flatNo.isNotEmpty) a.flatNo, if (a.landmark.isNotEmpty) a.landmark].join(' · '),
          icon: a.addressId == selectedId ? Icons.check_circle_rounded : Icons.place_outlined,
          onTap: () => Navigator.of(context).pop(a),
        ),
      BergenArkRow(
        label: KasseCopy.a1_kasse_adr_ny,
        value: KasseCopy.a1_kasse_adr_ny_line,
        icon: Icons.add_rounded,
        onTap: () async {
          Navigator.of(context).pop();
          await onAddNew();
        },
      ),
    ],
    body: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KasseCopy.a1_kasse_adr_dor_kicker,
            style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.inkFaint),
          ),
          const SizedBox(height: 2),
          Text(
            KasseCopy.a1_kasse_adr_dor_line,
            style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: BergenTokens.inkSecondary),
          ),
        ],
      ),
    ),
  );
}

/// Ny adresse: the existing drawer, then the caller reloads the list.
Future<bool> showNyAdresseSheet(BuildContext context) async {
  final changed = await showAeAddressDrawer(context, parentContext: context);
  return changed == true;
}

/// Opens a Kasse sheet (`visSheet`, L8378): the scrim (`rgba(15,31,43,.32)`,
/// blur 5, `skjermInn .25s`) and the sheet rising on `arkOpp .38s
/// cubic-bezier(.2,.9,.3,1)` — teal for Levering, paper for Betaling.
Future<T?> visKasseArk<T>(
  BuildContext context, {
  required bool lys,
  required String navn,
  required WidgetBuilder builder,
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      settings: RouteSettings(name: '$appRoutePrefix$navn'),
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      // Bergen 29 Oct: Bølge up 520ms, down 380ms (`arkOvergang`).
      transitionDuration: reduce ? Duration.zero : kBolgeInn,
      reverseTransitionDuration: reduce ? Duration.zero : kBolgeUt,
      pageBuilder: (context, a, _) => _KasseArkRute(anim: a, lys: lys, builder: builder),
    ),
  );
}

class _KasseArkRute extends StatelessWidget {
  const _KasseArkRute({required this.anim, required this.lys, required this.builder});

  final Animation<double> anim;
  final bool lys;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: LfFrame(
        child: Builder(
          builder: (context) {
            final s = context.bs;
            final mq = MediaQuery.of(context);
            // Lys plan (`sheetBg` / `sheetHandle` L20216, `.mkam`): every Kasse sheet
            // is `--lys-ark` with `--lys-haandtak` and `--lys-arkskygge` in Lys.
            final modusLys = context.lys;
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: const Interval(0, .66, curve: Curves.easeOut),
                      ),
                      child: BackdropFilter(
                        enabled: BergenPerf.blurOn(context),
                        filter: BergenPerf.blur(context, 2.5, 2.5),
                        child: const ColoredBox(color: Color.fromRGBO(15, 31, 43, .32)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: bolgeArkRute(
                    anim,
                    mork: !lys,
                    radius: 28 * s,
                    Container(
                      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 22 * s + mq.padding.bottom * .5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28 * s)),
                        color: modusLys ? LysPalett.ark : lys ? const Color(0xF2FAF9F6) : null,
                        gradient: lys || modusLys
                            ? null
                            : cssLinear(
                                180,
                                const [Color(0xFF27596A), Color(0xFF1E4F5C), Color(0xFF173E48)],
                                const [0, .55, 1],
                              ),
                        // Design 21 Nov (`mkam`): the dark sheet's top hairline is faint (.14); the light one keeps .95.
                        border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, lys || modusLys ? .95 : .14))),
                        boxShadow: modusLys
                            ? kurvLysSkygger(LysPalett.arkskygge, s)
                            : [
                                BoxShadow(
                                  color: rgba(15, 31, 43, .55),
                                  offset: Offset(0, -24 * s),
                                  blurRadius: onbBlur(50 * s),
                                  spreadRadius: -20 * s,
                                ),
                              ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          bergenInsetTop(
                            radius: 28 * s,
                            height: 1.5 * s,
                            alpha: .95,
                            pad: EdgeInsets.symmetric(
                              horizontal: 16 * s,
                            ).copyWith(bottom: 22 * s + mq.padding.bottom * .5),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Padding(
                                  padding: EdgeInsets.only(top: 10 * s),
                                  child: Center(
                                    child: Container(
                                      width: 44 * s,
                                      height: 5 * s,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3 * s),
                                        color: modusLys ? LysPalett.haandtak : lys ? rgba(35, 32, 29, .28) : rgba(255, 255, 255, .35),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              builder(context),
                            ],
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
    );
  }
}

/// The time shown on the Kurv row: «Så fort som mulig», else «Kl. 18:30».
String kasseTidNavn(KasseSlot slot) => slot.at == null ? slot.label : KasseCopy.a1_kasse_kl(slot.label);

/// Levering (Design 21 Nov A3, `sheet:'levering'`): «Når vil du ha det?» 21/800 with a sub-line per mode and the
/// round close key, the Levering / Henting tab pill with icons ([AeFanePille]), one 64 px radio card per time
/// ([AeRadioKort]: the longship tile for «Så fort som mulig», the clock time for the rest; the flex window and the
/// pickup lines stay the app's), and the 56 px pill «Bekreft levering · snarest / 18:30» ([AeKnappPille]). Returns
/// the chosen slot; the mode is reported on the pill.
Future<KasseSlot?> showLeveringSheet(
  BuildContext context, {
  required List<KasseSlot> slots,
  KasseSlot? selected,
  required bool pickup,
  required ValueChanged<bool> onModeChanged,
}) {
  var mode = pickup;
  KasseSlot? chosen = selected ?? slots.firstOrNull;
  return visKasseArk<KasseSlot>(
    context,
    lys: false,
    navn: 'levering',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final s = ctx.bs;
        final valgt = chosen ?? slots.firstOrNull;
        // «snarest», «18:30», «innen 2 timer» — the time named in the pill.
        final tidTx = valgt == null || valgt.id == 'asap'
            ? KasseCopy.a1_kasse_snarest
            : valgt.id == 'flex'
                ? languages.flex_window_title.toLowerCase()
                : valgt.label;
        return Column(
          key: const Key('a1_kasse_levering_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 14 * s),
            KasseArkHode(tittel: KasseCopy.a1_kasse_lev_sheet_title, linje: mode ? KasseCopy.a1_kasse_lev_sub_hent : KasseCopy.a1_kasse_lev_sub_lev),
            SizedBox(height: 14 * s),
            AeFanePille(
              faner: [
                AeFane(label: KasseCopy.a1_kasse_levering, icon: Icons.home_outlined, key: const Key('a1_kasse_ark_levering')),
                AeFane(label: KasseCopy.a1_kasse_henting, icon: Icons.shopping_bag_outlined, key: const Key('a1_kasse_ark_henting')),
              ],
              valgt: mode ? 1 : 0,
              onValg: (i) => setState(() => mode = i == 1),
            ),
            for (var i = 0; i < slots.length; i++) ...[
              SizedBox(height: (i == 0 ? 12 : 8) * s),
              AeRadioKort(
                key: Key('a1_kasse_slot_${slots[i].id}'),
                valgt: valgt?.id == slots[i].id,
                onTap: () => setState(() => chosen = slots[i]),
                tittel: i == 0
                    ? slots[i].label
                    // Customer v2 Step 1: «Innen 2 timer» (pricing.flex_window).
                    : slots[i].id == 'flex'
                    ? languages.flex_window_title
                    : (i == 1 ? KasseCopy.a1_kasse_lev_middag : KasseCopy.a1_kasse_lev_kveld),
                under: kasseTidLinje(slots[i], i, hent: mode),
                ikon: i == 0
                    ? bergenSvg('longship3d', width: 32 * s, height: 17 * s)
                    : Text(slots[i].label, textAlign: TextAlign.center, softWrap: false, overflow: TextOverflow.visible, style: BergenTokens.text(12 * s, weight: FontWeight.w800)),
              ),
            ],
            SizedBox(height: 16 * s),
            AeKnappPille(
              key: const Key('a1_kasse_bruk_dette'),
              label: mode ? KasseCopy.a1_kasse_bekreft_hent(tidTx) : KasseCopy.a1_kasse_bekreft_lev(tidTx),
              onPressed: () {
                onModeChanged(mode);
                Navigator.of(ctx).pop(chosen);
              },
            ),
          ],
        );
      },
    ),
  );
}

/// The sub-line of a time card: the slot's own line, except on pickup where «Så fort som mulig» reads «Klar ca.
/// 18:20» (the time out of the delivery line) and «Til middag» «Maten er klar når du kommer» (design `tid0Under` /
/// `tid1Under`); the flex window keeps its engine line.
String kasseTidLinje(KasseSlot slot, int i, {required bool hent}) {
  if (!hent || slot.id == 'flex') return slot.line;
  if (i == 0) {
    final t = RegExp(r'\d{1,2}[:.]\d{2}').firstMatch(slot.line)?.group(0);
    return t == null ? slot.line : KasseCopy.a1_kasse_tid_klar_ca(t);
  }
  if (i == 1) return KasseCopy.a1_kasse_hent_middag_line;
  return slot.line;
}

/// The sheets' head (Design 21 Nov A3): title 21/800 −.03em, the sub-line 12.5/600 .62, and the round 44 px close key.
class KasseArkHode extends StatelessWidget {
  const KasseArkHode({super.key, required this.tittel, required this.linje});

  final String tittel;
  final String linje;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lys = context.lys;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tittel, style: bDisplay(context, 21, letterSpacingEm: -.03, color: context.aeM(Colors.white, LysPalett.tittel)).copyWith(height: 1.15)),
              SizedBox(height: 4 * s),
              Text(linje, style: bText(context, 12.5, weight: FontWeight.w600, height: 1.35, color: context.aeM(rgba(255, 255, 255, .62), LysPalett.sekundar))),
            ],
          ),
        ),
        SizedBox(width: 12 * s),
        Semantics(
          button: true,
          label: languages.close,
          child: OnbPressable(
            key: const Key('a1_kasse_ark_lukk'),
            onTap: () => Navigator.of(context).pop(),
            pressDy: 0,
            pressScale: .94,
            child: Container(
              width: 44 * s,
              height: 44 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lys ? LysPalett.dis : rgba(4, 18, 26, .38),
                border: Border.all(color: lys ? Colors.transparent : rgba(255, 255, 255, .12)),
              ),
              child: Icon(Icons.close_rounded, size: 18 * s, color: lys ? LysPalett.fjord : Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// The legacy payment types: 3 = Vipps, 2 = card (the Stripe checkout); Apple
/// Pay (4) and Google Pay (5) take the card path, where Stripe offers them.
const kBetVipps = 3, kBetKort = 2, kBetApple = 4, kBetGoogle = 5;

String kasseBetalingNavn(int type) {
  return switch (type) {
    kBetVipps => KasseCopy.a1_kasse_bet_vipps,
    kBetApple => 'Apple Pay',
    kBetGoogle => 'Google Pay',
    _ => KasseCopy.a1_kasse_bet_kort,
  };
}

/// Betaling (Design 21 Nov A3, `sheet:'betaling'`): the dark sheet, «Hvordan vil du betale?» with its sub-line and
/// the close key, and one 64 px radio card per method with its brand tile ([AeRadioKort]; Vipps carries the phone).
/// Checked visually only — nothing here starts a payment; a tap picks and closes. Returns the type.
Future<int?> showBetalingSheet(BuildContext context, {int? selected}) {
  final metoder = [
    kBetVipps,
    kBetKort,
    if (defaultTargetPlatform == TargetPlatform.iOS) kBetApple,
    if (defaultTargetPlatform == TargetPlatform.android) kBetGoogle,
  ];
  final tlf = KasseValg.tlf(prefGetString(prefContactNumber));
  return visKasseArk<int>(
    context,
    lys: false,
    navn: 'betaling',
    builder: (ctx) {
      final s = ctx.bs;
      return Column(
        key: const Key('a1_kasse_betaling_sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 14 * s),
          KasseArkHode(tittel: KasseCopy.a1_kasse_bet_sheet_title, linje: KasseCopy.a1_kasse_bet_sheet_line),
          for (var i = 0; i < metoder.length; i++) ...[
            SizedBox(height: (i == 0 ? 14 : 8) * s),
            AeRadioKort(
              key: Key('a1_kasse_bet_${metoder[i]}'),
              valgt: (selected ?? kBetVipps) == metoder[i],
              tittel: kasseBetalingNavn(metoder[i]),
              under: metoder[i] == kBetVipps && tlf.isNotEmpty ? tlf : null,
              flis: KasseBetFlis(type: metoder[i]),
              onTap: () {
                Navigator.of(ctx).pop(metoder[i]);
                showBergenToast(
                  context,
                  KasseCopy.a1_kasse_betaler_med(
                    metoder[i] == kBetKort
                        ? KasseCopy.a1_kasse_kort.toLowerCase()
                        : kasseBetalingNavn(metoder[i]).split(' · ').first,
                  ),
                );
              },
            ),
          ],
        ],
      );
    },
  );
}

/// The 40 px brand tile of a payment method: Vipps orange, Visa blue, Apple black, Google white.
class KasseBetFlis extends StatelessWidget {
  const KasseBetFlis({super.key, required this.type});

  final int type;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final (bg, merke) = switch (type) {
      kBetVipps => (
        cssLinear(160, const [Color(0xFFFF7A45), Color(0xFFE9501A)]),
        Text('v', style: bDisplay(context, 19, letterSpacingEm: -.04)),
      ),
      kBetKort => (
        cssLinear(160, const [Color(0xFF2A3A9C), Color(0xFF141B5E)]),
        Text('VISA', style: bDisplay(context, 11, letterSpacingEm: .02).copyWith(fontStyle: FontStyle.italic)),
      ),
      kBetApple => (
        cssLinear(160, const [Color(0xFF3A3A3C), Color(0xFF0F0F10)]),
        CustomPaint(size: Size(16 * s, 19 * s), painter: const _MerkePainter(_kEple, 20, 24, [Colors.white])),
      ),
      _ => (
        cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFEEF2F1)]),
        CustomPaint(
          size: Size.square(18 * s),
          painter: const _MerkePainter(_kG, 24, 24, [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
          ]),
        ),
      ),
    };
    return Container(
      width: 40 * s,
      height: 40 * s,
      alignment: Alignment.center,
      decoration: CssDecoration(
        borderRadius: BorderRadius.circular(13 * s),
        gradient: bg,
        boxShadow: [
          BoxShadow(
            color: rgba(8, 24, 32, .6),
            offset: Offset(0, 7 * s),
            blurRadius: onbBlur(12 * s),
            spreadRadius: -7 * s,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13 * s),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rgba(0, 0, 0, 0), rgba(0, 0, 0, 0), rgba(0, 0, 0, .22)],
          stops: const [0, .8, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox.expand(),
          bergenInsetTop(radius: 13 * s, height: 1.5 * s, alpha: .35),
          merke,
        ],
      ),
    );
  }
}

const _kEple = [
  'M14.6 12.7c0-2.5 2-3.7 2.1-3.8-1.1-1.7-2.9-1.9-3.5-1.9-1.5-.1-2.8.9-3.5.9s-1.9-.9-3.1-.8C4.8 7.2 3 8.4 2 10.4c-1.1 2-.7 5.7 1 8.4.8 1.3 1.9 2.8 3.3 2.7 1.3 0 1.8-.8 3.4-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.2-2.6.9-1.4 1.3-2.7 1.3-2.8-.1 0-2.9-1.2-3-4.4zM12.2 4.9c.7-.9 1.2-2 1-3.2-1 0-2.3.7-3 1.5-.7.8-1.2 2-1.1 3.1 1.1.1 2.3-.6 3.1-1.4z',
];
const _kG = [
  'M21.6 12.2c0-.7-.06-1.37-.18-2H12v3.8h5.4a4.62 4.62 0 0 1-2 3.03v2.5h3.22c1.88-1.73 2.98-4.28 2.98-7.33z',
  'M12 22c2.7 0 4.96-.9 6.62-2.43l-3.22-2.5c-.9.6-2.04.95-3.4.95a5.98 5.98 0 0 1-5.62-4.13H3.04v2.6A10 10 0 0 0 12 22z',
  'M6.38 13.89a6 6 0 0 1 0-3.78v-2.6H3.04a10 10 0 0 0 0 8.98l3.34-2.6z',
  'M12 6.18c1.47 0 2.79.5 3.83 1.5l2.85-2.85A9.6 9.6 0 0 0 12 2a10 10 0 0 0-8.96 5.51l3.34 2.6A5.98 5.98 0 0 1 12 6.18z',
];

/// Brand marks from their SVG paths: filled in [farger] (one per path).
class _MerkePainter extends CustomPainter {
  const _MerkePainter(this.stier, this.vw, this.vh, this.farger);

  final List<String> stier;
  final double vw;
  final double vh;
  final List<Color> farger;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / vw, size.height / vh);
    for (var i = 0; i < stier.length; i++) {
      canvas.drawPath(svgSti(stier[i]), Paint()..color = farger[i % farger.length]);
    }
  }

  @override
  bool shouldRepaint(_MerkePainter old) => false;
}

/// Coverage at address change (geo spec §4): a guarded read; 404 / flag off
/// skips silently. Returns false only when the answer says "not covered".
Future<bool> checkCoverage(OpsCustomerApi api, AddressListItem a) async {
  final lat = double.tryParse(a.lat);
  final lng = double.tryParse(a.long);
  if (lat == null || lng == null) return true;
  final json = await api.coverage(lat, lng);
  if (json == null) return true;
  final covered = json['covered'] ?? json['is_covered'] ?? json['eligible'];
  return covered != false;
}
