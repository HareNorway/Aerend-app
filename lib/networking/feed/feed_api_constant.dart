import 'package:shared_preferences/shared_preferences.dart';

import '../api_constant.dart';

class FeedBaseUrl {
  static String _override = '';

  static const String prodDomain =
      'https://aerend-feed-88chd.ondigitalocean.app/';
  // static const String prodDomain =
      // 'http://172.16.37.180:3000/';
  static const String localIOS = 'http://localhost:3000/';
  static const String localAndroid = 'http://10.0.2.2:3000/';

  static String get localLan {
    final laravel = BaseUrl.localLan;
    return laravel.replaceAll(':8000/', ':3000/');
  }

  static String get domain {
    if (_override.isNotEmpty) return _override;
    return prodDomain;
  }

  static String get apiBase => '${domain}v1/';

  static void setOverride(String baseUrl) {
    _override = baseUrl;
    SharedPreferences.getInstance()
        .then((p) => p.setString('dev_feed_api_override', baseUrl));
  }

  static Future<void> restoreOverride() async {
    final p = await SharedPreferences.getInstance();
    _override = p.getString('dev_feed_api_override') ?? '';
  }

  static void clearOverride() {
    _override = '';
    SharedPreferences.getInstance()
        .then((p) => p.remove('dev_feed_api_override'));
  }
}
