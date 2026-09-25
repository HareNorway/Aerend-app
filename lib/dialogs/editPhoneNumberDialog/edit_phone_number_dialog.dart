import 'package:flutter/material.dart';

import '../../networking/api_base_helper.dart';
import '../../screens/common/auth/auth_style.dart';
import '../../screens/common/otpVerify/otp_verify_dl.dart';
import '../../ui/kit/ae_sheet.dart';
import '../../theme/design_scale.dart';
import '../../theme/bergen_tokens.dart';
import '../../utils/utils.dart';
import 'edit_phone_number_dialog_bloc.dart';

/// Edit Number — navy auth sheet matching OTP / Login phone chrome.
Future<bool?> showEditAuthPhoneSheet(BuildContext context) {
  return showAeSheet<bool>(
    context: context,
    isScrollControlled: true,
    // OTP / login sit on Reen navy; keep the sheet on the same surface so
    // authTitleStyle / authLabelStyle (white) stay readable.
    backgroundColor: AerendBergenAuthTokens.navy,
    builder: (sheetContext) => const _EditAuthPhoneSheet(),
  );
}

/// Legacy dialog entry — redirects to [showEditAuthPhoneSheet].
class EditPhoneNumberDialog extends StatefulWidget {
  const EditPhoneNumberDialog({super.key});

  @override
  State<EditPhoneNumberDialog> createState() => _EditPhoneNumberDialogState();
}

class _EditPhoneNumberDialogState extends State<EditPhoneNumberDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final nav = Navigator.of(context);
      final result = await showEditAuthPhoneSheet(context);
      if (!mounted) return;
      nav.pop(result ?? false);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _EditAuthPhoneSheet extends StatefulWidget {
  const _EditAuthPhoneSheet();

  @override
  State<_EditAuthPhoneSheet> createState() => _EditAuthPhoneSheetState();
}

class _EditAuthPhoneSheetState extends State<_EditAuthPhoneSheet> {
  late final EditPhoneNumberDialogBloc _bloc;
  bool _ready = false;
  late String _dialCode;

  @override
  void didChangeDependencies() {
    if (!_ready) {
      _bloc = EditPhoneNumberDialogBloc(context, this);
      final stored = prefGetString(prefCountryCode).trim();
      _dialCode = stored.isNotEmpty ? stored : '+47';
      _bloc.changeCountryCodeFromDial(_dialCode);
      final existing = prefGetString(prefContactNumber).trim();
      if (existing.isNotEmpty && _bloc.mobileController.text.isEmpty) {
        _bloc.mobileController.text = existing;
      }
      _ready = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (_ready) _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(20),
        context.dp(8),
        context.dp(20),
        context.dp(20) + bottom,
      ),
      child: Form(
        key: _bloc.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: context.dp(36),
                height: context.dp(4),
                margin: EdgeInsets.only(bottom: context.dp(14)),
                decoration: BoxDecoration(
                  color: AerendBergenAuthTokens.glassBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              languages.editNumber,
              style: authTitleStyle(context).copyWith(fontSize: context.dp(20)),
            ),
            SizedBox(height: context.dp(16)),
            AuthPhoneField(
              label: languages.mobileNumber,
              hint: languages.mobileNumber,
              dialCode: _dialCode,
              controller: _bloc.mobileController,
              showCountryPicker: true,
              onDialCodeChanged: (dial) {
                setState(() => _dialCode = dial);
                _bloc.changeCountryCodeFromDial(dial);
              },
              validator: (value) => validateEmptyField(
                value,
                languages.enterMobileNumber,
              ),
            ),
            SizedBox(height: context.dp(20)),
            StreamBuilder<ApiResponse<EditNumberPojo>>(
              stream: _bloc.subject,
              builder: (context, snap) {
                final loading =
                    snap.hasData && snap.data?.status == Status.loading;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: AerendBergenAuthTokens.glassBorder,
                            width: context.dp(1.5),
                          ),
                          minimumSize: Size.fromHeight(context.dp(48)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.dp(14)),
                          ),
                        ),
                        child: Text(
                          languages.cancel,
                          style: authButtonTextStyle(context).copyWith(
                            fontSize: context.dp(15),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.dp(10)),
                    Expanded(
                      child: AuthPrimaryButton(
                        label: languages.change,
                        isLoading: loading,
                        onPressed: loading
                            ? null
                            : () {
                                if (_bloc.formKey.currentState!.validate()) {
                                  _bloc.editNumber();
                                }
                              },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
