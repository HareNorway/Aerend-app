import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class ManageCardRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getCardList() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointCardList,
      body: {ApiParam.paramUserId: prefGetInt(prefUserId), ApiParam.paramAccessToken: prefGetString(prefAccessToken)},
    );
    return response;
  }

  removeCard(int cardId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointCardRemove,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramCardId: cardId
      },
    );
    return response;
  }
}
