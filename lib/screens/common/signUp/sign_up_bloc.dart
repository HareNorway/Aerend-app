import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/customCountryCodePicker/country_code.dart';
import '../../../utils/utils.dart';
import '../login/login_dl.dart';
import '../login/login_repo.dart';
import '../createProfile/create_profile.dart';

class SignUpBloc extends Bloc {
  final LoginRepo _loginRepo = LoginRepo();
  BuildContext context;

  State<StatefulWidget> state;
  final bool returnOnSuccess;

  SignUpBloc(this.context, this.state, {this.returnOnSuccess = false});

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final rePassController = TextEditingController();
  final referralCodeController = TextEditingController();
  final mobileController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _acceptTermsController = BehaviorSubject<bool>.seeded(false);
  final countryCodeController = BehaviorSubject<CountryCode>();
  final _subject = BehaviorSubject<ApiResponse<LoginPojo>>();
  final submitValid = BehaviorSubject<bool>();

  Function(CountryCode) get changeCountryCode => countryCodeController.sink.add;

  Function(bool) get changeTerms => _acceptTermsController.sink.add;

  BehaviorSubject<ApiResponse<LoginPojo>> get subject => _subject;

  ValueStream<bool> get acceptTermsStream => _acceptTermsController.stream;

  submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!formKey.currentState!.validate()) {
      buttonHide();
      return;
    }

    prefSetString(prefUserName, fullNameController.text.trim());
    prefSetString(prefEmail, emailController.text.trim());
    prefSetString(prefPassword, passController.text.trim());

    final completed = await openScreenWithResult(
      context,
      CreateProfile(returnOnSuccess: returnOnSuccess),
    );
    if (returnOnSuccess &&
        completed == true &&
        state.mounted &&
        Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
    // FocusManager.instance.primaryFocus!.unfocus();
    // if (formKey.currentState!.validate()) {
    //   signUpApiCall();
    // }
  }

  buttonHide() {
    String fullName = fullNameValidate(fullNameController.text) ?? "";
    String pass = passwordValidate(passController.text) ?? "";
    String rePass =
        confirmPasswordValidate(rePassController.text, passController.text) ??
            "";
    // String mobile = mobileNumberValidate(mobileController.text) ?? "";
    String email = validateEmailOrNumber(emailController.text);
    if (fullName.isEmpty &&
        pass.isEmpty &&
        rePass.isEmpty &&
        email.isEmpty &&
        (_acceptTermsController.value)) {
      submitValid.add(true);
    } else {
      submitValid.add(false);
    }
  }

  socialLogin(String loginType, String name, String id, String email) async {
    FocusManager.instance.primaryFocus!.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      loginApiCall(loginType, email, "", name, id, "");
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  loginApiCall(String loginType, String emailAddress, String password,
      String name, String loginId, String profileImg) async {
    _subject.sink.add(ApiResponse.loading());
    try {
      var response = LoginPojo.fromJson(await _loginRepo.login(
          loginType, emailAddress, password, name, loginId, profileImg));

      _subject.sink.add(ApiResponse.completed(response));

      if (!state.mounted) return;
      await manageLoginResponse(
        context,
        response,
        popOnSuccess: returnOnSuccess,
      );
    } catch (e) {
      openSimpleSnackbar(e.toString());
      _subject.sink.add(ApiResponse.error(e.toString()));
    }
  }

  @override
  void dispose() {
    countryCodeController.close();
    submitValid.close();
    _subject.close();
    _acceptTermsController.close();
  }
}
