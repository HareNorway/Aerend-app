import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../networking/api_response.dart';
import '../../../../utils/guest_auth_helper.dart';
import '../../../../utils/utils.dart';
import '../../../deliveryService/home/ds_home.dart';
import '../../../deliveryService/home/ds_home_store_list_pojo.dart';
import '../../../deliveryService/storeDetail/store_detail.dart';
import '../../../deliveryService/trackOrder/track_order.dart';
import '../../../../networking/ops/ops_customer_api.dart';
import '../../../bergen/aegil/aegil_entry.dart';
import '../../../bergen/aegil/brett_entry.dart';
import '../../../bergen/kit/bergen_routes.dart';
import '../../../bergen/meg/a3_services.dart';
import '../../../bergen/meg/borte_entry.dart';
import '../../../bergen/meg/konto_screen.dart' show kPrefA3Rolig;
import '../../../bergen/poeng/napp_entry.dart';
import '../../../bergen/poeng/poeng_entry.dart';
import '../../../snurre/snurre_chat_screen.dart';
import '../../auth/onboarding_kit.dart';
import '../../homeMainV1/home_main_v1.dart';
import '../../location/add_location.dart';
import '../../manageAddress/manage_address_dl.dart';
import '../../notifications/notifications.dart';
import '../../swipeAerend/swipe_aerend_dl.dart';
import '../home_bloc.dart';
import '../home_dl.dart';
import '../home_post_order_feedback.dart';
import 'bergen_cards.dart';
import 'bergen_category_rad.dart';
import 'bergen_copy.dart';
import 'bergen_floats.dart';
import 'bergen_hero.dart';
import 'bergen_hjem_ark.dart';
import 'bergen_kit.dart';
import 'bergen_nav.dart';
import 'bergen_painters.dart';
import 'bergen_rails.dart';
import 'bergen_store_repo.dart';

// Hjem — the `erHjem` screen of "Ærend Kunde Bergen" (ROM style).
//
// Geometry (390×844 design frame, scaled by `context.bx`):
//   header row   top 10, height 56 (address pill h44 + bell 44)
//   hero         top 72 (`kromOffset`), height 250
//   sheet (ark)  top 296, rounded 30; scrolling it translates the sheet and
//                the hero up by min(212, offset) and fades the hero after 120
//   Under kaien  300 tall zone at the very bottom of the sheet, revealed when
//                the remaining scroll is < 210 (hidden again above 260)
//
// Data: categories from `HomeBloc.subjectHomeCat`, floats + popular products
// from `subjectHareSwipe`, stores per focused category via `BergenStoreRepo`
// (fallback `subjectHareExplore`), the boat from `subjectTrackOrder`, address
// from `deliveryAddress`. Anything the backend has no endpoint for yet keeps
// the design's sample content and is marked TODO(api).

const double _kHeaderTop = 10;
const double _kHeroTop = 72; // kromOffset
const double _kSheetTop = 296; // arkTop (ROM)
const double _kSheetSlide = 212; // max parallax translate
const double _kSheetRadius = 30;

/// Design's `LIVE` placeholders per category slot. TODO(api): open-now counts.
const List<String> kBergenLive = [
  '24 åpne nå',
  '9 åpne nå',
  'Åpner 10:00',
  '6 åpne nå',
  '4 åpne nå',
];

/// `/bergen/kategori/{slug}` from a category name — the app's categories
/// carry no slug of their own, so the name is the key (Phase 4 resolves it by
/// `id` when the arguments carry one).
abstract final class BergenHomeSlug {
  static String of(String name) {
    final lower = name
        .trim()
        .toLowerCase()
        .replaceAll('æ', 'ae')
        .replaceAll('ø', 'o')
        .replaceAll('å', 'a');
    final slug = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'kategori' : slug;
  }
}

class BergenHome extends StatefulWidget {
  const BergenHome({super.key, this.orderId = 0, this.isShowDialog = false});

  /// Set after a delivery: runs the post-order feedback dialogs.
  final int orderId;
  final bool isShowDialog;

  @override
  State<BergenHome> createState() => _BergenHomeState();
}

class _BergenHomeState extends State<BergenHome> with WidgetsBindingObserver {
  late final HomeBloc _bloc;
  final BergenStoreRepo _storeRepo = BergenStoreRepo();
  final ScrollController _scroll = ScrollController();
  Timer? _trackTimer;

  /// `arkScroll` — clamped scroll offset that drives the parallax.
  double _k = 0;

  /// `kaien` — Under kaien revealed.
  bool _kaien = false;

  /// `dragY` / `drar` — pull handle state.
  double _dragY = 0;
  bool _dragging = false;
  double _dragStartDy = 0;
  bool _armed = false;
  DateTime _lock = DateTime.fromMillisecondsSinceEpoch(0);

  /// Focused category (`i`) and the per-category store cache.
  int _catIndex = 0;
  final Map<int, List<BergenStoreCard>> _storesByCat = {};

  /// The Ark (design `st.ark`): both «Se alle» open it.
  bool _arkOpen = false;
  final Set<int> _storesLoading = {};
  int _storesRequestSeq = 0;

  /// Floats the user sank / banned this session (`gjemt`).
  final Set<String> _hiddenFloats = {};

  /// Last completed payloads, kept when a refresh later errors out.
  HomeCatePojo? _lastHome;
  HareSwipeListPojo? _lastSwipe;
  HareExplorePojo? _lastExplore;

  /// The intro walk plays once per app session.
  static bool _introPlayed = false;
  late final bool _playIntro;

  /// "UNDER KAIEN" — a real find from agil-2's suggestions tray, else the
  /// design's sample (AGIL-1 v2 Phase 2; guarded 404 → sample).
  BergenUnderQuayOffer? _underKaien;

  @override
  void initState() {
    super.initState();
    _playIntro = !_introPlayed;
    _introPlayed = true;
    _bloc = HomeBloc(context, this, false);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    _trackTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _bloc.callHomeTrackOrderApi();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      runPostOrderFeedback(context, widget.orderId);
      if (isDemoApp && widget.isShowDialog) _bloc.openDemoDialog();
    });
    _loadUnderKaien();
    _refreshSeams();
  }

  /// agil-3's seams need their data pulled (an ask of agil-1, merge day):
  /// the Ægil find count behind the relevanskort and "Mens du var borte",
  /// on cold start and on resume. Konto's calm-motion preference is read
  /// here too so it holds from the first frame.
  Future<void> _refreshSeams() async {
    A3Services.reducedMotion.value = prefGetBool(kPrefA3Rolig);
    if (isGuestUser()) return;
    await Future.wait<Object?>([
      refreshAegilFindCount(),
      refreshMensDuVarBorte(),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _loadUnderKaien() async {
    if (isGuestUser()) return;
    final finds = await OpsCustomerApi().underKaien();
    if (!mounted || finds.isEmpty) return;
    final f = finds.first;
    final ore = (f['price_ore'] as num?)?.toInt();
    setState(() {
      _underKaien = BergenUnderQuayOffer(
        id: '${f['id'] ?? ''}',
        title: '${f['title'] ?? f['product_name'] ?? f['name'] ?? ''}',
        price: ore != null ? '${ore ~/ 100} kr' : '${f['price_text'] ?? ''}',
        store: '${f['store_name'] ?? f['store'] ?? ''}',
        sub: '${f['reason'] ?? ''}',
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bloc.callHomeTrackOrderApi();
      _syncCartBadge();
      _refreshSeams();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackTimer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _bloc.dispose();
    super.dispose();
  }

  // ── Shell helpers ───────────────────────────────────────────────────────

  HomeMainV1State? get _shell =>
      context.findAncestorStateOfType<HomeMainV1State>();

  void _syncCartBadge() {
    final shell = _shell;
    if (shell != null) {
      shell.badgeCountNotifier.value = prefGetInt(prefCartCount);
    }
  }

  void _toExplore() {
    final shell = _shell;
    if (shell != null) {
      shell.switchToTab(BergenTab.explore.index);
    }
  }

  void _openAegil() {
    HapticFeedback.mediumImpact();
    // AGIL-CONTRACT §2.2: the greeting pushes `kAegilRoute`; the legacy chat
    // until agil-3's screen is on this tree.
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      orElse: () => openScreen(context, const SnurreChatScreen()),
    );
  }

  void _openAutomat() => BergenRoutes.push(context, '/bergen/automat');

  void _openFjordfiske() => BergenRoutes.push(context, '/bergen/fjordfiske');

  /// A bobber → the Napp card (seam, AGIL-CONTRACT §5.4).
  void _onFloatTap(BergenFloatItem f) {
    HapticFeedback.selectionClick();
    showNappKort(
      context,
      NappOffer(
        id: f.id,
        title: f.title,
        storeName: f.store,
        priceOre: (f.price * 100).round(),
        reason: f.reason,
        kind: switch (f.kind) {
          BergenFloatKind.offer => 'tilbud',
          BergenFloatKind.fresh => 'ny',
          BergenFloatKind.rhythm => 'rytme',
        },
      ),
    );
  }

  void _onUnderKaienOffer() {
    final o = _underKaien;
    if (o == null) {
      _comingSoon();
      return;
    }
    showNappKort(
      context,
      NappOffer(
        id: o.id,
        title: o.title,
        storeName: o.store,
        priceOre:
            (int.tryParse(o.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) *
            100,
        reason: o.sub,
        kind: 'tilbud',
      ),
    );
  }

  static String slugOf(String name) => BergenHomeSlug.of(name);

  void _comingSoon() => openSimpleSnackbar(BergenCopy.comingSoon);

  // ── Sheet scroll / parallax ─────────────────────────────────────────────

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final k = pos.pixels.clamp(0.0, _kSheetSlide * context.bs);
    final remaining = pos.maxScrollExtent - pos.pixels;
    bool kaien = _kaien;
    if (remaining < 210 * context.bs && !kaien) kaien = true;
    if (remaining > 260 * context.bs && kaien) kaien = false;
    if (k != _k || kaien != _kaien) {
      setState(() {
        _k = k;
        _kaien = kaien;
      });
    }
  }

  // ── Pull handle (`dragNed` / `dragFlytt` / `dragSlipp`) ─────────────────

  void _dragStart(DragStartDetails d) {
    _dragStartDy = d.globalPosition.dy;
    _armed = false;
    setState(() {
      _dragging = true;
      _dragY = 0;
      _kaien = false;
    });
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    final s = context.bs;
    final raw = (d.globalPosition.dy - _dragStartDy) / s;
    final v = raw < 0
        ? (raw * .6).clamp(-160.0, 0.0)
        : (raw * .58).clamp(0.0, 158.0);
    final snapped = (v / 8).round() * 8.0;
    final armed = snapped > 110;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.lightImpact();
    }
    if (snapped != _dragY) setState(() => _dragY = snapped);
  }

  void _dragEnd([DragEndDetails? _]) {
    if (!_dragging) return;
    final d = _dragY;
    _lock = DateTime.now().add(const Duration(milliseconds: 700));
    setState(() {
      _dragging = false;
      _dragY = 0;
      _kaien = false;
    });
    if (d > 110) {
      _openAegil();
    } else if (d < -110) {
      _toExplore();
    }
  }

  void _handleTap() {
    if (_dragging || DateTime.now().isBefore(_lock)) return;
    _openAegil();
  }

  // ── Data mapping ────────────────────────────────────────────────────────

  String? get _firstName {
    if (isGuestUser()) return null;
    final name = prefGetString(prefUserName).trim();
    if (name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  /// Categories: backend services, or the design's five while loading.
  List<BergenCategory> _categories(HomeCatePojo? home) {
    final services = home?.services ?? const <ServicesItem>[];
    if (services.isEmpty) {
      return [
        for (var i = 0; i < BergenCategoryLook.all.length; i++)
          BergenCategory(
            id: 0,
            name: _placeholderCategoryName(i),
            liveText: kBergenLive[i],
            iconAsset: BergenCategoryLook.all[i].icon,
            look: BergenCategoryLook.all[i],
          ),
      ];
    }
    return [
      for (var i = 0; i < services.length; i++)
        BergenCategory(
          id: services[i].serviceCategoryId,
          name: services[i].serviceCategoryName,
          liveText: kBergenLive[i % kBergenLive.length],
          iconUrl: services[i].serviceCategoryIcon.isEmpty
              ? null
              : services[i].serviceCategoryIcon,
          iconAsset:
              BergenCategoryLook.forName(
                services[i].serviceCategoryName,
              )?.icon ??
              BergenCategoryLook.all[i % BergenCategoryLook.all.length].icon,
          look:
              BergenCategoryLook.forName(services[i].serviceCategoryName) ??
              BergenCategoryLook.all[i % BergenCategoryLook.all.length],
        ),
    ];
  }

  String _placeholderCategoryName(int i) =>
      const ['Restaurant', 'Fisk', 'Mote', 'Interiør', 'Gaver'][i];

  /// `META` — the design's three floats. TODO(api): Ægil recommendations.
  List<BergenFloatItem> _placeholderFloats() => const [
    BergenFloatItem(
      id: 'b1',
      title: 'Reker på tilbud',
      store: 'Torgboden',
      priceText: '149 kr',
      reason: 'Du kjøpte reker to torsdager på rad.',
      kind: BergenFloatKind.offer,
      icon: BergenFloatIcon.shrimp,
      price: 149,
      bergensk: true,
      glow: true,
      ring: true,
    ),
    BergenFloatItem(
      id: 'b2',
      title: 'Sei er ny',
      store: 'Nordnes Fisk',
      priceText: '129 kr',
      reason: 'Ny i dag hos en butikk du følger.',
      kind: BergenFloatKind.fresh,
      icon: BergenFloatIcon.fish,
      price: 129,
    ),
    BergenFloatItem(
      id: 'b3',
      title: 'Torsdag-rytmen',
      store: 'Fyllingsdalen Wok',
      priceText: '189 kr',
      reason: 'Pad thai med kylling — som de tre siste torsdagene.',
      kind: BergenFloatKind.rhythm,
      icon: BergenFloatIcon.crate,
      price: 189,
      photoAsset: BergenAssets.bkWhopper,
    ),
  ];

  List<BergenFloatItem> _floats(List<SwipeCardModel> swipe) {
    final source = swipe.isEmpty
        ? _placeholderFloats()
        : [
            for (var i = 0; i < swipe.length && i < 3; i++)
              BergenFloatItem(
                id: 'p${swipe[i].productId}',
                title: swipe[i].productName,
                store: swipe[i].storeName,
                priceText: _kr(swipe[i].amount),
                reason: swipe[i].description.isEmpty
                    ? BergenCopy.reasonOffer
                    : swipe[i].description,
                kind: swipe[i].discountPercent > 0
                    ? BergenFloatKind.offer
                    : (i == 2 ? BergenFloatKind.rhythm : BergenFloatKind.fresh),
                icon: BergenFloatIcon.values[i % BergenFloatIcon.values.length],
                storeId: swipe[i].storeId,
                productId: swipe[i].productId,
                price: swipe[i].amount,
                photoUrl: swipe[i].productImage.isEmpty
                    ? null
                    : swipe[i].productImage,
                glow: swipe[i].discountPercent > 0,
                ring: i == 0,
              ),
          ];
    return [
      for (final f in source)
        if (!_hiddenFloats.contains(f.id)) f,
    ];
  }

  /// Popular products from the swipe feed. TODO(api): "popular tonight" list.
  List<BergenProductCard> _products(List<SwipeCardModel> swipe) {
    if (swipe.isEmpty) {
      return const [
        BergenProductCard(
          id: 0,
          name: 'Whopper meny',
          store: 'Burger King · Torgallmenningen',
          priceText: '139 kr',
          price: 139,
          imageAsset: BergenAssets.bkWhopper,
          wasPrice: '159 kr',
          offer: '-13%',
          hero: kBergenOrangeGradient,
        ),
        BergenProductCard(
          id: 0,
          name: 'Reker 1 kg',
          store: 'Torgboden',
          priceText: '149 kr',
          price: 149,
          wasPrice: '199 kr',
          offer: 'Tilbud',
        ),
        BergenProductCard(
          id: 0,
          name: 'Pad thai med kylling',
          store: 'Fyllingsdalen Wok',
          priceText: '189 kr',
          price: 189,
        ),
      ];
    }
    return [
      for (final p in swipe.take(8))
        BergenProductCard(
          id: p.productId,
          name: p.productName,
          store: p.storeName,
          priceText: _kr(p.amount),
          price: p.amount,
          storeId: p.storeId,
          imageUrl: p.productImage.isEmpty ? null : p.productImage,
          wasPrice: p.originalAmount > p.amount ? _kr(p.originalAmount) : null,
          offer: p.discountPercent > 0 ? '-${p.discountPercent}%' : null,
        ),
    ];
  }

  static String _kr(double v) =>
      '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)} kr';

  BergenStoreCard _storeFromList(StoreListItem s) => BergenStoreCard(
    id: s.storeId ?? 0,
    name: s.storeName ?? '',
    subtitle: (s.storeProducts ?? '').isNotEmpty
        ? s.storeProducts!
        : (s.offer ?? ''),
    open: (s.storeStatus ?? 0) == 1,
    bannerUrl: (s.storeBanner ?? '').isEmpty ? null : s.storeBanner,
    eta: (s.orderDeliveryTime ?? 0) > 0
        ? BergenCopy.minutes(s.orderDeliveryTime!)
        : null,
    rating: s.averageRatings == null ? null : '${s.averageRatings}',
    offer: (s.offer ?? '').isEmpty ? null : s.offer,
  );

  BergenStoreCard _storeFromExplore(HareStoreListItems s) => BergenStoreCard(
    id: s.storeId,
    name: s.storeName,
    subtitle: s.description,
    open: true,
    bannerUrl: s.storeImage.isEmpty ? null : s.storeImage,
    eta: s.deliveryTime > 0 ? BergenCopy.minutes(s.deliveryTime) : null,
    rating: s.storeRating > 0 ? s.storeRating.toStringAsFixed(1) : null,
  );

  /// Design placeholders when nothing has loaded. TODO(api).
  List<BergenStoreCard> _placeholderStores() => const [
    BergenStoreCard(
      id: 0,
      name: 'Burger King',
      subtitle: 'Torgallmenningen · Whopper-uke',
      open: true,
      bannerAsset: BergenAssets.bkBanner,
      logoAsset: BergenAssets.bkLogo,
      eta: '20–30 min',
      fee: '39 kr',
      rating: '4,6',
      offer: '2 for 1 Whopper',
      video: true,
    ),
    BergenStoreCard(
      id: 0,
      name: 'Casa Maria',
      subtitle: 'Steinovn på Bryggen',
      open: true,
      eta: '25–35 min',
      fee: '39 kr',
      rating: '4,8',
    ),
    BergenStoreCard(
      id: 0,
      name: 'Torgboden',
      subtitle: 'Fersk fisk fra Fisketorget',
      open: true,
      eta: '30–40 min',
      fee: 'Gratis',
      rating: '4,7',
      offer: 'Reker 149 kr',
    ),
  ];

  void _ensureStores(BergenCategory cat) {
    if (cat.id == 0) return;
    if (_storesByCat.containsKey(cat.id) || _storesLoading.contains(cat.id)) {
      return;
    }
    _storesLoading.add(cat.id);
    final seq = ++_storesRequestSeq;
    _storeRepo
        .fetch(cat.id)
        .then((list) {
          if (!mounted) return;
          setState(() {
            _storesLoading.remove(cat.id);
            _storesByCat[cat.id] = [for (final s in list) _storeFromList(s)];
          });
        })
        .catchError((Object e) {
          logd('BergenHome', 'stores for ${cat.id}: $e');
          if (!mounted) return;
          setState(() {
            _storesLoading.remove(cat.id);
            if (seq == _storesRequestSeq) _storesByCat[cat.id] = const [];
          });
        });
  }

  List<BergenStoreCard> _storesFor(
    BergenCategory cat,
    HareExplorePojo? explore,
  ) {
    final own = _storesByCat[cat.id];
    if (own != null && own.isNotEmpty) return own;
    final fallback = <BergenStoreCard>[
      if (explore != null) ...[
        for (final s in explore.lunchList) _storeFromExplore(s),
        for (final s in explore.fastList) _storeFromExplore(s),
      ],
    ];
    if (fallback.isNotEmpty) {
      final seen = <int>{};
      return [
        for (final s in fallback)
          if (seen.add(s.id)) s,
      ];
    }
    return _placeholderStores();
  }

  bool get _showSurprise {
    if (isGuestUser()) return false;
    final t = DateTime.now().hour;
    return (t >= 11 && t < 14) || (t >= 16 && t < 21);
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _openCategory(BergenCategory cat) {
    if (cat.id == 0) {
      _comingSoon();
      return;
    }
    setSelectedServiceInPref(cat.id, cat.name, cat.iconUrl ?? '');
    BergenRoutes.pushOr(
      context,
      '/bergen/kategori/${slugOf(cat.name)}',
      arguments: {'id': '${cat.id}', 'name': cat.name},
      orElse: () => openScreen(context, const DSHome()),
    );
  }

  void _openArk() {
    HapticFeedback.selectionClick();
    setState(() => _arkOpen = true);
  }

  void _closeArk() => setState(() => _arkOpen = false);

  Future<List<HjemArkProduct>> _loadPopulaert(int categoryId) async {
    final list = await OpsCustomerApi().populaert(categoryId);
    return [for (final j in list) HjemArkProduct.fromJson(j)];
  }

  void _openStore(BergenStoreCard s) {
    if (s.id == 0) {
      _comingSoon();
      return;
    }
    BergenRoutes.pushOr(
      context,
      '/bergen/butikk/${s.id}',
      arguments: {'name': s.name},
      orElse: () =>
          openScreen(context, StoreDetail(storeId: s.id, storeName: s.name)),
    );
  }

  void _openProduct(BergenProductCard p) {
    if (p.storeId == 0) {
      _comingSoon();
      return;
    }
    // The store page opens the product sheet for `product_id` (Phase 4).
    BergenRoutes.pushOr(
      context,
      '/bergen/butikk/${p.storeId}',
      arguments: {'name': p.store, 'product_id': '${p.id}'},
      orElse: () => openScreen(
        context,
        StoreDetail(storeId: p.storeId, storeName: p.store),
      ),
    );
  }

  Future<void> _addProduct(int storeId, int productId, String name) async {
    if (storeId == 0 || productId == 0) {
      _comingSoon();
      return;
    }
    if (!await showGuestLoginSheet(
      context,
      prompt: GuestLoginPrompt.checkout,
    )) {
      return;
    }
    HapticFeedback.selectionClick();
    await _bloc.addOrderCart(storeId, productId, 1);
    _syncCartBadge();
  }

  void _onFloatAdd(BergenFloatItem f) =>
      _addProduct(f.storeId, f.productId, f.title);

  void _onFloatSunk(BergenFloatItem f) {
    setState(() => _hiddenFloats.add(f.id));
    openSimpleSnackbar(BergenCopy.sunk);
  }

  void _onFloatNever(BergenFloatItem f) {
    setState(() => _hiddenFloats.add(f.id));
    openSimpleSnackbar(BergenCopy.aegilRemembers);
  }

  Future<void> _openAddressSheet() async {
    if (!await showGuestLoginSheet(context, prompt: GuestLoginPrompt.address)) {
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x520F1F2B),
      builder: (_) => _AddressSheet(bloc: _bloc),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final screenH = MediaQuery.sizeOf(context).height;
    final hour = DateTime.now().hour;
    final look = BergenWeatherLook.forHour(hour);

    return StreamBuilder<ApiResponse<HomeCatePojo>>(
      stream: _bloc.subjectHomeCat.stream,
      builder: (context, homeSnap) {
        if (homeSnap.data?.status == Status.completed) {
          _lastHome = homeSnap.data!.data;
        }
        final home = _lastHome;
        final categories = _categories(home);
        final catIndex = _catIndex.clamp(0, categories.length - 1);
        final focused = categories[catIndex];
        _ensureStores(focused);

        return StreamBuilder<ApiResponse<HareSwipeListPojo>>(
          stream: _bloc.subjectHareSwipe.stream,
          builder: (context, swipeSnap) {
            if (swipeSnap.data?.status == Status.completed) {
              _lastSwipe = swipeSnap.data!.data;
            }
            final swipe = _lastSwipe?.swipeList ?? const <SwipeCardModel>[];
            return StreamBuilder<ApiResponse<HareExplorePojo>>(
              stream: _bloc.subjectHareExplore.stream,
              builder: (context, exploreSnap) {
                if (exploreSnap.data?.status == Status.completed) {
                  _lastExplore = exploreSnap.data!.data;
                }
                final explore = _lastExplore;
                final stores = _storesFor(focused, explore);
                final products = _products(swipe);
                final floats = _floats(swipe);

                final heroOpacity = (1 - ((_k / s) - 120).clamp(0.0, 92.0) / 92)
                    .clamp(0.0, 1.0);
                final sheetTop = safeTop + (_kSheetTop + _dragY) * s - _k;
                final heroH =
                    (kBergenHeroHeight + (_dragY > 0 ? _dragY : 0)) * s;

                return OnbTimeline(
                  durationMs: 340,
                  builder: (context, t, child) {
                    // skjermInn .34s cubic-bezier(.2,.9,.3,1)
                    final e = const Cubic(
                      .2,
                      .9,
                      .3,
                      1,
                    ).transform(onbP(t, 0, 340));
                    return Opacity(
                      opacity: e,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translateByDouble(0, (1 - e) * 10 * s, 0, 1)
                          ..scaleByDouble(
                            .985 + .015 * e,
                            .985 + .015 * e,
                            1,
                            1,
                          ),
                        child: child,
                      ),
                    );
                  },
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: kBergenScreenGradient,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // radial-gradient(80% 50% at 14% 0%, rgba(255,255,255,.22) …)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: bergenRadial(
                              center: const Offset(.14, 0),
                              radii: const Offset(.8, .5),
                              colors: const [
                                Color(0x38FFFFFF),
                                Color(0x00FFFFFF),
                              ],
                              stops: const [0, .6],
                            ),
                          ),
                        ),

                        // ── Hero ───────────────────────────────────────
                        // Clipped at the status bar: the design's frame
                        // starts at y=0, ours below the safe area.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: safeTop,
                          bottom: 0,
                          child: ClipRect(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: _kHeroTop * s - _k,
                                  height: heroH,
                                  child: IgnorePointer(
                                    ignoring: heroOpacity < .05,
                                    child: Opacity(
                                      opacity: heroOpacity,
                                      child:
                                          StreamBuilder<
                                            ApiResponse<HomeTrackOrderPojo>
                                          >(
                                            stream:
                                                _bloc.subjectTrackOrder.stream,
                                            builder: (context, trackSnap) {
                                              final track =
                                                  trackSnap.data?.status ==
                                                      Status.completed
                                                  ? trackSnap.data!.data
                                                  : null;
                                              final orderId =
                                                  track?.orderId ?? 0;
                                              double? boat;
                                              if (orderId != 0) {
                                                final remaining =
                                                    (track!.remainingTime)
                                                        .toDouble();
                                                boat = (1 - remaining / 45)
                                                    .clamp(.06, .94);
                                              }
                                              return BergenHero(
                                                look: look,
                                                greeting: BergenCopy.greeting(
                                                  hour,
                                                  _firstName,
                                                ),
                                                floats: floats,
                                                onFloatAdd: _onFloatAdd,
                                                onFloatSunk: _onFloatSunk,
                                                onFloatNever: _onFloatNever,
                                                onFjordfiske: _openFjordfiske,
                                                onBag: _openAutomat,
                                                onFloatTap: _onFloatTap,
                                                onGreetingTap: _openAegil,
                                                showLantern:
                                                    hour >= 16 || hour < 8,
                                                boat: boat,
                                                onBoat: orderId == 0
                                                    ? null
                                                    : () => BergenRoutes.pushOr(
                                                        context,
                                                        '/bergen/sporing/$orderId',
                                                        orElse: () =>
                                                            openScreen(
                                                              context,
                                                              TrackOrder(
                                                                orderId:
                                                                    orderId,
                                                              ),
                                                            ),
                                                      ),
                                                playIntro: _playIntro,
                                              );
                                            },
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Sheet (ark) ────────────────────────────────
                        AnimatedPositioned(
                          duration: Duration(milliseconds: _dragging ? 0 : 340),
                          curve: const Cubic(.2, .9, .3, 1),
                          left: 0,
                          right: 0,
                          top: sheetTop,
                          height:
                              screenH -
                              (safeTop + _kSheetTop * s) +
                              _kSheetSlide * s,
                          child: _Sheet(
                            controller: _scroll,
                            child: _sheetBody(
                              context,
                              categories: categories,
                              catIndex: catIndex,
                              focused: focused,
                              stores: stores,
                              products: products,
                              storesLoading: _storesLoading.contains(
                                focused.id,
                              ),
                            ),
                          ),
                        ),

                        // ── Header row ─────────────────────────────────
                        Positioned(
                          left: 16 * s,
                          right: 16 * s,
                          top: safeTop + _kHeaderTop * s,
                          height: 56 * s,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: StreamBuilder<AddressListItem?>(
                                  stream: _bloc.deliveryAddress,
                                  builder: (context, snap) {
                                    final raw = snap.data?.address ?? '';
                                    final short = raw.isEmpty
                                        ? BergenCopy.chooseAddress
                                        : raw.split(',').first.trim();
                                    return _AddressPill(
                                      text: short,
                                      onTap: _openAddressSheet,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 10 * s),
                              _Bell(
                                count: home?.totalUnreadMessage ?? 0,
                                onTap: () => BergenRoutes.pushOr(
                                  context,
                                  '/bergen/meg/varsler',
                                  orElse: () => openScreen(
                                    context,
                                    const Notifications(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Ark (design L7146): both «Se alle» ──────────
                        if (_arkOpen) ...[
                          // A tap above the sheet closes it too.
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closeArk,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: safeTop + 96 * s,
                            bottom: 0,
                            child: PopScope(
                              canPop: false,
                              onPopInvokedWithResult: (didPop, _) {
                                if (!didPop) _closeArk();
                              },
                              child: HjemArk(
                                categories: categories,
                                index: catIndex,
                                stores: stores,
                                openCount: stores.where((x) => x.open).length,
                                loadProducts: _loadPopulaert,
                                onIndexChanged: (i) =>
                                    setState(() => _catIndex = i),
                                onClose: _closeArk,
                                onMore: () {
                                  _closeArk();
                                  _toExplore();
                                },
                                onOpenStore: _openStore,
                                onOpenProduct: (p) => _openProduct(
                                  BergenProductCard(
                                    id: p.id,
                                    name: p.name,
                                    store: p.storeName,
                                    priceText: p.priceText,
                                    price: p.priceOre / 100,
                                    storeId: p.storeId,
                                  ),
                                ),
                                onAdd: (p) =>
                                    _addProduct(p.storeId, p.id, p.name),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _sheetBody(
    BuildContext context, {
    required List<BergenCategory> categories,
    required int catIndex,
    required BergenCategory focused,
    required List<BergenStoreCard> stores,
    required List<BergenProductCard> products,
    required bool storesLoading,
  }) {
    final s = context.bs;
    final district = focused.look?.district ?? BergenCopy.bergenhus;
    final openCount = stores.where((e) => e.open).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PullHandle(
                dragging: _dragging,
                dragY: _dragY,
                onDragStart: _dragStart,
                onDragUpdate: _dragUpdate,
                onDragEnd: _dragEnd,
                onTap: _handleTap,
              ),
              SizedBox(height: 6 * s),
              // Seam (AGIL-CONTRACT §2.2): the cold-start card, when agil-3
              // has something to say.
              if (mensDuVarBorteCard(context) case final borte?) ...[
                borte,
                SizedBox(height: 10 * s),
              ],
              BergenCategoryRad(
                categories: categories,
                index: catIndex,
                onIndexChanged: (i) => setState(() => _catIndex = i),
                onOpen: _openCategory,
              ),
              SizedBox(height: 10 * s),
              Row(
                children: [
                  // Seam: the Points card → `kPoengRoute`.
                  GestureDetector(
                    key: const Key('hjem-poeng-entry'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => BergenRoutes.push(context, kPoengRoute),
                    child: poengEntryCard(context),
                  ),
                  SizedBox(width: 8 * s),
                  // Seam: Ægil-relevanskort, only when Ægil has finds.
                  if (aegilFindCount() > 0)
                    Expanded(
                      child: _AegilFindsCard(
                        count: aegilFindCount(),
                        onTap: () => showAegilBrett(context),
                      ),
                    ),
                ],
              ),
              if (_showSurprise) ...[
                SizedBox(height: 12 * s),
                // "Sikre en" → Poseautomaten (Phase 4).
                BergenSurpriseCard(onTap: _openAutomat),
              ],
              BergenSectionHeader(
                title: BergenCopy.storesIn(district),
                pill: openCount > 0
                    ? BergenCopy.openNow(openCount)
                    : BergenCopy.bergensk,
                pillDot: BergenColors.mint,
                dots: BergenCategoryDots(
                  count: categories.length,
                  index: catIndex,
                ),
                onSeeAll: _openArk,
                topPad: 16,
              ),
              SizedBox(height: 10 * s),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: const Cubic(.2, .9, .3, 1),
                child: BergenStoreRail(
                  key: ValueKey('stores-${focused.id}-${stores.length}'),
                  stores: stores,
                  onOpen: _openStore,
                ),
              ),
              SizedBox(height: 14 * s),
              BergenExploreCard(
                onTap: _toExplore,
                line: BergenCopy.exploreLine,
              ),
              BergenSectionHeader(
                title: BergenCopy.popularTonight,
                pill: BergenCopy.bergenhus,
                pillDot: BergenColors.gold,
                pulse: false,
                onSeeAll: _openArk,
                topPad: 18,
              ),
              SizedBox(height: 10 * s),
              BergenProductRail(
                products: products,
                onOpen: _openProduct,
                onAdd: (p) => _addProduct(p.storeId, p.id, p.name),
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * s),
        // Under kaien: the first card is a real find when the suggestions
        // tray has one (guarded read); the design's sample otherwise.
        BergenUnderQuay(
          revealed: _kaien,
          offer: _underKaien,
          onOffer: _onUnderKaienOffer,
          onBag: _openAutomat,
          onShipping: _comingSoon,
        ),
        SizedBox(height: bergenNavReserve(context) + 8 * s),
      ],
    );
  }
}

// ── Ægil-relevanskort (design ≈L2452) ─────────────────────────────────────

class _AegilFindsCard extends StatelessWidget {
  const _AegilFindsCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressScale: .985,
      child: Container(
        key: const Key('hjem-aegil-relevans'),
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(18 * s),
          border: Border.all(color: const Color(0x2EFFFFFF)),
        ),
        child: Row(
          children: [
            Image.asset(BergenAssets.aegilPopup, width: 32 * s, height: 32 * s),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BergenCopy.aegilFinds(count),
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    BergenCopy.aegilFindsLine,
                    style: bText(
                      context,
                      10.5,
                      weight: FontWeight.w600,
                      color: BergenColors.skyText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18 * s,
              color: const Color(0x8CFFFFFF),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet shell ───────────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  const _Sheet({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = Radius.circular(_kSheetRadius * s);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: r, topRight: r),
        gradient: kBergenScreenGradient,
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC04121A),
            offset: Offset(0, -24),
            blurRadius: 50,
            spreadRadius: -18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(topLeft: r, topRight: r),
        child: Stack(
          children: [
            // radial highlights + bottom shade
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    bergenRadial(
                      center: const Offset(.14, 0),
                      radii: const Offset(.8, .6),
                      colors: const [Color(0x47FFFFFF), Color(0x00FFFFFF)],
                      stops: const [0, .6],
                    ),
                    bergenRadial(
                      center: const Offset(.5, 1),
                      radii: const Offset(.9, .4),
                      colors: const [Color(0x8006141C), Color(0x0006141C)],
                      stops: const [0, .6],
                    ),
                  ],
                ),
              ),
            ),
            bergenInsetTop(radius: _kSheetRadius * s, alpha: .4),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: r, topRight: r),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
              ),
            ),
            SingleChildScrollView(
              controller: controller,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pull handle ───────────────────────────────────────────────────────────

class _PullHandle extends StatelessWidget {
  const _PullHandle({
    required this.dragging,
    required this.dragY,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  final bool dragging;
  final double dragY;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final wide = dragging && dragY.abs() > 60; // hbW 76 : 44
    final armed = dragging && dragY > 110;
    final up = dragging && dragY < -20;
    final color = armed ? BergenColors.mint : const Color(0xE0FFFFFF);
    final text = up
        ? BergenCopy.allStores
        : armed
        ? BergenCopy.releaseToOpen
        : (dragging && dragY > 24)
        ? BergenCopy.pullMore
        : BergenCopy.pullToAsk;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      onVerticalDragCancel: () => onDragEnd(DragEndDetails()),
      child: Padding(
        padding: EdgeInsets.only(top: 10 * s),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: (wide ? 76 : 44) * s,
              height: 5 * s,
              decoration: BoxDecoration(
                color: const Color(0x57FFFFFF),
                borderRadius: BorderRadius.circular(3 * s),
                boxShadow: const [
                  BoxShadow(color: Color(0x26FFFFFF), blurRadius: 8),
                ],
              ),
            ),
            SizedBox(height: 5 * s),
            AnimatedScale(
              scale: armed ? 1.09 : 1,
              duration: const Duration(milliseconds: 220),
              curve: const Cubic(.3, 1.3, .5, 1),
              child: SizedBox(
                height: 18 * s,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniAegil(size: 16 * s),
                    SizedBox(width: 6 * s),
                    Opacity(
                      opacity: .72,
                      child: Text(
                        text,
                        style: bText(
                          context,
                          10,
                          weight: FontWeight.w800,
                          letterSpacingEm: .02,
                          color: color,
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    AnimatedRotation(
                      turns: up ? .5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Opacity(
                        opacity: .6,
                        child: CustomPaint(
                          size: Size(9 * s, 9 * s),
                          painter: _ChevronPainter(color: color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAegil extends StatelessWidget {
  const _MiniAegil({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(0, -.4),
        colors: [BergenColors.teal1, BergenColors.teal3],
        stops: [0, .8],
      ),
      boxShadow: [BoxShadow(color: Color(0xCCF2C14E), spreadRadius: 1)],
    ),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(0, size * .06),
        child: Image.asset(
          BergenAssets.aegilFront,
          width: size,
          fit: BoxFit.fitWidth,
        ),
      ),
    ),
  );
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(6 * k, 10 * k)
        ..lineTo(12 * k, 16 * k)
        ..lineTo(18 * k, 10 * k),
      p,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

// ── Header widgets ────────────────────────────────────────────────────────

class _AddressPill extends StatelessWidget {
  const _AddressPill({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 1,
      pressScale: .97,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 270 * s),
        child: Container(
          height: 44 * s,
          padding: EdgeInsets.symmetric(horizontal: 14 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16 * s),
            gradient: kBergenChipGradient,
            boxShadow: bergenChipShadow(context),
          ),
          child: Stack(
            children: [
              bergenInsetTop(radius: 16 * s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: Size(16 * s, 16 * s),
                    painter: const _PinPainter(),
                  ),
                  SizedBox(width: 8 * s),
                  Text(
                    BergenCopy.deliverTo,
                    style: bText(context, 11.5, color: BergenColors.skyText),
                  ),
                  SizedBox(width: 8 * s),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bDisplay(context, 17, letterSpacingEm: -.02),
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

class _PinPainter extends CustomPainter {
  const _PinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = BergenColors.skyText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // M12 21.5S5.5 15.5 5.5 10.5a6.5 6.5 0 1 1 13 0c0 5-6.5 11-6.5 11z
    final path = Path()
      ..moveTo(12 * k, 21.5 * k)
      ..cubicTo(12 * k, 21.5 * k, 5.5 * k, 15.5 * k, 5.5 * k, 10.5 * k)
      ..arcToPoint(
        Offset(18.5 * k, 10.5 * k),
        radius: Radius.circular(6.5 * k),
        largeArc: true,
      )
      ..cubicTo(18.5 * k, 15.5 * k, 12 * k, 21.5 * k, 12 * k, 21.5 * k)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(12 * k, 10.5 * k), 2.3 * k, p);
  }

  @override
  bool shouldRepaint(_PinPainter old) => false;
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final dot = count > 0 && count < 3; // vsPrikk
    final number = count >= 3; // vsTall
    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .93,
      child: SizedBox(
        width: 44 * s,
        height: 44 * s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44 * s,
              height: 44 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: kBergenChipGradient,
                boxShadow: bergenChipShadow(context),
              ),
              child: Stack(
                children: [
                  bergenInsetTop(radius: 22 * s),
                  Center(
                    child: CustomPaint(
                      size: Size(21 * s, 21 * s),
                      painter: const _BellPainter(),
                    ),
                  ),
                ],
              ),
            ),
            if (dot)
              Positioned(
                top: 6 * s,
                right: 7 * s,
                child: Container(
                  width: 8 * s,
                  height: 8 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BergenColors.gold,
                    border: Border.all(color: BergenColors.teal3, width: 2 * s),
                  ),
                ),
              ),
            if (number)
              Positioned(
                top: -4 * s,
                right: -4 * s,
                child: Container(
                  constraints: BoxConstraints(minWidth: 20 * s),
                  height: 20 * s,
                  padding: EdgeInsets.symmetric(horizontal: 5 * s),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BergenColors.ink,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2 * s),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: bText(context, 11, weight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  const _BellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // M18 8.6a6 6 0 1 0-12 0c0 5.9-2.2 7.4-2.2 7.4h16.4S18 14.5 18 8.6z
    final body = Path()
      ..moveTo(18 * k, 8.6 * k)
      ..arcToPoint(
        Offset(6 * k, 8.6 * k),
        radius: Radius.circular(6 * k),
        largeArc: true,
        clockwise: false,
      )
      ..cubicTo(6 * k, 14.5 * k, 3.8 * k, 16 * k, 3.8 * k, 16 * k)
      ..lineTo(20.2 * k, 16 * k)
      ..cubicTo(20.2 * k, 16 * k, 18 * k, 14.5 * k, 18 * k, 8.6 * k)
      ..close();
    canvas.drawPath(body, p);
    // M10.3 19.6a2 2 0 0 0 3.4 0
    canvas.drawPath(
      Path()
        ..moveTo(10.3 * k, 19.6 * k)
        ..arcToPoint(
          Offset(13.7 * k, 19.6 * k),
          radius: Radius.circular(2 * k),
          clockwise: false,
        ),
      p,
    );
  }

  @override
  bool shouldRepaint(_BellPainter old) => false;
}

// ── Address sheet (`sheetAdresse`) ────────────────────────────────────────

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({required this.bloc});
  final HomeBloc bloc;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  bool _locating = false;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return OnbTimeline(
      durationMs: 380,
      builder: (context, t, child) {
        // arkOpp .38s cubic-bezier(.2,.9,.3,1)
        final e = const Cubic(.2, .9, .3, 1).transform(onbP(t, 0, 380));
        return Transform.translate(
          offset: Offset(0, (1 - e) * 26 * s),
          child: Opacity(opacity: .6 + .4 * e, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 22 * s + bottom),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28 * s)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)],
            stops: [0, .5, 1],
          ),
          border: const Border(top: BorderSide(color: Color(0x66FFFFFF))),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8C0F1F2B),
              offset: Offset(0, -24),
              blurRadius: 50,
              spreadRadius: -20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Container(
                  margin: EdgeInsets.only(top: 10 * s),
                  width: 44 * s,
                  height: 5 * s,
                  decoration: BoxDecoration(
                    color: const Color(0x59FFFFFF),
                    borderRadius: BorderRadius.circular(3 * s),
                  ),
                ),
              ),
            ),
            SizedBox(height: 14 * s),
            Text(
              BergenCopy.addressSheetTitle,
              style: bDisplay(context, 18, letterSpacingEm: -.02),
            ),
            SizedBox(height: 2 * s),
            Text(
              BergenCopy.addressSheetLine,
              style: bText(
                context,
                11.5,
                weight: FontWeight.w600,
                color: const Color(0x9EFFFFFF),
              ),
            ),
            SizedBox(height: 12 * s),
            StreamBuilder<List<AddressListItem>?>(
              stream: widget.bloc.addressList,
              builder: (context, listSnap) {
                final list = listSnap.data ?? const <AddressListItem>[];
                return StreamBuilder<AddressListItem?>(
                  stream: widget.bloc.deliveryAddress,
                  builder: (context, selSnap) {
                    final selectedId =
                        selSnap.data?.addressId ??
                        prefGetInt(prefNewDeliveryAddressId);
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .5,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (list.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8 * s),
                              child: Text(
                                BergenCopy.noAddresses,
                                textAlign: TextAlign.center,
                                style: bText(
                                  context,
                                  12,
                                  weight: FontWeight.w600,
                                  color: const Color(0x9EFFFFFF),
                                ),
                              ),
                            ),
                          for (var i = 0; i < list.length; i++)
                            Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : 8 * s),
                              child: _AddressRow(
                                item: list[i],
                                selected: list[i].addressId == selectedId,
                                onTap: () {
                                  widget.bloc.updateDeliveryAddress(
                                    addressId: list[i].addressId,
                                  );
                                  Navigator.pop(context);
                                },
                                onDelete: list.length > 1
                                    ? () => widget.bloc.deleteAddress(
                                        list[i].addressId,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 8 * s),
            _AddressAction(
              icon: Icons.my_location_rounded,
              label: BergenCopy.currentLocation,
              busy: _locating,
              onTap: () {
                if (_locating) return;
                setState(() => _locating = true);
                widget.bloc.getCurrentLocation();
              },
            ),
            SizedBox(height: 8 * s),
            _AddressAction(
              icon: Icons.add_rounded,
              label: BergenCopy.newAddress,
              onTap: () {
                Navigator.pop(context);
                openScreen(context, const AddLocation());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.item,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  final AddressListItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final type = item.type.trim();
    final label = type.isEmpty
        ? item.address
        : '${type[0].toUpperCase()}${type.substring(1)} · ${item.address.split(',').first.trim()}';
    final sub = [
      if (item.address.contains(','))
        item.address.split(',').skip(1).join(',').trim(),
      if (item.flatNo.isNotEmpty) item.flatNo,
      if (item.landmark.isNotEmpty) item.landmark,
    ].join(' · ');
    final IconData icon = type.toLowerCase() == 'home'
        ? Icons.home_outlined
        : type.toLowerCase() == 'work' || type.toLowerCase() == 'office'
        ? Icons.work_outline_rounded
        : Icons.place_outlined;

    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              selected ? const Color(0x2E5CE0B8) : const Color(0x1FFFFFFF),
              const Color(0x0DFFFFFF),
            ],
          ),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x4D5CE0B8), blurRadius: 18)]
              : const [],
        ),
        child: Row(
          children: [
            Container(
              width: 36 * s,
              height: 36 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * s),
                color: const Color(0x1FFFFFFF),
                border: Border.all(color: const Color(0x2EFFFFFF)),
              ),
              child: Icon(icon, size: 17 * s, color: BergenColors.mint),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bText(context, 13, weight: FontWeight.w800),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bText(
                        context,
                        10.5,
                        weight: FontWeight.w600,
                        color: const Color(0x9EFFFFFF),
                      ),
                    ),
                ],
              ),
            ),
            if (onDelete != null) ...[
              SizedBox(width: 6 * s),
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(4 * s),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16 * s,
                    color: const Color(0x8CFFFFFF),
                  ),
                ),
              ),
            ],
            SizedBox(width: 6 * s),
            Container(
              width: 20 * s,
              height: 20 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? BergenColors.mint : const Color(0x66FFFFFF),
                  width: 2 * s,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 10 * s,
                height: 10 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? BergenColors.mint : Colors.transparent,
                  boxShadow: selected
                      ? const [
                          BoxShadow(color: BergenColors.mint, blurRadius: 8),
                        ]
                      : const [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressAction extends StatelessWidget {
  const _AddressAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .985,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x4DFFFFFF), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36 * s,
              height: 36 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * s),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF2884E), Color(0xFFE0662C)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xE678320A),
                    offset: Offset(0, 6),
                    blurRadius: 12,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: busy
                  ? Padding(
                      padding: EdgeInsets.all(10 * s),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 18 * s, color: Colors.white),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(
                label,
                style: bText(context, 13, weight: FontWeight.w800),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18 * s,
              color: const Color(0x8CFFFFFF),
            ),
          ],
        ),
      ),
    );
  }
}
