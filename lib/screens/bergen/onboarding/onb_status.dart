import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../../services/customer/beacons.dart';
import '../../../services/customer/client_flags.dart';
import '../../../utils/shared_pref_utill.dart';
import 'onb_tips.dart';

/// What the tour and the coach marks have shown (Onboarding plan Step 3,
/// decision D4; the prototype's `vkLagret()` in `aerend.onb.v2`).
///
/// The local cache is the source of truth during a session: it answers at
/// once and offline. It syncs with `GET/PUT api/ops/customer/onboarding`
/// fire-and-forget; the server wins for `completed_at` / `skipped_at`, the
/// seen sets are a union. Guests keep the local cache only.
class OnbStatus extends ChangeNotifier {
  OnbStatus._();

  static final OnbStatus instance = OnbStatus._();

  static const String _pref = 'aerend.onb.v2';

  /// The design's `VK_VERSJON`; the server's `config.version` wins.
  static const int kVersjon = 3;

  /// The surface flags (backend `CusFlags`): the tour and the coach marks.
  static const String flagg = 'cus.onboarding';
  static const String flaggTips = 'cus.onboarding.tips';

  // ── The state (`sett, ferdig, hoppet, versjon, cm, hjemKort, pos`) ─────
  Set<String> sett = {};
  bool ferdig = false, hoppet = false, hjemKort = false;

  /// The customer has seen a delivery land (`vkLevert`, kept across restarts).
  bool levert = false;
  int versjon = 0;

  /// Coach marks shown: id → epoch ms (Step 4), and the ones acted on.
  Map<String, int> cm = {};
  Set<String> cmHandlet = {};

  /// The position answer: `tillatt` / `avslatt`, null before any.
  String? pos;

  /// The server's version and coach-mark caps (`config`).
  int serverVersjon = kVersjon;
  int cmSesjon = 1, cmDag = 3, cmAutoSek = 8, cmPrikkDager = 7;

  bool _lastet = false;
  bool get lastet => _lastet;
  Future<void>? _laster;

  /// The session arrived on a task (`handoff` from an assistant, `push`):
  /// no tour this session (docx §2), the arrival peek instead (Step 4).
  String? ankomst;

  /// The handoff screen was left: Step 4's `handoff` peek may show.
  bool handoffKlar = false;

  /// Debug: forget the server's answer this session (`onbNull`).
  bool ignorerServer = false;

  OpsCustomerApi Function() api = OpsCustomerApi.new;

  /// The tour's flag is on (false until the server has answered once).
  static bool get paa => ClientFlags.on(flagg);
  static bool get tipsPaa => ClientFlags.on(flaggTips);

  /// «Nytt» on the Meg row: done before, and the server has a newer tour.
  bool get nyVersjon => ferdig && versjon < serverVersjon;

  /// The Hjem card «Vil du se hva mer Ærend kan?» (`vkHjemKort`).
  bool get visHjemKort => paa && levert && ferdig && !hjemKort;

  // ── Loading ─────────────────────────────────────────────────────────────

  /// Reads the cache, then the server (once per app run). Safe to call often.
  Future<void> last() => _laster ??= _last();

  Future<void> _last() async {
    _lesLokal();
    _lastet = true;
    notifyListeners();
    await _lesServer();
    OnbTips.instance.plan();
  }

  void _lesLokal() {
    try {
      final raw = prefGetString(_pref);
      if (raw.isEmpty) return;
      final j = jsonDecode(raw);
      if (j is! Map) return;
      sett = {for (final s in (j['sett'] as List? ?? const [])) '$s'};
      ferdig = j['ferdig'] == true;
      hoppet = j['hoppet'] == true;
      hjemKort = j['hjemKort'] == true;
      levert = j['levert'] == true;
      versjon = (j['versjon'] as num?)?.toInt() ?? 0;
      cm = {for (final e in ((j['cm'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num?)?.toInt() ?? 0};
      cmHandlet = {for (final s in (j['cmHandlet'] as List? ?? const [])) '$s'};
      final p = j['pos'];
      pos = p is String && p.isNotEmpty ? p : null;
    } catch (_) {}
  }

  void _skrivLokal() {
    try {
      prefSetString(
        _pref,
        jsonEncode({
          'sett': sett.toList(),
          'ferdig': ferdig,
          'hoppet': hoppet,
          'hjemKort': hjemKort,
          'levert': levert,
          'versjon': versjon,
          'cm': cm,
          'cmHandlet': cmHandlet.toList(),
          'pos': pos,
        }),
      );
    } catch (_) {}
  }

  Future<void> _lesServer() async {
    if (ignorerServer || OpsCustomerApi.authParams() == null) return;
    try {
      final j = await api().onboarding();
      if (j == null) return;
      final cfg = j['config'];
      if (cfg is Map) {
        serverVersjon = (cfg['version'] as num?)?.toInt() ?? serverVersjon;
        final c = cfg['coach_marks'];
        if (c is Map) {
          cmSesjon = (c['session_cap'] as num?)?.toInt() ?? cmSesjon;
          cmDag = (c['daily_cap'] as num?)?.toInt() ?? cmDag;
          cmAutoSek = (c['auto_dismiss_seconds'] as num?)?.toInt() ?? cmAutoSek;
          cmPrikkDager = (c['dot_days'] as num?)?.toInt() ?? cmPrikkDager;
        }
      }
      final s = j['state'];
      if (s is! Map || ignorerServer) return;
      if (s['completed_at'] != null) ferdig = true;
      if (s['skipped_at'] != null && !ferdig) hoppet = true;
      sett.addAll([for (final x in (s['steps_seen'] as List? ?? const [])) '$x']);
      final m = s['coach_marks_seen'];
      if (m is Map) {
        for (final e in m.entries) {
          final v = e.value;
          final at = v is Map ? DateTime.tryParse('${v['seen_at'] ?? ''}')?.millisecondsSinceEpoch : null;
          cm.putIfAbsent('${e.key}', () => at ?? DateTime.now().millisecondsSinceEpoch);
          if (v is Map && v['acted'] == true) cmHandlet.add('${e.key}');
        }
      }
      final p = s['position'];
      if (pos == null && p is String && p.isNotEmpty) pos = p;
      if (s['home_card_dismissed'] == true) hjemKort = true;
      final v = (s['onboarding_version'] as num?)?.toInt() ?? 0;
      if (v > versjon) versjon = v;
      _skrivLokal();
      notifyListeners();
      // Anything the cache knew that the server did not: send it up.
      _planSync();
    } catch (_) {}
  }

  // ── Writes (cache now, server soon) ─────────────────────────────────────

  Timer? _syncT;
  final Map<String, Object?> _ekstra = {};

  void _endret({Map<String, Object?> ekstra = const {}}) {
    _ekstra.addAll(ekstra);
    _skrivLokal();
    notifyListeners();
    _planSync();
  }

  void _planSync() {
    _syncT?.cancel();
    _syncT = Timer(const Duration(milliseconds: 600), _sync);
  }

  Future<void> _sync() async {
    if (OpsCustomerApi.authParams() == null) return;
    final body = <String, Object?>{
      'steps_seen': sett.take(64).toList(),
      'coach_marks_seen': {
        for (final e in cm.entries)
          e.key: {'seen_at': DateTime.fromMillisecondsSinceEpoch(e.value).toUtc().toIso8601String(), 'acted': cmHandlet.contains(e.key)},
      },
      'home_card_dismissed': hjemKort,
      if (pos != null) 'position': pos,
      if (versjon > 0) 'onboarding_version': versjon,
      if (ferdig) 'completed': true,
      ..._ekstra,
    };
    _ekstra.clear();
    try {
      await api().setOnboarding(body);
    } catch (_) {}
  }

  void merkSett(String steg) {
    if (sett.add(steg)) {
      _endret();
      CusBeacons.melde('onboarding_step_viewed', screen: 'onb', data: {'step': steg});
    }
  }

  /// «Hopp over» / «Senere» at [stegNr] (`rtAvslutt`).
  void merkHoppet(int stegNr, String steg) {
    if (!ferdig) hoppet = true;
    versjon = serverVersjon;
    _endret(ekstra: {'skipped_at_step': stegNr});
    CusBeacons.melde('onboarding_skipped', screen: 'onb', data: {'step': steg});
  }

  /// «Start å handle» (`rtSlutt`).
  void merkFerdig({required int msTotal}) {
    ferdig = true;
    hoppet = false;
    versjon = serverVersjon;
    _endret();
    CusBeacons.melde('onboarding_completed', screen: 'onb', data: {'ms_total': msTotal, 'location_result': pos ?? 'ingen'});
  }

  void merkPos(String svar) {
    pos = svar;
    _endret();
  }

  void merkLevert() {
    if (levert) return;
    levert = true;
    _endret();
  }

  void merkHjemKort() {
    hjemKort = true;
    _endret();
  }

  /// A coach mark was shown (Step 4); [handlet] when its action was used.
  void merkCm(String id, {bool handlet = false}) {
    cm[id] = DateTime.now().millisecondsSinceEpoch;
    if (handlet) cmHandlet.add(id);
    _endret();
  }

  void merkReplay() => CusBeacons.melde('onboarding_replayed', screen: 'onb');

  /// `vkNullstill`: forget everything locally (debug harness `onbNull`).
  void nullstill() {
    sett = {};
    ferdig = hoppet = hjemKort = levert = false;
    versjon = 0;
    cm = {};
    cmHandlet = {};
    pos = null;
    ankomst = null;
    handoffKlar = false;
    ignorerServer = true;
    _skrivLokal();
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _syncT?.cancel();
    sett = {};
    ferdig = hoppet = hjemKort = levert = false;
    versjon = 0;
    cm = {};
    cmHandlet = {};
    pos = null;
    ankomst = null;
    handoffKlar = false;
    ignorerServer = false;
    serverVersjon = kVersjon;
    _lastet = false;
    _laster = null;
    _ekstra.clear();
    api = OpsCustomerApi.new;
  }
}
