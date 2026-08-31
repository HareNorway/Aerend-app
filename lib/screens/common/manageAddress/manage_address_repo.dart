import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class ManageAddressRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callAddressListApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointAddressList,
      body: {ApiParam.paramUserId: prefGetInt(prefUserId), ApiParam.paramAccessToken: prefGetString(prefAccessToken)},
    );
    return response;
  }

  callDeleteAddressApi(int addressId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDeleteAddress,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramAddressId: addressId
      },
    );
    return response;
  }
}
