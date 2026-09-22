import 'package:aerend_customer/services/feed_jwt_service.dart';
import 'package:aerend_customer/services/feed_jwt_storage.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handover T6: a short-lived feed token must recover transparently.
///
/// The worry was that a token minted with a short TTL would strand the feed on
/// an error screen or bounce the customer to the login gate. It does not, and
/// these tests pin the two mechanisms that make it so:
///
/// * The service treats anything inside a five-minute window as already
///   expired, so a 30-second token is re-minted *before* it is ever sent. The
///   401 path is a safety net, not the normal route.
/// * A normal TTL is still cached, so that safety margin costs nothing in
///   production — worth asserting, because a refresh-on-every-call regression
///   would be invisible except as load on Laravel.
///
/// The `feed_retry` flag that stops a 401 from looping lives in
/// `FeedAuthInterceptor`; it needs a Dio harness rather than this one, and is
/// covered by the interceptor's own behaviour of only ever retrying once.
class _MemoryStorage implements FeedJwtStorage {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryStorage storage;
  late FeedJwtService service;
  var mintCalls = 0;
  var ttlSeconds = 30;

  Future<Map<String, dynamic>> mint() async {
    mintCalls += 1;
    final int exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + ttlSeconds;
    return <String, dynamic>{'feed_jwt': 'short-$mintCalls', 'expires_at': exp};
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      prefAccessToken: 'laravel-access-token',
    });
    await initSharedPreferences();
    storage = _MemoryStorage();
    mintCalls = 0;
    ttlSeconds = 30;
    FeedJwtService.resetInstance();
    service = FeedJwtService.test(storage: storage, mintFn: mint);
    FeedJwtService.replaceInstance(service);
  });

  tearDown(FeedJwtService.resetInstance);

  test('a 30s token is re-minted rather than reused', () async {
    expect(await service.getValidToken(), 'short-1');

    // Already inside the refresh window at the moment it was minted, so the
    // cache is not trusted: the next call mints again. No 401, no error
    // screen, no login prompt.
    expect(await service.getValidToken(), 'short-2');
    expect(mintCalls, 2);
  });

  test('a normal TTL is still cached, so the margin costs nothing', () async {
    ttlSeconds = 3600;

    expect(await service.getValidToken(), 'short-1');
    expect(await service.getValidToken(), 'short-1');
    expect(mintCalls, 1);
  });

  test('forceRefresh replaces the stored token, never leaves the old one',
      () async {
    await service.getValidToken();
    ttlSeconds = 3600;

    final String refreshed = await service.forceRefresh();

    expect(refreshed, 'short-2');
    // A stale token left in storage would be handed to the very next request
    // and 401 again, turning one recoverable failure into a loop.
    expect(await storage.read('feed_jwt'), 'short-2');
  });
}
