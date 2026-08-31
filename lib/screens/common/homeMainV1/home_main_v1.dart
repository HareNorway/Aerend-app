import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badges/badges.dart' as badges;

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../commonView/circle_nav_bar.dart';
import '../account/account.dart';
import '../../deliveryService/searchStore/search_store.dart';
import '../../feed/feed_shell_screen.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../home/home_v1.dart';
import '../orderCart/order_cart.dart';

class HomeMainV1 extends StatefulWidget {
  final bool isShowDialog;
  final bool fromStore;
  final int orderId;

  /// Tab index to open on launch. Accepts LEGACY 5-tab indices for backward
  /// compatibility — they are remapped internally to the new 6-tab layout:
  ///   old 0 (Butikker) → 0 (Hjem)
  ///   old 1 (Kurv)     → 4 (Kurv)
  ///   old 2 (Hjem)     → 0 (Hjem)
  ///   old 3 (Søk)      → 1 (Søk)
  ///   old 4 (Konto)    → 5 (Profil)
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

class HomeMainV1State extends State<HomeMainV1>
    with SingleTickerProviderStateMixin {
  PageController controller = PageController();
  bool isOneTimeClick = true;
  DateTime? currentTime;
  int selectedPos = 0;

  ValueNotifier<int> badgeCountNotifier = ValueNotifier<int>(
    prefGetInt(prefCartCount),
  );

  /// Keyword from home search bar when opening the shell search tab.
  final ValueNotifier<String> searchLaunchKeyword = ValueNotifier('');

  static const int searchTabIndex = 1; // Søk is now index 1 (commercial)

  // Inert tab indices still referenced by dugnad-only screens (dg_home,
  // dugnad_notification_nav, dugnad_profile_section). No behaviour hangs off
  // them any more — they are deleted in Chunk 5 with their callers.
  static const int dugnadHomeTabIndex = 0;
  static const int dugnadKampanjeTabIndex = 1;
  static const int dugnadShopTabIndex = 2;
  static const int dugnadLeaderboardTabIndex = 3;
  static const int dugnadProfileTabIndex = 4;

  // ── Commercial 6-tab layout ──────────────────────────────────────
  // 0: Hjem   1: Søk   2: Feed   3: AI   4: Kurv   5: Profil
  // ─────────────────────────────────────────────────────────────────

  /// Maps legacy 5-tab homeIndex values to the new 6-tab positions (commercial).
  static int _remapLegacyIndex(int legacy) {
    const mapping = {
      0: 0, // old Butikker → Hjem
      1: 4, // old Kurv → Kurv
      2: 0, // old Hjem → Hjem
      3: 1, // old Søk → Søk
      4: 5, // old Konto → Profil
    };
    return mapping[legacy] ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final int initialTab = _remapLegacyIndex(widget.homeIndex);
    controller = PageController(initialPage: initialTab);
    setState(() {
      selectedPos = initialTab;
    });
  }

  /// Switch bottom-nav tab. Pass [animate]: false for instant jumps (e.g. tour
  /// relaunch from profile) so club-home tour targets can mount without waiting
  /// out the 1s page animation.
  void switchToTab(int index, {bool animate = true}) {
    if (animate) {
      controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.fastLinearToSlowEaseIn,
      );
    } else if (controller.hasClients) {
      controller.jumpToPage(index);
    }
    setState(() {
      selectedPos = index;
    });
  }

  /// Pop a pushed route when possible, otherwise switch to Hjem.
  void backOrHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    switchToTab(0);
  }

  void openSearchTab({String keyword = ''}) {
    final trimmed = keyword.trim();
    if (trimmed.isNotEmpty) {
      searchLaunchKeyword.value = trimmed;
    }
    switchToTab(searchTabIndex);
  }

  void _onItemTapped(int index) => switchToTab(index);

  /// Pill nav icon colors.
  static const Color _navActiveColor = Colors.white;
  static const Color _navInactiveOutline = Color(0xFF8F8F8F); // gray-500
  static const double _kNavIconSize = 22;

  /// Layout reserve for pages that need bottom padding above the floating pill.
  static const double _kShellNavLayoutReserve = 80;

  Widget _navSvgIcon(
    String assetPath, {
    required Color color,
    double size = _kNavIconSize,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }

  Widget _navSvgActive(String assetPath, {double size = _kNavIconSize}) {
    return _navSvgIcon(assetPath, color: _navActiveColor, size: size);
  }

  Widget _navSvgInactive(String assetPath, {double size = _kNavIconSize}) {
    return _navSvgIcon(assetPath, color: _navInactiveOutline, size: size);
  }

  /// Feed tab icon — Æ monogram (no dedicated feed SVG exists yet).
  Widget _buildFeedIcon({required bool active}) {
    const double iconBoxSize = 22;
    return SizedBox(
      width: iconBoxSize,
      height: iconBoxSize,
      child: FittedBox(
        fit: BoxFit.contain,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            active ? _navActiveColor : _navInactiveOutline,
            BlendMode.srcIn,
          ),
          child: Image.asset(
            'assets/Logo/reen-mark-coral.png',
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  /// AI tab icon — sparkle (Material icon; no AI SVG exists yet).
  Widget _buildAiIcon({required bool active}) {
    return Icon(
      Icons.auto_awesome,
      size: _kNavIconSize,
      color: active ? _navActiveColor : _navInactiveOutline,
    );
  }

  Widget _buildCartIconForNav({required bool selected}) {
    final icon = _navSvgIcon(
      'assets/svgs/menu/bucket.svg',
      color: selected ? _navActiveColor : _navInactiveOutline,
    );

    return ValueListenableBuilder<int>(
      valueListenable: badgeCountNotifier,
      builder: (context, count, child) {
        if (count > 0) {
          return badges.Badge(
            badgeContent: Text(
              '$count',
              style: const TextStyle(
                color: colorWhite,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: ScSaasThemeTokens.danger,
              elevation: 0,
              padding: const EdgeInsets.all(3),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            position: badges.BadgePosition.topEnd(top: -6, end: -6),
            child: icon,
          );
        }
        return icon;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageView = PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 0 — Hjem
          HomeV1(
              isShowDialog: widget.isShowDialog,
              orderId: widget.orderId),
          // 1 — Søk
          SearchStore(latLng: prefGetLatLng()),
          // 2 — Feed
          const FeedShellScreen(),
          // 3 — AI
          const SnurreChatScreen(),
          // 4 — Kurv
          Padding(
            padding:
                const EdgeInsets.only(bottom: _kShellNavLayoutReserve),
            child: OrderCart(fromStore: widget.fromStore),
          ),
          // 5 — Profil
          const Account(),
        ],
    );

    final scaffold = Scaffold(
      extendBody: true,
      body: pageView,
      // Floating pill — keep Scaffold's bottom slot fully transparent so the
      // page shows through (no solid foot plate behind the nav).
      //
      // activePillGradient / pillBorderColor / activePillShadowColor are left
      // null: on the commercial branch they always resolved to null (they were
      // fed from the dugnad club palette). CircleNavBar's own defaults apply.
      bottomNavigationBar: CircleNavBar(
        activeIndex: selectedPos,
        onTap: (index) => _onItemTapped(index),
        color: Colors.transparent,
        tabCurve: Curves.easeOutCubic,
        tabDuration: const Duration(milliseconds: 280),
        compactItems: false,
        compactGap: 2,
        compactWidthFactor: 0.90,
        activePillGradient: null,
        pillBorderColor: null,
        activePillShadowColor: null,
        levels: const ['Hjem', 'Søk', 'Feed', 'AI', 'Kurv', 'Profil'],
        activeIcons: [
          _navSvgActive('assets/svgs/menu/home.svg'),
          _navSvgActive('assets/svgs/menu/search.svg'),
          _buildFeedIcon(active: true),
          _buildAiIcon(active: true),
          _buildCartIconForNav(selected: true),
          _navSvgActive('assets/svgs/menu/user.svg'),
        ],
        inactiveIcons: [
          _navSvgInactive('assets/svgs/menu/home.svg'),
          _navSvgInactive('assets/svgs/menu/search.svg'),
          _buildFeedIcon(active: false),
          _buildAiIcon(active: false),
          _buildCartIconForNav(selected: false),
          _navSvgInactive('assets/svgs/menu/user.svg'),
        ],
      ),
    );

    // Scaffold wraps [bottomNavigationBar] in a Material using
    // BottomAppBarTheme.color / surface — force transparent so only the
    // floating pill is visible (no opaque foot strip).
    final themedScaffold = Theme(
      data: Theme.of(context).copyWith(
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: scaffold,
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
      child: themedScaffold,
    );
  }
}
