import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aerend_customer/screens/common/orderHistory/order_history_dl.dart';

import '../../../../utils/utils.dart';
import '../../../blocs/bloc.dart';
import 'order_history_repo.dart';

class OrderHistoryBloc extends Bloc {
  BuildContext context;
  final OrderHistoryRepo _orderHistoryRepo = OrderHistoryRepo();

  State<StatefulWidget> state;
  OrderHistoryBloc(this.context, this.state) {
    getDSOrderHistory();
  }

  final _subject = BehaviorSubject<ApiResponse<OrderHistoryListPojo>>();
  BehaviorSubject<ApiResponse<OrderHistoryListPojo>> get subject => _subject;

  getDSOrderHistory() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = OrderHistoryListPojo.fromJson(
            await _orderHistoryRepo.getOrderHistoryApi());
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
