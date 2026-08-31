import 'package:flutter/foundation.dart';

import '../../../constant/constant.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class ProductListRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callStoreProductApi(int storeId, int categoryId, int page, int perPage,
      String search, int filterType) async {
    debugPrint(
        "ProductListRepo.callStoreProductApi => storeId=$storeId, categoryId=$categoryId, "
        "page=$page, perPage=$perPage, search='$search', filterType=$filterType");

    final response = await _apiBaseHelper.post(
      ApiConst.endPointStoreProductList,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramStoreId: storeId,
        ApiParam.paramCategoryId: categoryId,
        ApiParam.paramPage: page,
        ApiParam.paramPerPage: perPageRecord,
        ApiParam.paramSearch: search,
        ApiParam.paramFilterType: filterType
      },
    );
    debugPrint(
        "ProductListRepo.callStoreProductApi <= status=${response["status"]}, "
        "messageCode=${response["message_code"]}, "
        "storeId=${response["store_id"]}, "
        "categoryId=${response["category_id"]}, "
        "hasProductList=${response["product_list"] != null}");
    return response;
  }
}
