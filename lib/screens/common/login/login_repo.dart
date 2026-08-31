import 'dart:io';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class LoginRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  login(String loginType, String emailAddress, String password, String name,
      String loginId, String profileImage) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointLogin,
      body: {
        ApiParam.paramLoginType: loginType,
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
        ApiParam.paramEmail: emailAddress,
        ApiParam.paramPassword: password,
        ApiParam.paramFullName: name,
        ApiParam.paramLoginId: loginId,
        ApiParam.paramLoginDevice: Platform.isAndroid
            ? loginDeviceFlutterAndroid
            : loginDeviceFlutterIos,
        ApiParam.paramProfileImage: profileImage,
        ApiParam.paramSelectLanguage: resolveSelectedLanguage(),
        ApiParam.paramSelectCurrency: resolveSelectedCurrency(),
      },
    );
    return response;
  }

  forgotPassReqApi(String phoneNum, String countryCode) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointForgotPassReq,
      body: {
        ApiParam.paramContactNumber: phoneNum,
        ApiParam.paramSelectCountryCode: countryCode
      },
    );
    return response;
  }

  getProfile() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointGetProfile,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken)
      },
    );
    return response;
  }

  forgotChangePassApi(int userId, String otp, String password) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointForgotChangePass,
      body: {
        ApiParam.paramUserId: userId,
        ApiParam.paramOtp: otp,
        ApiParam.paramNewPassword: password,
        ApiParam.paramLoginDevice: Platform.isAndroid
            ? loginDeviceFlutterAndroid
            : loginDeviceFlutterIos
      },
    );
    return response;
  }

  facebookGraphRequest(String url) async {
    final response = await _apiBaseHelper.get(url);
    return response;
  }
}
