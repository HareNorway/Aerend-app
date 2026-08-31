import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class DeliveriesOrderDetailRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  deliveriesOrderDetailApi(int orderId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsOrderDetails,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramOrderId: orderId
      },
    );
    return response;
  }
}
