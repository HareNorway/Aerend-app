import '../../base_dl.dart' show BaseModel;
import '../../../../utils/utils.dart';
import '../../createProfile/create_profile_repo.dart';
import '../../login/login_dl.dart';
import '../../login/login_repo.dart';
import '../../otpVerify/otp_verify_dl.dart';
import '../../otpVerify/otp_verify_repo.dart';

/// Result of one auth call: [ok], or the server's [message].
class LfResult<T> {
  const LfResult.ok(this.value) : ok = true, message = '';
  const LfResult.fail(this.message) : ok = false, value = null;

  final bool ok;
  final T? value;
  final String message;
}

/// The Launch onboarding's backend calls — the same endpoints and pref
/// bookkeeping as `LoginBloc`, `OtpVerifyBloc` and `manageLoginResponse`,
/// without their navigation, so every step stays on the one onboarding
/// surface.
class LfAuth {
  final LoginRepo _login = LoginRepo();
  final CreateProfileRepo _signUp = CreateProfileRepo();
  final OtpVerifyRepo _otp = OtpVerifyRepo();

  Future<bool> _online() => hasNetworkConnection();

  String _offline() => languages.internetConnLostTitle;

  /// E-post login (`login`, type email). Saves the session on success.
  Future<LfResult<LoginPojo>> loginEmail(String email, String password) =>
      _loginCall(loginTypeEmail, email, password, '', '', '');

  /// Google / Apple (`login`, social type + provider id).
  Future<LfResult<LoginPojo>> loginSocial(String type, String email, String name, String id) =>
      _loginCall(type, email, '', name, id, '');

  Future<LfResult<LoginPojo>> _loginCall(
    String type,
    String email,
    String password,
    String name,
    String id,
    String img,
  ) async {
    if (!await _online()) return LfResult.fail(_offline());
    try {
      final r = LoginPojo.fromJson(await _login.login(type, email, password, name, id, img));
      if (r.status != 1) return LfResult.fail(r.message);
      return await establish(r);
    } catch (e) {
      return LfResult.fail(e.toString());
    }
  }

  /// `manageLoginResponse` minus navigation.
  Future<LfResult<LoginPojo>> establish(LoginPojo r) async {
    await setDataInPref(r);
    markSessionEstablished();
    if (prefGetInt(prefUserId) == 0 || prefGetString(prefAccessToken).trim().isEmpty) {
      return LfResult.fail(r.message.isNotEmpty ? r.message : 'Login failed to save session. Please try again.');
    }
    return LfResult.ok(r);
  }

  /// Telefon step. A new e-post account registers here (`register` with
  /// the stashed name/e-post/password + phone, as `OtpVerifyBloc` does); an
  /// existing, unverified account changes its number. Then sends the code.
  Future<LfResult<void>> submitPhone({
    required String phone,
    required String dial,
    String? name,
    String? email,
    String? password,
  }) async {
    if (!await _online()) return LfResult.fail(_offline());
    try {
      if (prefGetInt(prefUserId) <= 0) {
        if ((email ?? '').isEmpty || (password ?? '').isEmpty) {
          return const LfResult.fail('Missing account details. Please go back and try again.');
        }
        final r = LoginPojo.fromJson(
          await _signUp.signUp((name ?? '').isEmpty ? 'Bruker' : name!, email!, password!, dial, phone),
        );
        if (r.status != 1) return LfResult.fail(r.message);
        await prefSetBool(prefIsGuestMode, false);
        await prefSetInt(prefUserId, r.userId);
        await prefSetString(prefAccessToken, r.accessToken);
        await prefSetString(prefContactNumber, phone);
        await prefSetString(prefCountryCode, dial);
        await setDataInPref(r);
      } else {
        final r = EditNumberPojo.fromJson(await _otp.callChangeNumberApi(phone, dial));
        if (r.status != 1) return LfResult.fail(r.message);
        final code = r.selectCountryCode.trim().isNotEmpty ? r.selectCountryCode.trim() : dial;
        await prefSetString(prefCountryCode, code);
        await prefSetString(prefContactNumber, r.contactNumber);
      }
      return await sendCode();
    } catch (e) {
      return LfResult.fail(e.toString());
    }
  }

  Future<LfResult<void>> sendCode() async {
    if (!await _online()) return LfResult.fail(_offline());
    try {
      final r = BaseModel.fromJson(await _otp.callSendOtpApi());
      return r.status == 1 ? const LfResult.ok(null) : LfResult.fail(r.message);
    } catch (e) {
      return LfResult.fail(e.toString());
    }
  }

  Future<LfResult<void>> resend() async {
    if (!await _online()) return LfResult.fail(_offline());
    try {
      final r = BaseModel.fromJson(await _otp.callResendOtpApi());
      return r.status == 1 ? const LfResult.ok(null) : LfResult.fail(r.message);
    } catch (e) {
      return LfResult.fail(e.toString());
    }
  }

  /// Kode step (`contact-verification`). Marks the account verified.
  Future<LfResult<void>> verify(String code) async {
    if (!await _online()) return LfResult.fail(_offline());
    try {
      final r = BaseModel.fromJson(await _otp.callVerifyOtpApi(code));
      if (r.status != 1) return LfResult.fail(r.message);
      await prefSetInt(prefUserVerified, 1);
      await prefSetBool(prefIsGuestMode, false);
      await prefSetString(prefPendingReferCode, '');
      await prefSetBool(prefPendingReferFromLink, false);
      return const LfResult.ok(null);
    } catch (e) {
      return LfResult.fail(e.toString());
    }
  }
}
