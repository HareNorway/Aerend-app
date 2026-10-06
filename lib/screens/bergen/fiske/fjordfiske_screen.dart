import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/suggestion_models.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../data/ops/fiske_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../../data/ops/favourite_stores.dart';
import '../kit/bergen_kit.dart';
import '../meg/a3_services.dart';
import '../poeng/napp_entry.dart';
import 'fiske_cards.dart';
import 'fiske_controls.dart';
import 'fiske_copy.dart';
import 'fiske_frame.dart';
import 'fiske_game.dart';
import '../../../utils/utils.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../kit/sjo_water.dart';
import '../hjem/hjem_harness.dart';
import 'fiske_line.dart';
import 'fiske_scene.dart';
import 'fiske_stang.dart';
import 'fiske_ui.dart';

/// Fjordfiske — `/bergen/fjordfiske` (`{{ erFiske }}`, L7890–8106 in `Ærend
/// Kunde Launch.dc.html`; logic `fiskeKast`, `fiskeDra`, `fiskePremieVelg`,
/// `fiskeDekk`, the rod `ffStart` L16296).
///
/// Ægil and the customer fish in Vågen: **Kast ut** → the line is out →
/// **NAPP!** → **DRA INN!** → the catch card (a suggestion from
/// `agent/suggestions?context=fiske`) with Slipp / Legg i kurven / Lagre.
/// From cast `fromCast` on, every `everyN`-th cast (at most `max` a session)
/// is a **Premiefangst** from `points/prizes/pick` with Hent / Sett som mål /
/// Slipp. Every reel earns through `points/me/earn?rule=dagens_napp`, capped
/// per day by the server; the cap is read before the first cast from
/// `ops.customer.fiske` and shown honestly (the hint line) when it is hit.
///
/// Layers (frame 390 × 844 fitted with one uniform scale, [FiskeFrame]):
/// [FiskeBakgrunn] — the sky, Bryggen baked from the prototype's WebGL canvas
/// and the real water shader mirroring it ([SjoWater], the prototype's pixel
/// budget) with ripples at the float; [FiskePier]; [FiskeAegil] per phase;
/// [FiskeStang] — the rod, line, float, rings and drops (`ffStart`, frame for
/// frame); the catch card [FiskeLFangstKort] / [FiskePremieCard] /
/// [FiskeFerdigCard]; Ægil's bubble; the bait rail [FiskeLAgnRail]; the header
/// and title; the controls ([FiskeLKastUt], [FiskeLVenter], [FiskeLDraInn],
/// [FiskeLRund]); the hint; and the shell's nav with no tab lit.
class FjordfiskeScreen extends StatefulWidget {
  const FjordfiskeScreen({
    super.key,
    this.points,
    this.aegil,
    this.random,
    this.rules = const FiskePrizeRules(),
    this.customerApi,
    this.storeLookup,
    this.addToCart,
    this.saveFavourite,
    this.weather,
  });

  /// Test seams (A3Services fakes in `test/a3/a3_fakes.dart`).
  final PointsAppApi? points;
  final AegilAppApi? aegil;
  final Random? random;

  /// Prize cadence (design tweaks `fiskePremieHverN` 8, `fiskePremieMaks` 3,
  /// `fiskePremieFraKast` 3); `ops.customer.fiske` overrides N and the first
  /// cast when it carries them.
  final FiskePrizeRules rules;

  final OpsCustomerApi? customerApi;
  final Future<BergenStoreInfo?> Function(int storeId)? storeLookup;
  final Future<bool> Function(
    BuildContext context, {
    required int storeId,
    required int productId,
  })?
  addToCart;
  final Future<bool> Function(int storeId)? saveFavourite;
  final BergenWeatherLook? weather;

  @override
  State<FjordfiskeScreen> createState() => _FjordfiskeScreenState();
}

class _FjordfiskeScreenState extends State<FjordfiskeScreen> {
  late final PointsAppApi _points = widget.points ?? A3Services.points();
  late final AegilAppApi _aegil = widget.aegil ?? A3Services.aegil();
  late final Random _rng = widget.random ?? Random();
  late final OpsCustomerApi _api = widget.customerApi ?? OpsCustomerApi();
  late FiskePrizeRules _rules = widget.rules;

  FiskeDeck _deck = const FiskeDeck([]);
  final Map<int, FiskeCatch> _catches = {};
  final Map<int, BergenStoreInfo?> _stores = {};

  FiskePhase _phase = FiskePhase.klar;
  int _idx = 0;
  int _kastNr = 0;
  AegilPick? _premie;
  int _premieAnt = 0;
  int _premieSiste = 0;
  int _lagret = 0;
  int _kjopt = 0;
  String? _sagt;
  EarnResult? _earn;
  FiskeDay? _day;
  int? _balance;
  int? _goalPrizeId;
  bool _loading = true;
  bool _nappGitt = false;

  FiskeCardAnim _cardAnim = FiskeCardAnim.fangstOpp;
  int _cardSeq = 0;
  int _bubbleSeq = 0;
  bool _lock = false;

  /// The water's ripples at the float (`sjoRippelPkt`).
  final SjoRipples _ripples = SjoRipples();

  Timer? _fk1;
  Timer? _fk2;
  Timer? _fk3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fk1?.cancel();
    _fk2?.cancel();
    _fk3?.cancel();
    super.dispose();
  }

  // ── data ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final pool =
        await a3Try(() => _aegil.suggestions(context: 'fiske')) ??
        const <Suggestion>[];
    if (!mounted) return;
    setState(() {
      _deck = FiskeDeck(pool);
      _loading = false;
    });
    if (kDebugMode) _harness();
    final day = await a3Try(_api.fiske);
    if (!mounted) return;
    if (day != null) {
      setState(() {
        _day = day;
        _rules = _rules.copyWith(
          everyN: day.prizeEveryN,
          fromCast: day.prizeFromCast,
        );
      });
    }
    final balance = await a3Try(_points.balance);
    if (mounted && balance != null)
      setState(() => _balance = balance.available);
    final shelf = await a3Try(_points.shelf);
    if (mounted && shelf?.goal?.prizeId != null) {
      setState(() => _goalPrizeId = shelf!.goal!.prizeId);
    }
  }

  /// Debug builds: `hjem_state.json`'s `fiskeFase` / `fiskeAgn`.
  void _harness() {
    final agn = HjemHarness.fiskeAgn;
    if (agn != null) _deck = _deck.withAgn(FiskeAgn.values.byName(agn));
    switch (HjemHarness.fiskeFase) {
      case 'kast':
        WidgetsBinding.instance.addPostFrameCallback((_) => _kast());
      case 'venter':
        setState(() => _phase = FiskePhase.venter);
      case 'napp':
        setState(() => _phase = FiskePhase.napp);
      case 'mistet':
        setState(() => _phase = FiskePhase.mistet);
      case 'fangst':
        final c = _current;
        if (c != null) _prefetchStore(c);
        setState(() {
          _phase = FiskePhase.fangst;
          _cardSeq += 1;
        });
      case 'premie':
        setState(() {
          // A sample prize (the prototype's first shelf item): no prizes
          // exist locally. Debug only.
          _premie = const AegilPick(
            prize: {'id': -1, 'name': 'Gratis levering', 'point_price': 400, 'line': 'Brukes automatisk på neste levering', 'tier_name': 'Bronse'},
            reason: '',
            affordable: true,
          );
          _phase = FiskePhase.fangst;
          _cardSeq += 1;
        });
      case 'ferdig':
        setState(() {
          _idx = _deck.cards.length;
          _lagret = 2;
          _kjopt = 1;
        });
    }
    setState(() => _bubbleSeq += 1);
  }

  Suggestion? get _current {
    final cards = _deck.cards;
    return _idx < cards.length ? cards[_idx] : null;
  }

  /// The card for [s], with the store read folded in once it has answered.
  FiskeCatch _catchFor(Suggestion s) {
    final cached = _catches[s.id];
    if (cached != null) return cached;
    final store = s.storeId == null ? null : _stores[s.storeId!];
    BergenMenuItem? item;
    if (store != null && s.storeProductId != null) {
      for (final c in store.menu) {
        for (final i in c.items) {
          if (i.id == s.storeProductId) item = i;
        }
      }
    }
    final built = FiskeCatch(
      suggestion: s,
      name: s.headline ?? item?.name ?? s.reason,
      // The suggestion's own card facts first (read live by the server), the
      // store read only where the server had nothing.
      storeName: s.storeName ?? store?.name,
      priceKr: s.priceOre != null
          ? (s.priceOre! / 100).round()
          : item?.price.round(),
      productId: s.storeProductId,
      bydel: s.bydel,
      eta: s.etaMinutes != null
          ? '${s.etaMinutes} min'
          : (store?.deliveryMinutes == null
                ? null
                : '${store!.deliveryMinutes} min'),
    );
    final complete =
        s.storeName != null &&
        s.etaMinutes != null &&
        (s.priceOre != null || s.storeProductId == null);
    if (complete || store != null || s.storeId == null) _catches[s.id] = built;
    return built;
  }

  Future<void> _prefetchStore(Suggestion s) async {
    final id = s.storeId;
    if (id == null || _stores.containsKey(id)) return;
    if (widget.storeLookup == null && !OpsCustomerApi.networkEnabled) return;
    final lookup = widget.storeLookup ?? OpsButikkApi().store;
    final info = await a3Try(() => lookup(id));
    if (!mounted) return;
    setState(() => _stores[id] = info);
  }

  // ── the cast ────────────────────────────────────────────────────────────

  void _cancelTimers() {
    _fk1?.cancel();
    _fk2?.cancel();
  }

  Future<void> _kast() async {
    if (_phase != FiskePhase.klar && _phase != FiskePhase.mistet) return;
    if (_current == null) return;
    HapticFeedback.selectionClick();
    _cancelTimers();
    final kastNr = _kastNr + 1;
    AegilPick? pr = _premie;
    var ant = _premieAnt;
    if (pr == null &&
        _rules.eligible(kastNr, taken: _premieAnt, lastAt: _premieSiste)) {
      final pick = await a3Try(_points.pick);
      if (!mounted) return;
      if (pick?.prize != null) {
        pr = pick;
        ant += 1;
      }
    }
    setState(() {
      _phase = FiskePhase.venter;
      _kastNr = kastNr;
      _premie = pr;
      _premieAnt = ant;
      _sagt = null;
      _bubbleSeq += 1;
    });
    _prefetchStore(_current!);
    _fk1 = Timer(Duration(milliseconds: 1500 + _rng.nextInt(1600)), () {
      if (!mounted) return;
      setState(() {
        _phase = FiskePhase.napp;
        _bubbleSeq += 1;
      });
      HapticFeedback.heavyImpact();
      _fk2 = Timer(const Duration(milliseconds: 1700), () {
        if (!mounted || _phase != FiskePhase.napp) return;
        setState(() {
          _phase = FiskePhase.mistet;
          _bubbleSeq += 1;
        });
        _fk1 = Timer(const Duration(milliseconds: 2200), () {
          if (!mounted || _phase != FiskePhase.mistet) return;
          setState(() {
            _phase = FiskePhase.klar;
            _bubbleSeq += 1;
          });
        });
      });
    });
  }

  Future<void> _dra() async {
    if (_phase != FiskePhase.napp) return;
    _fk2?.cancel();
    HapticFeedback.mediumImpact();
    final s = _current;
    final earn = await a3Try(
      () => _points.earn(catchNumber: _kastNr, suggestionId: s?.id),
    );
    if (!mounted) return;
    setState(() {
      _earn = earn;
      _phase = FiskePhase.fangst;
      _cardAnim = FiskeCardAnim.fangstOpp;
      _cardSeq += 1;
      _bubbleSeq += 1;
      if (_premie != null) _premieSiste = _kastNr;
      // «Dagens napp»: the first catch of the day that earned — the server
      // read said nothing was taken yet, and nothing has been since.
      if (s != null &&
          earn != null &&
          earn.earned > 0 &&
          !_nappGitt &&
          (_day == null || _day!.today == 0)) {
        _nappGitt = true;
        _catches[s.id] = _catchFor(s).copyWith(napp: true);
      }
    });
  }

  // ── the card ────────────────────────────────────────────────────────────

  /// Design `fiske(r)`: play the throw, then advance the deck.
  void _fiske(FiskeCardAnim anim, Future<void> Function() action) {
    if (_lock || _current == null) return;
    _lock = true;
    setState(() {
      _cardAnim = anim;
      _cardSeq += 1;
    });
    _fk3 = Timer(const Duration(milliseconds: 420), () async {
      if (!mounted) return;
      _lock = false;
      await action();
      if (!mounted) return;
      setState(() {
        _idx += 1;
        _phase = FiskePhase.klar;
        _bubbleSeq += 1;
      });
    });
  }

  void _slipp() => _fiske(FiskeCardAnim.kastVenstre, () async {
    final s = _current;
    if (s != null) await a3Try(() => _aegil.dismiss(s.id));
  });

  void _lagre() => _fiske(FiskeCardAnim.kastHoyre, () async {
    final s = _current;
    if (s != null) {
      await a3Try(() => _aegil.add(s.id));
      final storeId = s.storeId;
      if (storeId != null) {
        // The same favourites every Bergen heart writes (ops.customer.favourites).
        final save =
            widget.saveFavourite ??
            (int id) async {
              if (!OpsCustomerApi.networkEnabled) return false;
              return FavouriteStores.instance.set(id, true);
            };
        await a3Try(() => save(storeId));
      }
    }
    _lagret += 1;
    if (mounted) {
      showBergenToast(
        context,
        FiskeCopy.a1_fiske_toast_lagret,
        icon: Icons.favorite_rounded,
      );
    }
  });

  void _kurv() => _fiske(FiskeCardAnim.kastOpp, () async {
    final s = _current;
    if (s != null) {
      await a3Try(() => _aegil.add(s.id));
      final c = _catchFor(s);
      if (s.storeId != null && c.productId != null && mounted) {
        final add = widget.addToCart ?? _cartAdd;
        await add(context, storeId: s.storeId!, productId: c.productId!);
      }
    }
    _kjopt += 1;
  });

  static Future<bool> _cartAdd(
    BuildContext context, {
    required int storeId,
    required int productId,
  }) => BergenCart.add(context, storeId: storeId, productId: productId);

  // ── the prize ───────────────────────────────────────────────────────────

  void _premieSlipp() {
    if (_lock || _premie == null) return;
    _lock = true;
    setState(() {
      _cardAnim = FiskeCardAnim.kastVenstre;
      _cardSeq += 1;
    });
    _fk3 = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _lock = false;
      setState(() {
        _premie = null;
        _phase = FiskePhase.klar;
        _bubbleSeq += 1;
      });
    });
  }

  Future<void> _premieHent() async {
    final id = _premie?.prizeId;
    if (id == null) return;
    final r = await a3Try(() => _points.claim(id));
    if (!mounted) return;
    final ok = r?.claim != null;
    showBergenToast(
      context,
      ok
          ? FiskeCopy.a1_fiske_toast_din(_premie?.prizeName ?? '')
          : (r?.error ?? FiskeCopy.a1_fiske_toast_kunne_ikke),
      icon: Icons.redeem_rounded,
    );
    if (!ok) return;
    setState(() {
      _premie = null;
      _phase = FiskePhase.klar;
      _sagt = FiskeCopy.a1_fiske_snakk_din;
      _bubbleSeq += 1;
    });
  }

  Future<void> _premieSettMaal() async {
    final id = _premie?.prizeId;
    if (id == null || id == _goalPrizeId) return;
    await a3Try(() => _points.setGoal(prizeId: id));
    if (!mounted) return;
    setState(() => _goalPrizeId = id);
    showBergenToast(
      context,
      FiskeCopy.a1_fiske_toast_satt_maal(_premie?.prizeName ?? ''),
      icon: Icons.flag_rounded,
    );
  }

  // ── the deck ────────────────────────────────────────────────────────────

  void _velgAgn(FiskeAgn a) {
    _cancelTimers();
    setState(() {
      _deck = _deck.withAgn(a);
      _idx = 0;
      _premie = null;
      _phase = FiskePhase.klar;
      _bubbleSeq += 1;
    });
  }

  void _reset() {
    _cancelTimers();
    setState(() {
      _idx = 0;
      _lagret = 0;
      _kjopt = 0;
      _kastNr = 0;
      _premie = null;
      _premieAnt = 0;
      _premieSiste = 0;
      _phase = FiskePhase.klar;
      _bubbleSeq += 1;
    });
  }

  void _nappKort(FiskeCatch c) {
    showNappKort(
      context,
      NappOffer(
        id: '${c.suggestion.id}',
        title: c.name,
        storeName: c.storeName ?? '',
        priceOre: (c.priceKr ?? 0) * 100,
        reason: c.suggestion.reason,
        kind: 'rytme',
      ),
      aegil: _aegil,
    );
  }

  // ── view-model (design `fiskeVals`) ─────────────────────────────────────

  bool get _capped =>
      _earn?.capped == true || (_day?.capped == true && _kastNr == 0);
  int get _perCatch => _day?.perCatch ?? 5;

  String _snakk(FiskeCatch? fi) {
    final pr = _premie;
    final erPr = pr != null && _phase == FiskePhase.fangst;
    return switch (_phase) {
      FiskePhase.klar => _sagt ?? FiskeCopy.a1_fiske_snakk_klar,
      FiskePhase.venter => FiskeCopy.a1_fiske_snakk_venter,
      FiskePhase.napp => FiskeCopy.a1_fiske_snakk_napp,
      FiskePhase.mistet => FiskeCopy.a1_fiske_snakk_mistet,
      FiskePhase.fangst =>
        erPr
            ? (pr.prizeId == _goalPrizeId
                  ? FiskeCopy.a1_fiske_snakk_premie_maal(pr.prizeName ?? '')
                  : FiskeCopy.a1_fiske_snakk_premie)
            : FiskeCopy.a1_fiske_snakk_fangst(fi?.name ?? '', fi?.storeName),
    };
  }

  String _hint() {
    final erPr = _premie != null && _phase == FiskePhase.fangst;
    return switch (_phase) {
      FiskePhase.napp => FiskeCopy.a1_fiske_hint_napp,
      FiskePhase.fangst =>
        erPr ? FiskeCopy.a1_fiske_hint_premie : FiskeCopy.a1_fiske_hint_fangst,
      FiskePhase.venter => FiskeCopy.a1_fiske_hint_venter,
      _ =>
        _capped
            ? FiskeCopy.a1_fiske_hint_capped(_day?.max ?? _earn?.max ?? 5)
            : FiskeCopy.a1_fiske_hint_klar(_perCatch),
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF3D6B7A),
    body: FiskeScope.fit(child: Builder(builder: _body)),
  );

  Widget _body(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;
    final look =
        widget.weather ?? BergenWeatherLook.forHour(DateTime.now().hour);

    final fi = _current;
    final catchNow = fi == null ? null : _catchFor(fi);
    final aktiv = !_loading && fi != null;
    final ferdig = !_loading && fi == null;
    final erPr = _premie != null && _phase == FiskePhase.fangst;
    final visFangst = _phase == FiskePhase.fangst && fi != null && !erPr;
    final deckLen = _deck.cards.length;
    final nr = min(
      _idx + _premieAnt + (_premie != null ? 0 : 1),
      max(deckLen, 1) + _premieAnt,
    );
    final av = deckLen + _premieAnt;

    final ripples = _ripples;

    /// A design-px widget [w] × [h], drawn at the frame's scale.
    Widget d(double w, double h, Widget child) => SizedBox(
      width: w * s,
      height: h * s,
      child: FittedBox(fit: BoxFit.fill, child: SizedBox(width: w, height: h, child: child)),
    );

    final kontroller = switch (_phase) {
      FiskePhase.klar || FiskePhase.mistet => [
        FiskeLKastUt(
          label: _phase == FiskePhase.mistet ? FiskeCopy.a1_fiske_kast_igjen : FiskeCopy.a1_fiske_kast,
          onTap: _kast,
        ),
      ],
      FiskePhase.venter => [const FiskeLVenter()],
      FiskePhase.napp => [FiskeLDraInn(onTap: _dra)],
      FiskePhase.fangst =>
        erPr
            ? [
                FiskeLRund(key: const Key('a1_fiske_premie_slipp'), svg: FiskeLRund.kryss, label: FiskeCopy.a1_fiske_slipp, onTap: _premieSlipp),
                const SizedBox(width: 16),
                FiskeLRund(
                  key: const Key('a1_fiske_hent'),
                  svg: FiskeLRund.hake,
                  label: FiskeCopy.a1_fiske_hent,
                  orange: true,
                  ikon: 26,
                  onTap: _premie!.affordable ? _premieHent : () {},
                ),
                const SizedBox(width: 16),
                FiskeLRund(
                  key: const Key('a1_fiske_sett_maal'),
                  svg: FiskeLRund.blink,
                  label: _premie!.prizeId == _goalPrizeId ? FiskeCopy.a1_fiske_er_maal : FiskeCopy.a1_fiske_sett_maal,
                  opacity: _premie!.prizeId == _goalPrizeId ? .55 : 1,
                  onTap: _premieSettMaal,
                ),
              ]
            : [
                FiskeLRund(key: const Key('a1_fiske_slipp'), svg: FiskeLRund.kryss, label: FiskeCopy.a1_fiske_slipp, onTap: _slipp),
                const SizedBox(width: 16),
                FiskeLRund(key: const Key('a1_fiske_legg'), svg: FiskeLRund.pilOpp, label: FiskeCopy.a1_fiske_legg, orange: true, ikon: 26, onTap: _kurv),
                const SizedBox(width: 16),
                FiskeLRund(key: const Key('a1_fiske_lagre'), svg: FiskeLRund.hjerte, label: FiskeCopy.a1_fiske_lagre, onTap: _lagre),
              ],
    };

    return FiskeSkjermInn(
      child: Stack(
        key: const Key('a1_fiske_screen'),
        clipBehavior: Clip.none,
        children: [
          FiskeBakgrunn(look: look, ripples: ripples),
          const FiskePier(),
          // The prototype shows no Ægil pose while the prize card is up
          // (`fiskeAegRear` / `fiskeNapp` / `fiskeFangst` are all false).
          if (!erPr) FiskeAegil(phase: _phase),
          Positioned.fill(child: FiskeStang(phase: _phase, ripples: ripples)),
          if (_phase == FiskePhase.venter || _phase == FiskePhase.napp || _phase == FiskePhase.fangst)
            const Positioned(left: 0, top: 0, child: SizedBox.shrink(key: Key('a1_fiske_ute'))),
          if (_phase == FiskePhase.fangst && !erPr) const FiskeSprut(),
          if (visFangst)
            Positioned(
              top: f.y(322),
              left: (f.width - 250 * s) / 2,
              child: FiskeCardMotion(
                anim: _cardAnim,
                seq: _cardSeq,
                child: Transform.scale(
                  scale: s,
                  alignment: Alignment.topLeft,
                  child: FiskeLFangstKort(
                    item: catchNow!,
                    earned: _earn?.earned ?? 0,
                    onNappTap: () => _nappKort(catchNow),
                  ),
                ),
              ),
            ),
          if (erPr)
            Positioned(
              top: f.y(322),
              left: (f.width - 250 * s) / 2,
              child: FiskeCardMotion(
                anim: _cardAnim,
                seq: _cardSeq,
                child: FiskePremieCard(
                  pick: _premie!,
                  balance: _balance,
                  isGoal: _premie!.prizeId == _goalPrizeId,
                ),
              ),
            ),
          if (ferdig)
            Positioned(
              top: f.y(224),
              left: f.x(24),
              right: f.x(24),
              child: FiskeFerdigCard(
                lagret: _lagret,
                kjopt: _kjopt,
                onSeLagret: () => BergenRoutes.push(context, '/bergen/meg/favoritter'),
                onIgjen: _reset,
              ),
            ),
          FiskeBubble(text: _snakk(catchNow), seq: _bubbleSeq),
          Positioned(
            left: 0,
            top: f.y(572),
            child: d(f.width / s, 80, FiskeLAgnRail(selected: _deck.agn, count: _deck.count, onSelect: _velgAgn)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: f.safeTop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FiskeHeader(kast: nr, av: av, lagret: _lagret, onBack: () => Navigator.of(context).maybePop()),
                const FiskeTitle(),
              ],
            ),
          ),
          if (aktiv)
            Positioned(
              left: 0,
              bottom: f.b(104),
              child: d(
                f.width / s,
                84,
                OverflowBox(
                  key: const Key('a1_fiske_kontroller'),
                  alignment: Alignment.center,
                  minWidth: 0,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  maxWidth: double.infinity,
                  child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: kontroller),
                ),
              ),
            ),
          Positioned(left: 0, right: 0, bottom: f.b(80), child: FiskeHint(text: _hint())),
          // The nav, no tab lit (`skjerm:'fiske'` is no tab).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BergenBottomNav(
              index: -1,
              merkMeg: false,
              onTab: _tilFane,
              cartCount: ValueNotifier<int>(prefGetInt(prefCartCount)),
              onSearch: (_) => _tilSok(),
              onAegil: (_) => BergenRoutes.push(context, '/bergen/aegil'),
              showHint: false,
            ),
          ),
        ],
      ),
    );
  }

  /// The nav's tabs: back to the shell on that tab.
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
}
