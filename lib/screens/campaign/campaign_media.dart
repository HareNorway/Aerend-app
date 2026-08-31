import '../../networking/api_constant.dart';

/// Resolves campaign/club media URLs for network images (relative paths + local dev port).
class CampaignMedia {
  CampaignMedia._();

  static String? resolveUrl(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    String resolved;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      resolved = raw;
    } else if (raw.startsWith('//')) {
      resolved = 'https:$raw';
    } else if (raw.startsWith('/')) {
      resolved = '${BaseUrl.domain}${raw.substring(1)}';
    } else {
      resolved = '${BaseUrl.domain}assets/images/store-images/product-images/$raw';
    }

    return _fixLocalhostPort(resolved);
  }

  static String? _fixLocalhostPort(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final apiBase = Uri.tryParse(BaseUrl.domain);
    if (apiBase != null &&
        uri.host == 'localhost' &&
        uri.port == 80 &&
        apiBase.port != 80 &&
        apiBase.port != 443) {
      return uri.replace(port: apiBase.port).toString();
    }

    return url;
  }
}
