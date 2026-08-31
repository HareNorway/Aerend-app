import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/campaign/campaign_my_orders_screen.dart';
import 'package:aerend_customer/screens/dev/dev_env_screen.dart';
import 'package:aerend_customer/screens/common/account/account_detail.dart';
import 'package:aerend_customer/screens/common/account/redeem_code.dart';
import 'package:aerend_customer/screens/common/account/referral_code.dart';
import 'package:intercom_flutter/intercom_flutter.dart';

import '../../../commonView/circle_nav_bar.dart';
import '../../../commonView/guest_empty_state.dart';
import '../../../commonView/surface_decorations.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/dugnad_profile_section.dart';
import '../../dugnad/dugnad_state.dart';
import '../../dugnad/widgets/dugnad_bell_button.dart';
import '../../common/helpAndSupport/help_and_support.dart';
import '../orderHistory/order_history.dart';
import 'application_setting.dart';
import 'account_bloc.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  AccountState createState() => AccountState();
}

class AccountState extends State<Account> {
  AccountBloc? bloc;

  @override
  void initState() {
    super.initState();
    bloc = AccountBloc(context, this);
    if (prefGetString(prefAccessToken) != '') {
      Intercom.instance.loginIdentifiedUser(email: prefGetString(prefEmail));
    }
    if (DugnadState.instance.isDugnadMode && isLoggedIn()) {
      DugnadState.instance.syncPointsTeamFromServer().then((_) {
        if (mounted) setState(() {});
      });
      DugnadState.instance.syncClubThemeFromApi().then((_) {
        if (mounted) setState(() {});
      });
    }
    DugnadState.instance.revision.addListener(_onDugnadStateChanged);
  }

  void _onDugnadStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onDugnadStateChanged);
    bloc!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDugnad = DugnadState.instance.isDugnadMode;
    final theme = isDugnad ? context.dugnadTheme : null;
    final pageBg =
        theme?.background ?? ScSaasThemeTokens.background;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: isDugnad
          ? null
          : AppBar(
              backgroundColor: pageBg,
              automaticallyImplyLeading: false,
              toolbarHeight: 60,
              elevation: 0,
              title: GestureDetector(
                onLongPress: () {
                  if (!kReleaseMode) {
                    openScreen(context, const DevEnvScreen());
                  }
                },
                child: Text(languages.accountMyAccount, style: aeH2()),
              ),
              centerTitle: true,
            ),
      body: (isLoggedIn() || (isDugnad && isGuestUser()))
          ? (isDugnad
              // bottom: false — parent shell uses extendBody + floating pill;
              // SafeArea bottom would paint an opaque page-bg strip under the nav.
              ? SafeArea(bottom: false, child: _buildDugnadAccount(context))
              : _buildAccount())
          : _noAccount(),
    );
  }

  Widget _buildDugnadAccount(BuildContext context) {
    final theme = context.dugnadTheme;
    return StreamBuilder<String>(
      stream: bloc?.userName,
      builder: (context, nameSnap) {
        return StreamBuilder<String>(
          stream: bloc?.profileImg,
          builder: (context, imgSnap) {
            return ListView(
              // Clear floating pill + mockup breathing room under Sign out.
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                aePillNavReservedHeight(context) + context.dp(28),
              ),
              children: [
                // Design `.tk-head` — Profile title + bell (offers.jsx).
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () {
                            if (!kReleaseMode) {
                              openScreen(context, const DevEnvScreen());
                            }
                          },
                          child: Text(
                            languages.dugnadProfileTitle,
                            style: aeH2(color: theme.text),
                          ),
                        ),
                      ),
                      const DugnadBellButton(),
                    ],
                  ),
                ),
                DugnadProfileSection(
                  userName: nameSnap.data ?? '-',
                  avatarUrl: imgSnap.data ?? '',
                  onLogout: () => bloc!.openLogoutDialog(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAccount() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AeSurface.card(),
          child: Row(
            children: [
              StreamBuilder<String>(
                stream: bloc?.profileImg,
                builder: (context, snap) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LoadImageWithPlaceHolder(
                      image: snap.data ?? "",
                      width: 56,
                      height: 56,
                      defaultAssetImage: "assets/images/avatar_user.png",
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<String>(
                      stream: bloc?.userName,
                      builder: (context, snap) {
                        return Text(snap.data ?? "-", style: aeTitle());
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prefGetString(prefEmail),
                      style: aeCaption(),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () =>
                    openScreenWithResult(context, const AccountDetail()),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: ScSaasThemeTokens.primaryHover),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: AeSurface.card(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _settingsRow(
                icon: Icons.settings_outlined,
                label: 'Innstillinger',
                onTap: () => openScreenWithResult(
                    context, const ApplicationSetting()),
              ),
              _divider(),
              _settingsRow(
                icon: Icons.receipt_long_outlined,
                label: languages.orderHistory,
                onTap: () =>
                    openScreenWithResult(context, const OrderHistory()),
              ),
              _divider(),
              _settingsRow(
                icon: Icons.shopping_bag_outlined,
                label: languages.orderHistory,
                onTap: () => openScreenWithResult(
                    context, const CampaignMyOrdersScreen()),
              ),
              _divider(),
              _settingsRow(
                icon: Icons.headset_mic_outlined,
                label: 'Kundestøtte',
                onTap: () => openScreenWithResult(
                    context, const HelpAndSupport()),
              ),
              _divider(),
              _settingsRow(
                icon: Icons.card_giftcard_outlined,
                label: 'Henvisningskode',
                onTap: () =>
                    openScreenWithResult(context, const ReferralCode()),
              ),
              _divider(),
              _settingsRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Løs inn rabattkode',
                onTap: () =>
                    openScreenWithResult(context, const RedeemCode()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => bloc!.openLogoutDialog(),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ScSaasThemeTokens.danger, width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(languages.logout,
                style: aeLabel(color: ScSaasThemeTokens.danger)),
          ),
        ),
      ],
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ScSaasThemeTokens.primaryHover),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: aeBody())),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: ScSaasThemeTokens.gray500),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 52, color: ScSaasThemeTokens.gray100);

  Widget _noAccount() {
    return GuestEmptyState(
      title: languages.guestAccountPromptTitle,
      message: languages.guestAccountPromptMessage,
      imageAsset: 'assets/images/unregistered.png',
    );
  }
}
