import 'package:flutter/material.dart';

import '../../../data/ops/tracking_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';

/// **Bud-identitet** (Launch L8995): the white glass pill with the
/// courier's initial, «{navn} · el-sykkel» and «BankID-verifisert» — or the
/// store's icon and «{butikk} leverer selv» for a partner delivery. The pill
/// never shows a courier identity for partner orders (spec §5).
class BudIdentitetPill extends StatelessWidget {
  const BudIdentitetPill({super.key, required this.tracking});

  final OpsTracking tracking;

  static String kjoretoy(OpsCourier c) => switch (c.vehicle) {
    'sykkel' => 'el-sykkel',
    'bil' => 'bil',
    final v? => v,
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final courier = tracking.isPartner ? null : tracking.courier;
    final partner = tracking.isPartner;
    final navn = partner ? SporingCopy.a1_sporing_leverer_selv(tracking.deliveredByLabel) : (courier?.firstName ?? SporingCopy.a1_sporing_Budet);
    final kj = courier == null ? '' : kjoretoy(courier);
    final tittel = kj.isEmpty ? navn : '$navn · $kj';
    final verifisert = partner || (courier?.verified ?? false);
    return LfOnce(
      key: const Key('a1_sporing_bud_pill'),
      ms: 340,
      builder: (context, t, child) {
        final p = cssSkjerm.transform(kfP(t, 0, 340));
        return Opacity(
          opacity: kf(p, const [0, .55, 1], const [0, 1, 1]),
          child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.978 + .022 * p, .978 + .022 * p, 1, 1), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
        decoration: BoxDecoration(
          color: rgba(255, 255, 255, .62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: rgba(255, 255, 255, .85)),
          boxShadow: [
            BoxShadow(color: rgba(8, 24, 32, .12), offset: const Offset(0, 2), blurRadius: 3, spreadRadius: -1),
            BoxShadow(color: rgba(8, 24, 32, .4), offset: const Offset(0, 12), blurRadius: 20, spreadRadius: -14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: partner
                    ? const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFF2A6272), Color(0xFF1E4F5C)])
                    : const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFFDCE9EC), Color(0xFF9FB6C2)]),
              ),
              child: Center(
                child: partner
                    ? spIkon(kSpIkonButikk, size: 15, color: const Color(0xFFF5F3EF), width: 2.2, key: const Key('a1_sporing_bud_store_icon'))
                    : Text(_initial(courier), style: jakarta(13, color: kSpTeal)),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tittel,
                  key: const Key('a1_sporing_bud_navn'),
                  style: inter(12, weight: FontWeight.w800, color: kSpInk),
                ),
                if (kj.isNotEmpty) SizedBox(key: const Key('a1_sporing_bud_kjoretoy'), width: 0, height: 0),
                if (verifisert)
                  Row(
                    key: const Key('a1_sporing_bud_verifisert'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      spIkon(kSpIkonSkjold, size: 10, color: const Color(0xFF2E7E4F), width: 3),
                      const SizedBox(width: 4),
                      Text(
                        SporingCopy.a1_sporing_bankid_verifisert,
                        style: inter(10, weight: FontWeight.w800, color: const Color(0xFF2E7E4F)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initial(OpsCourier? c) => (c?.firstName.isNotEmpty ?? false) ? c!.firstName[0].toUpperCase() : 'B';
}

/// **Leveringskode** (Launch L7122): the white card with the 7 × 7 visual
/// code, the title («VIS DENNE TIL BUDET» / «… SJÅFØREN» / «… I DISKEN»),
/// the PIN at 32 px and who may take it. Without a connection the visual
/// code is dropped and «Uten nett vises bare PIN.» is added.
class LeveringskodeCard extends StatelessWidget {
  const LeveringskodeCard({super.key, required this.code, this.offline = false, this.onDark = false, this.tracking});

  final OpsDeliveryCode code;

  /// No connection: the visual code is dropped and only the PIN stays.
  final bool offline;
  final bool onDark;

  /// Who takes the code (the title and the line under the PIN).
  final OpsTracking? tracking;

  /// A stable 7×7 pattern from the payload — the design's "visual code".
  static List<bool> pattern(String payload) {
    var h = 0x811C9DC5;
    for (final unit in payload.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    final out = <bool>[];
    var x = h == 0 ? 0x9E3779B9 : h;
    for (var i = 0; i < 49; i++) {
      x ^= x << 13 & 0xFFFFFFFF;
      x ^= x >> 17;
      x ^= x << 5 & 0xFFFFFFFF;
      out.add((x & 1) == 1);
    }
    // Corners always set so a partial view still reads as a code.
    for (final i in const [0, 6, 42, 48]) {
      out[i] = true;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = tracking;
    final pin = code.pin ?? '';
    final payload = code.qrPayload;
    final henting = t?.isPickup ?? false;
    final bil = t?.courier?.vehicle == 'bil';
    final tittel = henting
        ? SporingCopy.a1_sporing_vis_disken
        : bil
        ? SporingCopy.a1_sporing_vis_sjaforen
        : SporingCopy.a1_sporing_vis_budet;
    final hvem = henting
        ? (t?.store?.name ?? SporingCopy.a1_sporing_Butikken)
        : (t?.isPartner ?? false)
        ? (t?.deliveredByLabel ?? '')
        : (t?.courier?.firstName ?? SporingCopy.a1_sporing_Budet);
    final under = henting ? SporingCopy.a1_sporing_gir_bare_ut(hvem) : SporingCopy.a1_sporing_leverer_bare(hvem);
    return SpBobleInn(
      dur: 450,
      child: CssBox(
        key: const Key('ops-delivery-code-card'),
        radius: BorderRadius.circular(20),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        bg: const [
          CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEDF2F2)]),
        ],
        shadows: [const CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 3, 0, 0, rgba(6, 30, 38, .5)), CssShadow(0, 14, 22, -12, rgba(4, 18, 26, .85))],
        child: Row(
          children: [
            if (!offline && payload != null && payload.isNotEmpty) ...[_Visual(key: const Key('ops-delivery-code-qr'), pattern: pattern(payload)), const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tittel,
                    style: inter(10, weight: FontWeight.w800, em: .08, color: const Color(0xFF6B655D)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pin,
                    key: const Key('ops-delivery-code-pin'),
                    style: jakarta(32, em: .16, height: 1.1, color: kSpInk),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    offline ? '$under ${SporingCopy.a1_sporing_uten_nett_kode}' : under,
                    key: Key(offline ? 'ops-delivery-code-offline' : 'ops-delivery-code-no-leave-at-door'),
                    style: inter(11, weight: FontWeight.w600, height: 1.35, color: const Color(0xFF57534B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 7 × 7 visual code (84 × 84, white, 7 px padding, 2 px gaps).
class _Visual extends StatelessWidget {
  const _Visual({super.key, required this.pattern});

  final List<bool> pattern;

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: rgba(35, 32, 29, .1), spreadRadius: 1, blurStyle: BlurStyle.inner)],
    ),
    child: GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        for (var i = 0; i < 49; i++)
          DecoratedBox(
            decoration: BoxDecoration(color: pattern[i] ? kSpInk : Colors.transparent, borderRadius: BorderRadius.circular(1)),
          ),
      ],
    ),
  );
}

/// **Valg som venter** (Launch L9008): the store has not seen the order —
/// wait for a new window, or cancel with a full refund.
class ValgSomVenterCard extends StatelessWidget {
  const ValgSomVenterCard({super.key, required this.storeName, required this.onWait, required this.onCancel});

  final String storeName;
  final VoidCallback onWait;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('a1_sporing_valg'),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: rgba(255, 255, 255, .9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: rgba(242, 109, 61, .5), width: 1.5),
      boxShadow: [BoxShadow(color: rgba(8, 24, 32, .55), offset: const Offset(0, 24), blurRadius: 44, spreadRadius: -22)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            aegil('invitation', w: 34, h: 34),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SporingCopy.a1_sporing_valg_tittel(storeName),
                    style: inter(14, weight: FontWeight.w800, color: kSpInk),
                  ),
                  Text(
                    SporingCopy.a1_sporing_valg_line,
                    style: inter(12, weight: FontWeight.w600, height: 1.35, color: const Color(0xFF57534B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LfPress(
                key: const Key('a1_sporing_valg_vent'),
                onTap: onWait,
                scale: .97,
                child: CssBox(
                  height: 46,
                  radius: BorderRadius.circular(999),
                  bg: const [
                    CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1]),
                  ],
                  child: Center(
                    child: Text(SporingCopy.a1_sporing_vent, style: inter(13.5, weight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LfPress(
                key: const Key('a1_sporing_valg_avbestill'),
                onTap: onCancel,
                scale: .97,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFB9441A), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      SporingCopy.a1_sporing_avbestill,
                      style: inter(13.5, weight: FontWeight.w800, color: const Color(0xFFB9441A)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
