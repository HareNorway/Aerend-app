import '../../../../networking/api_base_helper.dart';
import '../../../../utils/shared_pref_utill.dart';

class OrderDetailRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getOrderDetailApi(int orderId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsOrderDetail,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramOrderId: orderId,
      },
    );
    return response;
  }
}
