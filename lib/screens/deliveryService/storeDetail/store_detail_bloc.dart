import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/orderCart/order_cart_repo.dart';
import 'package:aerend_customer/screens/deliveryService/home/ds_home_dl.dart';
import 'package:aerend_customer/screens/deliveryService/home/ds_home_repo.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/cart_store_conflict_helper.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import 'store_detail_dl.dart';
import 'store_detail_repo.dart';
import '../productList/product_list_repo.dart';
import '../productList/product_list_dl.dart';

class StoreDetailBloc extends Bloc {
  String tag = "StoreDetailsBloc>>>";
  final StoreDetailRepo _storeDetailRepo = StoreDetailRepo();
  final DSHomeRepo _dsHomeRepo = DSHomeRepo();
  final ProductListRepo _productListRepo = ProductListRepo();
  late BuildContext context;
  late int storeId;

  final State state;

  StoreDetailBloc(this.context, this.storeId, this.state) {
    getStoreReviewList();
    getStoreDetail(0);
    getOrderCart();
    if (prefGetInt(prefSelectedServiceCateId) == 6) {
      callBrandListApi();
    }
  }

  final _subject = BehaviorSubject<ApiResponse<StoreDetailsPojo>>();
  final _orderCartSubject = BehaviorSubject<ApiResponse<UserOrderCartPojo>>();
  final _filterVegController = BehaviorSubject<bool>.seeded(false);
  final showCuisineButton = BehaviorSubject<bool>.seeded(true);
  final showCuisineText = BehaviorSubject<bool>.seeded(true);
  final _storeRatingListController =
      BehaviorSubject<List<StoreRatingListItem>>();
  final _subjectAddFavourite =
      BehaviorSubject<ApiResponse<ModelAddFavourite>>();
  final _subjectBrand = BehaviorSubject<ApiResponse<BrandCategoryPojo>>();

  BehaviorSubject<ApiResponse<StoreDetailsPojo>> get subject => _subject;
  BehaviorSubject<ApiResponse<UserOrderCartPojo>> get orderCartSubject =>
      _orderCartSubject;

  BehaviorSubject<ApiResponse<ModelAddFavourite>> get subjectAddFavourite =>
      _subjectAddFavourite;

  BehaviorSubject<ApiResponse<BrandCategoryPojo>> get subjectBrand =>
      _subjectBrand;

  Stream<List<StoreRatingListItem>> get storeRatingList =>
      _storeRatingListController.stream;

  Stream<bool> get filterVeg => _filterVegController.stream;

  Function(List<StoreRatingListItem>) get changeStoreRatingList =>
      _storeRatingListController.sink.add;

  getStoreDetail(int filterType, {bool isLoading = true}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (isLoading) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        logd(tag,
            "Requesting store-details for storeId=$storeId, filterType=$filterType, lat=${prefGetLatLng().latitude}, long=${prefGetLatLng().longitude}");

        var response = await _storeDetailRepo.callStoreDetailsApi(
          storeId,
          filterType,
          prefGetLatLng().latitude,
          prefGetLatLng().longitude,
        );

        prefSetString(prefSelectedStoreFullResponse, jsonEncode(response));
        response = StoreDetailsPojo.fromJson(response);

        logd(
          tag,
          "store-details response: status=${response.status}, messageCode=${response.messageCode}, "
          "categories=${response.categoryWiseProductList.length}, "
          "takenAwayType=${response.takenAwayType}",
        );

        // If backend does not return category-wise products for this store,
        // fall back to the generic store-product-list API so that any
        // active products created from the store admin become visible.
        if (response.categoryWiseProductList.isEmpty) {
          logd(
            tag,
            "No category_wise_product_list from store-details. Falling back to store-product-list...",
          );
          try {
            final rawProductListJson =
                await _productListRepo.callStoreProductApi(
              storeId,
              0, // 0 = all categories
              1, // first page
              perPageRecord,
              "",
              0, // no veg/non-veg filter
            );

            final storeProductList =
                StoreProductList.fromJson(rawProductListJson);

            logd(
              tag,
              "store-product-list response: status=${storeProductList.status}, "
              "messageCode=${storeProductList.messageCode}, "
              "categoryId=${storeProductList.categoryId}, "
              "totalProducts=${storeProductList.productList.length}",
            );

            if (storeProductList.productList.isNotEmpty) {
              // Group fallback products by category so that the UI can still
              // render them in a tabbed / category-wise layout similar to
              // the store-details payload.
              final Map<int, List<ProductListItem>> productsByCategory = {};
              final Map<int, String> categoryNames = {};

              for (final product in storeProductList.productList) {
                final catId = product.categoryId;
                final catName =
                    (product.categoryName.isNotEmpty ? product.categoryName : "All Products");

                productsByCategory.putIfAbsent(catId, () => []).add(product);
                categoryNames[catId] = catName;
              }

              final List<CategoryWiseProductListItem> fallbackCategories = [];

              productsByCategory.forEach((catId, products) {
                final catName = categoryNames[catId] ?? "All Products";

                final subCategory = SubCategoryWiseProductListItem(
                  subCategoryId: catId,
                  subCategoryName: catName,
                  subCategoryIcon: "",
                  isShowMore: false,
                  productList: products,
                );

                final category = CategoryWiseProductListItem(
                  categoryId: catId,
                  categoryName: catName,
                  categoryIcon: "",
                  isShowMore: false,
                );
                category.setProductList([subCategory]);

                fallbackCategories.add(category);
              });

              response.setCategoryWiseProductList(fallbackCategories);

              logd(
                tag,
                "Injected fallback category-wise list with "
                "${storeProductList.productList.length} total products "
                "across ${fallbackCategories.length} categories.",
              );
            } else {
              logd(
                tag,
                "Fallback store-product-list returned NO products for storeId=$storeId.",
              );
            }
          } catch (e) {
            logd(tag, "Fallback store-product-list failed: $e");
          }
        } else {
          logd(
            tag,
            "Using category_wise_product_list from store-details directly.",
          );
        }

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _subject.sink.add(ApiResponse.completed(response));
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  addOrderCart(int productId, int quantity) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
      return;
    }

    try {
      final bool added = await addToCartResolvingStoreConflict(
        context: context,
        storeId: storeId,
        productId: productId,
        quantity: quantity,
      );

      if (!state.mounted) return;
      if (added) {
        await getOrderCart();
      }
    } catch (e) {
      logd(tag, e.toString());
      if (!state.mounted) return;
      openSimpleSnackbar(e.toString());
    }
  }

  getOrderCart() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = UserOrderCartPojo.fromJson(
            await OrderCartRepo().callOrderCartApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _orderCartSubject.sink.add(ApiResponse.completed(response));
        } else {
          _orderCartSubject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _orderCartSubject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _orderCartSubject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  getStoreReviewList() async {
    try {
      var response = StoreReviewListPojo.fromJson(
          await _storeDetailRepo.callStoreReviewApi(storeId));

      if (!state.mounted) return;
      String message =
          getApiMsg(context, response.messageCode, response.message);
      if (isApiStatus(context, response.status, message, true,
          showMess: false)) {
        changeStoreRatingList(response.storeRatingList);
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }

  setFavouriteStore(int storeId, int isFavourite) async {
    if (isGuestUser()) {
      await showGuestLoginSheet(context, prompt: GuestLoginPrompt.favorites);
      return;
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectAddFavourite.sink.add(ApiResponse.loading());
      try {
        var response = ModelAddFavourite.fromJson(
            await _storeDetailRepo.callAddFavourite(storeId, isFavourite));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _subject.value.data!.setIsFavourite(response.isFavourite);
          _subject.sink.add(ApiResponse.completed(_subject.value.data));
          _subjectAddFavourite.sink.add(ApiResponse.completed(response));
        } else {
          _subjectAddFavourite.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectAddFavourite.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  callBrandListApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectBrand.sink.add(ApiResponse.loading());
      try {
        var response =
            BrandCategoryPojo.fromJson(await _dsHomeRepo.callBrandListApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectBrand.sink.add(ApiResponse.completed(response));
        } else {
          _subjectBrand.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectBrand.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  changeFilterVeg(bool value) {
    if (value) {
      getStoreDetail(1, isLoading: false);
    } else {
      getStoreDetail(0, isLoading: false);
    }
    _filterVegController.sink.add(value);
  }

  @override
  void dispose() {
    _filterVegController.close();
    showCuisineButton.close();
    showCuisineText.close();
    _subject.close();
    _subjectAddFavourite.close();
    _storeRatingListController.close();
  }
}
