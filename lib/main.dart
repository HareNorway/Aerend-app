import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'services/customer/client_flags.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:aerend_customer/utils/route_names.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/blocs/bloc.dart';
import 'package:aerend_customer/screens/common/account/redeem_code.dart';
import 'package:redux/redux.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:translator/translator.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';
import 'redux/store.dart';
import 'screens/common/auth/launch/launch_onboarding.dart' show lfSetInviterName;
import 'screens/common/login/login.dart';
import 'screens/common/splash/splash.dart';
import 'screens/common/vipps/vipps_login_link_handler.dart';
import 'screens/common/vipps/vipps_return_screens.dart';
import 'services/push_notification_service.dart';
import 'networking/feed/feed_api_constant.dart';
import 'utils/utils.dart';
import 'screens/bergen/bergen_routes_agil1.dart';
import 'screens/bergen/bergen_routes_agil3.dart';
import 'screens/bergen/kit/bergen_routes.dart';
import 'screens/bergen/meg/a3_services.dart';
import 'screens/bergen/kit/bergen_perf.dart';
import 'screens/bergen/kit/server_banner.dart';
import 'services/customer/beacons.dart';

//Created at 20/05/2021 11:30 AM

PushNotificationService pushNotificationService = PushNotificationService();
GetLocationUtils getLocationUtils = GetLocationUtils();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();
Locale selectedLocale = const Locale(defaultLanguage, '');
late String localTimeZone;
final translator = GoogleTranslator();
late AppLocalizations languages;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage notification,
) async {
  await initSharedPreferences();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  Map<String, dynamic> notificationData = notification.data;
  debugPrint("handleBackNotification message==> $notificationData");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Parity plan §3: the motion tier (device class, low power, heat).
  unawaited(BergenPerf.start());

  // Initialize Stripe
  Stripe.publishableKey = stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.com.reen.customer';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  // Initialize timezone
  try {
    localTimeZone = (await FlutterTimezone.getLocalTimezone()).toString();
  } catch (e) {
    localTimeZone = 'UTC'; // Fallback timezone
  }

  // Initialize shared preferences
  await initSharedPreferences();
  await BaseUrl.restoreOverride();
  await FeedBaseUrl.restoreOverride();
  print('Shared preferences initialized');

  // Check connectivity and initialize Firebase
  List<ConnectivityResult> connectivityResult = await (Connectivity()
      .checkConnectivity());
  if (!connectivityResult.contains(ConnectivityResult.none)) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await pushNotificationService.initialise();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    // Register once at startup (not from Widget.didChangeDependencies — that
    // would attach duplicate onMessage listeners every rebuild).
    await pushNotificationService.handleNotification();
  }

  // Initialize timezones
  tz.initializeTimeZones();

  // Initialize the Redux store
  await initStore();

  // Initialize Google Maps
  try {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = false;
      await mapsImplementation.initializeWithRenderer(
        AndroidMapRenderer.latest,
      );
    }
  } catch (e) {
    debugPrint('Google Maps initialization error: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Customer Step 11: the `cus.*` flags the app renders on (silent, the last answer stays offline).
  unawaited(ClientFlags.refresh());

  // Customer Step 16: the client beacons (technical events, no PII, signed
  // after login) and the per-version flags / banner / min_version.
  await _startBeacons();

  runApp(MyApp(store));
}

/// The app version the beacons and `agents/flags` carry.
String cusAppVersion = '0.0.0';

Future<void> _startBeacons() async {
  try {
    final info = await PackageInfo.fromPlatform();
    cusAppVersion = '${info.version}+${info.buildNumber}';
  } catch (_) {
    // The plugin is missing in a test host: the version stays 0.0.0.
  }
  final device = prefGetString(prefDeviceToken);
  final b = CusBeacons(
    transport: DioCusBeaconTransport(),
    version: cusAppVersion,
    platform: Platform.isAndroid ? 'android' : 'ios',
    locale: prefGetStringWithDefaultValue(prefSelectedLanguageCode, 'no'),
    device: device.isEmpty ? '' : CusBeacon.hash(device),
  );
  CusBeacons.current = b;
  b.start();
  unawaited(b.loadFlags());
  final prev = FlutterError.onError;
  FlutterError.onError = (details) {
    CusBeacons.uncaught(details.exception, details.stack);
    if (prev != null) {
      prev(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    CusBeacons.uncaught(error, stack);
    return false;
  };
}

class MyApp extends StatefulWidget {
  final Store<AppState> store;

  const MyApp(this.store, {super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    var state = context.findAncestorStateOfType<MyAppState>();
    state?.setLocale(newLocale);
  }

  static void setThemeMode(BuildContext context, ThemeMode themeMode) {
    MyAppState.setThemeMode(context, themeMode);
  }

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _resumedFromBackground = false;

  // Dark mode disabled until `ScSaasTheme.dark()` is finished — keep app light-only.
  // ThemeMode _themeMode = ThemeMode.system;

  //For Multi Language
  void setLocale(Locale locale) {
    setState(() {
      selectedLocale = locale;
    });
  }

  static void setThemeMode(BuildContext context, ThemeMode _) {
    // Dark/system appearance disabled for now.
    // var state = context.findAncestorStateOfType<MyAppState>();
    // state?._setThemeMode(themeMode);
  }

  // void _setThemeMode(ThemeMode themeMode) {
  //   setState(() {
  //     _themeMode = themeMode;
  //   });
  //   saveThemeMode(themeMode);
  // }

  @override
  void initState() {
    super.initState();
    ClientFlags.agents.addListener(_oppdaterSjekk);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VippsLoginLinkHandler.bootstrap();
    });
  }

  @override
  void dispose() {
    ClientFlags.agents.removeListener(_oppdaterSjekk);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(VippsLoginLinkHandler.dispose());
    super.dispose();
  }

  /// Customer Step 16: the `min_version` prompt when `agents/flags` says so.
  void _oppdaterSjekk() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    unawaited(CusOppdaterArk.visHvis(ctx, ClientFlags.agents.value, cusAppVersion));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _resumedFromBackground = true;
      // Customer Step 16: the beacons go out before the app sleeps.
      if (state == AppLifecycleState.paused) unawaited(CusBeacons.current?.flush() ?? Future.value());
    }
    if (state == AppLifecycleState.resumed && _resumedFromBackground) {
      _resumedFromBackground = false;
      // Customer Step 16: the flags, banner and min_version again on resume.
      unawaited(ClientFlags.refresh());
      unawaited(CusBeacons.current?.loadFlags() ?? Future.value());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resumePendingVippsLoginIfNeeded();
      });
    }
  }

  @override
  void didChangeDependencies() async {
    selectedLocale = getLocale();

    // Initialize languages
    if (AppLocalizations.of(context) != null) {
      languages = AppLocalizations.of(context)!;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StoreProvider<AppState>(
        store: widget.store,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          theme: ScSaasTheme.light(),
          // darkTheme: ScSaasTheme.dark(),
          themeMode: ThemeMode.light,
          builder: (context, child) {
            deviceWidth = MediaQuery.of(context).size.width;
            deviceHeight = MediaQuery.of(context).size.height;
            deviceAverageSize = (deviceWidth + deviceHeight) / 2;
            textScaleFactorOf = MediaQuery.textScaleFactorOf(context);
            if (AppLocalizations.of(context) != null) {
              languages = AppLocalizations.of(context)!;
            }

            // Pixel parity with the 375×812 design frame needs the OS text
            // setting bounded — but not disabled outright, which used to be
            // the case here (`TextScaler.linear(1.0)`). Clamping keeps
            // large-text users functional without letting the layout blow
            // apart; `context.dp()` handles the device-width scaling.
            final appChild = MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.15,
              child: ScrollConfiguration(behavior: MyBehavior(), child: child!),
            );

            // agil-1 Phase 8 (an ask of agil-3): Konto's "Roligere bevegelse"
            // becomes MediaQuery.disableAnimations for the whole app, so the
            // Bergen kit's motion helpers honour it everywhere.
            final calmChild = ValueListenableBuilder<bool>(
              valueListenable: A3Services.reducedMotion,
              builder: (context, calm, child) => calm
                  ? MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(disableAnimations: true),
                      child: child!,
                    )
                  : child!,
              child: BergenPerfScope(child: appChild),
            );

            return calmChild;
          },
          debugShowCheckedModeBanner: false,
          locale: selectedLocale,
          initialRoute: routeNameFor(const Splash()),
          routes: {
            routeNameFor(const Splash()): (_) => const Splash(),
            // Sync C (AGIL-CONTRACT §2.2): each branch owns one route map.
            ...bergenRoutesAgil1(),
            ...bergenRoutesAgil3(),
          },
          onGenerateRoute: (settings) {
            final name = settings.name ?? '';
            final uri = Uri.tryParse(
              name.contains('://') ? name : 'aerend://local$name',
            );

            // `aerendapp://payment/vipps?orderId=N`: the full link on a cold
            // start, or `/vipps?orderId=N` when the running app receives it
            // (Flutter keeps only path + query of a pushed deep link).
            final isVippsPayment =
                name.contains('payment/vipps') ||
                (uri?.host == 'payment' &&
                    (uri?.path.contains('vipps') ?? false)) ||
                (uri?.host == 'local' && uri?.path == '/vipps');
            if (isVippsPayment) {
              final orderId =
                  int.tryParse(uri?.queryParameters['orderId'] ?? '') ??
                  prefGetInt('vipps_pending_order_id');
              if (orderId > 0) {
                return MaterialPageRoute(
                  settings: const RouteSettings(
                    name: '${appRoutePrefix}vipps-retur',
                  ),
                  builder: (context) =>
                      VippsPaymentReturnScreen(orderId: orderId),
                );
              }
            }

            final isVippsLoginHttpsCallback =
                uri?.path.contains('/vipps/login/callback') == true;
            final isVippsLogin =
                isVippsLoginHttpsCallback ||
                name.contains('vipps-login') ||
                uri?.host == 'vipps-login' ||
                ((uri?.scheme == appUrlScheme || uri?.scheme == 'aerend') &&
                    (uri?.host == 'vipps-login' ||
                        uri?.path.contains('vipps-login') == true));
            if (isVippsLogin) {
              final code = uri?.queryParameters['code'] ?? '';
              final state = uri?.queryParameters['state'] ?? '';
              if (code.isNotEmpty && state.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (context) =>
                      VippsLoginReturnScreen(code: code, state: state),
                );
              }
            }

            // Legacy: `/invite?code=…` arrives from old hare.io invite links. No screen creates
            // them any more; kept on purpose so an old link still lands somewhere sensible.
            if (settings.name?.startsWith('/invite') ?? false) {
              final uri = Uri.parse(settings.name!);
              final code = uri.queryParameters['code'];
              if (!isLoggedIn() && code != null && code.trim().isNotEmpty) {
                // Logged out: keep the code for `register` and show the
                // "Du er vervet" card on the onboarding landing.
                prefSetString(prefPendingReferCode, code.trim().toUpperCase());
                prefSetBool(prefPendingReferFromLink, true);
                lfSetInviterName(uri.queryParameters['from'] ?? '');
                return MaterialPageRoute(builder: (context) => const Login());
              }
              return MaterialPageRoute(
                builder: (context) => RedeemCode(discountCode: code),
              );
            }

            // Customer Step 14: `aerendapp://bergen/ai/foresporsel/<id>` (the
            // hand-off link) on a cold start — the host is the first segment.
            if ((uri?.scheme == appUrlScheme || uri?.scheme == 'aerend') && uri?.host == 'bergen') {
              // Customer Step 15: the query stays (`/hurtig?mod=forrige`, the shortcuts).
              final r = BergenRoutes.generate(RouteSettings(name: '/bergen${uri!.path}${uri.hasQuery ? '?${uri.query}' : ''}', arguments: settings.arguments));
              if (r != null) return r;
            }

            // agil-1 Phase 2 (AGIL-CONTRACT §3.4): `/bergen/...` names with a
            // query or a trailing id resolve to the branch route maps.
            final bergenRoute = BergenRoutes.generate(settings);
            if (bergenRoute != null) return bergenRoute;

            return null;
          },
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
