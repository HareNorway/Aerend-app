import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_no.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
    Locale('es'),
    Locale('no'),
    Locale('sv'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Reen Dugnad'**
  String get appName;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get showLess;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @cropper.
  ///
  /// In en, this message translates to:
  /// **'Cropper'**
  String get cropper;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneNo.
  ///
  /// In en, this message translates to:
  /// **'Phone No'**
  String get phoneNo;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get item;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCart;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkOut;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @noRecordFound.
  ///
  /// In en, this message translates to:
  /// **'Sorry !!\nNo Record Found This Time'**
  String get noRecordFound;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search Product'**
  String get searchProduct;

  /// No description provided for @internetConnLostTitle.
  ///
  /// In en, this message translates to:
  /// **'You are offline please check your internet connection.'**
  String get internetConnLostTitle;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @get.
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get get;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @loginToAerend.
  ///
  /// In en, this message translates to:
  /// **'Login to Reen Dugnad'**
  String get loginToAerend;

  /// No description provided for @continueTxt.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueTxt;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @taxiRide.
  ///
  /// In en, this message translates to:
  /// **'Taxi Ride'**
  String get taxiRide;

  /// No description provided for @bikeRide.
  ///
  /// In en, this message translates to:
  /// **'Bike Ride'**
  String get bikeRide;

  /// No description provided for @courierService.
  ///
  /// In en, this message translates to:
  /// **'Courier Service'**
  String get courierService;

  /// No description provided for @rideService.
  ///
  /// In en, this message translates to:
  /// **'Ride Service'**
  String get rideService;

  /// No description provided for @newUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'New update available!'**
  String get newUpdateAvailable;

  /// No description provided for @newUpdateMsg.
  ///
  /// In en, this message translates to:
  /// **'Please update the new app from the store for further access app.'**
  String get newUpdateMsg;

  /// No description provided for @splashMsg.
  ///
  /// In en, this message translates to:
  /// **'40+ Services in single app'**
  String get splashMsg;

  /// No description provided for @obRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Taxi, Bike or Courier'**
  String get obRideTitle;

  /// No description provided for @obRideMsg.
  ///
  /// In en, this message translates to:
  /// **'Request transport services anywhere and anytime. Choose your destination, book a ride, track your ride and enjoy your journey.'**
  String get obRideMsg;

  /// No description provided for @obDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Food, Grocery, Liquor & More'**
  String get obDeliveryTitle;

  /// No description provided for @obDeliveryMsg.
  ///
  /// In en, this message translates to:
  /// **'Now get the store at your doorstep, shop for your daily needs for same-day and get delivery at a convenient time.'**
  String get obDeliveryMsg;

  /// No description provided for @obProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Just Fix Anything'**
  String get obProviderTitle;

  /// No description provided for @obProviderMsg.
  ///
  /// In en, this message translates to:
  /// **'Need a hand for house chores? We\'ve got you covered! Book cleaner, beautician, handyman services and more with few clicks.'**
  String get obProviderMsg;

  /// No description provided for @obMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'And many more'**
  String get obMoreTitle;

  /// No description provided for @obMoreMsg.
  ///
  /// In en, this message translates to:
  /// **'With general configuration, manage app account, wallet transaction, chat & order history, profile setting and more.'**
  String get obMoreMsg;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @onGoing.
  ///
  /// In en, this message translates to:
  /// **'On Going'**
  String get onGoing;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

  /// No description provided for @loginSignUpMsg.
  ///
  /// In en, this message translates to:
  /// **'Join Reen Dugnad — every order gives back to the club'**
  String get loginSignUpMsg;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get loginWithEmail;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signupWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Create Account with Email'**
  String get signupWithEmail;

  /// No description provided for @productBy.
  ///
  /// In en, this message translates to:
  /// **'Product By'**
  String get productBy;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now!'**
  String get registerNow;

  /// No description provided for @registerWith.
  ///
  /// In en, this message translates to:
  /// **'Register with'**
  String get registerWith;

  /// No description provided for @preference.
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get preference;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @preferenceMsg.
  ///
  /// In en, this message translates to:
  /// **'You can change settings later from preference'**
  String get preferenceMsg;

  /// No description provided for @connectWith.
  ///
  /// In en, this message translates to:
  /// **'Connect With'**
  String get connectWith;

  /// No description provided for @loginWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Login with Facebook'**
  String get loginWithFacebook;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @referralCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get referralCodeOptional;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter Full Name'**
  String get enterFullName;

  /// No description provided for @enterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter Email Address'**
  String get enterEmailAddress;

  /// No description provided for @enterEmailOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Email Address or Number'**
  String get enterEmailOrNumber;

  /// No description provided for @enterPass.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPass;

  /// No description provided for @enterConfPass.
  ///
  /// In en, this message translates to:
  /// **'Enter Confirm Password'**
  String get enterConfPass;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number'**
  String get enterMobileNumber;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Email Address'**
  String get invalidEmailAddress;

  /// No description provided for @passShortMsg.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get passShortMsg;

  /// No description provided for @confPassNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password not matched'**
  String get confPassNotMatch;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsCondMsg.
  ///
  /// In en, this message translates to:
  /// **'Check here to acknowledge that you have read and agree to our'**
  String get termsCondMsg;

  /// No description provided for @alreadyAccTitle.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyAccTitle;

  /// No description provided for @loginHere.
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get loginHere;

  /// No description provided for @loginWith.
  ///
  /// In en, this message translates to:
  /// **'Login with'**
  String get loginWith;

  /// No description provided for @startedWithAerend.
  ///
  /// In en, this message translates to:
  /// **'Get Started with Reen Dugnad'**
  String get startedWithAerend;

  /// No description provided for @choosesettingaccount.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to continue setting up your account'**
  String get choosesettingaccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to continue'**
  String get loginToContinue;

  /// No description provided for @acceptTermsCondMsg.
  ///
  /// In en, this message translates to:
  /// **'Accept terms & condition'**
  String get acceptTermsCondMsg;

  /// No description provided for @forgotPassWithQueMark.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassWithQueMark;

  /// No description provided for @orConnectWith.
  ///
  /// In en, this message translates to:
  /// **'Or Connect With'**
  String get orConnectWith;

  /// No description provided for @dontHaveAnAcc.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAcc;

  /// No description provided for @setNewPass.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPass;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @enterCompOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Complete OTP'**
  String get enterCompOtp;

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otp;

  /// No description provided for @requiredInformation.
  ///
  /// In en, this message translates to:
  /// **'Required Information'**
  String get requiredInformation;

  /// No description provided for @accountVerification.
  ///
  /// In en, this message translates to:
  /// **'Account Verification'**
  String get accountVerification;

  /// No description provided for @enterVerfCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerfCode;

  /// No description provided for @enterVerfCodeMsg.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the verification code.'**
  String get enterVerfCodeMsg;

  /// No description provided for @enterOtp1234.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP 1234'**
  String get enterOtp1234;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @editNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Number'**
  String get editNumber;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in'**
  String get resendOtpIn;

  /// No description provided for @resendEmailMsg.
  ///
  /// In en, this message translates to:
  /// **'Still waiting for the SMS verification code?\nClick below button to resend the code.'**
  String get resendEmailMsg;

  /// No description provided for @resendOtpSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Fresh OTP has sent to your registered phone number'**
  String get resendOtpSuccessMsg;

  /// No description provided for @forgotPass.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPass;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @myFavourites.
  ///
  /// In en, this message translates to:
  /// **'My Favourites'**
  String get myFavourites;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @manageAddress.
  ///
  /// In en, this message translates to:
  /// **'Manage Address'**
  String get manageAddress;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signUpText.
  ///
  /// In en, this message translates to:
  /// **'By registering you agree with our'**
  String get signUpText;

  /// No description provided for @termAndConditionUse.
  ///
  /// In en, this message translates to:
  /// **'Term & condition'**
  String get termAndConditionUse;

  /// No description provided for @ofUse.
  ///
  /// In en, this message translates to:
  /// **'of use'**
  String get ofUse;

  /// No description provided for @myCoupons.
  ///
  /// In en, this message translates to:
  /// **'My Coupons'**
  String get myCoupons;

  /// No description provided for @validity.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get validity;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @manageCard.
  ///
  /// In en, this message translates to:
  /// **'Manage Card'**
  String get manageCard;

  /// No description provided for @inviteFriend.
  ///
  /// In en, this message translates to:
  /// **'Invite Friend'**
  String get inviteFriend;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @chatWithAdmin.
  ///
  /// In en, this message translates to:
  /// **'Chat With Admin'**
  String get chatWithAdmin;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logOutDialogTitle;

  /// No description provided for @surgePricing.
  ///
  /// In en, this message translates to:
  /// **'Surge Pricing'**
  String get surgePricing;

  /// No description provided for @ofTotalFare.
  ///
  /// In en, this message translates to:
  /// **'of total fare'**
  String get ofTotalFare;

  /// No description provided for @surgeChargeMsg.
  ///
  /// In en, this message translates to:
  /// **'Peak Pricing Applied In Specific Time Duration'**
  String get surgeChargeMsg;

  /// No description provided for @iAcceptHigherFare.
  ///
  /// In en, this message translates to:
  /// **'I Accept Higher Fare'**
  String get iAcceptHigherFare;

  /// No description provided for @tryLater.
  ///
  /// In en, this message translates to:
  /// **'Try Later'**
  String get tryLater;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get ago;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @allowAccess.
  ///
  /// In en, this message translates to:
  /// **'Please Allow Access'**
  String get allowAccess;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Please Allow \"{appName}\" Access your location\nPlease go to Setting > {appName} > Location'**
  String locationPermission(Object appName);

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @minOrder.
  ///
  /// In en, this message translates to:
  /// **'Min Order'**
  String get minOrder;

  /// No description provided for @noOfferAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Offer available'**
  String get noOfferAvailable;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @sortRestaurantsBy.
  ///
  /// In en, this message translates to:
  /// **'Sort restaurants by'**
  String get sortRestaurantsBy;

  /// No description provided for @sortStoreBy.
  ///
  /// In en, this message translates to:
  /// **'Sort store by'**
  String get sortStoreBy;

  /// No description provided for @costLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Cost Low To High'**
  String get costLowHigh;

  /// No description provided for @costHighLow.
  ///
  /// In en, this message translates to:
  /// **'Cost High To Low'**
  String get costHighLow;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @clearSorting.
  ///
  /// In en, this message translates to:
  /// **'Clear Sorting'**
  String get clearSorting;

  /// No description provided for @addFilter.
  ///
  /// In en, this message translates to:
  /// **'Add Filter'**
  String get addFilter;

  /// No description provided for @filterRestWith.
  ///
  /// In en, this message translates to:
  /// **'Filter Restaurant With'**
  String get filterRestWith;

  /// No description provided for @filterStoreWith.
  ///
  /// In en, this message translates to:
  /// **'Filter Store With'**
  String get filterStoreWith;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @cuisine.
  ///
  /// In en, this message translates to:
  /// **'Cuisine'**
  String get cuisine;

  /// No description provided for @cuisineCategory.
  ///
  /// In en, this message translates to:
  /// **'Cuisine Category'**
  String get cuisineCategory;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Product Category'**
  String get productCategory;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @inSpotLight.
  ///
  /// In en, this message translates to:
  /// **'In Spot Light!'**
  String get inSpotLight;

  /// No description provided for @featuredRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Featured Restaurant'**
  String get featuredRestaurant;

  /// No description provided for @featuredStore.
  ///
  /// In en, this message translates to:
  /// **'Featured Store'**
  String get featuredStore;

  /// No description provided for @featuredGroceryStore.
  ///
  /// In en, this message translates to:
  /// **'Featured Grocery Store'**
  String get featuredGroceryStore;

  /// No description provided for @findService.
  ///
  /// In en, this message translates to:
  /// **'Find Service'**
  String get findService;

  /// No description provided for @contactSalesPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Sales Person'**
  String get contactSalesPerson;

  /// No description provided for @contactSalesPersonMsg.
  ///
  /// In en, this message translates to:
  /// **'Ask for help regarding the app features and sales queries.'**
  String get contactSalesPersonMsg;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocation;

  /// No description provided for @confirmPlace.
  ///
  /// In en, this message translates to:
  /// **'Confirm Place'**
  String get confirmPlace;

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get fetchingLocation;

  /// No description provided for @startTypingRestaurantName.
  ///
  /// In en, this message translates to:
  /// **'Start typing restaurant name...'**
  String get startTypingRestaurantName;

  /// No description provided for @noAnyRestaurantFound.
  ///
  /// In en, this message translates to:
  /// **'No any restaurant found'**
  String get noAnyRestaurantFound;

  /// No description provided for @noAnyDishesFound.
  ///
  /// In en, this message translates to:
  /// **'No any dishes found'**
  String get noAnyDishesFound;

  /// No description provided for @noAnyProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No any products found'**
  String get noAnyProductsFound;

  /// No description provided for @noAnyStoreFound.
  ///
  /// In en, this message translates to:
  /// **'No any store found'**
  String get noAnyStoreFound;

  /// No description provided for @minimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order'**
  String get minimumOrder;

  /// No description provided for @addOns.
  ///
  /// In en, this message translates to:
  /// **'Customizable'**
  String get addOns;

  /// No description provided for @openingHour.
  ///
  /// In en, this message translates to:
  /// **'Opening hour'**
  String get openingHour;

  /// No description provided for @onlyVeg.
  ///
  /// In en, this message translates to:
  /// **'Only Veg'**
  String get onlyVeg;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add To Cart'**
  String get addToCart;

  /// No description provided for @selectCuisine.
  ///
  /// In en, this message translates to:
  /// **'Select Cuisine'**
  String get selectCuisine;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get selectCategories;

  /// No description provided for @updateCart.
  ///
  /// In en, this message translates to:
  /// **'Update Cart'**
  String get updateCart;

  /// No description provided for @updateCartMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to change the Store? Your existing cart will empty.'**
  String get updateCartMsg;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @iWillChoose.
  ///
  /// In en, this message translates to:
  /// **'I\'ll Choose'**
  String get iWillChoose;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @minimumOrderMsg.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order Amount Must Be'**
  String get minimumOrderMsg;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @noReviewMsg.
  ///
  /// In en, this message translates to:
  /// **'No Reviews yet'**
  String get noReviewMsg;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours'**
  String get openingHours;

  /// No description provided for @profileUpdateSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccessfully;

  /// No description provided for @addressDeletedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted address'**
  String get addressDeletedSuccessMsg;

  /// No description provided for @changePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Picture'**
  String get changePicture;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountDelete;

  /// No description provided for @accountDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete the account?'**
  String get accountDeleteMsg;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @rides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get rides;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @onDemandService.
  ///
  /// In en, this message translates to:
  /// **'On Demand Services'**
  String get onDemandService;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get filterUpcoming;

  /// No description provided for @filterLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get filterLast7Days;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get filterThisMonth;

  /// No description provided for @filterYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get filterYear;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @takeAwayOrder.
  ///
  /// In en, this message translates to:
  /// **'Take away order'**
  String get takeAwayOrder;

  /// No description provided for @deliveryOrder.
  ///
  /// In en, this message translates to:
  /// **'Delivery order'**
  String get deliveryOrder;

  /// No description provided for @noAnyAddressMsg.
  ///
  /// In en, this message translates to:
  /// **'You have no added any delivery address please add it from here'**
  String get noAnyAddressMsg;

  /// No description provided for @addAnAddress.
  ///
  /// In en, this message translates to:
  /// **'Add An Address'**
  String get addAnAddress;

  /// No description provided for @changeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change Address'**
  String get changeAddress;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address?'**
  String get deleteAddress;

  /// No description provided for @deleteAddressDialogMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get deleteAddressDialogMsg;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @houseFlatNo.
  ///
  /// In en, this message translates to:
  /// **'House / Flat No.'**
  String get houseFlatNo;

  /// No description provided for @selectLocationMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select location'**
  String get selectLocationMsg;

  /// No description provided for @enterFlatNo.
  ///
  /// In en, this message translates to:
  /// **'Enter flat no'**
  String get enterFlatNo;

  /// No description provided for @enterLandmark.
  ///
  /// In en, this message translates to:
  /// **'Enter landmark'**
  String get enterLandmark;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @enterOldPass.
  ///
  /// In en, this message translates to:
  /// **'Enter Old Password'**
  String get enterOldPass;

  /// No description provided for @enterNewPass.
  ///
  /// In en, this message translates to:
  /// **'Enter New Password'**
  String get enterNewPass;

  /// No description provided for @reEnterPass.
  ///
  /// In en, this message translates to:
  /// **'Re-Enter Password'**
  String get reEnterPass;

  /// No description provided for @passNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Password not match'**
  String get passNotMatch;

  /// No description provided for @confPassNotMatchWithNew.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password not matched with new password'**
  String get confPassNotMatchWithNew;

  /// No description provided for @passChangeSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Your password changed successfully!'**
  String get passChangeSuccessMsg;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @changePasswordMsg.
  ///
  /// In en, this message translates to:
  /// **'Do you want to change your current password?'**
  String get changePasswordMsg;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @viewTransaction.
  ///
  /// In en, this message translates to:
  /// **'View Transaction'**
  String get viewTransaction;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @walletMsg.
  ///
  /// In en, this message translates to:
  /// **'We use secure technology to secure your data'**
  String get walletMsg;

  /// No description provided for @rechargeAmount.
  ///
  /// In en, this message translates to:
  /// **'Recharge Amount'**
  String get rechargeAmount;

  /// No description provided for @selectValidDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid date'**
  String get selectValidDate;

  /// No description provided for @addCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Add Card Details'**
  String get addCardDetails;

  /// No description provided for @cardDateFormat.
  ///
  /// In en, this message translates to:
  /// **'MM/YYYY'**
  String get cardDateFormat;

  /// No description provided for @expiryMonthIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Expiry month is invalid'**
  String get expiryMonthIsInvalid;

  /// No description provided for @expiryYearIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Expiry year is invalid'**
  String get expiryYearIsInvalid;

  /// No description provided for @cardHasExpired.
  ///
  /// In en, this message translates to:
  /// **'Card has expired'**
  String get cardHasExpired;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @cardListEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'No cards available please add new card'**
  String get cardListEmptyMsg;

  /// No description provided for @addCreditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Add Credit/Debit Card'**
  String get addCreditDebitCard;

  /// No description provided for @sureToRemove.
  ///
  /// In en, this message translates to:
  /// **'Are You Sure to Remove?'**
  String get sureToRemove;

  /// No description provided for @removeCardSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Your card removed successfully'**
  String get removeCardSuccessMsg;

  /// No description provided for @safeAndSecurePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Safe and secure payment method'**
  String get safeAndSecurePaymentMethod;

  /// No description provided for @selectCreditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Select Credit/Debit Card'**
  String get selectCreditDebitCard;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Add new Card'**
  String get payment;

  /// No description provided for @hintCardHolderName.
  ///
  /// In en, this message translates to:
  /// **'Card Holder Name'**
  String get hintCardHolderName;

  /// No description provided for @hintYourCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Your Card Number'**
  String get hintYourCardNumber;

  /// No description provided for @hintExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Expiration Date'**
  String get hintExpirationDate;

  /// No description provided for @hintCvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get hintCvv;

  /// No description provided for @enterHolderName.
  ///
  /// In en, this message translates to:
  /// **'Enter Card Holder Name'**
  String get enterHolderName;

  /// No description provided for @enterCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Card Number'**
  String get enterCardNumber;

  /// No description provided for @invalidCard.
  ///
  /// In en, this message translates to:
  /// **'Invalid Card Number'**
  String get invalidCard;

  /// No description provided for @selectCardDate.
  ///
  /// In en, this message translates to:
  /// **'Enter Expiration Date'**
  String get selectCardDate;

  /// No description provided for @enterCvv.
  ///
  /// In en, this message translates to:
  /// **'Enter CVV'**
  String get enterCvv;

  /// No description provided for @invalidCvv.
  ///
  /// In en, this message translates to:
  /// **'Invalid CVV'**
  String get invalidCvv;

  /// No description provided for @buttonAddCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get buttonAddCard;

  /// No description provided for @inviteFriendAnd.
  ///
  /// In en, this message translates to:
  /// **'Refer Friend & Get Benefits'**
  String get inviteFriendAnd;

  /// No description provided for @inviteFriendMessage.
  ///
  /// In en, this message translates to:
  /// **'Invite Your Friend With This Referral Code To Get More Benefits'**
  String get inviteFriendMessage;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Invite Code'**
  String get shareCode;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @referCodeGetDiscount.
  ///
  /// In en, this message translates to:
  /// **'Referral Code and get Discount'**
  String get referCodeGetDiscount;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @findForFoodAndRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Find for Food and Restaurant'**
  String get findForFoodAndRestaurant;

  /// No description provided for @findForProductsAndStore.
  ///
  /// In en, this message translates to:
  /// **'Find for Products and Store'**
  String get findForProductsAndStore;

  /// No description provided for @takeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get takeaway;

  /// No description provided for @filterYourSearch.
  ///
  /// In en, this message translates to:
  /// **'Filter Your Store'**
  String get filterYourSearch;

  /// No description provided for @filterRestaurantWith.
  ///
  /// In en, this message translates to:
  /// **'Filter Restaurant With'**
  String get filterRestaurantWith;

  /// No description provided for @filterOrderDelivery.
  ///
  /// In en, this message translates to:
  /// **'Order Delivery'**
  String get filterOrderDelivery;

  /// No description provided for @favoriteRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Favorite Restaurant'**
  String get favoriteRestaurant;

  /// No description provided for @favoriteStore.
  ///
  /// In en, this message translates to:
  /// **'Favorite Store'**
  String get favoriteStore;

  /// No description provided for @filterOrderTakeAway.
  ///
  /// In en, this message translates to:
  /// **'Order Takeaway'**
  String get filterOrderTakeAway;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price High To Low'**
  String get priceHighToLow;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price Low To High'**
  String get priceLowToHigh;

  /// No description provided for @nearBy.
  ///
  /// In en, this message translates to:
  /// **'Near By'**
  String get nearBy;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @dishes.
  ///
  /// In en, this message translates to:
  /// **'Dishes'**
  String get dishes;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @searchForFood.
  ///
  /// In en, this message translates to:
  /// **'Search For Food'**
  String get searchForFood;

  /// No description provided for @searchForProducts.
  ///
  /// In en, this message translates to:
  /// **'Search For Products'**
  String get searchForProducts;

  /// No description provided for @searchForRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Search For Restaurants'**
  String get searchForRestaurants;

  /// No description provided for @searchForStore.
  ///
  /// In en, this message translates to:
  /// **'Search For Store'**
  String get searchForStore;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get additionalInfo;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID #'**
  String get bookingId;

  /// No description provided for @cancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get cancelReason;

  /// No description provided for @itemTotal.
  ///
  /// In en, this message translates to:
  /// **'Item Total'**
  String get itemTotal;

  /// No description provided for @deliveryCharges.
  ///
  /// In en, this message translates to:
  /// **'Delivery Charges'**
  String get deliveryCharges;

  /// No description provided for @packingCharges.
  ///
  /// In en, this message translates to:
  /// **'Packing Charges'**
  String get packingCharges;

  /// No description provided for @offerDiscount.
  ///
  /// In en, this message translates to:
  /// **'Offer Discount'**
  String get offerDiscount;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To Pay'**
  String get toPay;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @giveReview.
  ///
  /// In en, this message translates to:
  /// **'Give Review'**
  String get giveReview;

  /// No description provided for @ratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate from 1 to 5 star'**
  String get ratingTitle;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @writeReviewHere.
  ///
  /// In en, this message translates to:
  /// **'Write your review here'**
  String get writeReviewHere;

  /// No description provided for @commentHere.
  ///
  /// In en, this message translates to:
  /// **'Comment here…'**
  String get commentHere;

  /// No description provided for @deliveryPerson.
  ///
  /// In en, this message translates to:
  /// **'Delivery Person'**
  String get deliveryPerson;

  /// No description provided for @giveReviewToAnyOne.
  ///
  /// In en, this message translates to:
  /// **'Please give your review to the store & delivery person'**
  String get giveReviewToAnyOne;

  /// No description provided for @giveReviewToStore.
  ///
  /// In en, this message translates to:
  /// **'Please select review to store'**
  String get giveReviewToStore;

  /// No description provided for @giveReviewToProvider.
  ///
  /// In en, this message translates to:
  /// **'Please give review to provider'**
  String get giveReviewToProvider;

  /// No description provided for @giveReviewToDriver.
  ///
  /// In en, this message translates to:
  /// **'Please Give Review to Driver '**
  String get giveReviewToDriver;

  /// No description provided for @giveReviewToBoth.
  ///
  /// In en, this message translates to:
  /// **'Please select review to both'**
  String get giveReviewToBoth;

  /// No description provided for @cartDetail.
  ///
  /// In en, this message translates to:
  /// **'Cart Detail'**
  String get cartDetail;

  /// No description provided for @applyPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Apply Promo Code'**
  String get applyPromoCode;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @scheduleOrder.
  ///
  /// In en, this message translates to:
  /// **'Schedule Order'**
  String get scheduleOrder;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get promoCode;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Promo Code'**
  String get enterPromoCode;

  /// No description provided for @availablePromoCode.
  ///
  /// In en, this message translates to:
  /// **'Available Promo Code'**
  String get availablePromoCode;

  /// No description provided for @promoCodeListNullMsg.
  ///
  /// In en, this message translates to:
  /// **'No Promo Code Available for This account'**
  String get promoCodeListNullMsg;

  /// No description provided for @cartEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty please add new items.'**
  String get cartEmptyMsg;

  /// No description provided for @addOrSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please add or select address'**
  String get addOrSelectAddress;

  /// No description provided for @addDeliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Delivery Location'**
  String get addDeliveryLocation;

  /// No description provided for @landmarkOptional.
  ///
  /// In en, this message translates to:
  /// **'Landmark (Optional)'**
  String get landmarkOptional;

  /// No description provided for @flatNoHouseNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Flat No.,House Name (Optional)'**
  String get flatNoHouseNameOptional;

  /// No description provided for @doYouWant.
  ///
  /// In en, this message translates to:
  /// **'I would like to'**
  String get doYouWant;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @invalidScheduleTime.
  ///
  /// In en, this message translates to:
  /// **'Please select time after one hour from now'**
  String get invalidScheduleTime;

  /// No description provided for @unavailableProductMess.
  ///
  /// In en, this message translates to:
  /// **'Some products are no more available on the store. We will remove it from the cart'**
  String get unavailableProductMess;

  /// No description provided for @prescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Prescription Required'**
  String get prescriptionRequired;

  /// No description provided for @additionNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional instructions for'**
  String get additionNotes;

  /// No description provided for @addTipToDriver.
  ///
  /// In en, this message translates to:
  /// **'Add tip to driver'**
  String get addTipToDriver;

  /// No description provided for @requiredMess.
  ///
  /// In en, this message translates to:
  /// **'Please enter the below details.'**
  String get requiredMess;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// No description provided for @orderPlacedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your Order is Placed And Will Be Deliver Soon'**
  String get orderPlacedMsg;

  /// No description provided for @orderPickupMsg.
  ///
  /// In en, this message translates to:
  /// **'Your order was placed, wait until restaurant complete order and then go to pickup your order'**
  String get orderPickupMsg;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYou;

  /// No description provided for @addNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCard;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @selectAnyCardMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select any card'**
  String get selectAnyCardMsg;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCard;

  /// No description provided for @creditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit Card'**
  String get creditDebitCard;

  /// No description provided for @insufficientWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'You can\'t pay order amount through Wallet because your wallet balance is insufficient.'**
  String get insufficientWalletBalance;

  /// No description provided for @chatHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chat history…'**
  String get chatHistoryEmpty;

  /// No description provided for @startTyping.
  ///
  /// In en, this message translates to:
  /// **'Start Typing...'**
  String get startTyping;

  /// No description provided for @writeAMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Write a message here...'**
  String get writeAMessageHere;

  /// No description provided for @orderPlacedMsgTo.
  ///
  /// In en, this message translates to:
  /// **'Your Order Awaiting for store approval.'**
  String get orderPlacedMsgTo;

  /// No description provided for @orderProcessingMsg.
  ///
  /// In en, this message translates to:
  /// **'Your order has been processing'**
  String get orderProcessingMsg;

  /// No description provided for @orderReadyForPickupMsg.
  ///
  /// In en, this message translates to:
  /// **'Your order has been ready for pickup'**
  String get orderReadyForPickupMsg;

  /// No description provided for @orderPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Order Picked up'**
  String get orderPickedUp;

  /// No description provided for @orderReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get orderReadyForPickup;

  /// No description provided for @acceptedByStore.
  ///
  /// In en, this message translates to:
  /// **'Accepted By Store'**
  String get acceptedByStore;

  /// No description provided for @acceptedByDeliveryMan.
  ///
  /// In en, this message translates to:
  /// **'Accepted By Delivery Man'**
  String get acceptedByDeliveryMan;

  /// No description provided for @orderPickUp.
  ///
  /// In en, this message translates to:
  /// **'Order Pick up'**
  String get orderPickUp;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @confirmYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Order'**
  String get confirmYourOrder;

  /// No description provided for @yourOrderAcceptedBy.
  ///
  /// In en, this message translates to:
  /// **'Your order accepted by'**
  String get yourOrderAcceptedBy;

  /// No description provided for @orderPickUpBy.
  ///
  /// In en, this message translates to:
  /// **'Your order pick up by'**
  String get orderPickUpBy;

  /// No description provided for @deliveredMsg.
  ///
  /// In en, this message translates to:
  /// **'Your order has been delivered'**
  String get deliveredMsg;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @enterCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Provide Cancellation Reason'**
  String get enterCancelReason;

  /// No description provided for @orderCancelMsg.
  ///
  /// In en, this message translates to:
  /// **'There will be a cancellation charge of'**
  String get orderCancelMsg;

  /// No description provided for @orderCancelMsg1.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue?'**
  String get orderCancelMsg1;

  /// No description provided for @cancellationCharge.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Charge'**
  String get cancellationCharge;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get km;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @trackLocation.
  ///
  /// In en, this message translates to:
  /// **'Track Location'**
  String get trackLocation;

  /// No description provided for @rideFare.
  ///
  /// In en, this message translates to:
  /// **'Ride Fare'**
  String get rideFare;

  /// No description provided for @subTotal.
  ///
  /// In en, this message translates to:
  /// **'Sub Total'**
  String get subTotal;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @selectPickupDateMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select the first pickup date & time'**
  String get selectPickupDateMsg;

  /// No description provided for @invalidPickupDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select pickup date & time at least one hour from now.'**
  String get invalidPickupDateTime;

  /// No description provided for @invalidDropDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select drop date & time at least one hour from pickup.'**
  String get invalidDropDateTime;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @giveYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give your feedback !'**
  String get giveYourFeedback;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @cancelBy.
  ///
  /// In en, this message translates to:
  /// **'Cancel by'**
  String get cancelBy;

  /// No description provided for @courierDetail.
  ///
  /// In en, this message translates to:
  /// **'Courier Details'**
  String get courierDetail;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get contactName;

  /// No description provided for @houseNameLandmark.
  ///
  /// In en, this message translates to:
  /// **'House Name/Landmark'**
  String get houseNameLandmark;

  /// No description provided for @goodsDimensionInCM.
  ///
  /// In en, this message translates to:
  /// **'Item Dimension (cm)'**
  String get goodsDimensionInCM;

  /// No description provided for @goodsWeightInKG.
  ///
  /// In en, this message translates to:
  /// **'Item Weight (kg)'**
  String get goodsWeightInKG;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get kg;

  /// No description provided for @above.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get above;

  /// No description provided for @weightUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get weightUp;

  /// No description provided for @weightTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get weightTo;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Item Description'**
  String get itemDescription;

  /// No description provided for @deliveryInstruction.
  ///
  /// In en, this message translates to:
  /// **'Delivery Instructions'**
  String get deliveryInstruction;

  /// No description provided for @pickUpDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Pick up Date & Time'**
  String get pickUpDateAndTime;

  /// No description provided for @timeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time Taken'**
  String get timeTaken;

  /// No description provided for @costPerKm.
  ///
  /// In en, this message translates to:
  /// **'Cost Per Km'**
  String get costPerKm;

  /// No description provided for @distanceFare.
  ///
  /// In en, this message translates to:
  /// **'Distance Fare'**
  String get distanceFare;

  /// No description provided for @serviceFare.
  ///
  /// In en, this message translates to:
  /// **'Service Fare'**
  String get serviceFare;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @baseFare.
  ///
  /// In en, this message translates to:
  /// **'Base Fare'**
  String get baseFare;

  /// No description provided for @timeFare.
  ///
  /// In en, this message translates to:
  /// **'Time Fare'**
  String get timeFare;

  /// No description provided for @referDiscount.
  ///
  /// In en, this message translates to:
  /// **'Referral Discount'**
  String get referDiscount;

  /// No description provided for @minAdjustAmt.
  ///
  /// In en, this message translates to:
  /// **'Min Adjustment Amount'**
  String get minAdjustAmt;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @senderDetail.
  ///
  /// In en, this message translates to:
  /// **'Sender Detail'**
  String get senderDetail;

  /// No description provided for @receiverDetail.
  ///
  /// In en, this message translates to:
  /// **'Receiver Detail'**
  String get receiverDetail;

  /// No description provided for @flatNo.
  ///
  /// In en, this message translates to:
  /// **'Flat No.'**
  String get flatNo;

  /// No description provided for @additionalRemark.
  ///
  /// In en, this message translates to:
  /// **'Additional Remarks'**
  String get additionalRemark;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @shoppingCharges.
  ///
  /// In en, this message translates to:
  /// **'Shopping Charges'**
  String get shoppingCharges;

  /// No description provided for @addTip.
  ///
  /// In en, this message translates to:
  /// **'Add Tip'**
  String get addTip;

  /// No description provided for @enterTipAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Tip Amount'**
  String get enterTipAmount;

  /// No description provided for @addMoneyToWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Money to Wallet'**
  String get addMoneyToWallet;

  /// No description provided for @payByCard.
  ///
  /// In en, this message translates to:
  /// **'Pay By Card'**
  String get payByCard;

  /// No description provided for @payByWallet.
  ///
  /// In en, this message translates to:
  /// **'Pay By Wallet'**
  String get payByWallet;

  /// No description provided for @processToAdd.
  ///
  /// In en, this message translates to:
  /// **'Process To Add'**
  String get processToAdd;

  /// No description provided for @dummyCardNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Add card number 4111 1111 1111 1111 OR 4242 4242 4242 4242'**
  String get dummyCardNote;

  /// No description provided for @panic.
  ///
  /// In en, this message translates to:
  /// **'Panic'**
  String get panic;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @callStore.
  ///
  /// In en, this message translates to:
  /// **'Call Store'**
  String get callStore;

  /// No description provided for @callDriver.
  ///
  /// In en, this message translates to:
  /// **'Call Driver'**
  String get callDriver;

  /// No description provided for @emergencyContactAddMessage.
  ///
  /// In en, this message translates to:
  /// **'Please Add Emergency Contact Number!'**
  String get emergencyContactAddMessage;

  /// No description provided for @emergencyContactAddMessage1.
  ///
  /// In en, this message translates to:
  /// **'You can change the emergency contact number from your profile'**
  String get emergencyContactAddMessage1;

  /// No description provided for @noEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'No Emergency Contact!'**
  String get noEmergencyContact;

  /// No description provided for @addEmergencyContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact Number'**
  String get addEmergencyContactNumber;

  /// No description provided for @emergencyCall.
  ///
  /// In en, this message translates to:
  /// **'Emergency Call'**
  String get emergencyCall;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @plsSelectPickLoc.
  ///
  /// In en, this message translates to:
  /// **'Please Select Pickup Location'**
  String get plsSelectPickLoc;

  /// No description provided for @plsSelectDestLoc.
  ///
  /// In en, this message translates to:
  /// **'Please Select Destination Location'**
  String get plsSelectDestLoc;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @addDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Delivery Address'**
  String get addDeliveryAddress;

  /// No description provided for @rideNow.
  ///
  /// In en, this message translates to:
  /// **'Ride Now'**
  String get rideNow;

  /// No description provided for @scheduleRide.
  ///
  /// In en, this message translates to:
  /// **'Schedule Ride'**
  String get scheduleRide;

  /// No description provided for @changePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Change Payment Method'**
  String get changePaymentMethod;

  /// No description provided for @selectPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Select Promo Code'**
  String get selectPromoCode;

  /// No description provided for @promoCodeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'No available Promo Code!'**
  String get promoCodeNotAvailable;

  /// No description provided for @doYouWantToCancel.
  ///
  /// In en, this message translates to:
  /// **'Do you want to cancel?'**
  String get doYouWantToCancel;

  /// No description provided for @findDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding Driver'**
  String get findDriver;

  /// No description provided for @notFindDriver.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t Find Driver'**
  String get notFindDriver;

  /// No description provided for @findDriverMsg.
  ///
  /// In en, this message translates to:
  /// **'We are finding driver. Please Wait'**
  String get findDriverMsg;

  /// No description provided for @notFindDriverMsg.
  ///
  /// In en, this message translates to:
  /// **'We do not have the available driver in this area please try again'**
  String get notFindDriverMsg;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @pickUpLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickUpLocation;

  /// No description provided for @dropLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop Location'**
  String get dropLocation;

  /// No description provided for @dropDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Drop Date & Time'**
  String get dropDateAndTime;

  /// No description provided for @selectPickupTime.
  ///
  /// In en, this message translates to:
  /// **'Please select pickup date & time'**
  String get selectPickupTime;

  /// No description provided for @selectDropTime.
  ///
  /// In en, this message translates to:
  /// **'Please select drop date & time'**
  String get selectDropTime;

  /// No description provided for @process.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process;

  /// No description provided for @courierDelivery.
  ///
  /// In en, this message translates to:
  /// **'Courier Delivery'**
  String get courierDelivery;

  /// No description provided for @sendAnyThing.
  ///
  /// In en, this message translates to:
  /// **'Send Anything'**
  String get sendAnyThing;

  /// No description provided for @createOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Order'**
  String get createOrder;

  /// No description provided for @listIllegalItem.
  ///
  /// In en, this message translates to:
  /// **'List of illegal and non-essential items'**
  String get listIllegalItem;

  /// No description provided for @pickUpInformation.
  ///
  /// In en, this message translates to:
  /// **'Pickup information'**
  String get pickUpInformation;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @packageDetail.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packageDetail;

  /// No description provided for @packageWeight.
  ///
  /// In en, this message translates to:
  /// **'Package Weight'**
  String get packageWeight;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated Value'**
  String get estimatedValue;

  /// No description provided for @pickupDetail.
  ///
  /// In en, this message translates to:
  /// **'Pickup Details'**
  String get pickupDetail;

  /// No description provided for @shopBuildingName.
  ///
  /// In en, this message translates to:
  /// **'Shop name/Building name'**
  String get shopBuildingName;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @deliveryDetail.
  ///
  /// In en, this message translates to:
  /// **'Delivery Detail'**
  String get deliveryDetail;

  /// No description provided for @packageInformation.
  ///
  /// In en, this message translates to:
  /// **'Package Information'**
  String get packageInformation;

  /// No description provided for @selectPackageType.
  ///
  /// In en, this message translates to:
  /// **'Select Package Type'**
  String get selectPackageType;

  /// No description provided for @wantSend.
  ///
  /// In en, this message translates to:
  /// **'I want to send'**
  String get wantSend;

  /// No description provided for @estimatedValueOptional.
  ///
  /// In en, this message translates to:
  /// **'Estimated value (Optional)'**
  String get estimatedValueOptional;

  /// No description provided for @enterDeliveryInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter delivery instruction'**
  String get enterDeliveryInstruction;

  /// No description provided for @notSending.
  ///
  /// In en, this message translates to:
  /// **'i am not sending '**
  String get notSending;

  /// No description provided for @illegalItem.
  ///
  /// In en, this message translates to:
  /// **'illegal items'**
  String get illegalItem;

  /// No description provided for @selectPackageWeight.
  ///
  /// In en, this message translates to:
  /// **'Select Package Weight'**
  String get selectPackageWeight;

  /// No description provided for @enterPickUpLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter Pickup Location'**
  String get enterPickUpLocation;

  /// No description provided for @enterShopBuildingName.
  ///
  /// In en, this message translates to:
  /// **'Enter Shop/Building name'**
  String get enterShopBuildingName;

  /// No description provided for @enterHouseLandmark.
  ///
  /// In en, this message translates to:
  /// **'Enter House name/Landmark'**
  String get enterHouseLandmark;

  /// No description provided for @senderName.
  ///
  /// In en, this message translates to:
  /// **'Sender Name'**
  String get senderName;

  /// No description provided for @enterSenderName.
  ///
  /// In en, this message translates to:
  /// **'Enter Sender Name'**
  String get enterSenderName;

  /// No description provided for @senderContactNum.
  ///
  /// In en, this message translates to:
  /// **'Sender Contact Number'**
  String get senderContactNum;

  /// No description provided for @enterSenderContactNum.
  ///
  /// In en, this message translates to:
  /// **'Enter Sender Contact Number'**
  String get enterSenderContactNum;

  /// No description provided for @receiverInformation.
  ///
  /// In en, this message translates to:
  /// **'Receiver Information'**
  String get receiverInformation;

  /// No description provided for @enterDropLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter Drop Location'**
  String get enterDropLocation;

  /// No description provided for @receiverName.
  ///
  /// In en, this message translates to:
  /// **'Receiver Name'**
  String get receiverName;

  /// No description provided for @enterReceiverName.
  ///
  /// In en, this message translates to:
  /// **'Enter Receiver Name'**
  String get enterReceiverName;

  /// No description provided for @enterReceiverContactNum.
  ///
  /// In en, this message translates to:
  /// **'Enter Receiver Contact Number'**
  String get enterReceiverContactNum;

  /// No description provided for @receiverContactNum.
  ///
  /// In en, this message translates to:
  /// **'Receiver Contact Number'**
  String get receiverContactNum;

  /// No description provided for @illegalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that you do not send illegal items.'**
  String get illegalConfirmation;

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemDetails;

  /// No description provided for @itemHeightInCM.
  ///
  /// In en, this message translates to:
  /// **'Item Height (cm)'**
  String get itemHeightInCM;

  /// No description provided for @itemWidthInCM.
  ///
  /// In en, this message translates to:
  /// **'Item Width (cm)'**
  String get itemWidthInCM;

  /// No description provided for @enterContactName.
  ///
  /// In en, this message translates to:
  /// **'Enter Contact Name'**
  String get enterContactName;

  /// No description provided for @enterHouseOrLandmarkName.
  ///
  /// In en, this message translates to:
  /// **'Enter House or Landmark Name'**
  String get enterHouseOrLandmarkName;

  /// No description provided for @invalidContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid Contact Number'**
  String get invalidContactNumber;

  /// No description provided for @enterGoodsWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter Item Weight'**
  String get enterGoodsWeight;

  /// No description provided for @enterGoodsWidth.
  ///
  /// In en, this message translates to:
  /// **'Enter Item Width'**
  String get enterGoodsWidth;

  /// No description provided for @enterGoodsHeight.
  ///
  /// In en, this message translates to:
  /// **'Enter Item Height'**
  String get enterGoodsHeight;

  /// No description provided for @enterGoodsLength.
  ///
  /// In en, this message translates to:
  /// **'Enter Item Length'**
  String get enterGoodsLength;

  /// No description provided for @enRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get enRoute;

  /// No description provided for @enterCourierDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter Item Description'**
  String get enterCourierDescription;

  /// No description provided for @goodsEg.
  ///
  /// In en, this message translates to:
  /// **'( Documents, Personal Items, etc. )'**
  String get goodsEg;

  /// No description provided for @your.
  ///
  /// In en, this message translates to:
  /// **'Your'**
  String get your;

  /// No description provided for @goodsNotMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'not match as per vehicle. You can add max'**
  String get goodsNotMatchMessage;

  /// No description provided for @itemHeight.
  ///
  /// In en, this message translates to:
  /// **'Item Height'**
  String get itemHeight;

  /// No description provided for @itemWidth.
  ///
  /// In en, this message translates to:
  /// **'Item Width'**
  String get itemWidth;

  /// No description provided for @itemWeight.
  ///
  /// In en, this message translates to:
  /// **'Item Weight'**
  String get itemWeight;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Proceed To Pay'**
  String get proceedToPay;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'km away'**
  String get kmAway;

  /// No description provided for @arriving.
  ///
  /// In en, this message translates to:
  /// **'Arriving'**
  String get arriving;

  /// No description provided for @cancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride'**
  String get cancelRide;

  /// No description provided for @cancelRideMsg.
  ///
  /// In en, this message translates to:
  /// **'Ride Cancelled by Driver'**
  String get cancelRideMsg;

  /// No description provided for @vehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformation;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Color'**
  String get vehicleColor;

  /// No description provided for @vehicleManufactureName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Manufacture Name'**
  String get vehicleManufactureName;

  /// No description provided for @vehicleModelName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model'**
  String get vehicleModelName;

  /// No description provided for @vehicleModelYear.
  ///
  /// In en, this message translates to:
  /// **'Model Year'**
  String get vehicleModelYear;

  /// No description provided for @vehiclePlatNo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Plate Number'**
  String get vehiclePlatNo;

  /// No description provided for @vehicleNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Currently vehicle is not available'**
  String get vehicleNotAvailable;

  /// No description provided for @weightLimit.
  ///
  /// In en, this message translates to:
  /// **'Weight Limit (In kg)'**
  String get weightLimit;

  /// No description provided for @dimensionLimit.
  ///
  /// In en, this message translates to:
  /// **'Dimension Limit (In cm)'**
  String get dimensionLimit;

  /// No description provided for @walletAddSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Wallet amount added successfully'**
  String get walletAddSuccessful;

  /// No description provided for @cardAddSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Card added successfully'**
  String get cardAddSuccessful;

  /// No description provided for @apiMsg52.
  ///
  /// In en, this message translates to:
  /// **'Order Rejected by Store'**
  String get apiMsg52;

  /// No description provided for @apiMsg109.
  ///
  /// In en, this message translates to:
  /// **'Not enough wallet balance. Please add money to wallet or use credit card.'**
  String get apiMsg109;

  /// No description provided for @apiMsg157.
  ///
  /// In en, this message translates to:
  /// **'The added products are not available at the moment!'**
  String get apiMsg157;

  /// No description provided for @apiMsg204.
  ///
  /// In en, this message translates to:
  /// **'Selected packages not available at this moment!'**
  String get apiMsg204;

  /// No description provided for @apiErrorCancelMsg.
  ///
  /// In en, this message translates to:
  /// **'Request to API server was cancelled'**
  String get apiErrorCancelMsg;

  /// No description provided for @apiErrorConnectTimeoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout with API server'**
  String get apiErrorConnectTimeoutMsg;

  /// No description provided for @apiErrorOtherMsg.
  ///
  /// In en, this message translates to:
  /// **'You are offline please check your internet connection.'**
  String get apiErrorOtherMsg;

  /// No description provided for @apiErrorReceiveTimeoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Receive timeout in connection with API server'**
  String get apiErrorReceiveTimeoutMsg;

  /// No description provided for @apiErrorResponseMsg.
  ///
  /// In en, this message translates to:
  /// **'Received invalid status code'**
  String get apiErrorResponseMsg;

  /// No description provided for @apiErrorSendTimeoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Send timeout in connection with API server'**
  String get apiErrorSendTimeoutMsg;

  /// No description provided for @apiErrorUnexpectedErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get apiErrorUnexpectedErrorMsg;

  /// No description provided for @apiErrorCommunicationMsg.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while Communication with Server with StatusCode'**
  String get apiErrorCommunicationMsg;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @firstNameReq.
  ///
  /// In en, this message translates to:
  /// **'First Name*'**
  String get firstNameReq;

  /// No description provided for @lastNameReq.
  ///
  /// In en, this message translates to:
  /// **'Last Name*'**
  String get lastNameReq;

  /// No description provided for @emailAddressReq.
  ///
  /// In en, this message translates to:
  /// **'Email Address*'**
  String get emailAddressReq;

  /// No description provided for @passReq.
  ///
  /// In en, this message translates to:
  /// **'Password*'**
  String get passReq;

  /// No description provided for @confPassReq.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password*'**
  String get confPassReq;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter First Name'**
  String get enterFirstName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter Last Name'**
  String get enterLastName;

  /// No description provided for @closeStore.
  ///
  /// In en, this message translates to:
  /// **'We are still close, comeback later…'**
  String get closeStore;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get close;

  /// No description provided for @sureToCancel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to cancel this order?'**
  String get sureToCancel;

  /// No description provided for @packagingCharge.
  ///
  /// In en, this message translates to:
  /// **'Packaging Charge'**
  String get packagingCharge;

  /// No description provided for @bikeDriverArrivedMsg.
  ///
  /// In en, this message translates to:
  /// **'Bike Driver arrived at your pickup location.'**
  String get bikeDriverArrivedMsg;

  /// No description provided for @bikeRideStartedMsg.
  ///
  /// In en, this message translates to:
  /// **'Bike Driver started your ride.'**
  String get bikeRideStartedMsg;

  /// No description provided for @bikeRideFinishMsg.
  ///
  /// In en, this message translates to:
  /// **'Bike Driver completed your ride.\nPlease check your drop location.'**
  String get bikeRideFinishMsg;

  /// No description provided for @bikeRideSuccessfullyFinishedMsg.
  ///
  /// In en, this message translates to:
  /// **'Current trip is successfully finished.\nVisit again!'**
  String get bikeRideSuccessfullyFinishedMsg;

  /// No description provided for @courierDriverArrived.
  ///
  /// In en, this message translates to:
  /// **'Delivery Person Arrived'**
  String get courierDriverArrived;

  /// No description provided for @courierDriverArrivedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {appName} Delivery Person arrived at your pickup location'**
  String courierDriverArrivedMsg(Object appName);

  /// No description provided for @courierDeliveryStarted.
  ///
  /// In en, this message translates to:
  /// **'Delivery Started'**
  String get courierDeliveryStarted;

  /// No description provided for @courierDeliveryStartedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {appName} Delivery Has Begun'**
  String courierDeliveryStartedMsg(Object appName);

  /// No description provided for @courierDeliveryFinish.
  ///
  /// In en, this message translates to:
  /// **'Delivery Completed'**
  String get courierDeliveryFinish;

  /// No description provided for @courierDeliveryFinishMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {appName} Delivery Person Delivered Your\nCourier items to recipient'**
  String courierDeliveryFinishMsg(Object appName);

  /// No description provided for @courierRideSuccessfullyFinished.
  ///
  /// In en, this message translates to:
  /// **'Successfully Completed'**
  String get courierRideSuccessfullyFinished;

  /// No description provided for @courierRideSuccessfullyFinishedMsg.
  ///
  /// In en, this message translates to:
  /// **'Current Delivery Is Successfully Finished'**
  String get courierRideSuccessfullyFinishedMsg;

  /// No description provided for @searchByContactOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by Contact or Email'**
  String get searchByContactOrEmail;

  /// No description provided for @enterContactOrEmailToSearchPerson.
  ///
  /// In en, this message translates to:
  /// **'Please enter the contact number or email to search for the person.'**
  String get enterContactOrEmailToSearchPerson;

  /// No description provided for @beneficial.
  ///
  /// In en, this message translates to:
  /// **'Beneficial'**
  String get beneficial;

  /// No description provided for @beneficialContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Beneficial contact number'**
  String get beneficialContactNumber;

  /// No description provided for @beneficialEmail.
  ///
  /// In en, this message translates to:
  /// **'Beneficial email'**
  String get beneficialEmail;

  /// No description provided for @amountToTransfer.
  ///
  /// In en, this message translates to:
  /// **'Amount to transfer'**
  String get amountToTransfer;

  /// No description provided for @selectUser.
  ///
  /// In en, this message translates to:
  /// **'Select User'**
  String get selectUser;

  /// No description provided for @youCantTransfer.
  ///
  /// In en, this message translates to:
  /// **'You can\'t transfer more than'**
  String get youCantTransfer;

  /// No description provided for @youHave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get youHave;

  /// No description provided for @toTransfer.
  ///
  /// In en, this message translates to:
  /// **'to transfer'**
  String get toTransfer;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @successTransaction.
  ///
  /// In en, this message translates to:
  /// **'You have successfully transferred'**
  String get successTransaction;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select Day'**
  String get selectDay;

  /// No description provided for @selectServiceTime.
  ///
  /// In en, this message translates to:
  /// **'Select Service Time'**
  String get selectServiceTime;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @atProviderLocation.
  ///
  /// In en, this message translates to:
  /// **'At provider location'**
  String get atProviderLocation;

  /// No description provided for @atYourLocation.
  ///
  /// In en, this message translates to:
  /// **'At your location'**
  String get atYourLocation;

  /// No description provided for @serviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Service location'**
  String get serviceLocation;

  /// No description provided for @routeToProvider.
  ///
  /// In en, this message translates to:
  /// **'En-route to provider'**
  String get routeToProvider;

  /// No description provided for @providerAddress.
  ///
  /// In en, this message translates to:
  /// **'Provider Address'**
  String get providerAddress;

  /// No description provided for @serviceTime.
  ///
  /// In en, this message translates to:
  /// **'Service Time'**
  String get serviceTime;

  /// No description provided for @filterOrder.
  ///
  /// In en, this message translates to:
  /// **'Order Filter'**
  String get filterOrder;

  /// No description provided for @courierAnything.
  ///
  /// In en, this message translates to:
  /// **'Courier/Deliver Anything'**
  String get courierAnything;

  /// No description provided for @iWant.
  ///
  /// In en, this message translates to:
  /// **'I Want'**
  String get iWant;

  /// No description provided for @transportMyItem.
  ///
  /// In en, this message translates to:
  /// **'Transport my parcel'**
  String get transportMyItem;

  /// No description provided for @purchaseDeliver.
  ///
  /// In en, this message translates to:
  /// **'Purchase & Deliver'**
  String get purchaseDeliver;

  /// No description provided for @itemToPurchase.
  ///
  /// In en, this message translates to:
  /// **'Items to purchase'**
  String get itemToPurchase;

  /// No description provided for @amountToPayAtShop.
  ///
  /// In en, this message translates to:
  /// **'Amount to pay at shop'**
  String get amountToPayAtShop;

  /// No description provided for @goodsWeight.
  ///
  /// In en, this message translates to:
  /// **'Goods Weight'**
  String get goodsWeight;

  /// No description provided for @whatIsParcelGoods.
  ///
  /// In en, this message translates to:
  /// **'What is the parcel/goods?'**
  String get whatIsParcelGoods;

  /// No description provided for @cashOnDeliery.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get cashOnDeliery;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @enterItemName.
  ///
  /// In en, this message translates to:
  /// **'Enter item name'**
  String get enterItemName;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemName;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @enterQty.
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enterQty;

  /// No description provided for @addMoreItem.
  ///
  /// In en, this message translates to:
  /// **'Add more item'**
  String get addMoreItem;

  /// No description provided for @houseName.
  ///
  /// In en, this message translates to:
  /// **'House Name'**
  String get houseName;

  /// No description provided for @enterHouseName.
  ///
  /// In en, this message translates to:
  /// **'Enter House Name'**
  String get enterHouseName;

  /// No description provided for @surgeCharge.
  ///
  /// In en, this message translates to:
  /// **'Surge charge'**
  String get surgeCharge;

  /// No description provided for @giveRatingMsg.
  ///
  /// In en, this message translates to:
  /// **'Share your ride experience and give your driver a rating.'**
  String get giveRatingMsg;

  /// No description provided for @successfullyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Successfully Completed'**
  String get successfullyCompleted;

  /// No description provided for @deliveryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delivery Completed'**
  String get deliveryCompleted;

  /// No description provided for @followMeAt.
  ///
  /// In en, this message translates to:
  /// **'Follow me at {appName}'**
  String followMeAt(Object appName);

  /// No description provided for @shareExperience.
  ///
  /// In en, this message translates to:
  /// **'Share Your Ride Experience'**
  String get shareExperience;

  /// No description provided for @rateDriverStar.
  ///
  /// In en, this message translates to:
  /// **'Rate Driver from 1 to 5 star'**
  String get rateDriverStar;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get writeReview;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter Reason'**
  String get enterReason;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @trackRide.
  ///
  /// In en, this message translates to:
  /// **'Track Ride'**
  String get trackRide;

  /// No description provided for @goodsWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get goodsWidth;

  /// No description provided for @goodsHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get goodsHeight;

  /// No description provided for @goodsLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get goodsLength;

  /// No description provided for @estimatedPriceOfItem.
  ///
  /// In en, this message translates to:
  /// **'Estimated price of item'**
  String get estimatedPriceOfItem;

  /// No description provided for @estimatedPriceMsg.
  ///
  /// In en, this message translates to:
  /// **'This helps your driver to prepare enough money.'**
  String get estimatedPriceMsg;

  /// No description provided for @canNotAdd.
  ///
  /// In en, this message translates to:
  /// **'You can not add more products'**
  String get canNotAdd;

  /// No description provided for @justUpdateOne.
  ///
  /// In en, this message translates to:
  /// **'You can update only one line at a time'**
  String get justUpdateOne;

  /// No description provided for @txtToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get txtToday;

  /// No description provided for @txtUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get txtUpcoming;

  /// No description provided for @txtRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get txtRunning;

  /// No description provided for @txtLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get txtLast7Days;

  /// No description provided for @txtThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get txtThisMonth;

  /// No description provided for @txtYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get txtYear;

  /// No description provided for @txtAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get txtAll;

  /// No description provided for @upTo.
  ///
  /// In en, this message translates to:
  /// **'Up to'**
  String get upTo;

  /// No description provided for @cm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cm;

  /// No description provided for @maxAddressMsg.
  ///
  /// In en, this message translates to:
  /// **'User can only have {maxLimit} addresses. Delete previous before adding a new one'**
  String maxAddressMsg(int maxLimit);

  /// No description provided for @courier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get courier;

  /// No description provided for @enterTip.
  ///
  /// In en, this message translates to:
  /// **'Enter Tip'**
  String get enterTip;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @connectionMsg.
  ///
  /// In en, this message translates to:
  /// **'Please check network connectivity'**
  String get connectionMsg;

  /// No description provided for @selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get selectVehicle;

  /// No description provided for @rideCancelByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ride Cancelled by Admin!'**
  String get rideCancelByAdmin;

  /// No description provided for @sameEditNumberMsg.
  ///
  /// In en, this message translates to:
  /// **'Use a different number. You entered the same one.'**
  String get sameEditNumberMsg;

  /// No description provided for @appExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Back again to exit the app!'**
  String get appExitMessage;

  /// No description provided for @invalidAmountMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get invalidAmountMsg;

  /// No description provided for @passChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password changed successfully!'**
  String get passChangeSuccess;

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction Failed'**
  String get transactionFailed;

  /// No description provided for @stripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe'**
  String get stripe;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @signInToCompleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Sign in to complete your order'**
  String get signInToCompleteOrder;

  /// No description provided for @signInToCompleteOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'Create an account or sign in to save your order details and track delivery.'**
  String get signInToCompleteOrderMessage;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signInToSaveFavorites.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favorites'**
  String get signInToSaveFavorites;

  /// No description provided for @signInToViewOrders.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your orders'**
  String get signInToViewOrders;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @guestAccountPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started with Reen Dugnad'**
  String get guestAccountPromptTitle;

  /// No description provided for @guestAccountPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to access orders, favorites, and more.'**
  String get guestAccountPromptMessage;

  /// No description provided for @signInToSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save addresses to your account'**
  String get signInToSaveAddress;

  /// No description provided for @feed_tab_label.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed_tab_label;

  /// No description provided for @feed_brand_title.
  ///
  /// In en, this message translates to:
  /// **'Aerend Feed'**
  String get feed_brand_title;

  /// No description provided for @feed_nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get feed_nav_home;

  /// No description provided for @feed_nav_explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get feed_nav_explore;

  /// No description provided for @feed_nav_reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get feed_nav_reels;

  /// No description provided for @feed_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get feed_coming_soon;

  /// No description provided for @feed_explore_hint.
  ///
  /// In en, this message translates to:
  /// **'Search for a restaurant to see their posts'**
  String get feed_explore_hint;

  /// No description provided for @feed_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get feed_loading;

  /// No description provided for @feed_empty_followed.
  ///
  /// In en, this message translates to:
  /// **'Follow a store to see posts here'**
  String get feed_empty_followed;

  /// No description provided for @feed_empty_explore.
  ///
  /// In en, this message translates to:
  /// **'Nothing to explore right now'**
  String get feed_empty_explore;

  /// No description provided for @feed_pull_to_refresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get feed_pull_to_refresh;

  /// No description provided for @story_viewer_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get story_viewer_close;

  /// No description provided for @story_viewer_reply_hint.
  ///
  /// In en, this message translates to:
  /// **'Send a message…'**
  String get story_viewer_reply_hint;

  /// No description provided for @store_profile_follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get store_profile_follow;

  /// No description provided for @store_profile_following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get store_profile_following;

  /// No description provided for @store_profile_visit_store.
  ///
  /// In en, this message translates to:
  /// **'Visit store'**
  String get store_profile_visit_store;

  /// No description provided for @store_profile_followers.
  ///
  /// In en, this message translates to:
  /// **'followers'**
  String get store_profile_followers;

  /// No description provided for @store_profile_posts.
  ///
  /// In en, this message translates to:
  /// **'posts'**
  String get store_profile_posts;

  /// No description provided for @store_profile_no_posts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get store_profile_no_posts;

  /// No description provided for @post_detail_like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get post_detail_like;

  /// No description provided for @post_detail_liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get post_detail_liked;

  /// No description provided for @post_detail_comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get post_detail_comments;

  /// No description provided for @post_detail_no_comments.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment'**
  String get post_detail_no_comments;

  /// No description provided for @post_detail_comment_hint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get post_detail_comment_hint;

  /// No description provided for @post_detail_comment_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get post_detail_comment_send;

  /// No description provided for @comment_rate_limit_message.
  ///
  /// In en, this message translates to:
  /// **'You\'re posting too quickly. Wait a moment.'**
  String get comment_rate_limit_message;

  /// No description provided for @comment_prohibited_message.
  ///
  /// In en, this message translates to:
  /// **'Your comment contains content that isn\'t allowed.'**
  String get comment_prohibited_message;

  /// No description provided for @comment_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get comment_delete_confirm_title;

  /// No description provided for @comment_delete_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get comment_delete_confirm_message;

  /// No description provided for @comment_delete_confirm_yes.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get comment_delete_confirm_yes;

  /// No description provided for @comment_delete_confirm_no.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get comment_delete_confirm_no;

  /// No description provided for @search_stores_hint.
  ///
  /// In en, this message translates to:
  /// **'Search stores'**
  String get search_stores_hint;

  /// No description provided for @search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No stores match'**
  String get search_no_results;

  /// No description provided for @feed_error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get feed_error_generic;

  /// No description provided for @feed_error_offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection.'**
  String get feed_error_offline;

  /// No description provided for @feed_error_login_required.
  ///
  /// In en, this message translates to:
  /// **'Please log in to use Ærend Feed'**
  String get feed_error_login_required;

  /// No description provided for @feed_empty_explore_button.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get feed_empty_explore_button;

  /// No description provided for @feed_view_comments.
  ///
  /// In en, this message translates to:
  /// **'View {count} comments'**
  String feed_view_comments(int count);

  /// No description provided for @feed_story_your_story.
  ///
  /// In en, this message translates to:
  /// **'Your story'**
  String get feed_story_your_story;

  /// No description provided for @feed_post_kebab_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get feed_post_kebab_report;

  /// No description provided for @feed_post_kebab_copy_link.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get feed_post_kebab_copy_link;

  /// No description provided for @feed_post_kebab_link_copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get feed_post_kebab_link_copied;

  /// No description provided for @feed_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get feed_retry;

  /// No description provided for @store_profile_stories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get store_profile_stories;

  /// No description provided for @store_profile_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get store_profile_loading;

  /// No description provided for @store_profile_error.
  ///
  /// In en, this message translates to:
  /// **'Could not load store'**
  String get store_profile_error;

  /// No description provided for @store_profile_visit_store_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open store page'**
  String get store_profile_visit_store_failed;

  /// No description provided for @store_profile_report_action.
  ///
  /// In en, this message translates to:
  /// **'Report store'**
  String get store_profile_report_action;

  /// No description provided for @feed_store_profile_story_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap profile photo to view story'**
  String get feed_store_profile_story_hint;

  /// No description provided for @feed_store_profile_default_hint.
  ///
  /// In en, this message translates to:
  /// **'Restaurant · Browse posts & stories'**
  String get feed_store_profile_default_hint;

  /// No description provided for @post_detail_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get post_detail_loading;

  /// No description provided for @post_detail_error.
  ///
  /// In en, this message translates to:
  /// **'Could not load post'**
  String get post_detail_error;

  /// No description provided for @post_detail_share_action.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get post_detail_share_action;

  /// No description provided for @post_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post_detail_title;

  /// No description provided for @comment_send_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not send comment'**
  String get comment_send_failed;

  /// No description provided for @comment_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete comment'**
  String get comment_delete_failed;

  /// No description provided for @comment_delete_not_author.
  ///
  /// In en, this message translates to:
  /// **'You can only delete your own comments'**
  String get comment_delete_not_author;

  /// No description provided for @comment_char_counter.
  ///
  /// In en, this message translates to:
  /// **'{count} / 2000'**
  String comment_char_counter(int count);

  /// No description provided for @dugnadSelectModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select mode'**
  String get dugnadSelectModeTitle;

  /// No description provided for @dugnadSelectModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to use Reen Dugnad?'**
  String get dugnadSelectModeSubtitle;

  /// No description provided for @dugnadModeDugnad.
  ///
  /// In en, this message translates to:
  /// **'Dugnad'**
  String get dugnadModeDugnad;

  /// No description provided for @dugnadModeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dugnadModeActive;

  /// No description provided for @dugnadModeDugnadDesc.
  ///
  /// In en, this message translates to:
  /// **'Order through your team and support the club.'**
  String get dugnadModeDugnadDesc;

  /// No description provided for @dugnadModeCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get dugnadModeCommercial;

  /// No description provided for @dugnadModeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get dugnadModeComingSoon;

  /// No description provided for @dugnadModeCommercialDesc.
  ///
  /// In en, this message translates to:
  /// **'Regular ordering from all stores in Bergen.'**
  String get dugnadModeCommercialDesc;

  /// No description provided for @dugnadModeSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Commercial mode launches later. Until then you use Reen Dugnad in dugnad mode.'**
  String get dugnadModeSwitchHint;

  /// No description provided for @dugnadChooseYourClub.
  ///
  /// In en, this message translates to:
  /// **'Choose your club'**
  String get dugnadChooseYourClub;

  /// No description provided for @dugnadSwitchClub.
  ///
  /// In en, this message translates to:
  /// **'Switch club'**
  String get dugnadSwitchClub;

  /// No description provided for @dugnadSearchForClub.
  ///
  /// In en, this message translates to:
  /// **'Search for your club'**
  String get dugnadSearchForClub;

  /// No description provided for @dugnadChangeClub.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dugnadChangeClub;

  /// No description provided for @dugnadMemberOfClub.
  ///
  /// In en, this message translates to:
  /// **'Member of {clubName}?'**
  String dugnadMemberOfClub(String clubName);

  /// No description provided for @dugnadMembershipPrompt.
  ///
  /// In en, this message translates to:
  /// **'Got a membership number? Enter it to unlock exclusive discounts.'**
  String get dugnadMembershipPrompt;

  /// No description provided for @dugnadMembershipNumber.
  ///
  /// In en, this message translates to:
  /// **'Membership number'**
  String get dugnadMembershipNumber;

  /// No description provided for @dugnadUnlockDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Unlock discounts'**
  String get dugnadUnlockDiscounts;

  /// No description provided for @dugnadContinueAsSupporter.
  ///
  /// In en, this message translates to:
  /// **'Continue as supporter'**
  String get dugnadContinueAsSupporter;

  /// No description provided for @dugnadBrowseWithoutClub.
  ///
  /// In en, this message translates to:
  /// **'Browse without choosing'**
  String get dugnadBrowseWithoutClub;

  /// No description provided for @dugnadChooseClubToStart.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to get started'**
  String get dugnadChooseClubToStart;

  /// No description provided for @dugnadChooseClubToStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Find your club and start supporting them through your purchases.'**
  String get dugnadChooseClubToStartDesc;

  /// No description provided for @dugnadChooseClubOnboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the club to connect your membership to. You can switch at any time.'**
  String get dugnadChooseClubOnboardSubtitle;

  /// No description provided for @dugnadClubChangeAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change clubs at any time — the choice is never binding.'**
  String get dugnadClubChangeAnytime;

  /// No description provided for @dugnadTourPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'New to Reen Dugnad?'**
  String get dugnadTourPromptTitle;

  /// No description provided for @dugnadTourPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Take a short tour of the app — how you pick a team, collect points and build your STØ card. Takes under a minute.'**
  String get dugnadTourPromptBody;

  /// No description provided for @dugnadTourPromptReward.
  ///
  /// In en, this message translates to:
  /// **'points when you finish'**
  String get dugnadTourPromptReward;

  /// No description provided for @dugnadTourPromptRewardNote.
  ///
  /// In en, this message translates to:
  /// **'Straight into your STØ rating'**
  String get dugnadTourPromptRewardNote;

  /// No description provided for @dugnadTourPromptStart.
  ///
  /// In en, this message translates to:
  /// **'Take the tour'**
  String get dugnadTourPromptStart;

  /// No description provided for @dugnadTourPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get dugnadTourPromptLater;

  /// No description provided for @dugnadTourBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get dugnadTourBack;

  /// No description provided for @dugnadTourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get dugnadTourSkip;

  /// No description provided for @dugnadTourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get dugnadTourNext;

  /// No description provided for @dugnadTourFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dugnadTourFinish;

  /// No description provided for @dugnadTourClose.
  ///
  /// In en, this message translates to:
  /// **'Close tour'**
  String get dugnadTourClose;

  /// No description provided for @dugnadTourStepCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String dugnadTourStepCounter(int current, int total);

  /// No description provided for @dugnadTourRowTitle.
  ///
  /// In en, this message translates to:
  /// **'App walkthrough'**
  String get dugnadTourRowTitle;

  /// No description provided for @dugnadTourRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See how points, teams and STØ work'**
  String get dugnadTourRowSubtitle;

  /// No description provided for @dugnadTourWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Reen Dugnad 💜'**
  String get dugnadTourWelcomeTitle;

  /// No description provided for @dugnadTourWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you buy here sends a share back to your club. Let\'s take a quick tour of how it works.'**
  String get dugnadTourWelcomeBody;

  /// No description provided for @dugnadTourTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your team in the club'**
  String get dugnadTourTeamTitle;

  /// No description provided for @dugnadTourTeamBody.
  ///
  /// In en, this message translates to:
  /// **'The club has many teams. Tap the points card and choose the team you want to support — your points then land with the right team on the leaderboard.'**
  String get dugnadTourTeamBody;

  /// No description provided for @dugnadTourConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Your points connect to the team'**
  String get dugnadTourConnectTitle;

  /// No description provided for @dugnadTourConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Once your team is set, every purchase counts for both you and the team. The card shows your STØ rating and where the team stands.'**
  String get dugnadTourConnectBody;

  /// No description provided for @dugnadTourEarnTitle.
  ///
  /// In en, this message translates to:
  /// **'How you earn points'**
  String get dugnadTourEarnTitle;

  /// No description provided for @dugnadTourEarnBody.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address, buy from campaigns, set up recurring support or refer friends. Tap here to see how many points each action gives.'**
  String get dugnadTourEarnBody;

  /// No description provided for @dugnadTourAddrTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your address'**
  String get dugnadTourAddrTitle;

  /// No description provided for @dugnadTourAddrBody.
  ///
  /// In en, this message translates to:
  /// **'Tap here to add your delivery address. It\'s the quickest points you can pick up — and it means orders go straight to your door.'**
  String get dugnadTourAddrBody;

  /// No description provided for @dugnadTourCampsTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy from campaigns'**
  String get dugnadTourCampsTitle;

  /// No description provided for @dugnadTourCampsBody.
  ///
  /// In en, this message translates to:
  /// **'The club\'s own campaigns — food boxes, fundraising goods and offers. Most of your points come from here, and a share goes straight into the club\'s coffers.'**
  String get dugnadTourCampsBody;

  /// No description provided for @dugnadTourDonateTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring support'**
  String get dugnadTourDonateTitle;

  /// No description provided for @dugnadTourDonateBody.
  ///
  /// In en, this message translates to:
  /// **'Set up a monthly amount. It gives the club predictable income — and you points every month without lifting a finger.'**
  String get dugnadTourDonateBody;

  /// No description provided for @dugnadTourReferTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer friends'**
  String get dugnadTourReferTitle;

  /// No description provided for @dugnadTourReferBody.
  ///
  /// In en, this message translates to:
  /// **'Share your referral link. Everyone who joins earns you points, and the club gains another supporter.'**
  String get dugnadTourReferBody;

  /// No description provided for @dugnadTourCompTitle.
  ///
  /// In en, this message translates to:
  /// **'The team competition'**
  String get dugnadTourCompTitle;

  /// No description provided for @dugnadTourCompBody.
  ///
  /// In en, this message translates to:
  /// **'Here you\'ll find the table for every team in the club — plus top scorer, assist leader and the highest STØ card. See where your team sits and what separates you from the one above.'**
  String get dugnadTourCompBody;

  /// No description provided for @dugnadTourStoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your STØ card'**
  String get dugnadTourStoTitle;

  /// No description provided for @dugnadTourStoBody.
  ///
  /// In en, this message translates to:
  /// **'Your STØ rating grows with your points. The card changes metal — bronze, silver, gold, platinum — and shows your team, form and badges.'**
  String get dugnadTourStoBody;

  /// No description provided for @dugnadTourFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Your form'**
  String get dugnadTourFormTitle;

  /// No description provided for @dugnadTourFormBody.
  ///
  /// In en, this message translates to:
  /// **'Form reflects your activity over recent weeks. Shop regularly and you stay in good form; go quiet and it drops.'**
  String get dugnadTourFormBody;

  /// No description provided for @dugnadTourBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get dugnadTourBadgesTitle;

  /// No description provided for @dugnadTourBadgesBody.
  ///
  /// In en, this message translates to:
  /// **'Badges unlock from what you do — first purchase, recurring support, referrals, season goals. Some are permanent, others renew each season.'**
  String get dugnadTourBadgesBody;

  /// No description provided for @dugnadTourDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set 🎉'**
  String get dugnadTourDoneTitle;

  /// No description provided for @dugnadTourDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve earned 50 points for the tour — they\'re already on your STØ card. You can always take it again from your profile.'**
  String get dugnadTourDoneBody;

  /// No description provided for @dugnadTourDoneAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to speed 💜'**
  String get dugnadTourDoneAgainTitle;

  /// No description provided for @dugnadTourDoneAgainBody.
  ///
  /// In en, this message translates to:
  /// **'The 50-point reward has already been paid out, so this round doesn\'t add new points. Come back here whenever you like.'**
  String get dugnadTourDoneAgainBody;

  /// No description provided for @dugnadMembershipOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'You can add your membership number at any time.'**
  String get dugnadMembershipOptionalHint;

  /// No description provided for @dugnadMembershipOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Membership number (optional)'**
  String get dugnadMembershipOptionalLabel;

  /// No description provided for @dugnadChooseClub.
  ///
  /// In en, this message translates to:
  /// **'Choose club'**
  String get dugnadChooseClub;

  /// No description provided for @dugnadSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select address'**
  String get dugnadSelectAddress;

  /// No description provided for @dugnadMyClub.
  ///
  /// In en, this message translates to:
  /// **'My club'**
  String get dugnadMyClub;

  /// No description provided for @dugnadChangeTeamOrClub.
  ///
  /// In en, this message translates to:
  /// **'Change team in Club'**
  String get dugnadChangeTeamOrClub;

  /// No description provided for @dugnadChangeTeamOrClubSub.
  ///
  /// In en, this message translates to:
  /// **'Change anytime — choose a team'**
  String get dugnadChangeTeamOrClubSub;

  /// No description provided for @dugnadSwitchAnytimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change anytime — without waiting for the window'**
  String get dugnadSwitchAnytimeSubtitle;

  /// No description provided for @dugnadYourTeamNow.
  ///
  /// In en, this message translates to:
  /// **'Your team now'**
  String get dugnadYourTeamNow;

  /// No description provided for @dugnadYourTeamFallback.
  ///
  /// In en, this message translates to:
  /// **'your team'**
  String get dugnadYourTeamFallback;

  /// No description provided for @dugnadSwitchTeamInfo.
  ///
  /// In en, this message translates to:
  /// **'Your STØ rating, points and level follow you. Season counters restart for the new team.'**
  String get dugnadSwitchTeamInfo;

  /// No description provided for @dugnadSwitchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm switch to {team}{clubSuffix}'**
  String dugnadSwitchConfirmTitle(String team, String clubSuffix);

  /// No description provided for @dugnadSwitchConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Standard switch — no countdown. You keep rating, points and level.'**
  String get dugnadSwitchConfirmBody;

  /// No description provided for @dugnadSwitchConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm switch'**
  String get dugnadSwitchConfirmBtn;

  /// No description provided for @dugnadSwitchConfirmedToast.
  ///
  /// In en, this message translates to:
  /// **'Switch confirmed 💜'**
  String get dugnadSwitchConfirmedToast;

  /// No description provided for @dugnadPointsTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your team so points count'**
  String get dugnadPointsTeamTitle;

  /// No description provided for @dugnadPointsTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All points you earn go to this one team. You can change it later — only future points are affected.'**
  String get dugnadPointsTeamSubtitle;

  /// No description provided for @dugnadPointsTeamProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Team you support'**
  String get dugnadPointsTeamProfileTitle;

  /// No description provided for @dugnadPointsTeamNone.
  ///
  /// In en, this message translates to:
  /// **'No team selected'**
  String get dugnadPointsTeamNone;

  /// No description provided for @dugnadPointsTeamSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose team'**
  String get dugnadPointsTeamSelect;

  /// No description provided for @dugnadPointsTeamChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dugnadPointsTeamChange;

  /// No description provided for @dugnadPointsTeamConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm team'**
  String get dugnadPointsTeamConfirm;

  /// No description provided for @dugnadPointsTeamSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get dugnadPointsTeamSkip;

  /// No description provided for @dugnadPointsTeamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teams are set up for this club yet.'**
  String get dugnadPointsTeamEmpty;

  /// No description provided for @dugnadPointsTeamLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Log in to choose a points team.'**
  String get dugnadPointsTeamLoginRequired;

  /// No description provided for @dugnadPointsTeamSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your team. Please try again.'**
  String get dugnadPointsTeamSaveFailed;

  /// No description provided for @dugnadPointsTeamCheckoutNudge.
  ///
  /// In en, this message translates to:
  /// **'Choose a team so your purchase earns points for them.'**
  String get dugnadPointsTeamCheckoutNudge;

  /// No description provided for @dugnadPointsTeamPurchasePoints.
  ///
  /// In en, this message translates to:
  /// **'+{points} points per campaign purchase'**
  String dugnadPointsTeamPurchasePoints(int points);

  /// No description provided for @dugnadPointsTeamTotal.
  ///
  /// In en, this message translates to:
  /// **'{points} points earned'**
  String dugnadPointsTeamTotal(int points);

  /// No description provided for @dugnadPointsHistoryLink.
  ///
  /// In en, this message translates to:
  /// **'View points log'**
  String get dugnadPointsHistoryLink;

  /// No description provided for @dugnadPointsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Points log'**
  String get dugnadPointsHistoryTitle;

  /// No description provided for @dugnadPointsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No points activity yet.'**
  String get dugnadPointsHistoryEmpty;

  /// No description provided for @dugnadPointsActionCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign purchase'**
  String get dugnadPointsActionCampaign;

  /// No description provided for @dugnadPointsActionDonation.
  ///
  /// In en, this message translates to:
  /// **'Monthly support'**
  String get dugnadPointsActionDonation;

  /// No description provided for @dugnadPointsActionReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral conversion'**
  String get dugnadPointsActionReferral;

  /// No description provided for @dugnadPointsActionReferralMilestone.
  ///
  /// In en, this message translates to:
  /// **'Referral milestone'**
  String get dugnadPointsActionReferralMilestone;

  /// No description provided for @dugnadPointsActionCampaignReversal.
  ///
  /// In en, this message translates to:
  /// **'Campaign purchase reversed'**
  String get dugnadPointsActionCampaignReversal;

  /// No description provided for @dugnadPointsActionDonationReversal.
  ///
  /// In en, this message translates to:
  /// **'Monthly support reversed'**
  String get dugnadPointsActionDonationReversal;

  /// No description provided for @dugnadPointsActionReferralReversal.
  ///
  /// In en, this message translates to:
  /// **'Referral reversed'**
  String get dugnadPointsActionReferralReversal;

  /// No description provided for @dugnadPointsActionReferralMilestoneReversal.
  ///
  /// In en, this message translates to:
  /// **'Referral milestone reversed'**
  String get dugnadPointsActionReferralMilestoneReversal;

  /// No description provided for @dugnadPointsActionReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get dugnadPointsActionReversal;

  /// No description provided for @dugnadPointsReferralConversionDetail.
  ///
  /// In en, this message translates to:
  /// **'Referral no. {sequence} converted'**
  String dugnadPointsReferralConversionDetail(int sequence);

  /// No description provided for @dugnadPointsReferralMilestoneDetail.
  ///
  /// In en, this message translates to:
  /// **'Bonus at {count} converted referrals'**
  String dugnadPointsReferralMilestoneDetail(int count);

  /// No description provided for @dugnadProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dugnadProfileTitle;

  /// No description provided for @dugnadYourPoints.
  ///
  /// In en, this message translates to:
  /// **'Your points and badges'**
  String get dugnadYourPoints;

  /// No description provided for @dugnadPointsUnit.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get dugnadPointsUnit;

  /// No description provided for @dugnadHeroNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{tier} · not connected to a team'**
  String dugnadHeroNotConnected(String tier);

  /// No description provided for @dugnadConnectPointsTeam.
  ///
  /// In en, this message translates to:
  /// **'Connect your points to a team'**
  String get dugnadConnectPointsTeam;

  /// No description provided for @dugnadConnectPointsTeamSub.
  ///
  /// In en, this message translates to:
  /// **'Choose your team so points count in the team competition'**
  String get dugnadConnectPointsTeamSub;

  /// No description provided for @dugnadConnectPointsToTeam.
  ///
  /// In en, this message translates to:
  /// **'Connect points to teams'**
  String get dugnadConnectPointsToTeam;

  /// No description provided for @dugnadStoCardButton.
  ///
  /// In en, this message translates to:
  /// **'STØ card'**
  String get dugnadStoCardButton;

  /// No description provided for @dugnadPointsToNextWithSto.
  ///
  /// In en, this message translates to:
  /// **'{points} points to {tier} ({sto} {stoLabel})'**
  String dugnadPointsToNextWithSto(
    int points,
    String tier,
    int sto,
    String stoLabel,
  );

  /// No description provided for @dugnadSeasonCarryoverLine.
  ///
  /// In en, this message translates to:
  /// **'Bringing {points} points to next season'**
  String dugnadSeasonCarryoverLine(int points);

  /// No description provided for @dugnadSeasonFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'The season is ending soon'**
  String get dugnadSeasonFinaleTitle;

  /// No description provided for @dugnadSeasonFinaleCarryoverBodyPrefix.
  ///
  /// In en, this message translates to:
  /// **'With STØ {sto} you take '**
  String dugnadSeasonFinaleCarryoverBodyPrefix(int sto);

  /// No description provided for @dugnadSeasonFinaleCarryoverBodySuffix.
  ///
  /// In en, this message translates to:
  /// **' {points, plural, =1{point} other{points}} into the next season.'**
  String dugnadSeasonFinaleCarryoverBodySuffix(int points);

  /// No description provided for @dugnadSeasonFinaleHigherMetalHint.
  ///
  /// In en, this message translates to:
  /// **'Higher metal = greater lead'**
  String get dugnadSeasonFinaleHigherMetalHint;

  /// No description provided for @dugnadSeasonFinaleNextCarryover.
  ///
  /// In en, this message translates to:
  /// **'Now {nextTier} (STØ {sto}) → {points} points carryover 🚀'**
  String dugnadSeasonFinaleNextCarryover(String nextTier, int sto, int points);

  /// No description provided for @dugnadSeasonFinaleMaxCarryover.
  ///
  /// In en, this message translates to:
  /// **'Maximum carryover lead reached 🚀'**
  String get dugnadSeasonFinaleMaxCarryover;

  /// No description provided for @dugnadSeasonFinaleBadgesLocked.
  ///
  /// In en, this message translates to:
  /// **'{count} season badges locked into your history this season'**
  String dugnadSeasonFinaleBadgesLocked(int count);

  /// No description provided for @dugnadSeasonFinaleShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Show season finale again'**
  String get dugnadSeasonFinaleShowAgain;

  /// No description provided for @dugnadSeasonFinaleDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dugnadSeasonFinaleDismiss;

  /// No description provided for @dugnadNowTier.
  ///
  /// In en, this message translates to:
  /// **'Now {tier}'**
  String dugnadNowTier(String tier);

  /// No description provided for @dugnadNoPointsYet.
  ///
  /// In en, this message translates to:
  /// **'You have not earned points yet'**
  String get dugnadNoPointsYet;

  /// No description provided for @dugnadSignInForPoints.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your points'**
  String get dugnadSignInForPoints;

  /// No description provided for @dugnadReferFriendsEarnSub.
  ///
  /// In en, this message translates to:
  /// **'Get more supporters to join the club'**
  String get dugnadReferFriendsEarnSub;

  /// No description provided for @dugnadEarnMorePoints.
  ///
  /// In en, this message translates to:
  /// **'Earn more points'**
  String get dugnadEarnMorePoints;

  /// No description provided for @dugnadClubShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Club shop'**
  String get dugnadClubShopTitle;

  /// No description provided for @dugnadClubShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{club} collection at member price'**
  String dugnadClubShopSubtitle(String club);

  /// No description provided for @dugnadClubShopLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'The shop is for members'**
  String get dugnadClubShopLockedTitle;

  /// No description provided for @dugnadClubShopLockedBody.
  ///
  /// In en, this message translates to:
  /// **'{collection} is sold at member price. Enter your membership number to unlock.'**
  String dugnadClubShopLockedBody(String collection);

  /// No description provided for @dugnadClubShopMemberNumber.
  ///
  /// In en, this message translates to:
  /// **'Membership number'**
  String get dugnadClubShopMemberNumber;

  /// No description provided for @dugnadClubShopMemberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'FF-10428'**
  String get dugnadClubShopMemberPlaceholder;

  /// No description provided for @dugnadClubShopUnlockCta.
  ///
  /// In en, this message translates to:
  /// **'Unlock shop'**
  String get dugnadClubShopUnlockCta;

  /// No description provided for @dugnadClubShopUnlockEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your membership number.'**
  String get dugnadClubShopUnlockEmpty;

  /// No description provided for @dugnadClubShopUnlockGeneric.
  ///
  /// In en, this message translates to:
  /// **'We cannot find this membership number. Check that it is correct, or contact the club.'**
  String get dugnadClubShopUnlockGeneric;

  /// No description provided for @dugnadClubShopHintCard.
  ///
  /// In en, this message translates to:
  /// **'You will find the membership number on your membership card or on the invoice from the club.'**
  String get dugnadClubShopHintCard;

  /// No description provided for @dugnadClubShopHintPartner.
  ///
  /// In en, this message translates to:
  /// **'The collection is delivered together with {partner}. Garments are picked up there against your order number.'**
  String dugnadClubShopHintPartner(String partner);

  /// No description provided for @dugnadClubShopUnlockSuccess.
  ///
  /// In en, this message translates to:
  /// **'The shop is unlocked — welcome, {name}'**
  String dugnadClubShopUnlockSuccess(String name);

  /// No description provided for @dugnadClubShopVerified.
  ///
  /// In en, this message translates to:
  /// **'Verifisert medlem'**
  String get dugnadClubShopVerified;

  /// No description provided for @dugnadClubShopVerifiedLine.
  ///
  /// In en, this message translates to:
  /// **'Verified member · {number}'**
  String dugnadClubShopVerifiedLine(String number);

  /// No description provided for @dugnadClubShopVerifiedSub.
  ///
  /// In en, this message translates to:
  /// **'The member discount is deducted automatically at checkout'**
  String get dugnadClubShopVerifiedSub;

  /// No description provided for @dugnadClubShopAudienceMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get dugnadClubShopAudienceMen;

  /// No description provided for @dugnadClubShopAudienceWomen.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get dugnadClubShopAudienceWomen;

  /// No description provided for @dugnadClubShopAudienceKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get dugnadClubShopAudienceKids;

  /// No description provided for @dugnadClubShopCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dugnadClubShopCategoryAll;

  /// No description provided for @dugnadClubShopSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get dugnadClubShopSoldOut;

  /// No description provided for @dugnadClubShopSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get dugnadClubShopSeeMore;

  /// No description provided for @dugnadClubShopWithPartner.
  ///
  /// In en, this message translates to:
  /// **'In collaboration with {partner}'**
  String dugnadClubShopWithPartner(String partner);

  /// No description provided for @dugnadClubShopMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get dugnadClubShopMyOrders;

  /// No description provided for @dugnadClubShopEmptyOrders.
  ///
  /// In en, this message translates to:
  /// **'You have no orders yet.'**
  String get dugnadClubShopEmptyOrders;

  /// No description provided for @dugnadClubShopChooseSize.
  ///
  /// In en, this message translates to:
  /// **'Choose size'**
  String get dugnadClubShopChooseSize;

  /// No description provided for @dugnadClubShopAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart · {price}'**
  String dugnadClubShopAddToCart(String price);

  /// No description provided for @dugnadClubShopAllSoldOut.
  ///
  /// In en, this message translates to:
  /// **'All sizes are sold out. The club will restock when the partner has delivered.'**
  String get dugnadClubShopAllSoldOut;

  /// No description provided for @dugnadClubShopInCartHint.
  ///
  /// In en, this message translates to:
  /// **'You already have {count} of this item in the cart.'**
  String dugnadClubShopInCartHint(int count);

  /// No description provided for @dugnadClubShopAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} ({size}) added to the cart'**
  String dugnadClubShopAdded(String name, String size);

  /// No description provided for @dugnadClubShopMemberDiscount.
  ///
  /// In en, this message translates to:
  /// **'Member discount −{pct} %'**
  String dugnadClubShopMemberDiscount(int pct);

  /// No description provided for @dugnadClubShopCategoryCollection.
  ///
  /// In en, this message translates to:
  /// **'{category} · {collection}'**
  String dugnadClubShopCategoryCollection(String category, String collection);

  /// No description provided for @dugnadClubShopStockGone.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get dugnadClubShopStockGone;

  /// No description provided for @dugnadClubShopInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get dugnadClubShopInStock;

  /// No description provided for @dugnadClubShopLowStock.
  ///
  /// In en, this message translates to:
  /// **'Few left'**
  String get dugnadClubShopLowStock;

  /// No description provided for @dugnadClubShopCartCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in the basket'**
  String dugnadClubShopCartCount(int count);

  /// No description provided for @dugnadClubShopGoToCart.
  ///
  /// In en, this message translates to:
  /// **'To the basket'**
  String get dugnadClubShopGoToCart;

  /// No description provided for @dugnadClubShopCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Basket'**
  String get dugnadClubShopCartTitle;

  /// No description provided for @dugnadClubShopCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'The basket is empty'**
  String get dugnadClubShopCartEmpty;

  /// No description provided for @dugnadClubShopCartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add items from the club collection.'**
  String get dugnadClubShopCartEmptyBody;

  /// No description provided for @dugnadClubShopToShop.
  ///
  /// In en, this message translates to:
  /// **'To the shop'**
  String get dugnadClubShopToShop;

  /// No description provided for @dugnadClubShopSizeLine.
  ///
  /// In en, this message translates to:
  /// **'Size {size}'**
  String dugnadClubShopSizeLine(String size);

  /// No description provided for @dugnadClubShopOrdinarySum.
  ///
  /// In en, this message translates to:
  /// **'Ordinary sum'**
  String get dugnadClubShopOrdinarySum;

  /// No description provided for @dugnadClubShopMemberDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Member discount'**
  String get dugnadClubShopMemberDiscountLabel;

  /// No description provided for @dugnadClubShopToPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get dugnadClubShopToPay;

  /// No description provided for @dugnadClubShopPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get dugnadClubShopPaymentMethod;

  /// No description provided for @dugnadClubShopPayVipps.
  ///
  /// In en, this message translates to:
  /// **'Vipps'**
  String get dugnadClubShopPayVipps;

  /// No description provided for @dugnadClubShopPayCard.
  ///
  /// In en, this message translates to:
  /// **'Card · Visa •••• 4412'**
  String get dugnadClubShopPayCard;

  /// No description provided for @dugnadClubShopPayCta.
  ///
  /// In en, this message translates to:
  /// **'Pay {price}'**
  String dugnadClubShopPayCta(String price);

  /// No description provided for @dugnadClubShopCartHint.
  ///
  /// In en, this message translates to:
  /// **'The order is registered under membership number {number}. Items are picked up at {partner}, {address} — give the order number you receive after payment.'**
  String dugnadClubShopCartHint(String number, String partner, String address);

  /// No description provided for @dugnadClubShopProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing payment …'**
  String get dugnadClubShopProcessing;

  /// No description provided for @dugnadClubShopProcessingSub.
  ///
  /// In en, this message translates to:
  /// **'Do not close the app'**
  String get dugnadClubShopProcessingSub;

  /// No description provided for @dugnadClubShopPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Show the order number when you pick up.'**
  String get dugnadClubShopPaid;

  /// No description provided for @dugnadClubShopReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Order confirmation'**
  String get dugnadClubShopReceiptTitle;

  /// No description provided for @dugnadClubShopThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase'**
  String get dugnadClubShopThanks;

  /// No description provided for @dugnadClubShopShowNumber.
  ///
  /// In en, this message translates to:
  /// **'Show the order number when you pick up the garments.'**
  String get dugnadClubShopShowNumber;

  /// No description provided for @dugnadClubShopPointsAdded.
  ///
  /// In en, this message translates to:
  /// **'points added to your account'**
  String get dugnadClubShopPointsAdded;

  /// No description provided for @dugnadClubShopOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get dugnadClubShopOrderNumber;

  /// No description provided for @dugnadClubShopScanAt.
  ///
  /// In en, this message translates to:
  /// **'Scanned or read out at {partner}'**
  String dugnadClubShopScanAt(String partner);

  /// No description provided for @dugnadClubShopPickupAt.
  ///
  /// In en, this message translates to:
  /// **'Pickup at {partner}'**
  String dugnadClubShopPickupAt(String partner);

  /// No description provided for @dugnadClubShopPickupBody.
  ///
  /// In en, this message translates to:
  /// **'{address} · {pickup}. Give the order number at the counter — they look it up and find your garments.'**
  String dugnadClubShopPickupBody(String address, String pickup);

  /// No description provided for @dugnadClubShopReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'The confirmation is always under My orders in the shop — you will find it again when you pick up.'**
  String get dugnadClubShopReceiptHint;

  /// No description provided for @dugnadClubShopSeeOrders.
  ///
  /// In en, this message translates to:
  /// **'See my orders'**
  String get dugnadClubShopSeeOrders;

  /// No description provided for @dugnadClubShopBackToShop.
  ///
  /// In en, this message translates to:
  /// **'Back to the shop'**
  String get dugnadClubShopBackToShop;

  /// No description provided for @dugnadClubShopPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get dugnadClubShopPaidLabel;

  /// No description provided for @dugnadClubShopClubLabel.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get dugnadClubShopClubLabel;

  /// No description provided for @dugnadClubShopMemberNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Membership number'**
  String get dugnadClubShopMemberNoLabel;

  /// No description provided for @dugnadClubShopPlacedLabel.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get dugnadClubShopPlacedLabel;

  /// No description provided for @dugnadClubShopPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get dugnadClubShopPointsLabel;

  /// No description provided for @dugnadClubShopOrderedToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dugnadClubShopOrderedToday;

  /// No description provided for @dugnadClubShopOrderedTodayTime.
  ///
  /// In en, this message translates to:
  /// **'Today · {time}'**
  String dugnadClubShopOrderedTodayTime(String time);

  /// No description provided for @dugnadClubShopStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get dugnadClubShopStatusReady;

  /// No description provided for @dugnadClubShopStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get dugnadClubShopStatusPending;

  /// No description provided for @dugnadClubShopStatusCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get dugnadClubShopStatusCollected;

  /// No description provided for @dugnadClubShopOrderMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} garments'**
  String dugnadClubShopOrderMeta(int count);

  /// No description provided for @dugnadClubShopPayFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Try again.'**
  String get dugnadClubShopPayFailed;

  /// No description provided for @dugnadClubShopPayInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start payment. Try again.'**
  String get dugnadClubShopPayInitFailed;

  /// No description provided for @dugnadClubShopRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dugnadClubShopRemoveItem;

  /// No description provided for @dugnadClubShopPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'You earn points on this purchase'**
  String get dugnadClubShopPointsTitle;

  /// No description provided for @dugnadClubShopPointsSub.
  ///
  /// In en, this message translates to:
  /// **'Points are added once payment is confirmed'**
  String get dugnadClubShopPointsSub;

  /// No description provided for @dugnadClubShopProductImage.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get dugnadClubShopProductImage;

  /// No description provided for @dugnadClubShopBrowseSoon.
  ///
  /// In en, this message translates to:
  /// **'The collection opens here after you unlock.'**
  String get dugnadClubShopBrowseSoon;

  /// No description provided for @dugnadEarnMostPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to earn the most points'**
  String get dugnadEarnMostPointsTitle;

  /// No description provided for @dugnadEarnMostPointsSub.
  ///
  /// In en, this message translates to:
  /// **'Every action for {club} gives points'**
  String dugnadEarnMostPointsSub(String club);

  /// No description provided for @dugnadEarnSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Points level you up, unlock badges and help {club}'**
  String dugnadEarnSheetSubtitle(String club);

  /// No description provided for @dugnadEarnSheetIntro.
  ///
  /// In en, this message translates to:
  /// **'The more you contribute, the more points you collect. Points earn you higher levels and badges — and propel your team up the season standings toward prizes.'**
  String get dugnadEarnSheetIntro;

  /// No description provided for @dugnadEarnSheetActivitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'POINTS PER ACTIVITY'**
  String get dugnadEarnSheetActivitiesLabel;

  /// No description provided for @dugnadEarnSheetTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an activity to get started.'**
  String get dugnadEarnSheetTapHint;

  /// No description provided for @dugnadEarnBuyCampaignDesc.
  ///
  /// In en, this message translates to:
  /// **'Support a team by shopping for items'**
  String get dugnadEarnBuyCampaignDesc;

  /// No description provided for @dugnadEarnReferDesc.
  ///
  /// In en, this message translates to:
  /// **'Get someone to support {club}'**
  String dugnadEarnReferDesc(String club);

  /// No description provided for @dugnadEarnDonationDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn membership points every month automatically'**
  String get dugnadEarnDonationDesc;

  /// No description provided for @dugnadEarnDonationPtsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'+{points}/mo'**
  String dugnadEarnDonationPtsPerMonth(int points);

  /// No description provided for @dugnadEarnLeaderboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Help your team climb'**
  String get dugnadEarnLeaderboardDesc;

  /// No description provided for @dugnadEarnTeamPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Team points'**
  String get dugnadEarnTeamPointsLabel;

  /// No description provided for @dugnadCampaignsFromClub.
  ///
  /// In en, this message translates to:
  /// **'Campaigns from {club}'**
  String dugnadCampaignsFromClub(String club);

  /// No description provided for @dugnadCampaignPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get dugnadCampaignPageTitle;

  /// No description provided for @dugnadCampaignSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search team, campaign or product …'**
  String get dugnadCampaignSearchHint;

  /// No description provided for @dugnadAllTeams.
  ///
  /// In en, this message translates to:
  /// **'All teams'**
  String get dugnadAllTeams;

  /// No description provided for @dugnadSupportTeamsIn.
  ///
  /// In en, this message translates to:
  /// **'Support teams in {club}'**
  String dugnadSupportTeamsIn(String club);

  /// No description provided for @dugnadSupportTeamsSub.
  ///
  /// In en, this message translates to:
  /// **'Each team sells its own meal box'**
  String get dugnadSupportTeamsSub;

  /// No description provided for @dugnadCampaignSupportBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Support your local team — buy from the campaign'**
  String get dugnadCampaignSupportBuyTitle;

  /// No description provided for @dugnadSupplierEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get dugnadSupplierEyebrow;

  /// No description provided for @dugnadCarryoverHighlightPoints.
  ///
  /// In en, this message translates to:
  /// **'Now {tier} (STØ {sto}) → take {points} points into next season 🚀'**
  String dugnadCarryoverHighlightPoints(String tier, int sto, int points);

  /// No description provided for @dugnadCarryoverPerLevelSubPoints.
  ///
  /// In en, this message translates to:
  /// **'Your metal level at season end sets the points head start you bring into next season.'**
  String get dugnadCarryoverPerLevelSubPoints;

  /// No description provided for @campaignOrderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get campaignOrderDetailsTitle;

  /// No description provided for @campaignProductsSection.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get campaignProductsSection;

  /// No description provided for @campaignCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart'**
  String get campaignCartTitle;

  /// No description provided for @campaignCartClear.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get campaignCartClear;

  /// No description provided for @campaignCartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get campaignCartCheckout;

  /// No description provided for @campaignCartSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item in cart} other{{count} items in cart}}'**
  String campaignCartSummary(int count);

  /// No description provided for @campaignCountdownLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get campaignCountdownLeft;

  /// No description provided for @campaignCountdownDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'Order deadline has passed'**
  String get campaignCountdownDeadlinePassed;

  /// No description provided for @campaignCountdownLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day — order now'**
  String get campaignCountdownLastDay;

  /// No description provided for @campaignCountdownTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left to order'**
  String get campaignCountdownTimeLeft;

  /// No description provided for @campaignCountdownClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get campaignCountdownClosed;

  /// No description provided for @campaignMatkasseFallback.
  ///
  /// In en, this message translates to:
  /// **'Meal box'**
  String get campaignMatkasseFallback;

  /// No description provided for @campaignOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get campaignOrderNumber;

  /// No description provided for @campaignOrderPlacedOn.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get campaignOrderPlacedOn;

  /// No description provided for @campaignDistributionDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get campaignDistributionDate;

  /// No description provided for @campaignPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get campaignPickupLocation;

  /// No description provided for @campaignOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get campaignOrderAmount;

  /// No description provided for @campaignPaymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get campaignPaymentStatusLabel;

  /// No description provided for @campaignOrderStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Order status'**
  String get campaignOrderStatusLabel;

  /// No description provided for @campaignOrderDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get campaignOrderDone;

  /// No description provided for @campaignOrderOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get campaignOrderOngoing;

  /// No description provided for @campaignDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get campaignDownloadPdf;

  /// No description provided for @campaignOrderPdfFooter.
  ///
  /// In en, this message translates to:
  /// **'Generated from the Reen Dugnad app'**
  String get campaignOrderPdfFooter;

  /// No description provided for @campaignOrderPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the PDF. Please try again.'**
  String get campaignOrderPdfFailed;

  /// No description provided for @dugnadMissionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load weekly challenges right now.'**
  String get dugnadMissionsLoadError;

  /// No description provided for @dugnadMissionsLoadErrorSub.
  ///
  /// In en, this message translates to:
  /// **'Check your network and try again.'**
  String get dugnadMissionsLoadErrorSub;

  /// No description provided for @dugnadMissionsNoTeam.
  ///
  /// In en, this message translates to:
  /// **'Choose a team under Your points to see weekly challenges and season goals.'**
  String get dugnadMissionsNoTeam;

  /// No description provided for @dugnadMissionsNoWeekly.
  ///
  /// In en, this message translates to:
  /// **'No active weekly challenges this week.'**
  String get dugnadMissionsNoWeekly;

  /// No description provided for @dugnadSeasonGoals.
  ///
  /// In en, this message translates to:
  /// **'Season goals'**
  String get dugnadSeasonGoals;

  /// No description provided for @dugnadMissionsNoSeasonGoals.
  ///
  /// In en, this message translates to:
  /// **'No season goals set up yet.'**
  String get dugnadMissionsNoSeasonGoals;

  /// No description provided for @dugnadWeeklyChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly challenges'**
  String get dugnadWeeklyChallengesTitle;

  /// No description provided for @dugnadMissionsResetMonday.
  ///
  /// In en, this message translates to:
  /// **'Resets Monday · {days} days left'**
  String dugnadMissionsResetMonday(int days);

  /// No description provided for @dugnadMissionsFormEntrySub.
  ///
  /// In en, this message translates to:
  /// **'Form is built from your in-app activity — purchases, referrals, sharing and logins'**
  String get dugnadMissionsFormEntrySub;

  /// No description provided for @dugnadStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks in a row with activity'**
  String dugnadStreakTitle(int weeks);

  /// No description provided for @dugnadStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the streak to build form — one point-earning action a week counts'**
  String get dugnadStreakSubtitle;

  /// No description provided for @dugnadMissionsTempoDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dugnadMissionsTempoDone;

  /// No description provided for @dugnadMissionsTempoOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get dugnadMissionsTempoOnTrack;

  /// No description provided for @dugnadMissionsTempoNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get dugnadMissionsTempoNotStarted;

  /// No description provided for @dugnadWeeklyChallengeLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly challenge'**
  String get dugnadWeeklyChallengeLabel;

  /// No description provided for @dugnadMissionsInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Activity earns points and form — never tied to membership or payment, and it never affects the clubs\' share.'**
  String get dugnadMissionsInfoBanner;

  /// No description provided for @dugnadShareYourSupport.
  ///
  /// In en, this message translates to:
  /// **'Share your support'**
  String get dugnadShareYourSupport;

  /// No description provided for @dugnadSupportShareMessage.
  ///
  /// In en, this message translates to:
  /// **'I just supported {club} 💜'**
  String dugnadSupportShareMessage(String club);

  /// No description provided for @dugnadShareCampaign.
  ///
  /// In en, this message translates to:
  /// **'Share the campaign'**
  String get dugnadShareCampaign;

  /// No description provided for @dugnadShareProduct.
  ///
  /// In en, this message translates to:
  /// **'Share the product'**
  String get dugnadShareProduct;

  /// No description provided for @dugnadShareCampaignMessage.
  ///
  /// In en, this message translates to:
  /// **'Support {club} — buy from the campaign on Reen Dugnad 💜'**
  String dugnadShareCampaignMessage(String club);

  /// No description provided for @dugnadShareProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out {product} from {club} on Reen Dugnad 💜'**
  String dugnadShareProductMessage(String product, String club);

  /// No description provided for @dugnadPurchaseShareToClub.
  ///
  /// In en, this message translates to:
  /// **'A share of your purchase goes to {club}'**
  String dugnadPurchaseShareToClub(String club);

  /// No description provided for @dugnadModeCommercialSub.
  ///
  /// In en, this message translates to:
  /// **'Regular mode — launching later'**
  String get dugnadModeCommercialSub;

  /// No description provided for @dugnadSaveChange.
  ///
  /// In en, this message translates to:
  /// **'Save change'**
  String get dugnadSaveChange;

  /// No description provided for @dugnadNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get dugnadNotNow;

  /// No description provided for @dugnadEarnPointsOnPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'You earn points on this purchase'**
  String get dugnadEarnPointsOnPurchaseTitle;

  /// No description provided for @dugnadEarnPointsOnPurchaseSub.
  ///
  /// In en, this message translates to:
  /// **'Points are added to your account when the purchase is confirmed'**
  String get dugnadEarnPointsOnPurchaseSub;

  /// No description provided for @dugnadInCartBoxes.
  ///
  /// In en, this message translates to:
  /// **'In cart · {count, plural, =1{1 box} other{{count} boxes}}'**
  String dugnadInCartBoxes(int count);

  /// No description provided for @dugnadProfileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get dugnadProfileAccountSection;

  /// No description provided for @dugnadSupporterCardProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Your collectible card — shareable'**
  String get dugnadSupporterCardProfileSub;

  /// No description provided for @dugnadSeasonRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Your season recap'**
  String get dugnadSeasonRecapTitle;

  /// No description provided for @dugnadSeasonRecapSub.
  ///
  /// In en, this message translates to:
  /// **'Your season in numbers — shareable'**
  String get dugnadSeasonRecapSub;

  /// No description provided for @dugnadVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get dugnadVisibilityTitle;

  /// No description provided for @dugnadVisibilitySub.
  ///
  /// In en, this message translates to:
  /// **'Display name and privacy on leaderboards'**
  String get dugnadVisibilitySub;

  /// No description provided for @dugnadPaymentVippsMasked.
  ///
  /// In en, this message translates to:
  /// **'Vipps •••• {last4}'**
  String dugnadPaymentVippsMasked(String last4);

  /// No description provided for @dugnadSeasonRecapSoon.
  ///
  /// In en, this message translates to:
  /// **'Season recap coming soon'**
  String get dugnadSeasonRecapSoon;

  /// No description provided for @dugnadSeasonRecapSeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season {label}'**
  String dugnadSeasonRecapSeasonLabel(String label);

  /// No description provided for @dugnadSeasonRecapHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your season, {name} 💜'**
  String dugnadSeasonRecapHeroTitle(String name);

  /// No description provided for @dugnadSeasonRecapHeroSub.
  ///
  /// In en, this message translates to:
  /// **'Thanks for cheering the team on all the way. Here\'s your season in numbers.'**
  String get dugnadSeasonRecapHeroSub;

  /// No description provided for @dugnadSeasonRecapContributed.
  ///
  /// In en, this message translates to:
  /// **'You contributed'**
  String get dugnadSeasonRecapContributed;

  /// No description provided for @dugnadSeasonRecapReferrals.
  ///
  /// In en, this message translates to:
  /// **'Friends you referred'**
  String get dugnadSeasonRecapReferrals;

  /// No description provided for @dugnadSeasonRecapCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns purchased'**
  String get dugnadSeasonRecapCampaigns;

  /// No description provided for @dugnadSeasonRecapPoints.
  ///
  /// In en, this message translates to:
  /// **'Points collected'**
  String get dugnadSeasonRecapPoints;

  /// No description provided for @dugnadSeasonRecapTeamFinished.
  ///
  /// In en, this message translates to:
  /// **'{team} finished in {rank} place'**
  String dugnadSeasonRecapTeamFinished(String team, int rank);

  /// No description provided for @dugnadSeasonRecapTeamOf.
  ///
  /// In en, this message translates to:
  /// **'of {count} teams in {club}'**
  String dugnadSeasonRecapTeamOf(int count, String club);

  /// No description provided for @dugnadSeasonRecapViewCard.
  ///
  /// In en, this message translates to:
  /// **'View your supporter card'**
  String get dugnadSeasonRecapViewCard;

  /// No description provided for @dugnadSeasonRecapCardSub.
  ///
  /// In en, this message translates to:
  /// **'Seasonal trading card'**
  String get dugnadSeasonRecapCardSub;

  /// No description provided for @dugnadSeasonRecapShare.
  ///
  /// In en, this message translates to:
  /// **'Share your season'**
  String get dugnadSeasonRecapShare;

  /// No description provided for @dugnadSeasonRecapShareMessage.
  ///
  /// In en, this message translates to:
  /// **'My Reen Dugnad season with {club} 💜\n{link}'**
  String dugnadSeasonRecapShareMessage(String club, String link);

  /// No description provided for @dugnadSeasonRecapShareMessageLegacy.
  ///
  /// In en, this message translates to:
  /// **'My Reen Dugnad season with {club} 💜'**
  String dugnadSeasonRecapShareMessageLegacy(String club);

  /// No description provided for @dugnadTransitionWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'The transition window'**
  String get dugnadTransitionWindowTitle;

  /// No description provided for @dugnadTransitionWindowSub.
  ///
  /// In en, this message translates to:
  /// **'Move up with the team or change clubs'**
  String get dugnadTransitionWindowSub;

  /// No description provided for @dugnadTransitionWindowSoon.
  ///
  /// In en, this message translates to:
  /// **'The transition window is coming soon'**
  String get dugnadTransitionWindowSoon;

  /// No description provided for @dugnadTransferWindowClosesTitle.
  ///
  /// In en, this message translates to:
  /// **'The transfer window closes in {days} days ⏳'**
  String dugnadTransferWindowClosesTitle(int days);

  /// No description provided for @dugnadTransferWindowClosesSoon.
  ///
  /// In en, this message translates to:
  /// **'The transfer window closes soon ⏳'**
  String get dugnadTransferWindowClosesSoon;

  /// No description provided for @dugnadTransferWindowDeadlineSub.
  ///
  /// In en, this message translates to:
  /// **'End of season · make your choice before the deadline'**
  String get dugnadTransferWindowDeadlineSub;

  /// No description provided for @dugnadTransferNextSeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening with your team next season?'**
  String get dugnadTransferNextSeasonLabel;

  /// No description provided for @dugnadTransferMoveUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get dugnadTransferMoveUpTitle;

  /// No description provided for @dugnadTransferMoveUpSub.
  ///
  /// In en, this message translates to:
  /// **'{current} become {next} — join us'**
  String dugnadTransferMoveUpSub(String current, String next);

  /// No description provided for @dugnadTransferRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get dugnadTransferRecommended;

  /// No description provided for @dugnadTransferStayTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on the same level'**
  String get dugnadTransferStayTitle;

  /// No description provided for @dugnadTransferStaySub.
  ///
  /// In en, this message translates to:
  /// **'Continue following {team} (new year)'**
  String dugnadTransferStaySub(String team);

  /// No description provided for @dugnadTransferTeamSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to another team in the club'**
  String get dugnadTransferTeamSwitchTitle;

  /// No description provided for @dugnadTransferTeamSwitchSub.
  ///
  /// In en, this message translates to:
  /// **'Follow another team in {club}'**
  String dugnadTransferTeamSwitchSub(String club);

  /// No description provided for @dugnadTransferClubChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change club'**
  String get dugnadTransferClubChangeTitle;

  /// No description provided for @dugnadTransferClubChangeSub.
  ///
  /// In en, this message translates to:
  /// **'Sign for a new club — \"Signed for\" card'**
  String get dugnadTransferClubChangeSub;

  /// No description provided for @dugnadTransferInfo.
  ///
  /// In en, this message translates to:
  /// **'At season end your metal level determines how many points you carry over. Your rating rebuilds through activity; lifetime points are always safe.'**
  String get dugnadTransferInfo;

  /// No description provided for @dugnadTransferMoveUpConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{current} become {next} — coming with us?'**
  String dugnadTransferMoveUpConfirmTitle(String current, String next);

  /// No description provided for @dugnadTransferMoveUpConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The team moves up one age group for the new season. You keep your rating, points and level.'**
  String get dugnadTransferMoveUpConfirmBody;

  /// No description provided for @dugnadTransferMoveUpConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Yes, join {next}'**
  String dugnadTransferMoveUpConfirmBtn(String next);

  /// No description provided for @dugnadTransferStayConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on {team} next season?'**
  String dugnadTransferStayConfirmTitle(String team);

  /// No description provided for @dugnadTransferStayConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You continue following {team} (new year group). Quick confirmation — you keep rating, points and level.'**
  String dugnadTransferStayConfirmBody(String team);

  /// No description provided for @dugnadTransferStayConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Yes, stay on {team}'**
  String dugnadTransferStayConfirmBtn(String team);

  /// No description provided for @dugnadTransferPickTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a team in {club}'**
  String dugnadTransferPickTeamLabel(String club);

  /// No description provided for @dugnadTransferPickClubLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a new club'**
  String get dugnadTransferPickClubLabel;

  /// No description provided for @dugnadTransferFollowTeamBtn.
  ///
  /// In en, this message translates to:
  /// **'Follow {team}'**
  String dugnadTransferFollowTeamBtn(String team);

  /// No description provided for @dugnadTransferNewTeam.
  ///
  /// In en, this message translates to:
  /// **'new team'**
  String get dugnadTransferNewTeam;

  /// No description provided for @dugnadTransferBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get dugnadTransferBack;

  /// No description provided for @dugnadTransferSuccessMoveUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re continuing with {team} 💜'**
  String dugnadTransferSuccessMoveUp(String team);

  /// No description provided for @dugnadTransferSuccessStay.
  ///
  /// In en, this message translates to:
  /// **'You\'re continuing with {team} 💜'**
  String dugnadTransferSuccessStay(String team);

  /// No description provided for @dugnadTransferSuccessTeamSwitch.
  ///
  /// In en, this message translates to:
  /// **'You\'re now following {team} 💜'**
  String dugnadTransferSuccessTeamSwitch(String team);

  /// No description provided for @dugnadTransferClubChanged.
  ///
  /// In en, this message translates to:
  /// **'You signed for {club} 💜'**
  String dugnadTransferClubChanged(String club);

  /// No description provided for @dugnadTransferCommitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your choice is saved 💜'**
  String get dugnadTransferCommitSuccess;

  /// No description provided for @dugnadTransferCommitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your choice. Try again.'**
  String get dugnadTransferCommitFailed;

  /// No description provided for @dugnadTransferMoveUpUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Move-up is not set up for this team yet — the next age group is missing in the club.'**
  String get dugnadTransferMoveUpUnavailable;

  /// No description provided for @dugnadTransferLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the transfer window.'**
  String get dugnadTransferLoadFailed;

  /// No description provided for @dugnadTransferWindowDisabled.
  ///
  /// In en, this message translates to:
  /// **'The transfer window is not enabled yet.'**
  String get dugnadTransferWindowDisabled;

  /// No description provided for @dugnadTransferWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'The transfer window is closed.'**
  String get dugnadTransferWindowClosed;

  /// No description provided for @dugnadTransferNotNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get dugnadTransferNotNowTitle;

  /// No description provided for @dugnadTransferNotNowSub.
  ///
  /// In en, this message translates to:
  /// **'Keep your team — choose later from your profile'**
  String get dugnadTransferNotNowSub;

  /// No description provided for @dugnadTransferExtra.
  ///
  /// In en, this message translates to:
  /// **'You can switch teams at any time — in the transfer window your move gets extra celebration ✨'**
  String get dugnadTransferExtra;

  /// No description provided for @dugnadTransferChooseLater.
  ///
  /// In en, this message translates to:
  /// **'You can choose later from your profile 💜'**
  String get dugnadTransferChooseLater;

  /// No description provided for @dugnadCareerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your career'**
  String get dugnadCareerTitle;

  /// No description provided for @dugnadCareerSub.
  ///
  /// In en, this message translates to:
  /// **'Timeline of team affiliation'**
  String get dugnadCareerSub;

  /// No description provided for @dugnadCareerSoon.
  ///
  /// In en, this message translates to:
  /// **'Your career timeline is coming soon'**
  String get dugnadCareerSoon;

  /// No description provided for @dugnadCareerHeroSub.
  ///
  /// In en, this message translates to:
  /// **'Your permanent history on Reen Dugnad'**
  String get dugnadCareerHeroSub;

  /// No description provided for @dugnadCareerLifetimeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Lifetime points'**
  String get dugnadCareerLifetimeEyebrow;

  /// No description provided for @dugnadCareerLifetimePermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get dugnadCareerLifetimePermanent;

  /// No description provided for @dugnadCareerLifetimeSub.
  ///
  /// In en, this message translates to:
  /// **'Earned since {date} · grows forever, never resets'**
  String dugnadCareerLifetimeSub(String date);

  /// No description provided for @dugnadCareerSeasonArchiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Season ticket archive'**
  String get dugnadCareerSeasonArchiveLabel;

  /// No description provided for @dugnadCareerSeasonArchiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No seasons archived yet'**
  String get dugnadCareerSeasonArchiveEmptyTitle;

  /// No description provided for @dugnadCareerSeasonArchiveEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your STØ card is frozen here when the first season ends — with final rating, club and season badges. That is when your card collection starts.'**
  String get dugnadCareerSeasonArchiveEmptyBody;

  /// No description provided for @dugnadCareerSeasonStamp.
  ///
  /// In en, this message translates to:
  /// **'Season {label}'**
  String dugnadCareerSeasonStamp(String label);

  /// No description provided for @dugnadCareerStoTier.
  ///
  /// In en, this message translates to:
  /// **'STØ · {tier}'**
  String dugnadCareerStoTier(String tier);

  /// No description provided for @dugnadCareerTeamsMulti.
  ///
  /// In en, this message translates to:
  /// **'{team} · {count} teams'**
  String dugnadCareerTeamsMulti(String team, int count);

  /// No description provided for @dugnadCareerPermanentMarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent marks'**
  String get dugnadCareerPermanentMarksTitle;

  /// No description provided for @dugnadCareerPermanentMarksSub.
  ///
  /// In en, this message translates to:
  /// **'With vesting date and STØ value · never lost'**
  String get dugnadCareerPermanentMarksSub;

  /// No description provided for @dugnadCareerAffiliationTimeline.
  ///
  /// In en, this message translates to:
  /// **'Affiliation timeline'**
  String get dugnadCareerAffiliationTimeline;

  /// No description provided for @dugnadCareerRoleCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current club'**
  String get dugnadCareerRoleCurrent;

  /// No description provided for @dugnadCareerRoleTransfer.
  ///
  /// In en, this message translates to:
  /// **'Free transfer'**
  String get dugnadCareerRoleTransfer;

  /// No description provided for @dugnadCareerNowBadge.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get dugnadCareerNowBadge;

  /// No description provided for @dugnadCareerInfoFooter.
  ///
  /// In en, this message translates to:
  /// **'Lifetime points and permanent badges last forever. Season badges and season tickets are archived here at the end of each season — with club and team names frozen as they were that season.'**
  String get dugnadCareerInfoFooter;

  /// No description provided for @dugnadCareerShareMessage.
  ///
  /// In en, this message translates to:
  /// **'My career on Reen Dugnad — {points} lifetime points 💜\n{link}'**
  String dugnadCareerShareMessage(String points, String link);

  /// No description provided for @dugnadCareerShareMessageLegacy.
  ///
  /// In en, this message translates to:
  /// **'My career on Reen Dugnad — {points} lifetime points 💜'**
  String dugnadCareerShareMessageLegacy(String points);

  /// No description provided for @dugnadVisibilitySoon.
  ///
  /// In en, this message translates to:
  /// **'Visibility coming soon'**
  String get dugnadVisibilitySoon;

  /// No description provided for @dugnadPrivacyIntroPrefix.
  ///
  /// In en, this message translates to:
  /// **'How to control where you appear: '**
  String get dugnadPrivacyIntroPrefix;

  /// No description provided for @dugnadPrivacyIntroBold.
  ///
  /// In en, this message translates to:
  /// **'Standings, Top Scorer, Assist King, Squad'**
  String get dugnadPrivacyIntroBold;

  /// No description provided for @dugnadPrivacyIntroSuffix.
  ///
  /// In en, this message translates to:
  /// **' and Shared Cards.'**
  String get dugnadPrivacyIntroSuffix;

  /// No description provided for @dugnadPrivacyPreviewAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview as'**
  String get dugnadPrivacyPreviewAsLabel;

  /// No description provided for @dugnadPrivacyPreviewAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get dugnadPrivacyPreviewAdult;

  /// No description provided for @dugnadPrivacyPreviewMinor.
  ///
  /// In en, this message translates to:
  /// **'Under 18'**
  String get dugnadPrivacyPreviewMinor;

  /// No description provided for @dugnadPrivacyDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get dugnadPrivacyDisplayTitle;

  /// No description provided for @dugnadPrivacyPrefFull.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get dugnadPrivacyPrefFull;

  /// No description provided for @dugnadPrivacyPrefFullSub.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone'**
  String get dugnadPrivacyPrefFullSub;

  /// No description provided for @dugnadPrivacyPrefInitial.
  ///
  /// In en, this message translates to:
  /// **'First name + initial'**
  String get dugnadPrivacyPrefInitial;

  /// No description provided for @dugnadPrivacyPrefInitialSub.
  ///
  /// In en, this message translates to:
  /// **'A little more private'**
  String get dugnadPrivacyPrefInitialSub;

  /// No description provided for @dugnadPrivacyPrefNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get dugnadPrivacyPrefNickname;

  /// No description provided for @dugnadPrivacyPrefNicknameSub.
  ///
  /// In en, this message translates to:
  /// **'Choose your own'**
  String get dugnadPrivacyPrefNicknameSub;

  /// No description provided for @dugnadPrivacyPrefAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous supporter'**
  String get dugnadPrivacyPrefAnonymous;

  /// No description provided for @dugnadPrivacyPrefAnonymousSub.
  ///
  /// In en, this message translates to:
  /// **'Hide your name completely'**
  String get dugnadPrivacyPrefAnonymousSub;

  /// No description provided for @dugnadPrivacyPrefAnonymousEx.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get dugnadPrivacyPrefAnonymousEx;

  /// No description provided for @dugnadPrivacyVisibleSection.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get dugnadPrivacyVisibleSection;

  /// No description provided for @dugnadPrivacyVisibleOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Show me on tables and in the squad'**
  String get dugnadPrivacyVisibleOnTitle;

  /// No description provided for @dugnadPrivacyVisibleOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden (anonymous)'**
  String get dugnadPrivacyVisibleOffTitle;

  /// No description provided for @dugnadPrivacyVisibleNote.
  ///
  /// In en, this message translates to:
  /// **'Your contribution counts for the team regardless — you just disappear from the roster.'**
  String get dugnadPrivacyVisibleNote;

  /// No description provided for @dugnadPrivacyLeaderboardPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'How to appear on the leaderboards'**
  String get dugnadPrivacyLeaderboardPreviewTitle;

  /// No description provided for @dugnadPrivacyNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Write your nickname …'**
  String get dugnadPrivacyNicknameHint;

  /// No description provided for @dugnadPrivacyMinorBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You are under 18'**
  String get dugnadPrivacyMinorBannerTitle;

  /// No description provided for @dugnadPrivacyMinorBannerSub.
  ///
  /// In en, this message translates to:
  /// **'For privacy you are anonymous or masked by default. Full name requires consent from a parent or guardian.'**
  String get dugnadPrivacyMinorBannerSub;

  /// No description provided for @dugnadPrivacyMinorConsent.
  ///
  /// In en, this message translates to:
  /// **'Request parental consent'**
  String get dugnadPrivacyMinorConsent;

  /// No description provided for @dugnadPrivacyMinorConsentSoon.
  ///
  /// In en, this message translates to:
  /// **'Parental consent coming soon'**
  String get dugnadPrivacyMinorConsentSoon;

  /// No description provided for @dugnadPrivacyHiddenMeta.
  ///
  /// In en, this message translates to:
  /// **'Hidden · {team}'**
  String dugnadPrivacyHiddenMeta(String team);

  /// No description provided for @dugnadPrivacyGoalUnit.
  ///
  /// In en, this message translates to:
  /// **'goal'**
  String get dugnadPrivacyGoalUnit;

  /// No description provided for @dugnadPrivacySaved.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings saved'**
  String get dugnadPrivacySaved;

  /// No description provided for @dugnadPrivacySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save privacy settings'**
  String get dugnadPrivacySaveFailed;

  /// No description provided for @dugnadPaymentSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment coming soon'**
  String get dugnadPaymentSoon;

  /// No description provided for @dugnadCustomerSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer support'**
  String get dugnadCustomerSupport;

  /// No description provided for @dugnadSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dugnadSettings;

  /// No description provided for @dugnadPickTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your team'**
  String get dugnadPickTeamTitle;

  /// No description provided for @dugnadPickTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which team in {club} do you belong to?'**
  String dugnadPickTeamSubtitle(String club);

  /// No description provided for @dugnadPickTeamSearch.
  ///
  /// In en, this message translates to:
  /// **'Search for your team …'**
  String get dugnadPickTeamSearch;

  /// No description provided for @dugnadPickTeamNote.
  ///
  /// In en, this message translates to:
  /// **'You can change teams at any time. Engagement points from your everyday purchases are credited to the team you choose.'**
  String get dugnadPickTeamNote;

  /// No description provided for @dugnadPickTeamMeta.
  ///
  /// In en, this message translates to:
  /// **'{families} active supporters · #{rank} in the competition'**
  String dugnadPickTeamMeta(int families, int rank);

  /// No description provided for @dugnadPickTeamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teams match «{query}».'**
  String dugnadPickTeamEmpty(String query);

  /// No description provided for @dugnadLeaderboardTeamSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} · #{rank}'**
  String dugnadLeaderboardTeamSelectedTitle(String team, int rank);

  /// No description provided for @dugnadLeaderboardTeamSelectedSub.
  ///
  /// In en, this message translates to:
  /// **'See standing, points and level'**
  String get dugnadLeaderboardTeamSelectedSub;

  /// No description provided for @dugnadYourPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Your place'**
  String get dugnadYourPlaceLabel;

  /// No description provided for @dugnadYourPlaceRank.
  ///
  /// In en, this message translates to:
  /// **'#{rank} / {total}'**
  String dugnadYourPlaceRank(int rank, int total);

  /// No description provided for @dugnadBuyFoodbox.
  ///
  /// In en, this message translates to:
  /// **'Buy a food box'**
  String get dugnadBuyFoodbox;

  /// No description provided for @dugnadBuyFoodboxSub.
  ///
  /// In en, this message translates to:
  /// **'Team food boxes — support a team directly'**
  String get dugnadBuyFoodboxSub;

  /// No description provided for @dugnadSupportRegularly.
  ///
  /// In en, this message translates to:
  /// **'Support the team regularly'**
  String get dugnadSupportRegularly;

  /// No description provided for @dugnadSupportRegularlySub.
  ///
  /// In en, this message translates to:
  /// **'Regular monthly support for the team'**
  String get dugnadSupportRegularlySub;

  /// No description provided for @dugnadYourBadges.
  ///
  /// In en, this message translates to:
  /// **'Your badges'**
  String get dugnadYourBadges;

  /// No description provided for @dugnadBadgesUnlocked.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} badges unlocked'**
  String dugnadBadgesUnlocked(int earned, int total);

  /// No description provided for @dugnadSeeAllBadges.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dugnadSeeAllBadges;

  /// No description provided for @dugnadPointsToNext.
  ///
  /// In en, this message translates to:
  /// **'{points} points to {tier}'**
  String dugnadPointsToNext(int points, String tier);

  /// No description provided for @dugnadHighestTierReached.
  ///
  /// In en, this message translates to:
  /// **'Highest level reached 🎉'**
  String get dugnadHighestTierReached;

  /// No description provided for @dugnadPreviewLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a level to see the upgrade'**
  String get dugnadPreviewLevelHint;

  /// No description provided for @dugnadStoSourceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'This builds your rating'**
  String get dugnadStoSourceSectionTitle;

  /// No description provided for @dugnadStoSourceActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity & referrals'**
  String get dugnadStoSourceActivityTitle;

  /// No description provided for @dugnadStoSourceActivitySub.
  ///
  /// In en, this message translates to:
  /// **'Referrals, participation and sharing'**
  String get dugnadStoSourceActivitySub;

  /// No description provided for @dugnadStoSourceCampaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign purchases'**
  String get dugnadStoSourceCampaignTitle;

  /// No description provided for @dugnadStoSourceCampaignSub.
  ///
  /// In en, this message translates to:
  /// **'Purchases of campaigns and products'**
  String get dugnadStoSourceCampaignSub;

  /// No description provided for @dugnadStoSourceBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus from badges'**
  String get dugnadStoSourceBadgeTitle;

  /// No description provided for @dugnadStoSourceBadgeSub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 badge unlocked} other{{count} badges unlocked}}'**
  String dugnadStoSourceBadgeSub(int count);

  /// No description provided for @dugnadSeasonPointsThisYear.
  ///
  /// In en, this message translates to:
  /// **'Season points this year'**
  String get dugnadSeasonPointsThisYear;

  /// No description provided for @dugnadYourStoRating.
  ///
  /// In en, this message translates to:
  /// **'Your STØ rating'**
  String get dugnadYourStoRating;

  /// No description provided for @dugnadStoRatingFromPoints.
  ///
  /// In en, this message translates to:
  /// **'Your point total determines the rating'**
  String get dugnadStoRatingFromPoints;

  /// No description provided for @dugnadStoCardPillarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your STØ card'**
  String get dugnadStoCardPillarTitle;

  /// No description provided for @dugnadStoCardPillarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{tier} · {metal} · shareable'**
  String dugnadStoCardPillarSubtitle(String tier, String metal);

  /// No description provided for @dugnadPointsShortSuffix.
  ///
  /// In en, this message translates to:
  /// **'p'**
  String get dugnadPointsShortSuffix;

  /// No description provided for @dugnadYourTeam.
  ///
  /// In en, this message translates to:
  /// **'Your team'**
  String get dugnadYourTeam;

  /// No description provided for @dugnadShowSupporterCard.
  ///
  /// In en, this message translates to:
  /// **'Show your supporter card'**
  String get dugnadShowSupporterCard;

  /// No description provided for @dugnadSupporterCardLine.
  ///
  /// In en, this message translates to:
  /// **'{tier} · {points} points · shareable'**
  String dugnadSupporterCardLine(String tier, int points);

  /// No description provided for @dugnadHowYouEarnPoints.
  ///
  /// In en, this message translates to:
  /// **'How you earn points'**
  String get dugnadHowYouEarnPoints;

  /// No description provided for @dugnadReferFriend.
  ///
  /// In en, this message translates to:
  /// **'Refer a friend'**
  String get dugnadReferFriend;

  /// No description provided for @dugnadReferFriendSub.
  ///
  /// In en, this message translates to:
  /// **'Get supporters to join the team'**
  String get dugnadReferFriendSub;

  /// No description provided for @dugnadBuyCampaign.
  ///
  /// In en, this message translates to:
  /// **'Buy a campaign'**
  String get dugnadBuyCampaign;

  /// No description provided for @dugnadBuyCampaignSub.
  ///
  /// In en, this message translates to:
  /// **'Food boxes from the team'**
  String get dugnadBuyCampaignSub;

  /// No description provided for @dugnadRegularSupport.
  ///
  /// In en, this message translates to:
  /// **'Regular support'**
  String get dugnadRegularSupport;

  /// No description provided for @dugnadRegularSupportSub.
  ///
  /// In en, this message translates to:
  /// **'Support a team monthly'**
  String get dugnadRegularSupportSub;

  /// No description provided for @dugnadChangeTeam.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dugnadChangeTeam;

  /// No description provided for @dugnadTeamPointsCount.
  ///
  /// In en, this message translates to:
  /// **'#{rank} of {total} · your points count here'**
  String dugnadTeamPointsCount(int rank, int total);

  /// No description provided for @dugnadLevelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Level up — you\'re now {tier}! 💜'**
  String dugnadLevelUpTitle(String tier);

  /// No description provided for @dugnadLevelUpThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for everything you contribute. Next level: {nextTier}.'**
  String dugnadLevelUpThanks(String nextTier);

  /// No description provided for @dugnadLevelUpThanksMax.
  ///
  /// In en, this message translates to:
  /// **'Thanks for everything you contribute.'**
  String get dugnadLevelUpThanksMax;

  /// No description provided for @dugnadSupporterLabel.
  ///
  /// In en, this message translates to:
  /// **'SUPPORTER'**
  String get dugnadSupporterLabel;

  /// No description provided for @dugnadShareCardMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m now {tier} on Reen Dugnad 💜'**
  String dugnadShareCardMessage(String tier);

  /// No description provided for @dugnadShareResult.
  ///
  /// In en, this message translates to:
  /// **'Share your result'**
  String get dugnadShareResult;

  /// No description provided for @dugnadSharePointsReward.
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String dugnadSharePointsReward(int points);

  /// No description provided for @dugnadCheerButton.
  ///
  /// In en, this message translates to:
  /// **'Cheers!'**
  String get dugnadCheerButton;

  /// No description provided for @dugnadSupporterCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Supporter card'**
  String get dugnadSupporterCardTitle;

  /// No description provided for @dugnadStoPosition.
  ///
  /// In en, this message translates to:
  /// **'SUP'**
  String get dugnadStoPosition;

  /// No description provided for @dugnadKapPosition.
  ///
  /// In en, this message translates to:
  /// **'CAP'**
  String get dugnadKapPosition;

  /// No description provided for @dugnadPointsStat.
  ///
  /// In en, this message translates to:
  /// **'POINT'**
  String get dugnadPointsStat;

  /// No description provided for @dugnadGoalsPurchases.
  ///
  /// In en, this message translates to:
  /// **'GOAL · PURCHASE'**
  String get dugnadGoalsPurchases;

  /// No description provided for @dugnadAssistsReferrals.
  ///
  /// In en, this message translates to:
  /// **'ASSIST · POSITION'**
  String get dugnadAssistsReferrals;

  /// No description provided for @dugnadShareYourCard.
  ///
  /// In en, this message translates to:
  /// **'Share your card'**
  String get dugnadShareYourCard;

  /// No description provided for @dugnadSupporterCardShareMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} — {club} 💜\n{link}'**
  String dugnadSupporterCardShareMessage(
    String title,
    String club,
    String link,
  );

  /// No description provided for @dugnadCardValueHint.
  ///
  /// In en, this message translates to:
  /// **'The card increases in value as you earn points, recruit supporters, and support the team throughout the season.'**
  String get dugnadCardValueHint;

  /// No description provided for @dugnadBadgeRegularSupporter.
  ///
  /// In en, this message translates to:
  /// **'Regular supporter'**
  String get dugnadBadgeRegularSupporter;

  /// No description provided for @dugnadBadgeRegularSupporterSub.
  ///
  /// In en, this message translates to:
  /// **'Set up regular support'**
  String get dugnadBadgeRegularSupporterSub;

  /// No description provided for @dugnadBadgeAmbassador.
  ///
  /// In en, this message translates to:
  /// **'Club ambassador'**
  String get dugnadBadgeAmbassador;

  /// No description provided for @dugnadBadgeAmbassadorSub.
  ///
  /// In en, this message translates to:
  /// **'Refer 5 to the club'**
  String get dugnadBadgeAmbassadorSub;

  /// No description provided for @dugnadBadgeTeamPlayer.
  ///
  /// In en, this message translates to:
  /// **'Team player'**
  String get dugnadBadgeTeamPlayer;

  /// No description provided for @dugnadBadgeTeamPlayerSub.
  ///
  /// In en, this message translates to:
  /// **'3 months regular support'**
  String get dugnadBadgeTeamPlayerSub;

  /// No description provided for @dugnadBadgeVeteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get dugnadBadgeVeteran;

  /// No description provided for @dugnadBadgeVeteranSub.
  ///
  /// In en, this message translates to:
  /// **'1 year as a supporter'**
  String get dugnadBadgeVeteranSub;

  /// No description provided for @dugnadBadgeHatTrick.
  ///
  /// In en, this message translates to:
  /// **'Hat-trick'**
  String get dugnadBadgeHatTrick;

  /// No description provided for @dugnadBadgeHatTrickSub.
  ///
  /// In en, this message translates to:
  /// **'3 referrals'**
  String get dugnadBadgeHatTrickSub;

  /// No description provided for @dugnadBadgeAssistKing.
  ///
  /// In en, this message translates to:
  /// **'Assist king'**
  String get dugnadBadgeAssistKing;

  /// No description provided for @dugnadBadgeAssistKingSub.
  ///
  /// In en, this message translates to:
  /// **'Refer more than 5 to the club'**
  String get dugnadBadgeAssistKingSub;

  /// No description provided for @dugnadBadgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get dugnadBadgeUnlocked;

  /// No description provided for @dugnadBadgeReferProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/5'**
  String dugnadBadgeReferProgress(int current);

  /// No description provided for @dugnadBadgeVeteranProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/12 mo'**
  String dugnadBadgeVeteranProgress(int current);

  /// No description provided for @dugnadBadgeAssistProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/6'**
  String dugnadBadgeAssistProgress(int current);

  /// No description provided for @dugnadPermanentBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent badges'**
  String get dugnadPermanentBadgesTitle;

  /// No description provided for @dugnadPermanentBadgesSub.
  ///
  /// In en, this message translates to:
  /// **'Lasts forever — never lost'**
  String get dugnadPermanentBadgesSub;

  /// No description provided for @dugnadSeasonalBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Seasonal badges'**
  String get dugnadSeasonalBadgesTitle;

  /// No description provided for @dugnadSeasonalBadgesSub.
  ///
  /// In en, this message translates to:
  /// **'Renews every season · resets at season end'**
  String get dugnadSeasonalBadgesSub;

  /// No description provided for @dugnadBadgeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get dugnadBadgeSheetTitle;

  /// No description provided for @dugnadBadgeTypePermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent badge · never lost'**
  String get dugnadBadgeTypePermanent;

  /// No description provided for @dugnadBadgeTypeSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal badge · renews every season'**
  String get dugnadBadgeTypeSeasonal;

  /// No description provided for @dugnadBadgeStatusActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get dugnadBadgeStatusActiveNow;

  /// No description provided for @dugnadBadgeEarnedAt.
  ///
  /// In en, this message translates to:
  /// **'Earned {date}'**
  String dugnadBadgeEarnedAt(String date);

  /// No description provided for @dugnadBadgeStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Not unlocked yet'**
  String get dugnadBadgeStatusLocked;

  /// No description provided for @dugnadBadgeHowToSection.
  ///
  /// In en, this message translates to:
  /// **'HOW TO EARN THIS BADGE'**
  String get dugnadBadgeHowToSection;

  /// No description provided for @dugnadBadgeProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get dugnadBadgeProgressLabel;

  /// No description provided for @dugnadBadgeStoEarned.
  ///
  /// In en, this message translates to:
  /// **'+{bonus} STØ'**
  String dugnadBadgeStoEarned(int bonus);

  /// No description provided for @dugnadBadgeStoUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock +{bonus} STØ'**
  String dugnadBadgeStoUnlock(int bonus);

  /// No description provided for @dugnadBadgeRewardEarnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Gives you +{bonus} STØ rating'**
  String dugnadBadgeRewardEarnedTitle(int bonus);

  /// No description provided for @dugnadBadgeRewardLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlocks +{bonus} STØ rating'**
  String dugnadBadgeRewardLockedTitle(int bonus);

  /// No description provided for @dugnadBadgeRewardEarnedSub.
  ///
  /// In en, this message translates to:
  /// **'Already added to your rating'**
  String get dugnadBadgeRewardEarnedSub;

  /// No description provided for @dugnadBadgeRewardLockedSub.
  ///
  /// In en, this message translates to:
  /// **'Added when you earn the badge'**
  String get dugnadBadgeRewardLockedSub;

  /// No description provided for @dugnadBadgeFirstSub.
  ///
  /// In en, this message translates to:
  /// **'Complete a club transfer'**
  String get dugnadBadgeFirstSub;

  /// No description provided for @dugnadBadgeFirstPurchaseSub.
  ///
  /// In en, this message translates to:
  /// **'Buy your first campaign box'**
  String get dugnadBadgeFirstPurchaseSub;

  /// No description provided for @dugnadBadgePurchaseHattrickSub.
  ///
  /// In en, this message translates to:
  /// **'Buy 3 campaign boxes'**
  String get dugnadBadgePurchaseHattrickSub;

  /// No description provided for @dugnadBadgeTenBoxesSub.
  ///
  /// In en, this message translates to:
  /// **'Buy 10 campaign boxes in total'**
  String get dugnadBadgeTenBoxesSub;

  /// No description provided for @dugnadBadgeMissionsMasterSub.
  ///
  /// In en, this message translates to:
  /// **'Complete 8 weekly missions'**
  String get dugnadBadgeMissionsMasterSub;

  /// No description provided for @dugnadBadgeFormWeekSub.
  ///
  /// In en, this message translates to:
  /// **'10 weeks in shape'**
  String get dugnadBadgeFormWeekSub;

  /// No description provided for @dugnadBadgeSeasonTopSub.
  ///
  /// In en, this message translates to:
  /// **'Top 3 on your team'**
  String get dugnadBadgeSeasonTopSub;

  /// No description provided for @dugnadBadgeClubEngagedSub.
  ///
  /// In en, this message translates to:
  /// **'Active for your club'**
  String get dugnadBadgeClubEngagedSub;

  /// No description provided for @dugnadBadgeLockedGenericSub.
  ///
  /// In en, this message translates to:
  /// **'Keep being active'**
  String get dugnadBadgeLockedGenericSub;

  /// No description provided for @dugnadBadgeMonthsProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{goal} mo'**
  String dugnadBadgeMonthsProgress(int current, int goal);

  /// No description provided for @dugnadBadgeReferralsProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{goal} referred'**
  String dugnadBadgeReferralsProgress(int current, int goal);

  /// No description provided for @dugnadBadgeWeeklyChallengesProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{goal} missions'**
  String dugnadBadgeWeeklyChallengesProgress(int current, int goal);

  /// No description provided for @dugnadBadgeFormWeeksProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{goal} weeks'**
  String dugnadBadgeFormWeeksProgress(int current, int goal);

  /// No description provided for @dugnadBadgeSeasonRankProgress.
  ///
  /// In en, this message translates to:
  /// **'#{rank} · {places} places to go'**
  String dugnadBadgeSeasonRankProgress(int rank, int places);

  /// No description provided for @dugnadBadgeBoxesProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{goal} boxes'**
  String dugnadBadgeBoxesProgress(int current, int goal);

  /// No description provided for @dugnadBadgeHowActivityGeneric.
  ///
  /// In en, this message translates to:
  /// **'Stay active in the app to unlock this badge.'**
  String get dugnadBadgeHowActivityGeneric;

  /// No description provided for @dugnadBadgeHowTenureGeneric.
  ///
  /// In en, this message translates to:
  /// **'Keep an active membership over time to unlock this badge.'**
  String get dugnadBadgeHowTenureGeneric;

  /// No description provided for @dugnadBadgeHowLocalityGeneric.
  ///
  /// In en, this message translates to:
  /// **'Stay active for your club and team through the season.'**
  String get dugnadBadgeHowLocalityGeneric;

  /// No description provided for @dugnadBadgeHowGenericStep1.
  ///
  /// In en, this message translates to:
  /// **'Be active in the app'**
  String get dugnadBadgeHowGenericStep1;

  /// No description provided for @dugnadBadgeHowGenericStep2.
  ///
  /// In en, this message translates to:
  /// **'Meet the requirement'**
  String get dugnadBadgeHowGenericStep2;

  /// No description provided for @dugnadBadgeHowGenericStep3.
  ///
  /// In en, this message translates to:
  /// **'The badge unlocks automatically'**
  String get dugnadBadgeHowGenericStep3;

  /// No description provided for @dugnadBadgeHowSupport.
  ///
  /// In en, this message translates to:
  /// **'Set up regular support for your club. The badge unlocks as soon as membership is active.'**
  String get dugnadBadgeHowSupport;

  /// No description provided for @dugnadBadgeHowSupportStep1.
  ///
  /// In en, this message translates to:
  /// **'Choose club and team'**
  String get dugnadBadgeHowSupportStep1;

  /// No description provided for @dugnadBadgeHowSupportStep2.
  ///
  /// In en, this message translates to:
  /// **'Set up regular support'**
  String get dugnadBadgeHowSupportStep2;

  /// No description provided for @dugnadBadgeHowSupportStep3.
  ///
  /// In en, this message translates to:
  /// **'Yours forever'**
  String get dugnadBadgeHowSupportStep3;

  /// No description provided for @dugnadBadgeHowLagspiller.
  ///
  /// In en, this message translates to:
  /// **'Be an active member for 3 months in a row without pausing.'**
  String get dugnadBadgeHowLagspiller;

  /// No description provided for @dugnadBadgeHowLagspillerStep1.
  ///
  /// In en, this message translates to:
  /// **'Keep active membership'**
  String get dugnadBadgeHowLagspillerStep1;

  /// No description provided for @dugnadBadgeHowLagspillerStep2.
  ///
  /// In en, this message translates to:
  /// **'Hold it for 3 months'**
  String get dugnadBadgeHowLagspillerStep2;

  /// No description provided for @dugnadBadgeHowLagspillerStep3.
  ///
  /// In en, this message translates to:
  /// **'Unlocks automatically'**
  String get dugnadBadgeHowLagspillerStep3;

  /// No description provided for @dugnadBadgeHowFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete your first transfer between two clubs in the app.'**
  String get dugnadBadgeHowFirst;

  /// No description provided for @dugnadBadgeHowFirstStep1.
  ///
  /// In en, this message translates to:
  /// **'Switch to a new club'**
  String get dugnadBadgeHowFirstStep1;

  /// No description provided for @dugnadBadgeHowFirstStep2.
  ///
  /// In en, this message translates to:
  /// **'Complete the transfer'**
  String get dugnadBadgeHowFirstStep2;

  /// No description provided for @dugnadBadgeHowFirstStep3.
  ///
  /// In en, this message translates to:
  /// **'A keepsake badge — never lost'**
  String get dugnadBadgeHowFirstStep3;

  /// No description provided for @dugnadBadgeHowHattrick.
  ///
  /// In en, this message translates to:
  /// **'Refer 3 friends who become members. Each completed referral counts.'**
  String get dugnadBadgeHowHattrick;

  /// No description provided for @dugnadBadgeHowHattrickStep1.
  ///
  /// In en, this message translates to:
  /// **'Share your referral link'**
  String get dugnadBadgeHowHattrickStep1;

  /// No description provided for @dugnadBadgeHowHattrickStep2.
  ///
  /// In en, this message translates to:
  /// **'3 friends become members'**
  String get dugnadBadgeHowHattrickStep2;

  /// No description provided for @dugnadBadgeHowHattrickStep3.
  ///
  /// In en, this message translates to:
  /// **'Badge unlocks'**
  String get dugnadBadgeHowHattrickStep3;

  /// No description provided for @dugnadBadgeHowVeteran.
  ///
  /// In en, this message translates to:
  /// **'Stay a member for 12 consecutive months. A loyalty badge that lasts forever.'**
  String get dugnadBadgeHowVeteran;

  /// No description provided for @dugnadBadgeHowVeteranStep1.
  ///
  /// In en, this message translates to:
  /// **'Keep membership active'**
  String get dugnadBadgeHowVeteranStep1;

  /// No description provided for @dugnadBadgeHowVeteranStep2.
  ///
  /// In en, this message translates to:
  /// **'12 months in a row'**
  String get dugnadBadgeHowVeteranStep2;

  /// No description provided for @dugnadBadgeHowVeteranStep3.
  ///
  /// In en, this message translates to:
  /// **'Gives extra STØ rating'**
  String get dugnadBadgeHowVeteranStep3;

  /// No description provided for @dugnadBadgeHowSeasonAmbassador.
  ///
  /// In en, this message translates to:
  /// **'Refer 5 new members during the current season. Resets at season end.'**
  String get dugnadBadgeHowSeasonAmbassador;

  /// No description provided for @dugnadBadgeHowSeasonAmbassadorStep1.
  ///
  /// In en, this message translates to:
  /// **'Share your referral link'**
  String get dugnadBadgeHowSeasonAmbassadorStep1;

  /// No description provided for @dugnadBadgeHowSeasonAmbassadorStep2.
  ///
  /// In en, this message translates to:
  /// **'5 referrals this season'**
  String get dugnadBadgeHowSeasonAmbassadorStep2;

  /// No description provided for @dugnadBadgeHowSeasonAmbassadorStep3.
  ///
  /// In en, this message translates to:
  /// **'Renews every season'**
  String get dugnadBadgeHowSeasonAmbassadorStep3;

  /// No description provided for @dugnadBadgeHowMissionsMaster.
  ///
  /// In en, this message translates to:
  /// **'Complete 8 weekly missions during the season. New missions every week.'**
  String get dugnadBadgeHowMissionsMaster;

  /// No description provided for @dugnadBadgeHowMissionsMasterStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Matches of the week'**
  String get dugnadBadgeHowMissionsMasterStep1;

  /// No description provided for @dugnadBadgeHowMissionsMasterStep2.
  ///
  /// In en, this message translates to:
  /// **'Complete 8 missions'**
  String get dugnadBadgeHowMissionsMasterStep2;

  /// No description provided for @dugnadBadgeHowMissionsMasterStep3.
  ///
  /// In en, this message translates to:
  /// **'Renews every season'**
  String get dugnadBadgeHowMissionsMasterStep3;

  /// No description provided for @dugnadBadgeHowClubEngaged.
  ///
  /// In en, this message translates to:
  /// **'Stay active for your club through the season — log in, participate and support.'**
  String get dugnadBadgeHowClubEngaged;

  /// No description provided for @dugnadBadgeHowClubEngagedStep1.
  ///
  /// In en, this message translates to:
  /// **'Stay regularly active'**
  String get dugnadBadgeHowClubEngagedStep1;

  /// No description provided for @dugnadBadgeHowClubEngagedStep2.
  ///
  /// In en, this message translates to:
  /// **'Support your club'**
  String get dugnadBadgeHowClubEngagedStep2;

  /// No description provided for @dugnadBadgeHowClubEngagedStep3.
  ///
  /// In en, this message translates to:
  /// **'Renews every season'**
  String get dugnadBadgeHowClubEngagedStep3;

  /// No description provided for @dugnadBadgeHowFormWeek.
  ///
  /// In en, this message translates to:
  /// **'Stay in full shape for 10 weeks during the season. Shape is built with daily activity.'**
  String get dugnadBadgeHowFormWeek;

  /// No description provided for @dugnadBadgeHowFormWeekStep1.
  ///
  /// In en, this message translates to:
  /// **'Be active every week'**
  String get dugnadBadgeHowFormWeekStep1;

  /// No description provided for @dugnadBadgeHowFormWeekStep2.
  ///
  /// In en, this message translates to:
  /// **'10 weeks in full shape'**
  String get dugnadBadgeHowFormWeekStep2;

  /// No description provided for @dugnadBadgeHowFormWeekStep3.
  ///
  /// In en, this message translates to:
  /// **'Renews every season'**
  String get dugnadBadgeHowFormWeekStep3;

  /// No description provided for @dugnadBadgeHowSeasonTop.
  ///
  /// In en, this message translates to:
  /// **'Reach top 3 on your team in the season standings. Compete with teammates.'**
  String get dugnadBadgeHowSeasonTop;

  /// No description provided for @dugnadBadgeHowSeasonTopStep1.
  ///
  /// In en, this message translates to:
  /// **'Collect season points'**
  String get dugnadBadgeHowSeasonTopStep1;

  /// No description provided for @dugnadBadgeHowSeasonTopStep2.
  ///
  /// In en, this message translates to:
  /// **'Climb to top 3'**
  String get dugnadBadgeHowSeasonTopStep2;

  /// No description provided for @dugnadBadgeHowSeasonTopStep3.
  ///
  /// In en, this message translates to:
  /// **'Renews every season'**
  String get dugnadBadgeHowSeasonTopStep3;

  /// No description provided for @dugnadBadgeHowFirstPurchase.
  ///
  /// In en, this message translates to:
  /// **'Complete your first paid campaign order. One box is enough.'**
  String get dugnadBadgeHowFirstPurchase;

  /// No description provided for @dugnadBadgeHowFirstPurchaseStep1.
  ///
  /// In en, this message translates to:
  /// **'Open a campaign'**
  String get dugnadBadgeHowFirstPurchaseStep1;

  /// No description provided for @dugnadBadgeHowFirstPurchaseStep2.
  ///
  /// In en, this message translates to:
  /// **'Buy a meal box'**
  String get dugnadBadgeHowFirstPurchaseStep2;

  /// No description provided for @dugnadBadgeHowFirstPurchaseStep3.
  ///
  /// In en, this message translates to:
  /// **'Yours forever after the first purchase'**
  String get dugnadBadgeHowFirstPurchaseStep3;

  /// No description provided for @dugnadBadgeHowPurchaseHattrick.
  ///
  /// In en, this message translates to:
  /// **'Buy 3 campaign boxes in total. They can be in one order or several.'**
  String get dugnadBadgeHowPurchaseHattrick;

  /// No description provided for @dugnadBadgeHowPurchaseHattrickStep1.
  ///
  /// In en, this message translates to:
  /// **'Order campaign boxes'**
  String get dugnadBadgeHowPurchaseHattrickStep1;

  /// No description provided for @dugnadBadgeHowPurchaseHattrickStep2.
  ///
  /// In en, this message translates to:
  /// **'Reach 3 boxes in total'**
  String get dugnadBadgeHowPurchaseHattrickStep2;

  /// No description provided for @dugnadBadgeHowPurchaseHattrickStep3.
  ///
  /// In en, this message translates to:
  /// **'Hat-trick badge unlocks'**
  String get dugnadBadgeHowPurchaseHattrickStep3;

  /// No description provided for @dugnadBadgeHowTenBoxes.
  ///
  /// In en, this message translates to:
  /// **'Buy 10 campaign boxes in total. Every paid box counts.'**
  String get dugnadBadgeHowTenBoxes;

  /// No description provided for @dugnadBadgeHowTenBoxesStep1.
  ///
  /// In en, this message translates to:
  /// **'Keep ordering campaign boxes'**
  String get dugnadBadgeHowTenBoxesStep1;

  /// No description provided for @dugnadBadgeHowTenBoxesStep2.
  ///
  /// In en, this message translates to:
  /// **'Reach 10 boxes in total'**
  String get dugnadBadgeHowTenBoxesStep2;

  /// No description provided for @dugnadBadgeHowTenBoxesStep3.
  ///
  /// In en, this message translates to:
  /// **'A keepsake badge — never lost'**
  String get dugnadBadgeHowTenBoxesStep3;

  /// No description provided for @dugnadPointsChip.
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String dugnadPointsChip(int points);

  /// No description provided for @dugnadSwipeForOffers.
  ///
  /// In en, this message translates to:
  /// **'Swipe for offers'**
  String get dugnadSwipeForOffers;

  /// No description provided for @dugnadYouSupport.
  ///
  /// In en, this message translates to:
  /// **'You support {clubName}'**
  String dugnadYouSupport(String clubName);

  /// No description provided for @dugnadViewMemberOffers.
  ///
  /// In en, this message translates to:
  /// **'View your member offers'**
  String get dugnadViewMemberOffers;

  /// No description provided for @dugnadMemberDiscountsLocked.
  ///
  /// In en, this message translates to:
  /// **'Member discounts are locked'**
  String get dugnadMemberDiscountsLocked;

  /// No description provided for @dugnadUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get dugnadUnlock;

  /// No description provided for @dugnadMemberNumber.
  ///
  /// In en, this message translates to:
  /// **'Member #{number}'**
  String dugnadMemberNumber(String number);

  /// No description provided for @dugnadShopAtSponsors.
  ///
  /// In en, this message translates to:
  /// **'Shop at sponsors'**
  String get dugnadShopAtSponsors;

  /// No description provided for @dugnadPercentToClub.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to the club'**
  String dugnadPercentToClub(String percent);

  /// No description provided for @dugnadFundraisingYtd.
  ///
  /// In en, this message translates to:
  /// **'The club has raised {amount} this year'**
  String dugnadFundraisingYtd(String amount);

  /// No description provided for @dugnadReferFriendsToClub.
  ///
  /// In en, this message translates to:
  /// **'Refer friends to {clubName}'**
  String dugnadReferFriendsToClub(String clubName);

  /// No description provided for @dugnadReferFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get more people to support the club — more in the club fund'**
  String get dugnadReferFriendsSubtitle;

  /// No description provided for @dugnadReferralPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Referral links and rewards are coming in a later Dugnad phase.'**
  String get dugnadReferralPlaceholderBody;

  /// No description provided for @dgAuthLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started with Reen Dugnad'**
  String get dgAuthLoginTitle;

  /// No description provided for @dgAuthLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support your sports club — every order gives back to the team.'**
  String get dgAuthLoginSubtitle;

  /// No description provided for @dgAuthRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account and choose your club to start supporting.'**
  String get dgAuthRegisterSubtitle;

  /// No description provided for @dgAuthViaReferralLink.
  ///
  /// In en, this message translates to:
  /// **'Via referral link'**
  String get dgAuthViaReferralLink;

  /// No description provided for @dgAuthOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get dgAuthOrganic;

  /// No description provided for @dgAuthEmailToggle.
  ///
  /// In en, this message translates to:
  /// **'or continue with email'**
  String get dgAuthEmailToggle;

  /// No description provided for @dgAuthBrowseFirst.
  ///
  /// In en, this message translates to:
  /// **'Browse first'**
  String get dgAuthBrowseFirst;

  /// No description provided for @dugnadReferralTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer to the club'**
  String get dugnadReferralTitle;

  /// No description provided for @dugnadReferralYourLink.
  ///
  /// In en, this message translates to:
  /// **'Your referral link'**
  String get dugnadReferralYourLink;

  /// No description provided for @dugnadReferralCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get dugnadReferralCopyLink;

  /// No description provided for @dugnadReferralPromoEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EARN POINTS NOW'**
  String get dugnadReferralPromoEyebrow;

  /// No description provided for @dugnadReferralPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer friends to Reen Dugnad'**
  String get dugnadReferralPromoTitle;

  /// No description provided for @dugnadReferralPromoBenefit.
  ///
  /// In en, this message translates to:
  /// **'+{points} points for every friend who joins — right away.'**
  String dugnadReferralPromoBenefit(int points);

  /// No description provided for @dugnadReferralPromoBenefitBold.
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String dugnadReferralPromoBenefitBold(int points);

  /// No description provided for @dugnadReferralPromoBenefitSuffix.
  ///
  /// In en, this message translates to:
  /// **' for every friend who joins — right away.'**
  String get dugnadReferralPromoBenefitSuffix;

  /// No description provided for @dugnadReferralPromoCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy referral link'**
  String get dugnadReferralPromoCopyLink;

  /// No description provided for @dugnadReferralPromoLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get dugnadReferralPromoLinkCopied;

  /// No description provided for @dugnadReferralPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'You earn points for each friend'**
  String get dugnadReferralPointsTitle;

  /// No description provided for @dugnadReferralPointsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Points are added when your friend completes their first purchase (+{points}).'**
  String dugnadReferralPointsSubtitle(int points);

  /// No description provided for @dugnadReferralConvertedCount.
  ///
  /// In en, this message translates to:
  /// **'referred to the club'**
  String get dugnadReferralConvertedCount;

  /// No description provided for @dugnadReferralPointsPerConversion.
  ///
  /// In en, this message translates to:
  /// **'points per conversion'**
  String get dugnadReferralPointsPerConversion;

  /// No description provided for @dugnadReferralAmbassadorTitle.
  ///
  /// In en, this message translates to:
  /// **'Club ambassador'**
  String get dugnadReferralAmbassadorTitle;

  /// No description provided for @dugnadReferralAmbassadorProgress.
  ///
  /// In en, this message translates to:
  /// **'Refer {count} more to unlock the badge'**
  String dugnadReferralAmbassadorProgress(int count);

  /// No description provided for @dugnadReferralAmbassadorDone.
  ///
  /// In en, this message translates to:
  /// **'You are a club ambassador'**
  String get dugnadReferralAmbassadorDone;

  /// No description provided for @dugnadReferralHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get dugnadReferralHowItWorks;

  /// No description provided for @dugnadReferralStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Share your link'**
  String get dugnadReferralStep1Title;

  /// No description provided for @dugnadReferralStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Send it to family, neighbours and friends'**
  String get dugnadReferralStep1Subtitle;

  /// No description provided for @dugnadReferralStep2Title.
  ///
  /// In en, this message translates to:
  /// **'They join the club'**
  String get dugnadReferralStep2Title;

  /// No description provided for @dugnadReferralStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'They sign up and choose {club}'**
  String dugnadReferralStep2Subtitle(String club);

  /// No description provided for @dugnadReferralStep3Title.
  ///
  /// In en, this message translates to:
  /// **'The club earns — for good'**
  String get dugnadReferralStep3Title;

  /// No description provided for @dugnadReferralStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'{club} gets a share of everything they buy'**
  String dugnadReferralStep3Subtitle(String club);

  /// No description provided for @dugnadReferralYourRecruits.
  ///
  /// In en, this message translates to:
  /// **'Your referrals'**
  String get dugnadReferralYourRecruits;

  /// No description provided for @dugnadReferralPendingInvite.
  ///
  /// In en, this message translates to:
  /// **'Invited · waiting'**
  String get dugnadReferralPendingInvite;

  /// No description provided for @dugnadReferralPending.
  ///
  /// In en, this message translates to:
  /// **'Not registered yet'**
  String get dugnadReferralPending;

  /// No description provided for @dugnadReferralWaitingFirstPurchase.
  ///
  /// In en, this message translates to:
  /// **'Registered · waiting for first order'**
  String get dugnadReferralWaitingFirstPurchase;

  /// No description provided for @dugnadReferralActive.
  ///
  /// In en, this message translates to:
  /// **'Supporting now'**
  String get dugnadReferralActive;

  /// No description provided for @dugnadReferralInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name} ✓'**
  String dugnadReferralInvitedBy(String name);

  /// No description provided for @dugnadWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations as a new user of the Reen Dugnad app!'**
  String get dugnadWelcomeTitle;

  /// No description provided for @dugnadWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your sports team is lucky to have people like you 💜'**
  String get dugnadWelcomeSubtitle;

  /// No description provided for @dugnadWelcomeCta.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get dugnadWelcomeCta;

  /// No description provided for @dugnadWelcomeBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'points welcome bonus'**
  String get dugnadWelcomeBonusLabel;

  /// No description provided for @dugnadWelcomeBonusPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'welcome bonus waiting'**
  String get dugnadWelcomeBonusPendingLabel;

  /// No description provided for @dugnadWelcomeBonusPendingTip.
  ///
  /// In en, this message translates to:
  /// **'You will receive +30 points when you choose which team to support under Profile.'**
  String get dugnadWelcomeBonusPendingTip;

  /// No description provided for @dugnadWelcomeTip.
  ///
  /// In en, this message translates to:
  /// **'You start with a small head start — so the gap to the veterans feels manageable from day one.'**
  String get dugnadWelcomeTip;

  /// No description provided for @dugnadReferralInvitedToClub.
  ///
  /// In en, this message translates to:
  /// **'You are invited to {club}'**
  String dugnadReferralInvitedToClub(String club);

  /// No description provided for @dugnadReferralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get dugnadReferralCodeLabel;

  /// No description provided for @dugnadReferralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter code from a friend'**
  String get dugnadReferralCodeHint;

  /// No description provided for @dugnadReferralCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code is not valid.'**
  String get dugnadReferralCodeInvalid;

  /// No description provided for @dugnadReferralCodeSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot use your own code.'**
  String get dugnadReferralCodeSelf;

  /// No description provided for @dugnadReferralHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code?'**
  String get dugnadReferralHaveCode;

  /// No description provided for @dugnadReferralShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join {club} on Reen Dugnad! Use my link {link} or code {code}.'**
  String dugnadReferralShareMessage(String club, String link, String code);

  /// No description provided for @dugnadReferralShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Support {club} with Reen Dugnad'**
  String dugnadReferralShareSubject(String club);

  /// No description provided for @dugnadLeagueCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the team competition'**
  String get dugnadLeagueCtaTitle;

  /// No description provided for @dugnadLeagueCtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See how the teams are doing'**
  String get dugnadLeagueCtaSubtitle;

  /// No description provided for @dugnadLeagueTeamRankTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} are #{rank}'**
  String dugnadLeagueTeamRankTitle(String team, int rank);

  /// No description provided for @dugnadLeagueTeamRankSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Team competition · {club}'**
  String dugnadLeagueTeamRankSubtitle(String club);

  /// No description provided for @dugnadMissionsEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches of the week'**
  String get dugnadMissionsEntryTitle;

  /// No description provided for @dugnadMissionsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Streak, form and season goals'**
  String get dugnadMissionsEntrySubtitle;

  /// No description provided for @dugnadFormEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shape · {status}'**
  String dugnadFormEntryTitle(String status);

  /// No description provided for @dugnadFormStatusUp.
  ///
  /// In en, this message translates to:
  /// **'In shape'**
  String get dugnadFormStatusUp;

  /// No description provided for @dugnadFormStatusFlat.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get dugnadFormStatusFlat;

  /// No description provided for @dugnadFormStatusDown.
  ///
  /// In en, this message translates to:
  /// **'Out of shape'**
  String get dugnadFormStatusDown;

  /// No description provided for @dugnadFormEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build shape with daily activities and assignments'**
  String get dugnadFormEntrySubtitle;

  /// No description provided for @dugnadFormPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Your form'**
  String get dugnadFormPageTitle;

  /// No description provided for @dugnadFormPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Built only on activity in the app'**
  String get dugnadFormPageSubtitle;

  /// No description provided for @dugnadFormSeasonGraphTitle.
  ///
  /// In en, this message translates to:
  /// **'Form through the season'**
  String get dugnadFormSeasonGraphTitle;

  /// No description provided for @dugnadFormStateUpDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'re building form — keep it going!'**
  String get dugnadFormStateUpDesc;

  /// No description provided for @dugnadFormStateFlatDesc.
  ///
  /// In en, this message translates to:
  /// **'Your form is stable. One mission lifts you.'**
  String get dugnadFormStateFlatDesc;

  /// No description provided for @dugnadFormStateDownDesc.
  ///
  /// In en, this message translates to:
  /// **'Your form is falling. Complete a mission to turn it around.'**
  String get dugnadFormStateDownDesc;

  /// No description provided for @dugnadFormPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to preview form states'**
  String get dugnadFormPreviewHint;

  /// No description provided for @dugnadFormWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Your form is about to fall'**
  String get dugnadFormWarningTitle;

  /// No description provided for @dugnadFormWarningSub.
  ///
  /// In en, this message translates to:
  /// **'Complete a mission this week to turn it around'**
  String get dugnadFormWarningSub;

  /// No description provided for @dugnadFormBuildSection.
  ///
  /// In en, this message translates to:
  /// **'How you build form'**
  String get dugnadFormBuildSection;

  /// No description provided for @dugnadFormBuildLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily login'**
  String get dugnadFormBuildLoginTitle;

  /// No description provided for @dugnadFormBuildLoginSub.
  ///
  /// In en, this message translates to:
  /// **'Open the app every day'**
  String get dugnadFormBuildLoginSub;

  /// No description provided for @dugnadFormBuildMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Take part in weekly missions'**
  String get dugnadFormBuildMissionTitle;

  /// No description provided for @dugnadFormBuildMissionSub.
  ///
  /// In en, this message translates to:
  /// **'Weekly matches give the most form'**
  String get dugnadFormBuildMissionSub;

  /// No description provided for @dugnadFormBuildReferTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer a friend'**
  String get dugnadFormBuildReferTitle;

  /// No description provided for @dugnadFormBuildReferSub.
  ///
  /// In en, this message translates to:
  /// **'Bring more supporters on board'**
  String get dugnadFormBuildReferSub;

  /// No description provided for @dugnadFormBuildShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share the supporter card'**
  String get dugnadFormBuildShareTitle;

  /// No description provided for @dugnadFormBuildShareSub.
  ///
  /// In en, this message translates to:
  /// **'Spread the word about the team'**
  String get dugnadFormBuildShareSub;

  /// No description provided for @dugnadFormBuildStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak'**
  String get dugnadFormBuildStreakTitle;

  /// No description provided for @dugnadFormBuildStreakSub.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break your run of active weeks'**
  String get dugnadFormBuildStreakSub;

  /// No description provided for @dugnadFormBuildChip.
  ///
  /// In en, this message translates to:
  /// **'+form'**
  String get dugnadFormBuildChip;

  /// No description provided for @dugnadFormBuildChipPoints.
  ///
  /// In en, this message translates to:
  /// **'+{points} form'**
  String dugnadFormBuildChipPoints(int points);

  /// No description provided for @dugnadFormWhyRisingTitle.
  ///
  /// In en, this message translates to:
  /// **'Why is the rating rising?'**
  String get dugnadFormWhyRisingTitle;

  /// No description provided for @dugnadFormWhyFallingTitle.
  ///
  /// In en, this message translates to:
  /// **'Why is the rating falling?'**
  String get dugnadFormWhyFallingTitle;

  /// No description provided for @dugnadFormWhyFlatTitle.
  ///
  /// In en, this message translates to:
  /// **'Why is the rating standing still?'**
  String get dugnadFormWhyFlatTitle;

  /// No description provided for @dugnadFormLiftSection.
  ///
  /// In en, this message translates to:
  /// **'How you lift form'**
  String get dugnadFormLiftSection;

  /// No description provided for @dugnadFormArrowExplainerPrefix.
  ///
  /// In en, this message translates to:
  /// **'The arrow shows '**
  String get dugnadFormArrowExplainerPrefix;

  /// No description provided for @dugnadFormArrowExplainerBold.
  ///
  /// In en, this message translates to:
  /// **'your form'**
  String get dugnadFormArrowExplainerBold;

  /// No description provided for @dugnadFormArrowExplainerSuffix.
  ///
  /// In en, this message translates to:
  /// **' — the part of the STØ rating that moves. It rises with activity in the app and falls slowly in quiet periods. Payment and membership never affect it.'**
  String get dugnadFormArrowExplainerSuffix;

  /// No description provided for @dugnadFormInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Form, points and rating are built only on what you do in the app. Ending a membership never affects your form.'**
  String get dugnadFormInfoBanner;

  /// No description provided for @dugnadFormTeamRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a team under Your points to see your form.'**
  String get dugnadFormTeamRequired;

  /// No description provided for @dugnadKapteinTitle.
  ///
  /// In en, this message translates to:
  /// **'You are the captain of {team}'**
  String dugnadKapteinTitle(String team);

  /// No description provided for @dugnadKapteinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The team\'s top contributor this season'**
  String get dugnadKapteinSubtitle;

  /// No description provided for @dugnadKapteinBadge.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get dugnadKapteinBadge;

  /// No description provided for @dugnadPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'You are a player on {team}'**
  String dugnadPlayerTitle(String team);

  /// No description provided for @dugnadPlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earn points and climb the leaderboard'**
  String get dugnadPlayerSubtitle;

  /// No description provided for @dugnadPlayerBadge.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get dugnadPlayerBadge;

  /// No description provided for @dugnadTransferBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'The transfer window is open ⏳'**
  String get dugnadTransferBannerTitle;

  /// No description provided for @dugnadTransferBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Closes in {days} days · move up or change club'**
  String dugnadTransferBannerSubtitle(int days);

  /// No description provided for @dugnadTransferBannerSubtitleSoon.
  ///
  /// In en, this message translates to:
  /// **'Closing soon · move up or change club'**
  String get dugnadTransferBannerSubtitleSoon;

  /// No description provided for @dugnadSupportClubFast.
  ///
  /// In en, this message translates to:
  /// **'Support {club} firmly'**
  String dugnadSupportClubFast(String club);

  /// No description provided for @dugnadSupportClubFastSub.
  ///
  /// In en, this message translates to:
  /// **'Monthly support — earn points'**
  String get dugnadSupportClubFastSub;

  /// No description provided for @dugnadManageSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage regular support'**
  String get dugnadManageSupportTitle;

  /// No description provided for @dugnadLeaguePlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard and season tables will be built after team attribution.'**
  String get dugnadLeaguePlaceholderBody;

  /// No description provided for @dugnadLeaderboardSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Team competition'**
  String get dugnadLeaderboardSectionTitle;

  /// No description provided for @dugnadMembershipSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get dugnadMembershipSectionTitle;

  /// No description provided for @dugnadLeaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Team competition'**
  String get dugnadLeaderboardTitle;

  /// No description provided for @dugnadLeaderboardProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a team and follow the competition'**
  String get dugnadLeaderboardProfileSubtitle;

  /// No description provided for @dugnadLeaderboardSeasonEnds.
  ///
  /// In en, this message translates to:
  /// **'Season ends {date}'**
  String dugnadLeaderboardSeasonEnds(String date);

  /// No description provided for @dugnadLeaderboardSeasonPrizeLabel.
  ///
  /// In en, this message translates to:
  /// **'SEASONAL PRIZES'**
  String get dugnadLeaderboardSeasonPrizeLabel;

  /// No description provided for @dugnadLeaderboardSeasonPrizeAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} kr'**
  String dugnadLeaderboardSeasonPrizeAmount(String amount);

  /// No description provided for @dugnadLeaderboardSeasonPrizeNote.
  ///
  /// In en, this message translates to:
  /// **'Tap to see all prizes — from Reen Dugnad'**
  String get dugnadLeaderboardSeasonPrizeNote;

  /// No description provided for @dugnadLeaderboardChooseAnotherClub.
  ///
  /// In en, this message translates to:
  /// **'Choose another club'**
  String get dugnadLeaderboardChooseAnotherClub;

  /// No description provided for @dugnadLeaderboardChooseTeamInClub.
  ///
  /// In en, this message translates to:
  /// **'Choose your team in {clubName}'**
  String dugnadLeaderboardChooseTeamInClub(String clubName);

  /// No description provided for @dugnadLeaderboardChooseTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow your team\'s ranking and collect points'**
  String get dugnadLeaderboardChooseTeamSubtitle;

  /// No description provided for @dugnadLeaderboardYourTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow your team\'s ranking and collect points'**
  String get dugnadLeaderboardYourTeamSubtitle;

  /// No description provided for @dugnadLeaderboardRankHeader.
  ///
  /// In en, this message translates to:
  /// **'RANKING'**
  String get dugnadLeaderboardRankHeader;

  /// No description provided for @dugnadLeaderboardPointsHeader.
  ///
  /// In en, this message translates to:
  /// **'TEAM POINTS'**
  String get dugnadLeaderboardPointsHeader;

  /// No description provided for @dugnadLeaderboardKrRaised.
  ///
  /// In en, this message translates to:
  /// **'{amount} kr'**
  String dugnadLeaderboardKrRaised(String amount);

  /// No description provided for @dugnadLeaderboardActiveFamilies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active supporter} other{{count} active supporters}}'**
  String dugnadLeaderboardActiveFamilies(int count);

  /// No description provided for @dugnadLeaderboardPointsValue.
  ///
  /// In en, this message translates to:
  /// **'{points} POINTS'**
  String dugnadLeaderboardPointsValue(String points);

  /// No description provided for @dugnadLeaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No team points yet this season.'**
  String get dugnadLeaderboardEmpty;

  /// No description provided for @dugnadLeaderboardNoClub.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to see the team competition.'**
  String get dugnadLeaderboardNoClub;

  /// No description provided for @dugnadLeaderboardGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your points\nfollow your account'**
  String get dugnadLeaderboardGuestTitle;

  /// No description provided for @dugnadLeaderboardGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Teams in the club compete for prizes throughout the season. With an account your purchases count for your team on the table.'**
  String get dugnadLeaderboardGuestBody;

  /// No description provided for @dugnadLeaderboardGuestStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get dugnadLeaderboardGuestStep1Title;

  /// No description provided for @dugnadLeaderboardGuestStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Your points are saved to your account'**
  String get dugnadLeaderboardGuestStep1Body;

  /// No description provided for @dugnadLeaderboardGuestStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Choose your team'**
  String get dugnadLeaderboardGuestStep2Title;

  /// No description provided for @dugnadLeaderboardGuestStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Your points go to that team'**
  String get dugnadLeaderboardGuestStep2Body;

  /// No description provided for @dugnadLeaderboardGuestStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Follow the season'**
  String get dugnadLeaderboardGuestStep3Title;

  /// No description provided for @dugnadLeaderboardGuestStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Top scorer, assists and prize zone'**
  String get dugnadLeaderboardGuestStep3Body;

  /// No description provided for @dugnadLeaderboardGuestCta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get dugnadLeaderboardGuestCta;

  /// No description provided for @dugnadLeaderboardGuestHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to join'**
  String get dugnadLeaderboardGuestHeroSubtitle;

  /// No description provided for @dugnadLeaderboardTabTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get dugnadLeaderboardTabTable;

  /// No description provided for @dugnadLeaderboardTabTopScorer.
  ///
  /// In en, this message translates to:
  /// **'Top scorer'**
  String get dugnadLeaderboardTabTopScorer;

  /// No description provided for @dugnadLeaderboardTabAssistKing.
  ///
  /// In en, this message translates to:
  /// **'Assist king'**
  String get dugnadLeaderboardTabAssistKing;

  /// No description provided for @dugnadLeaderboardTabValue.
  ///
  /// In en, this message translates to:
  /// **'STØ'**
  String get dugnadLeaderboardTabValue;

  /// No description provided for @dugnadLeaderboardValueTitle.
  ///
  /// In en, this message translates to:
  /// **'STØ ranking'**
  String get dugnadLeaderboardValueTitle;

  /// No description provided for @dugnadLeaderboardTableTitle.
  ///
  /// In en, this message translates to:
  /// **'{club} table'**
  String dugnadLeaderboardTableTitle(String club);

  /// No description provided for @dugnadLeaderboardInternalSeries.
  ///
  /// In en, this message translates to:
  /// **'{count} teams · internal series'**
  String dugnadLeaderboardInternalSeries(int count);

  /// No description provided for @dugnadLeaderboardTeamHeader.
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get dugnadLeaderboardTeamHeader;

  /// No description provided for @dugnadLeaderboardPrizeZone.
  ///
  /// In en, this message translates to:
  /// **'PRIZE ZONE'**
  String get dugnadLeaderboardPrizeZone;

  /// No description provided for @dugnadLeaderboardPrizeZoneTop.
  ///
  /// In en, this message translates to:
  /// **'TOP {count}'**
  String dugnadLeaderboardPrizeZoneTop(int count);

  /// No description provided for @dugnadLeaderboardYourTeamTag.
  ///
  /// In en, this message translates to:
  /// **'YOUR TEAM'**
  String get dugnadLeaderboardYourTeamTag;

  /// No description provided for @dugnadLeaderboardGapToZone.
  ///
  /// In en, this message translates to:
  /// **'{points} points away from the prize zone'**
  String dugnadLeaderboardGapToZone(String points);

  /// No description provided for @dugnadLeaderboardFilterClub.
  ///
  /// In en, this message translates to:
  /// **'The whole club'**
  String get dugnadLeaderboardFilterClub;

  /// No description provided for @dugnadLeaderboardFilterMyTeam.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get dugnadLeaderboardFilterMyTeam;

  /// No description provided for @dugnadLeaderboardScorerCapGoals.
  ///
  /// In en, this message translates to:
  /// **'RANKED ON GOALS — CAMPAIGN PURCHASES'**
  String get dugnadLeaderboardScorerCapGoals;

  /// No description provided for @dugnadLeaderboardScorerCapAssists.
  ///
  /// In en, this message translates to:
  /// **'RANKED ON ASSISTS — REFERRALS'**
  String get dugnadLeaderboardScorerCapAssists;

  /// No description provided for @dugnadLeaderboardScorerCapValue.
  ///
  /// In en, this message translates to:
  /// **'Ranked by STØ rating'**
  String get dugnadLeaderboardScorerCapValue;

  /// No description provided for @dugnadLeaderboardScorerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contributors in {team} yet.'**
  String dugnadLeaderboardScorerEmpty(String team);

  /// No description provided for @dugnadLeaderboardYouTag.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get dugnadLeaderboardYouTag;

  /// No description provided for @dugnadLeaderboardGoalUnit.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get dugnadLeaderboardGoalUnit;

  /// No description provided for @dugnadLeaderboardAssistUnit.
  ///
  /// In en, this message translates to:
  /// **'ASSIST'**
  String get dugnadLeaderboardAssistUnit;

  /// No description provided for @dugnadLeaderboardValueUnit.
  ///
  /// In en, this message translates to:
  /// **'STØ'**
  String get dugnadLeaderboardValueUnit;

  /// No description provided for @dugnadLeaderboardYourTeamCardSub.
  ///
  /// In en, this message translates to:
  /// **'{team} · #{rank} of {total}'**
  String dugnadLeaderboardYourTeamCardSub(String team, int rank, int total);

  /// No description provided for @dugnadLeaderboardYourPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your points'**
  String get dugnadLeaderboardYourPointsTitle;

  /// No description provided for @dugnadLeaderboardYourPointsCardSub.
  ///
  /// In en, this message translates to:
  /// **'{points} · {tier}'**
  String dugnadLeaderboardYourPointsCardSub(String points, String tier);

  /// No description provided for @dugnadTeamDetailHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your team'**
  String get dugnadTeamDetailHeroTitle;

  /// No description provided for @dugnadTeamDetailRankOf.
  ///
  /// In en, this message translates to:
  /// **'#{rank} of {total} in {club}'**
  String dugnadTeamDetailRankOf(int rank, int total, String club);

  /// No description provided for @dugnadTeamDetailChangeTeam.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dugnadTeamDetailChangeTeam;

  /// No description provided for @dugnadTeamDetailSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support firmly'**
  String get dugnadTeamDetailSupportTitle;

  /// No description provided for @dugnadTeamDetailSupportSub.
  ///
  /// In en, this message translates to:
  /// **'Fixed monthly support for the team'**
  String get dugnadTeamDetailSupportSub;

  /// No description provided for @dugnadTeamDetailSeasonGoal.
  ///
  /// In en, this message translates to:
  /// **'Towards the season goal'**
  String get dugnadTeamDetailSeasonGoal;

  /// No description provided for @dugnadTeamDetailGoalPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent} % of the target'**
  String dugnadTeamDetailGoalPercent(int percent);

  /// No description provided for @dugnadTeamDetailBreakdownHeading.
  ///
  /// In en, this message translates to:
  /// **'HOW TEAM POINTS ARE BUILT'**
  String get dugnadTeamDetailBreakdownHeading;

  /// No description provided for @dugnadTeamDetailBreakdownCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get dugnadTeamDetailBreakdownCampaigns;

  /// No description provided for @dugnadTeamDetailBreakdownCampaignsSub.
  ///
  /// In en, this message translates to:
  /// **'Collected via food boxes'**
  String get dugnadTeamDetailBreakdownCampaignsSub;

  /// No description provided for @dugnadTeamDetailBreakdownEngagement.
  ///
  /// In en, this message translates to:
  /// **'Everyday purchases'**
  String get dugnadTeamDetailBreakdownEngagement;

  /// No description provided for @dugnadTeamDetailBreakdownEngagementSub.
  ///
  /// In en, this message translates to:
  /// **'Sponsor engagement'**
  String get dugnadTeamDetailBreakdownEngagementSub;

  /// No description provided for @dugnadTeamDetailBreakdownParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get dugnadTeamDetailBreakdownParticipation;

  /// No description provided for @dugnadTeamDetailBreakdownParticipationSub.
  ///
  /// In en, this message translates to:
  /// **'{families} supporters active'**
  String dugnadTeamDetailBreakdownParticipationSub(int families);

  /// No description provided for @dugnadTeamDetailClimbTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you climb?'**
  String get dugnadTeamDetailClimbTitle;

  /// No description provided for @dugnadTeamDetailClimbReferrals.
  ///
  /// In en, this message translates to:
  /// **'Recruit supporters'**
  String get dugnadTeamDetailClimbReferrals;

  /// No description provided for @dugnadTeamDetailClimbReferralsSub.
  ///
  /// In en, this message translates to:
  /// **'More active supporters = more breadth points'**
  String get dugnadTeamDetailClimbReferralsSub;

  /// No description provided for @dugnadTeamDetailClimbSponsors.
  ///
  /// In en, this message translates to:
  /// **'Buy through sponsors'**
  String get dugnadTeamDetailClimbSponsors;

  /// No description provided for @dugnadTeamDetailClimbSponsorsSub.
  ///
  /// In en, this message translates to:
  /// **'Everyday purchases give engagement points to the team'**
  String get dugnadTeamDetailClimbSponsorsSub;

  /// No description provided for @dugnadTeamDetailClimbCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Participate in promotions'**
  String get dugnadTeamDetailClimbCampaigns;

  /// No description provided for @dugnadTeamDetailClimbCampaignsSub.
  ///
  /// In en, this message translates to:
  /// **'Food boxes give the most team points'**
  String get dugnadTeamDetailClimbCampaignsSub;

  /// No description provided for @dugnadTeamDetailYourPointsSub.
  ///
  /// In en, this message translates to:
  /// **'See level and how you contribute'**
  String get dugnadTeamDetailYourPointsSub;

  /// No description provided for @dugnadMemberOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Member offers'**
  String get dugnadMemberOffersTitle;

  /// No description provided for @dugnadMemberOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discounts active'**
  String get dugnadMemberOffersSubtitle;

  /// No description provided for @dugnadMemberOffersPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This surface is a placeholder and will be connected later.'**
  String get dugnadMemberOffersPlaceholderBody;

  /// No description provided for @dugnadFastSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support regularly'**
  String get dugnadFastSupportTitle;

  /// No description provided for @dugnadFastSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly support — baseline'**
  String get dugnadFastSupportSubtitle;

  /// No description provided for @dugnadFastSupportPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Vipps recurring for regular support is being built.'**
  String get dugnadFastSupportPlaceholderBody;

  /// No description provided for @dugnadDonationHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Regular monthly support for the team'**
  String get dugnadDonationHeroSubtitle;

  /// No description provided for @dugnadDonationWhoSupport.
  ///
  /// In en, this message translates to:
  /// **'Who do you want to support?'**
  String get dugnadDonationWhoSupport;

  /// No description provided for @dugnadDonationWholeClub.
  ///
  /// In en, this message translates to:
  /// **'The whole club'**
  String get dugnadDonationWholeClub;

  /// No description provided for @dugnadDonationWholeClubShort.
  ///
  /// In en, this message translates to:
  /// **'CLUB'**
  String get dugnadDonationWholeClubShort;

  /// No description provided for @dugnadDonationTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get dugnadDonationTeamLabel;

  /// No description provided for @dugnadDonationTeamInClub.
  ///
  /// In en, this message translates to:
  /// **'Team in {club}'**
  String dugnadDonationTeamInClub(String club);

  /// No description provided for @dugnadDonationSearchTeams.
  ///
  /// In en, this message translates to:
  /// **'Search for a team …'**
  String get dugnadDonationSearchTeams;

  /// No description provided for @dugnadDonationMonthlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly amount'**
  String get dugnadDonationMonthlyAmount;

  /// No description provided for @dugnadDonationOtherAmount.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get dugnadDonationOtherAmount;

  /// No description provided for @dugnadDonationAmountKr.
  ///
  /// In en, this message translates to:
  /// **'{amount} kr'**
  String dugnadDonationAmountKr(int amount);

  /// No description provided for @dugnadDonationCurrencyPerMonth.
  ///
  /// In en, this message translates to:
  /// **'kr/month'**
  String get dugnadDonationCurrencyPerMonth;

  /// No description provided for @dugnadDonationCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get dugnadDonationCustomHint;

  /// No description provided for @dugnadDonationTierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get dugnadDonationTierBronze;

  /// No description provided for @dugnadDonationTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get dugnadDonationTierSilver;

  /// No description provided for @dugnadDonationTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get dugnadDonationTierGold;

  /// No description provided for @dugnadDonationTierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get dugnadDonationTierPlatinum;

  /// No description provided for @dugnadDonationMinTierBronze.
  ///
  /// In en, this message translates to:
  /// **'Give at least 50 kr/month for Bronze'**
  String get dugnadDonationMinTierBronze;

  /// No description provided for @dugnadDonationAmountToNextTier.
  ///
  /// In en, this message translates to:
  /// **'{amount} kr to {tier}'**
  String dugnadDonationAmountToNextTier(int amount, String tier);

  /// No description provided for @dugnadDonationFeeBreakdownPrefix.
  ///
  /// In en, this message translates to:
  /// **'Of {total} kr/month, '**
  String dugnadDonationFeeBreakdownPrefix(String total);

  /// No description provided for @dugnadDonationFeeBreakdownMiddle.
  ///
  /// In en, this message translates to:
  /// **' goes to {target} · '**
  String dugnadDonationFeeBreakdownMiddle(String target);

  /// No description provided for @dugnadDonationFeeBreakdownSuffix.
  ///
  /// In en, this message translates to:
  /// **'covers payment and operations'**
  String get dugnadDonationFeeBreakdownSuffix;

  /// No description provided for @dugnadDonationWhyFee.
  ///
  /// In en, this message translates to:
  /// **'Why a fee?'**
  String get dugnadDonationWhyFee;

  /// No description provided for @dugnadDonationWhyFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Why a fee?'**
  String get dugnadDonationWhyFeeTitle;

  /// No description provided for @dugnadDonationWhyFeeLead.
  ///
  /// In en, this message translates to:
  /// **'Your full intention goes to the team. A small, transparent fee is deducted and explained honestly:'**
  String get dugnadDonationWhyFeeLead;

  /// No description provided for @dugnadDonationWhyFeeTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction fee'**
  String get dugnadDonationWhyFeeTransactionTitle;

  /// No description provided for @dugnadDonationWhyFeeTransactionBody.
  ///
  /// In en, this message translates to:
  /// **'Covers payment (Vipps/card) and secure handling.'**
  String get dugnadDonationWhyFeeTransactionBody;

  /// No description provided for @dugnadDonationWhyFeePlatformTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations fee'**
  String get dugnadDonationWhyFeePlatformTitle;

  /// No description provided for @dugnadDonationWhyFeePlatformBody.
  ///
  /// In en, this message translates to:
  /// **'Covers running support and development of Reen Dugnad.'**
  String get dugnadDonationWhyFeePlatformBody;

  /// No description provided for @dugnadDonationWhyFeeHeartNote.
  ///
  /// In en, this message translates to:
  /// **'We take the fee to keep Reen Dugnad going — not to profit from your gift.'**
  String get dugnadDonationWhyFeeHeartNote;

  /// No description provided for @dugnadDonationWhyFeeUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get dugnadDonationWhyFeeUnderstand;

  /// No description provided for @dugnadDonationNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'How the support is paid'**
  String get dugnadDonationNudgeTitle;

  /// No description provided for @dugnadDonationHowPaidBody.
  ///
  /// In en, this message translates to:
  /// **'Reen Dugnad sponsors {clubName} and pays out the amount as a sponsorship, earmarked for {teamName}. {clubShort} is responsible for the final support to the team.'**
  String dugnadDonationHowPaidBody(
    String clubName,
    String clubShort,
    String teamName,
  );

  /// No description provided for @dugnadDonationNudgeBodyPrefix.
  ///
  /// In en, this message translates to:
  /// **'You support the team even more when you buy the team\'s '**
  String get dugnadDonationNudgeBodyPrefix;

  /// No description provided for @dugnadDonationNudgeMatkasserLink.
  ///
  /// In en, this message translates to:
  /// **'meal boxes'**
  String get dugnadDonationNudgeMatkasserLink;

  /// No description provided for @dugnadDonationNudgeBodySuffix.
  ///
  /// In en, this message translates to:
  /// **' and refer friends.'**
  String get dugnadDonationNudgeBodySuffix;

  /// No description provided for @dugnadDonationPaymentHeading.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get dugnadDonationPaymentHeading;

  /// No description provided for @dugnadDonationVippsLabel.
  ///
  /// In en, this message translates to:
  /// **'Vipps'**
  String get dugnadDonationVippsLabel;

  /// No description provided for @dugnadDonationVippsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment in the Vipps app'**
  String get dugnadDonationVippsSubtitle;

  /// No description provided for @dugnadDonationSelectTeam.
  ///
  /// In en, this message translates to:
  /// **'Choose a team'**
  String get dugnadDonationSelectTeam;

  /// No description provided for @dugnadDonationNoTeams.
  ///
  /// In en, this message translates to:
  /// **'No teams are available for this club yet. Ask your club admin to add teams in AdminPanel.'**
  String get dugnadDonationNoTeams;

  /// No description provided for @dugnadDonationTerms.
  ///
  /// In en, this message translates to:
  /// **'First charge in one month. Cancel anytime. A failed charge is skipped. Already paid amounts are not refunded.'**
  String get dugnadDonationTerms;

  /// No description provided for @dugnadDonationPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'You earn points every month'**
  String get dugnadDonationPointsTitle;

  /// No description provided for @dugnadDonationPointsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Membership points are added every time the monthly amount is deducted — activity and promotional purchases give even more'**
  String get dugnadDonationPointsSubtitle;

  /// No description provided for @dugnadDonationPointsValue.
  ///
  /// In en, this message translates to:
  /// **'+{points}/month'**
  String dugnadDonationPointsValue(int points);

  /// No description provided for @dugnadDonationPointsUnit.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get dugnadDonationPointsUnit;

  /// No description provided for @dugnadDonationPointsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get dugnadDonationPointsPerMonth;

  /// No description provided for @dugnadDonationSetupButton.
  ///
  /// In en, this message translates to:
  /// **'Set up regular support'**
  String get dugnadDonationSetupButton;

  /// No description provided for @dugnadDonationEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Change fixed support'**
  String get dugnadDonationEditTitle;

  /// No description provided for @dugnadDonationEditButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get dugnadDonationEditButton;

  /// No description provided for @dugnadDonationUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Changes saved. They apply from the next payment.'**
  String get dugnadDonationUpdateSuccess;

  /// No description provided for @dugnadDonationUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes. Please try again.'**
  String get dugnadDonationUpdateFailed;

  /// No description provided for @dugnadDonationUpdateNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Vipps has not confirmed the new amount yet. Try again in a moment.'**
  String get dugnadDonationUpdateNotConfirmed;

  /// No description provided for @dugnadDonationPauseComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Pause is coming soon.'**
  String get dugnadDonationPauseComingSoon;

  /// No description provided for @dugnadDonationManageResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get dugnadDonationManageResume;

  /// No description provided for @dugnadDonationManageSubLinePaused.
  ///
  /// In en, this message translates to:
  /// **'{amount} kr/month · paused'**
  String dugnadDonationManageSubLinePaused(int amount);

  /// No description provided for @dugnadDonationStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get dugnadDonationStatusPaused;

  /// No description provided for @dugnadDonationPauseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Support paused.'**
  String get dugnadDonationPauseSuccess;

  /// No description provided for @dugnadDonationPauseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pause. Please try again.'**
  String get dugnadDonationPauseFailed;

  /// No description provided for @dugnadDonationResumeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Support resumed.'**
  String get dugnadDonationResumeSuccess;

  /// No description provided for @dugnadDonationResumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resume. Please try again.'**
  String get dugnadDonationResumeFailed;

  /// No description provided for @dugnadDonationIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement not completed'**
  String get dugnadDonationIncompleteTitle;

  /// No description provided for @dugnadDonationIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You returned from Vipps without approving the agreement. Nothing was started.'**
  String get dugnadDonationIncompleteBody;

  /// No description provided for @dugnadDonationIncompleteRetry.
  ///
  /// In en, this message translates to:
  /// **'Continue in Vipps'**
  String get dugnadDonationIncompleteRetry;

  /// No description provided for @dugnadDonationIncompleteDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard and go back'**
  String get dugnadDonationIncompleteDiscard;

  /// No description provided for @dugnadDonationSetupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not start support'**
  String get dugnadDonationSetupFailedTitle;

  /// No description provided for @dugnadDonationSetupFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The Vipps agreement was not approved. You can try again from Fast støtte.'**
  String get dugnadDonationSetupFailedBody;

  /// No description provided for @dugnadDonationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get dugnadDonationComingSoon;

  /// No description provided for @dugnadDonationComingSoonBackend.
  ///
  /// In en, this message translates to:
  /// **'Vipps recurring setup is coming soon.'**
  String get dugnadDonationComingSoonBackend;

  /// No description provided for @dugnadDonationManageLink.
  ///
  /// In en, this message translates to:
  /// **'My support'**
  String get dugnadDonationManageLink;

  /// No description provided for @dugnadDonationSyncing.
  ///
  /// In en, this message translates to:
  /// **'Confirming your Vipps agreement…'**
  String get dugnadDonationSyncing;

  /// No description provided for @dugnadDonationSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the agreement. Try again from My support.'**
  String get dugnadDonationSyncFailed;

  /// No description provided for @dugnadDonationCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start regular support. Please try again.'**
  String get dugnadDonationCreateFailed;

  /// No description provided for @dugnadDonationVippsLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Vipps. Please try again.'**
  String get dugnadDonationVippsLaunchFailed;

  /// No description provided for @dugnadDonationVippsError.
  ///
  /// In en, this message translates to:
  /// **'Could not start Vipps agreement. Check that Recurring API is enabled on your test MSN.'**
  String get dugnadDonationVippsError;

  /// No description provided for @dugnadDonationErrorSubscriptionCap.
  ///
  /// In en, this message translates to:
  /// **'You can have at most 3 active subscriptions.'**
  String get dugnadDonationErrorSubscriptionCap;

  /// No description provided for @dugnadDonationErrorDuplicateTarget.
  ///
  /// In en, this message translates to:
  /// **'You already support this team or club.'**
  String get dugnadDonationErrorDuplicateTarget;

  /// No description provided for @dugnadDonationConfirmAppBar.
  ///
  /// In en, this message translates to:
  /// **'Regular support'**
  String get dugnadDonationConfirmAppBar;

  /// No description provided for @dugnadDonationConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support!'**
  String get dugnadDonationConfirmTitle;

  /// No description provided for @dugnadDonationConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your monthly Vipps agreement is active. The first charge is one month from today.'**
  String get dugnadDonationConfirmSubtitle;

  /// No description provided for @dugnadDonationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement pending'**
  String get dugnadDonationPendingTitle;

  /// No description provided for @dugnadDonationPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We are still waiting for Vipps to confirm your agreement.'**
  String get dugnadDonationPendingSubtitle;

  /// No description provided for @dugnadDonationConfirmTarget.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get dugnadDonationConfirmTarget;

  /// No description provided for @dugnadDonationConfirmAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get dugnadDonationConfirmAmount;

  /// No description provided for @dugnadDonationConfirmNextCharge.
  ///
  /// In en, this message translates to:
  /// **'First charge'**
  String get dugnadDonationConfirmNextCharge;

  /// No description provided for @dugnadDonationConfirmManage.
  ///
  /// In en, this message translates to:
  /// **'View my support'**
  String get dugnadDonationConfirmManage;

  /// No description provided for @dugnadDonationConfirmHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get dugnadDonationConfirmHome;

  /// No description provided for @dugnadDonationConfirmThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! 💜'**
  String get dugnadDonationConfirmThanks;

  /// No description provided for @dugnadDonationConfirmSupportLine.
  ///
  /// In en, this message translates to:
  /// **'You support {team} with {amount}'**
  String dugnadDonationConfirmSupportLine(String team, String amount);

  /// No description provided for @dugnadDonationConfirmPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'membership points per month'**
  String get dugnadDonationConfirmPointsLabel;

  /// No description provided for @dugnadDonationConfirmEarmarked.
  ///
  /// In en, this message translates to:
  /// **'Earmarked {team}'**
  String dugnadDonationConfirmEarmarked(String team);

  /// No description provided for @dugnadDonationConfirmOperations.
  ///
  /// In en, this message translates to:
  /// **'Operation & payment'**
  String get dugnadDonationConfirmOperations;

  /// No description provided for @dugnadDonationConfirmReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get dugnadDonationConfirmReady;

  /// No description provided for @dugnadDonationConfirmGiveMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you want to give even more?'**
  String get dugnadDonationConfirmGiveMoreTitle;

  /// No description provided for @dugnadDonationConfirmGiveMoreBody.
  ///
  /// In en, this message translates to:
  /// **'Buy a food box from the team — a portion goes to the club.'**
  String get dugnadDonationConfirmGiveMoreBody;

  /// No description provided for @dugnadSupportShareCardMessage.
  ///
  /// In en, this message translates to:
  /// **'I support {team} firmly 💜'**
  String dugnadSupportShareCardMessage(String team);

  /// No description provided for @dugnadShareSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share that you support the team'**
  String get dugnadShareSheetTitle;

  /// No description provided for @dugnadShareSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get more supporters involved — the team benefits from everyone who joins.'**
  String get dugnadShareSheetSubtitle;

  /// No description provided for @dugnadShareLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load your support card link.'**
  String get dugnadShareLinkUnavailable;

  /// No description provided for @dugnadShareSheetEarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn {points} points'**
  String dugnadShareSheetEarnTitle(int points);

  /// No description provided for @dugnadShareSheetEarnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'when you share with a friend'**
  String get dugnadShareSheetEarnSubtitle;

  /// No description provided for @dugnadShareSheetDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You earned {points} points! 💜'**
  String dugnadShareSheetDoneTitle(int points);

  /// No description provided for @dugnadShareSheetDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for spreading the word about the team.'**
  String get dugnadShareSheetDoneSubtitle;

  /// No description provided for @dugnadDonationManageTitle.
  ///
  /// In en, this message translates to:
  /// **'My regular support'**
  String get dugnadDonationManageTitle;

  /// No description provided for @dugnadDonationManageHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed support'**
  String get dugnadDonationManageHeroTitle;

  /// No description provided for @dugnadDonationManageYouSupport.
  ///
  /// In en, this message translates to:
  /// **'You support'**
  String get dugnadDonationManageYouSupport;

  /// No description provided for @dugnadDonationManageOfTeams.
  ///
  /// In en, this message translates to:
  /// **'of {max} teams'**
  String dugnadDonationManageOfTeams(int max);

  /// No description provided for @dugnadDonationManageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dugnadDonationManageTotal;

  /// No description provided for @dugnadDonationManageKrPerMonthShort.
  ///
  /// In en, this message translates to:
  /// **'kr/month'**
  String get dugnadDonationManageKrPerMonthShort;

  /// No description provided for @dugnadDonationManageSubLine.
  ///
  /// In en, this message translates to:
  /// **'{amount} kr/month · next payment {date}'**
  String dugnadDonationManageSubLine(int amount, String date);

  /// No description provided for @dugnadDonationManageChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dugnadDonationManageChange;

  /// No description provided for @dugnadDonationManagePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get dugnadDonationManagePause;

  /// No description provided for @dugnadDonationManageExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get dugnadDonationManageExit;

  /// No description provided for @dugnadDonationManageAddTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Support another team'**
  String get dugnadDonationManageAddTeamTitle;

  /// No description provided for @dugnadDonationManageAddTeamHint.
  ///
  /// In en, this message translates to:
  /// **'You can support up to 3 teams at the same time'**
  String get dugnadDonationManageAddTeamHint;

  /// No description provided for @dugnadDonationManageMaxNote.
  ///
  /// In en, this message translates to:
  /// **'You support the maximum of 3 teams. Cancel one to switch.'**
  String get dugnadDonationManageMaxNote;

  /// No description provided for @dugnadDonationManageChangesNote.
  ///
  /// In en, this message translates to:
  /// **'Changes will apply from the next payment. Payments already made will not be refunded.'**
  String get dugnadDonationManageChangesNote;

  /// No description provided for @dugnadDonationCancelSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this support?'**
  String get dugnadDonationCancelSheetTitle;

  /// No description provided for @dugnadDonationCancelSheetBody.
  ///
  /// In en, this message translates to:
  /// **'You can set it up again at any time. Remember you still support the team for free when you shop through sponsors.'**
  String get dugnadDonationCancelSheetBody;

  /// No description provided for @dugnadDonationCancelSheetKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get dugnadDonationCancelSheetKeep;

  /// No description provided for @dugnadDonationManageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add support'**
  String get dugnadDonationManageAdd;

  /// No description provided for @dugnadDonationManageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No regular support yet'**
  String get dugnadDonationManageEmpty;

  /// No description provided for @dugnadDonationManageEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Set up monthly Vipps support for your team or club.'**
  String get dugnadDonationManageEmptyHint;

  /// No description provided for @dugnadDonationManageAmountPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} kr/month'**
  String dugnadDonationManageAmountPerMonth(int amount);

  /// No description provided for @dugnadDonationManageNextCharge.
  ///
  /// In en, this message translates to:
  /// **'Next charge: {date}'**
  String dugnadDonationManageNextCharge(String date);

  /// No description provided for @dugnadDonationManageStreak.
  ///
  /// In en, this message translates to:
  /// **'{months} month streak'**
  String dugnadDonationManageStreak(int months);

  /// No description provided for @dugnadDonationStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dugnadDonationStatusActive;

  /// No description provided for @dugnadDonationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dugnadDonationStatusPending;

  /// No description provided for @dugnadDonationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get dugnadDonationStatusCancelled;

  /// No description provided for @dugnadDonationCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dugnadDonationCancelAction;

  /// No description provided for @dugnadDonationCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel regular support?'**
  String get dugnadDonationCancelTitle;

  /// No description provided for @dugnadDonationCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Future charges to {target} will stop. Amounts already paid are not refunded.'**
  String dugnadDonationCancelBody(String target);

  /// No description provided for @dugnadDonationCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel support'**
  String get dugnadDonationCancelConfirm;

  /// No description provided for @dugnadDonationCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Regular support cancelled.'**
  String get dugnadDonationCancelSuccess;

  /// No description provided for @dugnadDonationCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel. Please try again.'**
  String get dugnadDonationCancelFailed;

  /// No description provided for @dugnadDonationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your subscriptions.'**
  String get dugnadDonationLoadFailed;

  /// No description provided for @dugnadMealBoxFromClub.
  ///
  /// In en, this message translates to:
  /// **'Meal box from the club'**
  String get dugnadMealBoxFromClub;

  /// No description provided for @dugnadSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dugnadSeeAll;

  /// No description provided for @dugnadSupportClub.
  ///
  /// In en, this message translates to:
  /// **'Support {clubName}'**
  String dugnadSupportClub(String clubName);

  /// No description provided for @dugnadCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get dugnadCampaign;

  /// No description provided for @dugnadChooseClubFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a club first'**
  String get dugnadChooseClubFirst;

  /// No description provided for @dugnadChooseClubForCampaigns.
  ///
  /// In en, this message translates to:
  /// **'You need to choose a club to see campaigns.'**
  String get dugnadChooseClubForCampaigns;

  /// No description provided for @dugnadNoCampaignsNow.
  ///
  /// In en, this message translates to:
  /// **'No active campaigns right now'**
  String get dugnadNoCampaignsNow;

  /// No description provided for @dugnadCampaignsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned — new meal boxes from {clubName} are coming soon.'**
  String dugnadCampaignsComingSoon(String clubName);

  /// No description provided for @dugnadDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String dugnadDeadline(String date);

  /// No description provided for @dugnadCampaignOrderBy.
  ///
  /// In en, this message translates to:
  /// **'Order by {date}'**
  String dugnadCampaignOrderBy(String date);

  /// No description provided for @dugnadCampaignRaised.
  ///
  /// In en, this message translates to:
  /// **'{amount} raised'**
  String dugnadCampaignRaised(String amount);

  /// No description provided for @dugnadCampaignFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {amount} kr'**
  String dugnadCampaignFromPrice(String amount);

  /// No description provided for @dugnadCampaignSeeBoxes.
  ///
  /// In en, this message translates to:
  /// **'See boxes'**
  String get dugnadCampaignSeeBoxes;

  /// No description provided for @dugnadMembershipSheetDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your membership number to unlock exclusive discounts.'**
  String get dugnadMembershipSheetDesc;

  /// No description provided for @dugnadSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dugnadSave;

  /// No description provided for @dugnadRemoveMembership.
  ///
  /// In en, this message translates to:
  /// **'Remove membership number'**
  String get dugnadRemoveMembership;

  /// No description provided for @dugnadSwitchMode.
  ///
  /// In en, this message translates to:
  /// **'Switch mode'**
  String get dugnadSwitchMode;

  /// No description provided for @dugnadActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now · support your team'**
  String get dugnadActiveNow;

  /// No description provided for @dugnadCommercialComingSoonToast.
  ///
  /// In en, this message translates to:
  /// **'Commercial mode coming soon!'**
  String get dugnadCommercialComingSoonToast;

  /// No description provided for @dugnadOffersComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Offers coming soon'**
  String get dugnadOffersComingSoon;

  /// No description provided for @dugnadOffersComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'re working on exclusive offers from sponsors for your club. Stay tuned!'**
  String get dugnadOffersComingSoonDesc;

  /// No description provided for @dugnadSearchClubHint.
  ///
  /// In en, this message translates to:
  /// **'Search for your club …'**
  String get dugnadSearchClubHint;

  /// No description provided for @dugnadSupporter.
  ///
  /// In en, this message translates to:
  /// **'Supporter'**
  String get dugnadSupporter;

  /// No description provided for @dugnadAddMembership.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dugnadAddMembership;

  /// No description provided for @dugnadNoClubMatch.
  ///
  /// In en, this message translates to:
  /// **'No club matches \"{query}\".'**
  String dugnadNoClubMatch(String query);

  /// No description provided for @dugnadStoreCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 store} other{{count} stores}}'**
  String dugnadStoreCount(int count);

  /// No description provided for @dugnadNoClubSelected.
  ///
  /// In en, this message translates to:
  /// **'No club selected'**
  String get dugnadNoClubSelected;

  /// No description provided for @dugnadSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get dugnadSwitch;

  /// No description provided for @dugnadMemberDiscountsActive.
  ///
  /// In en, this message translates to:
  /// **'Member #{number} · discounts active'**
  String dugnadMemberDiscountsActive(String number);

  /// No description provided for @dugnadAddMembershipNumber.
  ///
  /// In en, this message translates to:
  /// **'Add membership number'**
  String get dugnadAddMembershipNumber;

  /// No description provided for @campaignMatkasser.
  ///
  /// In en, this message translates to:
  /// **'Meal boxes'**
  String get campaignMatkasser;

  /// No description provided for @campaignNoActiveCampaigns.
  ///
  /// In en, this message translates to:
  /// **'No active campaigns right now'**
  String get campaignNoActiveCampaigns;

  /// No description provided for @campaignOrderBefore.
  ///
  /// In en, this message translates to:
  /// **'Order before'**
  String get campaignOrderBefore;

  /// No description provided for @campaignDeliveryDay.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get campaignDeliveryDay;

  /// No description provided for @campaignFromPrice.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get campaignFromPrice;

  /// No description provided for @campaignSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get campaignSupport;

  /// No description provided for @campaignChooseBox.
  ///
  /// In en, this message translates to:
  /// **'Choose box'**
  String get campaignChooseBox;

  /// No description provided for @campaignChooseYourMatkasse.
  ///
  /// In en, this message translates to:
  /// **'Choose your box'**
  String get campaignChooseYourMatkasse;

  /// No description provided for @campaignOrderBy.
  ///
  /// In en, this message translates to:
  /// **'Order by'**
  String get campaignOrderBy;

  /// No description provided for @campaignAllProfitToClub.
  ///
  /// In en, this message translates to:
  /// **'All profits go to the club'**
  String get campaignAllProfitToClub;

  /// No description provided for @campaignViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get campaignViewDetails;

  /// No description provided for @campaignDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get campaignDescriptionHeading;

  /// No description provided for @campaignContentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get campaignContentsHeading;

  /// No description provided for @campaignPricePerBox.
  ///
  /// In en, this message translates to:
  /// **'Price per box'**
  String get campaignPricePerBox;

  /// No description provided for @campaignContains.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get campaignContains;

  /// No description provided for @campaignSwipeToPay.
  ///
  /// In en, this message translates to:
  /// **'Swipe to pay'**
  String get campaignSwipeToPay;

  /// No description provided for @campaignSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get campaignSubtotal;

  /// No description provided for @campaignPaymentHeading.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get campaignPaymentHeading;

  /// No description provided for @campaignChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get campaignChange;

  /// No description provided for @campaignGoToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Go to checkout'**
  String get campaignGoToCheckout;

  /// No description provided for @campaignEnded.
  ///
  /// In en, this message translates to:
  /// **'Campaign has ended'**
  String get campaignEnded;

  /// No description provided for @campaignEndedBody.
  ///
  /// In en, this message translates to:
  /// **'This campaign has ended. Contact the club for the next round.'**
  String get campaignEndedBody;

  /// No description provided for @campaignUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Campaign starting soon'**
  String get campaignUpcoming;

  /// No description provided for @campaignUpcomingBody.
  ///
  /// In en, this message translates to:
  /// **'Sales open soon. Come back when we open.'**
  String get campaignUpcomingBody;

  /// No description provided for @campaignSuppliedBy.
  ///
  /// In en, this message translates to:
  /// **'Meat from Jens Eide Slakteri'**
  String get campaignSuppliedBy;

  /// No description provided for @campaignClubEarns.
  ///
  /// In en, this message translates to:
  /// **'The club earns from every purchase'**
  String get campaignClubEarns;

  /// No description provided for @campaignYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get campaignYourOrder;

  /// No description provided for @campaignDeliveryMethod.
  ///
  /// In en, this message translates to:
  /// **'Delivery method'**
  String get campaignDeliveryMethod;

  /// No description provided for @campaignHomeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Home delivery'**
  String get campaignHomeDelivery;

  /// No description provided for @campaignPickupAtClub.
  ///
  /// In en, this message translates to:
  /// **'Pickup at club'**
  String get campaignPickupAtClub;

  /// No description provided for @campaignPickupAtClubName.
  ///
  /// In en, this message translates to:
  /// **'Pick up at {club}'**
  String campaignPickupAtClubName(String club);

  /// No description provided for @campaignDeliveredOn.
  ///
  /// In en, this message translates to:
  /// **'Delivered {date}'**
  String campaignDeliveredOn(String date);

  /// No description provided for @campaignPickupOnDate.
  ///
  /// In en, this message translates to:
  /// **'Can be picked up on {date}'**
  String campaignPickupOnDate(String date);

  /// No description provided for @campaignPickupOnDateTime.
  ///
  /// In en, this message translates to:
  /// **'Can be picked up on {date} · at {time}'**
  String campaignPickupOnDateTime(String date, String time);

  /// No description provided for @campaignContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact information'**
  String get campaignContactInfo;

  /// No description provided for @campaignPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get campaignPhone;

  /// No description provided for @campaignStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get campaignStreetAddress;

  /// No description provided for @campaignPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get campaignPostalCode;

  /// No description provided for @campaignCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get campaignCity;

  /// No description provided for @campaignPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get campaignPaymentMethod;

  /// No description provided for @campaignPayVipps.
  ///
  /// In en, this message translates to:
  /// **'Vipps'**
  String get campaignPayVipps;

  /// No description provided for @campaignPayWithVipps.
  ///
  /// In en, this message translates to:
  /// **'Pay with Vipps'**
  String get campaignPayWithVipps;

  /// No description provided for @campaignPayCard.
  ///
  /// In en, this message translates to:
  /// **'Card / Apple Pay / Google Pay'**
  String get campaignPayCard;

  /// No description provided for @campaignProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get campaignProcessing;

  /// No description provided for @campaignTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get campaignTotal;

  /// No description provided for @campaignEmptyCart.
  ///
  /// In en, this message translates to:
  /// **'Add at least one box to continue.'**
  String get campaignEmptyCart;

  /// No description provided for @campaignThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your order!'**
  String get campaignThankYou;

  /// No description provided for @campaignSupportThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support!'**
  String get campaignSupportThankYou;

  /// No description provided for @campaignBoxesOrdered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 meal box ordered.} other{{count} meal boxes ordered.}}'**
  String campaignBoxesOrdered(int count);

  /// No description provided for @campaignOrderSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'ORDER SUMMARY'**
  String get campaignOrderSummaryTitle;

  /// No description provided for @campaignConfirmationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Order confirmation and details have been sent to {email}'**
  String campaignConfirmationEmailSent(String email);

  /// No description provided for @campaignPurchaseClubShare.
  ///
  /// In en, this message translates to:
  /// **'A portion of the purchase goes to the club 💖'**
  String get campaignPurchaseClubShare;

  /// No description provided for @campaignPointsAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'points added to your account'**
  String get campaignPointsAddedLabel;

  /// No description provided for @campaignConfirmationSent.
  ///
  /// In en, this message translates to:
  /// **'We have sent a confirmation by email.'**
  String get campaignConfirmationSent;

  /// No description provided for @campaignContributionToSupport.
  ///
  /// In en, this message translates to:
  /// **'You contributed {amount} kr to {supportName}'**
  String campaignContributionToSupport(String amount, String supportName);

  /// No description provided for @campaignPointsEarnedForTeam.
  ///
  /// In en, this message translates to:
  /// **'+{points} points earned for {teamName}'**
  String campaignPointsEarnedForTeam(int points, String teamName);

  /// No description provided for @campaignViewMyOrders.
  ///
  /// In en, this message translates to:
  /// **'View my orders'**
  String get campaignViewMyOrders;

  /// No description provided for @campaignBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get campaignBackToHome;

  /// No description provided for @campaignPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get campaignPaymentFailed;

  /// No description provided for @campaignPaymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm the payment. Please try again.'**
  String get campaignPaymentFailedBody;

  /// No description provided for @campaignMyMatkasser.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get campaignMyMatkasser;

  /// No description provided for @campaignOrdersBoughtBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have bought 1 campaign so far} other{You have bought {count} campaigns so far}}'**
  String campaignOrdersBoughtBanner(int count);

  /// No description provided for @campaignOrdersBoughtBannerSub.
  ///
  /// In en, this message translates to:
  /// **'each of them supports your team — thank you! 💜'**
  String get campaignOrdersBoughtBannerSub;

  /// No description provided for @campaignNoOrders.
  ///
  /// In en, this message translates to:
  /// **'You have no meal box orders yet.'**
  String get campaignNoOrders;

  /// No description provided for @campaignPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get campaignPaid;

  /// No description provided for @campaignPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get campaignPending;

  /// No description provided for @campaignFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get campaignFailed;

  /// No description provided for @campaignSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get campaignSomethingWentWrong;

  /// No description provided for @campaignNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get campaignNameRequired;

  /// No description provided for @campaignEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get campaignEmailRequired;

  /// No description provided for @campaignPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get campaignPhoneRequired;

  /// No description provided for @campaignAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required for home delivery'**
  String get campaignAddressRequired;

  /// No description provided for @campaignPaymentInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment initialization failed. Please try again.'**
  String get campaignPaymentInitFailed;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping cart ({count})'**
  String cartTitle(int count);

  /// No description provided for @cartRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get cartRecommendations;

  /// No description provided for @cartOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get cartOpening;

  /// No description provided for @cartToCheckout.
  ///
  /// In en, this message translates to:
  /// **'To checkout'**
  String get cartToCheckout;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartAddProducts.
  ///
  /// In en, this message translates to:
  /// **'Add products to get started'**
  String get cartAddProducts;

  /// No description provided for @cartDugnadEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Find an offer from your club\'s sponsors and add items to your cart.'**
  String get cartDugnadEmptyDesc;

  /// No description provided for @cartSeeOffers.
  ///
  /// In en, this message translates to:
  /// **'See offers'**
  String get cartSeeOffers;

  /// No description provided for @cartBackToStores.
  ///
  /// In en, this message translates to:
  /// **'Back to stores'**
  String get cartBackToStores;

  /// No description provided for @cartReviewSubstitution.
  ///
  /// In en, this message translates to:
  /// **'Review substitution'**
  String get cartReviewSubstitution;

  /// No description provided for @cartSubstitutionDetail.
  ///
  /// In en, this message translates to:
  /// **'Snurre matched {requested} to {matched}. Review before paying.'**
  String cartSubstitutionDetail(String requested, String matched);

  /// No description provided for @homeFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'How was your meal?'**
  String get homeFeedbackTitle;

  /// No description provided for @homeFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'Whether it\'s good or bad, let\'s talk about it! 😉'**
  String get homeFeedbackBody;

  /// No description provided for @homeLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get homeLocation;

  /// No description provided for @homeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get homeCurrent;

  /// No description provided for @homeSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get homeSwipe;

  /// No description provided for @accountMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get accountMyAccount;

  /// No description provided for @accountAerendCredits.
  ///
  /// In en, this message translates to:
  /// **'Ærend Credits'**
  String get accountAerendCredits;

  /// No description provided for @accountAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get accountAvailableBalance;

  /// No description provided for @heroDeliveryTo.
  ///
  /// In en, this message translates to:
  /// **'Delivery to'**
  String get heroDeliveryTo;

  /// No description provided for @heroSearchStoresProducts.
  ///
  /// In en, this message translates to:
  /// **'Search for stores and products'**
  String get heroSearchStoresProducts;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Every order supports the team'**
  String get splashTagline;

  /// No description provided for @snurreSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Where can I buy the cheapest sunglasses?'**
  String get snurreSuggestion1;

  /// No description provided for @snurreSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'How long are restaurants in Bergen open?'**
  String get snurreSuggestion2;

  /// No description provided for @snurreWriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get snurreWriteMessage;

  /// No description provided for @campaignLastChance.
  ///
  /// In en, this message translates to:
  /// **'Last chance'**
  String get campaignLastChance;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutDeliveryTab.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get checkoutDeliveryTab;

  /// No description provided for @checkoutPickupTab.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get checkoutPickupTab;

  /// No description provided for @checkoutEstimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery'**
  String get checkoutEstimatedDelivery;

  /// No description provided for @checkoutSelectDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Select delivery address'**
  String get checkoutSelectDeliveryAddress;

  /// No description provided for @dugnadAddressDeliverMultiple.
  ///
  /// In en, this message translates to:
  /// **'Deliver to more places'**
  String get dugnadAddressDeliverMultiple;

  /// No description provided for @dugnadAddressSavedInfo.
  ///
  /// In en, this message translates to:
  /// **'The address is saved for future deliveries. You can change it at any time.'**
  String get dugnadAddressSavedInfo;

  /// No description provided for @dugnadAddressSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for street and number'**
  String get dugnadAddressSearchHint;

  /// No description provided for @dugnadAddressSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get dugnadAddressSavedToast;

  /// No description provided for @dugnadAddressSuggestFoot.
  ///
  /// In en, this message translates to:
  /// **'Suggestions from place search'**
  String get dugnadAddressSuggestFoot;

  /// No description provided for @dugnadAddressStandardBadge.
  ///
  /// In en, this message translates to:
  /// **'STANDARD'**
  String get dugnadAddressStandardBadge;

  /// No description provided for @checkoutPickupInMin.
  ///
  /// In en, this message translates to:
  /// **'Pickup in {minutes} min'**
  String checkoutPickupInMin(String minutes);

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get checkoutOrderSummary;

  /// No description provided for @checkoutPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get checkoutPaymentFailed;

  /// No description provided for @checkoutPlacingOrderTerms.
  ///
  /// In en, this message translates to:
  /// **'By placing this order, you agree to the '**
  String get checkoutPlacingOrderTerms;

  /// No description provided for @checkoutUnableToEdit.
  ///
  /// In en, this message translates to:
  /// **'Unable to edit this item right now.'**
  String get checkoutUnableToEdit;

  /// No description provided for @checkoutUnableToLoadEdit.
  ///
  /// In en, this message translates to:
  /// **'Unable to load edit options right now.'**
  String get checkoutUnableToLoadEdit;

  /// No description provided for @checkoutDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String checkoutDistanceKm(String distance);

  /// No description provided for @searchStores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get searchStores;

  /// No description provided for @storeProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get storeProductDetails;

  /// No description provided for @storeReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get storeReadMore;

  /// No description provided for @storeViewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get storeViewCart;

  /// No description provided for @storeAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get storeAddToCart;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @accountDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get accountDetailTitle;

  /// No description provided for @accountDeleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get accountDeleteMyAccount;

  /// No description provided for @editEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get editEmailTitle;

  /// No description provided for @editEmailCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Email Now'**
  String get editEmailCurrentLabel;

  /// No description provided for @editEmailNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New Email'**
  String get editEmailNewLabel;

  /// No description provided for @editEmailNewHint.
  ///
  /// In en, this message translates to:
  /// **'New Email Here'**
  String get editEmailNewHint;

  /// No description provided for @editEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Update Email'**
  String get editEmailButton;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get editNameTitle;

  /// No description provided for @editNameCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Name Now'**
  String get editNameCurrentLabel;

  /// No description provided for @editNameNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get editNameNewLabel;

  /// No description provided for @editNameNewHint.
  ///
  /// In en, this message translates to:
  /// **'New Name Here'**
  String get editNameNewHint;

  /// No description provided for @editNameButton.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get editNameButton;

  /// No description provided for @editPhoneButton.
  ///
  /// In en, this message translates to:
  /// **'Update Number'**
  String get editPhoneButton;

  /// No description provided for @editPicCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Picture'**
  String get editPicCurrent;

  /// No description provided for @editPicNew.
  ///
  /// In en, this message translates to:
  /// **'New Picture'**
  String get editPicNew;

  /// No description provided for @redeemCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem Code'**
  String get redeemCodeTitle;

  /// No description provided for @redeemCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your discount code'**
  String get redeemCodeHint;

  /// No description provided for @redeemCodeOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get redeemCodeOkay;

  /// No description provided for @referralShareCode.
  ///
  /// In en, this message translates to:
  /// **'Share your referral code'**
  String get referralShareCode;

  /// No description provided for @referralHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works?'**
  String get referralHowItWorks;

  /// No description provided for @settingsLimitTracking.
  ///
  /// In en, this message translates to:
  /// **'Limit Tracking'**
  String get settingsLimitTracking;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAerendVersion.
  ///
  /// In en, this message translates to:
  /// **'Reen Dugnad Version'**
  String get settingsAerendVersion;

  /// No description provided for @settingsOsVersion.
  ///
  /// In en, this message translates to:
  /// **'OS Version'**
  String get settingsOsVersion;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get profileYourProfile;

  /// No description provided for @profileEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get profileEnterFullName;

  /// No description provided for @profileEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get profileEnterEmail;

  /// No description provided for @locationAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add New Location'**
  String get locationAddNew;

  /// No description provided for @locationCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get locationCountry;

  /// No description provided for @locationStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get locationStreet;

  /// No description provided for @locationStreetHint.
  ///
  /// In en, this message translates to:
  /// **'Street name and number'**
  String get locationStreetHint;

  /// No description provided for @locationYourType.
  ///
  /// In en, this message translates to:
  /// **'Your Location Type'**
  String get locationYourType;

  /// No description provided for @locationAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get locationAddressDetails;

  /// No description provided for @locationDoorHint.
  ///
  /// In en, this message translates to:
  /// **'Name / Number on door'**
  String get locationDoorHint;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get locationOptional;

  /// No description provided for @locationCourierInstruction.
  ///
  /// In en, this message translates to:
  /// **'Other instruction for the courier'**
  String get locationCourierInstruction;

  /// No description provided for @locationSelectFromMaps.
  ///
  /// In en, this message translates to:
  /// **'Select From Maps'**
  String get locationSelectFromMaps;

  /// No description provided for @locationMapsHelp.
  ///
  /// In en, this message translates to:
  /// **'Adding exact location on maps helps us find you faster.'**
  String get locationMapsHelp;

  /// No description provided for @locationAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get locationAddButton;

  /// No description provided for @locationAddressPrefix.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String locationAddressPrefix(String address);

  /// No description provided for @locationChooseThis.
  ///
  /// In en, this message translates to:
  /// **'Choose This Location'**
  String get locationChooseThis;

  /// No description provided for @locationEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get locationEditTitle;

  /// No description provided for @authEmailOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Email or number'**
  String get authEmailOrNumber;

  /// No description provided for @authEnterEmailOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter email or number'**
  String get authEnterEmailOrNumber;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter {field}'**
  String authEnterPassword(String field);

  /// No description provided for @authRegisterAccount.
  ///
  /// In en, this message translates to:
  /// **'Register Your Account'**
  String get authRegisterAccount;

  /// No description provided for @authEmailOrNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or Number'**
  String get authEmailOrNumberLabel;

  /// No description provided for @authEnterEmailOrNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or number'**
  String get authEnterEmailOrNumberHint;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Your Friend'**
  String get inviteTitle;

  /// No description provided for @inviteHeading.
  ///
  /// In en, this message translates to:
  /// **'Invite a Friend and Hop Together!'**
  String get inviteHeading;

  /// No description provided for @inviteDescription.
  ///
  /// In en, this message translates to:
  /// **'Share the joy of Reen Dugnad with your friends and earn rewards together! Invite a friend to join Reen Dugnad and both of you will receive exciting benefits. Spread the word — every order gives back to the club!'**
  String get inviteDescription;

  /// No description provided for @inviteButton.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends Now'**
  String get inviteButton;

  /// No description provided for @inviteTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get inviteTerms;

  /// No description provided for @inviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get inviteCopyLink;

  /// No description provided for @checkoutOrderFee.
  ///
  /// In en, this message translates to:
  /// **'Order fee'**
  String get checkoutOrderFee;

  /// No description provided for @snurreLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to use AI chat.'**
  String get snurreLoginRequired;

  /// No description provided for @snurreProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product is unavailable.'**
  String get snurreProductUnavailable;

  /// No description provided for @snurreCouldNotAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Could not add to cart.'**
  String get snurreCouldNotAddToCart;

  /// No description provided for @snurreAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get snurreAddedToCart;

  /// No description provided for @snurreClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get snurreClose;

  /// No description provided for @snurreStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store is unavailable.'**
  String get snurreStoreUnavailable;

  /// No description provided for @snurreBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get snurreBuy;

  /// No description provided for @snurreBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get snurreBuyNow;

  /// No description provided for @snurreVisitStore.
  ///
  /// In en, this message translates to:
  /// **'Visit Store'**
  String get snurreVisitStore;

  /// No description provided for @snurreStoreSelectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store selection is unavailable.'**
  String get snurreStoreSelectionUnavailable;

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type message'**
  String get chatTypeMessage;

  /// No description provided for @trackEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated time'**
  String get trackEstimatedTime;

  /// No description provided for @trackDeliveryOtp.
  ///
  /// In en, this message translates to:
  /// **'Delivery OTP'**
  String get trackDeliveryOtp;

  /// No description provided for @trackCouldNotOpenPhone.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app.'**
  String get trackCouldNotOpenPhone;

  /// No description provided for @trackNoDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get trackNoDataAvailable;

  /// No description provided for @storeSearchIn.
  ///
  /// In en, this message translates to:
  /// **'Search in {storeName}'**
  String storeSearchIn(String storeName);

  /// No description provided for @storeDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get storeDescription;

  /// No description provided for @storePosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get storePosition;

  /// No description provided for @storeOpeningTime.
  ///
  /// In en, this message translates to:
  /// **'Opening Time'**
  String get storeOpeningTime;

  /// No description provided for @storeContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get storeContact;

  /// No description provided for @storePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get storePhoneNumber;

  /// No description provided for @locationMapError.
  ///
  /// In en, this message translates to:
  /// **'Google Map Error!'**
  String get locationMapError;

  /// No description provided for @cartCannotLoadProduct.
  ///
  /// In en, this message translates to:
  /// **'Cannot load this product right now.'**
  String get cartCannotLoadProduct;

  /// No description provided for @cartCannotAddNow.
  ///
  /// In en, this message translates to:
  /// **'Cannot add right now.'**
  String get cartCannotAddNow;

  /// No description provided for @editPicSelectFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first'**
  String get editPicSelectFirst;

  /// No description provided for @referralCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get referralCopied;

  /// No description provided for @orderContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get orderContactSupport;

  /// No description provided for @swipeCouldNotAdd.
  ///
  /// In en, this message translates to:
  /// **'Could not add this item to cart.'**
  String get swipeCouldNotAdd;

  /// No description provided for @swipeTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Device token missing. Restart the app and try again.'**
  String get swipeTokenMissing;

  /// No description provided for @feedReportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Report coming soon'**
  String get feedReportComingSoon;

  /// No description provided for @dugnadStoExplainerTitle.
  ///
  /// In en, this message translates to:
  /// **'How the STØ rating is calculated'**
  String get dugnadStoExplainerTitle;

  /// No description provided for @dugnadSeeWhatMakesRating.
  ///
  /// In en, this message translates to:
  /// **'See what makes the rating'**
  String get dugnadSeeWhatMakesRating;

  /// No description provided for @dugnadStoTempoTitle.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get dugnadStoTempoTitle;

  /// No description provided for @dugnadStoTempoNote.
  ///
  /// In en, this message translates to:
  /// **'in good form — how quickly you\'re collecting points right now. This is only a tempo indicator and doesn\'t affect the rating.'**
  String get dugnadStoTempoNote;

  /// No description provided for @dugnadStoSeasonFarmNote.
  ///
  /// In en, this message translates to:
  /// **'The rating shows the points you\'ve earned this season and rebuilds every season. Your metal level at season end determines how many points you carry forward.'**
  String get dugnadStoSeasonFarmNote;

  /// No description provided for @dugnadStoSeasonFarmEmphasis.
  ///
  /// In en, this message translates to:
  /// **'this season'**
  String get dugnadStoSeasonFarmEmphasis;

  /// No description provided for @dugnadCarryoverPerLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Carryover per level'**
  String get dugnadCarryoverPerLevelTitle;

  /// No description provided for @dugnadCarryoverPerLevelSub.
  ///
  /// In en, this message translates to:
  /// **'Your metal level at season end sets how much of your season points carry over into next season.'**
  String get dugnadCarryoverPerLevelSub;

  /// No description provided for @dugnadCarryoverYourLevelTag.
  ///
  /// In en, this message translates to:
  /// **'YOU NOW'**
  String get dugnadCarryoverYourLevelTag;

  /// No description provided for @dugnadCarryoverHighlight.
  ///
  /// In en, this message translates to:
  /// **'Reach {tier} ({sto} STØ) → carry {percent} % to next season 🚀'**
  String dugnadCarryoverHighlight(String tier, int sto, int percent);

  /// No description provided for @dugnadCarryoverMaxLine.
  ///
  /// In en, this message translates to:
  /// **'Top level {tier} → you bring the most points to next season 🚀'**
  String dugnadCarryoverMaxLine(String tier);

  /// No description provided for @dugnadStoIncreaseTitle.
  ///
  /// In en, this message translates to:
  /// **'How to increase the rating'**
  String get dugnadStoIncreaseTitle;

  /// No description provided for @dugnadStoBoostReferTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer a supporter'**
  String get dugnadStoBoostReferTitle;

  /// No description provided for @dugnadStoBoostReferSub.
  ///
  /// In en, this message translates to:
  /// **'Every referral lifts the card the most'**
  String get dugnadStoBoostReferSub;

  /// No description provided for @dugnadStoBoostCampaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy a food box'**
  String get dugnadStoBoostCampaignTitle;

  /// No description provided for @dugnadStoBoostCampaignSub.
  ///
  /// In en, this message translates to:
  /// **'Support a team directly'**
  String get dugnadStoBoostCampaignSub;

  /// No description provided for @dugnadStoBoostMembershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up membership'**
  String get dugnadStoBoostMembershipTitle;

  /// No description provided for @dugnadStoBoostMembershipSub.
  ///
  /// In en, this message translates to:
  /// **'Unlocks the «Regular member» badge'**
  String get dugnadStoBoostMembershipSub;

  /// No description provided for @dugnadStoBoostFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your form up'**
  String get dugnadStoBoostFormTitle;

  /// No description provided for @dugnadStoBoostFormSub.
  ///
  /// In en, this message translates to:
  /// **'Weekly missions keep the rating rising'**
  String get dugnadStoBoostFormSub;

  /// No description provided for @dugnadGateCollectPoints.
  ///
  /// In en, this message translates to:
  /// **'Create an account to collect points'**
  String get dugnadGateCollectPoints;

  /// No description provided for @dugnadGateBuyAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Create an account to buy and earn points'**
  String get dugnadGateBuyAndEarn;

  /// No description provided for @dugnadGateCompete.
  ///
  /// In en, this message translates to:
  /// **'Create an account to take part'**
  String get dugnadGateCompete;

  /// No description provided for @dugnadGateUnlockBadges.
  ///
  /// In en, this message translates to:
  /// **'Create an account to unlock badges'**
  String get dugnadGateUnlockBadges;

  /// No description provided for @dugnadGateMissions.
  ///
  /// In en, this message translates to:
  /// **'Create an account to get missions'**
  String get dugnadGateMissions;

  /// No description provided for @dugnadGateSupport.
  ///
  /// In en, this message translates to:
  /// **'Create an account to support monthly'**
  String get dugnadGateSupport;

  /// No description provided for @dugnadGateRefer.
  ///
  /// In en, this message translates to:
  /// **'Create an account to invite friends'**
  String get dugnadGateRefer;

  /// No description provided for @dugnadGateSeeAccountAndPayments.
  ///
  /// In en, this message translates to:
  /// **'Create an account to view account and payments'**
  String get dugnadGateSeeAccountAndPayments;

  /// No description provided for @dugnadGateChooseClubCollectPoints.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to collect points'**
  String get dugnadGateChooseClubCollectPoints;

  /// No description provided for @dugnadGateChooseClubBuyAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to buy and earn points'**
  String get dugnadGateChooseClubBuyAndEarn;

  /// No description provided for @dugnadGateChooseClubCompete.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to take part'**
  String get dugnadGateChooseClubCompete;

  /// No description provided for @dugnadGateChooseClubBadges.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to unlock badges'**
  String get dugnadGateChooseClubBadges;

  /// No description provided for @dugnadGateChooseClubAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to view account and payments'**
  String get dugnadGateChooseClubAccount;

  /// No description provided for @dugnadChooseClubHomeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your club'**
  String get dugnadChooseClubHomeCardTitle;

  /// No description provided for @dugnadChooseClubHomeCardBody.
  ///
  /// In en, this message translates to:
  /// **'A share of every order goes to the club fund'**
  String get dugnadChooseClubHomeCardBody;

  /// No description provided for @dugnadChooseClubHomeCardCta.
  ///
  /// In en, this message translates to:
  /// **'Choose club'**
  String get dugnadChooseClubHomeCardCta;

  /// No description provided for @dugnadLeaderboardNoClubHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to see the teams'**
  String get dugnadLeaderboardNoClubHeroSubtitle;

  /// No description provided for @dugnadLeaderboardNoClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Teams compete\nfor prizes'**
  String get dugnadLeaderboardNoClubTitle;

  /// No description provided for @dugnadLeaderboardNoClubBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the club you want to support — then follow the teams and season on the table.'**
  String get dugnadLeaderboardNoClubBody;

  /// No description provided for @dugnadLeaderboardNoClubStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Choose club'**
  String get dugnadLeaderboardNoClubStep1Title;

  /// No description provided for @dugnadLeaderboardNoClubStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Find the club you want to support'**
  String get dugnadLeaderboardNoClubStep1Body;

  /// No description provided for @dugnadProfileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get dugnadProfileGuestTitle;

  /// No description provided for @dugnadProfileGuestBadge.
  ///
  /// In en, this message translates to:
  /// **'GUEST'**
  String get dugnadProfileGuestBadge;

  /// No description provided for @dugnadProfileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save your profile, points and orders'**
  String get dugnadProfileGuestBody;

  /// No description provided for @dugnadProfileGuestCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get dugnadProfileGuestCtaTitle;

  /// No description provided for @dugnadProfileGuestCtaBody.
  ///
  /// In en, this message translates to:
  /// **'Your points will be saved and you can shop in the app'**
  String get dugnadProfileGuestCtaBody;

  /// No description provided for @dugnadChooseYourClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your club'**
  String get dugnadChooseYourClubTitle;

  /// No description provided for @dugnadChooseYourClubBody.
  ///
  /// In en, this message translates to:
  /// **'A share of every order goes to the club fund'**
  String get dugnadChooseYourClubBody;

  /// No description provided for @celebrationClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get celebrationClose;

  /// No description provided for @celebrationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get celebrationContinue;

  /// No description provided for @celebrationCtaBadges.
  ///
  /// In en, this message translates to:
  /// **'See badge'**
  String get celebrationCtaBadges;

  /// No description provided for @celebrationCtaMissions.
  ///
  /// In en, this message translates to:
  /// **'Weekly matches'**
  String get celebrationCtaMissions;

  /// No description provided for @celebrationCtaSeasonGoals.
  ///
  /// In en, this message translates to:
  /// **'Season goals'**
  String get celebrationCtaSeasonGoals;

  /// No description provided for @celebrationCtaForm.
  ///
  /// In en, this message translates to:
  /// **'See your form'**
  String get celebrationCtaForm;

  /// No description provided for @celebrationCtaTable.
  ///
  /// In en, this message translates to:
  /// **'See the table'**
  String get celebrationCtaTable;

  /// No description provided for @celebrationCtaSto.
  ///
  /// In en, this message translates to:
  /// **'See the STØ ranking'**
  String get celebrationCtaSto;

  /// No description provided for @celebrationCtaStoCard.
  ///
  /// In en, this message translates to:
  /// **'See the STØ card'**
  String get celebrationCtaStoCard;

  /// No description provided for @celebrationCtaScorers.
  ///
  /// In en, this message translates to:
  /// **'See top scorer'**
  String get celebrationCtaScorers;

  /// No description provided for @celebrationCtaAssists.
  ///
  /// In en, this message translates to:
  /// **'See assist king'**
  String get celebrationCtaAssists;

  /// No description provided for @celebrationCtaSeason.
  ///
  /// In en, this message translates to:
  /// **'See the season summary'**
  String get celebrationCtaSeason;

  /// No description provided for @celebrationTitleT2.
  ///
  /// In en, this message translates to:
  /// **'New badge unlocked'**
  String get celebrationTitleT2;

  /// No description provided for @celebrationTitleT3Weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly match complete'**
  String get celebrationTitleT3Weekly;

  /// No description provided for @celebrationTitleT3Season.
  ///
  /// In en, this message translates to:
  /// **'Season goal complete'**
  String get celebrationTitleT3Season;

  /// No description provided for @celebrationSubtitleT3Weekly.
  ///
  /// In en, this message translates to:
  /// **'You showed up every day this week'**
  String get celebrationSubtitleT3Weekly;

  /// No description provided for @celebrationSubtitleT3Season.
  ///
  /// In en, this message translates to:
  /// **'Season goal reached — thanks for the lift'**
  String get celebrationSubtitleT3Season;

  /// No description provided for @celebrationTitleT4Up.
  ///
  /// In en, this message translates to:
  /// **'You\'re in form! 🔥'**
  String get celebrationTitleT4Up;

  /// No description provided for @celebrationTitleT4Flat.
  ///
  /// In en, this message translates to:
  /// **'Your form is steady'**
  String get celebrationTitleT4Flat;

  /// No description provided for @celebrationTitleT4Down.
  ///
  /// In en, this message translates to:
  /// **'Your form has dropped'**
  String get celebrationTitleT4Down;

  /// No description provided for @celebrationEyebrowT4Up.
  ///
  /// In en, this message translates to:
  /// **'Your tempo has risen'**
  String get celebrationEyebrowT4Up;

  /// No description provided for @celebrationEyebrowT4Flat.
  ///
  /// In en, this message translates to:
  /// **'Your tempo is holding'**
  String get celebrationEyebrowT4Flat;

  /// No description provided for @celebrationEyebrowT4Down.
  ///
  /// In en, this message translates to:
  /// **'Your tempo has eased'**
  String get celebrationEyebrowT4Down;

  /// No description provided for @celebrationTitleT5a.
  ///
  /// In en, this message translates to:
  /// **'Your team is on top! 🏆'**
  String get celebrationTitleT5a;

  /// No description provided for @celebrationEyebrowT5a.
  ///
  /// In en, this message translates to:
  /// **'New table top'**
  String get celebrationEyebrowT5a;

  /// No description provided for @celebrationTitleT5b.
  ///
  /// In en, this message translates to:
  /// **'Your team is in the prize zone'**
  String get celebrationTitleT5b;

  /// No description provided for @celebrationEyebrowT5b.
  ///
  /// In en, this message translates to:
  /// **'Prize zone'**
  String get celebrationEyebrowT5b;

  /// No description provided for @celebrationTitleT5bPlace.
  ///
  /// In en, this message translates to:
  /// **'Your team took {placeLabel}! {emoji}'**
  String celebrationTitleT5bPlace(String placeLabel, String emoji);

  /// No description provided for @celebrationTitleT5bSecond.
  ///
  /// In en, this message translates to:
  /// **'Your team took second place! 🥈'**
  String get celebrationTitleT5bSecond;

  /// No description provided for @celebrationTitleT5bThird.
  ///
  /// In en, this message translates to:
  /// **'Your team took third place! 🥉'**
  String get celebrationTitleT5bThird;

  /// No description provided for @celebrationBodyT5a.
  ///
  /// In en, this message translates to:
  /// **'Your team leads the club table right now. Hold the lead through the season.'**
  String get celebrationBodyT5a;

  /// No description provided for @celebrationBodyT5b.
  ///
  /// In en, this message translates to:
  /// **'Top 3 at season end earns a prize. You\'re in — now stay there.'**
  String get celebrationBodyT5b;

  /// No description provided for @celebrationBodyT5bPlace.
  ///
  /// In en, this message translates to:
  /// **'Your team is in the prize zone. {metal} on the club table.'**
  String celebrationBodyT5bPlace(String metal);

  /// No description provided for @celebrationBodyT5bSilver.
  ///
  /// In en, this message translates to:
  /// **'Your team is in the prize zone. Silver on the club table.'**
  String get celebrationBodyT5bSilver;

  /// No description provided for @celebrationBodyT5bBronze.
  ///
  /// In en, this message translates to:
  /// **'Your team finished in the prize zone. Bronze on the club table for the season.'**
  String get celebrationBodyT5bBronze;

  /// No description provided for @celebrationSeasonPill.
  ///
  /// In en, this message translates to:
  /// **'Season {season}'**
  String celebrationSeasonPill(String season);

  /// No description provided for @celebrationSeasonPillFinal.
  ///
  /// In en, this message translates to:
  /// **'Season {season} · Final'**
  String celebrationSeasonPillFinal(String season);

  /// No description provided for @celebrationTitleT6.
  ///
  /// In en, this message translates to:
  /// **'You have the club\'s highest STØ! 👑'**
  String get celebrationTitleT6;

  /// No description provided for @celebrationEyebrowT6.
  ///
  /// In en, this message translates to:
  /// **'New throne'**
  String get celebrationEyebrowT6;

  /// No description provided for @celebrationBodyT6.
  ///
  /// In en, this message translates to:
  /// **'Nobody in the club has a higher STØ rating than you right now.'**
  String get celebrationBodyT6;

  /// No description provided for @celebrationTitleT7.
  ///
  /// In en, this message translates to:
  /// **'You\'re top scorer! ⚽'**
  String get celebrationTitleT7;

  /// No description provided for @celebrationEyebrowT7.
  ///
  /// In en, this message translates to:
  /// **'New top scorer'**
  String get celebrationEyebrowT7;

  /// No description provided for @celebrationBodyT7.
  ///
  /// In en, this message translates to:
  /// **'You have the most goals in the club — most campaign purchases this season.'**
  String get celebrationBodyT7;

  /// No description provided for @celebrationTitleT8.
  ///
  /// In en, this message translates to:
  /// **'You\'re assist king! 🅰️'**
  String get celebrationTitleT8;

  /// No description provided for @celebrationEyebrowT8.
  ///
  /// In en, this message translates to:
  /// **'New assist king'**
  String get celebrationEyebrowT8;

  /// No description provided for @celebrationBodyT8.
  ///
  /// In en, this message translates to:
  /// **'You have the most assists in the club — most recruited friends.'**
  String get celebrationBodyT8;

  /// No description provided for @celebrationTitleT9.
  ///
  /// In en, this message translates to:
  /// **'Your team won the season! 🏆'**
  String get celebrationTitleT9;

  /// No description provided for @celebrationBodyT9.
  ///
  /// In en, this message translates to:
  /// **'Your team finished top of the club table. It\'s in the history books now.'**
  String get celebrationBodyT9;

  /// No description provided for @celebrationTitleT10.
  ///
  /// In en, this message translates to:
  /// **'You became the season\'s top scorer! ⚽'**
  String get celebrationTitleT10;

  /// No description provided for @celebrationTitleT11.
  ///
  /// In en, this message translates to:
  /// **'You became the season\'s assist king! 🅰️'**
  String get celebrationTitleT11;

  /// No description provided for @celebrationTitleT12.
  ///
  /// In en, this message translates to:
  /// **'You had the season\'s highest STØ! 👑'**
  String get celebrationTitleT12;

  /// No description provided for @celebrationBodyT10.
  ///
  /// In en, this message translates to:
  /// **'Nobody in the club bought more campaigns than you this season.'**
  String get celebrationBodyT10;

  /// No description provided for @celebrationBodyT11.
  ///
  /// In en, this message translates to:
  /// **'Nobody in the club recruited more than you this season.'**
  String get celebrationBodyT11;

  /// No description provided for @celebrationBodyT12.
  ///
  /// In en, this message translates to:
  /// **'You finished the season with the club\'s highest STØ rating.'**
  String get celebrationBodyT12;

  /// No description provided for @celebrationTitleT13.
  ///
  /// In en, this message translates to:
  /// **'You are signed by'**
  String get celebrationTitleT13;

  /// No description provided for @celebrationTitleT14.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the club'**
  String get celebrationTitleT14;

  /// No description provided for @celebrationTitleT15.
  ///
  /// In en, this message translates to:
  /// **'Your team took {place}. place!'**
  String celebrationTitleT15(int place);

  /// No description provided for @celebrationTitleT15Second.
  ///
  /// In en, this message translates to:
  /// **'Your team took second place! 🥈'**
  String get celebrationTitleT15Second;

  /// No description provided for @celebrationTitleT15Third.
  ///
  /// In en, this message translates to:
  /// **'Your team took third place! 🥉'**
  String get celebrationTitleT15Third;

  /// No description provided for @celebrationTitleT16.
  ///
  /// In en, this message translates to:
  /// **'Your STØ rating rose'**
  String get celebrationTitleT16;

  /// No description provided for @celebrationStoRemainingSuffix.
  ///
  /// In en, this message translates to:
  /// **' left until {league}'**
  String celebrationStoRemainingSuffix(String league);

  /// No description provided for @celebrationStoAtTopLeague.
  ///
  /// In en, this message translates to:
  /// **'You\'re in {league}'**
  String celebrationStoAtTopLeague(String league);

  /// No description provided for @celebrationStoReasonCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign purchase'**
  String get celebrationStoReasonCampaign;

  /// No description provided for @celebrationStoReasonDonation.
  ///
  /// In en, this message translates to:
  /// **'Club support'**
  String get celebrationStoReasonDonation;

  /// No description provided for @celebrationStoReasonReferral.
  ///
  /// In en, this message translates to:
  /// **'Recruited a friend'**
  String get celebrationStoReasonReferral;

  /// No description provided for @celebrationStoReasonBadge.
  ///
  /// In en, this message translates to:
  /// **'New badge'**
  String get celebrationStoReasonBadge;

  /// No description provided for @celebrationStoReasonChallenge.
  ///
  /// In en, this message translates to:
  /// **'Weekly match complete'**
  String get celebrationStoReasonChallenge;

  /// No description provided for @celebrationStoReasonSeasonGoal.
  ///
  /// In en, this message translates to:
  /// **'Season goal reached'**
  String get celebrationStoReasonSeasonGoal;

  /// No description provided for @celebrationStoReasonStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak bonus'**
  String get celebrationStoReasonStreak;

  /// No description provided for @celebrationStoReasonShop.
  ///
  /// In en, this message translates to:
  /// **'Club shop purchase'**
  String get celebrationStoReasonShop;

  /// No description provided for @celebrationStoReasonWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome bonus'**
  String get celebrationStoReasonWelcome;

  /// No description provided for @celebrationStoReasonTour.
  ///
  /// In en, this message translates to:
  /// **'Tour complete'**
  String get celebrationStoReasonTour;

  /// No description provided for @celebrationStoReasonCarryover.
  ///
  /// In en, this message translates to:
  /// **'Season carryover'**
  String get celebrationStoReasonCarryover;

  /// No description provided for @celebrationStoReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'Your STØ rating increased'**
  String get celebrationStoReasonDefault;

  /// No description provided for @celebrationBodyT15Silver.
  ///
  /// In en, this message translates to:
  /// **'Your team finished in the prize zone. Silver on the club table for the season.'**
  String get celebrationBodyT15Silver;

  /// No description provided for @celebrationBodyT15Bronze.
  ///
  /// In en, this message translates to:
  /// **'Your team finished in the prize zone. Bronze on the club table for the season.'**
  String get celebrationBodyT15Bronze;

  /// No description provided for @celebrationEyebrowT15.
  ///
  /// In en, this message translates to:
  /// **'Season result'**
  String get celebrationEyebrowT15;

  /// No description provided for @celebrationBodyT2.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String celebrationBodyT2(String name);

  /// No description provided for @celebrationBodyT3.
  ///
  /// In en, this message translates to:
  /// **'{title}'**
  String celebrationBodyT3(String title);

  /// No description provided for @celebrationBodyT4Up.
  ///
  /// In en, this message translates to:
  /// **'You\'re collecting points faster than before — keep the tempo up.'**
  String get celebrationBodyT4Up;

  /// No description provided for @celebrationBodyT4Flat.
  ///
  /// In en, this message translates to:
  /// **'You\'re holding a steady tempo. One mission lifts you further.'**
  String get celebrationBodyT4Flat;

  /// No description provided for @celebrationBodyT4Down.
  ///
  /// In en, this message translates to:
  /// **'The tempo has eased — finish a mission and come back ⚡'**
  String get celebrationBodyT4Down;

  /// No description provided for @celebrationBodyT5.
  ///
  /// In en, this message translates to:
  /// **'{team} is now in position {position}.'**
  String celebrationBodyT5(String team, int position);

  /// No description provided for @celebrationBodyThrone.
  ///
  /// In en, this message translates to:
  /// **'{name} · {club}'**
  String celebrationBodyThrone(String name, String club);

  /// No description provided for @celebrationBodySeasonTeam.
  ///
  /// In en, this message translates to:
  /// **'{team} · {season}'**
  String celebrationBodySeasonTeam(String team, String season);

  /// No description provided for @celebrationBodySeasonPersonal.
  ///
  /// In en, this message translates to:
  /// **'{name} · {season}'**
  String celebrationBodySeasonPersonal(String name, String season);

  /// No description provided for @celebrationBodyT13.
  ///
  /// In en, this message translates to:
  /// **'From now on you play for this team — your points lift them on the table'**
  String get celebrationBodyT13;

  /// No description provided for @celebrationBodyT14.
  ///
  /// In en, this message translates to:
  /// **'The club will grow big with a player like you on the team'**
  String get celebrationBodyT14;

  /// No description provided for @celebrationContractTitle.
  ///
  /// In en, this message translates to:
  /// **'Player contract'**
  String get celebrationContractTitle;

  /// No description provided for @celebrationContractPlayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get celebrationContractPlayerLabel;

  /// No description provided for @celebrationContractRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get celebrationContractRoleLabel;

  /// No description provided for @celebrationContractSignedBy.
  ///
  /// In en, this message translates to:
  /// **'Signed by you'**
  String get celebrationContractSignedBy;

  /// No description provided for @celebrationContractStamp.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get celebrationContractStamp;

  /// No description provided for @celebrationTeamContractConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Contract confirmed · season {season}'**
  String celebrationTeamContractConfirmed(String season);

  /// No description provided for @campaignPurchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign purchases'**
  String get campaignPurchasesTitle;

  /// No description provided for @campaignPurchasesEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign purchases and overview'**
  String get campaignPurchasesEntryTitle;

  /// No description provided for @campaignPurchasesEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Countdown, delivery and archive'**
  String get campaignPurchasesEntrySubtitle;

  /// No description provided for @campaignTrackerMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 more} other{+{count} more}}'**
  String campaignTrackerMore(int count);

  /// No description provided for @campaignTrackerLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get campaignTrackerLocked;

  /// No description provided for @campaignUnitDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get campaignUnitDay;

  /// No description provided for @campaignUnitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get campaignUnitDays;

  /// No description provided for @campaignUnitHour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get campaignUnitHour;

  /// No description provided for @campaignUnitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get campaignUnitHours;

  /// No description provided for @campaignUnitMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get campaignUnitMin;

  /// No description provided for @campaignUnitSec.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get campaignUnitSec;

  /// No description provided for @campaignCountdownDeliverIn.
  ///
  /// In en, this message translates to:
  /// **'Delivered in'**
  String get campaignCountdownDeliverIn;

  /// No description provided for @campaignCountdownPickupIn.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup in'**
  String get campaignCountdownPickupIn;

  /// No description provided for @campaignTabActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Active} other{Active · {count}}}'**
  String campaignTabActive(int count);

  /// No description provided for @campaignTabArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get campaignTabArchive;

  /// No description provided for @campaignActiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active purchases'**
  String get campaignActiveEmptyTitle;

  /// No description provided for @campaignActiveEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you buy a campaign, you follow the delivery here.'**
  String get campaignActiveEmptyBody;

  /// No description provided for @campaignArchiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get campaignArchiveEmptyTitle;

  /// No description provided for @campaignArchiveEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Completed campaign purchases show up here.'**
  String get campaignArchiveEmptyBody;

  /// No description provided for @campaignReceiptBought.
  ///
  /// In en, this message translates to:
  /// **'Receipt · bought {date}'**
  String campaignReceiptBought(String date);

  /// No description provided for @campaignRowPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get campaignRowPaid;

  /// No description provided for @campaignRowDeliveryDay.
  ///
  /// In en, this message translates to:
  /// **'Delivery day'**
  String get campaignRowDeliveryDay;

  /// No description provided for @campaignRowPickupDay.
  ///
  /// In en, this message translates to:
  /// **'Pickup day'**
  String get campaignRowPickupDay;

  /// No description provided for @campaignRowTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Time slot'**
  String get campaignRowTimeSlot;

  /// No description provided for @campaignRowAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get campaignRowAddress;

  /// No description provided for @campaignRowPickupPlace.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get campaignRowPickupPlace;

  /// No description provided for @campaignRowMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get campaignRowMethod;

  /// No description provided for @campaignMethodDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get campaignMethodDelivery;

  /// No description provided for @campaignMethodPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get campaignMethodPickup;

  /// No description provided for @campaignPointsChip.
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String campaignPointsChip(int points);

  /// No description provided for @campaignChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get campaignChangeButton;

  /// No description provided for @campaignLockedButton.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get campaignLockedButton;

  /// No description provided for @campaignChangeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change to {method}?'**
  String campaignChangeSheetTitle(String method);

  /// No description provided for @campaignFreeChangeUntil.
  ///
  /// In en, this message translates to:
  /// **'Free to change until {time}'**
  String campaignFreeChangeUntil(String time);

  /// No description provided for @campaignChangeFee.
  ///
  /// In en, this message translates to:
  /// **'Changing costs {fee} kr for this campaign'**
  String campaignChangeFee(String fee);

  /// No description provided for @campaignConfirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm change'**
  String get campaignConfirmChange;

  /// No description provided for @campaignChangeProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get campaignChangeProcessing;

  /// No description provided for @campaignChangeDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Changed to {method}'**
  String campaignChangeDoneTitle(String method);

  /// No description provided for @campaignChangeSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Changed to {method}'**
  String campaignChangeSuccessToast(String method);

  /// No description provided for @campaignLockMessage.
  ///
  /// In en, this message translates to:
  /// **'The deadline to change has passed — it ended {datetime}. See you {place}!'**
  String campaignLockMessage(String datetime, String place);

  /// No description provided for @campaignLockSeeYouDoor.
  ///
  /// In en, this message translates to:
  /// **'at the door'**
  String get campaignLockSeeYouDoor;

  /// No description provided for @campaignLockSeeYouPickup.
  ///
  /// In en, this message translates to:
  /// **'at the pickup point'**
  String get campaignLockSeeYouPickup;

  /// No description provided for @campaignPointsUnit.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get campaignPointsUnit;

  /// No description provided for @campaignErrorMethodNotOffered.
  ///
  /// In en, this message translates to:
  /// **'This campaign only offers: {methods}'**
  String campaignErrorMethodNotOffered(String methods);

  /// No description provided for @campaignErrorNoChange.
  ///
  /// In en, this message translates to:
  /// **'This purchase already uses that method.'**
  String get campaignErrorNoChange;

  /// No description provided for @campaignErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get campaignErrorGeneric;

  /// No description provided for @campaignArchiveDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered {day}'**
  String campaignArchiveDelivered(String day);

  /// No description provided for @campaignArchivePickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up {day}'**
  String campaignArchivePickedUp(String day);

  /// No description provided for @campaignArchivePointsEarnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Points earned in archive'**
  String get campaignArchivePointsEarnedLabel;

  /// No description provided for @campaignArchivePointsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{count} points}}'**
  String campaignArchivePointsTotal(int count);

  /// No description provided for @campaignArchiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 purchase} other{{count} purchases}}'**
  String campaignArchiveCount(int count);

  /// No description provided for @campaignViewFullHistory.
  ///
  /// In en, this message translates to:
  /// **'See full purchase history'**
  String get campaignViewFullHistory;

  /// No description provided for @campaignChangeFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change fee'**
  String get campaignChangeFeeLabel;

  /// No description provided for @campaignChangeFeeHint.
  ///
  /// In en, this message translates to:
  /// **'Paid when you confirm'**
  String get campaignChangeFeeHint;

  /// No description provided for @campaignChangeFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free to change'**
  String get campaignChangeFreeLabel;

  /// No description provided for @campaignChangeFreeHint.
  ///
  /// In en, this message translates to:
  /// **'No cost for this campaign'**
  String get campaignChangeFreeHint;

  /// No description provided for @campaignDeliverTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to {place}'**
  String campaignDeliverTo(String place);

  /// No description provided for @campaignWithinWindow.
  ///
  /// In en, this message translates to:
  /// **'During the window {time}'**
  String campaignWithinWindow(String time);

  /// No description provided for @campaignPaidWith.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get campaignPaidWith;

  /// No description provided for @campaignKeepAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Don\'t close the app'**
  String get campaignKeepAppOpen;

  /// No description provided for @campaignPayingOverlay.
  ///
  /// In en, this message translates to:
  /// **'Processing payment…'**
  String get campaignPayingOverlay;

  /// No description provided for @campaignChangingOverlay.
  ///
  /// In en, this message translates to:
  /// **'Changing…'**
  String get campaignChangingOverlay;

  /// No description provided for @campaignArchiveCompleteNote.
  ///
  /// In en, this message translates to:
  /// **'This purchase is complete and archived'**
  String get campaignArchiveCompleteNote;

  /// No description provided for @campaignPointsAddedToAccount.
  ///
  /// In en, this message translates to:
  /// **'Added to your account'**
  String get campaignPointsAddedToAccount;

  /// No description provided for @campaignBoughtLabel.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get campaignBoughtLabel;

  /// No description provided for @campaignDeliveredShort.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get campaignDeliveredShort;

  /// No description provided for @campaignPickedUpShort.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get campaignPickedUpShort;

  /// No description provided for @campaignMethodChangePending.
  ///
  /// In en, this message translates to:
  /// **'Change pending'**
  String get campaignMethodChangePending;

  /// No description provided for @campaignYourAddress.
  ///
  /// In en, this message translates to:
  /// **'your address'**
  String get campaignYourAddress;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['da', 'en', 'es', 'no', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'no':
      return AppLocalizationsNo();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
