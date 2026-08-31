import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/exceptions/feed/feed_api_exception.dart';
import 'package:aerend_customer/services/feed_jwt_service.dart';
import 'package:aerend_customer/services/feed_jwt_storage.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryFeedJwtStorage implements FeedJwtStorage {
  final Map<String, String> _data = {};

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

  late MemoryFeedJwtStorage storage;
  late FeedJwtService service;
  var mintCalls = 0;

  Future<Map<String, dynamic>> mintFn() async {
    mintCalls += 1;
  await Future<void>.delayed(const Duration(milliseconds: 50));
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    return {
      'feed_jwt': 'jwt-$mintCalls',
      'expires_at': exp,
    };
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      prefAccessToken: 'laravel-access-token',
    });
    await initSharedPreferences();
    storage = MemoryFeedJwtStorage();
    mintCalls = 0;
    FeedJwtService.resetInstance();
    service = FeedJwtService.test(
      storage: storage,
      mintFn: mintFn,
    );
    FeedJwtService.replaceInstance(service);
  });

  tearDown(() {
    FeedJwtService.resetInstance();
  });

  test('getValidToken mints when cache empty', () async {
    final token = await service.getValidToken();
    expect(token, 'jwt-1');
    expect(await storage.read('feed_jwt'), 'jwt-1');
    expect(mintCalls, 1);
  });

  test('getValidToken returns cached when not near expiry', () async {
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    await storage.write('feed_jwt', 'cached-jwt');
    await storage.write('feed_jwt_exp', exp.toString());

    final token = await service.getValidToken();
    expect(token, 'cached-jwt');
    expect(mintCalls, 0);
  });

  test('getValidToken mints when within 5min of expiry', () async {
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 120;
    await storage.write('feed_jwt', 'old-jwt');
    await storage.write('feed_jwt_exp', exp.toString());

    final token = await service.getValidToken();
    expect(token, isNot('old-jwt'));
    expect(mintCalls, 1);
  });

  test('forceRefresh always mints', () async {
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    await storage.write('feed_jwt', 'cached-jwt');
    await storage.write('feed_jwt_exp', exp.toString());

    final token = await service.forceRefresh();
    expect(token, 'jwt-1');
    expect(mintCalls, 1);
  });

  test('concurrent getValidToken shares one mint', () async {
    final tokens = await Future.wait(
      List.generate(10, (_) => service.getValidToken()),
    );
    expect(tokens.every((t) => t == 'jwt-1'), isTrue);
    expect(mintCalls, 1);
  });

  test('missing access_token throws FeedJwtUnauthenticatedException', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefAccessToken, '');
    await expectLater(
      service.getValidToken(),
      throwsA(
        predicate<Object>(
          (e) => e is FeedJwtUnauthenticatedException,
          'FeedJwtUnauthenticatedException',
        ),
      ),
    );
  });
}
