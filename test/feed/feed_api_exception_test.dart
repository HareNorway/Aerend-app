import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/exceptions/feed/feed_api_exception.dart';

DioException _dioWithBody(Map<String, dynamic> body, {int statusCode = 400}) {
  return DioException(
    requestOptions: RequestOptions(path: '/v1/feed'),
    response: Response(
      requestOptions: RequestOptions(path: '/v1/feed'),
      statusCode: statusCode,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test('maps missing_token to FeedAuthMissingException', () {
    final ex = FeedApiException.fromDio(
      _dioWithBody({
        'error': {
          'code': 'missing_token',
          'message': 'Missing token',
          'request_id': 'req-1',
        },
      }, statusCode: 401),
    );
    expect(ex, isA<FeedAuthMissingException>());
    expect(ex.code, 'missing_token');
    expect(ex.requestId, 'req-1');
  });

  test('maps rate_limit_exceeded with resetAt', () {
    final ex = FeedApiException.fromDio(
      _dioWithBody({
        'error': {
          'code': 'rate_limit_exceeded',
          'message': 'too many',
          'request_id': 'req-2',
          'reset_at': 1710000000000,
        },
      }, statusCode: 429),
    );
    expect(ex, isA<FeedRateLimitException>());
    expect((ex as FeedRateLimitException).resetAt, 1710000000000);
  });

  test('maps store_not_found', () {
    final ex = FeedApiException.fromDio(
      _dioWithBody({
        'error': {
          'code': 'store_not_found',
          'message': 'Store not found',
        },
      }, statusCode: 404),
    );
    expect(ex, isA<FeedStoreNotFoundException>());
  });

  test('maps comment_contains_prohibited_content', () {
    final ex = FeedApiException.fromDio(
      _dioWithBody({
        'error': {
          'code': 'comment_contains_prohibited_content',
          'message': 'blocked',
        },
      }, statusCode: 422),
    );
    expect(ex, isA<FeedProhibitedContentException>());
  });

  test('missing response body yields FeedNetworkException', () {
    final ex = FeedApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/v1/feed'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(ex, isA<FeedNetworkException>());
  });

  test('malformed error envelope yields FeedInternalErrorException', () {
    final ex = FeedApiException.fromDio(
      _dioWithBody({'error': 'not-a-map'}),
    );
    expect(ex, isA<FeedInternalErrorException>());
  });

  test('unknown code yields FeedInternalErrorException with code', () {
    final ex = FeedApiException.fromDio(
      _dioWithBody({
        'error': {
          'code': 'some_new_code',
          'message': 'future error',
        },
      }),
    );
    expect(ex, isA<FeedInternalErrorException>());
    expect(ex.code, 'some_new_code');
  });

  test('maps each documented auth and validation code', () {
    final cases = <String, Type>{
      'jwt_invalid': FeedAuthInvalidException,
      'jwt_expired': FeedAuthExpiredException,
      'customer_action_only': FeedCustomerActionOnlyException,
      'invalid_id_format': FeedInvalidIdException,
      'invalid_cursor': FeedInvalidCursorException,
      'invalid_limit': FeedInvalidLimitException,
      'invalid_query': FeedInvalidQueryException,
      'invalid_request_body': FeedInvalidBodyException,
      'video_upload_not_yet_supported': FeedVideoNotSupportedException,
      'upload_purpose_forbidden': FeedUploadPurposeForbiddenException,
      'post_not_found': FeedPostNotFoundException,
      'comment_not_found': FeedCommentNotFoundException,
      'not_comment_author': FeedNotCommentAuthorException,
      'rate_limit_check_failed': FeedRateLimitCheckFailedException,
      'laravel_unavailable': FeedLaravelUnavailableException,
      'internal_error': FeedInternalErrorException,
    };

    for (final entry in cases.entries) {
      final ex = FeedApiException.fromDio(
        _dioWithBody({
          'error': {'code': entry.key, 'message': entry.key},
        }),
      );
      expect(ex, isA<FeedApiException>());
      expect(ex.runtimeType, entry.value);
    }
  });
}
