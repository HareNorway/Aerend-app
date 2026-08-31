import 'package:flutter/material.dart';

import '../../screens/common/auth/auth_style.dart';
import '../../ui/kit/ae_sheet.dart';
import '../../ui/kit/ae_confirm_sheet.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'add_tips_dialog_bloc.dart';

/// `TipsSheet` (dugnad/dialogs.jsx) — bottom sheet, not an AlertDialog.
/// `.dg-msheet` › `.dg-msheet-grab` › `.dg-mem-head` (success tone, heart
/// glyph) › `.dgd-tips` amount chips › `.ae-btn--primary` (label flips to
/// "Fortsett uten tips" at 0) › `.dga-cancel`.
///
/// The bloc contract is unchanged: the picked amount is written into
/// `tipController` and pushed through [AddTipsDialogBloc.submit], so
/// `onSubmit(tip)` still receives the amount as a string.
class AddTipsDialog extends StatefulWidget {
  final Function(String tip) onSubmit;

  const AddTipsDialog({super.key, required this.onSubmit});

  @override
  State createState() => _AddTipsDialogState();
}

/// dialogs.jsx `DG_TIPS` — the repo defined no tip presets (the old dialog was
/// a free-amount field), so the design's ladder is used.
const List<int> kTipAmounts = <int>[0, 10, 20, 30, 50];

class _AddTipsDialogState extends State<AddTipsDialog> {
  AddTipsDialogBloc? _bloc;

  /// Prototype default (`React.useState(20)`).
  int _amount = 20;

  @override
  void didChangeDependencies() {
    _bloc ??= AddTipsDialogBloc(context, widget.onSubmit);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  void _submit() {
    _bloc!.tipController.text = _amount.toString();
    aeSheetSaveHaptic();
    _bloc!.submit();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _bloc!.formKey,
      child: AeSheetBody(
        children: [
          const AeSheetHead(
            tone: AeSheetTone.success,
            icon: Icons.favorite_rounded,
            iconSize: 18,
            title: 'Tips til budet', // TODO(l10n)
            message: '100 % går til budet — ikke til Ærend.', // TODO(l10n)
          ),
          // .dgd-tips { gap: 8px; margin-top: 12px }
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                for (var i = 0; i < kTipAmounts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _TipChip(
                      label: kTipAmounts[i] == 0
                          ? 'Ingen' // TODO(l10n)
                          : getAmountWithCurrency(kTipAmounts[i]),
                      selected: _amount == kTipAmounts[i],
                      onTap: () => setState(() => _amount = kTipAmounts[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          AeSheetPrimaryButton(
            topMargin: 18,
            label: _amount > 0
                ? 'Gi ${getAmountWithCurrency(_amount)} i tips' // TODO(l10n)
                : 'Fortsett uten tips', // TODO(l10n)
            icon: Icons.check_rounded,
            onPressed: _submit,
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

/// `.dgd-tips .tp` — equal-width white chip, radius 13, 1.5px hairline,
/// 13.5/800 midnight; `.on` turns the border/label success-green over an 8%
/// green wash.
class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuthPressable(
      onTap: onTap,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              // rgba(31,138,91,.08) against the repo's --ae-success.
              ? ScSaasThemeTokens.success.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            width: 1.5,
            color: selected ? ScSaasThemeTokens.success : kAeSheetHairline,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? ScSaasThemeTokens.success
                        : ScSaasThemeTokens.text,
                  ) ??
              TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: selected
                    ? ScSaasThemeTokens.success
                    : ScSaasThemeTokens.text,
              ),
        ),
      ),
    );
  }
}
