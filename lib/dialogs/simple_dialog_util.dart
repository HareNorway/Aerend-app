import 'package:flutter/material.dart';

import '../commonView/modal_ui.dart';
import '../ui/kit/ae_sheet.dart';
import '../ui/kit/ae_confirm_sheet.dart';
import '../utils/utils.dart';

/// `LogoutSheet` (dugnad/dialogs.jsx) — the logout confirmation is a bottom
/// sheet in the approved design, not an AlertDialog: danger-tone `.dg-mem-head`
/// with the logout glyph, a red `.dgd-confirm` and a `.dga-cancel` "stay".
///
/// Embeddable so callers that already wrap the confirmation in a
/// `StreamBuilder` (loading state on the logout API) can keep that wiring:
/// pass [onConfirm] + [isLoading] and pop yourself. Callers that just need a
/// yes/no answer should use [showLogoutSheet].
class LogoutSheet extends StatelessWidget {
  const LogoutSheet({super.key, this.onConfirm, this.isLoading = false});

  final VoidCallback? onConfirm;
  final bool isLoading;

  /// dialogs.jsx `LogoutSheet` copy.
  static const String title = 'Vil du logge ut?'; // TODO(l10n)
  static const String message =
      'Du må logge inn igjen for å bestille og samle poeng.'; // TODO(l10n)
  static const String stayLabel = 'Bli værende'; // TODO(l10n)

  @override
  Widget build(BuildContext context) {
    return AeConfirmSheet(
      tone: AeSheetTone.danger,
      icon: Icons.logout_rounded,
      title: title,
      message: message,
      confirmLabel: languages.logout,
      cancelLabel: stayLabel,
      isLoading: isLoading,
      onConfirm: onConfirm,
    );
  }
}

/// Presents [LogoutSheet]; resolves to `true` when "Logg ut" is tapped and
/// `null` when the sheet is dismissed.
Future<bool?> showLogoutSheet(BuildContext context) {
  return showAeSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const LogoutSheet(),
  );
}

class SimpleDialogUtil extends StatelessWidget {
  final String title, message, positiveButtonTxt, negativeButtonTxt;
  final Function? onPositivePress, onNegativePress;
  final bool isLoading;

  const SimpleDialogUtil({
    super.key,
    required this.title,
    required this.positiveButtonTxt,
    required this.onPositivePress,
    this.message = "",
    this.negativeButtonTxt = "",
    this.onNegativePress,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) => Dialog(
          insetPadding: dialogPending,
          shape: RoundedRectangleBorder(borderRadius: dialogBorderRadius),
          child: Container(
            width: double.infinity,
            padding: EdgeInsetsDirectional.only(
              top: deviceHeight * 0.018,
              start: deviceWidth * 0.03,
              end: deviceWidth * 0.03,
              bottom: deviceHeight * 0.01,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalUi.handle(),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: bodyText(
                    fontSize: textSizeMediumBig,
                    textColor: colorTextCommon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message.trim().isNotEmpty)
                  Container(
                    margin: EdgeInsetsDirectional.only(
                      top: deviceHeight * 0.008,
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.start,
                      style: bodyText(),
                    ),
                  ),
                const SizedBox(height: 16),
                ModalUi.actionRow(
                  context,
                  primaryLabel: positiveButtonTxt,
                  secondaryLabel: negativeButtonTxt.trim().isNotEmpty
                      ? negativeButtonTxt
                      : 'Cancel',
                  onPrimaryPressed: () {
                    onPositivePress!();
                  },
                  onSecondaryPressed: negativeButtonTxt.trim().isNotEmpty
                      ? () {
                          onNegativePress?.call();
                        }
                      : () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
