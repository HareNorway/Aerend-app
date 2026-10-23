import 'package:flutter/material.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart' show isLoggedIn;
import '../kit/bergen_kit.dart';
import '../kit/live_aerend.dart' show hjemLiveOrdre;
import 'ai_copy.dart';

/// `/bergen/siste-bestilling` — the TrackOrder intent / shortcut (Customer
/// Step 15). Finds the order to follow and replaces itself with Sporing: the
/// order under way Hjem knows, else the newest order that was not cancelled;
/// Ordrehistorikk with a line when there is none (or a guest).
class SisteBestillingScreen extends StatefulWidget {
  const SisteBestillingScreen({super.key, this.api, this.liveId});

  /// Tests inject the API and the live order.
  final OpsCustomerApi? api;
  final int? liveId;

  @override
  State<SisteBestillingScreen> createState() => _SisteBestillingScreenState();
}

class _SisteBestillingScreenState extends State<SisteBestillingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finn());
  }

  Future<void> _finn() async {
    var id = widget.liveId ?? hjemLiveOrdre.value?.orderId ?? 0;
    if (id == 0 && isLoggedIn()) {
      try {
        final rows = await (widget.api ?? OpsCustomerApi()).orders(limit: 5);
        final r = rows.where((r) => r['state'] != 'cancelled').firstOrNull;
        // `order_id` comes as a string from `ops.customer.orders`.
        id = int.tryParse('${r?['order_id'] ?? ''}') ?? 0;
      } catch (_) {
        id = 0;
      }
    }
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (id > 0) {
      final r = BergenRoutes.generate(RouteSettings(name: '/bergen/sporing/$id'));
      if (r != null) {
        nav.pushReplacement(r);
        return;
      }
    }
    showBergenToast(context, AiCopy.cus_ai_ingen_bestilling);
    final r = BergenRoutes.generate(const RouteSettings(name: '/bergen/meg/bestillinger'));
    if (r != null) {
      nav.pushReplacement(r);
    } else {
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    key: Key('cus-ai-siste-bestilling'),
    backgroundColor: Color(0xFF173E48),
    body: Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF7FF0CB)))),
  );
}
