import 'package:flutter/material.dart';

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
import 'dreieskiven.dart';
import 'klede_sheet.dart';

/// `{{ butSideLabel }}` (≈L2705–3033 in `Ærend Kunde Bergen.dc.html`): the
/// fashion / gift store page. Label "Mote-butikk" / "Gavebutikk · {navn}" /
/// "Anledning · {x}"; hero with "N kikker nå" from
/// `ops.customer.stores.presence`; "Ukens utstilling" on the Dreieskiven;
/// PERSONALETS FAVORITT; "Til denne:" cross-sell; brand chips; the shelves
/// with −% and points badges; "Usikker på størrelsen? Spør butikken" →
/// `ops.customer.contact`; the gift variant; mini basket + bar.
class MoteButikkScreen extends StatefulWidget {
  const MoteButikkScreen({
    super.key,
    required this.store,
    required this.api,
    required this.customerApi,
    this.occasion,
  });

  final BergenStoreInfo store;
  final OpsButikkApi api;
  final OpsCustomerApi customerApi;
  final String? occasion;

  @override
  State<MoteButikkScreen> createState() => _MoteButikkScreenState();
}

class _MoteButikkScreenState extends State<MoteButikkScreen> {
  String _brand = '';
  String? _forWhom;
  final Set<int> _saved = {};
  final List<BergenMenuItem> _lines = [];
  bool _miniOpen = false;
  Map<String, dynamic>? _presence;
  double? _pointsPct;

  BergenStoreInfo get store => widget.store;
  bool get isGift => store.kind == BergenStoreKind.gift;

  String get _label {
    if (widget.occasion != null)
      return ButikkCopy.a1_butikk_anledning_label(widget.occasion!);
    return isGift
        ? ButikkCopy.a1_butikk_gave_label(store.name)
        : ButikkCopy.a1_butikk_mote_label;
  }

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
  }

  /// The categories double as brands on a fashion store.
  List<String> get _brands => [for (final c in store.menu) c.name];

  List<BergenMenuItem> get _shelf {
    final all = store.allItems;
    if (_brand.isEmpty) return all;
    return [
      for (final i in all)
        if (i.categoryName == _brand) i,
    ];
  }

  List<BergenMenuItem> get _display => store.allItems.take(6).toList();

  Future<void> _add(BergenMenuItem item) async {
    final ok = await BergenCart.add(
      context,
      storeId: item.storeId,
      productId: item.id,
    );
    if (ok && mounted) setState(() => _lines.add(item));
  }

  void _open(BergenMenuItem item) {
    showKledeSheet(
      context,
      item: item,
      api: widget.api,
      brand: item.categoryName,
    ).then((_) {
      if (!mounted) return;
      if (prefGetInt(prefCartCount) > _lines.length)
        setState(() => _lines.add(item));
    });
  }

  Future<void> _save(BergenMenuItem item) async {
    final ok = await widget.api.subscribeToPrice(item.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _saved.add(item.id));
      showBergenToast(context, ButikkCopy.a1_butikk_skive_lagret);
    } else {
      showBergenToast(context, BergenRoutes.kommerSnart);
    }
  }

  Future<void> _askStore() async {
    final controller = TextEditingController();
    final text = await showBergenArk<String>(
      context,
      title: ButikkCopy.a1_butikk_spor_butikken,
      subtitle: ButikkCopy.a1_butikk_storrelse_hint_generic,
      body: TextField(
        key: const Key('a1_butikk_spor_felt'),
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: ButikkCopy.a1_butikk_melding_hint,
          border: const OutlineInputBorder(),
        ),
      ),
      primary: BergenArkAction(
        label: ButikkCopy.a1_butikk_send,
        onTap: () => Navigator.of(context).pop(controller.text.trim()),
      ),
    );
    if (!mounted || text == null || text.isEmpty) return;
    // The store contact route is per order (contract §3.2); with no order
    // open, the question rides on the customer's latest order at this store
    // when there is one, else it goes to Ægil with the store intent.
    final orders = await widget.customerApi.orders(limit: 20);
    final mine = orders
        .where(
          (o) =>
              (o['store'] is Map) &&
              ((o['store']['id'] as num?)?.toInt() == store.id),
        )
        .firstOrNull;
    if (!mounted) return;
    if (mine != null) {
      final id = int.tryParse('${mine['order_id']}') ?? 0;
      final res = await widget.customerApi.contact(
        id,
        kind: 'message',
        message: text,
      );
      if (!mounted) return;
      showBergenToast(
        context,
        res != null
            ? ButikkCopy.a1_butikk_melding_sendt
            : BergenRoutes.kommerSnart,
      );
      return;
    }
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      arguments: {'intent': 'store', 'store_id': '${store.id}', 'q': text},
      orElse: () =>
          openScreen(context, SnurreChatScreen(draftFromHomeSearch: text)),
    );
  }

  void _askAegilGift() => BergenRoutes.pushOr(
    context,
    kAegilRoute,
    arguments: {
      'intent': 'gift',
      'store_id': '${store.id}',
      if (_forWhom != null) 'for': _forWhom!,
    },
    orElse: () => openScreen(context, const SnurreChatScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final viewers = (_presence?['viewers_now'] as num?)?.toInt() ?? 0;
    final display = _display;
    final front = display.firstOrNull;
    final crossSell = store.allItems
        .where((i) => front == null || i.id != front.id)
        .firstOrNull;
    final subtotal = _lines.fold<double>(0, (a, l) => a + l.price);

    return Scaffold(
      backgroundColor: BergenTokens.paper,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: 120 * s),
            children: [
              // ── Hero ───────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                  16 * s,
                  safeTop + 10 * s,
                  16 * s,
                  16 * s,
                ),
                decoration: BoxDecoration(
                  gradient: isGift
                      ? const LinearGradient(
                          colors: [Color(0xFFF2C14E), Color(0xFFF26D3D)],
                        )
                      : kBergenScreenGradient,
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
                              border: Border.all(
                                color: const Color(0x40FFFFFF),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20 * s,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _label,
                          key: const Key('a1_butikk_mote_label'),
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w800,
                            color: const Color(0xE6FFFFFF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14 * s),
                    Row(
                      children: [
                        Container(
                          width: 46 * s,
                          height: 46 * s,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14 * s),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: store.logoUrl != null
                              ? Image.network(
                                  store.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      store.name.isEmpty ? '?' : store.name[0],
                                      style: bDisplay(
                                        context,
                                        18,
                                        weight: FontWeight.w800,
                                        color: BergenTokens.ink,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    store.name.isEmpty ? '?' : store.name[0],
                                    style: bDisplay(
                                      context,
                                      18,
                                      weight: FontWeight.w800,
                                      color: BergenTokens.ink,
                                    ),
                                  ),
                                ),
                        ),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                key: const Key('a1_butikk_navn'),
                                style: bDisplay(
                                  context,
                                  22,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ).copyWith(letterSpacing: -0.5),
                              ),
                              Text(
                                [
                                  if (store.closeTime != null && store.open)
                                    ButikkCopy.a1_butikk_open_til(
                                      store.closeTime!,
                                    ),
                                  if (!store.open) ButikkCopy.a1_butikk_stengt,
                                  if (store.deliveryMinutes != null)
                                    '${store.deliveryMinutes} min',
                                  if (store.deliveryChargeKr != null)
                                    ButikkCopy.a1_butikk_levering(
                                      store.deliveryChargeKr == 0
                                          ? ButikkCopy.a1_butikk_kat_free
                                          : ButikkCopy.kr(
                                              store.deliveryChargeKr!,
                                            ),
                                    ),
                                ].join(' · '),
                                style: bText(
                                  context,
                                  11.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xE6FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (viewers > 0)
                          Container(
                            key: const Key('a1_butikk_kikker'),
                            padding: EdgeInsets.symmetric(
                              horizontal: 9 * s,
                              vertical: 4 * s,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x40FFFFFF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x80FFFFFF),
                              ),
                            ),
                            child: Text(
                              ButikkCopy.a1_butikk_kikker(viewers),
                              style: bText(
                                context,
                                10,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Gift: Ægil + Til hvem ──────────────────────────────────
              if (isGift)
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _askAegilGift,
                        child: Text(
                          ButikkCopy.a1_butikk_gave_aegil,
                          key: const Key('a1_butikk_gave_aegil'),
                          style: bText(
                            context,
                            12.5,
                            weight: FontWeight.w800,
                            color: BergenTokens.teal,
                          ),
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      Text(
                        ButikkCopy.a1_butikk_til_hvem,
                        style: bDisplay(
                          context,
                          14,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      Wrap(
                        spacing: 8 * s,
                        runSpacing: 8 * s,
                        children: [
                          for (final h in ButikkCopy.a1_butikk_til_hvem_liste)
                            BergenChip(
                              label: h,
                              selected: _forWhom == h,
                              onTap: () => setState(
                                () => _forWhom = _forWhom == h ? null : h,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              // ── Ukens utstilling ───────────────────────────────────────
              if (display.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGift
                            ? ButikkCopy.a1_butikk_gave_utstilling
                            : ButikkCopy.a1_butikk_mote_utstilling,
                        key: const Key('a1_butikk_utstilling'),
                        style: bDisplay(
                          context,
                          16,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      Dreieskiven(
                        items: display,
                        saved: _saved,
                        who:
                            '${ButikkCopy.a1_butikk_personalets} · ${store.name}',
                        onAdd: _add,
                        onOpen: _open,
                        onSave: _save,
                      ),
                      if (crossSell != null) ...[
                        SizedBox(height: 12 * s),
                        BergenCard(
                          key: const Key('a1_butikk_til_denne'),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * s,
                            vertical: 10 * s,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ButikkCopy.a1_butikk_til_denne(
                                    crossSell.name,
                                    ButikkCopy.kr(crossSell.price),
                                  ),
                                  style: bText(
                                    context,
                                    12,
                                    weight: FontWeight.w700,
                                    color: BergenTokens.ink,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _add(crossSell),
                                child: Text(
                                  _lines.any((l) => l.id == crossSell.id)
                                      ? ButikkCopy.a1_butikk_lagt_til
                                      : ButikkCopy.a1_butikk_pluss_legg,
                                  style: bText(
                                    context,
                                    12,
                                    weight: FontWeight.w800,
                                    color: BergenTokens.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 10 * s),
                      GestureDetector(
                        key: const Key('a1_butikk_spor_butikken'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _askStore,
                        child: Text(
                          ButikkCopy.a1_butikk_spor_butikken,
                          style: bText(
                            context,
                            12,
                            weight: FontWeight.w800,
                            color: BergenTokens.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // ── Brands ────────────────────────────────────────────────
              if (_brands.length > 1) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 8 * s),
                  child: Text(
                    ButikkCopy.a1_butikk_merker,
                    style: bDisplay(
                      context,
                      14,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40 * s,
                  child: ListView(
                    key: const Key('a1_butikk_merker'),
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16 * s),
                    children: [
                      BergenChip(
                        label: ButikkCopy.a1_butikk_alle,
                        selected: _brand.isEmpty,
                        onTap: () => setState(() => _brand = ''),
                      ),
                      SizedBox(width: 8 * s),
                      for (final b in _brands) ...[
                        BergenChip(
                          label: b,
                          selected: _brand == b,
                          onTap: () => setState(() => _brand = b),
                        ),
                        SizedBox(width: 8 * s),
                      ],
                    ],
                  ),
                ),
              ],
              // ── Shelves ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 8 * s),
                child: Text(
                  ButikkCopy.a1_butikk_hyllene,
                  style: bDisplay(
                    context,
                    16,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
              ),
              if (_shelf.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s),
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
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s),
                  child: GridView.builder(
                    key: const Key('a1_butikk_hyller'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10 * s,
                      crossAxisSpacing: 10 * s,
                      childAspectRatio: .72,
                    ),
                    itemCount: _shelf.length,
                    itemBuilder: (context, i) => _ShelfTile(
                      item: _shelf[i],
                      points: _pointsPct == null
                          ? null
                          : (_shelf[i].price * _pointsPct! / 100).round(),
                      inCart: _lines.any((l) => l.id == _shelf[i].id),
                      gift: isGift,
                      onOpen: () => _open(_shelf[i]),
                      onAdd: () => _add(_shelf[i]),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _askStore,
                  child: Text(
                    ButikkCopy.a1_butikk_storrelse_hint_generic,
                    style: bText(
                      context,
                      11.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                            ButikkCopy.kr(subtotal),
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

class _ShelfTile extends StatelessWidget {
  const _ShelfTile({
    required this.item,
    required this.onOpen,
    required this.onAdd,
    this.points,
    this.inCart = false,
    this.gift = false,
  });

  final BergenMenuItem item;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final int? points;
  final bool inCart;
  final bool gift;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final pct = item.wasPrice == null || item.wasPrice == 0
        ? null
        : ((1 - item.price / item.wasPrice!) * 100).round();
    return OnbPressable(
      onTap: onOpen,
      pressScale: .985,
      child: Container(
        key: Key('a1_butikk_hylle_${item.id}'),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl != null)
                    Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFE9E2D2)),
                    )
                  else
                    Container(
                      color: BergenTokens.paperWarm,
                      child: Icon(
                        gift
                            ? Icons.card_giftcard_rounded
                            : Icons.checkroom_rounded,
                        color: BergenTokens.teal,
                        size: 34 * s,
                      ),
                    ),
                  Positioned(
                    left: 8 * s,
                    top: 8 * s,
                    child: Wrap(
                      spacing: 4 * s,
                      children: [
                        if (pct != null && pct > 0)
                          _Badge(text: '−$pct%', color: BergenTokens.orange),
                        if (points != null && points! > 0)
                          _Badge(
                            text: '+$points',
                            color: BergenTokens.lantern,
                            dark: true,
                          ),
                        if (gift)
                          _Badge(
                            text: ButikkCopy.a1_butikk_innpakning,
                            color: BergenTokens.mint,
                            dark: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ButikkCopy.kr(item.price),
                          style: bDisplay(
                            context,
                            14,
                            weight: FontWeight.w800,
                            color: BergenTokens.ink,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: Key('a1_butikk_hylle_add_${item.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onAdd,
                        child: Container(
                          height: 28 * s,
                          padding: EdgeInsets.symmetric(horizontal: 10 * s),
                          decoration: BoxDecoration(
                            gradient: inCart ? null : kBergenOrangeGradient,
                            color: inCart ? BergenTokens.paperWarm : null,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            inCart
                                ? ButikkCopy.a1_butikk_i_kurven
                                : ButikkCopy.a1_butikk_legg_til,
                            style: bText(
                              context,
                              10.5,
                              weight: FontWeight.w800,
                              color: inCart ? BergenTokens.ink : Colors.white,
                            ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, this.dark = false});

  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: bText(
          context,
          9.5,
          weight: FontWeight.w800,
          color: dark ? BergenTokens.ink : Colors.white,
        ),
      ),
    );
  }
}
