import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../networking/ops/ops_customer_api.dart';

/// One row of `ops.customer.favourites`.
class FavouriteStore {
  const FavouriteStore({
    required this.storeId,
    required this.name,
    this.address,
    this.rating,
    this.etaMinutes,
    this.open = false,
  });

  final int storeId;
  final String name;
  final String? address;
  final double? rating;
  final int? etaMinutes;
  final bool open;

  factory FavouriteStore.fromJson(Map<String, dynamic> json) => FavouriteStore(
    storeId: (json['store_id'] as num?)?.toInt() ?? 0,
    name: (json['name'] as String?) ?? '',
    address: json['address'] as String?,
    rating: (json['rating'] as num?)?.toDouble(),
    etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
    open: json['open'] == true,
  );
}

/// The customer's favourite stores, shared by every Bergen heart (Hjem's
/// store rail, the store page, Fjordfiske "Lagre", Meg → Favoritter).
///
/// One list in memory so a heart tapped on Hjem is already filled on the
/// store page. Writes are optimistic: the heart fills at once and falls back
/// if `ops.customer.favourites.set` does not land.
class FavouriteStores {
  FavouriteStores._();

  static final FavouriteStores instance = FavouriteStores._();

  /// Replaced in tests.
  OpsCustomerApi api = OpsCustomerApi();

  /// The hearted store ids; widgets listen to this.
  final ValueNotifier<Set<int>> ids = ValueNotifier<Set<int>>(const <int>{});

  List<FavouriteStore> _stores = const [];
  bool _loaded = false;
  Future<void>? _loading;

  List<FavouriteStore> get stores => _stores;
  bool get loaded => _loaded;
  bool isFavourite(int storeId) => ids.value.contains(storeId);

  /// Loads once per session; later callers share the same request.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= refresh();
  }

  Future<void> refresh() async {
    try {
      final json = await api.favourites();
      if (json == null) return;
      final list = (json['stores'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => FavouriteStore.fromJson(e.cast<String, dynamic>()))
          .toList();
      final hearted = (json['store_ids'] as List? ?? const [])
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet();
      _stores = list;
      ids.value = hearted;
      _loaded = true;
    } finally {
      _loading = null;
    }
  }

  /// Hearts ([favourite] true) or un-hearts one store. True when it landed.
  Future<bool> set(int storeId, bool favourite) async {
    final before = ids.value;
    if (before.contains(storeId) == favourite) return true;
    ids.value = favourite ? {...before, storeId} : ({...before}..remove(storeId));
    final json = await api.setFavourite(storeId, favourite);
    if (json == null) {
      ids.value = before;
      return false;
    }
    if (favourite) {
      unawaited(refresh());
    } else {
      _stores = _stores.where((s) => s.storeId != storeId).toList();
    }
    return true;
  }

  Future<bool> toggle(int storeId) => set(storeId, !isFavourite(storeId));

  @visibleForTesting
  void reset({OpsCustomerApi? api}) {
    this.api = api ?? OpsCustomerApi();
    ids.value = const <int>{};
    _stores = const [];
    _loaded = false;
    _loading = null;
  }
}