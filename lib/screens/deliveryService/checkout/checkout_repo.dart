import 'package:dio/dio.dart';

import '../../../constant/constant.dart';
import '../../../networking/api_base_helper.dart';
import '../../../networking/feed/feed_attribution.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../common/orderCart/order_cart_repo.dart';

class CheckoutRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  /// Customer v2 Step 1: [flex] asks for the «Innen 2 timer» price (pricing.flex_window); with [clientErrors]
  /// a 4xx body (e.g. 422 `OUT_OF_COVERAGE` from the pricing engine) comes back instead of throwing.
  callOrderPreviewApi({bool flex = false, bool clientErrors = false}) async {
    final ownerId = OrderCartRepo().resolveCartOwnerId();
    final body = {
        ApiParam.paramUserId:
            ownerId.isNotEmpty ? ownerId : prefGetInt(prefUserId),
        ApiParam.paramAddressId: prefGetInt(prefNewDeliveryAddressId),
        if (flex) 'flex': 1,
      };
    if (clientErrors) {
      final r = await _apiBaseHelper.postAllowClientError(ApiConst.endPointOrderPreview, body: body);
      return r.data;
    }
    final response = await _apiBaseHelper.post(
      ApiConst.endPointOrderPreview,
      body: body,
    );
    return response;
  }

  callPromoCodeApi({int? serviceCateId}) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointPromoCodeList,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId:
            serviceCateId ?? prefGetInt(prefSelectedServiceCateId),
      },
    );
    return response;
  }

  applyPromoCodeApi(
    String promoCode,
    double orderAmount,
    int serviceCategoryId,
  ) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointApplyPromoCode,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: serviceCategoryId,
        ApiParam.paramSelectLanguage: resolveSelectedLanguage(),
        ApiParam.paramPromoCode: promoCode,
        ApiParam.paramOrderAmount: orderAmount,
      },
    );
    return response;
  }

  callStorePlaceOrderApi(
    int storeId,
    int address,
    int paymentType,
    int takenType,
    String additionalInfo,
    String productList,
    bool credit,
    String promoCode,
    String? scheduleDateTime,
    double? tip,
    MultipartFile? multipartFile, {
    String? quoteId,
    bool flex = false,
    bool clientErrors = false,
    String? companyName,
    String? companyOrgNr,
  }) async {
    // Customer v2 Step 1: with [clientErrors] a 422 (`QUOTE_EXPIRED`, `OUT_OF_COVERAGE`) comes back as its body.
    final post = clientErrors
        ? ((String url, {required Map<String, dynamic> body}) async => (await _apiBaseHelper.postFormDataAllowClientError(url, body: body)).data)
        : ((String url, {required Map<String, dynamic> body}) => _apiBaseHelper.postFormData(url, body: body));
    final response = await post(
      ApiConst.endPointDsPlaceOrder,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramStoreId: storeId,
        ApiParam.paramOrderId: prefGetInt('bookedOrderId') == 0
            ? null
            : prefGetInt('bookedOrderId'),
        ApiParam.paramAddress: address,
        ApiParam.paramPaymentType: paymentType,
        ApiParam.paramAdditionalInfo: additionalInfo,
        ApiParam.paramProductList: productList,
        ApiParam.paramUserTakenType: takenType,
        ApiParam.paramPromoCode: promoCode,
        ApiParam.paramCredit: credit,
        ApiParam.paramCardId: 0,
        ApiParam.paramScheduleDateTime: scheduleDateTime,
        ApiParam.paramTip: tip,
        // The feed post this basket came from (backend plan Step 9).
        if (FeedAttribution.forStore(storeId) case final post?) 'source_post_id': post,
        // Customer v2 Step 1 (pricing spec §2.4): the quote the customer saw is the fee.
        if (quoteId != null) 'quote_id': quoteId,
        if (flex) 'flex': 1,
        // Payments plan Step 3 (payments spec v1.3 §2.1): Bedriftskvittering — the company on the receipt.
        if (companyOrgNr != null && companyOrgNr.isNotEmpty) 'company_org_nr': companyOrgNr,
        if (companyOrgNr != null && companyOrgNr.isNotEmpty && (companyName ?? '').isNotEmpty) 'company_name': companyName,
        // ApiParam.paramPrescription: multipartFile
      },
    );
    if (response is Map && (response['status'] == 1 || response['status'] == true)) {
      FeedAttribution.clear(storeId);
    }
    return response;
  }

  getPaymentIntentApi(double amount) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointPaymentIntent,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramAmount: amount,
      },
    );
    return response;
  }

  initiateVippsViaBackend(int orderId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointVippsInitiate,
      body: {
        'order_id': orderId,
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response;
  }

  confirmVippsViaBackend(int orderId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointVippsConfirm,
      body: {
        'order_id': orderId,
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response;
  }
}
