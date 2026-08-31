import 'package:dio/dio.dart';

import '../../utils/shared_pref_utill.dart';

class FeedLocaleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final locale = prefGetString(prefSelectedLanguageCode);
    if (locale.isNotEmpty) {
      options.headers['Accept-Language'] = locale;
    }
    handler.next(options);
  }
}
