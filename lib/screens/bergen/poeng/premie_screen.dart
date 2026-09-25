import 'package:flutter/material.dart';

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// One prize (`/bergen/premie/{id}`): what it is, what it costs in points,
/// who gives it, and Hent → `points/prizes/{id}/claim` through the existing
/// repo. The prize arrives as the route argument (from the shelf) or is
/// looked up by id from the shelf.
class PremieScreen extends StatefulWidget {
  const PremieScreen({super.key, this.prize, this.prizeId, this.api});

  final Prize? prize;
  final int? prizeId;
  final PointsAppApi? api;

  @override
  State<PremieScreen> createState() => _PremieScreenState();
}

class _PremieScreenState extends State<PremieScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  Prize? _prize;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prize = widget.prize;
    if (_prize == null) _lookup();
  }

  Future<void> _lookup() async {
    final shelf = await a3Try(_api.shelf);
    if (!mounted) return;
    setState(() {
      _prize = shelf?.prizes.where((p) => p.id == widget.prizeId).firstOrNull;
    });
  }

  Future<void> _claim() async {
    final p = _prize;
    if (p == null) return;
    setState(() => _busy = true);
    final r = await _api.claim(p.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = r.error;
    });
    if (r.claim != null) {
      showBergenToast(context, '${p.name} er din · ${r.claim!.voucherCode ?? ''}'.trim(), icon: Icons.check_rounded);
      Navigator.of(context).maybePop(r.claim);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _prize;

    return A3Scaffold(
      title: p?.name ?? 'Premie',
      subtitle: p?.partnerName,
      child: p == null
          ? Padding(padding: const EdgeInsets.only(top: 60), child: Text(A3PoengCopy.a3_poeng_velger_tom, textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textBody, color: Colors.white)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BergenCard(
                  onDark: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, color: BergenTokens.lantern, size: 32),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${p.pointPrice} ${A3PoengCopy.a3_poeng_poeng}', style: BergenTokens.display(BergenTokens.textHero, color: Colors.white))),
                          if (!p.inStock) const BergenChip(label: A3PoengCopy.a3_poeng_badge_utsolgt, onDark: true),
                        ],
                      ),
                      if (p.line != null) ...[const SizedBox(height: 10), Text(p.line!, style: BergenTokens.text(BergenTokens.textBody, color: const Color(0xFFDCE9EC)))],
                      const SizedBox(height: 10),
                      Text('${A3PoengCopy.a3_poeng_nivaa} · ${p.tierName} · ${p.type}', style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w700, color: const Color(0xFF9FD3DE))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (p.blockedReason != null && !p.claimable)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(p.blockedReason!, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: BergenTokens.lantern))),
                if (_error != null)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: BergenTokens.orangeLight))),
                BergenCta3d(
                  label: A3PoengCopy.a3_poeng_velger_hent,
                  icon: Icons.redeem_rounded,
                  onPressed: p.claimable && !_busy ? _claim : null,
                ),
                const SizedBox(height: 12),
                Text(A3PoengCopy.a3_poeng_gjelder, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: const Color(0xFF9FD3DE))),
              ],
            ),
    );
  }
}
