import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
       !mapsApiKey.isEmpty {
      GMSServices.provideAPIKey(mapsApiKey)
    } else {
      assertionFailure("Missing GOOGLE_MAPS_API_KEY in Info.plist")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
  {
    Messaging.messaging().apnsToken = deviceToken
   
  }

   func userNotificationCenter(_center: UNUserNotificationCenter,
    willPresent notification: UNNotification, withCompletionHandler
    completionHandler: @escaping (UNNotificationPresentationOptions) ->
    Void){
    print("Notification recevied while app is in Foreground")

      completionHandler([.alert, .badge, .sound])
    }
  func userNotificationCenter(_center: UNUserNotificationCenter,
  didReceive response: UNNotificationResponse, withCompletionHandler
  completionHandler: @escaping () ->
  Void){
    print("Notification recevied while app is in Background")

    completionHandler()
  }
}
 