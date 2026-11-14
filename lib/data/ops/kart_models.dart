import 'dart:math' as math;

/// 2026-11-14: the real maps' data (`ops.customer.order_map`, `ops.customer.store_route`) — points as plain
/// (lat, lng) records so this file needs no map package.
typedef AePunkt = (double lat, double lng);

class AeKartData {
  const AeKartData({
    this.store,
    this.storeName,
    this.door,
    this.doorLabel,
    this.courier,
    this.route = const [],
    this.metres,
    this.seconds,
    this.fromCourier = false,
    this.partner = false,
  });

  final AePunkt? store;
  final String? storeName;
  final AePunkt? door;
  final String? doorLabel;
  final AePunkt? courier;

  /// The road (Google Directions), or the straight line when Google had none; empty without a start.
  final List<AePunkt> route;
  final int? metres;
  final int? seconds;

  /// The road starts at the courier (else at the store: not picked up yet, or no position).
  final bool fromCourier;

  /// The store delivers itself (no courier on the map).
  final bool partner;

  static AePunkt? _p(Object? m) {
    if (m is! Map) return null;
    final lat = (m['lat'] as num?)?.toDouble(), lng = (m['lng'] as num?)?.toDouble();
    return lat == null || lng == null ? null : (lat, lng);
  }

  factory AeKartData.fromJson(Map<String, dynamic> j) {
    final route = j['route'] is Map ? Map<String, dynamic>.from(j['route'] as Map) : const <String, dynamic>{};
    final points = <AePunkt>[
      for (final p in (route['points'] as List? ?? const []))
        if (p is List && p.length == 2 && p[0] is num && p[1] is num) ((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
    final store = j['store'] is Map ? j['store'] as Map : null;
    final door = j['door'] is Map ? j['door'] as Map : null;
    return AeKartData(
      store: _p(store),
      storeName: store?['name'] as String?,
      door: _p(door),
      doorLabel: door?['label'] as String?,
      courier: _p(j['courier']),
      route: points,
      metres: (route['metres'] as num?)?.toInt(),
      seconds: (route['seconds'] as num?)?.toInt(),
      fromCourier: route['from'] == 'courier',
      partner: j['actor'] == 'partner',
    );
  }

  /// The point a [fraction] of the way along the road (Ægil's place when the courier's position is not known).
  AePunkt? along(double fraction) {
    if (route.isEmpty) return null;
    if (route.length == 1) return route.first;
    double d(AePunkt a, AePunkt b) {
      final dx = (a.$2 - b.$2) * 0.5, dy = a.$1 - b.$1; // ≈ metres ratio at 60° N
      return dx * dx + dy * dy;
    }
    final seg = <double>[];
    var total = 0.0;
    for (var i = 1; i < route.length; i++) {
      final s = d(route[i - 1], route[i]);
      final l = s <= 0 ? 0.0 : math.sqrt(s);
      seg.add(l);
      total += l;
    }
    var want = total * fraction.clamp(0.0, 1.0);
    for (var i = 0; i < seg.length; i++) {
      if (want <= seg[i] || i == seg.length - 1) {
        final f = seg[i] == 0 ? 0.0 : (want / seg[i]).clamp(0.0, 1.0);
        final a = route[i], b = route[i + 1];
        return (a.$1 + (b.$1 - a.$1) * f, a.$2 + (b.$2 - a.$2) * f);
      }
      want -= seg[i];
    }
    return route.last;
  }
}
