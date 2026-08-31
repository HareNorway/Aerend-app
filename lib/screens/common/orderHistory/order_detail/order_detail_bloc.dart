import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aerend_customer/screens/common/orderHistory/order_detail/order_detail_dl.dart';

import '../../../../utils/utils.dart';
import '../../../../blocs/bloc.dart';
import 'order_detail_repo.dart';

class OrderDetailBloc extends Bloc {
  BuildContext context;
  final OrderDetailRepo _orderDetailRepo = OrderDetailRepo();
  late int orderId;

  State<StatefulWidget> state;
  OrderDetailBloc(this.context, this.orderId, this.state) {
    getDSOrderDetail();
  }

  final _subject = BehaviorSubject<ApiResponse<OrderDetailPojo>>();
  BehaviorSubject<ApiResponse<OrderDetailPojo>> get subject => _subject;

  getDSOrderDetail() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        // Raw API response log to help debug pickup-at-store orders.
        final raw = await _orderDetailRepo.getOrderDetailApi(orderId);
        // ignore: avoid_print
        print('OrderDetailApi (order_id=$orderId) response: $raw');

        var response = OrderDetailPojo.fromJson(raw);
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
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
  }
}
