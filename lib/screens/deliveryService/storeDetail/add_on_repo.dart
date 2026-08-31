import "../../../networking/api_base_helper.dart";

class AddOnRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  getToppingsAndOptions(int productId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointGetAddOns,
      body: {ApiParam.paramProductId: productId},
    );

    return response;
  }
}
