import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class RideDetailRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  rideReceiptDetailApi(int rideId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportRideReceiptDetail,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramRideId: rideId
      },
    );
    return response;
  }

  cancelRideBookingApi(String rideId, String cancellationReason) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportCancelRideBooking,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramRideId: rideId,
        ApiParam.paramCancelReason: cancellationReason
      },
    );
    return response;
  }

  rideRating(int rideId, int driverId, double rating, String comment) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportRideUserRating,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramRideId: rideId,
        ApiParam.paramDriverId: driverId,
        ApiParam.paramRating: rating,
        ApiParam.paramComment: comment
      },
    );
    return response;
  }

  addTip(int rideId, String tip) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportTip,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramRideId: rideId,
        ApiParam.paramTip: tip
      },
    );
    return response;
  }
}
