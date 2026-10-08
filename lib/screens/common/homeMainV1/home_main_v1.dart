import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../services/push_deep_link.dart';
import '../../../services/push_notification_service.dart';
import '../../../utils/utils.dart';
import '../../bergen/utforsk/utforsk_screen.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../../bergen/meg/meg_host.dart';
import '../../bergen/sok/sok_screen.dart';
import '../home/bergen/bergen_home.dart';
import '../home/bergen/bergen_kit.dart' show kBergenScreenGradient, BergenScale;
import '../home/bergen/bergen_nav.dart';
import '../../bergen/kit/fane_bytte.dart';
import '../../bergen/kit/live_aerend.dart';
import '../../bergen/aegil/aegil_entry.dart';
import '../../bergen/kit/bergen_routes.dart';
import '../auth/launch/lf_css.dart' show lfFlow;
import '../../deliveryService/trackOrder/track_order.dart';
import '../../bergen/kasse/kurv_screen.dart';

/// The Bergen shell: Hjem · Utforsk · Kurv · Meg behind the design's pill nav
/// plus the round search orb (search field + Ægil pill, long-press → Ægil).
/// The orb opens Søk over the current tab — the nav's field types into it —
/// and, turned into an X, closes it again (`gaa(skjerm==='sok'?'hjem':'sok')`).
class HomeMainV1 extends StatefulWidget {
  final bool isShowDialog;
  final bool fromStore;
  final int orderId;

  /// Tab index to open on launch. Accepts the LEGACY 5-tab indices callers
  /// still pass — they are remapped to the 4-tab layout:
  ///   old 0 (Butikker) → 0 (Hjem)
  ///   old 1 (Kurv)     → 2 (Kurv)
  ///   old 2 (Hjem)     → 0 (Hjem)
  ///   old 3 (Søk)      → 3 (Meg — only account sub-screens use it as "back")
  ///   old 4 (Konto)    → 3 (Meg)
  final int homeIndex;

  const HomeMainV1({
    super.key,
    this.isShowDialog = false,
    this.fromStore = false,
    this.homeIndex = 2,
    this.orderId = 0,
  });

  @override
  HomeMainV1State createState() => HomeMainV1State();
}

class HomeMainV1State extends State<HomeMainV1> {
  /// The shell that is up, for screens pushed over it whose nav switches tab
  /// (Fjordfiske, Poseautomaten).
  static HomeMainV1State? current;

  PageController controller = PageController();
  DateTime? currentTime;
  int selectedPos = 0;

  ValueNotifier<int> badgeCountNotifier = ValueNotifier<int>(prefGetInt(prefCartCount));

  /// Keyword handed to the search screen when it is opened from Hjem.
  final ValueNotifier<String> searchLaunchKeyword = ValueNotifier('');

  /// Søk: open while the nav is in search mode; the nav's field is its query.
  final ValueNotifier<bool> sokOpen = ValueNotifier(false);
  final TextEditingController _sokField = TextEditingController();
  final GlobalKey<SokScreenState> _sokKey = GlobalKey();

  /// Search is no longer a tab; kept for callers that still switch to it —
  /// [switchToTab] with this value opens the search screen instead.
  static const int searchTabIndex = -1;

  static int _remapLegacyIndex(int legacy) {
    const mapping = {
      0: 0, // old Butikker → Hjem
      1: 2, // old Kurv → Kurv
      2: 0, // old Hjem → Hjem
      3: 3, // old Søk → Meg (account "back")
      4: 3, // old Konto → Meg
    };
    return mapping[legacy] ?? 0;
  }

  @override
  void initState() {
    super.initState();
    current = this;
    final int initialTab = _remapLegacyIndex(widget.homeIndex);
    controller = PageController(initialPage: initialTab);
    selectedPos = initialTab;
    // A push tapped to launch the app waited for the shell (Step 13).
    if (PushDeepLink.hasPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) PushNotificationService.openPendingPushRoute();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    badgeCountNotifier.dispose();
    searchLaunchKeyword.dispose();
    sokOpen.dispose();
    _sokField.dispose();
    if (identical(current, this)) current = null;
    super.dispose();
  }

  /// Switch bottom-nav tab. [animate]: false jumps instantly.
  void switchToTab(int index, {bool animate = true}) {
    if (index == searchTabIndex) {
      openSearchTab();
      return;
    }
    sokOpen.value = false;
    final target = index.clamp(0, BergenTab.values.length - 1);
    // The change itself animates in [BergenFaneBytte] (`faneBytt`).
    setState(() => selectedPos = target);
  }

  /// Pop a pushed route when possible, otherwise switch to Hjem.
  void backOrHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    switchToTab(BergenTab.home.index);
  }

  /// Opens Søk (the design's search orb) with an optional query.
  void openSearchTab({String keyword = ''}) {
    final trimmed = keyword.trim();
    searchLaunchKeyword.value = trimmed;
    _sokField.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    sokOpen.value = true;
  }

  /// The orb's long press and Søk's Ægil key: Ægil (`gaa('agent')`), with
  /// the search draft as the first line when there is one.
  void _openAegil(String draft) {
    final q = draft.trim();
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      arguments: {if (q.isNotEmpty) 'q': q},
      orElse: () => openScreen(context, SnurreChatScreen(draftFromHomeSearch: q)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageView = BergenFaneBytte(
      index: selectedPos,
      background: kBergenScreenGradient,
      builder: (context, i) => switch (i) {
        // 0 — Hjem
        0 => BergenHome(isShowDialog: widget.isShowDialog, orderId: widget.orderId),
        // 1 — Utforsk (AGIL-1 v2 Phase 2: Feed / Fjordfiske / Forundringspose)
        1 => const UtforskScreen(),
        // 2 — Kurv (AGIL-1 v2 Phase 5: the Bergen Kurv; the legacy cart is
        // still the card-payment checkout behind it)
        2 => const KurvScreen(),
        // 3 — Meg (Sync C seam: agil-3 fills MegScreen)
        _ => const MegScreen(),
      },
    );

    final scaffold = Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: pageView),
          ValueListenableBuilder<bool>(
            valueListenable: sokOpen,
            builder: (context, open, _) => open
                ? Positioned.fill(
                    child: SokScreen(key: _sokKey, controller: _sokField, onClose: () => sokOpen.value = false),
                  )
                : const SizedBox.shrink(),
          ),
          // Live-ærend (L9598): left 14, 14 above the nav pill.
          ValueListenableBuilder(
            valueListenable: kurvSkjulerNav,
            builder: (context, _, __) => ValueListenableBuilder(
              valueListenable: hjemLiveOrdre,
              builder: (context, ordre, _) => ValueListenableBuilder<bool>(
                valueListenable: sokOpen,
                builder: (context, sok, _) {
                  if (ordre == null || sok) return const SizedBox.shrink();
                  final s = context.bs;
                  final navBunn = math.max(MediaQuery.paddingOf(context).bottom, 16 * s);
                  // `liveBunnFor`: 90 over the nav, 104 over the Kurv's slider.
                  final overSlider = selectedPos == BergenTab.cart.index && kurvSkjulerNav.value;
                  return Positioned(
                    left: 14 * s,
                    bottom: navBunn + (overSlider ? 88 : 76) * s,
                    width: 234 * s,
                    height: 64 * s,
                    child: lfFlow(
                      234,
                      HjemLiveAerend(
                        data: ordre.data,
                        onTap: () {
                          // `liveApne`: Sporing grows out of the pill.
                          final navn = '/bergen/sporing/${ordre.orderId}';
                          final side = BergenRoutes.generate(RouteSettings(name: navn));
                          if (side is! PageRoute) {
                            openScreen(context, TrackOrder(orderId: ordre.orderId));
                            return;
                          }
                          final size = MediaQuery.sizeOf(context);
                          final top = size.height - navBunn - (overSlider ? 88 : 76) * s - 64 * s;
                          Navigator.of(context).push(
                            LiveApneRoute<dynamic>(
                              settings: side.settings,
                              pill: Rect.fromLTWH(14 * s, top, 234 * s, 64 * s),
                              screen: size,
                              page: (context, a, sa) => side.buildPage(context, a, sa),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // `visNav`: hidden on Kurv while it has lines (the slider's place).
          ValueListenableBuilder<bool>(
            valueListenable: kurvSkjulerNav,
            builder: (context, skjul, nav) =>
                selectedPos == BergenTab.cart.index && skjul ? const SizedBox.shrink() : nav!,
            child: Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BergenBottomNav(
                index: selectedPos,
                onTab: (i) => switchToTab(i),
                cartCount: badgeCountNotifier,
                onSearch: (_) => _sokKey.currentState?.submit(),
                onAegil: _openAegil,
                showHint: selectedPos == BergenTab.home.index,
                searchController: _sokField,
                searchOpen: sokOpen,
              ),
            ),
          ),
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () {
        if (sokOpen.value) {
          sokOpen.value = false;
          return Future.value(false);
        }
        DateTime now = DateTime.now();
        if (currentTime == null || now.difference(currentTime!) > const Duration(seconds: 2)) {
          currentTime = now;
          openSimpleSnackbar(languages.appExitMessage);
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: scaffold,
    );
  }
}
