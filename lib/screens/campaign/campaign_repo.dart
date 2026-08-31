import '../../networking/api_base_helper.dart';
import '../../utils/utils.dart';
import 'models/campaign_order_pojo.dart';

/// Typed outcome of [CampaignRepo.changeMethod]. Enum-tagged (the repo has no
/// existing sealed-result pattern — other methods return raw `dynamic`), so this
/// gives the (future) UI a single value to switch on.
enum ChangeMethodResultKind {
  changed,
  paymentRequired,
  locked,
  noChange,
  notOffered,
  error,
}

class ChangeMethodResult {
  final ChangeMethodResultKind kind;

  /// changed / done — the method now in effect.
  final String? newMethod;

  /// paymentRequired — provider + payment payload to hand to the existing payment
  /// helper in Chunk 7 (this layer never calls payment itself).
  final String? provider;
  final CampaignPaymentInfo? payment;
  final int? changeId;

  /// locked — when the change deadline passed (may be null if server omitted it).
  final DateTime? lockAt;

  /// notOffered — the methods this campaign actually offers.
  final List<String>? offeredMethods;

  /// error / generic — a user-facing message.
  final String? message;

  const ChangeMethodResult._(
    this.kind, {
    this.newMethod,
    this.provider,
    this.payment,
    this.changeId,
    this.lockAt,
    this.offeredMethods,
    this.message,
  });

  factory ChangeMethodResult.changed(String newMethod) =>
      ChangeMethodResult._(ChangeMethodResultKind.changed, newMethod: newMethod);

  factory ChangeMethodResult.paymentRequired({
    required String provider,
    required CampaignPaymentInfo payment,
    int? changeId,
  }) =>
      ChangeMethodResult._(
        ChangeMethodResultKind.paymentRequired,
        provider: provider,
        payment: payment,
        changeId: changeId,
      );

  factory ChangeMethodResult.locked(DateTime? lockAt) =>
      ChangeMethodResult._(ChangeMethodResultKind.locked, lockAt: lockAt);

  factory ChangeMethodResult.noChange() =>
      const ChangeMethodResult._(ChangeMethodResultKind.noChange);

  factory ChangeMethodResult.notOffered(List<String> offeredMethods) =>
      ChangeMethodResult._(ChangeMethodResultKind.notOffered,
          offeredMethods: offeredMethods);

  factory ChangeMethodResult.error(String message) =>
      ChangeMethodResult._(ChangeMethodResultKind.error, message: message);
}

/// Pure parser for the change-method response (Chunk-2 convention: int `status` +
/// `result` on 200, `code` on 422). Kept free of Flutter globals so it is unit
/// testable; the caller supplies [fallbackErrorMessage].
ChangeMethodResult parseChangeMethodResponse(
  int statusCode,
  dynamic data, {
  required String targetMethod,
  required String fallbackErrorMessage,
}) {
  final map =
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  if (statusCode == 200 && map['status'] == 1) {
    final r = map['result']?.toString();
    if (r == 'changed') {
      return ChangeMethodResult.changed(
          (map['method'] ?? targetMethod).toString());
    }
    if (r == 'payment_required') {
      final payment = map['payment'] is Map
          ? CampaignPaymentInfo.fromJson(
              Map<String, dynamic>.from(map['payment'] as Map))
          : CampaignPaymentInfo(
              required_: true,
              provider: (map['provider'] ?? targetMethod).toString());
      return ChangeMethodResult.paymentRequired(
        provider: (map['provider'] ?? payment.provider).toString(),
        payment: payment,
        changeId: (map['change_id'] as num?)?.toInt(),
      );
    }
    return ChangeMethodResult.error(
        map['message']?.toString() ?? fallbackErrorMessage);
  }

  if (statusCode == 422) {
    final ec = map['code']?.toString();
    if (ec == 'change_locked') {
      final la = map['method_change_lock_at']?.toString();
      return ChangeMethodResult.locked(
          la != null ? DateTime.tryParse(la) : null);
    }
    if (ec == 'no_change') {
      return ChangeMethodResult.noChange();
    }
    if (ec == 'method_not_offered') {
      final offered = map['methods_offered'] is List
          ? (map['methods_offered'] as List).map((e) => e.toString()).toList()
          : <String>[];
      return ChangeMethodResult.notOffered(offered);
    }
  }

  // Validation (200 status:0), 404, or any other unexpected shape.
  return ChangeMethodResult.error(map['message']?.toString() ?? fallbackErrorMessage);
}

/// True when confirm-payment has flipped (or already flipped) the method.
///
/// `status == 1` is not enough: that flag is the original order payment, which
/// is already paid before a method-change fee. Settlement is
/// `method_change.settled` (or `delivery_method` already matching [targetMethod]).
bool isMethodChangeFeeSettled(
  dynamic response, {
  required String targetMethod,
}) {
  if (response is! Map) return false;
  final map = Map<String, dynamic>.from(response);
  final status = map['status'];
  if (status != 1 && status != '1') return false;

  final mc = map['method_change'];
  if (mc is Map) {
    final settled = mc['settled'];
    if (settled == true || settled == 1 || settled == '1') return true;
    final mcMethod = mc['method']?.toString();
    if (mcMethod != null && mcMethod == targetMethod && settled != false) {
      return true;
    }
  }

  return map['delivery_method']?.toString() == targetMethod;
}

class CampaignRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  /// Fetch list of currently-selling campaigns for the authenticated user.
  Future<dynamic> getActiveCampaigns() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointCampaignsActive,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response;
  }

  /// Fetch campaign detail by slug (public endpoint, no auth needed).
  Future<dynamic> getCampaignDetail(String slug) async {
    final helper = ApiBaseHelper(baseUrl: BaseUrl.domain);
    final response = await helper.get(
      '${ApiConst.endPointCampaignPublicShow}$slug',
    );
    return response;
  }

  /// Place a campaign order (authenticated).
  Future<dynamic> placeOrder(Map<String, dynamic> body) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointCampaignPlaceOrder,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ...body,
      },
    );
    return response;
  }

  /// Confirm campaign payment after client-side Stripe/Vipps success.
  Future<dynamic> confirmPayment(String orderNo) async {
    return _apiBaseHelper.post(
      ApiConst.endPointCampaignConfirmPayment,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        'order_no': orderNo,
      },
    );
  }

  /// Change a campaign purchase's delivery method (pickup <-> delivery).
  /// Reads the Chunk-2 response convention: int `status` + `result` on 200, or
  /// `code` on 422. Never calls payment — a fee>0 change returns the payload for
  /// the payment helper (Chunk 7).
  Future<ChangeMethodResult> changeMethod({
    required String orderNo,
    required String targetMethod,
    String paymentMethod = 'stripe',
    String? deliveryAddress,
    int? addressId,
  }) async {
    try {
      final body = <String, dynamic>{
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        'order_no': orderNo,
        'target_method': targetMethod,
        'payment_method': paymentMethod,
      };
      final address = deliveryAddress?.trim() ?? '';
      if (address.isNotEmpty) body['delivery_address'] = address;
      if (addressId != null && addressId > 0) body['address_id'] = addressId;

      final result = await _apiBaseHelper.postAllowClientError(
        ApiConst.endPointCampaignChangeMethod,
        body: body,
      );

      return parseChangeMethodResponse(
        result.statusCode,
        result.data,
        targetMethod: targetMethod,
        fallbackErrorMessage: languages.apiErrorUnexpectedErrorMsg,
      );
    } catch (e) {
      // Network / timeout / 5xx — postAllowClientError rethrew a localized String.
      return ChangeMethodResult.error(e.toString());
    }
  }

  /// Fetch campaign orders for the authenticated user.
  Future<dynamic> getMyOrders() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointCampaignMyOrders,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response;
  }
}
