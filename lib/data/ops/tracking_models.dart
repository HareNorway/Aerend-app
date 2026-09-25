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
  });

  final int? id;
  final String firstName;
  final String? avatarUrl;
  final bool verified;

  /// `sykkel` | `bil` | null.
  final String? vehicle;

  bool get onBike => vehicle != 'bil';

  factory OpsCourier.fromJson(Map<String, dynamic> j) => OpsCourier(
    id: (j['id'] as num?)?.toInt(),
    firstName: '${j['first_name'] ?? 'Bud'}',
    avatarUrl: j['avatar_url']?.toString(),
    verified: j['verified'] == true,
    vehicle: j['vehicle']?.toString(),
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
    this.locked = false,
    this.verifiedAt,
  });

  final String? pin;
  final String? reason;
  final String reasonCopyKey;
  final String? qrPayload;
  final bool locked;
  final DateTime? verifiedAt;

  factory OpsDeliveryCode.fromJson(Map<String, dynamic> j) => OpsDeliveryCode(
    pin: j['pin']?.toString(),
    reason: j['reason']?.toString(),
    reasonCopyKey:
        '${j['reason_copy_key'] ?? 'a1_sporing_kode_reason_default'}',
    qrPayload: j['qr_payload']?.toString(),
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
