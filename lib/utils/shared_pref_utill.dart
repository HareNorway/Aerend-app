
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constant/constant.dart';
import '../main.dart';

const String prefSelectedLanguageCode = "SelectedLanguageCode";
/// Set once the user picks a language themselves, so the Norwegian-default
/// migration below never overrides a deliberate choice.
const String prefLanguagePickedByUser = "LanguagePickedByUser";
const String prefSelectedCurrency = "SelectedCurrency";
const String prefAccessToken = "AccessToken";
const String prefUserId = "UserId";
const String prefCartCount = "CartCount";
const String prefCountryCode = "countryCode";
const String prefUserName = "userName";
const String prefEmail = "email";
const String prefPassword = "password";
const String prefLoginType = "loginType";
const String prefProfileImage = "profileImage";
const String prefContactNumber = "contactNumber";
const String prefEmergencyContact = "emergencyContact";
const String prefReferralCode = "referralCode";
const String prefAerendCredit = "credit";
const String prefUserVerified = "userVerified";
const String prefDeviceToken = "deviceToken";
/// Count used for app-icon badge on incoming chat pushes (best-effort).
const String prefChatAppBadgeCount = "chatAppBadgeCount";
const String prefDemoDialogOpen = "demoDialogOpen";
const String prefSelectedServiceCateId = "selectedServiceCateId";
const String prefHandicap = "handicap";
const String prefChildSeat = "childSeat";
const String prefProductId = "productId";
const String prefDriverGender = "driverGender";
const String prefServerTimeZone = "serverTimeZone";
const String prefSelectedStoreFullResponse = "dsKeySelectedStoreFullRes";
const String prefNewDeliveryAddress = "keyNewDeliveryAddress";
const String prefNewDeliveryAddressId = "keyNewDeliveryAddressId";
const String prefSelectedServiceCateName = "selectedServiceCateName";
const String prefSelectedServiceCateIcon = "selectedServiceCateIcon";
const String prefIsShownOnBoarding = "isShownOnBoarding";
const String prefOldOrderStatus = "oldStatus";
const String prefOldWayPointOrderStatus = "oldWaypointStatus";
const String prefServiceAccountAccessToken = "serviceAccountAccessToken";
const String prefOTPerror = "prefOTPerror";
const String prefSelectedLatLng = "selectedLatLng";
const String prefTip = "tip";
const String prefThemeMode = "themeMode";
const String prefHomeCategoryCache = "homeCategoryCache";
const String prefIsGuestMode = "isGuestMode";
/// Vilkår og personvern accepted on this device — returning users skip the
/// terms step of the onboarding flow.
const String prefTermsAccepted = "termsAccepted";
/// Referral (verve) code entered or received before an account exists; sent
/// as `refer_code` with the register call.
const String prefPendingReferCode = "pendingReferCode";
/// [prefPendingReferCode] arrived through an `/invite?code=` link (shows the
/// "Du er vervet" card instead of the code input).
const String prefPendingReferFromLink = "pendingReferFromLink";
/// Set when guest taps Pay on store checkout; cleared after resume.
const String prefGuestCheckoutResume = "guestCheckoutResume";
const String prefGuestCheckoutPaymentType = "guestCheckoutPaymentType";
const String prefGuestCheckoutTakenType = "guestCheckoutTakenType";
const String prefGuestCheckoutSpendCredit = "guestCheckoutSpendCredit";
/// Set when login was opened to return to a prior screen after OTP.
const String prefAuthReturnOnSuccess = "authReturnOnSuccess";






late SharedPreferences _prefs;

Future<SharedPreferences> initSharedPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  await ensureLocalePrefsDefaults();
  return _prefs;
}

/// API requires non-empty language/currency; guests may skip the picker screen.
Future<void> ensureLocalePrefsDefaults() async {
  final stored = prefGetString(prefSelectedLanguageCode).trim();
  if (stored.isEmpty) {
    await prefSetString(prefSelectedLanguageCode, defaultLanguage);
  } else if (stored == _legacyDefaultLanguage &&
      !prefGetBool(prefLanguagePickedByUser)) {
    // The app shipped with an unintended `en` default. Changing
    // `defaultLanguage` alone does nothing for installs that already persisted
    // `en` — this migrates them once, unless the user picked English on
    // purpose (in which case [setLocale] has set the flag).
    await prefSetString(prefSelectedLanguageCode, defaultLanguage);
  }
  if (prefGetString(prefSelectedCurrency).trim().isEmpty) {
    await prefSetString(prefSelectedCurrency, defaultCurrency);
  }
}

String resolveSelectedLanguage() {
  final code = prefGetString(prefSelectedLanguageCode).trim();
  return code.isNotEmpty ? code : defaultLanguage;
}

String resolveSelectedCurrency() {
  final currency = prefGetString(prefSelectedCurrency).trim();
  return currency.isNotEmpty ? currency : defaultCurrency;
}

String prefGetString(String key) {
  return _prefs.getString(key) ?? "";
}

bool prefGetBool(String key) {
  return _prefs.getBool(key) ?? false;
}

String prefGetStringWithDefaultValue(String key, String defaultValue) {
  return _prefs.getString(key) ?? defaultValue;
}

int prefGetInt(String key) {
  return _prefs.getInt(key) ?? 0;
}

Future<void> prefSetBool(String key, bool value) async {
  await _prefs.setBool(key, value);
}

Future<void> prefSetString(String key, String value) async {
  await _prefs.setString(key, value);
}

Future<void> prefSetInt(String key, int value) async {
  await _prefs.setInt(key, value);
}

//deletes..
Future<bool> prefRemove(String key) async => await _prefs.remove(key);

Future<bool> prefClear() async => await _prefs.clear();

prefClearWithRemainSomeData() async {
  String languageCode = prefGetString(prefSelectedLanguageCode);
  bool isShownOnBoarding = prefGetBool(prefIsShownOnBoarding);
  await _prefs.clear();
  prefSetString(prefSelectedLanguageCode, languageCode);
  prefSetBool(prefIsShownOnBoarding, isShownOnBoarding);
}

Future<void> saveThemeMode(ThemeMode themeMode) async {
  prefSetString(prefThemeMode, _themeModeToString(themeMode));
}

ThemeMode getSavedThemeMode() {
  final themeModeString = prefGetString(prefThemeMode);
  switch (themeModeString) {
    case "dark":
      return ThemeMode.dark;
    case "light":
      return ThemeMode.light;
    case "system":
      return ThemeMode.system;
    default:
      return ThemeMode.system;
  }
}

String _themeModeToString(ThemeMode themeMode) {
  switch (themeMode) {
    case ThemeMode.dark:
      return "dark";
    case ThemeMode.light:
      return "light";
    case ThemeMode.system:
      return "system";
  }
}

/// The pre-Norwegian default. Only used to recognise installs that never made
/// a deliberate language choice.
const String _legacyDefaultLanguage = "en";

Future<Locale> setLocale(String languageCode) async {
  await _prefs.setString(prefSelectedLanguageCode, languageCode);
  // Any explicit pick — including English — is now sticky.
  await prefSetBool(prefLanguagePickedByUser, true);
  return _locale(languageCode);
}

Locale getLocale() {
  String languageCode =
      _prefs.getString(prefSelectedLanguageCode) ?? defaultLanguage;
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  return languageCode.isNotEmpty
      ? Locale(languageCode, '')
      : const Locale('en', '');
}

Future changeLanguage(
    BuildContext context, String selectedLanguageCode, State state) async {
  var locale = await setLocale(selectedLanguageCode);
  if (!state.mounted) return;
  MyApp.setLocale(context, locale);
}

prefSetLatLng(LatLng latLng) async {
  prefSetString(prefSelectedLatLng, "${latLng.latitude},${latLng.longitude}");
}

LatLng prefGetLatLng() {
  String stringLatLng =
      prefGetStringWithDefaultValue(prefSelectedLatLng, "60.3913,5.3221");
  List<String> latLngParts = stringLatLng.split(',');
  if (latLngParts.length < 2) {
    return const LatLng(60.3913, 5.3221);
  }

  double latitude = double.tryParse(latLngParts[0].trim()) ?? 60.3913;
  double longitude = double.tryParse(latLngParts[1].trim()) ?? 5.3221;

  return LatLng(latitude, longitude);
}

/// Prefer the saved delivery address (same source as checkout / home chip); fall back to [prefGetLatLng].
LatLng prefGetLatLngForStoreSearch() {
  try {
    final raw = prefGetString(prefNewDeliveryAddress).trim();
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        final la = (m['lat'] ?? m['latitude'])?.toString().trim() ?? '';
        final lo = (m['long'] ?? m['lng'] ?? m['longitude'])?.toString().trim() ?? '';
        final dLat = double.tryParse(la);
        final dLon = double.tryParse(lo);
        if (dLat != null &&
            dLon != null &&
            dLat.abs() > 1e-7 &&
            dLon.abs() > 1e-7) {
          return LatLng(dLat, dLon);
        }
      }
    }
  } catch (_) {}
  return prefGetLatLng();
}
