import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:aerend_customer/screens/common/swipeAerend/swipe_aerend_dl.dart';
import 'package:aerend_customer/screens/common/swipeAerend/swipe_aerend_repo.dart';
import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../../common/home/home_dl.dart';
import '../../common/home/home_repo.dart';
import '../../rideService/rideAddLocation/ride_add_location.dart';
import '../searchStore/search_store.dart';
import 'ds_home.dart';
import 'ds_home_dl.dart';
import 'ds_home_repo.dart';
import 'filter_model.dart';

class DSHomeBloc extends Bloc {
  String tag = "DSHomeBloc>>>";
  late BuildContext context;

  LatLng? selectedLatLng;
  String? filterKey;

  final DSHomeRepo _dsHomeRepo = DSHomeRepo();
  final HomeRepo _homeRepo = HomeRepo();

  final isFiltered = BehaviorSubject<bool>();
  List<FilterModel> filterCuisine = [];
  List<FilterModel> filterList = [];

  List<FilterModel> filterSort = [];

  State<DSHome> state;

  DSHomeBloc(this.context, this.state) {
    callStoreCategoryListApi();
    if (prefGetInt(prefSelectedServiceCateId) == 6) {
      callBrandListApi();
    }
    homeStoreListApiCall(null, null);
    // getCurrentLocation();
    // getSortFilterList();
    // getHareSwipeList();
  }

  List<SortFilterItem>? listSortFilter;
  List<DsProductCategoryListItem>? listFilterCuisine;
  final _selectedLocationController = BehaviorSubject<String>();
  final _sortFilterListController = BehaviorSubject<List<SortFilterItem>>();
  final _userNameController = BehaviorSubject<String>();
  final _userImageController = BehaviorSubject<String>();
  final _selectedPosController = BehaviorSubject<int>.seeded(0);
  final _tabControllerLength = BehaviorSubject<int>.seeded(0);
  final _subject = BehaviorSubject<ApiResponse<DsHomeStoreListPojo>>();
  final _subjectHareSwipe = BehaviorSubject<ApiResponse<HareSwipeListPojo>>();
  final _swipeListController = BehaviorSubject<List<SwipeCardModel>>();
  final _subjectFeaturedStore =
      BehaviorSubject<ApiResponse<FeaturedStorePojo>>();
  final _subjectFavouriteStore =
      BehaviorSubject<ApiResponse<FavouriteStorePojo>>();
  final _subjectProductCat =
      BehaviorSubject<ApiResponse<ProductCategoryPojo>>();
  final _subjectStoreCat = BehaviorSubject<ApiResponse<StoreCategoryPojo>>();
  final _subjectBrand = BehaviorSubject<ApiResponse<BrandCategoryPojo>>();

  BehaviorSubject<ApiResponse<FeaturedStorePojo>> get subjectFeaturedStore =>
      _subjectFeaturedStore;

  BehaviorSubject<ApiResponse<FavouriteStorePojo>> get subjectFavouriteStore =>
      _subjectFavouriteStore;

  BehaviorSubject<ApiResponse<ProductCategoryPojo>> get subjectProductCat =>
      _subjectProductCat;

  BehaviorSubject<ApiResponse<StoreCategoryPojo>> get subjectStoreCat =>
      _subjectStoreCat;

  BehaviorSubject<ApiResponse<BrandCategoryPojo>> get subjectBrand =>
      _subjectBrand;

  Stream<int> get selectedPos => _selectedPosController.stream;

  Stream<int> get tabControllerLength => _tabControllerLength.stream;

  Stream<List<SwipeCardModel>> get swipeList => _swipeListController.stream;

  Function(int) get changeSelectedPos => _selectedPosController.sink.add;

  BehaviorSubject<ApiResponse<DsHomeStoreListPojo>> get subject => _subject;

  Stream<List<SortFilterItem>> get sortFilterList =>
      _sortFilterListController.stream;

  Stream<String> get userName => _userNameController.stream;

  Stream<String> get userImage => _userImageController.stream;

  Stream<String> get selectedLocation => _selectedLocationController.stream;

  Function(String) get changeUserName => _userNameController.sink.add;

  Function(String) get changeUserImage => _userImageController.sink.add;

  Function(String) get changeSelectedLocation =>
      _selectedLocationController.sink.add;

  callFeatureStoreApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectFeaturedStore.sink.add(ApiResponse.loading());
      try {
        var response = FeaturedStorePojo.fromJson(
            await _homeRepo.homeFeaturedApi(
                selectedLatLng?.latitude ?? 0, selectedLatLng?.longitude ?? 0,
                serviceCatId: prefGetInt(prefSelectedServiceCateId)));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectFeaturedStore.sink.add(ApiResponse.completed(response));
        } else {
          _subjectFeaturedStore.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectFeaturedStore.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  callFavouriteStoreApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectFavouriteStore.sink.add(ApiResponse.loading());
      try {
        var response = FavouriteStorePojo.fromJson(
            await _dsHomeRepo.callFavouriteStoreApi(0, 1));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectFavouriteStore.sink.add(ApiResponse.completed(response));
        } else {
          _subjectFavouriteStore.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectFavouriteStore.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  callStoreCategoryListApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectStoreCat.sink.add(ApiResponse.loading());
      try {
        var response = StoreCategoryPojo.fromJson(
            await _dsHomeRepo.callStoreCategoryListApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectStoreCat.sink.add(ApiResponse.completed(response));
        } else {
          _subjectStoreCat.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectStoreCat.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
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

  // callStoreProductCatListApi() async {
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult != ConnectivityResult.none) {
  //     _subjectProductCat.sink.add(ApiResponse.loading());
  //     try {
  //       var response = ProductCategoryPojo.fromJson(
  //           await _dsHomeRepo.callStoreProductCatListApi());

  //       if (!state.mounted) return;
  //       String message =
  //           getApiMsg(context, response.messageCode, response.message);
  //       if (isApiStatus(context, response.status, message, true,
  //           showMess: false)) {
  //         List<FilterModel> tmp = filterCuisine
  //             .map((e) => FilterModel(
  //                 filter: e.filter,
  //                 filterName: e.filterName,
  //                 isSelect: e.isSelect))
  //             .toList();
  //         filterCuisine.clear();
  //         for (var element in response.productCategoryList) {
  //           var firstWhere = tmp.firstWhere(
  //             (ele) {
  //               logd(tag, "--- ${ele.filter} ${ele.isSelect}");
  //               return (ele.filter == "${element.productCategoryId}") &&
  //                   ele.isSelect;
  //             },
  //             orElse: () {
  //               logd(tag, "else ${element.productCategoryName}");
  //               return FilterModel(
  //                   filter: "${element.productCategoryId}",
  //                   filterName: element.productCategoryName,
  //                   isSelect: false);
  //             },
  //           );
  //           logd(tag,
  //               "filter  ${tmp.length} =>${firstWhere.filterName},${firstWhere.id} - ${firstWhere.isSelect}");

  //           // filterCuisine.add(FilterModel(id: element.categoryId,filter: "${element.categoryId}", filterName: "${element.categoryName}", isSelect: false));
  //           filterCuisine.add(firstWhere);
  //         }
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

  getSortFilterList() {
    listSortFilter = [
      SortFilterItem(0, languages.rating, false, "rating"),
      SortFilterItem(1, languages.deliveryTime, false, "delivery_time"),
      SortFilterItem(2, languages.costLowHigh, false, "cost_low_to_high"),
      SortFilterItem(3, languages.costHighLow, false, "cost_high_to_low"),
    ];

    filterSort.add(FilterModel(
        filter: "cost_high_to_low",
        filterName: languages.priceHighToLow,
        isSelect: false));
    filterSort.add(FilterModel(
        filter: "cost_low_to_high",
        filterName: languages.priceLowToHigh,
        isSelect: false));
    filterSort.add(FilterModel(
        filter: "near_by", filterName: languages.nearBy, isSelect: false));
    filterSort.add(FilterModel(
        filter: "delivery_time",
        filterName: languages.deliveryTime,
        isSelect: false));
    filterSort.add(FilterModel(
        filter: "rating", filterName: languages.rating, isSelect: false));

    filterList.add(FilterModel(
        filter: "open_now", filterName: languages.openNow, isSelect: false));
    filterList.add(FilterModel(
        filter: "offer", filterName: languages.offers, isSelect: false));
    filterList.add(FilterModel(
        filter: "order_delivery",
        filterName: languages.filterOrderDelivery,
        isSelect: false));
    filterList.add(FilterModel(
        filter: "order_takeaway",
        filterName: languages.filterOrderTakeAway,
        isSelect: false));

    _sortFilterListController.sink.add(listSortFilter!);
  }

  getCurrentLocation() async {
    _subject.add(ApiResponse.loading());
    getLocationUtils.getLocationUtils((locationData) {},
        (locationData, address) {
      changeSelectedLocation(address);
      selectedLatLng = LatLng(locationData.latitude!, locationData.longitude!);
      callStoreCategoryListApi();
      // homeStoreListApiCall();
      // callFeatureStoreApi();
      // callFavouriteStoreApi();
    });
  }

  getHareSwipeList({bool isLoading = true}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (isLoading) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        final response = HareSwipeListPojo.fromJson(await SwipeAerendRepo()
            .callHareSwipeApi(
                prefGetLatLng().latitude, prefGetLatLng().longitude));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _swipeListController.sink.add(response.swipeList);
          _subjectHareSwipe.sink.add(ApiResponse.completed(response));
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

  homeStoreListApiCall(int? storeCatId, int? brandId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.add(ApiResponse.loading());
      try {
        var response = DsHomeStoreListPojo.fromJson(
            await _dsHomeRepo.callHomeStoreApi(prefGetLatLng().latitude,
                prefGetLatLng().longitude, '', storeCatId, brandId));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          if (response.storeList.isNotEmpty) {
            _subject.sink.add(ApiResponse.completed(response));
          } else {
            _subject.sink.add(ApiResponse.error(
                prefGetInt(prefSelectedServiceCateId) == 5
                    ? languages.noAnyRestaurantFound
                    : languages.noAnyStoreFound));
          }
        } else {
          _subject.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  gotoSelectLocation() {
    openScreenWithResult(context, const RideAddLocation()).then((l) {
      if (l != null && l["lat_long"] != null) {
        LatLng latLng = l["lat_long"];
        String address = l["address"];
        selectedLatLng = latLng;
        if (address.isNotEmpty) {
          changeSelectedLocation(address);
        } else {
          getAddress(latLng.latitude, latLng.longitude).then((value) {
            String addressLine =
                '${value!.first.name!.isNotEmpty ? '${value.first.name!}, ' : ''}${value.first.thoroughfare!.isNotEmpty ? '${value.first.thoroughfare!}, ' : ''}${value.first.subLocality!.isNotEmpty ? '${value.first.subLocality!}, ' : ''}${value.first.locality!.isNotEmpty ? '${value.first.locality!}, ' : ''}${value.first.subAdministrativeArea!.isNotEmpty ? '${value.first.subAdministrativeArea!}, ' : ''}${value.first.postalCode!.isNotEmpty ? '${value.first.postalCode!}, ' : ''}${value.first.administrativeArea!.isNotEmpty ? value.first.administrativeArea : ''}';
            changeSelectedLocation(addressLine);
          });
        }
        callStoreCategoryListApi();
        // homeStoreListApiCall();
        // callFeatureStoreApi();
        // callFavouriteStoreApi();
      }
    });
  }

  refreshScreen() async {
    if (selectedLatLng == null) {
      getCurrentLocation();
    } else {
      callStoreCategoryListApi();
      // homeStoreListApiCall();
      // callFeatureStoreApi();
      // callFavouriteStoreApi();
    }
  }

  openSearchStoreScreen() {
    if (selectedLatLng != null) {
      openScreen(context, SearchStore(latLng: selectedLatLng!));
    }
  }

  @override
  void dispose() {
    _subjectProductCat.close();
    _subjectFeaturedStore.close();
    _subjectFavouriteStore.close();
    _userNameController.close();
    _userImageController.close();
    _sortFilterListController.close();
    _selectedPosController.close();
    _selectedLocationController.close();
    _tabControllerLength.close();
    isFiltered.close();
    _subject.close();
  }
}

class KeyVal {
  String img;
  String name;

  KeyVal(this.name, this.img);
}
