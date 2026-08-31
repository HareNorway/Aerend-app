import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class HomeRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  homeApi({String? appVersion, double? lat, double? lng}) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointHome,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramAppVersion: appVersion,
        ApiParam.paramCurrentLat: lat,
        ApiParam.paramCurrentLng: lng,
      },
    );
    return response;
  }

  homeFeaturedApi(double lat, double long, {int serviceCatId = 0}) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointHomePageFeatureStore,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: serviceCatId,
        ApiParam.paramLat: lat,
        ApiParam.paramLong: long,
      },
    );
    return response;
  }

  homeTrackOrderApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointHomeTrackOrder,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response;
  }

  checkingRedeemCode(String referCode) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointReferCode,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramReferCode: referCode,
      },
    );
    return response;
  }

  addProductRateApi(int orderId, int rate) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointAddProductRate,
      body: {
        ApiParam.paramOrderId: orderId,
        ApiParam.paramRate: rate,
      },
    );
    return response;
  }

  callLogoutApi() async {
    final int userId = prefGetInt(prefUserId);
    final String accessToken = prefGetString(prefAccessToken).trim();
    final response = await _apiBaseHelper.post(
      ApiConst.endPointLogout,
      body: {
        ApiParam.paramUserId: userId,
        ApiParam.paramAccessToken: accessToken,
      },
    );
    return response;
  }
}
