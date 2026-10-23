// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../networking/ops/cus_api.dart';
import '../../../utils/shared_pref_utill.dart' show prefGetString, prefSetString;
import '../../../utils/utils.dart' show resolveSelectedLanguage;

// ── Min Bio (Bergen Step 6, design L19975–20219) ────────────────────────────
// What the customer tells Ægil about food: kosthold, allergier, what they like
// and what they will not have, and a few lines in their own words. The model,
// the text reader (`bioTolk`), the effective set (`bioEff`), the score and the
// sentences are the design's own; the sheet, the Meg card and «Det Ægil vet
// om deg» draw them.
//
// One rule from the backend is kept on top of the design: allergies and diets
// come from chips, never from prose (`ChatToolAllowlist`). What the reader
// finds in the text is a suggestion (the design's ★) until the customer taps
// it; likes and dislikes are soft and count at once.
//
// Customer Step 6 (Customer spec §4.2, Addendum §15): with `cus.bio` on the
// server keeps the bio (`CusBio`, `customer/me/bio`) — the chips as codes,
// only with the customer's consent, plus which diets are strict (a hard
// filter). An «unngår» the text names is a suggestion too now (it is health
// data); what Ærend AI reads (`bio/parse`) and the onboarding's picks are
// suggestions the same way.

// «Uten svin» and «Uten alkohol» are the spec's launch list (not in the design: needs sign-off).
const List<String> bioKostListe = ['Spiser alt', 'Vegetar', 'Veganer', 'Pescetar', 'Halal', 'Kosher', 'Glutenfri', 'Laktosefri', 'Lavkarbo', 'Uten svin', 'Uten alkohol'];
const List<String> bioAllListe = ['Gluten', 'Skalldyr', 'Egg', 'Fisk', 'Peanøtter', 'Nøtter', 'Melk', 'Soya', 'Selleri', 'Sennep', 'Sesam', 'Sulfitt', 'Lupin', 'Bløtdyr'];
const List<String> bioLikListe = ['Fisk', 'Thai', 'Pizza', 'Sushi', 'Burger', 'Indisk', 'Taco', 'Wok', 'Sterkt', 'Bakst', 'Salat', 'Pasta', 'Kylling', 'Kebab'];
const List<String> bioIkkeListe = ['Koriander', 'Sopp', 'Oliven', 'Løk', 'Sterkt', 'Innmat', 'Ost', 'Rosiner'];

/// The server's codes for the diet and allergen chips (`BioVocab`).
const Map<String, String> bioKostKode = {
  'Spiser alt': 'omnivore', 'Vegetar': 'vegetarian', 'Veganer': 'vegan', 'Pescetar': 'pescetarian', 'Halal': 'halal', 'Kosher': 'kosher',
  'Glutenfri': 'gluten_free', 'Laktosefri': 'lactose_free', 'Lavkarbo': 'low_carb', 'Uten svin': 'no_pork', 'Uten alkohol': 'no_alcohol',
};
const Map<String, String> bioAllKode = {
  'Gluten': 'gluten', 'Skalldyr': 'crustaceans', 'Egg': 'eggs', 'Fisk': 'fish', 'Peanøtter': 'peanuts', 'Nøtter': 'nuts', 'Melk': 'milk',
  'Soya': 'soy', 'Selleri': 'celery', 'Sennep': 'mustard', 'Sesam': 'sesame', 'Sulfitt': 'sulphites', 'Lupin': 'lupin', 'Bløtdyr': 'molluscs',
};

/// Diets the customer can make strict (a hard filter: Ægil shows only what fits).
const Set<String> bioStrengbar = {'Vegetar', 'Veganer', 'Halal', 'Kosher', 'Glutenfri', 'Laktosefri', 'Uten svin', 'Uten alkohol'};

/// … of which strict means «only what the store has marked».
const Set<String> bioBareMerket = {'Halal', 'Kosher'};

/// The four chip lists (`BIO_KOST`, `BIO_ALL`, `BIO_LIK`, `BIO_IKKE`).
enum BioListe { kost, all, liker, ikke }

/// An allergen's state: allergy (one tap), avoid (two taps), or taken off.
abstract final class BioAll {
  static const String allergi = 'allergi';
  static const String unnga = 'unnga';
  static const String av = 'av';
}

/// The bio as the customer set it (`st.bio`). [all] holds what they tapped
/// (`allergi` / `unnga` / `av`); [ign] the text finds they took off.
@immutable
class MinBio {
  const MinBio({
    this.kost = const [],
    this.all = const {},
    this.liker = const [],
    this.ikke = const [],
    this.tekst = '',
    this.ign = const [],
    this.ingen = false,
    this.egne = const {},
    this.streng = const {},
    this.kilde,
    this.ai,
    this.ventende = const [],
  });

  final List<String> kost;
  final Map<String, String> all;
  final List<String> liker;
  final List<String> ikke;
  final String tekst;
  final List<String> ign;
  final bool ingen;

  /// The customer's own chips («Legg til»), per list.
  final Map<BioListe, List<String>> egne;

  /// The diets marked strict.
  final Set<String> streng;

  /// The server's bio (Customer Step 6), or null on the Bergen Step 6 path.
  final CusBio? kilde;

  /// What Ærend AI read in the text (`bio/parse`, the model only).
  final BioFunn? ai;

  /// Ægil's onboarding picks waiting for a tap (`kost:Halal`, `all:Nøtter`).
  final List<String> ventende;

  bool get server => kilde != null;

  List<String> egneI(BioListe l) => egne[l] ?? const [];

  MinBio copyWith({
    List<String>? kost,
    Map<String, String>? all,
    List<String>? liker,
    List<String>? ikke,
    String? tekst,
    List<String>? ign,
    bool? ingen,
    Map<BioListe, List<String>>? egne,
    Set<String>? streng,
    BioFunn? ai,
    List<String>? ventende,
  }) =>
      MinBio(
        kost: kost ?? this.kost,
        all: all ?? this.all,
        liker: liker ?? this.liker,
        ikke: ikke ?? this.ikke,
        tekst: tekst ?? this.tekst,
        ign: ign ?? this.ign,
        ingen: ingen ?? this.ingen,
        egne: egne ?? this.egne,
        streng: streng ?? this.streng,
        kilde: kilde,
        ai: ai ?? this.ai,
        ventende: ventende ?? this.ventende,
      );
}

/// What a text says (`bioTolk`), or what counts (`bioEff`): the same four lists.
class BioFunn {
  BioFunn({required this.kost, required this.all, required this.liker, required this.ikke});

  final List<String> kost;
  final Map<String, String> all;
  final List<String> liker;
  final List<String> ikke;

  /// `bioTagger`: `kost:X`, `all:X`, `lik:X`, `ikke:X`.
  List<String> get tagger => [
        for (final x in kost) 'kost:$x',
        for (final x in all.keys) 'all:$x',
        for (final x in liker) 'lik:$x',
        for (final x in ikke) 'ikke:$x',
      ];
}

/// `bioEff`: what counts. [p] is the text's reading, [fjernet] the likes taken
/// off because they clash with a diet or an allergy (`[like, 'Vegetar']` or
/// `[like, 'allergi:Fisk']`), [forslag] the allergies and diets the text
/// suggests and the customer has not tapped yet.
class BioEff extends BioFunn {
  BioEff({
    required super.kost,
    required super.all,
    required super.liker,
    required super.ikke,
    required this.p,
    required this.fjernet,
    required this.forslag,
  });

  final BioFunn p;
  final List<(String, String)> fjernet;
  final List<String> forslag;
}

final List<(RegExp, String)> _kostRe = [
  (RegExp('vegan'), 'Veganer'),
  (RegExp('vegetar'), 'Vegetar'),
  (RegExp('pescetar|pesketar'), 'Pescetar'),
  (RegExp('halal'), 'Halal'),
  (RegExp('kosher'), 'Kosher'),
  (RegExp('glutenfri|cøliaki'), 'Glutenfri'),
  (RegExp('laktosefri|laktoseintoler'), 'Laktosefri'),
  (RegExp('lavkarbo|keto'), 'Lavkarbo'),
  (RegExp('ikke svin|uten svin|ingen svin'), 'Uten svin'),
  (RegExp('alkoholfri|uten alkohol|ingen alkohol|drikker ikke'), 'Uten alkohol'),
];

final List<(RegExp, String)> _allRe = [
  (RegExp('skalldyr|reke|krabbe|hummer|scampi|kreps'), 'Skalldyr'),
  (RegExp('peanøtt|peanut'), 'Peanøtter'),
  (RegExp('(^|[^a])nøtt|mandel|cashew'), 'Nøtter'),
  (RegExp('(^|[^a-zæøå])egg'), 'Egg'),
  (RegExp('melk|laktose|meieri'), 'Melk'),
  (RegExp('gluten|hvete|cøliaki'), 'Gluten'),
  (RegExp('fisk'), 'Fisk'),
  (RegExp('soya|soja'), 'Soya'),
  (RegExp('sesam'), 'Sesam'),
  (RegExp('selleri'), 'Selleri'),
  (RegExp('sennep'), 'Sennep'),
  (RegExp('bløtdyr|blåskjell|østers|blekksprut|skjell'), 'Bløtdyr'),
  (RegExp('sulfitt'), 'Sulfitt'),
  (RegExp('lupin'), 'Lupin'),
];

final List<(RegExp, String)> _likRe = [
  (RegExp('fisk|laks|torsk'), 'Fisk'),
  (RegExp('thai'), 'Thai'),
  (RegExp('pizza'), 'Pizza'),
  (RegExp('sushi'), 'Sushi'),
  (RegExp('burger'), 'Burger'),
  (RegExp('indisk|curry'), 'Indisk'),
  (RegExp('taco|meksikansk'), 'Taco'),
  (RegExp('wok|asiatisk|kinesisk'), 'Wok'),
  (RegExp('sterk|chili|spicy'), 'Sterkt'),
  (RegExp('bakst|boller|bakeri|kanel'), 'Bakst'),
  (RegExp('salat|sunt|grønt'), 'Salat'),
  (RegExp('pasta|italiensk'), 'Pasta'),
  (RegExp('kylling'), 'Kylling'),
  (RegExp('kebab'), 'Kebab'),
  (RegExp('koriander'), 'Koriander'),
  (RegExp('sopp'), 'Sopp'),
  (RegExp('oliven'), 'Oliven'),
  (RegExp('løk'), 'Løk'),
  (RegExp('innmat|(^|[^a-zæøå])lever(\$|[^a-zæøå])'), 'Innmat'),
  (RegExp('(^|[^a-zæøå])ost(\$|[^a-zæøå])'), 'Ost'),
  (RegExp('rosin'), 'Rosiner'),
];

final RegExp _hardRe = RegExp('allergi|allergisk|tåler ikke|tåle|cøliaki|anafylak|epipen|livsfarlig');
// At a word's start: «uten» is not the end of «gluten» (fixed with the server's reader).
final RegExp _negRe = RegExp('(?<![a-zæøå])(ikke|uten|hater|unngå|aldri|nei takk|dropper|kutter)');
final RegExp _ikkeKostRe = RegExp('ikke (vegan|vegetar|halal|kosher)');

/// `bioTolk`: reads the bio text, clause by clause.
BioFunn bioTolk(String t) {
  final kost = <String>[], liker = <String>[], ikke = <String>[];
  final all = <String, String>{};
  void add(List<String> a, String v) {
    if (!a.contains(v)) a.add(v);
  }

  for (final c in t.toLowerCase().split(RegExp(r'[.!?;\n,]| men '))) {
    if (c.trim().isEmpty) continue;
    final hard = _hardRe.hasMatch(c);
    final neg = hard || _negRe.hasMatch(c);
    for (final (re, n) in _kostRe) {
      if (re.hasMatch(c) && !_ikkeKostRe.hasMatch(c)) add(kost, n);
    }
    if (RegExp('cøliaki|glutenfri').hasMatch(c)) all['Gluten'] = BioAll.allergi;
    if (RegExp('laktosefri|laktoseintoler').hasMatch(c)) all['Melk'] ??= BioAll.unnga;
    if (neg) {
      for (final (re, n) in _allRe) {
        if (re.hasMatch(c)) all[n] = hard ? BioAll.allergi : (all[n] ?? BioAll.unnga);
      }
    }
    for (final (re, n) in _likRe) {
      if (!re.hasMatch(c)) continue;
      if (neg) {
        if (!_allRe.any((a) => a.$2 == n) && bioIkkeListe.contains(n)) add(ikke, n);
      } else if (bioLikListe.contains(n)) {
        add(liker, n);
      }
    }
  }
  return BioFunn(kost: kost, all: all, liker: liker, ikke: ikke);
}

/// Likes a diet rules out (`KONF`), and an allergy rules out (`ALLK`).
const Map<String, List<String>> _konf = {
  'Veganer': ['Fisk', 'Sushi', 'Kylling', 'Kebab', 'Burger', 'Ost', 'Bakst'],
  'Vegetar': ['Fisk', 'Sushi', 'Kylling', 'Kebab', 'Burger'],
  'Pescetar': ['Kylling', 'Kebab', 'Burger'],
  'Glutenfri': ['Pizza', 'Pasta', 'Bakst'],
  'Laktosefri': ['Ost'],
  'Lavkarbo': ['Pizza', 'Pasta', 'Bakst'],
};
const Map<String, List<String>> _allk = {
  'Fisk': ['Fisk', 'Sushi'],
  'Gluten': ['Pizza', 'Pasta', 'Bakst', 'Burger'],
  'Melk': ['Ost'],
  'Bløtdyr': ['Sushi'],
};

/// Two readings as one (the text's and Ærend AI's).
BioFunn _flett(BioFunn a, BioFunn? b) {
  if (b == null) return a;
  return BioFunn(
    kost: [...a.kost, ...b.kost.where((x) => !a.kost.contains(x))],
    all: {...b.all, ...a.all},
    liker: [...a.liker, ...b.liker.where((x) => !a.liker.contains(x))],
    ikke: [...a.ikke, ...b.ikke.where((x) => !a.ikke.contains(x))],
  );
}

/// `bioEff`: the customer's taps over the text's reading.
BioEff bioEff(MinBio b) {
  final p0 = bioTolk(b.tekst);
  final p = _flett(p0, b.ai);
  final ign = b.ign;
  List<String> u(String pre, List<List<String>> ls) {
    final o = <String>[];
    for (final l in ls) {
      for (final v in l) {
        if (!o.contains(v) && !ign.contains('$pre$v')) o.add(v);
      }
    }
    return o;
  }

  final forslag = <String>[];
  // The text's allergies and «unngår» are suggestions (health data: a tap decides).
  final allM = <String, String>{};
  p.all.forEach((k, v) {
    if (!b.all.containsKey(k)) {
      if (v == BioAll.allergi || v == BioAll.unnga) forslag.add('all:$k');
    } else {
      allM[k] = v;
    }
  });
  allM.addAll(b.all);
  final all = <String, String>{
    for (final e in allM.entries)
      if (e.value == BioAll.allergi || e.value == BioAll.unnga) e.key: e.value,
  };
  // So are its diets.
  for (final k in u('kost:', [p.kost])) {
    if (!b.kost.contains(k)) forslag.add('kost:$k');
  }
  var kost = u('kost:', [b.kost]);
  if (kost.length > 1) kost = kost.where((x) => x != 'Spiser alt').toList();
  // Ægil's onboarding picks, until tapped or taken off.
  for (final t in b.ventende) {
    final (l, n) = _del(t);
    final venter = l == 'kost' ? !b.kost.contains(n) && !ign.contains(t) : (l == 'all' && !b.all.containsKey(n));
    if (venter && !forslag.contains(t)) forslag.add(t);
  }

  final fjernet = <(String, String)>[];
  final ikke = u('ikke:', [b.ikke, p.ikke]);
  final liker = u('lik:', [b.liker, p.liker]).where((x) {
    if (ikke.contains(x)) return false;
    final k = kost.where((k) => (_konf[k] ?? const []).contains(x)).firstOrNull;
    if (k != null) {
      fjernet.add((x, k));
      return false;
    }
    final a = all.keys.where((a) => all[a] == BioAll.allergi && (_allk[a] ?? const []).contains(x)).firstOrNull;
    if (a != null) {
      fjernet.add((x, 'allergi:$a'));
      return false;
    }
    return true;
  }).toList();
  return BioEff(kost: kost, all: all, liker: liker, ikke: ikke, p: p0, fjernet: fjernet, forslag: forslag);
}

/// `bioScore`: one point each for a diet, the allergies answered, two likes,
/// one dislike and twenty characters of own words.
int bioScore(MinBio b, [BioEff? e]) {
  final E = e ?? bioEff(b);
  return [
    E.kost.isNotEmpty,
    E.all.isNotEmpty || b.ingen,
    E.liker.length >= 2,
    E.ikke.isNotEmpty,
    b.tekst.trim().length >= 20,
  ].where((x) => x).length;
}

/// `hbStor`: the first letter up.
String bioStor(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// `bioAdj`: the diet as an adjective.
String bioAdj(String k) =>
    const {
      'Veganer': 'vegansk',
      'Vegetar': 'vegetarisk',
      'Pescetar': 'pescetariansk',
      'Glutenfri': 'glutenfritt',
      'Laktosefri': 'laktosefritt',
      'Lavkarbo': 'lavkarbo',
      'Halal': 'halal',
      'Kosher': 'kosher',
      'Uten svin': 'uten svin',
      'Uten alkohol': 'uten alkohol',
    }[k] ??
    k.toLowerCase();

(String, String) _del(String key) {
  final i = key.indexOf(':');
  return (key.substring(0, i), key.substring(i + 1));
}

/// `bioEtikett`: «allergi mot skalldyr», «unngår melk», «liker thai» …
String bioEtikett(String key, BioFunn E) {
  final (t, n) = _del(key);
  final l = n.toLowerCase();
  return switch (t) {
    'kost' => l,
    'all' => E.all[n] == BioAll.unnga ? 'unngår $l' : 'allergi mot $l',
    'lik' => 'liker $l',
    _ => 'ikke $l',
  };
}

/// `lst`: «a, b og c» from the first [m].
String bioLst(List<String> a, [int m = 2]) {
  final x = a.take(m).map((s) => s.toLowerCase()).toList();
  if (x.length > 1) return '${x.sublist(0, x.length - 1).join(', ')} og ${x.last}';
  return x.firstOrNull ?? '';
}

/// `NAVN`: what Ægil calls the bond at each score.
const List<String> bioNivaaNavn = ['Ny bekjent', 'Hilst på', 'Bekjent', 'Kjenner deg', 'Kjenner deg godt', 'Som en venn'];

abstract final class BioCopy {
  static const String tittel = 'Min Bio';
  static const String linje = 'Ægil leser alt her og husker det. Agentene i Ærend bruker det i hele appen.';
  static const String lagre = 'Lagre i Ægils minne';
  static const String intelligence = 'Ærend Intelligence';
  static const String kortLinje = 'Mat, allergier og kosthold. Ægil leser og husker alt.';
  static const String aegil = 'Ægil: ';
  static const String setningTom = 'Fortell meg hva du liker, så tilpasser jeg appen til deg.';
  static const String aegStart = 'Fortell meg hva du liker og hva du ikke tåler. Jeg husker alt, og passer på i hele appen.';
  static const String kjennerDeg = 'ÆGIL KJENNER DEG';
  static const String venn = 'Nå kjenner jeg deg som en venn! Hele appen er tilpasset deg.';
  static const String nesteFerdig = 'Ægil kjenner deg som en venn. Alt i appen er tilpasset deg.';
  static String neste(String mangler, String navn) => 'Neste: $mangler, så blir Ægil «${navn.toLowerCase()}».';
  static String score(int n) => '$n av 5';
  static String nivaa(int n) => '${bioNivaaNavn[n]} · $n/5';

  static const String k1 = '1 · Kosthold';
  static const String k1Sub = 'Velg det som gjelder deg. Ægil foreslår bare det som passer.';
  static const String k2 = '2 · Allergier og intoleranser';
  static const String k2Sub = 'Trykk én gang for allergi. To ganger hvis du bare vil unngå det.';
  static const String k3 = '3 · Det du liker';
  static const String k3Sub = 'Dette legger Ægil øverst.';
  static const String k4 = '4 · Det du ikke vil ha';
  static const String k4Sub = 'Ægil foreslår det aldri, og sier fra hvis det er med.';
  static const String k5 = '5 · Med egne ord';
  static const String ingenAllergier = 'Ingen allergier';
  static const String merkeAllergi = 'ALLERGI';
  static const String merkeUnngaar = 'UNNGÅR';
  static const String leggTil = 'Legg til';
  static const Map<BioListe, String> nyHint = {
    BioListe.kost: 'Mangler noe? F.eks. FODMAP',
    BioListe.all: 'Annen allergi? F.eks. kiwi',
    BioListe.liker: 'Noe annet du liker? F.eks. ramen',
    BioListe.ikke: 'Mer du vil unngå? F.eks. aubergine',
  };
  static const String skrivSom = 'SKRIV SOM TIL EN VENN';
  static const String aegilLeser = 'Ægil leser';
  static const String tekstHint = 'F.eks. Allergisk mot nøtter. Spiser halal. Elsker sterk mat, men ikke koriander.';
  static const String plukker = 'Ægil plukker ut det viktige mens du skriver';
  static const String fanget = 'ÆGIL FANGET OPP FRA TEKSTEN';
  static const String lagrer = 'Lagrer i minnet mitt …';
  static const String lagret = 'Lagret! Nå passer jeg på i hele appen.';
  static String lagretToast(int n) => 'Lagret · Ægil husker $n ting om deg';
  static const String ikkeLagret = 'Fikk ikke lagret. Prøv igjen.';

  /// Not in the design (needs sign-off): the text's allergies and diets wait
  /// for a tap.
  static const String trykkForAaHuske = 'Allergier og kosthold husker jeg når du trykker på dem.';

  static const Map<String, String> si = {
    'Spiser alt': 'Du spiser alt! Da kan jeg tipse deg om mye mer.',
    'Vegetar': 'Vegetar, notert. Jeg hopper over kjøtt og fisk.',
    'Veganer': 'Veganer! Ikke noe kjøtt, fisk, egg eller melk fra meg.',
    'Pescetar': 'Fisk ja, kjøtt nei. Skjønner!',
    'Halal': 'Halal, notert. Jeg sjekker at butikken har merket retten.',
    'Kosher': 'Kosher, notert. Jeg viser bare det butikken har merket.',
    'Glutenfri': 'Glutenfritt. Jeg sier fra om alt med gluten.',
    'Laktosefri': 'Laktosefritt. Jeg sjekker melken for deg.',
    'Lavkarbo': 'Lavkarbo! Mindre brød og pasta, mer av det andre.',
    // Not in the design (needs sign-off): the spec's two launch diets.
    'Uten svin': 'Uten svin, notert. Jeg sjekker navnet og det butikken skriver.',
    'Uten alkohol': 'Uten alkohol, notert. Ingen øl, vin eller sprit fra meg.',
  };

  // «Det Ægil vet om deg» (`agMinne`).
  static const String minneKicker = 'DET ÆGIL VET OM DEG';
  static const String minneLinje = 'Alt her er ditt. Ægil bruker ingenting som ikke står her, og du kan fjerne alt.';
  static const String redigerBio = 'Rediger Min Bio';
  static const String medEgneOrd = 'MED EGNE ORD';
  static const List<String> grupper = ['Kosthold', 'Allergier', 'Du liker', 'Vil ikke ha'];
  static const List<String> grupperTom = ['Ikke valgt ennå', 'Ikke sjekket ennå', 'Fortell Ægil hva du liker', 'Ingenting ennå'];
}

/// The Ægil sentence on the card (`bioSetning`).
String bioSetning(BioEff E) {
  final kostE = E.kost.where((k) => k != 'Spiser alt').toList();
  final aa = E.all.keys.where((k) => E.all[k] == BioAll.allergi).toList();
  final un = E.all.keys.where((k) => E.all[k] == BioAll.unnga).toList();
  final s = <String>[];
  if (kostE.isNotEmpty) s.add('Alt jeg foreslår er ${bioLst(kostE.map(bioAdj).toList(), 3)}.');
  if (aa.isNotEmpty) {
    s.add('Jeg viser deg aldri ${bioLst(aa, 3)}.');
  } else if (un.isNotEmpty) {
    s.add('Jeg sier fra om ${bioLst(un)}.');
  }
  if (E.liker.isNotEmpty) s.add('${bioStor(bioLst(E.liker))} kommer først.');
  if (E.ikke.isNotEmpty && s.length < 3) s.add('Og ingen ${bioLst(E.ikke, 1)}.');
  return s.isEmpty ? BioCopy.setningTom : s.join(' ');
}

/// `bioNesteTx`: the next thing to do, or the friend line at 5/5.
String bioNeste(MinBio b, BioEff E) {
  final score = bioScore(b, E);
  final kriterier = [
    (E.kost.isNotEmpty, 'velg kosthold'),
    (E.all.isNotEmpty || b.ingen, 'sjekk allergiene'),
    (E.liker.length >= 2, 'velg minst to ting du liker'),
    (E.ikke.isNotEmpty, 'velg noe du ikke vil ha'),
    (b.tekst.trim().length >= 20, 'skriv litt med egne ord'),
  ];
  final m = kriterier.where((k) => !k.$1).firstOrNull;
  return m == null ? BioCopy.nesteFerdig : BioCopy.neste(m.$2, bioNivaaNavn[score + 1]);
}

/// The sheet's state: the bio, the last tapped chip (`bioSist`), what Ægil
/// says (`bioAeg`) and how often he has spoken (`bioN`, which restarts his hop).
class MinBioKontroll extends ChangeNotifier {
  MinBioKontroll(this._bio);

  MinBio _bio;
  MinBio get bio => _bio;

  int n = 0;
  String? sist;
  String? aeg;

  /// Text finds that just appeared (`bioNye`) and pop.
  List<String> nye = const [];

  /// True while the customer types and for 900 ms after (`bioSkriver`).
  bool skriver = false;

  /// Ærend AI's line under the finds (`bioAiTx`), after a model reading.
  String? aiTx;

  Timer? _skT, _vennT;

  BioEff get eff => bioEff(_bio);

  @override
  void dispose() {
    _skT?.cancel();
    _vennT?.cancel();
    super.dispose();
  }

  void si(String tx, {String? key}) {
    n++;
    sist = key;
    aeg = tx;
    notifyListeners();
  }

  /// `bioKonfTx`: the likes a change took off, said once.
  static String konfTx(List<(String, String)> for0, MinBio etter) {
    final nye = bioEff(etter).fjernet.where((f) => !for0.any((g) => g.$1 == f.$1)).toList();
    if (nye.isEmpty) return '';
    final f = nye.first;
    final hvem = f.$2.startsWith('allergi:') ? 'allergien mot ${f.$2.substring(8).toLowerCase()}' : bioAdj(f.$2);
    final hva = nye.length > 1 ? '${nye.first.$1} og ${nye.skip(1).map((x) => x.$1.toLowerCase()).join(' og ')} passer' : '${f.$1} passer';
    return ' $hva ikke med $hvem, så jeg tok ${nye.length > 1 ? 'dem' : 'den'} bort.';
  }

  /// `bioSett`.
  void _sett(MinBio nb, String? key, String? tx) {
    final for0 = bioScore(_bio);
    final ktx = konfTx(eff.fjernet, nb);
    _bio = nb;
    sist = key;
    n++;
    aeg = (tx ?? aeg ?? '') + ktx;
    notifyListeners();
    if (for0 < 5 && bioScore(_bio) == 5) {
      _vennT?.cancel();
      _vennT = Timer(const Duration(milliseconds: 1500), () => si(BioCopy.venn));
    }
  }

  /// `bioKost`. A diet that can be strict starts strict (Customer Step 6).
  void kost(String k) {
    final b = _bio;
    final on = eff.kost.contains(k);
    var kost = [...b.kost];
    var ign = [...b.ign];
    var streng = {...b.streng};
    if (on) {
      kost.remove(k);
      ign.add('kost:$k');
      streng.remove(k);
    } else {
      ign.remove('kost:$k');
      if (k == 'Spiser alt') {
        for (final x in eff.kost) {
          if (x != k) ign.add('kost:$x');
        }
        kost = [k];
        streng = {};
      } else {
        kost = [...kost.where((x) => x != 'Spiser alt'), k];
        if (bioStrengbar.contains(k)) streng.add(k);
      }
    }
    _sett(b.copyWith(kost: kost, ign: ign.toSet().toList(), streng: streng), 'kost:$k',
        on ? 'Ok, jeg glemmer «$k».' : (BioCopy.si[k] ?? '«$k», notert. Det tar jeg hensyn til i alt jeg foreslår.'));
  }

  /// Strict or not (Customer Step 6, not in the design: needs sign-off).
  void strengTrykk(String k) {
    final b = _bio;
    final na = !b.streng.contains(k);
    _sett(b.copyWith(streng: na ? {...b.streng, k} : ({...b.streng}..remove(k))), 'streng:$k', na ? CusBioCopy.cus_bio_streng_paa(k) : CusBioCopy.cus_bio_streng_av(k));
  }

  /// What Ærend AI read (`bio/parse` with the model). Its finds are
  /// suggestions like the text's; Ægil names the new ones.
  void settAi(BioFunn ai) {
    final for0 = bioEff(_bio).forslag.toSet()..addAll(bioEff(_bio).tagger);
    final etter = _bio.copyWith(ai: ai);
    final E = bioEff(etter);
    final nyeT = [...E.forslag, ...E.tagger].where((x) => !for0.contains(x)).toSet().toList();
    _bio = etter;
    final ord = nyeT.map((x) => bioEtikett(x, _flett(E.p, ai))).join(', ');
    aiTx = nyeT.isEmpty ? CusBioCopy.cus_bio_ai_stemmer : CusBioCopy.cus_bio_ai_fant(ord);
    if (nyeT.isNotEmpty) {
      nye = nyeT;
      n++;
      sist = null;
      aeg = CusBioCopy.cus_bio_ai_aeg(ord);
    }
    notifyListeners();
  }

  /// `bioAllTrykk`: none → allergy → avoid → none.
  void allTrykk(String k) {
    final b = _bio;
    final cur = eff.all[k];
    final nx = cur == null ? BioAll.allergi : (cur == BioAll.allergi ? BioAll.unnga : BioAll.av);
    final lk = k.toLowerCase();
    _sett(
      b.copyWith(all: {...b.all, k: nx}, ingen: false),
      'all:$k',
      switch (nx) {
        BioAll.allergi => 'Allergi mot $lk. Det viser jeg deg aldri.',
        BioAll.unnga => 'Du unngår $lk. Jeg sier fra hvis det er med.',
        _ => '${bioStor(lk)} er fjernet fra lista.',
      },
    );
  }

  bool get ingenPaa => _bio.ingen && eff.all.isEmpty;

  /// `bioIngen`.
  void ingen() {
    final b = _bio;
    final ny = !ingenPaa;
    final all = {...b.all};
    if (ny) {
      for (final k in eff.all.keys) {
        all[k] = BioAll.av;
      }
      // The text's suggestions go too.
      for (final f in eff.forslag) {
        if (f.startsWith('all:')) all[f.substring(4)] = BioAll.av;
      }
    }
    _sett(b.copyWith(all: all, ingen: ny), 'ingen', ny ? 'Ingen allergier, notert. Si fra hvis noe endrer seg.' : 'Ok. Velg det du ikke tåler.');
  }

  /// `bioLik`: [liste] is `liker` or `ikke`; a like moves out of `ikke`.
  void lik(String k, BioListe liste) {
    final b = _bio;
    final E = eff;
    final erLik = liste == BioListe.liker;
    final on = (erLik ? E.liker : E.ikke).contains(k);
    final pre = erLik ? 'lik:' : 'ikke:';
    final apre = erLik ? 'ikke:' : 'lik:';
    var L = [...(erLik ? b.liker : b.ikke)];
    var A = [...(erLik ? b.ikke : b.liker)];
    final ign = [...b.ign];
    if (on) {
      L.remove(k);
      ign.add('$pre$k');
    } else {
      ign.remove('$pre$k');
      L.add(k);
      if ((erLik ? E.ikke : E.liker).contains(k)) {
        A.remove(k);
        ign.add('$apre$k');
      }
    }
    final lk = k.toLowerCase();
    MinBio med(MinBio x) => erLik ? x.copyWith(liker: L, ikke: A, ign: ign.toSet().toList()) : x.copyWith(ikke: L, liker: A, ign: ign.toSet().toList());
    if (!on && erLik) {
      final f = bioEff(med(b)).fjernet.where((x) => x.$1 == k).firstOrNull;
      if (f != null) {
        final hvem = f.$2.startsWith('allergi:') ? 'allergien mot ${f.$2.substring(8).toLowerCase()}' : bioAdj(f.$2);
        _sett(b, '$pre$k', '$k passer ikke med $hvem. Den foreslår jeg ikke.');
        return;
      }
    }
    _sett(med(b), '$pre$k', on ? 'Greit, «$k» er fjernet.' : (erLik ? '${bioStor(lk)}! Det legger jeg øverst for deg.' : 'Ingen $lk. Skal bli!'));
  }

  /// `bioSkriv`: the text, up to 400 characters, read as it is typed.
  void skriv(String v0) {
    final v = v0.length > 400 ? v0.substring(0, 400) : v0;
    final b = _bio;
    final f0 = bioTolk(b.tekst).tagger;
    final P = bioTolk(v);
    final nyeT = P.tagger.where((x) => !f0.contains(x)).toList();
    final etter = b.copyWith(tekst: v);
    _bio = etter;
    skriver = true;
    if (nyeT.isNotEmpty) {
      final ktx = konfTx(bioEff(b).fjernet, etter);
      final harde = nyeT.where((x) => x.startsWith('kost:') || (x.startsWith('all:') && P.all[x.substring(4)] == BioAll.allergi)).isNotEmpty;
      nye = nyeT;
      n++;
      sist = null;
      final ord = nyeT.map((x) => bioEtikett(x, P)).join(', ');
      aeg = harde ? 'Fanget opp: $ord. ${BioCopy.trykkForAaHuske}$ktx' : 'Fanget opp: $ord. Notert!$ktx';
    }
    notifyListeners();
    _skT?.cancel();
    _skT = Timer(const Duration(milliseconds: 900), () {
      skriver = false;
      notifyListeners();
    });
  }

  /// `bioNyLegg`: a chip of the customer's own, up to 28 characters.
  void nyLegg(BioListe t, String tekst) {
    final raw = tekst.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (raw.isEmpty) return;
    final kort = raw.length > 28 ? raw.substring(0, 28) : raw;
    final navn = bioStor(kort);
    final b = _bio;
    final base = [...switch (t) { BioListe.kost => bioKostListe, BioListe.all => bioAllListe, BioListe.liker => bioLikListe, BioListe.ikke => bioIkkeListe }, ...b.egneI(t)];
    final fins = base.where((x) => x.toLowerCase() == navn.toLowerCase()).firstOrNull;
    final k = fins ?? navn;
    final E = eff;
    final egne = fins != null ? b.egne : {...b.egne, t: [...b.egneI(t), k]};
    switch (t) {
      case BioListe.kost:
        if (E.kost.contains(k)) return _sett(b.copyWith(egne: egne), 'kost:$k', '«$k» har jeg allerede notert.');
        _bio = b.copyWith(egne: egne);
        return kost(k);
      case BioListe.all:
        final lk = k.toLowerCase();
        return _sett(b.copyWith(egne: egne, all: {...b.all, k: BioAll.allergi}, ingen: false), 'all:$k',
            // The design adds «Jeg sjekker det mot alle menyene» for a new one;
            // menus do not read the bio, so that half is left out.
            'Allergi mot $lk, notert. Det viser jeg deg aldri.');
      case BioListe.liker || BioListe.ikke:
        final on = (t == BioListe.liker ? E.liker : E.ikke).contains(k);
        if (on) return _sett(b.copyWith(egne: egne), '${t == BioListe.liker ? 'lik:' : 'ikke:'}$k', '«$k» står der allerede.');
        _bio = b.copyWith(egne: egne);
        return lik(k, t);
    }
  }
}

// ── Load and save (`agent/me/memory`, `agent/me/settings`) ──────────────────

/// The memory kinds the bio owns, per list. «Unngår» is `avoid` (soft).
const String _diet = 'diet', _allergen = 'allergen', _avoid = 'avoid', _like = 'like', _dislike = 'dislike';
const Set<String> bioKinds = {_diet, _allergen, _avoid, _like, _dislike};

String _navn(MemoryEntry m) => (m.label ?? m.value).trim();

/// A line the bio owns. Onboarding's store categories (`like` ·
/// `kategori:…`, «Mote», «Bakeri») are not food and stay out of it.
bool bioEier(MemoryEntry m) => bioKinds.contains(m.kind) && !m.value.startsWith('kategori:');

String? _kanon(List<String> liste, String navn) => liste.where((x) => x.toLowerCase() == navn.toLowerCase()).firstOrNull;

/// The bio from what Ægil remembers. Every line is the customer's own (a tap
/// or an answer), so it loads as tapped; what the text says beyond it was
/// taken off before, so it stays off.
MinBio minBioFra(List<MemoryEntry> minne, AegilSettings? s) {
  final kost = <String>[], liker = <String>[], ikke = <String>[];
  final all = <String, String>{};
  final egne = <BioListe, List<String>>{};
  void legg(BioListe l, List<String> base, List<String> inn, String navn) {
    final k = _kanon(base, navn) ?? _kanon(egne[l] ?? const [], navn);
    if (k == null) (egne[l] ??= []).add(bioStor(navn));
    final v = k ?? bioStor(navn);
    if (!inn.contains(v)) inn.add(v);
  }

  for (final m in minne) {
    final navn = _navn(m);
    if (navn.isEmpty || !bioEier(m)) continue;
    switch (m.kind) {
      case _diet:
        legg(BioListe.kost, bioKostListe, kost, navn);
      case _like:
        legg(BioListe.liker, bioLikListe, liker, navn);
      case _dislike:
        legg(BioListe.ikke, bioIkkeListe, ikke, navn);
      case _allergen || _avoid:
        final k = _kanon(bioAllListe, navn) ?? _kanon(egne[BioListe.all] ?? const [], navn);
        if (k == null) (egne[BioListe.all] ??= []).add(bioStor(navn));
        final v = k ?? bioStor(navn);
        // An allergy outranks an avoid line for the same thing.
        if (all[v] != BioAll.allergi) all[v] = m.kind == _allergen ? BioAll.allergi : BioAll.unnga;
    }
  }
  final tekst = s?.bioText ?? '';
  final p = bioTolk(tekst);
  final ign = <String>[
    for (final x in p.kost)
      if (!kost.contains(x)) 'kost:$x',
    for (final x in p.liker)
      if (!liker.contains(x)) 'lik:$x',
    for (final x in p.ikke)
      if (!ikke.contains(x)) 'ikke:$x',
  ];
  // The text's soft «unngår» that was not kept is off; its allergies are
  // only ever suggestions.
  p.all.forEach((k, v) {
    if (v == BioAll.unnga && !all.containsKey(k)) all[k] = BioAll.av;
  });
  return MinBio(kost: kost, all: all, liker: liker, ikke: ikke, tekst: tekst, ign: ign, ingen: s?.noAllergies ?? false, egne: egne);
}

/// Saves the bio: forgets the lines that went, adds the new ones as explicit
/// chips (`me/preferences/batch`), then the own words and «Ingen allergier».
/// Returns how many things Ægil now knows, or null when a call failed.
Future<int?> minBioLagre(AegilRepo repo, MinBio bio, List<MemoryEntry> minne) async {
  final E = bioEff(bio);
  final maal = <(String, String)>[
    for (final x in E.kost) (_diet, x),
    for (final e in E.all.entries) (e.value == BioAll.allergi ? _allergen : _avoid, e.key),
    for (final x in E.liker) (_like, x),
    for (final x in E.ikke) (_dislike, x),
  ];
  bool samme((String, String) a, MemoryEntry m) => a.$1 == m.kind && a.$2.toLowerCase() == _navn(m).toLowerCase();
  final gamle = minne.where(bioEier).toList();
  final borte = gamle.where((m) => !maal.any((a) => samme(a, m))).toList();
  final nye = maal.where((a) => !gamle.any((m) => samme(a, m))).toList();

  final slettet = await Future.wait(borte.map((m) => repo.forget(m.id)));
  if (slettet.contains(false)) return null;
  if (nye.isNotEmpty) {
    final r = await repo.submitChips([
      for (final (kind, navn) in nye) OnboardingChip(kind: kind, value: navn.toLowerCase(), label: navn, selected: true),
    ]);
    if (r.error != null) return null;
  }
  final s = await repo.updateSettings({'bio_text': bio.tekst.trim(), 'no_allergies': bio.ingen && E.all.isEmpty});
  if (s.settings == null) return null;
  return E.tagger.length;
}

// ── Customer Step 6: the server's bio (`customer/me/bio`) ───────────────────

String? _navnFra(Map<String, String> kart, String kode) => kart.entries.where((e) => e.value == kode).firstOrNull?.key;

/// The sheet's bio from the server's: codes to chips, the customer's own
/// words to own chips, likes by their stored value first («koriander» →
/// «Koriander»). [ventende]: the onboarding's picks still waiting for a tap.
MinBio minBioFraCus(CusBio c, {List<String> ventende = const []}) {
  final kost = <String>[], liker = <String>[], ikke = <String>[];
  final all = <String, String>{};
  final egne = <BioListe, List<String>>{};
  void legg(BioListe l, List<String> base, List<String> inn, String navn) {
    final k = _kanon(base, navn) ?? _kanon(egne[l] ?? const [], navn);
    if (k == null) (egne[l] ??= []).add(bioStor(navn));
    final v = k ?? bioStor(navn);
    if (!inn.contains(v)) inn.add(v);
  }

  for (final kode in c.kost) {
    final n = _navnFra(bioKostKode, kode);
    if (n != null && !kost.contains(n)) kost.add(n);
  }
  for (final w in c.annetKost) {
    legg(BioListe.kost, bioKostListe, kost, w);
  }
  for (final kode in c.allergener) {
    final n = _navnFra(bioAllKode, kode);
    if (n != null) all[n] = BioAll.allergi;
  }
  for (final kode in c.unngaar) {
    final n = _navnFra(bioAllKode, kode);
    if (n != null) all[n] ??= BioAll.unnga;
  }
  for (final w in c.annet) {
    final k = _kanon(bioAllListe, w) ?? _kanon(egne[BioListe.all] ?? const [], w);
    if (k == null) (egne[BioListe.all] ??= []).add(bioStor(w));
    all[k ?? bioStor(w)] = BioAll.allergi;
  }
  String tastNavn(({String value, String label}) t, List<String> base) => _kanon(base, t.value) ?? t.label;
  for (final t in c.liker) {
    legg(BioListe.liker, bioLikListe, liker, tastNavn(t, bioLikListe));
  }
  for (final t in c.ikke) {
    legg(BioListe.ikke, bioIkkeListe, ikke, tastNavn(t, bioIkkeListe));
  }
  final p = bioTolk(c.tekst);
  final ign = <String>[
    for (final x in p.kost)
      if (!kost.contains(x)) 'kost:$x',
    for (final x in p.liker)
      if (!liker.contains(x)) 'lik:$x',
    for (final x in p.ikke)
      if (!ikke.contains(x)) 'ikke:$x',
  ];
  return MinBio(
    kost: kost,
    all: all,
    liker: liker,
    ikke: ikke,
    tekst: c.tekst,
    ign: ign,
    ingen: c.ingenAllergier,
    egne: egne,
    streng: {for (final kode in c.streng) if (_navnFra(bioKostKode, kode) case final n?) n},
    kilde: c,
    ventende: ventende,
  );
}

/// What `PUT customer/me/bio` gets: the effective chips as codes. Own
/// allergen words go as «annet», own diet words as `other_preferences`; an
/// own word to avoid goes with the dislikes (it hides nothing).
Map<String, dynamic> minBioKropp(MinBio bio) {
  final E = bioEff(bio);
  final allergener = <String>[], unngaar = <String>[], annet = <String>[];
  final ikke = [...E.ikke];
  E.all.forEach((k, v) {
    final kode = bioAllKode[k];
    if (v == BioAll.allergi) {
      kode != null ? allergener.add(kode) : annet.add(k);
    } else if (v == BioAll.unnga) {
      if (kode != null) {
        unngaar.add(kode);
      } else if (!ikke.contains(k)) {
        ikke.add(k);
      }
    }
  });
  final kost = <String>[], annetKost = <String>[];
  for (final x in E.kost) {
    final kode = bioKostKode[x];
    kode != null ? kost.add(kode) : annetKost.add(x);
  }
  return {
    'allergens': allergener,
    'avoids': unngaar,
    'other': annet,
    'preferences': kost,
    'other_preferences': annetKost,
    'strict': [for (final x in E.kost) if (bio.streng.contains(x) && bioStrengbar.contains(x)) bioKostKode[x]!],
    'likes': E.liker,
    'dislikes': ikke,
    'text': bio.tekst.trim(),
    'no_allergies': bio.ingen && E.all.isEmpty,
  };
}

/// The bio holds special-category data (GDPR Art. 9): it needs the consent tick.
bool minBioSensitiv(MinBio bio) {
  final k = minBioKropp(bio);
  return [k['allergens'], k['avoids'], k['other'], k['preferences'], k['other_preferences']].any((l) => (l as List).isNotEmpty) ||
      (k['text'] as String).isNotEmpty ||
      k['no_allergies'] == true;
}

/// Saves the bio on the server. [samtykke]: the box ticked now. Returns how
/// many things Ægil knows and the saved bio, or the refusal's code. The
/// onboarding's waiting picks are settled by the save (tapped or left).
Future<({int? n, CusBio? bio, String? feil})> minBioLagreCus(CusApi api, MinBio bio, {required bool samtykke}) async {
  final r = await api.bioLagre(minBioKropp(bio), samtykke: samtykke, versjon: bio.kilde?.samtykkeVersjon ?? 'v1');
  if (r.bio == null) return (n: null, bio: null, feil: r.feil);
  await BioVentende.tom();
  return (n: bioEff(minBioFraCus(r.bio!)).tagger.length, bio: r.bio, feil: null);
}

/// The bio to open: the server's when it answers (`cus.bio` on), else from
/// Ægil's memory (the Bergen Step 6 path).
MinBio minBioVelg(CusBio? c, List<MemoryEntry> minne, AegilSettings? s) => c != null ? minBioFraCus(c, ventende: BioVentende.les()) : minBioFra(minne, s);

/// Ægil's onboarding picks for allergies and diets while Min bio is on: they
/// wait in Min bio as suggestions (consent first), on this phone.
abstract final class BioVentende {
  static const String _nokkel = 'cus_bio_ventende';

  static List<String> les() => prefGetString(_nokkel).split('|').where((s) => s.isNotEmpty).toList();

  static Future<void> legg(List<String> tagger) => prefSetString(_nokkel, {...les(), ...tagger}.join('|'));

  static Future<void> tom() => prefSetString(_nokkel, '');
}

/// Customer Step 6 copy (not in the design: needs sign-off, except the
/// design's «Ærend AI» lines). `cus_*` facade names as the plan's other copy.
abstract final class CusBioCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static bool get en => _en;
  static String _t(String no, String en) => _en ? en : no;

  static String get cus_bio_samtykke_hode => _t('6 · Samtykke', '6 · Consent');
  static String cus_bio_streng(String k) => _t('Strengt: $k', 'Strict: $k');
  static String cus_bio_streng_sub(String k, bool paa) => paa
      ? (bioBareMerket.contains(k) ? _t('Ægil viser bare det butikken har merket', 'Ægil only shows what the store has marked') : _t('Ægil viser bare det som passer', 'Ægil only shows what fits'))
      : _t('Ægil foretrekker det, men viser også resten', 'Ægil prefers it, but shows the rest too');
  static String cus_bio_streng_paa(String k) => _t('Strengt, notert. Det som ikke passer med ${bioAdj(k)}, viser jeg ikke.', 'Strict, noted. What is not ${bioAdj(k)}, I will not show.');
  static String cus_bio_streng_av(String k) => _t('Ok. Jeg foretrekker ${bioAdj(k)}, men viser deg resten også.', 'Ok. I prefer ${bioAdj(k)}, but show you the rest too.');
  static String get cus_bio_ansvar => _t(
    'Allergenene kommer fra butikkene og varekatalogen. Ærend kan ikke garantere at de stemmer. Har du en alvorlig allergi, sjekk med butikken før du bestiller.',
    'Allergens come from the stores and the product catalogue. Ærend cannot guarantee they are right. If you have a severe allergy, check with the store before you order.',
  );
  static String get cus_bio_samtykke => _t(
    'Ja, Ærend kan lagre allergiene, kostholdet og teksten min i Min bio. Ægil bruker dem bare til å velge og sortere matforslag til meg. Butikkene ser dem ikke. Jeg kan trekke samtykket når som helst ved å slette bioen.',
    'Yes, Ærend may store my allergies, my diet and my text in My bio. Ægil uses them only to pick and sort food suggestions for me. Stores do not see them. I can withdraw my consent at any time by deleting the bio.',
  );
  static String get cus_bio_samtykke_mangler => _t('Kryss av for samtykket nederst før du lagrer allergier, kosthold eller tekst.', 'Tick the consent at the bottom before you save allergies, diet or text.');
  static String get cus_bio_samtykke_ny => _t('Samtykketeksten er endret. Les den og kryss av igjen.', 'The consent text has changed. Read it and tick again.');
  static String cus_bio_samtykket(String dato) => _t('Du samtykket $dato. Slett bioen for å trekke samtykket.', 'You consented on $dato. Delete the bio to withdraw it.');
  static String cus_bio_kjenner(String dato) => _t('Ægil kjenner bioen din · sist oppdatert $dato', 'Ægil knows your bio · last updated $dato');
  static String get cus_bio_slett => _t('Slett bioen', 'Delete the bio');
  static String get cus_bio_slett_sporsmal => _t('Er du sikker?', 'Are you sure?');
  static String get cus_bio_slett_linje => _t('Allergiene, kostholdet, teksten og det du liker forsvinner fra Ægils minne med en gang.', 'Your allergies, diet, text and likes leave Ægil\'s memory at once.');
  static String get cus_bio_slett_ja => _t('Slett', 'Delete');
  static String get cus_bio_slett_nei => _t('Avbryt', 'Cancel');
  static String get cus_bio_slettet => _t('Bioen er slettet. Ægil har glemt den.', 'The bio is deleted. Ægil has forgotten it.');
  static String get cus_bio_ikke_slettet => _t('Fikk ikke slettet bioen. Prøv igjen.', 'Could not delete the bio. Try again.');
  // The design's Ærend AI lines (`bioAiLes`).
  static String get cus_bio_ai_leser => _t('Ærend AI leser', 'Ærend AI is reading');
  static String cus_bio_ai_fant(String ord) => _t('Ærend AI fant også: $ord.', 'Ærend AI also found: $ord.');
  static String get cus_bio_ai_stemmer => _t('Ærend AI har lest teksten. Alt stemmer med det Ægil fant.', 'Ærend AI has read the text. Everything matches what Ægil found.');
  static String cus_bio_ai_aeg(String ord) => _t('Ærend AI leste mellom linjene: $ord. ${BioCopy.trykkForAaHuske}', 'Ærend AI read between the lines: $ord. ${BioCopy.trykkForAaHuske}');
  // Ægil's chat cards.
  static String get cus_bio_skjult => _t('Skjult av bioen din', 'Hidden by your bio');
  static String cus_bio_skjult_sub(int n, String grunn) => [_t(n == 1 ? '1 vare' : '$n varer', n == 1 ? '1 item' : '$n items'), if (grunn.isNotEmpty) grunn].join(' · ');
  static String get cus_bio_vis_likevel => _t('Vis likevel', 'Show anyway');
  static String get cus_bio_ukjent => _t('Allergener ikke oppgitt', 'Allergens not stated');
  static String get cus_bio_gave => _t('Bioen din gjelder deg, ikke gaven', 'Your bio is about you, not the gift');

  static const List<String> _mnd = ['jan.', 'feb.', 'mars', 'apr.', 'mai', 'juni', 'juli', 'aug.', 'sep.', 'okt.', 'nov.', 'des.'];
  static String dato(DateTime d) => '${d.day}. ${_mnd[d.month - 1]} ${d.year}';
}

