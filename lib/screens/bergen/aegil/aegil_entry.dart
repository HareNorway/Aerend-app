import 'package:flutter/material.dart';

/// The Ægil route (AGIL-CONTRACT §3.4). agil-3 registers the screen; the Hjem
/// greeting and the Søk · Spør Ægil card push this constant.
const String kAegilRoute = '/bergen/aegil';

/// The Ægil greeting line on the Hjem (seam). Sync C stub: nothing rendered;
/// agil-3 replaces it with the real greeting.
Widget aegilGreeting(BuildContext context) => const SizedBox.shrink();
