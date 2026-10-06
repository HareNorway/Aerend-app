import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../snurre/snurre_launcher_policy.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../hjelp/demo_panel.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_kit.dart';
import 'hjelp_sheet.dart';
import 'leveringskode_card.dart';
import 'levert_screen.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_panel.dart';
import 'sporing_scene_disk.dart';
import 'sporing_scene_hus.dart';
import 'sporing_scene_kai.dart';
import 'sporing_scene_kart.dart';
import 'sporing_scene_kjokken.dart';
import 'sporing_skifte.dart';

/// `sporing` (Launch L6400–7277) at `/bergen/sporing/{id}`.
///
/// The header (back, the LIVE pill with the stage, help), the ETA block with
/// «om N min», one scene per stage (the quay, the kitchen, the counter or
/// the map, the house), the courier pill, the bottom panel (Leveringskode /
/// Ægil-veileder / vervebillett, the four stages, Sammendrag · Detaljer, the
/// actions), the Bestillingsdetaljer sheet and the stage-change overlay.
///
/// Data: `ops.customer.tracking` polled every ten seconds; the order's lines,
/// total and address from `ops.customer.orders`; the store's logo from the
/// store record. The app never maps states — the stage, its label, who
/// delivers and whether a courier is being found all come from the payload.
class SporingScreen extends StatefulWidget {
  const SporingScreen({super.key, this.orderId, this.api, this.preloaded, this.poll = true, this.showMap = true, this.fersk = false});

  final int? orderId;
  final OpsCustomerApi? api;

  /// Tests inject the payload and disable polling / the platform map.
  final OpsTracking? preloaded;
  final bool poll;
  final bool showMap;

  /// Right after a purchase: the vervebillett takes the panel's slot.
  final bool fersk;

  static const Duration pollEvery = Duration(seconds: 10);

  /// Points per stage for the Ægil-veileder chip.
  // UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
  static const List<int> stegPoeng = [8, 8, 8, 34];

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
  int _shiftSteg = 0;
  bool _waited = false;
  bool _fersk = false;
  bool _vervLukket = false;
  String? _vervKode;
  SpArk? _ark;
  SpOrdre? _ordre;
  String? _logo;
  int? _poeng;
  DateTime? _levertKl;
  bool _harness = false;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _id = widget.orderId ?? int.tryParse(args['id'] ?? '') ?? 0;
    _fersk = widget.fersk || args['fersk'] == '1';
    if (widget.preloaded != null) {
      _t = widget.preloaded;
      _lastStage = _t!.stage;
      if (_t!.stage == 3) _etterLevert(_t!);
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
      _loadOrdre();
      if (_fersk) _loadVerv();
    }
    _registerDemo();
    _harnessStart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _conn?.cancel();
    super.dispose();
  }

  // ── data ────────────────────────────────────────────────────────────────

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
      if (_lastStage == null && next.stage == 3) _etterLevert(next);
      _lastStage = next.stage;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_t == null) _missing = true;
        _offline = true;
      });
    }
  }

  /// The order's lines, total and address, and the store's logo.
  Future<void> _loadOrdre() async {
    try {
      final list = await _api.orders();
      final row = list.cast<Map<String, dynamic>?>().firstWhere((o) => '${o?['order_id']}' == '$_id', orElse: () => null);
      String? logo;
      String? adresse;
      final storeId = (row?['store_id'] as num?)?.toInt() ?? _t?.store?.id;
      if (storeId != null && storeId > 0) {
        final info = await OpsButikkApi().store(storeId);
        logo = info?.logoUrl;
        adresse = info?.address;
      }
      if (!mounted) return;
      setState(() {
        _logo = logo;
        if (row != null) _ordre = SpOrdre.fraJson(row, butikkAdresse: adresse, logo: logo);
      });
    } catch (_) {
      // The sheet shows what the tracking payload has.
    }
  }

  Future<void> _loadVerv() async {
    final json = await _api.referral();
    final referral = json?['referral'];
    if (!mounted || referral is! Map) return;
    final code = '${referral['code'] ?? ''}';
    if (code.isNotEmpty) setState(() => _vervKode = code);
  }

  /// Delivered: remember when, and fetch the order's points for SPART TID.
  void _etterLevert(OpsTracking t) {
    _levertKl ??= DateTime.tryParse('${t.raw['delivered_at'] ?? ''}')?.toLocal() ?? t.deliveryCode?.verifiedAt ?? DateTime.now();
    _api.pointsForOrder(_id).then((p) {
      final n = spPoengForOrdre(p, _id);
      if (mounted && n != null) setState(() => _poeng = n);
    });
  }

  Future<void> _onStageChange(OpsTracking next) async {
    HapticFeedback.mediumImpact();
    if (next.stage == 3) _etterLevert(next);
    _visSkifte(next.stage);
  }

  void _visSkifte(int steg) {
    setState(() {
      _shift = true;
      _shiftSteg = steg;
    });
    Future<void>.delayed(BergenTokens.motion(context, const Duration(milliseconds: SpSkifte.dur ~/ 1)), () {
      if (mounted) setState(() => _shift = false);
    });
  }

  void _toLevert() {
    final t = _t;
    if (t == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '$snurreLauncherHiddenRoutePrefix/bergen/levert/$_id'),
        builder: (_) => LevertScreen(orderId: _id, tracking: t, api: _api, levertKl: _levertKl, poeng: _poeng),
      ),
    );
  }

  void _openHelp([HjelpState initial = HjelpState.main]) {
    final t = _t;
    final reduce = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        settings: RouteSettings(name: '$snurreLauncherHiddenRoutePrefix/bergen/sporing/$_id/hjelp'),
        transitionDuration: Duration(milliseconds: reduce ? 0 : 380),
        reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 260),
        pageBuilder: (_, __, ___) => HjelpScreen(orderId: _id, tracking: t, api: _api, initial: initial, items: _ordre?.linjer.map((l) => l.navn).toList() ?? const [], adresse: _ordre?.adresse),
        transitionsBuilder: (context, a, _, child) {
          final p = cssSkjerm.transform(a.value);
          return Opacity(
            opacity: (.6 + .4 * p).clamp(0.0, 1.0) * (a.status == AnimationStatus.reverse ? p : 1),
            child: Transform.translate(offset: Offset(0, 26 * (1 - p)), child: child),
          );
        },
      ),
    );
  }

  Future<void> _wait() async {
    final res = await _api.problem(_id, kind: 'wait');
    if (!mounted) return;
    setState(() => _waited = true);
    showBergenToast(context, res == null ? BergenRoutes.kommerSnart : SporingCopy.a1_sporing_venter);
  }

  Future<void> _cancel() async {
    final res = await _api.problem(_id, kind: 'cancel');
    if (!mounted) return;
    if (res == null || res['error'] != null) {
      showBergenToast(context, '${res?['message'] ?? BergenRoutes.kommerSnart}');
      return;
    }
    showBergenToast(context, SporingCopy.a1_sporing_refundert);
    await _refresh();
  }

  void _kvittering() {
    final epost = prefGetString(prefEmail).trim();
    showBergenToast(context, SporingCopy.a1_sporing_kvittering_sendt(epost.isEmpty ? '…' : epost));
  }

  void _fjordfiske() => BergenRoutes.pushOr(context, '/bergen/fjordfiske', orElse: () => showBergenToast(context, BergenRoutes.kommerSnart));

  Future<void> _delBillett() async {
    final code = _vervKode;
    if (code == null) return;
    await Share.share(code);
  }

  Future<void> _kopierBillett() async {
    final code = _vervKode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showBergenToast(context, 'Kopiert · $code');
  }

  // ── harness (debug only) ────────────────────────────────────────────────

  void _harnessStart() {
    if (!kDebugMode || _harness || HjemHarness.sporing == null) return;
    _harness = true;
    if (HjemHarness.sporingFersk) _fersk = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var i = 0; i < 40 && _t == null && mounted; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      if (HjemHarness.sporingArk case final a?) {
        setState(() => _ark = a == 'detaljer' ? SpArk.detaljer : SpArk.sammendrag);
      }
      if (HjemHarness.sporingSkifte) {
        // Two seconds after the screen settles, so a screenshot can catch it.
        await Future<void>.delayed(const Duration(milliseconds: 2000));
        if (mounted) _visSkifte(_t?.stage ?? 0);
      }
      if (HjemHarness.sporingHjelp case final h?) {
        _openHelp(HjelpState.values.firstWhere((s) => s.name == h, orElse: () => HjelpState.main));
      }
    });
  }

  // ── demo panel (debug only) ────────────────────────────────────────────

  void _registerDemo() {
    if (!kDebugMode) return;
    Future<void> step(String to) async {
      final res = await _api.transition(_id, to);
      if (!mounted) return;
      showBergenToast(context, res == null ? BergenRoutes.kommerSnart : '${res['event']?['type'] ?? to}');
      await _refresh();
    }

    BergenDemoPanel.register(DemoScenario(id: 'sporing_ny', label: SporingCopy.a1_sporing_demo_ny, run: (_) => step('accepted')));
    BergenDemoPanel.register(
      DemoScenario(
        id: 'sporing_neste',
        label: SporingCopy.a1_sporing_demo_neste,
        run: (_) async {
          const next = {'placed': 'accepted', 'accepted': 'seen', 'seen': 'ready', 'ready': 'picked_up', 'picked_up': 'arrived_customer', 'arrived_customer': 'delivered'};
          final to = next[_t?.state ?? 'placed'];
          if (to != null) await step(to);
        },
      ),
    );
    BergenDemoPanel.register(DemoScenario(id: 'sporing_usett', label: SporingCopy.a1_sporing_demo_usett, run: (_) => step('accepted')));
    BergenDemoPanel.register(
      DemoScenario(
        id: 'sporing_kode_ok',
        label: SporingCopy.a1_sporing_demo_kode_ok,
        run: (_) async {
          final pin = _t?.deliveryCode?.pin;
          if (pin == null) return;
          final res = await _api.proofPin(_id, pin, courierId: _t?.courier?.id ?? 0);
          if (mounted) showBergenToast(context, res?['ok'] == true ? SporingCopy.a1_sporing_kode_bekreftet : '${res?['message'] ?? ''}');
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
            res = await _api.proofPin(_id, wrong, courierId: _t?.courier?.id ?? 0);
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

  // ── derived ─────────────────────────────────────────────────────────────

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
      final delivered = _levertKl;
      final end = t.promisedEnd;
      if (t.isPartner) return SporingCopy.a1_sporing_levert_av(t.deliveredByLabel);
      if (delivered != null && end != null && end.isAfter(delivered)) return SporingCopy.a1_sporing_levert_min_for(end.difference(delivered).inMinutes);
      return SporingCopy.stages(false)[3];
    }
    if (t.isPartner && t.stage == 2) return SporingCopy.a1_sporing_butikken_paa_vei;
    return SporingCopy.a1_sporing_kommer;
  }

  String _etaBig(OpsTracking t) {
    if (t.isCancelled) return '—';
    if (t.isPickup) {
      final ready = t.predictedReadyAt ?? t.promisedEnd;
      return switch (t.stage) {
        0 || 1 => ready == null ? '' : SporingCopy.a1_sporing_klar_kl(spKlokke(ready)),
        2 => SporingCopy.a1_sporing_klar_naa,
        _ => spKlokke(_levertKl ?? DateTime.now()),
      };
    }
    if (t.stage >= 3) return spKlokke(_levertKl ?? DateTime.now());
    if (t.stage == 2 && !t.isPartner && t.promisedEnd != null) return spKlokke(t.promisedEnd!);
    return t.hasWindow ? t.windowText : '…';
  }

  SpSceneInfo _info(OpsTracking t) {
    final o = _ordre;
    final now = DateTime.now();
    final end = t.promisedEnd;
    final start = t.promisedStart;
    final minLeft = t.minutesLeft(now);
    final windowSec = end != null && start != null ? math.max(60, end.difference(start).inSeconds) : 1800;
    final levert = _levertKl;
    final spart = levert != null && end != null && end.isAfter(levert) ? end.difference(levert).inSeconds : null;
    return SpSceneInfo(
      butikk: t.store?.name ?? o?.butikk ?? '',
      logo: _logo ?? o?.logo,
      linjer: o?.korteLinjer ?? const [],
      total: o == null ? '' : spKr(o.total),
      adresse: o?.adresse ?? '${t.raw['delivery_address'] ?? ''}',
      kode: t.code ?? '',
      klokke: o?.bestilt == null ? '' : spKlokke(o!.bestilt!),
      kunde: _fornavn(),
      sykkel: t.courier?.onBike ?? true,
      partner: t.isPartner,
      henting: t.isPickup,
      minIgjen: minLeft,
      pct: minLeft == null ? .62 : (1 - minLeft / 30).clamp(.1, .95),
      slutt: end,
      totalSek: windowSec,
      spartSek: spart,
      poeng: _poeng,
    );
  }

  String _fornavn() {
    final n = prefGetString(prefUserName).trim();
    if (n.isEmpty) return SporingCopy.a1_sporing_Budet;
    return n.split(' ').first;
  }

  List<CssBg> _himmel(OpsTracking t) {
    final s = t.stage;
    if (s >= 3)
      return const [
        CssLinear(180, [Color(0xFF2C3B45), Color(0xFF3A4B55), Color(0xFF23405C)], [0, .13, 1]),
      ];
    if (s == 2 && !t.isPickup)
      return const [
        CssLinear(180, [Color(0xFF7E93A3), Color(0xFF9FB2BD), Color(0xFFC3CBC6)], [0, .3, 1]),
      ];
    if (s == 0)
      return const [
        CssLinear(180, [Color(0xFF35434C), Color(0xFF495A62), Color(0xFF456E7C), Color(0xFF2F5462)], [0, .14, .4, 1]),
      ];
    return const [
      CssLinear(180, [Color(0xFF7E93A3), Color(0xFF9FB2BD), Color(0xFF456E7C), Color(0xFF2F5462)], [0, .26, .4, 1]),
    ];
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (_missing && t == null) {
      return Scaffold(
        backgroundColor: BergenTokens.tealDeep,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
        body: Center(
          child: Text(
            SporingCopy.a1_sporing_ikke_funnet,
            key: const Key('a1_sporing_ikke_funnet'),
            style: inter(13, weight: FontWeight.w700),
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
              const SizedBox(height: 12),
              Text(SporingCopy.a1_sporing_laster, style: inter(12, weight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      resizeToAvoidBottomInset: false,
      body: LfFrame(
        child: LfOnce(
          ms: 340,
          builder: (context, tt, child) {
            final p = cssSkjerm.transform(kfP(tt, 0, 340));
            return Opacity(
              opacity: kf(p, const [0, .55, 1], const [0, 1, 1]),
              child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.978 + .022 * p, .978 + .022 * p, 1, 1), child: child),
            );
          },
          child: _skjerm(context, t),
        ),
      ),
    );
  }

  Widget _skjerm(BuildContext context, OpsTracking t) {
    final mq = MediaQuery.of(context);
    // The prototype's frame has no status bar: its 12 px top margin is
    // absorbed by the device's, and the scenes sit 12 px closer to the ETA
    // block so the panel covers no more of them than in the frame.
    final topp = math.max(0.0, mq.padding.top - 12);
    final s0 = t.stage.clamp(0, 3);
    // The map's arrival card must clear the panel; the house's title must
    // clear the ETA block.
    final sceneTopp = math.max(
      0.0,
      mq.padding.top -
          (s0 == 3
              ? 12
              : (s0 == 2 && !t.isPickup)
              ? 36
              : 32),
    );
    final bunn = mq.padding.bottom;
    final h = mq.size.height;
    final s = t.stage.clamp(0, 3);
    final hent = t.isPickup;
    final navn = SporingCopy.stages(hent);
    final info = _info(t);
    final lines = SporingCopy.lines(
      hent,
      partner: t.isPartner,
      bike: t.courier?.onBike ?? true,
      store: t.store?.name,
      gate: hent ? t.store?.address?.split(',').first.trim() : (info.gate.isEmpty ? null : info.gate),
      minutter: t.minutesLeft(DateTime.now()),
      navn: info.kunde,
      vindu: t.hasWindow ? t.windowText : null,
      klokke: _levertKl == null ? null : spKlokke(_levertKl!),
    );
    final linje = t.isCancelled ? SporingCopy.a1_sporing_avbestilt : lines[s];
    final minutes = t.minutesLeft(DateTime.now());
    final gift = '${t.raw['gift_to'] ?? ''}';
    final budTop =
        (s >= 3
            ? 444.0
            : s == 2
            ? 176.0
            : 150.0) +
        sceneTopp;
    final visBud = !hent && s >= 2 && (t.courier != null || t.isPartner) && !t.isCancelled;
    final slotVerv = _fersk && !_vervLukket && _vervKode != null;
    final slotKode = !slotVerv && _ark == null && t.deliveryCode != null && (hent ? s == 2 : s == 3);
    final stadieNavn = t.isCancelled
        ? SporingCopy.a1_sporing_avbestilt
        : t.findingCourier
        ? SporingCopy.order_status_finding_courier
        : t.stageLabel;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: CssBox(bg: _himmel(t))),
        // The scene.
        Positioned(
          left: 0,
          top:
              sceneTopp +
              (s == 0
                  ? 118
                  : s == 1
                  ? 130
                  : s == 2
                  ? 126
                  : 110),
          child: RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey('scene-$s-$hent'),
              child: switch (s) {
                0 => KeyedSubtree(
                  key: const Key('a1_sporing_kort_bekreftet'),
                  child: SpSceneKai(info: info),
                ),
                1 => KeyedSubtree(
                  key: const Key('a1_sporing_kort_tilberedes'),
                  child: SpSceneKjokken(info: info),
                ),
                2 when hent => KeyedSubtree(
                  key: const Key('a1_sporing_kort_hentklar'),
                  child: SpSceneDisk(info: info),
                ),
                2 => KeyedSubtree(
                  key: const Key('a1_sporing_kort_paavei'),
                  child: SpSceneKart(info: info, linje: linje),
                ),
                _ => KeyedSubtree(
                  key: const Key('a1_sporing_kort_levert'),
                  child: SpSceneHus(info: info),
                ),
              },
            ),
          ),
        ),
        // The header (top 12).
        Positioned(
          left: 16,
          right: 16,
          top: 12 + topp,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SpGlassKey(
                key: const Key('a1_sporing_tilbake'),
                semantics: SporingCopy.a1_sporing_tilbake_knapp,
                onTap: () => Navigator.of(context).maybePop(),
                child: spIkon(kSpIkonTilbake, size: 16, width: 2.8),
              ),
              _LivePill(navn: stadieNavn),
              SpGlassKey(
                key: const Key('a1_sporing_hjelp_knapp'),
                semantics: SporingCopy.a1_sporing_hjelp_knapp,
                onTap: _openHelp,
                child: spIkon(kSpIkonHjelp, size: 18, width: 2.4, extra: '<circle cx="12" cy="12" r="9"/>'),
              ),
            ],
          ),
        ),
        if (t.isPartner) Positioned(left: 0, right: 0, top: 0, child: SizedBox(key: const Key('a1_sporing_leveres_av'), width: 0, height: 0)),
        // The ETA block (top 58) and «om N min».
        Positioned(
          left: 0,
          right: 0,
          top: 58 + topp,
          child: Column(
            children: [
              _EtaBlokk(label: _etaLabel(t), tid: _etaBig(t), stor: s == 3 ? 28 : 40),
              if (minutes != null && s < 3 && !hent && !t.isCancelled) ...[
                const SizedBox(height: 7),
                SpEtaPopp(
                  key: ValueKey('min-$minutes'),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(11, 4, 11, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFEFF3F4)]),
                      boxShadow: [
                        BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 1),
                        const BoxShadow(color: Color(0xFFCFDADD), offset: Offset(0, 2)),
                        BoxShadow(color: rgba(10, 40, 50, .6), offset: const Offset(0, 4), blurRadius: 8, spreadRadius: -4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          SporingCopy.a1_sporing_om_min(minutes),
                          key: const Key('a1_sporing_om_min'),
                          style: inter(11, weight: FontWeight.w800, color: const Color(0xFF1B4A57)),
                        ),
                        const SizedBox(width: 5),
                        const SpPuls(size: 5, color: Color(0xFF3F8F5F), dur: 2400),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_offline)
          Positioned(
            left: 16,
            right: 16,
            top: 62 + topp,
            child: const Center(child: BergenOfflineBanner(key: Key('a1_sporing_offline'))),
          ),
        if (gift.isNotEmpty && s < 3)
          Positioned(
            left: 0,
            right: 0,
            top: 300 + topp,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 30),
                child: Transform.rotate(
                  angle: rad(-3),
                  child: Container(
                    key: const Key('a1_sporing_gave'),
                    padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
                    decoration: BoxDecoration(
                      color: rgba(255, 255, 255, .9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        const BoxShadow(color: Colors.white, spreadRadius: 1.5),
                        BoxShadow(color: rgba(15, 31, 43, .5), offset: const Offset(0, 6), blurRadius: 12, spreadRadius: -6),
                      ],
                    ),
                    child: Text(
                      SporingCopy.a1_sporing_gave_venter(gift),
                      style: inter(10.5, weight: FontWeight.w800, color: kSpInk),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // The courier pill (stage 3: ten px above the panel).
        if (visBud && s < 3)
          Positioned(
            left: 0,
            right: 0,
            top: budTop,
            child: IgnorePointer(
              child: Align(
                alignment: s == 2 ? Alignment.centerLeft : Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(left: s == 2 ? 26 : 0),
                  child: BudIdentitetPill(tracking: t),
                ),
              ),
            ),
          ),
        // «Kart kommer» marker for the tests' contract (the map scene draws
        // the courier itself).
        if (s == 2 && !hent) Positioned(left: 0, top: 0, child: SizedBox(key: Key(t.livePosition != null && !t.isPartner ? 'a1_sporing_live_marker' : 'a1_sporing_ingen_marker'), width: 0, height: 0)),
        // The bottom panel.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (visBud && s >= 3) ...[IgnorePointer(child: BudIdentitetPill(tracking: t)), const SizedBox(height: 10)],
              SpPanel(
                tracking: t,
                linje: linje,
                offline: _offline,
                slotKode: slotKode,
                slotVerv: slotVerv,
                vervKode: _vervKode ?? '',
                bunn: math.max(bunn - 24, 0),
                poengNeste: SporingScreen.stegPoeng,
                onSammendrag: () => setState(() => _ark = SpArk.sammendrag),
                onDetaljer: () => setState(() => _ark = SpArk.detaljer),
                onAvslutt: _toLevert,
                onFjordfiske: _fjordfiske,
                onVisVeien: () => _showMapSheet(t),
                onChat: () => _openHelp(HjelpState.melding),
                onRing: _openHelp,
                onLukkVerv: () => setState(() => _vervLukket = true),
                onDelBillett: _delBillett,
                onKopierBillett: _kopierBillett,
              ),
            ],
          ),
        ),
        // Valg som venter.
        if (t.unseenByStore && !_waited && !t.isCancelled)
          Positioned(
            left: 16,
            right: 16,
            bottom: 198 + math.max(bunn - 24, 0),
            child: ValgSomVenterCard(storeName: t.store?.name ?? '', onWait: _wait, onCancel: _cancel),
          ),
        // Bestillingsdetaljer.
        if (_ark case final ark?)
          Positioned.fill(
            child: SpDetaljerArk(
              ark: ark,
              tracking: t,
              ordre: _ordre,
              height: h,
              onLukk: () => setState(() => _ark = null),
              onDetaljer: () => setState(() => _ark = SpArk.detaljer),
              onKvittering: _kvittering,
              onKundeservice: () {
                setState(() => _ark = null);
                _openHelp(HjelpState.kundeservice);
              },
              onRingButikk: () {
                setState(() => _ark = null);
                _openHelp();
              },
            ),
          ),
        // The stage change.
        if (_shift)
          Positioned.fill(
            child: SpSkifte(key: ValueKey('skifte-$_shiftSteg'), steg: _shiftSteg, navn: navn[_shiftSteg.clamp(0, 3)], linje: lines[_shiftSteg.clamp(0, 3)]),
          ),
      ],
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
                initialCameraPosition: CameraPosition(target: LatLng(store!.lat!, store.lng!), zoom: 15),
                markers: {
                  Marker(
                    markerId: const MarkerId('butikk'),
                    position: LatLng(store.lat!, store.lng!),
                    infoWindow: InfoWindow(title: store.name, snippet: store.address),
                  ),
                },
              )
            : Center(
                child: Text(
                  '${store?.name ?? ''}\n${store?.address ?? ''}',
                  textAlign: TextAlign.center,
                  style: inter(13, weight: FontWeight.w700, color: kSpInk),
                ),
              ),
      ),
    );
  }
}

/// The LIVE pill in the header: the flat Æ disc, «LIVE» with its pulse,
/// the stage name.
class _LivePill extends StatelessWidget {
  const _LivePill({required this.navn});

  final String navn;

  @override
  Widget build(BuildContext context) => CssBox(
    height: 42,
    radius: BorderRadius.circular(999),
    clip: true,
    padding: const EdgeInsets.fromLTRB(5, 0, 16, 0),
    bg: [
      CssLinear(180, [rgba(255, 255, 255, .22), rgba(255, 255, 255, .07)]),
    ],
    shadows: [
      CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .42)),
      CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14)),
      CssShadow.inset(0, -2, 0, 0, rgba(4, 20, 28, .2)),
      CssShadow(0, 3, 0, 0, rgba(4, 20, 28, .55)),
      CssShadow(0, 12, 18, -10, rgba(3, 14, 20, .85)),
    ],
    child: Stack(
      children: [
        Positioned(
          left: 14,
          right: 14,
          top: 3,
          height: 42 * .42,
          child: IgnorePointer(
            child: CssBox(
              radius: const BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.elliptical(20, 8)),
              bg: [
                CssLinear(180, [rgba(255, 255, 255, .22), rgba(255, 255, 255, 0)]),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CssBox(
              width: 32,
              height: 32,
              radius: BorderRadius.circular(16),
              bg: const [
                CssRadial([Color(0xFFFFFFFF), Color(0xFFEEF4F5), Color(0xFFD3E0E3)], stops: [0, .55, 1], rx: .7, ry: .6, cx: .4, cy: .25),
              ],
              shadows: [
                const CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
                CssShadow.inset(0, -2, 3, 0, rgba(30, 79, 92, .2)),
                CssShadow(0, 2, 0, 0, rgba(4, 20, 28, .4)),
                CssShadow(0, 5, 8, -3, rgba(3, 14, 20, .6)),
              ],
              child: Center(child: spMerkeFlat(w: 23, h: 18)),
            ),
            const SizedBox(width: 9),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SpPuls(
                      size: 7,
                      color: Color(0xFFFF8A57),
                      gradient: RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFFFD9C8), Color(0xFFFF8A57), Color(0xFFC2481C)], stops: [0, .55, 1]),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      SporingCopy.a1_sporing_live_ord,
                      style: inter(8.5, weight: FontWeight.w800, em: .16, height: 1, color: const Color(0xFF9FF0D4)),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  navn,
                  key: const Key('a1_sporing_topline'),
                  maxLines: 1,
                  softWrap: false,
                  style: jakarta(
                    13.5,
                    em: -.01,
                    height: 1.1,
                    shadows: [Shadow(color: rgba(3, 14, 20, .45), offset: const Offset(0, 1))],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

/// The ETA block: the glass with its sheen, the label with the orange
/// pulse, the time (`vekt` fading in).
class _EtaBlokk extends StatelessWidget {
  const _EtaBlokk({required this.label, required this.tid, required this.stor});

  final String label, tid;
  final double stor;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: CssBox(
      radius: BorderRadius.circular(20),
      clip: true,
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 10),
      bg: [
        CssLinear(180, [rgba(10, 32, 42, .5), rgba(6, 22, 30, .62)]),
      ],
      shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .26)), CssShadow.inset(0, -2, 6, 0, rgba(2, 14, 20, .5)), CssShadow(0, 10, 20, -10, rgba(4, 20, 28, .8))],
      child: Stack(
        children: [
          const SpSveip(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpPuls(size: 6, color: kSpOrange, glow: rgba(242, 109, 61, .9)),
                  const SizedBox(width: 6),
                  Text(
                    label.toUpperCase(),
                    key: const Key('a1_sporing_eta_label'),
                    style: inter(10, weight: FontWeight.w800, em: .08, color: kSpLabel),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              LfOnce(
                ms: 900,
                builder: (context, t, child) => Opacity(opacity: .6 + .4 * cssEaseOut.transform(kfP(t, 0, 900)), child: child),
                child: Text(tid, key: const Key('a1_sporing_eta'), style: jakarta(stor, em: -.04, height: 1)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
