import 'package:flutter/material.dart';

import 'meg_screen.dart';

/// Tab 3 of the shell (AGIL-CONTRACT §2.2 seam). agil-3 renders the Meg
/// screen here and keeps the class name, so `home_main_v1.dart` never
/// changes for it.
class MegScreen extends StatelessWidget {
  const MegScreen({super.key});

  @override
  Widget build(BuildContext context) => const MegScreenBody();
}
