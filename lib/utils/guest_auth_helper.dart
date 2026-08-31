import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/login/login.dart';
import 'package:aerend_customer/screens/common/signUp/sign_up.dart';
// Mode select temporarily skipped.
// import 'package:aerend_customer/screens/dugnad/mode_select_screen.dart';
import 'package:aerend_customer/screens/snurre/snurre_launcher_policy.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/utils/utils.dart';

enum GuestLoginPrompt {
  checkout,
  campaignCheckout,
  favorites,
  orders,
  address,
  promo,
  generic,
}

String _titleFor(GuestLoginPrompt prompt) {
  switch (prompt) {
    case GuestLoginPrompt.checkout:
    case GuestLoginPrompt.campaignCheckout:
      return languages.signInToCompleteOrder;
    case GuestLoginPrompt.favorites:
      return languages.signInToSaveFavorites;
    case GuestLoginPrompt.orders:
      return languages.signInToViewOrders;
    case GuestLoginPrompt.address:
      return languages.signInToSaveAddress;
    case GuestLoginPrompt.promo:
    case GuestLoginPrompt.generic:
      return languages.signIn;
  }
}

String _messageFor(GuestLoginPrompt prompt) {
  switch (prompt) {
    case GuestLoginPrompt.checkout:
    case GuestLoginPrompt.campaignCheckout:
      return languages.signInToCompleteOrderMessage;
    case GuestLoginPrompt.favorites:
      return languages.signInToSaveFavorites;
    case GuestLoginPrompt.orders:
      return languages.signInToViewOrders;
    case GuestLoginPrompt.address:
      return languages.signInToSaveAddress;
    case GuestLoginPrompt.promo:
    case GuestLoginPrompt.generic:
      return languages.guestAccountPromptMessage;
  }
}

bool isGuestUser() {
  return prefGetBool(prefIsGuestMode) && !isLoggedIn();
}

void enterGuestMode() {
  ensureLocalePrefsDefaults();
  prefSetBool(prefIsGuestMode, true);
}

void clearGuestMode() {
  prefSetBool(prefIsGuestMode, false);
}

void continueAsGuest(BuildContext context) {
  enterGuestMode();
  // ModeSelectScreen skipped — dugnad is the only mode for now.
  dugnadAuthDestination(isShowDialog: false).then((dest) {
    if (!context.mounted) return;
    openScreenWithClearPrevious(context, dest);
  });
}

/// Returns `true` if the user signed in successfully.
Future<bool> showGuestLoginSheet(
  BuildContext context, {
  GuestLoginPrompt prompt = GuestLoginPrompt.generic,
}) async {
  if (!isGuestUser()) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _titleFor(prompt),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _messageFor(prompt),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        settings: RouteSettings(
                          name: snurreLauncherRouteNameFor(
                            const Login(returnOnSuccess: true),
                          ),
                        ),
                        builder: (_) => const Login(returnOnSuccess: true),
                      ),
                    );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext, ok == true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScSaasThemeTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    languages.signIn,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUp(returnOnSuccess: true),
                      ),
                    );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext, ok == true);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScSaasThemeTokens.primary,
                    side: const BorderSide(color: ScSaasThemeTokens.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    languages.createAccount,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(
                  languages.cancel,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return result == true;
}

/// Persists store-checkout state so payment can resume after login.
void saveGuestStoreCheckoutResume({
  required int paymentType,
  required int takenType,
  required bool spendCredit,
}) {
  prefSetBool(prefGuestCheckoutResume, true);
  prefSetInt(prefGuestCheckoutPaymentType, paymentType);
  prefSetInt(prefGuestCheckoutTakenType, takenType);
  prefSetBool(prefGuestCheckoutSpendCredit, spendCredit);
}

void clearGuestStoreCheckoutResume() {
  prefSetBool(prefGuestCheckoutResume, false);
  prefSetInt(prefGuestCheckoutPaymentType, 0);
  prefSetInt(prefGuestCheckoutTakenType, 0);
  prefSetBool(prefGuestCheckoutSpendCredit, false);
}

bool consumeGuestStoreCheckoutResume() {
  final resume = prefGetBool(prefGuestCheckoutResume);
  if (!resume) return false;
  clearGuestStoreCheckoutResume();
  return true;
}

int guestCheckoutResumePaymentType() =>
    prefGetInt(prefGuestCheckoutPaymentType);

int guestCheckoutResumeTakenType() => prefGetInt(prefGuestCheckoutTakenType);

bool guestCheckoutResumeSpendCredit() =>
    prefGetBool(prefGuestCheckoutSpendCredit);

void saveGuestCampaignCheckoutResume({
  required String paymentMethod,
  required String payMode,
}) {
  prefSetBool(prefGuestCampaignCheckoutResume, true);
  prefSetString(prefGuestCampaignPaymentMethod, paymentMethod);
  prefSetString(prefGuestCampaignPayMode, payMode);
}

void clearGuestCampaignCheckoutResume() {
  prefSetBool(prefGuestCampaignCheckoutResume, false);
  prefSetString(prefGuestCampaignPaymentMethod, '');
  prefSetString(prefGuestCampaignPayMode, '');
}

bool consumeGuestCampaignCheckoutResume() {
  final resume = prefGetBool(prefGuestCampaignCheckoutResume);
  if (!resume) return false;
  clearGuestCampaignCheckoutResume();
  return true;
}

String guestCampaignResumePaymentMethod() =>
    prefGetString(prefGuestCampaignPaymentMethod);

String guestCampaignResumePayMode() => prefGetString(prefGuestCampaignPayMode);
