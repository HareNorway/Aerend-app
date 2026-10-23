/// The customer tracking payload (AGIL-CONTRACT §5.1, served by
/// `ops.customer.tracking`). Every field the Sporing screen shows is derived
/// on the server; the app never maps states itself.
class OpsTracking {
  const OpsTracking({
    required this.orderId,
    required this.state,
    required this.stage,
    required this.stageLabel,
    this.code,
    this.mode = 'delivery',
    this.promisedStart,
    this.promisedEnd,
    this.predictedReadyAt,
    this.adjustedByMinutes = 0,
    this.deliveryActor = 'aerend_courier',
    this.deliveredByLabel = 'Bud',
    this.findingCourier = false,
    this.courier,
    this.store,
    this.callTarget = 'store',
    this.messageTarget = 'store',
    this.deliveryCode,
    this.livePosition,
    this.unseenByStore = false,
    this.policyVersion = 0,
    this.eventsSince = 0,
    this.notice,
    this.effects = const [],
    this.via,
    this.raw = const {},
  });

  static const String modeDelivery = 'delivery';
  static const String modePickup = 'pickup';
  static const String actorCourier = 'aerend_courier';
  static const String actorPartner = 'partner';

  final String orderId;
  final String state;
  final int stage;
  final String stageLabel;
  final String? code;
  final String mode;
  final DateTime? promisedStart;
  final DateTime? promisedEnd;
  final DateTime? predictedReadyAt;
  final int adjustedByMinutes;
  final String deliveryActor;
  final String deliveredByLabel;
  final bool findingCourier;
  final OpsCourier? courier;
  final OpsStoreRef? store;
  final String callTarget;
  final String messageTarget;
  final OpsDeliveryCode? deliveryCode;
  final OpsPosition? livePosition;
  final bool unseenByStore;
  final int policyVersion;
  final int eventsSince;

  /// Customer Step 10: the proactive notice with its options (agent.comms,
  /// until the customer answered it), and the «Utført av Ærend AI» lines on
  /// the order's timeline.
  final OpsNotice? notice;
  final List<OpsEffect> effects;

  /// Customer Step 14: «Via {AI}» — the assistant whose request the customer
  /// confirmed (name, vendor), null for the app's own orders.
  final OpsVia? via;
  final Map<String, dynamic> raw;

  bool get isPickup => mode == modePickup;
  bool get isPartner => deliveryActor == actorPartner;
  bool get isDelivered => state == 'delivered';
  bool get isCancelled => state == 'cancelled';
  bool get hasWindow => promisedStart != null && promisedEnd != null;

  /// "kontaktRolle": butikken for partner orders, else bud.
  String get contactRole => isPartner ? 'butikken' : 'bud';

  static DateTime? _t(dynamic v) =>
      v == null ? null : DateTime.tryParse('$v')?.toLocal();

  factory OpsTracking.fromJson(Map<String, dynamic> j) {
    final contact = j['contact'] is Map ? j['contact'] as Map : const {};
    return OpsTracking(
      orderId: '${j['order_id'] ?? ''}',
      code: j['code']?.toString(),
      mode: '${j['mode'] ?? modeDelivery}',
      state: '${j['state'] ?? 'placed'}',
      stage: (j['stage'] as num?)?.toInt() ?? 0,
      stageLabel: '${j['stage_label'] ?? ''}',
      promisedStart: _t(j['promised_start']),
      promisedEnd: _t(j['promised_end']),
      predictedReadyAt: _t(j['predicted_ready_at']),
      adjustedByMinutes: (j['adjusted_by_minutes'] as num?)?.toInt() ?? 0,
      deliveryActor: '${j['delivery_actor'] ?? actorCourier}',
      deliveredByLabel: '${j['delivered_by_label'] ?? 'Bud'}',
      findingCourier: j['finding_courier'] == true,
      courier: j['courier'] is Map
          ? OpsCourier.fromJson(Map<String, dynamic>.from(j['courier'] as Map))
          : null,
      store: j['store'] is Map
          ? OpsStoreRef.fromJson(Map<String, dynamic>.from(j['store'] as Map))
          : null,
      callTarget: '${contact['call_target'] ?? 'store'}',
      messageTarget: '${contact['message_target'] ?? 'store'}',
      deliveryCode: j['delivery_code'] is Map
          ? OpsDeliveryCode.fromJson(
              Map<String, dynamic>.from(j['delivery_code'] as Map),
            )
          : null,
      livePosition: j['live_position'] is Map
          ? OpsPosition.fromJson(
              Map<String, dynamic>.from(j['live_position'] as Map),
            )
          : null,
      unseenByStore: j['unseen_by_store'] == true,
      policyVersion: (j['policy_version'] as num?)?.toInt() ?? 0,
      eventsSince: (j['events_since'] as num?)?.toInt() ?? 0,
      notice: j['notice'] is Map ? OpsNotice.fromJson(Map<String, dynamic>.from(j['notice'] as Map)) : null,
      effects: [for (final e in (j['effects'] as List? ?? const []).whereType<Map>()) OpsEffect.fromJson(Map<String, dynamic>.from(e))],
      via: j['via'] is Map ? OpsVia.fromJson(Map<String, dynamic>.from(j['via'] as Map)) : null,
      raw: j,
    );
  }

  static String hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// "18:12–18:22", or an empty string without a window.
  String get windowText =>
      hasWindow ? '${hhmm(promisedStart!)}–${hhmm(promisedEnd!)}' : '';

  /// Minutes until the end of the window (never negative), or null.
  int? minutesLeft(DateTime now) {
    final end = promisedEnd;
    if (end == null) return null;
    final m = end.difference(now).inMinutes;
    return m < 0 ? 0 : m;
  }
}

class OpsCourier {
  const OpsCourier({
    required this.firstName,
    this.avatarUrl,
    this.verified = false,
    this.vehicle,
    this.id,
    this.since,
    this.rating,
  });

  final int? id;
  final String firstName;
  final String? avatarUrl;
  final bool verified;

  /// `sykkel` | `bil` | null.
  final String? vehicle;

  /// When they started with Ærend («sykler siden mars»), and their average
  /// customer rating (backend plan Step 4); null when unknown.
  final DateTime? since;
  final double? rating;

  bool get onBike => vehicle != 'bil';

  factory OpsCourier.fromJson(Map<String, dynamic> j) => OpsCourier(
    id: (j['id'] as num?)?.toInt(),
    firstName: '${j['first_name'] ?? 'Bud'}',
    avatarUrl: j['avatar_url']?.toString(),
    verified: j['verified'] == true,
    vehicle: j['vehicle']?.toString(),
    since: DateTime.tryParse('${j['since'] ?? ''}')?.toLocal(),
    rating: (j['rating'] as num?)?.toDouble(),
  );
}

class OpsStoreRef {
  const OpsStoreRef({
    required this.id,
    this.name,
    this.address,
    this.lat,
    this.lng,
  });

  final int id;
  final String? name;
  final String? address;
  final double? lat;
  final double? lng;

  factory OpsStoreRef.fromJson(Map<String, dynamic> j) => OpsStoreRef(
    id: (j['id'] as num?)?.toInt() ?? 0,
    name: j['name']?.toString(),
    address: j['address']?.toString(),
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
  );
}

class OpsDeliveryCode {
  const OpsDeliveryCode({
    this.pin,
    this.reason,
    required this.reasonCopyKey,
    this.qrPayload,
    this.qrUrl,
    this.locked = false,
    this.verifiedAt,
  });

  final String? pin;
  final String? reason;
  final String reasonCopyKey;
  final String? qrPayload;

  /// The QR the courier scans (Customer Step 2, D-K17):
  /// `https://aerend.no/k/<ops_code>-<pin>` while `cus.delivery_qr` is on;
  /// null shows the PIN only.
  final String? qrUrl;
  final bool locked;
  final DateTime? verifiedAt;

  factory OpsDeliveryCode.fromJson(Map<String, dynamic> j) => OpsDeliveryCode(
    pin: j['pin']?.toString(),
    reason: j['reason']?.toString(),
    reasonCopyKey:
        '${j['reason_copy_key'] ?? 'a1_sporing_kode_reason_default'}',
    qrPayload: j['qr_payload']?.toString(),
    qrUrl: j['qr_url']?.toString(),
    locked: j['locked'] == true,
    verifiedAt: OpsTracking._t(j['verified_at']),
  );
}

class OpsPosition {
  const OpsPosition({
    required this.lat,
    required this.lng,
    this.accuracyMetres,
    this.recordedAt,
  });

  final double lat;
  final double lng;
  final int? accuracyMetres;
  final DateTime? recordedAt;

  factory OpsPosition.fromJson(Map<String, dynamic> j) => OpsPosition(
    lat: (j['lat'] as num?)?.toDouble() ?? 0,
    lng: (j['lng'] as num?)?.toDouble() ?? 0,
    accuracyMetres: (j['accuracy_metres'] as num?)?.toInt(),
    recordedAt: OpsTracking._t(j['recorded_at']),
  );
}

/// One option on a proactive notice (`wait` with the new window, `cancel` with its policy).
class OpsNoticeOption {
  const OpsNoticeOption({required this.key, required this.label, this.windowStart, this.windowEnd, this.policy});

  final String key;
  final String label;
  final DateTime? windowStart;
  final DateTime? windowEnd;

  /// `full_refund` on a cancel before pickup.
  final String? policy;

  factory OpsNoticeOption.fromJson(Map<String, dynamic> j) => OpsNoticeOption(
    key: '${j['key'] ?? ''}',
    label: '${j['label'] ?? ''}',
    windowStart: j['window_start'] == null ? null : DateTime.tryParse('${j['window_start']}')?.toLocal(),
    windowEnd: j['window_end'] == null ? null : DateTime.tryParse('${j['window_end']}')?.toLocal(),
    policy: j['policy'] as String?,
  );

  /// «13:07–13:31» for a wait option with a window.
  String get window => windowStart == null || windowEnd == null ? '' : '${OpsTracking.hhmm(windowStart!)}–${OpsTracking.hhmm(windowEnd!)}';
}

/// A proactive notice on the order (Customer Step 10; `delay_notice` / `issue_notice`).
class OpsNotice {
  const OpsNotice({required this.key, required this.kind, required this.title, required this.body, this.reason, this.options = const [], this.at});

  /// The Varsler key (`n:<id>`): answering dismisses it.
  final String key;
  final String kind;
  final String title;
  final String body;
  final String? reason;
  final List<OpsNoticeOption> options;
  final DateTime? at;

  OpsNoticeOption? get wait => options.where((o) => o.key == 'wait').firstOrNull;
  OpsNoticeOption? get cancel => options.where((o) => o.key == 'cancel').firstOrNull;

  factory OpsNotice.fromJson(Map<String, dynamic> j) => OpsNotice(
    key: '${j['key'] ?? ''}',
    kind: '${j['kind'] ?? ''}',
    title: '${j['title'] ?? ''}',
    body: '${j['body'] ?? ''}',
    reason: j['reason'] as String?,
    options: [for (final o in (j['options'] as List? ?? const []).whereType<Map>()) OpsNoticeOption.fromJson(Map<String, dynamic>.from(o))],
    at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal(),
  );
}

/// «Utført av Ærend AI: …» on the order's timeline (`agent.action_applied`, `done_by_ai`).
class OpsEffect {
  const OpsEffect({required this.textKey, required this.text, required this.textEn, this.actionType, this.at});

  final String textKey;
  final String text;
  final String textEn;
  final String? actionType;
  final DateTime? at;

  factory OpsEffect.fromJson(Map<String, dynamic> j) => OpsEffect(
    textKey: '${j['text_key'] ?? ''}',
    text: '${j['text'] ?? ''}',
    textEn: '${j['text_en'] ?? j['text'] ?? ''}',
    actionType: j['action_type'] as String?,
    at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal(),
  );
}

/// «Via {AI}» (Customer Step 14).
class OpsVia {
  const OpsVia({required this.name, required this.vendor});
  final String name;
  final String vendor;
  factory OpsVia.fromJson(Map<String, dynamic> j) => OpsVia(name: '${j['name'] ?? ''}', vendor: '${j['vendor'] ?? 'other'}');
}
