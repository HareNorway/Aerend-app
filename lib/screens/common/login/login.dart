import 'package:flutter/material.dart';

import '../auth/launch/launch_onboarding.dart';

/// Sign-in entry point: the Ærend Kunde Launch onboarding
/// ([LaunchOnboarding], `Design-New/Ærend Kunde Launch.dc.html`
/// `data-screen-label="Onboarding"`). Every existing call site keeps its
/// arguments.
class Login extends StatefulWidget {
  final bool returnOnSuccess;

  /// Open straight on Konto ("Logg inn") instead of the landing.
  final bool openEmailForm;

  /// Open Konto on the "Opprett konto" tab.
  final bool startOnRegisterTab;

  /// Kept for call sites from the old consent-first flow; no longer used.
  final bool? fromConsent;

  /// Cold start from the splash: the landing is shown settled under the
  /// splash cross-fade.
  final bool fromSplash;

  const Login({
    super.key,
    this.returnOnSuccess = false,
    this.openEmailForm = false,
    this.startOnRegisterTab = false,
    this.fromConsent = false,
    this.fromSplash = false,
  });

  bool get enteredFromConsent => fromConsent ?? false;

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    final konto = widget.openEmailForm || widget.startOnRegisterTab;
    return LaunchOnboarding(
      initial: konto ? LfSteg.konto : LfSteg.landing,
      loginTab: widget.openEmailForm && !widget.startOnRegisterTab,
      returnOnSuccess: widget.returnOnSuccess,
      fromSplash: widget.fromSplash,
    );
  }
}
