import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../commonView/circle_nav_bar.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_branding.dart';
import '../../../ui/kit/ae_theme.dart';
import '../widgets/dugnad_points_pop.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../../../ui/kit/ae_support_share.dart';
import 'club_shop_models.dart';
import 'club_shop_orders_screen.dart';
import 'club_shop_screen.dart';

class ClubShopReceiptScreen extends StatelessWidget {
  const ClubShopReceiptScreen({
    super.key,
    required this.order,
    this.fresh = true,
  });

  final ClubShopPaidOrder order;
  final bool fresh;

  String get _placedLabel {
    final paid = order.paidAt?.toLocal();
    if (paid == null) return languages.dugnadClubShopOrderedToday;
    final hh = paid.hour.toString().padLeft(2, '0');
    final mm = paid.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay = paid.year == now.year &&
        paid.month == now.month &&
        paid.day == now.day;
    if (sameDay) {
      return languages.dugnadClubShopOrderedTodayTime('$hh:$mm');
    }
    return '${paid.day.toString().padLeft(2, '0')}.${paid.month.toString().padLeft(2, '0')} · $hh:$mm';
  }

  void _backToShop(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) =>
          route.settings.name == ClubShopScreen.routeName ||
          route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final partner = order.partnerName;
    final club = DugnadClubBranding.compactName();
    final code = order.orderNumber;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.background,
          body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              MediaQuery.paddingOf(context).top + context.dp(16),
              context.dp(18),
              context.dp(10),
            ),
            child: Row(
              children: [
                if (!fresh)
                  AeBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                else
                  SizedBox(width: context.dp(38)),
                Expanded(
                  child: Text(
                    languages.dugnadClubShopReceiptTitle,
                    textAlign: TextAlign.center,
                    style: aeH2(color: theme.text)
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w800)
                        .dp(context),
                  ),
                ),
                SizedBox(width: context.dp(38)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.dp(18),
                context.dp(12),
                context.dp(18),
                aePillNavReservedHeight(context) + context.dp(16),
              ),
              children: [
                if (fresh) ...[
                  Center(
                    child: Container(
                      width: context.dp(66),
                      height: context.dp(66),
                      decoration: BoxDecoration(
                        color: ScSaasThemeTokens.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x8C14663F),
                            blurRadius: context.dp(32),
                            offset: Offset(0, context.dp(8)),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: context.dp(30),
                      ),
                    ),
                  ),
                  SizedBox(height: context.dp(16)),
                  Text(
                    languages.dugnadClubShopThanks,
                    textAlign: TextAlign.center,
                    style: aeH2(color: theme.text)
                        .copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        )
                        .dp(context),
                  ),
                  SizedBox(height: context.dp(8)),
                  Text(
                    languages.dugnadClubShopShowNumber,
                    textAlign: TextAlign.center,
                    style: aeBody(color: ScSaasThemeTokens.gray500)
                        .copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        )
                        .dp(context),
                  ),
                  if (order.pointsAwarded > 0) ...[
                    SizedBox(height: context.dp(18)),
                    AeSuccessPointsBadge(
                      points: order.pointsAwarded,
                      label: languages.dugnadClubShopPointsAdded,
                      animate: fresh,
                    ),
                  ],
                  SizedBox(height: context.dp(18)),
                ],
                _ticket(context, theme, partner, club, code),
                SizedBox(height: context.dp(14)),
                _infoBox(
                  context,
                  theme,
                  icon: Icons.location_on_outlined,
                  title: languages.dugnadClubShopPickupAt(partner),
                  body: languages.dugnadClubShopPickupBody(
                    order.partnerAddress,
                    order.pickupPoint,
                  ),
                ),
                SizedBox(height: context.dp(12)),
                _infoBox(
                  context,
                  theme,
                  icon: Icons.receipt_long_outlined,
                  title: '',
                  body: languages.dugnadClubShopReceiptHint,
                ),
                if (fresh) ...[
                  SizedBox(height: context.dp(18)),
                  GestureDetector(
                    onTap: () => openScreen(
                      context,
                      const ClubShopOrdersScreen(),
                    ),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: context.dp(15)),
                      decoration: BoxDecoration(
                        gradient: theme.shinyGradient,
                        borderRadius: BorderRadius.circular(context.dp(16)),
                        boxShadow: theme.shadowButton,
                      ),
                      child: Text(
                        languages.dugnadClubShopSeeOrders,
                        style: aeBody(color: Colors.white)
                            .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )
                            .dp(context),
                      ),
                    ),
                  ),
                  SizedBox(height: context.dp(10)),
                  GestureDetector(
                    onTap: () => _backToShop(context),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: context.dp(15)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.dp(16)),
                        border: Border.all(
                          color: ScSaasThemeTokens.gray100,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A2D1B5B),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        languages.dugnadClubShopBackToShop,
                        style: aeBody(color: theme.text)
                            .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )
                            .dp(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
        ),
        if (fresh)
          DugnadPointsPopTrigger(
            points: order.pointsAwarded,
            reason: DugnadPointsPopReasons.clubShop(context),
            enabled: order.pointsAwarded > 0,
          ),
      ],
    );
  }

  Widget _ticket(
    BuildContext context,
    AeThemePalette theme,
    String partner,
    String club,
    String code,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x732D1B5B),
            blurRadius: 42,
            offset: Offset(0, context.dp(16)),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              context.dp(20),
              context.dp(18),
              context.dp(18),
            ),
            child: Column(
              children: [
                Text(
                  languages.dugnadClubShopOrderNumber.toUpperCase(),
                  style: aeOverline(color: ScSaasThemeTokens.gray500)
                      .copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 11.5 * 0.1,
                      )
                      .dp(context),
                ),
                SizedBox(height: context.dp(7)),
                Text(
                  code,
                  style: aeH2(color: theme.text)
                      .copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      )
                      .dp(context),
                ),
                SizedBox(height: context.dp(16)),
                Container(
                  width: context.dp(168),
                  height: context.dp(168),
                  padding: EdgeInsets.all(context.dp(11)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.dp(16)),
                    border: Border.all(color: ScSaasThemeTokens.gray100),
                  ),
                  child: order.qrPayload.isEmpty
                      ? const SizedBox.shrink()
                      : QrImageView(
                          data: order.qrPayload,
                          version: QrVersions.auto,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF16181F),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF16181F),
                          ),
                        ),
                ),
                SizedBox(height: context.dp(12)),
                Text(
                  languages.dugnadClubShopScanAt(partner),
                  textAlign: TextAlign.center,
                  style: aeCaption(color: ScSaasThemeTokens.gray500)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w700)
                      .dp(context),
                ),
              ],
            ),
          ),
          SizedBox(
            height: context.dp(22),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -context.dp(11),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: context.dp(22),
                      height: context.dp(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.background,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -context.dp(11),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: context.dp(22),
                      height: context.dp(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.background,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: context.dp(18)),
                    height: 2,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: ScSaasThemeTokens.gray100,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              context.dp(4),
              context.dp(18),
              context.dp(20),
            ),
            child: Column(
              children: [
                for (final line in order.items)
                  _metaRow(
                    context,
                    theme,
                    '${line.qty} × ${line.name} · ${line.size}',
                    shopKr(line.lineMember),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: context.dp(6)),
                  child: Divider(color: ScSaasThemeTokens.gray100, height: 1),
                ),
                _metaRow(
                  context,
                  theme,
                  languages.dugnadClubShopMemberDiscountLabel,
                  '−${shopKr(order.discountSum)}',
                  valueColor: ScSaasThemeTokens.success,
                ),
                _metaRow(
                  context,
                  theme,
                  languages.dugnadClubShopPaidLabel,
                  shopKr(order.amountPaid),
                  large: true,
                ),
                _metaRow(
                  context,
                  theme,
                  languages.dugnadClubShopClubLabel,
                  '$club × $partner',
                ),
                _metaRow(
                  context,
                  theme,
                  languages.dugnadClubShopMemberNoLabel,
                  order.membershipNumber,
                ),
                _metaRow(
                  context,
                  theme,
                  languages.dugnadClubShopPlacedLabel,
                  _placedLabel,
                ),
                if (order.pointsAwarded > 0)
                  _metaRow(
                    context,
                    theme,
                    languages.dugnadClubShopPointsLabel,
                    '+${order.pointsAwarded}',
                    valueColor: theme.primaryHover,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(
    BuildContext context,
    AeThemePalette theme,
    String label,
    String value, {
    Color? valueColor,
    bool large = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(7)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: aeCaption(color: ScSaasThemeTokens.gray500)
                  .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)
                  .dp(context),
            ),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: aeBody(color: valueColor ?? theme.text)
                  .copyWith(
                    fontSize: large ? 15 : 12.5,
                    fontWeight: FontWeight.w800,
                  )
                  .dp(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(
    BuildContext context,
    AeThemePalette theme, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(14),
        context.dp(13),
        context.dp(14),
        context.dp(13),
      ),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: context.dp(17), color: theme.primaryHover),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: aeBody(color: theme.text)
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w800)
                        .dp(context),
                  ),
                  SizedBox(height: context.dp(3)),
                ],
                Text(
                  body,
                  style: aeBody(color: ScSaasThemeTokens.gray600)
                      .copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      )
                      .dp(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
