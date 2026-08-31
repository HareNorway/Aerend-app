import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class SelectPaymentMethodRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  payForRide(int rideId, int cardId, int paymentType) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointCardPaymentTransaction,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramRideId: rideId,
        ApiParam.paramCardId: cardId,
        ApiParam.paramPaymentType: paymentType,
      },
    );
    return response;
  }
}
