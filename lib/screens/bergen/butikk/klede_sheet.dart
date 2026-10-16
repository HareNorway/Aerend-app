import 'package:flutter/material.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';
import '../kit/bergen_perf.dart';

/// The Klede sheet (`visKlede` ≈L2630 in `Ærend Kunde Bergen.dc.html`):
/// colour, size with stock, quantity, "Prøv hjemme. Budet henter returen
/// gratis innen 14 dager." and "Legg i kurv · X kr".
///
/// Catalogue sync (scraper plan Chunk 8): colour swatches with hex; a size
/// greys out when it is sold out in the chosen colour; «3 igjen i din
/// størrelse» at three or fewer; «Lager ikke bekreftet» when the shop did not
/// say; «Lager oppdatert for 2 t siden» for web stock; a swipe gallery; øre
/// prices from `ops.customer.product`; an error state with retry.
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
    this.detail,
  });

  final BergenMenuItem item;
  final OpsButikkApi api;
  final String? brand;
  final BergenProductOptions? options;

  /// Preloaded `ops.customer.product` (tests).
  final BergenProductDetail? detail;

  @override
  State<KledeSheet> createState() => _KledeSheetState();
}

class _KledeSheetState extends State<KledeSheet> {
  BergenProductOptions? _options;
  BergenProductDetail? _detail;
  bool _failed = false;
  int? _colour;
  int? _size;
  int _qty = 1;
  int _image = 0;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _detail = widget.detail;
    if (_options == null) {
      _load();
    } else {
      _defaults();
    }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final results = await Future.wait([
      widget.api.optionsResult(widget.item.id),
      widget.api.productDetailResult(widget.item.id),
    ]);
    if (!mounted) return;
    final o = results[0] as ButikkResult<BergenProductOptions>;
    final d = results[1] as ButikkResult<BergenProductDetail>;
    setState(() {
      // The sheet cannot offer sizes it could not read: an honest error, not an empty sheet.
      _failed = o.failed;
      _options = o.value;
      _detail = d.value ?? _detail;
      _defaults();
    });
  }

  void _defaults() {
    final o = _options;
    if (o == null) return;
    if (o.colours.isNotEmpty && _colour == null) {
      _colour = o.colours
          .firstWhere((c) => c.inStock && _colourHasStock(c), orElse: () => o.colours.first)
          .id;
    }
  }

  String? get _colourName =>
      _options?.colours.where((c) => c.id == _colour).firstOrNull?.name;

  /// The grid cell for a size in the chosen colour (the ops grid first).
  BergenCell? _cell(BergenVariant size) {
    final colour = _colourName;
    for (final c in _detail?.cells ?? const <BergenCell>[]) {
      if ((c.size ?? '').toLowerCase() == size.name.toLowerCase() &&
          (colour == null || (c.colour ?? '').toLowerCase() == colour.toLowerCase())) {
        return c;
      }
    }
    return _options?.cell(size.name, colour);
  }

  /// true / false / null (unknown) for a size in the chosen colour.
  bool? _sizeStock(BergenVariant size) {
    final cell = _cell(size);
    if (cell != null) return cell.inStock;
    return size.stock;
  }

  int? _sizeQty(BergenVariant size) => _cell(size)?.stockQty ?? size.stockQty;

  bool _colourHasStock(BergenVariant colour) {
    final cells = [...?_detail?.cells, ...?_options?.cells]
        .where((c) => (c.colour ?? '').toLowerCase() == colour.name.toLowerCase());
    if (cells.isEmpty) return colour.inStock;
    return cells.any((c) => c.inStock != false);
  }

  double get _base => _detail?.priceKr ?? widget.item.price;
  double? get _was => _detail?.wasPriceKr ?? widget.item.wasPrice;

  double get _sum {
    final o = _options;
    var unit = _base;
    final size = o?.sizes.where((v) => v.id == _size).firstOrNull;
    if (size != null) {
      final cell = _cell(size);
      unit += cell != null ? cell.priceDeltaOre / 100 : size.priceDelta;
    }
    return unit * _qty;
  }

  Future<void> _add() async {
    final o = _options;
    // Sizes not read yet: a jacket could go in the basket without one.
    if (o == null) {
      if (_failed) showBergenToast(context, ButikkCopy.a1_butikk_scr_feil);
      return;
    }
    if (o.sizes.isNotEmpty && _size == null) {
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

  List<String> get _images {
    final d = _detail?.images ?? const <String>[];
    if (d.isNotEmpty) return d;
    final one = widget.item.imageUrl ?? _detail?.imageUrl;
    return one == null ? const [] : [one];
  }

  Widget _picture(BuildContext context, String? url) {
    final s = context.bs;
    return url != null
        ? Image.network(
            cacheWidth: BergenPerf.decodeWidth,
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE9E2D2)),
          )
        : Container(
            color: BergenTokens.paperWarm,
            child: Icon(Icons.checkroom_rounded, size: 48 * s, color: BergenTokens.teal),
          );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final item = widget.item;
    final o = _options;
    final d = _detail;
    final colourName = _colourName;
    final images = _images;
    final selectedSize = o?.sizes.where((v) => v.id == _size).firstOrNull;
    final selectedQty = selectedSize == null ? null : _sizeQty(selectedSize);
    final selectedStock = selectedSize == null ? null : _sizeStock(selectedSize);

    if (_failed && o == null) {
      return Column(
        key: const Key('a1_butikk_klede_feil'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24 * s),
          Icon(Icons.wifi_off_rounded, size: 36 * s, color: BergenTokens.inkFaint),
          SizedBox(height: 10 * s),
          Text(
            ButikkCopy.a1_butikk_scr_feil,
            textAlign: TextAlign.center,
            style: bText(context, 13, weight: FontWeight.w700, color: BergenTokens.ink),
          ),
          SizedBox(height: 14 * s),
          BergenCta3d(
            key: const Key('a1_butikk_klede_prov_igjen'),
            label: ButikkCopy.a1_butikk_scr_prov_igjen,
            onPressed: _load,
          ),
          SizedBox(height: 16 * s),
        ],
      );
    }

    // The sheet host lays its child out unbounded: a long description and two
    // rows of sizes ran past the screen. Cap the height (the host's 92 %
    // minus its handle row, padding and the safe area), scroll the content
    // and keep quantity + «Legg i kurv» pinned.
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * .92 - mq.padding.bottom - 116 * s;

    return ConstrainedBox(
      key: const Key('a1_butikk_klede_sheet'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: SingleChildScrollView(
              key: const Key('a1_butikk_klede_rull'),
              child: _content(context, s, item, o, d, colourName, images, selectedSize, selectedQty, selectedStock),
            ),
          ),
          SizedBox(height: 16 * s),
          _bar(context, s),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    double s,
    BergenMenuItem item,
    BergenProductOptions? o,
    BergenProductDetail? d,
    String? colourName,
    List<String> images,
    BergenVariant? selectedSize,
    int? selectedQty,
    bool? selectedStock,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22 * s),
          child: SizedBox(
            height: 220 * s,
            width: double.infinity,
            child: images.length > 1
                ? Stack(
                    children: [
                      PageView(
                        key: const Key('a1_butikk_klede_galleri'),
                        onPageChanged: (i) => setState(() => _image = i),
                        children: [for (final u in images) _picture(context, u)],
                      ),
                      Positioned(
                        bottom: 8 * s,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < images.length; i++)
                              Container(
                                width: (i == _image ? 16 : 6) * s,
                                height: 6 * s,
                                margin: EdgeInsets.symmetric(horizontal: 2 * s),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: i == _image ? BergenTokens.orange : BergenTokens.paperBright,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _picture(context, images.firstOrNull),
          ),
        ),
        SizedBox(height: 12 * s),
        if (widget.brand != null || item.categoryName != null)
          Text(
            (widget.brand ?? item.categoryName!).toUpperCase(),
            style: bText(context, 10, weight: FontWeight.w800, color: BergenTokens.inkFaint),
          ),
        Text(
          item.name,
          key: const Key('a1_butikk_klede_navn'),
          style: bDisplay(context, 20, weight: FontWeight.w800, color: BergenTokens.ink),
        ),
        Row(
          children: [
            Text(
              ButikkCopy.kr(_base),
              key: const Key('a1_butikk_klede_pris'),
              style: bDisplay(context, 17, weight: FontWeight.w800, color: BergenTokens.ink),
            ),
            if (_was != null && _was! > _base) ...[
              SizedBox(width: 8 * s),
              Text(
                ButikkCopy.kr(_was!),
                style: bText(context, 12, weight: FontWeight.w600, color: BergenTokens.inkFaint)
                    .copyWith(decoration: TextDecoration.lineThrough),
              ),
            ],
          ],
        ),
        if (item.description != null || d?.description != null) ...[
          SizedBox(height: 4 * s),
          Text(
            (item.description ?? d!.description)!,
            style: bText(context, 12.5, weight: FontWeight.w500, color: BergenTokens.inkSecondary),
          ),
        ],
        if (o != null && o.colours.isNotEmpty) ...[
          SizedBox(height: 14 * s),
          Row(
            children: [
              Text(
                ButikkCopy.a1_butikk_klede_farge,
                style: bDisplay(context, 14, weight: FontWeight.w800, color: BergenTokens.ink),
              ),
              if (colourName != null) ...[
                SizedBox(width: 6 * s),
                Text(
                  colourName,
                  key: const Key('a1_butikk_klede_fargenavn'),
                  style: bText(context, 11, weight: FontWeight.w700, color: BergenTokens.inkFaint),
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
                _hexOf(c) != null
                    ? _Swatch(
                        key: Key('a1_butikk_klede_farge_${c.id}'),
                        hex: _hexOf(c)!,
                        selected: _colour == c.id,
                        available: _colourHasStock(c),
                        onTap: () => setState(() {
                          _colour = c.id;
                          // A size sold out in the new colour is let go.
                          final size = o.sizes.where((v) => v.id == _size).firstOrNull;
                          if (size != null && _sizeStock(size) == false) _size = null;
                        }),
                      )
                    : BergenChip(
                        key: Key('a1_butikk_klede_farge_${c.id}'),
                        label: c.name,
                        selected: _colour == c.id,
                        onTap: _colourHasStock(c) ? () => setState(() => _colour = c.id) : null,
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
                style: bDisplay(context, 14, weight: FontWeight.w800, color: BergenTokens.ink),
              ),
              SizedBox(width: 6 * s),
              Text(
                ButikkCopy.a1_butikk_klede_velg_str,
                style: bText(context, 11, weight: FontWeight.w700, color: BergenTokens.inkFaint),
              ),
            ],
          ),
          SizedBox(height: 8 * s),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final v in o.sizes)
                // Sold out in this colour: greyed (faded like a sold-out
                // swatch; the chip itself has no disabled look) and no tap.
                // Unknown stays choosable.
                Opacity(
                  opacity: _sizeStock(v) == false ? .4 : 1,
                  child: BergenChip(
                    key: Key('a1_butikk_klede_str_${v.id}'),
                    label: '${v.name} · ${switch (_sizeStock(v)) {
                      true => ButikkCopy.a1_butikk_klede_paa_lager,
                      false => ButikkCopy.a1_butikk_klede_utsolgt,
                      null => ButikkCopy.a1_butikk_scr_lager_ukjent,
                    }}',
                    selected: _size == v.id,
                    onTap: _sizeStock(v) != false ? () => setState(() => _size = v.id) : null,
                  ),
                ),
            ],
          ),
          if (selectedSize != null && selectedStock == true && selectedQty != null && selectedQty > 0 && selectedQty <= 3) ...[
            SizedBox(height: 6 * s),
            Text(
              ButikkCopy.a1_butikk_scr_igjen(selectedQty),
              key: const Key('a1_butikk_klede_igjen'),
              style: bText(context, 11.5, weight: FontWeight.w800, color: BergenTokens.orangeDeep),
            ),
          ],
          if (selectedSize != null && selectedStock == null) ...[
            SizedBox(height: 6 * s),
            Text(
              ButikkCopy.a1_butikk_scr_lager_ukjent,
              key: const Key('a1_butikk_klede_lager_ukjent'),
              style: bText(context, 11.5, weight: FontWeight.w700, color: BergenTokens.inkFaint),
            ),
          ],
        ],
        if (d?.stockMode == 'web' && d?.stockUpdatedAt != null) ...[
          SizedBox(height: 6 * s),
          Text(
            ButikkCopy.a1_butikk_scr_oppdatert(d!.stockUpdatedAt!),
            key: const Key('a1_butikk_klede_lager_oppdatert'),
            style: bText(context, 11, weight: FontWeight.w600, color: BergenTokens.inkFaint),
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
              Icon(Icons.autorenew_rounded, size: 16 * s, color: BergenTokens.mintDeep),
              SizedBox(width: 8 * s),
              Expanded(
                child: Text(
                  ButikkCopy.a1_butikk_klede_prov,
                  style: bText(context, 11.5, weight: FontWeight.w700, color: BergenTokens.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Quantity and «Legg i kurv · X kr», pinned under the scrolling content.
  Widget _bar(BuildContext context, double s) {
    return Row(
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
                    color: _qty > 1 ? BergenTokens.ink : BergenTokens.inkFaint,
                  ),
                ),
              ),
              Text(
                '$_qty',
                key: const Key('a1_butikk_klede_qty'),
                style: bDisplay(context, 15, weight: FontWeight.w800, color: BergenTokens.ink),
              ),
              GestureDetector(
                key: const Key('a1_butikk_klede_plus'),
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _qty++),
                child: SizedBox(
                  width: 40 * s,
                  height: 44 * s,
                  child: Icon(Icons.add_rounded, size: 18 * s, color: BergenTokens.ink),
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
    );
  }

  /// The colour's hex: from the colour list, else the grid, else the ops colours.
  String? _hexOf(BergenVariant c) {
    if (c.hex != null) return c.hex;
    for (final x in [...?_detail?.cells, ...?_options?.cells]) {
      if ((x.colour ?? '').toLowerCase() == c.name.toLowerCase() && x.hex != null) return x.hex;
    }
    for (final x in _detail?.colours ?? const <({String label, String? hex})>[]) {
      if (x.label.toLowerCase() == c.name.toLowerCase()) return x.hex;
    }
    return null;
  }
}

/// A colour swatch (`farger` in the design): the colour itself, ringed in the
/// accent when chosen, faded when every size of it is sold out.
class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.hex,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final colour = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: available ? 1 : .4,
        child: Container(
          width: 34 * s,
          height: 34 * s,
          padding: EdgeInsets.all(3 * s),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? BergenTokens.orange : BergenTokens.paperWarm,
              width: selected ? 2 * s : 1 * s,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: colour),
          ),
        ),
      ),
    );
  }
}
