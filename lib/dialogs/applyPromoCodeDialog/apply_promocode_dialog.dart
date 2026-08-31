import 'package:flutter/material.dart';

import '../../screens/common/auth/auth_style.dart';
import '../../screens/deliveryService/checkout/checkout_dl.dart';
import '../../screens/dugnad/dugnad_sheet.dart';
import '../../screens/dugnad/widgets/dugnad_confirm_sheet.dart';
import '../../utils/utils.dart';
import 'item_promo_code_list.dart';

/// `PromoCodeSheet` (dugnad/dialogs.jsx) — bottom sheet, not an AlertDialog.
/// `.dg-msheet` › `.dg-msheet-grab` › `.dg-mem-head` (purple tone, tag glyph) ›
/// `.ae-field` uppercase code input › `.dgd-promos` suggestion rows (omitted
/// when there are none) › `.ae-btn--primary` "Bruk koden" (disabled < 3 chars)
/// › `.dga-cancel`.
///
/// Constructor and callbacks are unchanged — [onPromoCodeApply] still receives
/// the code and the sheet pops itself afterwards, exactly like before.
class ApplyPromoCodeDialog extends StatefulWidget {
  final List<PromoCodeListItem>? promoCodeList;
  final void Function(int promoId)? onPromoCodeSelected;
  final void Function(String promoCode)? onPromoCodeApply;
  final bool isLoading;

  const ApplyPromoCodeDialog({
    super.key,
    required this.promoCodeList,
    this.onPromoCodeSelected,
    this.onPromoCodeApply,
    this.isLoading = false,
  });

  @override
  State<ApplyPromoCodeDialog> createState() => _ApplyPromoCodeDialogState();
}

class _ApplyPromoCodeDialogState extends State<ApplyPromoCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  /// Prototype: `onChange={(e) => setV(e.target.value.toUpperCase())}`.
  /// [AuthField] does not expose `inputFormatters`, so the controller does it.
  void _onCodeChanged() {
    final upper = _codeController.text.toUpperCase();
    if (upper != _codeController.text) {
      final selection = _codeController.selection;
      _codeController.value = _codeController.value.copyWith(
        text: upper,
        selection: selection,
        composing: TextRange.empty,
      );
      return; // the assignment re-enters this listener.
    }
    setState(() {});
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  String get _code => _codeController.text.trim();

  void _apply() {
    if (widget.onPromoCodeApply == null) return;
    dugnadSheetSaveHaptic();
    widget.onPromoCodeApply!(_code);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final promos = widget.promoCodeList ?? const <PromoCodeListItem>[];
    return Form(
      key: formKey,
      child: DugnadSheetBody(
        children: [
          DugnadSheetHead(
            icon: Icons.local_offer_rounded,
            title: languages.promoCode,
            message:
                'Legg inn koden din, eller velg et tilbud.', // TODO(l10n)
          ),
          // .ae-field { margin-top: 6px }
          const SizedBox(height: 6),
          AuthField(
            label: 'Kode', // TODO(l10n)
            hint: 'DUGNAD20',
            controller: _codeController,
            textInputAction: TextInputAction.done,
            validator: (value) =>
                value.trim().length >= 3 ? '' : languages.enterPromoCode,
            onValidate: () {},
          ),
          if (promos.isNotEmpty) ...[
            // .dgd-promos { gap: 8px; margin-top: 14px }
            const SizedBox(height: 14),
            for (var i = 0; i < promos.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              ItemPromoCodeList(
                promocodeListItem: promos[i],
                // Prototype: tapping a suggestion fills the code field.
                onClickApplyPromo: () {
                  widget.onPromoCodeSelected?.call(promos[i].promocodeId);
                  _codeController.text = promos[i].promocodeName.toUpperCase();
                  _codeController.selection = TextSelection.collapsed(
                    offset: _codeController.text.length,
                  );
                },
              ),
            ],
          ],
          DugnadSheetPrimaryButton(
            label: 'Bruk koden', // TODO(l10n)
            icon: Icons.check_rounded,
            isLoading: widget.isLoading,
            onPressed: _code.length < 3 ? null : _apply,
          ),
          DugnadSheetCancelButton(label: languages.cancel),
        ],
      ),
    );
  }
}
