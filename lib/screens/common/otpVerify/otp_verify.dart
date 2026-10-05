import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../auth/launch/launch_onboarding.dart';

/// Phone confirmation for an account that is signed in but not verified
/// (`manageLoginResponse`, Vipps return): the Launch onboarding's Telefon /
/// Kode steps (`onbErTelefon`, `onbErKode`). With a number on file the code
/// is sent at once.
class OtpVerify extends StatefulWidget {
  const OtpVerify({super.key});

  @override
  State<StatefulWidget> createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  late final bool _needsPhone = prefGetString(prefContactNumber).trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    return LaunchOnboarding(
      initial: _needsPhone ? LfSteg.telefon : LfSteg.kode,
      returnOnSuccess: prefGetBool(prefAuthReturnOnSuccess),
    );
  }
}
