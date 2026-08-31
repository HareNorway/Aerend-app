import 'package:flutter/material.dart';

import '../../networking/api_base_helper.dart';
import '../../screens/common/auth/auth_style.dart';
import '../../screens/common/base_dl.dart';
import '../../ui/kit/ae_sheet.dart';
import '../../ui/kit/ae_confirm_sheet.dart';
import '../../utils/utils.dart';
import 'review_dialog_bloc.dart';

/// `ReviewSheet` (dugnad/dialogs.jsx) — bottom sheet, not an AlertDialog.
/// `.dg-msheet` › `.dg-msheet-grab` › `.dg-mem-head` (purple tone, star glyph)
/// › `.dgd-stars` 30px star row › optional `.ae-field` comment ›
/// `.ae-btn--primary` "Send vurdering" (disabled until a star is picked) ›
/// `.dga-cancel` "Ikke nå".
///
/// The repo rates the store *and* (when there is one) the delivery person, so
/// the sheet repeats the star row + comment per subject. Constructor, bloc and
/// `onSelected(true)` contract are unchanged.
class ReviewDialog extends StatefulWidget {
  final String deliveryPeopleName, storeName;
  final int orderId;
  final void Function(bool isCompleted)? onSelected;

  const ReviewDialog({
    super.key,
    required this.deliveryPeopleName,
    required this.storeName,
    required this.orderId,
    this.onSelected,
  });

  @override
  State<StatefulWidget> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  ReviewDialogBloc? _reviewDialogBloc;

  int _storeStars = 0;
  int _driverStars = 0;

  bool get _hasDriver => widget.deliveryPeopleName.trim().isNotEmpty;

  @override
  void didChangeDependencies() {
    _reviewDialogBloc ??= ReviewDialogBloc(
      context,
      widget.orderId,
      this,
      ratingToDriver: _hasDriver,
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _reviewDialogBloc?.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _storeStars > 0 && (!_hasDriver || _driverStars > 0);

  @override
  Widget build(BuildContext context) {
    final bloc = _reviewDialogBloc!;
    return Form(
      child: AeSheetBody(
        children: [
          AeSheetHead(
            icon: Icons.star_rounded,
            title: 'Hvordan gikk det?', // TODO(l10n)
            message: widget.storeName.trim().isNotEmpty
                ? '${languages.ratingTitle} — ${widget.storeName}'
                : languages.ratingTitle,
          ),
          _subjectLabel(
            widget.storeName.trim().isNotEmpty
                ? widget.storeName
                : languages.store,
          ),
          _StarRow(
            value: _storeStars,
            onChanged: (value) {
              setState(() => _storeStars = value);
              bloc.changeStoreRating(value.toDouble());
            },
          ),
          const SizedBox(height: 4),
          AuthField(
            label: languages.writeReviewHere,
            hint: languages.commentHere,
            controller: bloc.storeCommentController,
            textInputAction: TextInputAction.done,
            validator: (value) => '',
          ),
          if (_hasDriver) ...[
            const SizedBox(height: 14),
            _subjectLabel(widget.deliveryPeopleName),
            _StarRow(
              value: _driverStars,
              onChanged: (value) {
                setState(() => _driverStars = value);
                bloc.changeDriverRating(value.toDouble());
              },
            ),
            const SizedBox(height: 4),
            AuthField(
              label: languages.writeReviewHere,
              hint: languages.commentHere,
              controller: bloc.driverCommentController,
              textInputAction: TextInputAction.done,
              validator: (value) => '',
            ),
          ],
          StreamBuilder<ApiResponse<BaseModel>>(
            stream: bloc.subject,
            builder: (context, snapLoading) {
              final isLoading = snapLoading.hasData &&
                  snapLoading.data?.status == Status.loading;
              return AeSheetPrimaryButton(
                label: 'Send vurdering', // TODO(l10n)
                icon: Icons.check_rounded,
                isLoading: isLoading,
                onPressed: _isValid
                    ? () {
                        aeSheetSaveHaptic();
                        bloc.submit(widget.onSelected);
                      }
                    : null,
              );
            },
          ),
          const AeSheetCancelButton(label: 'Ikke nå'), // TODO(l10n)
        ],
      ),
    );
  }

  /// `.ae-flabel` above each star row so it is clear who is being rated.
  Widget _subjectLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, left: 2, right: 2),
        child: Text(text, style: authLabelStyle(context)),
      );
}

/// `.dgd-stars` — centred 6px-gap row of 30px stars; `.st` is gray-300 and
/// `.st.on` is #f0b429 scaled 1.06.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  /// `.dgd-stars .st.on { color: #f0b429 }`
  static const Color _onColor = Color(0xFFF0B429);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // .dgd-stars { margin: 10px 0 6px }
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var n = 1; n <= 5; n++) ...[
            if (n > 1) const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(n),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.ease,
                  scale: n <= value ? 1.06 : 1,
                  child: Icon(
                    n <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 30,
                    color: n <= value ? _onColor : kAeSheetIdle,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
