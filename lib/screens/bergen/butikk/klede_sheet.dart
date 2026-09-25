import 'package:flutter/material.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';

/// The Klede sheet (`visKlede` ≈L2630 in `Ærend Kunde Bergen.dc.html`):
/// colour, size with stock, quantity, "Prøv hjemme. Budet henter returen
/// gratis innen 14 dager." and "Legg i kurv · X kr".
Future<void> showKledeSheet(
  BuildContext context, {
  required BergenMenuItem item,
  OpsButikkApi? api,
  String? brand,
}) {
  return showBergenSheet<void>(
    context,
    builder: (_) =>
        KledeSheet(item: item, api: api ?? OpsButikkApi(), brand: brand),
  );
}

class KledeSheet extends StatefulWidget {
  const KledeSheet({
    super.key,
    required this.item,
    required this.api,
    this.brand,
    this.options,
  });

  final BergenMenuItem item;
  final OpsButikkApi api;
  final String? brand;
  final BergenProductOptions? options;

  @override
  State<KledeSheet> createState() => _KledeSheetState();
}

class _KledeSheetState extends State<KledeSheet> {
  BergenProductOptions? _options;
  int? _colour;
  int? _size;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    if (_options == null) {
      _load();
    } else {
      _defaults();
    }
  }

  Future<void> _load() async {
    final o = await widget.api.options(widget.item.id);
    if (!mounted) return;
    setState(() {
      _options = o;
      _defaults();
    });
  }

  void _defaults() {
    final o = _options;
    if (o == null) return;
    if (o.colours.isNotEmpty)
      _colour = o.colours
          .firstWhere((c) => c.inStock, orElse: () => o.colours.first)
          .id;
  }

  double get _sum {
    final o = _options;
    var unit = widget.item.price;
    final size = o?.sizes.where((v) => v.id == _size).firstOrNull;
    if (size != null) unit += size.priceDelta;
    return unit * _qty;
  }

  Future<void> _add() async {
    final o = _options;
    if (o != null && o.sizes.isNotEmpty && _size == null) {
      showBergenToast(context, ButikkCopy.a1_butikk_klede_velg_str);
      return;
    }
    final ok = await BergenCart.add(
      context,
      storeId: widget.item.storeId,
      productId: widget.item.id,
      quantity: _qty,
      sizeId: _size ?? 0,
      colourId: _colour ?? 0,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final item = widget.item;
    final o = _options;
    final colourName = o?.colours
        .where((c) => c.id == _colour)
        .firstOrNull
        ?.name;

    return Column(
      key: const Key('a1_butikk_klede_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22 * s),
          child: SizedBox(
            height: 220 * s,
            width: double.infinity,
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFFE9E2D2)),
                  )
                : Container(
                    color: BergenTokens.paperWarm,
                    child: Icon(
                      Icons.checkroom_rounded,
                      size: 48 * s,
                      color: BergenTokens.teal,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12 * s),
        if (widget.brand != null || item.categoryName != null)
          Text(
            (widget.brand ?? item.categoryName!).toUpperCase(),
            style: bText(
              context,
              10,
              weight: FontWeight.w800,
              color: BergenTokens.inkFaint,
            ),
          ),
        Text(
          item.name,
          key: const Key('a1_butikk_klede_navn'),
          style: bDisplay(
            context,
            20,
            weight: FontWeight.w800,
            color: BergenTokens.ink,
          ),
        ),
        Row(
          children: [
            Text(
              ButikkCopy.kr(item.price),
              style: bDisplay(
                context,
                17,
                weight: FontWeight.w800,
                color: BergenTokens.ink,
              ),
            ),
            if (item.wasPrice != null) ...[
              SizedBox(width: 8 * s),
              Text(
                ButikkCopy.kr(item.wasPrice!),
                style: bText(
                  context,
                  12,
                  weight: FontWeight.w600,
                  color: BergenTokens.inkFaint,
                ).copyWith(decoration: TextDecoration.lineThrough),
              ),
            ],
          ],
        ),
        if (item.description != null) ...[
          SizedBox(height: 4 * s),
          Text(
            item.description!,
            style: bText(
              context,
              12.5,
              weight: FontWeight.w500,
              color: BergenTokens.inkSecondary,
            ),
          ),
        ],
        if (o != null && o.colours.isNotEmpty) ...[
          SizedBox(height: 14 * s),
          Row(
            children: [
              Text(
                ButikkCopy.a1_butikk_klede_farge,
                style: bDisplay(
                  context,
                  14,
                  weight: FontWeight.w800,
                  color: BergenTokens.ink,
                ),
              ),
              if (colourName != null) ...[
                SizedBox(width: 6 * s),
                Text(
                  colourName,
                  style: bText(
                    context,
                    11,
                    weight: FontWeight.w700,
                    color: BergenTokens.inkFaint,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8 * s),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final c in o.colours)
                BergenChip(
                  key: Key('a1_butikk_klede_farge_${c.id}'),
                  label: c.name,
                  selected: _colour == c.id,
                  onTap: c.inStock
                      ? () => setState(() => _colour = c.id)
                      : null,
                ),
            ],
          ),
        ],
        if (o != null && o.sizes.isNotEmpty) ...[
          SizedBox(height: 14 * s),
          Row(
            children: [
              Text(
                ButikkCopy.a1_butikk_klede_storrelse,
                style: bDisplay(
                  context,
                  14,
                  weight: FontWeight.w800,
                  color: BergenTokens.ink,
                ),
              ),
              SizedBox(width: 6 * s),
              Text(
                ButikkCopy.a1_butikk_klede_velg_str,
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w700,
                  color: BergenTokens.inkFaint,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * s),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final v in o.sizes)
                BergenChip(
                  key: Key('a1_butikk_klede_str_${v.id}'),
                  label:
                      '${v.name} · ${v.inStock ? ButikkCopy.a1_butikk_klede_paa_lager : ButikkCopy.a1_butikk_klede_utsolgt}',
                  selected: _size == v.id,
                  onTap: v.inStock ? () => setState(() => _size = v.id) : null,
                ),
            ],
          ),
        ],
        SizedBox(height: 14 * s),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
          decoration: BoxDecoration(
            color: const Color(0x1F5CE0B8),
            borderRadius: BorderRadius.circular(14 * s),
            border: Border.all(color: const Color(0x665CE0B8)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.autorenew_rounded,
                size: 16 * s,
                color: BergenTokens.mintDeep,
              ),
              SizedBox(width: 8 * s),
              Expanded(
                child: Text(
                  ButikkCopy.a1_butikk_klede_prov,
                  style: bText(
                    context,
                    11.5,
                    weight: FontWeight.w700,
                    color: BergenTokens.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * s),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: BergenTokens.paperBright,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: BergenTokens.paperWarm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    key: const Key('a1_butikk_klede_minus'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                    child: SizedBox(
                      width: 40 * s,
                      height: 44 * s,
                      child: Icon(
                        Icons.remove_rounded,
                        size: 18 * s,
                        color: _qty > 1
                            ? BergenTokens.ink
                            : BergenTokens.inkFaint,
                      ),
                    ),
                  ),
                  Text(
                    '$_qty',
                    key: const Key('a1_butikk_klede_qty'),
                    style: bDisplay(
                      context,
                      15,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  GestureDetector(
                    key: const Key('a1_butikk_klede_plus'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _qty++),
                    child: SizedBox(
                      width: 40 * s,
                      height: 44 * s,
                      child: Icon(
                        Icons.add_rounded,
                        size: 18 * s,
                        color: BergenTokens.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: BergenCta3d(
                key: const Key('a1_butikk_klede_legg'),
                label: ButikkCopy.a1_butikk_klede_legg(ButikkCopy.kr(_sum)),
                onPressed: _add,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
