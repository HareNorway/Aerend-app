import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../data/feed/feed_comment.dart';
import '../../data/feed/feed_config.dart';
import '../../data/feed/feed_cta.dart';
import '../../data/feed/feed_page.dart';
import '../../data/feed/feed_post.dart';
import '../../data/feed/feed_post_detail.dart';
import '../../data/feed/feed_store.dart';
import '../../data/feed/feed_store_profile.dart';
import '../../data/feed/feed_tab_item.dart';
import '../../data/feed/feed_story.dart';
import '../../data/feed/feed_upload_sign.dart';
import '../../data/feed/feed_write_results.dart';
import '../../utils/shared_pref_utill.dart';
import '../ops/ops_customer_api.dart';
import 'feed_api_helper.dart';

/// The delivery address's coordinates for the feed's I nærheten filter
/// (backend plan Step 9); null when the customer has not picked an address,
/// so the feed is never filtered by the app's Bergen default.
({double lat, double lng})? feedAddressLatLng() {
  final raw = prefGetString(prefSelectedLatLng).trim();
  final parts = raw.split(',');
  if (raw.isEmpty || parts.length < 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lng = double.tryParse(parts[1].trim());
  return lat == null || lng == null ? null : (lat: lat, lng: lng);
}

class FeedRepo {
  FeedRepo({FeedApiHelper? helper}) : _helper = helper ?? FeedApiHelper.instance;

  final FeedApiHelper _helper;

  Future<FeedPage<FeedPost>> fetchFeed({String? cursor, int? limit}) async {
    final json = await _helper.get(
      'feed',
      query: {'cursor': cursor, 'limit': limit},
    );
    return FeedPage.fromJson(json, FeedPost.fromJson);
  }

  Future<FeedPage<FeedPost>> fetchExploreFeed({String? cursor, int? limit}) async {
    final json = await _helper.get(
      'feed/explore',
      query: {'cursor': cursor, 'limit': limit},
    );
    return FeedPage.fromJson(json, FeedPost.fromJson);
  }

  /// One tab of the customer feed (feed update spec §3.1).
  ///
  /// `tab` is the ASCII slug the service expects — `naerheten`, `folger` or
  /// `fra_aerend` — rather than the Norwegian label, so a URL never depends on
  /// encoding "æ" correctly.
  ///
  /// `lat`/`lng` (the delivery address) let I nærheten show only stores that
  /// deliver there, when the feed's proximity flag is on (backend plan
  /// Step 9); without them, or with the flag off, the tab is unfiltered.
  Future<FeedTabPage> fetchFeedTab({
    required String tab,
    String? cursor,
    int? limit,
    String? bydel,
    double? lat,
    double? lng,
  }) async {
    final json = await _helper.get(
      'feed/tabs',
      query: {
        'tab': tab,
        'cursor': cursor,
        'limit': limit,
        'bydel': bydel,
        'lat': lat,
        'lng': lng,
      },
    );
    return FeedTabPage.fromJson(json);
  }

  // ── backend plan Step 9 ─────────────────────────────────────────────────

  /// The Utforsk badge: posts in [tab] since the customer last read it
  /// (`GET /v1/feed/unread`), counted on the server so it agrees across
  /// devices. `capped` means "99+".
  Future<({int unread, bool capped})> fetchUnread({
    String tab = 'naerheten',
    double? lat,
    double? lng,
  }) async {
    final json = await _helper.get(
      'feed/unread',
      query: {'tab': tab, 'lat': lat, 'lng': lng},
    );
    return (
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      capped: json['capped'] == true,
    );
  }

  /// The customer has read [tab] (`POST /v1/feed/seen`).
  Future<void> markSeen({String tab = 'naerheten'}) async {
    await _helper.post('feed/seen', body: {'tab': tab});
  }

  /// The pinned drift notice (`GET /v1/feed/notice`): `note`,
  /// `pinned_until` (ISO-8601), `post_id`; null when there is none.
  Future<Map<String, dynamic>?> fetchNotice() async {
    final json = await _helper.get('feed/notice');
    final notice = json['notice'];
    return notice is Map<String, dynamic> ? notice : null;
  }

  /// Report a post (`POST /v1/posts/:id/report`). [reason] is one of
  /// `spam`, `misleading`, `offensive`, `wrong_price`, `other`. Reporting
  /// twice is one report; true when this was the first.
  Future<bool> reportPost(String postId, {required String reason, String? note}) async {
    final json = await _helper.post(
      'posts/$postId/report',
      body: {'reason': reason, if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );
    return json['already_reported'] != true;
  }

  /// Report a comment (`POST /v1/comments/:id/report`, backend plan Step 13),
  /// with the same reasons as a post. True when this was the first report.
  Future<bool> reportComment(String commentId, {required String reason, String? note}) async {
    final json = await _helper.post(
      'comments/$commentId/report',
      body: {'reason': reason, if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );
    return json['already_reported'] != true;
  }

  // ── backend plan Step 13: the feed switches ─────────────────────────────

  /// The session's copy of the switches, so each screen reads them without a
  /// round trip once one has asked. Refetched after [configTtl].
  static FeedConfig? _config;
  static DateTime? _configAt;
  static const Duration configTtl = Duration(minutes: 10);

  /// What is known now: the cached switches, else all on. For a first frame
  /// that must not wait for [fetchConfig].
  static FeedConfig get cachedConfig => _config ?? FeedConfig.defaults;

  @visibleForTesting
  static void resetConfigCache() {
    _config = null;
    _configAt = null;
  }

  /// `GET /v1/feed/config` — the admin panel's switches. Never throws: all on
  /// when the call fails (not cached, so a later screen asks again).
  Future<FeedConfig> fetchConfig() async {
    final cached = _config;
    final at = _configAt;
    if (cached != null && at != null && DateTime.now().difference(at) < configTtl) {
      return cached;
    }
    // Offline in tests (the route-build contract flips this): the shared
    // client would leave a timeout timer pending.
    if (identical(_helper, FeedApiHelper.instance) && !OpsCustomerApi.networkEnabled) {
      return cached ?? FeedConfig.defaults;
    }
    try {
      final json = await _helper.get('feed/config');
      _configAt = DateTime.now();
      return _config = FeedConfig.fromJson(json);
    } catch (_) {
      return cached ?? FeedConfig.defaults;
    }
  }

  /// Whether the customer gets a push when Ærend publishes (opt-in).
  Future<bool> fetchAerendFollow() async {
    final json = await _helper.get('me/aerend-follow');
    return json['following'] == true;
  }

  Future<bool> setAerendFollow(bool on) async {
    final json = on ? await _helper.put('me/aerend-follow') : await _helper.delete('me/aerend-follow');
    return json['following'] == true;
  }

  /// How many stores this customer follows.
  ///
  /// Used only to tell two empty feeds apart (handover T4). A count rather than
  /// the list: the caller asks whether it is zero and nothing else.
  Future<int> fetchFollowingCount() async {
    final json = await _helper.get('me/follows/count');
    return (json['following_count'] as num?)?.toInt() ?? 0;
  }

  Future<FeedStoryFeed> fetchFollowedStories() async {
    final json = await _helper.get('stories');
    return FeedStoryFeed.fromJson(json);
  }

  Future<FeedStoreProfile> fetchStoreProfile(String storeId) async {
    final json = await _helper.get('stores/$storeId');
    return FeedStoreProfile.fromJson(json);
  }

  Future<FeedPage<FeedPost>> fetchStorePosts(
    String storeId, {
    String? cursor,
    int? limit,
  }) async {
    final json = await _helper.get(
      'stores/$storeId/posts',
      query: {'cursor': cursor, 'limit': limit},
    );
    return FeedPage.fromJson(json, FeedPost.fromJson);
  }

  Future<List<FeedStory>> fetchStoreStories(String storeId) async {
    final json = await _helper.get('stores/$storeId/stories');
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => FeedStory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeedPostDetail> fetchPostDetail(String postId) async {
    final json = await _helper.get('posts/$postId');
    return FeedPostDetail.fromJson(json);
  }

  Future<FeedPage<FeedComment>> fetchPostComments(
    String postId, {
    String? cursor,
    int? limit,
  }) async {
    final json = await _helper.get(
      'posts/$postId/comments',
      query: {'cursor': cursor, 'limit': limit},
    );
    return FeedPage.fromJson(json, FeedComment.fromJson);
  }

  static const int maxSearchStoresLimit = 20;

  Future<List<FeedStore>> searchStores(String query, {int? limit}) async {
    final effectiveLimit =
        (limit ?? 10).clamp(1, maxSearchStoresLimit);
    final json = await _helper.get(
      'search/stores',
      query: {'q': query, 'limit': effectiveLimit},
    );
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => FeedStore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeedCta> resolveCta(String postId) async {
    final json = await _helper.get('cta/$postId');
    return FeedCta.fromJson(json);
  }

  Future<FollowToggleResult> followStore(String storeId) async {
    final json = await _helper.post('stores/$storeId/follow');
    return FollowToggleResult.fromJson(json);
  }

  Future<FollowToggleResult> unfollowStore(String storeId) async {
    final json = await _helper.delete('stores/$storeId/follow');
    return FollowToggleResult.fromJson(json);
  }

  Future<LikeToggleResult> likePost(String postId) async {
    final json = await _helper.post('posts/$postId/like');
    return LikeToggleResult.fromJson(json);
  }

  Future<LikeToggleResult> unlikePost(String postId) async {
    final json = await _helper.delete('posts/$postId/like');
    return LikeToggleResult.fromJson(json);
  }

  /// Syncs the logged-in customer's name and avatar into feed_users.
  Future<void> syncFeedProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;
    final body = <String, dynamic>{'display_name': trimmed};
    final avatar = avatarUrl?.trim();
    if (avatar != null && avatar.isNotEmpty) {
      body['avatar_url'] = avatar;
    }
    await _helper.post('me/profile', body: body);
  }

  Future<FeedComment> createComment(
    String postId,
    String body, {
    String? displayName,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{'body': body};
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      payload['display_name'] = name;
    }
    final avatar = avatarUrl?.trim();
    if (avatar != null && avatar.isNotEmpty) {
      payload['avatar_url'] = avatar;
    }
    final json = await _helper.post(
      'posts/$postId/comments',
      body: payload,
    );
    return FeedComment.fromJson(json);
  }

  Future<CommentDeleteResult> deleteComment(String commentId) async {
    final json = await _helper.delete('comments/$commentId');
    return CommentDeleteResult.fromJson(json);
  }

  Future<FeedUploadSignParams> signUpload({
    required String resourceType,
    required String purpose,
  }) async {
    final json = await _helper.post(
      'uploads/sign',
      body: {
        'resource_type': resourceType,
        'purpose': purpose,
      },
    );
    return FeedUploadSignParams.fromJson(json);
  }
}
