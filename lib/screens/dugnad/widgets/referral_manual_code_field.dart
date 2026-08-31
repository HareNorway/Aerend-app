import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_state.dart';
import '../dugnad_referral_state.dart';
import '../dugnad_repo.dart';
import '../referral_capture_helper.dart';
import 'referral_invite_card.dart';

/// `.reg-organic` — collapsed `.reg-codetoggle` that expands into the
/// `.reg-code` entry row, with `.reg-err` and `.reg-applied` states.
///
/// Pre-club Reen styling from Design/Custom Dugnad.html `.reen-pre .reg-codetoggle`.
class ReferralManualCodeField extends StatefulWidget {
  final String? clubSlug;
  final bool startExpanded;

  const ReferralManualCodeField({
    super.key,
    this.clubSlug,
    this.startExpanded = false,
  });

  @override
  State<ReferralManualCodeField> createState() =>
      _ReferralManualCodeFieldState();
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _ReferralManualCodeFieldState extends State<ReferralManualCodeField> {
  final TextEditingController _controller = TextEditingController();
  final DugnadRepo _repo = DugnadRepo();
  bool _expanded = false;
  bool _loading = false;
  bool _pressed = false;
  String? _errorMessage;
  String? _appliedName;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
    final pending = DugnadReferralState.instance.pending;
    if (pending?.referrerDisplayName != null) {
      _appliedName = pending!.referrerDisplayName;
      _expanded = true;
    }
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final clubSlug =
        widget.clubSlug ?? DugnadReferralState.instance.pending?.clubSlug ?? '';

    final result = await _repo.validateReferral(
      clubSlug: clubSlug.isNotEmpty ? clubSlug : 'club',
      referralCode: code,
    );

    if (!mounted) return;

    if (result.valid) {
      await DugnadReferralState.instance.saveFromValidation(
        clubSlug: result.clubSlug ?? clubSlug,
        referralCode: result.referralCode ?? code,
        referralToken: result.referralToken,
        organizationId: result.organizationId,
        referrerDisplayName: result.referrerDisplayName,
        organizationName: result.organizationName,
        organizationLogo: result.organizationLogo,
      );
      if (isLoggedIn()) {
        await capturePendingDugnadReferralIfNeeded();
      }
    }

    setState(() {
      _loading = false;
      if (result.valid && result.referrerDisplayName != null) {
        _appliedName = result.referrerDisplayName;
      } else if (result.code == 'self_referral') {
        _errorMessage = languages.dugnadReferralCodeSelf;
      } else {
        _errorMessage = languages.dugnadReferralCodeInvalid;
      }
    });
  }

  void _clearApplied() {
    DugnadReferralState.instance.clearPending();
    setState(() {
      _appliedName = null;
      _errorMessage = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedName != null) {
      final pending = DugnadReferralState.instance.pending;
      final clubName = pending?.organizationName?.trim().isNotEmpty == true
          ? pending!.organizationName!.trim()
          : DugnadClubBranding.compactName();

      return ReferralInviteCard(
        clubName: clubName,
        clubLogoUrl: pending?.organizationLogo ?? DugnadState.instance.clubLogo,
        recruitedBy: pending?.referrerDisplayName ?? _appliedName!,
        onClear: _clearApplied,
      );
    }

    if (!_expanded) {
      return Padding(
        padding: EdgeInsets.only(bottom: context.dp(16)),
        child: _CodeToggle(
          label: languages.dugnadReferralHaveCode,
          onTap: () => setState(() => _expanded = true),
        ),
      );
    }

    final canSubmit = _controller.text.trim().isNotEmpty && !_loading;
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  inputFormatters: [_UpperCaseTextFormatter()],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _errorMessage = null),
                  onSubmitted: (_) => _validateCode(),
                  style: TextStyle(
                    fontSize: context.dp(15),
                    fontWeight: FontWeight.w700,
                    letterSpacing: context.dp(15) * 0.02,
                    color: Colors.white,
                  ),
                  cursorColor: ReenPreClubTokens.coral,
                  decoration: InputDecoration(
                    hintText: 'F.eks. FANA-4827',
                    hintStyle: TextStyle(
                      color: ReenPreClubTokens.textSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: context.dp(15),
                    ),
                    filled: true,
                    fillColor: ReenPreClubTokens.glassFill,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.dp(14),
                      vertical: context.dp(12),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.dp(12)),
                      borderSide: BorderSide(
                        width: context.dp(1.5),
                        color: ReenPreClubTokens.glassBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.dp(12)),
                      borderSide: BorderSide(
                        width: context.dp(1.5),
                        color: ReenPreClubTokens.glassBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.dp(12)),
                      borderSide: BorderSide(
                        width: context.dp(1.5),
                        color: ReenPreClubTokens.coral,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.dp(9)),
              GestureDetector(
                onTapDown:
                    canSubmit ? (_) => setState(() => _pressed = true) : null,
                onTapUp:
                    canSubmit ? (_) => setState(() => _pressed = false) : null,
                onTapCancel:
                    canSubmit ? () => setState(() => _pressed = false) : null,
                onTap: canSubmit ? _validateCode : null,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 120),
                  scale: _pressed ? 0.97 : 1,
                  child: Opacity(
                    opacity: canSubmit ? 1 : 0.45,
                    child: Container(
                      height: context.dp(48),
                      padding:
                          EdgeInsets.symmetric(horizontal: context.dp(16)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: ReenPreClubTokens.shinyCoral,
                        borderRadius: BorderRadius.circular(context.dp(12)),
                        boxShadow: canSubmit
                            ? [
                                BoxShadow(
                                  color: ReenPreClubTokens.coral
                                      .withValues(alpha: 0.45),
                                  blurRadius: context.dp(16),
                                  offset: Offset(0, context.dp(6)),
                                  spreadRadius: context.dp(-6),
                                ),
                              ]
                            : null,
                      ),
                      child: _loading
                          ? SizedBox(
                              width: context.dp(16),
                              height: context.dp(16),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              languages.apply,
                              style: TextStyle(
                                fontSize: context.dp(14),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: context.dp(8)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: context.dp(13),
                  color: ScSaasThemeTokens.danger,
                ),
                SizedBox(width: context.dp(6)),
                Flexible(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: context.dp(12),
                      fontWeight: FontWeight.w700,
                      color: ScSaasThemeTokens.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `.reen-pre .reg-codetoggle` — glass plate, coral key, white label.
class _CodeToggle extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _CodeToggle({required this.label, required this.onTap});

  @override
  State<_CodeToggle> createState() => _CodeToggleState();
}

class _CodeToggleState extends State<_CodeToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.ease,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(15),
          vertical: context.dp(11),
        ),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0x1FFFFFFF) // ~.12 hover
              : ReenPreClubTokens.glassFill, // ~.075
          borderRadius: BorderRadius.circular(context.dp(12)),
          border: Border.all(
            color: _pressed
                ? ReenPreClubTokens.coral.withValues(alpha: 0.4)
                : const Color(0x2EFFFFFF), // ~.18
            width: context.dp(1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.vpn_key_rounded,
              size: context.dp(15),
              color: ReenPreClubTokens.coral,
            ),
            SizedBox(width: context.dp(9)),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: context.dp(14),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
