import 'package:flutter/material.dart';

import '../screens/common/consent/consent_gate_screen.dart';
import '../screens/common/createProfile/create_profile.dart';
import '../screens/common/homeMainV1/home_main_v1.dart';
import '../screens/common/login/login.dart';
import '../screens/common/otpVerify/otp_verify.dart';
import '../screens/common/selectLanguageAndCurrency/select_language_and_currency.dart';
import '../screens/common/signUp/sign_up.dart';
import '../screens/common/splash/splash.dart';
import '../screens/feed/postDetail/post_detail.dart';

/// The app's own route names: the shell, the auth screens, the sheets and
/// every `/bergen/…` push carry this prefix. A screen pushed in an unnamed
/// route (a Vipps return, a harness push) carries none.
const String appRoutePrefix = 'aerend/';

/// The route name for [screen] when it is pushed through `openScreen`.
String routeNameFor(Widget screen) {
  if (screen is Splash) return '${appRoutePrefix}splash';
  if (screen is HomeMainV1) return '${appRoutePrefix}shell';
  if (screen is ConsentGateScreen) return '${appRoutePrefix}consent';
  if (screen is Login) return '${appRoutePrefix}login';
  if (screen is PostDetailScreen) return '${appRoutePrefix}post';
  if (screen is SignUp) return '${appRoutePrefix}signup';
  if (screen is CreateProfile) return '${appRoutePrefix}create-profile';
  if (screen is OtpVerify) return '${appRoutePrefix}otp';
  if (screen is SelectLanguageAndCurrency) return '${appRoutePrefix}language';
  return 'app';
}

/// Whether [route] carries [appRoutePrefix].
bool isAppRoute(Route<dynamic>? route) {
  final name = route?.settings.name;
  return name != null && name.startsWith(appRoutePrefix);
}
