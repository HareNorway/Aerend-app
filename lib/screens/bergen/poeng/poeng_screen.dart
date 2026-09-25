import 'package:flutter/material.dart';

import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../points/widgets/league_card.dart';
import '../../points/widgets/meg_points_card.dart';
import '../../points/widgets/mission_card.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// `/bergen/poeng` — the Points hub the Hjem card opens: balance + goal
/// (agil-2's [MegPointsCard]), the week's mission, the league card, and the
/// doors to Premiehylla, Nivå, Ægil velger and Fjordfiske.
class PoengScreen extends StatefulWidget {
  const PoengScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<PoengScreen> createState() => _PoengScreenState();
}

class _PoengScreenState extends State<PoengScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  PointsBalance? _balance;
  Premiehylla? _shelf;
  Mission? _mission;
  League? _league;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([a3Try(_api.balance), a3Try(_api.shelf), a3Try(_api.mission), a3Try(_api.league)]);
    if (!mounted) return;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _mission = r[2] as Mission?;
      _league = r[3] as League?;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = _balance;
    return A3Scaffold(
      title: A3PoengCopy.a3_poeng_entry_title,
      subtitle: A3PoengCopy.a3_poeng_entry_sub,
      child: _loading
          ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (b != null)
                  MegPointsCard(
                    balance: b,
                    goal: _shelf?.goal,
                    onOpenPremiehylla: () => Navigator.of(context).pushNamed('/bergen/premiehylla'),
                    onOpenNiva: () => Navigator.of(context).pushNamed('/bergen/opprykk'),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: BergenCta3d(key: const Key('poeng-hylla'), label: A3PoengCopy.a3_poeng_premiehylla_title, icon: Icons.card_giftcard_rounded, onPressed: () => Navigator.of(context).pushNamed('/bergen/premiehylla'))),
                    const SizedBox(width: 8),
                    Expanded(child: BergenCta3d(key: const Key('poeng-fiske'), label: A3PoengCopy.a3_poeng_fiske_title, icon: Icons.phishing_rounded, onPressed: () => Navigator.of(context).pushNamed('/bergen/fjordfiske'))),
                  ],
                ),
                if (_mission != null) ...[
                  MissionCard(
                    mission: _mission!,
                    onDecline: () async {
                      final r = await _api.declineMission();
                      if (!mounted) return;
                      setState(() => _mission = r.replacement);
                    },
                  ),
                ],
                if (_league != null) ...[
                  const A3Kicker(A3PoengCopy.a3_poeng_liga_title),
                  GestureDetector(
                    key: const Key('poeng-liga'),
                    onTap: () => Navigator.of(context).pushNamed('/bergen/liga'),
                    child: LeagueCard(
                      league: _league!,
                      onOptIn: () => _api.leagueOptIn(true).then((_) => _load()),
                      onOptOut: () => _api.leagueOptIn(false).then((_) => _load()),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                A3Row(title: A3PoengCopy.a3_poeng_velger_title, subtitle: A3PoengCopy.a3_poeng_velger_sub, icon: Icons.auto_awesome_rounded, onTap: () => Navigator.of(context).pushNamed('/bergen/premiehylla')),
              ],
            ),
    );
  }
}
