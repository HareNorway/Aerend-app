/// Helpers for campaign product copy (contents list, labels).
class CampaignProductUtils {
  CampaignProductUtils._();

  /// Splits admin `contents_description` into bullet lines (Figma INNHOLD).
  static List<String> parseContents(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    final parts = raw
        .split(RegExp(r'[·•,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return [raw.trim()];
    return parts;
  }

  static String audienceLabel({
    required String? clubName,
    required String? distributionLocation,
  }) {
    final club = (clubName ?? '').trim();
    final location = (distributionLocation ?? '').trim();
    if (club.isEmpty && location.isEmpty) return '';
    if (location.isEmpty) return club.toUpperCase();
    if (club.isEmpty) return location.toUpperCase();
    return '${club.toUpperCase()} - ${location.toUpperCase()}';
  }
}
