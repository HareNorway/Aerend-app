import 'package:aerend_customer/utils/utils.dart';

import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class StoreDetailRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callStoreDetailsApi(
      int storeId, int filterType, double latitude, double longitude) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointStoreDetails,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramStoreId: storeId,
        ApiParam.paramLat: latitude,
        ApiParam.paramLong: longitude,
        ApiParam.paramFilterType: filterType
      },
    );
    return response;
  }

  callOrderCartApi(int storeId, int productId, int quantity) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointAddOrderCart,
      body: {
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
        ApiParam.paramStoreId: storeId,
        ApiParam.paramProductId: productId,
        ApiParam.paramQuantity: quantity,
        ApiParam.paramSizeId: prefGetInt('checkedSize'),
        ApiParam.paramColorId: prefGetInt('checkedColor'),
        ApiParam.paramOptionsList:
            prefGetStringWithDefaultValue('checkedOptionList', '[]'),
      },
    );
    prefSetInt('checkedColor', 0);
    prefSetInt('checkedSize', 0);
    prefSetString('checkedOptionList', '[]');
    return response;
  }

  callAddFavourite(int storeId, int isFavourite) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointFavorite,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramStoreId: storeId,
        ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
        ApiParam.paramIsFavourite: isFavourite
      },
    );
    return response;
  }

  callStoreReviewApi(int storeId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointStoreReviewList,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramStoreId: storeId
      },
    );
    return response;
  }
}
