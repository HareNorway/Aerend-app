import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../../common/base_dl.dart';
import 'deliveries_order_detail.dart';
import 'deliveries_order_detail_dl.dart';
import 'deliveries_order_detail_repo.dart';

class DeliveriesOrderDetailBloc extends Bloc {
  late BuildContext context;

  late int orderId;
  final DeliveriesOrderDetailRepo _deliveriesOrderDetailRepo = DeliveriesOrderDetailRepo();

  State<DeliveriesOrderDetail> state;

  DeliveriesOrderDetailBloc(this.context, this.orderId, this.state) {
    getDeliveriesOrderDetail(true);
  }

  final _keyValueListController = BehaviorSubject<List<KeyValueModel>>();
  final _subject = BehaviorSubject<ApiResponse<DeliveriesOrderDetailPojo>>();

  BehaviorSubject<ApiResponse<DeliveriesOrderDetailPojo>> get subject => _subject;

  Stream<List<KeyValueModel>> get keyValueList => _keyValueListController.stream;

  Function(List<KeyValueModel>) get changeKeyValueList => _keyValueListController.sink.add;

  setKeyValueDate(DeliveriesOrderDetailPojo data) {
    List<KeyValueModel> keyValuesList = [];
    setKeyValuePair(keyValuesList, true, false, languages.itemTotal, getDoubleFromDynamic(data.totalItemCost ?? "0").toString());
    setKeyValuePair(keyValuesList, false, false, languages.deliveryCharges, getDoubleFromDynamic(data.deliveryCost ?? "0").toString());
    setKeyValuePair(keyValuesList, false, false, languages.packagingCharge, getDoubleFromDynamic(data.packagingCost ?? "0").toString());
    setKeyValuePair(keyValuesList, false, false, languages.discount, getDoubleFromDynamic(data.discountCost ?? "0").toString());
    setKeyValuePair(keyValuesList, false, false, languages.referDiscount, getDoubleFromDynamic(data.referDiscount ?? "0").toString());
    setKeyValuePair(keyValuesList, false, false, data.usedPromoCodeName, getDoubleFromDynamic(data.promoCodeDiscount ?? "0").toString());
    setKeyValuePair(keyValuesList, false, false, languages.tax, getDoubleFromDynamic(data.taxCost ?? "0").toString());
    setKeyValuePair(keyValuesList, false, false, languages.tip, getDoubleFromDynamic(data.tip ?? "0").toString());
    setKeyValuePair(keyValuesList, true, true, languages.total, getDoubleFromDynamic(data.totalPay ?? "0").toString());
    setKeyValuePair(keyValuesList, true, false, languages.paymentType, getPaymentType(context, data.paymentType));
    changeKeyValueList(keyValuesList);
  }

  getDeliveriesOrderDetail(bool isLoading) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (isLoading) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = DeliveriesOrderDetailPojo.fromJson(await _deliveriesOrderDetailRepo.deliveriesOrderDetailApi(orderId));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
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
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  finishChatWithStore(DeliveriesOrderDetailPojo orderDetailsPojo) {
    String storeIdCode = ChatConstant.providerIdCode + orderDetailsPojo.storeId.toString();
    String userIdCode = ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

    DatabaseReference referenceMessage =
        firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.messages).child("${userIdCode}_$storeIdCode");
    referenceMessage.once().then((DatabaseEvent event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        referenceMessage.remove();
      }
      return;
    });
    // DatabaseReference referenceMessage =
    //     firebaseDatabase.reference().child(ChatConstant.CHAT).child(ChatConstant.MESSAGES).child(userIdCode + "_" + storeIdCode);
    // referenceMessage.once().then((DataSnapshot dataSnapshot) {
    //   if (dataSnapshot.value != null) {
    //     referenceMessage.remove();
    //   }
    //   return;
    // });

    DatabaseReference referenceUser = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.users).child(userIdCode);
    referenceUser.orderByChild(ChatConstant.userId).equalTo(storeIdCode).once().then((DatabaseEvent event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map data = dataSnapshot.value as Map;
        data.forEach((key, value) {
          referenceUser.child(key.toString()).remove();
        });
      }
      return;
    });
    // DatabaseReference referenceUser = firebaseDatabase.reference().child(ChatConstant.CHAT).child(ChatConstant.USERS).child(userIdCode);
    // referenceUser.orderByChild(ChatConstant.USER_ID).equalTo(storeIdCode).once().then((DataSnapshot dataSnapshot) {
    //   if (dataSnapshot.value != null) {
    //     Map data = dataSnapshot.value;
    //     data.forEach((key, value) {
    //       referenceUser.child(key.toString()).remove();
    //     });
    //   }
    //   return;
    // });
  }

  finishChatWithDriver(DeliveriesOrderDetailPojo orderDetailsPojo) {
    String driverIdCode = ChatConstant.providerIdCode + orderDetailsPojo.driverId.toString();
    String userIdCode = ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

    DatabaseReference referenceMessage =
        firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.messages).child("${userIdCode}_$driverIdCode");

    referenceMessage.orderByChild(ChatConstant.userId).equalTo("${userIdCode}_$driverIdCode").once().then((DatabaseEvent event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map data = dataSnapshot.value as Map;
        data.forEach((key, value) {
          referenceMessage.child(key.toString()).remove();
        });
      }
      return;
    });

    DatabaseReference referenceUser = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.users).child(userIdCode);
    referenceUser.orderByChild(ChatConstant.userId).equalTo(driverIdCode).once().then((DatabaseEvent event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map data = dataSnapshot.value as Map;
        data.forEach((key, value) {
          referenceUser.child(key.toString()).remove();
        });
      }
      return;
    });
    // referenceUser.orderByChild(ChatConstant.USER_ID).equalTo(driverIdCode).once().then((DataSnapshot dataSnapshot) {
    //   if (dataSnapshot.value != null) {
    //     Map data = dataSnapshot.value;
    //     data.forEach((key, value) {
    //       referenceUser.child(key.toString()).remove();
    //     });
    //   }
    //   return;
    // });
  }

  @override
  void dispose() {
    _keyValueListController.close();
    _subject.close();
  }
}
