import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../networking/api_response.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../auth/auth_style.dart';
import '../base_dl.dart';
import 'wallet_transfer_bloc.dart';
import 'wallet_transfer_dl.dart';

class WalletTransfer extends StatefulWidget {
  final double walletAmount;

  const WalletTransfer({super.key, this.walletAmount = 0});

  @override
  State<WalletTransfer> createState() => _WalletTransferState();
}

class _WalletTransferState extends State<WalletTransfer> {
  late WalletTransferBloc _bloc;
  Timer? _searchDebounce;
  String _lastQuery = '';

  @override
  void initState() {
    _bloc = WalletTransferBloc(context, widget.walletAmount, this);
    _bloc.textEditingController.addListener(_onQueryChanged);
    _bloc.textAmountController.addListener(_onAmountChanged);
    super.initState();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _bloc.textEditingController.removeListener(_onQueryChanged);
    _bloc.textAmountController.removeListener(_onAmountChanged);
    _bloc.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _bloc.textEditingController.text.trim();
    if (query == _lastQuery) return;
    _lastQuery = query;
    // Editing the search text clears the current pick.
    if (_bloc.transferUserList != null) {
      setState(() => _bloc.transferUserList = null);
    }
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      _bloc.searchUser.add(null);
      setState(() {});
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _bloc.searchUsers(query);
    });
  }

  void _onAmountChanged() {
    // AuthField has no inputFormatters — sanitize so the bloc's
    // double parsing never sees commas or other junk.
    final text = _bloc.textAmountController.text;
    final sanitized =
        text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    if (sanitized != text) {
      _bloc.textAmountController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
      return; // listener fires again with the clean value
    }
    setState(() {});
  }

  void _pickUser(TransferUserList user) {
    FocusManager.instance.primaryFocus?.unfocus();
    _bloc.transferUserList = user;
    _bloc.textBeneficialController.text = user.name;
    _bloc.textNumberController.text =
        '${user.countryCode} ${user.contactNumber}'.trim();
    _bloc.textEmailController.text = user.email;
    _lastQuery = user.name.trim();
    _bloc.textEditingController.text = user.name;
    setState(() {});
  }

  double get _amount =>
      double.tryParse(_bloc.textAmountController.text.trim()) ?? 0;

  bool get _amountValid => _amount > 0 && _amount <= _bloc.walletAmount;

  @override
  Widget build(BuildContext context) {
    return AeFixedTypography(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pop(context, false);
        },
        child: Scaffold(
          backgroundColor: ScSaasThemeTokens.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AeRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: AuthField(
                          label: 'Til hvem', // TODO(l10n)
                          hint: 'Navn, mobil eller e-post', // TODO(l10n)
                          controller: _bloc.textEditingController,
                          textInputAction: TextInputAction.search,
                          validator: (value) => '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_bloc.transferUserList == null)
                        AeRiseIn(
                          delay: const Duration(milliseconds: 190),
                          child: _suggestions(),
                        )
                      else
                        ..._pickedSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          AeBackButton(
            onPressed: () => Navigator.pop(context, false),
          ),
          Expanded(
            child: Text(
              'Overfør saldo', // TODO(l10n)
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
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  /// `.dgw-people` — white suggestion card with person rows.
  Widget _suggestions() {
    return StreamBuilder<ApiResponse<UserSearchModel>?>(
      stream: _bloc.searchUser,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        switch (snapshot.data?.status) {
          case Status.loading:
            return _peopleCard([
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CommonCircularProgressIndicator(
                    strokeWidth: 2.5,
                    size: 24,
                    color: ScSaasThemeTokens.primary,
                  ),
                ),
              ),
            ]);
          case Status.completed:
            final users = snapshot.data?.data?.transferUserList ?? [];
            if (users.isEmpty) return _peopleMessage(languages.noRecordFound);
            return _peopleCard([
              for (var i = 0; i < users.length; i++)
                _personRow(users[i], withSeparator: i > 0),
            ]);
          case Status.error:
            return _peopleMessage(snapshot.data?.message ?? '');
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _peopleCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _peopleMessage(String message) {
    return _peopleCard([
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
        ),
      ),
    ]);
  }

  /// `.dgw-people .pr` — avatar, name/sub, chevron.
  Widget _personRow(TransferUserList user, {required bool withSeparator}) {
    final contactNumber =
        '${user.countryCode} ${user.contactNumber}'.trim();
    final sub = contactNumber.isNotEmpty ? contactNumber : user.email;
    return AuthPressable(
      onTap: () => _pickUser(user),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: withSeparator
            ? const BoxDecoration(
                border: Border(
                  top: BorderSide(color: ScSaasThemeTokens.background),
                ),
              )
            : null,
        child: Row(
          children: [
            // .dgw-people .av: 36px circle, lavender, purple-700 icon
            user.profileImage.isNotEmpty
                ? ClipOval(
                    child: LoadImageWithPlaceHolder(
                      width: 36,
                      height: 36,
                      image: user.profileImage,
                      borderRadius: BorderRadius.circular(18),
                      defaultAssetImage: 'assets/images/avatar_user.png',
                    ),
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ScSaasThemeTokens.background,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 17,
                      color: ScSaasThemeTokens.primaryHover,
                    ),
                  ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // .dgw-people .nm: 14.5/800 midnight
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: ScSaasThemeTokens.text,
                    ),
                  ),
                  // .dgw-people .s: 12/600 gray-500
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // .dgw-people .go: gray-400 chevron
            const Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: Color(0xFFA9A4BB),
            ),
          ],
        ),
      ),
    );
  }

  /// Picked state: `.dga-cur` + amount field + send + `.dg-info`.
  List<Widget> _pickedSection() {
    final user = _bloc.transferUserList!;
    return [
      // .dga-cur: lavender row, uppercase key + value
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              'MOTTAKER', // TODO(l10n)
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 11.5 * 0.06,
                color: ScSaasThemeTokens.gray500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.name,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: ScSaasThemeTokens.text,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AuthField(
        label: 'Beløp', // TODO(l10n)
        hint: '200',
        controller: _bloc.textAmountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        validator: (value) => '',
      ),
      const SizedBox(height: 16),
      StreamBuilder<ApiResponse<BaseModel>>(
        stream: _bloc.transferToWallet,
        builder: (context, snapLoading) {
          final isLoading = snapLoading.hasData &&
              snapLoading.data?.status == Status.loading;
          final amount = _amount;
          final label = amount > 0
              ? 'Send ${getAmountWithCurrency(amount)}' // TODO(l10n)
              : 'Send'; // TODO(l10n)
          return AuthPrimaryButton(
            label: label,
            isLoading: isLoading,
            onPressed: _amountValid ? () => _bloc.transferToUser() : null,
          );
        },
      ),
      const SizedBox(height: 16),
      // .dg-info: purple-100, wallet icon, "Tilgjengelig saldo"
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.primaryTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 17,
                color: ScSaasThemeTokens.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Tilgjengelig saldo: ', // TODO(l10n)
                  children: [
                    TextSpan(
                      text: getAmountWithCurrency(_bloc.walletAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: ScSaasThemeTokens.primaryHover,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
