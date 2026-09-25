import 'package:flutter/material.dart';

import '../kit/bergen_chip.dart';

/// The Points route (AGIL-CONTRACT §3.4). agil-3 registers the screen in
/// `bergen_routes_agil3.dart`; the Hjem only ever pushes this constant.
const String kPoengRoute = '/bergen/poeng';

/// The Points card the Hjem renders (AGIL-CONTRACT §2.2 seam). Sync C stub:
/// a placeholder chip. agil-3 replaces the body with the real balance card.
Widget poengEntryCard(BuildContext context) =>
    const BergenChip(label: 'Poeng', icon: Icons.stars_rounded);
