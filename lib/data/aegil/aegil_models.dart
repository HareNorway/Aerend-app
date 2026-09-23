/// Ægil settings and memory (AGIL-2 Phase 6).
library;

/// What Ægil is allowed to do, in the customer's own words.
///
/// Wording is the design's (NIVAAER in `Ærend Kunde Bergen.dc.html`); the backend sends the
/// same text, so the two cannot drift.
class AegilLevel {
  const AegilLevel({
    required this.level,
    required this.name,
    required this.body,
    this.isDefault = false,
    this.requiresRecurring = false,
  });

  final int level;
  final String name;
  final String body;
  final bool isDefault;

  /// Level 4 is a standing weekly order, so it needs a Vipps recurring agreement.
  final bool requiresRecurring;

  factory AegilLevel.fromJson(Map<String, dynamic> json) => AegilLevel(
        level: (json['level'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        isDefault: json['default'] as bool? ?? false,
        requiresRecurring: json['requires_recurring'] as bool? ?? false,
      );
}

class AegilSettings {
  const AegilSettings({
    this.level = 2,
    this.levelName = 'Varsle og foreslå',
    this.allowedStoreMode = 'all',
    this.pushMode = 'good_only',
    this.learningEnabled = true,
    this.againstInterestEnabled = true,
    this.readAloud = false,
    this.recurringAgreement = false,
    this.paused = false,
    this.pausedUntil,
    this.quietHoursFrom,
    this.quietHoursTo,
    this.mayWriteCart = false,
  });

  final int level;
  final String levelName;
  final String allowedStoreMode;
  final String pushMode;
  final bool learningEnabled;

  /// Advice that costs Ærend money and saves the customer money.
  final bool againstInterestEnabled;

  final bool readAloud;
  final bool recurringAgreement;
  final bool paused;
  final DateTime? pausedUntil;
  final String? quietHoursFrom;
  final String? quietHoursTo;
  final bool mayWriteCart;

  bool get hasQuietHours => quietHoursFrom != null && quietHoursTo != null;

  factory AegilSettings.fromJson(Map<String, dynamic> json) {
    final quiet = (json['quiet_hours'] as Map?)?.cast<String, dynamic>();

    return AegilSettings(
      level: (json['level'] as num?)?.toInt() ?? 2,
      levelName: (json['level_name'] as String?) ?? '',
      allowedStoreMode: (json['allowed_store_mode'] as String?) ?? 'all',
      pushMode: (json['push_mode'] as String?) ?? 'good_only',
      learningEnabled: json['learning_enabled'] as bool? ?? true,
      againstInterestEnabled: json['against_interest_enabled'] as bool? ?? true,
      readAloud: json['read_aloud'] as bool? ?? false,
      recurringAgreement: json['recurring_agreement'] as bool? ?? false,
      paused: json['paused'] as bool? ?? false,
      pausedUntil: json['paused_until'] is String
          ? DateTime.tryParse(json['paused_until'] as String)
          : null,
      quietHoursFrom: quiet?['from'] as String?,
      quietHoursTo: quiet?['to'] as String?,
      mayWriteCart: json['may_write_cart'] as bool? ?? false,
    );
  }
}

/// One thing Ægil knows.
class MemoryEntry {
  const MemoryEntry({
    required this.id,
    required this.kind,
    required this.value,
    this.label,
    this.source = 'chat',
    this.hardConstraint = false,
  });

  final int id;
  final String kind;
  final String value;
  final String? label;
  final String source;

  /// Absolute, and only ever set from an explicit choice — never inferred.
  final bool hardConstraint;

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        kind: (json['kind'] as String?) ?? 'note',
        value: (json['value'] as String?) ?? '',
        label: json['label'] as String?,
        source: (json['source'] as String?) ?? 'chat',
        hardConstraint: json['hard_constraint'] as bool? ?? false,
      );
}

/// One onboarding chip: a single explicit choice.
///
/// Chips are how allergens and diets get recorded at all — the backend refuses to infer them
/// from anything the customer types, so tapping one is the only way to state one.
class OnboardingChip {
  const OnboardingChip({
    required this.kind,
    required this.value,
    required this.label,
    this.selected = false,
  });

  final String kind;
  final String value;
  final String label;
  final bool selected;

  bool get isHardConstraint => kind == 'allergen' || kind == 'diet';

  OnboardingChip toggled() => OnboardingChip(
        kind: kind,
        value: value,
        label: label,
        selected: !selected,
      );

  /// The payload shape `/api/agent/me/preferences/batch` expects.
  Map<String, dynamic> toJson() => {
        'kind': kind,
        'value': value,
        'label': label,
      };
}
