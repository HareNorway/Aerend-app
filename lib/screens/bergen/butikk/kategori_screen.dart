import 'dart:async';

import 'dart:math' as math;

import '../aegil/aegil_guide.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../data/points/points_rules.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_home.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../deliveryService/home/ds_home_store_list_pojo.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../hjem/hjem_harness.dart';
import '../hjem/hjem_hjul.dart' show hjemHjulIkon;
import '../hjem/hjem_snart.dart' show kHjemKatNavn;
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import '../sok/sok_oversikt.dart' show SokIkon;
import 'kategori_kort.dart';
import 'kategori_utstilling.dart';

/// Copy for the Kategori screen (L5910–6135), NO and EN.
abstract final class KatCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String apne(String n) => _t('$n åpne nå · Bergen', '$n open now · Bergen');
  static String get butikker => _t('Butikker', 'Stores');
  static String get produkter => _t('Produkter', 'Products');
  static String get bilde => _t('Bestill fra bilde', 'Order from a photo');
  static String get fApen => _t('Åpen nå', 'Open now');
  static String get fGratis => _t('Gratis levering', 'Free delivery');
  static String get fRask => _t('Under 30 min', 'Under 30 min');
  static String get fTopp => _t('Topprangert', 'Top rated');
  static String sokI(String kat) => _t('Søk i $kat', 'Search $kat');
  static String minutter(int m) => _t('$m min', '$m min');
  static String get populaer => _t('POPULÆR NÅ', 'POPULAR NOW');
  static String get mestKjopt => _t('Mest kjøpt', 'Most bought');
  static String get tilbud => _t('Tilbud', 'Offer');
  static String get tomt => _t('Ingen butikker her ennå.', 'No stores here yet.');
  static String get tomtSok => _t('Ingen treff.', 'No matches.');
  static String get tomtProdukter =>
      _t('Ingen produkter her ennå.', 'No products here yet.');

  /// `katUnder` for the wheel's five slots.
  static String under(int k) => [
    _t('Bergens beste kjøkken — levert varmt til døra.', 'Bergen’s best kitchens — delivered hot to your door.'),
    _t('Fersk fangst fra Torget og skalldyr fra Nordnes.', 'Fresh catch from the Torget and shellfish from Nordnes.'),
    _t('Skandinavisk skreddersøm og vestlandsk ull.', 'Scandinavian tailoring and west-coast wool.'),
    _t('Ting som gjør stua til din — fra byens verksteder.', 'Things that make the living room yours — from the city’s workshops.'),
    _t('Gaver med mening, pakket inn og levert i kveld.', 'Gifts that mean something, wrapped and delivered tonight.'),
  ][k];

  /// `UNDER` — the sub-category names per slot.
  static List<String> underKat(int k) => [
    [_t('Alle', 'All'), 'Pizza', 'Sushi', 'Burger', _t('Asiatisk', 'Asian'), _t('Bakeri', 'Bakery')],
    [_t('Alle', 'All'), _t('Fisk', 'Fish'), _t('Skalldyr', 'Shellfish'), _t('Grønt', 'Greens'), _t('Bakeri', 'Bakery'), _t('Kolonial', 'Grocery')],
    [_t('Alle', 'All'), _t('Klær', 'Clothes'), _t('Sko', 'Shoes'), _t('Vesker', 'Bags'), 'Vintage', 'Sport'],
    [_t('Alle', 'All'), _t('Møbler', 'Furniture'), _t('Lys', 'Lights'), _t('Tekstil', 'Textiles'), _t('Planter', 'Plants'), _t('Kjøkken', 'Kitchen')],
    [_t('Alle', 'All'), _t('Blomster', 'Flowers'), _t('Sjokolade', 'Chocolate'), _t('Bøker', 'Books'), _t('Smykker', 'Jewellery'), _t('Kort', 'Cards')],
  ][k];
}

/// `kategori` (L5910–6135 in `Ærend Kunde Launch.dc.html`) at
/// `/bergen/kategori/{slug}` (arguments: `slug`, and `id` / `name` / `fane`
/// when the caller knows them).
///
/// The category's tint over the teal page, "{n} åpne nå · Bergen", the title
/// with its sticker slapped on (`klask`), Butikker / Produkter, the
/// sub-category orbs and, below, the floating 3D cards. Scrolling folds the
/// hero away and slides the tabs up under the back button (`katKollaps`).
/// At the bottom: the filter chips and the orb that turns them into a search
/// field. Mote adds the week's exhibition above its shops; Gaver has its
/// own page (`Gaver-kategori`).
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

  static const String filterOpen = 'apen';
  static const String filterFree = 'gratis';
  static const String filterFast = 'rask';
  static const String filterTop = 'topp';

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

/// The sub-category icons (`#g-…`), 24-unit paths.
final List<List<String>> _kUnderIkon = [
  [_gAlle, _gPizza, _gFisk, _gAlle, _gBlad, _gBok],
  [_gAlle, _gFisk, _gVintage, _gBlad, _gBok, _gVeske],
  [_gAlle, _gPlagg, _gSko, _gVeske, _gVintage, _gSport],
  [_gAlle, _gMobel, _gLys, _gPlagg, _gBlad, _gAlle],
  [_gAlle, _gBlomst, _gVeske, _gBok, _gVintage, _gBok],
];

/// What each sub-category looks for in a shop's or product's name.
const List<List<List<String>>> _kUnderOrd = [
  [[], ['pizza'], ['sushi'], ['burger'], ['thai', 'wok', 'asia', 'china', 'bangkok', 'nudel', 'sushi'], ['bakeri', 'bakst', 'kake', 'bolle', 'café', 'cafe']],
  [[], ['fisk'], ['skalldyr', 'reke', 'krabbe'], ['grønt', 'frukt'], ['bakeri', 'brød'], ['kolonial', 'dagligvare']],
  [[], ['klær', 'skjorte', 'jakke', 'genser'], ['sko'], ['veske'], ['vintage'], ['sport']],
  [[], ['møbel'], ['lys', 'lampe'], ['tekstil', 'pledd'], ['plante'], ['kjøkken']],
  [[], ['blomst'], ['sjokolade'], ['bok', 'bøker'], ['smykke'], ['kort']],
];

String _rekt(double x, double y, double w, double h, double r) =>
    'M${x + r} ${y}h${w - 2 * r}a$r $r 0 0 1 $r ${r}v${h - 2 * r}a$r $r 0 0 1 ${-r} ${r}h${-(w - 2 * r)}a$r $r 0 0 1 ${-r} ${-r}v${-(h - 2 * r)}a$r $r 0 0 1 $r ${-r}z';

final String _gAlle = _rekt(3.5, 3.5, 7, 7, 2) + _rekt(13.5, 3.5, 7, 7, 2) + _rekt(3.5, 13.5, 7, 7, 2) + _rekt(13.5, 13.5, 7, 7, 2);
final String _gPizza = 'M12 4l8 15H4z${SokIkon.sirkel(10, 13, 1.2)}${SokIkon.sirkel(14, 15.5, 1.2)}';
const String _gFisk = 'M4 12c4-5 10-6 13-3 1 1 2 2 3 3-1 1-2 2-3 3-3 3-9 2-13-3zM20 12l2.5-2.5v5z';
const String _gBlad = 'M19 5C11 5 5 9 5 16c0 2 1 3 3 3 7 0 11-6 11-14zM8 18C10 13 13 10 17 8';
const String _gBok = 'M4 5h7a2 2 0 0 1 2 2v13H6a2 2 0 0 1-2-2zM20 5h-7a2 2 0 0 0-2 2v13h7a2 2 0 0 0 2-2z';
const String _gVintage = 'M12 3l2.6 5.6 6 .8-4.4 4.2 1.1 6L12 16.8 6.7 19.6l1.1-6L3.4 9.4l6-.8z';
const String _gVeske = 'M5 8h14l-1 12H6zM9 8V6a3 3 0 0 1 6 0v2';
const String _gPlagg = 'M9 4l3 2 3-2 5 3-2 4-2-1v10H8V10L6 11 4 7z';
const String _gSko = 'M3 16h10l3-3 5 2v3H3zM6 16v-3M10 16v-4';
final String _gSport = '${SokIkon.sirkel(12, 12, 8.5)}M12 3.5v17M3.5 12h17';
final String _gMobel = 'M6 4v14M6 11h9M15 12v6${_rekt(7, 7, 7, 4, 2)}';
final String _gLys = '${_rekt(9, 9, 6, 11, 2)}M12 9V6M12 5c1.5-1.5 0-3 0-3s-1.5 1.5 0 3z';
const String _gBlomst = 'M12 12c0-3 2-4 3-3s0 3-3 3zM12 12c-3 0-4-2-3-3s3 0 3 3zM12 12c0 3-2 4-3 3s0-3 3-3zM12 12c3 0 4 2 3 3s-3 0-3-3zM12 15v5';

/// `katTint` per slot.
const List<Color> _kTint = [
  Color.fromRGBO(242, 109, 61, .16),
  Color.fromRGBO(30, 79, 92, .14),
  Color.fromRGBO(122, 78, 126, .15),
  Color.fromRGBO(63, 143, 95, .14),
  Color.fromRGBO(201, 150, 59, .16),
];

const List<String> _kStk = ['restaurant', 'fisk', 'mote', 'interior', 'gaver'];

/// `APNE` — shown until the category's pulse answers.
const List<String> _kApne = ['12', '8', '6', '5', '9'];

class _KategoriScreenState extends State<KategoriScreen> {
  late String _slug;
  int? _id;
  String? _name;
  bool _routeRead = false;
  bool _produkter = false;
  String _filter = KategoriScreen.filterOpen;
  int _under = 0;
  bool _sok = false;
  final TextEditingController _sokTekst = TextEditingController();
  final FocusNode _sokFokus = FocusNode();
  List<StoreListItem>? _stores;
  List<Map<String, dynamic>>? _products;
  Map<String, dynamic>? _pulse;

  /// `katKollaps`: how far the hero has folded (0–1, before easing).
  final ValueNotifier<double> _kollaps = ValueNotifier(0);
  final ScrollController _liste = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _fanerKey = GlobalKey();
  final GlobalKey _rotKey = GlobalKey();

  /// Measured in design px after the first layout (defaults: Restaurant).
  double _h = 110, _k = 226;

  OpsButikkApi get _api => widget.api ?? OpsButikkApi();
  OpsCustomerApi get _customer => widget.customerApi ?? OpsCustomerApi();

  /// The wheel slot (0 Restaurant … 4 Gaver) this category sits in.
  int get _slot => hjemHjulIkon(_name ?? _slug).clamp(0, 4);

  @override
  void initState() {
    super.initState();
    _liste.addListener(_onScroll);
    _sokTekst.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _slug = widget.slug ?? args['slug'] ?? 'kategori';
    _id = widget.categoryId ?? int.tryParse(args['id'] ?? '');
    _name = widget.name ?? args['name'];
    _produkter = args['fane'] == 'produkter';
    _load();
    _lastRegler();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maal());
    if (kDebugMode && HjemHarness.katScroll != null) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _liste.hasClients) {
          _liste.jumpTo(HjemHarness.katScroll! * context.bs);
        }
      });
    }
  }

  @override
  void dispose() {
    _liste.dispose();
    _kollaps.dispose();
    _sokTekst.dispose();
    _sokFokus.dispose();
    super.dispose();
  }

  /// `GET /api/points/rules` (backend plan Step 3): the product coins.
  PointsRules? _regler;

  /// Store id → `{viewers_now, typical_order_ore}` (backend plan Step 8).
  Map<int, Map<String, dynamic>> _presence = const {};

  Future<void> _lastRegler() async {
    final r = await _customer.rules();
    if (mounted && r != null) setState(() => _regler = r);
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
      final products = _customer.populaert(id);
      final stores = await _api.storesInCategory(id);
      if (!mounted) return;
      setState(() => _stores = stores);
      // «N nå» and each shop's typical order in one call (backend plan Step 8).
      unawaited(_customer.storesPresence([for (final s in stores) if (s.storeId != null) s.storeId!]).then((m) {
        if (mounted && m.isNotEmpty) setState(() => _presence = m);
      }));
      final p = await products;
      if (!mounted) return;
      setState(() => _products = p);
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

  /// `katKollaps`'s H and K from the laid-out hero and tabs.
  void _maal() {
    if (!mounted) return;
    final s = context.bs;
    final rot = _rotKey.currentContext?.findRenderObject() as RenderBox?;
    final hero = _heroKey.currentContext?.findRenderObject() as RenderBox?;
    final faner = _fanerKey.currentContext?.findRenderObject() as RenderBox?;
    if (rot == null || hero == null || faner == null) return;
    final dy = MediaQuery.paddingOf(context).top;
    final fanerBunn =
        (faner.localToGlobal(Offset(0, faner.size.height), ancestor: rot).dy - dy) / s;
    _h = hero.size.height / s + 14;
    _k = math.max(0, 334 - (fanerBunn - _h + 6));
    _onScroll();
  }

  void _onScroll() {
    if (!_liste.hasClients || _k <= 0) return;
    final c = (_liste.offset / context.bs).clamp(0.0, _k);
    _kollaps.value = c / _k;
  }

  static double _e(double p) =>
      p < .5 ? 2 * p * p : 1 - math.pow(-2 * p + 2, 2) / 2;

  // ── Data → cards ────────────────────────────────────────────────────────

  bool _treffer(String tekst) {
    final ord = _kUnderOrd[_slot][_under];
    final t = tekst.toLowerCase();
    return ord.any(t.contains);
  }

  List<StoreListItem> get _butikker {
    final alle = _stores ?? const <StoreListItem>[];
    final q = _sokTekst.text.trim().toLowerCase();
    var list = [
      for (final s in alle)
        if (q.isEmpty || (s.storeName ?? '').toLowerCase().contains(q)) s,
    ];
    final filtrert = [
      for (final s in list)
        if (switch (_filter) {
          KategoriScreen.filterOpen => (s.storeStatus ?? 1) == 1,
          // The store list carries no fee; an offer line is the nearest
          // real signal for "free delivery".
          KategoriScreen.filterFree => (s.offer ?? '').isNotEmpty,
          KategoriScreen.filterFast => (s.orderDeliveryTime ?? 999) <= 30,
          _ => (double.tryParse('${s.averageRatings ?? 0}') ?? 0) >= 4.5,
        })
          s,
    ];
    // A filter that would empty the page leaves it as it was.
    if (filtrert.isNotEmpty || q.isNotEmpty) list = filtrert;
    if (_under > 0) {
      // The sub-category brings its own shops to the front.
      final ja = [for (final s in list) if (_treffer('${s.storeName} ${s.storeProducts} ${s.description}')) s];
      list = [...ja, for (final s in list) if (!ja.contains(s)) s];
    }
    return list;
  }

  List<Map<String, dynamic>> get _produktliste {
    final alle = _products ?? const <Map<String, dynamic>>[];
    final q = _sokTekst.text.trim().toLowerCase();
    var list = [
      for (final p in alle)
        if (q.isEmpty || '${p['name']} ${p['store_name']}'.toLowerCase().contains(q)) p,
    ];
    if (_under > 0) {
      final ja = [for (final p in list) if (_treffer('${p['name']}')) p];
      list = [...ja, for (final p in list) if (!ja.contains(p)) p];
    }
    return list;
  }

  static String _kr(int ore) {
    final kr = (ore / 100).round();
    final t = '$kr';
    final b = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      if (i > 0 && (t.length - i) % 3 == 0) b.write(' ');
      b.write(t[i]);
    }
    return '$b kr';
  }

  static String? _rating(dynamic r) {
    final v = double.tryParse('${r ?? ''}') ?? 0;
    return v > 0 ? '★ ${v.toStringAsFixed(1).replaceAll('.', ',')}' : null;
  }

  int? _live(int? storeId) {
    final n = (_presence[storeId]?['viewers_now'] as num?)?.toInt() ?? 0;
    return n > 0 ? n : null;
  }

  int? _butikkPoeng(int? storeId) {
    final ore = (_presence[storeId]?['typical_order_ore'] as num?)?.toInt();
    final n = ore == null ? 0 : (_regler?.pointsForOre(ore) ?? 0);
    return n > 0 ? n : null;
  }

  KatButikkVis _butikkVis(StoreListItem s, int n, int? populaerId) {
    final sub = (s.description ?? '').trim().isNotEmpty
        ? s.description!.trim()
        : (s.storeProducts ?? '');
    return KatButikkVis(
      id: s.storeId ?? 0,
      navn: s.storeName ?? '',
      sub: sub,
      nr: n,
      bannerUrl: s.storeBanner,
      logoUrl: s.storeLogo,
      eta: (s.orderDeliveryTime ?? 0) > 0
          ? KatCopy.minutter(s.orderDeliveryTime!)
          : null,
      midt: _rating(s.averageRatings),
      // How many are following an order from the shop right now, and what a
      // typical order there earns (backend plan Step 8). Hidden without data.
      live: _live(s.storeId),
      poeng: _butikkPoeng(s.storeId),
      tag: s.storeId != null && s.storeId == populaerId ? KatCopy.populaer : null,
    );
  }

  KatProduktVis _produktVis(Map<String, dynamic> p, int n) {
    final storeId = int.tryParse('${p['store_id']}') ?? 0;
    final stores = _stores ?? const <StoreListItem>[];
    final si = stores.indexWhere((s) => s.storeId == storeId);
    final store = si >= 0 ? stores[si] : null;
    final ore = (p['price_ore'] as num?)?.toInt() ?? 0;
    final was = (p['was_price_ore'] as num?)?.toInt() ?? 0;
    final solgt = (p['ordered_7d'] as num?)?.toInt() ?? 0;
    return KatProduktVis(
      id: int.tryParse('${p['id']}') ?? 0,
      storeId: storeId,
      navn: '${p['name'] ?? ''}',
      butikk: '${p['store_name'] ?? store?.storeName ?? ''}',
      pris: _kr(ore),
      nr: n,
      fargeNr: si >= 0 ? si : n,
      bildeUrl: '${p['image'] ?? ''}',
      logoUrl: store?.storeLogo,
      eta: (store?.orderDeliveryTime ?? 0) > 0
          ? KatCopy.minutter(store!.orderDeliveryTime!)
          : null,
      // Ærend-kroner for the product: what KjopRule pays for its price
      // (`points/rules` kjop_per_10kr). Hidden without rules or below 10 kr.
      kroner: () {
        final n = _regler?.pointsForOre(ore) ?? 0;
        return n > 0 ? n : null;
      }(),
      tag: n == 0 && solgt > 0
          ? KatCopy.mestKjopt
          : (was > ore ? KatCopy.tilbud : null),
    );
  }

  /// The store with the most of the category's popular products.
  int? get _populaerId {
    final teller = <int, int>{};
    for (final p in _products ?? const <Map<String, dynamic>>[]) {
      final id = int.tryParse('${p['store_id']}');
      if (id != null) teller[id] = (teller[id] ?? 0) + 1;
    }
    if (teller.isEmpty) return null;
    return (teller.entries.toList()..sort((a, b) => b.value - a.value)).first.key;
  }

  // ── Ukens utstilling (Step 12) ──────────────────────────────────────────

  /// `catalog/showcase` per key (`mote`, `gaver`), loaded once on first build.
  final Map<String, KatUtstilling?> _utstillinger = {};
  final Set<String> _utstillingLaster = {};

  KatUtstilling? _utstillingFor(BuildContext context, String key) {
    if (!_utstillinger.containsKey(key) && _utstillingLaster.add(key)) {
      _customer.showcase(key).then((j) {
        if (mounted) setState(() => _utstillinger[key] = KatUtstilling.fraJson(j));
      });
    }
    return _utstillinger[key];
  }

  void _openButikk(int id) => _openStore(id, '');

  // ── Actions ─────────────────────────────────────────────────────────────

  void _openStore(int id, String name) {
    if (id == 0) return;
    BergenRoutes.pushOr(
      context,
      '/bergen/butikk/$id',
      arguments: {'name': name},
      orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
    );
  }

  /// A product opens its store with the product sheet on top.
  void _openProduct(KatProduktVis p) {
    if (p.storeId == 0) return;
    BergenRoutes.pushOr(
      context,
      '/bergen/butikk/${p.storeId}',
      arguments: {'name': p.butikk, 'product_id': '${p.id}'},
      orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
    );
  }

  void _askAegil(String intent) {
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      arguments: {'intent': intent, 'category': _name ?? _slug},
      orElse: () => openScreen(context, const SnurreChatScreen()),
    );
  }

  void _toggleSok() {
    HapticFeedback.selectionClick();
    setState(() {
      _sok = !_sok;
      _sokTekst.clear();
    });
    if (_sok) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && _sok) _sokFokus.requestFocus();
      });
    } else {
      _sokFokus.unfocus();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final dy = MediaQuery.paddingOf(context).top;
    final k = _slot;
    final navn = kHjemKatNavn[k];
    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      resizeToAvoidBottomInset: false,
      body: BergenOnce(
        durationMs: 340,
        builder: (context, p, child) {
          // `skjermInn .34s cubic-bezier(.2,.9,.3,1)`.
          final e = kSkjermInn.transform(p);
          return Opacity(
            opacity: (p / .55).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - e)),
              child: Transform.scale(scale: .978 + .022 * e, child: child),
            ),
          );
        },
        child: DecoratedBox(
          key: _rotKey,
          decoration: BoxDecoration(
            gradient: cssLinear(
              180,
              const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)],
              const [0, .42, 1],
            ),
          ),
          child: Stack(
            children: [
              // `radial-gradient(80% 50% at 14% 0%, rgba(255,255,255,.2), …)`.
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-.72, -1),
                        radius: 1,
                        colors: [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, 0)],
                        stops: [0, .6],
                        transform: _CssEllipse(.8, .5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: dy + 232 * s,
                child: _tint(context, k),
              ),
              _listeLag(context, dy),
              _rad(context, dy, k),
              Positioned(
                top: dy + 14 * s,
                left: 16 * s,
                right: 16 * s,
                child: _topp(context, k, navn),
              ),
              _bunnlinje(context, navn),
              // The Ægil-guide (L9495).
              Positioned.fill(child: AegilGuide(skjerm: 'kategori', tips: aegilGuideTips('kategori'), nav: false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tint(BuildContext context, int k) {
    final s = context.bs;
    return IgnorePointer(
      child: ValueListenableBuilder<double>(
        valueListenable: _kollaps,
        builder: (context, p, child) =>
            Opacity(opacity: .35 * (1 - _e(p) * .6), child: child),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_kTint[k], const Color.fromRGBO(30, 79, 92, 0)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -60 * s,
                top: -80 * s,
                width: 260 * s,
                height: 260 * s,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [rgba(255, 255, 255, .4), rgba(255, 255, 255, 0)],
                      stops: const [0, .68],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -70 * s,
                top: 40 * s,
                width: 240 * s,
                height: 240 * s,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [rgba(255, 255, 255, .25), rgba(255, 255, 255, 0)],
                      stops: const [0, .68],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Back key, the live pill, the folded title; the hero; the tabs.
  Widget _topp(BuildContext context, int k, String navn) {
    final s = context.bs;
    final apne = (_pulse?['stores_open'] as num?)?.toInt() ??
        _stores?.where((e) => (e.storeStatus ?? 1) == 1).length;
    return ValueListenableBuilder<double>(
      valueListenable: _kollaps,
      builder: (context, p, _) {
        final e = _e(p);
        final mini = math.max(0.0, (p - .55) / .45);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _GlassKnapp(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SokIkon(
                    'M15 6l-6 6 6 6',
                    size: 16 * s,
                    color: Colors.white,
                    stroke: 2.4,
                  ),
                ),
                SizedBox(width: 12 * s),
                _LivePille(tekst: KatCopy.apne(apne == null ? _kApne[k] : '$apne')),
                SizedBox(width: 12 * s),
                Expanded(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: mini.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - mini) * 6 * s),
                        child: Text(
                          navn,
                          key: const Key('a1_kat_mini'),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bDisplay(context, 19, letterSpacingEm: -.02),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14 * s),
            IgnorePointer(
              ignoring: p > .5,
              child: Opacity(
                opacity: math.max(0.0, 1 - p * 1.7),
                child: Transform(
                  alignment: Alignment.topLeft,
                  transform: Matrix4.translationValues(0, -e * _h * .45 * s, 0)
                    ..scaleByDouble(1 - e * .08, 1 - e * .08, 1, 1),
                  child: KeyedSubtree(key: _heroKey, child: _hero(context, k, navn)),
                ),
              ),
            ),
            SizedBox(height: 2 * s),
            Transform.translate(
              offset: Offset(0, -e * _h * s),
              child: KeyedSubtree(key: _fanerKey, child: _faner(context)),
            ),
          ],
        );
      },
    );
  }

  Widget _hero(BuildContext context, int k, String navn) {
    final s = context.bs;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 96 * s),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                navn,
                key: const Key('a1_kat_title'),
                style: bDisplay(
                  context,
                  34,
                  letterSpacingEm: -.03,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: rgba(4, 18, 26, .4),
                      offset: Offset(0, 2 * s),
                      blurRadius: 12 * s,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6 * s),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 220 * s),
                child: Text(
                  KatCopy.under(k),
                  style: bText(
                    context,
                    12.5,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: rgba(255, 255, 255, .72),
                  ),
                ),
              ),
              // `katErMat`: Mat & fisk can be ordered from a photo (C3).
              if (k == 1)
                Padding(
                  padding: EdgeInsets.only(top: 10 * s),
                  child: OnbPressable(
                    key: const Key('a1_kat_bilde'),
                    onTap: () => _askAegil('photo'),
                    pressDy: 0,
                    pressScale: .97,
                    child: Container(
                      height: 44 * s,
                      padding: EdgeInsets.symmetric(horizontal: 13 * s),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23201D),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: rgba(35, 32, 29, .9),
                            offset: Offset(0, 8 * s),
                            blurRadius: onbBlur(14 * s),
                            spreadRadius: -9 * s,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SokIkon(
                            'M4 8a2 2 0 0 1 2-2h2l1.5-2h5L16 6h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z${SokIkon.sirkel(12, 12.5, 3)}',
                            size: 14 * s,
                            color: Colors.white,
                            stroke: 2,
                          ),
                          SizedBox(width: 6 * s),
                          Text(
                            KatCopy.bilde,
                            style: bText(context, 12, weight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // The sticker slapped on (`klask .55s .1s`), rotated 7°.
          Positioned(
            right: -6 * s,
            top: -14 * s,
            child: BergenOnce(
              durationMs: 550,
              delayMs: 100,
              builder: (context, p, child) {
                const c = Cubic(.3, 1.3, .5, 1);
                final r = kf(p, const [0, .6, 1], const [-5, -7, -5], c);
                final sc = kf(p, const [0, .6, 1], const [1.15, .98, 1], c);
                final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
                return Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: (7 + r + 5) * math.pi / 180,
                    child: Transform.scale(scale: sc, child: child),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/dashboard/sok_stk_${_kStk[k]}.png',
                width: 118 * s,
                height: 118 * s,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faner(BuildContext context) {
    final s = context.bs;
    Widget fane(bool produkter, String tekst, String ikon, int? antall) {
      final paa = _produkter == produkter;
      final fg = paa ? Colors.white : rgba(255, 255, 255, .6);
      return Expanded(
        child: OnbPressable(
          key: Key(produkter ? 'a1_kat_tab_produkter' : 'a1_kat_tab_butikker'),
          onTap: () {
            if (_produkter == produkter) return;
            HapticFeedback.selectionClick();
            setState(() => _produkter = produkter);
            if (_liste.hasClients) _liste.jumpTo(0);
          },
          pressDy: 0,
          pressScale: .97,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            padding: EdgeInsets.symmetric(vertical: 10 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: paa
                    ? const [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)]
                    : const [Color(0x00F9A273), Color(0x00F26D3D), Color(0x00DD5A25)],
                stops: const [0, .56, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: rgba(242, 109, 61, paa ? .9 : 0),
                  offset: Offset(0, 4 * s),
                  blurRadius: onbBlur(10 * s),
                  spreadRadius: -4 * s,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (paa)
                  bergenInsetTop(
                    radius: 999,
                    height: 1.5 * s,
                    alpha: .4,
                    pad: EdgeInsets.symmetric(vertical: 10 * s),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SokIkon(ikon, size: 14 * s, color: fg, stroke: 2.3),
                    SizedBox(width: 7 * s),
                    Text(
                      tekst,
                      style: bText(context, 12.5, weight: FontWeight.w800, color: fg),
                    ),
                    if (antall != null) ...[
                      SizedBox(width: 7 * s),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 1 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: rgba(255, 255, 255, paa ? .28 : .1),
                        ),
                        child: Text(
                          '$antall',
                          style: bText(context, 10.5, weight: FontWeight.w800, color: fg),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(3 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: rgba(0, 0, 0, .28),
        border: Border.all(color: rgba(255, 255, 255, .12)),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rgba(0, 0, 0, .18), rgba(0, 0, 0, 0)],
          stops: const [0, .14],
        ),
      ),
      child: Row(
        children: [
          fane(false, KatCopy.butikker, 'M4 10l1.2-5h13.6L20 10M4 10h16v10H4zM10 20v-5h4v5', _stores?.length),
          SizedBox(width: 3 * s),
          fane(true, KatCopy.produkter, 'M6 8h12l1 13H5zM9 8V6a3 3 0 0 1 6 0v2', _products?.length),
        ],
      ),
    );
  }

  /// The sub-category orbs (`data-kc="rad"`, top 224).
  Widget _rad(BuildContext context, double dy, int k) {
    final s = context.bs;
    final navn = KatCopy.underKat(k);
    return Positioned(
      left: 0,
      right: 0,
      top: dy + 224 * s,
      child: ValueListenableBuilder<double>(
        valueListenable: _kollaps,
        builder: (context, p, child) {
          final e = _e(p);
          return IgnorePointer(
            ignoring: p > .5,
            child: Opacity(
              opacity: math.max(0.0, 1 - p * 1.6),
              child: Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.translationValues(0, -e * _h * s, 0)
                  ..scaleByDouble(1 - e * .25, 1 - e * .25, 1, 1),
                child: child,
              ),
            ),
          );
        },
        child: ShaderMask(
          // `mask-image: linear-gradient(90deg,#000 92%,transparent)`.
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0, .92, 1],
          ).createShader(r),
          child: SingleChildScrollView(
            key: const Key('a1_kat_under'),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(14 * s, 16 * s, 14 * s, 4 * s),
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var n = 0; n < navn.length; n++) ...[
                  if (n > 0) SizedBox(width: 6 * s),
                  _UnderOrb(
                    navn: navn[n],
                    ikon: _kUnderIkon[k][n],
                    valgt: n == _under,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _under = n);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _listeLag(BuildContext context, double dy) {
    final s = context.bs;
    final bunn = math.max(MediaQuery.paddingOf(context).bottom, 16 * s);
    final k = _slot;
    final gaver = k == 4 && !_produkter;
    final mote = k == 2 && !_produkter;
    final liste = ShaderMask(
      // `mask-image: linear-gradient(180deg, transparent 0, #000 14px,
      // #000 calc(100% - 96px), transparent calc(100% - 8px))`.
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
        stops: [
          0,
          (14 * s / r.height).clamp(0.0, 1.0),
          ((r.height - 96 * s) / r.height).clamp(0.0, 1.0),
          ((r.height - 8 * s) / r.height).clamp(0.0, 1.0),
        ],
      ).createShader(r),
      child: ListView(
        key: const Key('a1_kat_liste'),
        controller: _liste,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 96 * s + bunn),
        clipBehavior: Clip.hardEdge,
        children: [
          if (gaver)
            KatGaverSide(
              utstilling: _utstillingFor(context, 'gaver'),
              onAegil: () => _askAegil('gift'),
              onButikk: _openButikk,
            )
          else ...[
            if (mote)
              KatMoteUtstilling(
                utstilling: _utstillingFor(context, 'mote'),
                onButikk: _openButikk,
              ),
            if (_produkter) _produktGrid(context) else ..._butikkKort(context),
          ],
        ],
      ),
    );
    return ValueListenableBuilder<double>(
      valueListenable: _kollaps,
      child: liste,
      builder: (context, p, child) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        top: dy + (334 - _e(p) * _k) * s,
        child: child!,
      ),
    );
  }

  List<Widget> _butikkKort(BuildContext context) {
    final s = context.bs;
    if (_stores == null) return const [];
    final list = _butikker;
    if (list.isEmpty) {
      return [_Tomt(tekst: _sokTekst.text.trim().isEmpty ? KatCopy.tomt : KatCopy.tomtSok)];
    }
    final pop = _populaerId;
    return [
      for (var n = 0; n < list.length; n++)
        Padding(
          key: ValueKey('kb-${list[n].storeId}'),
          padding: EdgeInsets.only(bottom: 28 * s),
          child: KatKortStag(
            durationMs: 550,
            delayMs: (0.05 + math.min(n, 6) * 0.07) * 1000,
            child: KatButikkKort(
              b: _butikkVis(list[n], n, pop),
              onTap: () => _openStore(list[n].storeId ?? 0, list[n].storeName ?? ''),
            ),
          ),
        ),
    ];
  }

  Widget _produktGrid(BuildContext context) {
    final s = context.bs;
    if (_products == null) return const SizedBox.shrink();
    final list = _produktliste;
    if (list.isEmpty) {
      return _Tomt(tekst: _sokTekst.text.trim().isEmpty ? KatCopy.tomtProdukter : KatCopy.tomtSok);
    }
    final vis = [for (var n = 0; n < list.length; n++) _produktVis(list[n], n)];
    Widget kort(KatProduktVis p) => KatKortStag(
      key: ValueKey('kp-${p.id}'),
      durationMs: 500,
      delayMs: math.min(p.nr, 8) * 60.0,
      child: KatProduktKort(
        p: p,
        onTap: () => _openProduct(p),
        onLeggTil: () => _openProduct(p),
      ),
    );
    return Padding(
      // `padding-top:52px` — room for the products floating out of the cards.
      padding: EdgeInsets.only(top: 52 * s),
      child: Column(
        children: [
          for (var i = 0; i < vis.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: 60 * s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: kort(vis[i])),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: i + 1 < vis.length
                        ? Padding(
                            padding: EdgeInsets.only(top: 56 * s),
                            child: kort(vis[i + 1]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The filter chips / the search field, and the orb that swaps them.
  Widget _bunnlinje(BuildContext context, String navn) {
    final s = context.bs;
    final bunn = math.max(MediaQuery.paddingOf(context).bottom, 16 * s);
    final tastatur = MediaQuery.viewInsetsOf(context).bottom;
    final y = math.max(bunn, tastatur + 12 * s);
    const ut = Cubic(.3, 1.2, .5, 1);
    Widget chip(String id, String tekst, {bool hake = false}) {
      final paa = _filter == id;
      return OnbPressable(
        key: Key('a1_kat_f_$id'),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filter = id);
        },
        pressDy: 0,
        pressScale: .95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.ease,
          padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 9 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: paa
                  ? const [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)]
                  : [rgba(255, 255, 255, .06), rgba(255, 255, 255, .06), rgba(255, 255, 255, .06)],
              stops: const [0, .56, 1],
            ),
            border: Border.all(
              color: paa ? rgba(255, 255, 255, .55) : rgba(255, 255, 255, .22),
            ),
            boxShadow: paa
                ? [
                    BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 1.5 * s)),
                    BoxShadow(color: rgba(120, 45, 15, .4), offset: Offset(0, 3 * s)),
                    BoxShadow(
                      color: rgba(200, 70, 25, .85),
                      offset: Offset(0, 10 * s),
                      blurRadius: onbBlur(16 * s),
                      spreadRadius: -8 * s,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              bergenInsetTop(
                radius: 999,
                height: (paa ? 1.5 : 1) * s,
                alpha: paa ? .4 : .18,
                pad: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 9 * s),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hake) ...[
                    SokIkon(
                      'M4.5 12.5l5 5 10-11',
                      size: 12 * s,
                      color: paa ? Colors.white : rgba(255, 255, 255, .82),
                      stroke: 3,
                    ),
                    SizedBox(width: 5 * s),
                  ],
                  Text(
                    tekst,
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w800,
                      color: paa ? Colors.white : rgba(255, 255, 255, .82),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: 0,
      right: 0,
      bottom: y,
      height: 58 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14 * s,
            right: 86 * s,
            top: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B5F6E), Color(0xFF1E4F5C)],
                ),
                border: Border.all(color: rgba(255, 255, 255, .28)),
                boxShadow: [
                  BoxShadow(
                    color: rgba(4, 18, 26, .9),
                    offset: Offset(0, 18 * s),
                    blurRadius: onbBlur(30 * s),
                    spreadRadius: -16 * s,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  bergenInsetTop(
                    radius: 999,
                    height: 1.5 * s,
                    alpha: .3,
                    pad: EdgeInsets.symmetric(horizontal: 8 * s),
                  ),
                  SizedBox(
                    height: 42 * s,
                    child: Stack(
                      children: [
                        // The search field (`kFeltOp` / `kFeltSc`).
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !_sok,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 260),
                              opacity: _sok ? 1 : 0,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                curve: ut,
                                alignment: Alignment.centerLeft,
                                scale: _sok ? 1 : .96,
                                child: _SokFelt(
                                  controller: _sokTekst,
                                  fokus: _sokFokus,
                                  hint: KatCopy.sokI(navn),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // The filter chips (`kChipOp` / `kChipSc`).
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _sok,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 260),
                              opacity: _sok ? 0 : 1,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                curve: ut,
                                alignment: Alignment.centerLeft,
                                scale: _sok ? .96 : 1,
                                child: ShaderMask(
                                  blendMode: BlendMode.dstIn,
                                  shaderCallback: (r) => const LinearGradient(
                                    colors: [Colors.black, Colors.black, Colors.transparent],
                                    stops: [0, .88, 1],
                                  ).createShader(r),
                                  child: SingleChildScrollView(
                                    key: const Key('a1_kat_filters'),
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        chip(KategoriScreen.filterOpen, KatCopy.fApen, hake: true),
                                        SizedBox(width: 4 * s),
                                        chip(KategoriScreen.filterFree, KatCopy.fGratis),
                                        SizedBox(width: 4 * s),
                                        chip(KategoriScreen.filterFast, KatCopy.fRask),
                                        SizedBox(width: 4 * s),
                                        chip(KategoriScreen.filterTop, KatCopy.fTopp),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 14 * s,
            top: 0,
            child: _SokOrb(apen: _sok, onTap: _toggleSok),
          ),
        ],
      ),
    );
  }
}

/// CSS `radial-gradient(<rx>% <ry>% at …)` — Flutter's radial is a circle
/// on the box's shortest side; this stretches it to the ellipse.
class _CssEllipse extends GradientTransform {
  const _CssEllipse(this.rx, this.ry);

  final double rx;
  final double ry;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final short = math.min(bounds.width, bounds.height) / 2;
    final c = Offset(bounds.left + bounds.width * .14, bounds.top);
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(rx * bounds.width / short, ry * bounds.height / short, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

/// The 42px glass back key.
class _GlassKnapp extends StatelessWidget {
  const _GlassKnapp({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      key: const Key('a1_kat_tilbake'),
      onTap: onTap,
      pressDy: 0,
      pressScale: .94,
      child: Container(
        width: 42 * s,
        height: 42 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15 * s),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rgba(255, 255, 255, .16), rgba(255, 255, 255, .07)],
          ),
          border: Border.all(color: rgba(255, 255, 255, .26)),
          boxShadow: [
            BoxShadow(
              color: rgba(4, 18, 26, .8),
              offset: Offset(0, 12 * s),
              blurRadius: onbBlur(22 * s),
              spreadRadius: -12 * s,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            bergenInsetTop(radius: 15 * s, height: 1.5 * s, alpha: .34),
            child,
          ],
        ),
      ),
    );
  }
}

/// "12 åpne nå · Bergen" with the breathing mint dot (`livePuls 1.8s`).
class _LivePille extends StatelessWidget {
  const _LivePille({required this.tekst});

  final String tekst;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: const Key('a1_kat_apne'),
      padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 11 * s, 6 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rgba(255, 255, 255, .16), rgba(255, 255, 255, .07)],
        ),
        border: Border.all(color: rgba(255, 255, 255, .26)),
        boxShadow: [
          BoxShadow(
            color: rgba(4, 18, 26, .8),
            offset: Offset(0, 8 * s),
            blurRadius: onbBlur(14 * s),
            spreadRadius: -10 * s,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -8 * s,
            right: -11 * s,
            top: -6 * s,
            bottom: -6 * s,
            child: Stack(children: [bergenInsetTop(radius: 999, height: 1.5 * s, alpha: .34)]),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 7 * s,
                height: 7 * s,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BergenColors.mint,
                          boxShadow: [
                            BoxShadow(color: BergenColors.mint, blurRadius: onbBlur(8 * s)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: -3 * s,
                      top: -3 * s,
                      right: -3 * s,
                      bottom: -3 * s,
                      child: RepaintBoundary(
                        child: KatLoop(
                          durationMs: 1800,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: rgba(92, 224, 184, .7), width: 1.5 * s),
                            ),
                          ),
                          builder: (context, p, child) {
                            final e = Curves.easeOut.transform(p);
                            return Opacity(
                              opacity: (.9 * (1 - e)).clamp(0.0, 1.0),
                              child: Transform.scale(scale: .6 + 1.3 * e, child: child),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6 * s),
              Text(tekst, style: bText(context, 11, weight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One sub-category orb (50px) with its label; the chosen one lifts.
class _UnderOrb extends StatelessWidget {
  const _UnderOrb({
    required this.navn,
    required this.ikon,
    required this.valgt,
    required this.onTap,
  });

  final String navn;
  final String ikon;
  final bool valgt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    const c = Cubic(.3, 1.3, .5, 1);
    // CSS lists the top shadow first; Flutter paints the first one lowest.
    final skygge = valgt
        ? [
            BoxShadow(
              color: rgba(200, 70, 25, .85),
              offset: Offset(0, 12 * s),
              blurRadius: onbBlur(18 * s),
              spreadRadius: -6 * s,
            ),
            BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 3 * s), spreadRadius: 3 * s),
            BoxShadow(color: rgba(255, 255, 255, .05), spreadRadius: 7 * s),
            BoxShadow(color: rgba(255, 255, 255, .22), offset: Offset(0, 2 * s), spreadRadius: 4 * s),
            BoxShadow(color: rgba(0, 0, 0, .45), offset: Offset(0, -2 * s), spreadRadius: 4 * s),
            BoxShadow(color: rgba(0, 0, 0, .35), spreadRadius: 4 * s),
            BoxShadow(color: const Color(0xFF12333D), spreadRadius: 3 * s),
          ]
        : [
            BoxShadow(
              color: rgba(15, 45, 55, .75),
              offset: Offset(0, 7 * s),
              blurRadius: onbBlur(11 * s),
              spreadRadius: -5 * s,
            ),
            BoxShadow(color: rgba(11, 38, 45, .85), offset: Offset(0, 2 * s)),
          ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 74 * s,
        child: Column(
          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: c,
              offset: Offset(0, valgt ? -3 / 50 : 0),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 280),
                curve: c,
                scale: valgt ? 1.08 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.ease,
                  width: 50 * s,
                  height: 50 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: valgt
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
                            stops: [0, .56, 1],
                          )
                        : cssLinear(165, const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF1E4F5C)], const [0, 1, 1]),
                    boxShadow: skygge,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (valgt)
                        sokInsetBunnSirkel(s)
                      else
                        const SizedBox.shrink(),
                      bergenInsetTop(radius: 999, height: 1.5 * s, alpha: valgt ? .45 : .28),
                      // `filter: drop-shadow(0 2px 3px rgba(15,31,43,.35))`.
                      Transform.translate(
                        offset: Offset(0, 2 * s),
                        child: SokIkon(
                          ikon,
                          size: 26 * s,
                          color: rgba(15, 31, 43, .35),
                          stroke: 2,
                          blur: 1.5 * s,
                        ),
                      ),
                      SokIkon(ikon, size: 26 * s, color: Colors.white, stroke: 2),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 6 * s),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 280),
              style: bText(
                context,
                11,
                weight: FontWeight.w800,
                color: valgt ? const Color(0xFF7FF0CB) : rgba(255, 255, 255, .6),
              ),
              child: Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// `inset 0 -4px 6px rgba(120,45,15,.3)` inside a round orb.
Widget sokInsetBunnSirkel(double s) => Positioned.fill(
  child: IgnorePointer(
    child: ClipOval(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 9 * s,
          width: double.infinity,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color.fromRGBO(120, 45, 15, .3), Color.fromRGBO(120, 45, 15, 0)],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The white search pill inside the bottom bar.
class _SokFelt extends StatelessWidget {
  const _SokFelt({
    required this.controller,
    required this.fokus,
    required this.hint,
  });

  final TextEditingController controller;
  final FocusNode fokus;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.fromLTRB(5 * s, 0, 6 * s, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F5F0), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
          stops: [0, .46, 1],
        ),
        boxShadow: [
          BoxShadow(color: rgba(255, 255, 255, .28), offset: const Offset(0, 1)),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rgba(6, 30, 38, .18), rgba(6, 30, 38, 0)],
          stops: const [0, .12],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32 * s,
            height: 32 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF1F3), Color(0xFFCFDFE4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: rgba(6, 30, 38, .25),
                  offset: const Offset(0, 1),
                  blurRadius: onbBlur(2),
                ),
              ],
            ),
            child: SokIkon(
              '${SokIkon.sirkel(11, 11, 7)}M20.5 20.5l-4.3-4.3',
              size: 16 * s,
              color: const Color(0xFF1E4F5C),
              stroke: 2.6,
            ),
          ),
          SizedBox(width: 8 * s),
          Expanded(
            child: TextField(
              key: const Key('a1_kat_sok'),
              controller: controller,
              focusNode: fokus,
              cursorColor: const Color(0xFFF26D3D),
              textInputAction: TextInputAction.search,
              style: bDisplay(
                context,
                13.5,
                weight: FontWeight.w700,
                letterSpacingEm: -.01,
                color: const Color(0xFF23201D),
              ),
              decoration: onbBareInput(
                hint: hint,
                hintStyle: bDisplay(
                  context,
                  13.5,
                  weight: FontWeight.w700,
                  letterSpacingEm: -.01,
                  color: const Color(0xFF8C847C),
                ),
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty) ...[
            SizedBox(width: 8 * s),
            GestureDetector(
              onTap: controller.clear,
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
                  color: const Color(0xFF57534B),
                  stroke: 3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The 58px orb: search ↔ close, turning a quarter (`kSokRot`).
class _SokOrb extends StatelessWidget {
  const _SokOrb({required this.apen, required this.onTap});

  final bool apen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      key: const Key('a1_kat_sok_orb'),
      onTap: onTap,
      pressDy: 0,
      pressScale: .93,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 280),
        curve: const Cubic(.3, 1.2, .5, 1),
        turns: apen ? .25 : 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.ease,
          width: 58 * s,
          height: 58 * s,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * s),
            gradient: apen
                ? cssLinear(160, const [Color(0xFFF58A55), Color(0xFFE95C2C)])
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2B5F6E), Color(0xFF1E4F5C)],
                  ),
            border: Border.all(color: rgba(255, 255, 255, .3)),
            boxShadow: apen
                ? [
                    BoxShadow(color: rgba(150, 60, 15, .8), offset: Offset(0, 3 * s)),
                    BoxShadow(
                      color: rgba(120, 50, 10, .9),
                      offset: Offset(0, 16 * s),
                      blurRadius: onbBlur(26 * s),
                      spreadRadius: -12 * s,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: rgba(4, 18, 26, .85),
                      offset: Offset(0, 18 * s),
                      blurRadius: onbBlur(30 * s),
                      spreadRadius: -16 * s,
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              bergenInsetTop(radius: 22 * s, height: 1.5 * s, alpha: apen ? .35 : .34),
              if (apen)
                Transform.rotate(
                  angle: -math.pi / 2,
                  child: SokIkon('M6 6l12 12M18 6L6 18', size: 20 * s, color: Colors.white, stroke: 2.6),
                )
              else
                SokIkon(
                  '${SokIkon.sirkel(11, 11, 7)}M20.5 20.5l-4.3-4.3',
                  size: 22 * s,
                  color: Colors.white,
                  stroke: 2.4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tomt extends StatelessWidget {
  const _Tomt({required this.tekst});

  final String tekst;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(top: 40 * s),
      child: Text(
        tekst,
        key: const Key('a1_kat_tomt'),
        textAlign: TextAlign.center,
        style: bText(context, 12.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .7)),
      ),
    );
  }
}
