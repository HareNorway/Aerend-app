/// Chat card data shapes (AGIL-2 Phase 9, Ægil §14).
library;

class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.text,
    this.qty = 1,
    this.done = false,
    this.source = 'manual',
    this.addedByAgent = false,
  });

  final int id;
  final String text;
  final int qty;
  final bool done;
  final String source;

  /// Shown so the customer can tell what Ægil put there from what they typed.
  final bool addedByAgent;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) => ShoppingListItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: (json['text'] as String?) ?? '',
        qty: (json['qty'] as num?)?.toInt() ?? 1,
        done: json['done'] as bool? ?? false,
        source: (json['source'] as String?) ?? 'manual',
        addedByAgent: json['added_by_agent'] as bool? ?? false,
      );
}

/// One product in a comparison. Only the backend's allowlisted fields exist here.
class ComparisonProduct {
  const ComparisonProduct({
    required this.productIdentityId,
    required this.name,
    this.brand,
    this.unitAmount,
    this.unit,
    this.priceOre,
    this.pricePerUnitOre,
    this.storeId,
  });

  final int productIdentityId;
  final String name;
  final String? brand;
  final int? unitAmount;
  final String? unit;
  final int? priceOre;

  /// Price per 100 units, so different pack sizes can be compared honestly.
  final int? pricePerUnitOre;

  final int? storeId;

  String? get sizeLabel =>
      unitAmount == null || unit == null ? null : '$unitAmount $unit';

  factory ComparisonProduct.fromJson(Map<String, dynamic> json) => ComparisonProduct(
        productIdentityId: (json['product_identity_id'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? '',
        brand: json['brand'] as String?,
        unitAmount: (json['unit_amount'] as num?)?.toInt(),
        unit: json['unit'] as String?,
        priceOre: (json['price_ore'] as num?)?.toInt(),
        pricePerUnitOre: (json['price_per_unit_ore'] as num?)?.toInt(),
        storeId: (json['store_id'] as num?)?.toInt(),
      );
}

class Comparison {
  const Comparison({
    this.products = const [],
    this.cheapestId,
    this.note,
  });

  final List<ComparisonProduct> products;
  final int? cheapestId;

  /// Set when the packs are different sizes, so "cheapest" cannot be misread as
  /// "better value".
  final String? note;

  factory Comparison.fromJson(Map<String, dynamic> json) => Comparison(
        products: ((json['products'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ComparisonProduct.fromJson(e.cast<String, dynamic>()))
            .toList(),
        cheapestId: (json['cheapest_id'] as num?)?.toInt(),
        note: json['note'] as String?,
      );
}

class PointsExplainerRule {
  const PointsExplainerRule({
    required this.key,
    required this.title,
    required this.body,
  });

  final String key;
  final String title;
  final String body;

  factory PointsExplainerRule.fromJson(Map<String, dynamic> json) =>
      PointsExplainerRule(
        key: (json['key'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
      );
}

class PointsExplainer {
  const PointsExplainer({
    this.rules = const [],
    this.expiry = '',
    this.tierNote = '',
  });

  final List<PointsExplainerRule> rules;
  final String expiry;

  /// The promise the tier engine keeps: spending never lowers a level.
  final String tierNote;

  factory PointsExplainer.fromJson(Map<String, dynamic> json) => PointsExplainer(
        rules: ((json['rules'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => PointsExplainerRule.fromJson(e.cast<String, dynamic>()))
            .toList(),
        expiry: (json['expiry'] as String?) ?? '',
        tierNote: (json['tier_note'] as String?) ?? '',
      );
}

/// A refusal from the chat tool gate, with the level that would allow it.
class ToolRefusal {
  const ToolRefusal({
    required this.reason,
    required this.copy,
    this.requiredLevel,
  });

  final String reason;
  final String copy;
  final int? requiredLevel;

  bool get isLevelIssue => reason == 'LEVEL_TOO_LOW';

  factory ToolRefusal.fromJson(Map<String, dynamic> json) => ToolRefusal(
        reason: (json['reason'] as String?) ?? '',
        copy: (json['copy'] as String?) ?? '',
        requiredLevel: (json['required_level'] as num?)?.toInt(),
      );
}
