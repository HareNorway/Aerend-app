import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class AddCardRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  addCard(String holderName, String cardNumber, String month, String year, String cvv) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointAddCard,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramHolderName: holderName,
        ApiParam.paramCardNumber: cardNumber,
        ApiParam.paramMonth: month,
        ApiParam.paramYear: year,
        ApiParam.paramCvv: cvv
      },
    );
    return response;
  }
}
