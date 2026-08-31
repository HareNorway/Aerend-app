import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class OtpVerifyRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callSendOtpApi() async {
    final response = await _apiBaseHelper.post(ApiConst.endPointSendOtp,
        body: {ApiParam.paramUserId: prefGetInt(prefUserId)});
    return response;
  }

  callVerifyOtpApi(String otp) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointVerifyOtp,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramOtp: otp,
      },
    );
    return response;
  }

  callResendOtpApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointResendOtp,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken)
      },
    );
    return response;
  }

  callChangeNumberApi(String phoneNum, String countryCode) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointChangeNumber,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramContactNumber: phoneNum,
        ApiParam.paramSelectCountryCode: countryCode
      },
    );
    return response;
  }
}
