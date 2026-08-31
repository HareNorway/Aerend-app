import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../storeDetail/store_detail_dl.dart';
import 'product_list_dl.dart';
import 'product_list_repo.dart';

class ProductListBloc extends Bloc {
  String tag = "ProductListBloc>>>";
  final ProductListRepo _productListRepo = ProductListRepo();
  TextEditingController searchTEC = TextEditingController();

  final PagingController<int, ProductListItem> pagingController = PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  late BuildContext context;
  late int storeId, categoryId;
  late bool hasReachedEndOfResults;
  String lastInputValue = "";

  State<StatefulWidget> state;

  ProductListBloc(this.context, this.storeId, this.categoryId, this.state) {
    pagingController.addPageRequestListener((pageKey) {
      getProductList(pageKey, pagingController);
    });
    pagingController.notifyPageRequestListeners(1);

    searchTEC.addListener(() {
      var inputValue = searchTEC.text;
      if (lastInputValue != inputValue) {
        lastInputValue = inputValue;
        pagingController.notifyPageRequestListeners(1);
      }
    });
  }

  final _subject = BehaviorSubject<ApiResponse<StoreProductList>>();
  final _filterVegController = BehaviorSubject<bool>.seeded(false);

  BehaviorSubject<ApiResponse<StoreProductList>> get subject => _subject;

  Stream<bool> get filterVeg => _filterVegController.stream;

  changeFilterVeg(bool value) {
    _filterVegController.sink.add(value);
  }

  getProductList(int currentPage, PagingController<int, ProductListItem> pagingController) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (currentPage == 1) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = StoreProductList.fromJson(await _productListRepo.callStoreProductApi(
            storeId, categoryId, currentPage, perPageRecord, searchTEC.text, _filterVegController.value ? 1 : 0));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          bool isLastPage = currentPage == response.lastPage;
          if (currentPage == 1) {
            pagingController.itemList = [];
          }
          if (isLastPage) {
            pagingController.appendLastPage(response.productList);
          } else {
            int nextPageKey = currentPage + 1;
            pagingController.appendPage(response.productList, nextPageKey);
          }
          if (response.productList.isNotEmpty) {
            _subject.sink.add(ApiResponse.completed(response));
          } else {
            _subject.sink.add(ApiResponse.error(languages.noRecordFound));
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
    searchTEC.dispose();
    pagingController.dispose();
    _filterVegController.close();
  }
}
