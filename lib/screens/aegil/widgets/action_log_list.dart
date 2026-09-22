import 'package:flutter/material.dart';

import '../../../data/aegil/against_interest_models.dart';
import '../../../theme/reen_pre_club_theme.dart';

/// "Mens du var borte" — what Ægil did while the customer was away (AGIL-2 Phase 8).
///
/// Thirty days' worth. Short enough to stay readable after a holiday; the 12-month audit
/// lives on the server for the question "why did Ægil do that in March?".
class ActionLogList extends StatelessWidget {
  const ActionLogList({
    super.key,
    required this.actions,
    this.onOpen,
    this.onMarkAllSeen,
  });

  final List<AgentActionItem> actions;
  final void Function(AgentActionItem action)? onOpen;
  final VoidCallback? onMarkAllSeen;

  int get unseen => actions.where((a) => !a.seen).length;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Ægil har ikke gjort noe mens du var borte.',
          key: Key('action-log-empty'),
          style: TextStyle(
            fontSize: 13,
            color: AerendBergenAuthTokens.textSoft,
          ),
        ),
      );
    }

    return Column(
      key: const Key('action-log'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'MENS DU VAR BORTE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ),
              ),
              if (unseen > 0 && onMarkAllSeen != null)
                TextButton(
                  key: const Key('action-log-mark-seen'),
                  onPressed: onMarkAllSeen,
                  child: const Text(
                    'Merk som lest',
                    style: TextStyle(
                      fontSize: 12,
                      color: AerendBergenAuthTokens.textSoft,
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final action in actions)
          ListTile(
            key: Key('action-log-item-${action.id}'),
            dense: true,
            leading: Icon(
              action.seen ? Icons.check_circle_outline : Icons.circle,
              size: action.seen ? 15 : 9,
              color: action.seen
                  ? AerendBergenAuthTokens.textMuted
                  : AerendBergenAuthTokens.mint,
            ),
            title: Text(
              action.summary,
              style: const TextStyle(
                fontSize: 13,
                color: AerendBergenAuthTokens.ink,
              ),
            ),
            subtitle: action.createdAt == null
                ? null
                : Text(
                    '${action.createdAt!.day}.${action.createdAt!.month}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AerendBergenAuthTokens.textMuted,
                    ),
                  ),
            trailing: action.deepLink == null
                ? null
                : const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
            onTap: action.deepLink == null || onOpen == null
                ? null
                : () => onOpen!(action),
          ),
      ],
    );
  }
}

/// The reminders card: what Ægil is waiting to tell the customer about.
class RemindersCard extends StatelessWidget {
  const RemindersCard({super.key, required this.reminders, this.onCancel});

  final List<AgentReminderItem> reminders;
  final void Function(AgentReminderItem reminder)? onCancel;

  List<AgentReminderItem> get _active =>
      reminders.where((r) => r.isActive).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('reminders-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÆGIL SIER FRA NÅR',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (final reminder in _active)
            Padding(
              key: Key('reminder-${reminder.id}'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reminder.productName ?? 'En vare',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AerendBergenAuthTokens.ink,
                      ),
                    ),
                  ),
                  if (reminder.targetPriceOre != null)
                    Text(
                      'under ${(reminder.targetPriceOre! / 100).round()} kr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AerendBergenAuthTokens.textSoft,
                      ),
                    ),
                  if (onCancel != null)
                    IconButton(
                      key: Key('reminder-cancel-${reminder.id}'),
                      icon: const Icon(
                        Icons.close,
                        size: 15,
                        color: AerendBergenAuthTokens.textMuted,
                      ),
                      onPressed: () => onCancel!(reminder),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
