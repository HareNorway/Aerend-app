import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_dl.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_repo.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_repo.dart';
import 'package:aerend_customer/screens/common/manageAddress/add_new_address_repo.dart';

import '../../../blocs/bloc.dart';
import '../../../dialogs/demo_dialog.dart';
import '../../../dialogs/warning_dialog.dart';
import '../../../utils/utils.dart';
import 'home_dl.dart';
import 'home_repo.dart';
import '../swipeAerend/swipe_aerend_repo.dart';
import '../swipeAerend/swipe_aerend_dl.dart';

class HomeBloc extends Bloc {
  late BuildContext context;
  late bool isHareExplore;
  final HomeRepo _homeRepo = HomeRepo();
  final SwipeAerendRepo _swipeAerendRepo = SwipeAerendRepo();
  late ScrollController scrollController = ScrollController();

  final subjectHareSwipe = BehaviorSubject<ApiResponse<HareSwipeListPojo>>();
  final subjectHareExplore = BehaviorSubject<ApiResponse<HareExplorePojo>>();

  final subjectHomeCat = BehaviorSubject<ApiResponse<HomeCatePojo>>();
  final subjectTrackOrder = BehaviorSubject<ApiResponse<HomeTrackOrderPojo>>();
  final selectedPosController = BehaviorSubject<int>.seeded(0);

  final _subject = BehaviorSubject<ApiResponse<StoreDetailsPojo>>();
  // final _orderCartSubject = BehaviorSubject<ApiResponse<UserOrderCartPojo>>();
  final _addressListController = BehaviorSubject<List<AddressListItem>>();
  final _deliveryAddressController = BehaviorSubject<AddressListItem>();
  final GlobalKey one = GlobalKey();

  Stream<List<AddressListItem>?> get addressList =>
      _addressListController.stream;

  Stream<AddressListItem?> get deliveryAddress =>
      _deliveryAddressController.stream;

  String addressLine = "";
  String versionName = "";
  late DateTime dateTime;

  final GlobalKey exclusiveOfferKey = GlobalKey();

  State<StatefulWidget> state;

  HomeBloc(this.context, this.state, this.isHareExplore) {
    _initialize();
  }

  void _emitCachedHomeCategoriesIfAvailable() {
    final String cachedJson = prefGetString(prefHomeCategoryCache);
    if (cachedJson.trim().isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(cachedJson);
      if (decoded is! Map<String, dynamic>) return;
      final HomeCatePojo cached = HomeCatePojo.fromJson(decoded);
      if (cached.services.isEmpty) return;
      subjectHomeCat.sink.add(ApiResponse.completed(cached));
    } catch (_) {
      // Ignore malformed cache and continue with network fetch.
    }
  }

  void _cacheHomeCategories(HomeCatePojo response) {
    try {
      prefSetString(prefHomeCategoryCache, jsonEncode(response.toJson()));
    } catch (_) {
      // Cache failures should never block home rendering.
    }
  }

  Future<void> _initialize() async {
    _emitCachedHomeCategoriesIfAvailable();
    await Future.wait<void>([
      callHomeCateApi(),
      getHareSwipeList(),
      getHareExploreList(),
      callHomeTrackOrderApi(),
    ]);
    firebaseAuth().then((value) {
      setFCMToken();
    });
    getAddressList();
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
          openSimpleSnackbar(
            response.message,
            onPressed: () =>
                openScreenWithResult(context, const HomeMainV1(homeIndex: 1)),
          );
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

  getAddressList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = AddressListPojo.fromJson(
            await ManageAddressRepo().callAddressListApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _addressListController.sink.add(response.addressList);
          updateDeliveryAddress();
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

  deleteAddress(int addressId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = AddressListPojo.fromJson(
            await ManageAddressRepo().callDeleteAddressApi(addressId));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _addressListController.sink.add(response.addressList);
          // getAddressList();
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

  getHareSwipeList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      subjectHareSwipe.sink.add(ApiResponse.loading());
      try {
        final response = HareSwipeListPojo.fromJson(
            await _swipeAerendRepo.callHareSwipeApi(
                prefGetLatLng().latitude, prefGetLatLng().longitude));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          subjectHareSwipe.sink.add(ApiResponse.completed(response));
        } else {
          subjectHareSwipe.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        subjectHareSwipe.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  getHareExploreList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      subjectHareExplore.sink.add(ApiResponse.loading());
      try {
        final response = HareExplorePojo.fromJson(
            await _swipeAerendRepo.callHareExploreApi(
                prefGetLatLng().latitude, prefGetLatLng().longitude));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          subjectHareExplore.sink.add(ApiResponse.completed(response));
        } else {
          subjectHareExplore.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        subjectHareExplore.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  callHomeCateApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (!subjectHomeCat.hasValue ||
          subjectHomeCat.value.status != Status.completed) {
        subjectHomeCat.sink.add(ApiResponse.loading());
      }
      try {
        if (versionName.trim().isEmpty) {
          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          versionName = packageInfo.version;
        }
        final currentLatLng = prefGetLatLng();
        var response = HomeCatePojo.fromJson(
            await _homeRepo.homeApi(
              appVersion: versionName,
              lat: currentLatLng.latitude,
              lng: currentLatLng.longitude,
            ));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _cacheHomeCategories(response);
          subjectHomeCat.sink.add(ApiResponse.completed(response));
        } else {
          subjectHomeCat.sink.add(ApiResponse.error(message));
          if (response.status != 3) openSimpleSnackbar(message);
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        subjectHomeCat.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  callHomeTrackOrderApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      subjectTrackOrder.sink.add(ApiResponse.loading());
      try {
        var response =
            HomeTrackOrderPojo.fromJson(await _homeRepo.homeTrackOrderApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          subjectTrackOrder.sink.add(ApiResponse.completed(response));
        } else {
          subjectTrackOrder.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        subjectTrackOrder.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  updateDeliveryAddress({int addressId = 0}) {
    final list = _addressListController.hasValue
        ? _addressListController.value
        : <AddressListItem>[];
    if (addressId != 0) {
      prefSetInt(prefNewDeliveryAddressId, addressId);
    } else {
      addressId = prefGetInt(prefNewDeliveryAddressId);
    }
    AddressListItem selectedAddress;
    if (list.isNotEmpty) {
      selectedAddress = list.firstWhere(
        (address) => address.addressId == addressId,
        orElse: () => list.first,
      );
    } else {
      selectedAddress = AddressListItem(
        address: 'Velg Adresse',
        lat: prefGetLatLng().latitude.toString(),
        long: prefGetLatLng().longitude.toString(),
      );
    }
    prefSetInt(prefNewDeliveryAddressId, selectedAddress.addressId);
    final lat = double.tryParse(selectedAddress.lat) ?? prefGetLatLng().latitude;
    final long = double.tryParse(selectedAddress.long) ?? prefGetLatLng().longitude;
    prefSetLatLng(LatLng(lat, long));
    prefSetString(prefNewDeliveryAddress, jsonEncode(selectedAddress.toJson()));
    _deliveryAddressController.sink.add(selectedAddress);
    callHomeCateApi();
    getHareSwipeList();
    getHareExploreList();
    callHomeTrackOrderApi();
  }

  openShowcaseView(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([one]);
  }

  closeShowcaseView() {
    if (scContext != null) ShowCaseWidget.of(scContext!).dismiss();
  }

  openSupportWhatsapp() {
    String url = "https://wa.me/+917984931943?text=${Uri.parse("Hii")}";
    openUrl(url);
  }

  openDemoDialog() {
    Future.delayed(const Duration(seconds: 1), () {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const WarningDialog();
          }).then((value) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              prefSetBool(prefDemoDialogOpen, true);
              return const DemoDialog();
            }).then((value) {
          openShowcaseView(scContext!);
        });
      });
    });
  }

  getCurrentLocation() async {
    getLocationUtils.getLocationUtils((locationData) {},
        (locationData, address) async {
      try {
        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        prefSetLatLng(latLng);
        final response = await AddNewAddressRepo()
          .callAddAddressApi(address, 'home', latLng, 'current-location', address);
        if (response['status'] == 1) {
          final newAddressId = response['address_id'] ?? 0;
          prefSetInt(prefNewDeliveryAddressId, newAddressId);
          await getAddressList();
          updateDeliveryAddress(addressId: newAddressId);
          if (state.mounted) Navigator.pop(context);
        } else {
          openSimpleSnackbar(response['message'] ?? 'Unable to save address');
        }
      } catch (e) {
        openSimpleSnackbar(e.toString());
      }
    }, getForceFully: true);
  }

  onRefresh() async {
    callHomeCateApi();
    getHareSwipeList();
    getHareExploreList();
  }

  @override
  void dispose() {
    subjectHomeCat.close();
    selectedPosController.close();
    scrollController.dispose();
  }
}
