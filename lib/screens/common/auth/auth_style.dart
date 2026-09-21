import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../commonView/customCountryCodePicker/custom_country_code_picker.dart';
import '../../../commonView/customCountryCodePicker/selection_dialog.dart';
import '../../../commonView/custom_text_field.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../consent/reen_flip_mark.dart';

// `.dg-auth` / Reen `.reen-pre` tokens — navy surface, coral action.
const Color _authBackground = AerendBergenAuthTokens.navy;
const Color _authText = AerendBergenAuthTokens.ink;
const Color _authSubtitle = AerendBergenAuthTokens.textSubtitle;
const Color _authHairline = AerendBergenAuthTokens.glassBorder;
const Color _authGray500 = AerendBergenAuthTokens.textSoft;
const Color _vippsOrange = Color(0xFFF1591F);
const Color _vippsOrangeLight = Color(0xFFFF7A45);
const Color _vippsOrangeDeep = Color(0xFFD9450F);
const String _reenMarkAsset = AerendBergenAuthTokens.mark;
const String _vippsWordmarkAsset = 'assets/images/vipps_wordmark.png';
const String _googleLogoAsset = 'assets/images/google_standard_color.png';

/// Design `.reen-pre .auth-methods .ae-btn--vipps`:
/// `linear-gradient(180deg,#FF7A45,#F1591F 60%,#D9450F)`.
const LinearGradient _vippsShinyGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_vippsOrangeLight, _vippsOrange, _vippsOrangeDeep],
  stops: [0.0, 0.6, 1.0],
);

/// `.reen-pre .auth-methods .ae-btn--secondary` / `--dark` white plate.
const LinearGradient _socialShinyGradient = LinearGradient(
  begin: Alignment(-0.5, -0.85),
  end: Alignment(0.5, 0.85),
  colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FA), Color(0xFFE9EDF2)],
  stops: [0.0, 0.55, 1.0],
);

// kit-shared.css: 120ms ease colour/shadow, 60ms ease transform.
const Duration _pressColorDuration = Duration(milliseconds: 120);
const Duration _pressMoveDuration = Duration(milliseconds: 60);

TextStyle authTitleStyle(BuildContext context) {
  // `.auth-head h1`: 26px / 800 / -0.02em on Reen navy.
  final size = context.dp(26);
  return Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: _authText,
        fontSize: size,
        height: 1.4,
        fontWeight: FontWeight.w800,
        letterSpacing: size * -0.02,
      ) ??
      TextStyle(
        color: _authText,
        fontSize: size,
        height: 1.4,
        fontWeight: FontWeight.w800,
        letterSpacing: size * -0.02,
      );
}

TextStyle authSubtitleStyle(BuildContext context) {
  // `.reen-pre .auth-head p` — white ~72% (coral reserved for actions).
  final size = context.dp(14);
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: _authSubtitle,
        fontSize: size,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ) ??
      TextStyle(
        color: _authSubtitle,
        fontSize: size,
        height: 1.45,
        fontWeight: FontWeight.w600,
      );
}

TextStyle authLabelStyle(BuildContext context) {
  // `.reen-pre .ae-flabel` — white ~70% on navy.
  final size = context.dp(14);
  return Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AerendBergenAuthTokens.textMuted,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: size * -0.005,
      ) ??
      TextStyle(
        color: AerendBergenAuthTokens.textMuted,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: size * -0.005,
      );
}

TextStyle authButtonTextStyle(
  BuildContext context, {
  Color color = Colors.white,
}) {
  // .ae-btn: 16px / 700 / -0.01em
  final size = context.dp(16);
  return Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * -0.01,
      ) ??
      TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * -0.01,
      );
}

/// `.ae-body.auth-body` — fills the viewport, scrolls only when it can't.
///
/// The design body is `flex: 1` + `overflow-y: auto` inside the fixed 375×812
/// frame, so it always occupies the full height and `.auth-bottom`'s
/// `margin-top: auto` can push the action group to the bottom. The Flutter
/// equivalent is `ConstrainedBox(minHeight:)` — **minHeight, not height**, so
/// the body fills when there is room and scrolls when there isn't.
///
/// The single `margin-top: auto` is expressed as `MainAxisAlignment
/// .spaceBetween` over exactly two groups (`child`, `footer`), which is
/// identical to one `Spacer()` between them. A literal `Spacer()` cannot be
/// used here: `ConstrainedBox` passes `maxHeight: infinity` down from the
/// `SingleChildScrollView`, and a flex child under unbounded main-axis
/// constraints throws. `spaceBetween` still distributes correctly because
/// `RenderFlex` measures free space against its *constrained* size.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final Widget? footer;

  /// Absolutely-positioned chrome layered over the scroll body — the design's
  /// `position: absolute` elements (e.g. `.ae-back` at `top: 8; left: 16`),
  /// which are offset from the body's border box and so must escape
  /// [padding]. Use `Positioned` children; the Stack is the SafeArea box.
  final List<Widget> overlay;
  final bool centerContent;

  /// Defaults to [authBodyPadding] when null. Screens that need `.dg-auth`'s
  /// 34px bottom pass [dgAuthPadding] instead.
  final EdgeInsetsGeometry? padding;

  /// `.auth-body { padding: 8px 24px 24px }`, scaled. `.dg-auth` overrides the
  /// bottom to 34 — those screens pass [dgAuthPadding].
  static EdgeInsets authBodyPadding(BuildContext c) =>
      EdgeInsets.fromLTRB(c.dp(24), c.dp(8), c.dp(24), c.dp(24));

  /// `.dg-auth { padding: 8px 24px 34px }`, scaled.
  static EdgeInsets dgAuthPadding(BuildContext c) =>
      EdgeInsets.fromLTRB(c.dp(24), c.dp(8), c.dp(24), c.dp(34));

  /// `.auth-bottom { padding-top: 18px }`
  static double bottomGroupTopPadding(BuildContext c) => c.dp(18);

  const AuthScaffold({
    super.key,
    required this.child,
    this.footer,
    this.overlay = const [],
    this.centerContent = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authBackground,
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AerendBergenAuthTokens.screenGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBody(context)),
                ...overlay,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mainAxisAlignment = centerContent
              ? MainAxisAlignment.center
              : footer != null
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Full device width up to 450pt (where `ds` clamps), then a
                // centred phone-width column so tablets don't get a blown-up
                // phone layout.
                maxWidth: context.designColumnWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: padding ?? authBodyPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: mainAxisAlignment,
                  children: [
                    child,
                    if (footer != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: bottomGroupTopPadding(context),
                        ),
                        child: footer!,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double bottomSpacing;
  final bool animated;

  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.bottomSpacing = 22,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (animated) const AuthAnimatedLogo() else const AuthBrandMark(),
        SizedBox(height: context.dp(18)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: authTitleStyle(context),
        ),
        SizedBox(height: context.dp(8)),
        // .auth-head p { max-width: 30ch; margin: 0 auto; }
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.dp(268)),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: authSubtitleStyle(context),
            ),
          ),
        ),
        SizedBox(height: context.dp(bottomSpacing)),
      ],
    );
  }
}

/// The sticker Æ mark — Design `<symbol id="merke-flat">`. Natural aspect
/// ratio is 172:138 (wider than tall), unlike the old square coral badge.
class AuthBrandMark extends StatelessWidget {
  final double size;

  /// When true, wrap in a soft drop-shadow (halo is drawn separately when
  /// false, e.g. inside [AuthAnimatedLogo]).
  final bool showShadow;

  const AuthBrandMark({super.key, this.size = 68, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    final box = context.dp(size);
    final mark = SvgPicture.asset(
      _reenMarkAsset,
      width: box,
      height: box * (138 / 172),
      fit: BoxFit.contain,
    );
    if (!showShadow) return mark;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0x59000000),
            blurRadius: context.dp(24),
            offset: Offset(0, context.dp(12)),
          ),
        ],
      ),
      child: mark,
    );
  }
}

/// Login logo — settled after splash merge (no enter/breathe blink).
class AuthAnimatedLogo extends StatefulWidget {
  final double size;

  /// When true (default), skip entrance + breathe so splash→login is seamless.
  final bool settle;

  /// Consent-gate handoff: FLIP the coral mark from the gate wordmark rect.
  /// Nullable so a hot-reloaded logo built before this field existed is safe.
  final bool? fromConsent;

  const AuthAnimatedLogo({
    super.key,
    this.size = 68,
    this.settle = true,
    this.fromConsent = false,
  });

  bool get enteredFromConsent => fromConsent ?? false;

  @override
  State<AuthAnimatedLogo> createState() => _AuthAnimatedLogoState();
}

class _AuthAnimatedLogoState extends State<AuthAnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );

  Rect? _fromConsentRect;

  @override
  void initState() {
    super.initState();
    if (widget.enteredFromConsent) {
      _fromConsentRect = ReenMarkHandoff.takeConsent();
      _enter.value = 1;
      return;
    }
    if (widget.settle) {
      _enter.value = 1;
      return;
    }
    _enter.forward();
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) _breathe.repeat();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _breathe.dispose();
    super.dispose();
  }

  double _segment(double t, double a, double b, double from, double to) {
    if (t <= a) return from;
    if (t >= b) return to;
    return from + (to - from) * Curves.easeInOut.transform((t - a) / (b - a));
  }

  @override
  Widget build(BuildContext context) {
    final mark = AuthBrandMark(size: widget.size, showShadow: false);
    if (widget.enteredFromConsent) {
      return _logoFromConsent(context, mark);
    }
    if (widget.settle || MediaQuery.disableAnimationsOf(context)) {
      return _logoWithHalo(context, mark);
    }

    final enterCurve = CurvedAnimation(
      parent: _enter,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([enterCurve, _breathe]),
      builder: (context, child) {
        final e = enterCurve.value;
        final t = _breathe.value;

        final breatheTy = t < 0.30
            ? _segment(t, 0, 0.30, 0, -6)
            : t < 0.60
            ? _segment(t, 0.30, 0.60, -6, -2)
            : _segment(t, 0.60, 1, -2, 0);
        final breatheRot = t < 0.30
            ? _segment(t, 0, 0.30, 0, -3)
            : t < 0.60
            ? _segment(t, 0.30, 0.60, -3, 2.5)
            : _segment(t, 0.60, 1, 2.5, 0);
        final breatheScale = t < 0.30
            ? _segment(t, 0, 0.30, 1, 1.03)
            : t < 0.60
            ? _segment(t, 0.30, 0.60, 1.03, 1.015)
            : _segment(t, 0.60, 1, 1.015, 1);

        return Opacity(
          opacity: e.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, context.dp((1 - e) * -14 + breatheTy)),
            child: Transform.rotate(
              angle: breatheRot * math.pi / 180,
              child: Transform.scale(
                scale: (1.5 + (1 - 1.5) * e) * breatheScale,
                child: child,
              ),
            ),
          ),
        );
      },
      child: _logoWithHalo(context, mark),
    );
  }

  /// Soft blurred mark copy behind the logo (Design `.auth-logo-halo`).
  Widget _logoWithHalo(BuildContext context, Widget mark) {
    final box = context.dp(widget.size);
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: context.dp(11),
            child: Opacity(
              opacity: 0.45,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Transform.scale(
                  scale: 1.02,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcATop,
                    ),
                    child: SvgPicture.asset(
                      _reenMarkAsset,
                      width: box,
                      height: box * (138 / 172),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          mark,
        ],
      ),
    );
  }

  /// Gate → login: FLIP the coral square from the wordmark rect (`dgcEnterLoginFromConsent`).
  Widget _logoFromConsent(BuildContext context, Widget mark) {
    final box = context.dp(widget.size);
    final halo = AeRiseIn(
      delay: const Duration(milliseconds: 220),
      duration: const Duration(milliseconds: 500),
      offsetY: 14,
      child: Opacity(
        opacity: 0.45,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Transform.scale(
            scale: 1.02,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcATop,
              ),
              child: SvgPicture.asset(
                _reenMarkAsset,
                width: box,
                height: box * (138 / 172),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, right: 0, top: context.dp(11), child: halo),
          ReenFlipMark(
            from: _fromConsentRect,
            byHeight: true,
            fadeFrom: 0.4,
            duration: const Duration(milliseconds: 560),
            child: mark,
          ),
        ],
      ),
    );
  }
}

/// `.ae-back`: unified shiny circle — shared [AeBackButton].
class AuthBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AuthBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AeBackButton(
      onPressed: onTap ?? () => Navigator.maybePop(context),
      solidWhite: true,
      forceDarkSurface: true,
    );
  }
}

/// `.dga-ack` checkbox row (purple check variant used on registration).
class AuthCheckRow extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;
  final InlineSpan label;

  const AuthCheckRow({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      // `.dga-ack { gap: 11; padding: 4px 2px }`, `.bx { 22; radius 7;
      // border 2 }`, `.lb { 13.5px }`.
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(2),
          vertical: context.dp(4),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.ease,
              width: context.dp(22),
              height: context.dp(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.dp(7)),
                color: checked ? ScSaasThemeTokens.primary : Colors.transparent,
                border: Border.all(
                  width: context.dp(2),
                  color: checked
                      ? ScSaasThemeTokens.primary
                      : const Color(0xFFD5CFE4),
                ),
              ),
              child: checked
                  ? Icon(Icons.check, size: context.dp(14), color: Colors.white)
                  : null,
            ),
            SizedBox(width: context.dp(11)),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _authText,
                        fontSize: context.dp(13.5),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: _authText,
                        fontSize: context.dp(13.5),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                  children: [label],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String) validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool password;
  final VoidCallback? onValidate;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.password = false,
    this.onValidate,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _focused = false;

  BorderRadius _radius(BuildContext c) =>
      BorderRadius.all(Radius.circular(c.dp(14)));

  @override
  Widget build(BuildContext context) {
    // `.reen-pre .ae-input` — glass fill, white text, coral focus.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: authLabelStyle(context)),
          SizedBox(height: context.dp(8)),
        ],
        Focus(
          skipTraversal: true,
          canRequestFocus: false,
          onFocusChange: (value) => setState(() => _focused = value),
          child: AnimatedContainer(
            duration: _pressColorDuration,
            curve: Curves.ease,
            decoration: BoxDecoration(
              borderRadius: _radius(context),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AerendBergenAuthTokens.orange.withValues(alpha: 0.22),
                        spreadRadius: context.dp(4),
                      ),
                    ]
                  : null,
            ),
            child: TextFormFieldCustom(
              decoration: InputDecoration(
                hintText: widget.hint,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.dp(18),
                  vertical: context.dp(16),
                ),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintStyle: TextStyle(
                  color: const Color(0x80FFFFFF),
                  fontSize: context.dp(15),
                  fontWeight: FontWeight.w400,
                ),
              ),
              useLabelWithBorder: false,
              setError: true,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.dp(15),
                fontWeight: FontWeight.w400,
              ),
              backgroundColor: AerendBergenAuthTokens.glassFill,
              boxBorder: Border.all(
                width: context.dp(1.5),
                color: _focused
                    ? AerendBergenAuthTokens.orange
                    : AerendBergenAuthTokens.glassBorder,
              ),
              radius: context.dp(14),
              textAlignVertical: TextAlignVertical.center,
              controller: widget.controller,
              setPassword: widget.password,
              validator: (value) {
                widget.onValidate?.call();
                return widget.validator(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// `.ae-btn:active { transform: translateY(1px) }` press wrapper —
/// 60ms transform, child handles its own 120ms colour transition.
class AuthPressable extends StatefulWidget {
  final Widget Function(BuildContext context, bool pressed) builder;
  final VoidCallback? onTap;

  const AuthPressable({super.key, required this.builder, this.onTap});

  @override
  State<AuthPressable> createState() => _AuthPressableState();
}

class _AuthPressableState extends State<AuthPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: _pressMoveDuration,
        curve: Curves.ease,
        transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
        child: widget.builder(context, _pressed),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    // Auth surfaces use the Reen pre-club palette.
    final theme = AeThemePalette.reenPreClub;
    return AuthPressable(
      onTap: disabled ? null : onPressed,
      builder: (context, pressed) {
        // `.ae-btn--primary` in customer/app.css → `--ae-shiny-purple` gradient.
        return AnimatedContainer(
          duration: _pressColorDuration,
          curve: Curves.ease,
          width: double.infinity,
          // .ae-btn { height: 56px; border-radius: var(--ae-r-md) }
          height: context.dp(56),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.dp(14)),
            color: disabled ? theme.primaryDisabled : null,
            gradient: disabled
                ? null
                : (pressed
                      ? LinearGradient(
                          begin: theme.shinyGradient.begin,
                          end: theme.shinyGradient.end,
                          colors: [theme.primaryHover, theme.primaryHover],
                        )
                      : theme.shinyGradient),
            boxShadow: disabled ? null : theme.shadowButton,
          ),
          child: isLoading
              ? SizedBox(
                  width: context.dp(22),
                  height: context.dp(22),
                  child: CircularProgressIndicator(
                    strokeWidth: context.dp(2),
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: authButtonTextStyle(context)),
                    if (trailingIcon != null) ...[
                      SizedBox(width: context.dp(8)),
                      Icon(
                        trailingIcon,
                        size: context.dp(17),
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// `.otp-phone` — country-code chip + phone input (Login.jsx OTP phone phase).
class AuthPhoneField extends StatefulWidget {
  final String label;
  final String hint;
  final String dialCode;
  final TextEditingController controller;
  final String? Function(String)? validator;
  final VoidCallback? onChanged;
  final VoidCallback? onDialCodeTap;
  final ValueChanged<String>? onDialCodeChanged;
  final bool showCountryPicker;
  final bool autofocus;

  const AuthPhoneField({
    super.key,
    required this.label,
    required this.hint,
    required this.dialCode,
    required this.controller,
    this.validator,
    this.onChanged,
    this.onDialCodeTap,
    this.onDialCodeChanged,
    this.showCountryPicker = false,
    this.autofocus = false,
  });

  @override
  State<AuthPhoneField> createState() => _AuthPhoneFieldState();
}

class _AuthPhoneFieldState extends State<AuthPhoneField> {
  bool _focused = false;

  BorderRadius _radius(BuildContext c) =>
      BorderRadius.all(Radius.circular(c.dp(14)));

  Future<void> _openCountryPicker() async {
    final elements = myCountryList
        .map(CountryCode.fromJson)
        .toList(growable: false);
    final result = await showDialog<CountryCode>(
      context: context,
      barrierColor: ScSaasThemeTokens.muted.withValues(alpha: 0.45),
      builder: (context) => Center(
        child: Dialog(
          child: SelectionDialog(
            elements,
            const [],
            showFlag: true,
            showCountryOnly: false,
            flagWidth: 28,
            hideSearch: false,
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    final dial = result.dialCode;
    if (dial == null || dial.isEmpty || dial == widget.dialCode) return;
    widget.onDialCodeChanged?.call(dial);
  }

  /// Shared control height so `.cc` chip and phone input stay flush.
  double _controlHeight(BuildContext context) => context.dp(54);

  Widget _buildDialCodeChip() {
    CountryCode? country;
    try {
      country = CountryCode.fromDialCode(widget.dialCode);
    } catch (_) {
      country = null;
    }
    final flagUri = country?.flagUri;

    // Reen `.otp-phone .cc` — same glass plate + height as `.ae-input` on navy.
    final chipRadius = BorderRadius.circular(context.dp(14));
    return Material(
      color: Colors.transparent,
      borderRadius: chipRadius,
      child: InkWell(
        onTap: widget.showCountryPicker
            ? _openCountryPicker
            : widget.onDialCodeTap,
        borderRadius: chipRadius,
        child: Ink(
          height: _controlHeight(context),
          decoration: BoxDecoration(
            color: AerendBergenAuthTokens.glassFill,
            borderRadius: chipRadius,
            border: Border.all(
              width: context.dp(1.5),
              color: AerendBergenAuthTokens.glassBorder,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.dp(14)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showCountryPicker && flagUri != null) ...[
                  Image.asset(
                    flagUri,
                    width: context.dp(22),
                    height: context.dp(16),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        SizedBox(width: context.dp(22), height: context.dp(16)),
                  ),
                  SizedBox(width: context.dp(6)),
                ],
                Text(
                  widget.dialCode.isEmpty ? '+47' : widget.dialCode,
                  style: TextStyle(
                    fontSize: context.dp(15),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (widget.showCountryPicker) ...[
                  SizedBox(width: context.dp(2)),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: context.dp(20),
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controlH = _controlHeight(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: authLabelStyle(context)),
        SizedBox(height: context.dp(8)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // `.otp-phone .cc` — fixed height chip; never Flexible/unbounded.
            _buildDialCodeChip(),
            // .otp-phone { gap: 9px }
            SizedBox(width: context.dp(9)),
            Expanded(
              child: Focus(
                skipTraversal: true,
                canRequestFocus: false,
                onFocusChange: (v) => setState(() => _focused = v),
                child: AnimatedContainer(
                  duration: _pressColorDuration,
                  curve: Curves.ease,
                  height: controlH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: _radius(context),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: AerendBergenAuthTokens.orange.withValues(
                                alpha: 0.22,
                              ),
                              spreadRadius: context.dp(4),
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormFieldCustom(
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.dp(18),
                        vertical: context.dp(14),
                      ),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintStyle: TextStyle(
                        color: const Color(0x80FFFFFF),
                        fontSize: context.dp(15),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    useLabelWithBorder: false,
                    setError: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                    ],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.dp(15),
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                    backgroundColor: AerendBergenAuthTokens.glassFill,
                    boxBorder: Border.all(
                      width: context.dp(1.5),
                      color: _focused
                          ? AerendBergenAuthTokens.orange
                          : AerendBergenAuthTokens.glassBorder,
                    ),
                    radius: context.dp(14),
                    textAlignVertical: TextAlignVertical.center,
                    controller: widget.controller,
                    onChanged: (_) => widget.onChanged?.call(),
                    validator: widget.validator == null
                        ? null
                        : (value) => widget.validator!(value),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `.otp-cells` — digit boxes with current / filled states (Login.jsx).
class AuthOtpCells extends StatelessWidget {
  final String value;
  final int length;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool enabled;

  const AuthOtpCells({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 4,
    this.focusNode,
    this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Pre-club OTP sits on Reen navy — glass cells + coral focus (not white plates).
    final digits = value.replaceAll(RegExp(r'\D'), '');

    return Stack(
      children: [
        Row(
          children: List.generate(length, (i) {
            final filled = i < digits.length;
            final current = enabled && digits.length == i;
            // `.otp-cells { gap: 8 }` / `.cell { height: 54; radius: 13;
            // border: 1.5; font-size: 22; font-weight: 800 }`
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i == length - 1 ? 0 : context.dp(8),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: context.dp(54),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0x24FFFFFF)
                        : AerendBergenAuthTokens.glassFill,
                    borderRadius: BorderRadius.circular(context.dp(13)),
                    border: Border.all(
                      width: context.dp(1.5),
                      color: current
                          ? AerendBergenAuthTokens.orange
                          : filled
                          ? const Color(0x40FFFFFF)
                          : AerendBergenAuthTokens.glassBorder,
                    ),
                    boxShadow: current
                        ? [
                            BoxShadow(
                              color: AerendBergenAuthTokens.orange.withValues(
                                alpha: 0.22,
                              ),
                              spreadRadius: context.dp(3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    filled ? digits[i] : '',
                    style: TextStyle(
                      fontSize: context.dp(22),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (v) => onChanged(v.replaceAll(RegExp(r'\D'), '')),
            ),
          ),
        ),
      ],
    );
  }
}

/// `.otp-done .burst` — green success check after verify.
class AuthSuccessBurst extends StatefulWidget {
  const AuthSuccessBurst({super.key});

  @override
  State<AuthSuccessBurst> createState() => _AuthSuccessBurstState();
}

class _AuthSuccessBurstState extends State<AuthSuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _ctrl,
    curve: const Cubic(0.2, 1.3, 0.4, 1),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `.otp-done .burst { width: 84; height: 84; border-radius: 50% }`
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: context.dp(84),
        height: context.dp(84),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ScSaasThemeTokens.success,
          boxShadow: [
            BoxShadow(
              color: ScSaasThemeTokens.success.withValues(alpha: 0.55),
              blurRadius: context.dp(30),
              offset: Offset(0, context.dp(14)),
              spreadRadius: context.dp(-8),
            ),
          ],
        ),
        child: Icon(
          Icons.check_rounded,
          size: context.dp(34),
          color: Colors.white,
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    // .ae-divider: 1px gray-100 rules both sides, 14px gap, 12px/500 gray-500.
    final textStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _authGray500,
          fontSize: context.dp(12),
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          color: _authGray500,
          fontSize: context.dp(12),
          fontWeight: FontWeight.w500,
        );

    final rule = Expanded(
      child: ColoredBox(
        color: _authHairline,
        child: SizedBox(height: context.dp(1)),
      ),
    );

    return Row(
      children: [
        rule,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dp(14)),
          child: Text(label, style: textStyle),
        ),
        rule,
      ],
    );
  }
}

enum AuthSocialButtonType { vipps, google, apple }

class AuthSocialButton extends StatelessWidget {
  final AuthSocialButtonType type;
  final String label;
  final VoidCallback onTap;

  const AuthSocialButton({
    super.key,
    required this.type,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVipps = type == AuthSocialButtonType.vipps;

    if (isVipps) {
      // .ae-btn--vipps: logo-only, font-size:0 — no text label at all.
      // `.ae-btn` already sets `height: 56`; `.ae-btn--vipps`'s `min-height:52`
      // is a floor that never binds, so all three social buttons are 56.
      return Semantics(
        button: true,
        label: 'Fortsett med Vipps',
        child: AuthPressable(
          onTap: onTap,
          builder: (context, pressed) {
            return AnimatedContainer(
              duration: _pressColorDuration,
              curve: Curves.ease,
              width: double.infinity,
              height: context.dp(56),
              decoration: BoxDecoration(
                // Design: linear-gradient(180deg, #FF7A4D, #FF5B24 52%, #E64A15)
                // + white top inset / dark bottom inset / orange drop glow.
                gradient: pressed
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF25218),
                          Color(0xFFE64A15),
                          Color(0xFFD44312),
                        ],
                        stops: [0.0, 0.52, 1.0],
                      )
                    : _vippsShinyGradient,
                borderRadius: BorderRadius.circular(context.dp(14)),
                border: Border.all(
                  color: const Color(0x29FFFFFF),
                  width: context.dp(1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.45),
                    blurRadius: context.dp(1),
                    offset: Offset(0, context.dp(1)),
                    blurStyle: BlurStyle.inner,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: context.dp(14),
                    offset: Offset(0, context.dp(-8)),
                    spreadRadius: context.dp(-8),
                    blurStyle: BlurStyle.inner,
                  ),
                  BoxShadow(
                    color: const Color(0x8CFF5B24),
                    blurRadius: context.dp(20),
                    offset: Offset(0, context.dp(8)),
                    spreadRadius: context.dp(-6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Image.asset(
                _vippsWordmarkAsset,
                // Design `.ae-btn--vipps`: wordmark at ~34% of button height.
                height: context.dp(56 * 0.34),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'Vipps',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: context.dp(16),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return AuthPressable(
      onTap: onTap,
      builder: (context, pressed) {
        // Reen pre-club: Google + Apple — white shiny plates on navy
        // (same ramp family as email-tab / secondary auth buttons).
        const textColor = Color(0xFF14273F);

        return AnimatedContainer(
          duration: _pressColorDuration,
          curve: Curves.ease,
          width: double.infinity,
          height: context.dp(56),
          decoration: BoxDecoration(
            gradient: pressed
                ? const LinearGradient(
                    begin: Alignment(-0.5, -0.85),
                    end: Alignment(0.5, 0.85),
                    colors: [
                      Color(0xFFF6F8FA),
                      Color(0xFFE9EDF2),
                      Color(0xFFDEE3E9),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  )
                : _socialShinyGradient,
            borderRadius: BorderRadius.circular(context.dp(14)),
            border: Border.all(
              color: const Color(0x1F081626),
              width: context.dp(1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: context.dp(1),
                offset: Offset(0, context.dp(1)),
                blurStyle: BlurStyle.inner,
              ),
              BoxShadow(
                color: const Color(0x29081626),
                blurRadius: context.dp(14),
                offset: Offset(0, context.dp(-8)),
                spreadRadius: context.dp(-8),
                blurStyle: BlurStyle.inner,
              ),
              BoxShadow(
                color: const Color(0x80081626),
                blurRadius: context.dp(20),
                offset: Offset(0, context.dp(8)),
                spreadRadius: context.dp(-6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (type == AuthSocialButtonType.google) ...[
                Image.asset(
                  _googleLogoAsset,
                  width: context.dp(20),
                  height: context.dp(20),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      width: context.dp(20),
                      height: context.dp(20),
                    );
                  },
                ),
                SizedBox(width: context.dp(10)),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: authButtonTextStyle(context, color: textColor),
                  ),
                ),
              ] else ...[
                Image.asset(
                  'assets/images/apple_standard_color.png',
                  width: context.dp(20),
                  height: context.dp(20),
                  color: Colors.black,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.apple,
                      color: Colors.black,
                      size: context.dp(22),
                    );
                  },
                ),
                SizedBox(width: context.dp(10)),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: authButtonTextStyle(context, color: textColor),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // .dg-auth-footer: 13px gray-500; link purple-700 / 700.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prefix,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _authGray500,
                fontSize: context.dp(13),
                fontWeight: FontWeight.w500,
              ) ??
              TextStyle(
                color: _authGray500,
                fontSize: context.dp(13),
                fontWeight: FontWeight.w500,
              ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AerendBergenAuthTokens.orange,
            padding: EdgeInsets.symmetric(horizontal: context.dp(4)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AerendBergenAuthTokens.orange,
                  fontSize: context.dp(13),
                  fontWeight: FontWeight.w700,
                ) ??
                TextStyle(
                  color: AerendBergenAuthTokens.orange,
                  fontSize: context.dp(13),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
