import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../auth/onboarding_copy.dart';
import '../auth/onboarding_kit.dart';
import '../login/login.dart';
import 'consent_legal_docs.dart';

/// Onboarding **Vilkår** (+ the terms / privacy reader) — mirrors
/// `onbErVilkaar` / `onbErTekst` in
/// `Design/Ærend Kunde Bergen (frittstående).html`.
///
/// Pushed by [Login] before the first sign-in method. Pops `true` once
/// accepted (persisted in [prefTermsAccepted], so it shows once per device)
/// and `false` on "Avvis".
class ConsentGateScreen extends StatefulWidget {
  const ConsentGateScreen({super.key});

  @override
  State<ConsentGateScreen> createState() => _ConsentGateScreenState();
}

class _ConsentGateScreenState extends State<ConsentGateScreen> {
  bool _checked = false;
  int _shake = 0;

  /// `'terms'` / `'privacy'` while the reader is open.
  String? _doc;

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _openDoc('terms');
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _openDoc('privacy');

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _openDoc(String id) => setState(() => _doc = id);

  void _closeDoc() => setState(() => _doc = null);

  Future<void> _accept() async {
    if (!_checked) {
      setState(() => _shake++);
      return;
    }
    await prefSetBool(prefTermsAccepted, true);
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(true);
    } else {
      openScreenWithClearPreviousHandoff(context, const Login());
    }
  }

  void _decline() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(false);
    } else {
      openSimpleSnackbar(OnbCopy.declinedToast);
      continueAsGuest(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = _doc != null;
    return PopScope(
      canPop: !reading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && reading) _closeDoc();
      },
      child: OnbScaffold(
        // The reader has its own header; the ladder would cover it.
        step: reading ? null : 0,
        child: KeyedSubtree(
          key: ValueKey(_doc),
          child: OnbEnter(
            child: reading
                ? _buildDoc(context, consentLegalDocById(_doc!))
                : _buildGate(context),
          ),
        ),
      ),
    );
  }

  Widget _buildGate(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                onbTopInset(context),
                22,
                bottom + 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnbRise(
                    delayMs: 50,
                    child: Text(
                      OnbCopy.termsTitle,
                      style: onbDisplay(
                        26,
                        letterSpacingEm: -.035,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AegilSays(
                    asset: OnbAegil.terms,
                    text: OnbCopy.aegilTerms,
                    avatarSize: 54,
                    avatarRadius: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    delayMs: 160,
                  ),
                  const SizedBox(height: 18),
                  OnbRise(
                    delayMs: 260,
                    child: _DocCard(
                      title: OnbCopy.termsDoc,
                      subtitle: OnbCopy.termsDocSub,
                      icon: OnbIcons.doc,
                      gradient: const [OnbColors.orangeLight, OnbColors.orange],
                      glow: OnbColors.orange,
                      onTap: () => _openDoc('terms'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OnbRise(
                    delayMs: 340,
                    child: _DocCard(
                      title: OnbCopy.privacyDoc,
                      subtitle: OnbCopy.privacyDocSub,
                      icon: OnbIcons.shield,
                      gradient: const [Color(0xFF7FF0CB), OnbColors.mintDeep],
                      glow: OnbColors.mintDeep,
                      onTap: () => _openDoc('privacy'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OnbShake(trigger: _shake, child: _buildCheck()),
                  const Expanded(child: SizedBox(height: 12)),
                  OnbCta(
                    label: OnbCopy.acceptCta,
                    ready: _checked,
                    onTap: _accept,
                  ),
                  const SizedBox(height: 8),
                  OnbTextLink(label: OnbCopy.decline, onTap: _decline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheck() {
    final link = onbText(
      12.5,
      weight: FontWeight.w800,
      height: 1.45,
      color: OnbColors.orangeLight,
      decoration: TextDecoration.underline,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _checked = !_checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: _checked
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [OnbColors.orangeLight, OnbColors.orange],
                    )
                  : null,
              color: _checked ? null : const Color(0x4D000000),
              border: Border.all(
                width: 1.5,
                color: _checked ? OnbColors.orange : const Color(0x4DFFFFFF),
              ),
            ),
            child: _checked
                ? OnbHake(
                    child: OnbIcons.of(OnbIcons.check('#FFFFFF', 3.4), 15),
                  )
                : null,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: onbText(
                  12.5,
                  height: 1.45,
                  color: const Color(0xE0FFFFFF),
                ),
                children: [
                  TextSpan(text: OnbCopy.acceptPrefix),
                  TextSpan(
                    text: OnbCopy.acceptTerms,
                    style: link,
                    recognizer: _termsTap,
                  ),
                  TextSpan(text: OnbCopy.acceptAnd),
                  TextSpan(
                    text: OnbCopy.acceptPrivacy,
                    style: link,
                    recognizer: _privacyTap,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoc(BuildContext context, ConsentLegalDoc doc) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, bottom + 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                OnbPressable(
                  onTap: _closeDoc,
                  pressScale: .92,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(3, 16, 24, .8),
                          offset: const Offset(0, 8),
                          blurRadius: onbBlur(16),
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: OnbIcons.of(OnbIcons.chevronLeft('#0F1F2B'), 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc.id == 'privacy' ? OnbCopy.privacyDoc : OnbCopy.termsDoc,
                    style: onbDisplay(18, letterSpacingEm: -.02),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(3, 16, 24, .9),
                    offset: const Offset(0, 24),
                    blurRadius: onbBlur(40),
                    spreadRadius: -22,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.updated.toUpperCase(),
                        style: onbText(
                          10,
                          weight: FontWeight.w800,
                          letterSpacingEm: .1,
                          color: const Color(0xFF8C847C),
                        ),
                      ),
                      for (final b in doc.blocks) ..._block(b),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OnbCta(
            label: OnbCopy.backToTerms,
            onTap: _closeDoc,
            height: 52,
            fontSize: 15,
            dropY: 16,
            dropBlur: 24,
            dropSpread: -12,
          ),
        ],
      ),
    );
  }

  List<Widget> _block(ConsentLegalBlock b) {
    final body = onbText(
      12.5,
      weight: FontWeight.w500,
      height: 1.55,
      color: const Color(0xFF4A4741),
    );
    return [
      if (b.h != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            b.h!,
            style: onbDisplay(
              14.5,
              letterSpacingEm: -.015,
              color: const Color(0xFF173E48),
            ),
          ),
        ),
      if (b.p != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(b.p!, style: body),
        ),
      for (final item in b.list ?? const <String>[])
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: OnbColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(child: Text(item, style: body.copyWith(height: 1.5))),
            ],
          ),
        ),
    ];
  }
}

/// White document row: gradient icon tile, title + subtitle, chevron.
class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.glow,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String icon;
  final List<Color> gradient;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnbPressable(
      onTap: onTap,
      pressScale: .985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: onbPaperShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: .9),
                    offset: const Offset(0, 6),
                    blurRadius: onbBlur(12),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: OnbIcons.of(icon, 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: onbDisplay(14, color: OnbColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: onbText(11.5, color: OnbColors.cardSub),
                  ),
                ],
              ),
            ),
            OnbIcons.of(OnbIcons.chevronRight('#B9AF9C'), 16),
          ],
        ),
      ),
    );
  }
}
