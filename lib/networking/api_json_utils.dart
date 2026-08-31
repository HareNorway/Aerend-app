import 'dart:convert';

/// Coerces Dio/API payloads into a JSON map. Prevents crashes like
/// `type 'String' is not a subtype of type 'int' of 'index'` when the
/// server returns HTML/plain text or numeric fields as strings.
Map<String, dynamic> coerceApiJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);

  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) {
      return _unexpectedResponse('Empty server response');
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
    } catch (_) {
      return _unexpectedResponse(trimmed);
    }
    return _unexpectedResponse(trimmed);
  }

  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(data.first as Map);
  }

  return _unexpectedResponse(data?.toString() ?? 'Unexpected server response');
}

Map<String, dynamic> _unexpectedResponse(String message) {
  return {
    'status': 0,
    'message': message,
    'message_code': 9,
  };
}

int? parseApiInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? parseApiString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}
