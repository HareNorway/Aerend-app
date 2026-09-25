import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../../deliveryService/searchStore/search_store.dart';
import '../../bergen/utforsk/utforsk_screen.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../../bergen/kit/bergen_routes.dart';
import '../../bergen/meg/meg_host.dart';
import '../home/bergen/bergen_home.dart';
import '../home/bergen/bergen_nav.dart';
import '../orderCart/order_cart.dart';

/// The Bergen shell: Hjem · Utforsk · Kurv · Meg behind the design's pill nav
/// plus the round search orb (search field + Ægil pill, long-press → Ægil).
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
  PageController controller = PageController();
  DateTime? currentTime;
  int selectedPos = 0;

  ValueNotifier<int> badgeCountNotifier = ValueNotifier<int>(
    prefGetInt(prefCartCount),
  );

  /// Keyword handed to the search screen when it is opened from Hjem.
  final ValueNotifier<String> searchLaunchKeyword = ValueNotifier('');

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
    final int initialTab = _remapLegacyIndex(widget.homeIndex);
    controller = PageController(initialPage: initialTab);
    selectedPos = initialTab;
  }

  @override
  void dispose() {
    controller.dispose();
    badgeCountNotifier.dispose();
    searchLaunchKeyword.dispose();
    super.dispose();
  }

  /// Switch bottom-nav tab. [animate]: false jumps instantly.
  void switchToTab(int index, {bool animate = true}) {
    if (index == searchTabIndex) {
      openSearchTab();
      return;
    }
    final target = index.clamp(0, BergenTab.values.length - 1);
    if (animate) {
      controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 420),
        curve: const Cubic(.2, .9, .3, 1),
      );
    } else if (controller.hasClients) {
      controller.jumpToPage(target);
    }
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

  /// Opens the store search (the design's search orb) with an optional query.
  void openSearchTab({String keyword = ''}) {
    final trimmed = keyword.trim();
    searchLaunchKeyword.value = trimmed;
    // AGIL-1 v2 Phase 2/3: the Bergen Søk screen, with the typed text; the
    // legacy search until that route lands.
    BergenRoutes.pushOr(
      context,
      '/bergen/sok',
      arguments: {'q': trimmed},
      orElse: () => openScreen(
        context,
        SearchStore(latLng: prefGetLatLng(), keyword: trimmed),
      ),
    );
  }

  void _openAegil(String draft) {
    openScreen(context, SnurreChatScreen(draftFromHomeSearch: draft.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final pageView = PageView(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 0 — Hjem
        BergenHome(isShowDialog: widget.isShowDialog, orderId: widget.orderId),
        // 1 — Utforsk (AGIL-1 v2 Phase 2: Feed / Fjordfiske / Forundringspose)
        const UtforskScreen(),
        // 2 — Kurv
        Padding(
          padding: EdgeInsets.only(bottom: bergenNavReserve(context)),
          child: OrderCart(fromStore: widget.fromStore),
        ),
        // 3 — Meg (Sync C seam: agil-3 fills MegScreen)
        const MegScreen(),
      ],
    );

    final scaffold = Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: pageView),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BergenBottomNav(
              index: selectedPos,
              onTab: (i) => switchToTab(i),
              cartCount: badgeCountNotifier,
              onSearch: (q) => openSearchTab(keyword: q),
              onAegil: _openAegil,
              showHint: selectedPos == BergenTab.home.index,
            ),
          ),
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () {
        DateTime now = DateTime.now();
        if (currentTime == null ||
            now.difference(currentTime!) > const Duration(seconds: 2)) {
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
