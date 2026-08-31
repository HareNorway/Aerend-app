import 'dart:io';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class SplashRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getRunningServiceApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointGetRunningService,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken)
      },
    );
    return response;
  }

  appVersionCheckApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointAppVersionCheck,
      body: {
        ApiParam.paramLoginDevice: Platform.isAndroid
            ? loginDeviceFlutterAndroid
            : loginDeviceFlutterIos,
        ApiParam.paramAppType: 0
      },
    );
    return response;
  }
}
