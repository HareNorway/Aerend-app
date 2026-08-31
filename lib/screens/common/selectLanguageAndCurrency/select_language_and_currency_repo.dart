import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class SelectLanguageAndCurrencyRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getLanguageAndCurrency() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointCountryCurrency,
      body: {},
    );
    return response;
  }

  updateCountryAndCurrency(String languageCode, String currencySymbol) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointUpdateCountryCurrency,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramSelectLanguage: languageCode,
        ApiParam.paramSelectCountryCode: prefGetStringWithDefaultValue(prefCountryCode, defaultCountryCode.dialCode!),
        ApiParam.paramSelectCurrency: currencySymbol,
      },
    );
    return response;
  }
}
