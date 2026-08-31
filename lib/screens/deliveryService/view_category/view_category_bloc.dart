import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../home/ds_home_dl.dart';
import '../home/ds_home_repo.dart';
import '../searchStore/search_store_repo.dart';

class ViewCategoryBloc extends Bloc {
  String tag = "ViewCateBloc>>>";
  late BuildContext context;
  late int catId;
  final SearchStoreRepo _searchStoreRepo = SearchStoreRepo();
  final DSHomeRepo _dsHomeRepo = DSHomeRepo();

  State<StatefulWidget> state;

  ViewCategoryBloc(this.context, this.catId, this.state) {
    if (catId == -1) {
      homeStoreListApiCall();
    } else {
      searchStore();
    }
  }

  final _subject = BehaviorSubject<ApiResponse<DsHomeStoreListPojo>>();

  BehaviorSubject<ApiResponse<DsHomeStoreListPojo>> get subject => _subject;

  homeStoreListApiCall() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.add(ApiResponse.loading());
      try {
        var response = DsHomeStoreListPojo.fromJson(
            await _dsHomeRepo.callHomeStoreApi(
                prefGetLatLng().latitude, prefGetLatLng().longitude, '', null, null));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          if (response.storeList.isNotEmpty) {
            _subject.sink.add(ApiResponse.completed(response));
          } else {
            _subject.sink.add(ApiResponse.error(
                prefGetInt(prefSelectedServiceCateId) == 5
                    ? languages.noAnyRestaurantFound
                    : languages.noAnyStoreFound));
          }
        } else {
          _subject.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  searchStore() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = DsHomeStoreListPojo.fromJson(
            await _searchStoreRepo.callSearchStoreApi(
                prefGetLatLng().latitude, prefGetLatLng().longitude, "",
                catId: catId));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          if (response.storeList.isNotEmpty) {
            _subject.sink.add(ApiResponse.completed(response));
          } else {
            _subject.sink.add(ApiResponse.error(
                prefGetInt(prefSelectedServiceCateId) == 5
                    ? languages.noAnyRestaurantFound
                    : languages.noAnyStoreFound));
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

  @override
  void dispose() {
    _subject.close();
  }
}
