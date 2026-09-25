import 'package:flutter/material.dart';

import '../../utils/shared_pref_utill.dart';
import '../common/consent/consent_gate_screen.dart';
import '../common/createProfile/create_profile.dart';
import '../common/login/login.dart';
import '../common/otpVerify/otp_verify.dart';
import '../common/selectLanguageAndCurrency/select_language_and_currency.dart';
import '../common/signUp/sign_up.dart';
import '../common/homeMainV1/home_main_v1.dart';
import '../common/splash/splash.dart';

/// Route names with this prefix hide the global Snurre launcher.
const String snurreLauncherHiddenRoutePrefix = 'snurre-hide/';

/// Whether the signed-in user (not guest) may see or open Snurre.
bool canUseSnurreLauncher() {
  if (prefGetBool(prefIsGuestMode)) return false;
  return prefGetInt(prefUserId) != 0 &&
      prefGetString(prefAccessToken).trim().isNotEmpty;
}

/// Assign on [RouteSettings.name] for pushed screens (see [_buildSmoothRoute]).
String snurreLauncherRouteNameFor(Widget screen) {
  if (screen is Splash) return '${snurreLauncherHiddenRoutePrefix}splash';
  // The Bergen shell carries Ægil in its own nav (search pill + long-press
  // orb) and on Hjem's pull handle, so the floating launcher stays out.
  if (screen is HomeMainV1) return '${snurreLauncherHiddenRoutePrefix}shell';
  if (screen is ConsentGateScreen) {
    return '${snurreLauncherHiddenRoutePrefix}consent';
  }
  if (screen is Login) return '${snurreLauncherHiddenRoutePrefix}login';
  if (screen is SignUp) return '${snurreLauncherHiddenRoutePrefix}signup';
  if (screen is CreateProfile) {
    return '${snurreLauncherHiddenRoutePrefix}create-profile';
  }
  if (screen is OtpVerify) return '${snurreLauncherHiddenRoutePrefix}otp';
  if (screen is SelectLanguageAndCurrency) {
    return '${snurreLauncherHiddenRoutePrefix}language';
  }
  if (screen.runtimeType.toString() == 'SnurreChatScreen') {
    return '${snurreLauncherHiddenRoutePrefix}chat';
  }
  return 'snurre-app';
}

bool isSnurreLauncherHiddenRoute(Route<dynamic>? route) {
  final name = route?.settings.name;
  return name != null && name.startsWith(snurreLauncherHiddenRoutePrefix);
}

/// True while [SnurreChatScreen] is the active route.
final ValueNotifier<bool> snurreChatRouteOnTop = ValueNotifier(false);

/// Drives the global floating Snurre button in [MaterialApp.builder].
final ValueNotifier<bool> snurreLauncherVisible = ValueNotifier(false);

bool shouldShowSnurreLauncherForRoute(Route<dynamic>? route) {
  if (!canUseSnurreLauncher()) return false;
  if (snurreChatRouteOnTop.value) return false;
  if (isSnurreLauncherHiddenRoute(route)) return false;
  return true;
}

void refreshSnurreLauncherVisibility(Route<dynamic>? route) {
  final show = shouldShowSnurreLauncherForRoute(route);
  if (snurreLauncherVisible.value != show) {
    snurreLauncherVisible.value = show;
  }
}

/// Tracks the top [Navigator] route so the overlay launcher can react reliably.
///
/// Maintains an explicit stack — [didRemove]'s `previousRoute` is the route
/// *below the removed one*, not the navigator top, so assigning it directly
/// (e.g. after [Navigator.pushAndRemoveUntil]) incorrectly clears [topRoute]
/// and made the FAB reappear on the screen below.
class SnurreLauncherNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  Route<dynamic>? get topRoute => _stack.isEmpty ? null : _stack.last;

  void _publish() {
    refreshSnurreLauncherVisibility(topRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _stack.add(route);
    _publish();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _stack.remove(route);
    _publish();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _stack.remove(route);
    _publish();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute != null) {
        _stack[index] = newRoute;
      } else {
        _stack.removeAt(index);
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _publish();
  }
}

final SnurreLauncherNavigatorObserver snurreLauncherNavigatorObserver =
    SnurreLauncherNavigatorObserver();
