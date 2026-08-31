import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../blocs/bloc.dart';
import '../../commonView/customCountryCodePicker/country_code.dart';
import '../../screens/common/otpVerify/otp_verify_dl.dart';
import '../../screens/common/otpVerify/otp_verify_repo.dart';
import '../../utils/utils.dart';

class EditPhoneNumberDialogBloc extends Bloc {
  late BuildContext context;

  final formKey = GlobalKey<FormState>();
  final mobileController = TextEditingController();
  final OtpVerifyRepo _otpVerifyRepo = OtpVerifyRepo();

  State state;

  EditPhoneNumberDialogBloc(this.context, this.state);

  final _countryCodeController = BehaviorSubject<CountryCode>();

  final _subject = BehaviorSubject<ApiResponse<EditNumberPojo>>();

  BehaviorSubject<ApiResponse<EditNumberPojo>> get subject => _subject;

  Stream<CountryCode> get countryCode => _countryCodeController.stream;

  Function(CountryCode) get changeCountryCode =>
      _countryCodeController.sink.add;

  void changeCountryCodeFromDial(String dial) {
    try {
      changeCountryCode(CountryCode.fromDialCode(dial));
    } catch (_) {
      changeCountryCode(
        CountryCode(name: dial, dialCode: dial, code: ''),
      );
    }
  }

  editNumber() async {
    if (formKey.currentState!.validate()) {
      if ("${prefGetString(prefCountryCode)}${prefGetString(prefContactNumber)}" ==
          "${_countryCodeController.valueOrNull?.dialCode ?? defaultCountryCode.dialCode}${mobileController.text.trim()}") {
        openSimpleSnackbar(languages.sameEditNumberMsg);
      } else {
        editNumberApiCall();
      }
    }
  }

  editNumberApiCall() async {
    FocusManager.instance.primaryFocus?.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = EditNumberPojo.fromJson(
            await _otpVerifyRepo.callChangeNumberApi(
                mobileController.text.trim(),
                _countryCodeController.value.dialCode!));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        _subject.sink.add(ApiResponse.completed(response));
        if (isApiStatus(context, response.status, message, true)) {
          prefSetString(prefCountryCode, response.selectCountryCode);
          prefSetString(prefContactNumber, response.contactNumber);
          openSimpleSnackbar(languages.resendOtpSuccessMsg);
          // Caller (OTP screen / sheet) handles resend — don't push another OTP.
          Navigator.pop(context, true);
        } else {
          if (response.status != 3) openSimpleSnackbar(message);
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

  @override
  void dispose() {
    _countryCodeController.close();
    mobileController.dispose();
    _subject.close();
  }
}
