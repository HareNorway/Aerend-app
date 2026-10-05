import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../commonView/social_login.dart';
import '../../../../dialogs/forgotPasswordDialog/forgot_password_dialog.dart';
import '../../../../utils/guest_auth_helper.dart';
import '../../../../utils/utils.dart';
import '../../homeMainV1/home_main_v1.dart';
import '../../login/login_dl.dart';
import '../../login/vipps_login_helper.dart';
import '../../splash/splash_sticker_painter.dart';
import 'lf_auth.dart';
import 'lf_copy.dart';
import 'lf_css.dart';
import 'lf_icons.dart';
import 'lf_laster.dart';
import 'lf_motion.dart';
import 'lf_scene.dart';
import 'lf_widgets.dart';
import 'lf_wow.dart';

part 'lf_step_landing.dart';
part 'lf_step_vilkaar.dart';
part 'lf_step_konto.dart';
part 'lf_step_kode.dart';
part 'lf_step_ferdig.dart';

// ── Ærend Kunde Launch · onboarding ─────────────────────────────────────────
// `data-screen-label="Onboarding"` (prototype L1887–2214, logic `onbVals`
// L17460): one surface, the step ladder and the steps landing → vilkår
// (→ vilkårstekst / personvern) → konto → telefon → kode → ferdig, wired to
// the real auth API through [LfAuth]:
//  · Vipps / Google / Apple / e-post first pass Vilkår (as in the prototype);
//  · e-post registers at "Send kode" (`register` + OTP), logs in with
//    `login`; providers use their native sign-in;
//  · a verified account goes straight to Hjem (ring transition); an
//    unverified one continues Telefon → Kode → Ferdig.

enum LfSteg { landing, vilkaar, vilkaarTekst, personvern, konto, telefon, kode, ferdig }

enum LfMetode { vipps, google, apple, epost }

class LaunchOnboarding extends StatefulWidget {
  const LaunchOnboarding({
    super.key,
    this.initial = LfSteg.landing,
    this.returnOnSuccess = false,
    this.loginTab = false,
    this.fromSplash = false,
  });

  final LfSteg initial;

  /// Opened from a guest prompt: pop `true` on success instead of Hjem.
  final bool returnOnSuccess;

  /// Open Konto on "Logg inn".
  final bool loginTab;

  /// Arrived through the splash cross-fade: the landing is already settled
  /// (in the prototype it animated in underneath the splash).
  final bool fromSplash;

  @override
  State<LaunchOnboarding> createState() => LaunchOnboardingState();
}

class LaunchOnboardingState extends State<LaunchOnboarding> {
  final LfAuth _auth = LfAuth();

  late LfSteg _steg = widget.initial;
  LfMetode _metode = LfMetode.epost;

  // Landing
  bool _fane = false; // true = verv
  bool _kodeAapen = false;
  bool _vervOk = false;
  String _vervSvar = '';
  final TextEditingController _verv = TextEditingController();
  bool _en = LfCopy.en;
  bool _knottPop = false;

  // Vilkår
  bool _godtatt = false;
  bool _feil = false;
  int _rist = 0;
  bool _lestV = false;
  bool _lestP = false;

  // Konto
  bool _logg = false;
  final TextEditingController _navn = TextEditingController();
  final TextEditingController _epost = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  // Telefon / Kode
  final TextEditingController _tlf = TextEditingController();
  final TextEditingController _kode = TextEditingController();
  final FocusNode _kodeFokus = FocusNode();
  int _sek = 0;
  Timer? _sekT;

  // Ferdig
  int _poeng = 0;
  Timer? _poengT;
  int _maal = 50;

  bool _busy = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _logg = widget.loginTab;
    if (_steg == LfSteg.konto) _metode = LfMetode.epost;
    final pending = prefGetString(prefPendingReferCode);
    if (pending.isNotEmpty) {
      _verv.text = pending;
      _vervOk = true;
      _vervSvar = LfCopy.vervLagtTil;
    }
    for (final c in [_navn, _epost, _pass, _tlf]) {
      c.addListener(_rebuild);
    }
    if (_steg == LfSteg.kode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendFirstCode());
    }
    if (kDebugMode) _applyHarness();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// setState for the step builders (extensions in the `part` files).
  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  @override
  void dispose() {
    _sekT?.cancel();
    _poengT?.cancel();
    for (final c in [_verv, _navn, _epost, _pass, _tlf, _kode]) {
      c.dispose();
    }
    _kodeFokus.dispose();
    super.dispose();
  }

  // ── Derived ───────────────────────────────────────────────────────────────

  /// Invited through an `/invite?code=` link (`onbInvitert`).
  bool get _inv => prefGetBool(prefPendingReferFromLink) && prefGetString(prefPendingReferCode).isNotEmpty;

  /// The inviter's name from the link (`&from=`); the prototype's "Didrik".
  String get _vervNavn {
    final n = prefGetString(_prefInviterName).trim();
    return n.isEmpty ? (LfCopy.en ? 'A friend' : 'En venn') : n;
  }

  bool get _erVerv => _inv && _fane;
  bool get _vipps => _metode == LfMetode.vipps;

  static final RegExp _epostRe = RegExp(r'.+@.+\..+');
  String get _navnV => _navn.text;
  bool get _navnOk => _navnV.trim().length > 1;
  bool get _epostOk => _epostRe.hasMatch(_epost.text.trim());
  bool get _regOk => _navnOk && _epostOk && _pass.text.length >= 6;
  bool get _loggOk => _epostOk && _pass.text.length >= 4;
  bool get _tlfOk => _tlf.text.replaceAll(RegExp(r'\D'), '').length >= 8;
  String get _kodeV => _kode.text;

  List<String> get _stige => _vipps ? LfCopy.ladderVipps : LfCopy.ladder;

  int? get _stegIdx => _vipps
      ? const {LfSteg.vilkaar: 0, LfSteg.vilkaarTekst: 0, LfSteg.personvern: 0, LfSteg.ferdig: 1}[_steg]
      : const {
          LfSteg.vilkaar: 0,
          LfSteg.vilkaarTekst: 0,
          LfSteg.personvern: 0,
          LfSteg.konto: 1,
          LfSteg.telefon: 2,
          LfSteg.kode: 2,
          LfSteg.ferdig: 3,
        }[_steg];

  bool get _visStige => _stegIdx != null && _steg != LfSteg.vilkaarTekst && _steg != LfSteg.personvern;

  String get _fornavn {
    final n = _navnV.trim().split(' ').first;
    if (n.isNotEmpty) return n;
    final p = prefGetString(prefUserName).trim().split(' ').first;
    return p.isNotEmpty ? p : LfCopy.bergenser;
  }

  // ── Flow ──────────────────────────────────────────────────────────────────

  void _gaa(LfSteg s) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _steg = s;
      _feil = false;
      _gen++;
    });
    if (s == LfSteg.kode) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _steg == LfSteg.kode) _kodeFokus.requestFocus();
      });
    }
  }

  void _si(String text) {
    if (text.trim().isEmpty) return;
    LfToast.show(context, text);
  }

  Future<T> _withBusy<T>(Future<T> Function() run) async {
    setState(() => _busy = true);
    try {
      return await run();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _velgMetode(LfMetode m) {
    setState(() => _metode = m);
    _gaa(LfSteg.vilkaar);
  }

  void _seRundt(String toast) {
    // `onbSeRundt` / `onbAvvis`: the onboarding disappears, Hjem as a guest.
    enterGuestMode();
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, a, b) => const HomeMainV1(isShowDialog: false),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (r) => false,
    );
    _toastOn(nav, toast);
  }

  void _toastOn(NavigatorState nav, String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ov = nav.overlay;
      if (ov != null && ov.mounted) LfToast.show(ov.context, text, overlay: ov);
    });
  }

  Future<void> _godtaFortsett(Rect? from) async {
    if (!_godtatt) {
      setState(() {
        _feil = true;
        _rist++;
      });
      HapticFeedback.mediumImpact();
      return;
    }
    await prefSetBool(prefTermsAccepted, true);
    if (!mounted) return;
    switch (_metode) {
      case LfMetode.epost:
        _gaa(LfSteg.konto);
      case LfMetode.vipps:
        VippsLoginHelper.signInWithVipps(
          context,
          onSuccess: (r) async {
            if (!mounted) return;
            final res = await _auth.establish(r);
            if (!mounted) return;
            if (!res.ok) return _si(res.message);
            await _etterInnlogging(r, from);
          },
          onError: _si,
        );
      case LfMetode.google:
      case LfMetode.apple:
        final pick = _metode == LfMetode.google ? pickGoogleAccount : pickAppleAccount;
        final acc = await pick();
        if (acc == null || !mounted) return;
        final res = await _withBusy(() => _auth.loginSocial(acc.loginType, acc.email, acc.name, acc.id));
        if (!mounted) return;
        if (!res.ok) return _si(res.message);
        await _etterInnlogging(res.value!, from);
    }
  }

  /// After any successful login: a verified account is done (Hjem); an
  /// unverified one confirms its number.
  Future<void> _etterInnlogging(LoginPojo r, Rect? from) async {
    if (r.userVerified == 1) {
      _tilHjem(from, toast: null, coins: false);
      return;
    }
    if (widget.returnOnSuccess) await prefSetBool(prefAuthReturnOnSuccess, true);
    if (prefGetString(prefContactNumber).trim().isEmpty) {
      _gaa(LfSteg.telefon);
    } else {
      _tlf.text = _visTlf(prefGetString(prefContactNumber));
      final sent = await _withBusy(_auth.sendCode);
      if (!mounted) return;
      if (!sent.ok) return _si(sent.message);
      _gaa(LfSteg.kode);
      _startSek();
    }
  }

  Future<void> _sendFirstCode() async {
    _tlf.text = _visTlf(prefGetString(prefContactNumber));
    final sent = await _withBusy(_auth.sendCode);
    if (!mounted) return;
    if (!sent.ok) _si(sent.message);
    _startSek();
  }

  String _visTlf(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 8) return '${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5)}';
    return raw;
  }

  Future<void> _tilTelefon() async {
    if (!_regOk) return _si(LfCopy.regMangler);
    // A fresh registration: `register` runs at "Send kode".
    await prefSetInt(prefUserId, 0);
    await prefSetString(prefAccessToken, '');
    await prefSetBool(prefOTPerror, false);
    if (widget.returnOnSuccess) await prefSetBool(prefAuthReturnOnSuccess, true);
    _gaa(LfSteg.telefon);
  }

  Future<void> _loggInn(Rect? from) async {
    if (!_loggOk) return _si(LfCopy.loggMangler);
    FocusManager.instance.primaryFocus?.unfocus();
    final res = await _withBusy(() => _auth.loginEmail(_epost.text.trim(), _pass.text.trim()));
    if (!mounted) return;
    if (!res.ok) return _si(res.message);
    await _etterInnlogging(res.value!, from);
  }

  Future<void> _sendKode() async {
    if (!_tlfOk) return _si(LfCopy.tlfMangler);
    FocusManager.instance.primaryFocus?.unfocus();
    final phone = _tlf.text.replaceAll(RegExp(r'\D'), '');
    final res = await _withBusy(
      () => _auth.submitPhone(
        phone: phone,
        dial: '+47',
        name: _navnV.trim(),
        email: _epost.text.trim(),
        password: _pass.text.trim(),
      ),
    );
    if (!mounted) return;
    if (!res.ok) return _si(res.message);
    _kode.clear();
    _gaa(LfSteg.kode);
    _startSek();
  }

  void _startSek() {
    _sekT?.cancel();
    setState(() => _sek = 35);
    _sekT = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _sek = math.max(0, _sek - 1));
      if (_sek <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    if (_sek > 0) return;
    final res = await _auth.resend();
    if (!mounted) return;
    if (!res.ok) return _si(res.message);
    _startSek();
  }

  void _skrivKode(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    final s = d.length > 4 ? d.substring(0, 4) : d;
    if (s != v) {
      _kode.value = TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
    }
    setState(() => _feil = false);
    if (s.length == 4) {
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted && _kodeV.length == 4 && _steg == LfSteg.kode && !_busy) _bekreft();
      });
    }
  }

  Future<void> _bekreft() async {
    if (_kodeV.length < 4) return _si(LfCopy.kodeMangler);
    final res = await _withBusy(() => _auth.verify(_kodeV));
    if (!mounted) return;
    if (!res.ok) {
      setState(() {
        _feil = true;
        _rist++;
        _kode.clear();
      });
      HapticFeedback.mediumImpact();
      return _si(res.message);
    }
    _fullfor();
  }

  void _fullfor() {
    _sekT?.cancel();
    final returnToCaller = prefGetBool(prefAuthReturnOnSuccess) || prefGetBool(prefGuestCheckoutResume);
    if (returnToCaller && Navigator.of(context).canPop()) {
      prefSetBool(prefAuthReturnOnSuccess, false);
      Navigator.of(context).pop(true);
      return;
    }
    // UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
    // (The points API has no sign-up bonus; the 50/100 start points are the prototype's.)
    _maal = 50 + ((_erVerv || _vervOk) ? 50 : 0);
    _poeng = 0;
    _gaa(LfSteg.ferdig);
    _poengT?.cancel();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _poengT = Timer.periodic(const Duration(milliseconds: 70), (t) {
        if (!mounted) return t.cancel();
        final n = _poeng + (_maal / 8).ceil();
        setState(() => _poeng = math.min(n, _maal));
        if (_poeng >= _maal) t.cancel();
      });
    });
  }

  /// `onbFerdigFn` / a verified login: Hjem through the ring.
  void _tilHjem(Rect? from, {String? toast, bool coins = true}) {
    if (widget.returnOnSuccess && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    _poengT?.cancel();
    final size = MediaQuery.sizeOf(context);
    final c = from?.center ?? Offset(size.width / 2, size.height * .8);
    HapticFeedback.heavyImpact();
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(
      lfWowRoute(const HomeMainV1(isShowDialog: true), c, coins: coins),
      (r) => false,
    );
    if (toast != null) _toastOn(nav, toast);
  }

  void _sprak(bool no) {
    final code = no ? 'no' : 'en';
    if ((_en ? 'en' : 'no') == code) return;
    setState(() {
      _en = !no;
      _knottPop = true;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _knottPop = false);
    });
    setChangedLanguage(context, code, this, nextAction: () {
      if (mounted) setState(() {});
    });
  }

  void _brukVerv() {
    final k = _verv.text.trim().toUpperCase();
    if (k.isEmpty) {
      setState(() {
        _vervOk = false;
        _vervSvar = LfCopy.vervTom;
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    // No pre-sign-up validation endpoint exists (`refer-code` needs a
    // session and applies the credit at once): the code is kept and sent
    // with `register`, as the app always did.
    prefSetString(prefPendingReferCode, k);
    setState(() {
      _verv.text = k;
      _vervOk = true;
      _vervSvar = LfCopy.vervLagtTil;
    });
  }

  bool _onBack() {
    switch (_steg) {
      case LfSteg.landing:
      case LfSteg.ferdig:
        return true;
      case LfSteg.vilkaar:
        _gaa(LfSteg.landing);
      case LfSteg.vilkaarTekst:
      case LfSteg.personvern:
        _gaa(LfSteg.vilkaar);
      case LfSteg.konto:
        _gaa(LfSteg.landing);
      case LfSteg.telefon:
        _gaa(_vipps ? LfSteg.landing : LfSteg.konto);
      case LfSteg.kode:
        _sekT?.cancel();
        _kode.clear();
        _gaa(LfSteg.telefon);
    }
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// Design px between the status bar and the prototype's frame top (the
  /// prototype has no status bar; its ladder sits at `top:14px`).
  double _inset(BuildContext context) => math.max(0, MediaQuery.paddingOf(context).top - 8);

  @override
  Widget build(BuildContext context) {
    final canPop = _steg == LfSteg.landing && !widget.returnOnSuccess ? true : _steg == LfSteg.landing;
    return PopScope(
      canPop: canPop && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _onBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF2F6270),
          resizeToAvoidBottomInset: false,
          body: LfFrame(
            child: Builder(
              builder: (context) {
                final inset = _inset(context);
                final kb = MediaQuery.viewInsetsOf(context).bottom;
                final idx = _stegIdx;
                return Stack(
                  children: [
                    const Positioned.fill(child: LfSurface()),
                    Positioned.fill(
                      bottom: kb,
                      child: KeyedSubtree(
                        key: ValueKey('steg-$_steg-$_gen'),
                        child: _skipIntro(_buildSteg(context, inset)),
                      ),
                    ),
                    if (_visStige && idx != null)
                      Positioned(
                        left: 14,
                        right: 14,
                        top: inset + 14,
                        child: LfLadder(
                          key: ValueKey('stige-$_vipps'),
                          steps: _stige,
                          index: idx,
                        ),
                      ),
                    if (_busy)
                      Positioned.fill(child: AbsorbPointer(child: LfLaster(text: LfCopy.henter))),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _settled = false;

  /// The first landing after the splash is already settled.
  Widget _skipIntro(Widget child) {
    if (!widget.fromSplash || _settled || _steg != LfSteg.landing) {
      if (_steg != LfSteg.landing) _settled = true;
      return child;
    }
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: _UnsettleAfter(
        onDone: () {
          if (!mounted) return;
          setState(() => _settled = true);
        },
        child: child,
      ),
    );
  }

  Widget _buildSteg(BuildContext context, double inset) {
    switch (_steg) {
      case LfSteg.landing:
        return _landing(context, inset);
      case LfSteg.vilkaar:
        return LfStepIn(child: _vilkaar(context, inset));
      case LfSteg.vilkaarTekst:
      case LfSteg.personvern:
        return LfStepIn(dur: 300, child: _tekst(context, inset));
      case LfSteg.konto:
        return LfStepIn(child: _konto(context, inset));
      case LfSteg.telefon:
        return LfStepIn(child: _telefon(context, inset));
      case LfSteg.kode:
        return LfStepIn(child: _kodeSteg(context, inset));
      case LfSteg.ferdig:
        return LfOnce(
          ms: 300,
          builder: (context, t, child) => Opacity(opacity: cssEaseOut.transform(kfP(t, 0, 300)), child: child),
          child: _ferdig(context, inset),
        );
    }
  }

  // ── Debug harness ─────────────────────────────────────────────────────────
  // Debug builds only: `Documents/lf_state.json` presets a step and its
  // fields, so each state can be screenshotted against the prototype
  // without sending SMS or creating accounts. Ignored in release.

  Future<void> _applyHarness() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/lf_state.json');
      if (!await f.exists()) return;
      final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        if (m['metode'] != null) _metode = LfMetode.values.byName(m['metode']);
        if (m['steg'] != null) _steg = LfSteg.values.byName(m['steg']);
        if (m['inv'] == true) {
          prefSetBool(prefPendingReferFromLink, true);
          prefSetString(prefPendingReferCode, (m['invCode'] ?? 'BERGEN-4827') as String);
          prefSetString(_prefInviterName, (m['invName'] ?? 'Didrik') as String);
        } else if (m['inv'] == false) {
          prefSetBool(prefPendingReferFromLink, false);
          prefSetString(prefPendingReferCode, '');
          prefSetString(_prefInviterName, '');
          _verv.clear();
          _vervOk = false;
          _vervSvar = '';
        }
        _fane = m['verv'] == true;
        _kodeAapen = m['kodeAapen'] == true;
        if (m['vervKode'] != null) _verv.text = m['vervKode'];
        if (m['vervOk'] != null) _vervOk = m['vervOk'] == true;
        if (m['vervSvar'] != null) _vervSvar = m['vervSvar'];
        _godtatt = m['godtatt'] == true;
        _lestV = m['lestV'] == true;
        _lestP = m['lestP'] == true;
        _feil = m['feil'] == true;
        _logg = m['logg'] == true;
        _navn.text = (m['navn'] ?? '') as String;
        _epost.text = (m['epost'] ?? '') as String;
        _pass.text = (m['pass'] ?? '') as String;
        _tlf.text = (m['tlf'] ?? '') as String;
        _kode.text = (m['kode'] ?? '') as String;
        _sek = (m['sek'] ?? 0) as int;
        if (m['poeng'] != null) {
          _poeng = m['poeng'] as int;
          _maal = (m['maal'] ?? 50) as int;
        }
        _gen++;
      });
      debugPrint('LF_HARNESS applied');
      final acts = (m['act'] as List?)?.cast<String>() ?? const [];
      for (final a in acts) {
        await Future.delayed(Duration(milliseconds: (m['actGap'] ?? 2500) as int));
        if (!mounted) return;
        await _harnessAct(a);
        debugPrint('LF_ACT $a');
      }
    } catch (_) {}
  }

  /// Runs what the matching button does. `fyllTest` reads the local test
  /// account from `--dart-define=TEST_EMAIL=… --dart-define=TEST_PASSWORD=…`.
  Future<void> _harnessAct(String a) async {
    if (a.startsWith('kode:')) {
      final v = a.substring(5);
      _kode.text = v;
      _skrivKode(v);
      return;
    }
    switch (a) {
      case 'logout':
        await prefClearWithRemainSomeData();
      case 'epost':
        _velgMetode(LfMetode.epost);
      case 'huk':
        _set(() => _godtatt = true);
      case 'godta':
        await _godtaFortsett(null);
      case 'loggTab':
        _set(() => _logg = true);
      case 'fyllTest':
        _epost.text = const String.fromEnvironment('TEST_EMAIL');
        _pass.text = const String.fromEnvironment('TEST_PASSWORD');
      case 'loggInn':
        final size = MediaQuery.sizeOf(context);
        await _loggInn(Rect.fromCenter(center: Offset(size.width / 2, size.height * .62), width: 300, height: 60));
      case 'seRundt':
        _seRundt(LfCopy.seRundtToast);
      case 'avvis':
        _seRundt(LfCopy.avvisToast);
      case 'toastTest':
        _si(LfCopy.regMangler);
      case 'ferdigFn':
        final size = MediaQuery.sizeOf(context);
        _tilHjem(Rect.fromCenter(center: Offset(size.width / 2, size.height - 70), width: 340, height: 56),
            toast: LfCopy.velkommenToast(_maal));
      case 'busy':
        _set(() => _busy = true);
    }
  }
}

/// Debug builds only: `Documents/lf_state.json` with `"force": true` sends
/// the splash to the onboarding even with a session, for screenshots.
Future<bool> lfHarnessForced() async {
  if (!kDebugMode) return false;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/lf_state.json');
    if (!await f.exists()) return false;
    final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    return m['force'] == true;
  } catch (_) {
    return false;
  }
}

/// Inviter name carried by the invite link (`/invite?code=…&from=…`).
const String _prefInviterName = 'pendingReferInviterName';

/// Stores the inviter's name from an invite link (see `main.dart`).
void lfSetInviterName(String name) => prefSetString(_prefInviterName, name.trim());

/// Lets the settled (animation-free) landing animate normally after the
/// first frame, so later loops and taps behave.
class _UnsettleAfter extends StatefulWidget {
  const _UnsettleAfter({required this.child, required this.onDone});

  final Widget child;
  final VoidCallback onDone;

  @override
  State<_UnsettleAfter> createState() => _UnsettleAfterState();
}

class _UnsettleAfterState extends State<_UnsettleAfter> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => widget.onDone());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The Laster overlay for other screens' auth calls.
Widget lfBusyOverlay() => Positioned.fill(child: AbsorbPointer(child: LfLaster(text: LfCopy.henter)));

/// Reads [prefGetString] safely for the forgot-password sheet entry.
void lfForgotPassword(BuildContext context) => showForgotPasswordSheet(context);

/// `#merke` at any size.
class LfMerke extends StatelessWidget {
  const LfMerke({super.key, required this.w, required this.h});

  final double w;
  final double h;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: w, height: h, child: const CustomPaint(painter: SplashStickerPainter()));
}
