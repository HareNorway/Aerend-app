import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../blocs/bloc.dart';
import '../../../dialogs/addTipsDialog/add_tips_dialog.dart';
import '../../../dialogs/ride_common_dialog.dart';
import '../../../dialogs/vehicle_info_dialog.dart';
import '../../../services/push_notification_service.dart';
import '../../../utils/utils.dart';
import '../../common/base_dl.dart';
import '../../common/selectPaymentMethod/select_payment_method.dart';
import '../../dugnad/dugnad_sheet.dart';
import 'ride_detail.dart';
import 'ride_detail_dl.dart';
import 'ride_detail_repo.dart';

class RideDetailBloc extends Bloc {
  String tag = "RideDetailBloc>>>";
  BuildContext context;
  BuildContext? dialogContext;
  int rideId, orderStatus = 0, oldOrderStatus = 0;
  final RideDetailRepo _rideDetailRepo = RideDetailRepo();
  int msgCode = 0;
  String msg = "";

  // Timer _apiTimer;
  String shareAddressLine = "";
  State<RideDetail> state;

  RideDetailBloc(this.context, this.rideId, this.state) {
    getRideDetail();
    // _apiTimer = Timer.periodic(Duration(seconds: 15), (Timer t) {
    //   getRideDetail(isSetSubject: false);
    // });
    manageNotification();
  }

  final _keyValueListController = BehaviorSubject<List<KeyValueModel>>();
  final _subjectRating = BehaviorSubject<ApiResponse<BaseModel>>();
  final _subject = BehaviorSubject<ApiResponse<RideDetailPojo>>();
  final _subjectCancelOrder = BehaviorSubject<ApiResponse<BaseModel>>();
  final _driverRatingController = BehaviorSubject<double>.seeded(0);
  final _driverCommentController = BehaviorSubject<String>.seeded("");

  TextEditingController driverCommentTEC = TextEditingController();

  Stream<List<KeyValueModel>> get keyValueList => _keyValueListController.stream;

  Function(List<KeyValueModel>) get changeKeyValueList => _keyValueListController.sink.add;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectRating => _subjectRating;

  BehaviorSubject<ApiResponse<RideDetailPojo>> get subject => _subject;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectCancelOrder => _subjectCancelOrder;

  Stream<double> get driverRating => _driverRatingController.stream;

  Function(double) get changeDriverRating => _driverRatingController.sink.add;

  Function(String) get changeDriverComment => _driverCommentController.sink.add;

  getRideDetail({bool isSetSubject = true, bool showDialog = false}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (isSetSubject) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = RideDetailPojo.fromJson(await _rideDetailRepo.rideReceiptDetailApi(rideId));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          _subject.sink.add(ApiResponse.completed(response));
          orderStatus = response.rideStatus;
          setShareAddress(response.addressList);
          setKeyValueDate(response);
          // if (prefGetInt(prefOldOrderStatus) != orderStatus || prefGetInt(prefOldWayPointOrderStatus) != response.waypointMsgCode) {
          //   prefSetInt(prefOldWayPointOrderStatus, response.waypointMsgCode);
          int wayPointMsgCode = response.waypointMsgCode;
          if (wayPointMsgCode > 0) {
            msgCode = response.waypointMsgCode;
            msg = response.waypointMessage ?? "";
          }
          if (showDialog && oldOrderStatus != orderStatus) {
            if (response.cancelByAdmin == 1) {
              msg = languages.rideCancelByAdmin;
            }
            openOrderStatusDialog(orderStatus, fromNotification: response.cancelByAdmin == 1);
          }
          oldOrderStatus = orderStatus;
          // }
          // if ((orderStatus == 4 || orderStatus >= 6) && _apiTimer != null && _apiTimer.isActive) {
          //   _apiTimer.cancel();
          // }
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  cancelOrderApi(String reason) async {
    FocusManager.instance.primaryFocus?.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectCancelOrder.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _rideDetailRepo.cancelRideBookingApi(rideId.toString(), reason));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        _subjectCancelOrder.sink.add(ApiResponse.completed(response));
        if (isApiStatus(context, response.status, message, true)) {
          Navigator.pop(context, true);
          getRideDetail();
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectCancelOrder.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  void setShareAddress(List<AddressListItem> addressList) {
    if (addressList.isNotEmpty) {
      String pickupLatLong = '${addressList[0].addressLat},${addressList[0].addressLong}';
      String dropLatLong = '${addressList[addressList.length - 1].addressLat},${addressList[addressList.length - 1].addressLong}';
      shareAddressLine = "https://www.google.com/maps/dir/?api=1&origin=$pickupLatLong&destination=$dropLatLong&travelmode=driving&dir_action=navigate";
    }
  }

  setKeyValueDate(RideDetailPojo data) {
    List<KeyValueModel> keyValuesList = [];
    setKeyValuePair(keyValuesList, false, false, languages.pickUpDateAndTime, getDateTime(data.pickupDateTime ?? ""));
    setKeyValuePair(keyValuesList, false, false, languages.distance, data.totalDistance ?? "");
    setKeyValuePair(keyValuesList, false, false, languages.timeTaken, data.estimatedTime ?? "");
    setKeyValuePair(keyValuesList, false, false, languages.costPerKm, getDoubleFromDynamic(data.costPerKm).toString());
    setKeyValuePair(keyValuesList, false, false, languages.distanceFare, getDoubleFromDynamic(data.rideFare).toString());
    setKeyValuePair(keyValuesList, false, false, languages.baseFare, getDoubleFromDynamic(data.baseFare).toString());
    if (showSurgeChargeModule) {
      setKeyValuePair(keyValuesList, false, false, languages.surgeCharge, getDoubleFromDynamic(data.surchargeCost).toString());
    }
    setKeyValuePair(keyValuesList, false, false, "${languages.timeFare} (${getAmountWithCurrency(getDoubleFromDynamic(data.costPerMin))} / 1 ${languages.min})",
        getDoubleFromDynamic(data.timeFareAmount).toString());
    setKeyValuePair(keyValuesList, false, false, languages.minAdjustAmt, getDoubleFromDynamic(data.minAdjustmentAmount).toString());
    setKeyValuePair(keyValuesList, false, false, languages.referDiscount, getDoubleFromDynamic(data.referDiscount).toString());
    setKeyValuePair(keyValuesList, false, false, data.promocodeName ?? "-", getDoubleFromDynamic(data.promocodeDiscount).toString());
    setKeyValuePair(keyValuesList, true, false, languages.serviceFare, getDoubleFromDynamic(data.subtotal).toString());
    setKeyValuePair(keyValuesList, false, false, languages.tax, getDoubleFromDynamic(data.tax).toString());
    if ((data.rideStatus) > 5) {
      double tip = getDoubleFromDynamic(data.tip);
      bool showTipBtn = (tip == 0 && data.paymentStatus == 0);
      String tipString = showTipBtn ? languages.addTip : "$tip";

      setKeyValuePair(keyValuesList, false, false, languages.tip, tipString,
          setButton: !showTipBtn
              ? null
              : () {
                  // `TipsSheet` — a bottom sheet in the approved design.
                  showDugnadSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return AddTipsDialog(
                          onSubmit: (tip) {
                            if (tip.isNotEmpty) {
                              Navigator.pop(context, true);
                              addTipApiCall(tip);
                            }
                          },
                        );
                      });
                });
    }
    setKeyValuePair(keyValuesList, true, true, languages.total, getDoubleFromDynamic(data.totalPay).toString());
    setKeyValuePair(keyValuesList, true, false, languages.paymentType, getPaymentType(context, data.payment));
    setKeyValuePair(keyValuesList, true, false, languages.paymentStatus, data.paymentStatus == 1 ? languages.complete : languages.pending);
    changeKeyValueList(keyValuesList);
  }

  openVehicleInfoDialog(RideDetailPojo data) {
    List<KeyValueModel> vehicleList = [];
    setKeyValuePair(vehicleList, false, false, languages.vehicleColor, data.vehicleColor ?? "");
    setKeyValuePair(vehicleList, false, false, languages.vehicleManufactureName, data.vehicleManufactureName ?? "");
    setKeyValuePair(vehicleList, false, false, languages.vehicleModelName, data.vehicleModelName ?? "");
    setKeyValuePair(vehicleList, false, false, languages.vehicleModelYear, data.vehicleModelYear.toString(), setValueWithCurrency: false);
    setKeyValuePair(vehicleList, false, false, languages.vehiclePlatNo, data.vehiclePlatNo ?? "");
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return VehicleInfoDialog(
          vehicleList: vehicleList,
        );
      },
    );
  }

  rideRatingApiCall(int driverId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectRating.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _rideDetailRepo.rideRating(rideId, driverId, _driverRatingController.value, _driverCommentController.value));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectRating.sink.add(ApiResponse.completed(response));
          pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
          rideSuccessfullyDialog();
          getRideDetail();
        } else {
          _subjectRating.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subjectRating.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  rideRating(int driverId) {
    if ((_driverRatingController.value) > 0) {
      rideRatingApiCall(driverId);
    } else {
      openSimpleSnackbar(languages.giveRatingMsg);
    }
  }

  openSelectPaymentMethod(double totalPay) {
    openScreenWithResult(
        context,
        SelectPaymentMethod(
          payTo: rides,
          totalPay: totalPay,
          showWallet: true,
          id: rideId,
        )).then((value) {
      if (value ?? false) {
        RideDetailPojo? data = _subject.value.data;
        // data?.setPaymentStatus(1);
        _subject.sink.add(ApiResponse.completed(data));
        getRideDetail();
      }
    });
  }

  rideSuccessfullyDialog() {
    finishChat();
    String image = getRideSuccessFinish();
    String title = languages.successfullyCompleted;
    String msg = languages.deliveryCompleted;
    pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RideCommonDialog(
          isLoading: false,
          dialogImg: image,
          title: title,
          msg: msg,
          positiveBtnTxt: languages.done,
          positiveBtnOnClick: (spinnerPos, textFieldValue) {
            Navigator.pop(context, true);
          },
          negativeBtnOnClick: () {},
        );
      },
    ).then((value) {
      getRideDetail();
    });
  }

  addTipApiCall(String tip) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = RideDetailPojo.fromJson(await _rideDetailRepo.addTip(rideId, tip));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          _subject.sink.add(ApiResponse.completed(response));
          setKeyValueDate(response);
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  shareRide() {
    if (shareAddressLine.trim().isNotEmpty) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        String shareText = "${languages.followMeAt(languages.appName)} ${languages.courierService}\n$shareAddressLine";
        Share.share(shareText, subject: languages.appName, sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
      }
    }
  }

  finishChat() {
    String driverIdCode = ChatConstant.providerIdCode + (_subject.value.data?.driverId ?? 0).toString();
    String userIdCode = ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

    DatabaseReference referenceMessage = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.messages).child("${userIdCode}_$driverIdCode");
    referenceMessage.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        referenceMessage.remove();
      }
    });

    DatabaseReference referenceUser = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.users).child(userIdCode);
    referenceUser.orderByChild(ChatConstant.userId).equalTo(driverIdCode).once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        Map? data = dataSnapshot.snapshot.value as Map?;
        data?.forEach((key, value) {
          referenceUser.child(key.toString()).remove();
        });
      }
    });
  }

  openOrderStatusDialog(int orderStatus, {bool fromNotification = false}) {
    oldOrderStatus = orderStatus;
    logd(tag, "open dialog : $orderStatus");
    // prefSetInt(prefOldOrderStatus, orderStatus);
    String dialogImg = "assets/images/dialog_driver_arrived_img.png";
    String title = "";
    String message = "";
    switch (orderStatus) {
      case 3:
        dialogImg = getArrivedImage();
        title = getArrivedTitleMsg(isTitle: true);
        message = getArrivedTitleMsg(isTitle: false);
        break;
      case 4:
        dialogImg = "assets/images/dialog_cancel_img.png";
        title = getCancelTitleMsg(isTitle: true);
        message = fromNotification ? msg : getCancelTitleMsg(isTitle: false);
        break;
      case 5:
        if (msgCode == 272) {
          dialogImg = getRideStartedImg();
          title = getApiMsg(context, msgCode, msg);
          message = "";
        } else if (msgCode == 273) {
          dialogImg = getRideStartedImg();
          title = getApiMsg(context, msgCode, msg);
          message = "";
        } else if (msgCode == 274) {
          dialogImg = getRideStartedImg();
          title = getApiMsg(context, msgCode, msg);
          message = "";
        } else {
          dialogImg = getRideStartedImg();
          title = getRideStartedTitleMsg(isTitle: true);
          message = getRideStartedTitleMsg(isTitle: false);
        }
        break;
      case 6:
        dialogImg = getRideFinish();
        title = getRideFinishTitleMsg(isTitle: true);
        message = getRideFinishTitleMsg(isTitle: false);
        break;
      case 7:
        dialogImg = getRideFinish();
        title = getRideFinishTitleMsg(isTitle: true);
        message = getRideFinishTitleMsg(isTitle: false);
        break;
      case 9:
        dialogImg = getRideSuccessFinish();
        title = getRideSuccessTitleMsg(isTitle: true);
        message = getRideSuccessTitleMsg(isTitle: false);
        break;
    }
    if (orderStatus >= 3 && orderStatus < 9) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }
      pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          dialogContext = context;
          return RideCommonDialog(
            isLoading: false,
            dialogImg: dialogImg,
            title: title,
            msg: message,
            positiveBtnTxt: languages.done,
            positiveBtnOnClick: (spinnerPos, textFieldValue) {
              Navigator.pop(context, true);
              // pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
            },
            negativeBtnOnClick: () {},
          );
        },
      ).then((value) {
        dialogContext = null;
      });
    }
  }

  manageNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (!state.mounted) return;

      Map<String, dynamic> notificationData = message.data;
      int notificationType = int.parse((notificationData[NotificationConstant.notificationType] ?? 0).toString());
      msgCode = int.parse((notificationData[NotificationConstant.messageCode] ?? 0).toString());
      msg = (notificationData[NotificationConstant.message]).toString();
      int orderStatus = int.parse((notificationData[NotificationConstant.orderStatus] ?? 0).toString());
      int orderId = int.parse((notificationData[NotificationConstant.orderId] ?? 0).toString());
      int serviceCategoryId = int.parse((notificationData[NotificationConstant.serviceCategoryId] ?? 0).toString());
      int bookingType = int.parse((notificationData[NotificationConstant.bookingType] ?? 0).toString());
      if (notificationType == 1) {
        if (serviceCategoryId == 4) {
          if (bookingType == 0) {
            if (orderStatus > 1 && orderStatus < 9) {
              this.orderStatus = orderStatus;
              rideId = orderId;
              RideDetailPojo? data = _subject.value.data;
              data?.rideStatus = orderStatus;
              subject.add(ApiResponse.completed(data));
              openOrderStatusDialog(orderStatus, fromNotification: true);
            }
          } else {
            if (orderStatus > 2 && orderStatus < 9) {
              this.orderStatus = orderStatus;
              rideId = orderId;
              RideDetailPojo? data = _subject.value.data;
              data?.rideStatus = (orderStatus);
              subject.add(ApiResponse.completed(data));
              openOrderStatusDialog(orderStatus, fromNotification: true);
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _keyValueListController.close();
    _subject.close();
    _subjectCancelOrder.close();
    _subjectRating.close();
    _driverCommentController.close();
    _driverRatingController.close();
    driverCommentTEC.dispose();
    // if (_apiTimer != null && _apiTimer.isActive) {
    //   _apiTimer.cancel();
    // }
  }
}
