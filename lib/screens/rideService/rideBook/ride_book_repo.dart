import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class RideBookRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  serviceDataApi(double? currentLat, double? currentLong, String? goodsWeight, int courierType, String? estimatedPrice) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportServiceType,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: /*prefGetInt(prefSelectedServiceCateId)*/ 1,
        ApiParam.paramCurrentLat: currentLat,
        ApiParam.paramCurrentLng: currentLong,
        ApiParam.paramHandicap: prefGetInt(prefHandicap),
        ApiParam.paramChildSeat: prefGetInt(prefChildSeat),
        ApiParam.paramGender: prefGetInt(prefDriverGender),
        ApiParam.paramGoodsWeight: goodsWeight,
        ApiParam.paramCourierType: courierType,
        ApiParam.paramEstimatePrice: estimatedPrice,
      },
    );
    return response;
  }

  courierBookApi(Map<String, dynamic> dataMap) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportRideBooking,
      body: dataMap,
    );
    return response;
  }

  applyPromoCodeApi(String promoCode, double orderAmount) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointApplyPromoCode,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramPromoCode: promoCode,
        ApiParam.paramOrderAmount: orderAmount
      },
    );
    return response;
  }

  rideBookApi(String? rideId, String? addressList, int? paymentType, String? estimatedTime, String? totalDistance, int? serviceTypeId,
      String? pickupDateTime, String? promoCode,
      {String? contactNumberOfOther, bool? bookForOther}) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportRideBooking,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramRideId: rideId,
        ApiParam.paramAddressList: addressList,
        ApiParam.paramPaymentType: paymentType,
        ApiParam.paramEstimatedTime: estimatedTime,
        ApiParam.paramTotalDistance: totalDistance,
        ApiParam.paramServiceTypeId: serviceTypeId,
        ApiParam.paramPickupDateTime: pickupDateTime,
        ApiParam.paramPromoCode: promoCode,
        ApiParam.paramHandicap: prefGetInt(prefHandicap),
        ApiParam.paramChildSeat: prefGetInt(prefChildSeat),
        ApiParam.paramGender: prefGetInt(prefDriverGender),
        ApiParam.paramBookForOther: bookForOther! ? 1 : 0,
        ApiParam.paramContactNumberOfOther: contactNumberOfOther, //required if book for other,
        ApiParam.paramCardId: 0
      },
    );
    return response;
  }

  cancelRideBookingApi(String? rideId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportCancelRideBooking,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramRideId: rideId,
        ApiParam.paramCancelReason: null
      },
    );
    return response;
  }

  surgeCharge(int? serviceTypeId, String? pickupDateTime) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportSurchargeCharge,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceTypeId: serviceTypeId,
        ApiParam.paramPickupDateTime: pickupDateTime
      },
    );
    return response;
  }
}
