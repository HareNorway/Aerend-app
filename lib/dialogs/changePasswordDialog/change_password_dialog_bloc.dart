import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/login/login.dart';

import '../../blocs/bloc.dart';
import '../../screens/common/login/login_dl.dart';
import '../../screens/common/login/login_repo.dart';
import '../../utils/utils.dart';

class ChangePasswordDialogBloc extends Bloc {
  late BuildContext context;

  late final LoginRepo _loginRepo = LoginRepo();
  final otpController = TextEditingController();
  final passController = TextEditingController();
  final rePassController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  State state;

  ChangePasswordDialogBloc(this.context, this.state);

  final _subject = BehaviorSubject<ApiResponse<LoginPojo>>();

  BehaviorSubject<ApiResponse<LoginPojo>> get subject => _subject;

  submit(int userId) async {
    FocusManager.instance.primaryFocus!.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = LoginPojo.fromJson(await _loginRepo.forgotChangePassApi(userId, otpController.text.trim(), passController.text.trim()));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        _subject.sink.add(ApiResponse.completed(response));
        if (isApiStatus(context, response.status, message, true)) {
          await setDataInPref(response);
          openSimpleSnackbar(languages.passChangeSuccess);
          openScreenWithClearPrevious(context, const Login());
        } else {
          if (response.status != 3) openSimpleSnackbar( message);
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar( e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    passController.dispose();
    rePassController.dispose();
    _subject.close();
  }
}
