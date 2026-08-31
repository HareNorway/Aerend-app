
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
const String prefReenSportsMode = "reenSportsMode";
const String prefActiveSportsClubId = "activeSportsClubId";
const String prefActiveSportsClubName = "activeSportsClubName";
const String prefActiveSportsClubImage = "activeSportsClubImage";
const String prefHomeCategoryCache = "homeCategoryCache";
// Dugnad mode — user-driven (separate from server-schedule reen prefs above).
const String prefDugnadModeEnabled = "dugnadModeEnabled";
const String prefSelectedClubId = "selectedClubId";
const String prefSelectedClubName = "selectedClubName";
const String prefSelectedClubShortName = "selectedClubShortName";
const String prefSelectedClubLogo = "selectedClubLogo";
const String prefSelectedClubArea = "selectedClubArea";
const String prefSelectedClubPortalThemeColor = "selectedClubPortalThemeColor";
const String prefSelectedClubPortalBackgroundColor = "selectedClubPortalBackgroundColor";
const String prefMembershipNumber = "membershipNumber";
const String prefPointsTeamId = "pointsTeamId";
const String prefPointsTeamName = "pointsTeamName";
const String prefPointsTeamLogo = "pointsTeamLogo";
const String prefPointsTeamAgeGroup = "pointsTeamAgeGroup";
const String prefPointsTotal = "pointsTotal";
const String prefIsGuestMode = "isGuestMode";
/// Set when guest taps Pay on store checkout; cleared after resume.
const String prefGuestCheckoutResume = "guestCheckoutResume";
const String prefGuestCheckoutPaymentType = "guestCheckoutPaymentType";
const String prefGuestCheckoutTakenType = "guestCheckoutTakenType";
const String prefGuestCheckoutSpendCredit = "guestCheckoutSpendCredit";
/// Set when guest taps Pay on campaign checkout.
const String prefGuestCampaignCheckoutResume = "guestCampaignCheckoutResume";
const String prefGuestCampaignPayMode = "guestCampaignPayMode";
const String prefGuestCampaignPaymentMethod = "guestCampaignPaymentMethod";
/// Set when login was opened to return to a prior screen after OTP.
const String prefAuthReturnOnSuccess = "authReturnOnSuccess";
/// Set only while a newly registered user is finishing Dugnad onboarding.
const String prefShowDugnadWelcomeAfterOnboarding =
    "showDugnadWelcomeAfterOnboarding";
const String prefDugnadWelcomeBonusPoints = "dugnadWelcomeBonusPoints";
/// Pending referred-user signup points pop (shown after welcome, then cleared).
const String prefDugnadReferralJoinPoints = "dugnadReferralJoinPoints";
/// Guided tour (dugnad app walkthrough). Completed = prompt suppressed / final
/// step shows its "again" copy. RewardPaid = the 50-point reward strip hidden.
const String prefDugnadTourCompleted = "dugnadTourCompleted";
const String prefDugnadTourRewardPaid = "dugnadTourRewardPaid";
/// Set after the tour-completion points pop has been queued at least once.
const String prefDugnadTourPopShown = "dugnadTourPopShown";
/// Set only when the tour is FINISHED (not merely dismissed). Gates the reward
/// retry so a dismiss never awards; a later finish still does.
const String prefDugnadTourFinished = "dugnadTourFinished";

/// Pending Dugnad referral from deep link or manual entry (JSON).
const String prefPendingDugnadReferral = "pendingDugnadReferral";

/// Last acknowledged points tier key (per user+club) for level-up celebration.
const String prefDugnadLastSeenTierKey = "dugnadLastSeenTierKey";

/// Home season finale / carryover card dismissed by user.
const String prefDugnadSeasonFinaleDismissed = "dugnadSeasonFinaleDismissed";
const String prefDugnadReferralPromoDismissed = "dugnadReferralPromoDismissed";

/// Incoming referral banner dismissed by user (stores referral record id).
const String prefDugnadIncomingReferralDismissedId =
    "dugnadIncomingReferralDismissedId";
/// Last referral ledger id whose points pop was shown (or baselined) for this install.
const String prefDugnadReferralPopCursor = "dugnadReferralPopCursor";
const String prefDugnadReferralPopCursorReady = "dugnadReferralPopCursorReady";
const String prefDugnadMissionPopCursor = "dugnadMissionPopCursor";

/// Serialized [DugnadDataCache] snapshot for cold dugnad start.
const String prefDugnadDataCacheSnapshot = "dugnadDataCacheSnapshot";

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
  final referralPopKeep = <String, Object?>{};
  for (final key in _prefs.getKeys()) {
    if (key.startsWith(prefDugnadReferralPopCursor) ||
        key.startsWith(prefDugnadMissionPopCursor)) {
      referralPopKeep[key] = _prefs.get(key);
    }
  }
  await _prefs.clear();
  prefSetString(prefSelectedLanguageCode, languageCode);
  prefSetBool(prefIsShownOnBoarding, isShownOnBoarding);
  for (final entry in referralPopKeep.entries) {
    final value = entry.value;
    if (value is bool) {
      await prefSetBool(entry.key, value);
    } else if (value is int) {
      await prefSetInt(entry.key, value);
    }
  }
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
