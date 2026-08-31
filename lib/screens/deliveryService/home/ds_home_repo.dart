import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class DSHomeRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callHomeStoreApi(double lat, double long, String? filterKey, int? categoryId,
      int? brandId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsHomeStore,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramCategoryId: categoryId,
        ApiParam.paramBrandId: brandId,
        ApiParam.paramLat: lat,
        ApiParam.paramLong: long,
        ApiParam.paramFilterType: "all",
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramFilterKey: filterKey,
      },
    );
    return response;
  }

  callFavouriteStoreApi(int viewAll, int page) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsFavouriteStoreLists,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
        // ApiParam.PARAM_SERVICE_CAT_ID: prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramViewAll: viewAll,
        ApiParam.paramPage: page
      },
    );
    return response;
  }

  callStoreCategoryListApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsStoreCategoryLists,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
      },
    );
    return response;
  }

  callBrandListApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDsBrandLists,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
      },
    );
    return response;
  }

  // callStoreProductCatListApi() async {
  //   final response = await _apiBaseHelper.post(
  //     ApiConst.endPointDsStoreProductCategoryLists,
  //     body: {
  //       ApiParam.paramUserId: prefGetInt(prefUserId),
  //       ApiParam.paramAccessToken: prefGetString(prefAccessToken),
  //       ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
  //     },
  //   );
  //   return response;
  // }
}
