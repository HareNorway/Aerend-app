import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../home/ds_home_dl.dart';
import '../home/ds_home_repo.dart';
import 'favourite_store_screen.dart';

class FavouriteStoreBloc extends Bloc {
  BuildContext context;
  final DSHomeRepo _dsHomeRepo = DSHomeRepo();
  final _subjectFavouriteStore = BehaviorSubject<ApiResponse<FavouriteStorePojo>>();
  final PagingController<int, StoreListItem> pagingController = PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  State<FavouriteStoreScreen> state;

  FavouriteStoreBloc(this.context, this.state) {
    pagingController.addPageRequestListener((pageKey) {
      callFavouriteStoreApi(pageKey, pagingController);
    });
    pagingController.notifyPageRequestListeners(1);
  }

  BehaviorSubject<ApiResponse<FavouriteStorePojo>> get subjectFavouriteStore => _subjectFavouriteStore;

  callFavouriteStoreApi(int currentPage, PagingController<int, StoreListItem> pagingController) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (currentPage == 1) {
        _subjectFavouriteStore.sink.add(ApiResponse.loading());
      }
      try {
        var response = FavouriteStorePojo.fromJson(await _dsHomeRepo.callFavouriteStoreApi(1, currentPage));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          bool isLastPage = currentPage == response.totalPage;
          if (currentPage == 1) {
            pagingController.itemList = [];
          }
          if (isLastPage) {
            pagingController.appendLastPage(response.storeLists);
          } else {
            int nextPageKey = currentPage + 1;
            pagingController.appendPage(response.storeLists, nextPageKey);
          }
          if (response.storeLists.isNotEmpty) {
            _subjectFavouriteStore.sink.add(ApiResponse.completed(response));
          } else {
            _subjectFavouriteStore.sink.add(ApiResponse.error(languages.noRecordFound));
          }
        } else {
          _subjectFavouriteStore.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar( e.toString());
        _subjectFavouriteStore.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subjectFavouriteStore.close();
    pagingController.dispose();
  }
}
