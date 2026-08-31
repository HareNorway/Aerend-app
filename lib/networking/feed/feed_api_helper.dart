import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode, visibleForTesting;
import 'package:flutter_pretty_dio_logger/flutter_pretty_dio_logger.dart';

import '../../exceptions/feed/feed_api_exception.dart';
import 'feed_api_constant.dart';
import 'feed_auth_interceptor.dart';
import 'feed_locale_interceptor.dart';

class FeedApiHelper {
  static final FeedApiHelper instance = FeedApiHelper._();

  FeedApiHelper._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: FeedBaseUrl.apiBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(FeedAuthInterceptor());
    _dio.interceptors.add(FeedLocaleInterceptor());
    if (!kReleaseMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          canShowLog: true,
          queryParameters: true,
          showProcessingTime: false,
          showCUrl: false,
          logPrint: debugPrint,
        ),
      );
    }
  }

  @visibleForTesting
  FeedApiHelper.withDio(this._dio);

  late final Dio _dio;
  Dio get dio => _dio;

  void syncBaseUrl() {
    _dio.options.baseUrl = FeedBaseUrl.apiBase;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    syncBaseUrl();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: _stripNulls(query),
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw FeedApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    syncBaseUrl();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw FeedApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    syncBaseUrl();
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: body,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw FeedApiException.fromDio(e);
    }
  }

  Map<String, dynamic> _parseResponse(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FeedNetworkException('network_error', 'Empty response body');
    }
    return data;
  }

  Map<String, dynamic>? _stripNulls(Map<String, dynamic>? query) {
    if (query == null) return null;
    final out = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null) {
        out[key] = value;
      }
    });
    return out.isEmpty ? null : out;
  }
}
