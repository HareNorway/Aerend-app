import 'package:dio/dio.dart';

import '../../services/feed_jwt_service.dart';

class FeedAuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final jwt = await FeedJwtService.instance.getValidToken();
      options.headers['Authorization'] = 'Bearer $jwt';
    } catch (_) {
      // Proceed without auth; backend returns missing_token for screens to handle.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        (err.requestOptions.extra['feed_retry'] != true)) {
      try {
        final newToken = await FeedJwtService.instance.forceRefresh();
        final retryOptions = err.requestOptions;
        retryOptions.extra['feed_retry'] = true;
        retryOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await Dio().fetch(retryOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        // Fall through to the original error.
      }
    }
    handler.next(err);
  }
}
