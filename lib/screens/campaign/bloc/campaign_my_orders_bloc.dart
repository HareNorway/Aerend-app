import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../campaign_repo.dart';
import '../models/campaign_order_pojo.dart';

class CampaignMyOrdersBloc extends Bloc {
  final BuildContext context;
  final State state;
  final CampaignRepo _repo = CampaignRepo();

  final _ordersSubject =
      BehaviorSubject<ApiResponse<CampaignMyOrdersListPojo>>();

  Stream<ApiResponse<CampaignMyOrdersListPojo>> get ordersStream =>
      _ordersSubject.stream;

  CampaignMyOrdersBloc(this.context, this.state) {
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      _ordersSubject.sink.add(ApiResponse.loading());
      try {
        var response =
            CampaignMyOrdersListPojo.fromJson(await _repo.getMyOrders());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _ordersSubject.sink.add(ApiResponse.completed(response));
        } else {
          _ordersSubject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        _ordersSubject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  Future<void> refresh() => _fetchOrders();

  @override
  void dispose() {
    _ordersSubject.close();
  }
}
