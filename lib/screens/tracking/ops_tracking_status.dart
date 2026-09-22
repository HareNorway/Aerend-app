import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Customer-facing order status and the promised *window*
/// (Order Ops §5.4 / §7; Kunde design tracking screen).
///
/// The window is the point. We never show a single ETA, because a point-in-time
/// promise is a promise we break: the honest thing is a range plus how confident
/// we are in it. When a store adds time, the customer is told that in plain
/// words rather than watching a number silently slide.
class OpsTrackingStatus {
  const OpsTrackingStatus({
    required this.state,
    this.promisedStart,
    this.promisedEnd,
    this.adjustedByMinutes,
  });

  static const String placed = 'placed';
  static const String accepted = 'accepted';
  static const String seen = 'seen';
  static const String ready = 'ready';
  static const String pickedUp = 'picked_up';
  static const String arrivedCustomer = 'arrived_customer';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  final String state;
  final DateTime? promisedStart;
  final DateTime? promisedEnd;

  /// Set when the store pushed the window out; drives the honest copy.
  final int? adjustedByMinutes;

  bool get hasWindow => promisedStart != null && promisedEnd != null;

  /// Localised status label for this state — the shared vocabulary, so the
  /// customer app can never drift from what the store and courier are shown.
  String label(AppLocalizations l10n) {
    switch (state) {
      case placed:
        return l10n.ops_status_placed_customer;
      case accepted:
        return l10n.ops_status_accepted_customer;
      case seen:
        return l10n.ops_status_seen_customer;
      case ready:
        return l10n.ops_status_ready_customer;
      case pickedUp:
        return l10n.ops_status_picked_up_customer;
      case arrivedCustomer:
        return l10n.ops_status_arrived_customer_customer;
      case delivered:
        return l10n.ops_status_delivered_customer;
      case cancelled:
        return l10n.ops_status_cancelled_customer;
      default:
        return l10n.ops_status_unknown;
    }
  }

  String windowText() {
    if (!hasWindow) {
      return '';
    }

    return '${_hhmm(promisedStart!)}–${_hhmm(promisedEnd!)}';
  }

  static String _hhmm(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

/// The tracking card: status word, window, and the extra-time line when the
/// store has pushed the estimate out.
class OpsTrackingCard extends StatelessWidget {
  const OpsTrackingCard({super.key, required this.status});

  final OpsTrackingStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      key: const Key('ops-tracking-card'),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              status.label(l10n),
              key: const Key('ops-tracking-status'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (status.hasWindow) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                status.windowText(),
                key: const Key('ops-tracking-window'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vi viser et tidsrom, ikke et klokkeslett — det er mer ærlig.',
                key: Key('ops-tracking-window-note'),
                style: TextStyle(fontSize: 12),
              ),
            ],
            if (status.adjustedByMinutes != null && status.adjustedByMinutes! > 0) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Butikken trenger ${status.adjustedByMinutes} min ekstra',
                key: const Key('ops-tracking-extra-time'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
