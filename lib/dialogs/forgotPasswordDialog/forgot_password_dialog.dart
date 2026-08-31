import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/customCountryCodePicker/custom_country_code_picker.dart';
import '../../commonView/custom_text_field.dart';
import '../../networking/api_base_helper.dart';
import '../../screens/common/auth/auth_style.dart';
import '../../screens/common/login/login_dl.dart';
import '../../ui/kit/ae_sheet.dart';
import '../../ui/kit/ae_confirm_sheet.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'forgot_password_dialog_bloc.dart';

/// `ForgotPasswordSheet` (dugnad/auth-screens.jsx) — a bottom sheet, not a
/// full-screen route: `.dg-msheet` › `.dg-msheet-grab` › `.dg-mem-head`
/// (purple tone, key glyph) › `.ae-field` identifier input ›
/// `.ae-btn--primary` (disabled until the identifier is valid) › `.dga-cancel`.
///
/// The prototype asks for an e-mail; this app's reset endpoint takes a country
/// code + mobile number and answers with a one-time code, so the field and the
/// [ForgotPasswordDialogBloc] wiring are unchanged.
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<StatefulWidget> createState() => _ForgotPasswordDialogState();
}

/// Presents [ForgotPasswordDialog] as the design's bottom sheet.
Future<void> showForgotPasswordSheet(BuildContext context) {
  return showAeSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const ForgotPasswordDialog(),
  );
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  ForgotPasswordDialogBloc? _bloc;

  @override
  void didChangeDependencies() {
    _bloc ??= ForgotPasswordDialogBloc(context, this);
    _bloc!.mobileController.addListener(_onChanged);
    super.didChangeDependencies();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _bloc?.mobileController.removeListener(_onChanged);
    _bloc?.dispose();
    super.dispose();
  }

  /// Prototype gate: `disabled={!/.+@.+\..+/.test(v)}` — here, a plausible
  /// mobile number instead of an e-mail address.
  bool get _isValid => _bloc!.mobileController.text.trim().length >= 5;

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc!;
    return Form(
      key: bloc.formKey,
      child: AeSheetBody(
        children: [
          AeSheetHead(
            icon: Icons.vpn_key_rounded,
            title: languages.forgotPass,
            message:
                'Vi sender en kode for å lage nytt passord.', // TODO(l10n)
          ),
          // .ae-field { margin-top: 6px }
          const SizedBox(height: 6),
          Text(languages.mobileNumber, style: authLabelStyle(context)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 56,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CustomCountryCodePicker(
                  showDropDownButton: true,
                  flagWidth: 22,
                  showFlag: true,
                  showFlagDialog: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  dialogSize: Size(deviceWidth * 0.9, deviceHeight * 0.75),
                  textStyle: authLabelStyle(context),
                  dialogTextStyle: authLabelStyle(context),
                  onChanged: bloc.changeCountryCode,
                  onInit: (countryCode) {
                    bloc.changeCountryCode(countryCode ?? defaultCountryCode);
                  },
                  initialSelection: defaultCountryCode.name,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormFieldCustom(
                  controller: bloc.mobileController,
                  decoration: InputDecoration(
                    hintText: languages.enterMobileNumber,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    hintStyle: const TextStyle(
                      color: ScSaasThemeTokens.gray500,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  useLabelWithBorder: false,
                  backgroundColor: Colors.white,
                  radius: 14,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  setError: true,
                  style: const TextStyle(
                    color: ScSaasThemeTokens.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  validator: (value) =>
                      validateEmptyField(value, languages.enterMobileNumber) ??
                      '',
                ),
              ),
            ],
          ),
          StreamBuilder<ApiResponse<ForgotPassReqPojo>>(
            stream: bloc.subject,
            builder: (context, snapLoading) {
              final isLoading = snapLoading.hasData &&
                  snapLoading.data?.status == Status.loading;
              return AeSheetPrimaryButton(
                topMargin: 18,
                label: 'Send kode', // TODO(l10n)
                icon: Icons.send_rounded,
                isLoading: isLoading,
                onPressed: _isValid
                    ? () {
                        if (bloc.formKey.currentState!.validate()) {
                          aeSheetSaveHaptic();
                          bloc.forgotPass();
                        }
                      }
                    : null,
              );
            },
          ),
          AeSheetCancelButton(
            label: languages.cancel,
            onPressed: () {
              aeSheetCloseHaptic();
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}
