import 'dart:async';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';

/// A store's logo and banner, for lists that only carry the store's id and
/// name (Ordrehistorikk, Bergen Step 10). The design's `l_torgboden … l_x`
/// flags are its fixed logo set; the app uses the real images, with the
/// tint (and initial or icon) as the fallback.
class ButikkBilder {
  const ButikkBilder({this.logo, this.banner});

  final String? logo;
  final String? banner;

  static const ButikkBilder ingen = ButikkBilder();

  /// The store page (tests swap it).
  static Future<BergenStoreInfo?> Function(int storeId) hent = (id) => OpsButikkApi().store(id);

  static final Map<int, Future<ButikkBilder>> _cache = {};

  /// One lookup per store per app run; a failed lookup is not cached.
  static Future<ButikkBilder> of(int storeId) {
    if (storeId <= 0) return Future.value(ingen);
    return _cache.putIfAbsent(storeId, () async {
      try {
        final info = await hent(storeId);
        if (info == null) throw StateError('no store');
        return ButikkBilder(logo: _url(info.logoUrl), banner: _url(info.bannerUrl));
      } catch (_) {
        unawaited(Future<void>.microtask(() => _cache.remove(storeId)));
        return ingen;
      }
    });
  }

  /// Several stores at once, by id.
  static Future<Map<int, ButikkBilder>> alle(Iterable<int> storeIds) async {
    final ids = storeIds.toSet().toList();
    final ut = await Future.wait([for (final id in ids) of(id)]);
    return {for (var i = 0; i < ids.length; i++) ids[i]: ut[i]};
  }

  static String? _url(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

  static void reset() {
    _cache.clear();
    hent = (id) => OpsButikkApi().store(id);
  }
}
