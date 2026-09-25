import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../points/widgets/meg_points_card.dart';
import '../../points/widgets/mission_card.dart';
import 'a3_scaffold.dart';
import 'a3_services.dart';
import '../kit/bergen_kit.dart';
import 'borte_entry.dart';
import 'meg_copy.dart';
import 'varsler_panel.dart';

/// Meg (design `meg` ≈L5600): the header (name · bydel, Gullbilletten), the
/// Poeng card (agil-2's [MegPointsCard]), the Meg-rader (Nivå, Fløyen-ligaen,
/// Ukens oppdrag, Favoritter, Nytt fra butikkene, Hjelp, Konto,
/// Bestillinger, Varsler) and "Slik får du poeng".
/// Data: `points/me`, `points/prizes`, `points/mission`, `points/league`,
/// `points/referral`.
class MegScreenBody extends StatefulWidget {
  const MegScreenBody({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<MegScreenBody> createState() => _MegScreenBodyState();
}

class _MegScreenBodyState extends State<MegScreenBody> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  PointsBalance? _balance;
  Premiehylla? _shelf;
  Mission? _mission;
  League? _league;
  Referral? _referral;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([
      a3Try(_api.balance),
      a3Try(_api.shelf),
      a3Try(_api.mission),
      a3Try(_api.league),
      a3Try(_api.referral),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _mission = r[2] as Mission?;
      _league = r[3] as League?;
      _referral = r[4] as Referral?;
      _loading = false;
    });
  }

  void _go(String route) => Navigator.of(context).pushNamed(route);

  @override
  Widget build(BuildContext context) {
    final name = a3Pref(prefUserName).trim().split(' ').firstOrNull ?? '';
    final b = _balance;
    final ref = _referral;
    final borte = mensDuVarBorteCard(context);

    return A3Scaffold(
      title: name.isEmpty ? 'Meg' : A3MegCopy.a3_meg_fra(name, A3MegCopy.a3_meg_bydel_sub),
      subtitle: b == null ? null : A3MegCopy.a3_meg_premie_boble,
      showBack: false,
      trailing: IconButton(
        key: const Key('meg-varsler'),
        tooltip: A3MegCopy.a3_meg_rad_varsler,
        onPressed: () => showVarslerPanel(context),
        icon: const Icon(Icons.notifications_rounded, color: Colors.white),
      ),
      child: _loading
          ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (borte != null) ...[borte, const SizedBox(height: 10)],
                BergenCard(
                  key: const Key('meg-gullbillett'),
                  onDark: true,
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_rounded, color: BergenTokens.lantern, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(A3MegCopy.a3_meg_gullbillett, style: BergenTokens.display(BergenTokens.textBody, color: Colors.white)),
                            Text(ref == null ? A3MegCopy.a3_meg_gullbillett_sub : A3MegCopy.a3_meg_gullbillett_kode(ref.pointsForThem, ref.pointsForMe, ref.code), style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
                          ],
                        ),
                      ),
                      BergenCta3d(
                        label: A3MegCopy.a3_meg_del,
                        expand: false,
                        onPressed: () {
                          final code = ref?.code ?? a3Pref(prefReferralCode);
                          Clipboard.setData(ClipboardData(text: ref?.link ?? code));
                          showBergenToast(context, 'Koden $code er kopiert', icon: Icons.copy_rounded);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (b != null)
                  MegPointsCard(
                    balance: b,
                    goal: _shelf?.goal,
                    onOpenPremiehylla: () => _go('/bergen/premiehylla'),
                    onOpenNiva: () => _go('/bergen/opprykk'),
                  ),
                if (b != null) ...[
                  const SizedBox(height: 6),
                  if (b.pending > 0) Text(A3MegCopy.a3_meg_venter(b.pending), style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: A3Ink.soft)),
                ],
                const SizedBox(height: 12),
                A3Row(key: const Key('meg-rad-nivaa'), title: A3MegCopy.a3_meg_rad_nivaa, subtitle: b?.tierName, icon: Icons.terrain_rounded, onTap: () => _go('/bergen/opprykk')),
                A3Row(key: const Key('meg-rad-liga'), title: A3MegCopy.a3_meg_rad_liga, subtitle: _league?.own != null ? A3MegCopy.a3_meg_liga_plass(_league!.own!.rank) : null, badge: _league?.optedIn == true ? null : A3MegCopy.a3_meg_rad_liga_bli, icon: Icons.emoji_events_rounded, onTap: () => _go('/bergen/liga')),
                if (_mission != null) ...[
                  const SizedBox(height: 8),
                  MissionCard(
                    mission: _mission!,
                    onDecline: () async {
                      final r = await _api.declineMission();
                      if (mounted) setState(() => _mission = r.replacement);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                A3Row(key: const Key('meg-rad-favoritter'), title: A3MegCopy.a3_meg_rad_favoritter, icon: Icons.favorite_rounded, onTap: () => _go('/bergen/meg/favoritter')),
                A3Row(key: const Key('meg-rad-bestillinger'), title: A3MegCopy.a3_meg_rad_bestillinger, icon: Icons.receipt_long_rounded, onTap: () => _go('/bergen/meg/bestillinger')),
                A3Row(key: const Key('meg-rad-konto'), title: A3MegCopy.a3_meg_rad_konto, icon: Icons.person_rounded, onTap: () => _go('/bergen/meg/konto')),
                A3Row(key: const Key('meg-rad-varsler-row'), title: A3MegCopy.a3_meg_rad_varsler, icon: Icons.notifications_rounded, onTap: () => _go('/bergen/meg/varsler')),
                A3Row(title: A3MegCopy.a3_meg_rad_hjelp, icon: Icons.help_rounded, onTap: () => Navigator.of(context).pushNamed('/bergen/meg/konto')),
                const A3Kicker(A3MegCopy.a3_meg_slik_title),
                BergenCard(
                  onDark: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in A3MegCopy.a3_meg_slik_rader)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, size: 16, color: BergenTokens.lantern),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: Colors.white))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
