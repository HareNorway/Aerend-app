import 'package:flutter/material.dart';

import '../../common/account/account.dart';

/// Tab 3 of the shell (AGIL-CONTRACT §2.2 seam). The Sync C stub renders the
/// existing [Account]; agil-3 replaces the body with the Meg screen and keeps
/// the class name, so `home_main_v1.dart` never changes for it.
class MegScreen extends StatelessWidget {
  const MegScreen({super.key});

  @override
  Widget build(BuildContext context) => const Account();
}
