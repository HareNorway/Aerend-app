import 'dart:async' show Completer, unawaited;

import 'package:flutter/foundation.dart';
import '../exceptions/feed/feed_api_exception.dart';
import 'feed_jwt_storage.dart';
import '../networking/api_base_helper.dart';
import '../utils/shared_pref_utill.dart';

const _kFeedJwtKey = 'feed_jwt';
const _kFeedJwtExpKey = 'feed_jwt_exp';
const _refreshWindowSeconds = 300;

typedef FeedJwtMintFn = Future<Map<String, dynamic>> Function();

class FeedJwtService {
  static FeedJwtService instance = FeedJwtService._();

  FeedJwtService._({
    FeedJwtStorage? storage,
    FeedJwtMintFn? mintFn,
  })  : _storage = storage ?? const FlutterSecureFeedJwtStorage(),
        _mintFn = mintFn;

  @visibleForTesting
  factory FeedJwtService.test({
    FeedJwtStorage? storage,
    FeedJwtMintFn? mintFn,
  }) =>
      FeedJwtService._(
        storage: storage,
        mintFn: mintFn,
      );

  final FeedJwtStorage _storage;
  final FeedJwtMintFn? _mintFn;

  Completer<String>? _pendingMint;

  @visibleForTesting
  static void replaceInstance(FeedJwtService service) {
    instance = service;
  }

  @visibleForTesting
  static void resetInstance() {
    instance = FeedJwtService._();
  }

  Future<String> getValidToken() async {
    final cached = await _readCached();
    if (cached != null) {
      return cached;
    }
    return _mintWithGuard();
  }

  Future<String> forceRefresh() async {
    await clear();
    return _mintWithGuard();
  }

  Future<void> clear() async {
    await _storage.delete(_kFeedJwtKey);
    await _storage.delete(_kFeedJwtExpKey);
  }

  Future<String> _mintWithGuard() async {
    if (_pendingMint != null) {
      return _pendingMint!.future;
    }

    final completer = Completer<String>();
    _pendingMint = completer;
    unawaited(_runMint(completer));
    return completer.future;
  }

  Future<void> _runMint(Completer<String> completer) async {
    try {
      completer.complete(await _mintNow());
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      _pendingMint = null;
    }
  }

  Future<String?> _readCached() async {
    final token = await _storage.read(_kFeedJwtKey);
    final expRaw = await _storage.read(_kFeedJwtExpKey);
    if (token == null || token.isEmpty || expRaw == null || expRaw.isEmpty) {
      return null;
    }

    final exp = int.tryParse(expRaw);
    if (exp == null) {
      return null;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (exp - now < _refreshWindowSeconds) {
      return null;
    }

    return token;
  }

  Future<String> _mintNow() async {
    final accessToken = prefGetString(prefAccessToken);
    if (accessToken.isEmpty) {
      throw const FeedJwtUnauthenticatedException();
    }

    final Map<String, dynamic> body;
    final mint = _mintFn;
    if (mint != null) {
      body = await mint();
    } else {
      // Mint at Laravel root (`/api/auth/feed-token`), not under `/api/customer/`.
      final response = await ApiBaseHelper(baseUrl: BaseUrl.domain).post(
        'api/auth/feed-token',
        body: {
          'access_token': accessToken,
          'actor_type': 'customer',
        },
      );
      if (response is! Map<String, dynamic>) {
        throw const FeedNetworkException(
          'network_error',
          'Invalid feed token response',
        );
      }
      body = response;
    }

    final jwt = body['feed_jwt'] as String?;
    final expiresAt = body['expires_at'];
    if (jwt == null || jwt.isEmpty || expiresAt == null) {
      throw const FeedNetworkException(
        'network_error',
        'Feed token mint failed',
      );
    }

    final expUnix = expiresAt is num
        ? expiresAt.toInt()
        : int.tryParse(expiresAt.toString());
    if (expUnix == null) {
      throw const FeedNetworkException(
        'network_error',
        'Invalid feed token expiry',
      );
    }

    await _storage.write(_kFeedJwtKey, jwt);
    await _storage.write(_kFeedJwtExpKey, expUnix.toString());

    if (kDebugMode) {
      debugPrint('[FeedJwt] mint success exp=$expUnix');
    }

    return jwt;
  }
}
