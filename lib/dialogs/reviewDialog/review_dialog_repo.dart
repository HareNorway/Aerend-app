import '../../networking/api_base_helper.dart';
import '../../utils/shared_pref_utill.dart';

class ReviewDialogRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callOrderRatingApi(int orderId, double? storeRating, double? driverRating,
      String? storeComment, String? driverComment) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointOrderRating,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramOrderId: orderId,
        ApiParam.paramDriverRating: driverRating,
        ApiParam.paramDriverComment: driverComment,
        ApiParam.paramStoreRating: storeRating,
        ApiParam.paramStoreComment: storeComment
      },
    );
    return response;
  }
}
