import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import 'notifications.dart';
import 'notifications_dl.dart';
import 'notifications_repo.dart';

class NotificationsBloc extends Bloc {
  String tag = "NotificationBloc>>>";

  late BuildContext context;
  final NotificationsRepo _repo = NotificationsRepo();
  final PagingController<int, MassNotificationItem> pagingController = PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  State<Notifications> state;

  NotificationsBloc(this.context, this.state) {
    pagingController.addPageRequestListener((pageKey) {
      getNotificationsListApi(pageKey);
    });
    pagingController.notifyPageRequestListeners(1);
  }

  final _subject = BehaviorSubject<ApiResponse<NotificationsPojo>>();

  BehaviorSubject<ApiResponse<NotificationsPojo>> get subject => _subject;

  getNotificationsListApi(int currentPage) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (currentPage == 1) {
        pagingController.itemList = [];
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = NotificationsPojo.fromJson(await _repo.callNotificationsApi(currentPage, perPage: 30));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          bool isLastPage = currentPage == response.lastPage;
          if (isLastPage) {
            pagingController.appendLastPage(response.massNotificationList);
          } else {
            int nextPageKey = currentPage + 1;
            pagingController.appendPage(response.massNotificationList, nextPageKey);
          }
          if (currentPage == 1) {
            if (response.massNotificationList.isNotEmpty) {
              _subject.sink.add(ApiResponse.completed(response));
            } else {
              _subject.sink.add(ApiResponse.error(languages.noRecordFound));
            }
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
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
  }
}
