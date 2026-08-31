import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class TrackOrderRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();
  final ApiBaseHelper _apiStoreBaseHelper =
      ApiBaseHelper(baseUrl: BaseUrl.baseStoreUrl);

  callTrackOrderApi(int? orderId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsTrackOrder,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramOrderId: orderId
      },
    );
    return response;
  }

  updateOrderStatusApi(int orderId, int updateStatus) async {
    final response = await _apiStoreBaseHelper.post(
      ApiConst.endPointUpdateOrderStatus,
      body: {
        ApiParam.paramOrderId: orderId,
        ApiParam.paramUpdateStatus: updateStatus
      },
    );
    return response;
  }

  callOrderCancelsApi(String cancelReason, int orderId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsOrderCancel,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramCancelReason: cancelReason,
        ApiParam.paramOrderId: orderId,
      },
    );
    return response;
  }
}
