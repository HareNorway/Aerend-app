import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/feed/feed_comment.dart';
import 'package:aerend_customer/data/feed/feed_media.dart';
import 'package:aerend_customer/data/feed/feed_page.dart';
import 'package:aerend_customer/data/feed/feed_post.dart';
import 'package:aerend_customer/data/feed/feed_post_detail.dart';
import 'package:aerend_customer/networking/feed/feed_cloudinary_config.dart';

void main() {
  final fullPostJson = {
    'id': '42',
    'store': {
      'id': '5',
      'name': 'Test Store',
      'slug': 'test-store',
      'logo_url': null,
      'is_following': true,
    },
    'caption': 'Hello feed',
    'location_name': 'Oslo',
    'media': {
      'cloudinary_public_id': 'demo/sample',
      'cloudinary_version': '1',
      'format': 'jpg',
      'width': 1080,
      'height': 1080,
      'resource_type': 'image',
    },
    'like_count': 3,
    'comment_count': 2,
    'is_liked': false,
    'published_at': '2026-05-12T14:30:00+00:00',
  };

  test('FeedPost.fromJson parses full payload', () {
    final post = FeedPost.fromJson(fullPostJson);
    expect(post.id, '42');
    expect(post.store.name, 'Test Store');
    expect(post.caption, 'Hello feed');
    expect(post.likeCount, 3);
    expect(post.publishedAt?.toUtc().toIso8601String(),
        '2026-05-12T14:30:00.000Z');
  });

  test('FeedPage.fromJson with FeedPost items', () {
    final page = FeedPage.fromJson(
      {
        'items': [fullPostJson],
        'next_cursor': 'abc',
      },
      FeedPost.fromJson,
    );
    expect(page.items, hasLength(1));
    expect(page.items.first.id, '42');
    expect(page.nextCursor, 'abc');
  });

  test('FeedPostDetail nested comments', () {
    final detail = FeedPostDetail.fromJson({
      ...fullPostJson,
      'comments': {
        'items': [
          {
            'id': '9',
            'post_id': '42',
            'user': {'id': '1', 'name': 'User', 'avatar_url': null},
            'body': 'Nice',
            'created_at': '2026-05-12T15:00:00+00:00',
          },
        ],
        'next_cursor': null,
      },
    });
    expect(detail.comments.items, hasLength(1));
    expect(detail.comments.items.first.body, 'Nice');
  });

  test('FeedMedia.cloudinaryUrl format', () {
    final media = FeedMedia.fromJson(fullPostJson['media'] as Map<String, dynamic>);
    final url = media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);
    // Built from the configured cloud name rather than a hard-coded one: this
    // test used to assert "demo" and started failing the moment a real cloud
    // was configured, which told us nothing about the URL format it exists to
    // check.
    expect(
      url,
      'https://res.cloudinary.com/${FeedCloudinaryConfig.cloudName}'
      '/image/upload/f_auto,q_auto/v1/demo/sample.jpg',
    );
  });

  test('FeedComment.fromJson includes post_id when present', () {
    final comment = FeedComment.fromJson({
      'id': '9',
      'post_id': '42',
      'user': {'id': '1', 'name': 'User', 'avatar_url': null},
      'body': 'Hi',
      'created_at': '2026-05-12T15:00:00+00:00',
    });
    expect(comment.postId, '42');
    expect(comment.user.name, 'User');
  });
}
