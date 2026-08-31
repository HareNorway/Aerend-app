import '../../common/base_dl.dart';

/// Response from POST /api/customer/campaign/place-order
class CampaignPlaceOrderPojo extends BaseModel {
  CampaignOrderInfo? order;
  CampaignPaymentInfo? payment;

  CampaignPlaceOrderPojo.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json['order'] != null) {
      order = CampaignOrderInfo.fromJson(json['order']);
    }
    if (json['payment'] != null) {
      payment = CampaignPaymentInfo.fromJson(json['payment']);
    }
  }
}

class CampaignOrderInfo {
  int id;
  String orderNo;
  double totalPay;
  String paymentProvider;

  /// Club share in øre (integer). Null if no club. Divide by 100 for NOK.
  int? clubShareAmount;
  String? clubName;
  String? clubLogo;
  int? teamId;
  String? teamName;
  String? teamLogo;

  CampaignOrderInfo({
    required this.id,
    required this.orderNo,
    required this.totalPay,
    required this.paymentProvider,
    this.clubShareAmount,
    this.clubName,
    this.clubLogo,
    this.teamId,
    this.teamName,
    this.teamLogo,
  });

  factory CampaignOrderInfo.fromJson(Map<String, dynamic> json) {
    return CampaignOrderInfo(
      id: json['id'] ?? 0,
      orderNo: (json['order_no'] ?? '').toString(),
      totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0,
      paymentProvider: json['payment_provider'] ?? '',
      clubShareAmount: (json['club_share_amount'] as num?)?.toInt(),
      clubName: json['club_name'] as String?,
      clubLogo: json['club_logo'] as String?,
      teamId: (json['team_id'] as num?)?.toInt(),
      teamName: json['team_name'] as String?,
      teamLogo: json['team_logo'] as String?,
    );
  }

  /// Club share in NOK formatted with Norwegian comma decimal (e.g. "49,90").
  String? get clubShareNokFormatted {
    if (clubShareAmount == null || clubShareAmount! <= 0) return null;
    final nok = clubShareAmount! / 100;
    // Norwegian format: comma for decimal
    final whole = nok.truncate();
    final frac = ((nok - whole) * 100).round().toString().padLeft(2, '0');
    return '$whole,$frac';
  }
}

class CampaignPaymentInfo {
  bool required_;
  String provider;
  String? clientSecret;
  String? publishableKey;
  String? redirectUrl;

  CampaignPaymentInfo({
    required this.required_,
    required this.provider,
    this.clientSecret,
    this.publishableKey,
    this.redirectUrl,
  });

  factory CampaignPaymentInfo.fromJson(Map<String, dynamic> json) {
    return CampaignPaymentInfo(
      required_: json['required'] == true,
      provider: json['provider'] ?? '',
      clientSecret: json['client_secret'],
      publishableKey: json['publishable_key'],
      redirectUrl: json['redirect_url'],
    );
  }

  bool get isStripe => provider == 'stripe';
  bool get isVipps => provider == 'vipps';
}

/// Server-authoritative purchase lifecycle (Chunk 1). `unknown` for anything
/// unexpected so old/newer server strings never crash the client.
enum CampaignPurchaseState { awaiting, locked, archived, unknown }

CampaignPurchaseState campaignPurchaseStateFromString(String? value) {
  switch (value) {
    case 'awaiting':
      return CampaignPurchaseState.awaiting;
    case 'locked':
      return CampaignPurchaseState.locked;
    case 'archived':
      return CampaignPurchaseState.archived;
    default:
      return CampaignPurchaseState.unknown;
  }
}

/// One row of a campaign order's delivery method-change history (Chunk 2).
class MethodChangeLogEntry {
  final String from;
  final String to;
  final DateTime? changedAt;
  final double feeNok;
  final bool feePaid;

  MethodChangeLogEntry({
    required this.from,
    required this.to,
    this.changedAt,
    this.feeNok = 0,
    this.feePaid = false,
  });

  factory MethodChangeLogEntry.fromJson(Map<String, dynamic> json) {
    return MethodChangeLogEntry(
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      // Parse faithfully; NO timezone math (display-time tz handling is Chunk 5).
      changedAt: json['changed_at'] != null
          ? DateTime.tryParse(json['changed_at'].toString())
          : null,
      feeNok: (json['fee_nok'] as num?)?.toDouble() ?? 0,
      feePaid: json['fee_paid'] == true,
    );
  }
}

/// Response from POST /api/customer/campaign/orders
class CampaignMyOrdersListPojo extends BaseModel {
  List<CampaignMyOrder>? _orders;

  List<CampaignMyOrder> get orders => _orders ?? [];

  CampaignMyOrdersListPojo.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json['orders'] != null) {
      _orders = (json['orders'] as List)
          .map((e) => CampaignMyOrder.fromJson(e))
          .toList();
    }
  }
}

class CampaignMyOrder {
  int id;
  String orderNo;
  String? campaignName;
  String? campaignSlug;
  String? clubName;
  String? clubLogo;
  String? teamName;
  String? teamLogo;
  String? distributionDate;
  String? distributionLocation;
  String? deliveryAddress;
  String deliveryMethod;
  double totalPay;
  double clubPayoutAmount;
  String? paymentProvider;
  int paymentStatus;
  int status;
  String? productSummary;
  String? createdAt;

  // --- Chunk 1–3 additive fields (all nullable/defaulted) ---
  /// Derived delivery lifecycle state from the server (Chunk 1).
  CampaignPurchaseState state;

  /// Flat method-change fee for this campaign in NOK (Chunk 1).
  double methodChangeFeeNok;

  /// Effective hours-before-window that method changes lock (Chunk 1).
  int? methodChangeLockHours;

  /// Instant method changes lock. Parsed faithfully — NO timezone math (Chunk 5).
  DateTime? methodChangeLockAt;

  /// Delivery/pickup window start. Parsed faithfully — NO timezone math (Chunk 5).
  DateTime? windowStart;

  /// Methods this campaign offers (Chunk 3). Defaults to both for old payloads.
  List<String> methodsOffered;

  /// Per-order earned points, IF the server exposes it (forward-compat). Else null.
  int? earnedPoints;

  /// Delivery method-change history, newest-first (Chunk 2).
  List<MethodChangeLogEntry> methodChangeLog;

  CampaignMyOrder({
    required this.id,
    required this.orderNo,
    this.campaignName,
    this.campaignSlug,
    this.clubName,
    this.clubLogo,
    this.teamName,
    this.teamLogo,
    this.distributionDate,
    this.distributionLocation,
    this.deliveryAddress,
    required this.deliveryMethod,
    required this.totalPay,
    this.clubPayoutAmount = 0,
    this.paymentProvider,
    required this.paymentStatus,
    required this.status,
    this.productSummary,
    this.createdAt,
    this.state = CampaignPurchaseState.unknown,
    this.methodChangeFeeNok = 0,
    this.methodChangeLockHours,
    this.methodChangeLockAt,
    this.windowStart,
    this.methodsOffered = const ['pickup', 'delivery'],
    this.earnedPoints,
    this.methodChangeLog = const [],
  });

  factory CampaignMyOrder.fromJson(Map<String, dynamic> json) {
    return CampaignMyOrder(
      id: json['id'] ?? 0,
      orderNo: (json['order_no'] ?? '').toString(),
      campaignName: json['campaign_name'],
      campaignSlug: json['campaign_slug'],
      clubName: json['club_name'],
      clubLogo: json['club_logo'] as String?,
      teamName: json['team_name'] as String?,
      teamLogo: json['team_logo'] as String?,
      distributionDate: json['distribution_date'],
      distributionLocation: json['distribution_location'],
      deliveryAddress: json['delivery_address'] as String?,
      deliveryMethod: json['delivery_method'] ?? 'pickup',
      totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0,
      clubPayoutAmount: (json['club_payout_amount'] as num?)?.toDouble() ?? 0,
      paymentProvider: json['payment_provider'],
      paymentStatus: json['payment_status'] ?? 0,
      status: json['status'] ?? 0,
      productSummary: json['product_summary'],
      createdAt: json['created_at'],
      state: campaignPurchaseStateFromString(json['state'] as String?),
      methodChangeFeeNok: (json['method_change_fee_nok'] as num?)?.toDouble() ?? 0,
      methodChangeLockHours: (json['method_change_lock_hours'] as num?)?.toInt(),
      methodChangeLockAt: json['method_change_lock_at'] != null
          ? DateTime.tryParse(json['method_change_lock_at'].toString())
          : null,
      windowStart: json['window_start'] != null
          ? DateTime.tryParse(json['window_start'].toString())
          : null,
      methodsOffered: json['methods_offered'] is List
          ? (json['methods_offered'] as List).map((e) => e.toString()).toList()
          : const ['pickup', 'delivery'],
      // Ledger points from listMyOrders (`earned_points`). Never invent a value.
      earnedPoints: (json['earned_points'] as num?)?.toInt() ??
          (json['points'] as num?)?.toInt(),
      methodChangeLog: json['method_change_log'] is List
          ? (json['method_change_log'] as List)
              .map((e) => MethodChangeLogEntry.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }

  /// Current method comes from the existing [deliveryMethod] mapping (not duplicated).
  bool get canChangeMethod => state == CampaignPurchaseState.awaiting;
  bool get isArchived => state == CampaignPurchaseState.archived;
  bool get isActiveLifecycle =>
      state == CampaignPurchaseState.awaiting ||
      state == CampaignPurchaseState.locked;
  bool get isPickup => deliveryMethod == 'pickup';
  String get otherMethod => isPickup ? 'delivery' : 'pickup';
  bool get otherMethodOffered => methodsOffered.contains(otherMethod);
  bool get hasPendingMethodChange =>
      methodChangeLog.any((e) => !e.feePaid && e.feeNok > 0);

  DateTime? get boughtAt {
    if (createdAt == null) return null;
    return DateTime.tryParse(createdAt!);
  }

  DateTime? get windowInstant =>
      windowStart ??
      (distributionDate != null ? DateTime.tryParse(distributionDate!) : null);

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 1:
        return 'Betalt';
      case 2:
        return 'Mislykket';
      default:
        return 'Venter';
    }
  }
}
