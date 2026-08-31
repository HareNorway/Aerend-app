import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../commonView/customCountryCodePicker/country_code.dart';
import '../screens/common/chatting/chatting.dart';
import '../screens/common/notifications/notifications.dart';

export 'chat_constant.dart';
export 'colors.dart';
export 'dimensions.dart';

const stripePublishableKey =
    // "pk_test_51OuAwNRtRZ7Sf1Zqmbk7Mk06ucjWs3mHkemPKETlFEj3EpUzkCPIk03A6XpuuuscghAzL0y4etcoXuhvRLmRpbPF00Erk10Stm";
    "pk_live_51OuAwNRtRZ7Sf1ZqAc9zzKogVcHgR1yw2fug6ulaFq7Atw47Ea3eZkAQ4W549R8ZgIcnPqStnIhhZcbDGT59e3po00pJ8dR0sg";
const firebaseTopicName = "HareCustomer";
const appleId = "6478966156";

final CountryCode defaultCountryCode = CountryCode(
  name: "Norge",
  code: "NO",
  dialCode: "+47",
);

const String defaultCurrency = "NOK";
// Ærend ships Norwegian-first — the prototype copy is Norwegian and the
// product is Bergen-local. `intl_no.arb` is the matching bundle.
const String defaultLanguage = "no";

const int loginDeviceFlutterAndroid = 3;
const int loginDeviceFlutterIos = 4;
const int maxItems = 10;

//Chat with users...
const int chatWithTypeUser = 0;
const int chatWithTypeStore = 1;
const int chatWithTypeDriver = 2;

//Add-On Typs
const int typeToppingOption = 0;
const int typeSizeColor = 1;

//Dynamic Modules
const bool showWalletTransferModule = true;
const bool showSurgeChargeModule = true;
const bool showChildSeatModule = true;
const bool showHandicapModule = true;
const bool showRideForOther = true;
const bool isDemoApp = false;
const bool showInviteFriends = true;
const bool showChatWithAdmin = true;
const bool showEmergencyNumber = true;
const bool isMultiOrderDelivery = true;

late double deviceWidth;
late double deviceHeight;
late double deviceAverageSize;
late double textScaleFactorOf;

bool isChatOpen = false;
State<Chatting>? chatState;
State<Notifications>? notificationState;

//LOGIN TYPE
const loginTypeFacebook = "facebook";
const loginTypeGoogle = "google";
const loginTypeEmail = "email";
const loginTypeApple = "apple";
const loginTypeVipps = "vipps";

const double defaultMapZoom = 5.00;

// const defaultLatLng = LatLng(0, 0);
const defaultLatLng = LatLng(60.3913, 5.3221);

const initCameraPosition = CameraPosition(
  target: defaultLatLng,
  zoom: defaultMapZoom,
);

//PAGINATION
const int perPageRecord = 10;

//ADDRESS TYPE
const home = "home";
const work = "work";
const other = "other";

//PAYMENT TYPE
const paymentTypeCash = 1;
const paymentTypeCard = 2;
const paymentTypeWallet = 3;
const showCashPayment = true;
const showCardPayment = true;
const showWalletPayment = true;

//SELECT PAYMENT METHOD
const deliveries = "deliveries";
const rides = "rides";
const courier = "courier";
const wallet = "wallet";

const List<int> deliveryServiceCatIdList = [5, 6, 7, 8, 9, 10];

//TAKE AWAY
const delivery = 1;
const pickup = 2;

const filterTypeAll = 0;
const filterTypeToday = 1;
const filterTypeLast7Days = 2;
const filterTypeThisMonth = 3;
const filterTypeYear = 4;
const filterTypeUpcoming = 5;
const filterTypeRunning = 6;

BuildContext? scContext;
String firebaseProjectId = "";
