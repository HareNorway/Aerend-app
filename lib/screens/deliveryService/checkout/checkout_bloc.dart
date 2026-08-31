import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:aerend_customer/screens/deliveryService/trackOrder/track_order.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/common_view.dart';
import '../../../dialogs/simple_dialog_util.dart';
import '../../../redux/store.dart';
import '../../../utils/utils.dart';
import '../../common/base_dl.dart';
import '../../common/manageAddress/manage_address.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../common/manageAddress/manage_address_repo.dart';
import '../../common/selectPaymentMethod/select_payment_method.dart';
import '../../common/wallet/my_wallet_repo.dart';
import '../../common/wallet/wallet_dl.dart';

// import '../../rideService/rideBook/ride_book_dl.dart';
import '../../rideService/rideBook/ride_book_dl.dart';
import '../storeDetail/store_detail_dl.dart';
import 'cart_dl.dart';
import 'checkout.dart';
import 'checkout_dl.dart';
import 'checkout_preview_utils.dart';
import 'checkout_repo.dart';

bool _vippsInitiateApiOk(dynamic status) {
  if (status == null) return false;
  if (status is int) return status == 1;
  if (status is num) return status.toInt() == 1;
  return status.toString().trim() == '1';
}

class CheckOutBloc extends Bloc {
  String tag = "CheckOutBloc>>>";
  BuildContext context;
  final CheckoutRepo _checkoutRepo = CheckoutRepo();
  final MyWalletRepo _myWalletRepo = MyWalletRepo();
  bool showAddAddressBtn = false;
  double walletAmount = 0, totalPay = 0;
  int maxAddressLimit = 0;
  int addressListLength = 0;
  CurrentAddressPojo? currentAddressPojo;
  var tipController = TextEditingController();

  var additionalInfo = TextEditingController();

  State<CheckOut> state;

  CheckOutBloc(this.context, this.state) {
    getAddressList();
  }

  /// Reload address + totals after guest signs in on checkout.
  Future<void> refreshAfterGuestAuth() async {
    await getAddressList();
  }

  void syncTotalPayFromPreview(dynamic data, {int orderType = 0}) {
    totalPay = checkoutPreviewGrossTotal(
      data,
      orderType: orderType,
      tip: getTip(),
    );
  }

  final _loadingPlaceOrder = BehaviorSubject<bool>.seeded(false);
  final _selectedAddressController = BehaviorSubject<AddressListItem?>();
  final _addressListController = BehaviorSubject<List<AddressListItem>>();
  final _selectedTakeAwayController = BehaviorSubject<int>.seeded(1);
  final _selectedPromoCodeIdController = BehaviorSubject<String>.seeded("");
  final _prescriptionImgController = BehaviorSubject<File>();
  final _subject = BehaviorSubject<ApiResponse>();
  final _subjectCartItemLoading =
      BehaviorSubject<ApiResponse<OrderPreviewPojo>>();
  final _subjectPlaceOrder = BehaviorSubject<ApiResponse<PlaceOrderPojo>>();
  final _subjectPlaceScheduleOrder =
      BehaviorSubject<ApiResponse<PlaceOrderPojo>>();
  final _keyValueListController = BehaviorSubject<List<KeyValueModel>>();
  final _promoCodeListController = BehaviorSubject<List<PromoCodeListItem>>();
  final _subjectApplyPromoCode =
      BehaviorSubject<ApiResponse<ApplyPromoCodePojo>>();
  final _tipController = BehaviorSubject<double>.seeded(0);

  Stream<double> get streamTip => _tipController.stream;

  Function(double) get changeTip => _tipController.sink.add;

  BehaviorSubject<ApiResponse> get subject => _subject;

  BehaviorSubject<ApiResponse<OrderPreviewPojo>> get subjectCartItemLoading =>
      _subjectCartItemLoading;

  BehaviorSubject<ApiResponse<PlaceOrderPojo>> get subjectPlaceOrder =>
      _subjectPlaceOrder;

  BehaviorSubject<ApiResponse<PlaceOrderPojo>> get subjectPlaceScheduleOrder =>
      _subjectPlaceScheduleOrder;

  Stream<AddressListItem?> get selectedAddress =>
      _selectedAddressController.stream;

  Stream<List<AddressListItem>?> get addressList =>
      _addressListController.stream;

  Stream<List<KeyValueModel>> get keyValueList =>
      _keyValueListController.stream;

  Stream<List<PromoCodeListItem>> get promoCodeList =>
      _promoCodeListController.stream;

  BehaviorSubject<ApiResponse<ApplyPromoCodePojo>> get subjectApplyPromoCode =>
      _subjectApplyPromoCode;

  Stream<int> get selectedTakeAway => _selectedTakeAwayController.stream;

  Stream<bool> get loadingPlaceOrder => _loadingPlaceOrder.stream;

  Stream<File> get prescriptionImg => _prescriptionImgController.stream;

  Stream<String> get selectedPromoCodeId =>
      _selectedPromoCodeIdController.stream;

  Function(List<KeyValueModel>) get changeKeyValueList =>
      _keyValueListController.sink.add;

  Function(List<PromoCodeListItem>) get changePromoCodeList =>
      _promoCodeListController.sink.add;

  Function(AddressListItem?) get changeSelectedAddress =>
      _selectedAddressController.sink.add;

  Function(File) get changePrescriptionImg =>
      _prescriptionImgController.sink.add;

  changeSelectedTakeAway(int takeAway) {
    if (takeAway == pickup) {
      tipController.text = "";
      changeTip(0);
    }
    _selectedTakeAwayController.sink.add(takeAway);
    // getOrderPreview(true);
  }

  changeSelectedPromoCodeId(String promoCode) {
    // if (promoCode.isNotEmpty) {
    //   applyPromoCodeApiCall(promoCode);
    // } else {
    _selectedPromoCodeIdController.sink.add(promoCode);
    // getOrderPreview(true);
    // }
  }

  changeDeliveryAddress(int addressId) {
    prefSetInt(prefNewDeliveryAddressId, addressId);

    AddressListItem? newDeliveryAddress;
    for (final item in _addressListController.value) {
      if (item.addressId == addressId) {
        newDeliveryAddress = item;
        break;
      }
    }
    if (newDeliveryAddress != null) {
      _selectedAddressController.sink.add(newDeliveryAddress);
    }
    getOrderPreview();
  }

  setDeliveryAddress() {
    if (prefGetString(prefNewDeliveryAddress).trim().isNotEmpty) {
      AddressListItem addressListItem = AddressListItem.fromJson(
          jsonDecode(prefGetString(prefNewDeliveryAddress)));
      changeSelectedAddress(addressListItem);
    } else {
      changeSelectedAddress(null);
    }
    // getOrderPreview(true);
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

  getAddressList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = AddressListPojo.fromJson(
            await ManageAddressRepo().callAddressListApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _addressListController.sink.add(response.addressList);
          maxAddressLimit = response.maxAddressLimit;
          addressListLength = response.addressList.length;

          AddressListItem? selected;
          final int savedAddressId = prefGetInt(prefNewDeliveryAddressId);
          if (savedAddressId != 0) {
            for (final item in response.addressList) {
              if (item.addressId == savedAddressId) {
                selected = item;
                break;
              }
            }
          }
          if (selected == null && response.addressList.isNotEmpty) {
            selected = response.addressList.first;
            prefSetInt(prefNewDeliveryAddressId, selected.addressId);
          }
          if (selected != null) {
            _selectedAddressController.sink.add(selected);
            await getOrderPreview();
          }
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

  getOrderPreview() async {
    if (prefGetInt(prefNewDeliveryAddressId) <= 0) {
      return;
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = await _checkoutRepo.callOrderPreviewApi();

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response["message_code"], response["message"]);
        if (isApiStatus(context, response['status'], message, true)) {
          if (response["service_category_id"] != null) {
            prefSetInt(
                prefSelectedServiceCateId, response["service_category_id"]);
          }
          final List<dynamic> orderList =
              (response['order_list'] as List?) ?? const <dynamic>[];
          if (orderList.isEmpty) {
            _subject.sink.add(ApiResponse.error(languages.cartEmptyMsg));
            return;
          }
          syncTotalPayFromPreview(response, orderType: 0);
          _subject.sink.add(ApiResponse.completed(response));
        } else {
          _subject.sink.add(ApiResponse.error(message));
          openSimpleSnackbar(message);
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
        openSimpleSnackbar(e.toString());
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  // getOrderPreview(bool showShimmer,
  //     {bool isFromOrderPlace = false, bool isScheduleOrder = false}) async {
  //   String productList = getProductList();
  //   if (productList.trim().isNotEmpty) {
  //     var connectivityResult = await (Connectivity().checkConnectivity());
  //     if (connectivityResult != ConnectivityResult.none) {
  //       if (showShimmer) {
  //         _subject.sink.add(ApiResponse.loading());
  //       } else {
  //         _subjectCartItemLoading.sink.add(ApiResponse.loading());
  //       }
  //       if (isFromOrderPlace) {
  //         if (isScheduleOrder) {
  //           _subjectPlaceScheduleOrder.sink.add(ApiResponse.loading());
  //         } else {
  //           _subjectPlaceOrder.sink.add(ApiResponse.loading());
  //         }
  //       }
  //       // logd(tag,"selected Address :${_selectedAddressController?.value?.toJson()?.toString()}");
  //       // logd(tag,"current Address :${currentAddressPojo.toJson().toString()}");

  //       try {
  //         StoreDetailsPojo storeDetailsPojo = StoreDetailsPojo.fromJson(
  //             jsonDecode(prefGetString(prefSelectedStoreFullResponse)));
  //         var response = OrderPreviewPojo.fromJson(
  //             await _checkoutRepo.callOrderPreviewApi(
  //                 storeDetailsPojo.cartsSelectedStoreCateId,
  //                 storeDetailsPojo.storeId,
  //                 _selectedPromoCodeIdController.value,
  //                 _selectedAddressController.value?.addressId ?? 0,
  //                 _selectedTakeAwayController.value,
  //                 getProductList(),
  //                 getTip()));

  //         if (isFromOrderPlace) {
  //           if (isScheduleOrder) {
  //             _subjectPlaceScheduleOrder.sink.add(ApiResponse.completed());
  //           } else {
  //             _subjectPlaceOrder.sink.add(ApiResponse.completed());
  //           }
  //         }

  //         if (!state.mounted) return;
  //         String message =
  //             getApiMsg(context, response.messageCode, response.message);
  //         manageUnavailableProducts(response.unavailableProducts);
  //         //changed: Show message if products are available and popup not shown...
  //         if (isApiStatus(context, response.status, message, true,
  //             showMess: response.unavailableProducts.isEmpty)) {
  //           showAddAddressBtn = false;
  //           if (!showShimmer) {
  //             _subject.sink.add(ApiResponse.loading());
  //           } else {
  //             _subjectCartItemLoading.sink.add(ApiResponse.loading());
  //           }
  //           totalPay = double.parse(response.totalPay.toString());
  //           _subject.sink.add(ApiResponse.completed(response));
  //           _subjectCartItemLoading.sink.add(ApiResponse.completed(response));
  //           setKeyValueDate(response);
  //           _selectedPromoCodeIdController.sink.add(response.promocodeName);
  //           if ((response.promoCodeMessage).trim().isNotEmpty &&
  //               response.promoMessageCode != 1) {
  //             openSimpleSnackbar(response.promoCodeMessage);
  //           }
  //           if (isFromOrderPlace &&
  //               (response.unavailableProducts).trim().isEmpty) {
  //             placeOrder(isScheduleOrder);
  //           }
  //         } else {
  //           if (response.messageCode == 115) {
  //             // showAddAddressBtn = true;
  //           }
  //           _subject.sink.add(ApiResponse.error(message));
  //           _subjectCartItemLoading.sink.add(ApiResponse.error(message));
  //         }
  //       } catch (e) {
  //         logd(tag, e.toString());
  //         _subject.sink.add(ApiResponse.error(e.toString()));
  //         _subjectCartItemLoading.sink.add(ApiResponse.error(e.toString()));
  //         if (isFromOrderPlace) {
  //           if (isScheduleOrder) {
  //             _subjectPlaceScheduleOrder.sink.add(ApiResponse.error());
  //           } else {
  //             _subjectPlaceOrder.sink.add(ApiResponse.error());
  //           }
  //         }
  //       }
  //     } else {
  //       _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
  //       if (!state.mounted) return;
  //       openSimpleSnackbar(languages.internetConnLostTitle);
  //     }
  //   } else {
  //     // prefSetString(prefSelectedStoreFullResponse, "");
  //     _subject.sink.add(ApiResponse.error(languages.cartEmptyMsg));
  //   }
  // }

  showDateAndTimePicker() {
    selectDate(context, 1, 5).then((date) {
      if (date != null) {
        selectTime(context).then((time) {
          if (time != null) {
            DateTime dateTime = DateTime(
                date.year, date.month, date.day, time.hour, time.minute);
            bool isAfter = DateTime(
                    date.year, date.month, date.day, time.hour, time.minute)
                .isAfter(DateTime.now().add(const Duration(hours: 1)));
            if (isAfter) {
              openSelectPaymentMethod(convertTimeToServerTime(dateTime));
            } else {
              openSimpleSnackbar(languages.invalidScheduleTime);
            }
          }
        });
      }
    });
  }

  placeOrder(bool isScheduleOrder) async {
    if (checkStoreClose(
            context, isScheduleOrder, (_subject.value.data?.storeStatus)) &&
        checkStoreMinAmount(context,
            storeMinAmountApi: (_subject.value.data?.minOrderAmount))) {
      bool isPickup = (_selectedTakeAwayController.value) == pickup;

      if (_selectedAddressController.value != null || isPickup) {
        if ((_subject.value.data?.requiredPrescription ?? 0) == 1 &&
            (!_prescriptionImgController.hasValue ||
                (_prescriptionImgController.valueOrNull?.path ?? "").isEmpty)) {
          openSimpleSnackbar(languages.prescriptionRequired);
        } else {
          openRequiredInfoDialog(context, () {
            if (isScheduleOrder) {
              showDateAndTimePicker();
            } else {
              openSelectPaymentMethod(null);
            }
          });
        }
      } else {
        openSimpleSnackbar(languages.addOrSelectAddress);
      }
    }
  }

  openSelectPaymentMethod(String? scheduleTime) {
    openScreenWithResult(
            context, SelectPaymentMethod(payTo: deliveries, totalPay: totalPay))
        .then((value) {
      if (value != null && value["paymentType"] != null) {
        placeOrderApiCall(value["paymentType"], 0);
      }
    });
  }

  placeOrderApiCall(int paymentType, int addressId,
      {int takenType = 1, bool credit = false}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectPlaceOrder.sink.add(ApiResponse.loading());
      List orderList = _subject.value.data['order_list'];
      int storeId = _subject.value.data['store_id'];
      String storeName = _subject.value.data['store_name'];
      try {
        MultipartFile? multipartFile;
        _loadingPlaceOrder.sink.add(true);
        logd(tag,
            'placeOrderApiCall -> paymentType:$paymentType takenType:$takenType credit:$credit addressId:$addressId tip:${prefGetStringWithDefaultValue(prefTip, '0')}');
        var response = PlaceOrderPojo.fromJson(
          await _checkoutRepo.callStorePlaceOrderApi(
            storeId,
            addressId,
            paymentType,
            takenType,
            additionalInfo.text,
            jsonEncode(orderList.map((e) => e['id']).toList()),
            credit,
            _selectedPromoCodeIdController.value,
            null,
            double.parse(prefGetStringWithDefaultValue(prefTip, '0')),
            multipartFile,
          ),
        );
        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        logd(tag,
            'placeOrderApiCall response -> status:${response.status} orderId:${response.orderId} totalPay:${response.totalPay} paymentIntentType:${response.paymentIntent.runtimeType} message:$message');
          if (isApiStatus(context, response.status, message, true,
              showMess:
                  response.inActiveProductIds.isEmpty && response.status != 3)) {
          prefSetInt('bookedOrderId', response.orderId);
          if (paymentType == 3) {
            await _vippsPaymentProcess(response.totalPay, response.orderNo,
                response.orderId, storeName);
          } else {
            try {
              final bool noPaymentRequired = response.totalPay <= 0;
              final bool missingPaymentIntent = response.paymentIntent == null ||
                  (response.paymentIntent is Map &&
                      (response.paymentIntent['paymentIntent'] == null ||
                          '${response.paymentIntent['paymentIntent']}'.isEmpty));
              logd(tag,
                  'payment branch -> noPaymentRequired:$noPaymentRequired missingPaymentIntent:$missingPaymentIntent paymentType:$paymentType');
              if (!noPaymentRequired && missingPaymentIntent) {
                throw Exception('Missing payment intent for payable order.');
              }
              if (!noPaymentRequired) {
                await _stripePaymentProcess(
                    response.paymentIntent, paymentType, response);
                // Webhook is not always available on local/dev.
                // Re-hit place-order with bookedOrderId so backend can verify/mark payment_status.
                await _syncPaidOrderAfterStripe(
                  storeId: storeId,
                  paymentType: paymentType,
                  takenType: takenType,
                  credit: credit,
                  orderList: orderList,
                );
              } else {
                _loadingPlaceOrder.sink.add(false);
              }
              if (!state.mounted) return;
              HomeMainV1State? homeState =
                  context.findAncestorStateOfType<HomeMainV1State>();
              if (homeState != null) {
                prefSetInt(prefCartCount, 0);
                homeState.badgeCountNotifier.value = 0;
              }
              openScreenWithResult(
                  context, TrackOrder(orderId: response.orderId));
            } catch (e, stacktrace) {
              logd(tag, 'placeOrderApiCall inner error: $e');
              logd(tag, 'placeOrderApiCall inner stacktrace: $stacktrace');
              _loadingPlaceOrder.sink.add(false);
              openSimpleSnackbar(
                  'Your order is cancelled by unexpected issue. Please try again.');
            }
          }
        } else {
          prefSetInt('bookedOrderId', 0);
          _loadingPlaceOrder.sink.add(false);
          manageUnavailableProducts(response.inActiveProductIds);
          if (response.inActiveProductIds.isEmpty && response.status != 3) {
            openSimpleSnackbar(message);
          }
          _subjectPlaceOrder.sink.add(ApiResponse.error(message));
        }
      } catch (e, stacktrace) {
        logd(tag, "$stacktrace");
        _loadingPlaceOrder.sink.add(false);
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectPlaceOrder.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  Future _vippsPaymentProcess(
      double amount, String orderNo, int orderId, String storeName) async {
    try {
      final response = await CheckoutRepo().initiateVippsViaBackend(orderId);
      final dynamic redirectRaw =
          response['redirect_url'] ?? response['redirectUrl'];
      if (_vippsInitiateApiOk(response['status']) &&
          redirectRaw != null &&
          '$redirectRaw'.isNotEmpty) {
        prefSetInt('vipps_pending_order_id', orderId);
        final uri = Uri.parse(redirectRaw.toString());
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          openSimpleSnackbar(
            'Could not open Vipps. Install the Vipps app or try again.',
          );
        }
      } else {
        openSimpleSnackbar(
          response['message']?.toString() ?? 'Vipps initiation failed',
        );
      }
    } catch (e) {
      openSimpleSnackbar(e.toString());
    }
    _loadingPlaceOrder.sink.add(false);
  }

  Future _stripePaymentProcess(dynamic paymentIntent, int paymentType,
      PlaceOrderPojo paymentDetail) async {
    if (paymentType == 1) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          // Using default flow: presentPaymentSheet handles confirmation itself.
          customFlow: false,
          allowsDelayedPaymentMethods: true,
          returnURL: 'aerend://stripe-redirect',
          merchantDisplayName: 'Reen Dugnad',
          paymentIntentClientSecret: paymentIntent['paymentIntent'],
          customerEphemeralKeySecret: paymentIntent['ephemeralKey'],
          customerId: paymentIntent['customerId'],
          applePay: PaymentSheetApplePay(merchantCountryCode: 'NO', cartItems: [
            ApplePayCartSummaryItem.immediate(
                label: paymentDetail.orderNo,
                amount: '${paymentDetail.totalPay}',
                isPending: false)
          ]),
          googlePay: const PaymentSheetGooglePay(
              merchantCountryCode: 'NO', testEnv: false),
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
    } else if (paymentType == 2) {
      if (Platform.isAndroid) {
        await Stripe.instance.confirmPlatformPayPaymentIntent(
          clientSecret: paymentIntent['paymentIntent'],
          confirmParams: const PlatformPayConfirmParams.googlePay(
            googlePay: GooglePayParams(
              merchantName: 'Reen Dugnad',
              allowCreditCards: true,
              isEmailRequired: false,
              testEnv: false,
              currencyCode: 'nok',
              merchantCountryCode: 'no',
            ),
          ),
        );
      } else if (Platform.isIOS) {
        await Stripe.instance.confirmPlatformPayPaymentIntent(
          clientSecret: paymentIntent['paymentIntent'],
          confirmParams: PlatformPayConfirmParams.applePay(
            applePay: ApplePayParams(
              merchantCountryCode: 'no',
              currencyCode: 'nok',
              cartItems: [
                ApplePayCartSummaryItem.immediate(
                  label: paymentDetail.orderNo,
                  amount: '${paymentDetail.totalPay}',
                  isPending: true,
                ),
              ],
            ),
          ),
        );
      }
    }
    _loadingPlaceOrder.sink.add(false);
  }

  Future<void> _syncPaidOrderAfterStripe({
    required int storeId,
    required int paymentType,
    required int takenType,
    required bool credit,
    required List orderList,
  }) async {
    try {
      await _checkoutRepo.callStorePlaceOrderApi(
        storeId,
        prefGetInt(prefNewDeliveryAddressId),
        paymentType,
        takenType,
        additionalInfo.text,
        jsonEncode(orderList.map((e) => e['id']).toList()),
        credit,
        _selectedPromoCodeIdController.value,
        null,
        double.parse(prefGetStringWithDefaultValue(prefTip, '0')),
        null,
      );
    } catch (e) {
      logd(tag, 'syncPaidOrderAfterStripe ignored error: $e');
    }
  }

  // Future<File> compressImage(File file) async {
  //   final filePath = file.absolute.path;
  //   final lastIndex = filePath.lastIndexOf(new RegExp(r'.jp'));
  //   final splitted = filePath.substring(0, (lastIndex));
  //   final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
  //   final compressedImage = await FlutterImageCompress.compressAndGetFile(filePath, outPath, quality: 90);
  //   return compressedImage;
  // }

  getProductList() {
    String productList = "";
    List<CartItem> cartItemsList = store.state.cartItemState.cartItemsList;
    int prevProductId = 0;
    List<ProductListForOPParam> productListForOPParamList = [];
    ProductListForOPParam? productListForOPParam;
    List<ProductQuantityItemForOPParam> productQuantityItemForOPParamList = [];
    if (cartItemsList.isNotEmpty) {
      for (int i = 0; i < cartItemsList.length; i++) {
        CartItem cartItem = cartItemsList[i];
        if (cartItem.prodId == prevProductId) {
          if (productListForOPParam != null) {
            productListForOPParam.productId = cartItem.prodId;
            ProductQuantityItemForOPParam productQuantityItemForOPParam =
                ProductQuantityItemForOPParam();
            List<int> optionArray = [], toppingArray = [];
            if (cartItem.prodCustomizeOption.trim().isNotEmpty) {
              cartItem.prodCustomizeOption.trim().split(',').forEach((option) {
                optionArray.add(int.parse(option));
              });
            }
            if (cartItem.prodCustomizeToppings.trim().isNotEmpty) {
              cartItem.prodCustomizeToppings
                  .trim()
                  .split(',')
                  .forEach((customizeOption) {
                toppingArray.add(int.parse(customizeOption));
              });
            }
            productQuantityItemForOPParam.quantity = cartItem.prodQuantity;
            productQuantityItemForOPParam.size = cartItem.prodCustomizeSize;
            productQuantityItemForOPParam.options = optionArray;
            productQuantityItemForOPParam.toppings = toppingArray;
            productQuantityItemForOPParamList
                .add(productQuantityItemForOPParam);
          }
          if (cartItemsList.length - 1 == i) {
            if (productListForOPParam != null) {
              productListForOPParamList.add(productListForOPParam);
            }
          }
        } else {
          if (productListForOPParam != null) {
            productListForOPParamList.add(productListForOPParam);
          }
          productListForOPParam = ProductListForOPParam();
          prevProductId = cartItem.prodId;
          productListForOPParam.productId = prevProductId;
          productQuantityItemForOPParamList = [];
          ProductQuantityItemForOPParam productQuantityItemForOPParam =
              ProductQuantityItemForOPParam();
          List<int> optionArray = [], toppingArray = [];
          if (cartItem.prodCustomizeOption.trim().isNotEmpty) {
            cartItem.prodCustomizeOption.trim().split(',').forEach((option) {
              optionArray.add(int.parse(option));
            });
          }
          if (cartItem.prodCustomizeToppings.trim().isNotEmpty) {
            cartItem.prodCustomizeToppings
                .trim()
                .split(',')
                .forEach((customizeOption) {
              toppingArray.add(int.parse(customizeOption));
            });
          }
          productQuantityItemForOPParam.quantity = cartItem.prodQuantity;
          productQuantityItemForOPParam.size = cartItem.prodCustomizeSize;
          productQuantityItemForOPParam.options = optionArray;
          productQuantityItemForOPParam.toppings = toppingArray;
          productQuantityItemForOPParamList.add(productQuantityItemForOPParam);
          productListForOPParam.productQuantity =
              productQuantityItemForOPParamList;
          if (cartItemsList.length - 1 == i) {
            productListForOPParamList.add(productListForOPParam);
          }
        }
      }
      productList = jsonEncode(productListForOPParamList);
    }
    return productList;
  }

  setKeyValueDate(OrderPreviewPojo orderPreviewPojo) {
    List<KeyValueModel> keyValuesList = [];
    setKeyValuePair(keyValuesList, false, false, languages.itemTotal,
        orderPreviewPojo.totalItemCost.toString());
    setKeyValuePair(keyValuesList, false, false, languages.deliveryCharges,
        orderPreviewPojo.deliveryCost.toString());
    setKeyValuePair(keyValuesList, false, false, languages.packingCharges,
        orderPreviewPojo.packagingCost.toString());
    setKeyValuePair(keyValuesList, false, false, languages.discount,
        orderPreviewPojo.discountCost.toString());
    setKeyValuePair(keyValuesList, false, false, languages.referDiscount,
        orderPreviewPojo.referDiscount.toString());
    setKeyValuePair(keyValuesList, false, false, orderPreviewPojo.promocodeName,
        orderPreviewPojo.promocodeDiscount.toString());
    setKeyValuePair(keyValuesList, false, false, languages.tax,
        orderPreviewPojo.taxCost.toString());
    setKeyValuePair(keyValuesList, false, false, languages.tip,
        orderPreviewPojo.tip.toString());
    setKeyValuePair(keyValuesList, true, true, languages.toPay,
        orderPreviewPojo.totalPay.toString());
    changeKeyValueList(keyValuesList);
  }

  getWalletAmount() async {
    try {
      var response =
          WalletBalancePojo.fromJson(await _myWalletRepo.getWalletBalance());

      if (!state.mounted) return;
      String message =
          getApiMsg(context, response.messageCode, response.message);
      if (isApiStatus(context, response.status, message, true,
          showMess: false)) {
        walletAmount = getDoubleFromDynamic(response.walletBalance ?? "0");
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }

  getPromoCode() async {
    try {
      StoreDetailsPojo storeDetailsPojo = StoreDetailsPojo.fromJson(
          jsonDecode(prefGetString(prefSelectedStoreFullResponse)));
      var response = PromoCodePojo.fromJson(
          await _checkoutRepo.callPromoCodeApi(
              serviceCateId: storeDetailsPojo.cartsSelectedStoreCateId));

      if (!state.mounted) return;
      String message =
          getApiMsg(context, response.messageCode, response.message);
      if (isApiStatus(context, response.status, message, true,
          showMess: false)) {
        changePromoCodeList(response.promocodeList);
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }

  openSelectAddressScreen() {
    openScreenWithResult(
        context,
        const ManageAddress(
          showSelect: true,
        )).then((value) {
      if (value) {
        showAddAddressBtn = false;
        setDeliveryAddress();
      }
    });
  }

  getCurrentLocation() async {
    _subject.sink.add(ApiResponse.loading());

    getLocationUtils.getLocationUtils((locationData) {},
        (locationData, address) {
      currentAddressPojo = CurrentAddressPojo(
          address: address,
          lat: locationData.latitude.toString(),
          lng: locationData.longitude.toString());
      // getOrderPreview(true);
    });
  }

  manageUnavailableProducts(String unavailableProductsID) {
    if ((unavailableProductsID).trim().isNotEmpty) {
      String unAvailableProduct = removedProduct(unavailableProductsID);
      logd(tag, 'unAvailable : $unAvailableProduct');
      logd(tag, 'unAvailableID : $unavailableProductsID');
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialogUtil(
              title: languages.unavailableProductMess,
              message: unAvailableProduct,
              positiveButtonTxt: languages.ok,
              onPositivePress: () {
                Navigator.pop(context, true);
              },
            );
          }).then((value) {
        List<CartItem> cartItemList = store.state.cartItemState.cartItemsList;
        if (cartItemList.isNotEmpty) {
          // getOrderPreview(false);
        } else {
          _subject.sink.add(ApiResponse.error(languages.apiMsg157));
        }
      });
      // if (isPlaceOrder) {
      //   _subject.sink.add(ApiResponse.error(languages.apiMsg["api_msg_157"]));
      // }
    }
  }

  removedProduct(String ids) {
    List<String> split = ids.split(",").toSet().toList();
    List<CartItem> cartItemList = store.state.cartItemState.cartItemsList;
    List<CartItem> matchedCartItemList = cartItemList
        .where((element) => split.contains(element.prodId.toString()))
        .toList();
    for (var element in split) {
      StoreProvider.of<AppState>(context).dispatch(RemoveProductFromCart(
        productId: int.tryParse(element),
      ));
    }
    return matchedCartItemList
        .map((c) => c.productName)
        .toSet()
        .toList()
        .join(', ');
  }

  applyPromoCodeApiCall(String promoCodeId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectApplyPromoCode.sink.add(ApiResponse.loading());
      StoreDetailsPojo storeDetailsPojo = StoreDetailsPojo.fromJson(
          jsonDecode(prefGetString(prefSelectedStoreFullResponse)));
      try {
        var response =
            ApplyPromoCodePojo.fromJson(await _checkoutRepo.applyPromoCodeApi(
          promoCodeId,
          (subject.value.data?.totalItemCost ?? 0.0).toDouble(),
          storeDetailsPojo.cartsSelectedStoreCateId,
        ));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        double minOrderAmount = getDoubleFromDynamic(response.minOrderAmount);
        if (minOrderAmount > 0) {
          message = "$message ${getAmountWithCurrency(minOrderAmount)}";
        }
        if (isApiStatus(context, response.status, message, true)) {
          _subjectApplyPromoCode.sink.add(ApiResponse.completed(response));
          _selectedPromoCodeIdController.sink.add(promoCodeId);
          // getOrderPreview(true);
        } else {
          if (response.status != 3) openSimpleSnackbar(message);
          _subjectApplyPromoCode.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectApplyPromoCode.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  double getTip() {
    String tipTxt = tipController.text;
    double tip = _tipController.value;
    tip = tip != 0
        ? tip
        : (tipTxt.trim().isNotEmpty ? double.tryParse(tipTxt) : 0) ?? 0;
    return tip;
  }

  @override
  void dispose() {
    _selectedAddressController.close();
    _keyValueListController.close();
    _selectedTakeAwayController.close();
    _prescriptionImgController.close();
    _tipController.close();
    additionalInfo.dispose();
    tipController.dispose();
    _subjectCartItemLoading.close();
    _subjectPlaceOrder.close();
    _subjectPlaceScheduleOrder.close();
    _promoCodeListController.close();
    _selectedPromoCodeIdController.close();
    _subjectApplyPromoCode.close();
    _subject.close();
  }
}
