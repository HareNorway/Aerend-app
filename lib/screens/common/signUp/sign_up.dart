import 'package:flutter/material.dart';

import '../login/login.dart';

/// Legacy SignUp route — ConsumerLogin keeps register **on Login**
/// (`.auth-emailtabs` → Opprett konto → OTP phone). This widget only
/// forwards old call sites into that flow.
class SignUp extends StatelessWidget {
  final bool returnOnSuccess;

  const SignUp({super.key, this.returnOnSuccess = false});

  @override
  Widget build(BuildContext context) {
    return Login(
      returnOnSuccess: returnOnSuccess,
      openEmailForm: true,
      startOnRegisterTab: true,
    );
  }
}
