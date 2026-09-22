import '../../data/feed/feed_comment.dart';
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
import 'feed_api_helper.dart';

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
  Future<FeedTabPage> fetchFeedTab({
    required String tab,
    String? cursor,
    int? limit,
    String? bydel,
  }) async {
    final json = await _helper.get(
      'feed/tabs',
      query: {
        'tab': tab,
        'cursor': cursor,
        'limit': limit,
        'bydel': bydel,
      },
    );
    return FeedTabPage.fromJson(json);
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
