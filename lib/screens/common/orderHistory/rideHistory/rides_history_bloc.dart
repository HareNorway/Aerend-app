import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../blocs/bloc.dart';
import '../../../../utils/utils.dart';
import '../order_history_repo.dart';
import 'rides_history_dl.dart';

class RidesHistoryBloc extends Bloc {
  BuildContext context;

  int filterType = 0;
  final OrderHistoryRepo _orderHistoryRepo = OrderHistoryRepo();

  State<StatefulWidget> state;

  RidesHistoryBloc(this.context, this.state);

  setFilterType(int filterType) {
    this.filterType = filterType;
  }

  final _subject = BehaviorSubject<ApiResponse<RidesHistoryPojo>>();

  BehaviorSubject<ApiResponse<RidesHistoryPojo>> get subject => _subject;

  getRideHistory(int currentPage, PagingController<int, RidesItem> pagingController) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (currentPage == 1) {
        pagingController.itemList = [];
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = RidesHistoryPojo.fromJson(await _orderHistoryRepo.getRideHistoryApi(filterType, currentPage, localTimeZone));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          bool isLastPage = currentPage == response.lastPage;
          if (isLastPage) {
            pagingController.appendLastPage(response.rides);
          } else {
            int nextPageKey = currentPage + 1;
            pagingController.appendPage(response.rides, nextPageKey);
          }
          if (currentPage == 1) {
            if (response.rides.isNotEmpty) {
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
