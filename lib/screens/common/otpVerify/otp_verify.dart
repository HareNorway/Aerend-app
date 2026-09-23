import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/screens/common/splash/splash.dart';

import '../../../blocs/bloc.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import '../auth/onboarding_copy.dart';
import '../auth/onboarding_kit.dart';
import '../splash/splash_sticker_painter.dart';
import 'otp_verify_bloc.dart';

/// Onboarding **Telefon** → **Kode** → **Ferdig** — mirrors `onbErTelefon`,
/// `onbErKode` and `onbErFerdig` in
/// `Design/Ærend Kunde Bergen (frittstående).html`.
///
/// Inputs come from prefs: an empty [prefContactNumber] starts on the phone
/// step; `prefUserId <= 0` means this is a new registration (the phone step
/// calls `register`), which also ends on the Ferdig welcome. Verifying an
/// existing account skips Ferdig and continues straight on.
class OtpVerify extends StatefulWidget {
  const OtpVerify({super.key});

  @override
  State<StatefulWidget> createState() => _OtpVerifyState();
}

enum _OtpPhase { phone, code, done }

class _OtpVerifyState extends State<OtpVerify> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();
  OtpVerifyBloc? bloc;

  _OtpPhase _phase = _OtpPhase.code;
  String _selectedDialCode = '+47';

  /// Registration (vs re-verifying an existing account) — decides Ferdig.
  late final bool _isRegistration;

  int _codeShake = 0;
  StreamSubscription<ApiResponse>? _verifySub;
  Timer? _autoVerify;

  static const int _resendSeconds = 35;
  int _secondsLeft = _resendSeconds;
  Timer? _resendTimer;

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
        if (_secondsLeft == 0) timer.cancel();
      });
    });
  }

  String get _dialCode {
    final stored = prefGetString(prefCountryCode).trim();
    if (stored.isNotEmpty) return stored;
    return _selectedDialCode.trim().isNotEmpty
        ? _selectedDialCode
        : defaultCountryCode.dialCode!;
  }

  String get _phoneDisplay {
    final n = prefGetString(prefContactNumber);
    if (n.isEmpty) return '$_dialCode ${OnbCopy.phoneHint}';
    return '$_dialCode $n';
  }

  String get _phoneDigits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool get _phoneOk => _phoneDigits.length >= 8;

  @override
  void initState() {
    super.initState();
    var stored = prefGetString(prefCountryCode).trim();
    if (stored.isEmpty) {
      stored = defaultCountryCode.dialCode!;
      prefSetString(prefCountryCode, stored);
    }
    _selectedDialCode = stored;
    _isRegistration = prefGetInt(prefUserId) <= 0;
    final needsPhone = prefGetString(prefContactNumber).isEmpty;
    _phase = needsPhone ? _OtpPhase.phone : _OtpPhase.code;
  }

  @override
  void didChangeDependencies() {
    if (bloc == null) {
      bloc = OtpVerifyBloc(context, this);
      _verifySub = bloc!.subjectVerify.listen(_onVerifyState);
      if (!(_phase == _OtpPhase.phone) && isDemoApp) {
        _setCode('1234');
      }
      if (_phase == _OtpPhase.code) {
        _startResendCountdown();
      }
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _autoVerify?.cancel();
    _verifySub?.cancel();
    otpFocusNode.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    bloc?.dispose();
    super.dispose();
  }

  /// Wrong code → shake the cells and start over (design `onbKodeRist`).
  void _onVerifyState(ApiResponse response) {
    if (!mounted || response.status != Status.error) return;
    setState(() => _codeShake++);
    _setCode('');
  }

  void _setCode(String v) {
    _otpController.text = v;
    bloc?.changeOtp(v);
  }

  void _onCodeChanged(String v) {
    bloc?.changeOtp(v);
    setState(() {});
    _autoVerify?.cancel();
    if (v.length == 4) {
      // The design confirms by itself shortly after the fourth digit.
      _autoVerify = Timer(const Duration(milliseconds: 320), () {
        if (mounted && _otpController.text.length == 4) _confirm();
      });
    }
  }

  bool get _verifying =>
      bloc?.subjectVerify.valueOrNull?.status == Status.loading;

  void _confirm() {
    if (_verifying) return;
    if (_otpController.text.length < 4) {
      openSimpleSnackbar(OnbCopy.codeMissing);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    bloc?.verify(onSuccess: _onVerified);
  }

  void _onVerified() {
    if (!mounted) return;
    if (_isRegistration) {
      setState(() => _phase = _OtpPhase.done);
    } else {
      bloc?.finishAfterSuccess();
    }
  }

  void _sendCode() {
    if (!_phoneOk) {
      openSimpleSnackbar(OnbCopy.phoneMissing);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    bloc?.submitPhone(
      phone: _phoneDigits,
      dialCode: _dialCode,
      onReady: () {
        setState(() {
          _phase = _OtpPhase.code;
          _selectedDialCode = _dialCode;
        });
        _setCode(isDemoApp ? '1234' : '');
        _startResendCountdown();
      },
    );
  }

  void _resend() {
    if (_secondsLeft > 0 || _verifying) return;
    bloc?.resendOtp();
    _startResendCountdown();
  }

  /// "Endre telefonnummer" — back to the phone step (design); submitting
  /// again goes through the change-number API for the existing user.
  void _changeNumber() {
    _autoVerify?.cancel();
    _resendTimer?.cancel();
    _setCode('');
    _phoneController.text = prefGetString(prefContactNumber);
    setState(() => _phase = _OtpPhase.phone);
  }

  Future<void> _pickDialCode() async {
    final dial = await onbPickDialCode(context);
    if (!mounted || dial == null || dial == _selectedDialCode) return;
    setState(() => _selectedDialCode = dial);
    prefSetString(prefCountryCode, dial);
  }

  void _finish() {
    prefSetString(prefPendingReferCode, '');
    prefSetBool(prefPendingReferFromLink, false);
    bloc?.finishAfterSuccess();
  }

  void _onBack() {
    if (_phase == _OtpPhase.done) {
      _finish();
      return;
    }
    prefSetInt(prefUserId, 0);
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(false);
    } else {
      openScreenWithClearPrevious(context, const Splash());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: OnbScaffold(
        step: _phase == _OtpPhase.done ? 3 : 2,
        child: KeyedSubtree(
          key: ValueKey(_phase),
          child: OnbEnter(
            child: switch (_phase) {
              _OtpPhase.phone => _buildPhone(context),
              _OtpPhase.code => _buildCode(context),
              _OtpPhase.done => _Ferdig(onStart: _finish),
            },
          ),
        ),
      ),
    );
  }

  /// Fixed-height step: scrolls only when the keyboard needs the room.
  Widget _stepBody(BuildContext context, List<Widget> children) {
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
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhone(BuildContext context) {
    final digits = _phoneDigits;
    final accent = _phoneOk
        ? OnbColors.mintDeep
        : digits.isNotEmpty
        ? OnbColors.orange
        : OnbColors.accentIdle;
    return _stepBody(context, [
      const Center(
        child: AegilAvatar(asset: OnbAegil.phone, size: 96, radius: 28),
      ),
      const SizedBox(height: 14),
      Text(
        OnbCopy.phoneTitle,
        textAlign: TextAlign.center,
        style: onbDisplay(24, letterSpacingEm: -.03),
      ),
      const SizedBox(height: 6),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Text(
            OnbCopy.phoneSubtitle,
            textAlign: TextAlign.center,
            style: onbText(12.5, color: OnbColors.subtitle),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          OnbPressable(
            onTap: _pickDialCode,
            pressDy: 2,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                boxShadow: onbPaperShadow(spread: -16),
              ),
              child: Text(
                '${onbFlagFor(_selectedDialCode)} $_selectedDialCode'.trim(),
                style: onbText(14, weight: FontWeight.w800, color: OnbColors.ink),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: OnbField(
              label: OnbCopy.phoneLabel,
              hint: OnbCopy.phoneHint,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                LengthLimitingTextInputFormatter(12),
              ],
              inputStyle: onbText(
                16,
                weight: FontWeight.w800,
                letterSpacingEm: .04,
                color: OnbColors.ink,
              ),
              accent: accent,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendCode(),
            ),
          ),
        ],
      ),
      StreamBuilder<ApiResponse>(
        stream: bloc?.subjectSend,
        builder: (context, snap) {
          final err = snap.data?.status == Status.error
              ? snap.data?.message
              : null;
          if (err == null || err.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              err,
              textAlign: TextAlign.center,
              style: onbText(
                12.5,
                weight: FontWeight.w700,
                color: const Color(0xFFF09578),
              ),
            ),
          );
        },
      ),
      const Expanded(child: SizedBox(height: 12)),
      StreamBuilder<ApiResponse>(
        stream: bloc?.subjectSend,
        builder: (context, snap) => OnbCta(
          label: OnbCopy.sendCode,
          ready: _phoneOk,
          loading: snap.data?.status == Status.loading,
          onTap: _sendCode,
        ),
      ),
      const SizedBox(height: 8),
      OnbTextLink(label: OnbCopy.back, onTap: _onBack),
    ]);
  }

  Widget _buildCode(BuildContext context) {
    final code = _otpController.text;
    return _stepBody(context, [
      const Center(
        child: AegilAvatar(asset: OnbAegil.code, size: 84, radius: 26),
      ),
      const SizedBox(height: 12),
      Text(
        OnbCopy.codeTitle,
        textAlign: TextAlign.center,
        style: onbDisplay(25, letterSpacingEm: -.03),
      ),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          text: OnbCopy.codeSentTo,
          style: onbText(12.5, color: OnbColors.subtitle),
          children: [
            TextSpan(
              text: _phoneDisplay,
              style: onbText(12.5, weight: FontWeight.w800),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      if (isDemoApp) ...[
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x4D000000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x24FFFFFF)),
            ),
            child: Text.rich(
              TextSpan(
                text: OnbCopy.codeDemo,
                style: onbText(
                  11.5,
                  weight: FontWeight.w700,
                  color: const Color(0xB8FFFFFF),
                ),
                children: [
                  TextSpan(
                    text: '1234',
                    style: onbText(
                      11.5,
                      weight: FontWeight.w800,
                      letterSpacingEm: .1,
                      color: OnbColors.orangeLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 24),
      OnbShake(
        trigger: _codeShake,
        child: _CodeCells(
          controller: _otpController,
          focusNode: otpFocusNode,
          error: _codeShake > 0 && code.isEmpty,
          enabled: !_verifying,
          onChanged: _onCodeChanged,
        ),
      ),
      const SizedBox(height: 22),
      StreamBuilder<ApiResponse>(
        stream: bloc?.subjectVerify,
        builder: (context, snap) => OnbCta(
          label: OnbCopy.confirm,
          ready: code.length == 4,
          loading: snap.data?.status == Status.loading,
          onTap: _confirm,
        ),
      ),
      const SizedBox(height: 10),
      OnbTextLink(
        label: _secondsLeft > 0
            ? OnbCopy.resendIn(_secondsLeft)
            : OnbCopy.resend,
        onTap: _secondsLeft > 0 ? null : _resend,
        size: 12,
        color: _secondsLeft > 0
            ? const Color(0x73FFFFFF)
            : OnbColors.orangeLight,
      ),
      const SizedBox(height: 4),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _verifying ? null : _changeNumber,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnbIcons.of(OnbIcons.pencil, 14),
              const SizedBox(width: 7),
              Text(
                OnbCopy.changeNumber,
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
      const Expanded(child: SizedBox.shrink()),
    ]);
  }
}

/// Four 62×70 code cells over a hidden input.
class _CodeCells extends StatelessWidget {
  const _CodeCells({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.error,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? focusNode.requestFocus : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 11),
                _cell(i, code),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                showCursor: false,
                enableInteractiveSelection: false,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(int i, String code) {
    final filled = i < code.length;
    final current = i == code.length;
    final border = error
        ? OnbColors.error
        : filled
        ? OnbColors.orange
        : current
        ? OnbColors.orange.withValues(alpha: .55)
        : const Color(0x2EFFFFFF);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 62,
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? OnbColors.orange.withValues(alpha: .16)
            : const Color(0x47000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.5),
        boxShadow: current && !filled
            ? [
                BoxShadow(
                  color: OnbColors.orange.withValues(alpha: .14),
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: filled
          ? _Popp(
              key: ValueKey('$i${code[i]}'),
              child: Text(code[i], style: onbDisplay(28)),
            )
          : null,
    );
  }
}

/// `popp` — a digit landing in its cell.
class _Popp extends StatelessWidget {
  const _Popp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: 340,
    child: child,
    builder: (context, t, child) => Transform.scale(
      scale: onbKf(
        onbP(t, 0, 340),
        const [0, .35, .7, 1],
        const [1, 1.16, .96, 1],
        const Cubic(.34, 1.56, .64, 1),
      ),
      child: child,
    ),
  );
}

/// **Ferdig** — the welcome after a new account: sticker slap with confetti,
/// start points counting up, first missions and "Kom i gang".
class _Ferdig extends StatelessWidget {
  const _Ferdig({required this.onStart});

  final VoidCallback onStart;

  // [color, kx, ky, rotation, w, h, round]
  static const _confetti = <List<Object>>[
    [Color(0xFFF26D3D), -52.0, -104.0, 200.0, 9.0, 9.0, false],
    [Color(0xFF5CE0B8), 46.0, -96.0, -160.0, 8.0, 8.0, true],
    [Color(0xFFFFFFFF), -30.0, -118.0, 140.0, 7.0, 12.0, false],
    [Color(0xFFF2C14E), 58.0, -70.0, -220.0, 10.0, 10.0, true],
    [Color(0xFF9C7BE8), 10.0, -128.0, 180.0, 8.0, 8.0, false],
    [Color(0xFFFFFFFF), -66.0, -60.0, -140.0, 6.0, 6.0, true],
  ];

  @override
  Widget build(BuildContext context) {
    final referral = prefGetString(prefPendingReferCode).isNotEmpty;
    final target = referral ? 100 : 50;
    final name = prefGetString(prefUserName).trim();
    final firstName = name.isEmpty
        ? OnbCopy.fallbackFirstName
        : name.split(RegExp(r'\s+')).first;
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
                children: [
                  const SizedBox(height: 14),
                  _hero(),
                  const SizedBox(height: 10),
                  OnbRise(
                    delayMs: 500,
                    child: Text(
                      OnbCopy.welcome(firstName),
                      textAlign: TextAlign.center,
                      style: onbDisplay(26, letterSpacingEm: -.035, height: 1.15),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AegilSays(
                    asset: OnbAegil.done,
                    text: '${OnbCopy.aegilDone} ${OnbCopy.aegilDoneTier}',
                    avatarSize: 52,
                    avatarRadius: 17,
                    bubbleRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    showLabel: false,
                    fontSize: 12,
                    floorShadow: false,
                    delayMs: 600,
                  ),
                  const SizedBox(height: 18),
                  OnbRise(
                    delayMs: 660,
                    child: _points(target, referral),
                  ),
                  const SizedBox(height: 12),
                  _missions(),
                  const Expanded(child: SizedBox(height: 14)),
                  OnbCta(
                    label: OnbCopy.getStarted,
                    onTap: onStart,
                    height: 56,
                    fontSize: 16,
                    dropSpread: -12,
                    pulse: true,
                    trailing: OnbIcons.of(OnbIcons.arrowOut, 17),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return SizedBox(
      width: 180,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 30,
            top: 30,
            width: 120,
            height: 90,
            child: onbBlurred(
              20,
              CustomPaint(
                painter: SplashRadialPainter(
                  center: const Offset(.5, .5),
                  // `circle` = farthest-corner of 120×90 → r 75.
                  radii: const Offset(75 / 120, 75 / 90),
                  colors: [
                    OnbColors.mint.withValues(alpha: .45),
                    OnbColors.mint.withValues(alpha: 0),
                  ],
                  stops: const [0, .68],
                  oval: true,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 118,
            width: 150,
            height: 22,
            child: onbBlurred(
              5,
              const CustomPaint(
                painter: SplashRadialPainter(
                  center: Offset(.5, .5),
                  radii: Offset(.5, .5),
                  colors: [
                    Color.fromRGBO(3, 16, 24, .8),
                    Color.fromRGBO(3, 16, 24, 0),
                  ],
                  stops: [0, .72],
                  oval: true,
                ),
              ),
            ),
          ),
          for (var i = 0; i < _confetti.length; i++) _confettiPiece(i),
          const Positioned(
            left: 15,
            top: 15,
            width: 150,
            height: 120,
            child: OnbSlap(
              delayMs: 100,
              durationMs: 600,
              scales: [1.5, .97, 1.03, 1],
              degs: [-14, -4, -6, -5],
              curve: Cubic(.34, 1.56, .64, 1),
              child: OnbStickerMark(
                width: 150,
                height: 120,
                floatMs: 4400,
                floatDelayMs: 1000,
                sheen: false,
                floorShadow: false,
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 16,
            child: OnbHake(
              delayMs: 550,
              durationMs: 500,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [OnbColors.mint, OnbColors.mintDeep],
                  ),
                  boxShadow: [
                    const BoxShadow(color: Colors.white, spreadRadius: 3),
                    BoxShadow(
                      color: OnbColors.mintDeep.withValues(alpha: .9),
                      offset: const Offset(0, 10),
                      blurRadius: onbBlur(18),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: OnbIcons.of(OnbIcons.check('#0F1F2B', 3.6), 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `onbKonf` — six flecks bursting up from behind the sticker.
  Widget _confettiPiece(int i) {
    final k = _confetti[i];
    final w = k[4] as double;
    final h = k[5] as double;
    final dur = 1000 + i * 80.0;
    final delay = 250 + i * 50.0;
    return Positioned(
      left: 68 + (i % 3) * 8.0,
      top: 64,
      width: w,
      height: h,
      child: OnbTimeline(
        durationMs: delay + dur,
        builder: (context, t, _) {
          final p = onbP(t, delay, dur);
          const curve = Cubic(.2, .7, .4, 1);
          final e = curve.transform(p);
          final o = onbKf(p, const [0, .12, 1], const [0, 1, 0], curve);
          return Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(
                (k[1] as double) * e,
                (k[2] as double) * e,
                0,
              )
                ..rotateZ((k[3] as double) * e * 3.141592653589793 / 180)
                ..multiply(
                  Matrix4.diagonal3Values(.4 + .6 * e, .4 + .6 * e, 1),
                ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: k[0] as Color,
                  borderRadius: BorderRadius.circular(
                    (k[6] as bool) ? 99 : 2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _points(int target, bool referral) {
    // Counts up from 700ms in steps of ⌈target / 8⌉ every 70ms.
    final step = (target / 8).ceil();
    return OnbTimeline(
      durationMs: 700 + 70.0 * 9,
      builder: (context, t, _) {
        final ticks = t < 700 ? 0 : ((t - 700) / 70).floor();
        final points = (ticks * step).clamp(0, target);
        final done = points >= target;
        return OnbGlassCard(
          radius: 22,
          from: .13,
          to: .05,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      OnbCopy.startPoints,
                      style: onbText(
                        11.5,
                        weight: FontWeight.w800,
                        letterSpacingEm: .06,
                        color: OnbColors.mintText,
                      ),
                    ),
                  ),
                  Text(
                    '$points',
                    style: onbDisplay(26, letterSpacingEm: -.03).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0x24FFFFFF)),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 800),
                        curve: const Cubic(.3, .9, .3, 1),
                        alignment: Alignment.centerLeft,
                        widthFactor: points / target,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            gradient: LinearGradient(
                              colors: [OnbColors.mint, OnbColors.mintDeep],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                !done
                    ? OnbCopy.pointsCounting
                    : referral
                    ? OnbCopy.pointsReferral
                    : OnbCopy.pointsOrganic,
                style: onbText(
                  11,
                  weight: FontWeight.w700,
                  color: const Color(0xA6FFFFFF),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _missions() {
    Widget chip(String icon, String label, String points) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Column(
        children: [
          SvgPicture.asset(icon, width: 26, height: 26),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: onbText(9.5, weight: FontWeight.w800, height: 1.25),
          ),
          const SizedBox(height: 6),
          Text(
            points,
            style: onbText(
              9,
              weight: FontWeight.w800,
              color: OnbColors.mintText,
            ),
          ),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: OnbSlap(
            delayMs: 800,
            scales: const [1.7, .96, 1.03, 1],
            degs: const [-14, -4, -6.5, -6],
            child: chip(
              'assets/svgs/onboarding/bag.svg',
              OnbCopy.missionFirst,
              '+50',
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: OnbSlap(
            delayMs: 900,
            scales: const [1.7, .96, 1.03, 1],
            degs: const [12, 3, 4.5, 4],
            child: chip(
              'assets/svgs/onboarding/fish.svg',
              OnbCopy.missionFish,
              '+5',
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: OnbSlap(
            delayMs: 1000,
            scales: const [1.7, .96, 1.03, 1],
            degs: const [-10, -2, -3.5, -3],
            child: chip(
              'assets/svgs/onboarding/cairn.svg',
              OnbCopy.missionRefer,
              '+50',
            ),
          ),
        ),
      ],
    );
  }
}
