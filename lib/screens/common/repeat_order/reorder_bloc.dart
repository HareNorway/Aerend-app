import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../dialogs/simple_dialog_util.dart';
import '../../../redux/store.dart';
import '../../../utils/utils.dart';
import '../../deliveryService/checkout/cart_dl.dart';
import '../../deliveryService/checkout/checkout.dart';
import '../../deliveryService/storeDetail/store_detail_dl.dart';
import 'reorder_dl.dart';

class ReorderBloc extends Bloc {
  final _subject = BehaviorSubject<ApiResponse<ReorderDl>>();
  BuildContext? context;

  ReorderBloc() {
    context = navigatorKey.currentContext;
  }

  BehaviorSubject<ApiResponse<ReorderDl>> get subject => _subject;

  getReorderDetail(int orderId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var reOrder = await ApiBaseHelper().post(
          ApiConst.endPointOdReOrder,
          body: {
            ApiParam.paramUserId: prefGetInt(prefUserId),
            ApiParam.paramAccessToken: prefGetString(prefAccessToken),
            ApiParam.paramOrderId: orderId,
          },
        );
        var response = ReorderDl.fromJson(reOrder);

        String message =
            getApiMsg(context!, response.messageCode, response.message);
        if (isApiStatus(context!, response.status, message, true)) {
          addProducts(response);
          _subject.sink.add(ApiResponse.completed(response));
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        openSimpleSnackbar(e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  addProducts(ReorderDl reorderDl) {
    String selectedStoreDetails = prefGetString(prefSelectedStoreFullResponse);
    if (selectedStoreDetails.trim().isNotEmpty) {
      StoreDetailsPojo selectedStoreDetailsPojo = StoreDetailsPojo.fromJson(
          jsonDecode(prefGetString(prefSelectedStoreFullResponse)));
      if (selectedStoreDetailsPojo.storeId != reorderDl.storeId) {
        updateCartDialog(reorderDl);
      } else {
        StoreProvider.of<AppState>(context!).dispatch(ClearCartItem());
        prefSetString(prefSelectedStoreFullResponse, "");
        addProduct(reorderDl);
      }
    } else {
      addProduct(reorderDl);
    }
  }

  addProduct(ReorderDl reorderDl) {
    StoreDetailsPojo storeDetailsPojo = StoreDetailsPojo(
      status: reorderDl.status,
      message: reorderDl.message,
      messageCode: reorderDl.messageCode,
      storeId: reorderDl.storeId,
      storeName: reorderDl.storeName,
      storeBanner: reorderDl.storeBanner,
      storeStatus: reorderDl.storeStatus,
      averageRating: reorderDl.averageRating,
      description: reorderDl.description,
      deliveryTime: reorderDl.deliveryTime,
      orderMinAmount: reorderDl.orderMinAmount,
      offer: reorderDl.offer,
      offerMinAmount: reorderDl.offerMinAmount,
      offerPercentage: reorderDl.offerPercentage,
      address: reorderDl.address,
      latitude: reorderDl.latitude,
      longitude: reorderDl.longitude,
      packagingCharges: reorderDl.packagingCharges,
      productCategory: reorderDl.productCategory,
      isFavourite: reorderDl.isFavStore,
      takenAwayType: reorderDl.takenAwayType,
    );

    storeDetailsPojo.setCartsSelectedStoreCateId(reorderDl.serviceCategoryId);
    storeDetailsPojo.setStoreCatName(reorderDl.serviceCategoryName);
    storeDetailsPojo.setStoreCatIcon(reorderDl.serviceCategoryIcon);

    prefSetString(prefSelectedStoreFullResponse, jsonEncode(storeDetailsPojo));

    for (var element in reorderDl.orderDetail) {
      StoreProvider.of<AppState>(context!).dispatch(AddItemInCart(
          cartItem: CartItem(
              prodId: element.productId,
              prodQuantity: element.productQuantity,
              prodCustomizeSize: element.productSizeIds,
              prodTotalAmount: getDoubleFromDynamic(element.productAmount),
              prodCustomizeOption: element.productOptionIds,
              prodCustomizeToppings: element.productToppingsIds,
              productName: element.productName)));
    }
    openScreen(context!, const CheckOut());
  }

  updateCartDialog(ReorderDl reorderDl) {
    showDialog(
        context: context!,
        builder: (BuildContext context) {
          return SimpleDialogUtil(
            title: languages.updateCart,
            message: languages.updateCartMsg,
            positiveButtonTxt: languages.proceed,
            negativeButtonTxt: languages.cancel,
            onPositivePress: () {
              StoreProvider.of<AppState>(context).dispatch(ClearCartItem());
              prefSetString(prefSelectedStoreFullResponse, "");
              Navigator.pop(context, true);
              addProduct(reorderDl);
            },
            onNegativePress: () {
              Navigator.pop(context, true);
            },
          );
        });
  }

  @override
  void dispose() {
    _subject.close();
  }
}
