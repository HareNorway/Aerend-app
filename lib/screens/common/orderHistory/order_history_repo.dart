import '../../../constant/constant.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class OrderHistoryRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getRideHistoryApi(int filterType, int page, String timeZone) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointTransportRideHistory,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramFilterType: filterType,
        ApiParam.paramPage: page,
        ApiParam.paramTimeZone: timeZone, //Asia/Kolkata
        ApiParam.paramPerPage: perPageRecord
      },
    );
    return response;
  }

  getDSOrderHistoryApi(int filterType, int page, String timeZone) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsOrderHistory,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramFilterType: filterType,
        ApiParam.paramPage: page,
        ApiParam.paramTimeZone: timeZone,
        ApiParam.paramPerPage: perPageRecord
      },
    );
    return response;
  }

  getOrderHistoryApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsOrderHistory,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response;
  }
}
