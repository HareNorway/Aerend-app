import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class SearchStoreRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  /// [serviceCatId] overrides the selected service category; 0 searches
  /// every category (the Bergen Søk).
  callSearchStoreApi(double lat, double lng, String search,
      {int catId = 0, int? serviceCatId}) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointSearchStore,
      body: {
        ApiParam.paramLat: lat,
        ApiParam.paramLong: lng,
        ApiParam.paramSearch: search,
        ApiParam.paramServiceCatId:
            serviceCatId ?? prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramCategoryId: catId,
      },
    );
    return response;
  }

  callSearchProductApi(double lat, double lng, int page, String search,
      {int? serviceCatId}) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointSearchProduct,
      body: {
        ApiParam.paramLat: lat,
        ApiParam.paramLong: lng,
        ApiParam.paramPage: page,
        ApiParam.paramPerPage: perPageRecord,
        ApiParam.paramSearch: search,
        ApiParam.paramServiceCatId:
            serviceCatId ?? prefGetInt(prefSelectedServiceCateId),
      },
    );
    return response;
  }

  callSearchHareApi(double lat, double lng, String search) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointSearchHare,
      body: {
        ApiParam.paramLat: lat,
        ApiParam.paramLong: lng,
        ApiParam.paramSearch: search,
        // ApiParam.paramCategoryList: productCategoryList,
        // ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
      },
    );
    return response;
  }
}
