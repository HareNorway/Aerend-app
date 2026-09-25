import 'package:flutter/material.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';

/// The food product sheet (`visProdukt` ≈L7211 in `Ærend Kunde Bergen.dc.html`).
///
/// "Mest bestilt i kveld", points (from `GET /api/points/rules`, guarded —
/// hidden when absent), "Klar på N min" (the store's prep time when known),
/// size, add-ons and strength from the product's option groups, allergens
/// when the store lists them, quantity and "Legg til · X kr".
Future<void> showProduktSheet(
  BuildContext context, {
  required BergenMenuItem item,
  OpsButikkApi? api,
  OpsCustomerApi? customerApi,
  int? readyMinutes,
  bool mostOrdered = false,
  List<String> allergens = const [],
}) {
  return showBergenSheet<void>(
    context,
    builder: (_) => ProduktSheet(
      item: item,
      api: api ?? OpsButikkApi(),
      customerApi: customerApi ?? OpsCustomerApi(),
      readyMinutes: readyMinutes,
      mostOrdered: mostOrdered,
      allergens: allergens,
    ),
  );
}

class ProduktSheet extends StatefulWidget {
  const ProduktSheet({
    super.key,
    required this.item,
    required this.api,
    required this.customerApi,
    this.readyMinutes,
    this.mostOrdered = false,
    this.allergens = const [],
    this.options,
  });

  final BergenMenuItem item;
  final OpsButikkApi api;
  final OpsCustomerApi customerApi;
  final int? readyMinutes;
  final bool mostOrdered;
  final List<String> allergens;

  /// Preloaded options (tests).
  final BergenProductOptions? options;

  @override
  State<ProduktSheet> createState() => _ProduktSheetState();
}

class _ProduktSheetState extends State<ProduktSheet> {
  BergenProductOptions? _options;
  int _qty = 1;
  int? _size;
  final Set<int> _picked = {};
  double? _pointsPct;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    if (_options == null) _load();
    _loadPoints();
  }

  Future<void> _load() async {
    final o = await widget.api.options(widget.item.id);
    if (!mounted) return;
    setState(() {
      _options = o;
      if (o.sizes.isNotEmpty && widget.item.hasSizes) {
        _size = o.sizes
            .firstWhere((v) => v.inStock, orElse: () => o.sizes.first)
            .id;
      }
    });
  }

  Future<void> _loadPoints() async {
    final rules = await widget.customerApi.pointsRules();
    if (!mounted || rules == null) return;
    final pct =
        (rules['earn_percent'] ?? rules['points_per_krone'] ?? rules['rate'])
            as num?;
    if (pct != null) setState(() => _pointsPct = pct.toDouble());
  }

  double get _sum {
    final o = _options;
    var unit = widget.item.price;
    if (o != null) {
      final size = o.sizes.where((v) => v.id == _size).firstOrNull;
      if (size != null) unit += size.priceDelta;
      for (final g in o.groups) {
        for (final v in g.options) {
          if (_picked.contains(v.id)) unit += v.priceDelta;
        }
      }
    }
    return unit * _qty;
  }

  void _togglePick(BergenOptionGroup g, BergenVariant v) {
    setState(() {
      if (g.single) {
        for (final other in g.options) {
          _picked.remove(other.id);
        }
        _picked.add(v.id);
      } else if (!_picked.remove(v.id)) {
        _picked.add(v.id);
      }
    });
  }

  Future<void> _add() async {
    final ok = await BergenCart.add(
      context,
      storeId: widget.item.storeId,
      productId: widget.item.id,
      quantity: _qty,
      sizeId: _size ?? 0,
      optionIds: _picked.toList(),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final item = widget.item;
    final o = _options;
    final points = _pointsPct == null
        ? null
        : (item.price * _pointsPct! / 100).round();

    return Column(
      key: const Key('a1_butikk_produkt_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22 * s),
          child: SizedBox(
            height: 150 * s,
            width: double.infinity,
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFFE9E2D2)),
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF6D9B4), Color(0xFFD2854A)],
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12 * s),
        Wrap(
          spacing: 6 * s,
          runSpacing: 6 * s,
          children: [
            if (widget.mostOrdered)
              _Pill(
                text: ButikkCopy.a1_butikk_prod_mest_bestilt,
                color: BergenTokens.orange,
              ),
            if (points != null && points > 0)
              _Pill(
                text: ButikkCopy.a1_butikk_prod_poeng(points),
                color: BergenTokens.lantern,
                dark: true,
              ),
            if (widget.readyMinutes != null)
              _Pill(
                text: ButikkCopy.a1_butikk_prod_klar(widget.readyMinutes!),
                color: BergenTokens.mint,
                dark: true,
              ),
          ],
        ),
        SizedBox(height: 8 * s),
        Text(
          item.name,
          key: const Key('a1_butikk_produkt_navn'),
          style: bDisplay(
            context,
            20,
            weight: FontWeight.w800,
            color: BergenTokens.ink,
          ),
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
        SizedBox(height: 6 * s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ButikkCopy.kr(item.price),
              style: bDisplay(
                context,
                18,
                weight: FontWeight.w800,
                color: BergenTokens.ink,
              ),
            ),
            SizedBox(width: 6 * s),
            Text(
              ButikkCopy.a1_butikk_prod_inkl_mva,
              style: bText(
                context,
                10.5,
                weight: FontWeight.w600,
                color: BergenTokens.inkFaint,
              ),
            ),
          ],
        ),
        if (o != null && o.sizes.isNotEmpty) ...[
          SizedBox(height: 14 * s),
          _GroupTitle(
            title: ButikkCopy.a1_butikk_prod_storrelse,
            hint: ButikkCopy.a1_butikk_prod_velg_en,
          ),
          SizedBox(height: 8 * s),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final v in o.sizes)
                BergenChip(
                  key: Key('a1_butikk_prod_size_${v.id}'),
                  label: v.priceDelta == 0
                      ? '${v.name} · ${ButikkCopy.a1_butikk_prod_standard}'
                      : '${v.name} · ${v.priceDelta > 0 ? '+' : '−'}${ButikkCopy.kr(v.priceDelta.abs())}',
                  selected: _size == v.id,
                  onTap: v.inStock ? () => setState(() => _size = v.id) : null,
                ),
            ],
          ),
        ],
        if (o != null)
          for (final g in o.groups) ...[
            SizedBox(height: 14 * s),
            _GroupTitle(
              title: g.name.isEmpty
                  ? ButikkCopy.a1_butikk_prod_tillegg
                  : g.name,
              hint: g.single ? ButikkCopy.a1_butikk_prod_velg_en : null,
            ),
            SizedBox(height: 8 * s),
            Wrap(
              spacing: 8 * s,
              runSpacing: 8 * s,
              children: [
                for (final v in g.options)
                  BergenChip(
                    key: Key('a1_butikk_prod_opt_${v.id}'),
                    label: v.priceDelta == 0
                        ? v.name
                        : '${v.name} · +${ButikkCopy.kr(v.priceDelta)}',
                    selected: _picked.contains(v.id),
                    onTap: () => _togglePick(g, v),
                  ),
              ],
            ),
          ],
        SizedBox(height: 14 * s),
        _GroupTitle(title: ButikkCopy.a1_butikk_prod_allergener),
        SizedBox(height: 4 * s),
        Text(
          widget.allergens.isEmpty
              ? ButikkCopy.a1_butikk_info_allergen_missing
              : widget.allergens.join(' · '),
          style: bText(
            context,
            11.5,
            weight: FontWeight.w600,
            color: BergenTokens.inkSecondary,
          ),
        ),
        SizedBox(height: 16 * s),
        Row(
          children: [
            _Stepper(
              value: _qty,
              onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
              onPlus: () => setState(() => _qty++),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: BergenCta3d(
                key: const Key('a1_butikk_produkt_legg'),
                label: ButikkCopy.a1_butikk_prod_legg(ButikkCopy.kr(_sum)),
                onPressed: _add,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.dark = false});

  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: bText(
          context,
          10,
          weight: FontWeight.w800,
          color: dark ? BergenTokens.ink : Colors.white,
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: bDisplay(
            context,
            14,
            weight: FontWeight.w800,
            color: BergenTokens.ink,
          ),
        ),
        if (hint != null) ...[
          SizedBox(width: 6 * context.bs),
          Text(
            hint!,
            style: bText(
              context,
              10.5,
              weight: FontWeight.w700,
              color: BergenTokens.inkFaint,
            ),
          ),
        ],
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    Widget btn(IconData icon, VoidCallback? onTap, String key) =>
        GestureDetector(
          key: Key(key),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 40 * s,
            height: 44 * s,
            child: Icon(
              icon,
              size: 18 * s,
              color: onTap == null ? BergenTokens.inkFaint : BergenTokens.ink,
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: BergenTokens.paperBright,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BergenTokens.paperWarm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, onMinus, 'a1_butikk_qty_minus'),
          Text(
            '$value',
            key: const Key('a1_butikk_qty'),
            style: bDisplay(
              context,
              15,
              weight: FontWeight.w800,
              color: BergenTokens.ink,
            ),
          ),
          btn(Icons.add_rounded, onPlus, 'a1_butikk_qty_plus'),
        ],
      ),
    );
  }
}
