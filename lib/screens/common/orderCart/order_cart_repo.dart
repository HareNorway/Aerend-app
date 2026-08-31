import '../../../networking/api_base_helper.dart';
import '../../../utils/shared_pref_utill.dart';

class OrderCartRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  /// Guest carts use [prefDeviceToken]; logged-in carts use numeric user id
  /// (backend also merges device_token cart after login).
  String resolveCartOwnerId() {
    final int userId = prefGetInt(prefUserId);
    final String token = prefGetString(prefAccessToken).trim();
    if (userId != 0 && token.isNotEmpty) {
      return userId.toString();
    }
    return prefGetString(prefDeviceToken).trim();
  }

  Future<Map<String, dynamic>?> fetchOrderCartRaw() async {
    final ownerId = resolveCartOwnerId();
    if (ownerId.isEmpty) return null;
    return await _apiBaseHelper.post(
      ApiConst.endPointGetOrderCart,
      body: {ApiParam.paramUserId: ownerId},
    );
  }

  Future<void> clearAllCartItems() async {
    final cart = await fetchOrderCartRaw();
    if (cart == null || cart['status'] != 1) return;
    final List<dynamic> orderList = cart['order_list'] as List? ?? [];
    for (final dynamic item in orderList) {
      if (item is! Map) continue;
      final int cartId = (item['id'] as num?)?.toInt() ?? 0;
      if (cartId > 0) {
        await deleteOrderCartApi(cartId);
      }
    }
    prefSetInt(prefCartCount, 0);
  }

  callOrderCartApi() async {
    final ownerId = resolveCartOwnerId();
    final response = await _apiBaseHelper.post(
      ApiConst.endPointGetOrderCart,
      body: {
        ApiParam.paramUserId: ownerId.isNotEmpty ? ownerId : prefGetInt(prefUserId),
      },
    );
    return response;
  }

  callAddCartApi(
      int storeId, int serviceCategoryId, int productId, int quantity) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointAddOrderCart,
      body: {
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
        ApiParam.paramStoreId: storeId,
        ApiParam.paramServiceCatId: serviceCategoryId,
        ApiParam.paramProductId: productId,
        ApiParam.paramQuantity: quantity
      },
    );
    return response;
  }

  callChangeQuantityApi(int orderId, int quantity) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointChangeOrderQuantity,
      body: {ApiParam.paramOrderId: orderId, ApiParam.paramQuantity: quantity},
    );
    return response;
  }

  deleteOrderCartApi(int cartId) async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointDeleteOrderCart,
      body: {ApiParam.paramCartId: cartId},
    );
    return response;
  }
}
