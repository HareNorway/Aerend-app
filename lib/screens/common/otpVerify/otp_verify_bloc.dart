import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../constant/constant.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import '../homeMainV1/home_main_v1.dart';
import '../createProfile/create_profile_repo.dart';
import '../login/login_dl.dart';
import 'otp_verify.dart';
import 'otp_verify_dl.dart';
import 'otp_verify_repo.dart';

class OtpVerifyBloc extends Bloc {
  BuildContext context;
  final OtpVerifyRepo _otpVerifyRepo = OtpVerifyRepo();
  final CreateProfileRepo _signUpRepo = CreateProfileRepo();

  State<OtpVerify> state;

  OtpVerifyBloc(this.context, this.state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final needsPhone = prefGetString(prefContactNumber).isEmpty;
      if (needsPhone) {
        // Phone phase is rendered by [OtpVerify] — no dialog.
        return;
      }
      if (prefGetInt(prefUserId) <= 0) {
        openSimpleSnackbar(
          'Registration session expired. Please go back and try again.',
        );
      } else {
        sendOtp();
      }
    });
  }

  final _otpController = BehaviorSubject<String>();
  final _subjectSend = BehaviorSubject<ApiResponse<BaseModel>>();
  final _subjectVerify = BehaviorSubject<ApiResponse<BaseModel>>();
  final _subjectResend = BehaviorSubject<ApiResponse<BaseModel>>();
  final resendOTPController = BehaviorSubject<bool>.seeded(false);

  /// Set after a successful verify so the UI can show the `.otp-done` phase
  /// before navigating away.
  VoidCallback? _pendingFinish;

  Stream<String> get otp => _otpController.stream;

  String get currentOtp => _otpController.valueOrNull ?? '';

  Function(String) get changeOtp => _otpController.sink.add;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectVerify => _subjectVerify;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectResend => _subjectResend;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectSend => _subjectSend;

  /// Persist phone, then send OTP.
  ///
  /// New email signup (Login → Opprett konto) has `userId == 0` and calls
  /// register here with the stashed email/password + phone. Existing users
  /// use change-number.
  Future<void> submitPhone({
    required String phone,
    required String dialCode,
    required VoidCallback onReady,
  }) async {
    final connected = await hasNetworkConnection();
    if (!connected) {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
      _subjectSend.sink.add(
        ApiResponse.error(languages.internetConnLostTitle),
      );
      return;
    }

    _subjectSend.sink.add(ApiResponse.loading());
    try {
      if (prefGetInt(prefUserId) <= 0) {
        await _registerThenContinue(
          phone: phone,
          dialCode: dialCode,
          onReady: onReady,
        );
        return;
      }

      final response = EditNumberPojo.fromJson(
        await _otpVerifyRepo.callChangeNumberApi(phone, dialCode),
      );
      if (!state.mounted) return;
      final message =
          getApiMsg(context, response.messageCode, response.message);
      if (isApiStatus(context, response.status, message, true)) {
        final code = response.selectCountryCode.trim().isNotEmpty
            ? response.selectCountryCode.trim()
            : dialCode.trim().isNotEmpty
                ? dialCode.trim()
                : defaultCountryCode.dialCode!;
        prefSetString(prefCountryCode, code);
        prefSetString(prefContactNumber, response.contactNumber);
        final sent = await sendOtp();
        if (!state.mounted) return;
        if (sent) {
          onReady();
        } else {
          _subjectSend.sink.add(
            ApiResponse.error('Could not send verification code.'),
          );
        }
      } else {
        _subjectSend.sink.add(ApiResponse.error(message));
        if (response.status != 3) openSimpleSnackbar(message);
      }
    } catch (e) {
      if (!state.mounted) return;
      _subjectSend.sink.add(ApiResponse.error(e.toString()));
      openSimpleSnackbar(e.toString());
    }
  }

  Future<void> _registerThenContinue({
    required String phone,
    required String dialCode,
    required VoidCallback onReady,
  }) async {
    final email = prefGetString(prefEmail);
    final password = prefGetString(prefPassword);
    final name = prefGetString(prefUserName);
    if (email.isEmpty || password.isEmpty) {
      _subjectSend.sink.add(
        ApiResponse.error(
          'Missing account details. Please go back and try again.',
        ),
      );
      return;
    }

    final response = LoginPojo.fromJson(
      await _signUpRepo.signUp(
        name.isEmpty ? 'Bruker' : name,
        email,
        password,
        dialCode,
        phone,
      ),
    );
    if (!state.mounted) return;

    final message =
        getApiMsg(context, response.messageCode, response.message);

    if (response.status != 1) {
      _subjectSend.sink.add(ApiResponse.error(message));
      if (message.isNotEmpty) openSimpleSnackbar(message);
      return;
    }

    await prefSetBool(prefIsGuestMode, false);
    await prefSetInt(prefUserId, response.userId);
    await prefSetString(prefAccessToken, response.accessToken);
    await prefSetString(prefContactNumber, phone);
    await prefSetString(
      prefCountryCode,
      dialCode.trim().isNotEmpty ? dialCode.trim() : defaultCountryCode.dialCode!,
    );
    await setDataInPref(response);

    if (!state.mounted) return;
    // Finish sendOtp before leaving phone phase — otherwise StreamBuilder can
    // keep a stale `loading` snapshot when switching to subjectVerify.
    final sent = await sendOtp();
    if (!state.mounted) return;
    if (sent) {
      onReady();
    }
  }

  /// Returns true when the OTP SMS was accepted by the backend.
  Future<bool> sendOtp() async {
    if (prefGetInt(prefUserId) <= 0) {
      _subjectSend.sink.add(
        ApiResponse.error('Unable to send code. Please go back and try again.'),
      );
      return false;
    }

    var connectivityResult = await hasNetworkConnection();
    if (connectivityResult) {
      _subjectSend.sink.add(ApiResponse.loading());

      try {
        var response =
            BaseModel.fromJson(await _otpVerifyRepo.callSendOtpApi());

        if (!state.mounted) return false;

        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectSend.sink.add(ApiResponse.completed(response));
          return true;
        } else {
          _subjectSend.sink.add(ApiResponse.error(message));
          if (response.status != 3) {
            openSimpleSnackbar(message);
          }
          return false;
        }
      } catch (e) {
        if (!state.mounted) return false;
        final String err = e.toString();
        _subjectSend.sink.add(ApiResponse.error(err));
        openSimpleSnackbar(err);
        return false;
      }
    } else {
      if (!state.mounted) return false;
      openSimpleSnackbar(languages.internetConnLostTitle);
      _subjectSend.sink.add(
        ApiResponse.error(languages.internetConnLostTitle),
      );
      return false;
    }
  }

  Future<void> verify({VoidCallback? onSuccess}) async {
    var connectivityResult = await hasNetworkConnection();
    if (connectivityResult) {
      _subjectVerify.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(
            await _otpVerifyRepo.callVerifyOtpApi(_otpController.value));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectVerify.sink.add(ApiResponse.completed(response));
          prefSetInt(prefUserVerified, 1);
          prefSetBool(prefIsGuestMode, false);
          _pendingFinish = () => _navigateAfterVerify();
          onSuccess?.call();
          if (onSuccess == null) {
            finishAfterSuccess();
          }
        } else {
          _subjectVerify.sink.add(ApiResponse.error(message));
          if (response.status != 3) openSimpleSnackbar(message);
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectVerify.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
      _subjectVerify.sink.add(
        ApiResponse.error(languages.internetConnLostTitle),
      );
    }
  }

  void finishAfterSuccess() {
    final finish = _pendingFinish;
    _pendingFinish = null;
    finish?.call();
  }

  void _navigateAfterVerify() {
    if (!state.mounted) return;
    final bool returnToCaller = prefGetBool(prefAuthReturnOnSuccess) ||
        prefGetBool(prefGuestCheckoutResume);
    prefSetBool(prefAuthReturnOnSuccess, false);
    if (returnToCaller && Navigator.canPop(context)) {
      Navigator.pop(context, true);
      return;
    }
    openScreenWithClearPrevious(context, const HomeMainV1(isShowDialog: true));
  }

  Future<void> resendOtp() async {
    var connectivityResult = await hasNetworkConnection();
    if (connectivityResult) {
      _subjectResend.sink.add(ApiResponse.loading());
      try {
        var response =
            BaseModel.fromJson(await _otpVerifyRepo.callResendOtpApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectResend.sink.add(ApiResponse.completed(response));
          openSimpleSnackbar(languages.resendOtpSuccessMsg);
          resendOTPController.add(true);
        } else {
          _subjectResend.sink.add(ApiResponse.error(message));
          if (response.status != 3) openSimpleSnackbar(message);
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectResend.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
      _subjectResend.sink.add(
        ApiResponse.error(languages.internetConnLostTitle),
      );
    }
  }

  @override
  void dispose() {
    _otpController.close();
    _subjectSend.close();
    _subjectVerify.close();
    _subjectResend.close();
    resendOTPController.close();
  }
}
