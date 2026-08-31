import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/screens/campaign/models/campaign_order_pojo.dart';
import 'package:aerend_customer/screens/campaign/campaign_repo.dart';

void main() {
  group('A. CampaignMyOrder.fromJson', () {
    test('parses full listMyOrders payload with Chunk 1-3 keys', () {
      final json = {
        'id': 66,
        'order_no': '5460118202624046',
        'campaign_name': 'Fersk fiskekasse',
        'delivery_method': 'pickup',
        'total_pay': 549,
        'club_payout_amount': 44,
        'payment_status': 1,
        'status': 1,
        'distribution_date': '2026-05-24T10:00:00+00:00',
        // Chunk 1-3 additive keys
        'state': 'locked',
        'method_change_fee_nok': 49,
        'method_change_lock_hours': 24,
        'method_change_lock_at': '2026-05-23T10:00:00+00:00',
        'window_start': '2026-05-24T10:00:00+00:00',
        'methods_offered': ['pickup', 'delivery'],
        'club_logo': 'https://example.com/logo.png',
        'team_name': 'Gutter 16',
        'delivery_address': 'Sædalsvegen 118, 5099 Bergen',
        'earned_points': 75,
        'method_change_log': [
          {
            'from': 'pickup',
            'to': 'delivery',
            'changed_at': '2026-05-20T09:00:00+00:00',
            'fee_nok': 49,
            'fee_paid': false
          },
          {
            'from': 'delivery',
            'to': 'pickup',
            'changed_at': '2026-05-19T09:00:00+00:00',
            'fee_nok': 0,
            'fee_paid': true
          },
        ],
      };

      final o = CampaignMyOrder.fromJson(json);
      print('A.full -> state=${o.state} fee=${o.methodChangeFeeNok} '
          'lockHours=${o.methodChangeLockHours} lockAt=${o.methodChangeLockAt} '
          'windowStart=${o.windowStart} methodsOffered=${o.methodsOffered} '
          'earnedPoints=${o.earnedPoints} log=${o.methodChangeLog.length} '
          'canChange=${o.canChangeMethod} isArchived=${o.isArchived}');

      expect(o.state, CampaignPurchaseState.locked);
      expect(o.methodChangeFeeNok, 49);
      expect(o.methodChangeLockHours, 24);
      expect(o.methodChangeLockAt, isNotNull);
      expect(o.methodChangeLockAt!.toUtc(),
          DateTime.utc(2026, 5, 23, 10, 0, 0));
      expect(o.windowStart!.toUtc(), DateTime.utc(2026, 5, 24, 10, 0, 0));
      expect(o.methodsOffered, ['pickup', 'delivery']);
      expect(o.earnedPoints, 75);
      expect(o.clubLogo, 'https://example.com/logo.png');
      expect(o.teamName, 'Gutter 16');
      expect(o.deliveryAddress, 'Sædalsvegen 118, 5099 Bergen');
      expect(o.methodChangeLog.length, 2);
      expect(o.methodChangeLog.first.from, 'pickup');
      expect(o.methodChangeLog.first.feePaid, false);
      expect(o.methodChangeLog[1].feePaid, true);
      expect(o.canChangeMethod, false); // locked
      expect(o.isArchived, false);
    });

    test('OLD payload without new keys still parses (defaults, no crash)', () {
      final json = {
        'id': 1,
        'order_no': '999',
        'delivery_method': 'delivery',
        'total_pay': 100,
        'payment_status': 1,
        'status': 1,
      };
      final o = CampaignMyOrder.fromJson(json);
      print('A.old -> state=${o.state} fee=${o.methodChangeFeeNok} '
          'lockAt=${o.methodChangeLockAt} windowStart=${o.windowStart} '
          'methodsOffered=${o.methodsOffered} log=${o.methodChangeLog.length} '
          'earnedPoints=${o.earnedPoints}');

      expect(o.state, CampaignPurchaseState.unknown);
      expect(o.methodChangeFeeNok, 0);
      expect(o.methodChangeLockHours, isNull);
      expect(o.methodChangeLockAt, isNull);
      expect(o.windowStart, isNull);
      expect(o.methodsOffered, ['pickup', 'delivery']); // default both
      expect(o.methodChangeLog, isEmpty);
      expect(o.earnedPoints, isNull);
    });

    test('earned_points parsed when present (forward-compat)', () {
      final o = CampaignMyOrder.fromJson({
        'id': 2, 'order_no': '2', 'delivery_method': 'pickup',
        'total_pay': 0, 'payment_status': 1, 'status': 1,
        'earned_points': 55,
      });
      print('A.points -> earnedPoints=${o.earnedPoints}');
      expect(o.earnedPoints, 55);
    });

    test('unexpected state string -> unknown', () {
      final o = CampaignMyOrder.fromJson({
        'id': 3, 'order_no': '3', 'delivery_method': 'pickup',
        'total_pay': 0, 'payment_status': 1, 'status': 1, 'state': 'weird',
      });
      expect(o.state, CampaignPurchaseState.unknown);
    });
  });

  group('B. parseChangeMethodResponse', () {
    ChangeMethodResult parse(int code, Map<String, dynamic> data) =>
        parseChangeMethodResponse(code, data,
            targetMethod: 'delivery', fallbackErrorMessage: 'FALLBACK');

    test("result:'changed' -> changed(method)", () {
      final r = parse(200, {
        'status': 1, 'result': 'changed', 'method': 'delivery',
      });
      print('B.changed -> kind=${r.kind} method=${r.newMethod}');
      expect(r.kind, ChangeMethodResultKind.changed);
      expect(r.newMethod, 'delivery');
    });

    test("result:'payment_required' -> paymentRequired(stripe payload)", () {
      final r = parse(200, {
        'status': 1,
        'result': 'payment_required',
        'provider': 'stripe',
        'change_id': 2,
        'payment': {
          'required': true,
          'provider': 'stripe',
          'client_secret': 'pi_123_secret_abc',
          'publishable_key': 'pk_test_xyz',
        },
      });
      print('B.paymentRequired -> kind=${r.kind} provider=${r.provider} '
          'changeId=${r.changeId} isStripe=${r.payment?.isStripe} '
          'clientSecret=${r.payment?.clientSecret}');
      expect(r.kind, ChangeMethodResultKind.paymentRequired);
      expect(r.provider, 'stripe');
      expect(r.changeId, 2);
      expect(r.payment?.clientSecret, 'pi_123_secret_abc');
      expect(r.payment?.publishableKey, 'pk_test_xyz');
      expect(r.payment?.isStripe, true);
    });

    test("422 code:'change_locked' -> locked(lockAt)", () {
      final r = parse(422, {
        'status': 0,
        'code': 'change_locked',
        'method_change_lock_at': '2026-05-23T10:00:00+00:00',
      });
      print('B.locked -> kind=${r.kind} lockAt=${r.lockAt}');
      expect(r.kind, ChangeMethodResultKind.locked);
      expect(r.lockAt!.toUtc(), DateTime.utc(2026, 5, 23, 10, 0, 0));
    });

    test("422 code:'method_not_offered' -> notOffered(offered)", () {
      final r = parse(422, {
        'status': 0,
        'code': 'method_not_offered',
        'methods_offered': ['pickup'],
      });
      print('B.notOffered -> kind=${r.kind} offered=${r.offeredMethods}');
      expect(r.kind, ChangeMethodResultKind.notOffered);
      expect(r.offeredMethods, ['pickup']);
    });

    test("422 code:'no_change' -> noChange", () {
      final r = parse(422, {'status': 0, 'code': 'no_change'});
      expect(r.kind, ChangeMethodResultKind.noChange);
    });

    test("422 code:'address_required' -> error(server message)", () {
      final r = parse(422, {
        'status': 0,
        'code': 'address_required',
        'message': 'A delivery address is required when changing to delivery.',
      });
      expect(r.kind, ChangeMethodResultKind.error);
      expect(r.message, contains('delivery address'));
    });

    test('unexpected -> error(fallback)', () {
      final r = parse(404, {'status': 0, 'message': 'Order not found.'});
      print('B.error -> kind=${r.kind} message=${r.message}');
      expect(r.kind, ChangeMethodResultKind.error);
      expect(r.message, 'Order not found.');
    });
  });

  group('C. isMethodChangeFeeSettled', () {
    test('status 1 alone is not settlement (original order already paid)', () {
      expect(
        isMethodChangeFeeSettled(
          {'status': 1, 'paid': 1, 'payment_status': 1},
          targetMethod: 'delivery',
        ),
        isFalse,
      );
    });

    test('method_change.settled true is success', () {
      expect(
        isMethodChangeFeeSettled(
          {
            'status': 1,
            'paid': 1,
            'method_change': {'settled': true, 'method': 'delivery'},
          },
          targetMethod: 'delivery',
        ),
        isTrue,
      );
    });

    test('pending fee is not success', () {
      expect(
        isMethodChangeFeeSettled(
          {
            'status': 1,
            'paid': 1,
            'delivery_method': 'pickup',
            'method_change': {'settled': false, 'state': 'pending'},
          },
          targetMethod: 'delivery',
        ),
        isFalse,
      );
    });

    test('webhook already flipped delivery_method is success', () {
      expect(
        isMethodChangeFeeSettled(
          {
            'status': 1,
            'paid': 1,
            'delivery_method': 'delivery',
            'method_change': {'settled': true, 'already': true},
          },
          targetMethod: 'delivery',
        ),
        isTrue,
      );
    });

    test('delivery_method match succeeds when method_change is already gone', () {
      expect(
        isMethodChangeFeeSettled(
          {
            'status': 1,
            'paid': 1,
            'delivery_method': 'pickup',
          },
          targetMethod: 'pickup',
        ),
        isTrue,
      );
    });
  });
}
