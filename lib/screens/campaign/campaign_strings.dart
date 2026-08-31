import '../../utils/utils.dart';

/// Campaign feature UI strings — backed by ARB localization.
class CampaignStrings {
  // List screen
  static String get matkasser => languages.campaignMatkasser;
  static String get noActiveCampaigns => languages.campaignNoActiveCampaigns;
  static String get orderBefore => languages.campaignOrderBefore;
  static String get deliveryDay => languages.campaignDeliveryDay;
  static String get from => languages.campaignFromPrice;

  // Detail screen
  static String get support => languages.campaignSupport;
  static String get chooseBox => languages.campaignChooseBox;
  static String get chooseYourMatkasse => languages.campaignChooseYourMatkasse;
  static String get orderBy => languages.campaignOrderBy;
  static String get allProfitToClub => languages.campaignAllProfitToClub;
  static String allProfitToSupport(String supportName) {
    if (supportName.trim().isEmpty) return allProfitToClub;
    return allProfitToClub
        .replaceAll('klubben', supportName)
        .replaceAll('the club', supportName)
        .replaceAll('the Club', supportName)
        .replaceAll('club', supportName);
  }
  static String get viewDetails => languages.campaignViewDetails;
  static String get descriptionHeading => languages.campaignDescriptionHeading;
  static String get contentsHeading => languages.campaignContentsHeading;
  static String get pricePerBox => languages.campaignPricePerBox;
  static String get contains => languages.campaignContains;
  static String get addToCart => languages.storeAddToCart;
  static String get goToCheckout => languages.campaignGoToCheckout;
  static String get campaignEnded => languages.campaignEnded;
  static String get campaignEndedBody => languages.campaignEndedBody;
  static String get campaignUpcoming => languages.campaignUpcoming;
  static String get campaignUpcomingBody => languages.campaignUpcomingBody;
  static String get suppliedBy => languages.campaignSuppliedBy;
  static String get clubEarns => languages.campaignClubEarns;

  // Checkout
  static String get yourOrder => languages.campaignYourOrder;
  static String get deliveryMethod => languages.campaignDeliveryMethod;
  static String get homeDelivery => languages.campaignHomeDelivery;
  static String get pickupAtClub => languages.campaignPickupAtClub;
  static String get contactInfo => languages.campaignContactInfo;
  static String get fullName => languages.fullName;
  static String get email => languages.email;
  static String get phone => languages.campaignPhone;
  static String get deliveryAddress => languages.deliveryAddress;
  static String get streetAddress => languages.campaignStreetAddress;
  static String get postalCode => languages.campaignPostalCode;
  static String get city => languages.campaignCity;
  static String get paymentMethod => languages.campaignPaymentMethod;
  static String get payVipps => languages.campaignPayVipps;
  static String get payWithVippsSemanticsLabel => languages.campaignPayWithVipps;
  static String get payCard => languages.campaignPayCard;
  static String get payNow => languages.payNow;
  static String get processing => languages.campaignProcessing;
  static String get total => languages.campaignTotal;
  static String get swipeToPay => languages.campaignSwipeToPay;
  static String get subtotal => languages.campaignSubtotal;
  static String get paymentHeading => languages.campaignPaymentHeading;
  static String get change => languages.campaignChange;
  static String get deliveryTab => languages.checkoutDeliveryTab;
  static String get pickupTab => languages.checkoutPickupTab;
  static String get emptyCart => languages.campaignEmptyCart;

  // Confirmation
  static String get thankYou => languages.campaignThankYou;
  static String get confirmationSent => languages.campaignConfirmationSent;
  static String get orderNumber => languages.campaignOrderNumber;
  static String get distributionDate => languages.campaignDistributionDate;
  static String get viewMyOrders => languages.campaignViewMyOrders;
  static String get backToHome => languages.campaignBackToHome;
  static String get paymentFailed => languages.campaignPaymentFailed;
  static String get paymentFailedBody => languages.campaignPaymentFailedBody;
  static String contributionToSupport(String amount, String supportName) =>
      languages.campaignContributionToSupport(amount, supportName);
  static String pointsEarnedForTeam(int points, String teamName) =>
      languages.campaignPointsEarnedForTeam(points, teamName);

  // My orders
  static String get myMatkasser => languages.campaignMyMatkasser;
  static String ordersBoughtBanner(int count) =>
      languages.campaignOrdersBoughtBanner(count);
  static String get ordersBoughtBannerSub =>
      languages.campaignOrdersBoughtBannerSub;
  static String get noOrders => languages.campaignNoOrders;
  static String get paid => languages.campaignPaid;
  static String get pending => languages.campaignPending;
  static String get failed => languages.campaignFailed;

  // Errors
  static String get somethingWentWrong => languages.campaignSomethingWentWrong;
  static String get tryAgain => languages.tryAgain;
  static String get nameRequired => languages.campaignNameRequired;
  static String get emailRequired => languages.campaignEmailRequired;
  static String get phoneRequired => languages.campaignPhoneRequired;
  static String get addressRequired => languages.campaignAddressRequired;

  // Payment init error (was hardcoded in checkout screen)
  static String get paymentInitFailed => languages.campaignPaymentInitFailed;

  // ---- Campaign purchases: overview, countdown & tracker (Chunk 4) ----
  // Tracker
  static String get purchasesTitle => languages.campaignPurchasesTitle;
  static String get purchasesEntryTitle => languages.campaignPurchasesEntryTitle;
  static String get purchasesEntrySubtitle =>
      languages.campaignPurchasesEntrySubtitle;
  static String trackerMore(int count) => languages.campaignTrackerMore(count);
  static String get trackerLocked => languages.campaignTrackerLocked;
  // Countdown units
  static String get unitDay => languages.campaignUnitDay;
  static String get unitDays => languages.campaignUnitDays;
  static String get unitHour => languages.campaignUnitHour;
  static String get unitHours => languages.campaignUnitHours;
  static String get unitMin => languages.campaignUnitMin;
  static String get unitSec => languages.campaignUnitSec;
  static String get countdownDeliverIn => languages.campaignCountdownDeliverIn;
  static String get countdownPickupIn => languages.campaignCountdownPickupIn;
  // Overview
  static String tabActive(int count) => languages.campaignTabActive(count);
  static String get tabArchive => languages.campaignTabArchive;
  static String get activeEmptyTitle => languages.campaignActiveEmptyTitle;
  static String get activeEmptyBody => languages.campaignActiveEmptyBody;
  static String get archiveEmptyTitle => languages.campaignArchiveEmptyTitle;
  static String get archiveEmptyBody => languages.campaignArchiveEmptyBody;
  // Active card
  static String receiptBought(String date) => languages.campaignReceiptBought(date);
  static String get rowPaid => languages.campaignRowPaid;
  static String get rowDeliveryDay => languages.campaignRowDeliveryDay;
  static String get rowPickupDay => languages.campaignRowPickupDay;
  static String get rowTimeSlot => languages.campaignRowTimeSlot;
  static String get rowAddress => languages.campaignRowAddress;
  static String get rowPickupPlace => languages.campaignRowPickupPlace;
  static String get rowMethod => languages.campaignRowMethod;
  static String get methodDelivery => languages.campaignMethodDelivery;
  static String get methodPickup => languages.campaignMethodPickup;
  static String pointsChip(int points) => languages.campaignPointsChip(points);
  static String get pointsUnit => languages.campaignPointsUnit;
  static String get changeButton => languages.campaignChangeButton;
  static String get lockedButton => languages.campaignLockedButton;
  // Method change
  static String changeSheetTitle(String method) => languages.campaignChangeSheetTitle(method);
  static String freeChangeUntil(String time) => languages.campaignFreeChangeUntil(time);
  static String changeFee(String fee) => languages.campaignChangeFee(fee);
  static String get confirmChange => languages.campaignConfirmChange;
  // `swipeToPay` already exists above (reused, not redeclared).
  static String get changeProcessing => languages.campaignChangeProcessing;
  static String changeDoneTitle(String method) => languages.campaignChangeDoneTitle(method);
  static String changeSuccessToast(String method) => languages.campaignChangeSuccessToast(method);
  // Lock message
  static String lockMessage(String datetime, {required bool delivery}) =>
      languages.campaignLockMessage(
        datetime,
        delivery
            ? languages.campaignLockSeeYouDoor
            : languages.campaignLockSeeYouPickup,
      );
  // Errors
  static String errorMethodNotOffered(String methods) => languages.campaignErrorMethodNotOffered(methods);
  static String get errorNoChange => languages.campaignErrorNoChange;
  static String get errorGeneric => languages.campaignErrorGeneric;
  // Archive
  static String archiveDelivered(String day) => languages.campaignArchiveDelivered(day);
  static String archivePickedUp(String day) => languages.campaignArchivePickedUp(day);
  static String get archivePointsEarnedLabel => languages.campaignArchivePointsEarnedLabel;
  static String archivePointsTotal(int count) => languages.campaignArchivePointsTotal(count);
  static String archiveCount(int count) => languages.campaignArchiveCount(count);
  static String get viewFullHistory => languages.campaignViewFullHistory;
  static String get changeFeeLabel => languages.campaignChangeFeeLabel;
  static String get changeFeeHint => languages.campaignChangeFeeHint;
  static String get changeFreeLabel => languages.campaignChangeFreeLabel;
  static String get changeFreeHint => languages.campaignChangeFreeHint;
  static String deliverTo(String place) => languages.campaignDeliverTo(place);
  static String pickupAtName(String place) => languages.campaignPickupAtClubName(place);
  static String withinWindow(String time) => languages.campaignWithinWindow(time);
  static String get paidWith => languages.campaignPaidWith;
  static String get keepAppOpen => languages.campaignKeepAppOpen;
  static String get payingOverlay => languages.campaignPayingOverlay;
  static String get changingOverlay => languages.campaignChangingOverlay;
  static String get archiveCompleteNote => languages.campaignArchiveCompleteNote;
  static String get pointsAddedToAccount => languages.campaignPointsAddedToAccount;
  static String get boughtLabel => languages.campaignBoughtLabel;
  static String get deliveredShort => languages.campaignDeliveredShort;
  static String get pickedUpShort => languages.campaignPickedUpShort;
  static String get methodChangePending => languages.campaignMethodChangePending;
  static String get yourAddress => languages.campaignYourAddress;
}
