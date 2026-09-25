import 'package:flutter/material.dart';

import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_address_drawer.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../kit/bergen_kit.dart';
import 'kasse_copy.dart';

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
          label: '${a.type} · ${a.address.split(',').first}'
              .replaceFirst(RegExp(r'^ · '), ''),
          value: [
            if (a.flatNo.isNotEmpty) a.flatNo,
            if (a.landmark.isNotEmpty) a.landmark,
          ].join(' · '),
          icon: a.addressId == selectedId
              ? Icons.check_circle_rounded
              : Icons.place_outlined,
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
            style: BergenTokens.text(
              BergenTokens.textSmall,
              weight: FontWeight.w800,
              color: BergenTokens.inkFaint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            KasseCopy.a1_kasse_adr_dor_line,
            style: BergenTokens.text(
              BergenTokens.textSmall,
              weight: FontWeight.w600,
              color: BergenTokens.inkSecondary,
            ),
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

/// Levering: the slots, "Så fort som mulig" first; returns the chosen slot.
Future<KasseSlot?> showLeveringSheet(
  BuildContext context, {
  required List<KasseSlot> slots,
  KasseSlot? selected,
  required bool pickup,
  required ValueChanged<bool> onModeChanged,
}) {
  var mode = pickup;
  return showBergenSheet<KasseSlot>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final s = ctx.bs;
        KasseSlot? chosen = selected ?? slots.firstOrNull;
        return Column(
          key: const Key('a1_kasse_levering_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              KasseCopy.a1_kasse_lev_sheet_title,
              style: bDisplay(
                ctx,
                20,
                weight: FontWeight.w800,
                color: BergenTokens.ink,
              ),
            ),
            SizedBox(height: 10 * s),
            Row(
              children: [
                BergenChip(
                  label: KasseCopy.a1_kasse_levering,
                  selected: !mode,
                  onTap: () => setState(() => mode = false),
                ),
                SizedBox(width: 8 * s),
                BergenChip(
                  label: KasseCopy.a1_kasse_henting,
                  selected: mode,
                  onTap: () => setState(() => mode = true),
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            for (final slot in slots)
              Padding(
                padding: EdgeInsets.only(bottom: 8 * s),
                child: BergenCard(
                  key: Key('a1_kasse_slot_${slot.id}'),
                  onTap: () => setState(() => chosen = slot),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * s,
                    vertical: 12 * s,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.label,
                              style: bDisplay(
                                ctx,
                                15,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                            Text(
                              slot.line,
                              style: bText(
                                ctx,
                                11.5,
                                weight: FontWeight.w600,
                                color: BergenTokens.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        chosen?.id == slot.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: chosen?.id == slot.id
                            ? BergenTokens.orange
                            : BergenTokens.inkFaint,
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 6 * s),
            BergenCta3d(
              key: const Key('a1_kasse_bruk_dette'),
              label: KasseCopy.a1_kasse_bruk_dette,
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

/// Betaling: returns the legacy payment type (3 = Vipps, 2 = card), or null.
Future<int?> showBetalingSheet(BuildContext context, {int? selected}) {
  final phone = prefGetString(prefContactNumber).trim();
  return showBergenArk<int>(
    context,
    title: KasseCopy.a1_kasse_bet_sheet_title,
    subtitle: KasseCopy.a1_kasse_bet_sheet_line,
    rows: [
      BergenArkRow(
        label: KasseCopy.a1_kasse_bet_vipps(phone),
        icon: selected == 3
            ? Icons.check_circle_rounded
            : Icons.account_balance_wallet_outlined,
        onTap: () => Navigator.of(context).pop(3),
      ),
      BergenArkRow(
        label: KasseCopy.a1_kasse_bet_kort,
        value: KasseCopy.a1_kasse_kort_legacy,
        icon: selected == 2
            ? Icons.check_circle_rounded
            : Icons.credit_card_outlined,
        onTap: () => Navigator.of(context).pop(2),
      ),
    ],
  );
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
