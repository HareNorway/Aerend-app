import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../blocs/bloc.dart';
import '../../commonView/customCountryCodePicker/country_code.dart';
import '../../screens/common/login/login_dl.dart';
import '../../screens/common/login/login_repo.dart';
import '../../utils/utils.dart';
import '../changePasswordDialog/change_password_dialog.dart';

class ForgotPasswordDialogBloc extends Bloc {
  late BuildContext context;
  final LoginRepo _loginRepo = LoginRepo();
  final mobileController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  State state;

  ForgotPasswordDialogBloc(this.context, this.state);

  final _countryCodeController = BehaviorSubject<CountryCode>();

  final _subject = BehaviorSubject<ApiResponse<ForgotPassReqPojo>>();

  BehaviorSubject<ApiResponse<ForgotPassReqPojo>> get subject => _subject;

  Stream<CountryCode> get countryCode => _countryCodeController.stream;

  Function(CountryCode) get changeCountryCode => _countryCodeController.sink.add;

  forgotPass() async {
    FocusManager.instance.primaryFocus!.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response =
            ForgotPassReqPojo.fromJson(await _loginRepo.forgotPassReqApi(mobileController.text.trim(), _countryCodeController.value.dialCode!));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        _subject.sink.add(ApiResponse.completed(response));
        if (isApiStatus(context, response.status, message, true)) {
          // Both steps are bottom sheets now (dugnad/auth-screens.jsx), so the
          // old pushReplacement becomes "close this sheet, open the next one".
          Navigator.pop(context);
          final rootContext = navigatorKey.currentContext;
          if (rootContext != null) {
            showChangePasswordSheet(
              rootContext,
              userId: response.userId ?? 0,
            );
          }
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
    _countryCodeController.close();
    mobileController.dispose();
    _subject.close();
  }
}
