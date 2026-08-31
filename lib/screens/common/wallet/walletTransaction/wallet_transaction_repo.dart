import '../../../../networking/api_base_helper.dart';
import '../../../../utils/utils.dart';

class WalletTransactionRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getWalletTransactions() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointWalletTransactions,
      body: {ApiParam.paramUserId: prefGetInt(prefUserId), ApiParam.paramAccessToken: prefGetString(prefAccessToken)},
    );
    return response;
  }
}
