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
    setUpPerfChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Parity plan §3: the motion tier reads the device class, low power mode
  // and the thermal state here (`BergenPerf` in Dart).
  private var perfChannel: FlutterMethodChannel?

  private func perfState() -> [String: Any] {
    var size = 0
    sysctlbyname("hw.machine", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: max(size, 1))
    sysctlbyname("hw.machine", &machine, &size, nil, 0)
    let thermal: Int
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: thermal = 0
    case .fair: thermal = 1
    case .serious: thermal = 2
    case .critical: thermal = 3
    @unknown default: thermal = 0
    }
    return [
      "platform": "ios",
      "model": String(cString: machine),
      "ramMb": Double(ProcessInfo.processInfo.physicalMemory) / 1_048_576,
      "lowPower": ProcessInfo.processInfo.isLowPowerModeEnabled,
      "thermal": thermal,
    ]
  }

  private func setUpPerfChannel() {
    guard let registrar = self.registrar(forPlugin: "AerendPerf") else { return }
    let channel = FlutterMethodChannel(name: "aerend/perf", binaryMessenger: registrar.messenger())
    perfChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "info", let self = self {
        result(self.perfState())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    let center = NotificationCenter.default
    for name in [ProcessInfo.thermalStateDidChangeNotification, Notification.Name.NSProcessInfoPowerStateDidChange] {
      center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        guard let self = self else { return }
        self.perfChannel?.invokeMethod("changed", arguments: self.perfState())
      }
    }
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
 