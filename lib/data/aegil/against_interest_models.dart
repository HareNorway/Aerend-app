/// Against-interest advice, reminders, the action log and the trust ledger
/// (AGIL-2 Phase 8).
library;

/// One piece of advice that costs Ærend money.
///
/// Always carries an alternative — advice with no action is a scolding.
class AgainstInterestLine {
  const AgainstInterestLine({
    required this.check,
    required this.lineCode,
    required this.line,
    required this.alternativeAction,
    required this.alternativeLabel,
    this.savingOre = 0,
    this.productIdentityId,
    this.storeId,
  });

  final String check;
  final String lineCode;
  final String line;
  final String alternativeAction;
  final String alternativeLabel;
  final int savingOre;
  final int? productIdentityId;
  final int? storeId;

  int get savingKr => (savingOre / 100).round();

  factory AgainstInterestLine.fromJson(Map<String, dynamic> json) {
    final alternative =
        (json['alternative'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AgainstInterestLine(
      check: (json['check'] as String?) ?? '',
      lineCode: (json['line_code'] as String?) ?? '',
      line: (json['line'] as String?) ?? '',
      alternativeAction: (alternative['action'] as String?) ?? '',
      alternativeLabel: (alternative['label'] as String?) ?? '',
      savingOre: (json['saving_ore'] as num?)?.toInt() ?? 0,
      productIdentityId: (json['product_identity_id'] as num?)?.toInt(),
      storeId: (json['store_id'] as num?)?.toInt(),
    );
  }
}

class AgentReminderItem {
  const AgentReminderItem({
    required this.id,
    required this.kind,
    this.productName,
    this.targetPriceOre,
    this.state = 'active',
    this.expiresAt,
  });

  final int id;
  final String kind;
  final String? productName;
  final int? targetPriceOre;
  final String state;
  final DateTime? expiresAt;

  bool get isActive => state == 'active';

  factory AgentReminderItem.fromJson(Map<String, dynamic> json) =>
      AgentReminderItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        kind: (json['kind'] as String?) ?? 'wait_for_offer',
        productName: json['product_name'] as String?,
        targetPriceOre: (json['target_price_ore'] as num?)?.toInt(),
        state: (json['state'] as String?) ?? 'active',
        expiresAt: json['expires_at'] is String
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
      );
}

/// Something Ægil did while the customer was away.
class AgentActionItem {
  const AgentActionItem({
    required this.id,
    required this.action,
    required this.summary,
    this.deepLink,
    this.seen = false,
    this.createdAt,
  });

  final int id;
  final String action;
  final String summary;
  final String? deepLink;
  final bool seen;
  final DateTime? createdAt;

  factory AgentActionItem.fromJson(Map<String, dynamic> json) => AgentActionItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        action: (json['action'] as String?) ?? '',
        summary: (json['summary'] as String?) ?? '',
        deepLink: json['deep_link'] as String?,
        seen: json['seen'] as bool? ?? false,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

/// The monthly trust ledger: what Ægil's advice was worth.
class TrustLedgerMonth {
  const TrustLedgerMonth({
    required this.month,
    this.savedKr = 0,
    this.findsApplied = 0,
    this.againstInterestShown = 0,
    this.waitRecommended = 0,
    this.cheaperElsewhereTaken = 0,
  });

  final String month;
  final int savedKr;
  final int findsApplied;

  /// Everything Ægil found — including advice the customer silenced.
  final int againstInterestShown;

  final int waitRecommended;
  final int cheaperElsewhereTaken;

  bool get hasAnything => againstInterestShown > 0;

  factory TrustLedgerMonth.fromJson(Map<String, dynamic> json) => TrustLedgerMonth(
        month: (json['month'] as String?) ?? '',
        savedKr: (json['saved_kr'] as num?)?.toInt() ?? 0,
        findsApplied: (json['finds_applied'] as num?)?.toInt() ?? 0,
        againstInterestShown:
            (json['against_interest_shown'] as num?)?.toInt() ?? 0,
        waitRecommended: (json['wait_recommended'] as num?)?.toInt() ?? 0,
        cheaperElsewhereTaken:
            (json['cheaper_elsewhere_taken'] as num?)?.toInt() ?? 0,
      );
}
