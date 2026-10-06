import 'dart:math' as math;

import 'hurtig_copy.dart';
import 'hurtig_data.dart';

// ── Hurtigbestilling · Ægil's reasoning (prototype `hbTolk` & co.,
// L14834–15055) ───────────────────────────────────────────────────────────
//
// A straight port of the prototype's interpreter, generalised from its
// hand-written menu to the customer's real data: the habit of the day is the
// most recent order on today's weekday, «oftest» counts the delivered lines,
// the preference suggestion is the favourite shop's main scaled to the
// household plus one side, and a closed shop offers the customer's favourite
// from an open one.

/// A button under an Ægil bubble (`knapper`): [h] is the handler key
/// (`si:…`, `leggtil:<id>`, `angrebytt`, `bestill`).
class HbKnapp {
  const HbKnapp(this.tekst, this.h, {this.primar = false});
  final String tekst;
  final String h;
  final bool primar;
}

/// What the interpreter answers (`svar`).
class HbSvar {
  const HbSvar({
    required this.tekst,
    this.humor = 'glad',
    this.knapper = const [],
    this.modul = '',
    this.utkast,
    this.tomUtkast = false,
    this.tid,
    this.bestill = false,
    this.angre = false,
    this.ai = false,
  });

  final String tekst;
  final String humor;
  final List<HbKnapp> knapper;
  final String modul;

  /// Replaces the draft (null keeps it).
  final HbUtkast? utkast;
  final bool tomUtkast;
  final String? tid;
  final bool bestill;
  final bool angre;

  /// The local rules gave up: ask the assistant API.
  final bool ai;

  static const HbSvar sporAi = HbSvar(tekst: '', ai: true);
}

/// The habit / suggestion shape (`hbVane`, `hbPrefForslag`).
class HbForslag {
  const HbForslag({required this.dag, required this.butikkId, required this.butikk, required this.linjer, this.grunner = const []});
  final String dag;
  final int butikkId;
  final String butikk;
  final List<HbLinje> linjer;
  final List<String> grunner;
  HbUtkast get utkast => HbUtkast(butikkId: butikkId, butikk: butikk, linjer: linjer);
}

class HbOftestRad {
  const HbOftestRad(this.id, this.ganger, this.ant);
  final int id;
  final int ganger;
  final int ant;
}

class HbSum {
  const HbSum(this.varer, this.lev);
  final double varer;
  final double lev;
  double get total => varer + lev;
}

/// The state the interpreter reads (the screen owns it).
class HbTilstand {
  const HbTilstand({this.utkast, this.fase = 'utkast', this.hus, this.skalldyr, this.regn = true});
  final HbUtkast? utkast;
  final String fase;
  final int? hus;
  final bool? skalldyr;
  final bool regn;
}

class HurtigHjerne {
  HurtigHjerne(this.d, {DateTime? now}) : now = now ?? DateTime.now();

  final HurtigData d;
  final DateTime now;

  // ── helpers ─────────────────────────────────────────────────────────────

  String stor(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String dag() => HurtigCopy.dag(now.weekday);

  int hus(HbTilstand st) => st.hus ?? (d.minne.husstand > 0 ? d.minne.husstand : 2);

  bool unngaaSkalldyr(HbTilstand st) => st.skalldyr ?? d.minne.unngaaSkalldyr;

  HbVare? vare(int id) => d.vare(id);

  HbButikk b(int id, [String? navn]) => d.butikk(id, navn);

  List<HbLinje> linjer(HbOrdre o) => [for (final l in o.linjer) if (vare(l.id) != null) HbLinje(l.id, l.ant < 1 ? 1 : l.ant)];

  /// The usual quantity (`hbVanligAnt`): the mean over the history, at least 1.
  int vanligAnt(int id) {
    var n = 0, s = 0;
    for (final o in d.hist) {
      for (final l in o.linjer) {
        if (l.id == id) {
          n++;
          s += l.ant;
        }
      }
    }
    return n == 0 ? 1 : math.max(1, (s / n).round());
  }

  /// `hbOftest`: the four most ordered products.
  List<HbOftestRad> oftest() {
    final c = <int, List<int>>{};
    final order = <int>[];
    for (final o in d.hist) {
      for (final l in o.linjer) {
        if (vare(l.id) == null) continue;
        final k = c.putIfAbsent(l.id, () {
          order.add(l.id);
          return [0, 0];
        });
        k[0]++;
        k[1] += l.ant;
      }
    }
    final rows = [for (final id in order) HbOftestRad(id, c[id]![0], c[id]![1])];
    // JS sort is stable: ties keep history order (newest first).
    mergeSort(rows, (a, b) {
      final g = b.ganger.compareTo(a.ganger);
      return g != 0 ? g : b.ant.compareTo(a.ant);
    });
    return rows.take(4).toList();
  }

  /// `hbVane`: what the customer takes on this weekday — the most recent
  /// order on today's weekday; otherwise the favourite.
  HbForslag? vane(HbTilstand st) {
    if (d.hist.isEmpty) return null;
    final dagen = dag();
    final same = d.hist.where((o) => o.naar.weekday == now.weekday);
    if (same.isNotEmpty) {
      final o = same.first;
      final L = linjer(o);
      if (L.isNotEmpty) return HbForslag(dag: dagen, butikkId: o.butikkId, butikk: o.butikk, linjer: L);
    }
    final top = oftest();
    if (top.isEmpty) return null;
    final v = vare(top.first.id)!;
    return HbForslag(dag: dagen, butikkId: v.butikkId, butikk: v.butikk, linjer: [HbLinje(v.id, vanligAnt(v.id))]);
  }

  /// `hbPrefForslag`: the favourite shop's main for the household plus one side.
  HbForslag? prefForslag(HbTilstand st) {
    final top = oftest();
    if (top.isEmpty) return null;
    final h = hus(st), unng = unngaaSkalldyr(st), dagen = dag();
    HbVare? hoved;
    for (final r in top) {
      final v = vare(r.id)!;
      if (v.hoved && !(unng && v.skalldyr) && b(v.butikkId).stengt == null) {
        hoved = v;
        break;
      }
    }
    hoved ??= vare(top.first.id)!;
    final side = _side(hoved.butikkId, [hoved.id], unng);
    final L = [HbLinje(hoved.id, h), if (side != null) HbLinje(side.id, 1)];
    final liker = d.minne.liker.isNotEmpty ? d.minne.liker.first.toLowerCase() : hoved.navn.toLowerCase();
    final grunner = [
      HurtigCopy.erMiddagsdag(stor(dagen)),
      HurtigCopy.duLiker(liker),
      HurtigCopy.personer(h),
      if (st.regn) HurtigCopy.regnNoeVarmt,
      unng ? HurtigCopy.utenSkalldyr : HurtigCopy.rekerErOk,
    ];
    return HbForslag(dag: dagen, butikkId: hoved.butikkId, butikk: hoved.butikk, linjer: L, grunner: grunner);
  }

  /// The side the customer most often takes with the shop's mains (co-ordered
  /// non-main), else the shop's cheapest non-main.
  HbVare? _side(int butikkId, List<int> har, bool unng) {
    final c = <int, int>{};
    for (final o in d.hist) {
      if (o.butikkId != butikkId) continue;
      for (final l in o.linjer) {
        final v = vare(l.id);
        if (v != null && !v.hoved && !har.contains(v.id) && !(unng && v.skalldyr)) c[v.id] = (c[v.id] ?? 0) + 1;
      }
    }
    if (c.isNotEmpty) {
      final best = c.keys.reduce((a, bb) => c[bb]! > c[a]! ? bb : a);
      return vare(best);
    }
    final rest = d.meny.values.where((v) => v.butikkId == butikkId && !v.hoved && !har.contains(v.id) && !(unng && v.skalldyr)).toList()..sort((a, bb) => a.pris.compareTo(bb.pris));
    return rest.isEmpty ? null : rest.first;
  }

  /// `hbSum`.
  HbSum sum(HbUtkast? U) {
    if (U == null) return const HbSum(0, 0);
    var varer = 0.0;
    for (final l in U.linjer) {
      final v = vare(l.id);
      if (v != null) varer += v.pris * l.ant;
    }
    final bt = b(U.butikkId, U.butikk);
    final lev = varer == 0 || varer >= bt.gratisOver ? 0.0 : bt.frakt;
    return HbSum(varer, lev);
  }

  /// `hbKlar`: «Hos deg ca. 18:05» / «Levering kl. 18:30».
  String klar(HbUtkast? U) {
    if (U != null && U.tid.isNotEmpty && U.tid != HurtigCopy.snarest) return HurtigCopy.leveringTid(U.tid.toLowerCase());
    final t = now.add(Duration(minutes: U == null ? 30 : b(U.butikkId, U.butikk).min));
    return HurtigCopy.hosDegCa('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
  }

  /// `hbTekst`: «2× Fiskesuppe + Hjemmelaget brød».
  String tekst(List<HbLinje> L, [String sep = ' + ']) => [
    for (final l in L)
      if (vare(l.id) != null) '${l.ant > 1 ? '${l.ant}× ' : ''}${vare(l.id)!.navn}',
  ].join(sep);

  /// `HB_TIDER`: Snarest, then the next three half hours.
  List<String> tider() {
    final out = [HurtigCopy.snarest];
    var t = now.add(const Duration(minutes: 45));
    t = DateTime(t.year, t.month, t.day, t.hour, t.minute < 30 ? 30 : 60);
    for (var i = 0; i < 3; i++) {
      out.add(HurtigCopy.klokken('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'));
      t = t.add(const Duration(minutes: 30));
    }
    return out;
  }

  /// The prototype's `dato` label: «tirsdag», «forrige torsdag», «28. august».
  String dato(DateTime t) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return HurtigCopy.iDag;
    if (diff == 1) return HurtigCopy.iGaar;
    if (diff < 7) return HurtigCopy.dag(t.weekday);
    if (diff < 14) return HurtigCopy.forrige(HurtigCopy.dag(t.weekday));
    return HurtigCopy.datoDag(t.day, HurtigCopy.maaned(t.month));
  }

  static int tall(String s) {
    const T = {'en': 1, 'én': 1, 'ett': 1, 'ei': 1, 'to': 2, 'tre': 3, 'fire': 4, 'fem': 5, 'seks': 6};
    return RegExp(r'^\d+$').hasMatch(s) ? int.parse(s) : (T[s] ?? 0);
  }

  /// `hbFinn`: the products the text names, in order of appearance. Full
  /// names win over single words, and a matched span is not matched twice.
  List<({HbVare v, int pos})> finn(String l) {
    final t = <({HbVare v, int pos})>[];
    var masked = l;
    // Longest names first; among equals, what the customer has ordered before
    // wins over a namesake elsewhere, then an open shop over a closed one.
    final ganger = <int, int>{};
    for (final o in d.hist) {
      for (final x in o.linjer) {
        ganger[x.id] = (ganger[x.id] ?? 0) + 1;
      }
    }
    final byLength = d.meny.values.toList()
      ..sort((a, bb) {
        final n = bb.ord.first.length.compareTo(a.ord.first.length);
        if (n != 0) return n;
        final g = (ganger[bb.id] ?? 0).compareTo(ganger[a.id] ?? 0);
        if (g != 0) return g;
        final oa = b(a.butikkId, a.butikk).stengt == null ? 0 : 1, ob = b(bb.butikkId, bb.butikk).stengt == null ? 0 : 1;
        return oa.compareTo(ob);
      });
    for (final v in byLength) {
      final name = v.ord.first;
      if (name.length < 3) continue;
      final i = masked.indexOf(name);
      if (i > -1) {
        t.add((v: v, pos: i));
        masked = masked.replaceRange(i, i + name.length, '#' * name.length);
      }
    }
    for (final v in byLength) {
      if (t.any((x) => x.v.id == v.id)) continue;
      int best = -1;
      for (final o in v.ord.skip(1)) {
        final m = RegExp('(?:^|\\s)${RegExp.escape(o)}(?:\\s|\$)').firstMatch(masked);
        if (m != null && (best < 0 || m.start < best)) best = m.start;
      }
      if (best > -1) {
        t.add((v: v, pos: best));
        final o = v.ord.skip(1).firstWhere((o) => masked.indexOf(o, best) == best || masked.indexOf(o, best) == best + 1);
        final i = masked.indexOf(o, best);
        masked = masked.replaceRange(i, i + o.length, '#' * o.length);
      }
    }
    t.sort((a, bb) => a.pos.compareTo(bb.pos));
    return t;
  }

  /// `hbForslagFor`: the two «LEGG TIL?» chips for the draft.
  List<HbVare> forslagFor(HbUtkast U, HbTilstand st) {
    final har = U.linjer.map((l) => l.id).toList();
    final c = <int, int>{};
    final unng = unngaaSkalldyr(st);
    for (final o in d.hist) {
      final L = o.linjer.map((l) => l.id).toList();
      if (L.any(har.contains)) {
        for (final id in L) {
          if (!har.contains(id)) c[id] = (c[id] ?? 0) + 1;
        }
      }
    }
    for (final v in d.meny.values) {
      if (v.butikkId == U.butikkId && !v.hoved && !har.contains(v.id)) c.putIfAbsent(v.id, () => 0);
    }
    final out = c.keys.map(vare).whereType<HbVare>().where((v) => v.butikkId == U.butikkId && !(unng && v.skalldyr)).toList()
      ..sort((a, bb) {
        final x = c[bb.id]! - c[a.id]!;
        return x != 0 ? x : a.pris.compareTo(bb.pris);
      });
    return out.take(2).toList();
  }

  /// The customer's favourite at an open shop (the prototype's «Casa Maria
  /// er åpen og har pizza»).
  ({HbVare v, HbButikk b})? altAapen(int ikkeButikkId) {
    for (final r in oftest()) {
      final v = vare(r.id)!;
      if (v.butikkId == ikkeButikkId || !v.hoved) continue;
      final bt = b(v.butikkId, v.butikk);
      if (bt.stengt == null) return (v: v, b: bt);
    }
    return null;
  }

  HbSvar _stengtSvar(HbVare v, HbButikk bt) {
    final alt = altAapen(v.butikkId);
    if (alt == null) return HbSvar(tekst: HurtigCopy.stengtIngenAlt(v.butikk, bt.stengt!), humor: 'lei');
    return HbSvar(
      tekst: HurtigCopy.stengt(v.butikk, bt.stengt!, alt.b.navn, alt.v.navn.toLowerCase()),
      humor: 'lei',
      knapper: [HbKnapp(HurtigCopy.jaTa(alt.v.navn), 'leggtil:${alt.v.id}', primar: true), HbKnapp(HurtigCopy.neiTakk, 'si:${HurtigCopy.neiTakk}')],
    );
  }

  HbSvar skalldyrSvar(HbVare v) => HbSvar(
    tekst: HurtigCopy.skalldyrLikevel(v.navn.toLowerCase()),
    humor: 'tenker',
    knapper: [HbKnapp(HurtigCopy.jaLikevel, 'leggtil:${v.id}', primar: true), HbKnapp(HurtigCopy.neiLaVaere, 'si:${HurtigCopy.neiTakk}')],
  );

  /// `hbVelkomst`.
  ({String tekst, List<HbKnapp> knapper}) velkomst(HbTilstand st) {
    final v = vane(st);
    final navn = d.navn.isEmpty ? 'du' : d.navn;
    if (v == null) return (tekst: HurtigCopy.velkomstTom(navn), knapper: const []);
    final s = sum(v.utkast);
    return (
      tekst: HurtigCopy.velkomst(stor(v.dag), navn, tekst(v.linjer, HurtigCopy.og).toLowerCase(), v.butikk),
      knapper: [
        HbKnapp(HurtigCopy.jaDetVanlige(HurtigCopy.kr(s.total)), 'si:${HurtigCopy.detVanlige}', primar: true),
        HbKnapp(HurtigCopy.noeAnnet, 'si:${HurtigCopy.hvaForeslaarDu}'),
      ],
    );
  }

  /// `hbModulSvar`.
  HbSvar modulSvar(String m, HbTilstand st) {
    if (d.hist.isEmpty) return HbSvar(tekst: HurtigCopy.ingenHistorikk, humor: 'tenker', modul: '');
    if (m == 'oftest') {
      final o = oftest();
      final a = vare(o.first.id)!;
      final bb = o.length > 1 ? vare(o[1].id) : null;
      return HbSvar(modul: 'oftest', humor: 'glad', tekst: HurtigCopy.oftestSvar(a.navn, a.butikk, bb?.navn.toLowerCase(), bb?.butikk));
    }
    if (m == 'forrige') {
      final o = d.hist.first;
      return HbSvar(modul: 'forrige', humor: 'glad', tekst: HurtigCopy.forrigeSvar(dato(o.naar), tekst(linjer(o), HurtigCopy.og).toLowerCase(), o.butikk));
    }
    final p = prefForslag(st)!;
    return HbSvar(modul: 'pref', humor: 'tenker', tekst: HurtigCopy.prefSvar(tekst(p.linjer, HurtigCopy.og).toLowerCase(), p.butikk));
  }

  /// `hbTolk`: the local rules; [HbSvar.ai] when none applies.
  HbSvar tolk(String tx, HbTilstand st) {
    final l = ' ${tx.toLowerCase().replaceAll(RegExp(r'[!?.,]'), ' ')} ';
    bool h(List<String> o) => o.any((x) => l.contains(x));
    final U = st.utkast;
    final treff = finn(l);
    final forM = RegExp(r'for (\d+|to|tre|fire|fem|seks) ').firstMatch(l);
    final forN = forM != null ? tall(forM.group(1)!) : 0;
    final klM = RegExp(r'(?:kl |kl\. |klokka |klokken |til )(\d{1,2})(?:[:.](\d{2}))? ').firstMatch(l);
    final klH = klM != null ? int.parse(klM.group(1)!) : 0;
    final tid = klM != null && klH >= 11 && klH <= 23 ? HurtigCopy.klokken('${klH.toString().padLeft(2, '0')}:${klM.group(2) ?? '00'}') : '';
    final kjor = h(['bestill', 'kjør på', 'send den', 'send det']);
    String etter(String t) => kjor ? t + HurtigCopy.bestillerOmFem : t;

    if (st.fase == 'teller' && h(['angre', 'stopp', ' nei ', 'vent'])) return HbSvar(tekst: HurtigCopy.stoppet, humor: 'glad', angre: true);
    if (treff.isEmpty && h(['vanlig', 'oftest', 'favoritt', 'pleier'])) {
      final v = vane(st);
      if (v == null) return HbSvar(tekst: HurtigCopy.ingenHistorikk, humor: 'tenker');
      return HbSvar(modul: 'oftest', humor: 'spent', utkast: v.utkast, tid: tid, bestill: kjor, tekst: etter(HurtigCopy.vanligSvar(v.dag, tekst(v.linjer, HurtigCopy.og).toLowerCase(), v.butikk)));
    }
    if (treff.isEmpty && h(['sist', 'forrige', 'samme igjen', 'samme som'])) {
      if (d.hist.isEmpty) return HbSvar(tekst: HurtigCopy.ingenHistorikk, humor: 'tenker');
      final o = d.hist.first;
      final L = linjer(o);
      return HbSvar(modul: 'forrige', humor: 'glad', utkast: HbUtkast(butikkId: o.butikkId, butikk: o.butikk, linjer: L), tid: tid, bestill: kjor, tekst: etter(HurtigCopy.sammeSomSvar(dato(o.naar), tekst(L, HurtigCopy.og).toLowerCase(), o.butikk)));
    }
    if (treff.isEmpty && h(['preferans', 'hva vet du', 'foreslå', 'forslag', 'overrask', 'velg for meg', 'bestem', 'noe godt', 'middag', 'sulten', 'noe annet'])) {
      final p = prefForslag(st);
      if (p == null) return HbSvar(tekst: HurtigCopy.ingenHistorikk, humor: 'tenker');
      return HbSvar(modul: 'pref', humor: 'spent', utkast: p.utkast, tid: tid, bestill: kjor, tekst: etter(HurtigCopy.prefSattOpp(tekst(p.linjer, HurtigCopy.og).toLowerCase(), p.butikk)));
    }
    if (treff.isEmpty && h([' hei ', 'heisann', 'hallo', 'god kveld'])) {
      return HbSvar(tekst: HurtigCopy.heisann, humor: 'glad', knapper: [HbKnapp(HurtigCopy.detVanlige, 'si:${HurtigCopy.detVanlige}', primar: true)]);
    }
    if (treff.isEmpty && h(['takk']) && !h(['nei takk'])) return HbSvar(tekst: HurtigCopy.bareHyggelig, humor: 'glad');
    if (U != null && treff.isEmpty && (kjor || h([' ja ', 'gjør det', 'perfekt', ' ok ', 'greit', 'flott', 'kjøp']))) {
      return HbSvar(tekst: HurtigCopy.daBestillerJeg, humor: 'spent', bestill: true);
    }
    if (h(['uten ', 'fjern', 'ta bort', 'dropp', 'ikke ', 'slett']) && U != null && treff.isNotEmpty) {
      final ids = treff.map((t) => t.v.id).toList();
      final L = U.linjer.where((x) => !ids.contains(x.id)).toList();
      final borte = [for (final t in treff) if (U.har(t.v.id)) t.v.navn.toLowerCase()];
      if (borte.isEmpty) return HbSvar(tekst: HurtigCopy.ikkeIUtkastet, humor: 'tenker');
      return L.isNotEmpty
          ? HbSvar(utkast: U.kopi(linjer: L), humor: 'glad', tekst: HurtigCopy.fjernet(borte.join(HurtigCopy.og)))
          : HbSvar(tomUtkast: true, humor: 'tenker', tekst: HurtigCopy.fjernetTomt(borte.join(HurtigCopy.og)));
    }
    if (treff.isNotEmpty) {
      final v0 = treff.first.v;
      final bt = b(v0.butikkId, v0.butikk);
      if (bt.stengt != null) return _stengtSvar(v0, bt);
      final sk = treff.where((t) => t.v.skalldyr).firstOrNull;
      if (sk != null && unngaaSkalldyr(st) && !h(['likevel'])) return skalldyrSvar(sk.v);
      final egne = treff.where((t) => t.v.butikkId == v0.butikkId).toList();
      final andre = treff.where((t) => t.v.butikkId != v0.butikkId).toList();
      final samme = U != null && U.butikkId == v0.butikkId;
      final L = samme ? U.linjer.toList() : <HbLinje>[];
      for (final t in egne) {
        final before = l.substring(math.max(0, t.pos - 14), math.max(0, math.min(t.pos, l.length)));
        final m = RegExp(r'(?:^|\s)(\d+|en|én|ett|ei|to|tre|fire|fem|seks)\s*(?:x|×|stk\.?)?\s*$').firstMatch(before);
        var n = m != null ? tall(m.group(1)!) : 0;
        if (n == 0 && forN > 0 && t.v.hoved) n = forN;
        final i = L.indexWhere((x) => x.id == t.v.id);
        if (i > -1) {
          L[i] = L[i].med(n > 0 ? n : L[i].ant + 1);
        } else {
          L.add(HbLinje(t.v.id, n > 0 ? n : vanligAnt(t.v.id)));
        }
      }
      final navn = egne.map((t) {
        final x = L.firstWhere((y) => y.id == t.v.id);
        return '${x.ant > 1 ? '${x.ant}× ' : ''}${t.v.navn.toLowerCase()}';
      }).join(HurtigCopy.og);
      var tekst0 = (samme ? HurtigCopy.lagtTil : HurtigCopy.sattOpp) + navn + HurtigCopy.fra(v0.butikk);
      if (egne.length == 1 && !samme && forN == 0) {
        final va = vanligAnt(egne.first.v.id);
        if (va > 1 && L.first.ant == va) tekst0 += HurtigCopy.duPleierAaTa(va < HurtigCopy.ord.length ? HurtigCopy.ord[va] : '$va');
      }
      if (U != null && !samme) tekst0 += HurtigCopy.lagtTilSide(U.butikk);
      if (andre.isNotEmpty) tekst0 += HurtigCopy.finnesBareHos(andre.first.v.navn, andre.first.v.butikk);
      return HbSvar(
        utkast: HbUtkast(butikkId: v0.butikkId, butikk: v0.butikk, linjer: L, tid: U?.tid ?? ''),
        tid: tid,
        humor: 'spent',
        bestill: kjor,
        tekst: etter(tekst0),
        knapper: U != null && !samme ? [HbKnapp(HurtigCopy.angreBytte, 'angrebytt')] : const [],
      );
    }
    if (h(['billig', 'rimelig', 'spare', 'under '])) {
      final mx = int.tryParse(RegExp(r'under (\d{2,4})').firstMatch(l)?.group(1) ?? '') ?? 0;
      if (U != null) {
        final L = U.linjer.toList();
        double s() => L.fold(0, (a, x) => a + (vare(x.id)?.pris ?? 0) * x.ant);
        final fra = s();
        final grense = mx > 0 ? mx.toDouble() : (fra * .8).roundToDouble();
        var g = 0;
        while (s() > grense && g++ < 30) {
          final side = L.indexWhere((x) => !(vare(x.id)?.hoved ?? true));
          if (side > -1) {
            L.removeAt(side);
            continue;
          }
          final fler = L.indexWhere((x) => x.ant > 1);
          if (fler > -1) {
            L[fler] = L[fler].med(L[fler].ant - 1);
            continue;
          }
          break;
        }
        if (s() == fra) {
          return HbSvar(tekst: HurtigCopy.billigereIkke(HurtigCopy.kr(fra)), humor: 'tenker', knapper: [HbKnapp(HurtigCopy.finnNoeBilligere, 'si:${HurtigCopy.foreslaaNoeAnnet}')]);
        }
        return HbSvar(utkast: U.kopi(linjer: L), humor: 'glad', tekst: HurtigCopy.naaErDet(HurtigCopy.kr(s()), HurtigCopy.kr(fra), s() > grense));
      }
      final kandidater = oftest().map((x) => vare(x.id)!).where((v) => v.hoved && b(v.butikkId, v.butikk).stengt == null).toList()..sort((a, bb) => a.pris.compareTo(bb.pris));
      if (kandidater.isEmpty) return HbSvar.sporAi;
      final bil = kandidater.first;
      return HbSvar(utkast: HbUtkast(butikkId: bil.butikkId, butikk: bil.butikk, linjer: [HbLinje(bil.id, vanligAnt(bil.id))]), humor: 'spent', tekst: HurtigCopy.rimeligste(bil.navn, bil.butikk));
    }
    if (tid.isNotEmpty && U != null) return HbSvar(tid: tid, tekst: HurtigCopy.notertTid(tid.toLowerCase()), humor: 'glad');
    if (h(['levering', 'hvor lang', 'når kommer', 'når er'])) {
      if (U != null) {
        final s = sum(U);
        final bt = b(U.butikkId, U.butikk);
        return HbSvar(tekst: HurtigCopy.leveringNaa(klar(U).toLowerCase(), s.lev == 0, HurtigCopy.kr(bt.frakt), HurtigCopy.kr(bt.gratisOver)), humor: 'glad');
      }
      final first = d.hist.isEmpty ? null : b(d.hist.first.butikkId, d.hist.first.butikk);
      return HbSvar(tekst: HurtigCopy.leveringUten(first?.navn ?? 'Butikken', first?.min ?? 30), humor: 'glad');
    }
    if (h(['nei takk', ' nei ', 'la være'])) return HbSvar(tekst: HurtigCopy.greitLarDetVaere, humor: 'glad');
    return HbSvar.sporAi;
  }
}

/// Hjem's entry line (`hbHjemLinje`): «Fiskesuppe · Torgboden · 347 kr».
String hurtigHjemLinje(HurtigData? d, {DateTime? now}) {
  if (d == null) return HurtigCopy.sjekkerVanene;
  final h = HurtigHjerne(d, now: now);
  final v = h.vane(const HbTilstand());
  if (v == null) return HurtigCopy.placeholder;
  final m0 = h.vare(v.linjer.first.id);
  return '${m0?.navn ?? ''} · ${v.butikk} · ${HurtigCopy.kr(h.sum(v.utkast).total)}';
}

/// A stable sort (Dart's `List.sort` is not guaranteed stable).
void mergeSort<T>(List<T> list, int Function(T, T) compare) {
  if (list.length < 2) return;
  final mid = list.length ~/ 2;
  final left = list.sublist(0, mid), right = list.sublist(mid);
  mergeSort(left, compare);
  mergeSort(right, compare);
  var i = 0, j = 0, k = 0;
  while (i < left.length && j < right.length) {
    list[k++] = compare(left[i], right[j]) <= 0 ? left[i++] : right[j++];
  }
  while (i < left.length) {
    list[k++] = left[i++];
  }
  while (j < right.length) {
    list[k++] = right[j++];
  }
}
