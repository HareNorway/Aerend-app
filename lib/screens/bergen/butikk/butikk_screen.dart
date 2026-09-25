import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';
import 'info_sheet.dart';
import 'mote_butikk_screen.dart';
import 'produkt_sheet.dart';

/// `/bergen/butikk/{id}` (arguments: `id`, optional `name`, `category`,
/// `product_id`). Loads the store and shows the restaurant page
/// (`erButikk` ≈L3035–3520) or, for a fashion / gift store, the
/// `{{ butSideLabel }}` page (≈L2705–3033, [MoteButikkScreen]).
class ButikkScreen extends StatefulWidget {
  const ButikkScreen({
    super.key,
    this.storeId,
    this.name,
    this.category,
    this.productId,
    this.api,
    this.customerApi,
    this.preloaded,
  });

  final int? storeId;
  final String? name;
  final String? category;
  final int? productId;
  final OpsButikkApi? api;
  final OpsCustomerApi? customerApi;

  /// Tests inject the store.
  final BergenStoreInfo? preloaded;

  @override
  State<ButikkScreen> createState() => _ButikkScreenState();
}

class _ButikkScreenState extends State<ButikkScreen> {
  bool _routeRead = false;
  int _id = 0;
  String? _name;
  String? _category;
  int? _productId;
  BergenStoreInfo? _store;
  bool _missing = false;

  OpsButikkApi get _api => widget.api ?? OpsButikkApi();
  OpsCustomerApi get _customer => widget.customerApi ?? OpsCustomerApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _id = widget.storeId ?? int.tryParse(args['id'] ?? '') ?? 0;
    _name = widget.name ?? args['name'];
    _category = widget.category ?? args['category'];
    _productId = widget.productId ?? int.tryParse(args['product_id'] ?? '');
    if (widget.preloaded != null) {
      _store = widget.preloaded;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openRequestedProduct(),
      );
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final store = await _api.store(_id, categoryHint: _category);
    if (!mounted) return;
    setState(() {
      _store = store;
      _missing = store == null;
    });
    _openRequestedProduct();
  }

  void _openRequestedProduct() {
    final store = _store;
    final pid = _productId;
    if (store == null || pid == null) return;
    final item = store.allItems.where((i) => i.id == pid).firstOrNull;
    if (item == null) return;
    _productId = null;
    showProduktSheet(
      context,
      item: item,
      api: _api,
      customerApi: _customer,
      readyMinutes: store.deliveryMinutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (_missing) {
      return Scaffold(
        backgroundColor: BergenTokens.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: BergenTokens.ink,
        ),
        body: Center(
          child: Text(
            ButikkCopy.a1_butikk_not_found,
            key: const Key('a1_butikk_not_found'),
            style: bText(
              context,
              13,
              weight: FontWeight.w700,
              color: BergenTokens.inkSecondary,
            ),
          ),
        ),
      );
    }
    if (store == null) {
      return Scaffold(
        backgroundColor: BergenTokens.paper,
        body: Center(
          child: CircularProgressIndicator(
            color: BergenTokens.teal,
            semanticsLabel: _name,
          ),
        ),
      );
    }
    if (store.isFashionOrGift) {
      return MoteButikkScreen(store: store, api: _api, customerApi: _customer);
    }
    return RestaurantButikkBody(
      store: store,
      api: _api,
      customerApi: _customer,
    );
  }
}

/// The restaurant page body (`erButikk`).
class RestaurantButikkBody extends StatefulWidget {
  const RestaurantButikkBody({
    super.key,
    required this.store,
    required this.api,
    required this.customerApi,
  });

  final BergenStoreInfo store;
  final OpsButikkApi api;
  final OpsCustomerApi customerApi;

  @override
  State<RestaurantButikkBody> createState() => _RestaurantButikkBodyState();
}

class _RestaurantButikkBodyState extends State<RestaurantButikkBody> {
  int _catIndex = 0;
  int _special = 0;
  bool _miniOpen = false;
  final List<BergenMenuItem> _lines = [];
  Map<String, dynamic>? _presence;
  Map<String, dynamic>? _availability;
  double? _pointsPct;

  BergenStoreInfo get store => widget.store;

  double get _subtotal => _lines.fold(0, (a, l) => a + l.price);

  @override
  void initState() {
    super.initState();
    _loadSide();
  }

  Future<void> _loadSide() async {
    final presence = await widget.customerApi.storePresence(store.id);
    if (mounted && presence != null) setState(() => _presence = presence);
    final rules = await widget.customerApi.pointsRules();
    if (mounted && rules != null) {
      final pct = (rules['earn_percent'] ?? rules['rate']) as num?;
      if (pct != null) setState(() => _pointsPct = pct.toDouble());
    }
    final avail = await widget.customerApi.driftNotice(storeId: store.id);
    if (mounted && avail != null) setState(() => _availability = avail);
  }

  Future<void> _add(BergenMenuItem item) async {
    final ok = await BergenCart.add(
      context,
      storeId: item.storeId,
      productId: item.id,
    );
    if (ok && mounted) setState(() => _lines.add(item));
  }

  void _open(BergenMenuItem item, {bool mostOrdered = false}) {
    showProduktSheet(
      context,
      item: item,
      api: widget.api,
      customerApi: widget.customerApi,
      readyMinutes: store.deliveryMinutes,
      mostOrdered: mostOrdered,
    ).then((_) {
      // The sheet adds through the cart; mirror the line locally for the
      // voyage and the mini basket.
      if (!mounted) return;
      final count = prefGetInt(prefCartCount);
      if (count > _lines.length) setState(() => _lines.add(item));
    });
  }

  void _askAegil() => BergenRoutes.pushOr(
    context,
    kAegilRoute,
    arguments: {
      'intent': 'store',
      'store_id': '${store.id}',
      'store': store.name,
    },
    orElse: () => openScreen(context, const SnurreChatScreen()),
  );

  /// The voyage's thresholds, in order: the real minimum order, the real free
  /// delivery threshold when the store has one, then the design's tiers.
  List<(double, String)> get _tiers {
    final tiers = <(double, String)>[];
    if (store.minOrderKr != null && store.minOrderKr! > 0)
      tiers.add((
        store.minOrderKr!,
        ButikkCopy.a1_butikk_min(store.minOrderKr!),
      ));
    if (store.offerMinAmountKr != null && store.offerMinAmountKr! > 0)
      tiers.add((store.offerMinAmountKr!, ButikkCopy.a1_butikk_gratis_frakt));
    if (tiers.isEmpty) tiers.add((150, ButikkCopy.a1_butikk_min(150)));
    return tiers;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final menu = store.menu;
    final cat = menu.isEmpty ? null : menu[_catIndex.clamp(0, menu.length - 1)];
    final specials = store.specials;
    final tiers = _tiers;
    final goal = tiers.last.$1;
    final frac = goal <= 0 ? 0.0 : (_subtotal / goal).clamp(0.0, 1.0);
    final next = tiers.where((t) => t.$1 > _subtotal).firstOrNull;
    final viewers = (_presence?['viewers_now'] as num?)?.toInt() ?? 0;
    final kitchenOpen = _availability == null
        ? store.open
        : _availability!['state'] == 'open';

    return Scaffold(
      backgroundColor: BergenTokens.paper,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: 120 * s),
            children: [
              // ── Hero ───────────────────────────────────────────────────
              SizedBox(
                height: 230 * s + safeTop,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (store.bannerUrl != null)
                      Image.network(
                        store.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF2F6B7B)),
                      )
                    else
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: kBergenScreenGradient,
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x8004121A),
                            Color(0x0004121A),
                            Color(0xD904121A),
                          ],
                          stops: [0, .4, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16 * s,
                      top: safeTop + 10 * s,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 40 * s,
                          height: 40 * s,
                          decoration: BoxDecoration(
                            color: const Color(0x59000000),
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
                    ),
                    Positioned(
                      left: 16 * s,
                      right: 16 * s,
                      bottom: 16 * s,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            key: const Key('a1_butikk_navn'),
                            style: bDisplay(
                              context,
                              26,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ).copyWith(letterSpacing: -0.6),
                          ),
                          SizedBox(height: 4 * s),
                          Text(
                            [
                              if (store.address != null)
                                store.address!.split(',').first,
                              if (store.distanceKm != null)
                                ButikkCopy.a1_butikk_km(store.distanceKm!),
                              if (store.closeTime != null && store.open)
                                ButikkCopy.a1_butikk_open_til(store.closeTime!),
                              if (!store.open && store.openTime != null)
                                ButikkCopy.a1_butikk_apner(store.openTime!),
                              if (!store.open && store.openTime == null)
                                ButikkCopy.a1_butikk_stengt,
                            ].join(' · '),
                            style: bText(
                              context,
                              12,
                              weight: FontWeight.w700,
                              color: const Color(0xE6FFFFFF),
                            ),
                          ),
                          SizedBox(height: 8 * s),
                          Wrap(
                            spacing: 6 * s,
                            runSpacing: 6 * s,
                            children: [
                              _Tag(
                                text: kitchenOpen
                                    ? ButikkCopy.a1_butikk_kjokken
                                    : ButikkCopy.a1_butikk_pauset,
                                dot: kitchenOpen
                                    ? BergenTokens.mint
                                    : BergenTokens.lantern,
                              ),
                              if (store.deliveryMinutes != null)
                                _Tag(text: '${store.deliveryMinutes} min'),
                              if (store.deliveryChargeKr != null)
                                _Tag(
                                  text: ButikkCopy.a1_butikk_levering(
                                    store.deliveryChargeKr == 0
                                        ? ButikkCopy.a1_butikk_kat_free
                                        : ButikkCopy.kr(
                                            store.deliveryChargeKr!,
                                          ),
                                  ),
                                ),
                              if (store.rating != null)
                                _Tag(text: '★ ${store.rating}'),
                              if (viewers > 0)
                                _Tag(
                                  text: ButikkCopy.a1_butikk_kikker(viewers),
                                  key: const Key('a1_butikk_kikker'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Seilas ─────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
                child: Container(
                  key: const Key('a1_butikk_seilas'),
                  padding: EdgeInsets.all(14 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF25606F), Color(0xFF173E48)],
                    ),
                    borderRadius: BorderRadius.circular(22 * s),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x5904121A),
                        offset: Offset(0, 16),
                        blurRadius: 30,
                        spreadRadius: -14,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ButikkCopy.a1_butikk_seilas,
                            style: bText(
                              context,
                              10,
                              weight: FontWeight.w800,
                              color: BergenTokens.mint,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _askAegil,
                            child: Text(
                              ButikkCopy.a1_butikk_spor_aegil,
                              style: bText(
                                context,
                                11,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      Row(
                        children: [
                          Text(
                            ButikkCopy.a1_butikk_kjokkenet,
                            style: bText(
                              context,
                              10.5,
                              weight: FontWeight.w800,
                              color: const Color(0xFF9FD3DE),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            ButikkCopy.a1_butikk_din_dor,
                            style: bText(
                              context,
                              10.5,
                              weight: FontWeight.w800,
                              color: const Color(0xFF9FD3DE),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6 * s),
                      Stack(
                        children: [
                          Container(
                            height: 8 * s,
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          AnimatedFractionallySizedBox(
                            duration: BergenTokens.motion(
                              context,
                              BergenTokens.motionBase,
                            ),
                            widthFactor: frac == 0 ? 0.02 : frac,
                            child: Container(
                              height: 8 * s,
                              decoration: BoxDecoration(
                                gradient: kBergenOrangeGradient,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          for (final t in tiers)
                            Positioned(
                              left: 0,
                              right: 0,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (t.$1 / goal).clamp(0.02, 1.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 3,
                                    height: 8 * s,
                                    color: const Color(0xB3FFFFFF),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8 * s),
                      Row(
                        children: [
                          Text(
                            '${ButikkCopy.kr(_subtotal)} / ${ButikkCopy.kr(goal)}',
                            key: const Key('a1_butikk_seilas_sum'),
                            style: bText(
                              context,
                              11,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              next == null
                                  ? ButikkCopy.a1_butikk_havn
                                  : '${ButikkCopy.a1_butikk_neste} · ${ButikkCopy.a1_butikk_igjen(next.$1 - _subtotal, next.$2)}',
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFFDCE9EC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // ── Info buttons ───────────────────────────────────────────
              SizedBox(
                height: 44 * s,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 0),
                  children: [
                    BergenChip(
                      key: const Key('a1_butikk_info_a'),
                      label: ButikkCopy.a1_butikk_allergener,
                      onTap: () => showInfoSheet(context, store: store),
                    ),
                    SizedBox(width: 8 * s),
                    BergenChip(
                      key: const Key('a1_butikk_info_t'),
                      label: store.closeTime != null
                          ? ButikkCopy.a1_butikk_open_til(store.closeTime!)
                          : ButikkCopy.a1_butikk_apningstider,
                      onTap: () => showInfoSheet(
                        context,
                        store: store,
                        initial: InfoTab.apningstider,
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    BergenChip(
                      key: const Key('a1_butikk_info_m'),
                      label: ButikkCopy.a1_butikk_mer,
                      onTap: () => showInfoSheet(
                        context,
                        store: store,
                        initial: InfoTab.mer,
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    BergenChip(
                      label: ButikkCopy.a1_butikk_del,
                      icon: Icons.ios_share_rounded,
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: 'aerend://bergen/butikk/${store.id}',
                          ),
                        );
                        if (context.mounted)
                          showBergenToast(
                            context,
                            ButikkCopy.a1_butikk_info_kopiert,
                          );
                      },
                    ),
                  ],
                ),
              ),
              // ── Spør Ægil row ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 0),
                child: BergenCard(
                  onTap: _askAegil,
                  padding: EdgeInsets.all(12 * s),
                  child: Row(
                    children: [
                      Image.asset(
                        BergenAssets.aegilPopup,
                        width: 34 * s,
                        height: 34 * s,
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ButikkCopy.a1_butikk_spor_aegil,
                              style: bText(
                                context,
                                12.5,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                            Text(
                              ButikkCopy.a1_butikk_spor_aegil_line,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w600,
                                color: BergenTokens.inkFaint,
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
              ),
              // ── Kjøkkenluka ────────────────────────────────────────────
              if (specials.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 8 * s),
                  child: Row(
                    children: [
                      Text(
                        ButikkCopy.a1_butikk_kjokkenluka,
                        key: const Key('a1_butikk_kjokkenluka'),
                        style: bDisplay(
                          context,
                          16,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      Flexible(
                        child: Text(
                          ButikkCopy.a1_butikk_spesial,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w800,
                            color: BergenTokens.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 150 * s,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: .86),
                    itemCount: specials.length,
                    onPageChanged: (i) => setState(() => _special = i),
                    itemBuilder: (context, i) {
                      final sp = specials[i];
                      final kroner = _pointsPct == null
                          ? null
                          : (sp.price * _pointsPct! / 100).round();
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6 * s),
                        child: OnbPressable(
                          onTap: () => _open(sp),
                          pressScale: .985,
                          child: Container(
                            padding: EdgeInsets.all(12 * s),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20 * s),
                              border: Border.all(
                                color: i == _special
                                    ? BergenTokens.orange
                                    : BergenTokens.paperWarm,
                                width: i == _special ? 2 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2623201D),
                                  offset: Offset(0, 12),
                                  blurRadius: 22,
                                  spreadRadius: -12,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14 * s),
                                  child: SizedBox(
                                    width: 96 * s,
                                    height: 96 * s,
                                    child: sp.imageUrl != null
                                        ? Image.network(
                                            sp.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const ColoredBox(
                                                  color: Color(0xFFE9E2D2),
                                                ),
                                          )
                                        : const DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFFF6D9B4),
                                                  Color(0xFFD2854A),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(width: 12 * s),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sp.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: bDisplay(
                                          context,
                                          15,
                                          weight: FontWeight.w800,
                                          color: BergenTokens.ink,
                                        ),
                                      ),
                                      SizedBox(height: 4 * s),
                                      Row(
                                        children: [
                                          Text(
                                            ButikkCopy.kr(sp.price),
                                            style: bDisplay(
                                              context,
                                              16,
                                              weight: FontWeight.w800,
                                              color: BergenTokens.ink,
                                            ),
                                          ),
                                          SizedBox(width: 6 * s),
                                          Text(
                                            ButikkCopy.kr(sp.wasPrice!),
                                            style:
                                                bText(
                                                  context,
                                                  11,
                                                  weight: FontWeight.w600,
                                                  color: BergenTokens.inkFaint,
                                                ).copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6 * s),
                                      Wrap(
                                        spacing: 6 * s,
                                        children: [
                                          _Tag(
                                            text: ButikkCopy.a1_butikk_spar(
                                              sp.savedKr,
                                            ),
                                            dark: true,
                                          ),
                                          if (kroner != null && kroner > 0)
                                            _Tag(
                                              text: ButikkCopy.a1_butikk_kroner(
                                                kroner,
                                              ),
                                              dark: true,
                                              gold: true,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              // ── Category tabs + menu ───────────────────────────────────
              if (menu.isNotEmpty) ...[
                SizedBox(
                  height: 44 * s,
                  child: ListView(
                    key: const Key('a1_butikk_kategorier'),
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
                    children: [
                      for (var i = 0; i < menu.length; i++) ...[
                        BergenChip(
                          label: menu[i].name,
                          selected: i == _catIndex,
                          onTap: () => setState(() => _catIndex = i),
                        ),
                        SizedBox(width: 8 * s),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 8 * s),
                  child: Row(
                    children: [
                      Text(
                        cat?.name ?? ButikkCopy.a1_butikk_mest_bestilt,
                        style: bDisplay(
                          context,
                          16,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ButikkCopy.a1_butikk_inkl_mva,
                        style: bText(
                          context,
                          10.5,
                          weight: FontWeight.w700,
                          color: BergenTokens.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cat != null && cat.items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * s),
                    child: Text(
                      ButikkCopy.a1_butikk_drikke_hint,
                      style: bText(
                        context,
                        12,
                        weight: FontWeight.w600,
                        color: BergenTokens.inkSecondary,
                      ),
                    ),
                  ),
                if (cat != null)
                  for (var i = 0; i < cat.items.length; i++)
                    _MenuRow(
                      item: cat.items[i],
                      mostOrdered: i == 0 && _catIndex == 0,
                      onOpen: () => _open(
                        cat.items[i],
                        mostOrdered: i == 0 && _catIndex == 0,
                      ),
                      onAdd: () => _add(cat.items[i]),
                    ),
              ] else
                Padding(
                  padding: EdgeInsets.all(20 * s),
                  child: Text(
                    ButikkCopy.a1_butikk_menu_empty,
                    key: const Key('a1_butikk_menu_empty'),
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkSecondary,
                    ),
                  ),
                ),
            ],
          ),
          // ── Mini basket + floating bar ─────────────────────────────────
          if (_lines.isNotEmpty)
            Positioned(
              left: 16 * s,
              right: 16 * s,
              bottom: MediaQuery.paddingOf(context).bottom + 12 * s,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_miniOpen)
                    Container(
                      key: const Key('a1_butikk_minikurv'),
                      margin: EdgeInsets.only(bottom: 8 * s),
                      padding: EdgeInsets.all(12 * s),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18 * s),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4023201D),
                            offset: Offset(0, 14),
                            blurRadius: 26,
                            spreadRadius: -12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ButikkCopy.a1_butikk_i_kurven,
                                style: bText(
                                  context,
                                  11,
                                  weight: FontWeight.w800,
                                  color: BergenTokens.inkFaint,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(_lines.clear),
                                child: Text(
                                  ButikkCopy.a1_butikk_tom_kurven,
                                  style: bText(
                                    context,
                                    11,
                                    weight: FontWeight.w800,
                                    color: BergenTokens.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          for (final l in _lines)
                            Padding(
                              padding: EdgeInsets.only(top: 6 * s),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: bText(
                                        context,
                                        12.5,
                                        weight: FontWeight.w700,
                                        color: BergenTokens.ink,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ButikkCopy.kr(l.price),
                                    style: bText(
                                      context,
                                      12.5,
                                      weight: FontWeight.w800,
                                      color: BergenTokens.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _miniOpen = !_miniOpen),
                    child: Container(
                      key: const Key('a1_butikk_kurvbar'),
                      height: 58 * s,
                      padding: EdgeInsets.symmetric(horizontal: 14 * s),
                      decoration: BoxDecoration(
                        color: BergenTokens.ink,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x6623201D),
                            offset: Offset(0, 14),
                            blurRadius: 26,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _miniOpen
                                ? Icons.expand_more_rounded
                                : Icons.expand_less_rounded,
                            color: Colors.white,
                            size: 20 * s,
                          ),
                          SizedBox(width: 8 * s),
                          Text(
                            ButikkCopy.a1_butikk_kurv_antall(_lines.length),
                            style: bText(
                              context,
                              12.5,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            ButikkCopy.kr(_subtotal),
                            style: bDisplay(
                              context,
                              15,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10 * s),
                          BergenCta3d(
                            label: ButikkCopy.a1_butikk_til_kassen,
                            expand: false,
                            onPressed: () =>
                                BergenRoutes.push(context, '/bergen/kurv'),
                          ),
                        ],
                      ),
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

class _Tag extends StatelessWidget {
  const _Tag({
    super.key,
    required this.text,
    this.dot,
    this.dark = false,
    this.gold = false,
  });

  final String text;
  final Color? dot;
  final bool dark;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: gold
            ? BergenTokens.lantern
            : (dark ? BergenTokens.paperWarm : const Color(0x40FFFFFF)),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? Colors.transparent : const Color(0x80FFFFFF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6 * s,
              height: 6 * s,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            SizedBox(width: 5 * s),
          ],
          Text(
            text,
            style: bText(
              context,
              10,
              weight: FontWeight.w800,
              color: dark || gold ? BergenTokens.ink : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.onOpen,
    required this.onAdd,
    this.mostOrdered = false,
  });

  final BergenMenuItem item;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final bool mostOrdered;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 10 * s),
      child: OnbPressable(
        onTap: onOpen,
        pressScale: .99,
        child: Container(
          key: Key('a1_butikk_menu_${item.id}'),
          padding: EdgeInsets.all(10 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18 * s),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F23201D),
                offset: Offset(0, 10),
                blurRadius: 18,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mostOrdered)
                      Text(
                        ButikkCopy.a1_butikk_mest_bestilt,
                        style: bText(
                          context,
                          9.5,
                          weight: FontWeight.w800,
                          color: BergenTokens.orange,
                        ),
                      ),
                    Text(
                      item.name,
                      style: bDisplay(
                        context,
                        14.5,
                        weight: FontWeight.w800,
                        color: BergenTokens.ink,
                      ),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bText(
                          context,
                          11.5,
                          weight: FontWeight.w500,
                          color: BergenTokens.inkSecondary,
                        ),
                      ),
                    SizedBox(height: 6 * s),
                    Row(
                      children: [
                        Text(
                          ButikkCopy.kr(item.price),
                          style: bDisplay(
                            context,
                            14,
                            weight: FontWeight.w800,
                            color: BergenTokens.ink,
                          ),
                        ),
                        if (item.wasPrice != null) ...[
                          SizedBox(width: 6 * s),
                          Text(
                            ButikkCopy.kr(item.wasPrice!),
                            style: bText(
                              context,
                              11,
                              weight: FontWeight.w600,
                              color: BergenTokens.inkFaint,
                            ).copyWith(decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10 * s),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14 * s),
                    child: SizedBox(
                      width: 72 * s,
                      height: 72 * s,
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
                                  colors: [
                                    Color(0xFFF6D9B4),
                                    Color(0xFFD2854A),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  GestureDetector(
                    key: Key('a1_butikk_menu_add_${item.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onAdd,
                    child: Container(
                      height: 30 * s,
                      padding: EdgeInsets.symmetric(horizontal: 12 * s),
                      decoration: BoxDecoration(
                        gradient: kBergenOrangeGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ButikkCopy.a1_butikk_legg_til,
                        style: bText(
                          context,
                          11,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
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
