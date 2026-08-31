import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/custom_text_field.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../auth/auth_style.dart';

/// Shared Ærend design widgets for the "Min konto" screens
/// (prototype: `dugnad/account.jsx` + `dugnad.css`).

TextStyle _jakarta(
  double size,
  FontWeight weight, {
  Color? color,
  double? height,
  double? letterSpacingEm,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacingEm != null ? size * letterSpacingEm : null,
    color: color ?? ScSaasThemeTokens.text,
  );
}

/// `.dga-fbox .v.ph` / `.dga-danger .go` — --ae-gray-400.
const Color kAccountGray400 = Color(0xFFA9A4BB);

/// `.tk-head` — back button, centred h1 (20/800/-0.015em), 38px end spacer.
/// Horizontal inset is 22 (not design’s 18) so the back circle clears the
/// device edge the same way as [AoTkHead].
class AccountTkHead extends StatelessWidget {
  const AccountTkHead({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  /// Optional end action (e.g. «Merk lest»). Sized to ~38px when null.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(22),
        context.dp(8),
        context.dp(22),
        context.dp(14),
      ),
      child: Row(
        children: [
          AccountShinyBackButton(
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _jakarta(20, FontWeight.w800,
                  letterSpacingEm: -0.015, color: theme.text),
            ),
          ),
          SizedBox(width: context.dp(12)),
          SizedBox(
            width: trailing == null ? context.dp(38) : null,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// `.tk-head .ae-back` — delegates to the shared [AeBackButton].
class AccountShinyBackButton extends StatelessWidget {
  const AccountShinyBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AeBackButton(onPressed: onPressed);
  }
}

/// `.dg-mem-head` — 40px gradient icon circle + title + blurb.
class AccountSheetHead extends StatelessWidget {
  const AccountSheetHead({
    super.key,
    required this.icon,
    required this.title,
    required this.blurb,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String blurb;

  /// Flat colour override (delete sheet uses `--ae-error`); defaults to the
  /// `--ae-shiny-purple` gradient.
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: iconBackground != null
                ? BoxDecoration(color: iconBackground, shape: BoxShape.circle)
                : BoxDecoration(
                    gradient: theme.shinyGradient,
                    shape: BoxShape.circle,
                    boxShadow: theme.shadowButton,
                  ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _jakarta(18, FontWeight.w800,
                      letterSpacingEm: -0.02, color: theme.text),
                ),
                const SizedBox(height: 5),
                Text(
                  blurb,
                  style: _jakarta(
                    12.5,
                    FontWeight.w600,
                    height: 1.45,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dga-cancel` — plain text cancel button beneath sheet actions.
class AccountSheetCancelButton extends StatelessWidget {
  const AccountSheetCancelButton({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => Navigator.maybePop(context),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Center(
            child: Text(
              label,
              style: _jakarta(
                14.5,
                FontWeight.w700,
                color: ScSaasThemeTokens.gray500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable edit sheet — mirrors `EditFieldSheet` in account.jsx:
/// `.dg-mem-head`, `.dga-cur` current-value row, `.ae-field` input
/// (`.dga-phone` prefix chip for the phone variant), primary save button,
/// `.dga-cancel`.
class AccountEditFieldSheet extends StatefulWidget {
  const AccountEditFieldSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.blurb,
    required this.label,
    required this.hint,
    required this.saveLabel,
    required this.cancelLabel,
    required this.isValid,
    required this.onSave,
    this.current,
    this.phonePrefix,
    this.initialValue = '',
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  final IconData icon;
  final String title;
  final String blurb;

  /// `.dga-cur` row value — hidden when null/empty.
  final String? current;
  final String label;
  final String hint;
  final String saveLabel;

  /// `languages.cancel` ("Avbryt").
  final String cancelLabel;

  /// Country code shown in the `.dga-phone .cc` chip (phone variant only).
  final String? phonePrefix;
  final String initialValue;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool Function(String value) isValid;

  /// Performs the save. Pop the sheet (with a result) on success; show a
  /// snackbar on failure. The sheet shows a spinner while this runs.
  final Future<void> Function(BuildContext sheetContext, String value) onSave;

  @override
  State<AccountEditFieldSheet> createState() => _AccountEditFieldSheetState();
}

class _AccountEditFieldSheetState extends State<AccountEditFieldSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    aeSheetSaveHaptic();
    setState(() => _saving = true);
    try {
      await widget.onSave(context, _controller.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final hasCurrent = widget.current != null && widget.current!.isNotEmpty;
    final valid = widget.isValid(_controller.text);

    // .dg-msheet padding: 12px 18px calc(safe-area + 22px).
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 22 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AeSheetHandle(),
            AccountSheetHead(
              icon: widget.icon,
              title: widget.title,
              blurb: widget.blurb,
            ),
            if (hasCurrent) _currentRow(theme),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: authLabelStyle(context).copyWith(color: theme.text),
            ),
            const SizedBox(height: 8),
            if (widget.phonePrefix != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _phonePrefixChip(theme),
                  const SizedBox(width: 9),
                  Expanded(child: _input(theme)),
                ],
              )
            else
              _input(theme),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: widget.saveLabel,
              isLoading: _saving,
              onPressed: valid && !_saving ? _save : null,
            ),
            AccountSheetCancelButton(
              label: widget.cancelLabel,
              onTap: () {
                aeSheetCloseHaptic();
                Navigator.maybePop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// `.dga-cur` — "Nåværende" row.
  Widget _currentRow(AeThemePalette theme) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            'Nåværende'.toUpperCase(), // TODO(l10n)
            style: _jakarta(
              11.5,
              FontWeight.w800,
              letterSpacingEm: 0.06,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.current!,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _jakarta(14.5, FontWeight.w700, color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// `.dga-phone .cc` — 🇳🇴 +47 chip.
  Widget _phonePrefixChip(AeThemePalette theme) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇳🇴', style: TextStyle(fontSize: 16, height: 1)),
          const SizedBox(width: 6),
          Text(
            widget.phonePrefix!,
            style: _jakarta(15, FontWeight.w800, color: theme.text),
          ),
        ],
      ),
    );
  }

  /// `.ae-input` — white, radius 14, 1.5px border, club focus ring.
  Widget _input(AeThemePalette theme) {
    return _AccountSheetInput(
      controller: _controller,
      hint: widget.hint,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      focusColor: theme.primary,
    );
  }
}

class _AccountSheetInput extends StatefulWidget {
  const _AccountSheetInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.focusColor,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color? focusColor;

  @override
  State<_AccountSheetInput> createState() => _AccountSheetInputState();
}

class _AccountSheetInputState extends State<_AccountSheetInput> {
  bool _focused = false;

  static const _radius = BorderRadius.all(Radius.circular(14));

  OutlineInputBorder _border(Color color) => const OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(width: 1.5, color: Colors.transparent),
      ).copyWith(borderSide: BorderSide(width: 1.5, color: color));

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final focus = widget.focusColor ?? theme.primary;
    return Focus(
      skipTraversal: true,
      canRequestFocus: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.ease,
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: focus.withValues(alpha: 0.12),
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: TextFormFieldCustom(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: TextInputAction.done,
          inputFormatters: widget.inputFormatters,
          useLabelWithBorder: false,
          backgroundColor: Colors.white,
          radius: 14,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: widget.hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(focus),
            errorBorder: _border(ScSaasThemeTokens.danger),
            focusedErrorBorder: _border(ScSaasThemeTokens.danger),
            hintStyle: GoogleFonts.plusJakartaSans(
              color: ScSaasThemeTokens.gray500,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            color: theme.ink,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// `DeleteAccountSheet` from account.jsx — red icon head, `.dga-warn`,
/// `.dga-ack` checkbox gate, red `.dga-del` button, "Behold kontoen" cancel.
class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({
    super.key,
    required this.title,
    required this.onConfirm,
  });

  /// Sheet title (`languages.accountDelete`).
  final String title;
  final VoidCallback onConfirm;

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  bool _ack = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 22 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AeSheetHandle(),
          AccountSheetHead(
            icon: Icons.delete_outline_rounded,
            title: widget.title,
            blurb: 'Dette kan ikke angres.', // TODO(l10n)
            iconBackground: ScSaasThemeTokens.danger,
          ),
          // .dga-warn
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0x14D9534F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              // TODO(l10n)
              'Poengene, merkene og den faste støtten din forsvinner. '
              'Klubben mister deg som ildsjel. 💜',
              style: _jakarta(
                13.5,
                FontWeight.w600,
                height: 1.5,
                color: const Color(0xFF96322F),
              ),
            ),
          ),
          // .dga-ack
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _ack = !_ack),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.ease,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: _ack
                            ? ScSaasThemeTokens.danger
                            : Colors.transparent,
                        border: Border.all(
                          width: 2,
                          color: _ack
                              ? ScSaasThemeTokens.danger
                              : ScSaasThemeTokens.gray300,
                        ),
                      ),
                      child: _ack
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Jeg forstår at kontoen slettes permanent', // TODO(l10n)
                        style: _jakarta(13.5, FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // .dga-del
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AuthPressable(
              onTap: _ack
                  ? () {
                      aeSheetSaveHaptic();
                      widget.onConfirm();
                    }
                  : null,
              builder: (context, pressed) => AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _ack ? 1 : 0.4,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.danger,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Slett kontoen min', // TODO(l10n)
                        style: _jakarta(15, FontWeight.w800,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AccountSheetCancelButton(
            label: 'Behold kontoen', // TODO(l10n)
            onTap: () {
              aeSheetCloseHaptic();
              Navigator.maybePop(context);
            },
          ),
        ],
      ),
    );
  }
}
