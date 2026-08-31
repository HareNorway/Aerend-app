import 'package:flutter/material.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../account/settings_design_kit.dart';
import 'notifications_dl.dart';

/// Notification row in the design's card language — white shadow-card
/// (`.dgx-city` geometry: radius 16, padding 14, 38px lavender icon chip),
/// `.dgs-list .row .tx` type scale for the title/body.
class ItemNotifications extends StatelessWidget {
  final MassNotificationItem massNotificationItem;

  const ItemNotifications({required this.massNotificationItem, super.key});

  @override
  Widget build(BuildContext context) {
    final title = massNotificationItem.title.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 19,
              color: ScSaasThemeTokens.primaryHover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(title, style: dgText(14.5, FontWeight.w800)),
                  ),
                Text(
                  massNotificationItem.message,
                  style: dgText(
                    12.5,
                    FontWeight.w600,
                    height: 1.4,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    timeAgo(getTimeAndDateObj(massNotificationItem.datetime)),
                    style: dgText(
                      11,
                      FontWeight.w700,
                      color: kDgGray400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
