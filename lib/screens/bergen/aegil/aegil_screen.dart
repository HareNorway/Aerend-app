import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../data/aegil/suggestion_models.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfToast;
import '../../common/auth/onboarding_kit.dart' show onbBareInput;
import '../../common/home/bergen/bergen_copy.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeatherLook;
import '../../common/homeMainV1/home_main_v1.dart';
import '../../deliveryService/storeDetail/store_detail_repo.dart';
import '../hjem/hjem_harness.dart';
import '../hjem/hjem_hero.dart' show HjemVaer;
import '../hurtig/hurtig_data.dart';
import '../kit/bergen_cart.dart';
import '../kit/bergen_routes.dart';
import '../meg/a3_services.dart';
import 'aegil_bits.dart';
import 'aegil_chat.dart';
import 'aegil_laer.dart';
import 'aegil_launch_copy.dart';
import 'aegil_scene.dart';

/// Ægil (`erAgent`, L4500–5120 in `Ærend Kunde Launch.dc.html`, design px).
///
/// Fløyen at the top with Ægil on the viewpoint, the teal sheet with his
/// head and status, and below it one of:
/// * the start view — the greeting with the customer's name, what he
///   remembers (or the offer to start remembering), «Ægil tipper» (the last
///   delivered order, ready again), «Be Ægil om noe», «Eller søk og bla selv»;
/// * the chat — the customer's lines and Ægil's replies from `agent/chat`
///   with the cards each reply state carries (the basket, the comparison,
///   not found, 18+, the door note, the swap, a find), the tray's
///   suggestions with «Legg i kurven», app cards and follow-up chips;
/// * «Det Ægil vet om deg» (`agent/me/memory`, «Glem alt»), «Så mye kan Ægil
///   gjøre» (`agent/me/settings`), the first-time disclosure, and the five
///   onboarding questions (`agent/me/preferences/batch`).
///
/// Ægil proposes; the customer acts. Every add to the basket is a tap, and
/// paying always happens in the basket (AI agents spec: propose, never
/// execute). The composer morphs as Søk's does; the basket strip shows the
/// real basket.
class AegilScreen extends StatefulWidget {
  const AegilScreen({super.key, this.api, this.repo, this.steg, this.butikkApi, this.kasseApi, this.customerApi});

  final AegilAppApi? api;
  final AegilRepo? repo;
  final OpsButikkApi? butikkApi;
  final OpsKasseApi? kasseApi;
  final OpsCustomerApi? customerApi;

  /// Open on this view (`minne`, `nivaa`, `ob1` …) instead of the start.
  final String? steg;

  /// Pref: the first-time disclosure has been seen.
  static const String prefTillatelse = 'a1_aegil_tillatelse';

  /// Pref: «Ikke nå» on the memory offer.
  static const String prefAvslaatt = 'a1_aegil_minne_avslaatt';

  @override
  State<AegilScreen> createState() => _AegilScreenState();
}

class _AegilScreenState extends State<AegilScreen> implements AeHandling {
  late final AegilAppApi _api = widget.api ?? A3Services.aegil();
  late final AegilRepo _repo = widget.repo ?? A3Services.aegilRepo();
  late final OpsButikkApi _butikkApi = widget.butikkApi ?? OpsButikkApi();
  late final OpsKasseApi _kasse = widget.kasseApi ?? OpsKasseApi();
  late final OpsCustomerApi _customer = widget.customerApi ?? OpsCustomerApi();

  final TextEditingController _tekst = TextEditingController();
  final FocusNode _fokus = FocusNode();
  final ScrollController _scroll = ScrollController();

  String _steg = 'start';
  int _tikk = 0;

  // The chat (`vc`).
  final List<AeMelding> _vc = [];
  bool _tenker = false;
  List<String> _forslag = const [];
  int _sendSeq = 0;

  // Data.
  AegilSettings? _settings;
  List<AegilLevel> _levels = const [];
  List<MemoryEntry> _minne = const [];
  bool _minneLastet = false;
  final Set<int> _skjult = {};
  HurtigData? _h;
  final Map<int, BergenStoreInfo> _stores = {};
  final Set<int> _henter = {};
  KurvState _kurv = const KurvState();
  int? _poeng;
  bool _avslaatt = false;

  final Set<int> _lagt = {};
  final Set<String> _alleLagt = {};
  final Set<String> _dorLagret = {};
  int? _forrigeNivaa;

  // Onboarding.
  AeOb _ob = AeOb();
  List<AeObButikk> _obButikker = const [];
  bool _butArk = false;
  bool _obLagrer = false;

  @override
  void initState() {
    super.initState();
    _steg = widget.steg ?? (prefGetBool(AegilScreen.prefTillatelse) ? 'start' : 'tillatelse');
    _avslaatt = prefGetBool(AegilScreen.prefAvslaatt);
    _fokus.addListener(() => setState(() {}));
    _tekst.addListener(() => setState(() {}));
    _last();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fraRute());
    if (kDebugMode && HjemHarness.aegil != null) _harness();
  }

  @override
  void dispose() {
    _tekst.dispose();
    _fokus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> _last() async {
    unawaited(a3Try(_repo.fetchSettings).then((r) {
      if (!mounted || r == null) return;
      setState(() {
        _settings = r.settings;
        _levels = r.levels;
      });
    }));
    unawaited(_lastMinne());
    unawaited(_lastKurv());
    unawaited(a3Try(() => A3Services.points().balance()).then((b) {
      if (mounted && b != null) setState(() => _poeng = b.available);
    }));
    final h = await a3Try(() => HurtigKilde.load());
    if (!mounted || h == null) return;
    setState(() => _h = h);
    final sist = h.hist.firstOrNull;
    if (sist != null) _hentButikk(sist.butikkId);
  }

  Future<void> _lastMinne() async {
    final m = await a3Try(_repo.fetchMemory);
    if (!mounted) return;
    setState(() {
      _minne = m ?? const [];
      _minneLastet = true;
    });
  }

  Future<void> _lastKurv() async {
    final k = await _kasse.cart();
    if (!mounted) return;
    setState(() => _kurv = k);
  }

  void _hentButikk(int? id) {
    if (id == null || id == 0 || _stores.containsKey(id) || _henter.contains(id)) return;
    _henter.add(id);
    _butikkApi.store(id).then((s) {
      if (!mounted || s == null) return;
      setState(() => _stores[id] = s);
    });
  }

  /// The route's `q` / `intent` (Søk's «Spør Ægil», the basket's door note).
  void _fraRute() {
    final a = BergenRoutes.argsOf(context);
    final q = (a['q'] ?? '').trim();
    final intent = a['intent'];
    if (q.isNotEmpty || (intent != null && intent.isNotEmpty)) {
      if (_steg == 'tillatelse') _steg = 'start';
      _si(q.isEmpty ? AeCopy.tacoSi : q, intent: intent);
    }
  }

  // ── The chat (`vcSend`) ───────────────────────────────────────────────────

  @override
  void si(String tekst) => _si(tekst);

  Future<void> _si(String t, {String? intent}) async {
    final tx = t.trim();
    if (tx.isEmpty || _tenker) return;
    HapticFeedback.selectionClick();
    final seq = ++_sendSeq;
    setState(() {
      if (_steg != 'start') _steg = 'start';
      _vc.add(AeMelding.meg(tx));
      _tenker = true;
      _forslag = const [];
      _tikk++;
    });
    _tekst.clear();
    _fokus.unfocus();
    _rullNed();
    final t0 = DateTime.now();
    AegilTurn? turn;
    try {
      turn = await _api.chat(text: tx, intent: intent).timeout(const Duration(seconds: 20));
    } catch (_) {
      turn = null;
    }
    final vent = 850 - DateTime.now().difference(t0).inMilliseconds;
    if (vent > 0) await Future.delayed(Duration(milliseconds: vent));
    if (!mounted || seq != _sendSeq) return;
    final svar = _svar(tx, turn);
    for (final s in svar.kort) {
      _hentButikk(s.storeId);
    }
    _hentButikk(svar.kurv?.storeId);
    setState(() {
      _vc.add(svar);
      _tenker = false;
      _forslag = svar.forslag;
      _tikk++;
    });
    _rullNed();
  }

  /// The reply: the backend's turn, with Ægil's own line and the app cards
  /// when the request is about the app (`vcLokal`'s topics), and a plain line
  /// when Vågen can't be reached.
  AeMelding _svar(String t, AegilTurn? turn) {
    final l = t.toLowerCase();
    bool h(List<String> o) => o.any(l.contains);
    final navn = _h?.navn ?? '';
    (String, String, List<AeApp>, List<AeKnapp>, List<String>)? tema;
    if (h(['hjelp', 'hvordan', 'hva kan du', 'forklar'])) {
      tema = (AeCopy.svHjelp, 'glad', [AeApp.utforsk, AeApp.sporing], [AeKnapp(AeCopy.chipSulten, si: AeCopy.chipSulten)], [AeCopy.chipGave, AeCopy.chipPoeng, AeCopy.chipFiske]);
    } else if (h(['er du der', 'hører du', 'hallo?'])) {
      tema = (AeCopy.svSvar, 'glad', const [], const [], [AeCopy.chipSulten, AeCopy.chipGave, AeCopy.chipBud]);
    } else if (RegExp(r'^(hei|hallo|heisann|halla|god kveld|god morgen)\b').hasMatch(l)) {
      tema = (AeCopy.svHei(navn), 'glad', const [], const [], [AeCopy.chipSulten, AeCopy.chipGave, AeCopy.chipNytt]);
    } else if (h(['pose', 'overskudd'])) {
      tema = (AeCopy.svPose, 'spent', [AeApp.pose], [AeKnapp(AeCopy.trekkPose, app: AeApp.pose)], [AeCopy.chipHvaPose, AeCopy.chipBillig]);
    } else if (h(['fjordfiske', 'fiske', 'premie', 'spill', 'vinne'])) {
      tema = (AeCopy.svFiske, 'glad', [AeApp.fiske], [AeKnapp(AeCopy.kastUt, app: AeApp.fiske)], [AeCopy.chipPremier]);
    } else if (h(['poeng', 'nivå', 'premiehyll', 'liga'])) {
      tema = (AeCopy.svPoeng(_poeng), 'glad', [AeApp.poeng], [AeKnapp(AeCopy.sePremiehylla, app: AeApp.poeng)], [AeCopy.chipGull, AeCopy.chipPremier]);
    } else if (h(['hvor er', 'levering', 'budet', 'sporing', 'ordre', 'bestillingen', 'kommer'])) {
      tema = (AeCopy.svSporing, 'tenker', [AeApp.sporing], [AeKnapp(AeCopy.folgBestillingen, app: AeApp.sporing)], const []);
    } else if (h(['kurv', 'betal', 'handlekurv'])) {
      tema = (AeCopy.svKurv, 'glad', [AeApp.kurv], [AeKnapp(AeCopy.gaaTilKurven, app: AeApp.kurv)], const []);
    } else if (h(['takk', 'supert', 'flott', 'perfekt', 'nice'])) {
      tema = (AeCopy.svTakk, 'glad', const [], const [], [AeCopy.chipNytt]);
    }

    if (turn == null) {
      return AeMelding.aeg(
        tekst: tema?.$1 ?? AeCopy.utenNett,
        humor: tema?.$2 ?? 'tenker',
        app: tema?.$3 ?? const [],
        knapper: tema?.$4 ?? const [],
        forslag: tema?.$5 ?? [AeCopy.chipSulten, AeCopy.chipGave, AeCopy.chipHjelp],
      );
    }
    // Nothing to find, but the request was about the app: Ægil answers that.
    if (tema != null && turn.state == 'agIkkeFunnet' && turn.cards.isEmpty) {
      return AeMelding.aeg(tekst: tema.$1, humor: tema.$2, app: tema.$3, knapper: tema.$4, forslag: tema.$5);
    }
    final humor = switch (turn.state) {
      'agForslag' || 'agFunn' => 'spent',
      'agSammen' => 'tenker',
      'agIkkeFunnet' || 'agAldersblokk' => 'lei',
      _ => 'glad',
    };
    final forslag = tema?.$5 ??
        switch (turn.state) {
          'agForslag' => [AeCopy.chipBillig, AeCopy.chipGave, AeCopy.chipHjelp],
          'agFunn' => [AeCopy.chipTaco, AeCopy.chipBillig],
          'agSammen' => [AeCopy.chipTaco, AeCopy.chipGave],
          'agIkkeFunnet' => [AeCopy.chipTaco, AeCopy.chipBillig, AeCopy.chipSulten],
          'agAldersblokk' => [AeCopy.chipTaco, AeCopy.chipGave],
          'agFiks' => [AeCopy.chipBillig, AeCopy.chipTaco],
          _ => [AeCopy.chipSulten, AeCopy.chipGave, AeCopy.chipHjelp],
        };
    return AeMelding.aeg(
      tekst: turn.reply,
      state: turn.state,
      kort: turn.cards,
      kurv: turn.state == 'agForslag' ? turn.basket : null,
      sammen: turn.state == 'agSammen' ? turn.comparison : null,
      dor: turn.doorNote,
      bytt: turn.swap,
      app: tema?.$3 ?? const [],
      knapper: tema?.$4 ?? const [],
      forslag: forslag,
      humor: humor,
    );
  }

  void _rullNed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 420), curve: const Cubic(.2, .9, .3, 1));
      // The reply's cards land after the first frame: follow them down.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 360), curve: const Cubic(.2, .9, .3, 1));
        }
      });
    });
  }

  void _nyPrat() {
    _sendSeq++;
    setState(() {
      _vc.clear();
      _tenker = false;
      _forslag = const [];
      _tikk++;
    });
  }

  // ── AeHandling ────────────────────────────────────────────────────────────

  @override
  bool get handler => (_settings?.level ?? 2) >= 3;

  @override
  bool erLagt(int suggestionId) => _lagt.contains(suggestionId);

  @override
  bool alleLagt(AegilBasket kurv) => _alleLagt.contains(_kurvNokkel(kurv));

  @override
  bool dorLagret(String note) => _dorLagret.contains(note);

  @override
  int? poeng() => _poeng;

  @override
  String? butikkNavn(int? storeId) {
    if (storeId == null) return null;
    return _stores[storeId]?.name ?? _h?.butikker[storeId]?.navn;
  }

  @override
  HbButikk? butikk(int? storeId) {
    if (storeId == null) return null;
    final s = _stores[storeId];
    final h = _h?.butikker[storeId];
    if (h != null) return h;
    if (s == null) return null;
    return HbButikk(id: s.id, navn: s.name, ini: HbButikk.initialer(s.name), bg: HbButikk.farge(s.id), min: s.deliveryMinutes ?? 30);
  }

  @override
  String? bilde(int? storeProductId) {
    if (storeProductId == null) return null;
    for (final s in _stores.values) {
      for (final c in s.menu) {
        for (final i in c.items) {
          if (i.id == storeProductId && (i.imageUrl ?? '').isNotEmpty) return i.imageUrl;
        }
      }
    }
    return null;
  }

  @override
  String ikon(int? storeId) => switch (_stores[storeId]?.kind) {
    BergenStoreKind.restaurant => 'ico_mat',
    BergenStoreKind.gift => 'ico_gaver',
    BergenStoreKind.fashion => 'ico_mote',
    _ => 'ico_fisk',
  };

  static String _kurvNokkel(AegilBasket k) => k.lines.map((l) => '${l.suggestionId}:${l.storeProductId}').join(',');

  @override
  Future<void> leggKort(Suggestion s) async {
    final linje = _vc.reversed.expand((m) => m.kurv?.lines ?? const <AegilBasketLine>[]).where((l) => l.suggestionId == s.id).firstOrNull;
    final storeId = linje?.storeId ?? s.storeId;
    final productId = s.storeProductId;
    if (storeId == null || productId == null) return;
    final ok = await BergenCart.add(context, storeId: storeId, productId: productId, toast: '${linje?.name ?? s.headline ?? ''} ${AeCopy.iKurven}'.trim());
    if (!mounted || !ok) return;
    unawaited(a3Try(() => _api.add(s.id)));
    setState(() => _lagt.add(s.id));
    unawaited(_lastKurv());
  }

  @override
  Future<void> leggAlt(AegilBasket kurv) async {
    final storeId = kurv.storeId;
    final linjer = kurv.lines.where((l) => l.storeProductId != null && l.priceOre > 0 && (storeId == null || l.storeId == storeId)).toList();
    if (linjer.isEmpty) return;
    var ok = 0;
    for (final l in linjer) {
      prefSetInt('checkedSize', 0);
      prefSetInt('checkedColor', 0);
      prefSetString('checkedOptionList', jsonEncode(const <int>[]));
      try {
        final r = await StoreDetailRepo().callOrderCartApi(l.storeId ?? storeId ?? 0, l.storeProductId!, l.qty);
        if (r is Map && r['message_code'] == 1) {
          ok++;
          if (l.suggestionId != null) {
            _lagt.add(l.suggestionId!);
            unawaited(a3Try(() => _api.add(l.suggestionId!)));
          }
        } else if (r is Map && ok == 0 && mounted) {
          LfToast.show(context, '${r['message'] ?? ''}');
        }
      } catch (_) {}
    }
    await _lastKurv();
    if (!mounted) return;
    prefSetInt(prefCartCount, _kurv.lines.length);
    BergenCart.syncBadge(context, _kurv.lines.length);
    if (ok > 0) {
      HapticFeedback.mediumImpact();
      setState(() => _alleLagt.add(_kurvNokkel(kurv)));
      LfToast.show(context, '${AeCopy.varer(ok)} ${AeCopy.iKurven}');
    }
  }

  @override
  Future<void> lagreDor(String note) async {
    final r = await a3Try(() => _api.doorNote(note));
    if (!mounted || r == null) return;
    setState(() => _dorLagret.add(note));
    LfToast.show(context, AeCopy.lagret);
  }

  @override
  void aapneButikk(int storeId) => BergenRoutes.push(context, '/bergen/butikk/$storeId');

  @override
  void app(AeApp a) {
    switch (a) {
      case AeApp.fiske:
        BergenRoutes.push(context, '/bergen/fjordfiske');
      case AeApp.pose:
        BergenRoutes.push(context, '/bergen/automat');
      case AeApp.sporing:
        _tilSporing();
      case AeApp.poeng:
        _tilFane(3);
      case AeApp.kurv:
        _tilFane(2);
      case AeApp.utforsk:
        _tilFane(1);
    }
  }

  Future<void> _tilSporing() async {
    final rader = await _customer.orders(limit: 10);
    if (!mounted) return;
    final aktiv = rader.where((o) => o['paid'] == true && !const {'delivered', 'cancelled', 'completed'}.contains('${o['state']}')).firstOrNull;
    if (aktiv == null) {
      LfToast.show(context, AeCopy.ingenAktiv);
      return;
    }
    BergenRoutes.push(context, '/bergen/sporing/${aktiv['order_id']}');
  }

  void _tilFane(int i) {
    final shell = HomeMainV1State.current;
    Navigator.of(context).popUntil((r) => r.isFirst);
    shell?.switchToTab(i);
  }

  void _tilSok() {
    final shell = HomeMainV1State.current;
    Navigator.of(context).popUntil((r) => r.isFirst);
    shell?.openSearchTab();
  }

  void _gaa(String steg) {
    setState(() {
      _steg = steg;
      _tikk++;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  // ── «Ægil tipper» (`agSamme` / `agEndreSist`) ─────────────────────────────

  AeTips? get _tips {
    final h = _h;
    final o = h?.hist.firstOrNull;
    if (h == null || o == null || o.linjer.isEmpty) return null;
    final dag = AeCopy.dagerLang[o.naar.weekday - 1];
    final info = _stores[o.butikkId];
    final (ico, tint) = switch (info?.kind) {
      BergenStoreKind.restaurant => ('ico_mat', kAeTintMat),
      BergenStoreKind.gift => ('ico_gaver', kAeTintGave),
      BergenStoreKind.fashion => ('ico_mote', kAeTintGave),
      _ => ('ico_fisk', kAeTintFisk),
    };
    final idag = DateTime.now().weekday;
    return AeTips(
      butikk: o.butikk,
      dag: dag,
      min: h.butikk(o.butikkId, o.butikk).min + 5,
      adresse: h.adresse,
      sumKr: o.sum.round(),
      ico: ico,
      tint: tint,
      pleier: h.hist.where((x) => x.naar.weekday == idag).length >= 2 || o.naar.weekday == idag,
    );
  }

  /// `agSamme`: the last order's lines into the basket, then the basket. The
  /// basket holds one store, so another store's lines make way.
  Future<void> _bestillIgjen() async {
    final o = _h?.hist.firstOrNull;
    if (o == null) return;
    HapticFeedback.selectionClick();
    var cart = await _kasse.cart();
    if (!cart.isEmpty && cart.storeId != o.butikkId) {
      for (final l in cart.lines) {
        await _kasse.remove(l.cartId);
      }
    }
    for (final l in o.linjer) {
      prefSetInt('checkedSize', 0);
      prefSetInt('checkedColor', 0);
      prefSetString('checkedOptionList', jsonEncode(const <int>[]));
      try {
        await StoreDetailRepo().callOrderCartApi(o.butikkId, l.id, l.ant);
      } catch (_) {}
    }
    cart = await _kasse.cart();
    if (!mounted) return;
    prefSetInt(prefCartCount, cart.lines.length);
    BergenCart.syncBadge(context, cart.lines.length);
    if (cart.isEmpty) {
      LfToast.show(context, BergenRoutes.kommerSnart);
      return;
    }
    LfToast.show(context, '${AeCopy.sammeSomSist} ${AeCopy.iKurven}');
    _tilFane(2);
  }

  // ── Settings (header chip, nivå, rammer) ──────────────────────────────────

  Future<void> _endre(Map<String, dynamic> endring, {String? toast}) async {
    final r = await a3Try(() => _repo.updateSettings(endring));
    if (!mounted) return;
    if (r?.settings != null) {
      setState(() => _settings = r!.settings);
      if (toast != null) LfToast.show(context, toast);
    } else if (r?.error == 'LEVEL_REQUIRES_RECURRING') {
      LfToast.show(context, AeCopy.fastUkeshandel);
    } else {
      LfToast.show(context, BergenRoutes.kommerSnart);
    }
  }

  /// `agBytt`: Foreslå ↔ Handle i kurven (level 3 lets Ægil put things in
  /// the basket; paying stays with the customer).
  void _byttNivaa() {
    HapticFeedback.selectionClick();
    final level = _settings?.level ?? 2;
    if (level >= 3) {
      _endre({'level': math.min(_forrigeNivaa ?? 2, 2)}, toast: AeCopy.toastForeslaa);
    } else {
      _forrigeNivaa = level;
      _endre({'level': 3}, toast: AeCopy.toastHandle);
    }
  }

  void _velgNivaa(int k) {
    HapticFeedback.selectionClick();
    if (k == 4 && !(_settings?.recurringAgreement ?? false)) {
      LfToast.show(context, AeCopy.fastUkeshandel);
      return;
    }
    _endre({'level': k});
  }

  List<AegilLevel> get _nivaaer => _levels.isNotEmpty
      ? _levels
      : const [
          AegilLevel(level: 0, name: 'Bare når jeg spør', body: 'Svarer og handler i chatten. Husker ingenting utover samtalen med mindre du ber om det.'),
          AegilLevel(level: 1, name: 'Foreslå', body: 'Husker hva du liker og løfter fram tilbud og varer som passer, i appen. Ingen varsler.'),
          AegilLevel(level: 2, name: 'Varsle og foreslå', body: 'Som Foreslå, pluss varsler innen rammene. Legger forslag i skuffen mens du er borte.', isDefault: true),
          AegilLevel(level: 3, name: 'Fyll kurven min', body: 'Som over, pluss legger treff rett i kurven mens du er borte — med kvittering når du åpner. Betaler aldri.'),
          AegilLevel(
            level: 4,
            name: 'Fast ukeshandel',
            body: 'Som over, pluss en fast ukentlig dagligvarehandel: Ægil bygger den, du får et vindu til å se over, Vipps faste betalinger trekker.',
            requiresRecurring: true,
          ),
        ];

  static const List<String> _matFisk = ['fisk', 'gront', 'bakeri', 'mat'];

  List<AeRamme> get _rammer {
    final s = _settings ?? const AegilSettings();
    String ro(AegilSettings s) => s.hasQuietHours ? '${s.quietHoursFrom}–${s.quietHoursTo}' : AeCopy.rmRoIngen;
    final kat = s.allowedCategories.isEmpty
        ? AeCopy.rmKatAlle
        : (s.allowedCategories.contains('restaurant') ? AeCopy.rmKatMatRest : AeCopy.rmKatMat);
    final bel = s.capPerOrderOre == null ? AeCopy.rmBelIngen : AeCopy.rmBelVerdi(s.capPerOrderOre! ~/ 100, (s.capPerWeekOre ?? 0) ~/ 100);
    const mint = Color(0xFF7FF0CB);
    return [
      AeRamme(AeCopy.rmBut, s.allowedStoreMode == 'allowlist' ? AeCopy.rmButFav : AeCopy.rmButAlle, AeCopy.endre, mint, _byttButikker),
      AeRamme(AeCopy.rmKat, kat, AeCopy.endre, mint, () {
        final neste = s.allowedCategories.isEmpty ? _matFisk : (s.allowedCategories.contains('restaurant') ? <String>[] : [..._matFisk, 'restaurant']);
        _endre({'allowed_categories': neste});
      }),
      AeRamme(AeCopy.rmBel, bel, AeCopy.endre, mint, () {
        const valg = [(60000, 150000), (40000, 100000), (100000, 300000), null];
        final i = valg.indexWhere((v) => v?.$1 == s.capPerOrderOre);
        final n = valg[(i + 1) % valg.length];
        _endre({'cap_per_order': n?.$1, 'cap_per_week': n?.$2});
      }),
      AeRamme(AeCopy.rmRo, ro(s), AeCopy.endre, mint, () {
        const valg = [('21:00', '08:00'), ('22:00', '09:00'), null];
        final i = valg.indexWhere((v) => v?.$1 == s.quietHoursFrom);
        final n = valg[(i + 1) % valg.length];
        _endre({'quiet_hours': n == null ? null : {'from': n.$1, 'to': n.$2}});
      }),
      AeRamme(AeCopy.rmLaer, s.learningEnabled ? AeCopy.paa : AeCopy.av, s.learningEnabled ? AeCopy.slaaAv : AeCopy.slaaPaa, s.learningEnabled ? const Color(0xFFFF9A6B) : mint, () {
        _endre({'learning_enabled': !s.learningEnabled});
      }),
    ];
  }

  /// «Alle i nærheten» ↔ «Bare favoritter» (the allowlist is the customer's
  /// favourite stores).
  Future<void> _byttButikker() async {
    final s = _settings ?? const AegilSettings();
    if (s.allowedStoreMode == 'allowlist') {
      return _endre({'allowed_store_mode': 'all', 'allowed_store_ids': <int>[]});
    }
    final fav = await _customer.favourites();
    final ids = [
      for (final f in ((fav?['favourites'] ?? fav?['stores'] ?? const []) as List).whereType<Map>()) (f['store_id'] ?? f['id']) as num?,
    ].whereType<num>().map((e) => e.toInt()).toList();
    if (!mounted) return;
    if (ids.isEmpty) {
      LfToast.show(context, BergenRoutes.kommerSnart);
      return;
    }
    _endre({'allowed_store_mode': 'allowlist', 'allowed_store_ids': ids});
  }

  void _pause() {
    final pauset = _settings?.paused ?? false;
    _endre(
      {'paused_until': pauset ? null : DateTime.now().add(const Duration(days: 365)).toIso8601String()},
      toast: pauset ? AeCopy.iGangIgjen : AeCopy.pauset,
    );
  }

  String get _varsler {
    final s = _settings ?? const AegilSettings();
    final push = switch (s.pushMode) {
      'off' => AeCopy.pushAldri,
      'daily' => AeCopy.pushDag,
      _ => AeCopy.pushBraMaks,
    };
    String kort(String? t) => (t ?? '').split(':').first;
    return AeCopy.varselLinje(push, s.hasQuietHours ? '${kort(s.quietHoursFrom)}–${kort(s.quietHoursTo)}' : null);
  }

  // ── Memory ────────────────────────────────────────────────────────────────

  AeMinneData get _minneData => AeMinneData(_minne.where((m) => !_skjult.contains(m.id)).toList());

  Future<void> _glemAlt() async {
    HapticFeedback.mediumImpact();
    final ok = await a3Try(_repo.forgetAll);
    if (!mounted) return;
    if (ok == true) {
      setState(() => _skjult.clear());
      await _lastMinne();
      if (!mounted) return;
      LfToast.show(context, AeCopy.glemtAlt);
      _gaa('minne');
    } else {
      LfToast.show(context, BergenRoutes.kommerSnart);
    }
  }

  // UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
  // There is no endpoint to forget one line (only «Glem alt»): «Fjern» hides it here.
  void _fjern(MemoryEntry m) => setState(() => _skjult.add(m.id));

  /// «Stemmer»: the line restated as an explicit choice.
  Future<void> _stemmer(MemoryEntry m) async {
    final r = await a3Try(() => _repo.submitChips([OnboardingChip(kind: m.kind, value: m.value, label: m.label ?? m.value, selected: true)]));
    if (!mounted || r == null) return;
    await _lastMinne();
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  void _obStart() {
    setState(() => _ob = AeOb());
    _gaa('ob1');
    _lastButikker();
  }

  Future<void> _lastButikker() async {
    if (_obButikker.isNotEmpty) return;
    final kat = await _butikkApi.categories();
    final alle = <int, AeObButikk>{};
    for (final c in kat.take(8)) {
      final l = await _butikkApi.storesInCategory(c.serviceCategoryId);
      for (final s in l) {
        final id = s.storeId ?? 0;
        if (id == 0 || alle.containsKey(id)) continue;
        alle[id] = AeObButikk(
          id: id,
          navn: s.storeName ?? '',
          kat: c.serviceCategoryName,
          km: double.tryParse('${s.distance ?? ''}'),
          min: s.orderDeliveryTime,
        );
      }
    }
    final mine = [for (final o in _h?.hist ?? const <HbOrdre>[]) o.butikkId];
    final liste = alle.values.toList()
      ..sort((a, b) {
        final ia = mine.indexOf(a.id), ib = mine.indexOf(b.id);
        if (ia != ib) return (ia < 0 ? 1 << 20 : ia).compareTo(ib < 0 ? 1 << 20 : ib);
        return (a.km ?? 99).compareTo(b.km ?? 99);
      });
    if (mounted) setState(() => _obButikker = liste);
  }

  String get _oppsummering {
    final o = _ob;
    String del(Iterable<String> a) => a.where((x) => x.isNotEmpty).join(', ');
    final hus = o.hus.isEmpty ? '' : '${o.hus} ${o.hus == '1' ? AeCopy.personer1 : AeCopy.personer}';
    final kost = o.kost.where((k) => k != AeCopy.kost.last);
    return del([
      del((o.mat.isNotEmpty ? o.mat : o.kat).map((x) => x.toLowerCase())),
      del([for (final b in _obButikker) if (o.but.contains(b.id)) b.navn]),
      hus,
      if (kost.isNotEmpty) '${AeCopy.ingen} ${del(kost.map((x) => x.toLowerCase()))}',
      if (o.dager.isNotEmpty) '${AeCopy.middag} ${del(o.dager.map((x) => x.toLowerCase()))}',
    ]);
  }

  /// `obStemmer`: the answers to `agent/me/preferences/batch`, the alert
  /// choice to the settings, then «Så mye kan Ægil gjøre».
  Future<void> _obLagre() async {
    final o = _ob;
    const katNo = ['restaurant', 'mat og fisk', 'mote', 'interiør', 'gaver'];
    const matNo = ['pizza', 'sushi', 'fisk', 'indisk', 'thai', 'burger', 'salat', 'vegetar', 'hjemmelaget', 'noe annet'];
    const kostNo = ['nøtter', 'gluten', 'laktose', 'skalldyr', 'vegetar', 'vegansk', 'halal'];
    const dagNo = ['mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'];
    final chips = <OnboardingChip>[
      for (final (i, k) in AeCopy.kat.indexed)
        if (o.kat.contains(k)) OnboardingChip(kind: 'like', value: 'kategori:${katNo[i]}', label: k, selected: true),
      for (final (i, m) in AeCopy.mat.indexed)
        if (o.mat.contains(m)) OnboardingChip(kind: 'like', value: matNo[i], label: m, selected: true),
      for (final b in _obButikker)
        if (o.but.contains(b.id)) OnboardingChip(kind: 'store', value: '${b.id}', label: b.navn, selected: true),
      if (o.hus.isNotEmpty) OnboardingChip(kind: 'household', value: o.hus, label: '${o.hus} ${o.hus == '1' ? AeCopy.personer1 : AeCopy.personer}', selected: true),
      for (final (i, k) in AeCopy.kost.indexed)
        if (i < 7 && o.kost.contains(k)) OnboardingChip(kind: i < 4 ? 'allergen' : 'diet', value: kostNo[i], label: k, selected: true),
      for (final (i, d) in AeCopy.dager.indexed)
        if (o.dager.contains(d)) OnboardingChip(kind: 'dinner', value: dagNo[i], label: _stor(AeCopy.dagerLang[i]), selected: true),
    ];
    setState(() => _obLagrer = true);
    final r = chips.isEmpty ? (stored: 0, error: null) : await a3Try(() => _repo.submitChips(chips));
    if (o.varsel.isNotEmpty) {
      final i = AeCopy.varsel.indexOf(o.varsel);
      await a3Try(() => _repo.updateSettings({'push_mode': const ['off', 'daily', 'good_only'][i]}));
    }
    if (!mounted) return;
    setState(() => _obLagrer = false);
    if (r == null || r.error != null) {
      LfToast.show(context, AeCopy.obFeil);
      return;
    }
    await _lastMinne();
    unawaited(a3Try(_repo.fetchSettings).then((s) {
      if (mounted && s?.settings != null) setState(() => _settings = s!.settings);
    }));
    HurtigKilde.load(refresh: true);
    if (!mounted) return;
    _gaa('nivaa');
    LfToast.show(context, AeCopy.obToast);
  }

  static String _stor(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Header (`hodeVals` / `vcVals`) ────────────────────────────────────────

  bool get _vcAktiv => _vc.isNotEmpty;

  AeMelding? get _sistAeg => _vc.lastWhere((m) => !m.meg, orElse: () => AeMelding.meg(''));

  String get _tilstand {
    if (_vcAktiv) {
      if (_tenker) return AeCopy.skriver;
      final m = _sistAeg;
      if (m == null || m.meg) return AeCopy.herForDeg;
      return switch (m.state) {
        'agForslag' => (m.kurv?.lines.where((l) => l.storeProductId != null && l.priceOre > 0 && (m.kurv?.storeId == null || l.storeId == m.kurv?.storeId)).length ?? 0) >= 3 ? AeCopy.fantTre : AeCopy.fantNoe,
        'agFunn' => AeCopy.fantNoe,
        'agFiks' => AeCopy.fikser,
        'agSammen' => AeCopy.sammenlikner,
        'agIkkeFunnet' || 'agAldersblokk' => AeCopy.beklager,
        _ => AeCopy.herForDeg,
      };
    }
    if (_steg.startsWith('ob')) return AeCopy.sporDeg;
    return switch (_steg) {
      'minne' => AeCopy.detJegVet,
      'nivaa' => AeCopy.saaMye,
      _ => AeCopy.lytter,
    };
  }

  String get _humor {
    if (_tenker) return 'tenker';
    final m = _sistAeg;
    return m == null || m.meg ? 'glad' : m.humor;
  }

  AeHode get _hode {
    if (_vcAktiv) {
      return switch (_humor) {
        'tenker' => AeHode.find,
        'spent' => AeHode.discount,
        'lei' => AeHode.sorry,
        _ => AeHode.popup,
      };
    }
    if (_steg.startsWith('ob')) return AeHode.popup;
    return switch (_steg) {
      'minne' || 'nivaa' => AeHode.popup,
      _ => AeHode.front,
    };
  }

  AeKropp get _kropp {
    if (_vcAktiv) {
      if (_tenker) return AeKropp.leter;
      return switch (_humor) {
        'lei' => AeKropp.lei,
        'tenker' => AeKropp.rygg,
        _ => AeKropp.hei,
      };
    }
    return _steg == 'start' || _steg == 'tillatelse' ? AeKropp.hei : AeKropp.rygg;
  }

  BergenWeatherLook get _look {
    if (kDebugMode && HjemHarness.vaer != null) {
      return switch (HjemHarness.vaer!) {
        HjemVaer.regn => BergenWeatherLook.regn,
        HjemVaer.sol => BergenWeatherLook.sol,
        HjemVaer.solnedgang => BergenWeatherLook.solnedgang,
        HjemVaer.natt => BergenWeatherLook.natt,
      };
    }
    return BergenWeatherLook.forHour(DateTime.now().hour);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF2F5462),
        resizeToAvoidBottomInset: false,
        body: LfFrame(
          child: Builder(
            builder: (context) {
              final mq = MediaQuery.of(context);
              final kb = mq.viewInsets.bottom;
              final bunn = kb > 0 ? kb + 10 : math.max(mq.padding.bottom, 16.0);
              final kurvPaa = _vcAktiv && !_kurv.isEmpty && kb == 0;
              return Stack(
                children: [
                  // The page (`skjermInn .34s`).
                  Positioned.fill(
                    child: AeOnce(
                      kind: AeInn.skjermInn,
                      ms: 340,
                      curve: const Cubic(.2, .9, .3, 1),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF7E93A3), Color(0xFF9FB2BD), Color(0xFFB6BFB8), Color(0xFF456E7C), Color(0xFF2F5462)],
                                  stops: [0, .12, .17, .21, 1],
                                ),
                              ),
                            ),
                          ),
                          Positioned(left: 0, top: 0, width: 390, height: 252, child: AegilScene(look: _look, kropp: _kropp, lytter: _steg == 'start' && !_vcAktiv)),
                          Positioned(left: 0, right: 0, top: 222, bottom: 0, child: _ark(bunn, kurvPaa)),
                        ],
                      ),
                    ),
                  ),
                  if (kurvPaa) Positioned(left: 16, right: 16, bottom: bunn + 72, height: 64, child: _kurvStripe()),
                  ..._felt(bunn),
                  if (_butArk)
                    Positioned.fill(
                      child: AeButArk(
                        butikker: _obButikker,
                        valgt: _ob.but,
                        onVelg: (id) => setState(() => _ob.veksle(_ob.but, id)),
                        onLukk: () => setState(() => _butArk = false),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The teal sheet (`top:222px`, radius 30).
  Widget _ark(double bunn, bool kurvPaa) {
    return CssBox(
      radius: const BorderRadius.vertical(top: Radius.circular(30)),
      bg: const [
        CssRadial([Color.fromRGBO(255, 255, 255, .26), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
        CssLinear(180, [Color(0xFF2A6272), kAeTeal, Color(0xFF173E48)], [0, .42, 1]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
        CssShadow(0, -24, 50, -18, Color.fromRGBO(4, 18, 26, .8)),
      ],
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: const Color.fromRGBO(255, 255, 255, .28)),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: _hodeRad()),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 82,
            bottom: bunn + (kurvPaa ? 148 : 76) - 0,
            child: SingleChildScrollView(
              key: const Key('a1_aegil_rull'),
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(key: ValueKey(_vcAktiv ? 'vc' : _steg), child: _innhold()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hodeRad() => Row(
    children: [
      AegilHode(hode: _hode, tikk: _tikk),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AeCopy.navn, style: jakarta(19, em: -.025, height: 1.05)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kAeMint, boxShadow: [BoxShadow(color: kAeMint, blurRadius: 4)]),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(_tilstand, key: const Key('a1_aegil_tilstand'), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, weight: FontWeight.w800, height: 1.05, color: kAeMint)),
                ),
              ],
            ),
          ],
        ),
      ),
      AePress(
        key: const Key('a1_aegil_nivaa_chip'),
        onTap: _byttNivaa,
        dy: 0,
        scale: .95,
        child: CssBox(
          height: 36,
          radius: BorderRadius.circular(999),
          bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .1))],
          shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22))],
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
          padding: const EdgeInsets.fromLTRB(11, 0, 5, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF2C14E),
                  boxShadow: [BoxShadow(color: Color.fromRGBO(242, 193, 78, .9), blurRadius: 3)],
                ),
              ),
              const SizedBox(width: 6),
              Text(handler ? AeCopy.handle : AeCopy.foreslaa, style: inter(11.5, weight: FontWeight.w800)),
              const SizedBox(width: 6),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .14)),
                alignment: Alignment.center,
                child: const AeIkon('M9 6l6 6-6 6', size: 11, stroke: 2.6),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _innhold() {
    if (_vcAktiv) return _chat();
    final ob = RegExp(r'^ob(\d)$').firstMatch(_steg);
    if (ob != null) return _obSteg(int.parse(ob.group(1)!));
    switch (_steg) {
      case 'minne':
        return AeMinneView(
          data: _minneData,
          varsler: _varsler,
          nivaaNavn: _nivaaer.where((n) => n.level == (_settings?.level ?? 2)).firstOrNull?.name ?? '',
          onFjern: _fjern,
          onStemmer: _stemmer,
          onLeggTil: _obStart,
          onNivaa: () => _gaa('nivaa'),
          onGlem: _glemAlt,
        );
      case 'nivaa':
        return AeNivaaView(
          nivaaer: _nivaaer,
          valgt: _settings?.level ?? 2,
          rammer: _rammer,
          pauset: _settings?.paused ?? false,
          onVelg: _velgNivaa,
          onPause: _pause,
          onGlem: _glemAlt,
          onTilbake: () => _gaa('start'),
        );
      case 'tillatelse':
        return AeTillatelseView(
          handler: handler,
          onVelg: (h) {
            if (h != handler) _byttNivaa();
          },
          onAlle: () => _gaa('nivaa'),
          onKomIGang: () {
            prefSetBool(AegilScreen.prefTillatelse, true);
            _gaa('start');
          },
        );
      case 'obSum':
        return AeObSum(
          oppsummering: AeCopy.sumTekst(_oppsummering),
          poeng: _ob.poeng,
          linjer: _ob.linjer,
          lagrer: _obLagrer,
          onStemmer: _obLagre,
          onEndre: () => _gaa('ob1'),
        );
    }
    return _start();
  }

  Widget _start() {
    final now = DateTime.now();
    final hhmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final d = _minneData;
    final tips = _tips;
    final navn = _h?.navn ?? prefGetString(prefUserName).trim().split(RegExp(r'\s+')).first;
    final hilsen = !d.tom && tips != null && tips.pleier
        ? AeCopy.igjen(AeCopy.dagerLang[now.weekday - 1], tips.butikk)
        : '${BergenCopy.greeting(now.hour, navn)}. ${AeCopy.sporsmaal(now.hour)}';
    return AeStartView(
      kicker: AeCopy.kicker(hhmm, AeCopy.dagerLang[now.weekday - 1]),
      hilsen: hilsen,
      husker: d.topp,
      tilbud: _minneLastet && d.tom && !_avslaatt,
      tips: tips,
      onMinne: () => _gaa('minne'),
      onObStart: _obStart,
      onIkkeNaa: () {
        prefSetBool(AegilScreen.prefAvslaatt, true);
        setState(() => _avslaatt = true);
      },
      onBestill: _bestillIgjen,
      onEndre: () => _si(AeCopy.endreSist(tips?.butikk ?? '')),
      onSi: _si,
      onSok: _tilSok,
    );
  }

  Widget _chat() {
    final n = _vc.length;
    final sist = n == 0 ? null : _vc.last;
    final dF = sist != null && !sist.meg ? AeSvar.slutt(sist) : 200.0;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AeNyPrat(onTap: _nyPrat),
          for (final (i, m) in _vc.indexed) ...[
            const SizedBox(height: 14),
            if (m.meg)
              AeMegBoble(key: ValueKey(m.id), tekst: m.tekst, ny: i == n - 1)
            else ...[
              AeSvar(key: ValueKey(m.id), m: m, forst: i == 0 || _vc[i - 1].meg, ny: i == n - 1, h: this),
              if (m.kurv != null && m.kurv!.lines.any((l) => l.storeProductId != null)) ...[const SizedBox(height: 10), const AeAllergen()],
            ],
          ],
          if (_tenker) ...[const SizedBox(height: 14), const AeTenker()],
          if (!_tenker && _forslag.isNotEmpty) ...[
            const SizedBox(height: 14),
            AeForslag(key: ValueKey('fs${sist?.id}'), forslag: _forslag, delay: dF, onTap: _si),
          ],
        ],
      ),
    );
  }

  Widget _obSteg(int n) {
    final o = _ob;
    Widget chips(List<String> l, bool Function(String) paa, void Function(String) velg, {double gap = 9}) => Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final t in l) AeObChip(key: ValueKey(t), t: t, paa: paa(t), onTap: () => setState(() => velg(t)))],
    );
    Widget kicker(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 9),
      child: Text(t, style: inter(10, weight: FontWeight.w800, em: .1, color: const Color(0xFF8C847C))),
    );
    final (sp, hint, innhold, valg, poeng) = switch (n) {
      1 => (AeCopy.ob1, AeCopy.ob1Hint, chips(AeCopy.kat, o.kat.contains, (t) => o.veksle(o.kat, t)), o.kat.length, o.kat.length * 5),
      2 => (AeCopy.ob2, AeCopy.ob2Hint, chips(AeCopy.mat, o.mat.contains, (t) => o.veksle(o.mat, t)), o.mat.length, o.mat.length * 5),
      3 => (
        AeCopy.ob3,
        AeCopy.ob3Hint,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final b in _obButikker.take(6)) AeObChip(key: ValueKey(b.id), t: b.navn, paa: o.but.contains(b.id), onTap: () => setState(() => o.veksle(o.but, b.id))),
              ],
            ),
            const SizedBox(height: 11),
            GestureDetector(
              key: const Key('a1_aegil_vis_flere'),
              onTap: () => setState(() => _butArk = true),
              child: Text(AeCopy.visFlere, style: inter(11.5, weight: FontWeight.w800, color: kAeTeal)),
            ),
          ],
        ),
        o.but.length,
        o.but.length * 5,
      ),
      4 => (
        AeCopy.ob4,
        AeCopy.ob4Hint,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chips(AeCopy.hus, (t) => o.hus == t, (t) => o.hus = o.hus == t ? '' : t),
            kicker(AeCopy.unngaar),
            chips(AeCopy.kost, o.kost.contains, (t) => o.veksle(o.kost, t)),
          ],
        ),
        o.hus.isEmpty ? 0 : 1,
        ((o.hus.isEmpty ? 0 : 1) + o.kost.length) * 5,
      ),
      _ => (
        AeCopy.ob5,
        AeCopy.ob5Hint,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chips(AeCopy.dager, o.dager.contains, (t) => o.veksle(o.dager, t), gap: 7),
            kicker(AeCopy.naarTilbud),
            chips(AeCopy.varsel, (t) => o.varsel == t, (t) => o.varsel = o.varsel == t ? '' : t),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color.fromRGBO(30, 79, 92, .07)),
              child: Row(
                children: [
                  AeIkon('M18 15.5A6 6 0 0 1 12 21a6 6 0 0 1-6-5.5${AeIkon.sirkel(12, 12, 8.5)}M12 7.5V12l3 2', size: 13, stroke: 2.2, color: kAeTeal),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      AeCopy.roligeTimer(_settings?.hasQuietHours ?? false ? '${_settings!.quietHoursFrom}–${_settings!.quietHoursTo}' : '21:00–08:00'),
                      style: inter(11, weight: FontWeight.w700, color: kAeTeal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        o.dager.length,
        (o.dager.length + (o.varsel.isEmpty ? 0 : 1)) * 5,
      ),
    };
    return AeObSteg(
      key: ValueKey('ob$n'),
      steg: n,
      sporsmaal: sp,
      hint: hint,
      innhold: innhold,
      harValg: valg > 0,
      poeng: poeng,
      siste: n == 5,
      onNeste: () => _gaa(n == 5 ? 'obSum' : 'ob${n + 1}'),
      onHopp: () => _gaa(n == 5 ? 'obSum' : 'ob${n + 1}'),
      onAvbryt: () => _gaa('start'),
    );
  }

  /// The basket strip (`agKurv`, `bottom:88px`): the real basket, and
  /// «Betal med Vipps» which opens the basket — paying is done there.
  Widget _kurvStripe() {
    final ant = _kurv.lines.fold<int>(0, (n, l) => n + l.quantity);
    final innen = DateTime.now().add(const Duration(minutes: 35));
    final hhmm = '${innen.hour.toString().padLeft(2, '0')}:${innen.minute.toString().padLeft(2, '0')}';
    return AeOnce(
      kind: AeInn.stigOpp,
      ms: 450,
      curve: const Cubic(.3, 1.2, .5, 1),
      child: CssBox(
        key: const Key('a1_aegil_kurv'),
        radius: BorderRadius.circular(20),
        bg: const [
          CssLinear(160, [Color(0xFF2A6272), kAeTeal, Color(0xFF173E48)], [0, .6, 1]),
        ],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
          CssShadow(0, 18, 32, -14, Color.fromRGBO(30, 79, 92, .75)),
        ],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AeCopy.kurvAnt(ant), style: inter(11, weight: FontWeight.w700, color: const Color(0xFFB9CBD5))),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${_kurv.subtotal.round()} kr '),
                        TextSpan(text: '· ${AeCopy.innen(hhmm)}', style: inter(12, weight: FontWeight.w700, color: const Color(0xFFDCE9EC))),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: aeTab(jakarta(16, em: -.01)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AePress(
              key: const Key('a1_aegil_betal'),
              onTap: () => _tilFane(2),
              dy: 0,
              scale: .96,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 20, 30, .5), offset: Offset(0, 8), blurRadius: 7, spreadRadius: -8)],
                ),
                child: Text(AeCopy.betalVipps, style: inter(13.5, weight: FontWeight.w800, color: kAeTeal)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The composer (`agFeltVals`) and the floating ✕ (`tilHjem`).
  List<Widget> _felt(double bunn) {
    final har = _tekst.text.trim().isNotEmpty;
    final fok = _fokus.hasFocus || har;
    final prompt = _vcAktiv ? AeCopy.promptChat : (_steg == 'start' ? AeCopy.promptStart : AeCopy.promptEndre);
    return [
      AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: const Cubic(.3, 1.15, .4, 1),
        left: 14,
        right: fok ? 14 : 86,
        bottom: bunn,
        height: 62,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.ease,
          padding: const EdgeInsets.fromLTRB(17, 0, 7, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: fok ? const [Color(0xFF31697A), Color(0xFF21566A)] : const [Color(0xFF2B5F6E), kAeTeal],
            ),
            border: Border.all(color: fok ? const Color.fromRGBO(92, 224, 184, .6) : const Color.fromRGBO(255, 255, 255, .28)),
            boxShadow: [
              BoxShadow(color: Color.fromRGBO(92, 224, 184, fok ? .14 : 0), spreadRadius: 4),
              const BoxShadow(color: Color.fromRGBO(4, 18, 26, .85), offset: Offset(0, 18), blurRadius: 17, spreadRadius: -14),
            ],
          ),
          child: Row(
            children: [
              AeTw(
                v: fok ? 1 : 0,
                ms: 450,
                curve: const Cubic(.3, 1.5, .5, 1),
                builder: (t) => Transform.rotate(
                  angle: rad(-12 * t),
                  child: Transform.scale(
                    scale: 1 + .15 * t,
                    child: AeTw(v: fok ? 1 : 0, ms: 300, builder: (c) => AeGevir(color: Color.lerp(const Color(0xFFF26D3D), kAeMint, c)!)),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  key: const Key('a1_aegil_felt'),
                  controller: _tekst,
                  focusNode: _fokus,
                  onSubmitted: (_) => _si(_tekst.text),
                  textInputAction: TextInputAction.send,
                  cursorColor: kAeMint,
                  style: jakarta(14, weight: FontWeight.w700),
                  decoration: onbBareInput(
                    hint: prompt,
                    hintStyle: jakarta(14, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6)),
                  ).copyWith(hintMaxLines: 1),
                ),
              ),
              const SizedBox(width: 9),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: fok ? 0 : 1,
                child: Container(width: 1, height: 26, color: const Color.fromRGBO(255, 255, 255, .14)),
              ),
              const SizedBox(width: 9),
              _knapp(fok, har),
            ],
          ),
        ),
      ),
      Positioned(
        right: 14,
        bottom: bunn,
        width: 62,
        height: 62,
        child: IgnorePointer(
          ignoring: fok,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: fok ? 0 : 1,
            child: AeTw(
              v: fok ? 1 : 0,
              ms: 450,
              curve: const Cubic(.3, 1.3, .5, 1),
              builder: (t) => Transform.rotate(
                angle: rad(-90 * t),
                child: Transform.scale(scale: 1 - .6 * t, child: _Lukk(onTap: () => _tilFane(0))),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// The orange key: Ægil (`agAvOp`) and the mic (`agMikX`) when empty, the
  /// arrow (`agPil*`) with text; 92 → 46 wide in use.
  Widget _knapp(bool fok, bool har) => AePress(
    key: const Key('a1_aegil_send'),
    onTap: har ? () => _si(_tekst.text) : () => LfToast.show(context, AeCopy.stemme),
    dy: 0,
    scale: .92,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: const Cubic(.3, 1.25, .4, 1),
      width: fok ? 46 : 92,
      height: 46,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        gradient: LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFFFF9466), Color(0xFFE95C2C)]),
        boxShadow: [
          BoxShadow(color: Color(0xFFA63A12), offset: Offset(0, 2.5)),
          BoxShadow(color: Color.fromRGBO(3, 16, 24, .75), offset: Offset(0, 10), blurRadius: 7, spreadRadius: -8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(left: 0, right: 0, bottom: 0, height: 2, child: ColoredBox(color: Color.fromRGBO(0, 0, 0, .08))),
            const Positioned(left: 0, right: 0, top: 0, height: 1, child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .45))),
            Positioned(
              left: 5,
              top: 5,
              width: 36,
              height: 36,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 280),
                opacity: fok ? 0 : 1,
                child: AeTw(
                  v: fok ? 1 : 0,
                  ms: 450,
                  curve: const Cubic(.3, 1.3, .5, 1),
                  builder: (t) => Transform.translate(
                    offset: Offset(-22 * t, 0),
                    child: Transform.scale(scale: 1 - .5 * t, child: Transform.rotate(angle: rad(-20 * t), child: const _KnappAegil())),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: const Cubic(.3, 1.25, .4, 1),
              left: fok ? 16 : 61,
              top: 16,
              width: 14,
              height: 14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: har ? 0 : 1,
                child: AeTw(
                  v: har ? 1 : 0,
                  ms: 400,
                  curve: const Cubic(.3, 1.4, .5, 1),
                  builder: (t) => Transform.scale(
                    scale: 1 - .7 * t,
                    child: Transform.rotate(
                      angle: rad(-30 * t),
                      child: const AeIkon('M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-3 3a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3zM5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21', size: 14, stroke: 2.2),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              width: 18,
              height: 18,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: har ? 1 : 0,
                child: AeTw(
                  v: har ? 0 : 1,
                  ms: 450,
                  curve: const Cubic(.3, 1.5, .5, 1),
                  builder: (t) => Transform.translate(
                    offset: Offset(0, 14 * t),
                    child: Transform.scale(scale: 1 - .5 * t, child: const AeIkon('M12 19V5M5.5 11.5L12 5l6.5 6.5', size: 18, stroke: 2.8)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Debug harness (`Documents/hjem_state.json`) ───────────────────────────

  void _harness() {
    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      final steg = HjemHarness.aegil!;
      if (steg != 'chat') _gaa(steg);
      if (steg.startsWith('ob') || steg == 'obSum') _lastButikker();
      if (HjemHarness.aegOb) {
        setState(() {
          _ob = AeOb()
            ..kat.addAll([AeCopy.kat[1], AeCopy.kat[2]])
            ..mat.addAll([AeCopy.mat[2], AeCopy.mat[4]])
            ..hus = AeCopy.hus[1]
            ..kost.add(AeCopy.kost[3])
            ..dager.addAll([AeCopy.dager[1], AeCopy.dager[3]])
            ..varsel = AeCopy.varsel[2];
        });
      }
      if (HjemHarness.aegButArk) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) setState(() => _butArk = true);
      }
      for (final t in HjemHarness.aegSi ?? const <String>[]) {
        if (!mounted) return;
        await _si(t);
        await Future.delayed(const Duration(milliseconds: 1200));
      }
      if (HjemHarness.aegTenk && mounted) {
        setState(() {
          _vc.add(AeMelding.meg(HjemHarness.aegTekst ?? AeCopy.tacoSi));
          _tenker = true;
        });
      } else if (HjemHarness.aegTekst case final t?) {
        _tekst.text = t;
      }
      if (HjemHarness.aegFokus && mounted) _fokus.requestFocus();
      if (HjemHarness.aegScroll case final y?) {
        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted && _scroll.hasClients) _scroll.jumpTo(y.clamp(0.0, _scroll.position.maxScrollExtent));
      }
      debugPrint('AEGIL_HARNESS applied');
    });
  }
}

/// Ægil in the key's 36 px window (`aegVink 2.6s`).
class _KnappAegil extends StatelessWidget {
  const _KnappAegil();

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFFDCE9EC), Color(0xFF9FB6C2)]),
    ),
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(left: -8, top: 2, width: 52, child: AeLoop(m: (t) => aegVink(t, 2600), child: Image.asset(aePose('popup'), width: 52))),
        const Positioned(left: 0, right: 0, top: 0, height: 1, child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .6))),
      ],
    ),
  );
}

/// The floating orange ✕ (`aeKnSvev 3.4s -.2s` over `aeKnSkygge`).
class _Lukk extends StatelessWidget {
  const _Lukk({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('a1_aegil_lukk'),
    onTap: onTap,
    child: RepaintBoundary(
      child: LfLoopSvev(
        child: CssBox(
          width: 62,
          height: 62,
          radius: BorderRadius.circular(999),
          bg: const [
            CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)]),
          ],
          shadows: const [
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
            CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(150, 40, 10, .3)),
          ],
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .35)),
          child: const Center(child: AeIkon('M6 6l12 12M18 6L6 18', size: 20, stroke: 2.6)),
        ),
      ),
    ),
  );
}

/// `aeKnSvev` (translateY 0 → −5 → 0) with the soft shadow below
/// (`aeKnSkygge`: scaleX 1 → .82, opacity 1 → .6).
class LfLoopSvev extends StatelessWidget {
  const LfLoopSvev({super.key, required this.child, this.phaseMs = 200});

  final Widget child;
  final double phaseMs;

  @override
  Widget build(BuildContext context) => LfLoopBuilder(
    child: child,
    builder: (t, child) {
      final p = ((t + phaseMs) / 3400) % 1.0;
      final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
      final sx = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
      final o = kf(p, const [0, .5, 1], const [1, .6, 1], cssEaseInOut);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 62 * .1,
            right: 62 * .1,
            top: 63,
            height: 15,
            child: Opacity(
              opacity: o,
              child: Transform.translate(
                offset: Offset(0, 5 * (1 - (sx - .82) / .18)),
                child: Transform.scale(
                  scaleX: sx,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(25, 7.5)),
                      gradient: RadialGradient(colors: [Color.fromRGBO(8, 26, 32, .5), Color.fromRGBO(0, 0, 0, 0)], stops: [0, .72]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(0, y), child: child),
        ],
      );
    },
  );
}

/// [LfLoop] with a simpler builder signature.
class LfLoopBuilder extends StatelessWidget {
  const LfLoopBuilder({super.key, required this.builder, required this.child});

  final Widget Function(double t, Widget child) builder;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfLoop(child: child, builder: (context, t, c) => builder(t, c!));
}
