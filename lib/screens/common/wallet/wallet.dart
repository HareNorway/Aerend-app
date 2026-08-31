import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../auth/auth_style.dart';
import '../selectPaymentMethod/select_payment_method_dl.dart';
import 'wallet_bloc.dart';
import 'wallet_dl.dart';

// `.dgw-txns .ic.in` / `.amt.in` colours (dugnad.css).
const Color _txnInBg = Color(0xFFEAFAF0);
const Color _txnInColor = Color(0xFF1F8A5B);

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State createState() => _WalletState();
}

class _WalletState extends State<Wallet> with WidgetsBindingObserver {
  late WalletBloc _bloc;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _bloc = WalletBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _bloc.getWalletAmount();
      _bloc.getTransactionList();
    }
  }

  @override
  void dispose() {
    _bloc.dispose();
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: ScSaasThemeTokens.background,
        resizeToAvoidBottomInset: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AeRiseIn(
                      delay: const Duration(milliseconds: 120),
                      child: _balanceCard(),
                    ),
                    // `.ae-body { gap: 16 }`
                    const SizedBox(height: 16),
                    AeRiseIn(
                      delay: const Duration(milliseconds: 190),
                      child: _transactionsSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.tk-head` — back, centred h1, 38px spacer.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 8,
        22,
        14,
      ),
      child: Row(
        children: [
          AeBackButton(onPressed: () => Navigator.maybePop(context)),
          Expanded(
            child: Text(
              languages.wallet,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // .tk-head h1: 20/800/-0.015em midnight
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 20 * -0.015,
                color: ScSaasThemeTokens.text,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  /// `.dgw-card` — purple gradient balance hero.
  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // --ae-shiny-purple: linear-gradient(150deg, #a98fe0, #7f5fc4 55%, #6b4fa8)
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [Color(0xFFA98FE0), Color(0xFF7F5FC4), Color(0xFF6B4FA8)],
          stops: [0.0, 0.55, 1.0],
        ),
        // box-shadow: 0 14px 32px -14px rgba(127,95,196,.7)
        boxShadow: const [
          BoxShadow(
            color: Color(0xB37F5FC4),
            blurRadius: 32,
            offset: Offset(0, 14),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // .dgw-card .k: 11.5/800, ls .07em, uppercase, opacity .8
          Text(
            'ÆREND-SALDO', // TODO(l10n)
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 11.5 * 0.07,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          // .dgw-card .v: padding 4px 0 2px
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: _balanceValue(),
          ),
          // .dgw-card .acts: gap 9, margin-top 14
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  child: _heroActionButton(
                    icon: Icons.add_rounded,
                    iconSize: 15,
                    label: 'Fyll på', // TODO(l10n)
                    loadingStream: _bloc.subjectAddAmount,
                    onTap: _openTopUpSheet,
                  ),
                ),
                if (showWalletTransferModule) ...[
                  const SizedBox(width: 9),
                  Expanded(
                    child: _heroActionButton(
                      icon: Icons.send_rounded,
                      iconSize: 14,
                      label: 'Overfør', // TODO(l10n)
                      onTap: () => _bloc.openWalletTransfer(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `.dgw-card .v` — 38/800/-0.03em with 19/700 "kr" span.
  Widget _balanceValue() => StreamBuilder<double>(
        stream: _bloc.walletAmount,
        builder: (context, snap) {
          return StreamBuilder<ApiResponse<WalletBalancePojo>>(
            stream: _bloc.subjectGetBalance,
            builder: (context, snapLoading) {
              var isLoading = snapLoading.hasData &&
                  snapLoading.data?.status == Status.loading;
              if (isLoading && snap.data == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CommonCircularProgressIndicator(
                      strokeWidth: 2.5,
                      size: 24,
                      color: ScSaasThemeTokens.card,
                    ),
                  ),
                );
              }
              final formatted = getAmountWithCurrency(snap.data ?? 0);
              final splitAt = formatted.lastIndexOf(' ');
              final number =
                  splitAt > 0 ? formatted.substring(0, splitAt) : formatted;
              final currency =
                  splitAt > 0 ? formatted.substring(splitAt + 1) : '';
              return Text.rich(
                TextSpan(
                  text: number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 38 * -0.03,
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(
                      text: ' $currency',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

  /// `.dgw-card .acts button` — frosted white pill, 13.5/800.
  Widget _heroActionButton({
    required IconData icon,
    required double iconSize,
    required String label,
    required VoidCallback onTap,
    Stream<ApiResponse<PaymentBaseModel>>? loadingStream,
  }) {
    Widget content(bool isLoading) => AuthPressable(
          onTap: isLoading ? null : onTap,
          builder: (context, pressed) => Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: Colors.white.withValues(alpha: pressed ? 0.28 : 0.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(icon, size: iconSize, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

    if (loadingStream == null) return content(false);
    return StreamBuilder<ApiResponse<PaymentBaseModel>>(
      stream: loadingStream,
      builder: (context, snap) => content(
        snap.hasData && snap.data?.status == Status.loading,
      ),
    );
  }

  /// `.dg-label` "Bevegelser" + `.dgw-txns` card.
  Widget _transactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .dg-label with margin 2px 2px 8px override
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
          child: Text(
            'BEVEGELSER', // TODO(l10n)
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 11 * 0.08,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          child: StreamBuilder<ApiResponse<WalletTransactionPojo>>(
            stream: _bloc.subjectTransactions,
            builder: (context, snap) {
              var isLoading =
                  snap.hasData && snap.data?.status == Status.loading;
              var isError = snap.hasData && snap.data?.status == Status.error;
              final transactions = snap.data?.data?.transactions ?? [];

              if (isLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: CommonCircularProgressIndicator(
                      strokeWidth: 2.5,
                      size: 24,
                      color: ScSaasThemeTokens.primary,
                    ),
                  ),
                );
              }
              if (isError || transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 26,
                    horizontal: 8,
                  ),
                  child: Center(
                    child: Text(
                      isError
                          ? (snap.data?.message ?? '')
                          : 'Ingen bevegelser ennå', // TODO(l10n)
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < transactions.length; i++)
                    _transactionRow(
                      transactions[i],
                      withSeparator: i > 0,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// `.dgw-txns .tx` row.
  Widget _transactionRow(TransactionsItem item, {required bool withSeparator}) {
    final isIn = item.transactionType == 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: withSeparator
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(color: ScSaasThemeTokens.background),
              ),
            )
          : null,
      child: Row(
        children: [
          // .dgw-txns .ic: 34px, radius 11, tinted by direction
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: isIn ? _txnInBg : ScSaasThemeTokens.background,
            ),
            alignment: Alignment.center,
            child: Icon(
              isIn
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.arrow_outward_rounded,
              size: 16,
              color: isIn ? _txnInColor : ScSaasThemeTokens.primaryHover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // .dgw-txns .bd .t: 14/800 midnight
                Text(
                  item.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                // .dgw-txns .bd .s: 12/600 gray-500, padding-top 2
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    getDateTime(item.dateTime, returnFormat: 'dd.MM.yyyy HH:mm'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // .dgw-txns .amt: 14.5/800 tabular, green in / midnight out
          Text(
            '${isIn ? '+' : '−'}'
            '${getAmountWithCurrency(getDoubleFromDynamic(item.amount))}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isIn ? _txnInColor : ScSaasThemeTokens.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// "Fyll på" bottom sheet — amount entry, then the existing payment flow.
  void _openTopUpSheet() {
    _bloc.addAmountTEC.clear();
    _bloc.setError = true;
    showAeSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            MediaQuery.viewInsetsOf(sheetContext).bottom +
                MediaQuery.paddingOf(sheetContext).bottom +
                18,
          ),
          child: Form(
            key: _bloc.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AeSheetHandle(),
                // `.dg-mem-head`: gradient icon chip + h2 + p
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment(-0.5, -0.85),
                          end: Alignment(0.5, 0.85),
                          colors: [
                            Color(0xFFA98FE0),
                            Color(0xFF7F5FC4),
                            Color(0xFF6B4FA8),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fyll på', // TODO(l10n)
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 18 * -0.02,
                              color: ScSaasThemeTokens.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            languages.addMoneyToWallet,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: ScSaasThemeTokens.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AuthField(
                  label: languages.enterAmount,
                  hint: '200',
                  controller: _bloc.addAmountTEC,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (_bloc.setError) {
                      final empty = validateEmptyField(
                        value,
                        languages.pleaseEnterAmount,
                      );
                      if (empty.isNotEmpty) return empty;
                      final amount = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );
                      if (amount == null || amount <= 0) {
                        return languages.invalidAmountMsg;
                      }
                    }
                    return '';
                  },
                ),
                const SizedBox(height: 16),
                AuthPrimaryButton(
                  label: 'Fyll på', // TODO(l10n)
                  onPressed: () {
                    // Normalize decimal commas before the bloc parses it.
                    final normalized = _bloc.addAmountTEC.text
                        .trim()
                        .replaceAll(',', '.');
                    if (normalized != _bloc.addAmountTEC.text) {
                      _bloc.addAmountTEC.text = normalized;
                    }
                    if (_bloc.formKey.currentState!.validate()) {
                      Navigator.pop(sheetContext);
                      _bloc.openSelectPaymentScreen();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
