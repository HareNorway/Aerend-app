import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// The Points route (AGIL-CONTRACT §3.4). agil-3 registers the screen in
/// `bergen_routes_agil3.dart`; the Hjem only ever pushes this constant.
const String kPoengRoute = '/bergen/poeng';

/// The Points card the Hjem renders (AGIL-CONTRACT §2.2 seam): the balance
/// and the goal in one glance, tap → [kPoengRoute]. Loads `points/me`
/// through [A3Services.points]; renders the placeholder chip until it lands.
Widget poengEntryCard(BuildContext context) => const _PoengEntryCard();

class _PoengEntryCard extends StatefulWidget {
  const _PoengEntryCard();

  @override
  State<_PoengEntryCard> createState() => _PoengEntryCardState();
}

class _PoengEntryCardState extends State<_PoengEntryCard> {
  PointsBalance? _balance;

  @override
  void initState() {
    super.initState();
    a3Try(() => A3Services.points().balance()).then((b) {
      if (mounted && b != null) setState(() => _balance = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = _balance;
    return GestureDetector(
      key: const Key('poeng-entry'),
      onTap: () => Navigator.of(context).pushNamed(kPoengRoute),
      child: b == null
          ? const BergenChip(label: A3PoengCopy.a3_poeng_entry_title, icon: Icons.stars_rounded)
          : BergenChip(
              label: '${b.available} ${A3PoengCopy.a3_poeng_poeng} · ${b.tierName}',
              icon: Icons.stars_rounded,
              selected: true,
            ),
    );
  }
}
