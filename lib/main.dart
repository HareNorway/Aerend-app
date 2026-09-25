import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:aerend_customer/screens/snurre/snurre_chat_screen.dart';
import 'package:aerend_customer/screens/snurre/snurre_launcher_policy.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/blocs/bloc.dart';
import 'package:aerend_customer/screens/common/account/redeem_code.dart';
import 'package:redux/redux.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:translator/translator.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intercom_flutter/intercom_flutter.dart';

import 'firebase_options.dart';
import 'redux/store.dart';
import 'screens/common/login/login.dart';
import 'screens/common/splash/splash.dart';
import 'screens/common/vipps/vipps_login_link_handler.dart';
import 'screens/common/vipps/vipps_return_screens.dart';
import 'services/push_notification_service.dart';
import 'networking/feed/feed_api_constant.dart';
import 'utils/utils.dart';
import 'screens/bergen/bergen_routes_agil1.dart';
import 'screens/bergen/bergen_routes_agil3.dart';

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
  Map<String, String> stringNotificationData = notificationData.map(
    (key, value) => MapEntry(key, value.toString()),
  );
  if (await Intercom.instance.isIntercomPush(stringNotificationData)) {
    await Intercom.instance.handlePush(stringNotificationData);
    return;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  Stripe.publishableKey = stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.com.reen.customer';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  // Initialize Intercom
  await Intercom.instance.initialize(
    'rom4281p',
    androidApiKey: 'android_sdk-b83eca055509ac844d38323af68c6912dfc06fb4',
    iosApiKey: 'ios_sdk-80a6ca15c52d94177c6d439d43be89bb414d550b',
  );

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

  runApp(MyApp(store));
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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VippsLoginLinkHandler.bootstrap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(VippsLoginLinkHandler.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _resumedFromBackground = true;
    }
    if (state == AppLifecycleState.resumed && _resumedFromBackground) {
      _resumedFromBackground = false;
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

            return Stack(children: [appChild, const _GlobalSnurreLauncher()]);
          },
          debugShowCheckedModeBanner: false,
          locale: selectedLocale,
          initialRoute: snurreLauncherRouteNameFor(const Splash()),
          routes: {
            snurreLauncherRouteNameFor(const Splash()): (_) => const Splash(),
            // Sync C (AGIL-CONTRACT §2.2): each branch owns one route map.
            ...bergenRoutesAgil1(),
            ...bergenRoutesAgil3(),
          },
          navigatorObservers: [
            snurreRouteObserver,
            snurreLauncherNavigatorObserver,
          ],
          onGenerateRoute: (settings) {
            final name = settings.name ?? '';
            final uri = Uri.tryParse(
              name.contains('://') ? name : 'aerend://local$name',
            );

            final isVippsPayment = name.contains('payment/vipps') ||
                (uri?.host == 'payment' &&
                    (uri?.path.contains('vipps') ?? false));
            if (isVippsPayment) {
              final orderId = int.tryParse(
                    uri?.queryParameters['orderId'] ?? '',
                  ) ??
                  prefGetInt('vipps_pending_order_id');
              if (orderId > 0) {
                return MaterialPageRoute(
                  builder: (context) =>
                      VippsPaymentReturnScreen(orderId: orderId),
                );
              }
            }

            final isVippsLoginHttpsCallback =
                uri?.path.contains('/vipps/login/callback') == true;
            final isVippsLogin = isVippsLoginHttpsCallback ||
                name.contains('vipps-login') ||
                uri?.host == 'vipps-login' ||
                (uri?.scheme == 'aerend' &&
                    (uri?.host == 'vipps-login' ||
                        uri?.path.contains('vipps-login') == true));
            if (isVippsLogin) {
              final code = uri?.queryParameters['code'] ?? '';
              final state = uri?.queryParameters['state'] ?? '';
              if (code.isNotEmpty && state.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (context) => VippsLoginReturnScreen(
                    code: code,
                    state: state,
                  ),
                );
              }
            }

            if (settings.name?.startsWith('/invite') ?? false) {
              final uri = Uri.parse(settings.name!);
              final code = uri.queryParameters['code'];
              if (!isLoggedIn() && code != null && code.trim().isNotEmpty) {
                // Logged out: keep the code for `register` and show the
                // "Du er vervet" card on the onboarding landing.
                prefSetString(prefPendingReferCode, code.trim().toUpperCase());
                prefSetBool(prefPendingReferFromLink, true);
                return MaterialPageRoute(builder: (context) => const Login());
              }
              return MaterialPageRoute(
                builder: (context) => RedeemCode(discountCode: code),
              );
            }

            return null;
          },
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
  }
}

class _GlobalSnurreLauncher extends StatefulWidget {
  const _GlobalSnurreLauncher();

  @override
  State<_GlobalSnurreLauncher> createState() => _GlobalSnurreLauncherState();
}

class _GlobalSnurreLauncherState extends State<_GlobalSnurreLauncher> {
  bool _opening = false;

  Future<void> _openSnurre() async {
    if (_opening || snurreChatRouteOnTop.value) return;
    if (!canUseSnurreLauncher()) {
      openSimpleSnackbar('Please log in to use AI chat.');
      return;
    }
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    setState(() => _opening = true);
    try {
      await nav.push(
        MaterialPageRoute<void>(
          settings: RouteSettings(
            name: snurreLauncherRouteNameFor(const SnurreChatScreen()),
          ),
          builder: (_) => const SnurreChatScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        snurreLauncherVisible,
        snurreChatRouteOnTop,
      ]),
      builder: (context, _) {
        if (!shouldShowSnurreLauncherForRoute(
          snurreLauncherNavigatorObserver.topRoute,
        )) {
          return const SizedBox.shrink();
        }

        final top = MediaQuery.of(context).padding.top + kToolbarHeight + 16;
        return Positioned(
          right: -32,
          top: top,
          child: Semantics(
            button: true,
            label: 'Open Snurre chat',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _opening ? null : _openSnurre,
              child: SizedBox(
                width: 64,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: ScSaasThemeTokens.primary.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Align(
                    alignment: Alignment(-0.55, 0),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: ScSaasThemeTokens.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
