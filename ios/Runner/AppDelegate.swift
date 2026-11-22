import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import Firebase
import FirebaseMessaging
import UserNotifications
import CoreHaptics

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
    if let registrar = self.registrar(forPlugin: "AerendGameHaptics") {
      gameHapticsChannel = gameHaptics.register(with: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Parity plan §3: the motion tier reads the device class and low power
  // mode here (`BergenPerf` in Dart); the thermal state feeds the perf
  // heartbeat and the gentle heat ladder (serious: decorative motion at
  // 30 fps; critical: motion off).
  private var perfChannel: FlutterMethodChannel?
  // Fjordløpet haptics plan Step 3: the game's haptics (GameHapticsChannel at the end of this file).
  private let gameHaptics = GameHapticsChannel()
  private var gameHapticsChannel: FlutterMethodChannel?

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
 

// MARK: - Fjordløpet haptics plan Step 3 (haptics spec §7.1, §11.3): `aerend/game_haptics` on the iPhone.
//
// Kept in this file so the Xcode project needs no new entry. Written on Windows against Apple's API and first built by
// a person on a Mac (DH7): every failure falls back to Standard (Flutter's HapticFeedback, played from Dart), never a
// crash.
//
// Tier: off on an iPad; rich when Core Haptics reports `supportsHaptics` and the engine starts; standard otherwise.
// `prepare(table, scale)` builds one engine and one pattern player per pattern (H02 per step, H09 per band), ahead of
// play and reused; `play(key)` only starts a player. The engine's stopped and reset handlers restart it and rebuild the
// players before the next pattern. `release` when the game closes.
final class GameHapticsChannel {
  private var engine: CHHapticEngine?
  private var players: [String: CHHapticPatternPlayer] = [:]
  private var current: CHHapticPatternPlayer?
  private var table: [String: [[Any]]] = [:]
  private var scale: Float = 1.0
  private var needsStart = false
  private var tier = ""

  func register(with messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
    let channel = FlutterMethodChannel(name: "aerend/game_haptics", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "capabilities":
        result(self.capabilities())
      case "prepare":
        let t = args["table"] as? [String: Any] ?? [:]
        self.table = t["ios"] as? [String: [[Any]]] ?? [:]
        self.scale = Float((args["scale"] as? NSNumber)?.doubleValue ?? 1.0)
        self.build()
        result(nil)
      case "play":
        self.play(args["key"] as? String ?? "")
        result(nil)
      case "stop":
        self.stop()
        result(nil)
      case "release":
        self.release()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return channel
  }

  private func capabilities() -> [String: Any] {
    if UIDevice.current.userInterfaceIdiom == .pad {
      tier = "off"
      return ["tier": "off", "why": "ipad"]
    }
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
      // No Core Haptics (an older iPhone): Flutter's HapticFeedback still works there.
      tier = "standard"
      return ["tier": "standard"]
    }
    if startEngine() {
      tier = "rich"
      return ["tier": "rich"]
    }
    tier = "standard"
    return ["tier": "standard", "why": "engine"]
  }

  private func startEngine() -> Bool {
    do {
      if engine == nil {
        let e = try CHHapticEngine()
        e.playsHapticsOnly = true
        e.isAutoShutdownEnabled = false
        // The handlers come on a Core Haptics queue; the players are only touched on the main queue (the channel's).
        e.stoppedHandler = { [weak self] _ in
          DispatchQueue.main.async { self?.needsStart = true }
        }
        e.resetHandler = { [weak self] in
          DispatchQueue.main.async {
            guard let self = self else { return }
            do {
              try self.engine?.start()
              self.needsStart = false
              self.build()
            } catch {
              self.needsStart = true
            }
          }
        }
        engine = e
      }
      try engine?.start()
      needsStart = false
      return true
    } catch {
      engine = nil
      return false
    }
  }

  private func num(_ v: Any) -> Float { Float((v as? NSNumber)?.doubleValue ?? 0) }

  /// One pattern from the table's events: ["T", ms, intensity, sharpness] or ["C", from, to, i0, i1, sharpness].
  private func pattern(_ events: [[Any]]) throws -> CHHapticPattern {
    var evs: [CHHapticEvent] = []
    var curves: [CHHapticParameterCurve] = []
    for e in events {
      guard let kind = e.first as? String else { continue }
      if kind == "T", e.count >= 4 {
        evs.append(CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1, num(e[2]) * scale)),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: num(e[3])),
          ],
          relativeTime: TimeInterval(num(e[1]) / 1000)))
      } else if kind == "C", e.count >= 6 {
        let from = TimeInterval(num(e[1]) / 1000)
        let dur = TimeInterval((num(e[2]) - num(e[1])) / 1000)
        // The event carries the strength (× scale); the intensity-control curve shapes it from i0 to i1.
        evs.append(CHHapticEvent(
          eventType: .hapticContinuous,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1, scale)),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: num(e[5])),
          ],
          relativeTime: from,
          duration: dur))
        curves.append(CHHapticParameterCurve(
          parameterID: .hapticIntensityControl,
          controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: num(e[3])),
            CHHapticParameterCurve.ControlPoint(relativeTime: dur, value: num(e[4])),
          ],
          relativeTime: from))
      }
    }
    return try CHHapticPattern(events: evs, parameterCurves: curves)
  }

  private func build() {
    guard tier == "rich", let engine = engine else { return }
    players.removeAll()
    current = nil
    for (key, events) in table {
      if let p = try? pattern(events), let player = try? engine.makePlayer(with: p) {
        players[key] = player
      }
    }
  }

  private func play(_ key: String) {
    guard tier == "rich" else { return }
    if needsStart {
      guard startEngine() else { return }
      build()
    }
    guard let player = players[key] else { return }
    try? current?.stop(atTime: CHHapticTimeImmediate)
    do {
      try player.start(atTime: CHHapticTimeImmediate)
      current = player
    } catch {
      needsStart = true
    }
  }

  private func stop() {
    try? current?.stop(atTime: CHHapticTimeImmediate)
    current = nil
  }

  private func release() {
    stop()
    players.removeAll()
    engine?.stop(completionHandler: nil)
    engine = nil
    needsStart = false
  }
}
