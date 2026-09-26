import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../deliveryService/checkout/checkout.dart';
import '../../deliveryService/checkout/checkout_dl.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_motion.dart';
import 'kasse_copy.dart';
import 'kasse_sheets.dart';
import 'kurv_betal.dart';
import 'kurv_parts.dart';
import 'kurv_seilas.dart';

/// `kurv` (L4973–5242 in `Ærend Kunde Bergen.dc.html`) at `/bergen/kurv`,
/// tab 2 of the shell — rebuilt 1:1 on 2026-09-26.
///
/// Seilas · kassen (the rowing header, [KurvSeilas]), the teal panel with
/// Levering / Henting ([KurvModus]), the lines ([KurvLinje]) and «Legg til noe
/// mer», the Endre rows (address / time / payment, and «Beskjed til budet»
/// once Flere valg is open), Flere valg ([KurvFlere]) revealing the tips card
/// (delivery) or the «Beskjed til butikken» card (pickup) on `stigOpp`, the
/// SAMMENDRAG receipt with the dotted rows, the door note with Tolk (agil-3's
/// C4 — pushes `kAegilRoute` with `intent=door`), the share and «Kode ved
/// levering» toggles, the perforation and the teal Å BETALE NÅ box, the
/// lantern footer, and «Dra for å betale» ([KurvBetal]) on the existing
/// Vipps flow. The empty cart is Ægil pushing the trolley ([KurvTom]).
///
/// ## Design ledger — every property, design → Flutter
///
/// **Root** — `radial-gradient(80% 50% at 14% 0%, white .22 → 0 60%)` over
/// `180deg #2A6272 → #1E4F5C 42% → #173E48`; `skjermInn .34s
/// cubic-bezier(.2,.9,.3,1)` → [BergenOnce] on the whole screen.
///
/// **Seilas · kassen** — header `height 104; padding 26 16 0`; the 170×104 sea
/// box at the right: course `M-20 70 C40 56 90 82 150 66` dashed `5 7` white
/// .35 1.4px; `onbRing 9s 2s` ring 150×44 at `left:50%;top:66`; quay
/// `right:14;top:22;54×70` — deck `54×12 @36 r5 0 0 5 #8A6238→#5E4024 · 0 6px
/// 10px -6px rgba(3,16,24,.8)`, posts `4×12 #4A3018 @46 right 10/40`, logo tile
/// `38 r12 white · 0 0 0 2px white .8 · 0 8px 14px -8px rgba(3,16,24,.9)` with
/// two `damp 2.4s` bubbles (their `transform` uses an undefined `--dx`, so the
/// effective keyframe is the opacity fade only), «Bryggen» `8px 800 .04em
/// white .8`; boat `left:40;top:30` on `roInn 1.3s .1s cubic-bezier(.3,.9,.3,1)`
/// (`translateX −120 → 0`, opacity 1 at 20 %) — `roAvgang .75s
/// cubic-bezier(.4,0,.8,.4)` on pay (`+130px, scale .86, opacity 0`); 64×44 on
/// `roVugg 2.2s` (ty 0/−2/0, rot −1.5/1.5/−1.5); Ægil `front.png 36 @14,2`;
/// oars `aareA −28°→22°` / `aareB 28°→−22°` about (14,27)/(50,27), hull
/// `#6B4A2A / #8C6338 / #A5763D`, gunwale `#F2C14E 1.4`; wake `22×4 @−6,38
/// white .55 roKjolvann 2.2s` (tx 0→−22, scaleX .6→1.4, op .5→0); shadow
/// `44×6 radial white .45 sjoSkygge 2.2s`. Back `38 r14 glass 180deg white
/// .16→.07 · border .26 · inset 0 1.5px 0 .32 · 0 10px 18px -10px
/// rgba(4,18,26,.8) · scale(.92)`; title `PJS 26px 800 −.03em lh1`; sub `10.5px
/// 700 white .7` with the `6px #5CE0B8` dot glowing 8px → [KurvSeilas].
/// *Deviations:* the Ægil `drop-shadow(0 2px 3px)` and the boat's
/// `drop-shadow(0 6px 6px)` are off the moving layers; the store logo is the
/// cart store's logo from `OpsButikkApi.store` (the prototype's is the seed
/// store), with the store's initial when there is none.
///
/// **Panel** — `top:98; r28 28 0 0; 180deg #22586A → #1B4854 140px; inset 0
/// 1.5px 0 white .28; inset 0 0 0 1px white .14; 0 −12px 18px −10px
/// rgba(4,18,26,.6); 0 −34px 52px −26px rgba(4,18,26,.7); padding 10 16 290`.
///
/// **Levering / Henting** — `#EEE9DF` track `padding 4; inset 0 1.5px 3px
/// rgba(35,32,29,.14); inset 0 −1.5px 0 white .9; 0 1px 0 white .7`; thumb
/// `calc(50% − 6.5px)` `165deg #2A6272→#1E4F5C · inset .28 · 0 2px 0
/// rgba(11,38,45,.85) · 0 7px 11px −5px rgba(15,45,55,.7)`, `translateX .5s
/// cubic-bezier(.3,1.25,.4,1)`; labels `12.5px 800 −.01em` white / `#55504A`
/// with the truck / bag icons `15 stroke 2`; pressed `translateY(1.5px)` →
/// [KurvModus].
///
/// **Lines** — card `mt 12; r22; padding 4 12; glass; 0 18px 30px −18px`;
/// row `gap 11; padding 10 0; border-bottom white .12`; tile `48 r16 {{tint}}
/// · inset 0 2px 0 white .7 · inset 0 −9px 15px rgba(60,35,10,.2) · 0 0 0 1px
/// white .6 · 0 2px 0 rgba(190,170,140,.6) · 0 8px 13px −7px rgba(60,35,10,.55)`
/// with the radial sheen; name `13px 800 white`, «n stk. · pris kr per stk.»
/// `10.5px 700 white .62`; stepper `rgba(0,0,0,.26) · inset 0 2px 5px
/// rgba(0,0,0,.45) · inset 0 −1px 0 white .14 · padding 3 · gap 3`, buttons
/// `36 · 180deg #FFFFFF→#F3EFE6 · 0 1.5px 0 #D9D2C4 · 0 2.5px 0 rgba(90,74,48,.3)
/// · 0 5px 7px −4px rgba(35,32,29,.5)`, glyphs `11 stroke 3.2 #23201D`,
/// count `12.5px 800 min-width 18`; sum `PJS 14px 800 −.02em` + «kr» `10px
/// 800 white .5`; «Legg til noe mer» `12px 800 #5CE0B8` with the plus `13
/// stroke 2.6`, «Glemte du drikke?» `10.5px 700 white .5` → [KurvLinje],
/// [KurvLeggMer]. *Deviation:* the tile shows the product image over the
/// design's category gradient; the design's category art (`#ico-*`) needs a
/// category the cart line does not carry.
///
/// **Empty** — `padding 6 0 18`; the 230×132 stage: glow `180×96 radial
/// rgba(220,233,236,.55)`, shadow `150×14 blur 2`, two `damp 4.6s` dots
/// (`rgba(30,79,92,.18/.14)`), Ægil `side.png 62 @28,b12 aegSkyv 3.4s`
/// (`scaleX(−1)`, ty 0/−2.5, rot 1/−1.5), the trolley `112×86 @78,b10 tomVipp
/// 3.4s` (rot −7/−2, ty 0/−3, origin 70 % 100 %); bubble `max 270; r18 18 18 6;
/// padding 11 14; glass .16→.08; border .24; inset .32; 0 16px 24px −14px
/// rgba(4,18,26,.85); bobleInn .38s cubic-bezier(.25,1.25,.45,1)`, kicker
/// `9px 800 .06em #5CE0B8`, line `PJS 13px 800 −.015em lh1.3`; CTA `r16 ·
/// padding 12 20 · 160deg #F2884E→#E0662C · inset 0 1.5px 0 white .35 · 0 3px
/// 0 rgba(150,60,15,.8) · 0 14px 22px −12px rgba(120,50,10,.9) · PJS 13.5px
/// 800 · chevron 13/3.2 · translateY(3px)` → [KurvTom]. *Deviation:* «Tilbud
/// i kveld» (the seed store's three offers) is not built — the app has no
/// priced-offer read for an empty cart; the section stays hidden.
///
/// **Endre rows** — card `mt 12; r22; padding 4 14; glass`; row `gap 11;
/// padding 9 0; border-bottom white .12`; tile `36 r13 white .12 · border .18`
/// with the mint `17 stroke 2` icon (pin / clock / card); title `12.5px 700`,
/// line `11px white .62`; pill `min-h 38 · 0 12 · 180deg #FFFFFF→#EFF3F4 ·
/// #1B4A57 11.5px 800 −.01em · chevron 11/3.2 · 0 0 0 1px white .95 · 0 1.5px
/// 0 #D2DDE0 · 0 3px 0 rgba(60,90,100,.3) · 0 7px 10px −6px rgba(15,45,55,.55)
/// · translateY(2px)`; pickup: «Se fullt kart» with the map icon `13/2`;
/// «Beskjed til budet» row (Flere valg open, delivery): tile `32 r11
/// rgba(242,109,61,.14)` icon `15/1.9 #B9441A` → [KurvEndreRad],
/// [KurvEndrePill].
///
/// **Flere valg** — `mt 12; r18; padding 12 14; glass; 0 14px 22px −14px`;
/// `12.5px 800` + line `10.5px 700 white .55`; chevron `14/3 #5CE0B8
/// rotate 0/180 .28s cubic-bezier(.3,1.2,.5,1)` → [KurvFlere].
///
/// **Tips / Beskjed til butikken** — frosted `mt 10; r22; padding 12 14;
/// rgba(255,255,255,.62) blur 26 sat 1.4; border white .9; inset 0 1.5px 0
/// white .95; 0 2px 3px −1px rgba(120,80,40,.14); 0 18px 30px −18px
/// rgba(90,60,30,.5); stigOpp .3s cubic-bezier(.2,.9,.3,1)` → [KurvFrost].
/// Tips: title `13px 800`, four tiles `r12 padding 8 0 12px 800`
/// (`rgba(63,143,95,.18) #2E6B47` on / `#F3EFE7 #57534B` off), line `10.5px
/// 500 #6E6862`. Pickup: chips `padding 8 12 11.5px 800` (`pv/pf/ps`: teal
/// gradient with teal shadows on / white gradient `#1B4A57` with paper
/// shadows off), the input row `r14 padding 4 4 4 12 180deg #F7F5F0→#FFFFFF
/// 46% · inset 0 2px 4px rgba(35,32,29,.14)` with the `34 r12` clear button,
/// «Hentetid» `12.5px 800` + `10.5px 700 #57534B` and the time chips `padding
/// 8 10`, the receipt line `r14 padding 9 11 rgba(63,143,95,.12) 11px 700
/// #2E6B47` with the check → [KurvChip]. *Deviation:* pickup times are the
/// store's slots ([_slots]), not the design's three fixed clock times.
///
/// **SAMMENDRAG** — `mt 12; r22; padding 14 14 12; 180deg #FFFDF8 → #FAF6EC
/// 62% → #F4EFE3; border white .95; inset 0 1.5px 0 white; 0 2px 3px −1px
/// rgba(120,80,40,.14); 0 18px 30px −18px rgba(90,60,30,.5)`; stripe `4px
/// repeating 14px #F26D3D / #1E4F5C .24`; header `9.5px 800 .14em #A0968A` +
/// «n varer»; rows `padding 5 0`: label `12.5px 600 #57534B`, leader `1.5px
/// dotted rgba(35,32,29,.2)`, value `13px 800 #23201D`; free delivery: the
/// struck fee `11.5px 700 #A0968A` + chip `r999 padding 3 9 rgba(63,143,95,.16)
/// 10.5px 800 #2E6B47`; Ægil lines `mt 8 r14 padding 9 11 rgba(30,79,92,.08) ·
/// border rgba(30,79,92,.14)` with `invitation.png 26` and «Angre» `12px 800
/// #1E4F5C`; door card `mt 10 r14 padding 10 11 white .6 · border white .9`:
/// kicker `11px 800 #8C847C`, input `h40 r12 border rgba(35,32,29,.12) 12.5px
/// 600`, Tolk `#23201D white 12px 800 r12 0 12`, the `40×24` toggles
/// (`#2E7E4F` / `rgba(35,32,29,.22)`, thumb 18 at 3/21, `.2s`), «Kode ved
/// levering» `12.5px 800` + line `11px 600 #57534B`; perforation `h13 mt 11
/// mx −14; dashed 2px rgba(35,32,29,.16); holes 16 #EFE8DB`; Å BETALE NÅ `mt
/// 8 r18 padding 13 14 165deg #2A6272 → #1E4F5C 58% → #173E48 · inset 0 1.5px 0
/// white .22 · inset 0 −2px 6px rgba(4,20,28,.4) · 0 12px 20px −12px
/// rgba(15,45,55,.75)`; kicker `9.5px 800 .14em #8FB4C0`, «Totalt» `PJS 15px
/// 800 −.02em #F5F3EF`, total `PJS 32px 800 −.04em lh.9 · 0 2px 6px
/// rgba(4,20,28,.45)` + «kr» `13px 800 #9FC2CC`; lines `11px 700 #CFE3E9`
/// with the check `13/2.8 #6FE0AE` and the kroner sign `13/2.4 #F2C14E` →
/// [KurvRad], [KurvPerforering], [KurvAaBetale], [KurvToggle].
/// *Deviations:* «Premie: gratis levering» (the prototype's prize row) has
/// no source here; the free-delivery chip reads «Gratis» without the
/// threshold (the preview carries no threshold); the points line uses the
/// Points spec rule (1 point per 10 kr) instead of the prototype's 7 % «kr
/// tilbake»; the door chips the prototype's Tolk returns are not shown — Tolk
/// hands the note to Ægil; the gift block (`kGave`, only with a gift in the
/// cart) is not built; the door toggle is local state.
///
/// **Footer** — `mt 12; r20; padding 11 13; rgba(220,233,236,.5) blur 20;
/// border white .85; inset 0 1.5px 0 white .9; 0 14px 26px −16px
/// rgba(30,79,92,.4)`; dot `9 #F2C14E lyktPuls 3s`; `11.5px 600 #173E48
/// lh1.45` → [KurvFot]. *Deviation:* the courier's name is not known before
/// the order, so the second sentence («Ærendet krysser Vågen med Jonas») is
/// left out.
///
/// **Dra for å betale** — `left/right 16; bottom 16; h60; r20; padding 5;
/// 180deg #C94A20 → #E0662C 55% → #F2884E; inset 0 3px 7px rgba(110,35,8,.7);
/// inset 0 −2px 0 white .22; 0 1.5px 0 white .55; 0 16px 28px −14px
/// rgba(120,50,10,.75)`; fill `left/top/bottom 5; w 50+x; r16; 90deg #2E7E8F
/// → #46A3B4; inset .35 / inset −2px 4px rgba(6,30,38,.4)` with the `.45`
/// stripes on `vannRenn 1.1s`; label `14px 800` + three `9×12` arrows on
/// `pilVink 1.6s` (+.18 s, +.36 s); price pill `r10 padding 4 9
/// rgba(110,35,8,.32) · inset 0 1.5px 3px rgba(90,30,5,.55)`, `PJS 15px 800` +
/// «kr» `10.5px 800 #FFE0CC`, hidden past 35 %; knob `50 @5+x · r16 · radial
/// 36% 26% #4F9AAB → #2A6272 40% → #1E4F5C 78% → #143C46 · inset 0 2px 0 white
/// .4 · inset 0 −5px 8px rgba(4,20,28,.5) · 0 0 0 2px white .9 · 0 3px 0 2px
/// #0F2E36 · 0 10px 16px −4px rgba(0,20,30,.75)`, gloss `6/6/3 h16`, chevrons
/// `15 .55` + `17`, `knappHint 4.2s` idle; `spPuls 2.4s` ring `−6 r21 1.5px
/// white .55`; three `betBoble .9s` (+.3, +.6) while dragging; release ≥ 62 %
/// → snap `.5s cubic-bezier(.32,1.35,.45,1)` and pay, else spring back →
/// [KurvBetal]. *Deviation:* the prototype hides its bottom nav while the
/// cart has lines and puts the slider in its place; the app keeps the tab
/// nav and floats the slider above it.
class KurvScreen extends StatefulWidget {
  const KurvScreen({
    super.key,
    this.embedded = true,
    this.api,
    this.customerApi,
  });

  final bool embedded;
  final OpsKasseApi? api;
  final OpsCustomerApi? customerApi;

  @override
  State<KurvScreen> createState() => KurvScreenState();
}

class KurvScreenState extends State<KurvScreen> with WidgetsBindingObserver {
  KurvState? _cart;
  OrderPreviewPojo? _preview;
  List<AddressListItem> _addresses = const [];
  AddressListItem? _address;
  bool _pickup = false;
  KasseSlot? _slot;
  int _paymentType = 3;
  int _tip = 0;
  bool _more = false;
  bool _codeAtDoor = false;
  bool _doorShared = false;
  bool _departing = false;
  final Set<String> _pickupChips = {};
  final TextEditingController _pickupNote = TextEditingController();
  BergenStoreInfo? _store;
  bool _placing = false;
  List<KurvLine> _undone = const [];
  final TextEditingController _note = TextEditingController();
  final TextEditingController _door = TextEditingController();

  OpsKasseApi get _api => widget.api ?? OpsKasseApi();
  OpsCustomerApi get _customer => widget.customerApi ?? OpsCustomerApi();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _note.dispose();
    _door.dispose();
    _pickupNote.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  /// Public so the shell can refresh the tab when it is shown.
  Future<void> reload() => _load();

  Future<void> _load() async {
    final cart = await _api.cart();
    if (!mounted) return;
    setState(() => _cart = cart);
    if (cart.isEmpty) return;
    final results = await Future.wait([_api.preview(), _api.addresses()]);
    if (!mounted) return;
    final addresses = results[1] as List<AddressListItem>;
    final savedId = prefGetInt(prefNewDeliveryAddressId);
    setState(() {
      _preview = results[0] as OrderPreviewPojo?;
      _addresses = addresses;
      _address ??=
          addresses.where((a) => a.addressId == savedId).firstOrNull ??
          addresses.firstOrNull;
    });
    if (_store?.id != cart.storeId) {
      final store = await OpsButikkApi().store(cart.storeId);
      if (mounted && store != null) setState(() => _store = store);
    }
  }

  // ── slots (Levering sheet) ─────────────────────────────────────────────

  List<KasseSlot> get _slots {
    final now = DateTime.now();
    final eta = _preview == null ? 30 : 30;
    final asapEnd = now.add(Duration(minutes: eta + 5));
    String hhmm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    DateTime nextHalf(DateTime from) {
      final m = from.minute < 30 ? 30 : 60;
      return DateTime(
        from.year,
        from.month,
        from.day,
        from.hour,
        0,
      ).add(Duration(minutes: m));
    }

    final first = nextHalf(now.add(Duration(minutes: eta)));
    final second = first.add(const Duration(hours: 1));
    return [
      KasseSlot(
        id: 'asap',
        label: KasseCopy.a1_kasse_tid_asap,
        line: KasseCopy.a1_kasse_tid_innen(hhmm(asapEnd), eta - 5, eta + 5),
      ),
      KasseSlot(
        id: 'slot1',
        label: hhmm(first),
        line: KasseCopy.a1_kasse_lev_middag_line,
        at: first,
      ),
      KasseSlot(
        id: 'slot2',
        label: hhmm(second),
        line: KasseCopy.a1_kasse_lev_kveld_line,
        at: second,
      ),
    ];
  }

  // ── actions ────────────────────────────────────────────────────────────

  Future<void> _changeQty(KurvLine l, int delta) async {
    final q = l.quantity + delta;
    if (q <= 0) {
      await _remove(l);
      return;
    }
    if (await _api.changeQuantity(l.cartId, q)) await _load();
  }

  Future<void> _remove(KurvLine l) async {
    if (await _api.remove(l.cartId)) {
      prefSetInt(prefCartCount, (prefGetInt(prefCartCount) - 1).clamp(0, 999));
      if (mounted) BergenCart.syncBadge(context);
      await _load();
    }
  }

  Future<void> _undoAegil() async {
    final lines = _cart?.aegilLines ?? const [];
    for (final l in lines) {
      await _api.remove(l.cartId);
    }
    if (!mounted) return;
    setState(() => _undone = lines);
    showBergenToast(context, KasseCopy.a1_kasse_angret);
    await _load();
  }

  Future<void> _openAddress() async {
    if (!await showGuestLoginSheet(context, prompt: GuestLoginPrompt.address))
      return;
    if (!mounted) return;
    final chosen = await showAdresseSheet(
      context,
      addresses: _addresses,
      selectedId: _address?.addressId,
      onAddNew: () async {
        if (await showNyAdresseSheet(context)) await _load();
      },
    );
    if (chosen == null || !mounted) return;
    setState(() => _address = chosen);
    prefSetInt(prefNewDeliveryAddressId, chosen.addressId);
    final preview = await _api.preview();
    if (mounted) setState(() => _preview = preview);
    // Coverage (geo spec §4): skipped silently when the endpoint is not here.
    final covered = await checkCoverage(_customer, chosen);
    if (!mounted || covered) return;
    await showBergenArk<void>(
      context,
      title: KasseCopy.a1_kasse_ikke_dekket,
      primary: BergenArkAction(
        label: KasseCopy.a1_kasse_si_fra_cta,
        onTap: () async {
          Navigator.of(context).pop();
          final lat = double.tryParse(chosen.lat);
          final lng = double.tryParse(chosen.long);
          if (lat != null && lng != null)
            await _customer.waitlist(lat, lng, address: chosen.address);
          if (mounted) showBergenToast(context, KasseCopy.a1_kasse_sagt_fra);
        },
      ),
    );
  }

  Future<void> _openLevering() async {
    final chosen = await showLeveringSheet(
      context,
      slots: _slots,
      selected: _slot,
      pickup: _pickup,
      onModeChanged: (m) => setState(() => _pickup = m),
    );
    if (chosen != null && mounted) setState(() => _slot = chosen);
  }

  Future<void> _openBetaling() async {
    final chosen = await showBetalingSheet(context, selected: _paymentType);
    if (chosen != null && mounted) setState(() => _paymentType = chosen);
  }

  void _tolk() => BergenRoutes.pushOr(
    context,
    kAegilRoute,
    arguments: {'intent': 'door', 'q': _door.text.trim()},
    orElse: () => openScreen(
      context,
      SnurreChatScreen(draftFromHomeSearch: _door.text.trim()),
    ),
  );

  String get _fullNote {
    final parts = <String>[
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
      if (_door.text.trim().isNotEmpty)
        '${KasseCopy.a1_kasse_doren}: ${_door.text.trim()}',
      if (_pickup && _pickupChips.isNotEmpty) _pickupChips.join(' · '),
      if (_pickup && _pickupNote.text.trim().isNotEmpty)
        _pickupNote.text.trim(),
    ];
    return parts.join(' · ');
  }

  /// True when the order went through (Vipps opened / the card checkout
  /// opened); false sends the slider back.
  Future<bool> _pay() async {
    final cart = _cart;
    if (cart == null || cart.isEmpty || _placing) return false;
    if (!await showGuestLoginSheet(context, prompt: GuestLoginPrompt.checkout))
      return false;
    if (!mounted) return false;
    if (!_pickup && _address == null) {
      showBergenToast(context, KasseCopy.a1_kasse_velg_adresse_forst);
      return false;
    }
    final min = _preview?.minOrderAmount ?? 0;
    if (!_pickup && min > 0 && cart.subtotal < min) {
      showBergenToast(context, KasseCopy.a1_kasse_min_ordre(KasseCopy.kr(min)));
      return false;
    }
    if (_paymentType == 2) {
      // The card path is the existing Stripe checkout, unchanged.
      prefSetString(prefTip, '$_tip');
      openScreen(context, const CheckOut());
      return true;
    }
    setState(() {
      _placing = true;
      _departing = true;
    });
    HapticFeedback.mediumImpact();
    prefSetString(prefTip, '$_tip');
    final response = await _api.placeOrder(
      storeId: cart.storeId,
      addressId: _pickup ? 0 : (_address?.addressId ?? 0),
      paymentType: 3,
      pickup: _pickup,
      cartIds: [for (final l in cart.lines) l.cartId],
      note: _fullNote,
      scheduleDateTime: _slot?.scheduleDateTime,
      tip: _tip.toDouble(),
    );
    if (!mounted) return false;
    if (response == null || response['status'] != 1) {
      setState(() {
        _placing = false;
        _departing = false;
      });
      final code = '${response?['error'] ?? response?['code'] ?? ''}';
      if (code == 'PD_OUTSIDE_RADIUS') {
        // Spec §8.2: the store does not deliver here — offer pickup.
        await showBergenArk<void>(
          context,
          title: KasseCopy.a1_kasse_utenfor,
          subtitle: KasseCopy.a1_kasse_utenfor_line,
          primary: BergenArkAction(
            label: KasseCopy.a1_kasse_velg_henting,
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _pickup = true);
            },
          ),
        );
        return false;
      }
      showBergenToast(
        context,
        '${response?['message'] ?? BergenRoutes.kommerSnart}',
      );
      return false;
    }
    final orderId = (response['order_id'] as num?)?.toInt() ?? 0;
    prefSetInt('bookedOrderId', orderId);
    if (_codeAtDoor && orderId > 0) {
      await _customer.requestCode(orderId);
    }
    final url = orderId > 0 ? await _api.vippsRedirect(orderId) : null;
    if (!mounted) return false;
    setState(() => _placing = false);
    if (url == null) {
      showBergenToast(context, KasseCopy.a1_kasse_vipps);
      return orderId > 0;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showBergenToast(context, KasseCopy.a1_kasse_vipps);
    }
    return true;
  }

  // ── the note editor («Beskjed til budet» · Endre) ──────────────────────

  Future<void> _editNote() async {
    await showBergenSheet<void>(
      context,
      onDark: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              KasseCopy.a1_kasse_beskjed_bud,
              style: bDisplay(ctx, 16, letterSpacingEm: -.02),
            ),
            SizedBox(height: 10 * ctx.bs),
            TextField(
              key: const Key('a1_kasse_beskjed'),
              controller: _note,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              style: bText(ctx, 13, weight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: rgba(255, 255, 255, .1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14 * ctx.bs),
                  borderSide: BorderSide(color: rgba(255, 255, 255, .2)),
                ),
                hintText: KasseCopy.a1_kasse_beskjed_hint,
                hintStyle: bText(ctx, 13, weight: FontWeight.w600, color: rgba(255, 255, 255, .5)),
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(),
            ),
            SizedBox(height: 12 * ctx.bs),
            BergenCta3d(
              label: KasseCopy.a1_kasse_bruk_dette,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  // ── build ──────────────────────────────────────────────────────────────

  double _delivery() => _pickup ? 0.0 : (_preview?.deliveryCost ?? 0);
  double _fees() => (_preview?.taxCost ?? 0) + (_preview?.packagingCost ?? 0);
  double _discount() =>
      (_preview?.discountCost ?? 0) +
      (_preview?.promocodeDiscount ?? 0) +
      (_preview?.referDiscount ?? 0);

  double _total(KurvState cart) =>
      (cart.subtotal + _delivery() + _fees() - _discount() + _tip).clamp(
        0,
        double.infinity,
      );

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final bottom = widget.embedded
        ? bergenNavReserve(context)
        : MediaQuery.paddingOf(context).bottom + 12 * s;
    final cart = _cart;
    final hasCart = cart != null && !cart.isEmpty;

    return Scaffold(
      backgroundColor: BergenTokens.teal,
      body: BergenOnce(
        durationMs: 340,
        builder: (context, p, child) {
          final q = kSkjermInn.transform(p);
          return Opacity(
            opacity: q.clamp(0, 1),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(0.0, 10 * (1 - q) * s)
                ..scale(.985 + .015 * q),
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            // `radial-gradient(80% 50% at 14% 0%, white .22 → 0 60%)` over the
            // screen gradient.
            const Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(gradient: kBergenScreenGradient)),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-.72, -1),
                      radius: .8,
                      colors: [rgba(255, 255, 255, .22), rgba(255, 255, 255, 0)],
                      stops: const [0, .6],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: safeTop + 98 * s,
              bottom: 0,
              child: _Panel(
                bottomReserve: bottom + (hasCart ? 60 * s + 24 * s : 16 * s),
                child: cart == null
                    ? Padding(
                        padding: EdgeInsets.all(30 * s),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      )
                    : !hasCart
                    ? _empty(context)
                    : _filled(context, cart),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: KurvSeilas(
                safeTop: safeTop,
                embedded: widget.embedded,
                departing: _departing,
                storeName: _preview?.storeName,
                storeLogoUrl: _store?.logoUrl,
              ),
            ),
            if (hasCart)
              Positioned(
                left: 16 * s,
                right: 16 * s,
                bottom: bottom + 8 * s,
                child: KurvBetal(
                  total: _total(cart),
                  busy: _placing,
                  onPay: _pay,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(top: 12 * s),
      child: KurvGlass(
        radius: 22 * s,
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
        transparent: true,
        child: KurvTom(
          onBrowse: () {
            final shell = context.findAncestorStateOfType<HomeMainV1State>();
            if (shell != null) {
              shell.switchToTab(0);
            } else {
              BergenRoutes.push(context, '/bergen/utforsk');
            }
          },
        ),
      ),
    );
  }

  Widget _filled(BuildContext context, KurvState cart) {
    final s = context.bs;
    final slot = _slot ?? _slots.first;
    final address = _address;
    final delivery = _delivery();
    final fees = _fees();
    final discount = _discount();
    final total = _total(cart);
    final aegil = cart.aegilLines;
    final storeName = _preview?.storeName ?? '';
    final pickupCount =
        _pickupChips.length + (_pickupNote.text.trim().isEmpty ? 0 : 1);
    final flereUnder = _pickup
        ? KasseCopy.a1_kasse_flere_under_hent
        : KasseCopy.a1_kasse_flere_under_lev;
    final doorVisible = _more && !_pickup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10 * s),
        KurvModus(pickup: _pickup, onMode: (m) => setState(() => _pickup = m)),
        SizedBox(height: 12 * s),
        KurvGlass(
          key: const Key('a1_kasse_linjer'),
          radius: 22 * s,
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
          child: Column(
            children: [
              for (final l in cart.lines)
                KurvLinje(
                  line: l,
                  onMinus: () => _changeQty(l, -1),
                  onPlus: () => _changeQty(l, 1),
                ),
              KurvLeggMer(
                onTap: () => BergenRoutes.push(
                  context,
                  '/bergen/butikk/${cart.storeId}',
                  arguments: {'name': storeName},
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
        KurvGlass(
          radius: 22 * s,
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
          child: Column(
            children: [
              KurvEndreRad(
                keyName: 'a1_kasse_rad_adresse',
                icon: KurvIcons.pin,
                title: _pickup
                    ? [
                        if (storeName.isNotEmpty) storeName,
                        if (_preview?.storeAddress != null &&
                            _preview!.storeAddress!.isNotEmpty)
                          _preview!.storeAddress!.split(',').first,
                      ].join(' · ').ifEmpty(KasseCopy.a1_kasse_hent_tittel)
                    : address == null
                    ? KasseCopy.a1_kasse_adr_velg
                    : [
                        if (address.type.isNotEmpty) address.type,
                        address.address.split(',').first,
                      ].join(' · '),
                line: _pickup
                    ? KasseCopy.a1_kasse_hent_selv
                    : (address == null
                          ? KasseCopy.a1_kasse_adr_tittel
                          : [
                              if (address.flatNo.isNotEmpty) address.flatNo,
                              if (address.landmark.isNotEmpty) address.landmark,
                            ].join(' · ').ifEmpty(KasseCopy.a1_kasse_adr_tittel)),
                action: _pickup ? KasseCopy.a1_kasse_se_kart : KasseCopy.a1_kasse_endre,
                actionIcon: _pickup ? KurvIcons.map : null,
                onTap: _pickup
                    ? () => showBergenToast(context, BergenRoutes.kommerSnart)
                    : _openAddress,
              ),
              KurvEndreRad(
                keyName: 'a1_kasse_rad_tid',
                icon: KurvIcons.clock,
                title: _pickup ? '${KasseCopy.a1_kasse_henting} · ${slot.label}' : slot.label,
                line: slot.line,
                action: KasseCopy.a1_kasse_endre,
                onTap: _openLevering,
              ),
              KurvEndreRad(
                keyName: 'a1_kasse_rad_betaling',
                icon: KurvIcons.card,
                title: _paymentType == 3 ? KasseCopy.a1_kasse_vipps : KasseCopy.a1_kasse_kort,
                line: KasseCopy.a1_kasse_betaling_ved,
                action: KasseCopy.a1_kasse_endre,
                onTap: _openBetaling,
                last: !doorVisible,
              ),
              if (doorVisible)
                KurvEndreRad(
                  keyName: 'a1_kasse_rad_beskjed',
                  icon: KurvIcons.door,
                  orange: true,
                  title: KasseCopy.a1_kasse_beskjed_bud,
                  line: _note.text.trim().isEmpty
                      ? KasseCopy.a1_kasse_beskjed_hint.replaceAll(' …', '')
                      : _note.text.trim(),
                  action: KasseCopy.a1_kasse_endre,
                  onTap: _editNote,
                  last: true,
                ),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
        KurvFlere(
          open: _more,
          line: flereUnder,
          onTap: () => setState(() => _more = !_more),
        ),
        if (_more && _pickup) ...[
          SizedBox(height: 10 * s),
          KurvFrost(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KasseCopy.a1_kasse_beskjed_butikk,
                  style: bText(context, 13, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                ),
                SizedBox(height: 9 * s),
                Wrap(
                  spacing: 6 * s,
                  runSpacing: 6 * s,
                  children: [
                    for (final c in KasseCopy.a1_kasse_hent_chips)
                      KurvChip(
                        key: Key('a1_kasse_hent_chip_${KasseCopy.a1_kasse_hent_chips.indexOf(c)}'),
                        label: c,
                        on: _pickupChips.contains(c),
                        onTap: () => setState(() {
                          if (!_pickupChips.remove(c)) _pickupChips.add(c);
                        }),
                      ),
                  ],
                ),
                SizedBox(height: 10 * s),
                Container(
                  padding: EdgeInsets.fromLTRB(12 * s, 4 * s, 4 * s, 4 * s),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14 * s),
                    gradient: cssLinear(180, const [Color(0xFFF7F5F0), Color(0xFFFFFFFF)], const [0, .46]),
                    boxShadow: [BoxShadow(color: rgba(255, 255, 255, .95), offset: Offset(0, -1.5 * s))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('a1_kasse_hent_beskjed'),
                          controller: _pickupNote,
                          onChanged: (_) => setState(() {}),
                          style: bDisplay(context, 12.5, weight: FontWeight.w700, letterSpacingEm: 0, color: const Color(0xFF23201D)),
                          cursorColor: BergenTokens.orange,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 9 * s),
                            hintText: KasseCopy.a1_kasse_hent_beskjed_hint(storeName),
                            hintStyle: bDisplay(context, 12.5, weight: FontWeight.w700, letterSpacingEm: 0, color: BergenTokens.inkFaint),
                          ),
                        ),
                      ),
                      if (_pickupNote.text.isNotEmpty)
                        OnbPressable(
                          onTap: () => setState(_pickupNote.clear),
                          pressDy: 1.5,
                          child: Container(
                            width: 34 * s,
                            height: 34 * s,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12 * s),
                              gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF1ECE1)]),
                              boxShadow: [
                                BoxShadow(color: rgba(255, 255, 255, .95), spreadRadius: 1),
                                BoxShadow(color: const Color(0xFFD9D2C4), offset: Offset(0, 1.5 * s)),
                                BoxShadow(color: rgba(35, 32, 29, .5), offset: Offset(0, 3 * s), blurRadius: onbBlur(5 * s), spreadRadius: -3 * s),
                              ],
                            ),
                            child: KurvIcon(11 * s, KurvIcons.cross, color: const Color(0xFF57534B), width: 3),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 12 * s),
                  padding: EdgeInsets.only(top: 11 * s),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: rgba(35, 32, 29, .08)))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(KasseCopy.a1_kasse_hentetid, style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFF23201D))),
                            Text(KasseCopy.a1_kasse_hentetid_line, style: bText(context, 10.5, color: const Color(0xFF57534B))),
                          ],
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Wrap(
                        spacing: 5 * s,
                        children: [
                          for (final sl in _slots)
                            KurvChip(
                              label: sl.label,
                              padding: 10,
                              on: slot.id == sl.id,
                              onTap: () => setState(() => _slot = sl),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 11 * s),
                  padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 9 * s),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14 * s), color: rgba(63, 143, 95, .12)),
                  child: Row(
                    children: [
                      KurvIcon(14 * s, KurvIcons.check, color: const Color(0xFF2E6B47), width: 2.4),
                      SizedBox(width: 8 * s),
                      Expanded(
                        child: Text(
                          pickupCount == 0
                              ? KasseCopy.a1_kasse_hent_kvitt_klar(slot.label, prefGetString(prefUserName).split(' ').first)
                              : KasseCopy.a1_kasse_hent_kvitt_n(pickupCount, slot.label),
                          style: bText(context, 11, height: 1.4, color: const Color(0xFF2E6B47)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_more && !_pickup) ...[
          SizedBox(height: 10 * s),
          KurvFrost(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(KasseCopy.a1_kasse_tips_title, style: bText(context, 13, weight: FontWeight.w800, color: const Color(0xFF23201D))),
                SizedBox(height: 9 * s),
                Row(
                  children: [
                    for (final t in const [0, 15, 25, 40]) ...[
                      Expanded(
                        child: GestureDetector(
                          key: Key('a1_kasse_tips_$t'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _tip = t),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8 * s),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12 * s),
                              color: _tip == t ? rgba(63, 143, 95, .18) : const Color(0xFFF3EFE7),
                            ),
                            child: Text('$t kr', style: bText(context, 12, weight: FontWeight.w800, color: _tip == t ? const Color(0xFF2E6B47) : const Color(0xFF57534B))),
                          ),
                        ),
                      ),
                      if (t != 40) SizedBox(width: 8 * s),
                    ],
                  ],
                ),
                SizedBox(height: 8 * s),
                Text(KasseCopy.a1_kasse_tips_line, style: bText(context, 10.5, weight: FontWeight.w500, color: const Color(0xFF6E6862))),
              ],
            ),
          ),
        ],
        SizedBox(height: 12 * s),
        _Summary(
          cart: cart,
          pickup: _pickup,
          delivery: delivery,
          fees: fees,
          discount: discount,
          tip: _tip,
          total: total,
          aegil: aegil,
          doorVisible: doorVisible,
          door: _door,
          doorShared: _doorShared,
          codeAtDoor: _codeAtDoor,
          onUndoAegil: _undoAegil,
          onTolk: _tolk,
          onDoorShared: () {
            setState(() => _doorShared = !_doorShared);
            showBergenToast(context, _doorShared ? KasseCopy.a1_kasse_dor_delt : KasseCopy.a1_kasse_dor_ikke_delt);
          },
          onCode: () => setState(() => _codeAtDoor = !_codeAtDoor),
        ),
        if (_undone.isNotEmpty) ...[
          SizedBox(height: 8 * s),
          BergenUndoPill(
            message: KasseCopy.a1_kasse_angret,
            onUndo: () async {
              for (final l in _undone) {
                await BergenCart.add(context, storeId: l.storeId, productId: l.productId, quantity: l.quantity);
              }
              setState(() => _undone = const []);
              await _load();
            },
          ),
        ],
        SizedBox(height: 12 * s),
        KurvFot(text: KasseCopy.a1_kasse_bergenske),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

/// The scrolling panel (design L5047): `r28 28 0 0`, `180deg #22586A →
/// #1B4854 140px`, the inset highlight and the two upward shadows.
class _Panel extends StatelessWidget {
  const _Panel({required this.bottomReserve, required this.child});

  final double bottomReserve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return LayoutBuilder(
      builder: (context, box) {
        final stop = (140 * s / box.maxHeight).clamp(0.05, 1.0);
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28 * s)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Color(0xFF22586A), Color(0xFF1B4854)],
              stops: [0, stop],
            ),
            border: Border.all(color: rgba(255, 255, 255, .14)),
            boxShadow: [
              BoxShadow(color: rgba(4, 18, 26, .6), offset: Offset(0, -12 * s), blurRadius: onbBlur(18 * s), spreadRadius: -10 * s),
              BoxShadow(color: rgba(4, 18, 26, .7), offset: Offset(0, -34 * s), blurRadius: onbBlur(52 * s), spreadRadius: -26 * s),
            ],
          ),
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, bottomReserve),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [child],
              ),
              bergenInsetTop(radius: 28 * s, height: 1.5 * s, alpha: .28),
            ],
          ),
        );
      },
    );
  }
}

/// SAMMENDRAG (design L5200–5225).
class _Summary extends StatelessWidget {
  const _Summary({
    required this.cart,
    required this.pickup,
    required this.delivery,
    required this.fees,
    required this.discount,
    required this.tip,
    required this.total,
    required this.aegil,
    required this.doorVisible,
    required this.door,
    required this.doorShared,
    required this.codeAtDoor,
    required this.onUndoAegil,
    required this.onTolk,
    required this.onDoorShared,
    required this.onCode,
  });

  final KurvState cart;
  final bool pickup;
  final double delivery;
  final double fees;
  final double discount;
  final int tip;
  final double total;
  final List<KurvLine> aegil;
  final bool doorVisible;
  final TextEditingController door;
  final bool doorShared;
  final bool codeAtDoor;
  final VoidCallback onUndoAegil;
  final VoidCallback onTolk;
  final VoidCallback onDoorShared;
  final VoidCallback onCode;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final count = cart.lines.fold<int>(0, (a, l) => a + l.quantity);
    final points = (cart.subtotal / 10).floor();
    final side = EdgeInsets.symmetric(horizontal: 14 * s);
    return BergenCssShadow(
      radius: 22 * s,
      shadows: [
        BoxShadow(color: rgba(120, 80, 40, .14), offset: Offset(0, 2 * s), blurRadius: onbBlur(3 * s), spreadRadius: -1 * s),
        BoxShadow(color: rgba(90, 60, 30, .5), offset: Offset(0, 18 * s), blurRadius: onbBlur(30 * s), spreadRadius: -18 * s),
      ],
      child: Container(
        key: const Key('a1_kasse_sammendrag'),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.only(top: 14 * s, bottom: 12 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22 * s),
          gradient: cssLinear(180, const [Color(0xFFFFFDF8), Color(0xFFFAF6EC), Color(0xFFF4EFE3)], const [0, .62, 1]),
          border: Border.all(color: rgba(255, 255, 255, .95)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: side,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 9 * s),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(KasseCopy.a1_kasse_sammendrag, style: bText(context, 9.5, weight: FontWeight.w800, letterSpacingEm: .14, color: const Color(0xFFA0968A))),
                            Text(KasseCopy.a1_kasse_best_antall(count), style: bText(context, 9.5, weight: FontWeight.w800, letterSpacingEm: .06, color: const Color(0xFFA0968A))),
                          ],
                        ),
                      ),
                      KurvRad(label: KasseCopy.a1_kasse_varer, value: KasseCopy.kr(cart.subtotal)),
                      KurvRad(
                        key: pickup ? null : const Key('a1_kasse_frakt'),
                        label: pickup ? KasseCopy.a1_kasse_henting : KasseCopy.a1_kasse_frakt,
                        trailing: pickup || delivery == 0
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * s),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: rgba(63, 143, 95, .16)),
                                child: Text(
                                  pickup ? KasseCopy.a1_kasse_frakt_chip_hent : KasseCopy.a1_kasse_frakt_fri,
                                  style: bText(context, 10.5, weight: FontWeight.w800, color: const Color(0xFF2E6B47)),
                                ),
                              )
                            : null,
                        value: KasseCopy.kr(delivery),
                      ),
                      if (fees > 0) KurvRad(label: KasseCopy.a1_kasse_avgifter, value: KasseCopy.kr(fees)),
                      if (discount > 0) KurvRad(label: KasseCopy.a1_kasse_rabatt, value: '−${KasseCopy.kr(discount)}'),
                      if (tip > 0) KurvRad(key: const Key('a1_kasse_tips_rad'), label: KasseCopy.a1_kasse_tips_rad, value: KasseCopy.kr(tip.toDouble())),
                      if (aegil.isNotEmpty)
                        Container(
                          key: const Key('a1_kasse_aegil_linjer'),
                          margin: EdgeInsets.only(top: 8 * s),
                          padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 9 * s),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14 * s),
                            color: rgba(30, 79, 92, .08),
                            border: Border.all(color: rgba(30, 79, 92, .14)),
                          ),
                          child: Row(
                            children: [
                              Image.asset('assets/images/dashboard/invitation.png', width: 26 * s, height: 26 * s, fit: BoxFit.contain),
                              SizedBox(width: 10 * s),
                              Expanded(
                                child: Text(
                                  KasseCopy.a1_kasse_aegil_linjer(
                                    aegil.map((l) => l.name).join(', '),
                                    KasseCopy.kr(aegil.fold<double>(0, (a, l) => a + l.sum)),
                                  ),
                                  style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                                ),
                              ),
                              GestureDetector(
                                key: const Key('a1_kasse_aegil_angre'),
                                behavior: HitTestBehavior.opaque,
                                onTap: onUndoAegil,
                                child: Text(KasseCopy.a1_kasse_angre, style: bText(context, 12, weight: FontWeight.w800, color: BergenTokens.teal)),
                              ),
                            ],
                          ),
                        ),
                      if (doorVisible)
                        Container(
                          margin: EdgeInsets.only(top: 10 * s),
                          padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 10 * s),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14 * s),
                            color: rgba(255, 255, 255, .6),
                            border: Border.all(color: rgba(255, 255, 255, .9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(KasseCopy.a1_kasse_doren, style: bText(context, 11, weight: FontWeight.w800, color: const Color(0xFF8C847C))),
                              SizedBox(height: 6 * s),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 40 * s,
                                      padding: EdgeInsets.symmetric(horizontal: 10 * s),
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12 * s),
                                        border: Border.all(color: rgba(35, 32, 29, .12)),
                                      ),
                                      child: TextField(
                                        key: const Key('a1_kasse_dor'),
                                        controller: door,
                                        style: bText(context, 12.5, weight: FontWeight.w600, color: const Color(0xFF23201D)),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          border: InputBorder.none,
                                          hintText: KasseCopy.a1_kasse_doren_hint,
                                          hintStyle: bText(context, 12.5, weight: FontWeight.w600, color: BergenTokens.inkFaint),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6 * s),
                                  GestureDetector(
                                    key: const Key('a1_kasse_tolk'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onTolk,
                                    child: Container(
                                      height: 40 * s,
                                      padding: EdgeInsets.symmetric(horizontal: 12 * s),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: const Color(0xFF23201D), borderRadius: BorderRadius.circular(12 * s)),
                                      child: Text(KasseCopy.a1_kasse_tolk, style: bText(context, 12, weight: FontWeight.w800)),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onDoorShared,
                                child: Container(
                                  constraints: BoxConstraints(minHeight: 36 * s),
                                  margin: EdgeInsets.only(top: 8 * s),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(KasseCopy.a1_kasse_dor_del, style: bText(context, 12, color: const Color(0xFF57534B)))),
                                      SizedBox(width: 10 * s),
                                      KurvToggle(key: const Key('a1_kasse_dor_del'), on: doorShared, onTap: onDoorShared),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onCode,
                                child: Container(
                                  constraints: BoxConstraints(minHeight: 36 * s),
                                  margin: EdgeInsets.only(top: 4 * s),
                                  padding: EdgeInsets.only(top: 6 * s),
                                  decoration: BoxDecoration(border: Border(top: BorderSide(color: rgba(35, 32, 29, .07)))),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(KasseCopy.a1_kasse_kode, style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFF23201D))),
                                            Text(
                                              total >= 300 ? KasseCopy.a1_kasse_kode_over('300') : KasseCopy.a1_kasse_kode_under,
                                              style: bText(context, 11, weight: FontWeight.w600, color: const Color(0xFF57534B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10 * s),
                                      KurvToggle(key: const Key('a1_kasse_kode_switch'), on: codeAtDoor, onTap: onCode),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 11 * s),
                  child: const KurvPerforering(),
                ),
                Padding(
                  padding: side.copyWith(top: 8 * s),
                  child: KurvAaBetale(total: total, points: points),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 4 * s,
              child: Opacity(opacity: .24, child: CustomPaint(painter: _StripePainter(s))),
            ),
            bergenInsetTop(radius: 22 * s, height: 1.5 * s, alpha: 1),
          ],
        ),
      ),
    );
  }
}

/// `repeating-linear-gradient(90deg, #F26D3D 0 14px, #1E4F5C 14px 28px)`.
class _StripePainter extends CustomPainter {
  const _StripePainter(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    var x = 0.0;
    var orange = true;
    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 14 * s, size.height), Paint()..color = orange ? const Color(0xFFF26D3D) : const Color(0xFF1E4F5C));
      x += 14 * s;
      orange = !orange;
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.s != s;
}
