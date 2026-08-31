import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import 'change_password.dart';
import 'change_password_repo.dart';

class ChangePasswordBloc extends Bloc {
  final ChangePasswordRepo _changePasswordRepo = ChangePasswordRepo();
  BuildContext context;

  State<ChangePassword> state;

  ChangePasswordBloc(this.context, this.state);

  TextEditingController oldPasswordTEC = TextEditingController();
  TextEditingController newPasswordTEC = TextEditingController();
  TextEditingController reEnterPasswordTEC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _subject = BehaviorSubject<ApiResponse<BaseModel>>();
  final submitValid = BehaviorSubject<bool>();

  BehaviorSubject<ApiResponse<BaseModel>> get subject => _subject;

  submit() async {
    FocusManager.instance.primaryFocus!.unfocus();
    if (formKey.currentState!.validate()) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        _subject.sink.add(ApiResponse.loading());
        try {
          var response = BaseModel.fromJson(await _changePasswordRepo.changePassword(oldPasswordTEC.text.trim(), newPasswordTEC.text.trim()));

          if (!state.mounted) return;
          String message = getApiMsg(context, response.messageCode, response.message);
          if (isApiStatus(context, response.status, message, true)) {
            _subject.sink.add(ApiResponse.completed(response));
            openSimpleSnackbar( languages.passChangeSuccessMsg);
            openScreenWithReplacePrevious(context, const ChangePassword());
          } else {
            _subject.sink.add(ApiResponse.error(message));
          }
        } catch (e) {
          if (!state.mounted) return;
          openSimpleSnackbar( e.toString());
          _subject.sink.add(ApiResponse.error(e.toString()));
        }
      } else {
        _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
        if (!state.mounted) return;
        openSimpleSnackbar( languages.internetConnLostTitle);
      }
    }
  }

  buttonHide() {
    String oldPass = validateOldPassword(oldPasswordTEC.text) ?? "";
    String newPass = validateNewPassword(newPasswordTEC.text) ?? "";
    String confPass = validateConfPassword(reEnterPasswordTEC.text, newPasswordTEC.text) ?? "";

    if (oldPass.isEmpty && newPass.isEmpty && confPass.isEmpty) {
      submitValid.add(true);
    } else {
      submitValid.add(false);
    }
  }

  @override
  void dispose() {
    _subject.close();
    submitValid.close();
    reEnterPasswordTEC.dispose();
    oldPasswordTEC.dispose();
    newPasswordTEC.dispose();
  }
}
