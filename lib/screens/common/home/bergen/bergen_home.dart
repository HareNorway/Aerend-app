import 'dart:async';
import '../../../../data/ops/tracking_models.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../networking/api_response.dart';
import '../../../../utils/guest_auth_helper.dart';
import '../../../../utils/utils.dart';
import '../../../deliveryService/home/ds_home.dart';
import '../../../deliveryService/home/ds_home_store_list_pojo.dart';
import '../../../deliveryService/storeDetail/store_detail.dart';
import '../../../../networking/ops/ops_customer_api.dart';
import '../../../../networking/ops/ops_butikk_api.dart';
import '../../../../data/ops/butikk_models.dart';
import '../../../bergen/sporing/hjelp_sheet.dart';
import '../../../bergen/utforsk/feed_tab.dart' show utfPoseHentes;
import '../../../bergen/utforsk/utforsk_screen.dart';
import '../../../bergen/kasse/kjop_sekvens.dart' show KjopBekreftetScreen;
import '../../../bergen/kit/drape_route.dart' show DrapePek;
import '../../../bergen/aegil/aegil_entry.dart';
import '../../../bergen/hjem/hjem_harness.dart';
import '../../../bergen/sok/sok_screen.dart';
import '../../../bergen/hjem/hjem_header.dart';
import '../../../bergen/hjem/hjem_hero.dart';
import '../../auth/launch/lf_css.dart' show LfFrame, lfFlow;
import '../../../bergen/hjem/hjem_hjul.dart';
import '../../../bergen/hjem/hjem_kort.dart';
import '../../../bergen/hurtig/hurtig_brain.dart';
import '../../../bergen/hurtig/hurtig_data.dart';
import '../../../bergen/hurtig/hurtig_screen.dart';
import '../../../bergen/hjem/hjem_kaien.dart';
import '../../../bergen/hjem/hjem_tilbud.dart';
import '../../../bergen/hjem/hjem_vann.dart';
import '../../../bergen/hjem/hjem_vindu.dart';
import '../../../bergen/kit/live_aerend.dart';
import '../../../bergen/hjem/hjem_snart.dart';
import '../../../bergen/meg/bestill_igjen.dart';
import '../../../../networking/ops/ops_kasse_api.dart';
import '../../../bergen/aegil/brett_entry.dart';
import '../../../bergen/kit/bergen_routes.dart';
import '../../../bergen/meg/a3_services.dart';
import '../../../bergen/meg/borte_entry.dart';
import '../../../../data/aegil/aegil_app_models.dart' show AwayItem;
import '../../../bergen/meg/konto_screen.dart' show kPrefA3Rolig;
import '../../../bergen/poeng/napp_entry.dart';
import '../../../snurre/snurre_chat_screen.dart';
import '../../auth/onboarding_kit.dart';
import '../../homeMainV1/home_main_v1.dart';
import '../../manageAddress/manage_address_dl.dart';
import '../../notifications/notifications.dart';
import '../../swipeAerend/swipe_aerend_dl.dart';
import '../home_bloc.dart';
import '../home_dl.dart';
import '../home_post_order_feedback.dart';
import '../../../bergen/adresse/adr_ark.dart' show AdrArkProve, visAdresseArk;
import 'bergen_adr_kilde.dart';
import 'bergen_cards.dart';
import 'bergen_category_rad.dart';
import 'bergen_copy.dart';
import 'bergen_floats.dart';
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
  StreamSubscription<ApiResponse<HomeTrackOrderPojo>>? _trackSub;

  /// `arkScroll` — clamped scroll offset that drives the parallax.
  double _k = 0;

  /// `kaien` — Under kaien revealed.
  bool _kaien = false;

  /// `dragY` / `drar` — pull handle state.
  double _dragY = 0;
  bool _dragging = false;

  /// `sone: 'vindu'` — the window over the water (a tap on the handle).
  bool _vindu = false;

  /// True while the sheet and hero glide between the two zones.
  bool _soneBytt = false;
  double _stripeDy = 0;
  double _dragStartDy = 0;
  bool _armed = false;
  DateTime _lock = DateTime.fromMillisecondsSinceEpoch(0);

  /// Focused category (`i`) and the per-category store cache.
  int _catIndex = 0;

  /// The wheel's focused slot (`i`, 0–4) and the coming-soon slots the user
  /// asked to hear about (`snartVarsle`).
  int _hjulI = 0;
  Set<int> _snartVarsle = {};
  final Map<int, List<BergenStoreCard>> _storesByCat = {};

  /// «Populært i kveld» per category id when the swipe feed is empty
  /// (`ops/products?kind=populaert`, the Ark's list), and those asked for.
  final Map<int, List<BergenProductCard>> _populaertByCat = {};
  final Set<int> _populaertSpurt = {};

  /// «Kommer snart» per wheel slot from `catalog/launch-categories` (backend
  /// plan Step 8); null until it answers (the wheel then keeps 1–4 coming).
  Map<int, HjemSnartInfo>? _snart;

  /// «N åpne nå» per category id from the category pulse (Step 8), and the
  /// categories already asked for.
  final Map<int, int> _aapneNa = {};
  final Set<int> _pulsSpurt = {};

  /// Under kaien's FRAKT card: the nearest open store with a free-delivery
  /// threshold (`ops/customer/free-delivery`, Step 8); null hides the card.
  Map<String, dynamic>? _frakt;

  /// `GET /api/catalog/home` (Step 12): the hero offers and the FRAKT card the
  /// admin put on Hjem («Tilbud og fremheving»). Null until loaded / offline.
  Map<String, dynamic>? _katalog;

  /// The customer's personal / mystery offer (`offers/mine`, Step 12).
  HjemPersonlig? _personlig;

  /// Vindu «Bestill igjen»: this customer's latest order per shop, newest
  /// first, at most two (`ops.customer.orders`, Step 8).
  List<Map<String, dynamic>> _igjen = const [];

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

  late final BergenAdrKilde _adrKilde;
  StreamSubscription<AddressListItem?>? _adrSub;
  String? _hodeEta;

  @override
  void initState() {
    super.initState();
    DrapePek.lytt();
    _playIntro = !_introPlayed;
    _introPlayed = true;
    _bloc = HomeBloc(context, this, false);
    _adrKilde = BergenAdrKilde(_bloc);
    _adrSub = _bloc.deliveryAddress.listen(_hentHodeEta);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    _lastSnart();
    _lastPose();
    _lastFrakt();
    _lastKatalog();
    _lastPersonlig();
    _lastIgjen();
    // Live-ærend: the shell's pill follows the order under way.
    _trackSub = _bloc.subjectTrackOrder.stream.listen((r) {
      if (r.status != Status.completed) return;
      final t = r.data;
      final id = t?.orderId ?? 0;
      if (id == 0) {
        hjemLiveOrdre.value = null;
        return;
      }
      final min = t!.remainingTime;
      // The stage, the time to the door and the mode come from
      // `ops.customer.tracking`; until it answers, the minutes left from
      // `home-track-order` carry the pill.
      // A pill for another order (an earlier one, or another user's) is
      // replaced at once.
      if (hjemLiveOrdre.value?.orderId != id) {
        hjemLiveOrdre.value = (orderId: id, data: HjemLiveData(stadie: min <= 0 ? 3 : (min <= 20 ? 2 : 1), restSek: min * 60));
      }
      OpsCustomerApi().tracking(id).then((json) {
        // Late answers for an order no longer shown (logout, a new order)
        // are dropped.
        if (!mounted || hjemLiveOrdre.value?.orderId != id) return;
        final tr = OpsTracking.fromJson(json);
        final end = tr.promisedEnd;
        final rest = end == null ? min * 60 : end.difference(DateTime.now()).inSeconds;
        hjemLiveOrdre.value = (orderId: id, data: HjemLiveData(stadie: tr.stage, restSek: rest < 0 ? 0 : rest, henting: tr.isPickup));
      }).catchError((_) {});
    });
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
    // Hurtigbestilling's entry line: the habit of the day, loaded once.
    HurtigKilde.load();
    if (kDebugMode) {
      HjemHarness.load().then((_) {
        if (mounted) setState(() {});
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          final y = HjemHarness.scroll;
          if (y != null && _scroll.hasClients) {
            _scroll.jumpTo(y.clamp(0.0, _scroll.position.maxScrollExtent));
          }
          if (HjemHarness.hjul case final h?) setState(() => _hjulI = h);
          if (HjemHarness.vindu) _settVindu(true);
          final fane = HjemHarness.fane;
          if (fane != null) {
            debugPrint('HJEM_FANE');
            context.findAncestorStateOfType<HomeMainV1State>()?.switchToTab(
              fane,
            );
          }
          if (HjemHarness.borte) {
            // ignore: invalid_use_of_visible_for_testing_member
            setMensDuVarBorteForTest(const [
              AwayItem(
                id: 1,
                text: 'Ægil la 4 ting i kurven mandag (312 kr)',
                action: 'basket.add',
                undoable: true,
              ),
              AwayItem(
                id: 2,
                text: 'Fant reker 30 kr billigere hos Torgboden',
                action: 'price.watch',
              ),
              AwayItem(
                id: 3,
                text: 'Sandviken Bakeri åpnet i nabolaget',
                action: 'store.new',
              ),
            ]);
            setState(() {});
          }
          if (HjemHarness.adresse case final a?) {
            AdrArkProve.sok = HjemHarness.adrSok;
            AdrArkProve.dor = HjemHarness.adrDor;
            AdrArkProve.velg = HjemHarness.adrVelg;
            _openAddressSheet(ny: a == 'ny');
          }
          if (HjemHarness.sok case final q?) {
            if (HjemHarness.sokNylig case final l?) {
              SokScreen.harnessNylig(l);
            }
            _shell?.openSearchTab(keyword: q);
            if (HjemHarness.sokFokus) {
              Future.delayed(const Duration(milliseconds: 400), () {
                BergenBottomNav.focusSearch.value++;
              });
            }
          }
          if (HjemHarness.betalt case final id?) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => KjopBekreftetScreen(orderId: id)));
          }
          if (HjemHarness.hurtig) {
            BergenRoutes.push<dynamic>(context, '/bergen/hurtig');
          }
          if (HjemHarness.aegil != null) {
            BergenRoutes.push<dynamic>(context, kAegilRoute);
          }
          if (HjemHarness.rute case final r?) {
            final arg = HjemHarness.ruteArg;
            if (r == '/bergen/kundeservice' && arg is Map && arg['vis'] != null) {
              // The Hjelp sheet sits over Hjem, as Meg opens it.
              HjelpScreen.apne(context, initial: arg['vis'] == 'chat' ? HjelpState.chat : HjelpState.hub);
            } else {
              BergenRoutes.push<dynamic>(context, r, arguments: arg);
            }
          }
          if (HjemHarness.sporing case final id?) {
            BergenRoutes.push<dynamic>(context, '/bergen/sporing/$id', arguments: {if (HjemHarness.sporingFersk) 'fersk': '1'});
          }
          if (HjemHarness.levert case final id?) {
            BergenRoutes.push<dynamic>(context, '/bergen/levert/$id', arguments: {if (HjemHarness.levertArk case final a?) 'ark': a});
          }
          if (HjemHarness.butikk case final id?) {
            BergenRoutes.push(
              context,
              '/bergen/butikk/$id',
              arguments: {
                if (HjemHarness.butikkProdukt case final p?) 'product_id': '$p',
                if (HjemHarness.butikkKat case final k?) 'category': k,
              },
            );
          }
          if (HjemHarness.kat case final k?) {
            if (_sisteSlots[k] case final c?) {
              _openCategory(c, fane: HjemHarness.katFane);
            }
          }
          final k = HjemHarness.snart;
          if (k != null) {
            setState(() => _hjulI = k);
            _openSnart(k);
          }
        });
      });
    }
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
    _trackSub?.cancel();
    _adrSub?.cancel();
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

  /// Tonight's bags (`GET /api/ops/products?kind=pose`) for the
  /// Forundringspose card: the first bag, its shop's hours, and the count.
  List<Map<String, dynamic>> _poser = const [];
  BergenStoreInfo? _poseButikk;

  Future<void> _lastPose() async {
    final bags = await OpsCustomerApi().poser();
    if (!mounted || bags.isEmpty) return;
    setState(() => _poser = bags);
    final id = (bags.first['store_id'] as num?)?.toInt() ?? 0;
    if (id == 0) return;
    final info = await OpsButikkApi().store(id);
    if (mounted && info != null) setState(() => _poseButikk = info);
  }

  /// `scenePose` / `poseFn`: Utforsk on the Forundringspose segment.
  void _openPose() {
    final shell = _shell;
    if (shell == null) {
      BergenRoutes.push(context, '/bergen/utforsk?tab=pose');
      return;
    }
    UtforskScreen.apneSegment = UtforskScreen.tabPose;
    shell.switchToTab(BergenTab.explore.index);
  }

  /// Under kaien's POSE card from tonight's first real bag (Step 8); none
  /// when there are no bags.
  HjemKaienFunn? _kaienPose() {
    if (_poser.isEmpty) return null;
    final bag = _poser.first;
    final kr = ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final verdi = ((bag['value_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    return HjemKaienFunn(
      tittel: BergenCopy.poseTittel,
      under: verdi > 0 ? 'Verdi minst $verdi kr' : '${bag['store_name'] ?? ''}',
      pris: '$kr kr',
      merke: BergenCopy.poseIgjen(_poser.length),
      onTap: _openPose,
    );
  }

  /// Under kaien's FRAKT card: the admin's «Gratis levering» campaign when
  /// there is one (Step 12, `catalog/home` `free_delivery`), else the nearest
  /// open store's own free-delivery threshold (Step 8).
  HjemKaienFunn? _kaienFrakt() {
    final kampanje = _katalog?['free_delivery'];
    if (kampanje is Map<String, dynamic>) {
      final store = kampanje['store'] is Map ? kampanje['store'] as Map : null;
      final storeId = (store?['id'] as num?)?.toInt();
      final now = (kampanje['now_ore'] as num?)?.toInt();
      return HjemKaienFunn(
        tittel: '${kampanje['title'] ?? 'Gratis levering'}',
        under: [kampanje['sub'], store?['name']].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        pris: now == null || now == 0 ? '0 kr' : '${now ~/ 100} kr',
        merke: kampanje['badge'] as String?,
        onTap: storeId != null ? () => BergenRoutes.push(context, '/bergen/butikk/$storeId') : _toExplore,
      );
    }
    final f = _frakt;
    final id = (f?['id'] as num?)?.toInt();
    final ore = (f?['threshold_ore'] as num?)?.toInt() ?? 0;
    if (f == null || id == null || ore <= 0) return null;
    return HjemKaienFunn(
      tittel: 'Gratis levering',
      under: 'Over ${ore ~/ 100} kr · ${f['name'] ?? ''}',
      pris: '0 kr',
      // The store's own threshold, open now — not a tonight-only campaign.
      merke: 'Åpen nå',
      onTap: () => BergenRoutes.push(context, '/bergen/butikk/$id'),
    );
  }

  /// The Forundringspose card (L3177) from the first real bag; the count is
  /// the bags themselves (no stock is tracked).
  Widget _hjemPoseKort() {
    final bag = _poser.isEmpty ? null : _poser.first;
    final kr = bag == null ? 0 : ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final verdi = bag == null ? 0 : ((bag['value_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final butikk = bag == null ? '' : '${bag['store_name'] ?? ''}';
    final hentes = bag == null ? '' : utfPoseHentes(bag, _poseButikk);
    return HjemPoseKort(
      tittel: BergenCopy.poseTittel,
      igjen: BergenCopy.poseIgjen(_poser.length),
      verdi: verdi > 0 ? BergenCopy.poseVerdi(verdi) : '',
      under: [butikk, if (hentes.isNotEmpty) hentes.toLowerCase()].where((e) => e.isNotEmpty).join(' · '),
      kr: '$kr',
      onTap: _openPose,
    );
  }

  void _openFjordfiske() => BergenRoutes.push(context, '/bergen/fjordfiske');

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

  /// The hero's baked weather (`VAER`), from the time-of-day look.
  static HjemVaer _hjemVaer(BergenWeatherLook look) {
    final forced = HjemHarness.vaer;
    if (forced != null) return forced;
    if (identical(look, BergenWeatherLook.sol)) return HjemVaer.sol;
    if (identical(look, BergenWeatherLook.solnedgang)) {
      return HjemVaer.solnedgang;
    }
    if (identical(look, BergenWeatherLook.natt)) return HjemVaer.natt;
    return HjemVaer.regn;
  }

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
    _settVindu(!_vindu);
  }

  /// `toggleVindu`.
  void _settVindu(bool v) {
    _lock = DateTime.now().add(const Duration(milliseconds: 700));
    if (v && _scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _vindu = v;
      _soneBytt = true;
      _kaien = false;
      _dragY = 0;
      _k = 0;
    });
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) setState(() => _soneBytt = false);
    });
  }

  // ── Data mapping ────────────────────────────────────────────────────────

  /// Categories: backend services, or the design's five while loading.
  List<BergenCategory> _categories(HomeCatePojo? home) {
    final services = home?.services ?? const <ServicesItem>[];
    if (services.isEmpty) {
      return [
        for (var i = 0; i < BergenCategoryLook.all.length; i++)
          BergenCategory(
            id: 0,
            name: _placeholderCategoryName(i),
            liveText: '',
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
          liveText: _liveTekst(BergenCategory(id: services[i].serviceCategoryId, name: services[i].serviceCategoryName, liveText: '', look: BergenCategoryLook.all[i % BergenCategoryLook.all.length])),
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

  /// API categories by wheel slot (the first one per slot).
  Map<int, BergenCategory> _slots(List<BergenCategory> categories) {
    final m = <int, BergenCategory>{};
    for (final c in categories) {
      m.putIfAbsent(hjemHjulIkon(c.name), () => c);
    }
    return _sisteSlots = m;
  }

  /// The wheel's last slots (the debug harness opens a category from them).
  Map<int, BergenCategory> _sisteSlots = const {};

  void _velgHjul(
    int k,
    List<BergenCategory> categories,
    Map<int, BergenCategory> slots,
  ) {
    final c = slots[k];
    setState(() {
      _hjulI = k;
      if (c != null) _catIndex = categories.indexOf(c);
    });
  }

  /// The coming categories, their texts and counts, and which of them this
  /// customer asked to hear about — all from the server (Step 8; the device
  /// list in prefs is gone).
  Future<void> _lastSnart() async {
    final rows = await OpsCustomerApi().launchCategories();
    if (!mounted || rows.isEmpty) return;
    final m = <int, HjemSnartInfo>{};
    for (final r in rows) {
      final e = HjemSnartInfo.fraJson(r);
      if (e != null) m[e.$1] = e.$2;
    }
    setState(() {
      _snart = m;
      _snartVarsle = {for (final e in m.entries) if (e.value.varsles) e.key};
    });
  }

  /// Is wheel slot [k] still coming? Restaurant never is; without an answer
  /// from the server the design's four stay coming.
  bool _erSnart(int k) {
    if (k == 0 || HjemHarness.katLive) return false;
    final s = _snart;
    return s == null ? true : s.containsKey(k);
  }

  /// «Varsle meg» on the server; undone with a word when it does not land.
  Future<void> _settSnart(int k, bool v) async {
    final id = _snart?[k]?.id;
    setState(() => v ? _snartVarsle.add(k) : _snartVarsle.remove(k));
    if (id == null) return;
    final ok = await OpsCustomerApi().launchNotify(id, v);
    if (ok || !mounted) return;
    setState(() => v ? _snartVarsle.remove(k) : _snartVarsle.add(k));
    openSimpleSnackbar(isGuestUser() ? 'Logg inn for å få beskjed når det åpner.' : BergenCopy.comingSoon);
  }

  void _openSnart(int k) {
    final info = _snart?[k];
    if (info == null) {
      openSimpleSnackbar(BergenCopy.comingSoon);
      return;
    }
    visKommerSnart(
      context,
      k: k,
      info: info,
      varsles: _snartVarsle.contains(k),
      onVarsle: (v) => _settSnart(k, v),
      onRestauranter: () => setState(() => _hjulI = 0),
    );
  }

  /// «N åpne nå» for [c] from the pulse; '' until it answers (asked once).
  String _liveTekst(BergenCategory? c) {
    if (c == null || c.id == 0) return '';
    final n = _aapneNa[c.id];
    if (n != null) return BergenCopy.openNow(n);
    if (_pulsSpurt.add(c.id)) {
      OpsCustomerApi().categoryPulse(BergenHomeSlug.of(c.name)).then((p) {
        final open = (p?['stores_open'] as num?)?.toInt();
        if (mounted && open != null) setState(() => _aapneNa[c.id] = open);
      });
    }
    return '';
  }

  /// The FRAKT card's store, nearest to the delivery address when it has a
  /// position.
  Future<void> _lastFrakt([AddressListItem? a]) async {
    final lat = double.tryParse(a?.lat ?? '');
    final lng = double.tryParse(a?.long ?? '');
    final store = await OpsCustomerApi().freeDelivery(lat: lat, lng: lng);
    if (mounted) setState(() => _frakt = store);
  }

  /// «Tilbud og fremheving» for Hjem (Step 12).
  Future<void> _lastKatalog() async {
    final home = await OpsCustomerApi().catalogHome();
    if (mounted && home != null) setState(() => _katalog = home);
  }

  /// The first personal offer still good (Step 12); none for a guest.
  Future<void> _lastPersonlig() async {
    if (isGuestUser()) return;
    final rows = await OpsCustomerApi().myOffers();
    final p = rows.map(HjemPersonlig.fraJson).whereType<HjemPersonlig>().firstOrNull;
    if (mounted) setState(() => _personlig = p);
  }

  /// «Avslør» on the mystery coupon.
  Future<HjemPersonlig?> _avslorPersonlig(HjemPersonlig p) async {
    final r = await OpsCustomerApi().revealOffer(p.id);
    final avslort = r == null ? null : HjemPersonlig.fraJson(r);
    if (mounted && avslort != null) setState(() => _personlig = avslort);
    return avslort;
  }

  /// The revealed coupon's «Til butikken» / «Handle nå».
  void _tilPersonlig() {
    final id = _personlig?.butikkId;
    if (id != null) {
      BergenRoutes.push(context, '/bergen/butikk/$id');
    } else {
      _toExplore();
    }
  }

  /// The two shops this customer last ordered from, with that order's lines.
  Future<void> _lastIgjen() async {
    if (isGuestUser()) return;
    final rows = await OpsCustomerApi().orders(limit: 20);
    final seen = <int>{};
    final out = <Map<String, dynamic>>[];
    for (final r in rows) {
      final store = r['store'] is Map ? r['store'] as Map : const {};
      final id = (store['id'] as num?)?.toInt() ?? 0;
      final items = r['items'] is List ? r['items'] as List : const [];
      if (id == 0 || items.isEmpty || r['state'] == 'cancelled' || !seen.add(id)) continue;
      out.add(r);
      if (out.length == 2) break;
    }
    if (mounted) setState(() => _igjen = out);
  }

  Future<void> _bestillIgjen(int i) async {
    if (i >= _igjen.length) return;
    final r = _igjen[i];
    final store = r['store'] as Map;
    await bestillIgjen(
      context,
      kasse: OpsKasseApi(),
      storeId: (store['id'] as num).toInt(),
      butikk: '${store['name'] ?? ''}',
      linjer: [for (final l in (r['items'] as List).whereType<Map>()) Map<String, dynamic>.from(l)],
    );
  }

  String _placeholderCategoryName(int i) =>
      const ['Restaurant', 'Fisk', 'Mote', 'Interiør', 'Gaver'][i];

  /// `META` — the design's three floats (b2 last: the prototype keeps it
  /// off the water). TODO(api): Ægil recommendations.
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
      wasPrice: 179,
      bergensk: true,
      glow: true,
      ring: true,
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
  ];

  List<BergenFloatItem> _floats(List<SwipeCardModel> swipe) {
    final source = swipe.isEmpty || HjemHarness.demoFloats
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
                wasPrice: swipe[i].originalAmount > swipe[i].amount
                    ? swipe[i].originalAmount
                    : null,
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

  /// «Populært i kveld»: the swipe feed near the address; without it the
  /// focused category's most-ordered products (the Ark's list). Never the
  /// design's sample cards — a tap must always reach a real store.
  List<BergenProductCard> _products(List<SwipeCardModel> swipe, BergenCategory cat) {
    if (swipe.isEmpty) {
      _ensurePopulaert(cat);
      return _populaertByCat[cat.id] ?? const [];
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

  /// The admin's hero offers (`catalog/home` `featured`, Step 12) as coupons:
  /// the offer's own eyebrow, title, badge and prices, its colour as the stub.
  List<HjemTilbud> _featuredTilbud() {
    final rows = _katalog?['featured'];
    if (rows is! List) return const [];
    const farger = {'oransje': HjemStub.oransje, 'rosa': HjemStub.oransje, 'gronn': HjemStub.mint, 'bla': HjemStub.teal, 'lilla': HjemStub.teal};
    String kr(int ore) => ore == 0 ? 'Gratis' : '${(ore / 100).round()} kr';
    return [
      for (final o in rows.whereType<Map<String, dynamic>>().take(4))
        () {
          final store = o['store'] is Map ? o['store'] as Map : null;
          final storeId = (store?['id'] as num?)?.toInt();
          final was = (o['was_ore'] as num?)?.toInt();
          final now = (o['now_ore'] as num?)?.toInt();
          final badge = (o['badge'] as String?)?.trim();
          final pst = was != null && now != null && was > 0 ? ((was - now) / was * 100).round() : null;
          return HjemTilbud(
            eyebrow: (o['eyebrow'] as String?)?.trim().isNotEmpty == true ? o['eyebrow'] as String : 'Tilbud',
            navn: '${o['title'] ?? ''}',
            butikk: '${store?['name'] ?? 'Ærend'}',
            meta: '${o['sub'] ?? ''}',
            logoUrl: (store?['logo_url'] as String?)?.isNotEmpty == true ? store!['logo_url'] as String : null,
            fotoUrl: (o['banner_url'] as String?)?.isNotEmpty == true ? o['banner_url'] as String : null,
            ny: now != null ? kr(now) : '',
            gml: was != null ? kr(was) : '',
            gmlStrek: was != null,
            verdi: badge != null && badge.isNotEmpty ? badge : (pst != null ? '−$pst %' : '★'),
            under: was != null && now != null && was > now ? 'Spar ${kr(was - now)}' : (store == null ? 'Hele Ærend' : 'Hos ${store['name']}'),
            verdiStr: (badge?.length ?? 0) > 6 ? 20.0 : 28.0,
            stub: farger[o['grad']] ?? HjemStub.oransje,
            onTap: storeId != null ? () => BergenRoutes.push(context, '/bergen/butikk/$storeId') : _toExplore,
          );
        }(),
    ];
  }

  /// Ærend-tilbud: the discounted products in the swipe feed, as coupons;
  /// the prototype's coupons while there are none.
  List<HjemTilbud> _tilbud(List<SwipeCardModel> swipe) {
    const stubs = [
      HjemStub.oransje,
      HjemStub.gull,
      HjemStub.teal,
      HjemStub.mint,
    ];
    const eyebrows = ['Dagens kupp', 'Kun i kveld', 'Tilbud', 'Tilbud'];
    // Step 12: the admin's hero offers come first («Tilbud og fremheving»).
    final featured = _featuredTilbud();
    final deals = swipe
        .where((p) => p.originalAmount > p.amount && p.amount > 0)
        .take((4 - featured.length).clamp(0, 4).toInt())
        .toList();
    if (featured.isNotEmpty || deals.isNotEmpty) {
      return [
        ...featured,
        for (var k = 0; k < deals.length; k++)
          () {
            final p = deals[k];
            final spar = p.originalAmount - p.amount;
            final pst = p.discountPercent > 0
                ? p.discountPercent
                : (spar / p.originalAmount * 100).round();
            return HjemTilbud(
              eyebrow: eyebrows[k],
              navn: p.productName,
              butikk: p.storeName,
              meta: p.distance > 0
                  ? '${p.distance.toStringAsFixed(1).replaceAll('.', ',')} km unna'
                  : 'Bergen',
              logoUrl: p.storeLogo.isEmpty ? null : p.storeLogo,
              fotoUrl: p.productImage.isEmpty ? null : p.productImage,
              ny: _kr(p.amount),
              gml: _kr(p.originalAmount),
              verdi: '−$pst %',
              under: 'Spar ${_kr(spar)}',
              verdiStr: k == 0 ? 22 : 28,
              stub: stubs[(k + featured.length) % stubs.length],
              onTap: () => _openProduct(
                BergenProductCard(
                  id: p.productId,
                  name: p.productName,
                  store: p.storeName,
                  priceText: _kr(p.amount),
                  price: p.amount,
                  storeId: p.storeId,
                ),
              ),
            );
          }(),
      ];
    }
    // No discounts in the feed: no coupons — the row is left out rather than
    // filled with the design's samples (backend plan Step 8).
    return const [];
  }

  // The design's sample coupons, kept for reference only (never shown).
  // ignore: unused_element
  List<HjemTilbud> _tilbudPrototype() {
    return [
      HjemTilbud(
        eyebrow: 'Dagens kupp',
        navn: 'Crispy chicken',
        butikk: 'Burger King',
        meta: 'Bergen Storsenter · 25 min',
        logoAsset: BergenAssets.bkLogo,
        fotoAsset: BergenAssets.bkWhopper,
        ny: '89 kr',
        gml: '129 kr',
        verdi: '−30 %',
        under: 'Spar 40 kr',
        verdiStr: 22,
        stub: HjemStub.oransje,
        onTap: _comingSoon,
      ),
      HjemTilbud(
        eyebrow: 'Kun i kveld',
        navn: 'Pommes frites, stor',
        butikk: 'Burger King',
        meta: 'Bergen Storsenter · 25 min',
        logoAsset: BergenAssets.bkLogo,
        ny: '59 kr',
        gml: '118 kr',
        verdi: '2 for 1',
        under: 'Betal for én',
        verdiStr: 24,
        stub: HjemStub.gull,
        onTap: _comingSoon,
      ),
      HjemTilbud(
        eyebrow: 'Fersk i dag',
        navn: 'Fiskesuppe for to',
        butikk: 'Nordnes Fisk',
        meta: 'Nordnes · 30 min',
        ny: '164 kr',
        gml: '219 kr',
        verdi: '−25 %',
        under: 'Spar 55 kr',
        verdiStr: 24,
        stub: HjemStub.teal,
        onTap: _comingSoon,
      ),
      HjemTilbud(
        eyebrow: 'Ut av ovnen',
        navn: 'Seks kanelboller',
        butikk: 'Sandviken Bakeri',
        meta: 'Sandviken · 20 min',
        ny: '129 kr',
        gml: 'Levering 0 kr',
        gmlStrek: false,
        verdi: 'Fri frakt',
        under: 'Spar 39 kr',
        verdiStr: 20,
        stub: HjemStub.mint,
        onTap: _comingSoon,
      ),
    ];
  }

  /// Norwegian kroner: "149 kr", "139,30 kr".
  static String _kr(double v) =>
      '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2).replaceAll('.', ',')} kr';

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

  void _ensurePopulaert(BergenCategory cat) {
    if (cat.id == 0 || !_populaertSpurt.add(cat.id)) return;
    _loadPopulaert(cat.id).then((list) {
      if (!mounted) return;
      setState(() => _populaertByCat[cat.id] = [
        for (final p in list)
          if (p.id != 0 && p.storeId != 0)
            BergenProductCard(
              id: p.id,
              name: p.name,
              store: p.storeName,
              priceText: p.priceText,
              price: p.priceOre / 100,
              storeId: p.storeId,
              imageUrl: p.imageUrl,
            ),
      ]);
    });
  }

  void _ensureStores(BergenCategory cat) {
    if (cat.id == 0) return;
    if (_storesByCat.containsKey(cat.id) || _storesLoading.contains(cat.id)) {
      return;
    }
    _storesLoading.add(cat.id);
    final seq = ++_storesRequestSeq;
    _storeRepo
        .fetch(cat.id, surface: 'home')
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
    // The rail says «Ingen butikker her ennå»; no sample cards.
    return const [];
  }

  bool get _showSurprise {
    if (isGuestUser()) return false;
    if (HjemHarness.pose) return true;
    final t = DateTime.now().hour;
    return (t >= 11 && t < 14) || (t >= 16 && t < 21);
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _openCategory(BergenCategory cat, {String? fane}) {
    if (cat.id == 0) {
      _comingSoon();
      return;
    }
    setSelectedServiceInPref(cat.id, cat.name, cat.iconUrl ?? '');
    BergenRoutes.pushOr(
      context,
      '/bergen/kategori/${slugOf(cat.name)}',
      arguments: {'id': '${cat.id}', 'name': cat.name, 'fane': ?fane},
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

  Future<void> _openAddressSheet({bool ny = false}) async {
    if (!await showGuestLoginSheet(context, prompt: GuestLoginPrompt.address)) {
      return;
    }
    if (!mounted) return;
    await visAdresseArk(context, _adrKilde, ny: ny);
  }

  /// The header's "· 25–35 min" follows coverage for the chosen place.
  void _hentHodeEta(AddressListItem? a) {
    if (a == null || a.addressId == 0) return;
    _lastFrakt(a);
    _adrKilde.dekning(a).then((d) {
      if (mounted) setState(() => _hodeEta = d?.hodeEta);
    });
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
        final slots = _slots(categories);
        final catIndex = _catIndex.clamp(0, categories.length - 1);
        final focused = slots[_hjulI] ?? slots[0] ?? categories[catIndex];
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
                final products = _products(swipe, focused);
                final floats = _floats(swipe);

                final heroOpacity = (1 - ((_k / s) - 120).clamp(0.0, 92.0) / 92)
                    .clamp(0.0, 1.0);
                // Vindu's stripe keeps its distance from the bottom (640 of
                // the 844 frame); the scene runs 34px under it.
                final vinduTop = screenH - (844 - 640) * s;
                final sheetTop = _vindu
                    ? vinduTop + _stripeDy * s
                    : safeTop + (_kSheetTop + _dragY) * s - _k;
                final heroH = _vindu
                    ? vinduTop + 34 * s - safeTop
                    : (kHjemHeroH + (_dragY > 0 ? _dragY : 0)) * s;
                final restLive = stores.isNotEmpty && focused == slots[0]
                    ? '${stores.where((e) => e.open).length} åpne nå'
                    : _liveTekst(slots[0]);

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
                                AnimatedPositioned(
                                  duration: Duration(
                                    milliseconds: _soneBytt ? 340 : 0,
                                  ),
                                  curve: const Cubic(.2, .9, .3, 1),
                                  left: 0,
                                  right: 0,
                                  top: _vindu ? 0 : _kHeroTop * s - _k,
                                  height: heroH,
                                  child: IgnorePointer(
                                    ignoring: heroOpacity < .05,
                                    child: Opacity(
                                      opacity: heroOpacity,
                                      child: LfFrame(
                                        child: HjemHero(
                                          vaer: _hjemVaer(look),
                                          floats: floats,
                                          onFloatAdd: _onFloatAdd,
                                          onFloatSink: _onFloatSunk,
                                          onFloatNever: _onFloatNever,
                                          onPose: _openPose,
                                          onFjordfiske: _openFjordfiske,
                                          playIntro: _playIntro,
                                          extraHeight: _dragY > 0 ? _dragY : 0,
                                          vindu: _vindu,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Under kaien (L2663): behind the sheet's end ──
                        if (!_vindu)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 300 * s,
                            child: LfFrame(
                              child: HjemUnderKaien(
                                vist: _kaien,
                                reker: _underKaien == null
                                    ? null
                                    : HjemKaienFunn(
                                        tittel: _underKaien!.title,
                                        under: _underKaien!.sub.isEmpty
                                            ? _underKaien!.store
                                            : '${_underKaien!.store} · ${_underKaien!.sub}',
                                        pris: _underKaien!.price,
                                        onTap: _onUnderKaienOffer,
                                      ),
                                pose: _kaienPose(),
                                frakt: _kaienFrakt(),
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
                              slots: slots,
                              tilbud: _tilbud(swipe),
                            ),
                          ),
                        ),

                        // ── Header row (`visKromOver`) ─────────────────
                        if (!_vindu)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: safeTop + _kHeaderTop * s,
                            height: 56 * s,
                            child: LfFrame(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: StreamBuilder<AddressListItem?>(
                                  stream: _bloc.deliveryAddress,
                                  builder: (context, snap) {
                                    final raw = snap.data?.address ?? '';
                                    return HjemHeader(
                                      address: raw.isEmpty
                                          ? ''
                                          : raw.split(',').first.trim(),
                                      type: hjemAdrType(snap.data?.type ?? ''),
                                      eta: _hodeEta,
                                      unread:
                                          HjemHarness.unread ??
                                          home?.totalUnreadMessage ??
                                          0,
                                      onAddress: _openAddressSheet,
                                      onBell: () => BergenRoutes.pushOr(
                                        context,
                                        '/bergen/meg/varsler',
                                        orElse: () => openScreen(
                                          context,
                                          const Notifications(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        // Seam (AGIL-CONTRACT §2.2): the cold-start "Mens du
                        // var borte" card over the scene (design L9017, top
                        // 118), when agil-3 has something to say.
                        if (!_vindu)
                          if (mensDuVarBorteCard(context) case final borte?)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: safeTop + 118 * s,
                              child: lfFlow(
                                390,
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: borte,
                                ),
                              ),
                            ),

                        // ── Vindu: chrome, search and the category stickers
                        if (_vindu) ...[
                          Positioned(
                            left: 0,
                            right: 0,
                            top: safeTop,
                            height: heroH,
                            child: LfFrame(
                              child: StreamBuilder<AddressListItem?>(
                                stream: _bloc.deliveryAddress,
                                builder: (context, snap) {
                                  final raw = snap.data?.address ?? '';
                                  return HjemVinduLag(
                                    vaer: _hjemVaer(look),
                                    adresse: raw.isEmpty
                                        ? 'Velg adresse'
                                        : raw.split(',').first.trim(),
                                    uleste:
                                        HjemHarness.unread ??
                                        home?.totalUnreadMessage ??
                                        0,
                                    live: [
                                      restLive,
                                      for (var k = 1; k < 5; k++)
                                        'Kommer snart',
                                    ],
                                    opacity: (1 + _stripeDy / 90).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    onAdresse: _openAddressSheet,
                                    onBjelle: () => BergenRoutes.pushOr(
                                      context,
                                      '/bergen/meg/varsler',
                                      orElse: () => openScreen(
                                        context,
                                        const Notifications(),
                                      ),
                                    ),
                                    onSok: () => BergenRoutes.pushOr(
                                      context,
                                      '/bergen/sok',
                                      orElse: _comingSoon,
                                    ),
                                    onAegil: _openAegil,
                                    onKategori: (k) {
                                      _velgHjul(k, categories, slots);
                                      _settVindu(false);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: Duration(
                              milliseconds: _soneBytt ? 340 : 0,
                            ),
                            curve: const Cubic(.2, .9, .3, 1),
                            left: 0,
                            right: 0,
                            top: sheetTop,
                            child: lfFlow(
                              390,
                              HjemVinduStripe(
                                onToggle: () => _settVindu(false),
                                onDragStart: (_) =>
                                    setState(() => _stripeDy = 0),
                                onDragUpdate: (d) => setState(
                                  () => _stripeDy = (_stripeDy + d.delta.dy / s)
                                      .clamp(-160.0, 0.0),
                                ),
                                onDragEnd: (d) {
                                  final opp =
                                      _stripeDy < -70 ||
                                      (d.primaryVelocity ?? 0) < -400;
                                  setState(() => _stripeDy = 0);
                                  if (opp) _settVindu(false);
                                },
                                butikker: [
                                  for (final r in _igjen) '${(r['store'] as Map)['name'] ?? ''}',
                                ],
                                onButikk: _bestillIgjen,
                              ),
                            ),
                          ),
                        ],

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
    required Map<int, BergenCategory> slots,
    required List<HjemTilbud> tilbud,
  }) {
    final s = context.bs;
    // `katBydel` follows the wheel, also for coming-soon categories.
    final district = BergenCategoryLook.all[_hjulI].district;
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
            ],
          ),
        ),
        // Kategorirad: the full frame width (margin 4px -16px 0).
        Padding(
          padding: EdgeInsets.only(top: 4 * s),
          child: lfFlow(
            390,
            HjemKategoriHjul(
              kategorier: [
                for (var k = 0; k < 5; k++)
                  HjemHjulKat(
                    navn: kHjemKatNavn[k],
                    live: k == 0 && stores.isNotEmpty && focused == slots[0]
                        ? '$openCount åpne nå'
                        : _liveTekst(slots[k]),
                    ikon: k,
                    snart: _erSnart(k),
                    varsles: _snartVarsle.contains(k),
                  ),
              ],
              index: _hjulI,
              onIndex: (k) => _velgHjul(k, categories, slots),
              onOpen: (k) {
                final c = slots[k];
                if (c != null) _openCategory(c);
              },
              onSnart: _openSnart,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10 * s),
              lfFlow(
                358,
                // The line is the habit of the day from the customer's
                // delivered orders (the same data the screen reads).
                ValueListenableBuilder<HurtigData?>(
                  valueListenable: HurtigKilde.cache,
                  builder: (context, d, _) => HjemHurtigInngang(
                    linje: hurtigHjemLinje(d),
                    onTap: () async {
                      final r = await BergenRoutes.push<dynamic>(context, '/bergen/hurtig');
                      if (r == HurtigScreen.tilKurv && context.mounted) {
                        _shell?.switchToTab(BergenTab.cart.index);
                      }
                    },
                  ),
                ),
              ),
              lfFlow(
                358,
                HjemSeksjonHode(
                  tittel: BergenCopy.storesIn(district),
                  chip: HjemChip.bergensk,
                  chipTekst: BergenCopy.bergensk,
                  prikker: 5,
                  prikk: _hjulI,
                  onSeAlle: _openArk,
                ),
              ),
              SizedBox(height: 8 * s),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: const Cubic(.2, .9, .3, 1),
                child: BergenStoreRail(
                  key: ValueKey(
                    'stores-${focused.id}-${stores.length}-$_hjulI',
                  ),
                  stores: stores,
                  // A wrapped card opens the Kommer snart sheet.
                  onOpen: _erSnart(_hjulI) ? (_) => _openSnart(_hjulI) : _openStore,
                  snart: _erSnart(_hjulI),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 12 * s, bottom: 2 * s),
                child: lfFlow(
                  358,
                  HjemUtforskKort(
                    linje: BergenCopy.exploreLine,
                    onTap: _toExplore,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 22 * s),
                child: lfFlow(
                  358,
                  tilbud.isEmpty && _personlig == null
                      ? const SizedBox.shrink()
                      : HjemTilbudRad(tilbud: tilbud, personlig: _personlig, onAvslor: _avslorPersonlig, onMysterie: _tilPersonlig),
                ),
              ),
              // Only with real bags tonight.
              if (_showSurprise && _poser.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 22 * s),
                  child: lfFlow(
                    358,
                    _hjemPoseKort(),
                  ),
                ),
              lfFlow(
                358,
                HjemSeksjonHode(
                  tittel: BergenCopy.popularTonight,
                  chip: HjemChip.bydel,
                  chipTekst: BergenCopy.bergenhus,
                  topp: 26,
                  onSeAlle: _openArk,
                ),
              ),
              SizedBox(height: 10 * s),
              BergenProductRail(
                snart: _erSnart(_hjulI),
                products: products,
                onOpen: _erSnart(_hjulI) ? (_) => _openSnart(_hjulI) : _openProduct,
                onAdd: (p) => _addProduct(p.storeId, p.id, p.name),
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * s),
        // The open water after the content (296 + the inner padding 316):
        // the waterline sits 314px above its end, so Under kaien, fixed at
        // the bottom of the screen behind the sheet, shows through.
        SizedBox(height: (296 + 316) * s),
      ],
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
    return HjemVann(
      controller: controller,
      s: s,
      bunnLuft: 314,
      child: Container(
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
