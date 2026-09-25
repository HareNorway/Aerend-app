import 'package:flutter/material.dart';

import '../../../utils/shared_pref_utill.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'aegil_copy.dart';

/// The Ægil route (AGIL-CONTRACT §3.4). agil-3 registers the screen; the Hjem
/// greeting and the Søk · Spør Ægil card push this constant.
const String kAegilRoute = '/bergen/aegil';

/// The Ægil greeting line on the Hjem (seam, design ≈L1948): first name +
/// the evening question, tap → [kAegilRoute]. Nothing is fetched here — the
/// screen behind it does the talking.
Widget aegilGreeting(BuildContext context) {
  final name = a3Pref(prefUserName).trim().split(' ').firstOrNull ?? '';
  return GestureDetector(
    key: const Key('aegil-greeting'),
    onTap: () => Navigator.of(context).pushNamed(kAegilRoute),
    child: Row(
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 18, color: BergenTokens.mint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name.isEmpty ? A3AegilCopy.a3_aegil_greeting : 'Hei, $name! ${A3AegilCopy.a3_aegil_spor}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: A3Ink.sub),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 18, color: A3Ink.muted),
      ],
    ),
  );
}
