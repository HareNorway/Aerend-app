import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../networking/ops/ops_customer_api.dart';

/// One row of `ops.customer.favourite_products` (Bergen Step 9, D4).
class FavouriteProduct {
  const FavouriteProduct({
    required this.productId,
    required this.name,
    required this.priceOre,
    required this.storeId,
    required this.storeName,
    this.image,
    this.storeLogo,
    this.etaMinutes,
    this.open = false,
  });

  final int productId;
  final String name;
  final int priceOre;
  final int storeId;
  final String storeName;
  final String? image;
  final String? storeLogo;
  final int? etaMinutes;
  final bool open;

  double get priceKr => priceOre / 100;

  factory FavouriteProduct.fromJson(Map<String, dynamic> json) => FavouriteProduct(
    productId: (json['product_id'] as num?)?.toInt() ?? 0,
    name: (json['name'] as String?) ?? '',
    priceOre: (json['price_ore'] as num?)?.toInt() ?? 0,
    storeId: (json['store_id'] as num?)?.toInt() ?? 0,
    storeName: (json['store_name'] as String?) ?? '',
    image: json['image'] as String?,
    storeLogo: json['store_logo'] as String?,
    etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
    open: json['open'] == true,
  );
}

/// The customer's favourite products, shared by the product sheet's heart
/// and Favoritter › Produkter. Like [FavouriteStores]: one list in memory,
/// optimistic writes that fall back if the server says no.
class FavouriteProducts {
  FavouriteProducts._();

  static final FavouriteProducts instance = FavouriteProducts._();

  /// Replaced in tests.
  OpsCustomerApi api = OpsCustomerApi();

  /// The hearted product ids; widgets listen to this.
  final ValueNotifier<Set<int>> ids = ValueNotifier<Set<int>>(const <int>{});

  List<FavouriteProduct> _products = const [];
  bool _loaded = false;
  Future<void>? _loading;

  List<FavouriteProduct> get products => _products;
  bool get loaded => _loaded;
  bool isFavourite(int productId) => ids.value.contains(productId);

  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= refresh();
  }

  Future<void> refresh() async {
    try {
      final json = await api.favouriteProducts();
      if (json == null) return;
      _products = (json['products'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => FavouriteProduct.fromJson(e.cast<String, dynamic>()))
          .toList();
      ids.value = (json['product_ids'] as List? ?? const []).whereType<num>().map((e) => e.toInt()).toSet();
      _loaded = true;
    } finally {
      _loading = null;
    }
  }

  /// Hearts ([favourite] true) or un-hearts one product. True when it landed.
  Future<bool> set(int productId, bool favourite) async {
    final before = ids.value;
    if (before.contains(productId) == favourite) return true;
    ids.value = favourite ? {...before, productId} : ({...before}..remove(productId));
    final json = await api.setFavouriteProduct(productId, favourite);
    if (json == null) {
      ids.value = before;
      return false;
    }
    if (favourite) {
      unawaited(refresh());
    } else {
      _products = _products.where((p) => p.productId != productId).toList();
    }
    return true;
  }

  Future<bool> toggle(int productId) => set(productId, !isFavourite(productId));

  @visibleForTesting
  void reset({OpsCustomerApi? api}) {
    this.api = api ?? OpsCustomerApi();
    ids.value = const <int>{};
    _products = const [];
    _loaded = false;
    _loading = null;
  }
}
