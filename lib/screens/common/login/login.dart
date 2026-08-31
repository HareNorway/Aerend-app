import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../commonView/social_login.dart';
import '../../../dialogs/forgotPasswordDialog/forgot_password_dialog.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_referral_state.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../dugnad/widgets/referral_capture_banner.dart';
import '../../dugnad/widgets/referral_manual_code_field.dart';
import '../auth/auth_style.dart';
import '../otpVerify/otp_verify.dart';
import 'login_bloc.dart';
import 'login_dl.dart';

enum _ReferralUiMode { link, organic }

enum _EmailTab { login, signup }

/// Login — mirrors `ConsumerLogin` (ui_kits/customer/Login.jsx, `.auth-body`).
///
/// Register stays **on this screen** (`.auth-emailtabs` → Opprett konto), then
/// navigates to the OTP phone phase — never the old Create Account / Your
/// Profile screens.
class Login extends StatefulWidget {
  final bool returnOnSuccess;
  final bool openEmailForm;
  final bool startOnRegisterTab;

  /// Nullable so a hot-reloaded `Login()` built before this field existed
  /// does not throw (`Null is not a subtype of bool`).
  final bool? fromConsent;

  const Login({
    super.key,
    this.returnOnSuccess = false,
    this.openEmailForm = false,
    this.startOnRegisterTab = false,
    this.fromConsent = false,
  });

  bool get enteredFromConsent => fromConsent ?? false;

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  late final LoginBloc _bloc;
  late _ReferralUiMode _refMode;
  late bool _emailOpen;
  late _EmailTab _emailTab;

  /// Vipps/Google/Apple have no button of their own to spin — without this the
  /// screen sits dead between the provider sheet closing and the login call
  /// landing. Coral, because `.reen-pre` owns every pre-club surface.
  bool _socialBusy = false;
  StreamSubscription<ApiResponse<LoginPojo>>? _loginSub;

  Duration get _dTitle => widget.enteredFromConsent
      ? const Duration(milliseconds: 140)
      : const Duration(milliseconds: 120);
  Duration get _dSubtitle => widget.enteredFromConsent
      ? const Duration(milliseconds: 200)
      : const Duration(milliseconds: 190);

  @override
  void initState() {
    super.initState();
    _bloc = LoginBloc(context, this);
    _refMode = DugnadReferralState.instance.pending != null
        ? _ReferralUiMode.link
        : _ReferralUiMode.organic;
    _emailOpen = widget.openEmailForm || widget.startOnRegisterTab;
    _emailTab = widget.startOnRegisterTab ? _EmailTab.signup : _EmailTab.login;
    _loginSub = _bloc.subject.listen(_onLoginState);
  }

  /// Hold the loader through a successful response — `manageLoginResponse`
  /// emits `completed` *before* it navigates. Anything else (error, or a
  /// non-1 status that only raises a snackbar) has to release it.
  void _onLoginState(ApiResponse<LoginPojo> response) {
    if (!mounted || !_socialBusy) return;
    if (response.status == Status.loading) return;
    if (response.status == Status.completed && response.data?.status == 1) {
      return;
    }
    setState(() => _socialBusy = false);
  }

  @override
  void dispose() {
    _loginSub?.cancel();
    _bloc.dispose();
    super.dispose();
  }

  Widget _rise(Widget child, Duration delay) {
    return AeRiseIn(
      delay: delay,
      duration: Duration(milliseconds: widget.enteredFromConsent ? 520 : 600),
      offsetY: widget.enteredFromConsent ? 14 : 16,
      child: child,
    );
  }

  Widget _fromConsentRise(Widget child, int delayMs) {
    if (!widget.enteredFromConsent) return child;
    return AeRiseIn(
      delay: Duration(milliseconds: delayMs),
      duration: const Duration(milliseconds: 520),
      offsetY: 14,
      child: child,
    );
  }

  Future<void> _onEmailPrimary() async {
    if (_emailTab == _EmailTab.login) {
      _bloc.manageEmailLogin(loginTypeEmail);
      return;
    }
    // Registrer → Opprett konto: stash credentials, open OTP phone phase.
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_bloc.formKey.currentState!.validate()) return;

    final email = _bloc.emailController.text.trim();
    final pass = _bloc.passController.text.trim();
    final name = email.contains('@') ? email.split('@').first : email;

    await prefSetString(prefEmail, email);
    await prefSetString(prefPassword, pass);
    await prefSetString(prefUserName, name.isEmpty ? 'Bruker' : name);
    await prefSetString(prefContactNumber, '');
    if (prefGetString(prefCountryCode).isEmpty) {
      await prefSetString(prefCountryCode, '+47');
    }
    await prefSetInt(prefUserId, 0);
    await prefSetBool(prefOTPerror, false);
    if (widget.returnOnSuccess) {
      await prefSetBool(prefAuthReturnOnSuccess, true);
    }
    if (!mounted) return;
    openScreen(context, const OtpVerify());
  }

  // Design px on the 375×812 reference frame. Each is passed through
  // `context.dp()` at the use site so the layout keeps the same proportion of
  // the screen on wider devices — exact at 375, scaled beyond it.
  static const double _headMarginTop = 24; // .auth-head margin-top (inline)
  static const double _logoMarginBottom = 18; // .auth-logo-wrap margin-bottom
  static const double _titleMarginBottom = 8; // .auth-head h1 margin-bottom
  static const double _headMarginBottom = 22; // .auth-head margin-bottom
  static const double _regDemoMarginBottom = 14; // .reg-demo margin-bottom
  // `.auth-methods { margin-top: 18px }` only — the referral widgets already
  // carry `.reg-invite`/`.reg-organic`'s own 16px bottom margin internally.
  static const double _methodsMarginTop = 18;
  static const double _methodsGap = 11; // .auth-methods gap
  // .auth-methods gap + .auth-email-link margin-top 2 / .auth-email-form 4.
  static const double _methodsToEmailLink = _methodsGap + 2;
  static const double _methodsToEmailForm = _methodsGap + 4;
  static const double _guestMarginTop = 14; // .auth-guest margin-top

  void _onLanguageToggle(bool isNorwegian) {
    final code = isNorwegian ? 'no' : 'en';
    if (resolveSelectedLanguage() == code) return;
    setChangedLanguage(context, code, this);
  }

  @override
  Widget build(BuildContext context) {
    final isNorwegian = resolveSelectedLanguage() == 'no';
    return AuthScaffold(
      // Top-right language pill — mirrors design lang toggle (NO | EN).
      overlay: [
        Positioned(
          top: context.dp(8),
          right: context.dp(16),
          child: _AuthLanguageToggle(
            isNorwegian: isNorwegian,
            onChanged: _onLanguageToggle,
          ),
        ),
        if (_socialBusy)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: ReenPreClubTokens.navy.withValues(alpha: 0.72),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: ReenPreClubTokens.coral,
                  ),
                ),
              ),
            ),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: context.dp(_headMarginTop)),
          AuthAnimatedLogo(fromConsent: widget.enteredFromConsent),
          SizedBox(height: context.dp(_logoMarginBottom)),
          _rise(
            Text(
              languages.dgAuthLoginTitle,
              textAlign: TextAlign.center,
              style: authTitleStyle(context),
            ),
            _dTitle,
          ),
          SizedBox(height: context.dp(_titleMarginBottom)),
          _rise(
            Center(
              child: ConstrainedBox(
                // .auth-head p { max-width: 30ch } ≈ 268px at 14px
                constraints: BoxConstraints(maxWidth: context.dp(268)),
                child: Text(
                  languages.dgAuthLoginSubtitle,
                  textAlign: TextAlign.center,
                  style: authSubtitleStyle(context),
                ),
              ),
            ),
            _dSubtitle,
          ),
          SizedBox(height: context.dp(10)),
          _rise(_buildAerendByline(context), const Duration(milliseconds: 220)),
          SizedBox(height: context.dp(_headMarginBottom - 10)),
          _fromConsentRise(_buildRegDemoTabs(context), 260),
          SizedBox(height: context.dp(_regDemoMarginBottom)),
          _fromConsentRise(
            _refMode == _ReferralUiMode.link
                ? const ReferralCaptureBanner()
                : const ReferralManualCodeField(),
            310,
          ),
          SizedBox(height: context.dp(_methodsMarginTop)),
          SocialLogin(
            spacing: context.dp(_methodsGap),
            wrapButton: widget.enteredFromConsent
                ? (child, index) => AeRiseIn(
                    delay: Duration(milliseconds: 360 + index * 50),
                    duration: const Duration(milliseconds: 520),
                    offsetY: 14,
                    child: child,
                  )
                : null,
            function:
                ({String? email, String? name, String? id, String? loginType}) {
                  setState(() => _socialBusy = true);
                  _bloc.login(loginType!, email ?? "", name ?? "", id ?? "");
                },
          ),
          SizedBox(
            height: context.dp(
              _emailOpen ? _methodsToEmailForm : _methodsToEmailLink,
            ),
          ),
          _fromConsentRise(
            _emailOpen ? _buildEmailForm(context) : _buildEmailLink(context),
            410,
          ),
          SizedBox(height: context.dp(_guestMarginTop)),
          _fromConsentRise(_buildGuestLink(context), 460),
          // No Spacer / bottom group on the start view — `.auth-guest` is the
          // last element in the scroll body and SafeArea absorbs the inset.
        ],
      ),
    );
  }

  Widget _buildRegDemoTabs(BuildContext context) {
    final linkSelected = _refMode == _ReferralUiMode.link;

    Widget tab(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            // .reg-demo button { padding: 9px 8px }
            padding: EdgeInsets.symmetric(
              vertical: context.dp(9),
              horizontal: context.dp(8),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                // .reg-demo button { font-size: 12.5px; font-weight: 800 }
                fontSize: context.dp(12.5),
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: context.dp(12.5) * -0.01,
                color: selected ? Colors.white : const Color(0x8CFFFFFF),
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
    }

    // `.reen-pre .reg-demo` — dark glass track, coral sliding thumb.
    return IntrinsicHeight(
      child: Container(
        padding: EdgeInsets.all(context.dp(4)),
        decoration: BoxDecoration(
          color: const Color(0x38000000),
          borderRadius: BorderRadius.circular(context.dp(13)),
          border: Border.all(color: const Color(0x1AFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: const Cubic(0.4, 0, 0.2, 1),
                alignment: linkSelected
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: ReenPreClubTokens.regDemoThumb,
                      borderRadius: BorderRadius.circular(context.dp(10)),
                      boxShadow: [
                        BoxShadow(
                          color: ReenPreClubTokens.coral.withValues(
                            alpha: 0.45,
                          ),
                          blurRadius: context.dp(12),
                          offset: Offset(0, context.dp(4)),
                          spreadRadius: context.dp(-4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                tab(
                  languages.dgAuthViaReferralLink,
                  linkSelected,
                  () => setState(() => _refMode = _ReferralUiMode.link),
                ),
                tab(
                  languages.dgAuthOrganic,
                  !linkSelected,
                  () => setState(() => _refMode = _ReferralUiMode.organic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAerendByline(BuildContext context) {
    final mark = context.dp(19);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Design `.auth-by svg` — purple Æ tile with white strokes.
        ClipRRect(
          borderRadius: BorderRadius.circular(context.dp(5)),
          child: SvgPicture.string(
            ReenPreClubTokens.aerendByMarkSvg,
            width: mark,
            height: mark,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: context.dp(8)),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: context.dp(12.5),
              fontWeight: FontWeight.w600,
              color: const Color(0x99FFFFFF),
            ),
            children: [
              const TextSpan(text: 'et konsept av '),
              TextSpan(
                text: 'Ærend',
                style: TextStyle(
                  fontSize: context.dp(12.5),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xDBFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `.auth-email-link` — 13.5px / 700 / gray-500 / underlined, self-centred.
  Widget _buildEmailLink(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => setState(() => _emailOpen = true),
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(context.dp(4)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          languages.dgAuthEmailToggle,
          style: TextStyle(
            fontSize: context.dp(13.5),
            fontWeight: FontWeight.w700,
            color: const Color(0xE6FFFFFF),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xE6FFFFFF),
          ),
        ),
      ),
    );
  }

  /// `.auth-email-form { gap: 12; background: gray-50; radius: 16; pad: 14 }`
  Widget _buildEmailForm(BuildContext context) {
    final isSignup = _emailTab == _EmailTab.signup;
    final gap = SizedBox(height: context.dp(12));
    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1AFFFFFF), Color(0x09FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: ReenPreClubTokens.glassBorder),
      ),
      child: Form(
        key: _bloc.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailTabs(context),
            gap,
            AuthField(
              label: languages.email,
              hint: languages.authEnterEmailOrNumber,
              controller: _bloc.emailController,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmailOrNumber,
              onValidate: _bloc.buttonHide,
            ),
            gap,
            AuthField(
              label: languages.password,
              hint: languages.authEnterPassword(
                languages.password.toLowerCase(),
              ),
              controller: _bloc.passController,
              textInputAction: TextInputAction.done,
              password: true,
              validator: (value) {
                if (value.trim().isEmpty) return languages.enterPass;
                return "";
              },
              onValidate: _bloc.buttonHide,
            ),
            gap,
            StreamBuilder<bool>(
              stream: _bloc.submitValid,
              builder: (context, snapshot) {
                final isEnable = snapshot.data ?? false;
                return StreamBuilder<ApiResponse<LoginPojo>>(
                  stream: _bloc.subject,
                  builder: (context, snapLoading) {
                    final isLoading =
                        snapLoading.hasData &&
                        snapLoading.data?.status == Status.loading;
                    return AuthPrimaryButton(
                      label: isSignup ? kAoCreateAccountCta : languages.login,
                      isLoading: isLoading,
                      useDugnadTheme: false,
                      onPressed: (isLoading || !isEnable)
                          ? null
                          : _onEmailPrimary,
                    );
                  },
                );
              },
            ),
            // .auth-forgot { margin-top: -4 } against the form's 12px gap.
            if (!isSignup)
              Padding(
                padding: EdgeInsets.only(top: context.dp(12 - 4)),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => showForgotPasswordSheet(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      languages.forgotPass,
                      style: authLabelStyle(context).copyWith(
                        color: ReenPreClubTokens.coral,
                        fontSize: context.dp(13),
                        fontWeight: FontWeight.w700,
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

  /// `.auth-emailtabs` — white selected pill + coral label (Design Reen).
  Widget _buildEmailTabs(BuildContext context) {
    final selectedLogin = _emailTab == _EmailTab.login;

    Widget tab(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(context.dp(8)),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: context.dp(13),
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: selected
                    ? ReenPreClubTokens.coral
                    : const Color(0x8CFFFFFF),
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Container(
        padding: EdgeInsets.all(context.dp(4)),
        decoration: BoxDecoration(
          color: const Color(0x38000000),
          borderRadius: BorderRadius.circular(context.dp(11)),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: const Cubic(0.4, 0, 0.2, 1),
                alignment: selectedLogin
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.5, -0.85),
                        end: Alignment(0.5, 0.85),
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF6F8FA),
                          Color(0xFFE9EDF2),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(context.dp(8)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x66000000),
                          blurRadius: context.dp(8),
                          offset: Offset(0, context.dp(3)),
                          spreadRadius: context.dp(-3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                tab(
                  languages.login,
                  selectedLogin,
                  () => setState(() => _emailTab = _EmailTab.login),
                ),
                tab(
                  languages.register,
                  !selectedLogin,
                  () => setState(() => _emailTab = _EmailTab.signup),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// `.auth-guest` — width 100% / padding 14 / gap 7.
  Widget _buildGuestLink(BuildContext context) {
    return TextButton(
      onPressed: () => continueAsGuest(context),
      style: TextButton.styleFrom(
        foregroundColor: ReenPreClubTokens.coral,
        minimumSize: const Size.fromHeight(0),
        padding: EdgeInsets.all(context.dp(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: context.dp(15)),
          SizedBox(width: context.dp(7)),
          Text(
            languages.dgAuthBrowseFirst,
            style: TextStyle(
              fontSize: context.dp(14),
              fontWeight: FontWeight.w800,
              letterSpacing: context.dp(14) * -0.01,
              color: ReenPreClubTokens.coral,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact NO | EN pill — top-right on Login (Design `.ae-lang` on navy).
class _AuthLanguageToggle extends StatelessWidget {
  final bool isNorwegian;
  final ValueChanged<bool> onChanged;

  const _AuthLanguageToggle({
    required this.isNorwegian,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Language',
      child: Container(
        padding: EdgeInsets.all(context.dp(3)),
        decoration: BoxDecoration(
          color: const Color(0x38000000),
          borderRadius: BorderRadius.circular(context.dp(20)),
          border: Border.all(color: const Color(0x47000000)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: const Cubic(0.4, 0, 0.2, 1),
                  alignment: isNorwegian
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.dp(16)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x33000000),
                            blurRadius: context.dp(3),
                            offset: Offset(0, context.dp(1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _chip(context, 'NO', isNorwegian, () => onChanged(true)),
                  _chip(context, 'EN', !isNorwegian, () => onChanged(false)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(10),
          vertical: context.dp(6),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: context.dp(11),
            fontWeight: FontWeight.w800,
            letterSpacing: context.dp(11) * 0.04,
            height: 1.1,
            color: selected ? ReenPreClubTokens.coral : const Color(0x8CFFFFFF),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

const String kAoCreateAccountCta = 'Opprett konto'; // TODO(l10n)
