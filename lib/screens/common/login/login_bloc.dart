import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/customCountryCodePicker/country_code.dart';
import '../../../utils/utils.dart';
import 'login.dart';
import 'login_dl.dart';
import 'login_repo.dart';

class LoginBloc extends Bloc {
  BuildContext context;
  final LoginRepo _loginRepo = LoginRepo();

  State<Login> state;

  LoginBloc(this.context, this.state);

  final emailController = TextEditingController();
  final passController = TextEditingController();

  final _countryCodeController = BehaviorSubject<CountryCode>();
  final formKey = GlobalKey<FormState>();

  final _subject = BehaviorSubject<ApiResponse<LoginPojo>>();
  final submitValid = BehaviorSubject<bool>();

  BehaviorSubject<ApiResponse<LoginPojo>> get subject => _subject;

  Stream<CountryCode> get countryCode => _countryCodeController.stream;

  Function(CountryCode) get changeCountryCode =>
      _countryCodeController.sink.add;

  Future<void> loginApiCall(String loginType, String emailAddress,
      String password, String name, String loginId, String profileImg) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = LoginPojo.fromJson(await _loginRepo.login(
            loginType, emailAddress, password, name, loginId, profileImg));
        _subject.sink.add(ApiResponse.completed(response));

        if (!state.mounted) return;
        await manageLoginResponse(
          context,
          response,
          popOnSuccess: state.widget.returnOnSuccess,
        );
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  /// Completes once the login call — including any navigation it triggers
  /// (e.g. the OTP screen being popped) — has finished.
  Future<void> login(String loginType, String email, String name, String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    return loginApiCall(loginType, email, "", name, id, "");
  }

  manageEmailLogin(String loginType) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (formKey.currentState!.validate()) {
      loginApiCall(loginTypeEmail, emailController.text.trim(),
          passController.text.trim(), "", "", "");
    }
  }

  buttonHide() {
    String email = validateEmailOrNumber(emailController.text);
    String pass = passwordValidate(passController.text) ?? "";

    if (pass.isEmpty && email.isEmpty) {
      submitValid.add(true);
    } else {
      submitValid.add(false);
    }
  }

  @override
  void dispose() {
    _countryCodeController.close();
    emailController.dispose();
    passController.dispose();
    _subject.close();
    submitValid.close();
  }
}
