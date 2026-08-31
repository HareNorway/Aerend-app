import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import 'career_screen.dart';
import 'dugnad_missions_screen.dart';
import 'dugnad_models.dart';
import 'dugnad_points_screen.dart';
import 'kampanje_screen.dart';
import 'leaderboard_screen.dart';
import 'supporter_card_screen.dart';

/// Deep-link targets for in-app notification taps (keys from admin catalogue).
void openDugnadNotificationDeepLink(
  BuildContext context,
  DugnadNotificationItem item,
) {
  final key = (item.deepLinkKey ?? '').trim();
  if (key.isEmpty) return;

  switch (key) {
    case 'points':
      openScreen(context, const DugnadPointsScreen());
      return;
    case 'sto_card':
      openScreen(context, const SupporterCardScreen());
      return;
    case 'badges':
      openScreen(context, const DugnadPointsScreen());
      return;
    case 'career':
      openScreen(context, const CareerScreen());
      return;
    case 'campaign':
      final home = context.findAncestorStateOfType<HomeMainV1State>();
      if (home != null) {
        Navigator.maybePop(context);
        home.switchToTab(HomeMainV1State.dugnadKampanjeTabIndex);
      } else {
        openScreen(context, const KampanjeScreen());
      }
      return;
    case 'leaderboard':
      final home = context.findAncestorStateOfType<HomeMainV1State>();
      if (home != null) {
        Navigator.maybePop(context);
        home.switchToTab(HomeMainV1State.dugnadLeaderboardTabIndex);
      } else {
        openScreen(context, const LeaderboardScreen());
      }
      return;
    case 'missions':
      openScreen(context, const DugnadMissionsScreen());
      return;
    case 'friends':
      // No dedicated friends screen yet — land on points/referral context.
      openScreen(context, const DugnadPointsScreen());
      return;
    default:
      return;
  }
}
