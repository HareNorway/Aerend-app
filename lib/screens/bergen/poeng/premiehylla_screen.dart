import 'package:flutter/material.dart';

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'aegil_velger_screen.dart';
import 'poeng_copy.dart';

/// Premiehylla (design `premier` ≈L6178): the goal with its percentage,
/// "Mine premier (n)", the month's shelf priced in points — never in kroner —
/// MÅL / UTSOLGT badges, "N igjen", set-goal, the locked section, and the
/// 60-day rule. Data: `points/prizes`, `points/me`, `points/claims`.
class PremiehyllaScreen extends StatefulWidget {
  const PremiehyllaScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<PremiehyllaScreen> createState() => _PremiehyllaScreenState();
}

class _PremiehyllaScreenState extends State<PremiehyllaScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  PointsBalance? _balance;
  Premiehylla? _shelf;
  List<PrizeClaim> _claims = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([a3Try(_api.balance), a3Try(_api.shelf), a3Try(_api.claims)]);
    if (!mounted) return;
    setState(() {
      _balance = results[0] as PointsBalance?;
      _shelf = results[1] as Premiehylla?;
      _claims = (results[2] as List<PrizeClaim>?) ?? const [];
      _loading = false;
    });
  }

  Future<void> _setGoal(Prize p) async {
    final goal = await _api.setGoal(prizeId: p.id);
    if (!mounted) return;
    if (goal != null) {
      showBergenToast(context, '${p.name} er målet ditt', icon: Icons.flag_rounded);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;
    final shelf = _shelf;
    final goal = shelf?.goal;

    return A3Scaffold(
      title: A3PoengCopy.a3_poeng_premiehylla_title,
      subtitle: A3PoengCopy.a3_poeng_premiehylla_sub,
      trailing: balance == null
          ? null
          : BergenChip(label: '${balance.available} ${A3PoengCopy.a3_poeng_poeng}', onDark: true, icon: Icons.stars_rounded),
      child: _loading
          ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (balance != null)
                  Text(
                    '${A3PoengCopy.a3_poeng_nivaa} · ${balance.tierName}${balance.pointsToNextTier != null ? ' · ${balance.pointsToNextTier} poeng til ${balance.nextTierName}' : ''}',
                    style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: const Color(0xFFDCE9EC)),
                  ),
                if (goal != null) ...[
                  const A3Kicker(A3PoengCopy.a3_poeng_maal_label),
                  BergenCard(
                    onDark: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(goal.label, style: BergenTokens.display(BergenTokens.textSection, color: Colors.white))),
                            Text('${goal.percent} %', style: BergenTokens.display(BergenTokens.textSection, color: BergenTokens.mint)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (goal.percent / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: BergenTokens.glassBorder,
                            color: goal.reached ? BergenTokens.mint : BergenTokens.orange,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          goal.reached ? 'Målet er nådd — hent premien.' : '${goal.remaining} ${A3PoengCopy.a3_poeng_poeng} igjen',
                          style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: const Color(0xFFDCE9EC)),
                        ),
                      ],
                    ),
                  ),
                ],
                A3Kicker(
                  '${A3PoengCopy.a3_poeng_mine_premier} · ${_claims.length}',
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AegilVelgerScreen(api: _api))),
                    child: Text(A3PoengCopy.a3_poeng_velger_kicker, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: BergenTokens.orangeLight)),
                  ),
                ),
                if (_claims.isEmpty)
                  Text('Ingen premier hentet ennå.', style: BergenTokens.text(BergenTokens.textSmall, color: const Color(0xFFDCE9EC)))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _claims)
                        BergenChip(label: '${c.prizeName ?? 'Premie'} · ${c.state}', onDark: true, icon: Icons.confirmation_number_rounded),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(A3PoengCopy.a3_poeng_hylla_intro, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w500, color: const Color(0xFFDCE9EC))),
                const SizedBox(height: 12),
                if (shelf == null || shelf.prizes.isEmpty)
                  BergenCard(onDark: true, child: Text(A3PoengCopy.a3_poeng_velger_tom, style: BergenTokens.text(BergenTokens.textBody, color: Colors.white)))
                else
                  for (final p in shelf.prizes) _PrizeRow(prize: p, isGoal: goal?.prizeId == p.id, onOpen: () => _open(p), onGoal: () => _setGoal(p)),
                if (shelf != null && shelf.previews.isNotEmpty) ...[
                  const A3Kicker(A3PoengCopy.a3_poeng_laast_title),
                  for (final pv in shelf.previews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BergenCard(
                        onDark: true,
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: Color(0xFF9FD3DE)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pv.name, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: Colors.white)),
                                  if (pv.teaser != null) Text(pv.teaser!, style: BergenTokens.text(BergenTokens.textSmall, color: const Color(0xFFDCE9EC))),
                                  Text('${pv.pointPrice} ${A3PoengCopy.a3_poeng_poeng} · Fra ${pv.tierName} · ${A3PoengCopy.a3_poeng_til_laas(pv.pointsToUnlock)}', style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w700, color: const Color(0xFF9FD3DE))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Text(A3PoengCopy.a3_poeng_gjelder, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: const Color(0xFF9FD3DE))),
              ],
            ),
    );
  }

  void _open(Prize p) {
    Navigator.of(context).pushNamed('/bergen/premie', arguments: p);
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.prize, required this.isGoal, required this.onOpen, required this.onGoal});

  final Prize prize;
  final bool isGoal;
  final VoidCallback onOpen;
  final VoidCallback onGoal;

  @override
  Widget build(BuildContext context) {
    final soldOut = !prize.inStock;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BergenCard(
        onDark: true,
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isGoal) ...[const BergenChip(label: A3PoengCopy.a3_poeng_badge_maal, selected: true), const SizedBox(width: 6)],
                if (soldOut) ...[const BergenChip(label: A3PoengCopy.a3_poeng_badge_utsolgt, onDark: true), const SizedBox(width: 6)],
                if (prize.partnerName != null) Expanded(child: Text(prize.partnerName!, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: const Color(0xFF9FD3DE)))),
              ],
            ),
            const SizedBox(height: 6),
            Text(prize.name, style: BergenTokens.display(BergenTokens.textSection, color: Colors.white)),
            if (prize.line != null) Text(prize.line!, style: BergenTokens.text(BergenTokens.textSmall, color: const Color(0xFFDCE9EC))),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${prize.pointPrice} ${A3PoengCopy.a3_poeng_poeng}', style: BergenTokens.display(BergenTokens.textBody, color: BergenTokens.lantern)),
                const Spacer(),
                if (!prize.affordable && !soldOut)
                  Text(A3PoengCopy.a3_poeng_igjen(prize.pointPrice), style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w700, color: const Color(0xFF9FD3DE)))
                else if (prize.claimable)
                  BergenCta3d(label: A3PoengCopy.a3_poeng_hent, expand: false, onPressed: onOpen),
                const SizedBox(width: 8),
                if (!isGoal && !soldOut)
                  TextButton(onPressed: onGoal, child: Text(A3PoengCopy.a3_poeng_sett_maal, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orangeLight))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
