import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../networking/api_base_helper.dart';
import '../../screens/common/auth/auth_style.dart';
import '../../screens/common/base_dl.dart';
import '../../screens/dugnad/dugnad_sheet.dart';
import '../../screens/dugnad/widgets/dugnad_confirm_sheet.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'order_cancel_dialog_bloc.dart';

/// `OrderCancelSheet` (dugnad/dialogs.jsx) — the cancel-order confirmation is a
/// bottom sheet in the approved design, not an AlertDialog. Structure:
/// `.dg-msheet` › `.dg-msheet-grab` › `.dg-mem-head` (danger tone, ✕ glyph) ›
/// `.dgd-reasons` radio list › optional `.ae-field` for "Annet" ›
/// `.dgd-confirm.danger` › `.dga-cancel`.
///
/// The class name, constructor and result contract are unchanged: cancelling
/// pops with `true`, confirming forwards `onSubmit(true, reason)` exactly like
/// before (via [OrderCancelDialogBloc.submit], which reads `reasonController`).
class OrderCancelDialog extends StatefulWidget {
  final String? message, title;
  final Function(bool, String) onSubmit;
  final BehaviorSubject<ApiResponse<BaseModel>> subjectCancel;

  const OrderCancelDialog({
    super.key,
    required this.onSubmit,
    required this.subjectCancel,
    this.message,
    this.title,
  });

  @override
  OrderCancelDialogState createState() => OrderCancelDialogState();
}

/// dialogs.jsx `DG_CANCEL_REASONS` — the repo has no cancel-reason API/enum
/// (the old dialog was a single free-text field), so the design's five
/// Norwegian reasons are used.
const List<String> kOrderCancelReasons = <String>[
  'Bestilte ved et uhell', // TODO(l10n)
  'Endret mening', // TODO(l10n)
  'For lang leveringstid', // TODO(l10n)
  'Feil adresse', // TODO(l10n)
  'Annet', // TODO(l10n)
];

const String _kOtherReason = 'Annet'; // TODO(l10n)

class OrderCancelDialogState extends State<OrderCancelDialog> {
  OrderCancelDialogBloc? _bloc;

  /// Free text shown only when "Annet" is picked; copied into the bloc's
  /// `reasonController` on submit so the bloc/API contract is untouched.
  final TextEditingController _otherController = TextEditingController();

  String _reason = '';

  @override
  void initState() {
    super.initState();
    // Enables/disables the red confirm live while typing the "Annet" reason.
    _otherController.addListener(_onOtherChanged);
  }

  void _onOtherChanged() => setState(() {});

  @override
  void didChangeDependencies() {
    _bloc ??= OrderCancelDialogBloc(context, widget.onSubmit);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _otherController.removeListener(_onOtherChanged);
    _otherController.dispose();
    _bloc?.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _reason.isNotEmpty &&
      (_reason != _kOtherReason || _otherController.text.trim().length > 2);

  void _submit() {
    final reason = _reason == _kOtherReason
        ? _otherController.text.trim()
        : _reason;
    _bloc!.reasonController.text = reason;
    dugnadSheetSaveHaptic();
    _bloc!.submit();
  }

  @override
  Widget build(BuildContext context) {
    final message = (widget.message ?? '').trim();
    return Form(
      key: _bloc!.formKey,
      child: DugnadSheetBody(
        children: [
          DugnadSheetHead(
            tone: DugnadSheetTone.danger,
            icon: Icons.close_rounded,
            title: widget.title ?? languages.cancelReason,
            message: message.isNotEmpty
                ? message
                : 'Fortell oss hvorfor.', // TODO(l10n)
          ),
          // .dgd-reasons { gap: 8px; margin-top: 10px }
          const SizedBox(height: 10),
          for (var i = 0; i < kOrderCancelReasons.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ReasonTile(
              label: kOrderCancelReasons[i],
              selected: _reason == kOrderCancelReasons[i],
              onTap: () => setState(() => _reason = kOrderCancelReasons[i]),
            ),
          ],
          if (_reason == _kOtherReason)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AuthField(
                label: 'Din begrunnelse', // TODO(l10n)
                hint: 'Skriv kort hva som skjedde', // TODO(l10n)
                controller: _otherController,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    value.trim().length > 2 ? '' : languages.enterCancelReason,
                onValidate: () {},
              ),
            ),
          StreamBuilder<ApiResponse<BaseModel>>(
            stream: widget.subjectCancel,
            builder: (context, snapLoading) {
              final isLoading = snapLoading.hasData &&
                  snapLoading.data?.status == Status.loading;
              return DugnadSheetConfirmButton(
                label: 'Avbryt bestillingen', // TODO(l10n)
                danger: true,
                isLoading: isLoading,
                onPressed: _isValid ? _submit : null,
              );
            },
          ),
          DugnadSheetCancelButton(
            label: 'Behold bestillingen', // TODO(l10n)
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

/// `.dgd-reason` — white 14px-radius row, 1.5px hairline that turns purple-600
/// with a lavender fill when `.on`; 20px radio + 10px dot; label 14.5/700.
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
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
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? ScSaasThemeTokens.background : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: 1.5,
            color: selected ? ScSaasThemeTokens.primary : kDugnadSheetHairline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color:
                      selected ? ScSaasThemeTokens.primary : kDugnadSheetIdle,
                ),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ScSaasThemeTokens.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: ScSaasThemeTokens.text,
                        ) ??
                        const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: ScSaasThemeTokens.text,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
