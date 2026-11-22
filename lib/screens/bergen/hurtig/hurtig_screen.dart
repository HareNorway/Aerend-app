import 'dart:async';
import 'dart:math' as math;
import '../../common/home/bergen/bergen_nav.dart' show BergenTab;
import '../../common/homeMainV1/home_main_v1.dart' show HomeMainV1State;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../../../ui/kit/ae_haptic.dart';

import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeather, BergenWeatherLook;
import '../hjem/hjem_harness.dart';
import '../hjem/hjem_hero.dart' show HjemVaer;
import '../kasse/kasse_copy.dart';
import '../kit/bergen_cart.dart';
import '../kit/bergen_routes.dart';
import '../kit/bergen_toast.dart';
import '../meg/a3_services.dart';
import '../../../services/customer/client_flags.dart';
import '../ai/ai_bits.dart';
import '../ai/ai_copy.dart';
import '../ai/ai_sheets.dart';
import '../ai/ai_store.dart';
import 'hurtig_bits.dart';
import 'hurtig_brain.dart';
import 'hurtig_copy.dart';
import 'hurtig_data.dart';
import 'hurtig_glass.dart' show kHbLysIkon, kHbLysRing;
import 'hurtig_kort.dart';
import 'hurtig_utkast.dart';
import '../kasse/kurv_screen.dart' show KurvScreen;
import '../kit/bergen_perf.dart';
import 'package:aerend_customer/screens/bergen/kit/css_decoration.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';

// ── Hurtigbestilling (prototype `erHurtig`, L4245–4520) ────────────────────
//
// Ægil's own ordering chat: the teal screen with its warm band, Ægil in one
// of four moods, the dark sheet with the context chips, the conversation
// (bubbles, the three module cards, the confirmation), the draft with its
// countdown key, and the bottom bar with the three module keys and the
// composer. The reasoning is `HurtigHjerne`; this file owns the state the
// prototype keeps in `hb*` and the real order path.

/// Lys: `0 0 0 1px var(--lys-kant-farge), var(--lys-kortskygge)` (`.mk1m`).
const List<CssShadow> _lysBobleSkygge = [CssShadow(0, 0, 0, 1, LysPalett.kantFarge), ...LysPalett.kortskygge];

/// One line of the conversation (`hb[]`).
class _Melding {
  _Melding({required this.meg, required this.tekst, this.humor = 'glad', this.knapper = const [], this.modul = '', this.ordre}) : id = _n++;

  static int _n = 0;
  final int id;
  final bool meg;
  final String tekst;
  final String humor;
  final List<HbKnapp> knapper;
  final String modul;
  final _Ordre? ordre;
}

/// The placed order the «Bestilt» card shows (`ordre`).
class _Ordre {
  const _Ordre({required this.id, required this.kode, required this.butikkId, required this.butikk, required this.linje, required this.total, required this.varer, required this.klar});
  final int id;
  final String kode;
  final int butikkId;
  final String butikk;
  final String linje;
  final double total;
  final double varer;
  final String klar;
}

class HurtigScreen extends StatefulWidget {
  const HurtigScreen({super.key, this.data, this.now});

  /// Tests inject the data and the clock.
  final HurtigData? data;
  final DateTime? now;

  /// Pops with this when the draft went to the basket, so the caller can
  /// switch to the Kurv tab (`gaa('kurv')`).
  static const String tilKurv = 'kurv';

  @override
  State<HurtigScreen> createState() => HurtigScreenState();
}

class HurtigScreenState extends State<HurtigScreen> with WidgetsBindingObserver {
  HurtigData? _d;
  late HurtigHjerne _h;
  final List<_Melding> _hb = [];
  HbUtkast? _utkast;
  HbUtkast? _forrigeU;

  /// Customer Step 15: the route's `mod` / `si` applied once.
  bool _rute = false;
  String _fase = 'utkast';
  bool _tenker = false;
  String _modAktiv = '';
  int? _hus;
  bool? _skalldyr;
  bool _plasserer = false;
  Timer? _hbT;

  /// Design 21 Nov (A1): a line on its way out of the draft (quantity 0) slides left for 220 ms before it leaves.
  final Set<int> _ut = {};
  final TextEditingController _tekst = TextEditingController();
  final FocusNode _fokus = FocusNode();
  final ScrollController _scroll = ScrollController();
  bool _harness = false;

  HbTilstand get _st => HbTilstand(utkast: _utkast, fase: _fase, hus: _hus, skalldyr: _skalldyr, regn: _vaer == BergenWeather.regn);

  BergenWeather get _vaer {
    if (!kReleaseMode && HjemHarness.vaer != null) {
      return switch (HjemHarness.vaer!) {
        HjemVaer.regn => BergenWeather.regn,
        HjemVaer.sol => BergenWeather.sol,
        HjemVaer.solnedgang => BergenWeather.solnedgang,
        HjemVaer.natt => BergenWeather.natt,
      };
    }
    return BergenWeatherLook.forHour(_h.now.hour).kind;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _h = HurtigHjerne(HurtigData.tom, now: widget.now);
    // Customer Step 14: the linked list for the «Bestill med en annen AI» line.
    if (ClientFlags.on(ClientFlags.aiLinking)) unawaited(AiStore.instance.load());
    _tekst.addListener(() => setState(() {}));
    // New Bergen L15941: the field lights up while focused (`hbFokus`).
    _fokus.addListener(() => setState(() {}));
    _tenker = true;
    _load();
  }

  Future<void> _load() async {
    final d = widget.data ?? await HurtigKilde.load(refresh: true);
    if (!mounted) return;
    _h = HurtigHjerne(d, now: widget.now);
    setState(() {
      _d = d;
      _tenker = false;
      if (_hb.isEmpty) {
        final v = _h.velkomst(_st);
        _hb.add(_Melding(meg: false, tekst: v.tekst, humor: 'glad', knapper: v.knapper));
      }
    });
    if (kDebugMode && HjemHarness.hurtig && !_harness) {
      _harness = true;
      _applyHarness();
    }
    // Customer Step 15: a deep link's module or line (`/bergen/hurtig?mod=forrige`
    // from the OrderAgain intent / shortcut, `?si=Bestill …` for a favourite).
    // The draft card is the confirmation step — nothing is ordered here.
    if (!_rute) {
      _rute = true;
      // After the frame: the route is read through the context (`_load` may run from initState).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final a = BergenRoutes.argsOf(context);
        final mod = a['mod'] ?? '';
        final si = a['si'] ?? '';
        if (!const ['oftest', 'forrige', 'pref'].contains(mod) && si.isEmpty) return;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          if (mod.isNotEmpty) {
            _send(_modTekst(mod), modul: mod);
          } else {
            _send(si);
          }
        });
      });
    }
  }

  /// Debug only: the Hjem harness keys for this screen.
  void _applyHarness() {
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final mod = HjemHarness.hurtigMod;
      if (mod != null) _send(_modTekst(mod), modul: mod);
      if (HjemHarness.hurtigSi case final t?) _send(t);
      if (HjemHarness.hurtigTekst case final t?) _tekst.text = t;
      if (HjemHarness.hurtigFokus) _fokus.requestFocus();
      if (HjemHarness.hurtigBestilt case final id?) {
        final rows = await HurtigKilde.customer().orders(limit: 20);
        final o = rows.where((o) => '${o['order_id']}' == '$id').firstOrNull;
        if (o != null && mounted) _bestiltFerdig(o);
      }
      if (HjemHarness.hurtigTenk) {
        // The typing indicator, held (a frame check).
        setState(() {
          _hb.add(_Melding(meg: true, tekst: HurtigCopy.spOftest));
          _tenker = true;
        });
        _rullNed();
      }
      if (HjemHarness.hurtigAct == 'tilKurv') {
        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted) _tilKassen();
      }
      if (HjemHarness.hurtigScroll case final y?) {
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted && _scroll.hasClients) _scroll.jumpTo(y.clamp(0.0, _scroll.position.maxScrollExtent));
      }
      debugPrint('HURTIG_HARNESS applied');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hbT?.cancel();
    _tekst.dispose();
    _fokus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── the conversation ────────────────────────────────────────────────────

  /// The prototype's scroll rule: a new reply from Ægil scrolls so the reply
  /// starts at the top of the pane (10px above); anything else (the
  /// customer's line, the typing dots, a draft change) scrolls to the end.
  final Map<int, GlobalKey> _aegKeys = {};

  void _rullNed({int? tilMelding}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      var mal = max;
      final key = tilMelding == null ? null : _aegKeys[tilMelding];
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      final pane = _scroll.position.context.storageContext.findRenderObject() as RenderBox?;
      if (box != null && pane != null && box.attached) {
        final y = box.localToGlobal(Offset.zero, ancestor: pane).dy + _scroll.offset;
        mal = math.min(max, y - 10 - 6);
      }
      mal = math.max(0, mal);
      if ((mal - _scroll.offset).abs() > 1) {
        _scroll.animateTo(mal, duration: const Duration(milliseconds: 320), curve: const Cubic(.2, .9, .3, 1));
      }
    });
  }

  /// `hbAegil`: Ægil answers after [vent] ms of thinking (0: at once).
  void _aegil(String tekst, String humor, List<HbKnapp> knapper, {String modul = '', _Ordre? ordre, int? vent}) {
    _hbT?.cancel();
    void push() {
      if (!mounted) return;
      final m = _Melding(meg: false, tekst: tekst, humor: humor, knapper: knapper, modul: modul, ordre: ordre);
      setState(() {
        _tenker = false;
        _hb.add(m);
      });
      _rullNed(tilMelding: m.id);
    }

    if (vent == 0) return push();
    setState(() => _tenker = true);
    _rullNed();
    _hbT = Timer(Duration(milliseconds: vent ?? 650), push);
  }

  /// `hbSettUtkast`.
  void _settUtkast(int butikkId, String butikk, List<HbLinje> linjer, [String? tid]) {
    final L = [for (final l in linjer) if (l.ant > 0 && _h.vare(l.id) != null) l];
    _ut.clear();
    if (L.isEmpty) {
      setState(() {
        _utkast = null;
        _fase = 'utkast';
      });
      return;
    }
    final gml = _utkast;
    setState(() {
      _forrigeU = gml != null && gml.butikkId != butikkId ? gml : _forrigeU;
      _utkast = HbUtkast(butikkId: butikkId, butikk: butikk, linjer: [for (final l in L) HbLinje(l.id, math.min(20, l.ant))], tid: tid ?? gml?.tid ?? HurtigCopy.snarest);
      _fase = 'utkast';
    });
    _rullNed();
  }

  /// `hbEndre`. A line going to 0 slides out first (220 ms, design `hbEndre`'s exit), unless motion is reduced.
  void _endre(int id, int d, {bool ferdig = false}) {
    final U = _utkast;
    if (U == null) return;
    final L = U.linjer.toList();
    final i = L.indexWhere((l) => l.id == id);
    if (i < 0) {
      if (d > 0) L.add(HbLinje(id, d));
    } else {
      final n = math.min(20, L[i].ant + d);
      if (n <= 0) {
        if (!ferdig && !_ut.contains(id) && !MediaQuery.disableAnimationsOf(context)) {
          setState(() => _ut.add(id));
          Timer(const Duration(milliseconds: 220), () {
            if (mounted) _endre(id, d, ferdig: true);
          });
          return;
        }
        _ut.remove(id);
        L.removeAt(i);
      } else {
        L[i] = L[i].med(n);
      }
    }
    setState(() {
      _utkast = L.isEmpty ? null : U.kopi(linjer: L);
      _fase = 'utkast';
    });
    _rullNed();
  }

  /// `hbVelg`: the + / ✓ keys on the «oftest» rows.
  void _velg(int id) {
    final v = _h.vare(id);
    final U = _utkast;
    if (v == null) return;
    final bt = _h.b(v.butikkId, v.butikk);
    AeHaptikk.tikk();
    if (bt.stengt != null) {
      final alt = _h.altAapen(v.butikkId);
      if (alt == null) return _aegil(HurtigCopy.stengtIngenAlt(v.butikk, bt.stengt!), 'lei', const []);
      return _aegil(
        HurtigCopy.stengt(v.butikk, bt.stengt!, alt.b.navn, alt.v.navn.toLowerCase()),
        'lei',
        [HbKnapp(HurtigCopy.jaTa(alt.v.navn), 'leggtil:${alt.v.id}', primar: true), HbKnapp(HurtigCopy.neiTakk, 'si:${HurtigCopy.neiTakk}')],
      );
    }
    if (v.skalldyr && _h.unngaaSkalldyr(_st) && !(U != null && U.har(id))) {
      final s = _h.skalldyrSvar(v);
      return _aegil(s.tekst, s.humor, s.knapper);
    }
    if (U != null && U.butikkId == v.butikkId) {
      final har = U.linjer.where((l) => l.id == id).firstOrNull;
      return _endre(id, har != null ? -har.ant : _h.vanligAnt(id));
    }
    _settUtkast(v.butikkId, v.butikk, [HbLinje(id, _h.vanligAnt(id))]);
    if (U != null) _aegil(HurtigCopy.byttet(v.butikk, U.butikk), 'tenker', [HbKnapp(HurtigCopy.angreBytte, 'angrebytt')], vent: 450);
  }

  /// `hbKnapp`.
  void _knapp(String hh) {
    final i = hh.indexOf(':');
    final k = i > -1 ? hh.substring(0, i) : hh;
    final v = i > -1 ? hh.substring(i + 1) : '';
    AeHaptikk.tikk();
    if (k == 'si') return _send(v);
    if (k == 'leggtil') {
      final id = int.tryParse(v) ?? 0;
      final x = _h.vare(id);
      final U = _utkast;
      if (x == null) return;
      if (U != null && U.butikkId == x.butikkId) {
        _endre(id, _h.vanligAnt(id));
      } else {
        _settUtkast(x.butikkId, x.butikk, [HbLinje(id, _h.vanligAnt(id))]);
      }
      return _aegil(HurtigCopy.lagtInn(x.navn.toLowerCase(), x.butikk), 'glad', const [], vent: 450);
    }
    if (k == 'angrebytt') {
      final P = _forrigeU;
      if (P != null) {
        setState(() {
          _utkast = P;
          _forrigeU = null;
          _fase = 'utkast';
        });
        _aegil(HurtigCopy.tilbakeTil(P.butikk), 'glad', const [], vent: 400);
      }
      return;
    }
    // Design 21 Nov (D1): «bestill» and the Ægil line's «Til kassen» both land in the checkout.
    if (k == 'bestill') {
      unawaited(_tilKassen());
      return;
    }
    if (k == 'kasse') return _tilKurvFanen();
  }

  String _modTekst(String m) => switch (m) {
    'oftest' => HurtigCopy.spOftest,
    'forrige' => HurtigCopy.spForrige,
    _ => HurtigCopy.spPref,
  };

  /// `hbSend`: the customer's line, then the answer.
  void _send(String t, {String? modul}) {
    final tx = t.trim();
    if (tx.isEmpty || _tenker || _d == null) return;
    setState(() {
      _hb.add(_Melding(meg: true, tekst: tx));
      _tekst.clear();
      _modAktiv = modul ?? _modAktiv;
    });
    _rullNed();
    final svar = modul != null ? _h.modulSvar(modul, _st) : _h.tolk(tx, _st);
    if (svar.ai) {
      _ai(tx);
      return;
    }
    setState(() => _tenker = true);
    _rullNed();
    _hbT?.cancel();
    _hbT = Timer(Duration(milliseconds: 650 + math.Random().nextInt(351)), () {
      if (!mounted) return;
      if (svar.utkast != null) {
        _settUtkast(svar.utkast!.butikkId, svar.utkast!.butikk, svar.utkast!.linjer, svar.tid?.isNotEmpty == true ? svar.tid : null);
      } else if (svar.tomUtkast) {
        _settUtkast(0, '', const []);
      } else if (svar.tid != null && svar.tid!.isNotEmpty && _utkast != null) {
        setState(() => _utkast = _utkast!.kopi(tid: svar.tid));
      }
      _aegil(svar.tekst, svar.humor, svar.knapper, modul: svar.modul, vent: 0);
      // Design 21 Nov (A1): `bestill` = the draft to the checkout, 1 100 ms after the answer (was an order in 380 ms).
      if (svar.bestill) Timer(const Duration(milliseconds: 1100), _tilKassen);
    });
  }

  /// `hbAi`: the local rules gave up — the assistant answers in words; the
  /// draft is left as it is.
  Future<void> _ai(String tx) async {
    setState(() => _tenker = true);
    _rullNed();
    final t0 = DateTime.now();
    String? reply;
    try {
      final turn = await A3Services.aegil().chat(text: tx);
      final r = turn?.reply.trim() ?? '';
      if (r.isNotEmpty) reply = r;
    } catch (_) {}
    if (!mounted) return;
    final wait = math.max(0, 700 - DateTime.now().difference(t0).inMilliseconds);
    _hbT?.cancel();
    _hbT = Timer(Duration(milliseconds: wait), () {
      if (!mounted) return;
      if (reply != null) return _aegil(reply, 'glad', const [], vent: 0);
      _aegil(
        HurtigCopy.fikkIkke,
        'tenker',
        [HbKnapp(HurtigCopy.detVanlige, 'si:${HurtigCopy.detVanlige}', primar: true), HbKnapp(HurtigCopy.sammeSomSist, 'si:${HurtigCopy.sammeSomSist}')],
        vent: 0,
      );
    });
  }

  /// `hbNy`.
  void _ny() {
    _hbT?.cancel();
    AeHaptikk.tikk();
    final v = _h.velkomst(_st);
    _aegKeys.clear();
    setState(() {
      _hb
        ..clear()
        ..add(_Melding(meg: false, tekst: v.tekst, humor: 'glad', knapper: v.knapper));
      _utkast = null;
      _forrigeU = null;
      _fase = 'utkast';
      _tenker = false;
      _modAktiv = '';
      _tekst.clear();
    });
  }

  // ── ordering ────────────────────────────────────────────────────────────

  /// The draft's lines into the real basket (one shop at a time).
  Future<bool> _fyllKurven(HbUtkast U) async {
    final k = HurtigKilde.kasse();
    var cart = await k.cart();
    if (!cart.isEmpty && cart.storeId != U.butikkId) {
      for (final l in cart.lines) {
        await k.remove(l.cartId);
      }
    }
    for (final l in U.linjer) {
      try {
        await HurtigKilde.leggTil(U.butikkId, l.id, l.ant);
      } catch (_) {}
    }
    cart = await k.cart();
    if (!mounted) return false;
    prefSetInt(prefCartCount, cart.lines.length);
    BergenCart.syncBadge(context, cart.lines.length);
    return !cart.isEmpty;
  }

  /// The «Bestilt» card from the order summary (`hbFullfor`'s tail).
  void _bestiltFerdig(Map<String, dynamic> o) {
    aeSuccess(); // the payment landed
    final store = o['store'] is Map ? o['store'] as Map : const {};
    final items = o['items'] is List ? (o['items'] as List).whereType<Map>() : const <Map>[];
    final navn = [
      for (final i in items)
        '${((i['qty'] ?? i['quantity'] ?? i['num_of_items'] ?? 1) as num).toInt() > 1 ? '${((i['qty'] ?? i['quantity'] ?? i['num_of_items']) as num).toInt()}× ' : ''}${i['name'] ?? i['product_name'] ?? ''}',
    ].join(', ');
    final total = ((o['total_pay'] ?? 0) as num).toDouble();
    final lev = ((o['delivery_cost'] ?? 0) as num).toDouble();
    final id = (o['order_id'] is num ? o['order_id'] as num : num.tryParse('${o['order_id']}') ?? 0).toInt();
    final storeId = (store['id'] as num?)?.toInt() ?? _utkast?.butikkId ?? 0;
    final storeName = '${store['name'] ?? _utkast?.butikk ?? ''}';
    String klar;
    final end = DateTime.tryParse('${o['promised_end'] ?? ''}')?.toLocal();
    if (end != null) {
      klar = HurtigCopy.hosDegCa('${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}');
    } else {
      klar = _h.klar(_utkast ?? HbUtkast(butikkId: storeId, butikk: storeName, linjer: const []));
    }
    final kode = '${o['code'] ?? ''}'.isEmpty ? 'Æ-$id' : '${o['code']}';
    final ordre = _Ordre(id: id, kode: kode, butikkId: storeId, butikk: storeName, linje: navn, total: total, varer: math.max(0, total - lev), klar: klar);
    AeHaptikk.tung();
    setState(() {
      _fase = 'bestilt';
      _utkast = null;
      _forrigeU = null;
      _tenker = false;
      _hb.add(_Melding(meg: false, tekst: HurtigCopy.bestiltSvar(storeName), humor: 'ferdig', modul: 'bestilt', ordre: ordre));
    });
    _rullNed(tilMelding: _hb.last.id);
    showBergenToast(context, HurtigCopy.bestiltToast(kode));
    HurtigKilde.load(refresh: true);
  }

  /// `hbTilKasse` (Design 21 Nov, D1/D2): the draft's lines into the real basket (merged by the server, one shop
  /// at a time), the draft's time handed to the Kurv as its preselected slot, Ægil's «Lagt i kassen …» line with
  /// «Til kassen», the toast, and the Kurv tab. Nothing is ordered here.
  Future<void> _tilKassen() async {
    final U = _utkast;
    if (U == null || U.linjer.isEmpty || _plasserer) return;
    AeHaptikk.fast();
    setState(() => _plasserer = true);
    final ok = await _fyllKurven(U);
    if (!mounted) return;
    setState(() => _plasserer = false);
    if (!ok) {
      AeHaptikk.feil();
      return showBergenToast(context, BergenRoutes.ikkeIKurven);
    }
    final n = U.linjer.fold<int>(0, (a, l) => a + l.ant);
    KurvScreen.hurtigTid = HurtigHjerne.klokkeslett(U.tid);
    final m = _Melding(
      meg: false,
      tekst: HurtigCopy.lagtIKassen(_h.tekst(U.linjer, HurtigCopy.og).toLowerCase(), U.butikk),
      humor: 'glad',
      knapper: [HbKnapp(HurtigCopy.tilKassen, 'kasse', primar: true)],
    );
    setState(() {
      _utkast = null;
      _forrigeU = null;
      _fase = 'utkast';
      _tenker = false;
      _hb.add(m);
    });
    _rullNed(tilMelding: m.id);
    showBergenToast(context, HurtigCopy.liggerIKassen(n, U.butikk));
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) _tilKurvFanen();
  }

  /// Back to the shell on the Kurv tab, whichever way Hurtig was opened (the Hjem card also switches on the result).
  void _tilKurvFanen() {
    final shell = HomeMainV1State.current;
    Navigator.of(context).pop(HurtigScreen.tilKurv);
    shell?.switchToTab(BergenTab.cart.index);
  }

  void _folg(_Ordre o) {
    BergenRoutes.push(context, '/bergen/sporing/${o.id}');
  }

  // ── the view models (`hbVals`) ──────────────────────────────────────────

  List<HbOftestVis> _rader() {
    final oft = _h.oftest();
    return [
      for (var i = 0; i < oft.length; i++)
        () {
          final x = oft[i];
          final v = _h.vare(x.id)!;
          final bt = _h.b(v.butikkId, v.butikk);
          return HbOftestVis(id: x.id, nr: i + 1, navn: v.navn, butikk: v.butikk, b: bt, ganger: HurtigCopy.ganger(x.ganger), pris: HurtigCopy.kr(v.pris), lagt: _utkast?.har(x.id) ?? false);
        }(),
    ];
  }

  HbVaneVis? _vaneVis() {
    final v = _h.vane(_st);
    if (v == null) return null;
    final s = _h.sum(v.utkast);
    final dag = v.dag;
    final middag = _d!.minne.middag;
    return HbVaneVis(
      dag: dag.substring(0, math.min(3, dag.length)).toUpperCase(),
      kl: HurtigCopy.kl(_d!.minne.middagKl.replaceAll(RegExp(r':00$'), '')),
      tittel: middag.contains(dag) ? HurtigCopy.dagsfavoritt(dag) : HurtigCopy.dinFavoritt,
      varer: _h.tekst(v.linjer),
      sum: HurtigCopy.kr(s.total),
    );
  }

  HbOrdreVis _ordreVis(HbOrdre o, {bool full = false}) {
    final bt = _h.b(o.butikkId, o.butikk);
    return HbOrdreVis(
      ordre: o,
      butikk: o.butikk,
      b: bt,
      sum: HurtigCopy.kr(o.sum),
      dato: _h.stor(_h.dato(o.naar)),
      varer: o.linjer.map((x) => x.navn).join(', '),
      kode: o.kode,
      linjer: full ? [for (final x in o.linjer) HbLinjeVis('${x.ant}×', x.navn, HurtigCopy.kr(x.pris))] : const [],
    );
  }

  void _igjen(HbOrdreVis v) {
    final o = v.ordre;
    AeHaptikk.tikk();
    _settUtkast(o.butikkId, o.butikk, _h.linjer(o));
    _aegil(HurtigCopy.sammeSomLigger(_h.dato(o.naar)), 'glad', const [], vent: 450);
  }

  void _vaneFn() {
    final v = _h.vane(_st);
    if (v == null) return;
    AeHaptikk.tikk();
    _settUtkast(v.butikkId, v.butikk, v.linjer);
    _aegil('${HurtigCopy.sattOppVane}${HurtigCopy.liggerIUtkastet('${_h.stor(_h.tekst(v.linjer, HurtigCopy.og).toLowerCase())} fra ${v.butikk}')}', 'spent', const [], vent: 450);
  }

  // ── build ───────────────────────────────────────────────────────────────

  String get _aegilBilde {
    if (_tenker) return 'find';
    if (_fase == 'teller' || _fase == 'venter' || _plasserer) return 'wait';
    if (_fase == 'bestilt') return 'front';
    return 'popup';
  }

  @override
  Widget build(BuildContext context) {
    // Lys: the teal header stays in both modes, so the status bar keeps its light icons (the
    // root region sets dark ones in Lys).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: modusStatusMork,
      child: Scaffold(
      backgroundColor: kHbTealDeep,
      resizeToAvoidBottomInset: false,
      body: LfFrame(
        child: LfOnce(
          ms: 340,
          builder: (context, t, child) {
            // skjermInn .34s cubic-bezier(.2,.9,.3,1)
            final p = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 340));
            return Opacity(
              opacity: kf(p, const [0, .55, 1], const [0, 1, 1]),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.978 + .022 * p, .978 + .022 * p, 1, 1),
                child: child,
              ),
            );
          },
          child: _skjerm(context),
        ),
      ),
    ),
    );
  }

  Widget _skjerm(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topp = mq.padding.top;
    final bunn = math.max(mq.padding.bottom, mq.viewInsets.bottom);
    final d = _d;
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], stops: [0, .4, 1]),
            ),
          ),
        ),
        // The warm band (200px): two glows, the gradient, the fine stripes
        // and the sun disc.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 200 + topp,
          child: ClipRect(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CssBox(
                    bg: [
                      CssRadial([Color.fromRGBO(255, 168, 118, .34), Color.fromRGBO(255, 168, 118, 0)], stops: [0, .62], rx: .7, ry: 1, cx: .88, cy: 0),
                      CssRadial([Color.fromRGBO(127, 240, 203, .2), Color.fromRGBO(127, 240, 203, 0)], stops: [0, .6], rx: .7, ry: .8, cx: .06, cy: 0),
                      CssLinear(180, [Color(0xFF3E7787), Color(0xFF2C6576), Color(0xFF1F5260)], [0, .52, 1]),
                    ],
                  ),
                ),
                const Positioned.fill(child: CustomPaint(painter: _Striper())),
                Positioned(
                  right: -30,
                  top: -70 + topp,
                  width: 240,
                  height: 240,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Color.fromRGBO(255, 214, 170, .3), Color.fromRGBO(255, 214, 170, 0)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Header: back key and the «Kjenner N bestillinger» pill.
        Positioned(
          left: 16,
          right: 16,
          top: 14 + topp,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                label: HurtigCopy.tilbake,
                child: HbPress(
                  scale: .94,
                  ms: 140,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: CssBox(
                    width: 40,
                    height: 40,
                    radius: BorderRadius.circular(14),
                    bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .08)])],
                    shadows: const [
                      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
                      CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .2)),
                      CssShadow(0, 8, 14, -8, Color.fromRGBO(2, 12, 18, .8)),
                    ],
                    child: const Center(child: HbIkon(HbIkoner.tilbake, size: 16, stroke: Colors.white, width: 2.4)),
                  ),
                ),
              ),
              CssBox(
                height: 30,
                radius: BorderRadius.circular(999),
                bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .28))],
                shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(159, 240, 212, .35))],
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const CssDecoration(
                        shape: BoxShape.circle,
                        color: kHbMint,
                        boxShadow: [BoxShadow(color: kHbMint, blurRadius: 8 / 2 / .57735)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(HurtigCopy.laert(d?.hist.length ?? 0), style: hbI(11, weight: FontWeight.w800, color: const Color(0xFFDFF8EE))),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Title block.
        Positioned(
          left: 18,
          top: 68 + topp,
          width: 238,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HbIkon(HbIkoner.lyn, size: 11, fill: Color(0xFFF2C14E)),
                  const SizedBox(width: 6),
                  Text(HurtigCopy.kicker, style: hbI(10.5, weight: FontWeight.w800, em: .1, color: kHbMintPale)),
                ],
              ),
              const SizedBox(height: 5),
              Text(HurtigCopy.tittel, style: hbJ(27, em: -.03, height: 1.05, color: Colors.white)),
              const SizedBox(height: 6),
              LfPretty(HurtigCopy.under, style: hbI(12.5, color: const Color(0xFFD3E6EA), height: 1.4)),
            ],
          ),
        ),
        // Ægil's shadow and Ægil in one of four moods.
        Positioned(
          right: 26,
          top: 170 + topp,
          width: 92,
          height: 14,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color.fromRGBO(0, 15, 22, .55), Color.fromRGBO(0, 15, 22, 0)]),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 70 + topp,
          width: 112,
          child: IgnorePointer(child: _Aegil(bilde: _aegilBilde)),
        ),
        // The sheet. Lys: `.mk1e` `--lys-ull` + `--lys-arkskygge`; the handle `.mk1f` white with the kant ring.
        Positioned(
          left: 0,
          right: 0,
          top: 176 + topp,
          bottom: 0,
          child: CssBox(
            radius: const BorderRadius.vertical(top: Radius.circular(30)),
            bg: context.aeM(
              const [
                CssRadial([Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .4, cx: .14, cy: 0),
                CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .4, 1]),
              ],
              const [CssSolid(LysPalett.ull)],
            ),
            shadows: context.aeM(const [
              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
              CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
              CssShadow(0, -24, 50, -18, Color.fromRGBO(4, 18, 26, .8)),
            ], LysPalett.arkskygge),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: context.aeM(const Color.fromRGBO(255, 255, 255, .28), LysPalett.hvit),
                        boxShadow: context.aeM(const <BoxShadow>[], const [BoxShadow(color: LysPalett.kantFarge, spreadRadius: 1)]),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 22,
                  bottom: 132 + bunn,
                  child: _liste(context),
                ),
                Positioned(left: 0, right: 0, bottom: 0, child: _bunn(context, bunn)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _liste(BuildContext context) {
    final d = _d;
    final sist = _hb.lastIndexWhere((m) => !m.meg);
    final kontekst = <String>[];
    if (d != null) {
      final n = _h.now;
      kontekst.addAll([
        '${_h.stor(_h.dag())} ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}',
        switch (_vaer) {
          BergenWeather.regn => 'Regn',
          BergenWeather.sol => 'Sol',
          BergenWeather.solnedgang => 'Blåtime',
          BergenWeather.natt => 'Natt',
        },
        if (d.adresse.isNotEmpty) d.adresse,
        HurtigCopy.personer(_h.hus(_st)),
        HurtigCopy.vipps,
      ]);
    }
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // «ÆGIL TAR HENSYN TIL» + Start på nytt, and the context chips.
            // Lys: `.mk1g` `--lys-dempet`; «Start på nytt» `.mk1h` / the chips `.mk1j`: white, the kant
            // ring, `--lys-sekundar`; the icon `.mk1i`.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(HurtigCopy.tarHensyn, style: hbI(10, weight: FontWeight.w800, em: .1, color: context.aeM(const Color.fromRGBO(255, 255, 255, .58), LysPalett.dempet))),
                HbPress(
                  dy: 1.5,
                  onTap: _ny,
                  child: CssBox(
                    radius: BorderRadius.circular(999),
                    bg: [CssSolid(context.aeM(const Color.fromRGBO(255, 255, 255, .08), LysPalett.hvit))],
                    shadows: context.aeM(const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14))], kHbLysRing),
                    padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HbIkon(HbIkoner.omstart, size: 10, stroke: context.aeM(kHbMintPale, kHbLysIkon), width: 2.8),
                        const SizedBox(width: 5),
                        Text(HurtigCopy.startPaaNytt, style: hbI(10.5, weight: FontWeight.w800, color: context.aeM(const Color(0xFFBFD6DD), LysPalett.sekundar))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in kontekst)
                  CssBox(
                    radius: BorderRadius.circular(999),
                    bg: [CssSolid(context.aeM(const Color.fromRGBO(255, 255, 255, .08), LysPalett.hvit))],
                    shadows: context.aeM(const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14))], kHbLysRing),
                    padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: kHbMint)),
                        const SizedBox(width: 5),
                        Text(c, style: hbI(11, weight: FontWeight.w700, color: context.aeM(const Color(0xFFDCE9EC), LysPalett.sekundar))),
                      ],
                    ),
                  ),
              ],
            ),
            for (var i = 0; i < _hb.length; i++) ...[
              const SizedBox(height: 14),
              _hb[i].meg ? _megBoble(_hb[i]) : _aegBoble(_hb[i], forst: i == 0 || _hb[i - 1].meg, sist: i == sist && !_tenker),
            ],
            if (_tenker) ...[const SizedBox(height: 14), const _Tenker()],
            if (_utkast != null) ...[const SizedBox(height: 14), _utkastKort()],
          ],
        ),
      ),
    );
  }

  // Lys: `.mk1k` `--lys-fjord-fyll`, `0 8px 14px -10px rgba(23,62,72,.5)`, white text.
  Widget _megBoble(_Melding m) => Padding(
    key: ValueKey('m${m.id}'),
    padding: const EdgeInsets.only(left: 56),
    child: Align(
      alignment: Alignment.centerRight,
      child: VcMeg(
        child: CssBox(
          radius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(20)),
          bg: context.aeM(const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF2F2)])], LysPalett.fjordFyll),
          shadows: context.aeM(const [
            CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
            CssShadow(0, 2.5, 0, 0, Color(0xFF9FB3B8)),
            CssShadow(0, 12, 18, -12, Color.fromRGBO(3, 16, 24, .8)),
          ], const [CssShadow(0, 8, 14, -10, Color.fromRGBO(23, 62, 72, .5))]),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          child: LfPretty(m.tekst, style: hbI(14, weight: FontWeight.w700, height: 1.4, color: context.aeM(kHbTealDeep, Colors.white))),
        ),
      ),
    ),
  );

  Widget _aegBoble(_Melding m, {required bool forst, required bool sist}) {
    final d = _d!;
    final knapper = sist ? m.knapper : const <HbKnapp>[];
    Widget? kort;
    if (m.modul == 'oftest' && d.hist.isNotEmpty) {
      kort = HbOftestKort(
        rader: _rader(),
        under: HurtigCopy.oftUnder(d.hist.length, HurtigCopy.maaned(d.hist.last.naar.month)),
        vane: _vaneVis(),
        onVelg: _velg,
        onVane: _vaneFn,
      );
    } else if (m.modul == 'forrige' && d.hist.isNotEmpty) {
      kort = HbForrigeKort(
        fo: _ordreVis(d.hist.first, full: true),
        tidligere: [for (final o in d.hist.skip(1).take(2)) _ordreVis(o)],
        onIgjen: _igjen,
      );
    } else if (m.modul == 'pref') {
      final p = _h.prefForslag(_st);
      final hus = _h.hus(_st);
      final l0 = p == null || p.linjer.isEmpty ? null : _h.vare(p.linjer.first.id);
      kort = HbPrefKort(
        under: HurtigCopy.laertAv(d.hist.length),
        liker: d.minne.liker,
        butikker: [for (final n in d.minne.butikker) d.butikkNavn(n)],
        hus: hus,
        onHusMinus: () => setState(() => _hus = math.max(1, hus - 1)),
        onHusPluss: () => setState(() => _hus = math.min(8, hus + 1)),
        unngaaSkalldyr: _h.unngaaSkalldyr(_st),
        onSkalldyr: () => setState(() => _skalldyr = !_h.unngaaSkalldyr(_st)),
        middagDager: [for (final m in d.minne.middag) m.toLowerCase()],
        idag: HurtigCopy.dagerNo[(DateTime.now().weekday - 1).clamp(0, 6)],
        kl: d.minne.middagKl.replaceAll(RegExp(r':00$'), ''),
        forslag: p == null
            ? null
            : HbPrefForslagVis(
                linje: _h.tekst(p.linjer),
                butikk: '${p.butikk} · ${_h.klar(p.utkast).toLowerCase()}',
                grunner: p.grunner,
                sum: HurtigCopy.kr(_h.sum(p.utkast).total),
                retter: p.linjer.fold<int>(0, (a, x) => a + (x.ant < 1 ? 1 : x.ant)),
                wok: RegExp('wok|thai', caseSensitive: false).hasMatch(p.butikk),
                bilde: l0?.bilde,
                onTap: () {
                  AeHaptikk.tikk();
                  _settUtkast(p.butikkId, p.butikk, p.linjer);
                  _aegil(HurtigCopy.sattOppEtterPref, 'spent', const [], vent: 450);
                },
              ),
        onMinne: () => BergenRoutes.push(context, '/bergen/aegil/minne'),
      );
    } else if (m.modul == 'bestilt' && m.ordre != null) {
      final o = m.ordre!;
      kort = HbBestiltKort(
        kode: o.kode,
        butikk: o.butikk,
        klar: o.klar,
        linje: o.linje,
        kr: HurtigCopy.aerendKroner((o.total / 10).floor()),
        sum: HurtigCopy.kr(o.total),
        onFolg: () => _folg(o),
      );
    }
    // New Bergen: the cards take the full width (`width:calc(100% + 41px);
    // margin-left:-41px`), under the portrait column; the keys stay in it.
    return Column(
      key: _aegKeys.putIfAbsent(m.id, GlobalKey.new),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: forst ? const Padding(padding: EdgeInsets.only(top: 2), child: _Portrett()) : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lys: `.mk1m` white, the kant ring + `--lys-kortskygge`, `--lys-brod`.
                  VcBoble(
                    child: CssBox(
                      radius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(6)),
                      bg: context.aeM(
                        const [
                          CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .06)]),
                        ],
                        const [CssSolid(LysPalett.hvit)],
                      ),
                      shadows: context.aeM(const [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
                        CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .45)),
                        CssShadow(0, 16, 22, -16, Color.fromRGBO(3, 14, 20, .85)),
                      ], _lysBobleSkygge),
                      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                      child: LfPretty(m.tekst, style: hbI(14.5, height: 1.45, color: context.aeM(Colors.white, LysPalett.brod))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (kort != null) ...[const SizedBox(height: 9), VcKort(delayMs: 120, child: kort)],
        if (knapper.isNotEmpty) ...[
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.only(left: 41),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var j = 0; j < knapper.length; j++)
                  VcKnapp(
                    key: ValueKey('k${m.id}-$j'),
                    delayMs: 250 + j * 70,
                    child: HbPress(
                      dy: 2.5,
                      onTap: () => _knapp(knapper[j].h),
                      child: knapper[j].primar
                          ? CssBox(
                              height: 38,
                              radius: BorderRadius.circular(13),
                              bg: const [
                                CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
                              ],
                              shadows: const [
                                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                                CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                                CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .75)),
                              ],
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const HbIkon(HbIkoner.lyn, size: 11, fill: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    knapper[j].tekst,
                                    style: hbI(12.5, weight: FontWeight.w800, color: Colors.white, tabular: true),
                                  ),
                                ],
                              ),
                            )
                          // Lys: `.mk2o` white, kant, `--lys-tittel`.
                          : CssBox(
                              height: 38,
                              radius: BorderRadius.circular(13),
                              bg: [CssSolid(context.aeM(const Color.fromRGBO(255, 255, 255, .08), LysPalett.hvit))],
                              border: Border.all(color: context.aeM(const Color.fromRGBO(255, 255, 255, .12), LysPalett.kantFarge)),
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Center(
                                child: Text(
                                  knapper[j].tekst,
                                  style: hbI(12.5, weight: FontWeight.w800, color: context.aeM(Colors.white, LysPalett.tittel)),
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _utkastKort() {
    final U = _utkast!;
    final bt = _h.b(U.butikkId, U.butikk);
    final s = _h.sum(U);
    final forslag = _h.forslagFor(U, _st);
    final tid = HurtigHjerne.klokkeslett(U.tid);
    return VcKort(
      key: ValueKey('utkast-${U.butikkId}'),
      child: HbUtkastKort(
        ini: bt.ini,
        bg: bt.bg,
        fg: bt.fg,
        butikk: U.butikk,
        klar: _h.klar(U),
        linjer: [
          for (final l in U.linjer)
            if (_h.vare(l.id) case final v?)
              HbUtkastLinjeVis(
                id: l.id,
                navn: v.navn,
                bilde: v.bilde,
                enhet: KasseCopy.tall(v.pris),
                ant: l.ant,
                sum: KasseCopy.tall(v.pris * l.ant),
                ut: _ut.contains(l.id),
                onMinus: () => _endre(l.id, -1),
                onPluss: () => _endre(l.id, 1),
              ),
        ],
        forslag: [for (final v in forslag) HbForslagVis(navn: v.navn, pris: HurtigCopy.kr(v.pris), onTap: () => _endre(v.id, 1))],
        varer: s.varer,
        levGratis: s.lev == 0,
        levPst: bt.gratisOver > 0 ? math.min(1, s.varer / bt.gratisOver) : 1,
        levTekst: s.lev == 0 ? HurtigCopy.gratisLevering : HurtigCopy.tilGratisLevering(HurtigCopy.kr(bt.gratisOver - s.varer)),
        kasseTekst: HurtigCopy.kasseTekst(tid),
        cta: HurtigCopy.gaaTilKassen(HurtigCopy.kr(s.varer)),
        onCta: _plasserer ? null : _tilKassen,
        signatur: '${U.butikkId}|${U.linjer.map((l) => l.id).join(',')}',
      ),
    );
  }

  Widget _bunn(BuildContext context, double bunn) {
    final harTekst = _tekst.text.trim().isNotEmpty;
    // Lys: `.mk31` the fade into `--lys-ull`.
    return Container(
      padding: EdgeInsets.fromLTRB(14, 20, 14, 16 + bunn),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.aeM(
            const [Color.fromRGBO(23, 62, 72, 0), Color.fromRGBO(23, 62, 72, .96), Color(0xFF173E48)],
            const [Color.fromRGBO(247, 251, 253, 0), Color.fromRGBO(247, 251, 253, .96), LysPalett.ull],
          ),
          stops: const [0, .22, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer Step 14: «Bestill med en annen AI» (design L4563–4567, `hbAiSub`).
          if (ClientFlags.on(ClientFlags.aiLinking) || AiStore.instance.harness) ...[_aiRad(context), const SizedBox(height: 9)],
          Row(
            children: [
              for (final (i, (k, ikon, tekst)) in [('oftest', HbIkoner.modOftest, HurtigCopy.modOftest), ('forrige', HbIkoner.modForrige, HurtigCopy.modForrige), ('pref', HbIkoner.modPref, HurtigCopy.modPref)].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _modul(k, ikon, tekst)),
              ],
            ],
          ),
          const SizedBox(height: 9),
          _felt(context, harTekst),
        ],
      ),
    );
  }

  /// The input pill (new Bergen L4541–4545, `hbFelt*` / `hbLyn*` / `hbSend*`
  /// L15941–15947). Focused, it lifts 2 px, turns a lighter teal with a mint
  /// border, ring and glow, and — while still empty — a mint shine sweeps
  /// across (`bioSkann 2.4s`); the bolt warms and grows (and turns once
  /// there is text); the send button wakes from grey to full orange.
  Widget _felt(BuildContext context, bool t) {
    final f = _fokus.hasFocus;
    Duration d(int ms) => BergenPerf.oneShot(context, ms);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: f ? 1 : 0),
      duration: d(350),
      curve: const Cubic(.3, 1.4, .5, 1),
      builder: (context, y, child) => Transform.translate(offset: Offset(0, -2 * y), child: child),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: f ? 1 : 0),
        duration: d(400),
        curve: const Cubic(.3, 1, .4, 1),
        builder: (context, r, child) => TweenAnimationBuilder<double>(
          tween: Tween(end: f ? 1 : 0),
          duration: d(300),
          curve: cssEase,
          // Lys (`hbFeltBg` / `hbFeltBd`, L19121; `.mk36` `--v0`): white, the border from the kant to
          // `rgba(11,107,87,.45)`, the lighter drop.
          builder: (context, c, child) => CssBox(
            height: 54,
            radius: BorderRadius.circular(999),
            bg: context.aeM(
              [
                CssLinear(180, [
                  Color.lerp(const Color(0xFF2B5F6E), const Color(0xFF33707F), c)!,
                  Color.lerp(const Color(0xFF1E4F5C), const Color(0xFF22596A), c)!,
                ]),
              ],
              const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFFFFFFF)])],
            ),
            border: Border.all(
              color: context.aeM(
                Color.lerp(const Color.fromRGBO(255, 255, 255, .28), const Color.fromRGBO(127, 240, 203, .8), c)!,
                Color.lerp(LysPalett.kantFarge, const Color.fromRGBO(11, 107, 87, .45), c)!,
              ),
            ),
            shadows: [
              const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
              CssShadow(0, 0, 0, 4 * r, const Color.fromRGBO(92, 224, 184, .16)),
              CssShadow(0, 0, 26, -6, Color.fromRGBO(92, 224, 184, .55 * r)),
              context.aeM(const CssShadow(0, 18, 34, -14, Color.fromRGBO(4, 18, 26, .85)), const CssShadow(0, 10, 24, -14, Color.fromRGBO(23, 62, 72, .22))),
            ],
            child: child,
          ),
          child: child,
        ),
        child: Stack(
          children: [
            // `hbFeltSveipOp`: the shine, only while focused and empty.
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: f && !t ? 1 : 0),
                    duration: d(300),
                    curve: cssEase,
                    builder: (context, o, child) => o <= 0 ? const SizedBox.shrink() : Opacity(opacity: o, child: child),
                    child: LayoutBuilder(
                      builder: (context, box) => RepaintBoundary(
                        child: LfLoop(
                          builder: (context, ms, child) {
                            final w = box.maxWidth * .3;
                            final p = (ms / 2400) % 1.0;
                            return Transform.translate(offset: Offset(-w + w * (-1 + 4.4 * p), 0), child: child);
                          },
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: .3,
                              heightFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Color.fromRGBO(127, 240, 203, 0), Color.fromRGBO(127, 240, 203, .18), Color.fromRGBO(127, 240, 203, 0)]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // `hbLynSk` / `hbLynRot` (.4s spring) and `hbLynC` (.3s ease).
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: f ? 1 : 0),
                    duration: d(300),
                    curve: cssEase,
                    builder: (context, c, _) => TweenAnimationBuilder<double>(
                      tween: Tween(end: t ? 2 : (f ? 1 : 0)),
                      duration: d(400),
                      curve: const Cubic(.3, 1.6, .5, 1),
                      builder: (context, k, child) => Transform.rotate(
                        angle: -12 * math.max(0, k - 1) * math.pi / 180,
                        child: Transform.scale(scale: 1 + .1 * k, child: child),
                      ),
                      // `hbLynC`: `#FFB48E` / Lys `#DD5A25` when focused.
                      child: HbIkon(HbIkoner.lyn, size: 14, fill: Color.lerp(const Color(0xFFF26D3D), context.aeM(const Color(0xFFFFB48E), const Color(0xFFDD5A25)), c)!),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Semantics(
                      label: HurtigCopy.skrivTilAegil,
                      child: TextField(
                        key: const Key('a1_hurtig_felt'),
                        controller: _tekst,
                        focusNode: _fokus,
                        // Lys: `.mk12` `--lys-tittel`, caret `--lys-mint-tekst`.
                        style: hbJ(14, weight: FontWeight.w700, color: context.aeM(Colors.white, LysPalett.tittel)),
                        cursorColor: context.aeM(kHbMint, LysPalett.mintTekst),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          isDense: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: HurtigCopy.placeholder,
                          hintStyle: hbJ(14, weight: FontWeight.w700, color: const Color(0xFFA9A9A9)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Semantics(
                    button: true,
                    label: HurtigCopy.sendTilAegil,
                    child: HbPress(
                      scale: .92,
                      ms: 140,
                      onTap: () => _send(_tekst.text),
                      child: _HbSend(paa: t),
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

  /// «Bestill med en annen AI» (design L4563–4567): the three marks stacked,
  /// the line from the linked list (`hbAiSub`), the round chevron → aiVelg.
  Widget _aiRad(BuildContext context) => ListenableBuilder(
    listenable: AiStore.instance,
    builder: (_, __) {
      final l = AiStore.instance.aktive.where((x) => x.vendor != 'siri').firstOrNull;
      Widget merke(String n, double left) => Positioned(
        left: left,
        top: 0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), boxShadow: const [BoxShadow(color: Color(0xFF2A5B69), spreadRadius: 2)]),
          child: AiMerke(n, size: 28, radius: 9),
        ),
      );
      return HbPress(
        dy: 2,
        onTap: () => AiArk.flyt(context, 'velg', fraHurtig: true),
        child: CssBox(
          key: const Key('cus-ai-hurtig-rad'),
          height: 50,
          radius: BorderRadius.circular(16),
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          // Lys: `.mk32` white with the kant ring; the title `.mkb`, the line `.mk33`, the chevron disc
          // `.mk34` `--lys-dis` + `.mku` `#1E4F5C` (the marks' rings are inline).
          bg: context.aeM(const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)])], const [CssSolid(LysPalett.hvit)]),
          shadows: context.aeM(const [
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
            CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
            CssShadow(0, 3, 0, 0, Color.fromRGBO(6, 22, 30, .6)),
            CssShadow(0, 12, 18, -12, Color.fromRGBO(2, 12, 18, .9)),
          ], kHbLysRing),
          child: Row(
            children: [
              SizedBox(width: 68, height: 28, child: Stack(clipBehavior: Clip.none, children: [merke('Gemini', 40), merke('ChatGPT', 20), merke('Claude', 0)])),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AiCopy.cus_ai_hurtig_rad, maxLines: 1, overflow: TextOverflow.ellipsis, style: hbI(12.5, weight: FontWeight.w800, height: 1.2, color: context.aeM(Colors.white, LysPalett.tittel))),
                    const SizedBox(height: 1),
                    Text(l != null ? AiCopy.cus_ai_hurtig_sub_koblet(l.name) : AiCopy.cus_ai_hurtig_sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: hbI(10.5, weight: FontWeight.w600, color: context.aeM(const Color.fromRGBO(255, 255, 255, .62), LysPalett.sekundar))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: CssDecoration(
                  shape: BoxShape.circle,
                  color: context.aeM(const Color.fromRGBO(255, 255, 255, .12), LysPalett.dis),
                  boxShadow: context.aeM(const [BoxShadow(color: Color.fromRGBO(255, 255, 255, .18), spreadRadius: 1)], const <BoxShadow>[]),
                ),
                child: Center(child: HbIkon('M9 6l6 6-6 6', size: 12, stroke: context.aeM(Colors.white, const Color(0xFF1E4F5C)), width: 3)),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _modul(String k, String ikon, String tekst) {
    final a = _modAktiv == k;
    return HbPress(
      dy: 2,
      onTap: () => _send(_modTekst(k), modul: k),
      // CssBox, not a Container: a box-shadow never shows through its own
      // translucent glass (the dark drop made the chips look black).
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: a ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        curve: cssEase,
        // Lys: `.mk35` white with `--v0` `0 1px 2px rgba(23,62,72,.06), 0 10px 24px -14px rgba(23,62,72,.22)`;
        // the ring (`hbVals` L19094) from the kant to `rgba(11,107,87,.45)`.
        builder: (context, r, child) => CssBox(
          height: 50,
          radius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          bg: context.aeM(const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)])], const [CssSolid(LysPalett.hvit)]),
          shadows: context.aeM([
            const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
            CssShadow(0, 0, 0, 1 + .5 * r, Color.lerp(const Color.fromRGBO(255, 255, 255, .16), const Color.fromRGBO(127, 240, 203, .9), r)!),
            const CssShadow(0, 3, 0, 0, Color.fromRGBO(6, 22, 30, .6)),
            const CssShadow(0, 12, 18, -12, Color.fromRGBO(2, 12, 18, .9)),
          ], [
            const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
            CssShadow(0, 0, 0, 1 + .5 * r, Color.lerp(LysPalett.kantFarge, const Color.fromRGBO(11, 107, 87, .45), r)!),
            const CssShadow(0, 1, 2, 0, Color.fromRGBO(23, 62, 72, .06)),
            const CssShadow(0, 10, 24, -14, Color.fromRGBO(23, 62, 72, .22)),
          ]),
          child: child,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: a
                    ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8CF0D2), Color(0xFF3CC79F)])
                    : context.aeM(
                        const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .24), Color.fromRGBO(255, 255, 255, .1)]),
                        const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [LysPalett.dis, LysPalett.dis]),
                      ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .4), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .05]),
              ),
              child: Center(child: HbIkon(ikon, size: 15, stroke: a ? const Color(0xFF0F3A40) : context.aeM(Colors.white, LysPalett.fjord), width: 2.4)),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(tekst, style: hbI(11, weight: FontWeight.w800, height: 1.15, color: context.aeM(Colors.white, LysPalett.tittel)))),
          ],
        ),
      ),
    );
  }
}

/// Ægil's portrait in the chat: the teal disc with front.png cropped to the
/// face (`left:-30% top:-8% width:160%`).
class _Portrett extends StatelessWidget {
  const _Portrett();

  // Lys: `.mk1l` white with the kant ring.
  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: context.aeM(
        const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFF4A93A4), Color(0xFF1E4F5C)]),
        const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [LysPalett.hvit, LysPalett.hvit]),
      ),
      boxShadow: context.aeM(const [
        BoxShadow(color: Color.fromRGBO(255, 255, 255, .85), spreadRadius: 2),
        BoxShadow(color: Color.fromRGBO(3, 16, 24, .7), offset: Offset(0, 6), blurRadius: 10 / 2 / .57735, spreadRadius: -4),
      ], const [BoxShadow(color: LysPalett.kantFarge, spreadRadius: 1)]),
    ),
    child: ClipOval(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -32 * .3,
            top: -32 * .08,
            width: 32 * 1.6,
            height: 32 * 1.6,
            child: Image.asset('assets/images/dashboard/front.png', fit: BoxFit.cover, alignment: Alignment.topCenter, filterQuality: FilterQuality.medium),
          ),
        ],
      ),
    ),
  );
}

/// «Sjekker vanene dine»: the portrait with the pulse ring and the three
/// bouncing dots (`vcPuls`, `vcPrikk`).
class _Tenker extends StatelessWidget {
  const _Tenker();

  @override
  Widget build(BuildContext context) => BergenEssential(child: _essentialBuild(context));

  Widget _essentialBuild(BuildContext context) => VcBoble(
    ms: 350,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -4,
                top: -4,
                right: -4,
                bottom: -4,
                child: RepaintBoundary(
                  child: LfLoop(
                    builder: (context, t, child) {
                      final p = cssEaseOut.transform((t / 1400) % 1.0);
                      return Opacity(
                        opacity: .9 * (1 - p),
                        child: Transform.scale(scale: .9 + .45 * p, child: child),
                      );
                    },
                    child: const DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Color.fromRGBO(92, 224, 184, .7), width: 1.5))),
                    ),
                  ),
                ),
              ),
              const _Portrett(),
            ],
          ),
        ),
        const SizedBox(width: 9),
        CssBox(
          height: 40,
          radius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(6)),
          // Lys: `.mk2p` white with the kant ring; «Sjekker vanene dine» `.mk2q` (the dots are inline white).
          bg: context.aeM(const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .06)])], const [CssSolid(LysPalett.hvit)]),
          shadows: context.aeM(const [
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
            CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .45)),
            CssShadow(0, 16, 22, -16, Color.fromRGBO(3, 14, 20, .85)),
          ], kHbLysRing),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      LfLoop(
                        builder: (context, t, child) {
                          final p = kfLoop(t, 150.0 * i, 1100) ?? 0;
                          final y = kf(p, const [0, .3, .6, 1], const [0, -5, 0, 0], cssEaseInOut);
                          final o = kf(p, const [0, .3, .6, 1], const [.45, 1, .45, .45], cssEaseInOut);
                          return Opacity(opacity: o, child: Transform.translate(offset: Offset(0, y), child: child));
                        },
                        child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(HurtigCopy.sjekkerVanene, style: hbI(11.5, weight: FontWeight.w700, color: context.aeM(const Color(0xFFBFD6DD), LysPalett.sekundar))),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Ægil at the top right: popup (glad, `aegStaa 3.8s`), find (tenker,
/// `aegKikk 2.4s`), wait (venter, `aegStaa 2.6s`), front (ferdig,
/// `aegHopp 2.4s`).
class _Aegil extends StatelessWidget {
  const _Aegil({required this.bilde});
  final String bilde;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: LfLoop(
        key: ValueKey(bilde),
        builder: (context, t, child) {
          final Matrix4 m;
          switch (bilde) {
            case 'find':
              final p = (t / 2400) % 1.0;
              m = Matrix4.rotationZ(rad(kf(p, const [0, .5, 1], const [-4, 4, -4], cssEaseInOut)));
            case 'wait':
              m = aegStaa(t, 2600);
            case 'front':
              final p = (t / 2400) % 1.0;
              final y = kf(p, const [0, .3, .55, .7, 1], const [0, -10, 0, -4, 0], cssEaseInOut);
              final r = kf(p, const [0, .3, .55, .7, 1], const [0, -3, 0, 0, 0], cssEaseInOut);
              m = Matrix4.translationValues(0, y, 0)..rotateZ(rad(r));
            default:
              m = aegStaa(t, 3800);
          }
          return Transform(alignment: Alignment.bottomCenter, transform: m, child: child);
        },
        child: Image.asset('assets/images/dashboard/$bilde.png', width: 112, filterQuality: FilterQuality.medium),
      ),
    ),
  );
}

/// `repeating-linear-gradient(104deg, transparent 0 13px, white .04 13px 14px)`.
class _Striper extends CustomPainter {
  const _Striper();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, .04)
      ..strokeWidth = 1;
    // 104°: the gradient line points right and slightly down; the stripes
    // run perpendicular to it.
    final a = rad(104);
    final dir = Offset(math.sin(a), -math.cos(a));
    final perp = Offset(-dir.dy, dir.dx);
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    final c = Offset(size.width / 2, size.height / 2);
    for (var k = -diag; k < diag; k += 14) {
      final o = c + dir * k;
      canvas.drawLine(o + perp * diag, o - perp * diag, p);
    }
  }

  @override
  bool shouldRepaint(_Striper o) => false;
}

/// The send button (`hbSendOp/Sk/Sat/Ring`): .55 opacity, .92 scale and
/// 45 % saturation while empty; full, 1.06 and an orange ring with text.
class _HbSend extends StatelessWidget {
  const _HbSend({required this.paa});

  final bool paa;

  static List<double> _metning(double s) => [
    .213 + .787 * s, .715 - .715 * s, .072 - .072 * s, 0, 0,
    .213 - .213 * s, .715 + .285 * s, .072 - .072 * s, 0, 0,
    .213 - .213 * s, .715 - .715 * s, .072 + .928 * s, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    Duration d(int ms) => BergenPerf.oneShot(context, ms);
    final v = paa ? 1.0 : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: v),
      duration: d(250),
      curve: cssEase,
      builder: (context, o, child) => Opacity(
        opacity: .55 + .45 * o,
        child: o >= 1 ? child : ColorFiltered(colorFilter: ColorFilter.matrix(_metning(.45 + .55 * o)), child: child),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v),
        duration: d(350),
        curve: const Cubic(.3, 1.6, .5, 1),
        builder: (context, k, child) => Transform.scale(scale: .92 + .14 * k, child: child),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: v),
          duration: d(350),
          curve: cssEase,
          builder: (context, r, _) => CssBox(
            width: 42,
            height: 42,
            radius: BorderRadius.circular(21),
            bg: const [CssLinear(160, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
            shadows: [
              const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
              const CssShadow(0, 2.5, 0, 0, Color(0xFFA63A12)),
              const CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .75)),
              CssShadow(0, 0, 0, 4 * r, const Color.fromRGBO(242, 109, 61, .22)),
            ],
            child: const Center(child: HbIkon(HbIkoner.send, size: 17, stroke: Colors.white, width: 2.8)),
          ),
        ),
      ),
    );
  }
}
