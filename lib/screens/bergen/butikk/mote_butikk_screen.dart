import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import '../sok/sok_oversikt.dart' show SokIkon;
import 'butikk_copy.dart';
import 'kategori_utstilling.dart' show MoteSkive, MoteSkiveVare;
import 'klede_sheet.dart';
import 'restaurant_body.dart' show ButikkKurvBar, ButikkMiniKurv;

const _kGlass = [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .06)];

const _kPluss = 'M12 5v14M5 12h14';
const _kAlleIkon =
    'M5.5 3.5h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-3a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2z'
    'M15.5 3.5h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-3a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2z'
    'M5.5 13.5h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-3a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2z'
    'M15.5 13.5h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-3a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2z';

/// The chips' garment icons (Alle, T-skjorter, Gensere, Bukser).
const _kFilterIkon = [
  _kAlleIkon,
  'M9 3l3 2 3-2 5 3-2 4-2-1v12H8V9L6 10 4 6z',
  'M8 3h8l4 4-2 3-1-1v12H7V9L6 10 4 7zM12 3v6',
  'M6 3h12l-1 18h-4l-1-10-1 10H7zM6 7h12',
];

/// What each chip matches in a product's name or description — the
/// prototype filters its garments the same way (`mTreff`).
const _kMoteOrd = [
  <String>[],
  ['t-skjorte', 'tskjorte', 't-shirt', 'topp'],
  ['genser', 'hoodie', 'hettejakke', 'strikk', 'pullover', 'sweater', 'cardigan'],
  ['bukse', 'jeans', 'denim', 'chinos', 'shorts', 'skjørt'],
];
const _kGaveOrd = [
  <String>[],
  ['blomst', 'bukett', 'rose', 'tulipan', 'plante'],
  ['sjokolade', 'konfekt', 'sjoko', 'godteri', 'kake'],
  ['interiør', 'lys', 'vase', 'pute', 'kopp', 'skål', 'pledd'],
];

/// The brand discs: `#0F0F0F`, `#F2EFE7`, `#1B2A44`, … in turn.
const _kMerkeBg = [
  Color(0xFF0F0F0F),
  Color(0xFFF2EFE7),
  Color(0xFF1B2A44),
  Color(0xFFE8E2D6),
  Color(0xFF2E5A4C),
  Color(0xFF2C6675),
];

/// `{{ butSideLabel }}` with `erMoteButikk` (L3380): the fashion / gift
/// store page. Banner hero with the tilted logo, the name sheet with
/// "N kikker nå", "Ukens utstilling" on the Dreieskiven, Merker, Hyllene
/// (Herre / Dame / Barn — price bands in a gift store), the garment grid,
/// the size hint, and the bottom bar of type chips that turns into a search
/// field; the orange basket bar once something is in it.
class MoteButikkScreen extends StatefulWidget {
  const MoteButikkScreen({
    super.key,
    required this.store,
    required this.api,
    required this.customerApi,
    this.kasseApi,
    this.occasion,
  });

  final BergenStoreInfo store;
  final OpsButikkApi api;
  final OpsCustomerApi customerApi;
  final OpsKasseApi? kasseApi;
  final String? occasion;

  @override
  State<MoteButikkScreen> createState() => _MoteButikkScreenState();
}

class _MoteButikkScreenState extends State<MoteButikkScreen> {
  /// The brand disc picked ('' = Alle). Brands are the store's categories.
  String _merke = '';
  int _seg = 0;
  int _filter = 0;
  bool _sokApen = false;
  final TextEditingController _sok = TextEditingController();
  final FocusNode _sokFokus = FocusNode();
  String? _forWhom;
  final Set<int> _saved = {};

  List<KurvLine> _lines = const [];
  bool _mini = false;
  int _pulse = 0;

  /// Products just added: their key shows "I kurven" for 1.8s.
  final Map<int, Timer> _lagt = {};

  Map<String, dynamic>? _presence;
  double? _pointsPct;

  BergenStoreInfo get store => widget.store;
  bool get isGift => store.kind == BergenStoreKind.gift;
  OpsKasseApi get _kasse => widget.kasseApi ?? OpsKasseApi();

  List<String> get _segNavn => isGift ? ButikkCopy.a1_gave_seg : ButikkCopy.a1_mote_seg;
  List<String> get _filterNavn => isGift ? ButikkCopy.a1_gave_filtre : ButikkCopy.a1_mote_filtre;

  @override
  void initState() {
    super.initState();
    _sok.addListener(() => setState(() {}));
    _seg = _forsteSeg();
    _loadCart();
    _loadSide();
    if (kDebugMode && HjemHarness.butikkScroll != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(HjemHarness.butikkScroll! * context.bs);
      });
    }
    if (kDebugMode && HjemHarness.butikkOrb != null) _filter = HjemHarness.butikkOrb!;
    if (kDebugMode && HjemHarness.sokFokus) _sokApen = true;
    if (kDebugMode && HjemHarness.butikkLegg != null) {
      Future.delayed(const Duration(milliseconds: 1200), () async {
        if (HjemHarness.kurvTom) {
          for (final l in (await _kasse.cart()).lines) {
            await _kasse.remove(l.cartId);
          }
        }
        for (final id in HjemHarness.butikkLegg!) {
          final item = store.allItems.where((i) => i.id == id).firstOrNull;
          if (item == null || !mounted) continue;
          final ok = await BergenCart.add(context, storeId: item.storeId, productId: item.id);
          if (ok) await _loadCart(pulse: true);
        }
      });
    }
    if (kDebugMode && HjemHarness.butikkMini) {
      Future.delayed(const Duration(milliseconds: 3200), () {
        if (mounted && _lines.isNotEmpty) setState(() => _mini = true);
      });
    }
  }

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    for (final t in _lagt.values) {
      t.cancel();
    }
    _scroll.dispose();
    _sok.dispose();
    _sokFokus.dispose();
    super.dispose();
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

  Future<void> _loadCart({bool pulse = false}) async {
    final cart = await _kasse.cart();
    if (!mounted) return;
    setState(() {
      _lines = [
        for (final l in cart.lines)
          if (l.storeId == store.id) l,
      ];
      if (pulse) _pulse++;
      if (_lines.isEmpty) _mini = false;
    });
  }

  // ── what the shelves show ────────────────────────────────────────────────

  static bool _har(String hay, String ord) => hay.toLowerCase().contains(ord);

  /// Herre / Dame / Barn match the store's categories by name when it sorts
  /// that way; a gift store's segments are price bands.
  bool _iSeg(BergenMenuItem i, int seg) {
    if (isGift) {
      return switch (seg) {
        0 => i.price < 300,
        1 => i.price >= 300 && i.price <= 600,
        _ => i.price > 600,
      };
    }
    final ord = const ['herre', 'dame', 'barn'][seg];
    final kjonnet = store.menu.any((c) => ['herre', 'dame', 'barn'].any((k) => _har(c.name, k)));
    if (!kjonnet) return true;
    return _har(i.categoryName ?? '', ord);
  }

  int _forsteSeg() {
    for (var k = 0; k < 3; k++) {
      if (store.allItems.any((i) => _iSeg(i, k))) return k;
    }
    return 0;
  }

  bool _iFilter(BergenMenuItem i) {
    final ord = (isGift ? _kGaveOrd : _kMoteOrd)[_filter];
    if (ord.isEmpty) return true;
    return ord.any((o) => _har(i.name, o));
  }

  bool _iSok(BergenMenuItem i) {
    final q = _sok.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = '${i.name} ${i.description ?? ''} ${i.categoryName ?? ''}'.toLowerCase();
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }

  List<BergenMenuItem> get _hylle => [
    for (final i in store.allItems)
      if ((_merke.isEmpty || i.categoryName == _merke) && _iSeg(i, _seg) && (_sokApen ? _iSok(i) : _iFilter(i))) i,
  ];

  /// The week's three on the plinth: pictured ones first.
  List<BergenMenuItem> get _skive {
    final alle = store.allItems;
    final med = [
      for (final i in alle)
        if (i.imageUrl != null) i,
    ];
    final uten = [
      for (final i in alle)
        if (i.imageUrl == null) i,
    ];
    return [...med, ...uten].take(3).toList();
  }

  // ── actions ──────────────────────────────────────────────────────────────

  Future<void> _add(BergenMenuItem item) async {
    if (item.hasSizes || item.hasColours) {
      _open(item);
      return;
    }
    final ok = await BergenCart.add(
      context,
      storeId: item.storeId,
      productId: item.id,
      toast: ButikkCopy.a1_butikk_prod_i_kurven(item.name),
    );
    if (!ok || !mounted) return;
    _lagt[item.id]?.cancel();
    setState(() {
      _lagt[item.id] = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _lagt.remove(item.id));
      });
    });
    await _loadCart(pulse: true);
  }

  void _open(BergenMenuItem item) {
    showKledeSheet(context, item: item, api: widget.api, brand: item.categoryName).then((_) {
      if (mounted) _loadCart(pulse: true);
    });
  }

  Future<void> _save(BergenMenuItem item) async {
    HapticFeedback.selectionClick();
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
        decoration: InputDecoration(hintText: ButikkCopy.a1_butikk_melding_hint, border: const OutlineInputBorder()),
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
        .where((o) => (o['store'] is Map) && ((o['store']['id'] as num?)?.toInt() == store.id))
        .firstOrNull;
    if (!mounted) return;
    if (mine != null) {
      final id = int.tryParse('${mine['order_id']}') ?? 0;
      final res = await widget.customerApi.contact(id, kind: 'message', message: text);
      if (!mounted) return;
      showBergenToast(context, res != null ? ButikkCopy.a1_butikk_melding_sendt : BergenRoutes.kommerSnart);
      return;
    }
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      arguments: {'intent': 'store', 'store_id': '${store.id}', 'q': text},
      orElse: () => openScreen(context, SnurreChatScreen(draftFromHomeSearch: text)),
    );
  }

  void _askAegilGift() => BergenRoutes.pushOr(
    context,
    kAegilRoute,
    arguments: {'intent': 'gift', 'store_id': '${store.id}', if (_forWhom != null) 'for': _forWhom!},
    orElse: () => openScreen(context, const SnurreChatScreen()),
  );

  void _toggleSok() {
    HapticFeedback.selectionClick();
    setState(() => _sokApen = !_sokApen);
    if (_sokApen) {
      _sokFokus.requestFocus();
    } else {
      _sok.clear();
      _sokFokus.unfocus();
    }
  }

  Future<void> _minusLine(KurvLine l) async {
    HapticFeedback.selectionClick();
    final ok = l.quantity > 1 ? await _kasse.changeQuantity(l.cartId, l.quantity - 1) : await _kasse.remove(l.cartId);
    if (ok) await _loadCart();
  }

  Future<void> _plusLine(KurvLine l) async {
    HapticFeedback.selectionClick();
    final ok = await _kasse.changeQuantity(l.cartId, l.quantity + 1);
    if (ok) await _loadCart(pulse: true);
  }

  Future<void> _removeLine(KurvLine l) async {
    HapticFeedback.selectionClick();
    final ok = await _kasse.remove(l.cartId);
    if (!mounted) return;
    if (ok) showBergenToast(context, ButikkCopy.a1_butikk_ut_av_kurven(l.name));
    await _loadCart();
  }

  Future<void> _empty() async {
    for (final l in [..._lines]) {
      await _kasse.remove(l.cartId);
    }
    await _loadCart();
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final mq = MediaQuery.of(context);
    final bunn = math.max(16 * s, mq.padding.bottom - 8 * s);
    final hylle = _hylle;
    final skive = _skive;
    final harKurv = _lines.isNotEmpty;
    final antall = _lines.fold<int>(0, (a, l) => a + l.quantity);
    final sum = _lines.fold<double>(0, (a, l) => a + l.sum);

    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      resizeToAvoidBottomInset: false,
      body: BergenOnce(
        // `skjermInn .34s cubic-bezier(.2,.9,.3,1)`.
        durationMs: 340,
        builder: (context, p, child) {
          final e = const Cubic(.2, .9, .3, 1).transform(p);
          return Opacity(
            opacity: (p / .55).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 14 * s * (1 - e)),
              child: Transform.scale(scale: .978 + .022 * e, child: child),
            ),
          );
        },
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)],
              stops: [0, .42, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-.72, -1),
                        radius: .9,
                        colors: [rgba(255, 255, 255, .22), rgba(255, 255, 255, 0)],
                        stops: const [0, .6],
                      ),
                    ),
                  ),
                ),
              ),
              ListView(
                key: const Key('a1_mote_scroll'),
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: [
                  _Hero(store: store, viewers: (_presence?['viewers_now'] as num?)?.toInt() ?? 0),
                  if (isGift)
                    _TilHvem(valgt: _forWhom, onPick: (h) => setState(() => _forWhom = _forWhom == h ? null : h)),
                  _Glass(
                    padding: EdgeInsets.fromLTRB(16 * s, 18 * s, 16 * s, 0),
                    child: _Utstilling(
                      gift: isGift,
                      varer: skive,
                      saved: _saved,
                      onSave: _save,
                      onOpen: _open,
                      onAdd: _add,
                      onAegil: _askAegilGift,
                    ),
                  ),
                  if (store.menu.isNotEmpty)
                    _Glass(
                      padding: EdgeInsets.fromLTRB(16 * s, 18 * s, 16 * s, 0),
                      child: _Merker(
                        merker: [for (final c in store.menu) c.name],
                        valgt: _merke,
                        onPick: (m) => setState(() => _merke = m),
                      ),
                    ),
                  _Hyllene(
                    seg: _segNavn,
                    valgt: _seg,
                    onPick: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _seg = i);
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16 * s, 18 * s, 16 * s, 150 * s + bunn),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hylle.isEmpty)
                          Container(
                            key: const Key('a1_butikk_menu_empty'),
                            padding: EdgeInsets.all(14 * s),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20 * s),
                              color: rgba(255, 255, 255, .08),
                              border: Border.all(color: rgba(255, 255, 255, .14)),
                            ),
                            child: Text(
                              store.allItems.isEmpty ? ButikkCopy.a1_butikk_menu_empty : ButikkCopy.a1_mote_ingen_treff,
                              style: bText(
                                context,
                                12,
                                weight: FontWeight.w600,
                                height: 1.45,
                                color: rgba(255, 255, 255, .75),
                              ),
                            ),
                          )
                        else
                          _Grid(
                            key: ValueKey('$_merke|$_seg|$_filter'),
                            items: hylle,
                            pointsPct: _pointsPct,
                            lagt: _lagt.keys.toSet(),
                            onOpen: _open,
                            onAdd: _add,
                          ),
                        SizedBox(height: 14 * s),
                        _StorrelseHint(onTap: _askStore),
                      ],
                    ),
                  ),
                ],
              ),
              if (_mini && harKurv)
                Positioned(
                  left: 16 * s,
                  right: 16 * s,
                  bottom: bunn + 138 * s,
                  child: ButikkMiniKurv(
                    mork: true,
                    lines: _lines,
                    onEmpty: _empty,
                    onMinus: _minusLine,
                    onPlus: _plusLine,
                    onRemove: _removeLine,
                  ),
                ),
              if (harKurv)
                Positioned(
                  left: 16 * s,
                  right: 16 * s,
                  bottom: bunn + 72 * s,
                  child: ButikkKurvBar(
                    oransje: true,
                    lines: _lines,
                    count: antall,
                    total: sum,
                    pulse: _pulse,
                    mini: _mini,
                    onToggle: () => setState(() => _mini = !_mini),
                    onPay: () => BergenRoutes.push(context, '/bergen/kurv'),
                  ),
                ),
              Positioned(
                left: 14 * s,
                right: 86 * s,
                bottom: bunn,
                height: 62 * s,
                child: _FilterBar(
                  navn: _filterNavn,
                  valgt: _filter,
                  sokApen: _sokApen,
                  sok: _sok,
                  sokFokus: _sokFokus,
                  onPick: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = i);
                  },
                ),
              ),
              Positioned(
                right: 14 * s,
                bottom: bunn,
                width: 62 * s,
                height: 62 * s,
                child: _SokKnapp(apen: _sokApen, onTap: _toggleSok),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `linear-gradient(180deg,rgba(255,255,255,.14),rgba(255,255,255,.06))` —
/// the glass the page's sections sit on.
class _Glass extends StatelessWidget {
  const _Glass({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: const BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _kGlass),
    ),
    child: child,
  );
}

String _hm(String t) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t.trim());
  if (m == null) return t;
  final h = m.group(1)!.padLeft(2, '0');
  return m.group(2) == '00' ? h : '$h:${m.group(2)}';
}

/// The banner (168px) with the back key, "Åpen til …" and the tilted logo,
/// then the name sheet lapping 20px over it.
class _Hero extends StatelessWidget {
  const _Hero({required this.store, required this.viewers});

  final BergenStoreInfo store;
  final int viewers;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final dy = math.max(0.0, MediaQuery.paddingOf(context).top - 20 * s);
    final fee = store.deliveryChargeKr;
    final aapen = store.open
        ? (store.closeTime == null ? null : ButikkCopy.a1_mote_apen_til(_hm(store.closeTime!)))
        : (store.openTime == null ? ButikkCopy.a1_mote_stengt : ButikkCopy.a1_mote_apner(_hm(store.openTime!)));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 168 * s + dy,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF22586A), Color(0xFF1B4854)],
                  ),
                ),
              ),
              if (store.bannerUrl case final b?)
                Image.network(
                  b,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -.12),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [rgba(4, 18, 26, .25), rgba(4, 18, 26, 0), rgba(23, 62, 72, .6)],
                    stops: const [0, .45, 1],
                  ),
                ),
              ),
              Positioned(
                top: 14 * s + dy,
                left: 16 * s,
                right: 16 * s,
                child: Row(
                  children: [
                    OnbPressable(
                      key: const Key('a1_butikk_tilbake'),
                      onTap: () => Navigator.of(context).maybePop(),
                      pressDy: 0,
                      pressScale: .92,
                      child: Container(
                        width: 34 * s,
                        height: 34 * s,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12 * s),
                          color: rgba(255, 255, 255, .7),
                          border: Border.all(color: rgba(255, 255, 255, .9)),
                          boxShadow: [
                            BoxShadow(
                              color: rgba(15, 31, 43, .4),
                              offset: Offset(0, 8 * s),
                              blurRadius: onbBlur(16 * s),
                              spreadRadius: -8 * s,
                            ),
                          ],
                        ),
                        child: SokIkon('M15 6l-6 6 6 6', size: 14 * s, color: const Color(0xFF1B2A44), stroke: 2.6),
                      ),
                    ),
                    const Spacer(),
                    if (aapen != null)
                      Container(
                        key: const Key('a1_butikk_apen'),
                        padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 5 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: _kGlass,
                          ),
                          border: Border.all(color: rgba(255, 255, 255, .9)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // `lyktPuls 3s`: the lamp glows 8 → 15px.
                            BergenLoop(
                              durationMs: 3000,
                              builder: (context, p, child) {
                                final g = p == null ? 0.0 : kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                                return Container(
                                  width: 6 * s,
                                  height: 6 * s,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFF2C14E),
                                    boxShadow: [
                                      BoxShadow(
                                        color: rgba(242, 193, 78, .9 + .1 * g),
                                        blurRadius: onbBlur((8 + 7 * g) * s),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 6 * s),
                            Text(aapen, style: bText(context, 10.5, weight: FontWeight.w800)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 16 * s,
                bottom: 12 * s,
                child: Transform.rotate(
                  angle: -5 * math.pi / 180,
                  child: Container(
                    width: 52 * s,
                    height: 52 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2C6675),
                      border: Border.all(color: Colors.white, width: 2.5 * s),
                      boxShadow: [
                        BoxShadow(
                          color: rgba(4, 18, 26, .85),
                          offset: Offset(0, 10 * s),
                          blurRadius: onbBlur(18 * s),
                          spreadRadius: -8 * s,
                        ),
                        BoxShadow(
                          color: rgba(35, 32, 29, .22),
                          offset: Offset(0, 2 * s),
                          blurRadius: onbBlur(3 * s),
                          spreadRadius: -1 * s,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: store.logoUrl != null
                        ? Image.network(
                            store.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _Ini(store.name),
                          )
                        : _Ini(store.name),
                  ),
                ),
              ),
            ],
          ),
        ),
        // `margin-top:-20px`: the name sheet laps over the banner.
        Padding(
          padding: EdgeInsets.only(top: 148 * s + dy),
          child: Container(
            padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s)),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _kGlass),
              boxShadow: [
                BoxShadow(
                  color: rgba(35, 32, 29, .3),
                  offset: Offset(0, -6 * s),
                  blurRadius: onbBlur(14 * s),
                  spreadRadius: -8 * s,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        key: const Key('a1_butikk_navn'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bDisplay(context, 22, letterSpacingEm: -.025, height: 1.05),
                      ),
                      SizedBox(height: 5 * s),
                      Row(
                        children: [
                          if (store.deliveryMinutes != null) ...[
                            Text(
                              '${store.deliveryMinutes} min',
                              style: bText(context, 11.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .7)),
                            ),
                            SizedBox(width: 6 * s),
                            Container(
                              width: 3 * s,
                              height: 3 * s,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(4, 18, 26, .45)),
                            ),
                            SizedBox(width: 6 * s),
                          ],
                          if (fee != null)
                            Flexible(
                              child: Text(
                                fee <= 0 ? ButikkCopy.a1_mote_gratis_lev : ButikkCopy.a1_mote_lev(ButikkCopy.kr(fee)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bText(context, 11.5, weight: FontWeight.w700, color: const Color(0xFF7FF0CB)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (viewers > 0) ...[SizedBox(width: 10 * s), _Kikker(viewers: viewers)],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Ini extends StatelessWidget {
  const _Ini(this.navn);

  final String navn;

  @override
  Widget build(BuildContext context) {
    final ord = navn.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final ini = ord.isEmpty ? '?' : ord.take(2).map((w) => w[0].toUpperCase()).join();
    return Center(child: Text(ini, style: bDisplay(context, 15)));
  }
}

/// "12 kikker nå": a white-ringed glass pill with the green live dot.
class _Kikker extends StatelessWidget {
  const _Kikker({required this.viewers});

  final int viewers;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: const Key('a1_butikk_kikker'),
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _kGlass),
        boxShadow: [
          BoxShadow(
            color: rgba(35, 32, 29, .4),
            offset: Offset(0, 4 * s),
            blurRadius: onbBlur(8 * s),
            spreadRadius: -6 * s,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5 * s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 6 * s,
            height: 6 * s,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3F8F5F)),
                  child: SizedBox.expand(),
                ),
                // `livePuls 1.8s`.
                Positioned(
                  left: -3 * s,
                  top: -3 * s,
                  right: -3 * s,
                  bottom: -3 * s,
                  child: BergenLoop(
                    durationMs: 1800,
                    builder: (context, p, child) {
                      if (p == null) return const SizedBox.shrink();
                      final e = Curves.easeOut.transform(p);
                      return Opacity(
                        opacity: .9 * (1 - e),
                        child: Transform.scale(scale: .6 + 1.3 * e, child: child),
                      );
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: rgba(63, 143, 95, .7), width: 1.5 * s),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 5 * s),
          Text(ButikkCopy.a1_butikk_kikker(viewers), style: bText(context, 10.5, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Gift store: "Til hvem" — Mamma, Pappa, … as segment pills.
class _TilHvem extends StatelessWidget {
  const _TilHvem({required this.valgt, required this.onPick});

  final String? valgt;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return _Glass(
      padding: EdgeInsets.only(top: 18 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * s),
            child: Text(ButikkCopy.a1_butikk_til_hvem, style: bDisplay(context, 15, letterSpacingEm: -.015)),
          ),
          SizedBox(height: 8 * s),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(16 * s, 2 * s, 16 * s, 4 * s),
            child: Row(
              children: [
                for (final h in ButikkCopy.a1_butikk_til_hvem_liste) ...[
                  _SegPille(
                    label: h,
                    on: valgt == h,
                    onTap: () => onPick(h),
                    padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 8 * s),
                  ),
                  SizedBox(width: 6 * s),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ukens utstilling": the dark card with the Dreieskiven, and in a gift
/// store "La Ægil finne en gave".
class _Utstilling extends StatelessWidget {
  const _Utstilling({
    required this.gift,
    required this.varer,
    required this.saved,
    required this.onSave,
    required this.onOpen,
    required this.onAdd,
    required this.onAegil,
  });

  final bool gift;
  final List<BergenMenuItem> varer;
  final Set<int> saved;
  final ValueChanged<BergenMenuItem> onSave;
  final ValueChanged<BergenMenuItem> onOpen;
  final ValueChanged<BergenMenuItem> onAdd;
  final VoidCallback onAegil;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    if (varer.isEmpty && !gift) return const SizedBox.shrink();
    final trengerStr = varer.any((v) => v.hasSizes);
    return Container(
      key: const Key('a1_butikk_utstilling'),
      padding: EdgeInsets.fromLTRB(14 * s, 16 * s, 14 * s, 16 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E4F5C), Color(0xFF173E48), Color(0xFF122F3A)],
          stops: [0, .55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: rgba(18, 47, 58, .7),
            offset: Offset(0, 18 * s),
            blurRadius: onbBlur(30 * s),
            spreadRadius: -16 * s,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          bergenInsetTop(radius: 26 * s, alpha: .3, pad: EdgeInsets.fromLTRB(14 * s, 16 * s, 14 * s, 16 * s)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (varer.isNotEmpty)
                MoteSkive(
                  butikk: true,
                  tittel: gift ? ButikkCopy.a1_butikk_gave_utstilling : ButikkCopy.a1_butikk_mote_utstilling,
                  knapp: trengerStr ? ButikkCopy.a1_butikk_klede_velg_str : ButikkCopy.a1_butikk_legg_til,
                  varer: [
                    for (final v in varer)
                      MoteSkiveVare(
                        navn: v.name,
                        pris: ButikkCopy.kr(v.price),
                        bilde: v.imageUrl == null ? null : NetworkImage(v.imageUrl!),
                        y: .2,
                        sitat: v.description == null ? null : '«${v.description!.trim()}»',
                        hvem: v.description == null ? null : v.storeName,
                      ),
                  ],
                  lagret: (i) => saved.contains(varer[i].id),
                  onLagre: (i) => onSave(varer[i]),
                  onApne: (i) => onOpen(varer[i]),
                  onKnapp: (i) => onAdd(varer[i]),
                ),
              if (gift) ...[
                SizedBox(height: 12 * s),
                OnbPressable(
                  key: const Key('a1_butikk_gave_aegil'),
                  onTap: onAegil,
                  pressDy: 0,
                  pressScale: .98,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16 * s),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _kGlass,
                      ),
                      border: Border.all(color: rgba(255, 255, 255, .18)),
                      boxShadow: [
                        BoxShadow(
                          color: rgba(35, 32, 29, .4),
                          offset: Offset(0, 8 * s),
                          blurRadius: onbBlur(14 * s),
                          spreadRadius: -10 * s,
                        ),
                        BoxShadow(color: rgba(4, 18, 26, .45), offset: Offset(0, 2 * s)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/dashboard/invitation.png',
                          width: 30 * s,
                          height: 30 * s,
                          errorBuilder: (_, __, ___) => SizedBox(width: 30 * s),
                        ),
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: Text(
                            ButikkCopy.a1_mote_gave_aegil,
                            style: bText(context, 12.5, weight: FontWeight.w800),
                          ),
                        ),
                        Text('›', style: bText(context, 14, color: rgba(255, 255, 255, .55))),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// "Merker": Alle, then a disc per brand.
class _Merker extends StatelessWidget {
  const _Merker({required this.merker, required this.valgt, required this.onPick});

  final List<String> merker;
  final String valgt;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ButikkCopy.a1_butikk_merker, style: bDisplay(context, 15, letterSpacingEm: -.015)),
        SizedBox(height: 8 * s),
        SingleChildScrollView(
          key: const Key('a1_butikk_merker'),
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: EdgeInsets.only(top: 2 * s, bottom: 4 * s),
          child: Row(
            children: [
              _Merke(
                key: const Key('a1_butikk_merke_alle'),
                label: ButikkCopy.a1_butikk_alle,
                bg: valgt.isEmpty ? const Color(0xFF1B2A44) : rgba(35, 32, 29, .08),
                ikonFarge: valgt.isEmpty ? const Color(0xFFF5F3EF) : const Color(0xFF57534B),
                onTap: () => onPick(''),
              ),
              for (var i = 0; i < merker.length; i++) ...[
                SizedBox(width: 6 * s),
                _Merke(
                  key: Key('a1_butikk_merke_$i'),
                  label: merker[i],
                  bg: _kMerkeBg[(i + 1) % _kMerkeBg.length],
                  ini: merker[i],
                  valgt: valgt == merker[i],
                  onTap: () => onPick(valgt == merker[i] ? '' : merker[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Merke extends StatelessWidget {
  const _Merke({
    super.key,
    required this.label,
    required this.bg,
    this.ikonFarge,
    this.ini,
    this.valgt = false,
    required this.onTap,
  });

  final String label;
  final Color bg;
  final Color? ikonFarge;
  final String? ini;
  final bool valgt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lys = bg.computeLuminance() > .6;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 52 * s,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 40 * s,
              height: 40 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(color: valgt ? const Color(0xFFF26D3D) : Colors.white, width: 2 * s),
                boxShadow: [
                  BoxShadow(
                    color: rgba(4, 18, 26, .85),
                    offset: Offset(0, 14 * s),
                    blurRadius: onbBlur(16 * s),
                    spreadRadius: -10 * s,
                  ),
                  BoxShadow(
                    color: rgba(35, 32, 29, .4),
                    offset: Offset(0, 7 * s),
                    blurRadius: onbBlur(8 * s),
                    spreadRadius: -4 * s,
                  ),
                  BoxShadow(color: rgba(120, 100, 70, .3), offset: Offset(0, 4 * s)),
                  BoxShadow(color: rgba(4, 18, 26, .45), offset: Offset(0, 3 * s)),
                ],
              ),
              child: ini != null
                  ? Text(
                      _forkort(ini!),
                      style: bDisplay(
                        context,
                        13,
                        letterSpacingEm: -.04,
                        color: lys ? Colors.white : const Color(0xFFF5F3EF),
                      ),
                    )
                  : SokIkon(_kAlleIkon, size: 18 * s, color: ikonFarge ?? Colors.white, stroke: 2.2),
            ),
            SizedBox(height: 5 * s),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bText(context, 9, weight: FontWeight.w700, color: rgba(255, 255, 255, .7)),
            ),
          ],
        ),
      ),
    );
  }

  static String _forkort(String navn) {
    final ord = navn.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (ord.isEmpty) return '?';
    if (ord.length == 1) return ord.first.substring(0, math.min(2, ord.first.length)).toUpperCase();
    return '${ord[0][0]}${ord[1][0]}'.toUpperCase();
  }
}

/// "Hyllene" with the cream segment track (Herre / Dame / Barn).
class _Hyllene extends StatelessWidget {
  const _Hyllene({required this.seg, required this.valgt, required this.onPick});

  final List<String> seg;
  final int valgt;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCssShadow(
      key: const Key('a1_butikk_hyller_head'),
      radius: 28 * s,
      shadows: [
        BoxShadow(
          color: rgba(4, 26, 34, .35),
          offset: Offset(0, 10 * s),
          blurRadius: onbBlur(16 * s),
          spreadRadius: -8 * s,
        ),
      ],
      child: Container(
        padding: EdgeInsets.fromLTRB(16 * s, 20 * s, 16 * s, 26 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28 * s)),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _kGlass),
        ),
        child: Row(
          children: [
            Expanded(child: Text(ButikkCopy.a1_butikk_hyllene, style: bDisplay(context, 15, letterSpacingEm: -.015))),
            Container(
              padding: EdgeInsets.all(4 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE4DED2), Color(0xFFEFEAE0)],
                ),
                boxShadow: [BoxShadow(color: rgba(255, 255, 255, .9), offset: Offset(0, 1 * s))],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(0, 10, 16, .35), rgba(0, 10, 16, 0), rgba(255, 255, 255, 0), rgba(255, 255, 255, .5)],
                  stops: const [0, .14, .94, 1],
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < seg.length; i++) ...[
                    if (i > 0) SizedBox(width: 3 * s),
                    _SegPille(
                      key: Key('a1_butikk_seg_$i'),
                      label: seg[i],
                      on: valgt == i,
                      onTap: () => onPick(i),
                      padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 7 * s),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `seg(on)`: the raised white pill, or plain grey text.
class _SegPille extends StatelessWidget {
  const _SegPille({super.key, required this.label, required this.on, required this.onTap, required this.padding});

  final String label;
  final bool on;
  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(.3, 1, .4, 1),
        padding: padding,
        transform: Matrix4.translationValues(0, on ? -1 * s : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: on ? const [Colors.white, Color(0xFFF6F2E9)] : [rgba(255, 255, 255, 0), rgba(255, 255, 255, 0)],
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: rgba(35, 32, 29, .35),
                    offset: Offset(0, 6 * s),
                    blurRadius: onbBlur(8 * s),
                    spreadRadius: -4 * s,
                  ),
                  BoxShadow(color: rgba(120, 100, 70, .32), offset: Offset(0, 3 * s)),
                  BoxShadow(color: rgba(190, 178, 155, .9), offset: Offset(0, 2 * s)),
                  BoxShadow(color: rgba(255, 255, 255, .95), spreadRadius: 1),
                ]
              : const [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 350),
          style: bText(
            context,
            11.5,
            weight: FontWeight.w800,
            color: on ? const Color(0xFF23201D) : const Color(0xFF6E6862),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// The garments, two a row (`gap:14px 12px`), rising in (`kortStag`).
class _Grid extends StatelessWidget {
  const _Grid({
    super.key,
    required this.items,
    required this.pointsPct,
    required this.lagt,
    required this.onOpen,
    required this.onAdd,
  });

  final List<BergenMenuItem> items;
  final double? pointsPct;
  final Set<int> lagt;
  final ValueChanged<BergenMenuItem> onOpen;
  final ValueChanged<BergenMenuItem> onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      key: const Key('a1_butikk_hyller'),
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) SizedBox(height: 14 * s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _kort(items[i], i)),
              SizedBox(width: 12 * s),
              Expanded(child: i + 1 < items.length ? _kort(items[i + 1], i + 1) : const SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _kort(BergenMenuItem item, int i) => _Plagg(
    key: Key('a1_butikk_hylle_${item.id}'),
    item: item,
    index: i,
    poeng: pointsPct == null ? null : (item.price * pointsPct! / 100).round(),
    lagt: lagt.contains(item.id),
    onOpen: () => onOpen(item),
    onAdd: () => onAdd(item),
  );
}

/// One garment (L3567): picture on its teal glow fading to cream, −N %,
/// name, price with the old one struck, and the key that turns green
/// ("I kurven", `klask`) with the points rising off it (`myntOpp`).
class _Plagg extends StatelessWidget {
  const _Plagg({
    super.key,
    required this.item,
    required this.index,
    required this.poeng,
    required this.lagt,
    required this.onOpen,
    required this.onAdd,
  });

  final BergenMenuItem item;
  final int index;
  final int? poeng;
  final bool lagt;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final was = item.wasPrice;
    final pct = was != null && was > item.price ? ((1 - item.price / was) * 100).round() : 0;
    return BergenOnce(
      // `kortStag .55s .16s cubic-bezier(.2,.9,.3,1) both`, one after another.
      durationMs: 550,
      delayMs: 160.0 + math.min(index, 6) * 60,
      builder: (context, p, child) {
        final e = const Cubic(.2, .9, .3, 1).transform(p);
        return Opacity(
          opacity: e.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * s * (1 - e)),
            child: Transform.scale(scale: .97 + .03 * e, child: child),
          ),
        );
      },
      child: OnbPressable(
        onTap: onOpen,
        pressDy: 0,
        pressScale: .98,
        child: BergenCssShadow(
          radius: 20 * s,
          shadows: [
            BoxShadow(
              color: rgba(35, 32, 29, .5),
              offset: Offset(0, 22 * s),
              blurRadius: onbBlur(28 * s),
              spreadRadius: -18 * s,
            ),
            BoxShadow(
              color: rgba(0, 10, 16, .6),
              offset: Offset(0, 10 * s),
              blurRadius: onbBlur(14 * s),
              spreadRadius: -8 * s,
            ),
            BoxShadow(color: rgba(4, 18, 26, .3), offset: Offset(0, 3 * s)),
            BoxShadow(color: rgba(4, 18, 26, .45), offset: Offset(0, 2 * s)),
          ],
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * s),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _kGlass),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: rgba(255, 255, 255, .18)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bilde(item: item, pct: pct),
                Padding(
                  padding: EdgeInsets.fromLTRB(11 * s, 8 * s, 11 * s, 11 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bDisplay(context, 14, letterSpacingEm: -.01, height: 1.2),
                      ),
                      SizedBox(height: 5 * s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(ButikkCopy.kr(item.price), style: bDisplay(context, 17, letterSpacingEm: -.02)),
                          if (was != null && was > item.price) ...[
                            SizedBox(width: 6 * s),
                            Flexible(
                              child: Text(
                                ButikkCopy.kr(was).replaceAll(RegExp(r'\s*kr$'), ''),
                                maxLines: 1,
                                style: bText(context, 11, weight: FontWeight.w600, color: rgba(255, 255, 255, .55))
                                    .copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: rgba(255, 255, 255, .55),
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 9 * s),
                      _LeggKnapp(key: Key('a1_butikk_hylle_add_${item.id}'), lagt: lagt, poeng: poeng, onTap: onAdd),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bilde extends StatelessWidget {
  const _Bilde({required this.item, required this.pct});

  final BergenMenuItem item;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      height: 172 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * s), bottom: Radius.circular(18 * s)),
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF3C7788), Color(0xFF265A6A), Color(0xFF173E48)],
          stops: [0, .55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: rgba(0, 10, 16, .6),
            offset: Offset(0, 4 * s),
            blurRadius: onbBlur(10 * s),
            spreadRadius: -6 * s,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.2),
                radius: .6,
                colors: [rgba(127, 240, 203, .24), rgba(127, 240, 203, 0)],
                stops: const [0, .65],
              ),
            ),
          ),
          if (item.imageUrl case final u?)
            Image.network(
              u,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.56),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 44 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(248, 245, 238, 0), rgba(248, 245, 238, .95)],
                ),
              ),
            ),
          ),
          if (pct > 0)
            Positioned(
              top: 8 * s,
              left: 8 * s,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF58A55), Color(0xFFE95C2C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(120, 50, 10, .6),
                      offset: Offset(0, 4 * s),
                      blurRadius: onbBlur(8 * s),
                      spreadRadius: -4 * s,
                    ),
                    BoxShadow(color: Colors.white, spreadRadius: 1.5 * s),
                  ],
                ),
                child: Text('−$pct %', style: bText(context, 10, weight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Legg til" (orange) → "I kurven" (green) for 1.8s with "+N" rising.
class _LeggKnapp extends StatelessWidget {
  const _LeggKnapp({super.key, required this.lagt, required this.poeng, required this.onTap});

  final bool lagt;
  final int? poeng;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 2,
      pressScale: .98,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        curve: const Cubic(.3, 1.5, .5, 1),
        scale: lagt ? 1.02 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 38 * s,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: lagt
                  ? const [Color(0xFF6DBE8C), Color(0xFF3F8F5F), Color(0xFF357A50)]
                  : const [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
              stops: const [0, .58, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: lagt ? rgba(63, 143, 95, .7) : rgba(200, 70, 25, .75),
                offset: Offset(0, 9 * s),
                blurRadius: onbBlur(14 * s),
                spreadRadius: -8 * s,
              ),
              BoxShadow(color: lagt ? rgba(30, 80, 50, .35) : rgba(120, 45, 15, .4), offset: Offset(0, 3 * s)),
              BoxShadow(color: lagt ? const Color(0xFF2E6B47) : const Color(0xFFC4491A), offset: Offset(0, 1.5 * s)),
              BoxShadow(color: rgba(255, 255, 255, .6), spreadRadius: 1),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (lagt)
                    BergenOnce(
                      key: const ValueKey('klask'),
                      durationMs: 400,
                      builder: (context, p, child) {
                        final sc = kf(p, const [0, .6, 1], const [1.15, .98, 1], const Cubic(.3, 1.4, .5, 1));
                        final rot = kf(p, const [0, .6, 1], const [-5, -7, -5]);
                        return Opacity(
                          opacity: (p / .6).clamp(0.0, 1.0),
                          child: Transform.rotate(
                            angle: rot * math.pi / 180,
                            child: Transform.scale(scale: sc, child: child),
                          ),
                        );
                      },
                      child: SokIkon('M4.5 12.5l5 5 10-11', size: 14 * s, color: Colors.white, stroke: 3),
                    )
                  else
                    SokIkon(_kPluss, size: 14 * s, color: Colors.white, stroke: 2.8),
                  SizedBox(width: 6 * s),
                  Text(
                    lagt ? ButikkCopy.a1_butikk_i_kurven : ButikkCopy.a1_butikk_legg_til,
                    style: bText(context, 12.5, weight: FontWeight.w800),
                  ),
                ],
              ),
              if (lagt && poeng != null && poeng! > 0)
                Positioned(
                  right: 10 * s,
                  top: -9 * s,
                  child: BergenOnce(
                    // `myntOpp 1.1s`: pops up, hangs, drifts off.
                    durationMs: 1100,
                    builder: (context, p, child) {
                      final y = kf(p, const [0, .25, .75, 1], const [6, -14, -20, -30]);
                      final sc = kf(p, const [0, .25, .75, 1], const [.6, 1.05, 1, .9]);
                      final o = kf(p, const [0, .25, .75, 1], const [0, 1, 1, 0]);
                      return Opacity(
                        opacity: o.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (y + 9) * s),
                          child: Transform.scale(scale: sc, child: child),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFF26D3D),
                        boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 1.5 * s)],
                      ),
                      child: Text('+$poeng', style: bText(context, 9, weight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Usikker på størrelsen? Spør butikken" — the cream card with Ægil.
class _StorrelseHint extends StatelessWidget {
  const _StorrelseHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      key: const Key('a1_butikk_spor_butikken'),
      onTap: onTap,
      pressDy: 0,
      pressScale: .98,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          color: rgba(253, 252, 249, .96),
          border: Border.all(color: rgba(255, 255, 255, .95)),
          boxShadow: [
            BoxShadow(
              color: rgba(90, 60, 30, .5),
              offset: Offset(0, 18 * s),
              blurRadius: onbBlur(30 * s),
              spreadRadius: -18 * s,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44 * s,
              height: 44 * s,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14 * s), color: const Color(0xFFEAF2F4)),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/dashboard/front.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            SizedBox(width: 11 * s),
            Expanded(
              child: Text(
                ButikkCopy.a1_butikk_storrelse_hint_generic,
                style: bText(context, 12, weight: FontWeight.w700, height: 1.4, color: const Color(0xFF23201D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bottom bar: the type chips, or — with the search key on — the
/// search field (`.26s` fade, `.3s` spring scale from the left).
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.navn,
    required this.valgt,
    required this.sokApen,
    required this.sok,
    required this.sokFokus,
    required this.onPick,
  });

  final List<String> navn;
  final int valgt;
  final bool sokApen;
  final TextEditingController sok;
  final FocusNode sokFokus;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    const spring = Cubic(.3, 1.2, .5, 1);
    const fade = Duration(milliseconds: 260);
    const skala = Duration(milliseconds: 300);
    return Container(
      key: const Key('a1_butikk_filterbar'),
      padding: EdgeInsets.symmetric(horizontal: 10 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: cssLinear(160, const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], const [0, .62, 1]),
        border: Border.all(color: rgba(255, 255, 255, .18)),
        boxShadow: [
          BoxShadow(
            color: rgba(15, 45, 55, .6),
            offset: Offset(0, 16 * s),
            blurRadius: onbBlur(30 * s),
            spreadRadius: -14 * s,
          ),
          BoxShadow(
            color: rgba(15, 45, 55, .3),
            offset: Offset(0, 2 * s),
            blurRadius: onbBlur(3 * s),
            spreadRadius: -1 * s,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bergenInsetTop(radius: 999, alpha: .16, pad: EdgeInsets.symmetric(horizontal: 10 * s)),
          Center(
            child: SizedBox(
              height: 38 * s,
              child: Stack(
                children: [
                  // The chips.
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: sokApen,
                      child: AnimatedOpacity(
                        duration: fade,
                        opacity: sokApen ? 0 : 1,
                        child: AnimatedScale(
                          duration: skala,
                          curve: spring,
                          alignment: Alignment.centerLeft,
                          scale: sokApen ? .96 : 1,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (r) => const LinearGradient(
                              colors: [Colors.black, Colors.black, Colors.transparent],
                              stops: [0, .86, 1],
                            ).createShader(r),
                            child: ListView.separated(
                              key: const Key('a1_butikk_filtre'),
                              scrollDirection: Axis.horizontal,
                              itemCount: navn.length,
                              separatorBuilder: (_, __) => SizedBox(width: 4 * s),
                              itemBuilder: (context, i) => Center(
                                child: _Chip(
                                  key: Key('a1_butikk_filter_$i'),
                                  label: navn[i],
                                  ikon: _kFilterIkon[i % _kFilterIkon.length],
                                  on: valgt == i,
                                  onTap: () => onPick(i),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The search field.
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !sokApen,
                      child: AnimatedOpacity(
                        duration: fade,
                        opacity: sokApen ? 1 : 0,
                        child: AnimatedScale(
                          duration: skala,
                          curve: spring,
                          alignment: Alignment.centerLeft,
                          scale: sokApen ? 1 : .96,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(14 * s, 0, 6 * s, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: _kGlass,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: rgba(0, 20, 26, .2),
                                  offset: Offset(0, 2 * s),
                                  blurRadius: onbBlur(3 * s),
                                  spreadRadius: -1 * s,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                bergenInsetTop(
                                  radius: 999,
                                  height: 1,
                                  alpha: 1,
                                  pad: EdgeInsets.fromLTRB(14 * s, 0, 6 * s, 0),
                                ),
                                Row(
                                  children: [
                                    SokIkon(
                                      'M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14zM20.5 20.5l-4.3-4.3',
                                      size: 16 * s,
                                      color: Colors.white,
                                      stroke: 2.4,
                                    ),
                                    SizedBox(width: 9 * s),
                                    Expanded(
                                      child: TextField(
                                        key: const Key('a1_butikk_mote_sok'),
                                        controller: sok,
                                        focusNode: sokFokus,
                                        cursorColor: const Color(0xFFF26D3D),
                                        style: bText(context, 13, weight: FontWeight.w700),
                                        textInputAction: TextInputAction.search,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          hintText: ButikkCopy.a1_mote_sok_hint,
                                          hintStyle: bText(
                                            context,
                                            13,
                                            weight: FontWeight.w700,
                                            color: rgba(255, 255, 255, .5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (sok.text.isNotEmpty)
                                      GestureDetector(
                                        onTap: sok.clear,
                                        child: Container(
                                          width: 24 * s,
                                          height: 24 * s,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: rgba(30, 79, 92, .12),
                                          ),
                                          child: SokIkon(
                                            'M6 6l12 12M18 6L6 18',
                                            size: 9 * s,
                                            color: rgba(255, 255, 255, .7),
                                            stroke: 3,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `chip(on)`: orange and raised, or glass.
class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.ikon, required this.on, required this.onTap});

  final String label;
  final String ikon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(.3, 1.3, .5, 1),
        padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 8 * s),
        transform: Matrix4.translationValues(0, on ? -1 * s : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: on
              ? cssLinear(160, const [Color(0xFFF2884E), Color(0xFFE0662C)])
              : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _kGlass),
          border: Border.all(color: on ? rgba(255, 255, 255, .5) : rgba(255, 255, 255, .24)),
          // Two shadows in both states, so the spring (which overshoots)
          // only ever moves between them and never scales one to nothing.
          boxShadow: [
            BoxShadow(
              color: on ? rgba(120, 50, 10, .9) : rgba(0, 0, 0, .6),
              offset: Offset(0, (on ? 10 : 6) * s),
              blurRadius: onbBlur((on ? 16 : 12) * s),
              spreadRadius: (on ? -8 : -9) * s,
            ),
            BoxShadow(color: on ? rgba(150, 60, 15, .85) : rgba(150, 60, 15, 0), offset: Offset(0, 3 * s)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SokIkon(ikon, size: 13 * s, color: Colors.white, stroke: 2.1),
            SizedBox(width: 6 * s),
            Text(label, style: bDisplay(context, 12.5, letterSpacingEm: -.01)),
          ],
        ),
      ),
    );
  }
}

/// The round search key: frosted white, orange and turned 90° when open.
class _SokKnapp extends StatelessWidget {
  const _SokKnapp({required this.apen, required this.onTap});

  final bool apen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      key: const Key('a1_butikk_mote_sok_knapp'),
      onTap: onTap,
      pressDy: 0,
      pressScale: .93,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 280),
        curve: const Cubic(.3, 1.2, .5, 1),
        turns: apen ? .25 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: rgba(4, 18, 26, .85),
                offset: Offset(0, 16 * s),
                blurRadius: onbBlur(30 * s),
                spreadRadius: -14 * s,
              ),
            ],
          ),
          child: ClipOval(
            // The screen's one blur layer: `backdrop-filter: blur(40px)`.
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20 * s, sigmaY: 20 * s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: apen
                      ? cssLinear(160, const [Color(0xFFF58A55), Color(0xFFE95C2C)])
                      : LinearGradient(colors: [rgba(255, 255, 255, .62), rgba(255, 255, 255, .62)]),
                  border: Border.all(color: rgba(255, 255, 255, .9)),
                ),
                child: apen
                    ? Transform.rotate(
                        angle: -math.pi / 2,
                        child: SokIkon('M6 6l12 12M18 6L6 18', size: 20 * s, color: Colors.white, stroke: 2.6),
                      )
                    : SokIkon(
                        'M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14zM20.5 20.5l-4.3-4.3',
                        size: 24 * s,
                        color: Colors.white,
                        stroke: 2.3,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
