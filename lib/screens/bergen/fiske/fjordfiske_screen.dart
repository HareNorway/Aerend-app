import 'dart:async';
import 'dart:math';

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
import '../../../theme/bergen_tokens.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../deliveryService/storeDetail/store_detail_repo.dart';
import '../kit/bergen_kit.dart';
import '../meg/a3_services.dart';
import '../poeng/napp_entry.dart';
import 'fiske_cards.dart';
import 'fiske_controls.dart';
import 'fiske_copy.dart';
import 'fiske_frame.dart';
import 'fiske_game.dart';
import 'fiske_line.dart';
import 'fiske_scene.dart';
import 'fiske_sjo.dart';

/// Fjordfiske — `/bergen/fjordfiske` (design `<sc-if value="{{ erFiske }}">`,
/// `Ærend Kunde Bergen.dc.html` L6435–6641; logic `fiskeKast` L7762,
/// `fiskeDra` L7775, `fiskePremieVelg` L7748, `fiskeDekk` L7745).
///
/// Ægil and the customer fish in Vågen: **Kast ut** → the line is out →
/// **NAPP!** → **DRA INN!** → the catch card (a suggestion from
/// `agent/suggestions?context=fiske`) with Slipp / Legg i kurven / Lagre.
/// From cast `fromCast` on, every `everyN`-th cast (at most `max` a session)
/// is a **Premiefangst** from `points/prizes/pick` with Hent / Sett som mål /
/// Slipp. Every reel earns through `points/me/earn?rule=dagens_napp`, capped
/// per day by the server; the cap is read before the first cast from
/// `ops.customer.fiske` and shown honestly (the hint line) when it is hit.
/// The screen opens straight from the Utforsk segment (design `segFiske`)
/// and from Hjem; the prototype has no landing card in the flow.
///
/// ## Design ledger — every property, design → Flutter
///
/// Frame: 390-wide design px × `context.bs`; absolute `top:` values are
/// `FiskeFrame.y()` = status bar + px·s (the design has no status bar; its
/// y = 0 is the first row under ours). `bottom:` values add the home bar.
///
/// **Fjordfiske (root)** — `background:#3D6B7A` → Scaffold colour.
/// `skjermInn .34s cubic-bezier(.2,.9,.3,1)` → [FiskeSkjermInn] (opacity
/// 0→1, translateY 10→0, scale .985→1). Sky `height:230px; {{ vaerHimmel }}`
/// → [FiskeSky] with `BergenWeatherLook.forHour` (the prototype's weather
/// prop; the app has no weather feed — same rule as Hjem). Scene `svg
/// 390×140 @top:90`, `k-scene2` at `translate(0 4) scale(1 .6333)`, lights
/// at `visGlod` (blurred copy .55 + sharp) → [FiskeMountains]: the same two
/// SVG assets Hjem uses, clipped at 140. Mist `top:90;height:150;
/// {{ vaerDis }}` → [FiskeMist]. *Deviation:* `vaerHusFilter`
/// (`saturate()/brightness()`) is a darkening overlay (`houseDim`), as on
/// Hjem.
///
/// **Bryggen · fiske** — the `bryggen` loop in a `390×76 @top:156` SVG:
/// eleven gables (`F`, `W`, `T`, `R` arrays), `fbrg-vegg` / `fbrg-vegg-v` /
/// `fbrg-tak` / `fbrg-side` / `fbrg-nabo` gradients, planks `.7px
/// rgba(44,33,20,.5)`, windows `4.5×6 rx1 #FFF3D0→#FFCE7A→#E9A24A` with the
/// `fbrg-glow` blur, door `8×11 #2C2114`, lamp `r1.3 #FFE2A8` + `r3.5
/// #FFCE7A .35` glow, quay `61..67 #6A5A44→#4A3C2A→#241A10`, ticks every
/// 26px, five bollards `3.2×9 #3A3128`, two lights `r1.6 #F26D3D` →
/// [FiskeBryggen] = [BergenHousesPainter] (agil-1's Hjem painter of the
/// identical template), `dim: 0` because this block carries no weather
/// filter in the design.
///
/// **Sjø · fiske** — `top:223 → bottom; overflow:hidden` → [FiskeSjo].
/// Base `#3D6B7A` (kveld) / `#9FC3CC` (dag) / `#6F8790` (regn) +
/// `hav-dybde(-lys/-regn)` flipped at .45 / .4 / .45 → the two fills.
/// Textures: `sjoBake()` (patterns `lf`/`yf` 7px period, `feTurbulence
/// 0.016 0.08 ×2` + `feDisplacementMap 22`, mask `mu` 70→100 %) →
/// [FiskeSjoBake] draws the tile once to a `ui.Image` (value noise at the
/// same frequencies/octaves/amplitude; different seeds → same character,
/// not the same pixels). Caustics `ka` (`turbulence 0.018 0.03`, `2.4a−1.05`,
/// blur 1.4) → [FiskeSjoBake.ka], blurred once while baking. Perspective
/// box `left:-40%;right:-40%;height:150%; perspective(560px) rotateX(-24deg);
/// origin 50% 0` → `Transform(alignment: topCenter, m34 = −1/560s,
/// rotateX(−24°))`. Layers (`left:-30;top:-14;+60/+28`, tiles `100% 240px`):
/// ka `sjoX 19s −8s / sjoY 13s −3s` at `.18/.2/.12`; hero `15s / 9s −6s`;
/// hero mirrored `23s −17s alt-rev / 16s −11s alt-rev, .42, scaleX(−1)`;
/// hero low `17s −5s / 11s −2s, .55, mask 35→75 %, tile 380 @ 0 60%` — all
/// as `ImageShader` translations in [_SjoLayersPainter]; `sjoX` ±18 px,
/// `sjoY` ±8 px, `ease-in-out alternate`. Glint `radial 42% 38% white .2→0
/// @72%; box −10%/−30%; sjoGlint 33s −12s` (−12%,−6% s1 .55 → 6%,4% s1.15
/// 1 → 14%,−2% s1.05 .6) → same painter. Haze `110px rgba(190,214,222)
/// .32→.12@45%→0`, bottom vignette `radial 60% 70% @50% 100% rgba(3,14,20)
/// .42→0@75%; −20%/−10%/55%`, houses' reflection `60px .28 scaleY(−1)
/// hav-speil` → [BergenHouseReflectionPainter] + blur 1.4 (*deviation:* the
/// displacement is a blur), top shade `28px rgba(8,24,32,.3)→0`, vignette
/// `radial 110% 90% @50% 30% 0@50%→rgba(3,14,20,.5)`. *Deviation:* no
/// `sjoDag/Kveld/Regn` prop — the mode follows the weather look (sol → dag,
/// regn → regn, else kveld).
///
/// **Pier** (unlabelled, `right:0;top:296/310/316`, posts `5×40 @290`,
/// reflection `top:318 h40 .35`, Ægil shadow `74×9 blur 3`) → [FiskePier]
/// with every colour and offset verbatim.
///
/// **Ægil** — `right:22;top:222;80×80; aegBob 3.6s / rist .5s / popp .6s
/// cubic-bezier(.34,1.56,.64,1) / aegBob` per phase → [FiskeAegil].
/// *Deviation:* `filter:drop-shadow(0 8px 10px rgba(8,24,32,.45))` is not
/// on the animated image (the prototype's own note); the pier's blurred
/// ellipse is the shadow.
///
/// **Line / float / effects** — line out `M296 250 Q250 290 152 420, 1.3px
/// white .8, snoreKast .7s ease-out (dashoffset 400→0)`; line in `M296 250
/// Q300 268 298 286` + hook `r3 #F26D3D / 1px white` → [FiskeLine].
/// Ripples `112,424 80×26 1.5px white .55, rippel 2.6s (+1.3s)` →
/// [FiskeRipples]. Float `143,412 18×26`, stick `2×10 @8,−8`, body
/// `50%/40% 40% 60% 60%`, gradient `#F9A273 → #F26D3D 48% → #FFF 50% →
/// #EAF2F4`, `inset 0 1px 0 rgba(255,255,255,.7), 0 4px 6px −3px
/// rgba(8,24,32,.6)`, `duppFlyt 2.8s` / `duppNapp .45s` → [FiskeDupp].
/// Bite rings `96,420 112×34 2.5px #F26D3D / white +.45s, nappRing .9s` →
/// [FiskeNappRings]. Catch splash `sprut .8s` + three `dropp` drops →
/// [FiskeSprut].
///
/// **Ægil snakker** — `left:16;top:236;max-width:216; radius 18 18 18 6;
/// padding 8 12 9; rgba(15,31,43,.62) blur 16; border rgba(255,255,255,.28);
/// inset 0 1px 0 .25; 0 12px 22px −12px rgba(4,18,26,.9); bobleInn .4s
/// cubic-bezier(.3,1.3,.5,1)`; kicker `9.5px 800 .1em #7FF0CB` with the
/// `6px` dot `0 0 6px rgba(127,240,203,.9)`; text `12.5px 700 lh 1.4` →
/// [FiskeBubble] with [BergenCssShadow] under the glass.
///
/// **Header / title** — back `40×40 r14 rgba(15,31,43,.45) blur 18 border
/// .3 inset .25, 0 8px 16px −8px rgba(15,31,43,.6), scale(.92)`; status pill
/// `padding 7 12, 11.5px 800, dot 7px #F2C14E lyktPuls 3s`; title `Plus
/// Jakarta 28px 800 −.03em, text-shadow 0 2px 12px rgba(8,24,32,.45), vekt
/// .9s`; sub `12px 700 rgba(255,255,255,.85), 0 1px 8px rgba(8,24,32,.5)` →
/// [FiskeHeader], [FiskeTitle]. *Deviation:* `vekt` animates
/// `font-variation-settings 'wght' 500→800`; the GoogleFonts static face
/// plays only the opacity .6→1 half.
///
/// **Fangst** — `top:322; 250 wide; r28; #FFF→#F6F2E9; 1px #FFF; inset 0
/// 2px 0 #FFF, 0 0 0 1px rgba(255,255,255,.5), 0 30px 50px −20px
/// rgba(4,18,26,.85)`; hero `150px {{ fTint }}` + sheen `radial 120% 90% @30%
/// 10% white .6→0@62%` + foot `40% rgba(60,35,10,0→.18)`; art per `ik`
/// (`ico-fisk 150×100 @49,36`, `ico-mat 110×100 @69,36`, `ico-mote 110×112
/// @69,30`, `ico-interior 100×110 @74,30`, `ico-gaver 106×112 @71,30`) `bob
/// 4s`; coin `+5 poeng 10px 800 #7FF0CB on #0F1F2B, 0 0 0 1.5px #7FF0CB,
/// myntOpp 1.4s .3s both`; `Napp!` pill `#5CE0B8→#9C7BE8 10.5px 800
/// #0F1F2B, popp .6s` + `shock.png 58 @6,6 popp .6s .15s`; district badge
/// `9.5px 800 #23201D on rgba(255,255,255,.85)`; name `PJS 16px 800 −.015em
/// lh1.2 #23201D`, store `11.5px 600 #57534B`, price `PJS 19px 800
/// #B9441A`, eta `10.5px 700 #6E6862` → [FiskeFangstCard]. Card motion
/// `fangstOpp .75s cubic-bezier(.2,1.1,.4,1)` / `kastVenstre|Hoyre|Opp .42s
/// ease-in` → [FiskeCardMotion]. *Deviations:* the art's `drop-shadow(0
/// 12px 14px rgba(20,25,30,.45))` is off the bobbing layer; `myntOpp`'s
/// `translate(-50%, …)` (a centring offset on a `left:10px` pill, which
/// clips half the pill in the prototype) keeps only the vertical track; the
/// suggestion payload has no `bydel` / `eta` / `pris` — the district falls
/// back to «Bergen», the eta to «Leveres i kveld», the store and price come
/// from `ops_butikk_api.store()` (the store name and, when the
/// `store_product_id` is on its menu, the price); the Forundringspose /
/// burger art of the design deck has no category here.
///
/// **Premiefangst** — same shell; `Fra hylla di` pill `#0F1F2B 10px 800
/// white`; band pill `rgba(255,255,255,.9) 9.5px 800` with the 16px metal
/// disc (`nivMetall`: Bronse / Sølv / Gull / Platina radial by `tier_band`);
/// art centred (`translate(-50%,-46%)`, `pIw×pIh`, `bob 4s`); name `PJS 16px`,
/// points `12.5px 800 #B9441A` "{pris} poeng · du har {har}", how `11px 600
/// #57534B lh1.4` → [FiskePremieCard]. *Deviations:* the tint is per band
/// (the design tints per prize); the art is by prize `type`; the band name
/// is the app's `tier_name`.
///
/// **Ferdig** — `top:224; 24/24; r28; padding 18; rgba(255,255,255,.88) blur
/// 30; 1px #FFF; inset 0 2px 0 #FFF, 0 30px 50px −20px rgba(10,30,40,.7);
/// kortInn .5s`; `noresto.png 88 r24 aegBob 3.4s`; title `PJS 18px 800
/// −.02em`; line `12px 600 lh1.45 #57534B`; primary `46 r999 #1E4F5C 13.5px
/// 800, 0 12px 22px −10px rgba(30,79,92,.7)`; secondary `42 r999
/// rgba(30,79,92,.08) 12.5px 800 #1E4F5C` → [FiskeFerdigCard]. *Deviation:*
/// no backdrop blur behind the opaque-ish card.
///
/// **Fiske-kontroller** — `bottom:104; height:84; gap:16`. Kast ut `56 h,
/// 0 26 0 20, gradient #F9A273/#F26D3D 56%/#DD5A25, 0 0 0 1px white .5 ·
/// 0 1.5px 0 #C4491A · 0 4px 0 rgba(120,45,15,.42) · 0 16px 24px −10px
/// rgba(200,70,25,.9), PJS 16px 800 −.01em, rod icon 22/2.3, active
/// translateY(3px), bobleInn .4s` → [FiskeKastUt] (*not* [BergenCta3d]: the
/// kit face is `radius 16` with the `#F58A55→#E95C2C` gradient and a 4px
/// edge; the design's pill is a different shape and shadow stack). Venter
/// pill `52 h, 0 20, rgba(15,31,43,.55) blur 16, 13.5px 800, dots 6px
/// #F2C14E glod 1.2s/.3/.6, bobleInn .3s` → [FiskeVenterPill]. DRA INN!
/// `84 circle, 2px white, nappPuls .55s, arrow 22/3, PJS 13px 800, tidStrek
/// 1.7s bar 4px −14` → [FiskeDraInn]. Slipp / Lagre `54 glass rgba(15,31,43,
/// .55) blur 20 border .35 inset .3, 0 14px 22px −10px rgba(4,18,26,.7), X
/// 20/2.6, heart 20 #F26D3D/white 1.6, label 10px 800 white .85 shadow 0
/// 1px 6px rgba(8,24,32,.6), scale(.9)` → [FiskeGlassAction]. Legg i kurven
/// / Hent `68 orange, 2px white .7, inset 0 2px 0 white .4 · 0 1.5px 0
/// #C4491A · 0 18px 28px −10px rgba(233,92,44,.9), arrow 26/2.8 · check
/// 26/2.8, scale(.92)` → [FiskeOrangeAction]. Sett som mål `target 20/2.4,
/// opacity .55 when it already is the goal`.
///
/// **Agn** — `top:582; 0 12; gap 6; 58-wide; ring 42 padding 2.5 (on:
/// linear-gradient(150deg,#F26D3D,#F2C14E 45%,#1E4F5C) · 0 10px 18px −8px
/// rgba(242,109,61,.75); off: rgba(255,255,255,.35) · 0 6px 12px −8px
/// rgba(10,30,40,.5)); disc {{ c.bg }} 2px white .9, inset 0 1.5px 0 white
/// .6, inset 0 −7px 12px rgba(10,30,40,.2), sheen radial 120% 90% @30% 12%;
/// art ae-mark 26×17 #1E4F5C / ico-fisk 34×26 / pi-bolle 30×28 / 26×28;
/// badge 19px #FBFAF6 2px (on #F26D3D) 9.5px 800; label 9.5px 800 (on
/// white / off white .72) shadow 0 1px 4px rgba(10,30,40,.5)` →
/// [FiskeAgnRail]. *Deviation:* the art's `drop-shadow(0 2px 3px …)` is
/// omitted; the rail top is clamped above the controls on short screens.
///
/// **Hint** — `bottom:80; 10.5px 700 white .85; 0 1px 6px rgba(8,24,32,.6)`
/// → [FiskeHint]; when the day is capped the klar hint is the honest cap
/// line.
///
/// **Napp-kort** (design L2115) — the `Napp!` badge on the day's first catch
/// opens agil-3's `showNappKort` seam with the catch as a [NappOffer].
///
/// ## Device pass — iPhone 17 Pro Max, iOS 26.5 simulator, 2026-09-26
///
/// `integration_test/fiske_screens_test.dart` drove idle → cast → bite →
/// catch → prize with the test fakes next to the prototype pinned to the same
/// states (headless Chrome, `vaer` = regn). Still off after the pass:
///
/// * **Frame fit.** The prototype is a 390×844 phone with no status bar; the
///   app fits that frame into the safe area with one scale (Pro Max: 1.022),
///   so the whole composition sits 59 pt lower and the water below the
///   controls is a little taller. The prototype keeps its bottom nav under
///   the game; the app is full-screen (decision), so the controls sit
///   `bottom:104` from the home bar, not from the nav.
/// * **Water.** The baked value-noise wobble reads a touch denser than the
///   prototype's `feTurbulence` displacement, and the caustics are fainter;
///   the drift, layer count, opacities and the perspective match.
/// * **Cards.** The district badge reads «Bergen» and the eta is the store's
///   delivery minutes (no `bydel`/`eta` in the suggestion payload); the prize
///   card shows the tier pill only when `pick()` carries `tier_name`. The
///   `Napp!` pill and the `+5 poeng` coin stack at the same corner, as in the
///   design, until the coin fades (1.7 s).
/// * **Type.** `vekt` plays only its opacity half (static font faces).
/// * **Weather.** The app follows the time of day (Hjem's rule); the
///   prototype's default prop is regn — the two only match in the afternoon.
///
/// Timings (design `fiskeKast`): venter → napp after `1500 + rand·1600` ms;
/// napp → mistet after 1700 ms; mistet → klar after 2200 ms; card dismiss
/// 420 ms. Reduced motion: every clock stops (`OnbLoopClock`) or jumps to
/// its end (`OnbTimeline`); the game timers are logic, not motion, and are
/// cancelled in `dispose`.
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
  int _castSeq = 0;
  int _bubbleSeq = 0;
  bool _lock = false;

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
      storeName: store?.name,
      priceKr: item?.price.round(),
      productId: s.storeProductId,
      bydel: null,
      eta: store?.deliveryMinutes == null
          ? null
          : '${store!.deliveryMinutes} min',
    );
    if (store != null || s.storeId == null) _catches[s.id] = built;
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
      _castSeq += 1;
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
        final save =
            widget.saveFavourite ??
            (int id) async {
              if (!OpsCustomerApi.networkEnabled) return false;
              await StoreDetailRepo().callAddFavourite(id, 1);
              return true;
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
    final sea = look.isSun
        ? BergenSea.day
        : look.isRain
        ? BergenSea.rain
        : BergenSea.evening;

    final fi = _current;
    final catchNow = fi == null ? null : _catchFor(fi);
    final aktiv = !_loading && fi != null;
    final ferdig = !_loading && fi == null;
    final ute =
        _phase == FiskePhase.venter ||
        _phase == FiskePhase.napp ||
        _phase == FiskePhase.fangst;
    final erPr = _premie != null && _phase == FiskePhase.fangst;
    final visFangst = _phase == FiskePhase.fangst && fi != null && !erPr;
    final deckLen = _deck.cards.length;
    final nr = min(
      _idx + _premieAnt + (_premie != null ? 0 : 1),
      max(deckLen, 1) + _premieAnt,
    );
    final av = deckLen + _premieAnt;

    final railTop = f.y(582);

    return FiskeSkjermInn(
      child: Stack(
        key: const Key('a1_fiske_screen'),
        clipBehavior: Clip.none,
        children: [
          FiskeSky(look: look),
          FiskeMountains(look: look),
          FiskeMist(look: look),
          FiskeSjo(mode: sea),
          const FiskeBryggen(),
          const FiskePier(),
          if (ute) ...[
            const FiskeRipples(),
            if (_phase == FiskePhase.napp) const FiskeNappRings(),
            if (_phase == FiskePhase.fangst) const FiskeSprut(),
          ],
          FiskeLine(out: ute, castSeq: _castSeq),
          if (ute) FiskeDupp(bite: _phase == FiskePhase.napp),
          // The prototype shows no Ægil pose while the prize card is up
          // (`fiskeAegRear` / `fiskeNapp` / `fiskeFangst` are all false).
          if (!erPr) FiskeAegil(phase: _phase),
          if (visFangst)
            Positioned(
              top: f.y(322),
              left: (f.width - 250 * s) / 2,
              child: FiskeCardMotion(
                anim: _cardAnim,
                seq: _cardSeq,
                child: FiskeFangstCard(
                  item: catchNow!,
                  earned: _earn?.earned ?? 0,
                  onNappTap: () => _nappKort(catchNow),
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
                onSeLagret: () =>
                    BergenRoutes.push(context, '/bergen/meg/favoritter'),
                onIgjen: _reset,
              ),
            ),
          FiskeBubble(text: _snakk(catchNow), seq: _bubbleSeq),
          Positioned(
            left: 0,
            right: 0,
            top: railTop,
            child: FiskeAgnRail(
              selected: _deck.agn,
              count: _deck.count,
              onSelect: _velgAgn,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: f.safeTop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FiskeHeader(
                  kast: nr,
                  av: av,
                  lagret: _lagret,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const FiskeTitle(),
              ],
            ),
          ),
          if (aktiv)
            Positioned(
              left: 0,
              right: 0,
              bottom: f.b(104),
              height: 84 * s,
              // The design's 84px box lets a label hang below it; the
              // OverflowBox does the same instead of clipping.
              child: OverflowBox(
                alignment: Alignment.center,
                minWidth: 0,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Row(
                  key: const Key('a1_fiske_kontroller'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: switch (_phase) {
                    FiskePhase.klar || FiskePhase.mistet => [
                      FiskeKastUt(
                        label: _phase == FiskePhase.mistet
                            ? FiskeCopy.a1_fiske_kast_igjen
                            : FiskeCopy.a1_fiske_kast,
                        onTap: _kast,
                      ),
                    ],
                    FiskePhase.venter => [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: f.width - 32 * s),
                        child: const FiskeVenterPill(),
                      ),
                    ],
                    FiskePhase.napp => [FiskeDraInn(onTap: _dra)],
                    FiskePhase.fangst =>
                      erPr
                          ? [
                              FiskeGlassAction(
                                key: const Key('a1_fiske_premie_slipp'),
                                label: FiskeCopy.a1_fiske_slipp,
                                icon: FiskeIcons.cross(context),
                                onTap: _premieSlipp,
                              ),
                              SizedBox(width: 16 * s),
                              FiskeOrangeAction(
                                key: const Key('a1_fiske_hent'),
                                label: FiskeCopy.a1_fiske_hent,
                                icon: FiskeIcons.check(context),
                                onTap: _premie!.affordable ? _premieHent : null,
                              ),
                              SizedBox(width: 16 * s),
                              FiskeGlassAction(
                                key: const Key('a1_fiske_sett_maal'),
                                label: _premie!.prizeId == _goalPrizeId
                                    ? FiskeCopy.a1_fiske_er_maal
                                    : FiskeCopy.a1_fiske_sett_maal,
                                icon: FiskeIcons.target(context),
                                opacity: _premie!.prizeId == _goalPrizeId
                                    ? .55
                                    : 1,
                                onTap: _premieSettMaal,
                              ),
                            ]
                          : [
                              FiskeGlassAction(
                                key: const Key('a1_fiske_slipp'),
                                label: FiskeCopy.a1_fiske_slipp,
                                icon: FiskeIcons.cross(context),
                                onTap: _slipp,
                              ),
                              SizedBox(width: 16 * s),
                              FiskeOrangeAction(
                                key: const Key('a1_fiske_legg'),
                                label: FiskeCopy.a1_fiske_legg,
                                icon: FiskeIcons.up(context),
                                onTap: _kurv,
                              ),
                              SizedBox(width: 16 * s),
                              FiskeGlassAction(
                                key: const Key('a1_fiske_lagre'),
                                label: FiskeCopy.a1_fiske_lagre,
                                icon: FiskeIcons.heart(context),
                                onTap: _lagre,
                              ),
                            ],
                  },
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: f.b(80),
            child: FiskeHint(text: _hint()),
          ),
        ],
      ),
    );
  }
}
