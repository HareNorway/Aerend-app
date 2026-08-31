import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/customCountryCodePicker/country_code.dart';
import '../../../constant/constant.dart';
import '../../../dialogs/simple_dialog_util.dart';
import '../../../utils/utils.dart';
import '../login/login.dart';
import '../login/login_dl.dart';
import '../login/login_repo.dart';
import '../otpVerify/otp_verify.dart';
import 'create_profile.dart';
import 'create_profile_repo.dart';

class CreateProfileBloc extends Bloc {
  final CreateProfileRepo _signUpRepo = CreateProfileRepo();
  final LoginRepo _loginRepo = LoginRepo();
  BuildContext context;

  State<CreateProfile> state;

  CreateProfileBloc(this.context, this.state);

  final fullNameController =
      TextEditingController(text: prefGetString(prefUserName));
  final emailController = TextEditingController(text: prefGetString(prefEmail));
  final passController = TextEditingController();
  final rePassController = TextEditingController();
  final referralCodeController = TextEditingController();
  final mobileController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _acceptTermsController = BehaviorSubject<bool>.seeded(false);
  final countryCodeController =
      BehaviorSubject<CountryCode>.seeded(_initialCountryCode());
  final _subject = BehaviorSubject<ApiResponse<LoginPojo>>();
  final _submitting = BehaviorSubject<bool>.seeded(false);
  final submitValid = BehaviorSubject<bool>();

  Function(CountryCode) get changeCountryCode => countryCodeController.sink.add;

  Function(bool) get changeTerms => _acceptTermsController.sink.add;

  BehaviorSubject<ApiResponse<LoginPojo>> get subject => _subject;

  Stream<bool> get submitting => _submitting.stream;

  ValueStream<bool> get acceptTermsStream => _acceptTermsController.stream;

  Stream<CountryCode> get countryCodeStream => countryCodeController.stream;

  CountryCode get selectedCountryCode =>
      countryCodeController.valueOrNull ?? defaultCountryCode;

  static CountryCode _initialCountryCode() {
    final String prefDial = prefGetString(prefCountryCode).trim();
    if (prefDial.isNotEmpty) {
      return CountryCode.fromDialCode(prefDial);
    }
    return defaultCountryCode;
  }

  void onCountryCodeChanged(CountryCode code) {
    changeCountryCode(code);
    buttonHide();
  }

  void _setSubmitting(bool value) {
    if (!_submitting.isClosed) {
      _submitting.sink.add(value);
    }
  }

  void _stopLoading([String? message]) {
    _setSubmitting(false);
    if (_subject.isClosed) return;
    _subject.sink.add(
      ApiResponse.error(message ?? 'Something went wrong. Please try again.'),
    );
  }

  String? _validatePhoneBeforeSubmit() {
    return validateSignupMobileNumber(
      mobileController.text,
      dialCode: selectedCountryCode.dialCode,
    );
  }

  String _loginPhoneIdentifier() {
    final String dial =
        countryCodeController.valueOrNull?.dialCode ?? defaultCountryCode.dialCode!;
    final String dialDigits = dial.replaceAll('+', '').trim();
    return '$dialDigits${mobileController.text.trim()}';
  }

  Future<void> _persistSignupSessionCritical(LoginPojo response) async {
    await prefSetBool(prefIsGuestMode, false);
    await prefSetInt(prefUserId, response.userId);
    await prefSetString(prefAccessToken, response.accessToken);
    await prefSetString(prefContactNumber, mobileController.text.trim());
    await prefSetString(
      prefCountryCode,
      countryCodeController.valueOrNull?.dialCode ?? defaultCountryCode.dialCode!,
    );
  }

  Future<void> _openOtpAfterSignup(LoginPojo response) async {
    _setSubmitting(false);
    if (!_subject.isClosed) {
      _subject.sink.add(ApiResponse.completed(response));
    }

    try {
      await _persistSignupSessionCritical(response);
      await prefSetBool(prefShowDugnadWelcomeAfterOnboarding, true);
      if (!state.mounted) return;
      if (state.widget.returnOnSuccess) {
        await prefSetBool(prefAuthReturnOnSuccess, true);
      }
      final verified = await openScreenWithResult(context, const OtpVerify());
      unawaited(setDataInPref(response));
      if (state.widget.returnOnSuccess &&
          verified == true &&
          state.mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!state.mounted) return;
      _stopLoading(e.toString());
      openSimpleSnackbar(e.toString());
    }
  }

  Future<bool> _tryResumeExistingAccount({
    required String fallbackMessage,
    required bool usePhoneLogin,
  }) async {
    final String password = prefGetString(prefPassword).trim();
    if (password.isEmpty) {
      _setSubmitting(false);
      _subject.sink.add(ApiResponse.error(fallbackMessage));
      if (state.mounted) {
        _showAlreadyRegisteredDialog(fallbackMessage);
      }
      return false;
    }

    final String loginId = usePhoneLogin
        ? _loginPhoneIdentifier()
        : emailController.text.trim();

    try {
      final loginResponse = LoginPojo.fromJson(
        await _loginRepo.login(
          loginTypeEmail,
          loginId,
          password,
          fullNameController.text.trim(),
          '',
          '',
        ),
      );

      if (!state.mounted) return false;

      final String loginMessage = getApiMsg(
        context,
        loginResponse.messageCode,
        loginResponse.message,
      );

      if (loginResponse.status == 1) {
        if (loginResponse.userVerified == 1) {
          _setSubmitting(false);
          if (!_subject.isClosed) {
            _subject.sink.add(ApiResponse.completed(loginResponse));
          }
          await manageLoginResponse(
            context,
            loginResponse,
            popOnSuccess: state.widget.returnOnSuccess,
          );
        } else {
          await _openOtpAfterSignup(loginResponse);
        }
        return true;
      }

      _subject.sink.add(
        ApiResponse.error(
          loginMessage.isNotEmpty ? loginMessage : fallbackMessage,
        ),
      );
      if (state.mounted && loginMessage.isNotEmpty) {
        openSimpleSnackbar(loginMessage);
      }
      return false;
    } catch (e) {
      if (!state.mounted) return false;
      _subject.sink.add(ApiResponse.error(fallbackMessage));
      openSimpleSnackbar(fallbackMessage);
      return false;
    }
  }

  void _showAlreadyRegisteredDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialogUtil(
          title: 'Already registered',
          message: message.isNotEmpty
              ? message
              : 'This phone number is already registered. Sign in to continue.',
          positiveButtonTxt: languages.loginHere,
          negativeButtonTxt: languages.cancel,
          onPositivePress: () {
            Navigator.pop(dialogContext);
            openScreen(context, const Login());
          },
          onNegativePress: () => Navigator.pop(dialogContext),
        );
      },
    );
  }

  Future<void> _handleSignupResponse(LoginPojo response) async {
    final String message =
        getApiMsg(context, response.messageCode, response.message);

    if (response.status != 1) {
      if (response.messageCode == 12) {
        await _tryResumeExistingAccount(
          fallbackMessage: message.isNotEmpty
              ? message
              : 'This phone number is already registered.',
          usePhoneLogin: true,
        );
        return;
      }

      if (response.messageCode == 11) {
        await _tryResumeExistingAccount(
          fallbackMessage: message.isNotEmpty
              ? message
              : 'This email is already registered.',
          usePhoneLogin: false,
        );
        return;
      }

      _setSubmitting(false);
      _subject.sink.add(ApiResponse.error(message));
      if (state.mounted && message.isNotEmpty) {
        openSimpleSnackbar(message);
      }
      return;
    }

    await _openOtpAfterSignup(response);
  }

  submit() {
    prefSetString(prefContactNumber, mobileController.text.trim());
    prefSetString(
      prefCountryCode,
      countryCodeController.valueOrNull?.dialCode ??
          defaultCountryCode.dialCode!,
    );
    FocusManager.instance.primaryFocus?.unfocus();

    final String? phoneError = _validatePhoneBeforeSubmit();
    if (phoneError != null && phoneError.isNotEmpty) {
      _stopLoading(phoneError);
      openSimpleSnackbar(phoneError);
      return;
    }

    if (formKey.currentState!.validate()) {
      if (prefGetBool(prefOTPerror)) {
        changePhoneNumberApiCall();
      } else {
        signUpApiCall();
      }
    }
  }

  buttonHide() {
    String fullName = fullNameValidate(fullNameController.text) ?? "";
    String mobile = validateSignupMobileNumber(
      mobileController.text,
      dialCode: selectedCountryCode.dialCode,
    );
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

  changePhoneNumberApiCall() async {
    var connectivyResult = await (Connectivity().checkConnectivity());
    if (connectivyResult != ConnectivityResult.none) {
      _setSubmitting(true);
      if (!_subject.isClosed) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = LoginPojo.fromJson(
          await _signUpRepo.editProfile(
            prefGetInt(prefUserId),
            fullNameController.text.trim(),
            emailController.text.trim(),
            countryCodeController.valueOrNull?.dialCode ??
                defaultCountryCode.dialCode!,
            mobileController.text.trim(),
          ),
        );

        if (!state.mounted) return;
        await _handleSignupResponse(response);
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _stopLoading(e.toString());
      } finally {
        _setSubmitting(false);
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
      _stopLoading(languages.internetConnLostTitle);
    }
  }

  signUpApiCall() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _setSubmitting(true);
      if (!_subject.isClosed) {
        _subject.sink.add(ApiResponse.loading());
      }
      try {
        var response = LoginPojo.fromJson(
          await _signUpRepo.signUp(
            fullNameController.text.trim(),
            emailController.text.trim(),
            prefGetString(prefPassword),
            countryCodeController.valueOrNull?.dialCode ??
                defaultCountryCode.dialCode!,
            mobileController.text.trim(),
          ),
        );

        if (!state.mounted) return;
        await _handleSignupResponse(response);
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _stopLoading(e.toString());
      } finally {
        _setSubmitting(false);
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
      _stopLoading(languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    countryCodeController.close();
    submitValid.close();
    _submitting.close();
    _subject.close();
    _acceptTermsController.close();
  }
}
