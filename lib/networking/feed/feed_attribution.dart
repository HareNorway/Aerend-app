import 'dart:convert';

import '../../utils/shared_pref_utill.dart';

/// Which feed post a basket came from (Order Ops §16.1, backend plan Step 9).
///
/// A feed card's «Legg til» remembers its post per store; the order for that
/// store sends it as `source_post_id`, and the delivered order is counted on
/// the post (`attributed_order_count`). One post per store, the latest, and
/// only for a day: a basket left overnight is no longer the post's doing.
abstract final class FeedAttribution {
  static const String prefKey = 'a1_feed_source_posts';
  static const Duration window = Duration(hours: 24);

  static Map<String, dynamic> _read() {
    try {
      final raw = prefGetString(prefKey);
      final json = raw.isEmpty ? null : jsonDecode(raw);
      return json is Map<String, dynamic> ? json : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static void _write(Map<String, dynamic> map) => prefSetString(prefKey, jsonEncode(map));

  /// A feed card added [storeId]'s product to the basket from [postId].
  static void remember({required int storeId, required String postId, DateTime? now}) {
    if (storeId == 0 || postId.isEmpty) return;
    final map = _read();
    map['$storeId'] = {'post': postId, 'at': (now ?? DateTime.now()).toIso8601String()};
    _write(map);
  }

  /// The post an order for [storeId] came from, or null.
  static String? forStore(int storeId, {DateTime? now}) {
    final entry = _read()['$storeId'];
    if (entry is! Map) return null;
    final at = DateTime.tryParse('${entry['at'] ?? ''}');
    final post = '${entry['post'] ?? ''}';
    if (at == null || post.isEmpty || (now ?? DateTime.now()).difference(at) > window) return null;
    return post;
  }

  /// The order is placed: the next one is not the post's doing.
  static void clear(int storeId) {
    final map = _read();
    if (map.remove('$storeId') != null) _write(map);
  }
}
