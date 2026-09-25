import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aerend_customer/commonView/customCountryCodePicker/custom_country_code_picker.dart';
import 'package:aerend_customer/commonView/logout_curtain.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../blocs/bloc.dart';
import '../constant/constant.dart';
import '../dialogs/simple_dialog_util.dart';
import '../firebase_options.dart';
import '../googleApi/geocoding_api_call.dart';
import '../main.dart';
import '../redux/store.dart';
import '../theme/bergen_tokens.dart';
import '../screens/common/base_dl.dart';
import '../screens/common/homeMainV1/home_main_v1.dart';
import '../screens/common/login/login_dl.dart';
import '../screens/common/otpVerify/otp_verify.dart';
import '../screens/common/splash/splash.dart';
import '../screens/snurre/snurre_launcher_policy.dart';
import '../screens/deliveryService/home/ds_home.dart';
import '../screens/deliveryService/storeDetail/store_detail_dl.dart';
import '../screens/rideService/rideDetail/ride_detail.dart';
import '../screens/rideService/rideDetail/ride_detail_dl.dart';
import '../screens/rideService/rideDetail/ride_detail_repo.dart';
import '../services/push_notification_service.dart';
import 'shared_pref_utill.dart';

export '../blocs/validator.dart';
export '../commonView/custom_border_button.dart';
export '../commonView/custom_fill_button.dart';
export '../commonView/load_image_with_placeholder.dart';
export '../constant/constant.dart';
export '../main.dart';
export '../theme/ae_typography.dart';
export 'custom_icons.dart';
export 'get_location_utils.dart';
export 'shared_pref_utill.dart';

String tag = "Utils>>>";

getPlaceQuery(String text, double latitude, double longitude) {
  return "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&location=$latitude,$longitude&radius=20&sensor=true&key=";
}

getPlaceIDQuery(String placeId) {
  return "https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&language=en&sensor=true&key=";
}

String getRouteWithMultiStop(
  String startLocation,
  String destinationLocation,
  List<LatLng> wayPoint,
) {
  String origin = "origin=$startLocation";
  String waypoint = "";
  String destination = "&destination=$destinationLocation";

  String points = "";
  if (wayPoint.isNotEmpty) {
    for (var latLng in wayPoint) {
      points = "$points|via:${latLng.latitude},${latLng.longitude}";
    }
    if (points.trim().isNotEmpty) {
      waypoint = "&waypoints=optimize:true$points";
    }
  }
  return "https://maps.googleapis.com/maps/api/directions/json?$origin$waypoint$destination&mode=DRIVING&language=en&key=";
}

getGeoCodingQuery(double latitude, double longitude) {
  return "https://maps.google.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=";
}

getGeoCodingAddress(String keyword, String country) {
  return "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$keyword&components=country:${getCountryISOCodeFromName(country)}&types=address&key=";
}

/// Format a price for display in Norwegian style: "149 NOK" or "149,90 NOK".
/// Whole amounts hide the decimal part. Fractional amounts use comma separator.
/// This is display-only — no calculation is performed.
String formatNok(double amount) {
  String selectedCurrency = prefGetString(prefSelectedCurrency);
  if (selectedCurrency.isEmpty) selectedCurrency = defaultCurrency;
  if (amount == amount.roundToDouble()) {
    return '${amount.toInt()} $selectedCurrency';
  }
  final whole = amount.truncate();
  final frac = ((amount - whole).abs() * 100).round().toString().padLeft(
    2,
    '0',
  );
  return '$whole,$frac $selectedCurrency';
}

String getAmountWithCurrency(dynamic amount) {
  return formatNok(amount.toDouble());
}

String getAmountCurrency(dynamic value) {
  if (value == null) {
    StackTrace.current;
  }
  return formatNok(value.toDouble());
}

void focusInMap(
  GoogleMapController? googleMapController,
  double latitude,
  double longitude,
  bool isZoom,
) {
  final c = googleMapController;
  if (c == null) return;
  void logMapErr(Object e, StackTrace st) {
    debugPrint('focusInMap: $e\n$st');
  }

  if (isZoom) {
    c
        .animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(latitude, longitude), zoom: 15.0),
          ),
        )
        .catchError((Object e, StackTrace st) => logMapErr(e, st));
  } else {
    c
        .getZoomLevel()
        .then((value) {
          return c.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(latitude, longitude), zoom: value),
            ),
          );
        })
        .catchError((Object e, StackTrace st) => logMapErr(e, st));
  }
}

Future<List<Placemark>?> getAddress(double latitude, double longitude) async {
  final coordinates = LatLng(latitude, longitude);
  try {
    return await placemarkFromCoordinates(latitude, longitude);
  } catch (e) {
    return await GeoCodingApiCall().findAddressesFromCoordinates(coordinates);
  }
}

Future<String> getStringAddress(double latitude, double longitude) async {
  final coordinates = LatLng(latitude, longitude);
  try {
    List<Placemark> placeMark = await placemarkFromCoordinates(
      latitude,
      longitude,
    );
    return '${placeMark.first.name!.isNotEmpty ? '${placeMark.first.name!}, ' : ''}${placeMark.first.thoroughfare!.isNotEmpty ? '${placeMark.first.thoroughfare!}, ' : ''}${placeMark.first.subLocality!.isNotEmpty ? '${placeMark.first.subLocality!}, ' : ''}${placeMark.first.locality!.isNotEmpty ? '${placeMark.first.locality!}, ' : ''}${placeMark.first.subAdministrativeArea!.isNotEmpty ? '${placeMark.first.subAdministrativeArea!}, ' : ''}${placeMark.first.postalCode!.isNotEmpty ? '${placeMark.first.postalCode!}, ' : ''}${placeMark.first.administrativeArea!.isNotEmpty ? placeMark.first.administrativeArea : ''}';
  } catch (e) {
    List<Placemark> placeMark =
        (await GeoCodingApiCall().findAddressesFromCoordinates(coordinates)) ??
        [];
    return '${placeMark.first.name!.isNotEmpty ? '${placeMark.first.name!}, ' : ''}${placeMark.first.thoroughfare!.isNotEmpty ? '${placeMark.first.thoroughfare!}, ' : ''}${placeMark.first.subLocality!.isNotEmpty ? '${placeMark.first.subLocality!}, ' : ''}${placeMark.first.locality!.isNotEmpty ? '${placeMark.first.locality!}, ' : ''}${placeMark.first.subAdministrativeArea!.isNotEmpty ? '${placeMark.first.subAdministrativeArea!}, ' : ''}${placeMark.first.postalCode!.isNotEmpty ? '${placeMark.first.postalCode!}, ' : ''}${placeMark.first.administrativeArea!.isNotEmpty ? placeMark.first.administrativeArea : ''}';
  }
}

Future<void> openUrl(
  String url, {
  LaunchMode launchMode = LaunchMode.externalApplication,
}) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url, mode: launchMode);
  } else {
    logd(tag, "Error");
  }
}

Future<void> openUrlInStore(String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url, mode: LaunchMode.externalNonBrowserApplication);
  } else {
    logd(tag, "Error");
  }
}

/// Standard push route with **edge swipe-to-go-back** (iOS-style).
///
/// Prefer this over [PageRouteBuilder] / plain custom transitions — those
/// disable the left-edge drag gesture, so users were stuck tapping back.
PageRoute<T> buildAppPageRoute<T extends Object?>(
  Widget screen, {
  String? name,
  bool fullscreenDialog = false,
}) {
  return CupertinoPageRoute<T>(
    settings: RouteSettings(name: name ?? snurreLauncherRouteNameFor(screen)),
    builder: (_) => screen,
    fullscreenDialog: fullscreenDialog,
  );
}

PageRoute<dynamic> _buildSmoothRoute(Widget screen) =>
    buildAppPageRoute(screen);

void openScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(_buildSmoothRoute(screen));
}

void openScreenWithReplacePrevious(BuildContext context, Widget screen) {
  Navigator.of(context).pushReplacement(_buildSmoothRoute(screen));
}

void openScreenWithClearPrevious(BuildContext context, Widget screen) {
  Navigator.of(
    context,
  ).pushAndRemoveUntil(_buildSmoothRoute(screen), (route) => false);
}

/// Zero-duration opaque swap on the shared Reen navy surface.
///
/// Splash → consent → login must not Cupertino-slide: the wordmark FLIP owns
/// the motion (`dgcFlipMark` in `consent-gate.jsx`). A slide would fight it
/// and flash a blank frame between two identical gradients.
PageRoute<T> buildNavyHandoffRoute<T extends Object?>(Widget screen) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: snurreLauncherRouteNameFor(screen)),
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    opaque: true,
  );
}

void openScreenWithClearPreviousHandoff(BuildContext context, Widget screen) {
  Navigator.of(
    context,
  ).pushAndRemoveUntil(buildNavyHandoffRoute(screen), (route) => false);
}

void openBottomModalSheet(BuildContext context, Widget screen) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
    ),
    builder: (BuildContext context) {
      return screen;
    },
  );
}

Future openScreenWithResult(BuildContext context, Widget screen) async {
  return Navigator.push(context, _buildSmoothRoute(screen));
}

BoxDecoration getStatusBorder(Color color, {bool? isLeft}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadiusDirectional.only(
      topStart: (isLeft ?? false) ? zeroRadius : topLeftRadiusStatus,
      bottomStart: (isLeft ?? false) ? zeroRadius : bottomLeftRadiusStatus,
      topEnd: (isLeft ?? true) ? topRightRadiusStatus : zeroRadius,
      bottomEnd: (isLeft ?? true) ? bottomRightRadiusStatus : zeroRadius,
    ),
  );
}

/// Ærend toast kinds (`.ae-toast--*`).
enum AeToastKind { info, success, error, heart }

/// `.ae-toast` — midnight pill, icon circle, centred above the nav.
/// `.ae-toast` — pill, icon circle, centred above the nav. Uses the coral
/// `.reen-pre` remap of `--ae-shiny-purple` / `--ae-midnight`.
openSimpleSnackbar(
  String title, {
  duration = 3,
  void Function()? onPressed,
  AeToastKind kind = AeToastKind.info,
}) {
  if (rootScaffoldMessengerKey.currentState != null) {
    final Gradient? gradient = switch (kind) {
      AeToastKind.success => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1F8A5B), Color(0xFF12734A)],
      ),
      AeToastKind.error => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD9534F), Color(0xFFB83B37)],
      ),
      AeToastKind.heart => AerendBergenAuthTokens.shinyOrange,
      AeToastKind.info => AerendBergenAuthTokens.shinyOrange,
    };
    final IconData icon = switch (kind) {
      AeToastKind.success => Icons.check_rounded,
      AeToastKind.error => Icons.warning_amber_rounded,
      AeToastKind.heart => Icons.favorite_rounded,
      AeToastKind.info => Icons.info_outline_rounded,
    };

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(13, 11, 17, 11),
                  decoration: BoxDecoration(
                    color: gradient == null ? const Color(0xFF2D1B5B) : null,
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x99C94F41),
                        blurRadius: 34,
                        offset: const Offset(0, 14),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: kind == AeToastKind.info ? 0.16 : 0.22,
                          ),
                        ),
                        child: Icon(icon, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 13.5 * -0.01,
                            color: colorWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
        elevation: 0,
      ),
    );
  }
}

getAddressTypeInString(BuildContext context, String? type) {
  switch (type) {
    case home:
      return languages.home;
    case work:
      return languages.work;
    case other:
      return languages.other;
    default:
      return languages.home;
  }
}

getPaymentType(BuildContext context, int paymentType) {
  switch (paymentType) {
    case paymentTypeCash:
      return languages.cash;
    case paymentTypeCard:
      return languages.card;
    case paymentTypeWallet:
      return languages.wallet;
    default:
      return languages.cash;
  }
}

getAddressTypeInInt(String type) {
  switch (type) {
    case home:
      return 0;
    case work:
      return 1;
    case other:
      return 2;
    default:
      return 0;
  }
}

getAddressTypeIntToString(int type) {
  switch (type) {
    case 0:
      return home.toLowerCase();
    case 1:
      return work.toLowerCase();
    case 2:
      return other.toLowerCase();
    default:
      return home.toLowerCase();
  }
}

Future<TimeOfDay?> selectTime(BuildContext context) {
  final now = DateTime.now().add(const Duration(minutes: 61));

  return showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    builder: (BuildContext? context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor: colorPrimary,
          colorScheme: const ColorScheme.light(
            primary: colorPrimary,
            secondary: colorPrimary,
          ),
          buttonTheme: const ButtonThemeData(
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        child: child!,
      );
    },
  );
}

Future<DateTime?> selectDate(
  BuildContext context,
  int startSecond,
  int lastDay,
) => showDatePicker(
  context: context,
  initialDate: DateTime.now().add(Duration(hours: 1, seconds: startSecond)),
  firstDate: DateTime.now().add(const Duration(hours: 1)),
  lastDate: DateTime.now().add(Duration(hours: 1, days: lastDay)),
  builder: (BuildContext? context, Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: colorPrimary,
        colorScheme: const ColorScheme.light(
          primary: colorPrimary,
          secondary: colorPrimary,
        ),
        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
      ),
      child: child!,
    );
  },
);

int _normalizeApiStatus(int? status) {
  if (status == null) return 0;
  return status;
}

Future<bool> hasNetworkConnection() async {
  final dynamic result = await Connectivity().checkConnectivity();
  if (result is List<ConnectivityResult>) {
    return result.isNotEmpty &&
        result.any((item) => item != ConnectivityResult.none);
  }
  return result != ConnectivityResult.none;
}

/// Set when a login/session is freshly established. Used to ignore stale
/// in-flight API responses that would otherwise wipe a brand-new token.
DateTime? _sessionEstablishedAt;

void markSessionEstablished() {
  _sessionEstablishedAt = DateTime.now();
}

bool _isWithinFreshSessionGrace({
  Duration grace = const Duration(seconds: 20),
}) {
  final at = _sessionEstablishedAt;
  if (at == null) return false;
  return DateTime.now().difference(at) < grace;
}

isApiStatus(
  BuildContext context,
  int? status,
  String? message,
  bool? isLogout, {
  bool showMess = true,
  int messageCode = 0,
  List<int> hideMessOnCodeList = const [],
}) {
  final int normalizedStatus = _normalizeApiStatus(status);
  if (normalizedStatus == 3) showMess = false;

  //API STATUS
  //0 = false
  //1 = true
  //2 = registration pending
  //3 = app user blocked
  //4 = app user access token not match
  //5 = app user not found

  switch (normalizedStatus) {
    case 0:
      showApiMessage(
        context,
        showMess,
        message!,
        messageCode,
        hideMessOnCodeList,
      );
      return false;
    case 1:
      return true;
    case 2:
      showApiMessage(
        context,
        showMess,
        message!,
        messageCode,
        hideMessOnCodeList,
      );
      openScreenWithResult(context, const OtpVerify());
      return false;
    case 3:
      showSimpleDialogWithMessAndLogout(context, message!);
      return false;
    case 4:
    case 5:
      // Stale requests from a previous session must not wipe a just-saved login.
      final bool suppressStaleLogout =
          isLogout == true && _isWithinFreshSessionGrace();
      showApiMessage(
        context,
        showMess && !suppressStaleLogout,
        message!,
        messageCode,
        hideMessOnCodeList,
      );
      if (isLogout == true && !suppressStaleLogout) {
        logout(context);
      }
      return false;
  }
  return false;
}

showApiMessage(
  BuildContext context,
  bool showMess,
  String message,
  int messageCode,
  List<int> hideMessOnCodeList,
) {
  if (showMess) {
    if (!(hideMessOnCodeList.isNotEmpty &&
        hideMessOnCodeList.contains(messageCode))) {
      openSimpleSnackbar(message);
    }
  }
}

// isApiStatus(BuildContext context, int status, String message, bool isLogout) {
//   //API STATUS
//   //0 = false
//   //1 = true
//   //2 = registration pending
//   //3 = app user blocked
//   //4 = app user access token not match
//   //5 = app user not found
//   switch (status) {
//     case 0:
//       return false;
//     case 1:
//       return true;
//     case 2:
//       openScreenWithResult(context, const OtpVerify());
//       return false;
//     case 3:
//       showSimpleDialogWithMessAndLogout(context, message);
//       return false;
//     case 4:
//     case 5:
//       if (isLogout) {
//         logout(context);
//       }
//       return false;
//   }
//   return false;
// }

showSimpleDialogWithMessAndLogout(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialogUtil(
        title: message,
        message: "",
        positiveButtonTxt: languages.ok,
        negativeButtonTxt: "",
        onPositivePress: () {
          logout(context);
          // openSimpleSnackbar( languages.logout);
          // Navigator.pop(context, true);
        },
        onNegativePress: () {
          Navigator.pop(context, true);
        },
      );
    },
  );
}

manageBackgroundRideRequestAccept(int rideId) async {
  RideDetailRepo rideDetailRepo = RideDetailRepo();
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult != ConnectivityResult.none) {
    try {
      var response = RideDetailPojo.fromJson(
        await rideDetailRepo.rideReceiptDetailApi(rideId),
      );
      if (response.status == 1 &&
          response.driverId != 0 &&
          response.rideStatus > 0) {
        int status = response.status;
        String message = getApiMsg(
          navigatorKey.currentContext!,
          response.messageCode,
          response.message,
        );
        if (isApiStatus(
          navigatorKey.currentContext!,
          status,
          message,
          true,
          showMess: false,
        )) {
          openScreenWithClearPrevious(
            navigatorKey.currentContext!,
            RideDetail(
              rideId: response.rideId,
              rideType: getServiceName(response.driverSelectedServiceCatId),
              isFromNotification: true,
              clearAllNotifications: true,
            ),
          );
        }
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }
}

String getServiceName(int serviceCatId) {
  if (serviceCatId == 1) {
    return languages.bikeRide;
  } else if (serviceCatId == 2) {
    return languages.taxiRide;
  } else if (serviceCatId == 4) {
    return languages.courierService;
  } else {
    return "";
  }
}

// manageBackgroundRentalRequestAccept({int? rideId, int? serviceCatId}) async {
//   RentalRideDetailRepo _rentalDetailRepo = RentalRideDetailRepo();
//   var connectivityResult = await (Connectivity().checkConnectivity());
//   if (connectivityResult != ConnectivityResult.none) {
//     try {
//       var response = RentalRideDetailPojo.fromJson(await _rentalDetailRepo.rentalRideDetailApi(rideId, serviceCatId));
//       if (response != null) {
//         if (response.status == 1 && response.driverName != null && response.driverName.isNotEmpty && response.rideStatus > 0) {
//           int status = response.status;
//           String message = getApiMsg(navigatorKey.currentContext, response.messageCode, response.message);
//           if (isApiStatus(navigatorKey.currentContext, status, message, true, showMess: false)) {
//             bloc.showDetail = true;
//             if (bloc.isOpenBottomSheet && Navigator.canPop(navigatorKey.currentContext)) {
//               bloc.isOpenBottomSheet = false;
//               Navigator.pop(navigatorKey.currentContext);
//             }
//             bloc.subject.sink.add(ApiResponse.completed(response));
//             bloc.changeBackHomeScreen(true);
//           }
//         }
//       }
//     } catch (e) {
//       logd(tag,e.toString());
//     }
//   }
// }

logout(BuildContext context) async {
  // Cover the whole teardown first. Dropping the club repaints every
  // club-themed surface with the purple Ærend defaults, and that repaint is on
  // screen for the length of the swap — a purple flash before the splash.
  showLogoutCurtain();
  try {
    clearFCMToken().then((value) {
      FirebaseAuth.instance.signOut();
    });
    StoreProvider.of<AppState>(context).dispatch(ClearCartItem());
    StoreProvider.of<AppState>(context).dispatch(ClearSelectedCoupons());
    prefClearWithRemainSomeData();
    // Zero-duration opaque swap onto the same navy surface the curtain paints —
    // a Cupertino slide would drag the purple repaint across the screen instead.
    openScreenWithClearPreviousHandoff(context, const Splash());
  } finally {
    hideLogoutCurtainAfterSwap();
  }
}

getApiMsg(BuildContext context, int? messageCode, String? defaultMsg) {
  return defaultMsg ?? "";
  // var msgKey = "api_msg_$messageCode";
  // if (languages.apiMsg.containsKey(msgKey)) {
  //   return languages.apiMsg[msgKey];
  // } else {
  //   return defaultMsg ?? "";
  // }
}

bool hasValidAuthSession() {
  return prefGetInt(prefUserId) != 0 &&
      prefGetString(prefAccessToken).trim().isNotEmpty;
}

isLoggedIn() {
  if (hasValidAuthSession() && prefGetInt(prefUserVerified) == 1) {
    return true;
  }
  return false;
}

isUserLoginFromSocial() {
  if (prefGetString(prefLoginType) == loginTypeEmail) {
    return false;
  }
  return true;
}

isEmailOrNumNull() {
  if (prefGetString(prefEmail).trim().isEmpty ||
      prefGetString(prefContactNumber).trim().isEmpty) {
    return true;
  }
  return false;
}

isUserVerified() {
  if (prefGetInt(prefUserVerified) == 1) {
    return true;
  }
  return false;
}

Future<void> manageLoginResponse(
  BuildContext context,
  LoginPojo response, {
  bool popOnSuccess = false,
}) async {
  String message = getApiMsg(context, response.messageCode, response.message);
  if (!isApiStatus(context, response.status, message, false)) {
    return;
  }

  await setDataInPref(response);
  markSessionEstablished();

  if (!context.mounted) return;

  if (prefGetInt(prefUserId) == 0 ||
      prefGetString(prefAccessToken).trim().isEmpty) {
    openSimpleSnackbar(
      response.message.isNotEmpty
          ? response.message
          : 'Login failed to save session. Please try again.',
    );
    return;
  }

  // if (isEmailOrNumNull()) {
  //   openScreenWithClearPrevious(context, RequiredInformation());
  // } else {
  if (response.userVerified == 1) {
    if (popOnSuccess && Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      openScreenWithClearPrevious(
        context,
        const HomeMainV1(isShowDialog: true),
      );
    }
  } else {
    if (popOnSuccess) {
      await prefSetBool(prefAuthReturnOnSuccess, true);
    }
    if (!context.mounted) return;
    final verified = await openScreenWithResult(context, const OtpVerify());
    if (popOnSuccess &&
        verified == true &&
        context.mounted &&
        Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }
  // }
}

showSimpleDialog(
  BuildContext context,
  String title,
  String message, {
  String? posBtnName,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialogUtil(
        title: title,
        message: message,
        positiveButtonTxt: languages.ok,
        negativeButtonTxt: "",
        onPositivePress: () {
          Navigator.pop(context, true);
        },
        onNegativePress: () {
          Navigator.pop(context, true);
        },
      );
    },
  );
}

Future<void> setDataInPref(LoginPojo body) async {
  await prefSetBool(prefIsGuestMode, false);
  await prefSetInt(prefUserId, body.userId);
  await prefSetString(prefAccessToken, body.accessToken.trim());
  await prefSetString(prefUserName, body.userName);
  await prefSetString(prefEmail, body.email);
  await prefSetString(prefLoginType, body.loginType);
  await prefSetString(prefProfileImage, body.profileImage);
  await prefSetString(prefContactNumber, body.contactNumber);
  await prefSetString(prefReferralCode, body.referralCode);
  if (body.selectCountryCode.trim().isNotEmpty) {
    await prefSetString(prefCountryCode, body.selectCountryCode);
  }
  await prefSetString(prefSelectedCurrency, body.selectCurrency);
  await prefSetString(prefSelectedLanguageCode, body.selectLanguage);
  await prefSetString(prefServerTimeZone, body.serverTimeZone);
  await prefSetInt(prefUserVerified, body.userVerified);
  final num creditValue = body.credit is num
      ? body.credit as num
      : num.tryParse('$body.credit') ?? 0;
  final double roundedValue = (creditValue * 100).round() / 100;
  await prefSetString(prefAerendCredit, roundedValue.toStringAsFixed(2));
  await prefSetString(prefEmergencyContact, body.emergencyContact);
}

setKeyValuePair(
  List<KeyValueModel> keyValuesList,
  bool setDivider,
  bool setBold,
  String key,
  String? value, {
  Function()? setButton,
  bool setValueWithCurrency = true,
}) {
  if (value != null && value.isNotEmpty) {
    if (double.tryParse(value) != null) {
      if (double.parse(value) > 0) {
        if (setValueWithCurrency) {
          keyValuesList.add(
            KeyValueModel(
              setDivider,
              setBold,
              key,
              getAmountWithCurrency(double.parse(value)),
              setButton: setButton,
            ),
          );
        } else {
          keyValuesList.add(
            KeyValueModel(
              setDivider,
              setBold,
              key,
              value,
              setButton: setButton,
            ),
          );
        }
      }
    } else {
      keyValuesList.add(
        KeyValueModel(setDivider, setBold, key, value, setButton: setButton),
      );
    }
  }
}

BoxDecoration getBoxDecoration({
  Color color = Colors.white,
  double radius = 0.0,
  BoxBorder? border,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    color: color,
    border: border,
  );
}

String convertFullDateTimeToTime(String fullDateTime) {
  try {
    return DateFormat("h:mm a", selectedLocale.languageCode).format(
      DateFormat(
        "yyyy-MM-dd HH:mm:ss",
        selectedLocale.languageCode,
      ).parse(fullDateTime),
    );
  } on Exception {
    return "";
  }
}

bool isRtl() {
  if (selectedLocale.languageCode == 'ar' ||
      selectedLocale.languageCode == 'fa' ||
      selectedLocale.languageCode == 'he' ||
      selectedLocale.languageCode == 'ps' ||
      selectedLocale.languageCode == 'ur') {
    return true;
  }
  return false;
}

String getCurrentTime() {
  return DateFormat(
    "yyyy-MM-dd HH:mm:ss",
    selectedLocale.languageCode,
  ).format(DateTime.now());
}

String getCurrentTimeEnglish() {
  return DateFormat("yyyy-MM-dd HH:mm:ss", 'en').format(DateTime.now().toUtc());
}

setFCMToken() {
  String userId = ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
  logd(tag, '===userId: $userId');
  DatabaseReference refFcmToken = FirebaseDatabase.instance
      .ref()
      .child(ChatConstant.chat)
      .child(ChatConstant.fcmToken)
      .child(userId);
  var map = <String, String>{};
  map[ChatConstant.newUserFcmToken] = prefGetString(prefDeviceToken);
  refFcmToken.set(map);
}

Future<void> clearFCMToken() async {
  String userId = ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
  DatabaseReference refFcmToken = FirebaseDatabase.instance
      .ref()
      .child(ChatConstant.chat)
      .child(ChatConstant.fcmToken)
      .child(userId);
  var map = <String, String>{};
  map[ChatConstant.newUserFcmToken] = "";
  await refFcmToken.set(map);
}

/// Writes [token] to `hareshop-no/fcmToken/<peerChatId>/fcm_token` so chat FCM
/// can reach that peer. [peerChatId] is `u_<userId>`, `p_<providerId>`, etc.
Future<void> syncChatPeerFcmTokenToRtdb(String peerChatId, String token) async {
  final String t = token.trim();
  if (peerChatId.isEmpty || t.isEmpty) return;
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await FirebaseDatabase.instance
        .ref()
        .child(ChatConstant.chat)
        .child(ChatConstant.fcmToken)
        .child(peerChatId)
        .set({ChatConstant.newUserFcmToken: t});
    logd(tag, 'syncChatPeerFcmTokenToRtdb ok $peerChatId');
  } catch (e) {
    logd(tag, 'syncChatPeerFcmTokenToRtdb failed: $e');
  }
}

double getDoubleFromDynamic(dynamic value) {
  return double.parse(value.toString());
}

bool checkStoreMinAmount(BuildContext context, {dynamic storeMinAmountApi}) {
  double productTotalAmount = 0, storeMinAmount = 0;
  for (var element in store.state.cartItemState.cartItemsList) {
    productTotalAmount =
        productTotalAmount + (element.prodTotalAmount * element.prodQuantity);
  }
  if (storeMinAmountApi == null) {
    String selectedStoreDetails = prefGetString(prefSelectedStoreFullResponse);
    if (selectedStoreDetails.trim().isNotEmpty) {
      StoreDetailsPojo selectedStoreDetailsPojo = StoreDetailsPojo.fromJson(
        jsonDecode(prefGetString(prefSelectedStoreFullResponse)),
      );
      storeMinAmount = getDoubleFromDynamic(
        selectedStoreDetailsPojo.orderMinAmount,
      );
    }
  } else {
    storeMinAmount = getDoubleFromDynamic(storeMinAmountApi);
  }
  if (productTotalAmount >= storeMinAmount) {
    return true;
  } else {
    openSimpleSnackbar(
      "${languages.minimumOrderMsg} ${getAmountWithCurrency(storeMinAmount)}",
    );
    return false;
  }
}

bool checkStoreClose(
  BuildContext context,
  bool isScheduleOrder,
  dynamic storeStatus,
) {
  if (!isScheduleOrder) {
    if (storeStatus == null) {
      String selectedStoreDetails = prefGetString(
        prefSelectedStoreFullResponse,
      );
      if (selectedStoreDetails.trim().isNotEmpty) {
        StoreDetailsPojo selectedStoreDetailsPojo = StoreDetailsPojo.fromJson(
          jsonDecode(prefGetString(prefSelectedStoreFullResponse)),
        );
        if ((selectedStoreDetailsPojo.storeStatus) == 1) {
          return true;
        } else {
          openSimpleSnackbar(languages.closeStore);
          return false;
        }
      }
    } else {
      if (storeStatus == 1) {
        return true;
      } else {
        openSimpleSnackbar(languages.closeStore);
        return false;
      }
    }
    return false;
  } else {
    return true;
  }
}

String getDateTime(
  String ourDate, {
  String returnFormat = "yyyy-MM-dd hh:mm aa",
  String format = "yyyy-MM-dd HH:mm:ss",
  bool useLocalTime = false,
}) {
  String serverTimeZone = prefGetString(prefServerTimeZone);
  bool isUtc = (serverTimeZone.toUpperCase() == "UTC");
  var parse = DateFormat(format).parse(ourDate, isUtc);

  var detroit = useLocalTime
      ? tz.getLocation(localTimeZone)
      : isUtc
      ? tz.UTC
      : tz.getLocation(serverTimeZone);
  var now = tz.TZDateTime(
    detroit,
    parse.year,
    parse.month,
    parse.day,
    parse.hour,
    parse.minute,
    parse.second,
  );
  var convertedDate = tz.TZDateTime.from(now, tz.getLocation(localTimeZone));

  var formatDate = DateFormat(
    returnFormat,
    selectedLocale.languageCode,
  ).format(convertedDate);
  return formatDate;
}

DateTime getTimeAndDateObj(String ourDate) {
  String serverTimeZone = prefGetStringWithDefaultValue(
    prefServerTimeZone,
    "UTC",
  );
  bool isUtc = (serverTimeZone.toUpperCase() == "UTC");
  var parse = DateFormat("yyyy-MM-dd HH:mm:ss").parse(ourDate, isUtc);

  var detroit = isUtc ? tz.UTC : tz.getLocation(serverTimeZone);
  var now = tz.TZDateTime(
    detroit,
    parse.year,
    parse.month,
    parse.day,
    parse.hour,
    parse.minute,
    parse.second,
  );
  var convertedDate = tz.TZDateTime.from(now, tz.getLocation(localTimeZone));
  return convertedDate;
}

convertTimeToServerTime(DateTime dateTime) {
  String serverTimeZone = prefGetString(prefServerTimeZone);
  bool isUtc = (serverTimeZone.toUpperCase() == "UTC");
  final detroitTime = isUtc
      ? dateTime.toUtc()
      : TZDateTime.from(dateTime, getLocation(serverTimeZone));
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(detroitTime);
}

Future<BitmapDescriptor> getBitmapDescriptorFromAssetBytes(
  String path,
  int width,
) async {
  final Uint8List? imageData = await getBytesFromAsset(path, width);
  return BitmapDescriptor.fromBytes(imageData!);
}

Future<Uint8List?> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: width,
  );
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(
    format: ui.ImageByteFormat.png,
  ))?.buffer.asUint8List();
}

void setMapFitToTour(
  Set<Polyline> p,
  GoogleMapController? controller, {
  double? padding,
}) {
  double minLat = p.first.points.first.latitude;
  double minLong = p.first.points.first.longitude;
  double maxLat = p.first.points.first.latitude;
  double maxLong = p.first.points.first.longitude;
  for (var poly in p) {
    for (var point in poly.points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLong) minLong = point.longitude;
      if (point.longitude > maxLong) maxLong = point.longitude;
    }
  }
  controller?.moveCamera(
    CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLong),
        northeast: LatLng(maxLat, maxLong),
      ),
      padding ?? deviceAverageSize * 0.02,
    ),
  );
}

Future<void> zoomToFit(
  GoogleMapController? controller,
  LatLngBounds bounds,
  LatLng centerBounds,
) async {
  if (controller == null) return;
  const int maxIterations = 24;
  try {
    bool keepZoomingOut = true;
    double zoomLevel = (await controller.getZoomLevel()) - 0.5;
    int iteration = 0;
    while (keepZoomingOut && iteration < maxIterations) {
      iteration++;
      final LatLngBounds screenBounds = await controller.getVisibleRegion();
      if (fits(bounds, screenBounds)) {
        keepZoomingOut = false;
        await controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: centerBounds,
              zoom: zoomLevel <= 10 ? defaultMapZoom - 0.5 : zoomLevel,
            ),
          ),
        );
        break;
      } else {
        await controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: centerBounds, zoom: zoomLevel),
          ),
        );
        zoomLevel -= 0.5;
        if (zoomLevel < 2) break;
      }
    }
  } on PlatformException catch (e, st) {
    // Android platform view not ready or already disposed (pigeon channel-error).
    debugPrint('zoomToFit: $e\n$st');
  }
}

bool fits(LatLngBounds fitBounds, LatLngBounds screenBounds) {
  final bool northEastLatitudeCheck =
      screenBounds.northeast.latitude >= fitBounds.northeast.latitude;
  final bool northEastLongitudeCheck =
      screenBounds.northeast.longitude >= fitBounds.northeast.longitude;

  final bool southWestLatitudeCheck =
      screenBounds.southwest.latitude <= fitBounds.southwest.latitude;
  final bool southWestLongitudeCheck =
      screenBounds.southwest.longitude <= fitBounds.southwest.longitude;

  return northEastLatitudeCheck &&
      northEastLongitudeCheck &&
      southWestLatitudeCheck &&
      southWestLongitudeCheck;
}

extension MapWithIndex<T> on List<T> {
  List<R> mapWithIndex<R>(R Function(T, int i) callback) {
    List<R> result = [];
    for (int i = 0; i < length; i++) {
      R item = callback(this[i], i);
      result.add(item);
    }
    return result;
  }
}

openServices(BuildContext context, int serviceCategoryId) {
  // if (serviceCategoryId == 4) {
  //   openScreen(context, const CourierBooking());
  // } else {
  openScreen(context, const DSHome());
  // }
}

setSelectedServiceInPref(int catId, String catName, String catIcon) {
  prefSetInt(prefSelectedServiceCateId, catId);
  prefSetString(prefSelectedServiceCateName, catName);
  prefSetString(prefSelectedServiceCateIcon, catIcon);
}

bool isDirectionRTL(BuildContext context) {
  return Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
}

Size textSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textScaleFactor: 1,
    textDirection: ui.TextDirection.ltr,
  )..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

double calculateAutoscaleFontSize(
  String text,
  TextStyle style,
  double maxWidth,
) {
  final textPainter = TextPainter(textDirection: ui.TextDirection.rtl);

  var currentFontSize = style.fontSize;

  for (var i = 0; i < 500; i++) {
    // limit max iterations to 100
    final nextFontSize = currentFontSize! + 1;
    final nextTextStyle = style.copyWith(fontSize: nextFontSize);
    textPainter.text = TextSpan(text: text, style: nextTextStyle);
    textPainter.layout();
    if (textPainter.width >= maxWidth) {
      break;
    } else {
      currentFontSize = nextFontSize;
      // continue iteration
    }
  }

  return currentFontSize!;
}

bool getTwoDigitRegExp(String value) {
  return RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value);
}

getValueFromStream(List<BehaviorSubject<String>> listValue) {
  bool isValid = true;
  for (var element in listValue) {
    if ((element.value).isEmpty) {
      if (!element.hasError) {
        element.sink.add("");
        if (isValid) {
          isValid = false;
        }
      }
    }
  }
  return isValid;
}

// getTimeAndDate(String date, {String format = "EEE, MMM d, yyyy"}) {
//   try {
//     var parse = DateTime.parse(date);
//     var formatDate = DateFormat(format, selectedLocale.languageCode).format(parse);
//     return formatDate;
//   } catch (e) {
//     return date;
//   }
// }

getChatDateTime(String ourDate, {String format = "yyyy-MM-dd hh:mm"}) {
  var parse = DateFormat("yyyy-MM-dd HH:mm:ss").parse(ourDate, true).toLocal();
  var formatDate = DateFormat(
    format,
    selectedLocale.languageCode,
  ).format(parse);
  return formatDate;
}

// Future<Position> determinePosition() async {
//   bool serviceEnabled;
//   LocationPermission permission;
//
//   // Test if location services are enabled.
//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   logd(tag,"service:$serviceEnabled");
//   if (!serviceEnabled) {
//     await Geolocator.openLocationSettings();
//   }
//
//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       // Permissions are denied, next time you could try
//       // requesting permissions again (this is also where
//       // Android's shouldShowRequestPermissionRationale
//       // returned true. According to Android guidelines
//       // your App should show an explanatory UI now.
//       return Future.error('Location permissions are denied');
//     }
//   }
//
//   if (permission == LocationPermission.deniedForever) {
//     // Permissions are denied forever, handle appropriately.
//     return Future.error('Location permissions are permanently denied, we cannot request permissions.');
//   }
//
//   // When we reach here, permissions are granted and we can
//   // continue accessing the position of the device.
//   logd(tag,"getcurrentlocation permission Granted");
//   return await Geolocator.getCurrentPosition(forceAndroidLocationManager: true).then((value){
//     logd(tag,"getcurrentlocation successful");
//   }).catchError((e){
//     logd(tag,"getcurrentlocation error ${e.toString()}");
//   });
// }
//
// Stream<Position> determinePositionStream() {
//   LocationSettings locationSettings;
//
//   if (defaultTargetPlatform == TargetPlatform.android) {
//     locationSettings = AndroidSettings(
//       accuracy: LocationAccuracy.high,
//       forceLocationManager: true,
//       intervalDuration: const Duration(seconds: 10),
//     );
//   } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
//     locationSettings = AppleSettings(
//       accuracy: LocationAccuracy.high,
//       pauseLocationUpdatesAutomatically: true,
//     );
//   } else {
//     locationSettings = LocationSettings(
//       accuracy: LocationAccuracy.high,
//       distanceFilter: 30,
//     );
//   }
//
//   return Geolocator.getPositionStream(locationSettings: locationSettings);
// }

String getArrivedImage() {
  return "assets/images/dialog_courier_delivery_person_arrived_img.webp";
}

String getArrivedTitleMsg({bool? isTitle}) {
  return isTitle!
      ? languages.courierDriverArrived
      : languages.courierDriverArrivedMsg(languages.appName);
}

String getCancelTitleMsg({bool? isTitle}) {
  return isTitle! ? languages.cancelRide : languages.cancelRideMsg;
}

String getRideStartedImg() {
  return "assets/images/dialog_courier_started_img.webp";
}

String getRideStartedTitleMsg({bool? isTitle}) {
  return isTitle!
      ? languages.courierDeliveryStarted
      : languages.courierDeliveryStartedMsg(languages.appName);
}

String getRideFinish() {
  return "assets/images/dialog_courier_delivery_successful_finished_img.png";
}

String getRideFinishTitleMsg({bool? isTitle}) {
  return isTitle!
      ? languages.courierDeliveryFinish
      : languages.courierDeliveryFinishMsg(languages.appName);
}

String getRideSuccessFinish() {
  return "assets/images/dialog_courier_delivery_successful_finished_img.png";
}

String getRideSuccessTitleMsg({bool? isTitle}) {
  return isTitle!
      ? languages.courierRideSuccessfullyFinished
      : languages.courierRideSuccessfullyFinishedMsg;
}

TextStyle bodyText({
  FontWeight? fontWeight,
  double? fontSize,
  Color? textColor,
}) {
  return commonTextStyle(
    fontWeight: fontWeight,
    fontSize: fontSize,
    textColor: textColor,
  );
}

TextStyle headerText({
  FontWeight? fontWeight,
  double? fontSize,
  Color? textColor,
}) {
  return commonTextStyle(
    fontWeight: fontWeight ?? FontWeight.w600,
    fontSize: fontSize ?? textSizeBig,
    textColor: textColor,
  );
}

TextStyle toolbarStyle({
  FontWeight? fontWeight,
  double? fontSize,
  Color? textColor,
}) {
  return commonTextStyle(
    fontWeight: fontWeight ?? FontWeight.w600,
    fontSize: fontSize ?? textSizeLarge,
    textColor: textColor,
  );
}

TextStyle commonTextStyle({
  FontWeight? fontWeight,
  double? fontSize,
  Color? textColor,
}) {
  // Fixed px per the Ærend design; values < 1 are legacy screen-fractions.
  final size = fontSize ?? textSizeRegular;
  return GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      color: textColor ?? colorTextCommon,
      fontSize: size < 1 ? deviceAverageSize * size : size,
      decoration: TextDecoration.none,
    ),
    fontWeight: fontWeight ?? FontWeight.normal,
  );
}

Color lighten(Color c, [int percent = 30]) {
  assert(1 <= percent && percent <= 100);
  var p = percent / 100;
  return Color.fromARGB(
    c.alpha,
    c.red + ((255 - c.red) * p).round(),
    c.green + ((255 - c.green) * p).round(),
    c.blue + ((255 - c.blue) * p).round(),
  );
}

setCatDetailIntoPref(int catId, String catName, String catIcon) {
  prefSetInt(prefSelectedServiceCateId, catId);
  prefSetString(prefSelectedServiceCateName, catName);
  prefSetString(prefSelectedServiceCateIcon, catIcon);
}

setChangedLanguage(
  BuildContext context,
  String languageCode,
  State state, {
  Function()? nextAction,
}) {
  changeLanguage(context, languageCode, state).then((value) {
    selectedLocale = getLocale();
    AppLocalizations.delegate.load(selectedLocale).then((value) {
      languages = value;
      if (nextAction != null) nextAction();
    });
  });
}

Future<void> firebaseAuth() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String email = prefGetString(prefEmail).trim().isNotEmpty
      ? prefGetString(prefEmail)
      : "dummy@gmail.com";
  if (currentUser == null) {
    try {
      UserCredential result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(password: "123456", email: "u_$email");
      final User? user = result.user;
      if (user == null) {
        await firebaseAuthWithEmail(email);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        logd(tag, 'No user found for that email.');
        await firebaseAuthWithEmail(email);
      } else if (e.code == 'wrong-password') {
        logd(tag, 'Wrong password provided for that user.');
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }
}

Future<void> firebaseAuthWithEmail(String email) async {
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        password: "123456",
        email: "u_$email",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        logd(tag, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        logd(tag, 'The account already exists for that email.');
        await firebaseAuth();
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }
}

String timeAgo(DateTime d) {
  Duration diff = DateTime.now().difference(d);
  if (diff.inDays > 365) {
    return "${(diff.inDays / 365).floor()} ${(diff.inDays / 365).floor() == 1 ? languages.year : languages.years} ${languages.ago}";
  }
  if (diff.inDays > 30) {
    return "${(diff.inDays / 30).floor()} ${(diff.inDays / 30).floor() == 1 ? languages.month : languages.months} ${languages.ago}";
  }
  if (diff.inDays > 7) {
    return "${(diff.inDays / 7).floor()} ${(diff.inDays / 7).floor() == 1 ? languages.week : languages.weeks} ${languages.ago}";
  }
  if (diff.inDays > 0) {
    return "${diff.inDays} ${diff.inDays == 1 ? languages.day : languages.days} ${languages.ago}";
  }
  if (diff.inHours > 0) {
    return "${diff.inHours} ${diff.inHours == 1 ? languages.hour : languages.hours} ${languages.ago}";
  }
  if (diff.inMinutes > 0) {
    return "${diff.inMinutes} ${diff.inMinutes == 1 ? languages.minute : languages.minutes} ${languages.ago}";
  }
  if (diff.inSeconds >= 3) {
    return '${diff.inSeconds} ${languages.seconds} ${languages.ago}';
  }
  return languages.justNow;
}

logd(String tag, String message) {
  debugPrint("$tag $message");
}

initConfig() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  pushNotificationService = PushNotificationService();
  // Foreground listeners are registered from main() via
  // pushNotificationService.handleNotification() — do not attach here or you
  // will duplicate onMessage handlers.
  await pushNotificationService.initialise();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    badge: true,
    alert: true,
    sound: true,
  );
  return true;
}

String getChatWithDefaultProfile(int userType) {
  switch (userType) {
    case chatWithTypeStore:
      return "assets/images/avatar_store.png";
    case chatWithTypeDriver:
      return "assets/images/avatar_driver.png";
    case chatWithTypeUser:
      return "assets/images/avatar_user.png";
    default:
      return "assets/images/avatar_admin.png";
  }
}

String getChatWithService(int userType) {
  switch (userType) {
    case chatWithTypeStore:
      return languages.store;
    case chatWithTypeDriver:
      return languages.driver;
    default:
      return "";
  }
}

int getAddOnsType({int? categoryId}) {
  categoryId = categoryId ?? prefGetInt(prefSelectedServiceCateId);
  switch (categoryId) {
    case 2:
    case 5:
      return typeToppingOption;
    default:
      return typeSizeColor;
  }
}

String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
