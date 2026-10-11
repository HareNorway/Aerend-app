import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../networking/ops/ops_customer_api.dart';

/// Support for the customer (Launch `scStart` / `scSvar` / `sakVals`,
/// L17965–18030): one conversation per problem, the Ærend assistant first and
/// a person when the customer asks, and the cases filed on an order.
///
/// Backend plan Step 5: everything is server-side now — `GET support/config`
/// (hours, answer time, phone, e-mail), the conversation (`/api/support/
/// conversations`, the assistant's rules run on the server, a person takes
/// over from the panel inbox and their replies arrive by polling), the
/// customer's cases (`GET support/cases`), and the guest step (`support/guest/
/// lookup` + `verify` → a guest token for that one order).
///
/// When the server can't be reached, a conversation falls back to the same
/// scripted rules on the device so the screen still answers (offline only).
abstract final class SupportConfig {
  /// The customer chat's hours (Oslo time) and the promised first answer.
  /// Prototype values until `support/config` answers.
  static int aapner = 8;
  static int stenger = 23;
  static int svarMin = 30;

  /// From `general_settings`; null hides the row that would use it.
  static String? telefon;
  static String epost = 'hjelp@aerend.no';
  static List<String> paaVakt = const [];

  static DateTime? _lastet;

  /// Reads `support/config` at most every five minutes.
  static Future<void> last(OpsCustomerApi api) async {
    final l = _lastet;
    if (l != null && DateTime.now().difference(l) < const Duration(minutes: 5)) return;
    final j = await api.supportConfig();
    if (j == null) return;
    settFra(j);
    _lastet = DateTime.now();
  }

  @visibleForTesting
  static void settFra(Map<String, dynamic> j) {
    final h = j['hours'] is Map ? j['hours'] as Map : const {};
    aapner = (h['opens'] as num?)?.toInt() ?? aapner;
    stenger = (h['closes'] as num?)?.toInt() ?? stenger;
    svarMin = (j['answer_minutes'] as num?)?.toInt() ?? svarMin;
    final tlf = '${j['phone'] ?? ''}'.trim();
    telefon = tlf.isEmpty ? null : tlf;
    final mail = '${j['email'] ?? ''}'.trim();
    if (mail.isNotEmpty) epost = mail;
    paaVakt = j['on_call'] is List ? [for (final n in j['on_call'] as List) '$n'] : const [];
  }

  static bool aapen([DateTime? naa]) {
    final h = (naa ?? DateTime.now()).hour;
    return h >= aapner && h < stenger;
  }

  static String get aapnerKl => '${aapner.toString().padLeft(2, '0')}:00';

  /// «08–23» for the e-mail line.
  static String get timer => '${aapner.toString().padLeft(2, '0')}–${stenger.toString().padLeft(2, '0')}';
}

/// A card under a message: ORDRE, SAK, REFUSJON or ÅPNINGSTID.
enum SupportKortType { ordre, sak, refusjon, aapningstid }

class SupportKort {
  const SupportKort({required this.type, this.ref, required this.tittel, this.under = ''});

  final SupportKortType type;

  /// The order code or case reference after the label (`ORDRE · Æ-2HZ`).
  final String? ref;
  final String tittel;
  final String under;

  static SupportKort? fraServer(Object? j) {
    if (j is! Map) return null;
    final type = switch ('${j['type'] ?? ''}') {
      'ordre' => SupportKortType.ordre,
      'sak' => SupportKortType.sak,
      'refusjon' => SupportKortType.refusjon,
      'aapningstid' => SupportKortType.aapningstid,
      _ => null,
    };
    if (type == null) return null;
    return SupportKort(type: type, ref: j['ref']?.toString(), tittel: '${j['title'] ?? ''}', under: '${j['sub'] ?? ''}');
  }
}

enum SupportAvsender { du, assistent, menneske, system }

class SupportMelding {
  SupportMelding(this.fra, this.tekst, {this.kort, this.chips = const [], this.navn, DateTime? at, this.id}) : at = at ?? DateTime.now();

  final SupportAvsender fra;
  final String tekst;
  final SupportKort? kort;
  final List<String> chips;

  /// The person's first name (`human`).
  final String? navn;
  final DateTime at;

  /// The server's message id; null for a message only on this device.
  final int? id;

  String get kl => '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  factory SupportMelding.fraServer(Map<String, dynamic> j) => SupportMelding(
    switch ('${j['author'] ?? ''}') {
      'customer' => SupportAvsender.du,
      'human' => SupportAvsender.menneske,
      'system' => SupportAvsender.system,
      _ => SupportAvsender.assistent,
    },
    '${j['body'] ?? ''}',
    kort: SupportKort.fraServer(j['card']),
    chips: j['chips'] is List ? [for (final c in j['chips'] as List) '$c'] : const [],
    navn: j['author_name']?.toString(),
    at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal(),
    id: (j['id'] as num?)?.toInt(),
  );
}

/// What the conversation is about (`scStart(kontekst)`).
enum SupportTema { support, mangler, feil, komAldri }

extension on SupportTema {
  String get server => switch (this) {
    SupportTema.support => 'support',
    SupportTema.mangler => 'mangler',
    SupportTema.feil => 'feil',
    SupportTema.komAldri => 'kom_aldri',
  };
}

/// The order a conversation is about, from `ops.customer.orders`.
class SupportOrdre {
  const SupportOrdre({required this.id, required this.kode, required this.butikk, required this.total, required this.status, this.linjer = const [], this.aktiv = false, this.levert = false, this.lovet});

  final int id;
  final String kode;
  final String butikk;
  final int total;
  final String status;
  final List<String> linjer;
  final bool aktiv;
  final bool levert;

  /// The promised end of the window (`promised_end`).
  final DateTime? lovet;

  int? get minutterIgjen {
    final l = lovet;
    if (l == null) return null;
    final m = l.difference(DateTime.now()).inMinutes;
    return m > 0 ? m : null;
  }

  factory SupportOrdre.fraRad(Map<String, dynamic> r) {
    final id = int.tryParse('${r['order_id']}') ?? 0;
    final state = '${r['state'] ?? ''}';
    final levert = state == 'delivered' || state == 'completed';
    final avbestilt = state == 'cancelled';
    final store = r['store'] is Map ? r['store'] as Map : const {};
    final items = r['items'] is List ? (r['items'] as List).whereType<Map>() : const <Map>[];
    final label = '${r['stage_label'] ?? ''}';
    return SupportOrdre(
      id: id,
      kode: '${r['code'] ?? ''}'.isEmpty ? 'Æ-$id' : '${r['code']}',
      butikk: '${store['name'] ?? ''}',
      total: ((r['total_pay'] as num?) ?? 0).round(),
      status: levert ? SupportCopy.levert : (avbestilt ? SupportCopy.avbestilt : (label.isEmpty ? SupportCopy.paaVei : label)),
      linjer: [for (final l in items) '${l['name'] ?? ''}'].where((n) => n.isNotEmpty).toList(),
      aktiv: r['paid'] == true && !levert && !avbestilt,
      levert: levert,
      lovet: DateTime.tryParse('${r['promised_end'] ?? ''}')?.toLocal(),
    );
  }

  SupportKort get kort => SupportKort(type: SupportKortType.ordre, ref: kode, tittel: [if (butikk.isNotEmpty) butikk, if (total > 0) '$total kr'].join(' · '), under: status);
}

/// A case filed on an order — `GET support/cases` (backend plan Step 5).
class SupportSak {
  const SupportSak({required this.ordreId, required this.kode, required this.type, required this.tekst, required this.at, this.problemId, this.customerSees, this.loest = false, this.losning});

  final int ordreId;
  final String kode;

  /// `missing_item`, `wrong_item`, `quality`, `not_delivered`.
  final String type;
  final String tekst;
  final DateTime at;
  final int? problemId;
  final String? customerSees;

  /// Resolved, and how it reads to the customer.
  final bool loest;
  final String? losning;

  String get ref => problemId == null ? kode : 'SAK-$problemId';
  String get tittel => '${SupportCopy.sakType(type)} · $kode';

  /// A row of `GET support/cases` or the `case` of `ops.customer.problem`.
  factory SupportSak.fraServer(Map<String, dynamic> j) => SupportSak(
    ordreId: (j['order_id'] as num?)?.toInt() ?? 0,
    kode: '${j['order_code'] ?? ''}',
    type: '${j['kind'] ?? 'other'}',
    tekst: '${j['words'] ?? ''}',
    at: DateTime.tryParse('${j['created_at'] ?? ''}')?.toLocal() ?? DateTime.now(),
    problemId: (j['id'] as num?)?.toInt(),
    customerSees: j['customer_facing_status']?.toString(),
    loest: j['state'] == 'resolved',
    losning: j['resolution_text']?.toString(),
  );
}

class SupportSamtale {
  SupportSamtale({required this.id, required this.tema, required this.emne, this.ordre, this.serverId});

  final int id;

  /// The server's conversation id; null when the conversation runs on the
  /// device only (offline fallback).
  final int? serverId;

  /// Turns to [SupportTema.mangler] when «Noe mangler» is picked in a
  /// general conversation.
  SupportTema tema;
  final String emne;
  SupportOrdre? ordre;
  final List<SupportMelding> meldinger = [];

  /// `ai` → `human`; `iKo` once the customer asked for a person.
  bool iKo = false;
  String? menneske;
  bool lukket = false;
  SupportSak? sak;

  /// `can_rate` (backend plan Step 14): closed and not rated yet. False when
  /// the server does not send it (an older server shows no rating row).
  bool kanVurdere = false;

  /// `csat_score`, 1–5, once the customer rated the help; null before, or
  /// when the server does not send it.
  int? vurdering;

  /// Rated from this device: the row turns into «Takk for vurderingen!».
  bool takket = false;

  bool get erMenneske => menneske != null;

  /// The «Hvordan var hjelpen?» row (or its thanks) under a closed thread.
  bool get visVurdering => lukket && (kanVurdere || takket);

  /// The newest server message id (for `messages?after=`).
  int get sisteId => meldinger.fold<int>(0, (a, m) => (m.id ?? 0) > a ? m.id! : a);

  /// The chips of Ægil's last message while it is the last one (`scChips`).
  List<String> get chips {
    if (erMenneske || meldinger.isEmpty) return const [];
    final siste = meldinger.last;
    return siste.fra == SupportAvsender.assistent ? siste.chips : const [];
  }
}

/// The session's conversations, the customer's cases and the guest token.
class SupportStore {
  SupportStore._();

  static final SupportStore instance = SupportStore._();

  /// Bumps on every change; the sheet and the order sheet listen.
  final ValueNotifier<int> endret = ValueNotifier<int>(0);
  final List<SupportSamtale> samtaler = [];
  int _neste = 1;

  /// Replaced in tests.
  OpsCustomerApi api = OpsCustomerApi();

  /// From «Finn bestillingen din»: reaches only [gjestOrdreId].
  String? gjestToken;
  int? gjestOrdreId;

  final List<SupportSak> _saker = [];
  Timer? _poll;

  SupportSamtale? get aapen => samtaler.reversed.where((s) => !s.lukket).firstOrNull;

  SupportSamtale ny(SupportTema tema, String emne, {SupportOrdre? ordre, int? serverId}) {
    final s = SupportSamtale(id: _neste++, tema: tema, emne: emne, ordre: ordre, serverId: serverId);
    samtaler.add(s);
    return s;
  }

  void legg(SupportSamtale s, SupportMelding m) {
    if (m.id != null && s.meldinger.any((x) => x.id == m.id)) return;
    s.meldinger.add(m);
    endret.value++;
  }

  /// The customer's cases, newest first: the server's, plus any filed in
  /// this session before the list was read again.
  List<SupportSak> get saker => List.unmodifiable(_saker);

  SupportSak? sakFor(int ordreId) => _saker.where((s) => s.ordreId == ordreId).firstOrNull;

  /// `GET support/cases` (and the config, for the hours and the e-mail).
  Future<void> oppdater() async {
    unawaited(SupportConfig.last(api));
    final j = await api.supportCases(guestToken: gjestToken);
    final list = j?['cases'];
    if (list is! List) return;
    _saker
      ..clear()
      ..addAll(list.whereType<Map<String, dynamic>>().map(SupportSak.fraServer));
    endret.value++;
  }

  /// Files the case through `ops.customer.problem` with the case kind
  /// (`missing_item`, `wrong_item`, `quality`, `not_delivered`). Null when
  /// nothing landed. A second case on the same order returns the first.
  Future<SupportSak?> meld(SupportOrdre o, String type, {List<String> varer = const [], String? ord}) async {
    final eksisterende = sakFor(o.id);
    if (eksisterende != null && !eksisterende.loest) return eksisterende;
    Map<String, dynamic>? res;
    try {
      res = await api.problem(o.id, kind: type, items: varer, words: ord?.trim().isEmpty ?? true ? null : ord!.trim());
    } catch (_) {
      res = null;
    }
    if (res == null) return null;
    final fra = res['case'] is Map<String, dynamic> ? SupportSak.fraServer(res['case'] as Map<String, dynamic>) : null;
    final sak = fra ??
        SupportSak(
          ordreId: o.id,
          kode: o.kode,
          type: type,
          tekst: [if (varer.isNotEmpty) varer.join(', '), if (ord != null) ord].join(' · '),
          at: DateTime.now(),
          problemId: (res['problem_id'] as num?)?.toInt(),
          customerSees: res['customer_sees'] as String?,
        );
    _saker
      ..removeWhere((s) => s.problemId != null && s.problemId == sak.problemId)
      ..insert(0, sak);
    endret.value++;
    return sak;
  }

  /// Puts the server's conversation payload into [s]: new messages, state,
  /// the person, the case.
  void flett(SupportSamtale s, Map<String, dynamic>? c) {
    if (c == null) return;
    final msgs = c['messages'];
    if (msgs is List) {
      for (final m in msgs.whereType<Map<String, dynamic>>()) {
        legg(s, SupportMelding.fraServer(m));
      }
    }
    final state = '${c['state'] ?? ''}';
    s.iKo = state == 'queued' || state == 'human';
    final navn = c['assignee_name']?.toString();
    if (state == 'human' && navn != null && navn.isNotEmpty) s.menneske = navn;
    if (state == 'closed') s.lukket = true;
    s
      ..kanVurdere = c['can_rate'] == true
      ..vurdering = switch (c['csat_score']) {
        final num n when n >= 1 && n <= 5 => n.toInt(),
        _ => null,
      };
    endret.value++;
  }

  /// The 1-tap rating (backend plan Step 14): true when the score landed, or
  /// the server already had one (`ALREADY_RATED`) — both show the thanks.
  /// False on any other failure: the row stays, with a retry hint.
  Future<bool> vurder(SupportSamtale s, int score) async {
    final id = s.serverId;
    if (id == null || score < 1 || score > 5) return false;
    final r = await api.rateConversation(id, score, guestToken: gjestToken);
    final c = r.conversation;
    if (c != null) {
      flett(s, c);
      s
        ..vurdering ??= score
        ..kanVurdere = false
        ..takket = true;
      endret.value++;
      return true;
    }
    if (r.error == 'ALREADY_RATED') {
      s
        ..kanVurdere = false
        ..takket = true;
      endret.value++;
      return true;
    }
    return false;
  }

  /// Polls the open server conversation for the person's replies while the
  /// chat is on screen (`messages?after=`).
  void startPolling(SupportSamtale s, {Duration hver = const Duration(seconds: 5)}) {
    stoppPolling();
    final id = s.serverId;
    if (id == null) return;
    _poll = Timer.periodic(hver, (_) async {
      if (s.lukket) return stoppPolling();
      final j = await api.supportPoll(id, s.sisteId, guestToken: gjestToken);
      final c = j?['conversation'];
      if (c is Map<String, dynamic>) flett(s, c);
    });
  }

  void stoppPolling() {
    _poll?.cancel();
    _poll = null;
  }

  /// «Finn bestillingen din», step 1: null = sent (with where to), else the
  /// error code (`ORDER_NOT_FOUND`, `CODE_NOT_SENT`, `OFFLINE`).
  Future<(String?, String?)> gjestOppslag(String ordre) async {
    final r = await api.supportGuest('lookup', {'order_no': ordre});
    if (r == null) return ('OFFLINE', null);
    final (code, body) = r;
    if (code == 200) return (null, body['sent_to']?.toString());
    return ('${body['error'] ?? 'ORDER_NOT_FOUND'}', null);
  }

  /// Step 2: null when verified (the token is kept), else the error code.
  Future<String?> gjestBekreft(String ordre, String kode) async {
    final r = await api.supportGuest('verify', {'order_no': ordre, 'code': kode});
    if (r == null) return 'OFFLINE';
    final (code, body) = r;
    if (code != 200 || body['guest_token'] == null) return '${body['error'] ?? 'INVALID_CODE'}';
    gjestToken = '${body['guest_token']}';
    gjestOrdreId = (body['order_id'] as num?)?.toInt();
    endret.value++;
    return null;
  }

  @visibleForTesting
  void reset({OpsCustomerApi? api}) {
    stoppPolling();
    samtaler.clear();
    _saker.clear();
    _neste = 1;
    gjestToken = null;
    gjestOrdreId = null;
    this.api = api ?? OpsCustomerApi();
    endret.value++;
  }
}

/// The assistant: on the server (backend plan Step 5); the rules below are
/// the offline fallback, the same `scSvar` rules the server runs.
abstract final class SupportAssistent {
  static String _hei(String navn) => navn.isEmpty ? SupportCopy.heiAnonym : SupportCopy.hei(navn);

  static String _emne(SupportTema tema) => switch (tema) {
    SupportTema.mangler => SupportCopy.emneMangler,
    SupportTema.feil => SupportCopy.emneFeil,
    SupportTema.komAldri => SupportCopy.emneKomAldri,
    SupportTema.support => SupportCopy.emneSupport,
  };

  /// Opens a conversation and its first message (`scStart`): on the server
  /// when it answers, else on the device. [ordreId] attaches the order the
  /// customer came from (Sporing's «Ordre #… er allerede lagt ved») for the
  /// person who takes over, without an order card in the chat.
  static Future<SupportSamtale> start(SupportTema tema, {required String fornavn, SupportOrdre? ordre, int? ordreId}) async {
    final store = SupportStore.instance;
    final orderId = ordre?.id ?? ordreId ?? store.gjestOrdreId;
    final j = await store.api.supportOpen(topic: tema.server, orderId: orderId, guestToken: store.gjestToken);
    final c = j?['conversation'];
    if (c is Map<String, dynamic> && c['id'] != null) {
      final serverTema = switch ('${c['topic'] ?? ''}') {
        'mangler' => SupportTema.mangler,
        'feil' => SupportTema.feil,
        'kom_aldri' => SupportTema.komAldri,
        _ => SupportTema.support,
      };
      final s = store.ny(serverTema, _emne(serverTema), ordre: serverTema == SupportTema.support ? null : ordre, serverId: (c['id'] as num).toInt());
      store.flett(s, c);
      if (c['case_id'] != null) unawaited(store.oppdater().then((_) => s.sak = store.sakFor(ordre?.id ?? 0)));
      return s;
    }
    return _startLokal(tema, fornavn: fornavn, ordre: ordre);
  }

  static Future<SupportSamtale> _startLokal(SupportTema tema, {required String fornavn, SupportOrdre? ordre}) async {
    final store = SupportStore.instance;
    final hei = _hei(fornavn);
    final aapen = SupportConfig.aapen();
    switch (tema) {
      case SupportTema.mangler when ordre != null:
        final s = store.ny(tema, SupportCopy.emneMangler, ordre: ordre);
        store.legg(s, SupportMelding(SupportAvsender.assistent, SupportCopy.startMangler(hei, ordre), kort: ordre.kort, chips: [...ordre.linjer.take(3), SupportCopy.menneske]));
        return s;
      case SupportTema.feil when ordre != null:
        final s = store.ny(tema, SupportCopy.emneFeil, ordre: ordre);
        store.legg(s, SupportMelding(SupportAvsender.assistent, SupportCopy.startFeil(hei, ordre), kort: ordre.kort, chips: [...ordre.linjer.take(2), SupportCopy.beskriv, SupportCopy.menneske]));
        return s;
      case SupportTema.komAldri when ordre != null:
        final s = store.ny(tema, SupportCopy.emneKomAldri, ordre: ordre);
        final sak = await store.meld(ordre, 'not_delivered');
        s.sak = sak;
        store.legg(
          s,
          SupportMelding(
            SupportAvsender.assistent,
            SupportCopy.startKomAldri(hei, ordre),
            kort: SupportKort(type: SupportKortType.sak, ref: sak?.ref ?? ordre.kode, tittel: SupportCopy.ack, under: SupportCopy.menneskeAvgjor),
            chips: const [SupportCopy.menneske],
          ),
        );
        return s;
      default:
        final s = store.ny(SupportTema.support, SupportCopy.emneSupport, ordre: ordre);
        store.legg(
          s,
          aapen
              ? SupportMelding(SupportAvsender.assistent, SupportCopy.startSupport(hei), chips: const [SupportCopy.hvorEr, SupportCopy.noeMangler, SupportCopy.menneske])
              : SupportMelding(
                  SupportAvsender.assistent,
                  SupportCopy.startStengt(hei),
                  kort: SupportKort(type: SupportKortType.aapningstid, tittel: SupportCopy.viSvarerFra(SupportConfig.aapnerKl)),
                  chips: const [SupportCopy.hvorEr, SupportCopy.noeMangler, SupportCopy.menneske],
                ),
        );
        return s;
    }
  }

  /// The customer's message, then the answer after [tenk] (`scSvar`).
  /// [hentOrdre] finds the order a «Hvor er …» or «Noe mangler» is about.
  static Future<void> svar(
    SupportSamtale s,
    String tekst, {
    required Future<SupportOrdre?> Function() hentOrdre,
    required void Function(bool) skriver,
    Duration tenk = const Duration(milliseconds: 1300),
  }) async {
    final store = SupportStore.instance;
    final t = tekst.trim();
    if (t.isEmpty || s.lukket) return;
    final id = s.serverId;
    if (id != null) {
      // Shown at once; the server's copy (with its id) replaces nothing —
      // only the answers that follow it are appended.
      store.legg(s, SupportMelding(SupportAvsender.du, t));
      if (!s.erMenneske && !s.iKo) skriver(true);
      final svar = await Future.wait([
        store.api.supportSend(id, t, guestToken: store.gjestToken),
        Future<void>.delayed(s.erMenneske || s.iKo ? Duration.zero : tenk),
      ]);
      skriver(false);
      final j = svar.first as Map<String, dynamic>?;
      final c = j?['conversation'];
      if (c is Map<String, dynamic>) {
        final msgs = c['messages'];
        final uten = {...c, 'messages': msgs is List ? msgs.whereType<Map<String, dynamic>>().where((m) => m['author'] != 'customer').toList() : const []};
        // Keep the ids of the customer's own message, so polling does not repeat it.
        if (msgs is List) {
          final mine = msgs.whereType<Map<String, dynamic>>().where((m) => m['author'] == 'customer').map((m) => (m['id'] as num?)?.toInt()).whereType<int>();
          for (final mid in mine) {
            _merkSisteDu(s, mid);
          }
        }
        store.flett(s, uten);
        if (c['case_id'] != null && s.sak == null) {
          await store.oppdater();
          s.sak = store.sakFor((c['order_id'] as num?)?.toInt() ?? 0);
        }
      } else {
        store.legg(s, SupportMelding(SupportAvsender.assistent, SupportCopy.ikkeSendt, chips: const [SupportCopy.menneske]));
      }
      return;
    }
    await _svarLokal(s, t, hentOrdre: hentOrdre, skriver: skriver, tenk: tenk);
  }

  /// Gives the newest customer bubble on this device the server's id.
  static void _merkSisteDu(SupportSamtale s, int id) {
    for (var i = s.meldinger.length - 1; i >= 0; i--) {
      final m = s.meldinger[i];
      if (m.fra == SupportAvsender.du && m.id == null) {
        s.meldinger[i] = SupportMelding(m.fra, m.tekst, at: m.at, id: id);
        return;
      }
    }
  }

  static Future<void> _svarLokal(
    SupportSamtale s,
    String t, {
    required Future<SupportOrdre?> Function() hentOrdre,
    required void Function(bool) skriver,
    required Duration tenk,
  }) async {
    final store = SupportStore.instance;
    store.legg(s, SupportMelding(SupportAvsender.du, t));
    // With a person in the conversation, Ægil stays out of it.
    if (s.erMenneske) return;
    final l = t.toLowerCase();
    if (RegExp(r'menneske|person|ansatt').hasMatch(l)) {
      await eskaler(s, skriver: skriver, tenk: tenk);
      return;
    }
    skriver(true);
    await Future<void>.delayed(tenk);
    SupportMelding svar;
    final statusKode = RegExp(r'status på saken min for (\S+?)\??$').firstMatch(t)?.group(1);
    final statusSak = statusKode == null ? null : store.saker.where((x) => x.kode == statusKode).firstOrNull;
    if (statusSak != null) {
      svar = SupportMelding(
        SupportAvsender.assistent,
        SupportCopy.statusSvar(statusSak),
        kort: SupportKort(type: SupportKortType.sak, ref: statusSak.ref, tittel: SupportCopy.ack, under: SupportCopy.menneskeAvgjor),
      );
    } else if (RegExp(r'refusjon|penger tilbake').hasMatch(l)) {
      // Before «hvor er …»: «Hvor er refusjonen min?» is about money.
      svar = SupportMelding(SupportAvsender.assistent, SupportCopy.refusjon);
    } else if (RegExp(r'hvor er|hvor lang|når kommer').hasMatch(l)) {
      final o = s.ordre ?? await hentOrdre();
      if (o == null) {
        svar = SupportMelding(SupportAvsender.assistent, SupportCopy.ingenOrdre);
      } else if (o.aktiv) {
        svar = SupportMelding(SupportAvsender.assistent, SupportCopy.paaVeiSvar(o), kort: o.kort);
      } else {
        svar = SupportMelding(SupportAvsender.assistent, SupportCopy.ingenPaaVei(o), kort: o.kort);
      }
    } else if (s.tema == SupportTema.support && s.sak == null && l == SupportCopy.noeMangler.toLowerCase()) {
      // «Noe mangler» from the chips: ask what, on the order.
      final o = s.ordre ?? await hentOrdre();
      if (o == null) {
        svar = SupportMelding(SupportAvsender.assistent, SupportCopy.ingenOrdre);
      } else {
        s
          ..ordre = o
          ..tema = SupportTema.mangler;
        svar = SupportMelding(SupportAvsender.assistent, SupportCopy.hvaMangler(o), kort: o.kort, chips: [...o.linjer.take(3), SupportCopy.menneske]);
      }
    } else if (s.tema == SupportTema.mangler || s.tema == SupportTema.feil || RegExp(r'mangler|manglet|fikk ikke|feil|beskriv').hasMatch(l)) {
      final o = s.ordre ?? await hentOrdre();
      if (o == null) {
        svar = SupportMelding(SupportAvsender.assistent, SupportCopy.ingenOrdre);
      } else if (l == SupportCopy.beskriv.toLowerCase()) {
        s.ordre = o;
        svar = SupportMelding(SupportAvsender.assistent, SupportCopy.beskrivSvar);
      } else {
        s.ordre = o;
        final type = s.tema == SupportTema.feil ? 'wrong_item' : 'missing_item';
        final varer = _varer(o.linjer, l);
        final sak = s.sak ?? await store.meld(o, type, varer: varer, ord: varer.isEmpty ? t : null);
        s.sak = sak;
        svar = sak == null
            ? SupportMelding(SupportAvsender.assistent, SupportCopy.ikkeSendt, chips: const [SupportCopy.menneske])
            : SupportMelding(
                SupportAvsender.assistent,
                SupportCopy.sendtTilVurdering,
                kort: SupportKort(type: SupportKortType.sak, ref: sak.ref, tittel: SupportCopy.ack, under: SupportCopy.menneskeAvgjor),
                chips: const [SupportCopy.menneske],
              );
      }
    } else if (RegExp(r'tidligere bestilling|noe galt').hasMatch(l)) {
      svar = SupportMelding(SupportAvsender.assistent, SupportCopy.tidligere);
    } else if (RegExp(r'adresse|betaling').hasMatch(l)) {
      svar = SupportMelding(SupportAvsender.assistent, SupportCopy.adresseBetaling);
    } else if (RegExp(r'poeng|nivå|premie').hasMatch(l)) {
      svar = SupportMelding(SupportAvsender.assistent, SupportCopy.poeng);
    } else if (RegExp(r'^(nei|ok|takk)').hasMatch(l)) {
      svar = SupportMelding(SupportAvsender.assistent, SupportCopy.greit);
    } else {
      svar = SupportMelding(SupportAvsender.assistent, SupportCopy.vetIkke, chips: const [SupportCopy.menneske, SupportCopy.neiGaarBra]);
    }
    skriver(false);
    store.legg(s, svar);
  }

  /// The order lines a message names: the exact line when it is one (a chip),
  /// else every line it mentions, without lines inside a longer one
  /// («Classic» in «Classic Fries»).
  static List<String> _varer(List<String> linjer, String l) {
    final eksakt = linjer.where((n) => n.toLowerCase() == l).toList();
    if (eksakt.isNotEmpty) return eksakt.take(1).toList();
    final nevnt = linjer.where((n) => l.contains(n.toLowerCase())).toList();
    return nevnt.where((n) => !nevnt.any((m) => m != n && m.toLowerCase().contains(n.toLowerCase()))).toList();
  }

  /// «Snakk med et menneske» (`scEskaler`): into the queue, the whole thread
  /// goes along. On the server a person takes it from the panel inbox.
  static Future<bool> eskaler(SupportSamtale s, {required void Function(bool) skriver, Duration tenk = const Duration(milliseconds: 1200)}) async {
    if (s.erMenneske || s.iKo) return false;
    final store = SupportStore.instance;
    final id = s.serverId;
    if (id != null) {
      skriver(true);
      final j = await store.api.supportEscalate(id, guestToken: store.gjestToken);
      skriver(false);
      final c = j?['conversation'];
      if (c is Map<String, dynamic>) {
        store.flett(s, c);
        return true;
      }
    }
    s.iKo = true;
    store.legg(s, SupportMelding(SupportAvsender.system, SupportCopy.eskalert));
    skriver(true);
    await Future<void>.delayed(tenk);
    skriver(false);
    store.legg(s, SupportMelding(SupportAvsender.assistent, SupportConfig.aapen() ? SupportCopy.iKo : SupportCopy.iKoStengt(SupportConfig.aapnerKl)));
    return true;
  }

  /// A person takes over on the device — the debug harness and the tests
  /// only. In the app a person takes over from the panel inbox, and their
  /// messages arrive by polling.
  static void taOver(SupportSamtale s, String navn, String fornavnKunde) {
    final store = SupportStore.instance;
    final fornavn = navn.split(' ').first;
    s.menneske = navn;
    store.legg(s, SupportMelding(SupportAvsender.system, SupportCopy.tokOver(fornavn)));
    store.legg(s, SupportMelding(SupportAvsender.menneske, SupportCopy.menneskeHei(fornavnKunde, fornavn), navn: fornavn));
  }
}


/// Copy for support (Launch L8638–8830, `samtale-mock.js` ARB keys).
abstract final class SupportCopy {
  static const String levert = 'Levert';
  static const String avbestilt = 'Avbestilt';
  static const String paaVei = 'På vei';

  static String hei(String navn) => 'Hei $navn. Jeg er Ærend-assistenten.';
  static const String heiAnonym = 'Hei. Jeg er Ærend-assistenten.';

  static const String emneSupport = 'Support';
  static const String emneMangler = 'Noe mangler i bestillingen';
  static const String emneFeil = 'Feil vare';
  static const String emneKomAldri = 'Kom aldri';

  static String startSupport(String hei) => '$hei Hva kan jeg hjelpe med?';
  static String startStengt(String hei) => '$hei Support er stengt nå, vi svarer fra ${SupportConfig.aapnerKl}. Jeg kan hjelpe med det jeg finner i bestillingene dine, og et menneske følger opp i morgen.';
  static String startMangler(String hei, SupportOrdre o) => '$hei Jeg ser bestillingen ${o.kode} fra ${o.butikk}. Hva mangler?'.trim();
  static String startFeil(String hei, SupportOrdre o) => '$hei Hva fikk du i stedet for det du bestilte i ${o.kode}?';
  static String startKomAldri(String hei, SupportOrdre o) =>
      '$hei ${o.kode} står som levert. Jeg har sendt saken til vurdering og sjekker budets posisjon og bildet ved døra. Et menneske avgjør, normalt innen ${SupportConfig.svarMin} minutter.';

  static const String hvorEr = 'Hvor er bestillingen?';
  static const String noeMangler = 'Noe mangler';
  static const String menneske = 'Snakk med et menneske';
  static const String beskriv = 'Beskriv med ord';
  static const String neiGaarBra = 'Nei, det går bra';

  static String paaVeiSvar(SupportOrdre o) {
    final min = o.minutterIgjen;
    final status = o.status == paaVei ? 'Bestillingen er på vei.' : 'Bestillingen står som «${o.status}».';
    return min == null ? status : '$status Den er hos deg om ca. $min minutter.';
  }
  static String ingenPaaVei(SupportOrdre o) => 'Du har ingen bestilling på vei nå. Den siste, ${o.kode} fra ${o.butikk}, står som ${o.status.toLowerCase()}.';
  static const String ingenOrdre = 'Jeg finner ingen bestillinger på kontoen din ennå.';
  static String hvaMangler(SupportOrdre o) => 'Jeg ser bestillingen ${o.kode} fra ${o.butikk}. Hva mangler?';
  static const String beskrivSvar = 'Skriv med vanlige ord hva du fikk, så sender jeg saken videre.';
  static String get sendtTilVurdering =>
      'Takk. Jeg har sendt saken til vurdering. Et menneske hos Ærend avgjør refusjonen, normalt innen ${SupportConfig.svarMin} minutter. Jeg sier fra her når det er avgjort.';
  static const String ikkeSendt = 'Jeg fikk ikke sendt saken akkurat nå. Prøv igjen, eller snakk med et menneske.';
  static const String refusjon = 'Jeg kan ikke love refusjon før den er sendt. Saken ligger til vurdering hos et menneske — du får svar her. Vipps er vanligvis samme dag, kort 2–5 virkedager.';
  static const String tidligere = 'Du kan melde fra i 48 timer etter levering. Åpne bestillingen under Meg → Ordrehistorikk og trykk «Noe galt med bestillingen?».';
  static const String adresseBetaling = 'Endringer i adresse og betaling gjelder fra neste bestilling. Du finner dem under Meg → Konto.';
  static const String poeng = 'Du tjener poeng på bestillinger og i Fjordfiske, og bruker dem på Premiehylla under Meg.';
  static const String greit = 'Greit. Si fra her hvis det er noe mer.';
  static const String vetIkke = 'Det har jeg ikke et sikkert svar på fra det jeg vet om bestillingen. Vil du at et menneske ser på det?';
  static const String eskalert = 'Eskalert til menneske · Ba om menneske';
  static String get iKo => 'Selvfølgelig. Du står i kø for et menneske, forventet svar innen ${SupportConfig.svarMin} min. Hele samtalen følger med.';
  static String iKoStengt(String kl) => 'Selvfølgelig. Du står i kø for et menneske, vi svarer fra $kl. Hele samtalen følger med.';
  static String tokOver(String navn) => '$navn fra Ærend tok over';
  static String menneskeHei(String kunde, String navn) => 'Hei${kunde.isEmpty ? '' : ' $kunde'}, $navn her. Jeg har lest tråden. Hva kan jeg hjelpe med?';
  static const String allerede = 'Du står allerede i kø for et menneske';
  static String erISamtalen(String navn) => '$navn er allerede i samtalen';

  static String get ack => 'Vi ser på det · svar innen ${SupportConfig.svarMin} min';
  static const String menneskeAvgjor = 'Et menneske avgjør';
  static String viSvarerFra(String kl) => 'Vi svarer fra $kl';
  static const String komAldriMelding = 'Står som levert, men kom ikke';
  static const String ingenForbindelse = 'Fikk ikke kontakt. Sjekk nettet og prøv igjen.';

  static String sakType(String type) => switch (type) {
    'missing_item' => 'Noe manglet',
    'wrong_item' => 'Feil vare',
    'quality' => 'Kvalitet',
    'not_delivered' => 'Kom aldri',
    _ => 'Sak',
  };

  // Chat chrome.
  // Support v1 has no AI (backend plan Step 5): the assistant is scripted
  // server-side rules, so the chrome doesn't say «AI».
  static const String aiUnder = 'Ærend-assistent · svarer på sekunder';
  static String stengtUnder(String kl) => 'Stengt · vi svarer fra $kl';
  static String menneskeUnder(String navn) => '$navn fra Ærend · menneske';
  static const String avsluttetUnder = 'Samtalen er avsluttet';
  static const String nySamtale = 'Start en ny samtale';

  // 1-tap rating under a closed conversation (backend plan Step 14).
  static const String vurderSpor = 'Hvordan var hjelpen?';
  static const String vurderTakk = 'Takk for vurderingen!';
  static const String vurderFeil = 'Fikk ikke sendt. Trykk på en stjerne for å prøve igjen.';
  static String vurderStjerne(int n) => '$n av 5 stjerner';
  static String merkeDu(String kl) => 'DU · $kl';
  static String merkeAi(String kl) => 'ÆREND-ASSISTENT · $kl';
  static String merkeMenneske(String navn, String kl) => '${navn.toUpperCase()} FRA ÆREND · $kl';
  static const String skrivAi = 'Skriv med vanlige ord …';
  static String skrivTil(String navn) => 'Skriv til $navn …';
  static String iSamtalen(String navn) => '$navn fra Ærend er i samtalen';
  static const Map<SupportKortType, String> kortLabel = {
    SupportKortType.ordre: 'ORDRE',
    SupportKortType.sak: 'SAK',
    SupportKortType.refusjon: 'REFUSJON',
    SupportKortType.aapningstid: 'ÅPNINGSTID',
  };

  // Hub.
  static const String hjelpOgKontakt = 'Hjelp og kontakt';
  static const String aapenNaa = 'Åpent nå · svarer på sekunder';
  static String stengtNaa(String kl) => 'Stengt nå · vi svarer fra $kl';
  static const String fortsett = 'Fortsett samtalen';
  static const String chatMedOss = 'Chat med oss';
  static const String chatMedOssUnder = 'Assistenten svarer først · et menneske når du vil';
  static const String dineSaker = 'DINE SAKER';
  static const String finnSvar = 'FINN SVAR SELV';
  static const String aapenChip = 'Åpen';
  static String statusSpor(String kode) => 'Hva er status på saken min for $kode?';
  static String statusSvar(SupportSak s) => 'Saken på ${s.kode} ligger til vurdering. ${s.customerSees ?? ''} Du får svar her, normalt innen ${SupportConfig.svarMin} minutter.'.replaceAll('  ', ' ');
  static const List<(String, String)> faq = [
    ('Hvor er refusjonen min?', 'Vipps: vanligvis samme dag · kort: 2–5 virkedager'),
    ('Noe galt med en tidligere bestilling', 'Du kan melde fra i 48 timer etter levering'),
    ('Endre adresse eller betaling', 'Gjelder fra neste bestilling'),
    ('Poeng, nivå og premier', 'Slik tjener og bruker du poeng'),
    ('Slett konto og data', 'Du bestemmer over dataene dine'),
  ];
  static String get epostFor => 'Chat ${SupportConfig.timer} hver dag · e-post ';
  static const String epostEtter = ', svar innen 24 t';

  // Guest.
  static const String gjestTittel = 'Finn bestillingen din';
  static const String gjestTekst = 'Bestillingen er ikke knyttet til en konto. Skriv ordrenummeret fra kvitteringen, så sender vi en engangskode til ';
  static const String gjestKontakt = 'telefonen din';
  static const String gjestOrdre = 'Ordrenummer, f.eks. Æ-42K';
  static const String gjestKode = 'Engangskode (4 siffer)';
  static const String sendKode = 'Send kode';
  static const String bekreftKode = 'Bekreft kode';
  static const String fantIkke = 'Fant ikke bestillingen. Sjekk ordrenummeret på kvitteringen.';
  static const String feilKode = 'Koden stemmer ikke. Prøv igjen, eller be om ny kode.';
  static String kodeSendt(String til) => 'Kode sendt til $til';
  static const String bekreftet = 'Bekreftet · bestillingen er knyttet til samtalen';

  // Sak på ordren (L9237) and «Noe galt» (kArk noeGalt).
  static const String ikkeLost = 'Ikke løst';
  static const String noeGalt = 'Noe galt med bestillingen?';
  // A person decides every case in v1 (backend plan Step 5): no instant credit.
  static String get noeGaltUnder => 'Vi ser på det og svarer innen ${SupportConfig.svarMin} min';
  static String noeGaltTittel(String kode) => 'Noe galt med $kode?';
  static const String noeGaltLinje = 'Velg hva. Steg 2 spør bare om det vi trenger.';
  static const List<(String, String, String, String)> noeGaltValg = [
    ('Mangler noe', 'En eller flere varer kom ikke', 'missing_item', 'M6 8h12l-1 12H7L6 8zM9 8a3 3 0 0 1 6 0M10 14h4'),
    ('Feil vare', 'Fikk noe annet enn bestilt', 'wrong_item', 'M7 7h11l-3-3M17 17H6l3 3'),
    ('Kvalitet', 'Kaldt, skadet eller for gammelt', 'quality', 'M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9M9.5 4.5 12 7l2.5-2.5M9.5 19.5 12 17l2.5 2.5'),
    ('Ikke levert', 'Ordren står som levert, men kom ikke', 'not_delivered', 'M4 11l8-7 8 7v9H4zM10 20v-5h4v5'),
  ];
  static String steg2Tittel(String valg, String kode) => '$valg · $kode';
  static const String steg2Linje = 'Trykk på linjen det gjelder. Et menneske hos Ærend ser på saken.';
  static const String tilbake = 'Tilbake';
  static const String harAllerede = 'Vi har allerede saken';
  static String get harAlleredeLinje => '$ack · du følger den på bestillingen.';
  static const String mottatt = 'Vi har mottatt saken.';
  static const String saksreferanse = 'SAKSREFERANSE';
  static const String ferdig = 'Ferdig';
  static String get registrert => 'Saken er registrert · svar innen ${SupportConfig.svarMin} min';
  static const String naa = 'Nå';
}
