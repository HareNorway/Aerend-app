/// Search results for the Bergen Søk screen (AGIL-1 v2 Phase 3), mapped from
/// the app's existing `search-store` / `search-product` endpoints.
class SokButikk {
  const SokButikk({
    required this.id,
    required this.name,
    this.category,
    this.etaMinutes,
    this.rating,
    this.feeText,
    this.bannerUrl,
    this.open = true,
  });

  final int id;
  final String name;
  final String? category;
  final int? etaMinutes;
  final String? rating;
  final String? feeText;
  final String? bannerUrl;
  final bool open;
}

class SokProdukt {
  const SokProdukt({
    required this.id,
    required this.name,
    required this.storeId,
    required this.storeName,
    required this.price,
    this.imageUrl,
    this.wasPrice,
  });

  final int id;
  final String name;
  final int storeId;
  final String storeName;
  final double price;
  final String? imageUrl;
  final double? wasPrice;
}

class SokTreff {
  const SokTreff({this.butikker = const [], this.produkter = const []});

  final List<SokButikk> butikker;
  final List<SokProdukt> produkter;

  int get total => butikker.length + produkter.length;
  bool get isEmpty => total == 0;
}

/// One "Populært nå" row: the term and how many were ordered this week
/// (null when the backend only sent the term).
class SokTrend {
  const SokTrend(this.term, [this.count]);

  final String term;
  final int? count;
}
