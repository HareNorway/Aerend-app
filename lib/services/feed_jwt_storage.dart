import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class FeedJwtStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureFeedJwtStorage implements FeedJwtStorage {
  const FlutterSecureFeedJwtStorage([this._inner = const FlutterSecureStorage()]);

  final FlutterSecureStorage _inner;

  @override
  Future<void> delete(String key) => _inner.delete(key: key);

  @override
  Future<String?> read(String key) => _inner.read(key: key);

  @override
  Future<void> write(String key, String value) => _inner.write(key: key, value: value);
}
