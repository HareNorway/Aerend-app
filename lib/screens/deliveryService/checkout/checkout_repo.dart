import 'package:dio/dio.dart';

import '../../../constant/constant.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../common/orderCart/order_cart_repo.dart';

class CheckoutRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callOrderPreviewApi() async {
    final ownerId = OrderCartRepo().resolveCartOwnerId();
    final response = await _apiBaseHelper.post(
      ApiConst.endPointOrderPreview,
      body: {
        ApiParam.paramUserId:
            ownerId.isNotEmpty ? ownerId : prefGetInt(prefUserId),
        ApiParam.paramAddressId: prefGetInt(prefNewDeliveryAddressId),
      },
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
    MultipartFile? multipartFile,
  ) async {
    final response = await _apiBaseHelper.postFormData(
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
        // ApiParam.paramPrescription: multipartFile
      },
    );
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
