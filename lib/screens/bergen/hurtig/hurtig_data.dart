import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/utils.dart';
import 'hurtig_copy.dart';

// ── Hurtigbestilling · data (prototype `HB_BUT` / `HB_MENY` / `HB_HIST0` /
// `hbMinne`, L14792–14835) ─────────────────────────────────────────────────
//
// The prototype keeps a hand-written menu, store table and order history. The
// app reads the same shapes from the customer's real data: the delivered
// orders (`ops.customer.orders`), what Ægil has learned (`agent/me/memory`),
// the delivery address and the menus of the stores the customer has ordered
// from (so «pad thai for to» can be matched to a real product).

/// A product Ægil can put in the draft (`HB_MENY` row).
class HbVare {
  const HbVare({
    required this.id,
    required this.navn,
    required this.butikkId,
    required this.butikk,
    required this.pris,
    required this.ord,
    this.hoved = false,
    this.skalldyr = false,
  });

  final int id;
  final String navn;
  final int butikkId;
  final String butikk;
  final double pris;

  /// Words the customer may type for it, lower case; the full name first.
  final List<String> ord;

  /// A main dish (scaled by «for N» / the household).
  final bool hoved;
  final bool skalldyr;
}

/// A store the customer has ordered from (`HB_BUT` row).
class HbButikk {
  const HbButikk({
    required this.id,
    required this.navn,
    required this.ini,
    required this.bg,
    this.fg = Colors.white,
    this.min = 30,
    this.aapen = true,
    this.aapner,
    this.frakt = 39,
    this.gratisOver = 300,
  });

  final int id;
  final String navn;
  final String ini;
  final Color bg;
  final Color fg;

  /// Minutes until it is at the door.
  final int min;
  final bool aapen;

  /// When it opens again («åpner kl. 10:00»), when known.
  final String? aapner;

  /// Delivery fee and the free-delivery threshold.
  final double frakt;
  final double gratisOver;

  /// The prototype's «stengt» text (null while open).
  String? get stengt => aapen ? null : (aapner == null ? HurtigCopy.aapnerSenere : HurtigCopy.aapnerKl(aapner!));

  /// The prototype's store palette, by id.
  static const List<Color> _palett = [
    Color(0xFF2A6272),
    Color(0xFF8A5A1E),
    Color(0xFFB0472C),
    Color(0xFF1B4A57),
    Color(0xFF7A3B2A),
    Color(0xFF5A4632),
    Color(0xFFD6411B),
  ];

  static Color farge(int id) => _palett[id.abs() % _palett.length];

  /// «Sky Bangkok» → «SB», «Holy Cow» → «HC», «Reen» → «RE».
  static String initialer(String navn) {
    final words = navn.split(RegExp(r'[\s&/]+')).where((w) => w.isNotEmpty && RegExp(r'[A-Za-zÆØÅæøå0-9]').hasMatch(w)).toList();
    if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
    return navn.replaceAll(RegExp(r'[^A-Za-zÆØÅæøå0-9]'), '').toUpperCase().padRight(2).substring(0, 2).trim();
  }

  factory HbButikk.ukjent(int id, String navn) => HbButikk(id: id, navn: navn, ini: initialer(navn), bg: farge(id));
}

/// One draft / history line.
class HbLinje {
  const HbLinje(this.id, this.ant);
  final int id;
  final int ant;
  HbLinje med(int n) => HbLinje(id, n);
}

/// A delivered order (`HB_HIST0` row).
class HbOrdre {
  const HbOrdre({
    required this.id,
    required this.kode,
    required this.butikkId,
    required this.butikk,
    required this.naar,
    required this.sum,
    required this.linjer,
  });

  final int id;
  final String kode;
  final int butikkId;
  final String butikk;
  final DateTime naar;
  final double sum;

  /// (product id, quantity, name, line total) as the order had them.
  final List<HbOrdreLinje> linjer;
}

class HbOrdreLinje {
  const HbOrdreLinje({required this.id, required this.ant, required this.navn, required this.pris});
  final int id;
  final int ant;
  final String navn;

  /// The line total («298 kr» for 2× 149).
  final double pris;
}

/// What Ægil has learned (`hbMinne`).
class HbMinne {
  const HbMinne({
    this.liker = const [],
    this.butikker = const [],
    this.husstand = 2,
    this.unngaaSkalldyr = false,
    this.middag = const [],
    this.middagKl = '17',
  });

  final List<String> liker;
  final List<String> butikker;
  final int husstand;
  final bool unngaaSkalldyr;

  /// Dinner days, lower case («tirsdag»).
  final List<String> middag;
  final String middagKl;
}

/// The draft (`hbUtkast`).
class HbUtkast {
  const HbUtkast({required this.butikkId, required this.butikk, required this.linjer, this.tid = ''});
  final int butikkId;
  final String butikk;
  final List<HbLinje> linjer;

  /// «Snarest» or «Kl. 18:00» (empty: Snarest).
  final String tid;

  HbUtkast kopi({List<HbLinje>? linjer, String? tid}) => HbUtkast(butikkId: butikkId, butikk: butikk, linjer: linjer ?? this.linjer, tid: tid ?? this.tid);
  bool har(int id) => linjer.any((l) => l.id == id);
}

/// Everything the screen reads.
class HurtigData {
  const HurtigData({
    required this.hist,
    required this.meny,
    required this.butikker,
    required this.minne,
    required this.adresse,
    required this.adresseId,
    required this.navn,
  });

  /// Delivered orders, newest first.
  final List<HbOrdre> hist;
  final Map<int, HbVare> meny;
  final Map<int, HbButikk> butikker;
  final HbMinne minne;
  final String adresse;
  final int adresseId;
  final String navn;

  static const HurtigData tom = HurtigData(hist: [], meny: {}, butikker: {}, minne: HbMinne(), adresse: '', adresseId: 0, navn: '');

  HbVare? vare(int id) => meny[id];
  HbButikk butikk(int id, [String? navn]) => butikker[id] ?? HbButikk.ukjent(id, navn ?? '');
}

/// Reads the pieces and keeps the last result for the session, so Hjem's
/// entry line and the screen share one load.
abstract final class HurtigKilde {
  static final ValueNotifier<HurtigData?> cache = ValueNotifier<HurtigData?>(null);
  static Future<HurtigData>? _inflight;

  /// The data sources (tests swap them).
  static OpsCustomerApi Function() customer = () => OpsCustomerApi();
  static OpsKasseApi Function() kasse = () => OpsKasseApi();
  static OpsButikkApi Function() butikk = () => OpsButikkApi();
  static Future<List<MemoryEntry>> Function() memory = () => AegilRepo().fetchMemory();

  @visibleForTesting
  static void reset() {
    cache.value = null;
    _inflight = null;
    customer = () => OpsCustomerApi();
    kasse = () => OpsKasseApi();
    butikk = () => OpsButikkApi();
    memory = () => AegilRepo().fetchMemory();
  }

  static Future<HurtigData> load({bool refresh = false}) {
    if (!refresh && cache.value != null) return Future.value(cache.value);
    return _inflight ??= _load().then((d) {
      cache.value = d;
      _inflight = null;
      return d;
    }).catchError((Object _) {
      _inflight = null;
      return cache.value ?? HurtigData.tom;
    });
  }

  static Future<T> _guard<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }

  static Future<HurtigData> _load() async {
    final c = customer();
    final k = kasse();
    final results = await Future.wait<Object?>([
      _guard(() => c.orders(limit: 50), const <Map<String, dynamic>>[]),
      _guard(memory, const <MemoryEntry>[]),
      _guard(k.addresses, const <dynamic>[]),
    ]);
    final rows = results[0] as List<Map<String, dynamic>>;
    final mem = results[1] as List<MemoryEntry>;
    final adresser = results[2] as List<dynamic>;

    final hist = <HbOrdre>[];
    for (final o in rows) {
      if ('${o['state']}' != 'delivered') continue;
      final store = o['store'] is Map ? o['store'] as Map : const {};
      final items = o['items'] is List ? (o['items'] as List).whereType<Map>() : const <Map>[];
      final linjer = <HbOrdreLinje>[];
      for (final i in items) {
        final id = (i['product_id'] as num?)?.toInt() ?? 0;
        final ant = ((i['qty'] ?? i['quantity'] ?? i['num_of_items'] ?? 1) as num).toInt();
        final enhet = ((i['unit_price'] ?? i['price_for_one'] ?? i['price'] ?? 0) as num).toDouble();
        linjer.add(HbOrdreLinje(id: id, ant: ant, navn: '${i['name'] ?? i['product_name'] ?? ''}', pris: enhet * ant));
      }
      if (linjer.isEmpty) continue;
      final naar = DateTime.tryParse('${o['ordered_at'] ?? ''}')?.toLocal() ?? DateTime.now();
      hist.add(HbOrdre(
        id: (o['order_id'] is num ? o['order_id'] as num : num.tryParse('${o['order_id']}') ?? 0).toInt(),
        kode: '${o['code'] ?? ''}'.isEmpty ? 'Æ-${o['order_id']}' : '${o['code']}',
        butikkId: (store['id'] as num?)?.toInt() ?? 0,
        butikk: '${store['name'] ?? ''}',
        naar: naar,
        sum: linjer.fold<double>(0, (a, l) => a + l.pris),
        linjer: linjer,
      ));
    }
    hist.sort((a, b) => b.naar.compareTo(a.naar));

    // The menus of the stores in the history (newest stores first, six at
    // most): the matcher and the «LEGG TIL?» chips need the whole menu.
    final storeIds = <int>[];
    for (final o in hist) {
      if (o.butikkId > 0 && !storeIds.contains(o.butikkId)) storeIds.add(o.butikkId);
    }
    final b = butikk();
    final infos = await Future.wait([for (final id in storeIds.take(6)) _guard(() => b.store(id), null)]);

    final meny = <int, HbVare>{};
    final butikker = <int, HbButikk>{};
    // Which lines were the main of their order (the priciest line).
    final hovedIds = <int>{};
    for (final o in hist) {
      HbOrdreLinje? top;
      for (final l in o.linjer) {
        if (top == null || l.pris / l.ant > top.pris / top.ant) top = l;
      }
      if (top != null) hovedIds.add(top.id);
    }
    for (var i = 0; i < storeIds.take(6).length; i++) {
      final id = storeIds[i];
      final info = infos[i];
      final navn = info?.name ?? hist.firstWhere((o) => o.butikkId == id).butikk;
      final frakt = info?.deliveryChargeKr ?? 0;
      final terskel = info?.offerMinAmountKr ?? 0;
      butikker[id] = HbButikk(
        id: id,
        navn: navn,
        ini: HbButikk.initialer(navn),
        bg: HbButikk.farge(id),
        min: info?.deliveryMinutes ?? 30,
        aapen: info?.open ?? true,
        aapner: info?.openTime,
        frakt: frakt > 0 ? frakt : 39,
        gratisOver: terskel > 0 ? terskel : 300,
      );
      if (info != null) {
        for (final item in info.allItems) {
          meny[item.id] = _vare(item, id, navn, hoved: hovedIds.contains(item.id) || item.price >= 100);
        }
      }
    }
    // Lines whose product is no longer on the menu still count (history).
    for (final o in hist) {
      for (final l in o.linjer) {
        meny.putIfAbsent(
          l.id,
          () => HbVare(id: l.id, navn: l.navn, butikkId: o.butikkId, butikk: o.butikk, pris: l.pris / l.ant, ord: _ord(l.navn), hoved: hovedIds.contains(l.id), skalldyr: _erSkalldyr(l.navn, const [])),
        );
      }
    }
    _beholdUnikeOrd(meny);

    // Memory → the prototype's `minne` shape.
    final liker = <String>[], stores = <String>[], middag = <String>[];
    var hus = 2;
    var skalldyr = false;
    var kl = '17';
    for (final m in mem) {
      final label = (m.label ?? m.value).trim();
      switch (m.kind) {
        case 'like':
        case 'likes':
        case 'product':
          liker.add(label);
        case 'store':
        case 'stores':
          stores.add(label);
        case 'household':
          hus = int.tryParse(RegExp(r'\d+').firstMatch(m.value)?.group(0) ?? '') ?? hus;
        case 'allergen':
        case 'diet':
        case 'exclusion_product':
          if (RegExp(r'skalldyr|shellfish|reke|scampi', caseSensitive: false).hasMatch('${m.value} $label')) skalldyr = true;
        case 'dinner':
          middag.add(m.value.toLowerCase());
        case 'rhythm':
          kl = RegExp(r'\d{1,2}(?::\d{2})?').firstMatch(m.value)?.group(0) ?? kl;
      }
    }
    if (stores.isEmpty) {
      // Nothing stated: the shops the customer orders from most.
      final c = <String, int>{};
      for (final o in hist) {
        c[o.butikk] = (c[o.butikk] ?? 0) + 1;
      }
      final sorted = c.keys.toList()..sort((a, b) => c[b]!.compareTo(c[a]!));
      stores.addAll(sorted.take(3));
    }
    if (middag.isEmpty) {
      final c = <int, int>{};
      for (final o in hist) {
        c[o.naar.weekday] = (c[o.naar.weekday] ?? 0) + 1;
      }
      final sorted = c.keys.toList()..sort((a, b) => c[b]!.compareTo(c[a]!) != 0 ? c[b]!.compareTo(c[a]!) : a.compareTo(b));
      middag.addAll(sorted.take(2).map(HurtigCopy.dag));
      middag.sort((a, b) => HurtigCopy.dagerNo.indexOf(a).compareTo(HurtigCopy.dagerNo.indexOf(b)));
    }

    // The delivery address: the one the checkout uses, else the first.
    String adresse = '';
    var adresseId = 0;
    final savedId = prefGetInt(prefNewDeliveryAddressId);
    dynamic valgt;
    for (final a in adresser) {
      if (a.addressId == savedId) valgt = a;
    }
    valgt ??= adresser.isEmpty ? null : adresser.first;
    if (valgt != null) {
      adresseId = valgt.addressId as int;
      adresse = '${valgt.address}'.split(',').first.trim();
    }

    final navn = prefGetString(prefUserName).trim().split(RegExp(r'\s+')).first;

    return HurtigData(
      hist: hist,
      meny: meny,
      butikker: butikker,
      minne: HbMinne(liker: liker, butikker: stores, husstand: hus, unngaaSkalldyr: skalldyr, middag: middag, middagKl: kl),
      adresse: adresse,
      adresseId: adresseId,
      navn: navn,
    );
  }

  static HbVare _vare(BergenMenuItem item, int storeId, String storeName, {required bool hoved}) => HbVare(
    id: item.id,
    navn: item.name,
    butikkId: storeId,
    butikk: storeName,
    pris: item.price,
    ord: _ord(item.name),
    hoved: hoved,
    skalldyr: _erSkalldyr(item.name, item.allergens),
  );

  static bool _erSkalldyr(String navn, List<String> allergens) {
    final re = RegExp(r'skalldyr|reke|scampi|krabbe|hummer|kreps|shellfish|shrimp|prawn|crab', caseSensitive: false);
    return re.hasMatch(navn) || allergens.any(re.hasMatch);
  }

  static const Set<String> _stopp = {'med', 'uten', 'for', 'och', 'and', 'the', 'stk', 'liter', 'dispenser', 'meny', 'menu', 'barnemeny', 'deal', 'small', 'large', 'medium', 'pers'};

  /// The full name, then its words of four letters or more.
  static List<String> _ord(String navn) {
    final full = navn.toLowerCase().replaceAll(RegExp(r'[^a-zæøå0-9 ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final out = <String>[if (full.isNotEmpty) full];
    for (final w in full.split(' ')) {
      if (w.length >= 4 && !_stopp.contains(w) && !out.contains(w)) out.add(w);
    }
    return out;
  }

  /// A single word that belongs to several products is ambiguous («pad»
  /// in «Pad Thai» and «Pad Mi»); only the full names keep it.
  static void _beholdUnikeOrd(Map<int, HbVare> meny) {
    final count = <String, int>{};
    for (final v in meny.values) {
      for (final o in v.ord.skip(1)) {
        count[o] = (count[o] ?? 0) + 1;
      }
    }
    for (final id in meny.keys.toList()) {
      final v = meny[id]!;
      final ord = [v.ord.first, for (final o in v.ord.skip(1)) if ((count[o] ?? 0) == 1) o];
      if (ord.length != v.ord.length) {
        meny[id] = HbVare(id: v.id, navn: v.navn, butikkId: v.butikkId, butikk: v.butikk, pris: v.pris, ord: ord, hoved: v.hoved, skalldyr: v.skalldyr);
      }
    }
  }
}
