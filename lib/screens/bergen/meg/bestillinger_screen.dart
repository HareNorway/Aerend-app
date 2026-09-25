import 'package:flutter/material.dart';

import '../../common/orderHistory/order_history.dart';
import 'a3_scaffold.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';

/// Bestillinger (design `bestillinger` ≈L6020): "PÅ VEI NÅ" (live orders —
/// fed by agil-1's `GET /api/ops/customer/orders` once it lands; until then
/// the row opens the existing history), "Bestill igjen", and the full
/// history through the existing [OrderHistory] screen.
class BestillingerScreen extends StatelessWidget {
  const BestillingerScreen({super.key, this.liveCount = 0});

  final int liveCount;

  @override
  Widget build(BuildContext context) {
    void openHistory() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OrderHistory()));

    return A3Scaffold(
      title: A3MegCopy.a3_meg_best_title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (liveCount > 0) ...[
            const A3Kicker(A3MegCopy.a3_meg_best_live),
            A3Row(key: const Key('best-live'), title: '$liveCount på vei', subtitle: A3MegCopy.a3_meg_best_sporing, icon: Icons.sailing_rounded, onTap: openHistory),
          ],
          const SizedBox(height: 8),
          BergenCard(
            onDark: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(A3MegCopy.a3_meg_best_tom, key: const Key('best-intro'), style: BergenTokens.display(BergenTokens.textSection, color: Colors.white)),
                const SizedBox(height: 4),
                Text(A3MegCopy.a3_meg_best_tom_sub, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BergenCta3d(key: const Key('best-igjen'), label: A3MegCopy.a3_meg_best_igjen, icon: Icons.replay_rounded, onPressed: openHistory),
          const SizedBox(height: 8),
          A3Row(key: const Key('best-historikk'), title: A3MegCopy.a3_meg_best_title, subtitle: 'Sporing og kvitteringer', icon: Icons.receipt_long_rounded, onTap: openHistory),
        ],
      ),
    );
  }
}
