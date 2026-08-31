import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../home/ds_home_dl.dart';
import '../storeDetail/store_detail_dl.dart';
import 'ds_subcategory_repo.dart';

class DsSubCategoryBloc extends Bloc {
  final _dsSubCateRepo = DSSubCateRepo();
  CategoryWiseProductListItem? categoryWiseProductList;
  final _subjectProductCat = BehaviorSubject<ApiResponse<ProductCategoryPojo>>();
  BuildContext context;
  StoreDetailsPojo? storeDetailsPojo;

  State<StatefulWidget> state;

  DsSubCategoryBloc(this.context, this.categoryWiseProductList,  this.storeDetailsPojo, this.state) {
    callStoreProductCatListApi();
  }

  BehaviorSubject<ApiResponse<ProductCategoryPojo>> get subjectProductCat => _subjectProductCat;

  callStoreProductCatListApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectProductCat.sink.add(ApiResponse.loading());
      try {
        var response =
            ProductCategoryPojo.fromJson(await _dsSubCateRepo.callSubCatListApi(categoryWiseProductList!.categoryId, storeDetailsPojo!.storeId));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          _subjectProductCat.sink.add(ApiResponse.completed(response));
        } else {
          _subjectProductCat.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        // openSimpleSnackbar( e.toString());
        _subjectProductCat.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subjectProductCat.close();
  }
}
