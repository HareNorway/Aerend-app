import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_dl.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_repo.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../home/ds_home_dl.dart';
import 'search_store_dl.dart';
import 'search_store_repo.dart';
import '../home/filter_model.dart';

class SearchStoreBloc extends Bloc {
  late BuildContext context;
  String tag = "SearchStoreBloc>>>";

  final SearchStoreRepo _searchStoreRepo = SearchStoreRepo();
  TextEditingController textEditingController = TextEditingController();
  final PagingController<int, ProductList> pagingController =
      PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  LatLng selectedLatLng;
  String lastInputValue = "";
  bool isFood = prefGetInt(prefSelectedServiceCateId) == 5;

  final State state;

  SearchStoreBloc(this.context, this.selectedLatLng, this.state) {
    pagingController.addPageRequestListener((pageKey) {
      searchProduct(pageKey, pagingController);
    });
    // pagingController.notifyPageRequestListeners(1);
    // callStoreProductCatListApi();

    textEditingController.addListener(() {
      var inputValue = textEditingController.text;
      if (lastInputValue != inputValue) {
        if (inputValue.trim().isNotEmpty) {
          lastInputValue = inputValue;
          searchStore();
          if (lastInputValue.trim().isNotEmpty) {
            pagingController.notifyPageRequestListeners(1);
          } else {
            pagingController.itemList = [];
            _subjectSearchProduct.sink.add(ApiResponse.error(isFood
                ? languages.noAnyDishesFound
                : languages.noAnyProductsFound));
          }
        } else {
          lastInputValue = "";
          _subjectSearchProduct.sink.add(ApiResponse.error(isFood
              ? languages.noAnyDishesFound
              : languages.noAnyProductsFound));
          _subject.sink.add(ApiResponse.error(isFood
              ? languages.noAnyRestaurantFound
              : languages.noAnyStoreFound));
        }
      }
    });
  }

  // final _storeSearchController = BehaviorSubject<String>();
  final _storeListController = BehaviorSubject<List<StoreListItem>>();
  final _subject = BehaviorSubject<ApiResponse<DsHomeStoreListPojo>>();
  final _subjectSearchProduct =
      BehaviorSubject<ApiResponse<SearchProductPojo>>();
  final _subjectProductCat =
      BehaviorSubject<ApiResponse<ProductCategoryPojo>>();

  List<FilterModel> filterCuisine = [];

  BehaviorSubject<ApiResponse<DsHomeStoreListPojo>> get subject => _subject;

  BehaviorSubject<ApiResponse<SearchProductPojo>> get subjectSearchProduct =>
      _subjectSearchProduct;

  BehaviorSubject<ApiResponse<ProductCategoryPojo>> get subjectProductCat =>
      _subjectProductCat;

  // Stream<String> get storeSearch => _storeSearchController.stream;

  Stream<List<StoreListItem>> get storeList => _storeListController.stream;

  // Function(String) get changeStoreSearch => _storeSearchController.sink.add;

  searchStore() async {
    if (lastInputValue.trim().length >= 2) {
      // FocusManager.instance.primaryFocus.unfocus();
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        _subject.sink.add(ApiResponse.loading());
        try {
          if (lastInputValue.trim().length >= 2) {
            var response = DsHomeStoreListPojo.fromJson(
                await _searchStoreRepo.callSearchStoreApi(
                    selectedLatLng.latitude,
                    selectedLatLng.longitude,
                    lastInputValue));

            String message = response.message;

            if (!state.mounted) return;
            if (isApiStatus(context, response.status, message, true,
                showMess: false)) {
              if ((response.storeList).isNotEmpty) {
                if (lastInputValue.isNotEmpty) {
                  _subject.sink.add(ApiResponse.completed(response));
                  _storeListController.sink.add(response.storeList);
                } else {
                  _subject.sink.add(ApiResponse.error(isFood
                      ? languages.noAnyRestaurantFound
                      : languages.noAnyStoreFound));
                }
              } else {
                _subject.sink.add(ApiResponse.error(isFood
                    ? languages.noAnyRestaurantFound
                    : languages.noAnyStoreFound));
              }
            } else {
              _subject.sink.add(ApiResponse.error(isFood
                  ? languages.noAnyRestaurantFound
                  : languages.noAnyStoreFound));
            }
          }
        } catch (e) {
          _subject.sink.add(ApiResponse.error(isFood
              ? languages.noAnyRestaurantFound
              : languages.noAnyStoreFound));
        }
      } else {
        _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
        if (!state.mounted) return;
        openSimpleSnackbar(languages.internetConnLostTitle);
      }
    } else {
      _storeListController.sink.add([]);
    }
  }

  addOrderCart(int storeId, int productId, int quantity) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = UserOrderCartPojo.fromJson(await StoreDetailRepo()
            .callOrderCartApi(storeId, productId, quantity));

        if (!state.mounted) return;
        if (response.messageCode == 9 || response.messageCode == 5) {
          openSimpleSnackbar(response.message);
        } else if (response.messageCode == 1) {
          openSimpleSnackbar(response.message);
          logd(tag, response.message);
          HomeMainV1State? homeState =
              context.findAncestorStateOfType<HomeMainV1State>();
          if (homeState != null) {
            prefSetInt(prefCartCount, response.countOrder);
            homeState.badgeCountNotifier.value = response.countOrder;
          }
        } else if (response.messageCode == 412) {
          logd(tag, response.message);
          openSimpleSnackbar(response.message);
        }
      } catch (e) {
        logd(tag, e.toString());
        openSimpleSnackbar(e.toString());
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  // callStoreProductCatListApi() async {
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult != ConnectivityResult.none) {
  //     _subjectProductCat.sink.add(ApiResponse.loading());
  //     try {
  //       var response = ProductCategoryPojo.fromJson(
  //           await DSHomeRepo().callStoreProductCatListApi());

  //       if (!state.mounted) return;
  //       String message =
  //           getApiMsg(context, response.messageCode, response.message);
  //       if (isApiStatus(context, response.status, message, true,
  //           showMess: false)) {
  //         // List<FilterModel> tmp = filterCuisine
  //         //     .map((e) => FilterModel(
  //         //         filter: e.filter,
  //         //         filterName: e.filterName,
  //         //         isSelect: e.isSelect))
  //         //     .toList();
  //         // filterCuisine.clear();
  //         // for (var element in response.productCategoryList) {
  //         //   var firstWhere = tmp.firstWhere(
  //         //     (ele) {
  //         //       logd(tag, "--- ${ele.filter} ${ele.isSelect}");
  //         //       return (ele.filter == "${element.productCategoryId}") &&
  //         //           ele.isSelect;
  //         //     },
  //         //     orElse: () {
  //         //       logd(tag, "else ${element.productCategoryName}");
  //         //       return FilterModel(
  //         //           filter: "${element.productCategoryId}",
  //         //           filterName: element.productCategoryName,
  //         //           isSelect: false);
  //         //     },
  //         //   );
  //         //   logd(tag,
  //         //       "filter  ${tmp.length} =>${firstWhere.filterName},${firstWhere.id} - ${firstWhere.isSelect}");

  //         //   // filterCuisine.add(FilterModel(id: element.categoryId,filter: "${element.categoryId}", filterName: "${element.categoryName}", isSelect: false));
  //         //   filterCuisine.add(firstWhere);
  //         // }
  //         _subjectProductCat.sink.add(ApiResponse.completed(response));
  //       } else {
  //         _subjectProductCat.sink.add(ApiResponse.error(message));
  //       }
  //     } catch (e) {
  //       logd(tag, e.toString());
  //       // openSimpleSnackbar( e.toString());
  //       _subjectProductCat.sink.add(ApiResponse.error(e.toString()));
  //     }
  //   } else {
  //     if (!state.mounted) return;
  //     openSimpleSnackbar(languages.internetConnLostTitle);
  //   }
  // }

  searchProduct(int currentPage,
      PagingController<int, ProductList> pagingController) async {
    // FocusManager.instance.primaryFocus.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (currentPage == 1) {
        _subjectSearchProduct.sink.add(ApiResponse.loading());
      }
      try {
        if (lastInputValue.isNotEmpty) {
          var response = SearchProductPojo.fromJson(
              await _searchStoreRepo.callSearchProductApi(
                  selectedLatLng.latitude,
                  selectedLatLng.longitude,
                  currentPage,
                  lastInputValue));

          String message = response.message;

          if (!state.mounted) return;
          if (isApiStatus(context, response.status, message, true,
              showMess: false)) {
            bool isLastPage = currentPage == response.lastPage;
            if (currentPage == 1) {
              pagingController.itemList = [];
            }
            if (isLastPage) {
              pagingController.appendLastPage(response.productList);
            } else {
              int nextPageKey = currentPage + 1;
              pagingController.appendPage(response.productList, nextPageKey);
            }
            if ((response.productList).isNotEmpty) {
              if (lastInputValue.isNotEmpty) {
                _subjectSearchProduct.sink.add(ApiResponse.completed(response));
              } else {
                _subjectSearchProduct.sink.add(ApiResponse.error(isFood
                    ? languages.noAnyDishesFound
                    : languages.noAnyProductsFound));
              }
            } else {
              _subjectSearchProduct.sink.add(ApiResponse.error(isFood
                  ? languages.noAnyDishesFound
                  : languages.noAnyProductsFound));
            }
          } else {
            _subjectSearchProduct.sink.add(ApiResponse.error(isFood
                ? languages.noAnyDishesFound
                : languages.noAnyProductsFound));
          }
        }
      } catch (e) {
        _subjectSearchProduct.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subjectSearchProduct.sink
          .add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
    _subjectSearchProduct.close();
    textEditingController.dispose();
    _storeListController.close();
  }
}
