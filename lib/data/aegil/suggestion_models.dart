/// Suggestion tray data shapes (AGIL-2 Phase 7).
library;

class Suggestion {
  const Suggestion({
    required this.id,
    required this.reasonCode,
    required this.reason,
    this.state = 'open',
    this.headline,
    this.productIdentityId,
    this.storeId,
    this.storeProductId,
    this.category,
    this.postId,
    this.expiresAt,
    this.bydel,
    this.storeName,
    this.etaMinutes,
    this.priceOre,
  });

  final int id;

  /// One of the nine codes. A suggestion that cannot name why it exists is not made.
  final String reasonCode;

  /// The same reason in the customer's language, from the backend.
  final String reason;

  final String state;
  final String? headline;
  final int? productIdentityId;
  final int? storeId;
  final int? storeProductId;
  final String? category;
  final String? postId;
  final DateTime? expiresAt;

  /// Card facts (Fjordfiske): the post's district, and the store name, delivery
  /// minutes and today's price in øre read live by the server. Null when unknown.
  final String? bydel;
  final String? storeName;
  final int? etaMinutes;
  final int? priceOre;

  factory Suggestion.fromJson(Map<String, dynamic> json) => Suggestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        reasonCode: (json['reason_code'] as String?) ?? '',
        reason: (json['reason'] as String?) ?? '',
        state: (json['state'] as String?) ?? 'open',
        headline: json['headline'] as String?,
        productIdentityId: (json['product_identity_id'] as num?)?.toInt(),
        storeId: (json['store_id'] as num?)?.toInt(),
        storeProductId: (json['store_product_id'] as num?)?.toInt(),
        category: json['category'] as String?,
        postId: json['post_id'] as String?,
        expiresAt: json['expires_at'] is String
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        bydel: json['bydel'] as String?,
        storeName: json['store_name'] as String?,
        etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
        priceOre: (json['price_ore'] as num?)?.toInt(),
      );
}

/// Why a customer said no. The reasons are distinct because they mean different things:
/// "already have" is not a dislike, and "wrong store" is not about the product.
enum NotForMeReason {
  notForMe('not_for_me', 'Ikke for meg'),
  alreadyHave('already_have', 'Jeg har den allerede'),
  wrongTime('wrong_time', 'Ikke nå'),
  tooExpensive('too_expensive', 'For dyrt'),
  wrongStore('wrong_store', 'Ikke denne butikken'),
  notInterested('not_interested', 'Interesserer meg ikke');

  const NotForMeReason(this.code, this.label);

  final String code;
  final String label;
}

/// The result of reeling in the daily catch in "Vågen".
class DailyCatch {
  const DailyCatch({
    required this.day,
    this.points = 0,
    this.alreadyReeled = false,
    this.suggestion,
  });

  final String day;
  final int points;

  /// The contract allows one catch per customer per calendar day.
  final bool alreadyReeled;

  final Suggestion? suggestion;

  factory DailyCatch.fromJson(Map<String, dynamic> json) => DailyCatch(
        day: (json['day'] as String?) ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        alreadyReeled: json['already_reeled'] as bool? ?? false,
        suggestion: json['suggestion'] == null
            ? null
            : Suggestion.fromJson(
                (json['suggestion'] as Map).cast<String, dynamic>()),
      );
}
