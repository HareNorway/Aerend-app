import 'package:flutter/material.dart';

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../points/widgets/welcome_moment.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// Nivåopprykk (design `opprykk` ≈L6124): the celebration entered from a
/// `TierPromoted` push or a `points/me` tier delta — "HER ER NOE TIL DEG",
/// the gift Ægil chose (no points), "Hylla di har fått tre nye premier",
/// Hopp over / Ferdig. The first tier mounts agil-2's [WelcomeMoment].
class OpprykkScreen extends StatefulWidget {
  const OpprykkScreen({super.key, this.tierName, this.giftName, this.api});

  final String? tierName;
  final String? giftName;
  final PointsAppApi? api;

  @override
  State<OpprykkScreen> createState() => _OpprykkScreenState();
}

class _OpprykkScreenState extends State<OpprykkScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  PointsBalance? _balance;
  Premiehylla? _shelf;
  List<PrizeClaim> _claims = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([a3Try(_api.balance), a3Try(_api.shelf), a3Try(_api.claims)]);
    if (!mounted) return;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _claims = (r[2] as List<PrizeClaim>?) ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tierName ?? _balance?.tierName ?? '';
    final gift = widget.giftName ?? _shelf?.prizes.where((p) => p.pointPrice == 0).map((p) => p.name).firstOrNull;
    final giftClaim = _claims.where((c) => c.isGift).firstOrNull;
    final firstTier = (_balance?.tier ?? 1) <= 1;

    return A3Scaffold(
      kicker: A3PoengCopy.a3_poeng_opprykk_kicker,
      title: tier.isEmpty ? 'Nytt nivå' : A3PoengCopy.a3_poeng_opprykk_naa(tier),
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (firstTier && tier.isNotEmpty && giftClaim != null)
            WelcomeMoment(
              tierName: tier,
              gift: giftClaim,
              onOpenShelf: () => Navigator.of(context).pushReplacementNamed('/bergen/premiehylla'),
              onDismiss: () => Navigator.of(context).maybePop(),
            )
          else ...[
            const A3Kicker(A3PoengCopy.a3_poeng_opprykk_gave),
            BergenCard(
              onDark: true,
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: BergenTokens.lantern, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gift ?? 'Gratis levering neste gang', style: BergenTokens.display(BergenTokens.textSection, color: Colors.white)),
                        Text(A3PoengCopy.a3_poeng_opprykk_valgt, style: BergenTokens.text(BergenTokens.textSmall, color: const Color(0xFFDCE9EC))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BergenCta3d(label: A3PoengCopy.a3_poeng_opprykk_hent, icon: Icons.redeem_rounded, onPressed: () => Navigator.of(context).pushReplacementNamed('/bergen/premiehylla')),
          ],
          const SizedBox(height: 18),
          Text(A3PoengCopy.a3_poeng_opprykk_hylla, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/bergen/premiehylla'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: BergenTokens.glassBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton))),
                  child: const Text(A3PoengCopy.a3_poeng_opprykk_se),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(A3PoengCopy.a3_poeng_opprykk_hopp, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: const Color(0xFFDCE9EC))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BergenCta3d(label: A3PoengCopy.a3_poeng_opprykk_ferdig, onPressed: () => Navigator.of(context).maybePop()),
        ],
      ),
    );
  }
}
