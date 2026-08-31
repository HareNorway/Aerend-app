import 'package:dio/dio.dart';

abstract class FeedApiException implements Exception {
  final String code;
  final String message;
  final String? requestId;
  final int? statusCode;

  const FeedApiException(
    this.code,
    this.message, {
    this.requestId,
    this.statusCode,
  });

  static FeedApiException fromDio(DioException e) {
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) {
      return FeedNetworkException(
        'network_error',
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }

    final error = data['error'];
    if (error is! Map<String, dynamic>) {
      return FeedInternalErrorException(
        'internal_error',
        'Malformed error response',
        statusCode: e.response?.statusCode,
      );
    }

    final code = (error['code'] as String?) ?? 'internal_error';
    final message = (error['message'] as String?) ?? 'Unknown error';
    final requestId = error['request_id'] as String?;
    final statusCode = e.response?.statusCode;

    switch (code) {
      case 'missing_token':
        return FeedAuthMissingException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'jwt_invalid':
        return FeedAuthInvalidException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'jwt_expired':
        return FeedAuthExpiredException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'jwt_invalid_signature':
        return FeedAuthInvalidException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'jwt_claim_mismatch':
        return FeedAuthInvalidException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'jwt_claims_malformed':
        return FeedAuthInvalidException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'customer_action_only':
        return FeedCustomerActionOnlyException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'invalid_id_format':
        return FeedInvalidIdException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'invalid_cursor':
        return FeedInvalidCursorException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'invalid_limit':
        return FeedInvalidLimitException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'invalid_query':
        return FeedInvalidQueryException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'invalid_request_body':
        return FeedInvalidBodyException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'video_upload_not_yet_supported':
        return FeedVideoNotSupportedException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'upload_purpose_forbidden':
        return FeedUploadPurposeForbiddenException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'store_not_found':
        return FeedStoreNotFoundException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'post_not_found':
        return FeedPostNotFoundException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'comment_not_found':
        return FeedCommentNotFoundException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'not_comment_author':
        return FeedNotCommentAuthorException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'comment_contains_prohibited_content':
        return FeedProhibitedContentException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'rate_limit_exceeded':
        final resetAt = error['reset_at'];
        return FeedRateLimitException(
          code,
          message,
          requestId: requestId,
          statusCode: statusCode,
          resetAt: resetAt is num ? resetAt.toInt() : int.tryParse('$resetAt'),
        );
      case 'rate_limit_check_failed':
        return FeedRateLimitCheckFailedException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'laravel_unavailable':
        return FeedLaravelUnavailableException(code, message,
            requestId: requestId, statusCode: statusCode);
      case 'internal_error':
      case 'INTERNAL_ERROR':
        return FeedInternalErrorException(code, message,
            requestId: requestId, statusCode: statusCode);
      default:
        return FeedInternalErrorException(
          code,
          message,
          requestId: requestId,
          statusCode: statusCode,
        );
    }
  }

  @override
  String toString() => 'FeedApiException($code): $message';
}

class FeedAuthMissingException extends FeedApiException {
  const FeedAuthMissingException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedAuthInvalidException extends FeedApiException {
  const FeedAuthInvalidException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedAuthExpiredException extends FeedApiException {
  const FeedAuthExpiredException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedCustomerActionOnlyException extends FeedApiException {
  const FeedCustomerActionOnlyException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedInvalidIdException extends FeedApiException {
  const FeedInvalidIdException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedInvalidCursorException extends FeedApiException {
  const FeedInvalidCursorException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedInvalidLimitException extends FeedApiException {
  const FeedInvalidLimitException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedInvalidQueryException extends FeedApiException {
  const FeedInvalidQueryException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedInvalidBodyException extends FeedApiException {
  const FeedInvalidBodyException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedVideoNotSupportedException extends FeedApiException {
  const FeedVideoNotSupportedException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedUploadPurposeForbiddenException extends FeedApiException {
  const FeedUploadPurposeForbiddenException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedStoreNotFoundException extends FeedApiException {
  const FeedStoreNotFoundException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedPostNotFoundException extends FeedApiException {
  const FeedPostNotFoundException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedCommentNotFoundException extends FeedApiException {
  const FeedCommentNotFoundException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedNotCommentAuthorException extends FeedApiException {
  const FeedNotCommentAuthorException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedProhibitedContentException extends FeedApiException {
  const FeedProhibitedContentException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedRateLimitException extends FeedApiException {
  final int? resetAt;

  const FeedRateLimitException(
    super.code,
    super.message, {
    super.requestId,
    super.statusCode,
    this.resetAt,
  });
}

class FeedRateLimitCheckFailedException extends FeedApiException {
  const FeedRateLimitCheckFailedException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedLaravelUnavailableException extends FeedApiException {
  const FeedLaravelUnavailableException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedInternalErrorException extends FeedApiException {
  const FeedInternalErrorException(super.code, super.message,
      {super.requestId, super.statusCode});
}

class FeedNetworkException extends FeedApiException {
  const FeedNetworkException(super.code, super.message, {super.statusCode});
}

class FeedJwtUnauthenticatedException extends FeedApiException {
  const FeedJwtUnauthenticatedException([
    String message = 'User is not logged in',
  ]) : super('feed_jwt_unauthenticated', message);
}
