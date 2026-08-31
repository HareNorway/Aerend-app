import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badges/badges.dart' as badges;

import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../commonView/circle_nav_bar.dart';
import '../../campaign/campaign_purchases_screen.dart';
import '../../campaign/widgets/campaign_tracker.dart';
import '../account/account.dart';
import '../../deliveryService/searchStore/search_store.dart';
import '../../dugnad/dg_home.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/dugnad_state.dart';
import '../../dugnad/kampanje_screen.dart';
import '../../dugnad/leaderboard_screen.dart';
import '../../dugnad/shop/club_shop_screen.dart';
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

  /// Dugnad tabs mount on first visit so Kampanje/Toppliste/Profil skip cold-start APIs.
  final Set<int> _visitedDugnadTabs = {0};

  /// Keyword from home search bar when opening the shell search tab.
  final ValueNotifier<String> searchLaunchKeyword = ValueNotifier('');

  static const int searchTabIndex = 1; // Søk is now index 1 (commercial)
  static const int dugnadHomeTabIndex = 0;
  static const int dugnadKampanjeTabIndex = 1;
  static const int dugnadShopTabIndex = 2;
  static const int dugnadLeaderboardTabIndex = 3;
  static const int dugnadProfileTabIndex = 4;

  bool get _isDugnad => DugnadState.instance.isDugnadMode;

  // ── Commercial 6-tab layout ──────────────────────────────────────
  // 0: Hjem   1: Søk   2: Feed   3: AI   4: Kurv   5: Profil
  // ── Dugnad 5-tab layout ──────────────────────────────────────────
  // 0: Hjem   1: Kampanje   2: Shop   3: Toppliste   4: Profil
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

  /// Maps legacy homeIndex values to the dugnad 5-tab positions.
  static int _remapDugnadIndex(int legacy) {
    const mapping = {
      0: dugnadHomeTabIndex,
      1: dugnadKampanjeTabIndex,
      2: dugnadHomeTabIndex,
      3: dugnadHomeTabIndex,
      4: dugnadProfileTabIndex,
    };
    return mapping[legacy] ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final int initialTab = _isDugnad
        ? _remapDugnadIndex(widget.homeIndex)
        : _remapLegacyIndex(widget.homeIndex);
    controller = PageController(initialPage: initialTab);
    setState(() {
      selectedPos = initialTab;
    });
    DugnadState.instance.revision.addListener(_onDugnadStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _armPendingReferrerPointsPop();
    });
  }

  Future<void> _armPendingReferrerPointsPop() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    DugnadState.instance.markHomeShellReady();
  }

  void _onDugnadStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DugnadState.instance.markHomeShellNotReady();
    DugnadState.instance.revision.removeListener(_onDugnadStateChanged);
    super.dispose();
  }

  /// Switch bottom-nav tab. Pass [animate]: false for instant jumps (e.g. tour
  /// relaunch from profile) so club-home tour targets can mount without waiting
  /// out the 1s page animation.
  void switchToTab(int index, {bool animate = true}) {
    if (_isDugnad && !_visitedDugnadTabs.contains(index)) {
      setState(() => _visitedDugnadTabs.add(index));
    }
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

  /// Back affordance for dugnad root tabs (Kampanje / Toppliste):
  /// pop a pushed route when possible, otherwise switch to Hjem.
  void backOrHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    switchToTab(dugnadHomeTabIndex);
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

  /// Gap between the campaign tracker pill and the top of the nav pill —
  /// `.cp-tracker { bottom: 92px }` minus the 78px `.ae-pillnav` occupies on
  /// the design frame.
  static const double _kTrackerNavGap = 14;

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

  Widget _buildLeaderboardIcon({required bool active}) {
    return Icon(
      Icons.emoji_events_outlined,
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
    final dugnadPalette =
        _isDugnad ? DugnadState.instance.themePalette : null;
    final browseNoClub =
        _isDugnad && !DugnadState.instance.hasClub;

    final pageView = PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: _isDugnad
            ? [
                const DGHome(),
                _visitedDugnadTabs.contains(dugnadKampanjeTabIndex)
                    ? const KampanjeScreen()
                    : const SizedBox.shrink(),
                _visitedDugnadTabs.contains(dugnadShopTabIndex)
                    ? const ClubShopScreen()
                    : const SizedBox.shrink(),
                _visitedDugnadTabs.contains(dugnadLeaderboardTabIndex)
                    ? const LeaderboardScreen()
                    : const SizedBox.shrink(),
                _visitedDugnadTabs.contains(dugnadProfileTabIndex)
                    ? const Account()
                    : const SizedBox.shrink(),
              ]
            : [
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
      // Persistent campaign tracker pill sits above the nav across dugnad tabs;
      // non-blocking (a bounded Positioned — taps outside it fall through).
      body: _isDugnad
          ? Stack(
              children: [
                pageView,
                Positioned(
                  left: context.dp(14),
                  right: context.dp(14),
                  // Design puts `.cp-tracker` at `bottom: 92px`, which on the
                  // 375 frame (no safe-area) is the 78px pill nav plus a 14px
                  // gap. Hard-coding 92 loses that gap on a home-indicator
                  // phone, where the nav's own inset lifts it past 92 and the
                  // two pills touch — so measure from the nav instead.
                  bottom: aePillNavReservedHeight(context) +
                      context.dp(_kTrackerNavGap),
                  child: CampaignTracker(
                    onOpenOverview: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CampaignPurchasesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : pageView,
      // Floating pill — keep Scaffold's bottom slot fully transparent so the
      // club page shows through (no solid foot plate behind the nav).
      bottomNavigationBar: CircleNavBar(
        activeIndex: selectedPos,
        onTap: (index) => _onItemTapped(index),
        color: Colors.transparent,
        tabCurve: Curves.easeOutCubic,
        tabDuration: const Duration(milliseconds: 280),
        compactItems: _isDugnad,
        compactGap: 2,
        compactWidthFactor: _isDugnad ? 0.98 : 0.90,
        activePillGradient: browseNoClub
            ? ReenPreClubTokens.shinyCoral
            : dugnadPalette?.shinyGradient,
        pillBorderColor: browseNoClub
            ? const Color(0x14081626)
            : dugnadPalette?.primary.withValues(alpha: 0.12),
        activePillShadowColor: browseNoClub
            ? ReenPreClubTokens.coral.withValues(alpha: 0.42)
            : dugnadPalette?.primary.withValues(alpha: 0.55),
        levels: _isDugnad
            ? const [
                'Hjem',
                'Kampanje',
                'Shop',
                'Toppliste',
                'Profil',
              ]
            : const ['Hjem', 'Søk', 'Feed', 'AI', 'Kurv', 'Profil'],
        activeIcons: _isDugnad
            ? [
                _navSvgActive('assets/svgs/menu/home.svg'),
                _navSvgActive('assets/svgs/menu/box.svg'),
                _navSvgActive('assets/svgs/menu/shirt.svg'),
                _buildLeaderboardIcon(active: true),
                _navSvgActive('assets/svgs/menu/user.svg'),
              ]
            : [
                _navSvgActive('assets/svgs/menu/home.svg'),
                _navSvgActive('assets/svgs/menu/search.svg'),
                _buildFeedIcon(active: true),
                _buildAiIcon(active: true),
                _buildCartIconForNav(selected: true),
                _navSvgActive('assets/svgs/menu/user.svg'),
              ],
        inactiveIcons: _isDugnad
            ? [
                _navSvgInactive('assets/svgs/menu/home.svg'),
                _navSvgInactive('assets/svgs/menu/box.svg'),
                _navSvgInactive('assets/svgs/menu/shirt.svg'),
                _buildLeaderboardIcon(active: false),
                _navSvgInactive('assets/svgs/menu/user.svg'),
              ]
            : [
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
      child: _isDugnad
          ? DugnadClubThemeScope(
              palette: dugnadPalette!,
              child: themedScaffold,
            )
          : themedScaffold,
    );
  }
}
