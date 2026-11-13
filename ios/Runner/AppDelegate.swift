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

  // Parity plan §3: the motion tier reads the device class and low power
  // mode here (`BergenPerf` in Dart); the thermal state feeds the perf
  // heartbeat and the gentle heat ladder (serious: decorative motion at
  // 30 fps; critical: motion off).
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
    // Perf plan: the battery level (0–100, -1 when unknown) for the heartbeat.
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    return [
      "platform": "ios",
      "model": String(cString: machine),
      "ramMb": Double(ProcessInfo.processInfo.physicalMemory) / 1_048_576,
      "lowPower": ProcessInfo.processInfo.isLowPowerModeEnabled,
      "thermal": thermal,
      // Heat ladder: the raw state (on iOS the same scale).
      "thermalStatus": thermal,
      "battery": level < 0 ? -1.0 : Double(level * 100),
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
    // Notifications plan Step 7: hand the token on to the plugins too (FlutterAppDelegate forwards it).
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Notifications plan Step 7: the delegate selectors now match UNUserNotificationCenterDelegate (they were declared
  // `_center:` and never called). Both hand over to FlutterAppDelegate, which forwards to firebase_messaging and
  // flutter_local_notifications - the Dart side decides what a foreground push shows.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
 