import '../../screens/deliveryService/storeDetail/store_detail_dl.dart';

/// Models for the Bergen store and category screens (AGIL-1 v2 Phase 4),
/// mapped from the app's existing store-detail response so a screen never
/// reads the legacy POJO's `dynamic` fields directly.

enum BergenStoreKind { restaurant, fashion, gift, other }

class BergenStoreInfo {
  const BergenStoreInfo({
    required this.id,
    required this.name,
    required this.kind,
    this.categoryName,
    this.bannerUrl,
    this.logoUrl,
    this.open = true,
    this.openTime,
    this.closeTime,
    this.rating,
    this.deliveryMinutes,
    this.deliveryChargeKr,
    this.minOrderKr,
    this.offerMinAmountKr,
    this.offerPercentage,
    this.offer,
    this.address,
    this.distanceKm,
    this.description,
    this.contactNumber,
    this.pickupPossible = false,
    this.isFavourite = false,
    this.hours = const [],
    this.menu = const [],
  });

  final int id;
  final String name;
  final BergenStoreKind kind;
  final String? categoryName;
  final String? bannerUrl;
  final String? logoUrl;
  final bool open;
  final String? openTime;
  final String? closeTime;
  final String? rating;
  final int? deliveryMinutes;
  final double? deliveryChargeKr;
  final double? minOrderKr;
  final double? offerMinAmountKr;
  final double? offerPercentage;
  final String? offer;
  final String? address;
  final double? distanceKm;
  final String? description;
  final String? contactNumber;
  final bool pickupPossible;
  final bool isFavourite;
  final List<BergenStoreHours> hours;
  final List<BergenMenuCategory> menu;

  bool get isFashionOrGift =>
      kind == BergenStoreKind.fashion || kind == BergenStoreKind.gift;

  List<BergenMenuItem> get allItems => [for (final c in menu) ...c.items];

  /// The kitchen's specials: discounted items, best discount first.
  List<BergenMenuItem> get specials {
    final list =
        allItems
            .where((i) => i.wasPrice != null && i.wasPrice! > i.price)
            .toList()
          ..sort(
            (a, b) => (b.wasPrice! - b.price).compareTo(a.wasPrice! - a.price),
          );
    return list.take(3).toList();
  }

  static BergenStoreKind kindOf(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('mote') ||
        c.contains('fashion') ||
        c.contains('klær') ||
        c.contains('klær')) {
      return BergenStoreKind.fashion;
    }
    if (c.contains('gave') || c.contains('gift')) return BergenStoreKind.gift;
    if (c.contains('restaurant') ||
        c.contains('mat') ||
        c.contains('food') ||
        c.contains('fisk') ||
        c.contains('bakeri')) {
      return BergenStoreKind.restaurant;
    }
    return BergenStoreKind.other;
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  factory BergenStoreInfo.fromPojo(StoreDetailsPojo p, {String? categoryHint}) {
    final category = p.storeCatName.isNotEmpty ? p.storeCatName : categoryHint;
    return BergenStoreInfo(
      id: p.storeId,
      name: p.storeName,
      kind: kindOf(category),
      categoryName: category,
      bannerUrl: p.storeBanner.isEmpty ? null : p.storeBanner,
      logoUrl: p.storeLogo.isEmpty ? null : p.storeLogo,
      open: p.storeStatus == 1,
      openTime: p.openTime.isEmpty ? null : p.openTime,
      closeTime: p.closeTime.isEmpty ? null : p.closeTime,
      rating: _d(p.averageRating) == null || _d(p.averageRating) == 0
          ? null
          : _d(p.averageRating)!.toStringAsFixed(1).replaceAll('.', ','),
      deliveryMinutes: p.deliveryTime > 0 ? p.deliveryTime : null,
      deliveryChargeKr: _d(p.deliveryCharges),
      minOrderKr: _d(p.orderMinAmount),
      offerMinAmountKr: _d(p.offerMinAmount),
      offerPercentage: _d(p.offerPercentage),
      offer: p.offer.isEmpty ? null : p.offer,
      address: p.address.isEmpty ? null : p.address,
      distanceKm: _d(p.userToStoreDist),
      description: p.description.isEmpty ? null : p.description,
      contactNumber: p.storeContactNumber.isEmpty ? null : p.storeContactNumber,
      pickupPossible: p.takenAwayType == 2 || p.takenAwayType == 3,
      isFavourite: p.isFavourite == 1,
      hours: [
        for (final h in p.storeOpenCloseTime)
          BergenStoreHours(
            day: h.displayDay,
            opens: h.storeOpenTime,
            closes: h.storeCloseTime,
          ),
      ],
      menu: [
        for (final c in p.categoryWiseProductList)
          BergenMenuCategory(
            id: c.categoryId,
            name: c.categoryName,
            iconUrl: c.categoryIcon.isEmpty ? null : c.categoryIcon,
            items: [
              for (final sub in c.subCategoryList)
                for (final item in sub.productList)
                  BergenMenuItem.fromPojo(
                    item,
                    storeId: p.storeId,
                    storeName: p.storeName,
                    categoryName: c.categoryName,
                  ),
            ],
          ),
      ],
    );
  }
}

class BergenStoreHours {
  const BergenStoreHours({
    required this.day,
    required this.opens,
    required this.closes,
  });

  final String day;
  final String opens;
  final String closes;
}

class BergenMenuCategory {
  const BergenMenuCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.items = const [],
  });

  final int id;
  final String name;
  final String? iconUrl;
  final List<BergenMenuItem> items;
}

class BergenMenuItem {
  const BergenMenuItem({
    required this.id,
    required this.name,
    required this.storeId,
    required this.storeName,
    required this.price,
    this.wasPrice,
    this.description,
    this.imageUrl,
    this.categoryName,
    this.hasSizes = false,
    this.hasColours = false,
    this.rating,
  });

  final int id;
  final String name;
  final int storeId;
  final String storeName;
  final double price;
  final double? wasPrice;
  final String? description;
  final String? imageUrl;
  final String? categoryName;
  final bool hasSizes;
  final bool hasColours;
  final String? rating;

  double get savedKr =>
      wasPrice == null ? 0 : (wasPrice! - price).clamp(0, double.infinity);

  factory BergenMenuItem.fromPojo(
    ProductListItem p, {
    required int storeId,
    required String storeName,
    String? categoryName,
  }) {
    final amount = BergenStoreInfo._d(p.productAmount) ?? 0;
    final original = BergenStoreInfo._d(p.originalAmount);
    final discount = BergenStoreInfo._d(p.discountAmount);
    final price = discount != null && discount > 0 && discount < amount
        ? discount
        : amount;
    final was = discount != null && discount > 0 && discount < amount
        ? amount
        : (original != null && original > amount ? original : null);
    return BergenMenuItem(
      id: p.productId,
      name: p.productName,
      storeId: storeId,
      storeName: storeName,
      price: price,
      wasPrice: was,
      description: p.description.isEmpty ? null : p.description,
      imageUrl: p.hasProductImage ? p.productImage : null,
      categoryName: categoryName,
      hasSizes: p.sizeOptional == 0,
      hasColours: p.colorOptional == 0,
      rating: p.rateCount > 0
          ? (p.rateSum / p.rateCount).toStringAsFixed(1).replaceAll('.', ',')
          : null,
    );
  }
}

/// `get-topping-option`: option groups, sizes and colours for one product.
class BergenProductOptions {
  const BergenProductOptions({
    this.groups = const [],
    this.sizes = const [],
    this.colours = const [],
  });

  final List<BergenOptionGroup> groups;
  final List<BergenVariant> sizes;
  final List<BergenVariant> colours;

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

  factory BergenProductOptions.fromJson(Map<String, dynamic> json) {
    List<BergenVariant> variants(dynamic list) => [
      for (final v in (list is List ? list : const []))
        if (v is Map)
          BergenVariant(
            id: (v['id'] as num?)?.toInt() ?? 0,
            name: '${v['name'] ?? ''}',
            priceDelta: _d(v['amount'] ?? v['price'] ?? 0),
            inStock:
                v['stock'] == null || v['stock'] == 1 || v['stock'] == true,
          ),
    ];
    return BergenProductOptions(
      groups: [
        for (final g
            in (json['options_list'] is List
                ? json['options_list'] as List
                : const []))
          if (g is Map)
            BergenOptionGroup(
              name: '${g['name'] ?? g['category_name'] ?? ''}',
              single: (g['selection_type'] as num?)?.toInt() == 1,
              required: (g['selection_type'] as num?)?.toInt() == 1,
              options: [
                for (final o
                    in (g['options'] is List ? g['options'] as List : const []))
                  if (o is Map)
                    BergenVariant(
                      id: (o['id'] as num?)?.toInt() ?? 0,
                      name: '${o['name'] ?? ''}',
                      priceDelta: _d(o['amount'] ?? 0),
                    ),
              ],
            ),
      ],
      sizes: variants(json['size_list']),
      colours: variants(json['color_list']),
    );
  }
}

class BergenOptionGroup {
  const BergenOptionGroup({
    required this.name,
    this.single = false,
    this.required = false,
    this.options = const [],
  });

  final String name;
  final bool single;
  final bool required;
  final List<BergenVariant> options;
}

class BergenVariant {
  const BergenVariant({
    required this.id,
    required this.name,
    this.priceDelta = 0,
    this.inStock = true,
  });

  final int id;
  final String name;
  final double priceDelta;
  final bool inStock;
}

/// `ops.customer.product` — what the product sheet shows beyond the menu
/// row: description, allergens, prep time, «Mest bestilt i kveld».
class BergenProductDetail {
  const BergenProductDetail({
    this.description,
    this.imageUrl,
    this.allergens = const [],
    this.vegan = false,
    this.halal = false,
    this.hasSizes = false,
    this.readyMinutes,
    this.mostOrdered = false,
    this.pointsPer10Kr,
  });

  final String? description;
  final String? imageUrl;
  /// `points.kjop_per_10kr`: "+N poeng" = whole 10 kr × this (KjopRule).
  final int? pointsPer10Kr;
  final List<String> allergens;
  final bool vegan;
  final bool halal;
  final bool hasSizes;
  final int? readyMinutes;
  final bool mostOrdered;

  factory BergenProductDetail.fromJson(Map<String, dynamic> json) {
    String? text(dynamic v) {
      final t = '${v ?? ''}'.trim();
      return t.isEmpty ? null : t;
    }

    final allergens = json['allergens'];
    return BergenProductDetail(
      description: text(json['description']),
      imageUrl: text(json['image']),
      allergens: allergens is List
          ? [for (final a in allergens) if ('$a'.trim().isNotEmpty) '$a'.trim()]
          : const [],
      vegan: json['vegan'] == true,
      halal: json['halal'] == true,
      hasSizes: json['has_sizes'] == true,
      readyMinutes: (json['ready_minutes'] as num?)?.toInt(),
      mostOrdered: json['most_ordered'] == true,
      pointsPer10Kr: (json['points_per_10kr'] as num?)?.toInt(),
    );
  }
}
