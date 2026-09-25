import 'package:flutter/material.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_home.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../deliveryService/home/ds_home_store_list_pojo.dart';
import '../../deliveryService/searchStore/search_store_dl.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';
import 'dreieskiven.dart';
import 'info_sheet.dart';
import 'produkt_sheet.dart';

/// `kategori` (≈L4748–4856 in `Ærend Kunde Bergen.dc.html`) at
/// `/bergen/kategori/{slug}` (arguments: `slug`, and `id` / `name` when the
/// caller knows them).
///
/// "{n} åpne nå · Bergen", the title, "Bestill fra bilde" (Mat only — C3 is
/// agil-3's; the button pushes `kAegilRoute` with `intent=photo`), Butikker /
/// Produkter tabs, the live strip from `ops.customer.categories.pulse`, shop
/// cards, the product grid and the filter chips. Two variants: **Gaver**
/// (≈L4774) and **Mote** (≈L4825, the Dreieskiven).
class KategoriScreen extends StatefulWidget {
  const KategoriScreen({
    super.key,
    this.slug,
    this.categoryId,
    this.name,
    this.api,
    this.customerApi,
  });

  final String? slug;
  final int? categoryId;
  final String? name;
  final OpsButikkApi? api;
  final OpsCustomerApi? customerApi;

  static const String filterOpen = 'open';
  static const String filterFree = 'free';
  static const String filterFast = 'fast';
  static const String filterTop = 'top';

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen> {
  late String _slug;
  int? _id;
  String? _name;
  bool _routeRead = false;
  bool _tabProducts = false;
  final Set<String> _filters = {};
  List<StoreListItem>? _stores;
  List<ProductList>? _products;
  Map<String, dynamic>? _pulse;
  final Set<int> _saved = {};

  OpsButikkApi get _api => widget.api ?? OpsButikkApi();
  OpsCustomerApi get _customer => widget.customerApi ?? OpsCustomerApi();

  BergenStoreKind get _kind => BergenStoreInfo.kindOf(_name ?? _slug);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _slug = widget.slug ?? args['slug'] ?? 'kategori';
    _id = widget.categoryId ?? int.tryParse(args['id'] ?? '');
    _name = widget.name ?? args['name'];
    _load();
  }

  Future<void> _load() async {
    if (_id == null) {
      final cats = await _api.categories();
      for (final c in cats) {
        if (BergenHomeSlug.of(c.serviceCategoryName) == _slug) {
          _id = c.serviceCategoryId;
          _name ??= c.serviceCategoryName;
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {});
    final pulse = _customer.categoryPulse(_slug);
    final id = _id;
    if (id != null) {
      final stores = await _api.storesInCategory(id);
      if (!mounted) return;
      setState(() => _stores = stores);
      final products = await _api.productsInCategory(id);
      if (!mounted) return;
      setState(() => _products = products);
    } else {
      setState(() {
        _stores = const [];
        _products = const [];
      });
    }
    final p = await pulse;
    if (!mounted) return;
    setState(() => _pulse = p);
  }

  List<StoreListItem> get _filteredStores {
    final list = _stores ?? const [];
    return [
      for (final s in list)
        if (!_filters.contains(KategoriScreen.filterOpen) ||
            (s.storeStatus ?? 1) == 1)
          if (!_filters.contains(KategoriScreen.filterFast) ||
              ((s.orderDeliveryTime ?? 999) <= 30))
            if (!_filters.contains(KategoriScreen.filterTop) ||
                ((double.tryParse('${s.averageRatings ?? 0}') ?? 0) >= 4.5))
              // Free delivery: the store list carries no fee — the chip
              // keeps stores with an offer line (the closest real signal).
              if (!_filters.contains(KategoriScreen.filterFree) ||
                  ((s.offer ?? '').isNotEmpty))
                s,
    ];
  }

  void _toggle(String f) => setState(
    () => _filters.contains(f) ? _filters.remove(f) : _filters.add(f),
  );

  void _openStore(StoreListItem s) {
    final id = s.storeId ?? 0;
    if (id == 0) return;
    BergenRoutes.push(
      context,
      '/bergen/butikk/$id',
      arguments: {'name': s.storeName ?? '', 'category': _name ?? ''},
    );
  }

  void _openProduct(ProductList p) {
    final item = BergenMenuItem(
      id: p.productId,
      name: p.productName,
      storeId: p.storeId,
      storeName: p.storeName,
      price:
          double.tryParse('${p.discountAmount ?? ''}') ??
          double.tryParse('${p.productAmount ?? ''}') ??
          0,
      imageUrl: p.productImage.isEmpty ? null : p.productImage,
    );
    showProduktSheet(context, item: item, api: _api, customerApi: _customer);
  }

  void _askAegil(String intent) {
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      arguments: {'intent': intent, 'category': _name ?? _slug},
      orElse: () => openScreen(context, const SnurreChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final name = _name ?? _slug;
    final stores = _stores;
    final openCount = (stores ?? const [])
        .where((e) => (e.storeStatus ?? 1) == 1)
        .length;
    final look = BergenCategoryLook.forName(name);
    final kind = _kind;

    return Scaffold(
      backgroundColor: BergenTokens.paper,
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 40 * s),
        children: [
          // ── Hero band ─────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16 * s,
              safeTop + 10 * s,
              16 * s,
              16 * s,
            ),
            decoration: BoxDecoration(
              gradient: look?.hero ?? kBergenScreenGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40 * s,
                        height: 40 * s,
                        decoration: BoxDecoration(
                          color: const Color(0x33000000),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20 * s,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (stores != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showKategoriArk(
                          context,
                          name: name,
                          bydel: 'Bergen',
                          stores: stores,
                          onStore: _openStore,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10 * s,
                            vertical: 5 * s,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x2EFFFFFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            ButikkCopy.a1_butikk_kat_open(openCount),
                            key: const Key('a1_butikk_kat_open'),
                            style: bText(
                              context,
                              10.5,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 14 * s),
                Text(
                  name,
                  key: const Key('a1_butikk_kat_title'),
                  style: bDisplay(
                    context,
                    26,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ).copyWith(letterSpacing: -0.6),
                ),
                if (kind == BergenStoreKind.gift) ...[
                  SizedBox(height: 8 * s),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _askAegil('gift'),
                    child: Text(
                      ButikkCopy.a1_butikk_gave_aegil,
                      key: const Key('a1_butikk_gave_aegil'),
                      style: bText(
                        context,
                        12.5,
                        weight: FontWeight.w800,
                        color: BergenTokens.mint,
                      ),
                    ),
                  ),
                ],
                if (kind == BergenStoreKind.restaurant) ...[
                  SizedBox(height: 10 * s),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BergenChip(
                      key: const Key('a1_butikk_kat_bilde'),
                      label: ButikkCopy.a1_butikk_kat_bestill_bilde,
                      icon: Icons.photo_camera_outlined,
                      onDark: true,
                      onTap: () => _askAegil('photo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Live strip ─────────────────────────────────────────────────
          if (_pulse != null &&
              ((_pulse!['orders_last_hour'] as num?)?.toInt() ?? 0) > 0)
            Container(
              key: const Key('a1_butikk_kat_pulse'),
              margin: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * s,
                vertical: 8 * s,
              ),
              decoration: BoxDecoration(
                color: const Color(0x1F1E4F5C),
                borderRadius: BorderRadius.circular(14 * s),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8 * s,
                    height: 8 * s,
                    decoration: const BoxDecoration(
                      color: BergenTokens.mintDeep,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      ButikkCopy.a1_butikk_kat_pulse(
                        name,
                        (_pulse!['orders_last_hour'] as num).toInt(),
                      ),
                      style: bText(
                        context,
                        11.5,
                        weight: FontWeight.w700,
                        color: BergenTokens.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ── Gaver: today's picks + occasions ──────────────────────────
          if (kind == BergenStoreKind.gift)
            _GaverBlock(
              products: _products ?? const [],
              onOpen: _openProduct,
              onAegil: () => _askAegil('gift'),
            ),
          // ── Mote: the week's display ──────────────────────────────────
          if (kind == BergenStoreKind.fashion &&
              (_products ?? const []).isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ButikkCopy.a1_butikk_mote_utstilling,
                        key: const Key('a1_butikk_mote_utstilling'),
                        style: bDisplay(
                          context,
                          16,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ButikkCopy.a1_butikk_mote_antall(
                          (_products ?? const []).take(6).length,
                        ),
                        style: bText(
                          context,
                          10.5,
                          weight: FontWeight.w800,
                          color: BergenTokens.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * s),
                  Dreieskiven(
                    items: [
                      for (final p in (_products ?? const []).take(6))
                        _menuItem(p),
                    ],
                    saved: _saved,
                    onAdd: (i) => BergenCart.add(
                      context,
                      storeId: i.storeId,
                      productId: i.id,
                    ),
                    onOpen: (i) => showProduktSheet(
                      context,
                      item: i,
                      api: _api,
                      customerApi: _customer,
                    ),
                    onSave: (i) => _save(i),
                  ),
                ],
              ),
            ),
          // ── Tabs ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
            child: Row(
              children: [
                _Tab(
                  label: ButikkCopy.a1_butikk_kat_butikker,
                  count: stores?.length,
                  active: !_tabProducts,
                  onTap: () => setState(() => _tabProducts = false),
                  keyName: 'a1_butikk_kat_tab_butikker',
                ),
                SizedBox(width: 8 * s),
                _Tab(
                  label: ButikkCopy.a1_butikk_kat_produkter,
                  count: _products?.length,
                  active: _tabProducts,
                  onTap: () => setState(() => _tabProducts = true),
                  keyName: 'a1_butikk_kat_tab_produkter',
                ),
              ],
            ),
          ),
          if (!_tabProducts) ...[
            SizedBox(
              height: 44 * s,
              child: ListView(
                key: const Key('a1_butikk_kat_filters'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 0),
                children: [
                  for (final (f, label) in [
                    (
                      KategoriScreen.filterOpen,
                      ButikkCopy.a1_butikk_kat_f_open,
                    ),
                    (
                      KategoriScreen.filterFree,
                      ButikkCopy.a1_butikk_kat_f_free,
                    ),
                    (
                      KategoriScreen.filterFast,
                      ButikkCopy.a1_butikk_kat_f_fast,
                    ),
                    (KategoriScreen.filterTop, ButikkCopy.a1_butikk_kat_f_top),
                  ]) ...[
                    BergenChip(
                      label: label,
                      selected: _filters.contains(f),
                      onTap: () => _toggle(f),
                    ),
                    SizedBox(width: 8 * s),
                  ],
                ],
              ),
            ),
            SizedBox(height: 8 * s),
            if (stores == null)
              Padding(
                padding: EdgeInsets.all(30 * s),
                child: const Center(
                  child: CircularProgressIndicator(color: BergenTokens.teal),
                ),
              )
            else if (_filteredStores.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * s,
                  vertical: 16 * s,
                ),
                child: Text(
                  ButikkCopy.a1_butikk_kat_empty,
                  key: const Key('a1_butikk_kat_empty'),
                  style: bText(
                    context,
                    13,
                    weight: FontWeight.w600,
                    color: BergenTokens.inkSecondary,
                  ),
                ),
              )
            else
              for (final st in _filteredStores)
                _StoreCard(
                  store: st,
                  gift: kind == BergenStoreKind.gift,
                  onTap: () => _openStore(st),
                ),
          ] else ...[
            SizedBox(height: 10 * s),
            if (_products == null)
              Padding(
                padding: EdgeInsets.all(30 * s),
                child: const Center(
                  child: CircularProgressIndicator(color: BergenTokens.teal),
                ),
              )
            else if (_products!.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * s,
                  vertical: 16 * s,
                ),
                child: Text(
                  ButikkCopy.a1_butikk_kat_empty_products,
                  style: bText(
                    context,
                    13,
                    weight: FontWeight.w600,
                    color: BergenTokens.inkSecondary,
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                child: GridView.builder(
                  key: const Key('a1_butikk_kat_grid'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10 * s,
                    crossAxisSpacing: 10 * s,
                    childAspectRatio: .78,
                  ),
                  itemCount: _products!.length,
                  itemBuilder: (context, i) => _ProductTile(
                    product: _products![i],
                    onOpen: () => _openProduct(_products![i]),
                    onAdd: () => BergenCart.add(
                      context,
                      storeId: _products![i].storeId,
                      productId: _products![i].productId,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  BergenMenuItem _menuItem(ProductList p) => BergenMenuItem(
    id: p.productId,
    name: p.productName,
    storeId: p.storeId,
    storeName: p.storeName,
    price:
        double.tryParse('${p.discountAmount ?? ''}') ??
        double.tryParse('${p.productAmount ?? ''}') ??
        0,
    imageUrl: p.productImage.isEmpty ? null : p.productImage,
  );

  Future<void> _save(BergenMenuItem i) async {
    final ok = await _api.subscribeToPrice(i.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _saved.add(i.id));
      showBergenToast(context, ButikkCopy.a1_butikk_skive_lagret);
    } else {
      showBergenToast(context, BergenRoutes.kommerSnart);
    }
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    required this.keyName,
  });

  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      key: Key(keyName),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: BergenTokens.motion(context, BergenTokens.motionFast),
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 9 * s),
        decoration: BoxDecoration(
          gradient: active ? kBergenOrangeGradient : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? BergenTokens.orangeDeep : BergenTokens.paperWarm,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: bText(
                context,
                12.5,
                weight: FontWeight.w800,
                color: active ? Colors.white : BergenTokens.ink,
              ),
            ),
            if (count != null) ...[
              SizedBox(width: 6 * s),
              Text(
                '$count',
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w800,
                  color: active
                      ? const Color(0xE6FFFFFF)
                      : BergenTokens.inkFaint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.onTap,
    this.gift = false,
  });

  final StoreListItem store;
  final VoidCallback onTap;
  final bool gift;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final open = (store.storeStatus ?? 1) == 1;
    final eta = store.orderDeliveryTime ?? 0;
    final rating = store.averageRatings == null
        ? null
        : '${store.averageRatings}';
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 10 * s),
      child: OnbPressable(
        onTap: onTap,
        pressScale: .985,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2623201D),
                offset: Offset(0, 12),
                blurRadius: 22,
                spreadRadius: -12,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120 * s,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((store.storeBanner ?? '').isNotEmpty)
                      Image.network(
                        store.storeBanner!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF2F6B7B)),
                      )
                    else
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2F6B7B), Color(0xFF1B4854)],
                          ),
                        ),
                      ),
                    if ((store.offer ?? '').isNotEmpty)
                      Positioned(
                        left: 10 * s,
                        top: 10 * s,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9 * s,
                            vertical: 4 * s,
                          ),
                          decoration: BoxDecoration(
                            color: BergenTokens.orange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            store.offer!,
                            style: bText(
                              context,
                              10,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (gift)
                      Positioned(
                        right: 10 * s,
                        top: 10 * s,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * s,
                            vertical: 4 * s,
                          ),
                          decoration: BoxDecoration(
                            color: BergenTokens.lantern,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            ButikkCopy.a1_butikk_gave_innpakning,
                            style: bText(
                              context,
                              9,
                              weight: FontWeight.w800,
                              color: BergenTokens.ink,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 12 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.storeName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bDisplay(
                              context,
                              15,
                              weight: FontWeight.w800,
                              color: BergenTokens.ink,
                            ),
                          ),
                          Text(
                            [
                              if (!open) ButikkCopy.a1_butikk_stengt,
                              if (eta > 0) ButikkCopy.a1_butikk_kat_eta(eta),
                              if (rating != null) '★ $rating',
                              if ((store.storeProducts ?? '').isNotEmpty)
                                store.storeProducts!,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bText(
                              context,
                              11,
                              weight: FontWeight.w600,
                              color: BergenTokens.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: BergenTokens.inkFaint,
                      size: 20 * s,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onOpen,
    required this.onAdd,
  });

  final ProductList product;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final amount = double.tryParse('${product.productAmount ?? ''}') ?? 0;
    final discount = double.tryParse('${product.discountAmount ?? ''}');
    final price = discount != null && discount > 0 && discount < amount
        ? discount
        : amount;
    return OnbPressable(
      onTap: onOpen,
      pressScale: .985,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18 * s),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2623201D),
              offset: Offset(0, 10),
              blurRadius: 18,
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.productImage.isNotEmpty
                  ? Image.network(
                      product.productImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
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
            Padding(
              padding: EdgeInsets.all(10 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  Text(
                    product.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bText(
                      context,
                      10.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkFaint,
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ButikkCopy.kr(price),
                          style: bDisplay(
                            context,
                            14,
                            weight: FontWeight.w800,
                            color: BergenTokens.ink,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onAdd,
                        child: Container(
                          width: 30 * s,
                          height: 30 * s,
                          decoration: const BoxDecoration(
                            gradient: kBergenOrangeGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18 * s,
                            color: Colors.white,
                          ),
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
    );
  }
}

/// Gaver-kategori (≈L4774): "Rekker fram i dag · Innen 18:15", occasions,
/// and "Populært til bursdag".
class _GaverBlock extends StatelessWidget {
  const _GaverBlock({
    required this.products,
    required this.onOpen,
    required this.onAegil,
  });

  final List<ProductList> products;
  final ValueChanged<ProductList> onOpen;
  final VoidCallback onAegil;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final now = DateTime.now();
    // Same-day cut-off: the design's 18:15; real stores' cut-offs are in
    // their hours (TODO(api): a category-wide same-day cut-off).
    final cutoff = '18:15';
    final today = now.hour < 18 || (now.hour == 18 && now.minute < 15);
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (today) ...[
            Row(
              children: [
                Text(
                  ButikkCopy.a1_butikk_gave_idag,
                  key: const Key('a1_butikk_gave_idag'),
                  style: bDisplay(
                    context,
                    16,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
                SizedBox(width: 8 * s),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * s,
                    vertical: 3 * s,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x2E5CE0B8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ButikkCopy.a1_butikk_gave_innen(cutoff),
                    style: bText(
                      context,
                      10,
                      weight: FontWeight.w800,
                      color: BergenTokens.mintDeep,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * s),
            SizedBox(
              height: 130 * s,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in products.take(6)) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onOpen(p),
                      child: Container(
                        width: 120 * s,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16 * s),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2623201D),
                              offset: Offset(0, 10),
                              blurRadius: 18,
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: p.productImage.isNotEmpty
                                  ? Image.network(
                                      p.productImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                            color: Color(0xFFE9E2D2),
                                          ),
                                    )
                                  : const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFF2C14E),
                                            Color(0xFFF26D3D),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8 * s),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: bText(
                                      context,
                                      11.5,
                                      weight: FontWeight.w800,
                                      color: BergenTokens.ink,
                                    ),
                                  ),
                                  Text(
                                    ButikkCopy.kr(
                                      double.tryParse(
                                            '${p.productAmount ?? ''}',
                                          ) ??
                                          0,
                                    ),
                                    style: bText(
                                      context,
                                      11,
                                      weight: FontWeight.w700,
                                      color: BergenTokens.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14 * s),
          ],
          Text(
            ButikkCopy.a1_butikk_gave_anledninger,
            style: bDisplay(
              context,
              16,
              weight: FontWeight.w800,
              color: BergenTokens.ink,
            ),
          ),
          SizedBox(height: 8 * s),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final a in ButikkCopy.a1_butikk_gave_anledning_liste)
                BergenChip(label: a, onTap: onAegil),
            ],
          ),
          SizedBox(height: 14 * s),
          Text(
            ButikkCopy.a1_butikk_gave_populaert('Bergenhus'),
            style: bDisplay(
              context,
              16,
              weight: FontWeight.w800,
              color: BergenTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}
