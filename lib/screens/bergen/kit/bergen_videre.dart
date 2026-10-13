import 'package:flutter/widgets.dart';

import '../../common/home/bergen/bergen_nav.dart' show BergenTab;
import '../../common/homeMainV1/home_main_v1.dart' show HomeMainV1State;
import '../meg/meg_screen.dart' show MegApne;
import 'bergen_routes.dart';

/// A named route that only sends the user on (Gap Step 4, gap plan G3): it
/// pops itself on its first frame and runs [videre] with the navigator.
/// Keeps old route names (push deep links) working after their early pages
/// were removed.
class BergenVidere extends StatefulWidget {
  const BergenVidere(this.videre, {super.key});

  final void Function(NavigatorState nav) videre;

  /// The Meg tab, optionally with «Poeng, nivå og konkurranser» open.
  static void tilMeg(NavigatorState nav, {bool poeng = false}) {
    MegApne.poeng = poeng;
    final shell = HomeMainV1State.current;
    if (shell == null) {
      BergenRoutes.push<void>(nav.context, '/bergen/meg');
      return;
    }
    nav.popUntil((r) => r.isFirst);
    shell.switchToTab(BergenTab.me.index);
  }

  @override
  State<BergenVidere> createState() => _BergenVidereState();
}

class _BergenVidereState extends State<BergenVidere> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      widget.videre(nav);
    });
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Color(0xFF173E48));
}
