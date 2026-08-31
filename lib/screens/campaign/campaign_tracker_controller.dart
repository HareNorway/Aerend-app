import 'package:flutter/widgets.dart';

import '../../utils/utils.dart';
import '../dugnad/dugnad_state.dart';
import 'campaign_repo.dart';
import 'models/campaign_order_pojo.dart';

/// App-scoped state for the persistent campaign tracker pill.
///
/// - Holds the active (server-state awaiting/locked) purchases, kept across shell
///   rebuilds so re-mounting paints instantly (peek), then refreshes.
/// - Dismissals are IN-MEMORY ONLY (a runtime Set) — no persistence; they last
///   the whole session (opening the overview does NOT bring a dismissed pill
///   back) and vanish on app reload.
/// - Refreshes on club switch / logout (DugnadState.revision) and app resume.
class CampaignTrackerController extends ChangeNotifier
    with WidgetsBindingObserver {
  CampaignTrackerController._() {
    WidgetsBinding.instance.addObserver(this);
    DugnadState.instance.revision.addListener(_onClubOrModeChanged);
  }

  static final CampaignTrackerController instance = CampaignTrackerController._();

  /// Test constructor: no lifecycle/revision observers, no network — drive state
  /// via [debugSetActive].
  @visibleForTesting
  CampaignTrackerController.test();

  /// Injectable for tests.
  CampaignRepo repo = CampaignRepo();

  /// Seed active purchases directly (tests only).
  @visibleForTesting
  void debugSetActive(List<CampaignMyOrder> orders) {
    _loaded = true;
    _setActive(orders);
  }

  final List<CampaignMyOrder> _active = [];
  final Set<String> _dismissed = {};
  bool _loaded = false;
  bool _loading = false;

  /// Active purchases (server state awaiting|locked), soonest windowStart first,
  /// excluding in-memory-dismissed ones. Nulls (no window) sort last.
  List<CampaignMyOrder> get visibleActive {
    final list = _active
        .where((o) => !_dismissed.contains(o.orderNo))
        .toList()
      ..sort((a, b) {
        final aw = a.windowStart, bw = b.windowStart;
        if (aw == null && bw == null) return 0;
        if (aw == null) return 1;
        if (bw == null) return -1;
        return aw.compareTo(bw);
      });
    return list;
  }

  /// The purchase the pill shows — the soonest non-dismissed active one.
  CampaignMyOrder? get soonest =>
      visibleActive.isEmpty ? null : visibleActive.first;

  /// Total non-dismissed active purchases (drives the "+N mer" badge = count-1).
  int get activeCount => visibleActive.length;

  bool get hasLoaded => _loaded;

  /// Dismiss one purchase from the pill (in memory only, for the rest of the
  /// session). The next-soonest shows.
  void dismiss(String orderNo) {
    if (orderNo.isEmpty) return;
    _dismissed.add(orderNo);
    notifyListeners();
  }

  /// Load once (used by the widget on first mount); no-op if already loaded.
  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    await refresh();
  }

  /// Fetch active campaign purchases and update the pill.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      if (!DugnadState.instance.isDugnadMode ||
          !DugnadState.instance.hasClub ||
          !isLoggedIn()) {
        _setActive(const []);
        return;
      }
      final response = await repo.getMyOrders();
      if (response is! Map) {
        _setActive(const []);
        return;
      }
      final pojo = CampaignMyOrdersListPojo.fromJson(
          Map<String, dynamic>.from(response));
      final active = pojo.orders
          .where((o) =>
              o.state == CampaignPurchaseState.awaiting ||
              o.state == CampaignPurchaseState.locked)
          .toList();
      _setActive(active);
    } catch (_) {
      // Keep whatever we last had; never surface an error in a passive pill.
    } finally {
      _loaded = true;
      _loading = false;
    }
  }

  void _setActive(List<CampaignMyOrder> orders) {
    _active
      ..clear()
      ..addAll(orders);
    notifyListeners();
  }

  void _onClubOrModeChanged() {
    // Club switch / logout → drop cache + dismissals and refetch for the new club.
    _dismissed.clear();
    _loaded = false;
    refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _loaded) {
      refresh();
    }
  }

  @override
  void dispose() {
    // Singleton — normally never disposed; provided for completeness/tests.
    WidgetsBinding.instance.removeObserver(this);
    DugnadState.instance.revision.removeListener(_onClubOrModeChanged);
    super.dispose();
  }
}
