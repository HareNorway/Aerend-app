import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class RunningRideRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  cancelRideBookingApi(String rideId, String cancelReason) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportCancelRideBooking,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramRideId: rideId,
        ApiParam.paramCancelReason: cancelReason
      },
    );
    return response;
  }
}
