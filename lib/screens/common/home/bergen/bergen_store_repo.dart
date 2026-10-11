import '../../../../networking/api_base_helper.dart';
import '../../../../utils/shared_pref_utill.dart';
import '../../../deliveryService/home/ds_home_store_list_pojo.dart';

/// Store list for one service category, for the Hjem store rail.
///
/// `DSHomeRepo.callHomeStoreApi` reads the category from
/// `prefSelectedServiceCateId`; the dashboard rotates through categories
/// without changing that preference, so it posts the id explicitly.
class BergenStoreRepo {
  final ApiBaseHelper _api = ApiBaseHelper();

  /// [surface] tells the server which admin order to use (backend plan
  /// Step 12, Partnere): `home` (Kundeforsiden), `wheel` (a category opened
  /// from Kategorihjulet) or `list` (Butikklisten, the default).
  Future<List<StoreListItem>> fetch(int serviceCategoryId, {String surface = 'list'}) async {
    final latLng = prefGetLatLng();
    final response = await _api.post(
      ApiConst.endPointDsHomeStore,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramCategoryId: null,
        ApiParam.paramBrandId: null,
        ApiParam.paramLat: latLng.latitude,
        ApiParam.paramLong: latLng.longitude,
        ApiParam.paramFilterType: 'all',
        ApiParam.paramServiceCatId: serviceCategoryId,
        ApiParam.paramFilterKey: null,
        'surface': surface,
      },
    );
    final pojo = DsHomeStoreListPojo.fromJson(response);
    if (pojo.status != 1) return const [];
    return pojo.storeList ?? const [];
  }
}
