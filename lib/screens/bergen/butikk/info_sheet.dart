import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../deliveryService/home/ds_home_store_list_pojo.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';

/// The store Info sheet (≈L6913 in `Ærend Kunde Bergen.dc.html`, the
/// `sheetInfo` block): Allergener / Åpningstider / Mer via [BergenArk].
enum InfoTab { allergener, apningstider, mer }

Future<void> showInfoSheet(
  BuildContext context, {
  required BergenStoreInfo store,
  InfoTab initial = InfoTab.allergener,
  List<String> allergens = const [],
}) {
  return showBergenSheet<void>(
    context,
    builder: (_) =>
        InfoSheet(store: store, initial: initial, allergens: allergens),
  );
}

class InfoSheet extends StatefulWidget {
  const InfoSheet({
    super.key,
    required this.store,
    this.initial = InfoTab.allergener,
    this.allergens = const [],
  });

  final BergenStoreInfo store;
  final InfoTab initial;
  final List<String> allergens;

  @override
  State<InfoSheet> createState() => _InfoSheetState();
}

class _InfoSheetState extends State<InfoSheet> {
  late InfoTab _tab = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final store = widget.store;
    return Column(
      key: const Key('a1_butikk_info_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          store.name,
          style: bDisplay(
            context,
            18,
            weight: FontWeight.w800,
            color: BergenTokens.ink,
          ),
        ),
        SizedBox(height: 10 * s),
        Wrap(
          spacing: 8 * s,
          runSpacing: 8 * s,
          children: [
            for (final (t, label) in [
              (InfoTab.allergener, ButikkCopy.a1_butikk_allergener),
              (InfoTab.apningstider, ButikkCopy.a1_butikk_apningstider),
              (InfoTab.mer, ButikkCopy.a1_butikk_mer),
            ]) ...[
              BergenChip(
                key: Key('a1_butikk_info_${t.name}'),
                label: label,
                selected: _tab == t,
                onTap: () => setState(() => _tab = t),
              ),
            ],
          ],
        ),
        SizedBox(height: 14 * s),
        switch (_tab) {
          InfoTab.allergener => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.allergens.isEmpty
                    ? ButikkCopy.a1_butikk_info_allergen_missing
                    : ButikkCopy.a1_butikk_info_allergen_line,
                style: bText(
                  context,
                  12.5,
                  weight: FontWeight.w500,
                  color: BergenTokens.inkSecondary,
                ),
              ),
              if (widget.allergens.isNotEmpty) ...[
                SizedBox(height: 10 * s),
                Wrap(
                  spacing: 8 * s,
                  runSpacing: 8 * s,
                  children: [
                    for (final a in widget.allergens) BergenChip(label: a),
                  ],
                ),
              ],
            ],
          ),
          InfoTab.apningstider =>
            store.hours.isEmpty
                ? Text(
                    store.closeTime != null
                        ? ButikkCopy.a1_butikk_open_til(store.closeTime!)
                        : ButikkCopy.a1_butikk_info_stengt,
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkSecondary,
                    ),
                  )
                : Column(
                    children: [
                      for (final h in store.hours)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4 * s),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  h.day,
                                  style: bText(
                                    context,
                                    12.5,
                                    weight: FontWeight.w700,
                                    color: BergenTokens.ink,
                                  ),
                                ),
                              ),
                              Text(
                                h.opens.isEmpty || h.closes.isEmpty
                                    ? ButikkCopy.a1_butikk_info_stengt
                                    : '${h.opens}–${h.closes}',
                                style: bText(
                                  context,
                                  12.5,
                                  weight: FontWeight.w600,
                                  color: BergenTokens.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          InfoTab.mer => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (store.address != null) store.address!,
                  [
                    if (store.minOrderKr != null && store.minOrderKr! > 0)
                      ButikkCopy.a1_butikk_info_minste(
                        ButikkCopy.kr(store.minOrderKr!),
                      ),
                    if (store.deliveryChargeKr != null)
                      ButikkCopy.a1_butikk_info_levering(
                        ButikkCopy.kr(store.deliveryChargeKr!),
                      ),
                    if (store.pickupPossible) ButikkCopy.a1_butikk_info_henting,
                  ].join(' · '),
                  if (store.description != null) store.description!,
                ].where((e) => e.isNotEmpty).join('. '),
                style: bText(
                  context,
                  12.5,
                  weight: FontWeight.w500,
                  color: BergenTokens.inkSecondary,
                ),
              ),
              SizedBox(height: 12 * s),
              BergenCta3d(
                label: ButikkCopy.a1_butikk_info_del,
                icon: Icons.ios_share_rounded,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: 'aerend://bergen/butikk/${store.id}'),
                  );
                  if (context.mounted)
                    showBergenToast(context, ButikkCopy.a1_butikk_info_kopiert);
                },
              ),
            ],
          ),
        },
      ],
    );
  }
}

/// The category sheet (`arkAapent` ≈L7143): the category's name, "Åpne nå ·
/// {bydel}", and its stores and products as rows.
Future<void> showKategoriArk(
  BuildContext context, {
  required String name,
  required String bydel,
  required List<StoreListItem> stores,
  required ValueChanged<StoreListItem> onStore,
}) {
  return showBergenArk<void>(
    context,
    title: name,
    subtitle: ButikkCopy.a1_butikk_ark_under(bydel),
    rows: [
      for (final st in stores)
        BergenArkRow(
          label: st.storeName ?? '',
          value: [
            if ((st.storeStatus ?? 1) == 1) ButikkCopy.a1_butikk_ark_open,
            if ((st.orderDeliveryTime ?? 0) > 0)
              ButikkCopy.a1_butikk_kat_eta(st.orderDeliveryTime!),
            if (st.averageRatings != null) '★ ${st.averageRatings}',
          ].join(' · '),
          onTap: () {
            Navigator.of(context).pop();
            onStore(st);
          },
        ),
    ],
  );
}
