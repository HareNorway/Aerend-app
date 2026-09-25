import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../deliveryService/checkout/checkout.dart';
import '../../deliveryService/checkout/checkout_dl.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../kit/bergen_kit.dart';
import 'kasse_copy.dart';
import 'kasse_sheets.dart';

/// `kurv` (≈L4973–5250 in `Ærend Kunde Bergen.dc.html`) at `/bergen/kurv`,
/// tab 2 of the shell.
///
/// Seilas · kassen header, Levering / Henting, the lines, the empty state,
/// "Legg til noe mer", the Endre rows (address / time / payment), the note
/// for the courier, tips, SAMMENDRAG with the Ægil-added lines and Angre,
/// DØREN · FOR BUDET with the Tolk chip (agil-3's C4 — the chip pushes
/// `kAegilRoute` with `intent=door`), Kode ved levering, the gift recipient,
/// Å BETALE NÅ and the pay button on the existing Vipps flow.
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
  bool _gift = false;
  String _giftMode = 'overrask';
  bool _placing = false;
  List<KurvLine> _undone = const [];
  final TextEditingController _note = TextEditingController();
  final TextEditingController _door = TextEditingController();
  final TextEditingController _giftName = TextEditingController();

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
    _giftName.dispose();
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
    prefSetInt(prefNewDeliveryAddressId, chosen.addressId ?? 0);
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
          final lat = double.tryParse('${chosen.lat ?? ''}');
          final lng = double.tryParse('${chosen.long ?? ''}');
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
      if (_gift && _giftName.text.trim().isNotEmpty)
        '${KasseCopy.a1_kasse_gave_til} ${_giftName.text.trim()} · ${_giftMode == 'overrask' ? KasseCopy.a1_kasse_overrask : KasseCopy.a1_kasse_si_fra}',
    ];
    return parts.join(' · ');
  }

  Future<void> _pay() async {
    final cart = _cart;
    if (cart == null || cart.isEmpty || _placing) return;
    if (!await showGuestLoginSheet(context, prompt: GuestLoginPrompt.checkout))
      return;
    if (!mounted) return;
    if (!_pickup && _address == null) {
      showBergenToast(context, KasseCopy.a1_kasse_velg_adresse_forst);
      return;
    }
    final min = _preview?.minOrderAmount ?? 0;
    if (!_pickup && min > 0 && cart.subtotal < min) {
      showBergenToast(context, KasseCopy.a1_kasse_min_ordre(KasseCopy.kr(min)));
      return;
    }
    if (_paymentType == 2) {
      // The card path is the existing Stripe checkout, unchanged.
      prefSetString(prefTip, '$_tip');
      openScreen(context, const CheckOut());
      return;
    }
    setState(() => _placing = true);
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
    if (!mounted) return;
    if (response == null || response['status'] != 1) {
      setState(() => _placing = false);
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
        return;
      }
      showBergenToast(
        context,
        '${response?['message'] ?? BergenRoutes.kommerSnart}',
      );
      return;
    }
    final orderId = (response['order_id'] as num?)?.toInt() ?? 0;
    prefSetInt('bookedOrderId', orderId);
    if (_codeAtDoor && orderId > 0) {
      await _customer.requestCode(orderId);
    }
    final url = orderId > 0 ? await _api.vippsRedirect(orderId) : null;
    if (!mounted) return;
    setState(() => _placing = false);
    if (url == null) {
      showBergenToast(context, 'Vipps');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showBergenToast(context, 'Vipps');
    }
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final bottom = widget.embedded
        ? bergenNavReserve(context)
        : MediaQuery.paddingOf(context).bottom + 12 * s;
    final cart = _cart;

    return Scaffold(
      backgroundColor: BergenTokens.paper,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: bottom + 90 * s),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _Seilas(
                safeTop: safeTop,
                embedded: widget.embedded,
                pickup: _pickup,
                onMode: (m) => setState(() => _pickup = m),
                hasCart: !(cart?.isEmpty ?? true),
              ),
              if (cart == null)
                Padding(
                  padding: EdgeInsets.all(30 * s),
                  child: const Center(
                    child: CircularProgressIndicator(color: BergenTokens.teal),
                  ),
                )
              else if (cart.isEmpty)
                _Empty(
                  onBrowse: () {
                    final shell = context
                        .findAncestorStateOfType<HomeMainV1State>();
                    if (shell != null) {
                      shell.switchToTab(0);
                    } else {
                      BergenRoutes.push(context, '/bergen/utforsk');
                    }
                  },
                )
              else ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
                  child: BergenCard(
                    key: const Key('a1_kasse_linjer'),
                    padding: EdgeInsets.all(12 * s),
                    child: Column(
                      children: [
                        for (final l in cart.lines)
                          _Line(
                            line: l,
                            onMinus: () => _changeQty(l, -1),
                            onPlus: () => _changeQty(l, 1),
                            onRemove: () => _remove(l),
                          ),
                        SizedBox(height: 4 * s),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => BergenRoutes.push(
                            context,
                            '/bergen/butikk/${cart.storeId}',
                            arguments: {'name': _preview?.storeName ?? ''},
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18 * s,
                                color: BergenTokens.teal,
                              ),
                              SizedBox(width: 8 * s),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      KasseCopy.a1_kasse_legg_mer,
                                      style: bText(
                                        context,
                                        12.5,
                                        weight: FontWeight.w800,
                                        color: BergenTokens.ink,
                                      ),
                                    ),
                                    Text(
                                      KasseCopy.a1_kasse_glemte_drikke,
                                      style: bText(
                                        context,
                                        11,
                                        weight: FontWeight.w600,
                                        color: BergenTokens.inkFaint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18 * s,
                                color: BergenTokens.inkFaint,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Endre rows ─────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
                  child: BergenCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * s,
                      vertical: 4 * s,
                    ),
                    child: Column(
                      children: [
                        _EndreRow(
                          keyName: 'a1_kasse_rad_adresse',
                          icon: _pickup
                              ? Icons.storefront_rounded
                              : Icons.place_rounded,
                          title: _pickup
                              ? KasseCopy.a1_kasse_hent_tittel
                              : KasseCopy.a1_kasse_adr_tittel,
                          line: _pickup
                              ? (_preview?.storeAddress ??
                                    _preview?.storeName ??
                                    '')
                              : (_address?.address?.split(',').first ??
                                    KasseCopy.a1_kasse_adr_velg),
                          action: _pickup
                              ? KasseCopy.a1_kasse_se_kart
                              : KasseCopy.a1_kasse_endre,
                          onTap: _pickup
                              ? () => showBergenToast(
                                  context,
                                  BergenRoutes.kommerSnart,
                                )
                              : _openAddress,
                        ),
                        _EndreRow(
                          keyName: 'a1_kasse_rad_tid',
                          icon: Icons.schedule_rounded,
                          title: (_slot ?? _slots.first).label,
                          line: (_slot ?? _slots.first).line,
                          action: KasseCopy.a1_kasse_endre,
                          onTap: _openLevering,
                        ),
                        _EndreRow(
                          keyName: 'a1_kasse_rad_betaling',
                          icon: Icons.account_balance_wallet_rounded,
                          title: _paymentType == 3
                              ? KasseCopy.a1_kasse_vipps
                              : KasseCopy.a1_kasse_kort,
                          line: KasseCopy.a1_kasse_betaling_ved,
                          action: KasseCopy.a1_kasse_endre,
                          onTap: _openBetaling,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── note + more ────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
                  child: BergenCard(
                    padding: EdgeInsets.all(12 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pickup
                              ? KasseCopy.a1_kasse_beskjed_butikk
                              : KasseCopy.a1_kasse_beskjed_bud,
                          style: bText(
                            context,
                            11,
                            weight: FontWeight.w800,
                            color: BergenTokens.inkFaint,
                          ),
                        ),
                        TextField(
                          key: const Key('a1_kasse_beskjed'),
                          controller: _note,
                          maxLines: 2,
                          minLines: 1,
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w600,
                            color: BergenTokens.ink,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: KasseCopy.a1_kasse_beskjed_hint,
                            hintStyle: bText(
                              context,
                              13,
                              weight: FontWeight.w600,
                              color: BergenTokens.inkFaint,
                            ),
                          ),
                        ),
                        SizedBox(height: 8 * s),
                        GestureDetector(
                          key: const Key('a1_kasse_flere'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _more = !_more),
                          child: Row(
                            children: [
                              Text(
                                KasseCopy.a1_kasse_flere_valg,
                                style: bText(
                                  context,
                                  12,
                                  weight: FontWeight.w800,
                                  color: BergenTokens.teal,
                                ),
                              ),
                              Icon(
                                _more
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 18 * s,
                                color: BergenTokens.teal,
                              ),
                            ],
                          ),
                        ),
                        if (_more) ...[
                          SizedBox(height: 10 * s),
                          // Tips (delivery only).
                          if (!_pickup) ...[
                            Text(
                              KasseCopy.a1_kasse_tips_title,
                              style: bText(
                                context,
                                12.5,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                            SizedBox(height: 6 * s),
                            Wrap(
                              spacing: 8 * s,
                              children: [
                                for (final t in const [0, 15, 25, 40])
                                  BergenChip(
                                    key: Key('a1_kasse_tips_$t'),
                                    label: '$t kr',
                                    selected: _tip == t,
                                    onTap: () => setState(() => _tip = t),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4 * s),
                            Text(
                              KasseCopy.a1_kasse_tips_line,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w600,
                                color: BergenTokens.inkFaint,
                              ),
                            ),
                            SizedBox(height: 12 * s),
                            // Door note + Tolk (C4, agil-3).
                            Text(
                              KasseCopy.a1_kasse_doren,
                              style: bText(
                                context,
                                10,
                                weight: FontWeight.w800,
                                color: BergenTokens.inkFaint,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const Key('a1_kasse_dor'),
                                    controller: _door,
                                    style: bText(
                                      context,
                                      13,
                                      weight: FontWeight.w600,
                                      color: BergenTokens.ink,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: KasseCopy.a1_kasse_doren_hint,
                                      hintStyle: bText(
                                        context,
                                        13,
                                        weight: FontWeight.w600,
                                        color: BergenTokens.inkFaint,
                                      ),
                                    ),
                                  ),
                                ),
                                BergenChip(
                                  key: const Key('a1_kasse_tolk'),
                                  label: KasseCopy.a1_kasse_tolk,
                                  icon: Icons.translate_rounded,
                                  onTap: _tolk,
                                ),
                              ],
                            ),
                            SizedBox(height: 10 * s),
                            // Kode ved levering.
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        KasseCopy.a1_kasse_kode,
                                        style: bText(
                                          context,
                                          12.5,
                                          weight: FontWeight.w800,
                                          color: BergenTokens.ink,
                                        ),
                                      ),
                                      Text(
                                        KasseCopy.a1_kasse_kode_line,
                                        style: bText(
                                          context,
                                          10.5,
                                          weight: FontWeight.w600,
                                          color: BergenTokens.inkFaint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  key: const Key('a1_kasse_kode_switch'),
                                  value: _codeAtDoor,
                                  activeThumbColor: BergenTokens.orange,
                                  onChanged: (v) =>
                                      setState(() => _codeAtDoor = v),
                                ),
                              ],
                            ),
                            SizedBox(height: 6 * s),
                            // Gift recipient.
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    KasseCopy.a1_kasse_gave_til,
                                    style: bText(
                                      context,
                                      12.5,
                                      weight: FontWeight.w800,
                                      color: BergenTokens.ink,
                                    ),
                                  ),
                                ),
                                Switch(
                                  key: const Key('a1_kasse_gave_switch'),
                                  value: _gift,
                                  activeThumbColor: BergenTokens.orange,
                                  onChanged: (v) => setState(() => _gift = v),
                                ),
                              ],
                            ),
                            if (_gift) ...[
                              TextField(
                                key: const Key('a1_kasse_gave_navn'),
                                controller: _giftName,
                                style: bText(
                                  context,
                                  13,
                                  weight: FontWeight.w600,
                                  color: BergenTokens.ink,
                                ),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: KasseCopy.a1_kasse_gave_navn_hint,
                                ),
                              ),
                              SizedBox(height: 8 * s),
                              Row(
                                children: [
                                  Expanded(
                                    child: _GiftMode(
                                      label: KasseCopy.a1_kasse_overrask,
                                      line: KasseCopy.a1_kasse_overrask_line,
                                      selected: _giftMode == 'overrask',
                                      onTap: () => setState(
                                        () => _giftMode = 'overrask',
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8 * s),
                                  Expanded(
                                    child: _GiftMode(
                                      label: KasseCopy.a1_kasse_si_fra,
                                      line: KasseCopy.a1_kasse_si_fra_line,
                                      selected: _giftMode == 'si_fra',
                                      onTap: () =>
                                          setState(() => _giftMode = 'si_fra'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            Text(
                              KasseCopy.a1_kasse_hentetid,
                              style: bText(
                                context,
                                12.5,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                            Text(
                              KasseCopy.a1_kasse_hentetid_line,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w600,
                                color: BergenTokens.inkFaint,
                              ),
                            ),
                            SizedBox(height: 6 * s),
                            Wrap(
                              spacing: 8 * s,
                              children: [
                                for (final slot in _slots)
                                  BergenChip(
                                    label: slot.label,
                                    selected:
                                        (_slot ?? _slots.first).id == slot.id,
                                    onTap: () => setState(() => _slot = slot),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                // ── SAMMENDRAG ─────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
                  child: _Summary(
                    cart: cart,
                    preview: _preview,
                    pickup: _pickup,
                    tip: _tip,
                    onUndoAegil: _undoAegil,
                  ),
                ),
                if (_undone.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 0),
                    child: BergenUndoPill(
                      message: KasseCopy.a1_kasse_angret,
                      onUndo: () async {
                        for (final l in _undone) {
                          await BergenCart.add(
                            context,
                            storeId: l.storeId,
                            productId: l.productId,
                            quantity: l.quantity,
                          );
                        }
                        setState(() => _undone = const []);
                        await _load();
                      },
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 0),
                  child: Text(
                    KasseCopy.a1_kasse_bergenske,
                    style: bText(
                      context,
                      10.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkFaint,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (cart != null && !cart.isEmpty)
            Positioned(
              left: 16 * s,
              right: 16 * s,
              bottom: bottom + 8 * s,
              child: BergenCta3d(
                key: const Key('a1_kasse_betal'),
                label: _placing
                    ? '…'
                    : KasseCopy.a1_kasse_betal(KasseCopy.kr(_total(cart))),
                icon: Icons.lock_rounded,
                onPressed: _placing ? null : _pay,
              ),
            ),
        ],
      ),
    );
  }

  double _total(KurvState cart) {
    final p = _preview;
    final delivery = _pickup ? 0.0 : (p?.deliveryCost ?? 0);
    final fees = (p?.taxCost ?? 0) + (p?.packagingCost ?? 0);
    final discount =
        (p?.discountCost ?? 0) +
        (p?.promocodeDiscount ?? 0) +
        (p?.referDiscount ?? 0);
    return (cart.subtotal + delivery + fees - discount + _tip).clamp(
      0,
      double.infinity,
    );
  }
}

// ── pieces ────────────────────────────────────────────────────────────────

class _Seilas extends StatelessWidget {
  const _Seilas({
    required this.safeTop,
    required this.embedded,
    required this.pickup,
    required this.onMode,
    required this.hasCart,
  });

  final double safeTop;
  final bool embedded;
  final bool pickup;
  final ValueChanged<bool> onMode;
  final bool hasCart;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: const Key('a1_kasse_seilas'),
      padding: EdgeInsets.fromLTRB(16 * s, safeTop + 10 * s, 16 * s, 14 * s),
      decoration: const BoxDecoration(gradient: kBergenScreenGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!embedded)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: EdgeInsets.only(right: 10 * s),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22 * s,
                    ),
                  ),
                ),
              Text(
                KasseCopy.a1_kasse_bryggen,
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w800,
                  color: const Color(0xFF9FD3DE),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0x40FFFFFF),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      AnimatedAlign(
                        duration: BergenTokens.motion(
                          context,
                          const Duration(milliseconds: 900),
                        ),
                        curve: Curves.easeInOut,
                        alignment: hasCart
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Icon(
                          Icons.sailing_rounded,
                          size: 20 * s,
                          color: BergenTokens.lantern,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                KasseCopy.a1_kasse_kassen,
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * s),
          Text(
            KasseCopy.a1_kasse_ror,
            style: bText(
              context,
              10.5,
              weight: FontWeight.w600,
              color: const Color(0xFFDCE9EC),
            ),
          ),
          SizedBox(height: 12 * s),
          Container(
            padding: EdgeInsets.all(3 * s),
            decoration: BoxDecoration(
              color: const Color(0x47000000),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              children: [
                for (final (m, label) in [
                  (false, KasseCopy.a1_kasse_levering),
                  (true, KasseCopy.a1_kasse_henting),
                ])
                  Expanded(
                    child: GestureDetector(
                      key: Key(m ? 'a1_kasse_henting' : 'a1_kasse_levering'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onMode(m),
                      child: AnimatedContainer(
                        duration: BergenTokens.motion(
                          context,
                          BergenTokens.motionFast,
                        ),
                        height: 36 * s,
                        decoration: BoxDecoration(
                          gradient: pickup == m ? kBergenOrangeGradient : null,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: bText(
                            context,
                            12,
                            weight: FontWeight.w800,
                            color: pickup == m
                                ? Colors.white
                                : const Color(0xB3FFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 0),
      child: BergenCard(
        key: const Key('a1_kasse_tom'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  BergenAssets.aegilPopup,
                  width: 44 * s,
                  height: 44 * s,
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        KasseCopy.a1_kasse_tom_kicker,
                        style: bText(
                          context,
                          10,
                          weight: FontWeight.w800,
                          color: BergenTokens.teal,
                        ),
                      ),
                      Text(
                        KasseCopy.a1_kasse_tom_title,
                        style: bDisplay(
                          context,
                          16,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            BergenCta3d(label: KasseCopy.a1_kasse_tom_cta, onPressed: onBrowse),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.line,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  final KurvLine line;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * s),
      child: Row(
        key: Key('a1_kasse_linje_${line.cartId}'),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12 * s),
            child: SizedBox(
              width: 48 * s,
              height: 48 * s,
              child: line.imageUrl != null
                  ? Image.network(
                      line.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFE9E2D2)),
                    )
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF6D9B4), Color(0xFFD2854A)],
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bText(
                    context,
                    13,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
                Text(
                  KasseCopy.kr(line.sum),
                  style: bText(
                    context,
                    12,
                    weight: FontWeight.w700,
                    color: BergenTokens.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: BergenTokens.paperBright,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: BergenTokens.paperWarm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  key: Key('a1_kasse_minus_${line.cartId}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: line.quantity > 1 ? onMinus : onRemove,
                  child: SizedBox(
                    width: 34 * s,
                    height: 34 * s,
                    child: Icon(
                      line.quantity > 1
                          ? Icons.remove_rounded
                          : Icons.delete_outline_rounded,
                      size: 16 * s,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
                Text(
                  '${line.quantity}',
                  style: bText(
                    context,
                    13,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
                GestureDetector(
                  key: Key('a1_kasse_plus_${line.cartId}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onPlus,
                  child: SizedBox(
                    width: 34 * s,
                    height: 34 * s,
                    child: Icon(
                      Icons.add_rounded,
                      size: 16 * s,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndreRow extends StatelessWidget {
  const _EndreRow({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.line,
    required this.action,
    required this.onTap,
    this.last = false,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String line;
  final String action;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      key: Key(keyName),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * s),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: BergenTokens.paperWarm)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18 * s, color: BergenTokens.teal),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bText(
                      context,
                      13,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  if (line.isNotEmpty)
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bText(
                        context,
                        11,
                        weight: FontWeight.w600,
                        color: BergenTokens.inkFaint,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              action,
              style: bText(
                context,
                12,
                weight: FontWeight.w800,
                color: BergenTokens.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftMode extends StatelessWidget {
  const _GiftMode({
    required this.label,
    required this.line,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String line;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10 * s),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1FF26D3D) : BergenTokens.paperBright,
          borderRadius: BorderRadius.circular(14 * s),
          border: Border.all(
            color: selected ? BergenTokens.orange : BergenTokens.paperWarm,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: bText(
                context,
                12,
                weight: FontWeight.w800,
                color: BergenTokens.ink,
              ),
            ),
            Text(
              line,
              style: bText(
                context,
                10,
                weight: FontWeight.w600,
                color: BergenTokens.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.cart,
    required this.preview,
    required this.pickup,
    required this.tip,
    required this.onUndoAegil,
  });

  final KurvState cart;
  final OrderPreviewPojo? preview;
  final bool pickup;
  final int tip;
  final VoidCallback onUndoAegil;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final p = preview;
    final delivery = pickup ? 0.0 : (p?.deliveryCost ?? 0);
    final fees = (p?.taxCost ?? 0) + (p?.packagingCost ?? 0);
    final discount =
        (p?.discountCost ?? 0) +
        (p?.promocodeDiscount ?? 0) +
        (p?.referDiscount ?? 0);
    final total = (cart.subtotal + delivery + fees - discount + tip).clamp(
      0.0,
      double.infinity,
    );
    final aegil = cart.aegilLines;
    Widget row(String label, String value, {Key? key, Color? color}) => Padding(
      padding: EdgeInsets.symmetric(vertical: 3 * s),
      child: Row(
        key: key,
        children: [
          Expanded(
            child: Text(
              label,
              style: bText(
                context,
                12.5,
                weight: FontWeight.w600,
                color: BergenTokens.inkSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: bText(
              context,
              12.5,
              weight: FontWeight.w800,
              color: color ?? BergenTokens.ink,
            ),
          ),
        ],
      ),
    );
    return BergenCard(
      key: const Key('a1_kasse_sammendrag'),
      padding: EdgeInsets.all(14 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KasseCopy.a1_kasse_sammendrag,
            style: bText(
              context,
              10,
              weight: FontWeight.w800,
              color: BergenTokens.inkFaint,
            ),
          ),
          SizedBox(height: 6 * s),
          row(KasseCopy.a1_kasse_varer, KasseCopy.kr(cart.subtotal)),
          if (!pickup)
            row(
              KasseCopy.a1_kasse_frakt,
              delivery == 0
                  ? KasseCopy.a1_kasse_frakt_fri
                  : KasseCopy.kr(delivery),
              key: const Key('a1_kasse_frakt'),
              color: delivery == 0 ? BergenTokens.success : null,
            ),
          if (fees > 0) row(KasseCopy.a1_kasse_avgifter, KasseCopy.kr(fees)),
          if (discount > 0)
            row(
              KasseCopy.a1_kasse_rabatt,
              '−${KasseCopy.kr(discount)}',
              color: BergenTokens.success,
            ),
          if (tip > 0)
            row(
              KasseCopy.a1_kasse_tips_rad,
              KasseCopy.kr(tip),
              key: const Key('a1_kasse_tips_rad'),
            ),
          if (aegil.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6 * s),
              child: Row(
                key: const Key('a1_kasse_aegil_linjer'),
                children: [
                  Expanded(
                    child: Text(
                      KasseCopy.a1_kasse_aegil_linjer(
                        aegil.map((l) => l.name).join(', '),
                        KasseCopy.kr(
                          aegil.fold<double>(0, (a, l) => a + l.sum),
                        ),
                      ),
                      style: bText(
                        context,
                        11.5,
                        weight: FontWeight.w700,
                        color: BergenTokens.teal,
                      ),
                    ),
                  ),
                  GestureDetector(
                    key: const Key('a1_kasse_aegil_angre'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onUndoAegil,
                    child: Text(
                      KasseCopy.a1_kasse_angre,
                      style: bText(
                        context,
                        12,
                        weight: FontWeight.w800,
                        color: BergenTokens.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Divider(color: BergenTokens.paperWarm, height: 18 * s),
          Text(
            KasseCopy.a1_kasse_a_betale,
            style: bText(
              context,
              10,
              weight: FontWeight.w800,
              color: BergenTokens.inkFaint,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  KasseCopy.a1_kasse_totalt,
                  style: bDisplay(
                    context,
                    16,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
              ),
              Text(
                KasseCopy.kr(total),
                key: const Key('a1_kasse_total'),
                style: bDisplay(
                  context,
                  22,
                  weight: FontWeight.w800,
                  color: BergenTokens.ink,
                ),
              ),
            ],
          ),
          Text(
            KasseCopy.a1_kasse_inkl,
            style: bText(
              context,
              10.5,
              weight: FontWeight.w600,
              color: BergenTokens.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
