import '../../data/ops/butikk_models.dart';
import '../../screens/common/home/bergen/bergen_store_repo.dart';
import '../../screens/common/home/home_dl.dart';
import '../../screens/common/home/home_repo.dart';
import '../../screens/deliveryService/home/ds_home_store_list_pojo.dart';
import '../../screens/deliveryService/searchStore/search_store_dl.dart';
import '../../screens/deliveryService/searchStore/search_store_repo.dart';
import '../../screens/deliveryService/storeDetail/add_on_repo.dart';
import '../../screens/deliveryService/storeDetail/store_detail_dl.dart';
import '../../screens/deliveryService/storeDetail/store_detail_repo.dart';
import '../../utils/utils.dart';
import 'ops_customer_api.dart';

/// The store, category and product reads the Bergen Butikk group makes
/// (AGIL-1 v2 Phase 4), over the app's existing endpoints. Everything is
/// nullable / empty on failure; the screens show an honest empty state.
class OpsButikkApi {
  OpsButikkApi();

  static bool get _off => !OpsCustomerApi.networkEnabled;

  /// The app's service categories (id, name, icon), for resolving a slug.
  Future<List<ServicesItem>> categories() async {
    if (_off) return const [];
    try {
      final pos = prefGetLatLng();
      final pojo = HomeCatePojo.fromJson(
        await HomeRepo().homeApi(lat: pos.latitude, lng: pos.longitude),
      );
      return pojo.services;
    } catch (_) {
      return const [];
    }
  }

  /// Stores in one category, for the Kategori page.
  Future<List<StoreListItem>> storesInCategory(int categoryId) async {
    if (_off) return const [];
    try {
      return await BergenStoreRepo().fetch(categoryId);
    } catch (_) {
      return const [];
    }
  }

  /// Products in the selected category (the search endpoint with no text).
  Future<List<ProductList>> productsInCategory(
    int categoryId, {
    String query = '',
  }) async {
    if (_off) return const [];
    try {
      final pos = prefGetLatLng();
      final current = prefGetInt(prefSelectedServiceCateId);
      if (current != categoryId)
        prefSetInt(prefSelectedServiceCateId, categoryId);
      final pojo = SearchProductPojo.fromJson(
        await SearchStoreRepo().callSearchProductApi(
          pos.latitude,
          pos.longitude,
          1,
          query,
        ),
      );
      return pojo.productList;
    } catch (_) {
      return const [];
    }
  }

  /// One store with its menu.
  Future<BergenStoreInfo?> store(int storeId, {String? categoryHint}) async {
    if (_off) return null;
    try {
      final pos = prefGetLatLng();
      final pojo = StoreDetailsPojo.fromJson(
        await StoreDetailRepo().callStoreDetailsApi(
          storeId,
          0,
          pos.latitude,
          pos.longitude,
        ),
      );
      if (pojo.status != 1) return null;
      return BergenStoreInfo.fromPojo(pojo, categoryHint: categoryHint);
    } catch (_) {
      return null;
    }
  }

  /// Option groups, sizes and colours for a product.
  Future<BergenProductOptions> options(int productId) async {
    if (_off) return const BergenProductOptions();
    try {
      final json = await AddOnRepo().getToppingsAndOptions(productId);
      if (json is Map<String, dynamic> && json['status'] == 1) {
        return BergenProductOptions.fromJson(json);
      }
    } catch (_) {
      // Fall through.
    }
    return const BergenProductOptions();
  }

  /// `POST /api/agent/availability-subscriptions` (agil-2, guarded): "si fra
  /// hvis prisen faller". Null when the route is not on this tree.
  Future<bool> subscribeToPrice(int productId) async {
    if (_off) return false;
    final auth = OpsCustomerApi.authParams();
    if (auth == null) return false;
    try {
      final json = await OpsCustomerApi().postGuarded(
        'api/agent/availability-subscriptions',
        {'product_id': productId, 'kind': 'price_drop'},
      );
      return json != null;
    } catch (_) {
      return false;
    }
  }
}
