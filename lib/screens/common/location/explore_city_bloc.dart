import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import 'explore_city_repo.dart';

class ExploreCityBloc extends Bloc {
  String tag = "ExploreCityBloc>>>";
  final ExploreCityRepo _exploreCityRepo = ExploreCityRepo();
  late BuildContext context;

  final State state;

  ExploreCityBloc(this.context, this.state) {
    getExploreCity();
  }

  final _subject = BehaviorSubject<ApiResponse>();

  Stream<ApiResponse> get subject => _subject.stream;

  getExploreCity({isLoading = true}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if (isLoading) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = await _exploreCityRepo.callGetHareCitiesApi();

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response["messagte_code"], response["message"]);
        if (isApiStatus(context, response["status"], message, true,
            showMess: false)) {
          _subject.sink.add(ApiResponse.completed(response));
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
