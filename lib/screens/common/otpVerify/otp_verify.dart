import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/splash/splash.dart';

import '../../../blocs/bloc.dart';
import '../../../constant/constant.dart';
import '../../../dialogs/editPhoneNumberDialog/edit_phone_number_dialog.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../auth/auth_style.dart';
import 'otp_verify_bloc.dart';

/// OTP — mirrors `ConsumerLogin` OTP view (`ui_kits/customer/Login.jsx`):
/// phases `phone` → `code` → `done` with logo, rise-in, and shiny primary CTA.
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

  // Prototype resend is immediate; keep a short cooldown for API spam safety.
  static const int _resendSeconds = 38;
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
    if (n.isEmpty) return '';
    return '$_dialCode $n';
  }

  @override
  void initState() {
    super.initState();
    var stored = prefGetString(prefCountryCode).trim();
    if (stored.isEmpty) {
      stored = defaultCountryCode.dialCode!;
      prefSetString(prefCountryCode, stored);
    }
    _selectedDialCode = stored;
    final needsPhone = prefGetString(prefContactNumber).isEmpty;
    _phase = needsPhone ? _OtpPhase.phone : _OtpPhase.code;
  }

  @override
  void didChangeDependencies() {
    if (bloc == null) {
      bloc = OtpVerifyBloc(context, this);
      if (!(_phase == _OtpPhase.phone) && isDemoApp) {
        bloc?.changeOtp('1234');
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
    otpFocusNode.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    bloc?.dispose();
    super.dispose();
  }

  Widget _rise(Widget child, int ms) {
    return AeRiseIn(
      delay: Duration(milliseconds: ms),
      duration: const Duration(milliseconds: 600),
      offsetY: 16,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_phase == _OtpPhase.done) {
          bloc?.finishAfterSuccess();
          return;
        }
        prefSetInt(prefUserId, 0);
        openScreenWithClearPrevious(context, const Splash());
      },
      child: AuthScaffold(
        footer: _buildBottom(context),
        // `.ae-back { position: absolute; top: 8; left: 16; z-index: 6 }` —
        // offset from the body's border box, so it sits outside the 24px
        // content padding and must not take part in the column flow.
        overlay: [
          Positioned(
            top: context.dp(8),
            left: context.dp(16),
            child: AuthBackButton(onTap: _onBack),
          ),
        ],
        child: _buildBody(context),
      ),
    );
  }

  void _onBack() {
    if (_phase == _OtpPhase.done) {
      bloc?.finishAfterSuccess();
    } else {
      prefSetInt(prefUserId, 0);
      openScreenWithClearPrevious(context, const Splash());
    }
  }

  Widget _buildBody(BuildContext context) {
    final title = switch (_phase) {
      _OtpPhase.done => kAoOtpDoneTitle,
      _ => kAoOtpConfirmTitle,
    };
    final subtitle = switch (_phase) {
      _OtpPhase.phone => kAoOtpPhoneSubtitle,
      _OtpPhase.code =>
        '$kAoOtpCodeSubtitle ${_phoneDisplay.isEmpty ? '${defaultCountryCode.dialCode} ●●● ●● ●●●' : _phoneDisplay}.',
      _OtpPhase.done => kAoOtpDoneSubtitle,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.auth-head { margin-top: 40 }` (inline override of the 18px
        // default). The back button is absolute, so nothing precedes this.
        SizedBox(height: context.dp(40)),
        _rise(const AuthAnimatedLogo(), 0),
        // .auth-logo-wrap margin-bottom
        SizedBox(height: context.dp(18)),
        _rise(
          Text(
            title,
            textAlign: TextAlign.center,
            style: authTitleStyle(context),
          ),
          120,
        ),
        // .auth-head h1 margin-bottom
        SizedBox(height: context.dp(8)),
        _rise(
          Center(
            child: ConstrainedBox(
              // .auth-head p { max-width: 30ch } ≈ 268px at 14px
              constraints: BoxConstraints(maxWidth: context.dp(268)),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: authSubtitleStyle(context),
              ),
            ),
          ),
          190,
        ),
        // .auth-head margin-bottom 22 + .auth-form inline margin-top 8
        SizedBox(height: context.dp(22 + 8)),
        if (_phase == _OtpPhase.phone) _rise(_buildPhoneForm(context), 260),
        if (_phase == _OtpPhase.code) _rise(_buildCodeForm(context), 260),
        if (_phase == _OtpPhase.done)
          Padding(
            // .otp-done { padding: 24px 0 }
            padding: EdgeInsets.symmetric(vertical: context.dp(24)),
            child: const Center(child: AuthSuccessBurst()),
          ),
      ],
    );
  }

  Widget _buildPhoneForm(BuildContext context) {
    return StreamBuilder<ApiResponse>(
      stream: bloc?.subjectSend,
      builder: (context, snap) {
        final err = snap.hasData && snap.data?.status == Status.error
            ? snap.data?.message
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthPhoneField(
              label: kAoOtpPhoneLabel,
              hint: '400 12 345', // TODO(l10n)
              dialCode: _selectedDialCode,
              controller: _phoneController,
              showCountryPicker: true,
              onDialCodeChanged: (dial) {
                if (dial == _selectedDialCode) return;
                setState(() => _selectedDialCode = dial);
                prefSetString(prefCountryCode, dial);
              },
              onChanged: () => setState(() {}),
              validator: (v) =>
                  validateEmptyField(v, languages.enterMobileNumber),
            ),
            if (err != null && err.isNotEmpty) ...[
              SizedBox(height: context.dp(12)),
              Text(
                err,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ScSaasThemeTokens.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: context.dp(13),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCodeForm(BuildContext context) {
    return StreamBuilder<String>(
      stream: bloc?.otp,
      builder: (context, snap) {
        final otp = snap.data ?? '';
        return StreamBuilder<ApiResponse>(
          stream: bloc?.subjectVerify,
          builder: (context, verifySnap) {
            final verifying = verifySnap.hasData &&
                verifySnap.data?.status == Status.loading;
            final verifyErr =
                verifySnap.hasData && verifySnap.data?.status == Status.error
                    ? verifySnap.data?.message
                    : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(kAoOtpCodeLabel, style: authLabelStyle(context)),
                SizedBox(height: context.dp(8)),
                AuthOtpCells(
                  value: otp,
                  length: 4,
                  controller: _otpController,
                  focusNode: otpFocusNode,
                  enabled: !verifying,
                  onChanged: (v) {
                    bloc?.changeOtp(v);
                  },
                ),
                if (isDemoApp) ...[
                  SizedBox(height: context.dp(10)),
                  Text(
                    languages.enterOtp1234,
                    textAlign: TextAlign.center,
                    style: authSubtitleStyle(context).copyWith(
                      fontSize: context.dp(12.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (verifyErr != null && verifyErr.isNotEmpty) ...[
                  SizedBox(height: context.dp(10)),
                  Text(
                    verifyErr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ScSaasThemeTokens.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: context.dp(13),
                    ),
                  ),
                ],
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: (verifying || _secondsLeft > 0)
                        ? null
                        : () {
                            bloc?.resendOtp();
                            _startResendCountdown();
                          },
                    style: TextButton.styleFrom(
                      // .otp-resend { padding: 10px 2px 0; 13px/800 }
                      padding: EdgeInsets.fromLTRB(
                        context.dp(2),
                        context.dp(10),
                        context.dp(2),
                        0,
                      ),
                      foregroundColor: ReenPreClubTokens.coral,
                      disabledForegroundColor: ReenPreClubTokens.textSoft,
                    ),
                    child: Text(
                      _secondsLeft > 0
                          ? '$kAoOtpResend ($_secondsLeft s)'
                          : kAoOtpResend,
                      style: TextStyle(
                        fontSize: context.dp(13),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: verifying ? null : _changePhoneNumber,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(2),
                      context.dp(4),
                      context.dp(2),
                      0,
                    ),
                    foregroundColor: ReenPreClubTokens.textMuted,
                  ),
                  child: Text(
                    '${languages.change} ${languages.phoneNo.toLowerCase()}',
                    style: TextStyle(
                      fontSize: context.dp(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget? _buildBottom(BuildContext context) {
    // Key by phase so StreamBuilder does not keep a stale `loading` snapshot
    // from subjectSend when switching phone → code (sendOtp races onReady).
    return StreamBuilder<ApiResponse>(
      key: ValueKey(_phase),
      stream: _phase == _OtpPhase.phone
          ? bloc?.subjectSend
          : bloc?.subjectVerify,
      builder: (context, snap) {
        final loading =
            snap.hasData && snap.data?.status == Status.loading;

        if (_phase == _OtpPhase.phone) {
          final digits =
              _phoneController.text.replaceAll(RegExp(r'\D'), '');
          return AuthPrimaryButton(
            label: kAoOtpSendCode,
            isLoading: loading,
            useDugnadTheme: false,
            onPressed: digits.length < 8 || loading
                ? null
                : () => bloc?.submitPhone(
                      phone: digits,
                      dialCode: _dialCode,
                      onReady: () {
                        setState(() {
                          _phase = _OtpPhase.code;
                          _selectedDialCode = _dialCode;
                        });
                        _startResendCountdown();
                        if (isDemoApp) {
                          bloc?.changeOtp('1234');
                          _otpController.text = '1234';
                        }
                      },
                    ),
          );
        }

        if (_phase == _OtpPhase.code) {
          return StreamBuilder<String>(
            stream: bloc?.otp,
            initialData: bloc?.currentOtp ?? '',
            builder: (context, otpSnap) {
              final otp = otpSnap.data ?? '';
              return AuthPrimaryButton(
                label: kAoOtpConfirmCta,
                isLoading: loading,
                useDugnadTheme: false,
                onPressed: otp.length < 4 || loading
                    ? null
                    : () => bloc?.verify(onSuccess: _onVerified),
              );
            },
          );
        }

        // done
        return AuthPrimaryButton(
          label: kAoOtpDoneCta,
          trailingIcon: Icons.arrow_outward_rounded,
          useDugnadTheme: false,
          onPressed: () => bloc?.finishAfterSuccess(),
        );
      },
    );
  }

  void _onVerified() {
    if (!mounted) return;
    setState(() => _phase = _OtpPhase.done);
  }

  void _changePhoneNumber() {
    showEditAuthPhoneSheet(context).then((value) {
      if (value ?? false) {
        bloc?.resendOTPController.add(false);
        bloc?.sendOtp();
        _startResendCountdown();
        setState(() {
          _selectedDialCode = _dialCode;
        });
      }
    });
  }
}

// ── Prototype copy (Login.jsx OTP) ───────────────────────────────────────
const String kAoOtpConfirmTitle = 'Bekreft nummeret ditt'; // TODO(l10n)
const String kAoOtpPhoneSubtitle = 'Vi sender deg en kode på SMS.'; // TODO(l10n)
const String kAoOtpCodeSubtitle = 'Skriv inn koden vi sendte til'; // TODO(l10n)
const String kAoOtpDoneTitle = 'Nummeret er bekreftet'; // TODO(l10n)
const String kAoOtpDoneSubtitle =
    'Du er klar — velkommen til Ærend.'; // TODO(l10n)
const String kAoOtpPhoneLabel = 'Telefonnummer'; // TODO(l10n)
const String kAoOtpCodeLabel = 'Engangskode (SMS)'; // TODO(l10n)
const String kAoOtpSendCode = 'Send kode'; // TODO(l10n)
const String kAoOtpConfirmCta = 'Bekreft'; // TODO(l10n)
const String kAoOtpDoneCta = 'Kom i gang'; // TODO(l10n)
const String kAoOtpResend = 'Send på nytt'; // TODO(l10n)
