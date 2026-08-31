import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class DSSubCateRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callSubCatListApi(int catId, int storeId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsStoreProductCategoryLists,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramCategoryId: catId,
        ApiParam.paramStoreId: storeId
      },
    );
    return response;
  }
}
