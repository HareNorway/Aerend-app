import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/customCountryCodePicker/country_code.dart';
import '../../../utils/utils.dart';
import '../login/login_dl.dart';
import '../login/login_repo.dart';
import '../otpVerify/otp_verify.dart';
import 'vipps.dart';
import 'vipps_repo.dart';

class VippsIntegrationBloc extends Bloc {
  final VippsIntegrationRepo _signUpRepo = VippsIntegrationRepo();
  final LoginRepo _loginRepo = LoginRepo();
  BuildContext context;

  State<VippsIntegration> state;

  VippsIntegrationBloc(this.context, this.state);

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

  submit() {
    FocusManager.instance.primaryFocus!.unfocus();
    if (formKey.currentState!.validate()) {
      signUpApiCall();
    }
  }

  buttonHide() {
    String fullName = fullNameValidate(fullNameController.text) ?? "";
    String mobile = mobileNumberValidate(mobileController.text) ?? "";
    String email = validateEmailOrNumber(emailController.text);
    if (fullName.isEmpty &&
        email.isEmpty &&
        mobile.isEmpty &&
        (_acceptTermsController.value)) {
      submitValid.add(true);
    } else {
      submitValid.add(false);
    }
  }

  signUpApiCall() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = LoginPojo.fromJson(await _signUpRepo.signUp(
            fullNameController.text.trim(),
            emailController.text.trim(),
            passController.text.trim()));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        _subject.sink.add(ApiResponse.completed(response));
        if (isApiStatus(context, response.status, message, false)) {
          await setDataInPref(response);
          openScreenWithResult(context, const OtpVerify());
        }
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
      await manageLoginResponse(context, response);
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
