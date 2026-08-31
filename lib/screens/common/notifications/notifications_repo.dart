import '../../../utils/utils.dart';
import '../../../networking/api_base_helper.dart';

class NotificationsRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callNotificationsApi(int page, {int? perPage}) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointMassNotificationList,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramPage: page,
        ApiParam.paramPerPage: perPage ?? perPageRecord
      },
    );
    return response;
  }
}
