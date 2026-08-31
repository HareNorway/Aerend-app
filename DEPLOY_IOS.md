# Hare-Customer (Reen) - iOS Deployment & TestFlight Guide

## App Info

| Field | Value |
|---|---|
| App Name | Reen |
| Bundle ID | `com.reen.customer` |
| Apple App ID | `6478966156` |
| Team ID | `5795P2L9F3` |
| Stripe Merchant ID | `merchant.com.hare.io.customer` |
| Min iOS Version | 15.0 |
| Firebase Project | `hare-89094` |

---

## Prerequisites

- Mac with Xcode 15+ installed
- Apple Developer Account (Team ID: `5795P2L9F3`)
- Flutter SDK 3.35.6+
- CocoaPods installed (`sudo gem install cocoapods`)
- App Store Connect access

---

## Step 1: Apple Developer Portal Setup

### 1.1 Register App ID (if not done)

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles** > **Identifiers** > **+**
3. Select **App IDs** > **App**
4. Description: `Reen Customer`
5. Bundle ID: **Explicit** > `com.reen.customer`
6. Enable these **Capabilities**:
   - Apple Pay Payment Processing
   - Associated Domains
   - Push Notifications
   - Sign In with Apple
7. Click **Register**

### 1.2 Create Apple Pay Merchant ID

1. **Identifiers** > **+** > Select **Merchant IDs**
2. Description: `Reen Customer Payments`
3. Identifier: `merchant.com.hare.io.customer`
4. Click **Register**

### 1.3 Create Certificates

#### Apple Pay Payment Processing Certificate (for Stripe)

1. **Identifiers** > **Merchant IDs** > select `merchant.com.hare.io.customer`
2. Under **Apple Pay Payment Processing Certificate**, click **Create Certificate**
3. **IMPORTANT FOR STRIPE:** You need a CSR from Stripe, NOT from your Mac:
   - Go to [Stripe Dashboard](https://dashboard.stripe.com) > **Settings** > **Payment Methods** > **Apple Pay**
   - Click **Add new application**
   - Stripe will give you a `.certSigningRequest` file (CSR)
4. Upload that Stripe CSR to Apple Developer Portal
5. Download the generated `.cer` file
6. Upload the `.cer` file back to Stripe Dashboard
7. Stripe will confirm Apple Pay is active

#### iOS Distribution Certificate

1. **Certificates** > **+** > **Apple Distribution**
2. Open **Keychain Access** on Mac > **Certificate Assistant** > **Request a Certificate From a Certificate Authority**
   - Email: your Apple ID email
   - Common Name: your name
   - Request is: **Saved to disk**
3. Upload the `.certSigningRequest` to Apple
4. Download and double-click the `.cer` to install in Keychain

#### Push Notification Certificate

1. **Identifiers** > select `com.reen.customer` > **Push Notifications** > **Configure**
2. Create both **Development** and **Production** SSL certificates
3. Use your Keychain CSR for these (NOT the Stripe one)
4. Download and install both `.cer` files

### 1.4 Create Provisioning Profiles

1. **Profiles** > **+** > **App Store Connect**
2. Select App ID: `com.reen.customer`
3. Select your Distribution Certificate
4. Profile Name: `Reen Customer App Store`
5. Download the `.mobileprovision` file

---

## Step 2: Stripe Apple Pay Configuration

### 2.1 Stripe Dashboard Setup

1. Log in to [Stripe Dashboard](https://dashboard.stripe.com)
2. Go to **Settings** > **Payment Methods** > **Apple Pay**
3. Click **Add new application**
4. Follow the CSR exchange process (described in Step 1.3 above)
5. Once the certificate is uploaded, Apple Pay will show as **Active**

### 2.2 Switch to Live Keys (CRITICAL before release)

The app currently uses **test keys**. Before submitting to App Store:

**File: `lib/constant/constant.dart`**

Change the Stripe publishable key from:
```
pk_test_51OuAwNRtRZ7Sf1Zq...  (TEST)
```
To:
```
pk_live_51OuAwNRtRZ7Sf1Zq...  (LIVE)
```

The live key is already commented out in the file - just swap which one is active.

### 2.3 Verify Merchant ID in Code

Already configured in `lib/main.dart`:
```dart
Stripe.merchantIdentifier = 'merchant.com.hare.io.customer';
```

Already configured in entitlements:
- `ios/Runner/Runner.entitlements` - has `merchant.com.hare.io.customer`
- `ios/Runner/RunnerRelease.entitlements` - has `merchant.com.hare.io.customer`

---

## Step 3: App Store Connect Setup

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps** > **+** > **New App**
3. Fill in:
   - Platform: **iOS**
   - Name: `Reen`
   - Primary Language: English
   - Bundle ID: `com.reen.customer`
   - SKU: `com.reen.customer`
   - Access: Full Access
4. Click **Create**

### 3.1 App Information

- Category: **Travel** or **Food & Drink** (pick the most relevant)
- Content Rights: Confirm you own or have rights
- Age Rating: Complete the questionnaire

### 3.2 Prepare App Store Listing

You'll need:
- App icon (1024x1024 PNG, no alpha)
- Screenshots for:
  - iPhone 6.7" (1290 x 2796) - iPhone 15 Pro Max
  - iPhone 6.5" (1284 x 2778) - iPhone 14 Plus
  - iPad Pro 12.9" (2048 x 2732) - if supporting iPad
- Description, keywords, support URL, privacy policy URL

---

## Step 4: Pre-Build Checklist

Before building, verify these items:

### 4.1 Fix Google Maps API Key

In `ios/Runner/Info.plist`, replace:
```xml
<string>YOUR_KEY_HERE</string>
```
With your actual Google Maps iOS API key.

### 4.2 Fix Facebook Configuration

In `ios/Runner/Info.plist`, replace the placeholder `000` values:
```xml
<key>FacebookAppID</key>
<string>YOUR_ACTUAL_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_ACTUAL_CLIENT_TOKEN</string>
```

### 4.3 Update API Base URL

In `lib/constant/constant.dart` or wherever the base URL is set, ensure it points to production:
```
https://api.ailogistics.no/api/customer/
```

### 4.4 Verify Firebase Configuration

Ensure `ios/Runner/GoogleService-Info.plist` has the correct production Firebase config for bundle ID `com.reen.customer`.

---

## Step 5: Build & Upload to TestFlight

### 5.1 Install Dependencies

```bash
cd /c/Users/yashv/OneDrive/Desktop/Work/hare2/Hare-Customer

# Get Flutter packages
flutter pub get

# Install iOS pods (must be on Mac)
cd ios
pod install --repo-update
cd ..
```

### 5.2 Build the IPA

**Option A: Using Xcode (Recommended for first time)**

```bash
# Open in Xcode
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Runner** project > **Signing & Capabilities**
2. Team: Select your team (`5795P2L9F3`)
3. Ensure **Automatically manage signing** is checked
4. Verify capabilities:
   - Apple Pay (with `merchant.com.hare.io.customer`)
   - Push Notifications
   - Sign In with Apple
   - Associated Domains (`applinks:hare.io`)
5. Select **Any iOS Device (arm64)** as build target
6. **Product** > **Archive**
7. Once archived, click **Distribute App** > **App Store Connect** > **Upload**

**Option B: Using command line**

```bash
flutter build ipa --release

# The IPA will be at: build/ios/ipa/Reen.ipa
```

Then upload using Transporter app or:
```bash
xcrun altool --upload-app --type ios --file build/ios/ipa/Reen.ipa --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
```

### 5.3 TestFlight

1. After upload, go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app > **TestFlight** tab
3. Wait for build processing (5-30 minutes)
4. If there's a compliance warning about encryption:
   - Click **Manage** > Select **None of the algorithms mentioned above** (if you only use HTTPS)
5. Add **Internal Testers** (your team members with App Store Connect access)
6. Add **External Testers**:
   - Create a group > Add emails
   - Submit the build for Beta App Review (usually approved within 24-48 hours)
7. Testers will receive a TestFlight invitation email

---

## Step 6: Submit to App Store

1. In App Store Connect, go to your app > **App Store** tab
2. Select the build from TestFlight
3. Fill in all required metadata
4. Add screenshots for all required device sizes
5. Complete the **App Review Information**:
   - Demo account credentials (if login required)
   - Contact info for review team
   - Notes: Explain any special features (Apple Pay, location usage, etc.)
6. Click **Submit for Review**
7. Review typically takes 24-48 hours

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|---|---|
| `No signing certificate` | Download from Developer Portal and install in Keychain |
| `Provisioning profile doesn't match` | Regenerate profile in Developer Portal with correct cert |
| `Apple Pay not working` | Verify merchant ID in entitlements matches Stripe config |
| `Pod install fails` | Run `pod repo update` then `pod install` again |
| `Archive fails with bitcode` | Set `Enable Bitcode = NO` in Build Settings |
| `Push notifications not working` | Upload APNs key/cert to Firebase Console |

### APS Environment

The current entitlements have `aps-environment = development`. For App Store submission:
- Xcode automatically switches to `production` when you archive with Release configuration
- If you get push notification issues, verify in Runner**Release**.entitlements

---

## Quick Reference: Certificate Flow for Apple Pay + Stripe

```
1. Stripe Dashboard → Download CSR file
2. Apple Developer Portal → Merchant ID → Create Certificate → Upload Stripe CSR
3. Apple → Download .cer file
4. Stripe Dashboard → Upload .cer file
5. Stripe confirms Apple Pay is active
```

This is DIFFERENT from your regular iOS distribution certificate. You need BOTH:
- **Distribution Certificate** (for signing the app) - uses YOUR Mac's CSR
- **Apple Pay Processing Certificate** (for Stripe) - uses STRIPE's CSR
