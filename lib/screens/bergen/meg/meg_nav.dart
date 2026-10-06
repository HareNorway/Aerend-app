import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../kit/bergen_routes.dart';

/// The shell's nav on a Meg screen pushed over it (Premiehylla, the league,
/// order history, favourites, account): no tab lit, as in the prototype; a
/// tab or the search orb returns to the shell there. Lay it with
/// `Positioned(left: 0, right: 0, bottom: 0)`.
class MegNav extends StatelessWidget {
  const MegNav({super.key});

  @override
  Widget build(BuildContext context) => BergenBottomNav(
    index: -1,
    merkMeg: false,
    onTab: (i) {
      final shell = HomeMainV1State.current;
      Navigator.of(context).popUntil((r) => r.isFirst);
      shell?.switchToTab(i);
    },
    cartCount: ValueNotifier<int>(prefGetInt(prefCartCount)),
    onSearch: (_) {
      final shell = HomeMainV1State.current;
      Navigator.of(context).popUntil((r) => r.isFirst);
      shell?.openSearchTab();
    },
    onAegil: (_) => BergenRoutes.push(context, '/bergen/aegil'),
    showHint: false,
  );
}
