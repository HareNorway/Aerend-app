import 'package:flutter/material.dart';

import '../../networking/api_base_helper.dart';
import '../../screens/common/auth/auth_style.dart';
import '../../screens/common/login/login_dl.dart';
import '../../screens/dugnad/dugnad_sheet.dart';
import '../../screens/dugnad/widgets/dugnad_confirm_sheet.dart';
import '../../utils/utils.dart';
import 'change_password_dialog_bloc.dart';

/// `ChangePasswordSheet` (dugnad/auth-screens.jsx) — a bottom sheet, not a
/// full-screen route: `.dg-msheet` › `.dg-msheet-grab` › `.dg-mem-head`
/// (purple tone, lock glyph) › three stacked `.ae-field`s › `.dgo-err`
/// "Passordene er ikke like" while they differ › `.ae-btn--primary`
/// "Lagre passord" (disabled until valid) › `.dga-cancel`.
///
/// This is the *reset* step of the forgot-password flow, so the first field is
/// the one-time code rather than the current password — the endpoint
/// (`forgotChangePassApi(userId, otp, password)`) and the
/// [ChangePasswordDialogBloc] wiring are unchanged. The logged-in
/// `ChangePassword` screen (`screens/common/changePassword/`) is separate and
/// untouched.
class ChangePasswordDialog extends StatefulWidget {
  final int userId;

  const ChangePasswordDialog({super.key, this.userId = 0});

  @override
  State createState() => _ChangePasswordDialogState();
}

/// Presents [ChangePasswordDialog] as the design's bottom sheet.
Future<void> showChangePasswordSheet(
  BuildContext context, {
  required int userId,
}) {
  return showDugnadSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ChangePasswordDialog(userId: userId),
  );
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  ChangePasswordDialogBloc? _bloc;

  @override
  void didChangeDependencies() {
    if (_bloc == null) {
      _bloc = ChangePasswordDialogBloc(context, this);
      _bloc!.otpController.addListener(_onChanged);
      _bloc!.passController.addListener(_onChanged);
      _bloc!.rePassController.addListener(_onChanged);
    }
    super.didChangeDependencies();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _bloc?.otpController.removeListener(_onChanged);
    _bloc?.passController.removeListener(_onChanged);
    _bloc?.rePassController.removeListener(_onChanged);
    _bloc?.dispose();
    super.dispose();
  }

  String get _otp => _bloc!.otpController.text.trim();

  String get _pass => _bloc!.passController.text;

  String get _rePass => _bloc!.rePassController.text;

  /// `mismatch = f.cf.length > 0 && f.nw !== f.cf`
  bool get _mismatch => _rePass.isNotEmpty && _pass != _rePass;

  /// `valid = f.old.length >= 6 && f.nw.length >= 6 && f.nw === f.cf`
  /// (the OTP takes the place of the current password here — 4 digits).
  bool get _isValid =>
      _otp.length == 4 && _pass.length >= 6 && _pass == _rePass;

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc!;
    return Form(
      key: bloc.formKey,
      child: DugnadSheetBody(
        children: [
          DugnadSheetHead(
            icon: Icons.lock_rounded,
            title: languages.setNewPassword,
            message: 'Minst 6 tegn.', // TODO(l10n)
          ),
          // .ae-field { margin-top: 6px }
          const SizedBox(height: 6),
          AuthField(
            label: languages.enterOtp,
            hint: languages.enterOtp,
            controller: bloc.otpController,
            keyboardType: TextInputType.number,
            validator: (value) =>
                validateWithFixLength(
                  value,
                  4,
                  languages.enterOtp,
                  languages.enterCompOtp,
                ) ??
                '',
          ),
          // .ae-field { margin-top: 12px }
          const SizedBox(height: 12),
          AuthField(
            label: languages.password,
            hint: languages.password,
            controller: bloc.passController,
            password: true,
            validator: (value) => passwordValidate(value) ?? '',
          ),
          const SizedBox(height: 12),
          AuthField(
            label: languages.confirmPassword,
            hint: languages.confirmPassword,
            controller: bloc.rePassController,
            password: true,
            textInputAction: TextInputAction.done,
            validator: (value) =>
                confirmPasswordValidate(value, bloc.passController.text) ?? '',
          ),
          if (_mismatch)
            const DugnadSheetErrorNote(
              message: 'Passordene er ikke like', // TODO(l10n)
            ),
          StreamBuilder<ApiResponse<LoginPojo>>(
            stream: bloc.subject,
            builder: (context, snapLoading) {
              final isLoading = snapLoading.hasData &&
                  snapLoading.data!.status == Status.loading;
              return DugnadSheetPrimaryButton(
                topMargin: 18,
                label: 'Lagre passord', // TODO(l10n)
                icon: Icons.check_rounded,
                isLoading: isLoading,
                onPressed: _isValid
                    ? () {
                        if (bloc.formKey.currentState!.validate()) {
                          dugnadSheetSaveHaptic();
                          bloc.submit(widget.userId);
                        }
                      }
                    : null,
              );
            },
          ),
          DugnadSheetCancelButton(
            label: languages.cancel,
            onPressed: () {
              dugnadSheetCloseHaptic();
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}
