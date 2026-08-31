import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class HelpAndSupportRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getHelpAndSupport() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointSupportPages,
      body: {ApiParam.paramUserId: prefGetInt(prefUserId), ApiParam.paramAccessToken: prefGetString(prefAccessToken)},
    );
    return response;
  }
}
