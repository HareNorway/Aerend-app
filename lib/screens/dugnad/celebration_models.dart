// Pending celebration queue models — `POST dugnad/celebrations/pending`.

enum CelebrationType {
  t1,
  t2,
  t3,
  t4,
  t5a,
  t5b,
  t6,
  t7,
  t8,
  t9,
  t10,
  t11,
  t12,
  t13,
  t14,
  t15,
  t16,
  unknown;

  String get apiKey {
    switch (this) {
      case CelebrationType.t5a:
        return 'T5a';
      case CelebrationType.t5b:
        return 'T5b';
      case CelebrationType.unknown:
        return '';
      default:
        return name.toUpperCase();
    }
  }

  static CelebrationType fromApi(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'T1':
        return CelebrationType.t1;
      case 'T2':
        return CelebrationType.t2;
      case 'T3':
        return CelebrationType.t3;
      case 'T4':
        return CelebrationType.t4;
      case 'T5a':
        return CelebrationType.t5a;
      case 'T5b':
        return CelebrationType.t5b;
      case 'T6':
        return CelebrationType.t6;
      case 'T7':
        return CelebrationType.t7;
      case 'T8':
        return CelebrationType.t8;
      case 'T9':
        return CelebrationType.t9;
      case 'T10':
        return CelebrationType.t10;
      case 'T11':
        return CelebrationType.t11;
      case 'T12':
        return CelebrationType.t12;
      case 'T13':
        return CelebrationType.t13;
      case 'T14':
        return CelebrationType.t14;
      case 'T15':
        return CelebrationType.t15;
      case 'T16':
        return CelebrationType.t16;
      default:
        return CelebrationType.unknown;
    }
  }

  /// Spec §6 — higher first. T1 is inline and never queued.
  int get priority {
    switch (this) {
      case CelebrationType.t14:
        return 100;
      case CelebrationType.t13:
        return 90;
      case CelebrationType.t9:
        return 80;
      case CelebrationType.t15:
        return 79;
      case CelebrationType.t10:
        return 78;
      case CelebrationType.t11:
        return 77;
      case CelebrationType.t12:
        return 76;
      case CelebrationType.t5a:
        return 70;
      case CelebrationType.t5b:
        return 69;
      case CelebrationType.t6:
        return 68;
      case CelebrationType.t7:
        return 67;
      case CelebrationType.t8:
        return 66;
      case CelebrationType.t2:
        return 50;
      case CelebrationType.t16:
        return 45;
      case CelebrationType.t3:
        return 40;
      case CelebrationType.t4:
        return 30;
      case CelebrationType.t1:
      case CelebrationType.unknown:
        return 0;
    }
  }

  bool get isQueuedModal => this != CelebrationType.t1 && this != CelebrationType.unknown;

  /// How the orchestrator should present this celebration.
  CelebrationPresentation get presentation {
    switch (this) {
      case CelebrationType.t14:
      case CelebrationType.t13:
      case CelebrationType.t9:
      case CelebrationType.t10:
      case CelebrationType.t11:
      case CelebrationType.t12:
      case CelebrationType.t15:
        return CelebrationPresentation.fullscreenCeremonial;
      default:
        // T2–T8 / T5a–T5b are modal overlays.
        return CelebrationPresentation.modal;
    }
  }

  @Deprecated('Use presentation instead')
  bool get isCeremonial =>
      presentation == CelebrationPresentation.fullscreenCeremonial;
}

enum CelebrationPresentation {
  /// Card overlay on top of current screen (T2–T8).
  modal,

  /// Full-screen club-gradient ceremonial route (T13–T14, T9–T12, T15).
  fullscreenCeremonial,
}

class CelebrationConfig {
  const CelebrationConfig({
    this.sessionCap = 3,
    this.formFlapHours = 24,
    this.tweaks = const {},
  });

  final int sessionCap;
  final int formFlapHours;
  final Map<String, bool> tweaks;

  factory CelebrationConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CelebrationConfig();
    final tweaksRaw = json['tweaks'];
    final tweaks = <String, bool>{};
    if (tweaksRaw is Map) {
      tweaksRaw.forEach((key, value) {
        tweaks[key.toString()] = value == true;
      });
    }
    return CelebrationConfig(
      sessionCap: (json['session_cap'] as num?)?.toInt() ?? 3,
      formFlapHours: (json['form_flap_hours'] as num?)?.toInt() ?? 24,
      tweaks: tweaks,
    );
  }

  bool isTweakEnabled(CelebrationType type) {
    if (type == CelebrationType.unknown) return false;
    return tweaks[type.apiKey] ?? false;
  }
}

class PendingCelebration {
  const PendingCelebration({
    required this.id,
    required this.type,
    required this.clubId,
    required this.payload,
    this.priority = 0,
    this.createdAt,
    this.consumedAt,
  });

  final int id;
  final CelebrationType type;
  final int clubId;
  final Map<String, dynamic> payload;
  final int priority;
  final DateTime? createdAt;
  final DateTime? consumedAt;

  bool get isConsumed => consumedAt != null;

  factory PendingCelebration.fromJson(Map<String, dynamic> json) {
    final type = CelebrationType.fromApi(json['type_key']?.toString());
    Map<String, dynamic> payload = const {};
    final raw = json['payload'] ?? json['payload_json'];
    if (raw is Map) {
      payload = Map<String, dynamic>.from(raw);
    }
    return PendingCelebration(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: type,
      clubId: (json['club_id'] as num?)?.toInt() ?? 0,
      payload: payload,
      priority: (json['priority'] as num?)?.toInt() ?? type.priority,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      consumedAt: DateTime.tryParse(json['consumed_at']?.toString() ?? ''),
    );
  }

  String? stringPayload(String key) {
    final v = payload[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  int? intPayload(String key) {
    final v = payload[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }
}

class PendingCelebrationsResponse {
  const PendingCelebrationsResponse({
    required this.clubId,
    required this.config,
    required this.celebrations,
  });

  final int clubId;
  final CelebrationConfig config;
  final List<PendingCelebration> celebrations;

  factory PendingCelebrationsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['celebrations'] as List? ?? [];
    return PendingCelebrationsResponse(
      clubId: (json['club_id'] as num?)?.toInt() ?? 0,
      config: CelebrationConfig.fromJson(
        json['celebration_config'] is Map
            ? Map<String, dynamic>.from(json['celebration_config'] as Map)
            : null,
      ),
      celebrations: list
          .whereType<Map>()
          .map((e) => PendingCelebration.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Spec §6 sort: priority desc, then created_at asc. Drops T1 / unknown.
List<PendingCelebration> sortCelebrationsByPriority(
  Iterable<PendingCelebration> items,
) {
  final list = items.where((e) => e.type.isQueuedModal && !e.isConsumed).toList();
  list.sort((a, b) {
    final pa = a.priority != 0 ? a.priority : a.type.priority;
    final pb = b.priority != 0 ? b.priority : b.type.priority;
    if (pa != pb) return pb.compareTo(pa);
    final ca = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final cb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ca.compareTo(cb);
  });
  return list;
}

/// One T14 and one T13 per queue — duplicate club/team rows from retries
/// would otherwise play the same ceremony twice. Multiple T16 STØ-rises in
/// the same fetch collapse to one jump (earliest previous → latest new).
List<PendingCelebration> collapseTransitionDuplicates(
  Iterable<PendingCelebration> items,
) {
  PendingCelebration? t14;
  PendingCelebration? t13;
  PendingCelebration? t16;
  final rest = <PendingCelebration>[];
  for (final item in items) {
    if (item.type == CelebrationType.t14) {
      if (t14 == null || item.id > t14.id) t14 = item;
    } else if (item.type == CelebrationType.t13) {
      if (t13 == null || item.id > t13.id) t13 = item;
    } else if (item.type == CelebrationType.t16) {
      t16 = _mergeStoRise(t16, item);
    } else {
      rest.add(item);
    }
  }
  return sortCelebrationsByPriority([
    if (t14 != null) t14,
    if (t13 != null) t13,
    if (t16 != null) t16,
    ...rest,
  ]);
}

PendingCelebration _mergeStoRise(
  PendingCelebration? current,
  PendingCelebration next,
) {
  if (current == null) return next;
  final older = next.id < current.id ? next : current;
  final newer = next.id < current.id ? current : next;
  final prev = older.intPayload('previous_sto') ??
      newer.intPayload('previous_sto') ??
      0;
  final neu = newer.intPayload('new_sto') ??
      older.intPayload('new_sto') ??
      prev;
  return PendingCelebration(
    id: newer.id,
    type: newer.type,
    clubId: newer.clubId,
    payload: {
      ...newer.payload,
      'previous_sto': prev,
      'new_sto': neu,
      'delta': neu - prev,
    },
    priority: newer.priority,
    createdAt: newer.createdAt,
    consumedAt: newer.consumedAt,
  );
}
