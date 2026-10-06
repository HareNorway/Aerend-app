import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/shared_pref_utill.dart';

/// Support for the customer (Launch `scStart` / `scSvar` / `sakVals`,
/// L17965–18030): one conversation per problem, the Ærend assistant first and
/// a person when the customer asks, and the cases filed on an order.
///
/// What is real: every case goes through `ops.customer.problem` and keeps the
/// backend's own answer (problem id, `customer_sees`); «Kom aldri» is sent as
/// a message on the order (`ops.customer.contact`), as in Step 8. The order
/// cards read the customer's real orders.
///
/// UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
/// There is no support-conversation API (open, send, escalate, take over) and
/// no customer read of a case, so the conversation lives in this session, the
/// assistant's replies are scripted from the prototype's rules, and a case
/// stays «Åpen» (its resolution is never known here).
abstract final class SupportConfig {
  /// The customer queue's hours (`samtale-mock.js` CONFIG.hours.kunde).
  static const int aapner = 8;
  static const int stenger = 23;

  /// Minutes to the first answer on a case (`support-mock.js` ackMinutes).
  static const int svarMin = 30;
  static const String telefon = '55 00 12 34';
  static const String epost = 'hjelp@aerend.no';

  static bool aapen([DateTime? naa]) {
    final h = (naa ?? DateTime.now()).hour;
    return h >= aapner && h < stenger;
  }

  static String get aapnerKl => '${aapner.toString().padLeft(2, '0')}:00';
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
}

enum SupportAvsender { du, assistent, menneske, system }

class SupportMelding {
  SupportMelding(this.fra, this.tekst, {this.kort, this.chips = const [], this.navn, DateTime? at}) : at = at ?? DateTime.now();

  final SupportAvsender fra;
  final String tekst;
  final SupportKort? kort;
  final List<String> chips;

  /// The person's first name (`human`).
  final String? navn;
  final DateTime at;

  String get kl => '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
}

/// What the conversation is about (`scStart(kontekst)`).
enum SupportTema { support, mangler, feil, komAldri }

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

/// A case filed on an order — the backend's answer to `ops.customer.problem`,
/// kept on this device because no endpoint reads it back.
class SupportSak {
  const SupportSak({required this.ordreId, required this.kode, required this.type, required this.tekst, required this.at, this.problemId, this.customerSees});

  final int ordreId;
  final String kode;

  /// `missing_item`, `wrong_item`, `quality`, `not_delivered`.
  final String type;
  final String tekst;
  final DateTime at;
  final int? problemId;
  final String? customerSees;

  String get ref => problemId == null ? kode : 'SAK-$problemId';
  String get tittel => '${SupportCopy.sakType(type)} · $kode';

  Map<String, dynamic> toJson() => {
    'ordre_id': ordreId,
    'kode': kode,
    'type': type,
    'tekst': tekst,
    'at': at.toIso8601String(),
    'problem_id': problemId,
    'customer_sees': customerSees,
  };

  factory SupportSak.fromJson(Map<String, dynamic> j) => SupportSak(
    ordreId: (j['ordre_id'] as num?)?.toInt() ?? 0,
    kode: '${j['kode'] ?? ''}',
    type: '${j['type'] ?? 'other'}',
    tekst: '${j['tekst'] ?? ''}',
    at: DateTime.tryParse('${j['at'] ?? ''}') ?? DateTime.now(),
    problemId: (j['problem_id'] as num?)?.toInt(),
    customerSees: j['customer_sees'] as String?,
  );
}

class SupportSamtale {
  SupportSamtale({required this.id, required this.tema, required this.emne, this.ordre});

  final int id;

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

  bool get erMenneske => menneske != null;

  /// The chips of Ægil's last message while it is the last one (`scChips`).
  List<String> get chips {
    if (erMenneske || meldinger.isEmpty) return const [];
    final siste = meldinger.last;
    return siste.fra == SupportAvsender.assistent ? siste.chips : const [];
  }
}

/// The session's conversations and the device's cases.
class SupportStore {
  SupportStore._();

  static final SupportStore instance = SupportStore._();

  static const String _prefSaker = 'launch_support_saker';

  /// Bumps on every change; the sheet and the order sheet listen.
  final ValueNotifier<int> endret = ValueNotifier<int>(0);
  final List<SupportSamtale> samtaler = [];
  int _neste = 1;

  /// Replaced in tests.
  OpsCustomerApi api = OpsCustomerApi();

  SupportSamtale? get aapen => samtaler.reversed.where((s) => !s.lukket).firstOrNull;

  SupportSamtale ny(SupportTema tema, String emne, {SupportOrdre? ordre}) {
    final s = SupportSamtale(id: _neste++, tema: tema, emne: emne, ordre: ordre);
    samtaler.add(s);
    return s;
  }

  void legg(SupportSamtale s, SupportMelding m) {
    s.meldinger.add(m);
    endret.value++;
  }

  List<SupportSak> get saker {
    try {
      final raw = prefGetString(_prefSaker);
      if (raw.isEmpty) return const [];
      final list = jsonDecode(raw);
      return list is List ? list.whereType<Map<String, dynamic>>().map(SupportSak.fromJson).toList().reversed.toList() : const [];
    } catch (_) {
      return const [];
    }
  }

  SupportSak? sakFor(int ordreId) => saker.where((s) => s.ordreId == ordreId).firstOrNull;

  /// Files the case through `ops.customer.problem` (`missing` covers missing
  /// items, the wrong item and quality — the kinds the endpoint has) or, for
  /// «Kom aldri», a message on the order. Null when nothing landed.
  Future<SupportSak?> meld(SupportOrdre o, String type, {List<String> varer = const [], String? ord}) async {
    final eksisterende = sakFor(o.id);
    if (eksisterende != null) return eksisterende;
    Map<String, dynamic>? res;
    try {
      if (type == 'not_delivered') {
        res = await api.contact(o.id, kind: 'message', message: ord ?? SupportCopy.komAldriMelding);
      } else {
        final prefiks = type == 'wrong_item' ? 'Feil vare' : (type == 'quality' ? 'Kvalitet' : null);
        final ordene = [if (prefiks != null) prefiks, if (ord != null && ord.trim().isNotEmpty) ord.trim()].join(': ');
        res = await api.problem(o.id, kind: 'missing', items: varer, words: ordene.isEmpty ? null : ordene);
      }
    } catch (_) {
      res = null;
    }
    if (res == null) return null;
    final sak = SupportSak(
      ordreId: o.id,
      kode: o.kode,
      type: type,
      tekst: [if (varer.isNotEmpty) varer.join(', '), if (ord != null) ord].join(' · '),
      at: DateTime.now(),
      problemId: (res['problem_id'] as num?)?.toInt(),
      customerSees: res['customer_sees'] as String?,
    );
    final alle = [...saker.reversed, sak];
    try {
      await prefSetString(_prefSaker, jsonEncode([for (final s in alle) s.toJson()]));
    } catch (_) {
      // Prefs not ready: the case still went through; it shows once stored.
    }
    endret.value++;
    return sak;
  }

  @visibleForTesting
  void reset({OpsCustomerApi? api}) {
    samtaler.clear();
    _neste = 1;
    this.api = api ?? OpsCustomerApi();
    try {
      prefSetString(_prefSaker, '');
    } catch (_) {}
    endret.value++;
  }
}

/// The assistant's rules (`scSvar`), on the real order and the real case.
///
/// UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
abstract final class SupportAssistent {
  static String _hei(String navn) => navn.isEmpty ? SupportCopy.heiAnonym : SupportCopy.hei(navn);

  /// Opens a conversation and its first message (`scStart`).
  static Future<SupportSamtale> start(SupportTema tema, {required String fornavn, SupportOrdre? ordre}) async {
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

  /// The customer's message, then Ægil's answer after [tenk] (`scSvar`).
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
  /// goes along. No person is invented — there is no queue behind it yet.
  static Future<bool> eskaler(SupportSamtale s, {required void Function(bool) skriver, Duration tenk = const Duration(milliseconds: 1200)}) async {
    if (s.erMenneske || s.iKo) return false;
    final store = SupportStore.instance;
    s.iKo = true;
    store.legg(s, SupportMelding(SupportAvsender.system, SupportCopy.eskalert));
    skriver(true);
    await Future<void>.delayed(tenk);
    skriver(false);
    store.legg(s, SupportMelding(SupportAvsender.assistent, SupportConfig.aapen() ? SupportCopy.iKo : SupportCopy.iKoStengt(SupportConfig.aapnerKl)));
    return true;
  }

  /// A person takes over (`M.takeover`). Only the debug harness and the tests
  /// call this — there is no support desk behind the app yet.
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
  static const String sendtTilVurdering =
      'Takk. Jeg har sendt saken til vurdering. Et menneske hos Ærend avgjør refusjonen, normalt innen ${SupportConfig.svarMin} minutter. Jeg sier fra her når det er avgjort.';
  static const String ikkeSendt = 'Jeg fikk ikke sendt saken akkurat nå. Prøv igjen, eller snakk med et menneske.';
  static const String refusjon = 'Jeg kan ikke love refusjon før den er sendt. Saken ligger til vurdering hos et menneske — du får svar her. Vipps er vanligvis samme dag, kort 2–5 virkedager.';
  static const String tidligere = 'Du kan melde fra i 48 timer etter levering. Åpne bestillingen under Meg → Ordrehistorikk og trykk «Noe galt med bestillingen?».';
  static const String adresseBetaling = 'Endringer i adresse og betaling gjelder fra neste bestilling. Du finner dem under Meg → Konto.';
  static const String poeng = 'Du tjener poeng på bestillinger og i Fjordfiske, og bruker dem på Premiehylla under Meg.';
  static const String greit = 'Greit. Si fra her hvis det er noe mer.';
  static const String vetIkke = 'Det har jeg ikke et sikkert svar på fra det jeg vet om bestillingen. Vil du at et menneske ser på det?';
  static const String eskalert = 'Eskalert til menneske · Ba om menneske';
  static const String iKo = 'Selvfølgelig. Du står i kø for et menneske, forventet svar innen ${SupportConfig.svarMin} min. Hele samtalen følger med.';
  static String iKoStengt(String kl) => 'Selvfølgelig. Du står i kø for et menneske, vi svarer fra $kl. Hele samtalen følger med.';
  static String tokOver(String navn) => '$navn fra Ærend tok over';
  static String menneskeHei(String kunde, String navn) => 'Hei${kunde.isEmpty ? '' : ' $kunde'}, $navn her. Jeg har lest tråden. Hva kan jeg hjelpe med?';
  static const String allerede = 'Du står allerede i kø for et menneske';
  static String erISamtalen(String navn) => '$navn er allerede i samtalen';

  static const String ack = 'Vi ser på det · svar innen ${SupportConfig.svarMin} min';
  static const String menneskeAvgjor = 'Et menneske avgjør';
  static String viSvarerFra(String kl) => 'Vi svarer fra $kl';
  static const String komAldriMelding = 'Står som levert, men kom ikke';

  static String sakType(String type) => switch (type) {
    'missing_item' => 'Noe manglet',
    'wrong_item' => 'Feil vare',
    'quality' => 'Kvalitet',
    'not_delivered' => 'Kom aldri',
    _ => 'Sak',
  };

  // Chat chrome.
  static const String aiUnder = 'Ærend-assistent · AI · svarer på sekunder';
  static String stengtUnder(String kl) => 'Stengt · vi svarer fra $kl';
  static String menneskeUnder(String navn) => '$navn fra Ærend · menneske';
  static String merkeDu(String kl) => 'DU · $kl';
  static String merkeAi(String kl) => 'ÆREND-ASSISTENT · AI · $kl';
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
  static const String epostFor = 'Chat 08–23 hver dag · e-post ';
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
  static const String noeGaltUnder = 'Ægil ordner kreditt med én gang';
  static String noeGaltTittel(String kode) => 'Noe galt med $kode?';
  static const String noeGaltLinje = 'Velg hva. Steg 2 spør bare om det vi trenger.';
  static const List<(String, String, String, String)> noeGaltValg = [
    ('Mangler noe', 'En eller flere varer kom ikke', 'missing_item', 'M6 8h12l-1 12H7L6 8zM9 8a3 3 0 0 1 6 0M10 14h4'),
    ('Feil vare', 'Fikk noe annet enn bestilt', 'wrong_item', 'M7 7h11l-3-3M17 17H6l3 3'),
    ('Kvalitet', 'Kaldt, skadet eller for gammelt', 'quality', 'M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9M9.5 4.5 12 7l2.5-2.5M9.5 19.5 12 17l2.5 2.5'),
    ('Ikke levert', 'Ordren står som levert, men kom ikke', 'not_delivered', 'M4 11l8-7 8 7v9H4zM10 20v-5h4v5'),
  ];
  static String steg2Tittel(String valg, String kode) => '$valg · $kode';
  static const String steg2Linje = 'Trykk på linjen det gjelder. Ægil regner ut kreditten med én gang.';
  static const String tilbake = 'Tilbake';
  static const String harAllerede = 'Vi har allerede saken';
  static const String harAlleredeLinje = '$ack · du følger den på bestillingen.';
  static const String mottatt = 'Vi har mottatt saken.';
  static const String saksreferanse = 'SAKSREFERANSE';
  static const String ferdig = 'Ferdig';
  static const String registrert = 'Saken er registrert · svar innen ${SupportConfig.svarMin} min';
  static const String naa = 'Nå';
}
