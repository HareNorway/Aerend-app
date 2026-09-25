import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../hjelp/demo_panel.dart';
import '../kasse/bestilling_sheet.dart';
import '../kit/bergen_kit.dart';
import 'hjelp_sheet.dart';
import 'leveringskode_card.dart';
import 'levert_screen.dart';
import 'sporing_copy.dart';

/// `sporing` (≈L5287–5760 in `Ærend Kunde Bergen.dc.html`) at
/// `/bergen/sporing/{id}`.
///
/// Data: `ops.customer.tracking` polled every ten seconds (the events channel
/// when broadcasting is on is a later wiring — there is no socket client in
/// the app). The top line "Live · {stadie}" (or "Finner bud"), the ETA and
/// "om N min", the **Sporing · stadier** stepper with labels by `mode`, the
/// **stadieskifte** overlay on every stage change ("Steg N av 4", "+X poeng"
/// from `GET /api/points/me`, guarded), the stage cards (Bekreftet ·
/// Tilberedes · På vei / Klar for henting · Levert), the **Ægil-veileder**
/// line, **Avslutt** and the completion layer. The app never maps states: the
/// stage, its label, who delivers, who to call and whether a courier is
/// being found all come from the payload.
class SporingScreen extends StatefulWidget {
  const SporingScreen({
    super.key,
    this.orderId,
    this.api,
    this.preloaded,
    this.poll = true,
    this.showMap = true,
  });

  final int? orderId;
  final OpsCustomerApi? api;

  /// Tests inject the payload and disable polling / the platform map.
  final OpsTracking? preloaded;
  final bool poll;
  final bool showMap;

  static const Duration pollEvery = Duration(seconds: 10);

  @override
  State<SporingScreen> createState() => _SporingScreenState();
}

class _SporingScreenState extends State<SporingScreen> {
  bool _routeRead = false;
  int _id = 0;
  OpsTracking? _t;
  bool _missing = false;
  bool _offline = false;
  bool _forceOffline = false;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _conn;
  int? _lastStage;
  bool _shift = false;
  int _shiftPoints = 0;
  int? _pointsBefore;
  bool _waited = false;
  GoogleMapController? _map;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    _id =
        widget.orderId ??
        int.tryParse(BergenRoutes.argsOf(context)['id'] ?? '') ??
        0;
    if (widget.preloaded != null) {
      _t = widget.preloaded;
      _lastStage = _t!.stage;
    } else {
      _refresh();
    }
    if (widget.poll) {
      _timer = Timer.periodic(SporingScreen.pollEvery, (_) => _refresh());
      _conn = Connectivity().onConnectivityChanged.listen((results) {
        final down = results.every((r) => r == ConnectivityResult.none);
        if (mounted && down != _offline) setState(() => _offline = down);
        if (!down) _refresh();
      });
    }
    _registerDemo();
    _loadPoints();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _conn?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadPoints() async {
    final me = await _api.pointsMe();
    final available = (me?['points'] is Map)
        ? (me!['points']['available'] as num?)
        : null;
    if (mounted && available != null) _pointsBefore ??= available.toInt();
  }

  Future<void> _refresh() async {
    if (_forceOffline) return;
    try {
      final json = await _api.tracking(_id);
      if (!mounted) return;
      final next = OpsTracking.fromJson(json);
      final changed = _lastStage != null && next.stage != _lastStage;
      setState(() {
        _t = next;
        _offline = false;
        _missing = false;
      });
      if (changed) _onStageChange(next);
      _lastStage = next.stage;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_t == null) _missing = true;
        _offline = true;
      });
    }
  }

  Future<void> _onStageChange(OpsTracking next) async {
    HapticFeedback.mediumImpact();
    var earned = 0;
    final me = await _api.pointsMe();
    final available = (me?['points'] is Map)
        ? (me!['points']['available'] as num?)?.toInt()
        : null;
    if (available != null &&
        _pointsBefore != null &&
        available > _pointsBefore!) {
      earned = available - _pointsBefore!;
      _pointsBefore = available;
    }
    if (!mounted) return;
    setState(() {
      _shift = true;
      _shiftPoints = earned;
    });
    Future<void>.delayed(
      BergenTokens.motion(context, const Duration(milliseconds: 1750)),
      () {
        if (mounted) setState(() => _shift = false);
      },
    );
    if (next.stage == 3 && next.isDelivered) {
      Future<void>.delayed(const Duration(milliseconds: 1900), () {
        if (mounted) _toLevert();
      });
    }
  }

  void _toLevert() {
    final t = _t;
    if (t == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/bergen/levert/$_id'),
        builder: (_) => LevertScreen(orderId: _id, tracking: t, api: _api),
      ),
    );
  }

  void _openHelp([HjelpState initial = HjelpState.main]) {
    final t = _t;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/bergen/sporing/$_id/hjelp'),
        builder: (_) =>
            HjelpScreen(orderId: _id, tracking: t, api: _api, initial: initial),
      ),
    );
  }

  Future<void> _wait() async {
    final res = await _api.problem(_id, kind: 'wait');
    if (!mounted) return;
    setState(() => _waited = true);
    showBergenToast(
      context,
      res == null ? BergenRoutes.kommerSnart : SporingCopy.a1_sporing_venter,
    );
  }

  Future<void> _cancel() async {
    final res = await _api.problem(_id, kind: 'cancel');
    if (!mounted) return;
    if (res == null || res['error'] != null) {
      showBergenToast(
        context,
        '${res?['message'] ?? BergenRoutes.kommerSnart}',
      );
      return;
    }
    showBergenToast(context, SporingCopy.a1_sporing_refundert);
    await _refresh();
  }

  // ── demo panel (debug only) ────────────────────────────────────────────

  void _registerDemo() {
    if (!kDebugMode) return;
    Future<void> step(String to) async {
      final res = await _api.transition(_id, to);
      if (!mounted) return;
      showBergenToast(
        context,
        res == null
            ? BergenRoutes.kommerSnart
            : '${res['event']?['type'] ?? to}',
      );
      await _refresh();
    }

    BergenDemoPanel.register(
      DemoScenario(
        id: 'sporing_ny',
        label: SporingCopy.a1_sporing_demo_ny,
        run: (_) => step('accepted'),
      ),
    );
    BergenDemoPanel.register(
      DemoScenario(
        id: 'sporing_neste',
        label: SporingCopy.a1_sporing_demo_neste,
        run: (_) async {
          const next = {
            'placed': 'accepted',
            'accepted': 'seen',
            'seen': 'ready',
            'ready': 'picked_up',
            'picked_up': 'arrived_customer',
            'arrived_customer': 'delivered',
          };
          final to = next[_t?.state ?? 'placed'];
          if (to != null) await step(to);
        },
      ),
    );
    BergenDemoPanel.register(
      DemoScenario(
        id: 'sporing_usett',
        label: SporingCopy.a1_sporing_demo_usett,
        run: (_) async {
          // Accepted and never seen: the ops:sweep on the local stack writes the
          // escalation rung, after which the payload says unseen_by_store.
          await step('accepted');
        },
      ),
    );
    BergenDemoPanel.register(
      DemoScenario(
        id: 'sporing_kode_ok',
        label: SporingCopy.a1_sporing_demo_kode_ok,
        run: (_) async {
          final pin = _t?.deliveryCode?.pin;
          if (pin == null) return;
          final res = await _api.proofPin(
            _id,
            pin,
            courierId: _t?.courier?.id ?? 0,
          );
          if (mounted)
            showBergenToast(
              context,
              res?['ok'] == true
                  ? SporingCopy.a1_sporing_kode_bekreftet
                  : '${res?['message'] ?? ''}',
            );
          await _refresh();
        },
      ),
    );
    BergenDemoPanel.register(
      DemoScenario(
        id: 'sporing_pin_feil',
        label: SporingCopy.a1_sporing_demo_pin_feil,
        run: (_) async {
          final pin = _t?.deliveryCode?.pin ?? '0000';
          final wrong = pin == '0000' ? '1111' : '0000';
          Map<String, dynamic>? res;
          for (var i = 0; i < 3; i++) {
            res = await _api.proofPin(
              _id,
              wrong,
              courierId: _t?.courier?.id ?? 0,
            );
          }
          if (mounted) showBergenToast(context, '${res?['message'] ?? ''}');
          await _refresh();
        },
      ),
    );
    BergenDemoPanel.register(
      DemoScenario(
        id: 'uten_nett',
        label: SporingCopy.a1_sporing_demo_offline,
        run: (_) async {
          setState(() {
            _forceOffline = !_forceOffline;
            _offline = _forceOffline;
          });
          if (!_forceOffline) await _refresh();
        },
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final t = _t;
    if (_missing && t == null) {
      return Scaffold(
        backgroundColor: BergenTokens.tealDeep,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            SporingCopy.a1_sporing_ikke_funnet,
            key: const Key('a1_sporing_ikke_funnet'),
            style: bText(
              context,
              13,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    if (t == null) {
      return Scaffold(
        backgroundColor: BergenTokens.tealDeep,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: BergenTokens.mint),
              SizedBox(height: 12 * s),
              Text(
                SporingCopy.a1_sporing_laster,
                style: bText(
                  context,
                  12,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final stages = SporingCopy.stages(t.isPickup);
    final now = DateTime.now();
    final minutes = t.minutesLeft(now);
    final lines = SporingCopy.lines(
      t.isPickup,
      partner: t.isPartner,
      bike: t.courier?.onBike ?? true,
      store: t.store?.name,
    );
    final gift = '${t.raw['gift_to'] ?? ''}';

    return Scaffold(
      backgroundColor: BergenTokens.tealDeep,
      body: Stack(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2A6272),
                  Color(0xFF1E4F5C),
                  Color(0xFF0F1F2B),
                ],
                stops: [0, .4, 1],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16 * s,
                safeTop + 10 * s,
                16 * s,
                40 * s,
              ),
              children: [
                // ── top line ──────────────────────────────────────────
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
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20 * s,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Container(
                      width: 8 * s,
                      height: 8 * s,
                      decoration: BoxDecoration(
                        color: t.findingCourier
                            ? BergenTokens.lantern
                            : BergenTokens.mint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    Expanded(
                      child: Text(
                        t.isCancelled
                            ? SporingCopy.a1_sporing_avbestilt
                            : t.findingCourier
                            ? SporingCopy.order_status_finding_courier
                            : SporingCopy.a1_sporing_live(t.stageLabel),
                        key: const Key('a1_sporing_topline'),
                        style: bText(
                          context,
                          12.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (t.isPartner)
                      Flexible(
                        child: Text(
                          SporingCopy.a1_sporing_leveres_av(t.deliveredByLabel),
                          key: const Key('a1_sporing_leveres_av'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w800,
                            color: const Color(0xFF9FD3DE),
                          ),
                        ),
                      ),
                    SizedBox(width: 8 * s),
                    GestureDetector(
                      key: const Key('a1_sporing_hjelp_knapp'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _openHelp,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * s,
                          vertical: 6 * s,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x2EFFFFFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          SporingCopy.a1_sporing_hjelp,
                          style: bText(
                            context,
                            11,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_offline)
                  Padding(
                    padding: EdgeInsets.only(top: 10 * s),
                    child: const BergenOfflineBanner(
                      key: Key('a1_sporing_offline'),
                    ),
                  ),
                SizedBox(height: 14 * s),
                // ── ETA ───────────────────────────────────────────────
                Text(
                  _etaLabel(t),
                  key: const Key('a1_sporing_eta_label'),
                  style: bText(
                    context,
                    11,
                    weight: FontWeight.w800,
                    color: const Color(0xFF9FD3DE),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _etaBig(t),
                        key: const Key('a1_sporing_eta'),
                        style: bDisplay(
                          context,
                          t.stage == 3 ? 28 : 40,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ).copyWith(letterSpacing: -1, height: 1),
                      ),
                    ),
                    if (minutes != null && t.stage < 3 && !t.isPickup) ...[
                      SizedBox(width: 10 * s),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6 * s),
                        child: Text(
                          SporingCopy.a1_sporing_om_min(minutes),
                          key: const Key('a1_sporing_om_min'),
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w800,
                            color: BergenTokens.mint,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (gift.isNotEmpty && t.stage < 3)
                  Text(
                    SporingCopy.a1_sporing_gave_venter(gift),
                    key: const Key('a1_sporing_gave'),
                    style: bText(
                      context,
                      11.5,
                      weight: FontWeight.w700,
                      color: BergenTokens.lantern,
                    ),
                  ),
                SizedBox(height: 14 * s),
                // ── stepper ───────────────────────────────────────────
                BergenStepper(
                  key: const Key('a1_sporing_stepper'),
                  steps: stages,
                  current: t.stage,
                  onDark: true,
                ),
                SizedBox(height: 14 * s),
                // ── Ægil-veileder ─────────────────────────────────────
                Container(
                  key: const Key('a1_sporing_veileder'),
                  padding: EdgeInsets.all(12 * s),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: const Color(0x2EFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        BergenAssets.aegilPopup,
                        width: 40 * s,
                        height: 40 * s,
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  SporingCopy.a1_sporing_aegil,
                                  style: bText(
                                    context,
                                    12,
                                    weight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4 * s),
                                Flexible(
                                  child: Text(
                                    SporingCopy.a1_sporing_aegil_folger,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: bText(
                                      context,
                                      11,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFF9FD3DE),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              t.isCancelled
                                  ? SporingCopy.a1_sporing_avbestilt
                                  : lines[t.stage.clamp(0, 3)],
                              style: bText(
                                context,
                                12.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFFDCE9EC),
                              ),
                            ),
                            Text(
                              t.findingCourier
                                  ? SporingCopy.a1_sporing_finner_bud_hint
                                  : t.stage >= 3
                                  ? SporingCopy.a1_sporing_oppdrag_fullfort
                                  : SporingCopy.a1_sporing_neste(
                                      stages[(t.stage + 1).clamp(0, 3)],
                                    ),
                              key: const Key('a1_sporing_neste_hint'),
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w800,
                                color: BergenTokens.mint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14 * s),
                // ── stage card ────────────────────────────────────────
                _stageCard(context, t),
                SizedBox(height: 14 * s),
                // ── completion layer ──────────────────────────────────
                if (t.stage >= 2 || t.deliveryCode != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BudIdentitetPill(tracking: t),
                  ),
                if (t.deliveryCode != null && !t.isCancelled) ...[
                  SizedBox(height: 10 * s),
                  LeveringskodeCard(
                    code: t.deliveryCode!,
                    offline: _offline,
                    onDark: true,
                  ),
                ],
                if (t.unseenByStore &&
                    !_waited &&
                    !t.isCancelled &&
                    t.stage == 0) ...[
                  SizedBox(height: 10 * s),
                  ValgSomVenterCard(
                    storeName: t.store?.name ?? SporingCopy.a1_sporing_Butikken,
                    onWait: _wait,
                    onCancel: _cancel,
                  ),
                ],
                SizedBox(height: 16 * s),
                // ── Avslutt ───────────────────────────────────────────
                Row(
                  children: [
                    BergenChip(
                      key: const Key('a1_sporing_sammendrag'),
                      label: SporingCopy.a1_sporing_sammendrag,
                      onDark: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: RouteSettings(
                            name: '/bergen/bestilling/$_id',
                          ),
                          builder: (_) =>
                              BestillingScreen(orderId: _id, api: _api),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    BergenChip(
                      key: const Key('a1_sporing_detaljer'),
                      label: SporingCopy.a1_sporing_detaljer,
                      onDark: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: RouteSettings(
                            name: '/bergen/bestilling/$_id',
                          ),
                          builder: (_) =>
                              BestillingScreen(orderId: _id, api: _api),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12 * s),
                if (t.stage >= 3)
                  BergenCta3d(
                    key: const Key('a1_sporing_avslutt'),
                    label: SporingCopy.a1_sporing_avslutt,
                    onPressed: _toLevert,
                  )
                else
                  BergenCard(
                    key: const Key('a1_sporing_fjordfiske'),
                    onDark: true,
                    onTap: () =>
                        BergenRoutes.push(context, '/bergen/fjordfiske'),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14 * s,
                      vertical: 12 * s,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phishing_rounded,
                          color: BergenTokens.lantern,
                          size: 20 * s,
                        ),
                        SizedBox(width: 10 * s),
                        Text(
                          SporingCopy.a1_sporing_fjordfiske,
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6 * s),
                        Flexible(
                          child: Text(
                            SporingCopy.a1_sporing_mens_du_venter,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bText(
                              context,
                              11.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF9FD3DE),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: const Color(0x8CFFFFFF),
                          size: 20 * s,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // ── stadieskifte overlay ──────────────────────────────────────
          if (_shift)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  key: const Key('a1_sporing_stadieskifte'),
                  color: const Color(0xB30F1F2B),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        SporingCopy.a1_sporing_steg(t.stage + 1, 4),
                        style: bText(
                          context,
                          12,
                          weight: FontWeight.w800,
                          color: const Color(0xFF9FD3DE),
                        ),
                      ),
                      Text(
                        t.stageLabel,
                        style: bDisplay(
                          context,
                          34,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (_shiftPoints > 0)
                        Text(
                          SporingCopy.a1_sporing_pluss_poeng(_shiftPoints),
                          key: const Key('a1_sporing_skifte_poeng'),
                          style: bText(
                            context,
                            14,
                            weight: FontWeight.w800,
                            color: BergenTokens.mint,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _etaLabel(OpsTracking t) {
    if (t.isCancelled) return SporingCopy.a1_sporing_avbestilt;
    if (t.isPickup) {
      return switch (t.stage) {
        0 || 1 => SporingCopy.a1_sporing_hentes_hos(t.store?.name ?? ''),
        2 => SporingCopy.a1_sporing_star_klar,
        _ => SporingCopy.a1_sporing_hentet_takk,
      };
    }
    if (t.stage >= 3) {
      final delivered = DateTime.tryParse(
        '${t.raw['delivered_at'] ?? ''}',
      )?.toLocal();
      final end = t.promisedEnd;
      if (t.isPartner)
        return SporingCopy.a1_sporing_levert_av(t.deliveredByLabel);
      if (delivered != null && end != null && end.isAfter(delivered))
        return SporingCopy.a1_sporing_levert_min_for(
          end.difference(delivered).inMinutes,
        );
      return stagesLabelDelivered;
    }
    if (t.isPartner && t.stage == 2)
      return SporingCopy.a1_sporing_butikken_paa_vei;
    return SporingCopy.a1_sporing_kommer;
  }

  String get stagesLabelDelivered => SporingCopy.stages(false)[3];

  String _etaBig(OpsTracking t) {
    if (t.isCancelled) return '—';
    if (t.isPickup) {
      final ready = t.predictedReadyAt ?? t.promisedEnd;
      return switch (t.stage) {
        0 || 1 =>
          ready == null
              ? ''
              : SporingCopy.a1_sporing_klar_kl(OpsTracking.hhmm(ready)),
        2 => SporingCopy.a1_sporing_klar_naa,
        _ => OpsTracking.hhmm(
          DateTime.tryParse('${t.raw['delivered_at'] ?? ''}')?.toLocal() ??
              DateTime.now(),
        ),
      };
    }
    if (t.stage >= 3)
      return OpsTracking.hhmm(
        DateTime.tryParse('${t.raw['delivered_at'] ?? ''}')?.toLocal() ??
            DateTime.now(),
      );
    if (t.stage == 2 && t.promisedEnd != null)
      return OpsTracking.hhmm(t.promisedEnd!);
    return t.windowText;
  }

  Widget _stageCard(BuildContext context, OpsTracking t) {
    final s = context.bs;
    switch (t.stage) {
      case 0:
        return BergenCard(
          key: const Key('a1_sporing_kort_bekreftet'),
          onDark: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SporingCopy.a1_sporing_mottatt,
                style: bText(
                  context,
                  10,
                  weight: FontWeight.w800,
                  color: BergenTokens.mint,
                ),
              ),
              Text(
                t.store?.name ?? '',
                style: bDisplay(
                  context,
                  16,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (t.code != null)
                Text(
                  '${t.code}',
                  style: bText(
                    context,
                    11.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF9FD3DE),
                  ),
                ),
              if (t.raw['delivery_address'] != null)
                Text(
                  '${t.raw['delivery_address']}',
                  style: bText(
                    context,
                    11.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFFDCE9EC),
                  ),
                ),
            ],
          ),
        );
      case 1:
        final ready = t.predictedReadyAt;
        final left = ready == null
            ? null
            : ready.difference(DateTime.now()).inMinutes;
        return BergenCard(
          key: const Key('a1_sporing_kort_tilberedes'),
          onDark: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.code ?? ''}${ready != null ? ' · kl. ${OpsTracking.hhmm(ready)}' : ''}',
                style: bText(
                  context,
                  11.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF9FD3DE),
                ),
              ),
              Text(
                SporingCopy.a1_sporing_tilberedes_kicker,
                style: bText(
                  context,
                  10,
                  weight: FontWeight.w800,
                  color: BergenTokens.orangeLight,
                ),
              ),
              if (left != null && left >= 0)
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16 * s,
                      color: BergenTokens.orange,
                    ),
                    SizedBox(width: 6 * s),
                    Text(
                      '${SporingCopy.a1_sporing_paa_komfyren} · ${SporingCopy.a1_sporing_min_igjen(left)}',
                      key: const Key('a1_sporing_komfyren'),
                      style: bText(
                        context,
                        12.5,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      case 2:
        if (t.isPickup) {
          final who =
              '${t.raw['customer_first_name'] ?? prefGetString(prefUserName).split(' ').first}';
          return BergenCard(
            key: const Key('a1_sporing_kort_hentklar'),
            onDark: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SporingCopy.a1_sporing_klar_kicker,
                  style: bText(
                    context,
                    10,
                    weight: FontWeight.w800,
                    color: BergenTokens.mint,
                  ),
                ),
                Text(
                  SporingCopy.a1_sporing_disken(who),
                  style: bDisplay(
                    context,
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (t.store?.address != null)
                  Text(
                    t.store!.address!,
                    style: bText(
                      context,
                      11.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFFDCE9EC),
                    ),
                  ),
                SizedBox(height: 10 * s),
                BergenCta3d(
                  key: const Key('a1_sporing_vis_veien'),
                  label: SporingCopy.a1_sporing_vis_veien,
                  icon: Icons.directions_walk_rounded,
                  expand: false,
                  onPressed: () => _showMapSheet(t),
                ),
              ],
            ),
          );
        }
        return _mapCard(t);
      default:
        return BergenCard(
          key: const Key('a1_sporing_kort_levert'),
          onDark: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SporingCopy.stages(t.isPickup)[3],
                style: bDisplay(
                  context,
                  18,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                SporingCopy.a1_sporing_haaper,
                style: bText(
                  context,
                  12.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFFDCE9EC),
                ),
              ),
            ],
          ),
        );
    }
  }

  /// På vei: the route (store → address), a live marker only when the payload
  /// has a position, bike or car from the courier; partner orders show the
  /// route only. The platform map is skipped in tests.
  Widget _mapCard(OpsTracking t) {
    final s = context.bs;
    final store = t.store;
    final lat = double.tryParse('${t.raw['lat'] ?? ''}');
    final lng = double.tryParse('${t.raw['lng'] ?? ''}');
    final pos = t.livePosition;
    return ClipRRect(
      key: const Key('a1_sporing_kort_paavei'),
      borderRadius: BorderRadius.circular(22 * s),
      child: SizedBox(
        height: 220 * s,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.showMap && store?.lat != null && store?.lng != null)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    pos?.lat ?? store!.lat!,
                    pos?.lng ?? store!.lng!,
                  ),
                  zoom: 14,
                ),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (c) => _map = c,
                polylines: {
                  if (lat != null && lng != null)
                    Polyline(
                      polylineId: const PolylineId('rute'),
                      color: BergenTokens.orange,
                      width: 4,
                      points: [
                        LatLng(store!.lat!, store.lng!),
                        LatLng(lat, lng),
                      ],
                    ),
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('butikk'),
                    position: LatLng(store!.lat!, store.lng!),
                    infoWindow: InfoWindow(title: store.name),
                  ),
                  if (lat != null && lng != null)
                    Marker(
                      markerId: const MarkerId('hjem'),
                      position: LatLng(lat, lng),
                    ),
                  if (pos != null && !t.isPartner)
                    Marker(
                      markerId: const MarkerId('bud'),
                      position: LatLng(pos.lat, pos.lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                },
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF12333D), Color(0xFF0B2634)],
                  ),
                ),
              ),
            Positioned(
              left: 12 * s,
              top: 12 * s,
              child: Container(
                key: Key(
                  pos != null && !t.isPartner
                      ? 'a1_sporing_live_marker'
                      : 'a1_sporing_ingen_marker',
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * s,
                  vertical: 6 * s,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC0F1F2B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.isPartner
                          ? Icons.storefront_rounded
                          : ((t.courier?.onBike ?? true)
                                ? Icons.pedal_bike_rounded
                                : Icons.directions_car_rounded),
                      key: Key(
                        t.isPartner
                            ? 'a1_sporing_ikon_butikk'
                            : ((t.courier?.onBike ?? true)
                                  ? 'a1_sporing_ikon_sykkel'
                                  : 'a1_sporing_ikon_bil'),
                      ),
                      size: 14 * s,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6 * s),
                    Text(
                      t.isPartner
                          ? SporingCopy.a1_sporing_ingen_kart_partner
                          : pos != null
                          ? '${t.courier?.firstName ?? SporingCopy.a1_sporing_Budet} · ${t.minutesLeft(DateTime.now()) ?? 0} min'
                          : SporingCopy.a1_sporing_kart_kommer,
                      style: bText(
                        context,
                        10.5,
                        weight: FontWeight.w800,
                        color: Colors.white,
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

  /// `kArkErKart` — the pickup map sheet ("Vis veien").
  Future<void> _showMapSheet(OpsTracking t) {
    final store = t.store;
    return showBergenSheet<void>(
      context,
      builder: (ctx) => SizedBox(
        height: 320,
        child: widget.showMap && store?.lat != null && store?.lng != null
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(store!.lat!, store.lng!),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('butikk'),
                    position: LatLng(store.lat!, store.lng!),
                    infoWindow: InfoWindow(
                      title: store.name,
                      snippet: store.address,
                    ),
                  ),
                },
              )
            : Center(
                child: Text(
                  '${store?.name ?? ''}\n${store?.address ?? ''}',
                  textAlign: TextAlign.center,
                  style: bText(
                    ctx,
                    13,
                    weight: FontWeight.w700,
                    color: BergenTokens.ink,
                  ),
                ),
              ),
      ),
    );
  }
}
