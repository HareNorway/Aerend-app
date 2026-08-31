import 'dart:io';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class SignUpRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  signUp(String fullName, String email, String password) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointRegister,
      body: {
        ApiParam.paramFullName: fullName,
        ApiParam.paramEmail: email,
        ApiParam.paramPassword: password,
        ApiParam.paramContactNumber: '',
        ApiParam.paramReferCode: '',
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
        ApiParam.paramLoginDevice: Platform.isAndroid
            ? loginDeviceFlutterAndroid
            : loginDeviceFlutterIos,
        ApiParam.paramSelectLanguage: resolveSelectedLanguage(),
        ApiParam.paramSelectCountryCode: '',
        ApiParam.paramSelectCurrency: resolveSelectedCurrency(),
      },
    );
    return response;
  }
}
