import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/helpAndSupport/contact_us_screen.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'sporing_copy.dart';

/// The Hjelp sheet (`sheetHjelp` ≈L7000–7130 in `Ærend Kunde Bergen.dc.html`)
/// at `/bergen/sporing/{id}/hjelp`, and **Kundeservice** standalone at
/// `/bergen/kundeservice` (the same body with no order attached).
///
/// States: main (the contact card — courier or store by `delivery_actor` —
/// with Ring / Send melding, and the common questions), **Ring
/// {{ kontaktRolle }}** (`ops.customer.contact kind=call` → the relay
/// record; with no provider the masked number is dialled), **Melding til
/// {{ kontaktRolle }}** (`kind=message`), **Finner ikke døra**
/// (`problem kind=door`), **Noe mangler** (`kind=missing`), **Kundeservice**
/// (hours, chat, 55 00 12 34) and **Bekreftet**.
enum HjelpState { main, ring, melding, dor, mangler, kundeservice, sendt }

class HjelpScreen extends StatefulWidget {
  const HjelpScreen({
    super.key,
    this.orderId,
    this.tracking,
    this.api,
    this.initial = HjelpState.main,
    this.items = const [],
  });

  final int? orderId;

  /// The last tracking payload, when the Sporing screen opens the sheet.
  final OpsTracking? tracking;
  final OpsCustomerApi? api;
  final HjelpState initial;

  /// The order's line names for "Noe mangler".
  final List<String> items;

  @override
  State<HjelpScreen> createState() => _HjelpScreenState();
}

class _HjelpScreenState extends State<HjelpScreen> {
  late HjelpState _state = widget.initial;
  OpsTracking? _tracking;
  int _id = 0;
  bool _routeRead = false;
  String? _proxyNumber;
  bool _calling = false;
  bool _muted = false;
  bool _speaker = false;
  int _callSeconds = 0;
  Timer? _callTimer;
  final List<(bool, String)> _thread = [];
  bool _typing = false;
  final TextEditingController _msg = TextEditingController();
  final TextEditingController _door = TextEditingController();
  final Set<String> _missing = {};
  String _sentTitle = '';
  String _sentText = '';

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  bool get _standalone => _id == 0;
  OpsTracking? get t => _tracking;
  bool get _partner => t?.isPartner ?? false;
  String get _rolle =>
      _partner ? SporingCopy.a1_sporing_butikken : SporingCopy.a1_sporing_bud;
  String get _navn => _partner
      ? (t?.store?.name ?? SporingCopy.a1_sporing_Butikken)
      : (t?.courier?.firstName ?? SporingCopy.a1_sporing_Budet);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _id =
        widget.orderId ??
        int.tryParse(args['id'] ?? args['order_id'] ?? '') ??
        0;
    _tracking = widget.tracking;
    if (_tracking == null && _id > 0) _load();
    if (_standalone) _state = HjelpState.kundeservice;
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _msg.dispose();
    _door.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final json = await _api.tracking(_id);
      if (mounted) setState(() => _tracking = OpsTracking.fromJson(json));
    } catch (_) {
      // The sheet still works without the payload: the store card and the
      // common questions do not need it.
    }
  }

  // ── actions ────────────────────────────────────────────────────────────

  Future<void> _ring() async {
    setState(() {
      _state = HjelpState.ring;
      _calling = true;
      _callSeconds = 0;
    });
    final res = await _api.contact(_id, kind: 'call');
    if (!mounted) return;
    setState(() {
      _calling = false;
      _proxyNumber = res?['proxy_number']?.toString();
    });
    if (_proxyNumber != null) {
      _callTimer?.cancel();
      _callTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() => _callSeconds++) : null,
      );
      final uri = Uri.parse('tel:$_proxyNumber');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  void _endCall() {
    _callTimer?.cancel();
    setState(() => _state = HjelpState.main);
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _msg.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _thread.add((true, text));
      _msg.clear();
      _typing = true;
    });
    final res = await _api.contact(_id, kind: 'message', message: text);
    if (!mounted) return;
    setState(() {
      _typing = false;
      if (res != null)
        _thread.add((false, SporingCopy.a1_sporing_sendt_tekst(_navn)));
    });
    if (res == null) showBergenToast(context, BergenRoutes.kommerSnart);
  }

  Future<void> _sendDoor() async {
    final words = _door.text.trim();
    final res = await _api.problem(
      _id,
      kind: 'door',
      words: words.isEmpty ? null : words,
    );
    if (!mounted) return;
    if (res == null) {
      showBergenToast(context, BergenRoutes.kommerSnart);
      return;
    }
    setState(() {
      _sentTitle = SporingCopy.a1_sporing_sendt_tittel;
      _sentText = SporingCopy.a1_sporing_sendt_tekst(_navn);
      _state = HjelpState.sendt;
    });
  }

  Future<void> _sendMissing() async {
    if (_missing.isEmpty) return;
    final res = await _api.problem(
      _id,
      kind: 'missing',
      items: _missing.toList(),
    );
    if (!mounted) return;
    if (res == null) {
      showBergenToast(context, BergenRoutes.kommerSnart);
      return;
    }
    setState(() {
      _sentTitle = SporingCopy.a1_sporing_meldt_tittel;
      _sentText = SporingCopy.a1_sporing_mangler_refusjon;
      _state = HjelpState.sendt;
    });
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: BergenTokens.paper,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16 * s, safeTop + 10 * s, 16 * s, 0),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_state == HjelpState.main || _standalone) {
                      Navigator.of(context).maybePop();
                    } else {
                      setState(() => _state = HjelpState.main);
                    }
                  },
                  child: Container(
                    width: 40 * s,
                    height: 40 * s,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: BergenTokens.paperWarm),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20 * s,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
                SizedBox(width: 10 * s),
                Expanded(
                  child: Text(
                    _title,
                    key: const Key('a1_sporing_hjelp_tittel'),
                    style: bDisplay(
                      context,
                      20,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: BergenTokens.motion(context, BergenTokens.motionFast),
              child: KeyedSubtree(key: ValueKey(_state), child: _body(context)),
            ),
          ),
        ],
      ),
    );
  }

  String get _title => switch (_state) {
    HjelpState.main => SporingCopy.a1_sporing_hjelp,
    HjelpState.ring => SporingCopy.a1_sporing_hjelp_ring(_rolle),
    HjelpState.melding => SporingCopy.a1_sporing_hjelp_melding(_rolle),
    HjelpState.dor => SporingCopy.a1_sporing_hjelp_dor,
    HjelpState.mangler => SporingCopy.a1_sporing_hva_mangler,
    HjelpState.kundeservice => SporingCopy.a1_sporing_ks_tittel,
    HjelpState.sendt => _sentTitle,
  };

  Widget _body(BuildContext context) {
    final s = context.bs;
    switch (_state) {
      case HjelpState.main:
        return ListView(
          key: const Key('a1_sporing_hjelp_main'),
          padding: EdgeInsets.all(16 * s),
          children: [
            BergenCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44 * s,
                        height: 44 * s,
                        decoration: const BoxDecoration(
                          gradient: kBergenOrangeGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _partner
                              ? Icons.storefront_rounded
                              : Icons.pedal_bike_rounded,
                          color: Colors.white,
                          size: 22 * s,
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _navn,
                              key: const Key('a1_sporing_hjelp_kontakt'),
                              style: bDisplay(
                                context,
                                16,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                            Text(
                              _partner
                                  ? SporingCopy.a1_sporing_hjelp_kort_butikk
                                  : SporingCopy.a1_sporing_hjelp_kort_bud_enkel,
                              style: bText(
                                context,
                                11.5,
                                weight: FontWeight.w600,
                                color: BergenTokens.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * s),
                  Row(
                    children: [
                      Expanded(
                        child: BergenCta3d(
                          key: const Key('a1_sporing_hjelp_ring'),
                          label: SporingCopy.a1_sporing_hjelp_ring_kort,
                          icon: Icons.call_rounded,
                          onPressed: _id == 0 ? null : _ring,
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      Expanded(
                        child: BergenCta3d(
                          key: const Key('a1_sporing_hjelp_melding'),
                          label: SporingCopy.a1_sporing_hjelp_send,
                          icon: Icons.chat_bubble_outline_rounded,
                          onPressed: _id == 0
                              ? null
                              : () =>
                                    setState(() => _state = HjelpState.melding),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16 * s),
            Text(
              SporingCopy.a1_sporing_hjelp_vanlige,
              style: bText(
                context,
                10,
                weight: FontWeight.w800,
                color: BergenTokens.inkFaint,
              ),
            ),
            SizedBox(height: 8 * s),
            _Row(
              keyName: 'a1_sporing_hjelp_dor',
              icon: Icons.door_front_door_outlined,
              title: SporingCopy.a1_sporing_hjelp_dor,
              line: SporingCopy.a1_sporing_hjelp_dor_line,
              onTap: () => setState(() => _state = HjelpState.dor),
            ),
            _Row(
              keyName: 'a1_sporing_hjelp_mangler',
              icon: Icons.inventory_2_outlined,
              title: SporingCopy.a1_sporing_hjelp_mangler,
              line: SporingCopy.a1_sporing_hjelp_mangler_line,
              onTap: () => setState(() => _state = HjelpState.mangler),
            ),
            _Row(
              keyName: 'a1_sporing_hjelp_ks',
              icon: Icons.support_agent_rounded,
              title: SporingCopy.a1_sporing_hjelp_kundeservice,
              line: SporingCopy.a1_sporing_hjelp_kundeservice_line,
              onTap: () => setState(() => _state = HjelpState.kundeservice),
            ),
          ],
        );
      case HjelpState.ring:
        final mm = (_callSeconds ~/ 60).toString().padLeft(2, '0');
        final ss = (_callSeconds % 60).toString().padLeft(2, '0');
        return Padding(
          key: const Key('a1_sporing_hjelp_ring_state'),
          padding: EdgeInsets.all(24 * s),
          child: Column(
            children: [
              SizedBox(height: 24 * s),
              Container(
                width: 96 * s,
                height: 96 * s,
                decoration: const BoxDecoration(
                  gradient: kBergenOrangeGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _navn.isEmpty ? 'B' : _navn[0].toUpperCase(),
                    style: bDisplay(
                      context,
                      40,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              Text(
                _navn,
                style: bDisplay(
                  context,
                  22,
                  weight: FontWeight.w800,
                  color: BergenTokens.ink,
                ),
              ),
              SizedBox(height: 4 * s),
              Text(
                _calling
                    ? SporingCopy.a1_sporing_ring_kobler
                    : (_proxyNumber == null
                          ? SporingCopy.a1_sporing_ring_ingen
                          : '$mm:$ss'),
                key: const Key('a1_sporing_ring_status'),
                style: bText(
                  context,
                  13,
                  weight: FontWeight.w700,
                  color: BergenTokens.inkSecondary,
                ),
              ),
              if (_proxyNumber != null) ...[
                SizedBox(height: 6 * s),
                Text(
                  _proxyNumber!,
                  key: const Key('a1_sporing_ring_nummer'),
                  style: bText(
                    context,
                    13,
                    weight: FontWeight.w800,
                    color: BergenTokens.teal,
                  ),
                ),
                Text(
                  SporingCopy.a1_sporing_ring_maskert,
                  textAlign: TextAlign.center,
                  style: bText(
                    context,
                    10.5,
                    weight: FontWeight.w600,
                    color: BergenTokens.inkFaint,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Round(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: SporingCopy.a1_sporing_demp,
                    active: _muted,
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  _Round(
                    icon: Icons.call_end_rounded,
                    label: SporingCopy.a1_sporing_avslutt_samtale,
                    danger: true,
                    onTap: _endCall,
                    keyName: 'a1_sporing_ring_avslutt',
                  ),
                  _Round(
                    icon: Icons.volume_up_rounded,
                    label: SporingCopy.a1_sporing_hoyttaler,
                    active: _speaker,
                    onTap: () => setState(() => _speaker = !_speaker),
                  ),
                ],
              ),
              SizedBox(height: 16 * s),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _endCall,
                child: Text(
                  SporingCopy.a1_sporing_tilbake,
                  style: bText(
                    context,
                    12,
                    weight: FontWeight.w800,
                    color: BergenTokens.teal,
                  ),
                ),
              ),
            ],
          ),
        );
      case HjelpState.melding:
        return Column(
          key: const Key('a1_sporing_hjelp_melding_state'),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      SporingCopy.a1_sporing_aktiv,
                      style: bText(
                        context,
                        11,
                        weight: FontWeight.w700,
                        color: BergenTokens.mintDeep,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _ring,
                    child: Icon(
                      Icons.call_rounded,
                      color: BergenTokens.teal,
                      size: 20 * s,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16 * s),
                children: [
                  for (final (mine, text) in _thread)
                    Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8 * s),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * s,
                          vertical: 8 * s,
                        ),
                        constraints: BoxConstraints(maxWidth: 260 * s),
                        decoration: BoxDecoration(
                          color: mine ? BergenTokens.teal : Colors.white,
                          borderRadius: BorderRadius.circular(16 * s),
                          border: Border.all(
                            color: mine
                                ? BergenTokens.teal
                                : BergenTokens.paperWarm,
                          ),
                        ),
                        child: Text(
                          text,
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w600,
                            color: mine ? Colors.white : BergenTokens.ink,
                          ),
                        ),
                      ),
                    ),
                  if (_typing)
                    Text(
                      SporingCopy.a1_sporing_skriver,
                      key: const Key('a1_sporing_skriver'),
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
            SizedBox(
              height: 40 * s,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                children: [
                  for (final q in SporingCopy.a1_sporing_hurtig)
                    Padding(
                      padding: EdgeInsets.only(right: 8 * s),
                      child: BergenChip(label: q, onTap: () => _send(q)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16 * s,
                8 * s,
                16 * s,
                MediaQuery.paddingOf(context).bottom + 12 * s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14 * s),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: BergenTokens.paperWarm),
                      ),
                      child: TextField(
                        key: const Key('a1_sporing_meld_felt'),
                        controller: _msg,
                        onSubmitted: (_) => _send(),
                        style: bText(
                          context,
                          13,
                          weight: FontWeight.w600,
                          color: BergenTokens.ink,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: SporingCopy.a1_sporing_meld_hint,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  BergenCta3d(
                    key: const Key('a1_sporing_meld_send'),
                    label: SporingCopy.a1_sporing_send,
                    expand: false,
                    onPressed: () => _send(),
                  ),
                ],
              ),
            ),
          ],
        );
      case HjelpState.dor:
        return ListView(
          key: const Key('a1_sporing_hjelp_dor_state'),
          padding: EdgeInsets.all(16 * s),
          children: [
            Text(
              SporingCopy.a1_sporing_dor_tittel(_navn),
              style: bText(
                context,
                12.5,
                weight: FontWeight.w700,
                color: BergenTokens.inkSecondary,
              ),
            ),
            SizedBox(height: 12 * s),
            Text(
              SporingCopy.a1_sporing_lev_adresse,
              style: bText(
                context,
                10,
                weight: FontWeight.w800,
                color: BergenTokens.inkFaint,
              ),
            ),
            Text(
              '${t?.raw['delivery_address'] ?? t?.store?.address ?? ''}',
              style: bText(
                context,
                14,
                weight: FontWeight.w800,
                color: BergenTokens.ink,
              ),
            ),
            SizedBox(height: 12 * s),
            Text(
              SporingCopy.a1_sporing_veibeskrivelse,
              style: bText(
                context,
                10,
                weight: FontWeight.w800,
                color: BergenTokens.inkFaint,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * s,
                vertical: 8 * s,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14 * s),
                border: Border.all(color: BergenTokens.paperWarm),
              ),
              child: TextField(
                key: const Key('a1_sporing_dor_felt'),
                controller: _door,
                maxLines: 3,
                style: bText(
                  context,
                  13,
                  weight: FontWeight.w600,
                  color: BergenTokens.ink,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: SporingCopy.a1_sporing_dor_hint,
                ),
              ),
            ),
            SizedBox(height: 12 * s),
            BergenCta3d(
              key: const Key('a1_sporing_dor_send'),
              label: SporingCopy.a1_sporing_send_til(_navn),
              onPressed: _sendDoor,
            ),
            SizedBox(height: 8 * s),
            Row(
              children: [
                Expanded(
                  child: BergenChip(
                    label: SporingCopy.a1_sporing_ring_navn(_navn),
                    icon: Icons.call_rounded,
                    onTap: _ring,
                  ),
                ),
                SizedBox(width: 8 * s),
                Expanded(
                  child: BergenChip(
                    label: SporingCopy.a1_sporing_skriv_selv,
                    icon: Icons.edit_outlined,
                    onTap: () => setState(() => _state = HjelpState.melding),
                  ),
                ),
              ],
            ),
          ],
        );
      case HjelpState.mangler:
        final items = widget.items.isEmpty ? _itemsFromTracking : widget.items;
        return ListView(
          key: const Key('a1_sporing_hjelp_mangler_state'),
          padding: EdgeInsets.all(16 * s),
          children: [
            Text(
              SporingCopy.a1_sporing_mangler_line,
              style: bText(
                context,
                12.5,
                weight: FontWeight.w700,
                color: BergenTokens.inkSecondary,
              ),
            ),
            SizedBox(height: 12 * s),
            Wrap(
              spacing: 8 * s,
              runSpacing: 8 * s,
              children: [
                for (final i in items)
                  BergenChip(
                    key: Key('a1_sporing_mangler_$i'),
                    label: i,
                    selected: _missing.contains(i),
                    onTap: () => setState(
                      () => _missing.contains(i)
                          ? _missing.remove(i)
                          : _missing.add(i),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12 * s),
            Text(
              SporingCopy.a1_sporing_mangler_refusjon,
              style: bText(
                context,
                11.5,
                weight: FontWeight.w600,
                color: BergenTokens.inkFaint,
              ),
            ),
            SizedBox(height: 12 * s),
            BergenCta3d(
              key: const Key('a1_sporing_mangler_send'),
              label: SporingCopy.a1_sporing_meld_mangler(_missing.length),
              onPressed: _missing.isEmpty ? null : _sendMissing,
            ),
          ],
        );
      case HjelpState.kundeservice:
        return ListView(
          key: const Key('a1_sporing_kundeservice'),
          padding: EdgeInsets.all(16 * s),
          children: [
            Text(
              SporingCopy.a1_sporing_ks_line,
              style: bText(
                context,
                12.5,
                weight: FontWeight.w700,
                color: BergenTokens.inkSecondary,
              ),
            ),
            SizedBox(height: 12 * s),
            _Row(
              keyName: 'a1_sporing_ks_chat',
              icon: Icons.chat_rounded,
              title: SporingCopy.a1_sporing_ks_chat,
              line: SporingCopy.a1_sporing_ks_chat_line,
              onTap: () => openScreen(context, const ContactUsScreen()),
            ),
            _Row(
              keyName: 'a1_sporing_ks_ring',
              icon: Icons.call_rounded,
              title: SporingCopy.a1_sporing_ks_ring,
              line: SporingCopy.a1_sporing_ks_ring_line,
              onTap: () async {
                final uri = Uri.parse(
                  'tel:${SporingCopy.a1_sporing_ks_nummer}',
                );
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            if (_id > 0) ...[
              SizedBox(height: 8 * s),
              Text(
                SporingCopy.a1_sporing_ks_ordre(t?.code ?? '$_id'),
                key: const Key('a1_sporing_ks_ordre'),
                style: bText(
                  context,
                  11.5,
                  weight: FontWeight.w600,
                  color: BergenTokens.inkFaint,
                ),
              ),
            ],
          ],
        );
      case HjelpState.sendt:
        return Padding(
          key: const Key('a1_sporing_hjelp_sendt'),
          padding: EdgeInsets.all(24 * s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72 * s,
                  height: 72 * s,
                  decoration: const BoxDecoration(
                    color: BergenTokens.mint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: BergenTokens.tealDeep,
                    size: 40 * s,
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              Text(
                _sentText,
                textAlign: TextAlign.center,
                style: bText(
                  context,
                  13.5,
                  weight: FontWeight.w600,
                  color: BergenTokens.inkSecondary,
                ),
              ),
              SizedBox(height: 20 * s),
              BergenCta3d(
                key: const Key('a1_sporing_hjelp_ferdig'),
                label: SporingCopy.a1_sporing_ferdig,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        );
    }
  }

  List<String> get _itemsFromTracking {
    final raw = t?.raw['items'];
    if (raw is List)
      return [
        for (final i in raw)
          if (i is Map) '${i['name'] ?? i['product_name'] ?? ''}',
      ].where((e) => e.isNotEmpty).toList();
    return const [];
  }
}

/// `/bergen/kundeservice` — the Kundeservice body with no order attached.
class KundeserviceScreen extends StatelessWidget {
  const KundeserviceScreen({super.key, this.api});

  final OpsCustomerApi? api;

  @override
  Widget build(BuildContext context) {
    final orderId = int.tryParse(
      BergenRoutes.argsOf(context)['order_id'] ?? '',
    );
    return HjelpScreen(
      key: const Key('a1_sporing_kundeservice_screen'),
      orderId: orderId,
      api: api,
      initial: HjelpState.kundeservice,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.line,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * s),
      child: BergenCard(
        key: Key(keyName),
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        child: Row(
          children: [
            Icon(icon, color: BergenTokens.teal, size: 20 * s),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: bText(
                      context,
                      13,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  Text(
                    line,
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
              color: BergenTokens.inkFaint,
              size: 20 * s,
            ),
          ],
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
    this.keyName,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      key: keyName == null ? null : Key(keyName!),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64 * s,
            height: 64 * s,
            decoration: BoxDecoration(
              color: danger
                  ? BergenTokens.danger
                  : (active ? BergenTokens.ink : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(color: BergenTokens.paperWarm),
            ),
            child: Icon(
              icon,
              color: danger || active ? Colors.white : BergenTokens.ink,
              size: 26 * s,
            ),
          ),
          SizedBox(height: 6 * s),
          Text(
            label,
            style: bText(
              context,
              11,
              weight: FontWeight.w700,
              color: BergenTokens.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
