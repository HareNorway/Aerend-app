import '../../data/ops/fiske_models.dart';
import '../../data/ops/sok_models.dart';
import '../../screens/deliveryService/home/ds_home_store_list_pojo.dart';
import '../../screens/deliveryService/searchStore/search_store_dl.dart';
import '../../screens/deliveryService/searchStore/search_store_repo.dart';
import '../../utils/utils.dart';
import '../api_base_helper.dart';

/// The customer app's calls into the monolith's `ops.customer.*` routes and
/// the few other ops / points / agent reads the Bergen screens make
/// (AGIL-CONTRACT §3.2; `lib/networking/ops/ops_customer_api.dart`).
///
/// Auth is the house `user_id` + `access_token` pair from prefs, sent as query
/// parameters the way every other customer endpoint takes them. Reads that
/// belong to the other branch (`/api/points/...`, `/api/agent/...`, `/api/geo/...`)
/// are *guarded*: a 404, a missing route or any failure returns null and the
/// screen hides the element — the endpoint may not be on this tree yet.
class OpsCustomerApi {
  OpsCustomerApi({ApiBaseHelper? helper})
    : _helper = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);

  final ApiBaseHelper _helper;

  static const String _base = 'api/ops/customer/';

  /// False makes every call answer as if offline (null / empty) without
  /// touching the network. The route-build contract test flips it: a screen
  /// that starts a request in `initState` would otherwise leave a Dio timeout
  /// timer pending in the fake-async test zone.
  static bool networkEnabled = true;

  /// `user_id` + `access_token`, or null for a guest.
  static Map<String, String>? authParams() {
    final id = prefGetInt(prefUserId);
    final token = prefGetString(prefAccessToken).trim();
    if (id == 0 || token.isEmpty) return null;
    return {'user_id': '$id', 'access_token': token};
  }

  static String _qs(Map<String, String> params) => params.entries
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');

  Future<Map<String, dynamic>?> _get(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final auth = authParams();
    if (auth == null || !networkEnabled) return null;
    final json = await _helper.get('$path?${_qs({...auth, ...query})}');
    return json is Map<String, dynamic> ? json : null;
  }

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final auth = authParams();
    if (auth == null || !networkEnabled) return null;
    final json = await _helper.post('$path?${_qs(auth)}', body: body);
    return json is Map<String, dynamic> ? json : null;
  }

  /// Null on 404 / missing / any failure: the caller hides the element.
  Future<Map<String, dynamic>?> _guarded(
    Future<Map<String, dynamic>?> Function() call,
  ) async {
    if (!networkEnabled) return null;
    try {
      final json = await call();
      if (json == null) return null;
      // The house envelope: status 0 is a rejection, not data.
      if (json['status'] == 0) return null;
      return json;
    } on AppException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── ops.customer.* (agil-1, Phase 1) ───────────────────────────────────

  /// `ops.customer.tracking` — AGIL-CONTRACT §5.1. Throws on failure so the
  /// Sporing screen can show the offline banner with its last payload.
  Future<Map<String, dynamic>> tracking(int orderId) async {
    final json = await _get('${_base}orders/$orderId/tracking');
    if (json == null) throw UnauthorisedException('Ikke innlogget');
    return json;
  }

  /// `ops.customer.tracking.events` — the polling fallback.
  Future<Map<String, dynamic>?> events(int orderId, {int since = 0}) =>
      _guarded(
        () =>
            _get('${_base}orders/$orderId/events', query: {'since': '$since'}),
      );

  /// `ops.customer.contact` — `kind` is `call` or `message`.
  Future<Map<String, dynamic>?> contact(
    int orderId, {
    required String kind,
    String? message,
  }) => _post('${_base}orders/$orderId/contact', {
    'kind': kind,
    if (message != null) 'message': message,
  });

  /// `ops.customer.problem` — `kind` ∈ door, missing, wait, cancel.
  Future<Map<String, dynamic>?> problem(
    int orderId, {
    required String kind,
    String? words,
    List<String>? items,
  }) => _post('${_base}orders/$orderId/problem', {
    'kind': kind,
    if (words != null) 'words': words,
    if (items != null) 'items': items,
  });

  /// `ops.customer.code` — "Kode ved levering" on the customer's own order.
  Future<Map<String, dynamic>?> requestCode(int orderId) =>
      _guarded(() => _post('${_base}orders/$orderId/code', const {}));

  // ── the demo panel's real triggers (debug builds only) ───────────────

  /// `POST /api/ops/orders/{id}/transition` — the one write path, driven by
  /// the demo panel on the local stack.
  Future<Map<String, dynamic>?> transition(
    int orderId,
    String to, {
    String actorType = 'store',
  }) async {
    if (!networkEnabled) return null;
    try {
      final json = await _helper.post(
        'api/ops/orders/$orderId/transition',
        body: {'to': to, 'actor_type': actorType, 'actor_id': 'demo'},
      );
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  /// `ops.proof.pin` — the courier's PIN check, driven by the demo panel.
  Future<Map<String, dynamic>?> proofPin(
    int orderId,
    String pin, {
    int courierId = 0,
  }) async {
    if (!networkEnabled) return null;
    try {
      final json = await _helper.post(
        'api/ops/proof/orders/$orderId/pin',
        body: {'pin': pin, 'courier_id': courierId},
      );
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  /// `ops.customer.orders`.
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async {
    final json = await _guarded(
      () => _get('${_base}orders', query: {'limit': '$limit'}),
    );
    final list = json?['orders'];
    return list is List
        ? list.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  /// `ops.customer.away`.
  Future<Map<String, dynamic>?> awaySummary() =>
      _guarded(() => _get('${_base}away-summary'));

  /// `ops.customer.fiske` — Fjordfiske today: how many daily-catch points
  /// are taken and left (the count `points/me/earn` caps on) and the prize
  /// cadence. Null when offline or logged out: the screens then show no
  /// number rather than a guessed one.
  Future<FiskeDay?> fiske() async {
    final json = await _guarded(() => _get('${_base}fiske'));
    return json == null ? null : FiskeDay.fromJson(json);
  }

  // ── other agil-1 reads (Phase 2+) ───────────────────────────────────────

  /// Forundringsposer: `GET /api/ops/products?kind=pose`. Empty on failure.
  Future<List<Map<String, dynamic>>> poser() async {
    final json = await _guarded(() async {
      final j = await _helper.get('api/ops/products?kind=pose');
      return j is Map<String, dynamic> ? j : null;
    });
    final list = json?['products'];
    return list is List
        ? list.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  /// The pinned "Ærend · Drift" notice for Utforsk. The availability endpoint
  /// is per store and carries no weather note today, so this is null — the
  /// notice stays hidden (plan Phase 2: "else hidden").
  Future<Map<String, dynamic>?> driftNotice({int? storeId}) async {
    if (storeId == null) return null;
    final json = await _guarded(() async {
      final j = await _helper.get(
        'api/ops/store/availability?store_id=$storeId',
      );
      return j is Map<String, dynamic> ? j : null;
    });
    if (json == null || json['note'] == null) return null;
    return json;
  }

  // ── guarded cross-branch reads ──────────────────────────────────────────

  /// "UNDER KAIEN" finds — agil-2's suggestions tray, `context=under_kaien`.
  /// Hidden on 404 or any failure.
  Future<List<Map<String, dynamic>>> underKaien() async {
    final json = await _guarded(
      () => _get('api/agent/me/suggestions', query: {'context': 'under_kaien'}),
    );
    final list = json?['suggestions'];
    return list is List
        ? list.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  /// `GET /api/points/me/mission` (agil-2's route), guarded.
  Future<Map<String, dynamic>?> mission() =>
      _guarded(() => _get('api/points/mission'));

  /// `GET /api/points/me` (guarded) — the Sporing stage overlay's "+X poeng".
  Future<Map<String, dynamic>?> pointsMe() =>
      _guarded(() => _get('api/points/me'));

  /// `GET /api/points/me/ledger?order={id}` (guarded) — Levert's points line.
  Future<Map<String, dynamic>?> pointsForOrder(int orderId) => _guarded(
    () => _get('api/points/me/ledger', query: {'order': '$orderId'}),
  );

  /// `GET /api/points/me/referral` (guarded) — the vervebillett code.
  Future<Map<String, dynamic>?> referral() =>
      _guarded(() => _get('api/points/me/referral'));

  /// `GET /api/points/rules` (guarded) — the Ærend-kroner percentage.
  Future<Map<String, dynamic>?> pointsRules() =>
      _guarded(() => _get('api/points/rules'));

  /// Søk · treff: the app's existing `search-store` and `search-product`
  /// endpoints (`api_constant.dart`), mapped for the Bergen screen. Either
  /// half failing leaves the other; both failing is an empty result.
  Future<SokTreff> search(String query, {double? lat, double? lng}) async {
    final q = query.trim();
    if (q.length < 2 || !networkEnabled) return const SokTreff();
    final pos = prefGetLatLng();
    final la = lat ?? pos.latitude;
    final ln = lng ?? pos.longitude;
    final repo = SearchStoreRepo();

    final stores = <SokButikk>[];
    final products = <SokProdukt>[];
    try {
      final pojo = DsHomeStoreListPojo.fromJson(
        await repo.callSearchStoreApi(la, ln, q),
      );
      for (final s in pojo.storeList ?? const <StoreListItem>[]) {
        if (s.storeId == null) continue;
        stores.add(
          SokButikk(
            id: s.storeId!,
            name: s.storeName ?? '',
            category: (s.storeProducts ?? '').isEmpty ? null : s.storeProducts,
            etaMinutes: (s.orderDeliveryTime ?? 0) > 0
                ? s.orderDeliveryTime
                : null,
            rating: s.averageRatings == null ? null : '${s.averageRatings}',
            feeText: null,
            bannerUrl: (s.storeBanner ?? '').isEmpty ? null : s.storeBanner,
            open: (s.storeStatus ?? 1) == 1,
          ),
        );
      }
    } catch (_) {
      // Half a result is better than none; see above.
    }
    try {
      final pojo = SearchProductPojo.fromJson(
        await repo.callSearchProductApi(la, ln, 1, q),
      );
      for (final p in pojo.productList) {
        final id = p.productId;
        if (id == 0) continue;
        final amount = double.tryParse('${p.productAmount ?? ''}') ?? 0;
        final discount = double.tryParse('${p.discountAmount ?? ''}');
        products.add(
          SokProdukt(
            id: id,
            name: p.productName,
            storeId: p.storeId,
            storeName: p.storeName,
            price: discount != null && discount > 0 && discount < amount
                ? discount
                : amount,
            wasPrice: discount != null && discount > 0 && discount < amount
                ? amount
                : null,
            imageUrl: p.productImage.isEmpty ? null : p.productImage,
          ),
        );
      }
    } catch (_) {
      // Same.
    }
    return SokTreff(
      butikker: stores.take(4).toList(),
      produkter: products.take(6).toList(),
    );
  }

  /// `GET /api/ops/search/trending` (agil-1, Phase 3). Empty on failure.
  Future<List<String>> trending() async {
    final json = await _guarded(() async {
      final j = await _helper.get('api/ops/search/trending');
      return j is Map<String, dynamic> ? j : null;
    });
    final list = json?['terms'];
    return list is List
        ? list.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : const [];
  }

  /// A guarded POST to a route the other branch owns: null on 404 / failure.
  Future<Map<String, dynamic>?> postGuarded(
    String path,
    Map<String, dynamic> body,
  ) => _guarded(() => _post(path, body));

  /// `GET /api/geo/coverage?lat=&lng=` (agil-3, guarded by flag and 404).
  Future<Map<String, dynamic>?> coverage(double lat, double lng) => _guarded(
    () => _get('api/geo/coverage', query: {'lat': '$lat', 'lng': '$lng'}),
  );

  /// `POST /api/geo/waitlist` (agil-3, guarded).
  Future<Map<String, dynamic>?> waitlist(
    double lat,
    double lng, {
    String? address,
  }) => _guarded(
    () => _post('api/geo/waitlist', {
      'lat': lat,
      'lng': lng,
      if (address != null) 'address': address,
    }),
  );

  /// `GET /api/ops/customer/categories/{slug}/pulse` (agil-1, Phase 4), guarded.
  Future<Map<String, dynamic>?> categoryPulse(String slug) => _guarded(
    () => _get('${_base}categories/${Uri.encodeComponent(slug)}/pulse'),
  );

  /// `GET /api/ops/customer/stores/{id}/presence` (agil-1, Phase 4), guarded.
  Future<Map<String, dynamic>?> storePresence(int storeId) =>
      _guarded(() => _get('${_base}stores/$storeId/presence'));
}
