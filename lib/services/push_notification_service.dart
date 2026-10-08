import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:showcaseview/showcaseview.dart';

import '../networking/ops/ops_customer_api.dart';
import '../screens/common/chatting/chatting.dart';
import '../screens/common/homeMainV1/home_main_v1.dart';
import '../screens/common/splash/splash.dart';
import '../screens/common/swipeAerend/swipe_aerend.dart';
import '../screens/feed/postDetail/post_detail.dart';
import '../screens/feed/storeProfile/store_profile.dart';
import '../screens/common/wallet/walletTransaction/wallet_transaction.dart';
import '../screens/bergen/kit/bergen_routes.dart';
import '../screens/deliveryService/trackOrder/track_order.dart';
import '../screens/rideService/rideDetail/ride_detail.dart';
import '../utils/utils.dart';
import 'push_deep_link.dart';

class PushNotificationService {
  String tag = "Notification>>>";
  bool _fcmForegroundListenersAttached = false;

  /// Create a [AndroidNotificationChannel] for heads up notifications
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @pragma('vm:entry-point')
  Future initialise() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(firebaseTopicName);
    } catch (e) {
      debugPrint("FCM subscribeToTopic failed (likely iOS Simulator): $e");
    }

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    await initLocalNotification();
    autoRefreshCredentialsInitialize();
  }

  Future<void> bumpChatAppBadge() async {
    try {
      final int n = prefGetInt(prefChatAppBadgeCount) + 1;
      await prefSetInt(prefChatAppBadgeCount, n);
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(n);
      }
    } catch (e) {
      logd(tag, "bumpChatAppBadge: $e");
    }
  }

  Future<void> clearChatAppBadge() async {
    try {
      await prefSetInt(prefChatAppBadgeCount, 0);
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      logd(tag, "clearChatAppBadge: $e");
    }
  }

  showNotification(RemoteMessage remote) async {
    final Map<String, dynamic> notificationData = Map<String, dynamic>.from(
      remote.data,
    );
    logd(tag, notificationData.toString());

    final String? feedPayloadType =
        notificationData[NotificationConstant.feedType]?.toString();
    if (feedPayloadType == NotificationConstant.feedNewPost ||
        feedPayloadType == NotificationConstant.feedNewStory) {
      final String title =
          notificationData[NotificationConstant.title]?.toString() ?? "";
      final String message =
          notificationData[NotificationConstant.message]?.toString() ?? "";
      await flutterLocalNotificationsPlugin.show(
        notificationData.hashCode,
        title.isNotEmpty ? title : "Feed",
        message.isNotEmpty
            ? message
            : feedPayloadType == NotificationConstant.feedNewStory
            ? "New story"
            : "New post",
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'ic_notification',
            color: colorPrimary,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(notificationData),
      );
      return;
    }

    final dynamic rawType =
        notificationData[NotificationConstant.notificationType];
    final int notificationType = rawType == null
        ? 0
        : int.tryParse(rawType.toString()) ?? 0;

    // A campaign or an ops push (`aerend://` link) is never a chat message,
    // even when it carries a `user_id` (Step 13).
    final bool isChatPayload =
        notificationType == 0 &&
        notificationData[NotificationConstant.userId] != null &&
        !PushDeepLink.handles(notificationData);

    String title =
        notificationData[NotificationConstant.title]?.toString() ?? "";
    String message =
        notificationData[NotificationConstant.message]?.toString() ?? "";

    if (isChatPayload) {
      message =
          notificationData[NotificationConstant.desc]?.toString() ?? message;
    }

    if (isChatPayload && !isChatOpen) {
      await bumpChatAppBadge();
    }
    final int badgeForTray = prefGetInt(prefChatAppBadgeCount);

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: 'ic_notification',
        color: colorPrimary,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        fullScreenIntent: true,
        number: badgeForTray > 0 ? badgeForTray : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: badgeForTray > 0 ? badgeForTray : null,
      ),
    );

    final bool showTray = notificationType != 0 || !isChatOpen || isChatPayload;

    if (showTray) {
      await flutterLocalNotificationsPlugin.show(
        notificationData.hashCode,
        title,
        message,
        details,
        payload: jsonEncode(notificationData),
      );
    }
  }

  handleNotification() async {
    if (_fcmForegroundListenersAttached) {
      debugPrint("$tag handleNotification: listeners already attached, skip");
      return;
    }
    _fcmForegroundListenersAttached = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      logd(tag, "onMessage foreground: $message");
      await showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logd(tag, "onMessageOpenedApp: $message");
      handleNotificationClick(message.data, false);
    });

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      logd(tag, "getInitialMessage: $message");
      if (message != null) {
        handleNotificationClick(message.data, true);
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async {
      debugPrint("$tag FCM onTokenRefresh");
      await prefSetString(prefDeviceToken, newToken);
      if (prefGetInt(prefUserId) > 0) {
        setFCMToken();
      }
    });
  }

  Future initLocalNotification() async {
    if (Platform.isIOS) {
      // set iOS Local notification.
      var initializationSettingsAndroid = const AndroidInitializationSettings(
        'ic_notification',
      );
      var initializationSettingsIOS = const DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          _selectNotification(details.payload);
        },
      );
    } else {
      var initializationSettingsAndroid = const AndroidInitializationSettings(
        'ic_notification',
      );
      var initializationSettingsIOS = const DarwinInitializationSettings();
      var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          _selectNotification(details.payload);
        },
      );
    }
    FirebaseMessaging.instance
        .getToken()
        .then((token) async {
          debugPrint("$tag FCM getToken: ${token ?? 'null'}");
          if (token != null) {
            await prefSetString(prefDeviceToken, token);
            if (prefGetInt(prefUserId) > 0) {
              setFCMToken();
            }
          }
        })
        .catchError((e) {
          debugPrint("FCM token unavailable (likely iOS Simulator): $e");
        });
    _requestPermissions();
  }

  Future _selectNotification(String? payload) async {
    try {
      final dynamic decoded = jsonDecode(payload ?? "{}");
      if (decoded is! Map) return;
      await handleNotificationClick(Map<String, dynamic>.from(decoded), false);
    } catch (e) {
      debugPrint("$tag _selectNotification decode error: $e");
    }
  }

  /// The ops API the campaign open ping goes through; a fake in tests.
  @visibleForTesting
  static OpsCustomerApi Function() opsApi = OpsCustomerApi.new;

  /// Counts an admin campaign push as opened (backend plan Step 13).
  /// Fire-and-forget: never awaited, never throws. True when a ping was sent
  /// off, i.e. [nd] is a campaign with an id.
  static bool pingCampaignOpened(Map<String, dynamic> nd) {
    final id = PushDeepLink.campaignId(nd);
    if (id == null) return false;
    try {
      unawaited(opsApi().pushOpened(id).catchError((_) => false));
    } catch (_) {}
    return true;
  }

  handleNotificationClick(dynamic notificationData, bool isReplace) {
    final Map<String, dynamic> nd;
    if (notificationData is Map<String, dynamic>) {
      nd = notificationData;
    } else if (notificationData is Map) {
      nd = Map<String, dynamic>.from(notificationData);
    } else {
      debugPrint("$tag handleNotificationClick: invalid payload type");
      return;
    }
    // Before the login gate: the campaign's open count does not depend on
    // where the tap leads.
    pingCampaignOpened(nd);

    if (!isLoggedIn()) {
      return;
    }

    if (scContext != null) {
      ShowCaseWidget.of(scContext!).dismiss();
    }
    Widget screen = const Splash();
    bool isChatScreen = false;

    // Admin campaigns and the ops pushes (`aerend://` links) route by their
    // own target — before the chat branch, which would read an ops push with
    // a `user_id` and no `notification_type` as a chat message.
    if (PushDeepLink.handles(nd)) {
      final route = PushDeepLink.resolve(nd);
      if (route != null) {
        openPushRoute(route, isReplace: isReplace);
        return;
      }
      // Not understood: the fallback below (Splash), never the chat. No
      // navigator yet (a launching tap): Splash is on its way anyway.
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      if (isReplace) {
        openScreenWithClearPrevious(ctx, screen);
      } else {
        openScreen(ctx, screen);
      }
      return;
    }

    final String? feedPayloadType = nd[NotificationConstant.feedType]
        ?.toString();
    if (feedPayloadType == NotificationConstant.feedNewPost) {
      final String? postId = nd[NotificationConstant.postId]?.toString();
      if (postId != null && postId.isNotEmpty) {
        screen = PostDetailScreen(postId: postId);
        if (isReplace) {
          openScreenWithClearPrevious(navigatorKey.currentContext!, screen);
        } else {
          openScreen(navigatorKey.currentContext!, screen);
        }
        return;
      }
    }
    if (feedPayloadType == NotificationConstant.feedNewStory) {
      final String? storeId = nd[NotificationConstant.storeId]?.toString();
      if (storeId != null && storeId.isNotEmpty) {
        screen = StoreProfileScreen(storeId: storeId);
        if (isReplace) {
          openScreenWithClearPrevious(navigatorKey.currentContext!, screen);
        } else {
          openScreen(navigatorKey.currentContext!, screen);
        }
        return;
      }
    }

    if (nd[NotificationConstant.notificationType] == null) {
      if (nd[NotificationConstant.userId] != null) {
        if (chatState != null && chatState!.mounted) isChatScreen = true;
        clearChatAppBadge();
        screen = Chatting(
          chatWithId: nd[NotificationConstant.userId].toString(),
          chatWithName: nd[NotificationConstant.title].toString(),
          chatWithImage: nd[NotificationConstant.userImg].toString(),
          chatWithServicesName: (nd[NotificationConstant.userServiceName] ?? "")
              .toString(),
          chatWithUserType:
              int.tryParse(
                (nd[NotificationConstant.userType] ?? "-1").toString(),
              ) ??
              -1,
        );
      }
    } else {
      int notificationType = int.parse(
        (nd[NotificationConstant.notificationType] ?? 0).toString(),
      );
      int orderId = int.parse(
        (nd[NotificationConstant.orderId] ?? 0).toString(),
      );
      int serviceCategoryId = int.parse(
        (nd[NotificationConstant.serviceCategoryId] ?? 0).toString(),
      );

      if (notificationType == 6) {
        screen = const WalletTransaction(fromNotification: true);
      } else if (notificationType != 0) {
        //TRANSPORT
        if (serviceCategoryId == 1 ||
            serviceCategoryId == 2 ||
            serviceCategoryId == 4) {
          screen = openRideDetailScreen(orderId, serviceCategoryId);
        } else if (serviceCategoryId >= 5 && serviceCategoryId <= 10) {
          //food delivery — AGIL-1 v2 Phase 6: the Bergen Sporing screen.
          final bergen = BergenRoutes.generate(
            RouteSettings(name: '/bergen/sporing/$orderId'),
          );
          if (bergen != null) {
            navigatorKey.currentState?.push(bergen);
            return;
          }
          screen = TrackOrder(
            orderId: orderId,
            isFromPlacedOrder: false,
            isFromNotification: true,
          );
        }
      }
    }
    if (isReplace) {
      openScreenWithClearPrevious(navigatorKey.currentContext!, screen);
    } else if (isChatScreen) {
      openScreenWithReplacePrevious(navigatorKey.currentContext!, screen);
    } else {
      openScreen(navigatorKey.currentContext!, screen);
    }
  }

  /// Opens [route] over the Bergen shell. Before the shell is up (a tap that
  /// launched the app — Splash still runs and would replace anything pushed
  /// under it — or no navigator yet), the route is held and the shell opens
  /// it when it builds ([HomeMainV1State] takes it). True when opened now.
  static bool openPushRoute(PushRoute route, {bool isReplace = false}) {
    if (route.kind == PushRouteKind.ignore) return false;
    final nav = navigatorKey.currentState;
    final shell = HomeMainV1State.current;
    final shellUp = shell != null && shell.mounted;
    if (nav == null || (!shellUp && isReplace)) {
      PushDeepLink.hold(route);
      return false;
    }
    final ctx = nav.context;
    switch (route.kind) {
      case PushRouteKind.shell:
        if (shellUp) {
          nav.popUntil((r) => r.isFirst);
          shell.switchToTab(route.tab);
        } else {
          openScreenWithClearPrevious(ctx, HomeMainV1(homeIndex: route.tab));
        }
      case PushRouteKind.swipe:
        openScreen(ctx, const SwipeReen());
      case PushRouteKind.bergen:
        final page = BergenRoutes.generate(
          RouteSettings(name: route.name, arguments: route.arguments),
        );
        if (page != null) {
          nav.push(page);
        } else if (shellUp) {
          shell.switchToTab(0);
        }
      case PushRouteKind.post:
        openScreen(ctx, PostDetailScreen(postId: route.postId!));
      case PushRouteKind.ignore:
        return false;
    }
    return true;
  }

  /// The shell is up: open what a launching tap left waiting, if anything.
  static void openPendingPushRoute() {
    final route = PushDeepLink.takePending();
    if (route != null) openPushRoute(route);
  }

  openRideDetailScreen(int orderId, int serviceCategoryId) {
    return RideDetail(
      rideId: orderId,
      rideType: languages.courierDelivery,
      isFromNotification: true,
    );
  }

  _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool isGranted =
          await androidImplementation?.areNotificationsEnabled() ?? false;
      if (!isGranted) {
        final bool? granted = await androidImplementation
            ?.requestNotificationsPermission();
        debugPrint("Notification Permission: $granted");
      }
    }
  }

  Future<String> autoRefreshCredentialsInitialize() async {
    try {
      AccessCredentials? pushAccessTokenCred;
      String prefAccountAccessToken = prefGetString(
        prefServiceAccountAccessToken,
      ).trim();
      if (prefAccountAccessToken.isNotEmpty) {
        pushAccessTokenCred = AccessCredentials.fromJson(
          jsonDecode(prefAccountAccessToken),
        );
      }

      if (firebaseProjectId.trim().isEmpty) {
        String source = await rootBundle.loadString(
          'assets/json/service_account.json',
        );
        final serviceAccount = jsonDecode(source);
        if (serviceAccount['project_id'] != null) {
          firebaseProjectId = serviceAccount['project_id'];
        }
      }

      if (pushAccessTokenCred != null &&
          !pushAccessTokenCred.accessToken.hasExpired) {
        return pushAccessTokenCred.accessToken.data;
      }

      String source = await rootBundle.loadString(
        'assets/json/service_account.json',
      );
      final serviceAccount = jsonDecode(source);
      var accountCredentials = ServiceAccountCredentials.fromJson(
        serviceAccount,
      );

      AutoRefreshingAuthClient autoRefreshingAuthClient =
          await clientViaServiceAccount(accountCredentials, [
            'https://www.googleapis.com/auth/firebase.messaging',
          ]);

      /// initialization
      pushAccessTokenCred = autoRefreshingAuthClient.credentials;
      // when new credentials are available, pushAccessTokenCred will be updated
      // (it checks if the current credentials is expired)
      autoRefreshingAuthClient.credentialUpdates.listen((cred) {
        pushAccessTokenCred = cred;
      });
      prefSetString(
        prefServiceAccountAccessToken,
        jsonEncode(pushAccessTokenCred),
      );
      return pushAccessTokenCred!.accessToken.data;
    } catch (e) {
      // Invalid/missing service-account JWT must not crash app startup.
      logd(tag, "autoRefreshCredentialsInitialize failed: $e");
      return '';
    }
  }
}

class NotificationConstant {
  static const feedType = 'type';
  static const feedNewPost = 'feed_new_post';
  static const feedNewStory = 'feed_new_story';
  static const postId = 'post_id';
  static const storyId = 'story_id';
  static const storeId = 'store_id';
  static const title = 'title';
  static const titleCode = 'title_code';
  static const message = 'message';
  static const messageCode = 'message_code';
  static const desc = 'desc';
  static const notificationType = 'notification_type';
  static const userId = 'user_id';
  static const userImg = 'user_img';
  static const userServiceName = 'user_service_name';
  static const orderId = 'order_id';
  static const orderStatus = 'order_status';
  static const serviceCategoryId = 'service_category_id';
  static const bookingType = 'booking_type';
  static const userType = 'user_type';
}
