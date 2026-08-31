import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import 'login_dl.dart';

const String prefVippsLoginState = 'vipps_login_state';
const String prefVippsLoginStartedAt = 'vipps_login_started_at';

/// Client-side pending window — aligned with server `VIPPS_LOGIN_STATE_TTL` (600s).
const Duration vippsLoginPendingTtl = Duration(minutes: 10);

class VippsLoginHelper {
  static final ApiBaseHelper _api = ApiBaseHelper();

  /// Prevents iOS deep-link double-fire from completing Vipps twice / popping OTP.
  static bool _completing = false;
  static String? _completedState;
  static bool _loginSucceeded = false;
  static bool _resumeNudgeShown = false;

  /// If a deep link arrives while a state-only resume is in flight, keep the
  /// OAuth code and run it as soon as `_completing` clears.
  static String? _deferredCode;
  static String? _deferredState;
  static BuildContext? _deferredContext;
  static Future<void> Function(LoginPojo response)? _deferredOnSuccess;
  static void Function(String message)? _deferredOnError;

  static bool get isCompleting => _completing;
  static bool get loginSucceeded => _loginSucceeded;

  static void savePendingSession(String state) {
    prefSetString(prefVippsLoginState, state);
    prefSetString(
      prefVippsLoginStartedAt,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  static void clearPendingSession() {
    prefSetString(prefVippsLoginState, '');
    prefSetString(prefVippsLoginStartedAt, '');
  }

  static String? pendingStateIfValid() {
    final state = prefGetString(prefVippsLoginState).trim();
    if (state.isEmpty) return null;

    final startedRaw = prefGetString(prefVippsLoginStartedAt).trim();
    final startedAt = int.tryParse(startedRaw);
    if (startedAt != null) {
      final age = DateTime.now().millisecondsSinceEpoch - startedAt;
      if (age > vippsLoginPendingTtl.inMilliseconds) {
        clearPendingSession();
        return null;
      }
    }
    return state;
  }

  static bool get hasPendingVippsLogin {
    if (_loginSucceeded || _completing) return false;
    return pendingStateIfValid() != null;
  }

  /// True when this callback state should still be processed.
  static bool shouldHandleCallback(String state) {
    if (state.isEmpty) return false;
    if (_loginSucceeded || _completedState == state) {
      return false;
    }
    final expected = pendingStateIfValid();
    if (expected == null || expected != state) return false;
    // Allow queueing while a resume complete is in flight.
    return true;
  }

  static void _clearDeferredCallback() {
    _deferredCode = null;
    _deferredState = null;
    _deferredContext = null;
    _deferredOnSuccess = null;
    _deferredOnError = null;
  }

  static Future<void> _flushDeferredCallbackIfAny() async {
    final code = _deferredCode;
    final state = _deferredState;
    final context = _deferredContext;
    final onSuccess = _deferredOnSuccess;
    final onError = _deferredOnError;
    _clearDeferredCallback();

    if (code == null ||
        state == null ||
        context == null ||
        onSuccess == null ||
        _loginSucceeded ||
        _completing) {
      return;
    }
    if (!context.mounted) return;

    await completeFromCallback(
      context,
      code: code,
      state: state,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  static Future<void> signInWithVipps(
    BuildContext context, {
    required Future<void> Function(LoginPojo response) onSuccess,
    void Function(String message)? onError,
  }) async {
    try {
      final start = await _api.post(ApiConst.endPointVippsLoginStart, body: {
        'mobile_app': true,
      });
      if (start['status'] != 1) {
        onError?.call(
          start['message']?.toString() ?? 'Could not start Vipps login',
        );
        return;
      }

      final authorizeUrl = start['authorize_url']?.toString() ?? '';
      final state = start['state']?.toString() ?? '';
      if (authorizeUrl.isEmpty || state.isEmpty) {
        onError?.call('Invalid Vipps login response');
        return;
      }

      _completing = false;
      _completedState = null;
      _loginSucceeded = false;
      _resumeNudgeShown = false;
      _clearDeferredCallback();
      savePendingSession(state);

      final uri = Uri.parse(authorizeUrl);
      if (!await canLaunchUrl(uri)) {
        onError?.call('Could not open Vipps');
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  static Future<void> completeFromCallback(
    BuildContext context, {
    required String code,
    required String state,
    required Future<void> Function(LoginPojo response) onSuccess,
    void Function(String message)? onError,
  }) async {
    // Duplicate deep-link for an already-completed state — ignore silently.
    if (_completedState == state || _loginSucceeded) {
      return;
    }

    final expectedState = pendingStateIfValid();
    if (expectedState == null || expectedState != state) {
      if (_loginSucceeded) return;
      onError?.call('Vipps login session expired. Please try again.');
      return;
    }

    // Resume may already be mid-request; park the OAuth code and retry after.
    if (_completing) {
      _deferredCode = code;
      _deferredState = state;
      _deferredContext = context;
      _deferredOnSuccess = onSuccess;
      _deferredOnError = onError;
      return;
    }

    // Claim before any await so App Links + onGenerateRoute cannot both enter.
    _completing = true;
    await _complete(
      context,
      code: code,
      state: state,
      onSuccess: onSuccess,
      onError: onError,
      alreadyClaimed: true,
    );
  }

  /// Resume path when the app has pending `state` but no local OAuth `code`
  /// (server may have stashed the code on HTTPS callback).
  ///
  /// Returns:
  /// - `true` on success
  /// - `false` on hard failure
  /// - `null` when the server is still waiting for the OAuth code (retryable)
  static Future<bool?> completeFromPendingState(
    BuildContext context, {
    required Future<void> Function(LoginPojo response) onSuccess,
    void Function(String message)? onError,
  }) async {
    if (_loginSucceeded || _completing) return false;

    final state = pendingStateIfValid();
    if (state == null) return false;

    // Deep link already delivered a code while we were waiting — prefer it.
    if (_deferredCode != null && _deferredState == state) {
      await _flushDeferredCallbackIfAny();
      return _loginSucceeded ? true : false;
    }

    _completing = true;
    return _complete(
      context,
      code: null,
      state: state,
      onSuccess: onSuccess,
      onError: onError,
      alreadyClaimed: true,
    );
  }

  static Future<bool?> _complete(
    BuildContext context, {
    required String? code,
    required String state,
    required Future<void> Function(LoginPojo response) onSuccess,
    void Function(String message)? onError,
    bool alreadyClaimed = false,
  }) async {
    if (!alreadyClaimed) {
      if (_completedState == state || _loginSucceeded || _completing) {
        return false;
      }
      _completing = true;
    }

    try {
      final body = <String, dynamic>{
        'state': state,
        'mobile_app': true,
        ApiParam.paramSelectLanguage: resolveSelectedLanguage(),
        ApiParam.paramSelectCurrency: resolveSelectedCurrency(),
        ApiParam.paramDeviceToken: prefGetString(prefDeviceToken),
        ApiParam.paramLoginDevice: Platform.isAndroid
            ? loginDeviceFlutterAndroid
            : loginDeviceFlutterIos,
      };
      if (code != null && code.isNotEmpty) {
        body['code'] = code;
      }
      final prefCountry = prefGetString(prefCountryCode).trim();
      if (prefCountry.isNotEmpty) {
        body[ApiParam.paramSelectCountryCode] = prefCountry;
      }

      final raw =
          await _api.post(ApiConst.endPointVippsLoginComplete, body: body);
      final response = LoginPojo.fromJson(raw);

      if (response.status != 1) {
        if (_loginSucceeded) return false;
        // message_code 10 / retryable: resume beat the deep-link or stash.
        final retryable = response.messageCode == 10 ||
            (raw is Map && raw['retryable'] == true);
        if (retryable && (code == null || code.isEmpty)) {
          return null;
        }
        onError?.call(
          response.message.isNotEmpty
              ? response.message
              : 'Vipps login failed. Please try again.',
        );
        return false;
      }

      _completedState = state;
      _loginSucceeded = true;
      clearPendingSession();
      _clearDeferredCallback();
      await onSuccess(response);
      return true;
    } catch (e) {
      if (_loginSucceeded) return false;
      onError?.call(e.toString());
      return false;
    } finally {
      _completing = false;
      // Deep link may have arrived during this request — finish with the code.
      await _flushDeferredCallbackIfAny();
    }
  }

  /// At most one soft nudge per login attempt when resume cannot finish.
  static void maybeNudgeResumeFailure(String message) {
    if (_resumeNudgeShown || _loginSucceeded) return;
    _resumeNudgeShown = true;
    openSimpleSnackbar(message);
  }
}
