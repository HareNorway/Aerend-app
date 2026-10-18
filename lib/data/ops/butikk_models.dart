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
    this.allergens = const [],
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

  /// The store's allergen text split on , / ; — empty when not listed.
  final List<String> allergens;

  static List<String> splitAllergens(String raw) => [
    for (final a in raw.split(RegExp(r'[,/;·\n]+')))
      if (a.trim().isNotEmpty) a.trim(),
  ];

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
      // `size_optoinal` 0 = a size must be chosen. A missing key means no
      // sizes (the old getter defaults to 0, which made every item "sized").
      hasSizes: p.sizeOptionalRaw == 0,
      hasColours: p.colorOptionalRaw == 0,
      rating: p.rateCount > 0
          ? (p.rateSum / p.rateCount).toStringAsFixed(1).replaceAll('.', ',')
          : null,
      allergens: splitAllergens(p.allergens),
    );
  }
}

/// A stock flag from the API: true / false, or null when it was not sent —
/// unknown, never assumed in stock.
bool? bergenStock(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v > 0;
  final t = '$v'.trim().toLowerCase();
  if (t == '1' || t == 'true' || t == 'yes') return true;
  if (t == '0' || t == 'false' || t == 'no') return false;
  return null;
}

/// `get-topping-option`: option groups, sizes and colours for one product,
/// plus the size × colour grid when the product follows a catalogue source.
class BergenProductOptions {
  const BergenProductOptions({
    this.groups = const [],
    this.sizes = const [],
    this.colours = const [],
    this.cells = const [],
  });

  final List<BergenOptionGroup> groups;
  final List<BergenVariant> sizes;
  final List<BergenVariant> colours;

  /// The size × colour grid (`variants`), empty for a hand-made product.
  final List<BergenCell> cells;

  /// The grid cell for a size in a colour, if the product has a grid.
  BergenCell? cell(String? size, String? colour) {
    final s = (size ?? '').toLowerCase(), c = (colour ?? '').toLowerCase();
    for (final x in cells) {
      if ((x.size ?? '').toLowerCase() == s && (x.colour ?? '').toLowerCase() == c) return x;
    }
    return null;
  }

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
            // A missing `stock` is unknown, not in stock.
            inStock: bergenStock(v['stock']),
            stockQty: (v['stock_qty'] as num?)?.toInt(),
            hex: BergenCell.hexOf(v['hex']),
          ),
    ];
    return BergenProductOptions(
      cells: BergenCell.listFrom(json['variants']),
      groups: [
        for (final g
            in (json['options_list'] is List
                ? json['options_list'] as List
                : const []))
          if (g is Map)
            BergenOptionGroup.fromJson(
              g,
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
    this.min = 0,
    this.max = 0,
    this.options = const [],
  });

  final String name;
  final bool single;
  final bool required;

  /// Fewest and most choices; `max` 0 = no upper limit.
  final int min;
  final int max;
  final List<BergenVariant> options;

  /// The legacy group: `selection_type` 1 = one choice; `optional_type` 0 =
  /// required (when sent; else one choice counts as required, as before);
  /// `minimum` / `maximum` bound a multi-choice group.
  factory BergenOptionGroup.fromJson(Map g, {required List<BergenVariant> options}) {
    final selection = (g['selection_type'] as num?)?.toInt();
    final optional = (g['optional_type'] as num?)?.toInt();
    final max = (g['maximum'] as num?)?.toInt() ?? (selection == 1 ? 1 : 0);
    final required = optional != null ? optional == 0 : selection == 1;
    final min = (g['minimum'] as num?)?.toInt() ?? (required ? 1 : 0);
    return BergenOptionGroup(
      name: '${g['name'] ?? g['category_name'] ?? ''}',
      single: selection == 1 || max == 1,
      required: required || min > 0,
      min: required && min < 1 ? 1 : min,
      max: max,
      options: options,
    );
  }

  /// Fewest choices before the item can go in the basket.
  int get needed => required ? (min < 1 ? 1 : min) : min;

  /// Too few chosen to add to the basket?
  bool missing(int chosen) => chosen < needed;

  /// May one more be chosen?
  bool canAdd(int chosen) => max <= 0 || chosen < max;
}

class BergenVariant {
  const BergenVariant({
    required this.id,
    required this.name,
    this.priceDelta = 0,
    bool? inStock = true,
    this.stockQty,
    this.hex,
  }) : stock = inStock;

  final int id;
  final String name;
  final double priceDelta;

  /// true / false, or null = unknown (the API did not say).
  final bool? stock;
  final int? stockQty;

  /// `#RRGGBB` for a colour, when known.
  final String? hex;

  /// Selectable: in stock, or unknown («Lager ikke bekreftet»).
  bool get inStock => stock != false;
  bool get stockUnknown => stock == null;
}

/// One cell of the size × colour grid (`variants`).
class BergenCell {
  const BergenCell({
    this.size,
    this.colour,
    this.hex,
    this.priceDeltaOre = 0,
    this.stockQty,
    this.inStock,
  });

  final String? size;
  final String? colour;
  final String? hex;
  final int priceDeltaOre;
  final int? stockQty;

  /// null = unknown.
  final bool? inStock;

  static String? hexOf(dynamic v) {
    final t = '${v ?? ''}'.trim();
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(t) ? t : null;
  }

  static List<BergenCell> listFrom(dynamic list) => [
    for (final v in (list is List ? list : const []))
      if (v is Map)
        BergenCell(
          size: v['size'] == null ? null : '${v['size']}',
          colour: v['colour'] == null ? null : '${v['colour']}',
          hex: hexOf(v['colour_hex']),
          priceDeltaOre: (v['price_delta_ore'] as num?)?.toInt() ?? 0,
          stockQty: (v['stock_qty'] as num?)?.toInt(),
          inStock: bergenStock(v['in_stock']),
        ),
  ];
}

/// A modifier group from `ops.customer.product` (øre deltas, may be negative).
class BergenModifierGroup {
  const BergenModifierGroup({
    required this.name,
    this.required = false,
    this.min = 0,
    this.max = 0,
    this.options = const [],
  });

  final String name;
  final bool required;
  final int min;
  final int max;
  final List<({String name, int deltaOre})> options;
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
    this.priceOre,
    this.wasPriceOre,
    this.cells = const [],
    this.colours = const [],
    this.stockMode,
    this.stockUpdatedAt,
    this.images = const [],
    this.modifiers = const [],
    this.allergenCodes = const [],
  });

  /// Catalogue sync (scraper plan Chunk 8): øre prices, the size × colour
  /// grid, colours with hex, where stock comes from and when it was read,
  /// our copies of the images, modifier groups and EU-14 allergen codes.
  final int? priceOre;
  final int? wasPriceOre;
  final List<BergenCell> cells;
  final List<({String label, String? hex})> colours;

  /// pos | web | manual | none.
  final String? stockMode;
  final DateTime? stockUpdatedAt;
  final List<String> images;
  final List<BergenModifierGroup> modifiers;
  final List<String> allergenCodes;

  double? get priceKr => priceOre == null ? null : priceOre! / 100;
  double? get wasPriceKr => wasPriceOre == null ? null : wasPriceOre! / 100;

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
      priceOre: (json['price_ore'] as num?)?.toInt(),
      wasPriceOre: (json['was_price_ore'] as num?)?.toInt(),
      cells: BergenCell.listFrom(json['variants']),
      colours: [
        for (final c in (json['colours'] is List ? json['colours'] as List : const []))
          if (c is Map && text(c['label']) != null) (label: text(c['label'])!, hex: BergenCell.hexOf(c['hex'])),
      ],
      stockMode: json['stock'] is Map ? text((json['stock'] as Map)['mode']) : null,
      stockUpdatedAt: json['stock'] is Map ? DateTime.tryParse('${(json['stock'] as Map)['updated_at'] ?? ''}') : null,
      images: [
        for (final u in (json['images'] is List ? json['images'] as List : const []))
          if (text(u) != null) text(u)!,
      ],
      modifiers: [
        for (final g in (json['modifiers'] is List ? json['modifiers'] as List : const []))
          if (g is Map)
            BergenModifierGroup(
              name: '${g['name'] ?? ''}',
              required: g['required'] == true,
              min: (g['min'] as num?)?.toInt() ?? 0,
              max: (g['max'] as num?)?.toInt() ?? 0,
              options: [
                for (final o in (g['options'] is List ? g['options'] as List : const []))
                  if (o is Map) (name: '${o['name'] ?? ''}', deltaOre: (o['delta_ore'] as num?)?.toInt() ?? 0),
              ],
            ),
      ],
      allergenCodes: [
        for (final a in (json['allergen_codes'] is List ? json['allergen_codes'] as List : const []))
          if (text(a) != null) text(a)!,
      ],
    );
  }
}

/// A read that can fail: the product sheet shows an error state with retry
/// instead of an empty sheet when the network or the server failed.
class ButikkResult<T> {
  const ButikkResult.ok(this.value) : failed = false;
  const ButikkResult.failed() : value = null, failed = true;

  final T? value;
  final bool failed;
}
