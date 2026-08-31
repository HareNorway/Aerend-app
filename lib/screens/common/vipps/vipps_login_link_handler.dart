import 'dart:async';

import 'package:app_links/app_links.dart';

import '../../../main.dart';
import '../../../utils/utils.dart';
import '../login/login_dl.dart';
import '../login/vipps_login_helper.dart';

/// Supplements Flutter's built-in deep linking for Vipps Login (esp. iOS UL).
/// Does not replace `onGenerateRoute` — shared guards prevent double-complete.
///
/// Completes in-place (no extra route push) so Android App Links that already
/// hit `onGenerateRoute` → [VippsLoginReturnScreen] are not doubled.
class VippsLoginLinkHandler {
  VippsLoginLinkHandler._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static bool _bootstrapped = false;
  static String? _lastHandledKey;

  static Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await handleUri(initial);
      }
    } catch (_) {}

    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        unawaited(handleUri(uri));
      },
      onError: (_) {},
    );
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _bootstrapped = false;
  }

  static bool isVippsLoginUri(Uri uri) {
    final path = uri.path;
    final host = uri.host;
    if (path.contains('/vipps/login/callback')) return true;
    if (host == 'vipps-login') return true;
    if (uri.scheme == 'aerend' &&
        (host == 'vipps-login' || path.contains('vipps-login'))) {
      return true;
    }
    return false;
  }

  static Future<void> handleUri(Uri uri) async {
    if (!isVippsLoginUri(uri)) return;

    final code = uri.queryParameters['code'] ?? '';
    final state = uri.queryParameters['state'] ?? '';
    if (code.isEmpty || state.isEmpty) return;

    final key = '$state|$code';
    if (_lastHandledKey == key) return;
    if (!VippsLoginHelper.shouldHandleCallback(state)) return;

    _lastHandledKey = key;

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await VippsLoginHelper.completeFromCallback(
      context,
      code: code,
      state: state,
      onSuccess: (LoginPojo response) async {
        if (!context.mounted) return;
        await manageLoginResponse(context, response);
      },
      onError: (message) {
        // Deep-link ReturnScreen may own the error UI; avoid double snackbars
        // when the first completer already succeeded or is in flight.
        if (VippsLoginHelper.loginSucceeded || VippsLoginHelper.isCompleting) {
          return;
        }
        if (!context.mounted) return;
        openSimpleSnackbar(message);
      },
    );
  }
}

/// Called on app resume (alongside campaign Vipps payment resume).
/// Android-safe: no-op if deep link already completed or nothing pending.
///
/// iOS often resumes from Vipps *before* the universal/custom-scheme deep link
/// delivers `code`+`state`. Wait briefly, then retry state-only complete so we
/// do not race (and previously destroy) the OAuth session.
Future<void> resumePendingVippsLoginIfNeeded() async {
  if (_VippsLoginResumeLock.held) return;
  if (!VippsLoginHelper.hasPendingVippsLogin) return;
  if (VippsLoginHelper.isCompleting || VippsLoginHelper.loginSucceeded) {
    return;
  }

  _VippsLoginResumeLock.held = true;
  try {
    // Prefer deep-link complete (has OAuth code) over state-only resume.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!VippsLoginHelper.hasPendingVippsLogin) return;
    if (VippsLoginHelper.isCompleting || VippsLoginHelper.loginSucceeded) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    const delays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 800),
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2000),
    ];

    for (var i = 0; i < delays.length; i++) {
      final wait = delays[i];
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
      if (!VippsLoginHelper.hasPendingVippsLogin) return;
      if (VippsLoginHelper.isCompleting || VippsLoginHelper.loginSucceeded) {
        return;
      }
      if (!context.mounted) return;

      // Server may have stashed the OAuth code when HTTPS callback hit Laravel.
      final result = await VippsLoginHelper.completeFromPendingState(
        context,
        onSuccess: (LoginPojo response) async {
          if (!context.mounted) return;
          await manageLoginResponse(context, response);
        },
        onError: (_) {
          // Only nudge after retries are exhausted (handled below).
        },
      );

      if (result == true || VippsLoginHelper.loginSucceeded) return;
      if (result == false) {
        VippsLoginHelper.maybeNudgeResumeFailure(
          'Could not finish Vipps login. Please try again.',
        );
        return;
      }
      // result == null → awaiting_code; keep retrying.
    }

    if (VippsLoginHelper.hasPendingVippsLogin &&
        !VippsLoginHelper.loginSucceeded) {
      VippsLoginHelper.maybeNudgeResumeFailure(
        'Could not finish Vipps login. Please try again.',
      );
    }
  } finally {
    _VippsLoginResumeLock.held = false;
  }
}

class _VippsLoginResumeLock {
  static bool held = false;
}
