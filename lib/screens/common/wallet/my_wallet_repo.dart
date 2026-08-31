import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class MyWalletRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getWalletBalance() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointGetWalletBalance,
      body: {ApiParam.paramUserId: prefGetInt(prefUserId), ApiParam.paramAccessToken: prefGetString(prefAccessToken)},
    );
    return response;
  }

  addWalletBalance(double amount, int paymentType) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointWalletBalance,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramAmount: amount,
        ApiParam.paramCardId: 0,
        ApiParam.paramPaymentType : paymentType,
      },
    );
    return response;
  }
}
