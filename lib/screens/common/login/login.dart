import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commonView/social_login.dart';
import '../../../dialogs/forgotPasswordDialog/forgot_password_dialog.dart';
import '../../../networking/api_constant.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../auth/onboarding_copy.dart';
import '../auth/onboarding_kit.dart';
import '../consent/consent_gate_screen.dart';
import '../consent/reen_flip_mark.dart';
import '../otpVerify/otp_verify.dart';
import 'login_bloc.dart';
import 'vipps_login_helper.dart';

enum _Step { landing, account }

enum _AccountTab { register, login }

/// Onboarding **Landing** + **Konto** — mirrors `onbErLanding` / `onbErKonto`
/// in `Design/Ærend Kunde Bergen (frittstående).html`.
///
/// Landing: Vipps / Google / Apple / e-post. Every method first passes the
/// Vilkår step ([ConsentGateScreen], skipped once accepted), then either
/// signs in with the provider or opens Konto (e-post). Konto registers
/// (stash credentials → [OtpVerify] phone step) or logs in.
class Login extends StatefulWidget {
  final bool returnOnSuccess;

  /// Open straight on Konto (e-post) instead of the landing.
  final bool openEmailForm;

  /// Open Konto on the "Opprett konto" tab.
  final bool startOnRegisterTab;

  /// Kept for call sites from the old consent-first flow; no longer used.
  /// Nullable so a hot-reloaded `Login()` built before it existed is safe.
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  late _Step _step;
  late _AccountTab _tab;

  /// The splash mark's on-screen rect, for the splash → landing FLIP.
  Rect? _splashFrom;

  /// Blocks the screen while a provider login call is running — tied to the
  /// call and always released, so a success that doesn't leave this screen
  /// (session not saved, OTP screen popped back) can't lock it.
  bool _busy = false;

  String _referralNote = '';
  bool _referralSaved = false;

  @override
  void initState() {
    super.initState();
    _bloc = LoginBloc(context, this);
    _step = (widget.openEmailForm || widget.startOnRegisterTab)
        ? _Step.account
        : _Step.landing;
    _tab = widget.startOnRegisterTab ? _AccountTab.register : _AccountTab.login;
    if (_step == _Step.landing) _splashFrom = ReenMarkHandoff.takeSplash();
    final pending = prefGetString(prefPendingReferCode);
    if (pending.isNotEmpty && !_referralFromLink) {
      _referralController.text = pending;
      _referralSaved = true;
      _referralNote = OnbCopy.referralSaved;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _referralController.dispose();
    _bloc.dispose();
    super.dispose();
  }

  bool get _referralFromLink =>
      prefGetBool(prefPendingReferFromLink) &&
      prefGetString(prefPendingReferCode).isNotEmpty;

  bool get _hasReferral => prefGetString(prefPendingReferCode).isNotEmpty;

  // ── Validation (design `regOk` / `loggOk`) ────────────────────────────────

  static final RegExp _emailRe = RegExp(r'.+@.+\..+');

  String get _name => _nameController.text.trim();
  String get _email => _bloc.emailController.text.trim();
  String get _pass => _bloc.passController.text;

  bool get _nameOk => _name.length > 1;
  bool get _emailOk => _emailRe.hasMatch(_email);
  bool get _passOk => _pass.length >= 6;
  bool get _registerOk => _nameOk && _emailOk && _passOk;

  /// Login also accepts a phone number, like the API does.
  bool get _loginIdOk =>
      _email.isNotEmpty && validateEmailOrNumber(_email).isEmpty;
  bool get _loginOk => _loginIdOk && _pass.isNotEmpty;

  // ── Flow ──────────────────────────────────────────────────────────────────

  /// Vilkår step — once per device. True when accepted.
  Future<bool> _ensureTerms() async {
    if (prefGetBool(prefTermsAccepted)) return true;
    final accepted = await Navigator.of(
      context,
    ).push<bool>(buildNavyHandoffRoute<bool>(const ConsentGateScreen()));
    if (!mounted) return false;
    if (accepted == true) return true;
    if (accepted == false && !widget.returnOnSuccess) {
      // Avvis → look around as a guest (design `onbAvvis`).
      openSimpleSnackbar(OnbCopy.declinedToast);
      continueAsGuest(context);
    }
    return false;
  }

  Future<void> _withBusy(Future<void> Function() run) async {
    setState(() => _busy = true);
    try {
      await run();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onVipps() async {
    if (!await _ensureTerms()) return;
    if (!mounted) return;
    VippsLoginHelper.signInWithVipps(
      context,
      onSuccess: (response) async {
        if (!mounted) return;
        await manageLoginResponse(
          context,
          response,
          popOnSuccess: widget.returnOnSuccess,
        );
      },
      onError: (message) => openSimpleSnackbar(message),
    );
  }

  Future<void> _onProvider(Future<SocialAccount?> Function() pick) async {
    if (!await _ensureTerms()) return;
    final account = await pick();
    if (account == null || !mounted) return;
    await _withBusy(
      () => _bloc.login(
        account.loginType,
        account.email,
        account.name,
        account.id,
      ),
    );
  }

  Future<void> _onEmail() async {
    if (!await _ensureTerms()) return;
    if (!mounted) return;
    setState(() {
      _step = _Step.account;
      _tab = _AccountTab.register;
    });
  }

  void _toLanding() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = _Step.landing;
      _splashFrom = null;
    });
  }

  void _onReferralApply() {
    final code = _referralController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _referralSaved = false;
        _referralNote = OnbCopy.referralEmpty;
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    prefSetString(prefPendingReferCode, code);
    prefSetBool(prefPendingReferFromLink, false);
    setState(() {
      _referralController.text = code;
      _referralSaved = true;
      _referralNote = OnbCopy.referralSaved;
    });
  }

  /// "Opprett konto" — stash credentials, then the OTP phone step registers.
  Future<void> _onRegister() async {
    if (!_registerOk) {
      openSimpleSnackbar(OnbCopy.registerMissing);
      return;
    }
    if (!await _ensureTerms()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    await prefSetString(prefEmail, _email);
    await prefSetString(prefPassword, _pass.trim());
    await prefSetString(prefUserName, _name);
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
    Navigator.of(context).push(buildNavyHandoffRoute(const OtpVerify()));
  }

  Future<void> _onLogin() async {
    if (!_loginOk) {
      openSimpleSnackbar(OnbCopy.loginMissing);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await _withBusy(
      () =>
          _bloc.loginApiCall(loginTypeEmail, _email, _pass.trim(), "", "", ""),
    );
  }

  void _onLanguageToggle(bool isNorwegian) {
    final code = isNorwegian ? 'no' : 'en';
    if (resolveSelectedLanguage() == code) return;
    setChangedLanguage(context, code, this);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final onAccount = _step == _Step.account;
    return PopScope(
      canPop: !onAccount || widget.openEmailForm || widget.startOnRegisterTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && onAccount) _toLanding();
      },
      child: OnbScaffold(
        step: onAccount ? 1 : null,
        overlay: [
          if (_busy)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: OnbColors.navy.withValues(alpha: .55),
                  child: const Center(
                    child: CircularProgressIndicator(color: OnbColors.orange),
                  ),
                ),
              ),
            ),
        ],
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: OnbEnter(
            child: onAccount ? _buildAccount(context) : _buildLanding(context),
          ),
        ),
      ),
    );
  }

  // ── Landing ───────────────────────────────────────────────────────────────

  Widget _buildLanding(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final invited = _referralFromLink;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, top + 6, 22, bottom + 26),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OnbLanguagePill(
              isNorwegian: resolveSelectedLanguage() != 'en',
              onChanged: _onLanguageToggle,
            ),
          ),
          const SizedBox(height: 4),
          ReenFlipMark(
            from: _splashFrom,
            duration: const Duration(milliseconds: 620),
            child: const OnbStickerMark(),
          ),
          const SizedBox(height: 8),
          OnbRise(
            delayMs: 100,
            child: Text(
              OnbCopy.landingTitle,
              textAlign: TextAlign.center,
              style: onbDisplay(27, letterSpacingEm: -.035, height: 1.12),
            ),
          ),
          const SizedBox(height: 7),
          OnbRise(
            delayMs: 160,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                OnbCopy.landingSubtitle,
                textAlign: TextAlign.center,
                style: onbText(12.5, height: 1.45, color: OnbColors.subtitle),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AegilSays(asset: OnbAegil.landing, text: OnbCopy.aegilLanding),
          const SizedBox(height: 14),
          if (invited) _buildInviteCard() else _buildReferralInput(),
          const SizedBox(height: 16),
          _buildMethods(),
          const SizedBox(height: 15),
          OnbRise(
            delayMs: 520,
            durationMs: 400,
            child: OnbTextLink(
              label: OnbCopy.withEmail,
              onTap: _onEmail,
              color: Colors.white,
              underline: true,
            ),
          ),
          const SizedBox(height: 12),
          OnbRise(
            delayMs: 580,
            durationMs: 400,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => continueAsGuest(context),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnbIcons.of(OnbIcons.search, 15),
                    const SizedBox(width: 7),
                    Text(
                      OnbCopy.browseFirst,
                      style: onbText(
                        12.5,
                        weight: FontWeight.w800,
                        color: OnbColors.orangeLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opened from a referral link: "Du er vervet · +50 poeng til dere begge".
  Widget _buildInviteCard() {
    return OnbSlap(
      delayMs: 300,
      scales: const [1.7, .96, 1.03, 1],
      degs: const [-14, -4, -6.5, -6],
      child: OnbGlassCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 46,
                color: const Color(0x1FFFFFFF),
                child: Image.asset(OnbAegil.invite, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    OnbCopy.invitedTitle,
                    style: onbDisplay(13.5, letterSpacingEm: -.015),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: OnbColors.mint,
                          shape: BoxShape.circle,
                        ),
                        child: OnbIcons.of(OnbIcons.check('#0F1F2B', 4), 9),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        OnbCopy.invitedPoints,
                        style: onbText(
                          11,
                          weight: FontWeight.w700,
                          color: OnbColors.mintText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// No referral link: optional code + "Bruk".
  Widget _buildReferralInput() {
    final hasText = _referralController.text.trim().length > 3;
    final note = _referralNote.isEmpty ? OnbCopy.referralPrompt : _referralNote;
    return OnbRise(
      durationMs: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: onbPaperShadow(y: 12, blur: 20),
                  ),
                  child: TextField(
                    controller: _referralController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(14)],
                    onChanged: (_) => setState(() {
                      _referralSaved = false;
                      _referralNote = '';
                    }),
                    onSubmitted: (_) => _onReferralApply(),
                    cursorColor: OnbColors.orange,
                    style: onbText(
                      13.5,
                      weight: FontWeight.w800,
                      letterSpacingEm: .02,
                      color: OnbColors.ink,
                    ),
                    decoration: onbBareInput(
                      hint: OnbCopy.referralHint,
                      hintStyle: onbText(
                        13.5,
                        weight: FontWeight.w800,
                        letterSpacingEm: .02,
                        color: OnbColors.placeholder,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OnbPressable(
                onTap: _onReferralApply,
                pressDy: 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: OnbColors.orange.withValues(alpha: hasText ? 1 : .3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(184, 58, 12, .7),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    OnbCopy.referralApply,
                    style: onbText(12.5, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: onbText(
              10.5,
              weight: FontWeight.w700,
              color: _referralSaved
                  ? OnbColors.mintText
                  : const Color(0x80FFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethods() {
    final buttons = <Widget>[
      if (AppFeatureFlags.showVippsLogin) _MethodButton.vipps(onTap: _onVipps),
      _MethodButton.white(
        icon: Image.asset(
          'assets/images/google_standard_color.png',
          width: 18,
          height: 18,
        ),
        label: OnbCopy.continueGoogle,
        onTap: () => _onProvider(pickGoogleAccount),
      ),
      if (Theme.of(context).platform == TargetPlatform.iOS)
        _MethodButton.white(
          icon: const Icon(Icons.apple, size: 19, color: OnbColors.navy),
          label: OnbCopy.continueApple,
          onTap: () => _onProvider(pickAppleAccount),
        ),
    ];
    return Column(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          OnbRise(
            delayMs: 340 + 60.0 * i,
            durationMs: 400,
            child: SizedBox(width: double.infinity, child: buttons[i]),
          ),
        ],
      ],
    );
  }

  // ── Konto ─────────────────────────────────────────────────────────────────

  Widget _buildAccount(BuildContext context) {
    final register = _tab == _AccountTab.register;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, onbTopInset(context), 22, bottom + 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbSegmented(
            labels: [OnbCopy.tabRegister, OnbCopy.tabLogin],
            index: register ? 0 : 1,
            onChanged: (i) => setState(
              () => _tab = i == 0 ? _AccountTab.register : _AccountTab.login,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            register ? OnbCopy.registerTitle : OnbCopy.loginTitle,
            style: onbDisplay(24, letterSpacingEm: -.03),
          ),
          const SizedBox(height: 6),
          Text(
            register ? OnbCopy.registerSubtitle : OnbCopy.loginSubtitle,
            style: onbText(12.5, height: 1.45, color: OnbColors.subtitle),
          ),
          const SizedBox(height: 12),
          AegilSays(
            asset: OnbAegil.account,
            text: OnbCopy.aegilAccount,
            avatarSize: 48,
            avatarRadius: 16,
            bubbleRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            showLabel: false,
            fontSize: 12,
            floorShadow: false,
            delayMs: 160,
          ),
          const SizedBox(height: 18),
          if (register) ..._registerFields() else ..._loginFields(),
          const SizedBox(height: 20),
          OnbTextLink(
            label: OnbCopy.backToLanding,
            onTap: _toLanding,
            size: 12,
            color: const Color(0x73FFFFFF),
          ),
        ],
      ),
    );
  }

  List<Widget> _registerFields() {
    final pass = _pass;
    final strength = pass.length >= 10
        ? 3
        : pass.length >= 6
        ? 2
        : pass.isNotEmpty
        ? 1
        : 0;
    final strengthColor = strength == 3
        ? OnbColors.mint
        : strength == 2
        ? const Color(0xFFF2C14E)
        : OnbColors.error;
    final strengthText = switch (strength) {
      0 => '',
      1 => OnbCopy.strengthShort,
      2 => OnbCopy.strengthOk,
      _ => OnbCopy.strengthStrong,
    };
    final strengthTextColor = strength == 3
        ? OnbColors.mintText
        : strength == 2
        ? const Color(0xFFF2C14E)
        : const Color(0xFFF09578);
    void refresh(String _) => setState(() {});
    return [
      OnbField(
        label: OnbCopy.fullName,
        hint: OnbCopy.fullNameHint,
        icon: OnbIcons.user,
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.name],
        accent: _nameOk ? OnbColors.mintDeep : OnbColors.accentIdle,
        onChanged: refresh,
      ),
      const SizedBox(height: 13),
      OnbField(
        label: OnbCopy.email,
        hint: OnbCopy.emailHint,
        icon: OnbIcons.mail,
        controller: _bloc.emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        accent: _emailOk ? OnbColors.mintDeep : OnbColors.accentIdle,
        onChanged: refresh,
      ),
      const SizedBox(height: 13),
      OnbField(
        label: OnbCopy.password,
        hint: OnbCopy.passwordHintNew,
        icon: OnbIcons.lock,
        controller: _bloc.passController,
        obscure: true,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        accent: _passOk
            ? OnbColors.mintDeep
            : pass.isNotEmpty
            ? OnbColors.orange
            : OnbColors.accentIdle,
        onChanged: refresh,
        onSubmitted: (_) => _onRegister(),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i < strength
                            ? strengthColor
                            : const Color(0x24FFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            strengthText,
            style: onbText(
              10.5,
              weight: FontWeight.w800,
              color: strengthTextColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 13),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(92, 224, 184, .12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromRGBO(92, 224, 184, .3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                OnbAegil.account,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _hasReferral ? OnbCopy.bonusReferral : OnbCopy.bonusOrganic,
                style: onbText(
                  11.5,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: const Color(0xFFCFF3E6),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      OnbCta(
        label: OnbCopy.registerTitle,
        ready: _registerOk,
        onTap: _onRegister,
      ),
      const SizedBox(height: 13),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = _AccountTab.login),
        child: Text.rich(
          TextSpan(
            text: OnbCopy.haveAccount,
            style: onbText(
              12.5,
              weight: FontWeight.w700,
              color: const Color(0x99FFFFFF),
            ),
            children: [
              TextSpan(
                text: OnbCopy.tabLogin,
                style: onbText(
                  12.5,
                  weight: FontWeight.w800,
                  color: OnbColors.orangeLight,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ];
  }

  List<Widget> _loginFields() {
    void refresh(String _) => setState(() {});
    return [
      OnbField(
        label: OnbCopy.email,
        hint: OnbCopy.emailHint,
        icon: OnbIcons.mail,
        controller: _bloc.emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email, AutofillHints.username],
        accent: _loginIdOk ? OnbColors.mintDeep : OnbColors.accentIdle,
        onChanged: refresh,
      ),
      const SizedBox(height: 13),
      OnbField(
        label: OnbCopy.password,
        hint: OnbCopy.passwordHintLogin,
        icon: OnbIcons.lock,
        controller: _bloc.passController,
        obscure: true,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        accent: _pass.isNotEmpty ? OnbColors.mintDeep : OnbColors.accentIdle,
        onChanged: refresh,
        onSubmitted: (_) => _onLogin(),
      ),
      const SizedBox(height: 18),
      OnbCta(
        label: OnbCopy.tabLogin,
        ready: _loginOk,
        loading: _busy,
        onTap: _onLogin,
      ),
      const SizedBox(height: 13),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showForgotPasswordSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              OnbCopy.forgotPassword,
              style: onbText(
                12,
                weight: FontWeight.w800,
                color: OnbColors.orangeLight,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Landing sign-in buttons: orange Vipps, white Google / Apple.
class _MethodButton extends StatelessWidget {
  const _MethodButton._({
    required this.onTap,
    required this.child,
    required this.height,
    required this.gradient,
    required this.shadows,
    required this.pressDy,
    this.insetTop = false,
  });

  factory _MethodButton.vipps({required VoidCallback onTap}) => _MethodButton._(
    onTap: onTap,
    height: 52,
    gradient: kOnbVippsGradient,
    pressDy: 3,
    insetTop: true,
    shadows: [
      const BoxShadow(color: Color(0xFFB83A0C), offset: Offset(0, 2)),
      BoxShadow(
        color: const Color.fromRGBO(233, 92, 44, .95),
        offset: const Offset(0, 14),
        blurRadius: onbBlur(22),
        spreadRadius: -12,
      ),
    ],
    child: Semantics(
      label: 'Fortsett med Vipps',
      child: Text('vipps', style: onbDisplay(21, letterSpacingEm: -.02)),
    ),
  );

  factory _MethodButton.white({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) => _MethodButton._(
    onTap: onTap,
    height: 50,
    pressDy: 2,
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF1ECE4)],
    ),
    shadows: onbPaperShadow(y: 12, blur: 20, lip: .9),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Text(
          label,
          style: onbText(13.5, weight: FontWeight.w800, color: OnbColors.ink),
        ),
      ],
    ),
  );

  final VoidCallback onTap;
  final Widget child;
  final double height;
  final Gradient gradient;
  final List<BoxShadow> shadows;
  final double pressDy;
  final bool insetTop;

  @override
  Widget build(BuildContext context) {
    return OnbPressable(
      onTap: onTap,
      pressDy: pressDy,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: shadows,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (insetTop)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: 1.5,
                        width: double.infinity,
                        child: ColoredBox(color: Color(0x59FFFFFF)),
                      ),
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
