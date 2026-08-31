import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';

import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_dl.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_repo.dart';

import '../../../blocs/bloc.dart';
import '../../../networking/api_response.dart';
import '../../../utils/utils.dart';
import 'order_cart_repo.dart';

class OrderCartBloc extends Bloc {
  String tag = "OrderCartBloc>>>";
  final OrderCartRepo _orderCartRepo = OrderCartRepo();
  final StoreDetailRepo _storeDetailRepo = StoreDetailRepo();
  int storeId = 0;
  late BuildContext context;

  final State state;

  OrderCartBloc(this.context, this.state) {
    getOrderCart();
  }

  final _subject = BehaviorSubject<ApiResponse>();

  Stream<ApiResponse> get subject => _subject.stream;

  void _emitCartWithoutItem(int cartId) {
    if (!_subject.hasValue || _subject.value.status != Status.completed) {
      return;
    }
    final data = Map<String, dynamic>.from(_subject.value.data as Map);
    final orderList = List<dynamic>.from(data['order_list'] ?? []);
    final filtered =
        orderList.where((item) => (item['id'] as int?) != cartId).toList();
    if (filtered.length == orderList.length) return;

    data['order_list'] = filtered;
    data['count_order'] = filtered.length;
    _subject.sink.add(ApiResponse.completed(data));

    HomeMainV1State? homeState =
        context.findAncestorStateOfType<HomeMainV1State>();
    if (homeState != null) {
      prefSetInt(prefCartCount, filtered.length);
      homeState.badgeCountNotifier.value = filtered.length;
    }
  }

  Future<void> removeCartItem(int cartId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
      return;
    }

    _emitCartWithoutItem(cartId);

    try {
      final response = await _orderCartRepo.deleteOrderCartApi(cartId);
      if (!state.mounted) return;
      if (response['status'] == 1) {
        await getOrderCart(isLoading: false);
      } else {
        final message = getApiMsg(
          context,
          response['message_code'],
          response['message']?.toString(),
        );
        openSimpleSnackbar(message);
        await getOrderCart(isLoading: false);
      }
    } catch (e) {
      logd(tag, e.toString());
      if (!state.mounted) return;
      openSimpleSnackbar(e.toString());
      await getOrderCart(isLoading: false);
    }
  }

  getOrderCart({isLoading = true}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (isLoading) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = await _orderCartRepo.callOrderCartApi();

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response["messagte_code"], response["message"]);
        if (isApiStatus(context, response["status"], message, true,
            showMess: false)) {
          storeId = response['store_id'];
          _subject.sink.add(ApiResponse.completed(response));
          HomeMainV1State? homeState =
              context.findAncestorStateOfType<HomeMainV1State>();
          if (homeState != null) {
            prefSetInt(prefCartCount, response['count_order']);
            homeState.badgeCountNotifier.value = response['count_order'];
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

  addOrderCart(int productId, int quantity) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var jsonResponse = await _storeDetailRepo.callOrderCartApi(
            storeId, productId, quantity);
        var response = UserOrderCartPojo.fromJson(jsonResponse);

        if (!state.mounted) return;
        if (response.messageCode == 9 || response.messageCode == 5) {
          openSimpleSnackbar(response.message);
        } else if (response.messageCode == 1) {
          logd(tag, response.message);

          storeId = (jsonResponse['store_id'] as num?)?.toInt() ?? storeId;
          // Re-fetch the full cart payload so UI state stays stable.
          await getOrderCart(isLoading: false);
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
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
  }
}
