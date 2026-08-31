DateTime parseFeedDateTime(dynamic value) {
  if (value == null) {
    throw const FormatException('Missing datetime');
  }
  if (value is DateTime) {
    return value;
  }
  final s = value.toString().trim();
  if (s.isEmpty) {
    throw FormatException('Empty datetime');
  }
  return DateTime.parse(s);
}

DateTime? parseFeedDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.parse(s);
}
