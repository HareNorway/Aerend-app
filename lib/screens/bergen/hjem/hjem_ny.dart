import 'package:flutter/material.dart';

import '../../../utils/shared_pref_utill.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import 'hjem_harness.dart';

// ── «Ny i bydelen» (prototype `vsNyLykt`, L2508 / L17890) ──────────────────
// The prototype lights a lantern on Hjem and puts a «Ny» tag on the category
// orb while an unread «Ny på Ærend: …» notice exists. Here the real signal is
// the store list's `new_on_aerend` (joined in the last 14 days, parity
// Step 4); it stays lit until the customer opens that shop.

abstract final class HjemNy {
  static const _pref = 'hjem_ny_sett';

  /// Shops the store lists marked `new_on_aerend`.
  static final Set<int> nye = <int>{};

  /// Bumped when a shop is seen, so Hjem drops the lantern at once.
  static final ValueNotifier<int> endret = ValueNotifier<int>(0);

  static Set<int> get _sett => prefGetString(_pref)
      .split(',')
      .map((e) => int.tryParse(e.trim()))
      .whereType<int>()
      .toSet();

  /// A new shop the customer has not opened yet.
  static bool uapnet(int storeId) => nye.contains(storeId) && !_sett.contains(storeId);

  /// The store page calls this when it opens.
  static void merkSett(int storeId) {
    if (storeId <= 0 || !nye.contains(storeId)) return;
    final s = _sett..add(storeId);
    prefSetString(_pref, s.join(','));
    endret.value++;
  }

  /// Debug harness `nyButikk`: light it as the prototype's sample data does.
  static bool get tvunget => HjemHarness.nyButikk;
}

/// The lantern (`left 84, top 160`, z 4): a glow breathing (`lyktGlo
/// 3.4s ease-in-out infinite`) round a small paper lantern.
class HjemNyLykt extends StatelessWidget {
  const HjemNyLykt({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 13,
        height: 18,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -7,
              top: -6,
              width: 27,
              height: 29,
              child: RepaintBoundary(
                child: LfLoop(
                  frozenMs: 1700,
                  builder: (context, t, child) {
                    // `lyktGlo`: opacity .55 → 1 → .55.
                    final p = (t / 3400) % 1.0;
                    final o = kf(p, const [0, .5, 1], const [.55, 1, .55], cssEaseInOut);
                    return Opacity(opacity: o, child: child);
                  },
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color.fromRGBO(255, 205, 120, .75), Color.fromRGBO(255, 205, 120, 0)],
                        stops: [0, .68],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 3,
              top: 0,
              width: 7,
              height: 3,
              child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xFF3A3128), borderRadius: BorderRadius.circular(2))),
            ),
            Positioned(
              left: 1,
              top: 3,
              width: 11,
              height: 11,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE2A8), Color(0xFFF2B457)],
                  ),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 198, 110, .9), blurRadius: 6)],
                ),
              ),
            ),
            const Positioned(left: 4, top: 14, width: 5, height: 4, child: ColoredBox(color: Color(0xFF3A3128))),
          ],
        ),
      ),
    );
  }
}

/// The orb's «Ny» tag (`friKat`: under the orb, `margin-top: -16px` after the
/// 8 px live dot).
class HjemNyTag extends StatelessWidget {
  const HjemNyTag({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFF26D3D),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Colors.white, spreadRadius: 1.5)],
        ),
        child: Text('Ny', style: inter(8, weight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
