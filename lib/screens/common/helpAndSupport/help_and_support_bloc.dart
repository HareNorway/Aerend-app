import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import 'help_and_support.dart';
import 'help_and_support_dl.dart';
import 'help_and_support_repo.dart';

class HelpAndSupportBloc extends Bloc {
  String tag = "HelpSuppBloc>>>";
  BuildContext context;
  final HelpAndSupportRepo _repo = HelpAndSupportRepo();

  State<HelpAndSupport> state;

  HelpAndSupportBloc(this.context, this.state) {
    getSupportPage();
  }

  final _subject = BehaviorSubject<ApiResponse<SupportPojo>>();

  BehaviorSubject<ApiResponse<SupportPojo>> get subject => _subject;

  getSupportPage() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = SupportPojo.fromJson(await _repo.getHelpAndSupport());

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          if ((response.pages).isNotEmpty) {
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
  }
}
