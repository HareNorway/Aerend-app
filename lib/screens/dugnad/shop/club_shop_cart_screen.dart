import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../commonView/dugnad_club_loader.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/global_loading_overlay.dart';
import '../../../utils/stripe_payment_helper.dart';
import '../../../utils/utils.dart';
import '../club_crest.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';
import '../../campaign/widgets/campaign_swipe_pay_bar.dart';
import '../widgets/dugnad_checkout_payment_selector.dart';
import '../widgets/dugnad_points_earn.dart';
import '../widgets/dugnad_subpage_shell.dart';
import '../widgets/mk_qty_stepper.dart';
import 'club_shop_cart.dart';
import 'club_shop_models.dart';
import 'club_shop_receipt_screen.dart';
import 'club_shop_screen.dart';
import 'club_shop_vipps_return.dart';

class ClubShopCartScreen extends StatefulWidget {
  const ClubShopCartScreen({super.key});

  @override
  State<ClubShopCartScreen> createState() => _ClubShopCartScreenState();
}

class _ClubShopCartScreenState extends State<ClubShopCartScreen> {
  final ClubShopCart _cart = ClubShopCart.instance;
  final DugnadRepo _repo = DugnadRepo();
  DugnadCheckoutPayMethod _pay = dugnadCheckoutDefaultPayMethod();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCart);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCart);
    super.dispose();
  }

  void _onCart() {
    if (mounted) setState(() {});
  }

  Future<void> _payNow() async {
    if (_busy || _cart.itemCount == 0) return;
    setState(() => _busy = true);
    final isWallet = _pay == DugnadCheckoutPayMethod.platformWallet;
    final method =
        _pay == DugnadCheckoutPayMethod.vipps ? 'vipps' : 'stripe';
    try {
      final response = await _repo.clubShopPay(
        clubId: DugnadState.instance.clubId,
        lines: _cart.toApiLines(),
        paymentMethod: method,
        phone: prefGetString(prefContactNumber),
      );
      if (!mounted) return;
      if (response == null || response['status'] != 1) {
        setState(() => _busy = false);
        openSimpleSnackbar(
          (response?['message'] as String?)?.trim().isNotEmpty == true
              ? response!['message'].toString()
              : languages.dugnadClubShopPayInitFailed,
          kind: AeToastKind.error,
        );
        return;
      }

      final payment = response['payment'] is Map
          ? Map<String, dynamic>.from(response['payment'] as Map)
          : <String, dynamic>{};
      final order = response['order'] is Map
          ? Map<String, dynamic>.from(response['order'] as Map)
          : <String, dynamic>{};
      final clientSecret = payment['client_secret']?.toString();
      final redirectUrl = payment['redirect_url']?.toString();
      final ref = (payment['reference'] ??
              order['payment_ref'] ??
              order['order_number'] ??
              '')
          .toString();
      final totalPay = (_cart.totalMember).toDouble();

      if (method == 'vipps' && redirectUrl != null && redirectUrl.isNotEmpty) {
        savePendingClubShopVippsCheckout(
          paymentRef: ref,
          clubId: DugnadState.instance.clubId,
        );
        setState(() => _busy = false);
        final uri = Uri.tryParse(redirectUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      }

      if (method == 'stripe' && clientSecret != null && clientSecret.isNotEmpty) {
        if (isWallet) {
          await StripePaymentHelper.confirmPlatformPay(
            clientSecret: clientSecret,
            orderNo: ref,
            totalPay: totalPay,
            platform: Theme.of(context).platform,
          );
          if (mounted) setState(() => _busy = false);
        } else {
          await StripePaymentHelper.presentPaymentSheet(
            clientSecret: clientSecret,
            orderNo: ref,
            totalPay: totalPay,
            onReadyToPresent: () {
              if (mounted) setState(() => _busy = false);
            },
          );
        }
        if (!mounted) return;
        ClubShopPaidOrder? paid;
        final confirm = await withGlobalLoadingOverlay(() async {
          return _repo.clubShopConfirm(
            clubId: DugnadState.instance.clubId,
            paymentRef: ref,
          );
        }, message: languages.dugnadClubShopProcessing);
        if (!mounted) return;
        if (confirm != null && clubShopOrderIsPaid(confirm)) {
          final paidJson = confirm['order'] is Map
              ? Map<String, dynamic>.from(confirm['order'] as Map)
              : <String, dynamic>{};
          paid = ClubShopPaidOrder.fromJson(paidJson);
          if (paid.items.isEmpty) {
            paid = ClubShopPaidOrder(
              orderNumber: paid.orderNumber,
              membershipNumber: paid.membershipNumber.isNotEmpty
                  ? paid.membershipNumber
                  : _cart.member.number,
              partnerName: paid.partnerName.isNotEmpty
                  ? paid.partnerName
                  : _cart.partner.name,
              partnerAddress: paid.partnerAddress.isNotEmpty
                  ? paid.partnerAddress
                  : _cart.partner.address,
              pickupPoint: paid.pickupPoint.isNotEmpty
                  ? paid.pickupPoint
                  : _cart.partner.pickupPoint,
              status: paid.status,
              ordinarySum: paid.ordinarySum != 0
                  ? paid.ordinarySum
                  : _cart.ordinaryTotal,
              discountSum: paid.discountSum != 0
                  ? paid.discountSum
                  : _cart.discountTotal,
              amountPaid:
                  paid.amountPaid != 0 ? paid.amountPaid : _cart.totalMember,
              pointsAwarded: paid.pointsAwarded != 0
                  ? paid.pointsAwarded
                  : _cart.pointsPerOrder,
              paidAt: paid.paidAt ?? DateTime.now(),
              items: _cart.lines
                  .map(
                    (l) => ClubShopReceiptLine(
                      name: l.product.name,
                      size: l.size,
                      qty: l.qty,
                      memberUnit: l.product.memberPrice,
                      ordinaryUnit: l.product.ordinaryPrice,
                    ),
                  )
                  .toList(),
            );
          }
          _cart.clear();
          if (!mounted) return;
          setState(() => _busy = false);
          await Future<void>.delayed(Duration.zero);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ClubShopReceiptScreen(
                order: paid!,
                fresh: true,
              ),
            ),
            (route) =>
                route.settings.name == ClubShopScreen.routeName ||
                route.isFirst,
          );
        } else {
          openSimpleSnackbar(
            languages.dugnadClubShopPayFailed,
            kind: AeToastKind.error,
          );
        }
        return;
      }

      setState(() => _busy = false);
      openSimpleSnackbar(
        languages.dugnadClubShopPayInitFailed,
        kind: AeToastKind.error,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      openSimpleSnackbar(
        languages.dugnadClubShopPayFailed,
        kind: AeToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final qty = _cart.itemCount;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.dp(18),
                  MediaQuery.paddingOf(context).top + context.dp(8),
                  context.dp(18),
                  context.dp(10),
                ),
                child: Row(
                  children: [
                    DugnadLbBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        languages.dugnadClubShopCartTitle,
                        textAlign: TextAlign.center,
                        style: aeH2(color: theme.text)
                            .copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            )
                            .dp(context),
                      ),
                    ),
                    SizedBox(width: context.dp(38)),
                  ],
                ),
              ),
              Expanded(
                child: qty == 0
                    ? _empty(context, theme)
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          context.dp(18),
                          context.dp(4),
                          context.dp(18),
                          context.dp(24),
                        ),
                        children: [
                          _linesCard(context, theme),
                          SizedBox(height: context.dp(16)),
                          _sumCard(context, theme),
                          SizedBox(height: context.dp(16)),
                          DugnadPointsEarn(
                            points: _cart.pointsPerOrder,
                            title: languages.dugnadClubShopPointsTitle,
                            subtitle: languages.dugnadClubShopPointsSub,
                          ),
                          SizedBox(height: context.dp(16)),
                          DugnadCheckoutPaymentSelector(
                            value: _pay,
                            accent: theme.primary,
                            onChanged: (method) =>
                                setState(() => _pay = method),
                          ),
                          SizedBox(height: context.dp(16)),
                          _hint(context, theme),
                        ],
                      ),
              ),
              if (qty > 0)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(context.dp(22)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1414192D),
                        blurRadius: context.dp(36),
                        offset: Offset(0, context.dp(-18)),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(16),
                      context.dp(10),
                      context.dp(16),
                      bottomPad + context.dp(18),
                    ),
                    child: CampaignSwipePayBar(
                      label: languages.campaignSwipeToPay,
                      amountText: shopKr(_cart.totalMember),
                      enabled: !_busy && qty > 0,
                      onConfirmed: _payNow,
                      accent: theme.primary,
                      accentHover: theme.primaryHover,
                      accentDisabled: theme.primaryDisabled,
                      buttonShadow: theme.shadowButton,
                    ),
                  ),
                ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: theme.primaryTint.withValues(alpha: 0.92),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: context.dp(54),
                        height: context.dp(54),
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          color: theme.primaryHover,
                        ),
                      ),
                      SizedBox(height: context.dp(16)),
                      Text(
                        languages.dugnadClubShopProcessing,
                        style: aeH2(color: theme.text)
                            .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )
                            .dp(context),
                      ),
                      SizedBox(height: context.dp(6)),
                      Text(
                        languages.dugnadClubShopProcessingSub,
                        style: aeBody(color: ScSaasThemeTokens.gray500)
                            .copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )
                            .dp(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, DugnadClubThemePalette theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dp(28)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: context.dp(64),
            height: context.dp(64),
            decoration: BoxDecoration(
              color: theme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: context.dp(28),
              color: theme.primaryHover,
            ),
          ),
          SizedBox(height: context.dp(18)),
          Text(
            languages.dugnadClubShopCartEmpty,
            style: aeH2(color: theme.text)
                .copyWith(fontSize: 16, fontWeight: FontWeight.w800)
                .dp(context),
          ),
          SizedBox(height: context.dp(8)),
          Text(
            languages.dugnadClubShopCartEmptyBody,
            textAlign: TextAlign.center,
            style: aeBody(color: ScSaasThemeTokens.gray500)
                .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)
                .dp(context),
          ),
          SizedBox(height: context.dp(20)),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.dp(22),
                vertical: context.dp(14),
              ),
              decoration: BoxDecoration(
                gradient: theme.shinyGradient,
                borderRadius: BorderRadius.circular(context.dp(14)),
              ),
              child: Text(
                languages.dugnadClubShopToShop,
                style: aeBody(color: Colors.white)
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w800)
                    .dp(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linesCard(BuildContext context, DugnadClubThemePalette theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(15),
        context.dp(12),
        context.dp(15),
        context.dp(4),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x592D1B5B),
            blurRadius: 30,
            offset: Offset(0, context.dp(14)),
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                languages.campaignCartTitle,
                style: aeBody(color: theme.text)
                    .copyWith(fontSize: 13, fontWeight: FontWeight.w800)
                    .dp(context),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _cart.clear,
                child: Text(
                  languages.campaignCartClear,
                  style: aeCaption(color: ScSaasThemeTokens.danger)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w700)
                      .dp(context),
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(4)),
          for (var i = 0; i < _cart.lines.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: ScSaasThemeTokens.gray100),
            _line(context, theme, _cart.lines[i]),
          ],
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    DugnadClubThemePalette theme,
    ClubShopCartLine line,
  ) {
    final url = line.product.imageUrls.isEmpty
        ? null
        : ClubCrest.resolveClubMediaUrl(line.product.imageUrls.first);
    final mp = line.product.memberPrice * line.qty;
    final op = line.product.ordinaryPrice * line.qty;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(13)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.dp(14)),
            child: SizedBox(
              width: context.dp(62),
              height: context.dp(62),
              child: ColoredBox(
                color: theme.primaryTint,
                child: url == null
                    ? Icon(
                        Icons.image_outlined,
                        color: theme.primaryHover,
                        size: context.dp(22),
                      )
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (_, __, ___) =>
                            const DugnadClubImageLoader(size: 24),
                      ),
              ),
            ),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: aeBody(color: theme.text)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w800)
                      .dp(context),
                ),
                SizedBox(height: context.dp(3)),
                Text(
                  languages.dugnadClubShopSizeLine(line.size),
                  style: aeCaption(color: ScSaasThemeTokens.gray500)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w700)
                      .dp(context),
                ),
                SizedBox(height: context.dp(5)),
                Row(
                  children: [
                    Text(
                      shopKr(mp),
                      style: aeBody(color: theme.text)
                          .copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          )
                          .dp(context),
                    ),
                    if (mp < op) ...[
                      SizedBox(width: context.dp(7)),
                      Text(
                        shopKr(op),
                        style: aeCaption(color: ScSaasThemeTokens.gray500)
                            .copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.lineThrough,
                            )
                            .dp(context),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          MkQtyStepper(
            qty: line.qty,
            theme: theme,
            small: true,
            onDecrement: () =>
                _cart.setQty(line.product, line.size, line.qty - 1),
            onIncrement: _cart.remainingStock(line.product, line.size) > 0
                ? () => _cart.setQty(line.product, line.size, line.qty + 1)
                : () {},
          ),
          SizedBox(width: context.dp(6)),
          GestureDetector(
            onTap: () => _cart.removeLine(line.product, line.size),
            child: Container(
              width: context.dp(32),
              height: context.dp(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: context.dp(18),
                color: ScSaasThemeTokens.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumCard(BuildContext context, DugnadClubThemePalette theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(16),
        context.dp(15),
        context.dp(16),
        context.dp(15),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x592D1B5B),
            blurRadius: 30,
            offset: Offset(0, context.dp(14)),
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        children: [
          _sumRow(
            context,
            languages.dugnadClubShopOrdinarySum,
            shopKr(_cart.ordinaryTotal),
            color: ScSaasThemeTokens.gray500,
            valueColor: theme.text,
          ),
          _sumRow(
            context,
            languages.dugnadClubShopMemberDiscountLabel,
            '−${shopKr(_cart.discountTotal)}',
            color: ScSaasThemeTokens.success,
            valueColor: ScSaasThemeTokens.success,
            bold: true,
          ),
          Padding(
            padding: EdgeInsets.only(top: context.dp(8)),
            child: const Divider(color: ScSaasThemeTokens.gray100, height: 1),
          ),
          Padding(
            padding: EdgeInsets.only(top: context.dp(12)),
            child: _sumRow(
              context,
              languages.dugnadClubShopToPay,
              shopKr(_cart.totalMember),
              color: theme.text,
              valueColor: theme.text,
              large: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(
    BuildContext context,
    String label,
    String value, {
    required Color color,
    required Color valueColor,
    bool bold = false,
    bool large = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(5)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: aeBody(color: color)
                  .copyWith(
                    fontSize: large ? 17 : 13.5,
                    fontWeight: bold || large ? FontWeight.w800 : FontWeight.w700,
                  )
                  .dp(context),
            ),
          ),
          Text(
            value,
            style: aeBody(color: valueColor)
                .copyWith(
                  fontSize: large ? 17 : 13.5,
                  fontWeight: FontWeight.w800,
                )
                .dp(context),
          ),
        ],
      ),
    );
  }

  Widget _hint(BuildContext context, DugnadClubThemePalette theme) {
    return Container(
      padding: EdgeInsets.all(context.dp(12)),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: context.dp(16),
            color: theme.primaryHover,
          ),
          SizedBox(width: context.dp(8)),
          Expanded(
            child: Text(
              languages.dugnadClubShopCartHint(
                _cart.member.number,
                _cart.partner.name,
                _cart.partner.address,
              ),
              style: aeBody(color: ScSaasThemeTokens.gray600)
                  .copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  )
                  .dp(context),
            ),
          ),
        ],
      ),
    );
  }
}
