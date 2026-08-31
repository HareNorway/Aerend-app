import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../celebration_debug_flags.dart';
import '../celebration_models.dart';
import '../dugnad_celebration_orchestrator.dart';
import '../dugnad_t1_controller.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';

/// Temporary dev panel — trigger celebration tweaks from home for UI testing.
class CelebrationDebugPanel extends StatelessWidget {
  const CelebrationDebugPanel({super.key});

  static final _types = <CelebrationType>[
    CelebrationType.t2,
    CelebrationType.t3,
    CelebrationType.t4,
    CelebrationType.t5a,
    CelebrationType.t5b,
    CelebrationType.t6,
    CelebrationType.t7,
    CelebrationType.t8,
    CelebrationType.t9,
    CelebrationType.t10,
    CelebrationType.t11,
    CelebrationType.t12,
    CelebrationType.t13,
    CelebrationType.t14,
    CelebrationType.t15,
    CelebrationType.t16,
  ];

  Future<void> _triggerT1(BuildContext context) async {
    final clubId = DugnadState.instance.clubId;
    if (clubId <= 0) {
      openSimpleSnackbar('Velg klubb først');
      return;
    }
    await DugnadT1Controller.instance.debugPulse(delta: 55);
  }

  Future<void> _trigger(BuildContext context, CelebrationType type) =>
      trigger(context, type);

  /// Shared by the home chip panel and other debug entry points (e.g. STØ-kort).
  static Future<void> trigger(
    BuildContext context,
    CelebrationType type,
  ) async {
    final clubId = DugnadState.instance.clubId;
    if (clubId <= 0) {
      openSimpleSnackbar('Velg klubb først');
      return;
    }

    if (CelebrationDebugFlags.alsoCallDevApi) {
      unawaited(
        DugnadRepo().triggerDevCelebration(typeKey: type.apiKey, clubId: clubId),
      );
    }

    DugnadCelebrationOrchestrator.instance.debugEnqueue(
      _localSample(type, clubId),
    );
  }

  static int _t4Variant = 0;

  Future<void> _clearQueue(BuildContext context) async {
    await DugnadCelebrationOrchestrator.instance.debugClearAll();
    if (context.mounted) {
      openSimpleSnackbar('Feiring-kø tømt');
    }
  }

  static PendingCelebration _localSample(CelebrationType type, int clubId) {
    final teamName = DugnadState.instance.pointsTeamName.isNotEmpty
        ? DugnadState.instance.pointsTeamName
        : 'Gutter 16';
    final clubName = DugnadState.instance.clubName.isNotEmpty
        ? DugnadState.instance.clubName
        : 'Klubb';
    const seasonLabel = 'Sesong 25/26';

    final payload = switch (type) {
      CelebrationType.t2 => {
          'badge_key': 'sesongambassador',
          'badge_name': 'Sesongambassadør',
          'icon': 'shield',
          'tone': 'gold',
          'points_bonus': 6,
          'sto_bonus': 6,
        },
      CelebrationType.t3 => {
          'kind': 'weekly_challenge',
          'title': 'Logg inn 5 dager',
          'description': 'Du var innom hver dag denne uken',
          'reward_points': 30,
        },
      CelebrationType.t4 => () {
          const variants = ['up', 'flat', 'down'];
          const previous = ['flat', 'up', 'flat'];
          const values = [72, 60, 48];
          final i = _t4Variant % variants.length;
          _t4Variant++;
          return {
            'new_state': variants[i],
            'previous_state': previous[i],
            'form_value': values[i],
          };
        }(),
      CelebrationType.t5a => {
          'team_name': teamName,
          'rank': 1,
          'season_label': seasonLabel,
        },
      CelebrationType.t5b => {
          'team_name': teamName,
          'rank': 3,
          'position': 3,
          'prize_zone_size': 3,
          'season_label': seasonLabel,
        },
      CelebrationType.t6 => {
          'metric': 'sto',
          'value': 84,
          'display_name': 'Didrik',
        },
      CelebrationType.t7 => {
          'metric': 'goals',
          'value': 6,
          'display_name': 'Didrik Eide',
          'season_label': seasonLabel,
        },
      CelebrationType.t8 => {
          'metric': 'assists',
          'value': 3,
          'display_name': 'Didrik Eide',
          'season_label': seasonLabel,
        },
      CelebrationType.t9 => {
          'team_name': teamName,
          'final_position': 1,
          'season_label': seasonLabel,
          'club_logo_url': DugnadState.instance.clubLogo,
        },
      CelebrationType.t10 => {
          'title': 'top_scorer',
          'value': 6,
          'season_label': seasonLabel,
          'display_name': 'Didrik Eide',
        },
      CelebrationType.t11 => {
          'title': 'assist_king',
          'value': 3,
          'season_label': seasonLabel,
          'display_name': 'Didrik Eide',
        },
      CelebrationType.t12 => {
          'title': 'highest_sto',
          'value': 84,
          'season_label': seasonLabel,
          'display_name': 'Didrik Eide',
        },
      CelebrationType.t13 => {
          'team_name': teamName,
          'season_label': seasonLabel,
        },
      CelebrationType.t14 => {
          'club_name': clubName,
          'club_logo_url': DugnadState.instance.clubLogo,
        },
      CelebrationType.t15 => {
          'team_name': teamName,
          'final_position': 3,
          'season_label': seasonLabel,
          'club_logo_url': DugnadState.instance.clubLogo,
        },
      CelebrationType.t16 => {
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
      _ => <String, dynamic>{},
    };

    return PendingCelebration(
      id: 0,
      type: type,
      clubId: clubId,
      payload: payload,
      priority: type.priority,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !CelebrationDebugFlags.showPanel) {
      return const SizedBox.shrink();
    }

    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.all(context.dp(12)),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DEV · Feiringer',
                  style: aeLabel(color: theme.ink).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _clearQueue(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: context.dp(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Tøm kø',
                  style: aeLabel(color: theme.primary).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(8)),
          Wrap(
            spacing: context.dp(6),
            runSpacing: context.dp(6),
            children: [
              ActionChip(
                label: Text(
                  'T1',
                  style: aeLabel(color: theme.ink).copyWith(fontSize: 11),
                ),
                onPressed: () => _triggerT1(context),
                backgroundColor: Colors.white,
                side: BorderSide(color: theme.primary.withValues(alpha: 0.25)),
              ),
              for (final type in _types)
                ActionChip(
                  label: Text(
                    type.apiKey,
                    style: aeLabel(color: theme.ink).copyWith(fontSize: 11),
                  ),
                  onPressed: () => _trigger(context, type),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: theme.primary.withValues(alpha: 0.25)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
