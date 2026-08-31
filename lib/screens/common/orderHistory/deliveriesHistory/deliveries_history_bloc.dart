import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../blocs/bloc.dart';
import '../../../../utils/utils.dart';
import '../order_history_repo.dart';
import 'deliveries_history_dl.dart';

class DeliveriesHistoryBloc extends Bloc {
  BuildContext context;

  int filterType = 0;
  final OrderHistoryRepo _orderHistoryRepo = OrderHistoryRepo();

  State<StatefulWidget> state;

  DeliveriesHistoryBloc(this.context, this.state);

  setFilterType(int filterType) {
    this.filterType = filterType;
  }

  final _subject = BehaviorSubject<ApiResponse<DeliveriesHistoryPojo>>();

  BehaviorSubject<ApiResponse<DeliveriesHistoryPojo>> get subject => _subject;

  getDSOrderHistory(int currentPage, PagingController<int, DeliveriesHistoryItem> pagingController) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (currentPage == 1) {
        pagingController.itemList = [];
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = DeliveriesHistoryPojo.fromJson(await _orderHistoryRepo.getDSOrderHistoryApi(filterType, currentPage, localTimeZone));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          bool isLastPage = currentPage == response.lastPage;
          if (isLastPage) {
            pagingController.appendLastPage(response.orderList);
          } else {
            int nextPageKey = currentPage + 1;
            pagingController.appendPage(response.orderList, nextPageKey);
          }
          if (currentPage == 1) {
            if (response.orderList.isNotEmpty) {
              _subject.sink.add(ApiResponse.completed(response));
            } else {
              _subject.sink.add(ApiResponse.error(languages.noRecordFound));
            }
          }
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
  }
}
