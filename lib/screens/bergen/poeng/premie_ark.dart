import 'package:flutter/material.dart';

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../../data/points/points_rules.dart';
import '../kit/bergen_kit.dart';
import '../meg/meg_ark.dart';
import '../meg/meg_copy_a4.dart';
import '../meg/mork_rad.dart';

/// The prize sheets shared by Premiehylla and Meg (Gap Step 3):
/// - `krev` (L19658, new Bergen): claim a prize. Meg's «Hent premie» opens it
///   for the goal prize, as Premiehylla does for any prize.
/// - `premieVilkaar` (L20250): «Vilkår for premier», dark.
abstract final class PremieArk {
  /// `krev`: what happens, how long it lasts, points after — and the boat asks
  /// for its name first (identity prize).
  static Future<bool?> krev(BuildContext context, {required Prize p, required int poeng, required PointsAppApi api, int? gyldigDager}) {
    final after = (poeng - p.pointPrice).clamp(0, 1 << 30);
    final identity = p.type == 'identity';
    final name = TextEditingController();
    var busy = false;
    String? error;
    StateSetter? sheetSet;

    return showMegArk<bool>(
      context,
      key: const Key('hylla-krev-sheet'),
      title: p.name,
      subtitle: identity ? A4MegCopy.a4_hylla_baat_linje : '${A4MegCopy.nf(p.pointPrice)} poeng${p.partnerName == null ? '' : ' · ${p.partnerName}'}',
      body: (ctx, setState) {
        sheetSet = setState;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (identity)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  key: const Key('hylla-baat-navn'),
                  controller: name,
                  maxLength: 20,
                  onChanged: (_) => setState(() {}),
                  style: BergenTokens.text(15, weight: FontWeight.w800, color: MegArkInk.ink),
                  decoration: InputDecoration(
                    hintText: A4MegCopy.a4_hylla_baat_hint,
                    counterText: '${name.text.length} av 20 tegn',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5),
                    ),
                  ),
                ),
              ),
            MegArkRow(title: A4MegCopy.a4_hylla_dette_skjer, sub: identity ? A4MegCopy.a4_hylla_baat_skjer : hvordan(p.type)),
            MegArkRow(title: A4MegCopy.a4_hylla_gyldighet, sub: identity ? A4MegCopy.a4_hylla_baat_gyldig : A4MegCopy.a4_hylla_gyldig_dager(gyldigDager ?? 60)),
            MegArkRow(title: A4MegCopy.a4_hylla_poeng_etter, sub: '${A4MegCopy.nf(after)} poeng'),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(error!, style: megInter(12, FontWeight.w700, color: const Color(0xFFB9441A))),
              ),
          ],
        );
      },
      primary: MegArkButton(
        key: const Key('hylla-krev-cta'),
        label: identity ? A4MegCopy.a4_hylla_baat_cta : A4MegCopy.a4_hylla_hent_for(p.pointPrice),
        onTap: () async {
          if (busy) return;
          if (identity && name.text.trim().isEmpty) {
            showBergenToast(context, A4MegCopy.a4_hylla_baat_navn_forst);
            return;
          }
          busy = true;
          final nav = Navigator.of(context);
          final r = await api.claim(p.id, identityName: identity ? name.text.trim() : null);
          busy = false;
          if (r.claim != null) {
            nav.pop(true);
            if (context.mounted) showBergenToast(context, A4MegCopy.a4_hylla_hentet(p.name), icon: Icons.check_rounded);
          } else {
            sheetSet?.call(() => error = r.error ?? A4MegCopy.a4_hylla_feil);
          }
        },
      ),
    );
  }

  static String hvordan(String type) {
    switch (type) {
      case 'voucher':
        return 'Brukes automatisk på neste levering';
      case 'physical':
        return 'Sendes hjem til deg';
      case 'donation':
        return 'Gis til klubben du velger';
      case 'identity':
        return 'Båten din legges i Vågen';
      default:
        return 'Kode vises her';
    }
  }

  /// «Vilkår for premier» (kArk `premieVilkaar`, dark). Rows only from real
  /// rules: Gyldighet (`claim_expiry_days`) and Poeng (`points_expiry_months`)
  /// hide without them. The design's «Utsolgt · kommer tilbake neste måned»
  /// is left out: prize stock is a plain count with no monthly refill.
  static Future<void> vilkaar(BuildContext context, {PointsRules? regler}) {
    final rader = <(String, String, String)>[
      if (regler?.claimExpiryDays case final d?) (MorkIk.klokke, A4MegCopy.a4_premie_vilkaar_gyldighet, A4MegCopy.a4_premie_vilkaar_gyldig(d)),
      (MorkIk.butikk, A4MegCopy.a4_premie_vilkaar_partner, A4MegCopy.a4_premie_vilkaar_partner_sub),
      if (regler?.pointsExpiryMonths case final m?) (MorkIk.stjerne, A4MegCopy.a4_premie_vilkaar_poeng, A4MegCopy.a4_premie_vilkaar_poeng_sub(m)),
    ];
    return showMegArk<void>(
      context,
      key: const Key('premie-vilkaar-sheet'),
      mork: true,
      title: A4MegCopy.a4_premie_vilkaar_title,
      subtitle: A4MegCopy.a4_premie_vilkaar_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in rader.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            MorkRad(delayMs: i * 40.0, ikon: r.$1, navn: r.$2, under: r.$3, onTap: () {}),
          ],
        ],
      ),
      primary: MegArkButton(label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }
}
