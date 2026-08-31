import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class SwipeAerendRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callHareSwipeApi(double lat, double long) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointHareSwipe,
      body: {
        ApiParam.paramLat: lat,
        ApiParam.paramLong: long,
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
      },
    );
    return response;
  }

  callHareExploreApi(double lat, double long) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointHareExplore,
      body: {
        ApiParam.paramLat: lat,
        ApiParam.paramLong: long,
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
      },
    );
    return response;
  }
}
