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
  /// **'Login to Ærend'**
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
  /// **'Join Ærend — every order gives back to the club'**
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
  /// **'Get Started with Ærend'**
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
  /// **'Get started with Ærend'**
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

  /// No description provided for @feed_empty_no_posts.
  ///
  /// In en, this message translates to:
  /// **'The stores you follow haven\'t posted yet — check back soon!'**
  String get feed_empty_no_posts;

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

  /// No description provided for @story_viewer_unavailable.
  ///
  /// In en, this message translates to:
  /// **'This story is no longer available'**
  String get story_viewer_unavailable;

  /// No description provided for @post_detail_unavailable.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available'**
  String get post_detail_unavailable;

  /// No description provided for @post_detail_go_back.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get post_detail_go_back;

  /// No description provided for @feed_tab_stores.
  ///
  /// In en, this message translates to:
  /// **'Published by stores'**
  String get feed_tab_stores;

  /// No description provided for @feed_tab_aerend.
  ///
  /// In en, this message translates to:
  /// **'Published by Ærend'**
  String get feed_tab_aerend;

  /// No description provided for @feed_category_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feed_category_all;

  /// No description provided for @feed_vaagen_title.
  ///
  /// In en, this message translates to:
  /// **'The daily catch'**
  String get feed_vaagen_title;

  /// No description provided for @feed_vaagen_pull.
  ///
  /// In en, this message translates to:
  /// **'Pull it in'**
  String get feed_vaagen_pull;

  /// No description provided for @feed_vaagen_done.
  ///
  /// In en, this message translates to:
  /// **'Today\'s catch is pulled in'**
  String get feed_vaagen_done;

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

  /// No description provided for @dugnadMembershipPrompt.
  ///
  /// In en, this message translates to:
  /// **'Got a membership number? Enter it to unlock exclusive discounts.'**
  String get dugnadMembershipPrompt;

  /// No description provided for @dugnadContinueAsSupporter.
  ///
  /// In en, this message translates to:
  /// **'Continue as supporter'**
  String get dugnadContinueAsSupporter;

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

  /// No description provided for @dugnadMembershipOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'You can add your membership number at any time.'**
  String get dugnadMembershipOptionalHint;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select address'**
  String get selectAddress;

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

  /// No description provided for @dugnadPointsTeamChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dugnadPointsTeamChange;

  /// No description provided for @dugnadPointsActionReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get dugnadPointsActionReversal;

  /// No description provided for @dugnadProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dugnadProfileTitle;

  /// No description provided for @dugnadClubShopVerified.
  ///
  /// In en, this message translates to:
  /// **'Verifisert medlem'**
  String get dugnadClubShopVerified;

  /// No description provided for @dugnadClubShopAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} ({size}) added to the cart'**
  String dugnadClubShopAdded(String name, String size);

  /// No description provided for @dugnadClubShopStockGone.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get dugnadClubShopStockGone;

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

  /// No description provided for @dugnadClubShopPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Show the order number when you pick up.'**
  String get dugnadClubShopPaid;

  /// No description provided for @dugnadClubShopRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dugnadClubShopRemoveItem;

  /// No description provided for @dugnadClubShopBrowseSoon.
  ///
  /// In en, this message translates to:
  /// **'The collection opens here after you unlock.'**
  String get dugnadClubShopBrowseSoon;

  /// No description provided for @dugnadCampaignsFromClub.
  ///
  /// In en, this message translates to:
  /// **'Campaigns from {club}'**
  String dugnadCampaignsFromClub(String club);

  /// No description provided for @campaignOrderStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Order status'**
  String get campaignOrderStatusLabel;

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

  /// No description provided for @dugnadTransitionWindowSoon.
  ///
  /// In en, this message translates to:
  /// **'The transition window is coming soon'**
  String get dugnadTransitionWindowSoon;

  /// No description provided for @dugnadCareerSoon.
  ///
  /// In en, this message translates to:
  /// **'Your career timeline is coming soon'**
  String get dugnadCareerSoon;

  /// No description provided for @dugnadCareerTeamsMulti.
  ///
  /// In en, this message translates to:
  /// **'{team} · {count} teams'**
  String dugnadCareerTeamsMulti(String team, int count);

  /// No description provided for @dugnadVisibilitySoon.
  ///
  /// In en, this message translates to:
  /// **'Visibility coming soon'**
  String get dugnadVisibilitySoon;

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

  /// No description provided for @dugnadPreviewLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a level to see the upgrade'**
  String get dugnadPreviewLevelHint;

  /// No description provided for @dugnadShareCardMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m now {tier} on Reen Dugnad 💜'**
  String dugnadShareCardMessage(String tier);

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

  /// No description provided for @dugnadUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get dugnadUnlock;

  /// No description provided for @dugnadFundraisingYtd.
  ///
  /// In en, this message translates to:
  /// **'The club has raised {amount} this year'**
  String dugnadFundraisingYtd(String amount);

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

  /// No description provided for @dugnadReferralPromoBenefit.
  ///
  /// In en, this message translates to:
  /// **'+{points} points for every friend who joins — right away.'**
  String dugnadReferralPromoBenefit(int points);

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

  /// No description provided for @dugnadMembershipSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get dugnadMembershipSectionTitle;

  /// No description provided for @dugnadLeaderboardChooseAnotherClub.
  ///
  /// In en, this message translates to:
  /// **'Choose another club'**
  String get dugnadLeaderboardChooseAnotherClub;

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

  /// No description provided for @dugnadLeaderboardPointsValue.
  ///
  /// In en, this message translates to:
  /// **'{points} POINTS'**
  String dugnadLeaderboardPointsValue(String points);

  /// No description provided for @dugnadLeaderboardNoClub.
  ///
  /// In en, this message translates to:
  /// **'Choose a club to see the team competition.'**
  String get dugnadLeaderboardNoClub;

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

  /// No description provided for @dugnadDonationPointsUnit.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get dugnadDonationPointsUnit;

  /// No description provided for @dugnadDonationPauseComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Pause is coming soon.'**
  String get dugnadDonationPauseComingSoon;

  /// No description provided for @dugnadDonationComingSoonBackend.
  ///
  /// In en, this message translates to:
  /// **'Vipps recurring setup is coming soon.'**
  String get dugnadDonationComingSoonBackend;

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

  /// No description provided for @dugnadDonationManageTitle.
  ///
  /// In en, this message translates to:
  /// **'My regular support'**
  String get dugnadDonationManageTitle;

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

  /// No description provided for @dugnadMealBoxFromClub.
  ///
  /// In en, this message translates to:
  /// **'Meal box from the club'**
  String get dugnadMealBoxFromClub;

  /// No description provided for @dugnadCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get dugnadCampaign;

  /// No description provided for @dugnadChooseClubForCampaigns.
  ///
  /// In en, this message translates to:
  /// **'You need to choose a club to see campaigns.'**
  String get dugnadChooseClubForCampaigns;

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

  /// No description provided for @dugnadCampaignFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {amount} kr'**
  String dugnadCampaignFromPrice(String amount);

  /// No description provided for @dugnadSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dugnadSave;

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

  /// No description provided for @campaignChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get campaignChange;

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
  /// **'Ærend Version'**
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
  /// **'Share the joy of Ærend with your friends and earn rewards together! Invite a friend to join Ærend and both of you will receive exciting benefits. Spread the word — every order gives back to the club!'**
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

  /// No description provided for @dugnadCarryoverPerLevelSub.
  ///
  /// In en, this message translates to:
  /// **'Your metal level at season end sets how much of your season points carry over into next season.'**
  String get dugnadCarryoverPerLevelSub;

  /// No description provided for @dugnadCarryoverHighlight.
  ///
  /// In en, this message translates to:
  /// **'Reach {tier} ({sto} STØ) → carry {percent} % to next season 🚀'**
  String dugnadCarryoverHighlight(String tier, int sto, int percent);

  /// No description provided for @dugnadGateRefer.
  ///
  /// In en, this message translates to:
  /// **'Create an account to invite friends'**
  String get dugnadGateRefer;

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

  /// No description provided for @ops_status_placed_customer.
  ///
  /// In en, this message translates to:
  /// **'Sent to the store'**
  String get ops_status_placed_customer;

  /// No description provided for @ops_status_placed_partner.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get ops_status_placed_partner;

  /// No description provided for @ops_status_placed_courier.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get ops_status_placed_courier;

  /// No description provided for @ops_status_accepted_customer.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ops_status_accepted_customer;

  /// No description provided for @ops_status_accepted_partner.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ops_status_accepted_partner;

  /// No description provided for @ops_status_accepted_courier.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get ops_status_accepted_courier;

  /// No description provided for @ops_status_seen_customer.
  ///
  /// In en, this message translates to:
  /// **'Being prepared'**
  String get ops_status_seen_customer;

  /// No description provided for @ops_status_seen_partner.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get ops_status_seen_partner;

  /// No description provided for @ops_status_seen_courier.
  ///
  /// In en, this message translates to:
  /// **'Being prepared'**
  String get ops_status_seen_courier;

  /// No description provided for @ops_status_ready_customer.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get ops_status_ready_customer;

  /// No description provided for @ops_status_ready_partner.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ops_status_ready_partner;

  /// No description provided for @ops_status_ready_courier.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get ops_status_ready_courier;

  /// No description provided for @ops_status_picked_up_customer.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get ops_status_picked_up_customer;

  /// No description provided for @ops_status_picked_up_partner.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get ops_status_picked_up_partner;

  /// No description provided for @ops_status_picked_up_courier.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get ops_status_picked_up_courier;

  /// No description provided for @ops_status_arrived_customer_customer.
  ///
  /// In en, this message translates to:
  /// **'Courier has arrived'**
  String get ops_status_arrived_customer_customer;

  /// No description provided for @ops_status_arrived_customer_partner.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get ops_status_arrived_customer_partner;

  /// No description provided for @ops_status_arrived_customer_courier.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get ops_status_arrived_customer_courier;

  /// No description provided for @ops_status_delivered_customer.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ops_status_delivered_customer;

  /// No description provided for @ops_status_delivered_partner.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ops_status_delivered_partner;

  /// No description provided for @ops_status_delivered_courier.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ops_status_delivered_courier;

  /// No description provided for @ops_status_cancelled_customer.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ops_status_cancelled_customer;

  /// No description provided for @ops_status_cancelled_partner.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get ops_status_cancelled_partner;

  /// No description provided for @ops_status_cancelled_courier.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ops_status_cancelled_courier;

  /// No description provided for @ops_status_paused.
  ///
  /// In en, this message translates to:
  /// **'Opening again soon'**
  String get ops_status_paused;

  /// No description provided for @ops_status_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get ops_status_unknown;
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
