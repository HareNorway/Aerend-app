# Hare Customer App – Setup Guide (for interns)

Follow these steps after cloning the repo to run the **Hare-Customer** Flutter app on your machine.

---

## Prerequisites

- **Flutter SDK**: Flutter **3.35.6** (or any **3.5.x** compatible with Dart `>=3.5.0 <4.0.0`)  
  - Install from the official docs `https://docs.flutter.dev/get-started/install`
- **Dart**: Comes with Flutter (no separate install needed)
- **Android tooling** (for Android build/run):
  - Android Studio (SDK + emulator)
  - Java JDK (17 is recommended)
- **iOS tooling** (only on macOS, for iPhone build/run):
  - Xcode + Command Line Tools
  - CocoaPods (`sudo gem install cocoapods`, if not already installed)
- **Device / Emulator**:
  - Android Emulator, iOS Simulator, or a physical Android/iOS device
- **Backend API running** (Laravel – Hare-AdminPanel)
  - Same backend as in `Hare-AdminPanel/SETUP.md`
  - The customer app talks to the Laravel API at `domain + api/customer/...`

---

## 1. Clone the repo and open the customer app

If you don’t already have the project:

```bash
git clone <repository-url>
cd Hare/Hare-Customer
```

If you already have the repo, just move into the customer app:

```bash
cd Hare-Customer
```

---

## 2. Install Flutter dependencies

From the `Hare-Customer` folder run:

```bash
flutter pub get
```

If Flutter complains about the SDK version, make sure you are on a **3.5.x** Flutter channel (or specifically **3.35.6** as mentioned in `pubspec.yaml`).

---

## 3. Configure the backend API base URL

The mobile app uses the `BaseUrl` configuration in `lib/networking/api_constant.dart`:

```dart
class BaseUrl {
  // Dev
  static const domain = "https://hare.io/";
  // static const domain = "http://192.168.128.124:8000/";

  static const endPointBaseUrlApi = "api/";
  static const endPointBaseUrlCustomer = "customer/";
  static const endPointBaseUrlStore = "store/";

  static const baseUrl = domain + endPointBaseUrlApi + endPointBaseUrlCustomer;
  static const baseStoreUrl = domain + endPointBaseUrlApi + endPointBaseUrlStore;
  ...
}
```

You have **two common options**:

- **Use the live/staging server** (default):  
  Leave `domain` as `https://hare.io/`.  
  - All API calls go to `https://hare.io/api/customer/...`.

- **Use your local Laravel backend (recommended for dev)**:
  1. First, follow `Hare-AdminPanel/SETUP.md` and get the Laravel app running:
     ```bash
     cd ../Hare-AdminPanel
     php artisan serve --host=0.0.0.0
     ```
     - This usually exposes the API at something like `http://<your-ip-address>:8000/api/...`.
  2. Find your machine’s IP (for example `10.190.235.138`) and then update `BaseUrl.domain` in  
     `lib/networking/api_constant.dart`:
     ```dart
     class BaseUrl {
       static const domain = "http://10.190.235.138:8000/";
       // static const domain = "https://hare.io/";
       ...
     }
     ```
     **Note**:  
     - Keep the trailing `/` in the URL.  
     - Do **not** add `api/` here; it is appended automatically.
  3. For **Android emulator**, you can also use `http://10.0.2.2:8000/` as the domain (this maps to your host machine’s `localhost`).

Make sure the device/emulator can reach the same IP/port as the Laravel server.

---

## 4. Google Maps & Places (optional but recommended)

The app uses **Google Maps / Places / Directions** via URLs built in `lib/utils/utils.dart` and the `ApiMapHelper`.  
To have maps and autocomplete working properly:

- Ensure you have a valid **Google Maps / Places API key**.
- Confirm that the Android/iOS projects are configured with that key (typically in:
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/AppDelegate` / Info.plist).
- Make sure the key has the right APIs enabled (Maps, Places, Directions).

If you are only exploring basic flows and UI, you can skip this initially; map features may fail or show errors until keys are correct.

---

## 5. Firebase setup (push notifications, crashlytics)

Firebase is already wired in the codebase:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Dependencies: `firebase_core`, `firebase_messaging`, `firebase_auth`, `firebase_crashlytics`, etc.

For most development work you can **reuse the existing configuration**. If you need to point to your own Firebase project:

- Replace `google-services.json` and `GoogleService-Info.plist` with files from your Firebase project.
- Make sure bundle IDs / application IDs match the ones registered in Firebase.

If Firebase is misconfigured, push notifications and some analytics/crash reporting features may not work, but the core app will still run.

---

## 6. Run the app

From the `Hare-Customer` folder:

### 6.1. Android

#### Emulator

```bash
flutter devices       # verify an Android emulator is listed
flutter run           # by default runs on the first connected device/emulator
```

#### Physical device

- Enable **USB debugging** on the phone.
- Connect it via USB.
- Accept any prompts on the device.
- Then run:

```bash
flutter devices
flutter run
```

### 6.2. iOS (on macOS)

First ensure CocoaPods dependencies are installed:

```bash
cd ios
pod install
cd ..
```

Then run on a simulator or a connected device:

```bash
flutter devices    # should list iOS simulators / devices
flutter run
```

If Xcode complains about signing:

- Open `ios/Runner.xcworkspace` in Xcode.
- Set your **Team** and fix signing errors.

---

## 7. What’s in this app

This Flutter app is the **customer-facing mobile client** for Hare. It connects to the same backend as the admin panel and includes:

- **Delivery service**: store list, product list, store details, cart, checkout, order tracking.
- **Ride service**: book rides, see running rides, ride history, ride details.
- **Wallet & payments**: wallet balance, wallet transactions, Stripe & Vipps integration, multiple payment methods.
- **Auth & profile**: signup/login (email/social/Apple), profile, settings, language & currency selection.
- **Notifications & chat**: Firebase messaging, in-app notifications, and chat-related flows.

---

## 8. Troubleshooting

- **App cannot connect to server / network errors**  
  - Check `BaseUrl.domain` in `lib/networking/api_constant.dart`.  
  - Make sure Laravel (`php artisan serve`) is running and reachable from your device/emulator.

- **Android emulator cannot reach local backend**  
  - Use `http://10.0.2.2:8000/` as `BaseUrl.domain` instead of `http://127.0.0.1:8000/`.

- **White/blank screen at startup**  
  - Run `flutter clean && flutter pub get` and try again.  
  - Check Flutter/Dart SDK versions.

- **Google Maps / Places not working**  
  - Verify your API key and that the correct APIs are enabled in Google Cloud Console.

- **Firebase push notifications not received**  
  - Confirm that `google-services.json` and `GoogleService-Info.plist` match a valid Firebase project.  
  - Ensure the app’s bundle/application IDs are correctly configured in Firebase.

