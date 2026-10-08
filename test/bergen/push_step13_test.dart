import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_routes.dart';
import 'package:aerend_customer/services/push_deep_link.dart';
import 'package:aerend_customer/services/push_notification_service.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

import '../layout/reduced_motion_harness.dart';

/// Backend plan Step 13 — the app's half of «Push-varsler»: a campaign push
/// and the ops pushes open where they point, the campaign's open is counted,
/// and a tap that launches the app waits for the shell instead of crashing
/// on a navigator that is not there yet.

class _Ops extends OpsCustomerApi {
  final List<String> opened = [];

  @override
  Future<bool> pushOpened(String campaignId) async {
    opened.add(campaignId);
    return true;
  }
}

Map<String, dynamic> _campaign(
  String target, {
  String ref = '',
  String name = '',
  String slug = '',
  String link = '',
  String id = '7',
}) => {
  'type': 'aerend_push',
  'campaign_id': id,
  'target': target,
  'target_ref': ref,
  'target_name': name,
  'target_slug': slug,
  'deep_link': link,
  'title': 'Tittel',
  'message': 'Tekst',
};

void main() {
  setUp(() async {
    await bootstrapGlobals();
    PushDeepLink.takePending();
  });

  group('campaign target → route', () {
    test('home and offers open the shell on Hjem', () {
      expect(PushDeepLink.resolve(_campaign('home', link: 'aerend://home')), const PushRoute.shell());
      expect(PushDeepLink.resolve(_campaign('offers', link: 'aerend://offers')), const PushRoute.shell());
      expect(PushDeepLink.resolve(_campaign('home'))!.tab, 0);
    });

    test('swipe opens Swipe', () {
      expect(PushDeepLink.resolve(_campaign('swipe')), const PushRoute.swipe());
    });

    test('category opens Kategori by slug, with id and name', () {
      expect(
        PushDeepLink.resolve(_campaign('category', ref: '5', name: 'Mote', slug: 'mote', link: 'aerend://category/mote')),
        const PushRoute.bergen('/bergen/kategori/mote', arguments: {'slug': 'mote', 'id': '5', 'name': 'Mote'}),
      );
      // No slug field: the link's.
      expect(
        PushDeepLink.resolve(_campaign('category', ref: '5', link: 'aerend://category/mote')),
        const PushRoute.bergen('/bergen/kategori/mote', arguments: {'slug': 'mote', 'id': '5'}),
      );
    });

    test('store opens Butikk with the name', () {
      expect(
        PushDeepLink.resolve(_campaign('store', ref: '12', name: 'Møllaren Café', link: 'aerend://store/12')),
        const PushRoute.bergen('/bergen/butikk/12', arguments: {'name': 'Møllaren Café'}),
      );
      expect(
        PushDeepLink.resolve(_campaign('store', link: 'aerend://store/12')),
        const PushRoute.bergen('/bergen/butikk/12'),
        reason: 'no target_ref: the store id from the link',
      );
    });

    test('cart, orders and profile', () {
      expect(PushDeepLink.resolve(_campaign('cart')), const PushRoute.bergen('/bergen/kurv'));
      expect(PushDeepLink.resolve(_campaign('orders')), const PushRoute.bergen('/bergen/meg/bestillinger'));
      expect(PushDeepLink.resolve(_campaign('profile')), const PushRoute.bergen('/bergen/meg/konto'));
    });

    test('an unknown target falls back to the link, else null', () {
      expect(PushDeepLink.resolve(_campaign('mars', link: 'aerend://cart')), const PushRoute.bergen('/bergen/kurv'));
      expect(PushDeepLink.resolve(_campaign('mars')), isNull);
      expect(PushDeepLink.resolve(_campaign('store')), isNull, reason: 'a store with no id anywhere');
    });

    test('every route the mapping names is registered', () {
      for (final target in ['category', 'store', 'cart', 'orders', 'profile']) {
        final r = PushDeepLink.resolve(_campaign(target, ref: '12', slug: 'mote'))!;
        expect(r.kind, PushRouteKind.bergen);
        expect(BergenRoutes.resolve(r.name!), isNotNull, reason: r.name);
      }
    });
  });

  group('ops deep links', () {
    test('order, feed post, feed and Ægil', () {
      expect(PushDeepLink.resolve({'deep_link': 'aerend://order/381'}), const PushRoute.bergen('/bergen/sporing/381'));
      expect(PushDeepLink.resolve({'deep_link': 'aerend://feed/post/77'}), const PushRoute.post('77'));
      expect(PushDeepLink.resolve({'deep_link': 'aerend://feed'}), const PushRoute.bergen('/bergen/utforsk?tab=feed'));
      expect(PushDeepLink.resolve({'deep_link': 'aerend://aegil'}), const PushRoute.bergen('/bergen/aegil'));
      for (final name in ['/bergen/sporing/381', '/bergen/utforsk?tab=feed', '/bergen/aegil']) {
        expect(BergenRoutes.resolve(name), isNotNull, reason: name);
      }
    });

    test('the store and courier apps\' links are ignored', () {
      expect(PushDeepLink.resolve({'deep_link': 'aerend://partner/drift/4'}), const PushRoute.ignore());
      expect(PushDeepLink.resolve({'deep_link': 'aerend://bud/inntekt'}), const PushRoute.ignore());
    });

    test('an unknown link is null; a payload without a link is not ours', () {
      expect(PushDeepLink.resolve({'deep_link': 'aerend://mars/1'}), isNull);
      expect(PushDeepLink.handles({'deep_link': 'aerend://mars/1'}), isTrue, reason: 'still kept away from the chat');
      expect(PushDeepLink.resolve({'user_id': '5', 'title': 'Kari'}), isNull);
      expect(PushDeepLink.handles({'user_id': '5', 'title': 'Kari'}), isFalse);
      expect(PushDeepLink.handles({'type': 'feed_new_post', 'post_id': '3'}), isFalse);
    });
  });

  group('open ping', () {
    tearDown(() => PushNotificationService.opsApi = OpsCustomerApi.new);

    test('a campaign tap pings «opened», even before the login gate', () async {
      final ops = _Ops();
      PushNotificationService.opsApi = () => ops;

      // Not logged in: the tap goes nowhere, but the open still counts.
      PushNotificationService().handleNotificationClick(_campaign('home', id: '42'), false);
      await Future<void>.delayed(Duration.zero);
      expect(ops.opened, ['42']);
    });

    test('no ping for an ops push or a campaign without an id', () async {
      final ops = _Ops();
      PushNotificationService.opsApi = () => ops;

      expect(PushNotificationService.pingCampaignOpened({'deep_link': 'aerend://order/1'}), isFalse);
      expect(PushNotificationService.pingCampaignOpened(_campaign('home', id: '')), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(ops.opened, isEmpty);
    });

    test('the real call never throws: offline it is just false', () async {
      OpsCustomerApi.networkEnabled = false;
      addTearDown(() => OpsCustomerApi.networkEnabled = true);
      expect(await OpsCustomerApi().pushOpened('42'), isFalse);
      expect(await OpsCustomerApi().pushOpened(''), isFalse);
    });
  });

  group('cold start', () {
    test('with no navigator the route waits for the shell instead of crashing', () async {
      // Logged in, so the tap is routed.
      await prefSetInt(prefUserId, 5);
      await prefSetString(prefAccessToken, 'x');
      await prefSetInt(prefUserVerified, 1);
      PushNotificationService.opsApi = () => _Ops();
      addTearDown(() => PushNotificationService.opsApi = OpsCustomerApi.new);

      // An ops push with a `user_id` and no `notification_type` used to be
      // read as a chat message.
      PushNotificationService().handleNotificationClick(
        {'deep_link': 'aerend://order/381', 'category': 'order', 'notification_id': '9', 'user_id': '5'},
        true,
      );
      expect(PushDeepLink.takePending(), const PushRoute.bergen('/bergen/sporing/381'));
      expect(PushDeepLink.takePending(), isNull, reason: 'taken once');
    });

    test('a held route goes stale', () {
      final t = DateTime(2026, 10, 8, 12);
      PushDeepLink.hold(const PushRoute.swipe(), now: t);
      expect(PushDeepLink.takePending(now: t.add(const Duration(minutes: 6))), isNull);
      PushDeepLink.hold(const PushRoute.swipe(), now: t);
      expect(PushDeepLink.takePending(now: t.add(const Duration(minutes: 1))), const PushRoute.swipe());
    });

    test('an ignored link is never held', () {
      expect(PushNotificationService.openPushRoute(const PushRoute.ignore(), isReplace: true), isFalse);
      expect(PushDeepLink.hasPending, isFalse);
    });
  });
}
