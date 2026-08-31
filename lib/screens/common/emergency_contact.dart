import 'package:aerend_customer/screens/dugnad/widgets/dugnad_subpage_shell.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/utils.dart';
import 'editProfile/edit_profile.dart';

/// «Nødkontakt» — mirrors design `checkout-screens.jsx` `EmergencyContactScreen`
/// (`.tk-head` + centred `.dgec-ripple`/`.dgec-t`/`.dgec-s` + primary CTA + `.dga-cancel`).
class EmergencyContact extends StatefulWidget {
  const EmergencyContact({super.key});

  @override
  State<EmergencyContact> createState() => _EmergencyContactState();
}

class _EmergencyContactState extends State<EmergencyContact> {
  void _openEditContact() {
    openScreenWithResult(context, const EditProfile()).then((value) {
      if (value != null && value) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildEmergencyContact(context)),
            ],
          ),
        ),
      ),
    );
  }

  /// `.tk-head` (paddingBottom 6) — shiny back circle, centred h1, 38px spacer.
  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
        child: Row(
          children: [
            DugnadLbBackButton(onPressed: () => Navigator.maybePop(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Nødkontakt", // TODO(l10n)
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 20 * -0.015,
                  color: ScSaasThemeTokens.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 38),
          ],
        ),
      );

  /// `.ae-body` — padding `0 26px 120px`, centred column.
  Widget _buildEmergencyContact(BuildContext context) {
    bool isEcNotEmpty = prefGetString(prefEmergencyContact).trim().isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(26, 0, 26, MediaQuery.paddingOf(context).bottom + 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // `.dgec-ripple` — 92px lavender circle + two pulsing rings.
            const Center(child: _EcRippleCircle()),
            const SizedBox(height: 20),
            // `.dgec-t`
            Text(
              isEcNotEmpty
                  ? prefGetString(prefEmergencyContact)
                  : "Ingen nødkontakt lagt til", // TODO(l10n)
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 19 * -0.02,
                color: ScSaasThemeTokens.text,
              ),
            ),
            const SizedBox(height: 8),
            // `.dgec-s` — max-width 270, centred.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: Text(
                  isEcNotEmpty
                      ? "Vi ringer denne personen hvis noe skjer under en levering." // TODO(l10n)
                      : "Legg til en person vi kan ringe hvis noe skjer under en levering.", // TODO(l10n)
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            // `.ae-btn--primary` — «Ring nødkontakt» / «Legg til nødkontakt».
            _EcPrimaryButton(
              label: isEcNotEmpty
                  ? "Ring nødkontakt" // TODO(l10n)
                  : "Legg til nødkontakt", // TODO(l10n)
              icon: isEcNotEmpty ? Icons.call_rounded : Icons.add_rounded,
              onTap: () {
                if (isEcNotEmpty) {
                  String emergencyContact = prefGetString(prefEmergencyContact);
                  openUrl("tel:$emergencyContact");
                } else {
                  _openEditContact();
                }
              },
            ),
            // `.dga-cancel` — «Endre kontakt».
            if (isEcNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openEditContact,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Text(
                      "Endre kontakt", // TODO(l10n)
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.dgec-ripple` — lavender phone circle with two expanding ring pulses
/// (`dgec-pulse`: scale 1 → 1.55, opacity .7 → 0, 2.4s, second ring +1.2s).
class _EcRippleCircle extends StatefulWidget {
  const _EcRippleCircle();

  @override
  State<_EcRippleCircle> createState() => _EcRippleCircleState();
}

class _EcRippleCircleState extends State<_EcRippleCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double t) {
    final scale = 1 + 0.55 * t;
    final opacity = (0.7 * (1 - t)).clamp(0.0, 1.0);
    return Positioned.fill(
      child: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 2, color: const Color(0xFFC9B8EC)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ScSaasThemeTokens.background,
      ),
      child: const Icon(Icons.call_rounded, size: 30, color: ScSaasThemeTokens.primary),
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return SizedBox(width: 92, height: 92, child: core);
    }

    return SizedBox(
      width: 92,
      height: 92,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t1 = _controller.value;
          final t2 = (_controller.value + 0.5) % 1;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _ring(t1),
              _ring(t2),
              core,
            ],
          );
        },
      ),
    );
  }
}

/// `.ae-btn.ae-btn--primary` — 56px, radius 14, flat purple-600,
/// pressed purple-700 + translateY(1px), icon + label gap 10.
class _EcPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _EcPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_EcPrimaryButton> createState() => _EcPrimaryButtonState();
}

class _EcPrimaryButtonState extends State<_EcPrimaryButton> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.ease,
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _pressed ? ScSaasThemeTokens.primaryHover : ScSaasThemeTokens.primary,
          boxShadow: ScSaasThemeTokens.shadowButton,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 17, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 16 * -0.01,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
