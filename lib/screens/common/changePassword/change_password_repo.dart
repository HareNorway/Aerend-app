import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class ChangePasswordRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  changePassword(String oldPassword, String newPassword) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointChangePassword,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramOldPassword: oldPassword,
        ApiParam.paramNewPassword: newPassword
      },
    );
    return response;
  }
}
