import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/dugnad/celebration_models.dart';

void main() {
  PendingCelebration item({
    required int id,
    required String type,
    DateTime? created,
    Map<String, dynamic>? payload,
    String? consumed,
  }) {
    return PendingCelebration.fromJson({
      'id': id,
      'type_key': type,
      'club_id': 1,
      'payload': payload ?? {'x': 1},
      'created_at': (created ?? DateTime(2026, 1, 1)).toIso8601String(),
      'consumed_at': consumed,
    });
  }

  test('parses every payload shape without throwing', () {
    final fixtures = <Map<String, dynamic>>[
      {
        'id': 1,
        'type_key': 'T2',
        'club_id': 9,
        'payload': {
          'badge_key': 'ildsjel',
          'badge_name': 'Ildsjel',
          'image_url': null,
          'points_bonus': 25,
        },
      },
      {
        'id': 2,
        'type_key': 'T3',
        'payload': {
          'kind': 'weekly_challenge',
          'title': 'Ti kampanjekjøp',
          'reward_points': 50,
          'badge_key': null,
        },
      },
      {
        'id': 3,
        'type_key': 'T4',
        'payload': {
          'new_state': 'up',
          'previous_state': 'flat',
          'form_value': 72,
        },
      },
      {
        'id': 4,
        'type_key': 'T5a',
        'payload': {
          'team_id': 1,
          'team_name': 'Gutter 14',
          'position': 1,
          'club_name': 'Fana',
          'club_logo_url': 'https://example.com/logo.png',
        },
      },
      {
        'id': 5,
        'type_key': 'T6',
        'payload': {
          'metric': 'sto',
          'value': 99,
          'user_name': 'Ada',
          'club_name': 'Fana',
        },
      },
      {
        'id': 6,
        'type_key': 'T9',
        'payload': {
          'team_id': 1,
          'team_name': 'Gutter 14',
          'final_position': 1,
          'season_label': 'Sesong 25/26',
          'club_logo_url': '',
        },
      },
      {
        'id': 7,
        'type_key': 'T10',
        'payload': {
          'title': 'top_scorer',
          'value': 12,
          'season_label': 'Sesong 25/26',
          'user_name': 'Ada',
        },
      },
      {
        'id': 8,
        'type_key': 'T13',
        'payload': {'team_id': 1, 'team_name': 'Gutter 14'},
      },
      {
        'id': 9,
        'type_key': 'T14',
        'payload': {
          'club_id': 1,
          'club_name': 'Sædalen IL',
          'club_logo_url': null,
        },
      },
      {
        'id': 10,
        'type_key': 'T15',
        'payload': {'final_position': 2, 'team_name': 'Gutter 14'},
      },
      {
        'id': 12,
        'type_key': 'T16',
        'payload': {
          'previous_sto': 55,
          'new_sto': 57,
          'delta': 2,
          'metal': 'bronse',
          'next_metal': 'solv',
          'next_metal_label': 'Sølv',
          'remaining_to_next': 27,
          'progress_percent': 35,
          'previous_progress_percent': 28,
          'action': 'campaign_purchase',
        },
      },
      {
        'id': 11,
        'type_key': 'UNKNOWN_FUTURE',
        'payload': {'extra': true, 'nested': {'ok': 1}},
      },
    ];

    for (final json in fixtures) {
      final parsed = PendingCelebration.fromJson(json);
      expect(parsed.id, json['id']);
      expect(parsed.payload, isA<Map<String, dynamic>>());
    }
  });

  test('priority order matches spec §6', () {
    final mixed = [
      item(id: 1, type: 'T4', created: DateTime(2026, 1, 2)),
      item(id: 2, type: 'T2', created: DateTime(2026, 1, 1)),
      item(id: 3, type: 'T14', created: DateTime(2026, 1, 3)),
      item(id: 4, type: 'T13', created: DateTime(2026, 1, 1)),
      item(id: 5, type: 'T9', created: DateTime(2026, 1, 1)),
      item(id: 6, type: 'T3', created: DateTime(2026, 1, 1)),
      item(id: 7, type: 'T1', created: DateTime(2026, 1, 1)),
    ];
    final sorted = sortCelebrationsByPriority(mixed);
    expect(sorted.map((e) => e.type.apiKey).toList(), [
      'T14',
      'T13',
      'T9',
      'T2',
      'T3',
      'T4',
    ]);
  });

  test('collapseTransitionDuplicates keeps newest T14 and T13', () {
    final mixed = [
      item(id: 1, type: 'T14', created: DateTime(2026, 1, 1)),
      item(id: 2, type: 'T14', created: DateTime(2026, 1, 2)),
      item(id: 3, type: 'T13', created: DateTime(2026, 1, 1)),
      item(id: 4, type: 'T13', created: DateTime(2026, 1, 3)),
      item(id: 5, type: 'T2', created: DateTime(2026, 1, 1)),
    ];
    final collapsed = collapseTransitionDuplicates(mixed);
    expect(collapsed.map((e) => e.id).toList(), [2, 4, 5]);
  });

  test('session cap keeps remainder pending', () {
    final items = [
      item(id: 1, type: 'T2'),
      item(id: 2, type: 'T3'),
      item(id: 3, type: 'T4'),
      item(id: 4, type: 'T6'),
    ];
    final sorted = sortCelebrationsByPriority(items);
    const cap = 3;
    final showNow = sorted.take(cap).toList();
    final remainder = sorted.skip(cap).toList();
    expect(showNow.length, 3);
    expect(remainder.single.type, CelebrationType.t4);
  });

  test('consumed rows are dropped from the queue', () {
    final items = [
      item(id: 1, type: 'T2', consumed: DateTime(2026, 1, 2).toIso8601String()),
      item(id: 2, type: 'T14'),
    ];
    final sorted = sortCelebrationsByPriority(items);
    expect(sorted.map((e) => e.id), [2]);
  });

  test('celebration config parses tweaks and defaults', () {
    final cfg = CelebrationConfig.fromJson({
      'session_cap': 5,
      'form_flap_hours': 12,
      'tweaks': {'T2': true, 'T4': false},
    });
    expect(cfg.sessionCap, 5);
    expect(cfg.formFlapHours, 12);
    expect(cfg.isTweakEnabled(CelebrationType.t2), isTrue);
    expect(cfg.isTweakEnabled(CelebrationType.t4), isFalse);
    expect(CelebrationConfig.fromJson(null).sessionCap, 3);
  });

  test('presentation maps T13 and T14 to fullscreen ceremonial', () {
    expect(
      CelebrationType.t13.presentation,
      CelebrationPresentation.fullscreenCeremonial,
    );
    expect(
      CelebrationType.t14.presentation,
      CelebrationPresentation.fullscreenCeremonial,
    );
    expect(
      CelebrationType.t5a.presentation,
      CelebrationPresentation.modal,
    );
    expect(
      CelebrationType.t9.presentation,
      CelebrationPresentation.fullscreenCeremonial,
    );
    expect(
      CelebrationType.t16.presentation,
      CelebrationPresentation.modal,
    );
    expect(CelebrationType.t16.priority, 45);
    expect(CelebrationType.fromApi('T16'), CelebrationType.t16);
  });

  test('collapseTransitionDuplicates merges T16 into one STØ jump', () {
    final mixed = [
      item(
        id: 1,
        type: 'T16',
        payload: {
          'previous_sto': 55,
          'new_sto': 57,
          'delta': 2,
          'metal': 'bronse',
        },
      ),
      item(
        id: 2,
        type: 'T16',
        payload: {
          'previous_sto': 57,
          'new_sto': 59,
          'delta': 2,
          'metal': 'bronse',
          'action': 'campaign_purchase',
        },
      ),
      item(id: 3, type: 'T2'),
    ];
    final collapsed = collapseTransitionDuplicates(mixed);
    final t16 = collapsed.firstWhere((e) => e.type == CelebrationType.t16);
    expect(t16.id, 2);
    expect(t16.intPayload('previous_sto'), 55);
    expect(t16.intPayload('new_sto'), 59);
    expect(t16.intPayload('delta'), 4);
    expect(collapsed.where((e) => e.type == CelebrationType.t16).length, 1);
  });
}
