import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../campaign_repo.dart';
import '../models/campaign_list_pojo.dart';

class CampaignListBloc extends Bloc {
  final BuildContext context;
  final State state;
  final CampaignRepo _repo = CampaignRepo();

  final _campaignsSubject = BehaviorSubject<ApiResponse<CampaignListPojo>>();

  Stream<ApiResponse<CampaignListPojo>> get campaignsStream =>
      _campaignsSubject.stream;

  CampaignListBloc(this.context, this.state) {
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      _campaignsSubject.sink.add(ApiResponse.loading());
      try {
        var response =
            CampaignListPojo.fromJson(await _repo.getActiveCampaigns());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _campaignsSubject.sink.add(ApiResponse.completed(response));
        } else {
          _campaignsSubject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        _campaignsSubject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  Future<void> refresh() => _fetchCampaigns();

  @override
  void dispose() {
    _campaignsSubject.close();
  }
}
