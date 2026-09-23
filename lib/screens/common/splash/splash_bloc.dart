import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intercom_flutter/intercom_flutter.dart';

import '../../../blocs/bloc.dart';
import '../../../dialogs/simple_dialog_util.dart';
import '../../../utils/utils.dart';
import '../homeMainV1/home_main_v1.dart';
import '../login/login.dart';
// Language/currency pre-login screen skipped — NOK is the only currency;
// language is chosen via the NO/EN toggle on Login.
// import '../selectLanguageAndCurrency/select_language_and_currency.dart';
import 'splash.dart';
import 'splash_dl.dart';
import 'splash_repo.dart';

class SplashBloc extends Bloc {
  String tag = "SplashBloc>>>";
  BuildContext context;

  State<Splash> state;

  final SplashRepo _splashRepo = SplashRepo();

  SplashBloc(this.context, this.state) {
    checkAppVersionApi();
  }

  final _subject = BehaviorSubject<ApiResponse<AppVersionCheckPojo>>();

  BehaviorSubject<ApiResponse<AppVersionCheckPojo>> get subject => _subject;

  /// Set once the first route replacement is issued, so two resolved routes
  /// (e.g. the version API landing right as the animation completes) can
  /// never both push.
  bool _navigated = false;

  /// True once [skipSplashDelay] has been called — the splash animation has
  /// played out (or the user tapped past it), so it is fine to leave now.
  ///
  /// Every destination in this bloc is decided by fast local/network work
  /// that can resolve in a few milliseconds (a cached login check, or an
  /// immediate `splashAction()` when there's no connectivity). Without this
  /// gate, `_openScreen` would fire the instant a destination is known and
  /// the splash's Æ-mark animation would never get to play — it would read
  /// as the splash being skipped entirely, not merely fast.
  bool _readyToLeave = false;

  /// Destination decided before [_readyToLeave] was set — leaves as soon as
  /// [skipSplashDelay] is called.
  Widget? _pendingScreen;
  bool _pendingHandoff = false;

  /// Every route change on this screen goes through here. Holds until the
  /// splash animation says it is done, i.e. matches `Splash.jsx`'s `onDone`.
  void _openScreen(Widget screen, {bool handoff = false}) {
    if (_navigated || !state.mounted) return;
    if (!_readyToLeave) {
      _pendingScreen = screen;
      _pendingHandoff = handoff;
      return;
    }
    _navigated = true;
    _pendingScreen = null;
    _pendingHandoff = false;
    if (handoff) {
      openScreenWithClearPreviousHandoff(context, screen);
    } else {
      openScreenWithClearPrevious(context, screen);
    }
  }

  /// Called once — when the splash animation reaches its exit, when the user
  /// taps to skip, or (reduced motion) after the shortened hold. Releases
  /// whatever destination is already known; a still-pending version check
  /// still gets to finish and show its forced-update gate before leaving.
  void skipSplashDelay() {
    _readyToLeave = true;
    final Widget? pending = _pendingScreen;
    final handoff = _pendingHandoff;
    if (pending != null) {
      _pendingScreen = null;
      _pendingHandoff = false;
      _openScreen(pending, handoff: handoff);
    }
  }

  void _openHome({required bool isShowDialog}) {
    _openScreen(HomeMainV1(isShowDialog: isShowDialog));
  }

  splashAction() {
    FirebaseMessaging.instance.getToken().then((token) async {
      if (token == null || token.isEmpty) return;
      prefSetString(prefDeviceToken, token);
      logd(tag, "Token : $token");
      try {
        await Intercom.instance.sendTokenToIntercom(token);
      } catch (e) {
        // Intercom identity verification is often unset in local/dev builds.
        logd(tag, "Intercom sendTokenToIntercom skipped: $e");
      }
    });

    // Cold-start flow: Splash → Login (landing) → Vilkår → Konto / provider
    // → Telefon → Kode → Ferdig → Home.
    if (isLoggedIn()) {
      prefSetBool(prefIsGuestMode, false);
      callRunningServiceApi();
    } else {
      prefSetBool(prefIsGuestMode, false);
      _openScreen(const Login(), handoff: true);
    }
  }

  checkAppVersionApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none) == false) {
      _subject.sink.add(ApiResponse.loading());
      try {
        // Add timeout to prevent hanging
        var response = AppVersionCheckPojo.fromJson(
          await _splashRepo.appVersionCheckApi().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('API call timed out');
            },
          ),
        );

        if (!state.mounted) return;
        String message = getApiMsg(
          context,
          response.messageCode,
          response.message,
        );
        if (isApiStatus(context, response.status, message, true)) {
          _subject.sink.add(ApiResponse.completed(response));
          openForceFullyUpdateDialog(
            response.appVersion,
            response.isForcefullyUpdate,
          );
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        // Instead of showing error, proceed with app flow on API failure
        print('API call failed, proceeding with app flow: $e');
        _subject.sink.add(ApiResponse.error(e.toString()));
        // Skip version check and proceed directly to splash action
        splashAction();
      }
    } else {
      if (!state.mounted) return;
      // Skip version check and proceed directly to splash action when no internet
      print('No internet connection, proceeding with app flow');
      splashAction();
    }
  }

  callRunningServiceApi() async {
    _openHome(isShowDialog: true);
    // var connectivityResult = await (Connectivity().checkConnectivity());
    // if (connectivityResult != ConnectivityResult.none) {
    //   try {
    //     var response = GetRunningServicePojo.fromJson(await _splashRepo.getRunningServiceApi());
    //     if (response != null) {
    //       manageRunningServiceResponse(response);
    //     }
    //   } catch (e) {
    //     openSimpleSnackbar(context!, e.toString());
    //   }
    // } else {
    //   openSimpleSnackbar(context!, languages.internetConnLostTitle);
    // }
  }

  manageRunningServiceResponse(GetRunningServicePojo response) {
    int status = response.status;
    if (status == 2) {
      _openScreen(const Login());
    } else if (status == 0) {
      _openScreen(const HomeMainV1(isShowDialog: true));
    } else {
      String message = getApiMsg(
        context,
        response.messageCode,
        response.message,
      );
      if (isApiStatus(context, status, message, true)) {
        // if (response.orderStatus >= 6) {
        //   openScreenWithClearPrevious(context!, RideInvoice(rideId: response.orderId, serviceCateId: response.serviceCatId));
        // } else {
        //   openScreenWithClearPrevious(context!,
        //       RunningRide(orderId: response.orderId, orderStatus: response.orderStatus, serviceCateId: response.serviceCatId));
        // }
      }
    }
  }

  openHomeOrLoginActivity() {
    if (isLoggedIn()) {
      _openScreen(const HomeMainV1(isShowDialog: true));
    } else {
      _openScreen(const Login(), handoff: true);
    }
  }

  openForceFullyUpdateDialog(String versionName, int forcefullyUpdate) async {
    String currentVersion = "0", packageName = "";
    if (!kIsWeb) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
      packageName = packageInfo.packageName;
    }
    logd(tag, "${currentVersion.compareTo(versionName)}");
    if (!state.mounted) return;
    if (currentVersion.compareTo(versionName) == -1 && forcefullyUpdate == 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleDialogUtil(
            title: languages.newUpdateAvailable,
            message: languages.newUpdateMsg,
            positiveButtonTxt: languages.update,
            onPositivePress: () {
              String url = "";
              if (Platform.isAndroid) {
                url =
                    "https://play.google.com/store/apps/details?id=$packageName";
              } else {
                url = "https://apps.apple.com/app/id$appleId";
              }
              openUrlInStore(url);
            },
            onNegativePress: () {
              Navigator.pop(context, true);
            },
          );
        },
      ).then((value) {
        openForceFullyUpdateDialog(versionName, forcefullyUpdate);
      });
    } else {
      splashAction();
    }
  }

  @override
  void dispose() {
    _subject.close();
  }
}
