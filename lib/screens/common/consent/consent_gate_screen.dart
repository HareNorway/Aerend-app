import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../auth/auth_style.dart';
import '../login/login.dart';
import '../splash/splash.dart';
import 'consent_legal_docs.dart';
import 'reen_flip_mark.dart';

/// `cubic-bezier(.4,0,.75,.4)` — `dgc-fall`.
const Cubic _kFall = Cubic(0.4, 0, 0.75, 0.4);

/// `cubic-bezier(.22,.85,.3,1)` card enter.
const Cubic _kCardIn = Cubic(0.22, 0.85, 0.3, 1);

/// `cubic-bezier(.24,1.4,.4,1)` checkbox pop.
const Cubic _kBoxPop = Cubic(0.24, 1.4, 0.4, 1);

/// Ports `DgConsentGate` — sits on the shared Reen navy between splash and login.
class ConsentGateScreen extends StatefulWidget {
  const ConsentGateScreen({super.key});

  @override
  State<ConsentGateScreen> createState() => _ConsentGateScreenState();
}

class _ConsentGateScreenState extends State<ConsentGateScreen> {
  final GlobalKey _markKey = GlobalKey();

  bool _checked = false;
  String? _doc;
  bool _declined = false;
  bool _leaving = false;
  bool _declLeaving = false;

  Rect? _splashFrom;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _splashFrom = ReenMarkHandoff.takeSplash();
    _termsTap = TapGestureRecognizer()..onTap = () => _openDoc('terms');
    _privacyTap = TapGestureRecognizer()..onTap = () => _openDoc('privacy');
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _openDoc(String id) {
    if (_leaving) return;
    setState(() => _doc = id);
  }

  void _closeDoc() {
    setState(() => _doc = null);
  }

  void _accept() {
    if (!_checked || _leaving) return;
    ReenMarkHandoff.consentMark = ReenMarkHandoff.measure(_markKey);
    if (_reduceMotion) {
      _goLogin();
      return;
    }
    setState(() => _leaving = true);
    Future<void>.delayed(const Duration(milliseconds: 340), () {
      if (!mounted) return;
      _goLogin();
    });
  }

  void _goLogin() {
    if (!mounted) return;
    openScreenWithClearPreviousHandoff(context, const Login(fromConsent: true));
  }

  void _leaveDecl(VoidCallback then) {
    if (_reduceMotion) {
      then();
      return;
    }
    setState(() => _declLeaving = true);
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _declLeaving = false);
      then();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AerendBergenAuthTokens.navyBottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AerendBergenAuthTokens.screenGradient,
          ),
          child: SafeArea(
            child: _doc != null
                ? _buildDoc(context, consentLegalDocById(_doc!))
                : _declined
                ? _buildDeclined(context)
                : _buildGate(context),
          ),
        ),
      ),
    );
  }

  Widget _buildGate(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(26),
        0,
        context.dp(26),
        context.dp(30),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    ReenFlipMark(
                      from: _splashFrom,
                      duration: const Duration(milliseconds: 620),
                      child: SvgPicture.asset(
                        AerendBergenAuthTokens.mark,
                        key: _markKey,
                        height: context.dp(34),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: context.dp(26)),
                    _rise(
                      Text(
                        'Vilkår og personvern',
                        textAlign: TextAlign.center,
                        style: authTitleStyle(context).copyWith(
                          fontSize: context.dp(25),
                          height: 1.18,
                          letterSpacing: context.dp(25) * -0.025,
                        ),
                      ),
                      260,
                      fallDelay: 150,
                      fallMs: 280,
                    ),
                    SizedBox(height: context.dp(10)),
                    _rise(
                      Text(
                        'Før du oppretter en konto må du godta vilkårene for bruk og personvernerklæringen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xC7FFFFFF),
                          fontSize: context.dp(14.5),
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
                      ),
                      330,
                      fallDelay: 120,
                      fallMs: 280,
                    ),
                    SizedBox(height: context.dp(24)),
                    _rise(
                      Column(
                        children: [
                          _DocRow(
                            icon: Icons.receipt_long_outlined,
                            title: 'Vilkår for bruk',
                            subtitle: 'Regler for bruk av appen og tjenesten',
                            onTap: () => _openDoc('terms'),
                          ),
                          SizedBox(height: context.dp(10)),
                          _DocRow(
                            icon: Icons.shield_outlined,
                            title: 'Personvernerklæring',
                            subtitle: 'Hvordan vi behandler opplysningene dine',
                            onTap: () => _openDoc('privacy'),
                          ),
                        ],
                      ),
                      400,
                      fallDelay: 80,
                    ),
                    SizedBox(height: context.dp(20)),
                    _rise(
                      _ConsentCheck(
                        checked: _checked,
                        onChanged: (v) => setState(() => _checked = v),
                        termsTap: _termsTap,
                        privacyTap: _privacyTap,
                      ),
                      470,
                      fallDelay: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _rise(
            Column(
              children: [
                AuthPrimaryButton(
                  label: 'Godta og fortsett',
                  onPressed: (_checked && !_leaving) ? _accept : null,
                ),
                Transform.translate(
                  offset: Offset(0, context.dp(-4)),
                  child: TextButton(
                    onPressed: _leaving
                        ? null
                        : () => setState(() => _declined = true),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0x99FFFFFF),
                      padding: EdgeInsets.all(context.dp(13)),
                    ),
                    child: Text(
                      'Avvis',
                      style: TextStyle(
                        fontSize: context.dp(14),
                        fontWeight: FontWeight.w700,
                        color: const Color(0x99FFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            540,
            fallDelay: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildDoc(BuildContext context, ConsentLegalDoc doc) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(22),
        context.dp(8),
        context.dp(22),
        context.dp(30),
      ),
      child: Column(
        children: [
          AeRiseIn(
            duration: const Duration(milliseconds: 500),
            offsetY: 14,
            child: Row(
              children: [
                AuthBackButton(onTap: _closeDoc),
                Expanded(
                  child: Text(
                    doc.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.dp(20),
                      fontWeight: FontWeight.w800,
                      letterSpacing: context.dp(20) * -0.02,
                    ),
                  ),
                ),
                SizedBox(width: context.dp(38)),
              ],
            ),
          ),
          SizedBox(height: context.dp(6)),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: _DocCardIn(child: _LegalCard(doc: doc)),
            ),
          ),
          SizedBox(height: context.dp(18)),
          AeRiseIn(
            delay: const Duration(milliseconds: 460),
            duration: const Duration(milliseconds: 500),
            offsetY: 14,
            child: AuthPrimaryButton(
              label: 'Tilbake til vilkårene',
              onPressed: _closeDoc,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclined(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(26),
        0,
        context.dp(26),
        context.dp(34),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    _DeclPop(
                      leaving: _declLeaving,
                      child: Container(
                        width: context.dp(74),
                        height: context.dp(74),
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(context.dp(24)),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: context.dp(28),
                          color: AerendBergenAuthTokens.orangeHover,
                        ),
                      ),
                    ),
                    SizedBox(height: context.dp(20)),
                    _declRise(
                      Text(
                        'Du kan ikke opprette konto',
                        textAlign: TextAlign.center,
                        style: authTitleStyle(
                          context,
                        ).copyWith(fontSize: context.dp(25), height: 1.18),
                      ),
                      100,
                      fallDelay: 140,
                      fallMs: 260,
                    ),
                    SizedBox(height: context.dp(10)),
                    _declRise(
                      Text(
                        'For å opprette konto må du godta vilkårene for bruk og personvernerklæringen. Uten samtykke kan vi ikke lagre noe om deg — men du kan fortsatt se deg rundt i appen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xC7FFFFFF),
                          fontSize: context.dp(14.5),
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
                      ),
                      170,
                      fallDelay: 100,
                      fallMs: 260,
                    ),
                    SizedBox(height: context.dp(22)),
                    _declRise(
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          context.dp(14),
                          context.dp(13),
                          context.dp(14),
                          context.dp(13),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x12FFFFFF),
                          borderRadius: BorderRadius.circular(context.dp(15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: context.dp(16),
                              color: AerendBergenAuthTokens.orangeHover,
                            ),
                            SizedBox(width: context.dp(11)),
                            Expanded(
                              child: Text(
                                'Du kan lese dokumentene i ro og bestemme deg etterpå. Ingenting lagres før du godtar.',
                                style: TextStyle(
                                  color: const Color(0xB8FFFFFF),
                                  fontSize: context.dp(12.5),
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      240,
                      fallDelay: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _declRise(
                AuthPrimaryButton(
                  label: 'Les vilkårene på nytt',
                  onPressed: () =>
                      _leaveDecl(() => setState(() => _declined = false)),
                ),
                310,
                fallDelay: 0,
              ),
              SizedBox(height: context.dp(10)),
              _declRise(
                _GlassSecondaryButton(
                  label: 'Fortsett uten å opprette konto',
                  onPressed: () => _leaveDecl(() => continueAsGuest(context)),
                ),
                370,
                fallDelay: 0,
              ),
              _declRise(
                TextButton(
                  onPressed: () => _leaveDecl(() {
                    openScreenWithClearPreviousHandoff(context, const Splash());
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0x99FFFFFF),
                    padding: EdgeInsets.all(context.dp(13)),
                  ),
                  child: Text(
                    'Tilbake',
                    style: TextStyle(
                      fontSize: context.dp(14),
                      fontWeight: FontWeight.w700,
                      color: const Color(0x99FFFFFF),
                    ),
                  ),
                ),
                430,
                fallDelay: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rise(
    Widget child,
    int delayMs, {
    required int fallDelay,
    int fallMs = 300,
  }) {
    return AeRiseIn(
      delay: Duration(milliseconds: delayMs),
      duration: const Duration(milliseconds: 620),
      offsetY: 14,
      child: _DgcFall(
        leaving: _leaving,
        delay: Duration(milliseconds: fallDelay),
        duration: Duration(milliseconds: fallMs),
        child: child,
      ),
    );
  }

  Widget _declRise(
    Widget child,
    int delayMs, {
    required int fallDelay,
    int fallMs = 280,
  }) {
    return AeRiseIn(
      delay: Duration(milliseconds: delayMs),
      duration: const Duration(milliseconds: 560),
      offsetY: 14,
      child: _DgcFall(
        leaving: _declLeaving,
        delay: Duration(milliseconds: fallDelay),
        duration: Duration(milliseconds: fallMs),
        child: child,
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuthPressable(
      onTap: onTap,
      builder: (context, pressed) {
        return AnimatedScale(
          scale: pressed ? 0.99 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.ease,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              context.dp(14),
              context.dp(13),
              context.dp(14),
              context.dp(13),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x16FFFFFF), Color(0x08FFFFFF)],
              ),
              borderRadius: BorderRadius.circular(context.dp(16)),
              border: Border.all(
                color: pressed
                    ? const Color(0x73E86657)
                    : const Color(0x26FFFFFF),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x24FFFFFF), offset: Offset(0, 1)),
                BoxShadow(
                  color: Color(0x4D040C18),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(38),
                  height: context.dp(38),
                  decoration: BoxDecoration(
                    color: const Color(0x29E86657),
                    borderRadius: BorderRadius.circular(context.dp(12)),
                  ),
                  child: Icon(
                    icon,
                    size: context.dp(19),
                    color: AerendBergenAuthTokens.orangeHover,
                  ),
                ),
                SizedBox(width: context.dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.dp(14),
                          fontWeight: FontWeight.w800,
                          letterSpacing: context.dp(14) * -0.01,
                        ),
                      ),
                      SizedBox(height: context.dp(3)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0x9EFFFFFF),
                          fontSize: context.dp(12.5),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: context.dp(18),
                  color: const Color(0x6BFFFFFF),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConsentCheck extends StatefulWidget {
  const _ConsentCheck({
    required this.checked,
    required this.onChanged,
    required this.termsTap,
    required this.privacyTap,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final TapGestureRecognizer termsTap;
  final TapGestureRecognizer privacyTap;

  @override
  State<_ConsentCheck> createState() => _ConsentCheckState();
}

class _ConsentCheckState extends State<_ConsentCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.checked) _pop.value = 1;
  }

  @override
  void didUpdateWidget(_ConsentCheck old) {
    super.didUpdateWidget(old);
    if (!old.checked && widget.checked) {
      _pop.forward(from: 0);
    } else if (old.checked && !widget.checked) {
      _pop.value = 0;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  double _popScale(double t) {
    // `@keyframes dgc-boxpop { 0%{scale(.9)} 38%{scale(1.14)} 100%{scale(1)} }`
    if (t <= 0.38) {
      final u = t / 0.38;
      return 0.9 + (1.14 - 0.9) * u;
    }
    final u = (t - 0.38) / 0.62;
    return 1.14 + (1 - 1.14) * u;
  }

  @override
  Widget build(BuildContext context) {
    final box = context.dp(24);
    final linkStyle = TextStyle(
      color: AerendBergenAuthTokens.orangeHover,
      fontSize: context.dp(13.5),
      fontWeight: FontWeight.w800,
      height: 1.5,
      decoration: TextDecoration.underline,
      decorationColor: AerendBergenAuthTokens.orangeHover,
      decorationThickness: 1,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onChanged(!widget.checked),
          child: Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: AnimatedBuilder(
              animation: _pop,
              builder: (context, child) {
                final t = _kBoxPop.transform(_pop.value);
                final scale = widget.checked ? _popScale(t) : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.ease,
                width: box,
                height: box,
                decoration: BoxDecoration(
                  color: widget.checked
                      ? AerendBergenAuthTokens.orange
                      : const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(context.dp(8)),
                  border: Border.all(
                    width: 2,
                    color: widget.checked
                        ? AerendBergenAuthTokens.orange
                        : const Color(0x59FFFFFF),
                  ),
                ),
                child: widget.checked
                    ? Icon(
                        Icons.check_rounded,
                        size: context.dp(14),
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        ),
        SizedBox(width: context.dp(12)),
        Expanded(
          child: GestureDetector(
            onTap: () => widget.onChanged(!widget.checked),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: const Color(0xCCFFFFFF),
                  fontSize: context.dp(13.5),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Jeg har lest og godtar '),
                  TextSpan(
                    text: 'vilkårene for bruk',
                    style: linkStyle,
                    recognizer: widget.termsTap,
                  ),
                  const TextSpan(text: ' og '),
                  TextSpan(
                    text: 'personvernerklæringen',
                    style: linkStyle,
                    recognizer: widget.privacyTap,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.doc});

  final ConsentLegalDoc doc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.dp(20),
        context.dp(20),
        context.dp(20),
        context.dp(22),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(20)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2D1B5B),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x732D1B5B),
            blurRadius: 38,
            offset: Offset(0, 18),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc.updated.toUpperCase(),
            style: TextStyle(
              color: const Color(0xFF7C8899),
              fontSize: context.dp(11.5),
              fontWeight: FontWeight.w800,
              letterSpacing: context.dp(11.5) * 0.05,
            ),
          ),
          for (int i = 0; i < doc.blocks.length; i++)
            _block(context, doc.blocks[i], firstHeading: i == 0),
        ],
      ),
    );
  }

  Widget _block(
    BuildContext context,
    ConsentLegalBlock b, {
    required bool firstHeading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (b.h != null)
          Padding(
            padding: EdgeInsets.only(top: context.dp(firstHeading ? 16 : 20)),
            child: Text(
              b.h!,
              style: TextStyle(
                color: AerendBergenAuthTokens.navy,
                fontSize: context.dp(15),
                fontWeight: FontWeight.w800,
                letterSpacing: context.dp(15) * -0.01,
              ),
            ),
          ),
        if (b.p != null)
          Padding(
            padding: EdgeInsets.only(top: context.dp(8)),
            child: Text(
              b.p!,
              style: TextStyle(
                color: const Color(0xFF22364D),
                fontSize: context.dp(14),
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
          ),
        if (b.list != null)
          Padding(
            padding: EdgeInsets.only(top: context.dp(10)),
            child: Column(
              children: [
                for (final item in b.list!)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.dp(7)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: context.dp(8),
                            right: context.dp(10),
                          ),
                          child: Container(
                            width: context.dp(6),
                            height: context.dp(6),
                            decoration: const BoxDecoration(
                              color: AerendBergenAuthTokens.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: const Color(0xFF22364D),
                              fontSize: context.dp(14),
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DocCardIn extends StatefulWidget {
  const _DocCardIn({required this.child});

  final Widget child;

  @override
  State<_DocCardIn> createState() => _DocCardInState();
}

class _DocCardInState extends State<_DocCardIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final CurvedAnimation _curve;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _curve = CurvedAnimation(parent: _c, curve: _kCardIn);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    if (_started) return;
    _started = true;
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Transform.scale(scale: 0.985 + 0.015 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _GlassSecondaryButton extends StatelessWidget {
  const _GlassSecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AuthPressable(
      onTap: onPressed,
      builder: (context, pressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.ease,
          width: double.infinity,
          height: context.dp(56),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.dp(14)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: pressed
                  ? const [Color(0x2BFFFFFF), Color(0x12FFFFFF)]
                  : const [Color(0x1DFFFFFF), Color(0x0BFFFFFF)],
            ),
            border: Border.all(
              color: pressed
                  ? const Color(0x73E86657)
                  : const Color(0x33FFFFFF),
            ),
          ),
          child: Text(label, style: authButtonTextStyle(context)),
        );
      },
    );
  }
}

/// `dgc-fall` — opacity 1 → 0, translateY 0 → −10.
class _DgcFall extends StatefulWidget {
  const _DgcFall({
    required this.leaving,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
  });

  final bool leaving;
  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<_DgcFall> createState() => _DgcFallState();
}

class _DgcFallState extends State<_DgcFall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final CurvedAnimation _curve;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _c, curve: _kFall);
  }

  @override
  void didUpdateWidget(_DgcFall old) {
    super.didUpdateWidget(old);
    if (!old.leaving && widget.leaving) _start();
  }

  void _start() {
    _delay?.cancel();
    if (widget.delay == Duration.zero) {
      _c.forward();
      return;
    }
    _delay = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.leaving) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, -10 * t), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Declined lock icon — `dgc-pop` in, `dgc-shrink` out.
class _DeclPop extends StatefulWidget {
  const _DeclPop({required this.leaving, required this.child});

  final bool leaving;
  final Widget child;

  @override
  State<_DeclPop> createState() => _DeclPopState();
}

class _DeclPopState extends State<_DeclPop> with TickerProviderStateMixin {
  late final AnimationController _in;
  late final AnimationController _out;
  late final CurvedAnimation _inCurve;
  late final CurvedAnimation _outCurve;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _out = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _inCurve = CurvedAnimation(
      parent: _in,
      curve: const Cubic(0.24, 1.3, 0.4, 1),
    );
    _outCurve = CurvedAnimation(parent: _out, curve: _kFall);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _in.value = 1;
      return;
    }
    if (_started) return;
    _started = true;
    _in.forward();
  }

  @override
  void didUpdateWidget(_DeclPop old) {
    super.didUpdateWidget(old);
    if (!old.leaving && widget.leaving) {
      Future<void>.delayed(const Duration(milliseconds: 170), () {
        if (mounted) _out.forward();
      });
    }
  }

  @override
  void dispose() {
    _inCurve.dispose();
    _outCurve.dispose();
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_inCurve, _outCurve]),
      builder: (context, child) {
        if (widget.leaving) {
          final t = _outCurve.value;
          return Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(scale: 1 - 0.22 * t, child: child),
          );
        }
        final t = _inCurve.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.72 + 0.28 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
