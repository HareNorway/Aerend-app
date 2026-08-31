import 'package:intl/intl.dart';

import '../../utils/utils.dart';
import 'models/campaign_order_pojo.dart';

/// Server-state `awaiting|locked` — never re-derived from dates.
List<CampaignMyOrder> campaignActiveOrders(Iterable<CampaignMyOrder> orders) =>
    orders.where((o) => o.isActiveLifecycle).toList();

/// Server-state `archived`.
List<CampaignMyOrder> campaignArchivedOrders(Iterable<CampaignMyOrder> orders) =>
    orders.where((o) => o.isArchived).toList();

int campaignArchivePointsSum(Iterable<CampaignMyOrder> orders) =>
    orders.fold(0, (sum, o) => sum + (o.earnedPoints ?? 0));

class CampaignDistributionSchedule {
  final String dateLabel;
  final String? timeLabel;

  const CampaignDistributionSchedule({
    required this.dateLabel,
    this.timeLabel,
  });

  static CampaignDistributionSchedule fromIso(String? iso) {
    if (iso == null || iso.trim().isEmpty) {
      return const CampaignDistributionSchedule(dateLabel: '');
    }
    try {
      final dt = DateTime.parse(iso).toLocal();
      final date = DateFormat.yMMMMd(languages.localeName).format(dt);
      String? time;
      if (dt.hour != 0 || dt.minute != 0) {
        time = DateFormat('HH:mm', languages.localeName).format(dt);
      }
      return CampaignDistributionSchedule(dateLabel: date, timeLabel: time);
    } catch (_) {
      return CampaignDistributionSchedule(dateLabel: iso);
    }
  }

  String get pickupLine {
    if (dateLabel.isEmpty) return '';
    if (timeLabel == null || timeLabel!.isEmpty) {
      return languages.campaignPickupOnDate(dateLabel);
    }
    return languages.campaignPickupOnDateTime(dateLabel, timeLabel!);
  }

  String get deliveryLine {
    if (dateLabel.isEmpty) return '';
    return languages.campaignDeliveredOn(dateLabel);
  }
}

/// Numeric NOK for copy that already includes `kr` (`campaignChangeFee`).
String campaignKrNumber(num amount) {
  if (amount == amount.roundToDouble()) {
    return '${amount.round()}';
  }
  final whole = amount.truncate();
  final frac = ((amount - whole) * 100).round().abs().toString().padLeft(2, '0');
  return '$whole,$frac';
}

/// NOK amount for campaign-purchase receipts (`749 kr`).
String campaignKr(num amount) => '${campaignKrNumber(amount)} kr';

/// Wall-clock day from an ISO instant. Uses the device local zone — no extra
/// timezone math (the server sends a zoned ISO string).
String campaignDayLabel(DateTime? instant, {String? locale}) {
  if (instant == null) return '';
  final loc = locale ?? languages.localeName;
  return DateFormat('d. MMMM y', loc).format(instant.toLocal());
}

/// Single window time (`kl. 16:00`). The server has one datetime, not a range.
String campaignClockLabel(DateTime? instant, {String? locale}) {
  if (instant == null) return '';
  final loc = locale ?? languages.localeName;
  return 'kl. ${DateFormat('HH:mm', loc).format(instant.toLocal())}';
}

/// Prototype `fmtLockAt`: `23. mai kl. 11:00` (day + month, then `kl.` time).
String campaignLockAtLabel(DateTime? instant, {String? locale}) {
  if (instant == null) return '';
  final loc = locale ?? languages.localeName;
  final local = instant.toLocal();
  final day = DateFormat('d. MMMM', loc).format(local);
  final clock = DateFormat('HH:mm', loc).format(local);
  return '$day kl. $clock';
}

/// Splits a saved delivery address into a title line and subtitle line.
({String title, String subtitle}) splitSavedAddress(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return (title: '', subtitle: '');
  }

  final parts = trimmed
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return (title: trimmed, subtitle: '');
  }
  if (parts.length == 1) {
    return (title: parts.first, subtitle: '');
  }

  final title = parts.first;
  final subtitle = parts.sublist(1).join(', ');
  return (title: title, subtitle: subtitle);
}
