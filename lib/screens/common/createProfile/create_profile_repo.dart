import 'dart:io';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class CreateProfileRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  signUp(String fullName, String email, String password, String countryCode,
      String phoneNum) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointRegister,
      body: {
        ApiParam.paramFullName: fullName,
        ApiParam.paramEmail: email,
        ApiParam.paramPassword: password,
        ApiParam.paramContactNumber: phoneNum,
        ApiParam.paramReferCode: '',
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
        ApiParam.paramLoginDevice: Platform.isAndroid
            ? loginDeviceFlutterAndroid
            : loginDeviceFlutterIos,
        ApiParam.paramSelectLanguage: resolveSelectedLanguage(),
        ApiParam.paramSelectCountryCode: countryCode,
        ApiParam.paramSelectCurrency: resolveSelectedCurrency(),
      },
    );
    return response;
  }

  editProfile(int userId, String fullName, String email, String countryCode,
      String phoneNum) async {
    final response =
        await _apiBaseHelper.post(ApiConst.endPointErrorProfile, body: {
      ApiParam.paramUserId: userId,
      ApiParam.paramFullName: fullName,
      ApiParam.paramEmail: email,
      ApiParam.paramSelectCountryCode: countryCode,
      ApiParam.paramContactNumber: phoneNum
    });
    return response;
  }
}
