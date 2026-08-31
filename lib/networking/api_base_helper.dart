import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pretty_dio_logger/flutter_pretty_dio_logger.dart';

import '../utils/utils.dart';
import 'api_constant.dart';
import 'api_exceptions.dart';

export 'api_constant.dart';
export 'api_exceptions.dart';
export 'api_response.dart';

class ApiBaseHelper {
  final Dio _dio = Dio();
  final String? _fixedBaseUrl;

  ApiBaseHelper({String? baseUrl}) : _fixedBaseUrl = baseUrl {
    // When no fixed baseUrl is provided, resolve dynamically from BaseUrl.baseUrl
    // so that dev-env overrides take effect without restarting the app.
    _dio.options.baseUrl = baseUrl ?? BaseUrl.baseUrl;
    _dio.options.connectTimeout = const Duration(minutes: 3);
    _dio.options.receiveTimeout = const Duration(minutes: 3);
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      options.headers[ApiParam.paramSelectLanguageHeader] =
          prefGetStringWithDefaultValue(
              prefSelectedLanguageCode, defaultLanguage);
      final requestBase = _fixedBaseUrl ?? BaseUrl.domain;
      final tunnelAuth = BaseUrl.devTunnelAuthorizationHeader(requestBase);
      if (tunnelAuth != null) {
        options.headers['X-Tunnel-Authorization'] = tunnelAuth;
      }
      return handler.next(options);
    }, onResponse: (response, handler) {
      return handler.next(response);
    }, onError: (DioException e, handler) {
      return handler.next(e);
    }));
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

  /// Re-resolve base URL if no fixed URL was provided (supports dev-env override).
  void _syncBaseUrl() {
    if (_fixedBaseUrl == null) {
      _dio.options.baseUrl = BaseUrl.baseUrl;
    }
  }

  Future<dynamic> get(String url) async {
    _syncBaseUrl();
    print('[API] GET ${_dio.options.baseUrl}$url');
    dynamic responseJson;
    try {
      final response = await _dio.get(url);
      responseJson = _returnResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
    return responseJson;
  }

  Future<dynamic> post(String url, {dynamic body}) async {
    _syncBaseUrl();
    print('[API] POST ${_dio.options.baseUrl}$url');
    dynamic responseJson;
    try {
      Response response = await _dio.post(url, data: jsonEncode(body));
      responseJson = _returnResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
    return responseJson;
  }

  /// Like [post] but returns client-error (4xx, status < 500) bodies instead of
  /// throwing, so callers can read structured error payloads such as
  /// `{status:0, code:'change_locked', ...}`. 5xx and network/timeout failures
  /// still throw via [_handleError] exactly like [post]. Reuses this instance's
  /// interceptors, headers, and base URL; only relaxes validateStatus per-request.
  Future<ApiClientResult> postAllowClientError(String url, {dynamic body}) async {
    _syncBaseUrl();
    print('[API] POST(ace) ${_dio.options.baseUrl}$url');
    try {
      final response = await _dio.post(
        url,
        data: jsonEncode(body),
        options: Options(validateStatus: (s) => s != null && s >= 200 && s < 500),
      );
      return ApiClientResult(
        response.statusCode ?? 0,
        _normalizeResponseData(response.data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> postFormData(String url, {dynamic body, onProgress}) async {
    _syncBaseUrl();
    print('[API] POST-FORM ${_dio.options.baseUrl}$url');
    dynamic responseJson;
    try {
      Response response = await _dio.post(url,
          data: FormData.fromMap(body),
          onSendProgress: (sent, total) =>
              onProgress != null ? onProgress(sent / total) : null);
      responseJson = _returnResponse(response);
    } catch (e) {
      // throw FetchDataException('No Internet connection');
      throw _handleError(e);
    }
    return responseJson;
  }

  Future<dynamic> put(String url, dynamic body) async {
    _syncBaseUrl();
    print('[API] PUT ${_dio.options.baseUrl}$url');
    dynamic responseJson;
    try {
      final response = await _dio.put(url, data: body);
      responseJson = _returnResponse(response);
    } catch (e) {
      // throw FetchDataException('No Internet connection');
      throw _handleError(e);
    }
    debugPrint(responseJson.toString());
    return responseJson;
  }

  Future<dynamic> patch(String url, {dynamic body}) async {
    _syncBaseUrl();
    print('[API] PATCH ${_dio.options.baseUrl}$url');
    dynamic responseJson;
    try {
      final response = await _dio.patch(url, data: body is Map ? jsonEncode(body) : body);
      responseJson = _returnResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
    return responseJson;
  }

  Future<dynamic> delete(String url) async {
    _syncBaseUrl();
    print('[API] DELETE ${_dio.options.baseUrl}$url');
    dynamic apiResponse;
    try {
      final response = await _dio.delete(url);
      apiResponse = _returnResponse(response);
    } catch (e) {
      // throw FetchDataException('No Internet connection');
      throw _handleError(e);
    }
    return apiResponse;
  }
}

/// Result of [ApiBaseHelper.postAllowClientError] — carries the HTTP status code
/// alongside the (normalized) response body so callers can branch on 2xx vs 4xx.
class ApiClientResult {
  final int statusCode;
  final dynamic data;

  ApiClientResult(this.statusCode, this.data);
}

class ApiMapHelper {
  final Dio _dio = Dio();

  ApiMapHelper() {
    _dio.options.baseUrl = BaseUrl.mapBaseUrl;
    _dio.options.connectTimeout = const Duration(minutes: 3);
    _dio.options.receiveTimeout = const Duration(minutes: 3);
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

  Future<dynamic> get(String url) async {
    dynamic responseJson;
    try {
      final response = await _dio.get(url);
      responseJson = _returnResponse(response);
    } catch (e) {
      // throw FetchDataException('No Internet connection');
      throw _handleError(e);
    }
    return responseJson;
  }
}

class ApiFirebaseHelper {
  final Dio _dio = Dio();

  ApiFirebaseHelper(String auth2Token) {
    _dio.options.baseUrl = '';
    _dio.options.connectTimeout = const Duration(minutes: 3);
    _dio.options.receiveTimeout = const Duration(minutes: 3);
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $auth2Token'
    };
    _dio.options.headers.addAll(requestHeaders);
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

  /// [url] is ignored; the FCM endpoint is always [BaseUrl.firebaseMessagingSendEndpoint].
  Future<dynamic> postFormData(String url, {dynamic body}) async {
    dynamic responseJson;
    try {
      final Response response = await _dio.post(
        BaseUrl.firebaseMessagingSendEndpoint,
        data: jsonEncode(body),
      );
      responseJson = _returnResponse(response);
    } catch (e) {
      // throw FetchDataException('No Internet connection');
      throw _handleError(e);
    }
    return responseJson;
  }
}

dynamic _returnResponse(Response response) {
  switch (response.statusCode) {
    case 200:
    case 201:
      return _normalizeResponseData(response.data);
    case 400:
      throw BadRequestException(response.data.toString());
    case 401:
    case 403:
      throw UnauthorisedException(response.data.toString());
    case 500:
    default:
      throw FetchDataException(
          'Error occured while Communication with Server with StatusCode : ${response.statusCode}');
  }
}

dynamic _normalizeResponseData(dynamic data) {
  if (data is Map || data is List) return data;
  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return data;
    if (trimmed.startsWith('{') ||
        trimmed.startsWith('[') ||
        trimmed.startsWith('"')) {
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return data;
      }
    }
  }
  return data;
}

String _handleError(dynamic error) {
  String errorDescription = "";
  if (error is DioException) {
    DioException dioError = error;
    switch (dioError.type) {
      case DioExceptionType.cancel:
        errorDescription = languages.apiErrorCancelMsg;
        break;
      case DioExceptionType.connectionTimeout:
        errorDescription = languages.apiErrorConnectTimeoutMsg;
        break;
      case DioExceptionType.unknown:
        errorDescription = languages.apiErrorOtherMsg;
        break;
      case DioExceptionType.receiveTimeout:
        errorDescription = languages.apiErrorReceiveTimeoutMsg;
        break;
      case DioExceptionType.badResponse:
        errorDescription =
            "${languages.apiErrorResponseMsg}: ${dioError.response?.statusCode}";
        break;
      case DioExceptionType.sendTimeout:
        errorDescription = languages.apiErrorSendTimeoutMsg;
        break;
      case DioExceptionType.badCertificate:
        errorDescription = languages.apiErrorUnexpectedErrorMsg;
        break;
      case DioExceptionType.connectionError:
        errorDescription = languages.apiErrorConnectTimeoutMsg;
        break;
    }
  } else {
    errorDescription = languages.apiErrorUnexpectedErrorMsg;
  }
  return errorDescription;
}