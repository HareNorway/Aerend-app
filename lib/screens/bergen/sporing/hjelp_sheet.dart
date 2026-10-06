import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../snurre/snurre_launcher_policy.dart';
import '../hjelp/support.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_kit.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';

part 'hjelp_chat.dart';

/// The Hjelp sheet (Launch L8638–8830, `sheetHjelp`) at
/// `/bergen/sporing/{id}/hjelp`, and **Kundeservice** standalone at
/// `/bergen/kundeservice` (the same sheet opened on the support state).
///
/// The dark teal sheet rises over the screen beneath. States: main (the
/// contact card — courier or store by `delivery_actor` — with Ring / Send
/// melding, VANLIGE SPØRSMÅL), **Ring** (`ops.customer.contact kind=call` →
/// the relay record; with no provider the masked number is dialled),
/// **Melding** (`kind=message`), **Finner ikke døra** (`problem kind=door`),
/// **Noe mangler** / **Feil vare** / **Kom aldri** (the support chat, on the
/// order — Launch opens `scStart` for these), **Kundeservice**, **Bekreftet**,
/// the **support chat** (`hjChat`, L8775) and **Hjelp og kontakt**
/// (`hjIngenOrdre`, L8660 — the hub when no order is on its way).
///
/// [HjelpState.hub] on open means «Hjelp og kontakt» from Meg or Konto: the
/// sheet shows the active order's main state when one is on its way, the
/// hub otherwise (`hjHarOrdre` / `hjIngenOrdre`).
enum HjelpState { main, ring, melding, dor, mangler, feil, komAldri, kundeservice, sendt, chat, hub }

class HjelpScreen extends StatefulWidget {
  const HjelpScreen({super.key, this.orderId, this.tracking, this.api, this.initial = HjelpState.main, this.items = const [], this.adresse});

  final int? orderId;

  /// The last tracking payload, when the Sporing screen opens the sheet.
  final OpsTracking? tracking;
  final OpsCustomerApi? api;
  final HjelpState initial;

  /// Opens the sheet over the current screen (the screen stays visible
  /// behind the blur). [HjelpState.hub] is «Hjelp og kontakt» from Meg/Konto.
  static Future<void> apne(BuildContext context, {HjelpState initial = HjelpState.hub, int? orderId}) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        settings: const RouteSettings(name: '${snurreLauncherHiddenRoutePrefix}bergen/kundeservice'),
        transitionDuration: Duration(milliseconds: reduce ? 0 : 380),
        reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 260),
        pageBuilder: (_, __, ___) => HjelpScreen(orderId: orderId, initial: initial),
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

  /// The order's line names for «Noe mangler».
  final List<String> items;

  /// The delivery address (Finner ikke døra).
  final String? adresse;

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
  final List<(bool, String, String)> _thread = [];
  bool _typing = false;
  final TextEditingController _msg = TextEditingController();
  final TextEditingController _door = TextEditingController();
  List<String> _items = const [];
  String? _adresse;
  String _sentTitle = '';
  SupportSamtale? _samtale;
  bool _gjest = false;
  HjelpState _fraChat = HjelpState.main;

  /// This order's row from `ops.customer.orders`.
  Map<String, dynamic>? _ordreRad;
  String _sentText = '';
  final ScrollController _scroll = ScrollController();

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  bool get _standalone => _id == 0;
  OpsTracking? get t => _tracking;
  bool get _partner => t?.isPartner ?? false;
  String get _rolle => _partner ? SporingCopy.a1_sporing_butikken : SporingCopy.a1_sporing_bud;
  String get _rolleStor => _partner ? SporingCopy.a1_sporing_Butikken : SporingCopy.a1_sporing_Budet;
  String get _navn => _partner ? (t?.store?.name ?? SporingCopy.a1_sporing_Butikken) : (t?.courier?.firstName ?? SporingCopy.a1_sporing_Budet);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _id = widget.orderId ?? int.tryParse(args['id'] ?? args['order_id'] ?? '') ?? 0;
    _tracking = widget.tracking;
    _items = widget.items;
    // Cases go through the same API as the rest of the sheet.
    if (widget.api case final a?) SupportStore.instance.api = a;
    _adresse = widget.adresse;
    if (_tracking == null && _id > 0) _load();
    if (_id > 0 && (_items.isEmpty || _adresse == null)) _loadOrdre();
    final start = _state;
    if (_state == HjelpState.hub) {
      _velgStart();
    } else if (_standalone) {
      _state = HjelpState.kundeservice;
    }
    if (start == HjelpState.mangler || start == HjelpState.feil || start == HjelpState.komAldri || start == HjelpState.chat) {
      final tema = switch (start) {
        HjelpState.mangler => SupportTema.mangler,
        HjelpState.feil => SupportTema.feil,
        HjelpState.komAldri => SupportTema.komAldri,
        _ => SupportTema.support,
      };
      _state = _standalone ? HjelpState.kundeservice : HjelpState.main;
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _startChat(tema) : null);
    }
    _msg.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _msg.dispose();
    _door.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// «Hjelp og kontakt»: the order on its way, if any (`hjHarOrdre`), else
  /// the hub (`hjIngenOrdre`).
  Future<void> _velgStart() async {
    if (_id > 0) {
      _state = HjelpState.main;
      return;
    }
    if (kDebugMode && HjemHarness.hjelpHub) return;
    try {
      final rows = await _api.orders();
      final row = rows.where((r) => SupportOrdre.fraRad(r).aktiv).firstOrNull;
      if (!mounted) return;
      if (row == null) return;
      setState(() {
        _id = SupportOrdre.fraRad(row).id;
        _ordreRad = row;
        _state = HjelpState.main;
      });
      _load();
      _loadOrdre();
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final json = await _api.tracking(_id);
      if (mounted) setState(() => _tracking = OpsTracking.fromJson(json));
    } catch (_) {
      // The sheet still works without the payload.
    }
  }

  /// The order's lines and address when the opener did not pass them.
  Future<void> _loadOrdre() async {
    try {
      final list = await _api.orders();
      final row = list.cast<Map<String, dynamic>?>().firstWhere((o) => '${o?['order_id']}' == '$_id', orElse: () => null);
      if (!mounted || row == null) return;
      final rows = row['items'];
      setState(() {
        _ordreRad = row;
        if (_items.isEmpty && rows is List) {
          _items = [
            for (final r in rows)
              if (r is Map) '${r['name'] ?? r['product_name'] ?? ''}',
          ].where((n) => n.isNotEmpty).toList();
        }
        _adresse ??= row['delivery_address']?.toString();
      });
    } catch (_) {}
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
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() => _callSeconds++) : null);
    if (_proxyNumber != null) {
      final uri = Uri.parse('tel:$_proxyNumber');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  void _endCall() {
    _callTimer?.cancel();
    final s = _callSeconds;
    setState(() => _state = HjelpState.main);
    showBergenToast(context, '${SporingCopy.a1_sporing_avslutt_samtale} · ${spMmSs(s)}');
  }

  String get _kl => spKlokke(DateTime.now());

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _msg.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _thread.add((true, text, _kl));
      _msg.clear();
      _typing = true;
    });
    _scrollDown();
    final res = await _api.contact(_id, kind: 'message', message: text);
    if (!mounted) return;
    setState(() {
      _typing = false;
      if (res != null) _thread.add((false, SporingCopy.a1_sporing_sendt_tekst(_navn), _kl));
    });
    _scrollDown();
    if (res == null) showBergenToast(context, BergenRoutes.kommerSnart);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
    });
  }

  Future<void> _sendDoor() async {
    final words = _door.text.trim();
    final res = await _api.problem(_id, kind: 'door', words: words.isEmpty ? null : words);
    if (!mounted) return;
    if (res == null) {
      showBergenToast(context, BergenRoutes.kommerSnart);
      return;
    }
    setState(() {
      _sentTitle = SporingCopy.a1_sporing_fikk_beskjeden(_navn);
      _sentText = SporingCopy.a1_sporing_veibeskrivelse_sendt;
      _state = HjelpState.sendt;
    });
  }

  Future<void> _ringKs() async {
    final uri = Uri.parse('tel:${SporingCopy.a1_sporing_ks_nummer.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _supportChat() => _startChat(SupportTema.support);

  // ── support chat ────────────────────────────────────────────────────────

  String get _fornavn => prefGetString(prefUserName).trim().split(RegExp(r'\s+')).first;

  /// The order this sheet is about, as support sees it: its row, else what
  /// the opener passed (the tracking payload and the line names).
  SupportOrdre? get _ordre {
    if (_ordreRad case final r?) return SupportOrdre.fraRad(r);
    if (_id == 0) return null;
    return SupportOrdre(
      id: _id,
      kode: t?.code ?? 'Æ-$_id',
      butikk: t?.store?.name ?? '',
      total: 0,
      status: t?.stageLabel ?? SupportCopy.paaVei,
      linjer: _items,
      aktiv: (t?.stage ?? 3) < 3,
      levert: (t?.stage ?? 0) >= 3,
    );
  }

  /// The order a question is about: this sheet's, else the latest one on
  /// its way, else the latest one.
  Future<SupportOrdre?> _hentOrdre() async {
    if (_ordre case final o?) return o;
    try {
      final rows = await _api.orders();
      final ordrer = rows.map(SupportOrdre.fraRad).toList();
      return ordrer.where((o) => o.aktiv).firstOrNull ?? ordrer.firstOrNull;
    } catch (_) {
      return null;
    }
  }

  /// Opens the support chat on [tema] (`scStart`). Without a login the
  /// guest step comes first (`scApne(null, {gjest:true})`).
  Future<void> _startChat(SupportTema tema) async {
    await _startChatUten(tema);
    if (kDebugMode && mounted) _harness();
  }

  /// Step 13 harness (debug only): lines to send, a person, the guest step.
  Future<void> _harness() async {
    final si = HjemHarness.hjelpSi;
    final menneske = HjemHarness.hjelpMenneske;
    HjemHarness.hjelpSi = null;
    HjemHarness.hjelpMenneske = false;
    final s = _samtale;
    if (s == null) return;
    for (final t in si ?? const <String>[]) {
      await SupportAssistent.svar(s, t, hentOrdre: _hentOrdre, skriver: (_) {});
    }
    if (menneske) {
      await SupportAssistent.eskaler(s, skriver: (_) {});
      SupportAssistent.taOver(s, 'Kari N.', _fornavn);
    }
  }

  Future<void> _startChatUten(SupportTema tema) async {
    final fra = _state == HjelpState.chat ? _fraChat : (_state == HjelpState.mangler || _state == HjelpState.feil || _state == HjelpState.komAldri ? HjelpState.main : _state);
    if (OpsCustomerApi.authParams() == null || (kDebugMode && HjemHarness.hjelpGjest)) {
      HjemHarness.hjelpGjest = false;
      setState(() {
        _fraChat = fra;
        _gjest = true;
        _samtale = null;
        _state = HjelpState.chat;
      });
      return;
    }
    final o = tema == SupportTema.support ? null : (_ordre ?? await _hentOrdre());
    final s = await SupportAssistent.start(tema, fornavn: _fornavn, ordre: o);
    if (!mounted) return;
    setState(() {
      _fraChat = fra;
      _gjest = false;
      _samtale = s;
      _state = HjelpState.chat;
    });
  }

  /// A question from the hub (`hjSpor`): a new conversation that starts with it.
  Future<void> _spor(String t) async {
    await _startChatUten(SupportTema.support);
    final s = _samtale;
    if (s == null || !mounted) return;
    await SupportAssistent.svar(s, t, hentOrdre: _hentOrdre, skriver: (_) {});
  }

  void _lukk() => Navigator.of(context).maybePop();

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: LfFrame(
        child: Stack(
          children: [
            // The screen's one blur layer: the prototype blurs everything
            // behind the sheet (`backdrop-filter: blur(40px)`).
            Positioned.fill(
              child: GestureDetector(
                key: const Key('a1_sporing_hjelp_barriere'),
                behavior: HitTestBehavior.opaque,
                onTap: _lukk,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: ColoredBox(color: rgba(8, 24, 32, .45)),
                ),
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _ark(context)),
          ],
        ),
      ),
    );
  }

  Widget _ark(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bunn = math.max(mq.padding.bottom, mq.viewInsets.bottom);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: CssBox(
        radius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: EdgeInsets.fromLTRB(16, 0, 16, 22 + math.max(bunn - 8, 0)),
        border: Border(top: BorderSide(color: rgba(255, 255, 255, .9))),
        bg: const [
          CssLinear(180, [Color(0xFF27596A), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .55, 1]),
        ],
        shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .95)), CssShadow(0, -24, 50, -20, rgba(15, 31, 43, .55))],
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: mq.size.height * .86),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: rgba(255, 255, 255, .35), borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                AnimatedSize(
                  duration: BergenTokens.motion(context, const Duration(milliseconds: 240)),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: KeyedSubtree(key: ValueKey(_state), child: _body(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) => switch (_state) {
    HjelpState.main => _main(),
    HjelpState.ring => _ringState(),
    HjelpState.melding => _melding(),
    HjelpState.dor => _dor(),
    HjelpState.mangler || HjelpState.feil || HjelpState.komAldri || HjelpState.chat => _SupportChat(
      key: ValueKey('chat-${_samtale?.id}-$_gjest'),
      samtale: _samtale,
      gjest: _gjest,
      fornavn: _fornavn,
      hentOrdre: _hentOrdre,
      onTilbake: () => setState(() => _state = _fraChat),
      onGjestBekreftet: () async {
        final s = await SupportAssistent.start(SupportTema.support, fornavn: _fornavn);
        if (mounted) setState(() {
          _gjest = false;
          _samtale = s;
        });
      },
    ),
    HjelpState.hub => _Hub(
      onLukk: _lukk,
      onChat: () => _startChat(SupportTema.support),
      onFortsett: SupportStore.instance.aapen == null ? null : () => setState(() {
        _fraChat = HjelpState.hub;
        _samtale = SupportStore.instance.aapen;
        _gjest = false;
        _state = HjelpState.chat;
      }),
      onSpor: _spor,
    ),
    HjelpState.kundeservice => _support(),
    HjelpState.sendt => _sendt(),
  };

  // ── main ────────────────────────────────────────────────────────────────

  Widget _main() {
    final tr = t;
    final min = tr?.minutesLeft(DateTime.now());
    final under = [if (tr != null) tr.stageLabel, if (min != null && !(tr?.isPickup ?? false)) '$min min unna', if (!_partner && tr?.courier?.vehicle == 'sykkel') 'sykler'].join(' · ');
    return Column(
      key: const Key('a1_sporing_hjelp_main'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            _Avatar(size: 56, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_partner ? SporingCopy.a1_sporing_leverer_selv(_navn) : SporingCopy.a1_sporing_er_budet(_navn), key: const Key('a1_sporing_hjelp_tittel'), style: jakarta(17, em: -.02)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kSpMint,
                          boxShadow: [BoxShadow(color: kSpMint, blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          under,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(11.5, color: rgba(255, 255, 255, .65)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Lukk(onTap: _lukk),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Oransje(
                key: const Key('a1_sporing_hjelp_ring'),
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    spIkon(kSpIkonTelefon, size: 15),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(SporingCopy.a1_sporing_ring_kort, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13.5)),
                    ),
                  ],
                ),
                onTap: _ring,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Glass(
                key: const Key('a1_sporing_hjelp_melding'),
                height: 48,
                onTap: () => setState(() => _state = HjelpState.melding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    spIkon(kSpIkonChatEnkel, size: 15, color: kSpMint),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(SporingCopy.a1_sporing_send_melding, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          SporingCopy.a1_sporing_hjelp_vanlige.toUpperCase(),
          style: inter(10.5, weight: FontWeight.w800, em: .06, color: rgba(255, 255, 255, .6)),
        ),
        const SizedBox(height: 8),
        _Rad(
          key: const Key('a1_sporing_hjelp_dor'),
          ikon: kSpIkonHus2,
          tittel: '$_rolleStor ${SporingCopy.a1_sporing_hjelp_dor.substring(0, 1).toLowerCase()}${SporingCopy.a1_sporing_hjelp_dor.substring(1)}',
          under: SporingCopy.a1_sporing_hjelp_dor_line,
          onTap: () => setState(() => _state = HjelpState.dor),
        ),
        const SizedBox(height: 7),
        _Rad(
          key: const Key('a1_sporing_hjelp_mangler'),
          ikon: kSpIkonMangler,
          tittel: SporingCopy.a1_sporing_hjelp_mangler,
          under: SporingCopy.a1_sporing_svarer_innen(30).split('.').first,
          onTap: () => _startChat(SupportTema.mangler),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _Rad(
                key: const Key('a1_sporing_hjelp_feil'),
                ikon: kSpIkonFeilVare,
                tittel: SporingCopy.a1_sporing_feil_vare,
                under: SporingCopy.a1_sporing_fikk_noe_annet,
                pil: false,
                onTap: () => _startChat(SupportTema.feil),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _Rad(
                key: const Key('a1_sporing_hjelp_kom_aldri'),
                ikon: kSpIkonKomAldri,
                ikonExtra: kSpIkonKomAldriExtra,
                tittel: SporingCopy.a1_sporing_kom_aldri,
                under: SporingCopy.a1_sporing_staar_som_levert,
                pil: false,
                onTap: () => _startChat(SupportTema.komAldri),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _Rad(
          key: const Key('a1_sporing_hjelp_kundeservice'),
          ikon: kSpIkonHeadset,
          tittel: SporingCopy.a1_sporing_snakk_med,
          under: SporingCopy.a1_sporing_ks_aapent,
          onTap: () => setState(() => _state = HjelpState.kundeservice),
        ),
      ],
    );
  }

  // ── ring ────────────────────────────────────────────────────────────────

  Widget _ringState() => Column(
    key: const Key('a1_sporing_hjelp_ring_state'),
    children: [
      const SizedBox(height: 18),
      SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _puls(0, .5),
            _puls(600, .35),
            Container(
              width: 96,
              height: 96,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFF2F6B7B), Color(0xFF1B4854)]),
                border: Border.all(color: rgba(255, 255, 255, .3)),
                boxShadow: [BoxShadow(color: rgba(4, 18, 26, .95), offset: const Offset(0, 18), blurRadius: 30, spreadRadius: -14)],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [Positioned(left: -4, top: 6, child: aegil('side', w: 104, h: 104))],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(_navn, style: jakarta(20, em: -.02)),
      const SizedBox(height: 3),
      Text(_calling || _callSeconds < 3 ? SporingCopy.a1_sporing_ringer : SporingCopy.a1_sporing_samtale_med(_navn), style: inter(12, color: rgba(255, 255, 255, .65))),
      const SizedBox(height: 6),
      Text(
        spMmSs(_callSeconds),
        key: const Key('a1_sporing_ring_tid'),
        style: jakarta(28, em: -.02, color: kSpMint),
      ),
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _rund(SporingCopy.a1_sporing_demp, _muted, spIkon(kSpIkonDemp, size: 20, color: _muted ? kSpTeal : Colors.white, extra: kSpIkonDempExtra), () => setState(() => _muted = !_muted)),
          const SizedBox(width: 14),
          Column(
            children: [
              LfPress(
                key: const Key('a1_sporing_ring_avslutt'),
                onTap: _endCall,
                scale: .92,
                child: Transform.translate(
                  offset: const Offset(0, -6),
                  child: CssBox(
                    width: 68,
                    height: 68,
                    radius: BorderRadius.circular(34),
                    border: Border.all(color: rgba(255, 255, 255, .3)),
                    bg: const [
                      CssLinear(160, [Color(0xFFF26D5B), Color(0xFFD9412F)]),
                    ],
                    shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .35)), CssShadow(0, 3, 0, 0, rgba(140, 30, 20, .8)), CssShadow(0, 14, 22, -10, rgba(140, 30, 20, .9))],
                    child: Center(
                      child: Transform.rotate(angle: rad(135), child: spIkon(kSpIkonTelefon, size: 26)),
                    ),
                  ),
                ),
              ),
              Text(
                SporingCopy.a1_sporing_avslutt_samtale.split(' ').first,
                style: inter(10.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .7)),
              ),
            ],
          ),
          const SizedBox(width: 14),
          _rund(SporingCopy.a1_sporing_hoyttaler, _speaker, spIkon(kSpIkonHoyttaler, size: 20, color: _speaker ? kSpTeal : Colors.white), () => setState(() => _speaker = !_speaker)),
        ],
      ),
      const SizedBox(height: 18),
      GestureDetector(
        key: const Key('a1_sporing_ring_tilbake'),
        onTap: _endCall,
        child: Text(
          SporingCopy.a1_sporing_tilbake_til_hjelp,
          style: inter(12, weight: FontWeight.w800, color: rgba(255, 255, 255, .6)),
        ),
      ),
      const SizedBox(height: 6),
    ],
  );

  Widget _puls(double delay, double a) => Positioned(
    left: -10,
    top: -10,
    right: -10,
    bottom: -10,
    child: LfLoop(
      builder: (context, tt, child) {
        final e = tt - delay;
        final p = e < 0 ? 0.0 : cssEaseOut.transform((e / 1800) % 1.0);
        return Opacity(
          opacity: .9 * (1 - p),
          child: Transform.scale(scale: .6 + 1.3 * p, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: rgba(92, 224, 184, a), width: 1.5),
        ),
      ),
    ),
  );

  Widget _rund(String label, bool on, Widget ikon, VoidCallback onTap) => Column(
    children: [
      LfPress(
        onTap: onTap,
        scale: .92,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Colors.white : rgba(255, 255, 255, .14),
            border: Border.all(color: rgba(255, 255, 255, .26)),
            boxShadow: [BoxShadow(color: rgba(255, 255, 255, .3), offset: const Offset(0, 1.5), blurStyle: BlurStyle.inner)],
          ),
          child: Center(child: ikon),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: inter(10.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .7)),
      ),
    ],
  );

  // ── melding ─────────────────────────────────────────────────────────────

  Widget _melding() {
    final kunde = prefGetString(prefUserName).trim().split(' ').first;
    final chips = SporingCopy.a1_sporing_hurtig_launch.map((c) => c == SporingCopy.a1_sporing_ring_paa && kunde.isNotEmpty ? SporingCopy.a1_sporing_ring_paa_hos(kunde) : c).toList();
    return Column(
      key: const Key('a1_sporing_hjelp_melding_state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            _Tilbake(onTap: () => setState(() => _state = HjelpState.main)),
            const SizedBox(width: 10),
            _Avatar(size: 36, radius: 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SporingCopy.a1_sporing_hjelp_melding(_rolle), style: jakarta(15, em: -.02)),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kSpMint,
                          boxShadow: [BoxShadow(color: kSpMint, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          SporingCopy.a1_sporing_aktiv_naa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(10.5, color: rgba(255, 255, 255, .62)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            LfPress(
              onTap: _ring,
              scale: .92,
              child: CssBox(
                width: 34,
                height: 34,
                radius: BorderRadius.circular(12),
                bg: const [
                  CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
                ],
                shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .35)), CssShadow(0, 6, 10, -6, rgba(120, 50, 10, .9))],
                child: Center(child: spIkon(kSpIkonTelefon, size: 14)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150, maxHeight: 240),
          child: ListView(
            controller: _scroll,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 2),
            children: [
              for (final (i, m) in _thread.indexed) ...[if (i > 0) const SizedBox(height: 7), _Boble(meg: m.$1, tekst: m.$2, kl: m.$3, delay: math.min(i, 6) * 40.0)],
              if (_typing) ...[
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CssBox(
                    radius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5)),
                    padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                    border: Border.all(color: rgba(255, 255, 255, .24)),
                    bg: [
                      CssLinear(180, [rgba(255, 255, 255, .18), rgba(255, 255, 255, .09)]),
                    ],
                    child: Row(mainAxisSize: MainAxisSize.min, children: [for (var k = 0; k < 3; k++) _prikk(k * 150.0)]),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, c) in chips.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                LfPress(
                  key: Key('a1_sporing_meld_chip_$i'),
                  onTap: () => _send(c),
                  scale: .95,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
                    decoration: BoxDecoration(
                      color: rgba(255, 255, 255, .08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: rgba(255, 255, 255, .22)),
                    ),
                    child: Text(
                      c,
                      style: inter(11.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .9)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        CssBox(
          height: 50,
          radius: BorderRadius.circular(999),
          padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
          border: Border.all(color: rgba(255, 255, 255, .26)),
          bg: [
            CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .07)]),
          ],
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .32))],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('a1_sporing_meld_felt'),
                  controller: _msg,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  cursorColor: kSpMint,
                  style: jakarta(14, weight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: SporingCopy.a1_sporing_skriv_til(_navn),
                    hintStyle: jakarta(14, weight: FontWeight.w700, color: rgba(255, 255, 255, .45)),
                  ),
                ),
              ),
              LfPress(
                key: const Key('a1_sporing_meld_send'),
                onTap: _send,
                scale: .9,
                child: Opacity(
                  opacity: _msg.text.trim().isEmpty ? .45 : 1,
                  child: CssBox(
                    width: 38,
                    height: 38,
                    radius: BorderRadius.circular(19),
                    bg: const [
                      CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
                    ],
                    shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .35)), CssShadow(0, 6, 10, -6, rgba(120, 50, 10, .9))],
                    child: Center(child: spIkon(kSpIkonOpp, size: 16, width: 2.4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prikk(double delay) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: LfLoop(
      builder: (context, tt, child) {
        final e = tt - delay;
        final p = e < 0 ? 0.0 : (e / 900) % 1.0;
        return Transform.scale(scaleY: kf(p, const [0, .5, 1], const [.5, 1, .5], cssEaseInOut), child: child);
      },
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, .7)),
      ),
    ),
  );

  // ── dør ─────────────────────────────────────────────────────────────────

  Widget _dor() {
    final adresse = _adresse ?? '${t?.raw['delivery_address'] ?? ''}';
    return Column(
      key: const Key('a1_sporing_hjelp_dor_state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        _Hode(onTilbake: () => setState(() => _state = HjelpState.main), tittel: SporingCopy.a1_sporing_dor_tittel(_rolleStor), under: SporingCopy.a1_sporing_dette_ser(_navn)),
        const SizedBox(height: 14),
        CssBox(
          radius: BorderRadius.circular(20),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          border: Border.all(color: rgba(255, 255, 255, .22)),
          bg: [
            CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .07)]),
          ],
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .3))],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SporingCopy.a1_sporing_lev_adresse.toUpperCase(),
                style: inter(10.5, weight: FontWeight.w800, em: .06, color: rgba(255, 255, 255, .6)),
              ),
              const SizedBox(height: 4),
              Text(
                adresse.isEmpty ? '—' : '${SporingCopy.a1_sporing_hjem_etikett[0].toUpperCase()}${SporingCopy.a1_sporing_hjem_etikett.substring(1)} · ${adresse.split(',').first.trim()}',
                style: inter(14, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                SporingCopy.a1_sporing_veibeskrivelse.toUpperCase(),
                style: inter(10.5, weight: FontWeight.w800, em: .06, color: rgba(255, 255, 255, .6)),
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: spIkon(kSpIkonHus2, size: 14, color: kSpMint),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('a1_sporing_dor_felt'),
                      controller: _door,
                      maxLines: null,
                      cursorColor: kSpMint,
                      style: inter(13, height: 1.45, color: rgba(255, 255, 255, .9)),
                      decoration: InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        border: InputBorder.none,
                        filled: false,
                        hintText: SporingCopy.a1_sporing_dor_hint,
                        hintStyle: inter(13, height: 1.45, color: rgba(255, 255, 255, .5)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Oransje(
          key: const Key('a1_sporing_dor_send'),
          height: 50,
          onTap: _sendDoor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spIkon(kSpIkonSend, size: 15, width: 2.4),
              const SizedBox(width: 8),
              Flexible(
                child: Text(SporingCopy.a1_sporing_send_veibeskrivelsen(_navn), maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Glass(
                height: 46,
                onTap: _ring,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    spIkon(kSpIkonTelefon, size: 14, color: kSpMint),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        SporingCopy.a1_sporing_ring_navn(_navn),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(13, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Glass(
                height: 46,
                onTap: () => setState(() => _state = HjelpState.melding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    spIkon(kSpIkonChatEnkel, size: 14, color: kSpMint),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        SporingCopy.a1_sporing_skriv_selv,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(13, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── mangler / feil ──────────────────────────────────────────────────────

  // ── kundeservice ────────────────────────────────────────────────────────

  Widget _support() => Column(
    key: const Key('a1_sporing_kundeservice'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 14),
      Row(
        children: [
          if (!_standalone) ...[_Tilbake(onTap: () => setState(() => _state = HjelpState.main)), const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SporingCopy.a1_sporing_aerend_i_bergen, style: jakarta(18, em: -.02)),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: kSpMint,
                        boxShadow: [BoxShadow(color: kSpMint, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        SporingCopy.a1_sporing_aapent_til,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(11.5, color: rgba(255, 255, 255, .62)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_standalone) _Lukk(onTap: _lukk),
        ],
      ),
      const SizedBox(height: 14),
      _Rad(
        key: const Key('a1_sporing_ks_chat'),
        tile: CssBox(
          width: 40,
          height: 40,
          radius: BorderRadius.circular(13),
          bg: const [
            CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
          ],
          shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .35)), CssShadow(0, 6, 10, -6, rgba(120, 50, 10, .9))],
          child: Center(child: spIkon(kSpIkonChatEnkel, size: 18)),
        ),
        tittel: SporingCopy.a1_sporing_chat_med_oss,
        under: SporingCopy.a1_sporing_raskest,
        stor: true,
        onTap: _supportChat,
      ),
      const SizedBox(height: 7),
      _Rad(
        key: const Key('a1_sporing_ks_ring'),
        tile: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: rgba(255, 255, 255, .12), borderRadius: BorderRadius.circular(13)),
          child: Center(child: spIkon(kSpIkonTelefon, size: 18, color: kSpMint)),
        ),
        tittel: SporingCopy.a1_sporing_ring_nummer,
        under: SporingCopy.a1_sporing_vanlig_takst,
        stor: true,
        onTap: _ringKs,
      ),
      if (!_standalone) ...[
        const SizedBox(height: 12),
        Container(
          key: const Key('a1_sporing_ks_ordre'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: rgba(255, 255, 255, .06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: rgba(255, 255, 255, .14)),
          ),
          child: Text.rich(
            TextSpan(
              style: inter(11, height: 1.45, color: rgba(255, 255, 255, .6)),
              children: [
                TextSpan(text: SporingCopy.a1_sporing_ks_ordre_for),
                TextSpan(
                  text: t?.code ?? '#$_id',
                  style: inter(11, weight: FontWeight.w800, height: 1.45),
                ),
                TextSpan(text: SporingCopy.a1_sporing_ks_ordre_hale),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  // ── sendt ───────────────────────────────────────────────────────────────

  Widget _sendt() => Padding(
    key: const Key('a1_sporing_hjelp_sendt'),
    padding: const EdgeInsets.fromLTRB(10, 22, 10, 8),
    child: Column(
      children: [
        LfOnce(
          ms: 500,
          builder: (context, tt, child) {
            final p = kfP(tt, 0, 500);
            final k = kf(p, const [0, .35, .7, 1], const [0, 1.16, .96, 1], const Cubic(.34, 1.56, .64, 1));
            return Transform.scale(scale: k.clamp(0, 2), child: child);
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rgba(92, 224, 184, .16),
              border: Border.all(color: rgba(92, 224, 184, .5), width: 1.5),
            ),
            child: Center(child: spIkon('M4.5 12.5l5 5 10-11', size: 32, color: kSpMint, width: 3)),
          ),
        ),
        const SizedBox(height: 14),
        Text(_sentTitle, textAlign: TextAlign.center, style: jakarta(19, em: -.02)),
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          child: Text(
            _sentText,
            textAlign: TextAlign.center,
            style: inter(12.5, height: 1.45, color: rgba(255, 255, 255, .7)),
          ),
        ),
        const SizedBox(height: 18),
        _Glass(
          key: const Key('a1_sporing_sendt_ferdig'),
          height: 48,
          onTap: _lukk,
          child: Center(
            child: Text(SporingCopy.a1_sporing_ferdig, style: inter(13.5, weight: FontWeight.w800)),
          ),
        ),
      ],
    ),
  );
}

/// Kundeservice standalone (`/bergen/kundeservice`).
class KundeserviceScreen extends StatelessWidget {
  const KundeserviceScreen({super.key, this.api});

  final OpsCustomerApi? api;

  @override
  Widget build(BuildContext context) {
    final args = BergenRoutes.argsOf(context);
    final orderId = int.tryParse(args['order_id'] ?? '');
    // `vis: hjelp` is «Hjelp og kontakt»; `vis: chat` opens the support chat.
    final initial = switch (args['vis']) {
      'hjelp' => HjelpState.hub,
      'chat' => HjelpState.chat,
      _ => HjelpState.kundeservice,
    };
    return HjelpScreen(key: const Key('a1_sporing_kundeservice_screen'), orderId: orderId, api: api, initial: initial);
  }
}

// ── pieces ──────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, required this.radius});

  final double size, radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFF2F6B7B), Color(0xFF1B4854)]),
      border: Border.all(color: rgba(255, 255, 255, .26)),
      boxShadow: [BoxShadow(color: rgba(4, 18, 26, .9), offset: const Offset(0, 10), blurRadius: 18, spreadRadius: -10)],
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -size * .036,
          top: size * .054,
          child: aegil('side', w: size * 1.07, h: size * 1.07),
        ),
      ],
    ),
  );
}

class _Lukk extends StatelessWidget {
  const _Lukk({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    key: const Key('a1_sporing_hjelp_lukk'),
    onTap: onTap,
    scale: .92,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rgba(15, 31, 43, .5),
        boxShadow: [BoxShadow(color: rgba(255, 255, 255, .28), spreadRadius: 1)],
      ),
      child: Center(child: spIkon(kSpIkonKryss, size: 12, width: 2.6)),
    ),
  );
}

class _Tilbake extends StatelessWidget {
  const _Tilbake({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    key: const Key('a1_sporing_hjelp_tilbake'),
    onTap: onTap,
    scale: .92,
    child: Semantics(
      button: true,
      label: SporingCopy.a1_sporing_tilbake,
      child: CssBox(
        width: 34,
        height: 34,
        radius: BorderRadius.circular(12),
        border: Border.all(color: rgba(255, 255, 255, .22)),
        bg: [
          CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .07)]),
        ],
        child: Center(
          child: spIkon('M15 6l-6 6 6 6', size: 14, width: 2.4),
        ),
      ),
    ),
  );
}

class _Hode extends StatelessWidget {
  const _Hode({required this.onTilbake, required this.tittel, required this.under});

  final VoidCallback onTilbake;
  final String tittel, under;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Tilbake(onTap: onTilbake),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tittel, style: jakarta(18, em: -.02)),
            const SizedBox(height: 1),
            Text(under, style: inter(11.5, color: rgba(255, 255, 255, .62))),
          ],
        ),
      ),
    ],
  );
}

class _Oransje extends StatelessWidget {
  const _Oransje({super.key, required this.height, required this.child, required this.onTap});

  final double height;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    onTap: onTap,
    scale: .97,
    child: CssBox(
      height: height,
      radius: BorderRadius.circular(16),
      bg: const [
        CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
      ],
      shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .35)), CssShadow(0, 3, 0, 0, rgba(150, 60, 15, .8)), CssShadow(0, 12, 20, -10, rgba(120, 50, 10, .9))],
      child: child,
    ),
  );
}

class _Glass extends StatelessWidget {
  const _Glass({super.key, required this.height, required this.child, required this.onTap});

  final double height;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    onTap: onTap,
    scale: .97,
    child: CssBox(
      height: height,
      radius: BorderRadius.circular(16),
      border: Border.all(color: rgba(255, 255, 255, .26)),
      bg: [
        CssLinear(180, [rgba(255, 255, 255, .16), rgba(255, 255, 255, .08)]),
      ],
      shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .32))],
      child: child,
    ),
  );
}

/// A question row: the icon tile, title, line, chevron.
class _Rad extends StatelessWidget {
  const _Rad({super.key, this.ikon, this.ikonExtra = '', this.tile, required this.tittel, required this.under, required this.onTap, this.pil = true, this.stor = false, this.etter});

  final String? ikon;
  final String ikonExtra;
  final Widget? tile;
  final String tittel, under;
  final VoidCallback onTap;
  final bool pil, stor;

  /// Something at the end instead of the chevron (a case's «Åpen»).
  final Widget? etter;

  @override
  Widget build(BuildContext context) => LfPress(
    onTap: onTap,
    scale: .985,
    child: CssBox(
      radius: BorderRadius.circular(18),
      padding: stor ? const EdgeInsets.fromLTRB(14, 13, 14, 13) : const EdgeInsets.fromLTRB(12, 11, 12, 11),
      border: Border.all(color: rgba(255, 255, 255, .2)),
      bg: [
        CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .07)]),
      ],
      shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28))],
      child: Row(
        children: [
          tile ??
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: rgba(255, 255, 255, .12), borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: spIkon(ikon!, size: 16, color: kSpMint, extra: ikonExtra),
                ),
              ),
          SizedBox(width: stor ? 12 : 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tittel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(stor ? 13.5 : 13, weight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  under,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(10.5, color: rgba(255, 255, 255, .6)),
                ),
              ],
            ),
          ),
          if (etter != null) ...[const SizedBox(width: 8), etter!],
          if (pil && etter == null) spIkon(kSpIkonPilLiten, size: 13, color: rgba(255, 255, 255, .6), width: 2.4),
        ],
      ),
    ),
  );
}

/// A chat bubble (`chipInn` in).
class _Boble extends StatelessWidget {
  const _Boble({required this.meg, required this.tekst, required this.kl, required this.delay});

  final bool meg;
  final String tekst, kl;
  final double delay;

  @override
  Widget build(BuildContext context) => Align(
    alignment: meg ? Alignment.centerRight : Alignment.centerLeft,
    child: LfOnce(
      ms: delay + 350,
      builder: (context, tt, child) {
        final p = cssKlistre.transform(kfP(tt, delay, 350));
        final y = kf(p, const [0, .7, 1], const [10, -2, 0]);
        final k = kf(p, const [0, .7, 1], const [.92, 1.02, 1]);
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(k, k, 1, 1), child: child),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 358 * .78),
        child: CssBox(
          radius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(meg ? 18 : 5), bottomRight: Radius.circular(meg ? 5 : 18)),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
          border: Border.all(color: rgba(255, 255, 255, meg ? .2 : .24)),
          bg: meg
              ? const [
                  CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
                ]
              : [
                  CssLinear(180, [rgba(255, 255, 255, .18), rgba(255, 255, 255, .09)]),
                ],
          shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .28)), CssShadow(0, 8, 16, -12, rgba(4, 18, 26, .8))],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tekst, style: inter(13, height: 1.4)),
              const SizedBox(height: 3),
              Text(
                kl,
                style: inter(9.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .55)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
