import 'package:aerend_customer/ui/kit/ae_subpage_shell.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import '../manageCard/manage_card_dl.dart';
import 'item_select_payment_method.dart';
import 'select_payment_method_bloc.dart';
import 'select_payment_method_dl.dart';
import 'select_payment_method_shimmer.dart';

/// «Velg betalingsmåte» — mirrors design `checkout-screens.jsx`
/// `SelectPaymentScreen` (`.tk-head` + `.dgsp-row` list + `.co-foot`).
class SelectPaymentMethod extends StatefulWidget {
  final double totalPay;
  final String payTo;
  final int id;
  final bool showCash, showWallet;

  const SelectPaymentMethod({
    super.key,
    required this.totalPay,
    required this.payTo,
    this.id = 0,
    this.showCash = showCashPayment,
    this.showWallet = showWalletPayment,
  });

  @override
  SelectPaymentMethodState createState() => SelectPaymentMethodState();
}

class SelectPaymentMethodState extends State<SelectPaymentMethod> {
  SelectPaymentMethodBloc? _bloc;

  @override
  void didChangeDependencies() {
    _bloc = SelectPaymentMethodBloc(context, widget.id, widget.payTo, widget.totalPay, widget.showCash, widget.showWallet, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ScSaasThemeTokens.background,
        body: AeFixedTypography(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildSelectPaymentMethod()),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildFooter(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// `.tk-head` (paddingBottom 6) — shiny back circle, centred h1, 38px spacer.
  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
        child: Row(
          children: [
            AeBackButton(onPressed: () => Navigator.maybePop(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Betal — ${getAmountWithCurrency(widget.totalPay)}", // TODO(l10n)
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 20 * -0.015,
                  color: ScSaasThemeTokens.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 38),
          ],
        ),
      );

  /// `.ae-body` — padding `0 18px 120px`.
  Widget _buildSelectPaymentMethod() => StreamBuilder<ApiResponse<CardModel>>(
      stream: _bloc!.subject,
      builder: (context, snapshot) {
        return StreamBuilder<List<SelectPaymentMethodModel>>(
            stream: _bloc!.selectPaymentMethodList,
            builder: (context, snap) {
              var isLoading = snapshot.hasData && snapshot.data?.status == Status.loading;
              SelectPaymentMethodShimmer shimmerView = SelectPaymentMethodShimmer(
                enabled: isLoading,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                child: isLoading
                    ? shimmerView
                    : ItemSelectPaymentMethod(
                        labels: snap.data ?? [],
                        picked: widget.showCash ? paymentTypeCash : 1,
                        onSelected: (selected, selectPaymentMethodItem) {
                          _bloc!.changeSelectedPaymentMethod(selectPaymentMethodItem);
                        },
                      ),
              );
            });
      });

  /// `.co-foot` — sticky footer, lavender fade-up gradient.
  Widget _buildFooter(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.paddingOf(context).bottom + 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              ScSaasThemeTokens.background,
              ScSaasThemeTokens.background,
              Color(0x00F4F0FB),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: selectButton(),
      );

  Widget selectButton() => StreamBuilder<ApiResponse<PaymentBaseModel>>(
      stream: _bloc!.subjectPay,
      builder: (context, snapPayRide) {
        var isLoading = snapPayRide.hasData && snapPayRide.data?.status == Status.loading;
        return StreamBuilder<SelectPaymentMethodItem>(
            stream: _bloc!.selectedPaymentMethod,
            builder: (context, snap) {
              return snap.hasData
                  ? _CoFootPrimaryButton(
                      label: "Fortsett til betaling", // TODO(l10n)
                      icon: Icons.check_rounded,
                      isLoading: isLoading,
                      onTap: isLoading
                          ? null
                          : () {
                              _bloc!.payNow();
                            },
                    )
                  : const SizedBox.shrink();
            });
      });
}

/// `.ae-btn.ae-btn--primary` — 56px, radius 14, flat purple-600,
/// pressed purple-700 + translateY(1px), icon + label gap 10.
class _CoFootPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _CoFootPrimaryButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_CoFootPrimaryButton> createState() => _CoFootPrimaryButtonState();
}

class _CoFootPrimaryButtonState extends State<_CoFootPrimaryButton> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.ease,
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: !enabled && !widget.isLoading
              ? ScSaasThemeTokens.primaryDisabled
              : _pressed
                  ? ScSaasThemeTokens.primaryHover
                  : ScSaasThemeTokens.primary,
          boxShadow: enabled || widget.isLoading ? ScSaasThemeTokens.shadowButton : null,
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 17, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 16 * -0.01,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
