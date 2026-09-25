import 'package:flutter/material.dart';

import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// Fløyen-ligaen (design `liga` ≈L6368): the rank, Hele Bergen / Din bydel,
/// the climbers table, the four monthly prizes, "Se månedsslutten" (Ark
/// `kArkErSeremoni`) and "Navn i ligaen" (`kArkErLiga` join sheet).
/// Data: `points/league`, opt-in / opt-out.
class LigaScreen extends StatefulWidget {
  const LigaScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<LigaScreen> createState() => _LigaScreenState();
}

class _LigaScreenState extends State<LigaScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  League? _league;
  bool _bydel = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await a3Try(_api.league);
    if (!mounted) return;
    setState(() {
      _league = l;
      _loading = false;
    });
  }

  Future<void> _toggle(bool optIn) async {
    final ok = await _api.leagueOptIn(optIn);
    if (!mounted) return;
    if (ok) {
      showBergenToast(context, optIn ? 'Du er med i Fløyen-ligaen' : 'Du er meldt av ligaen', icon: Icons.emoji_events_rounded);
      _load();
    }
  }

  void _joinSheet() {
    final l = _league;
    showBergenArk(
      context,
      title: A3PoengCopy.a3_poeng_liga_navn,
      subtitle: l?.optedIn == true ? 'Navnet ditt vises som fornavn · bydel. Du kan melde deg av når som helst.' : 'Bli med, så vises fornavnet ditt og bydelen din i tabellen. Nivået ditt vises aldri.',
      rows: const [
        BergenArkRow(label: 'Fornavn · bydel', value: 'Aldri etternavn, aldri adresse'),
        BergenArkRow(label: 'Nivået ditt', value: 'Vises ikke — ligaen er nivåblind'),
        BergenArkRow(label: 'Poeng per bestilling', value: 'Tak per ordre, så små kjøp teller'),
      ],
      primary: BergenArkAction(
        label: l?.optedIn == true ? A3PoengCopy.a3_poeng_liga_meld_av : A3PoengCopy.a3_poeng_liga_bli_med,
        onTap: () {
          Navigator.of(context).pop();
          _toggle(!(l?.optedIn ?? false));
        },
      ),
      secondary: BergenArkAction(label: A3PoengCopy.a3_poeng_liga_vilkaar, onTap: () => Navigator.of(context).pop()),
    );
  }

  void _seremoni() {
    showBergenArk(
      context,
      title: A3PoengCopy.a3_poeng_liga_seremoni_title,
      subtitle: A3PoengCopy.a3_poeng_liga_seremoni_sub,
      rows: [for (final p in A3PoengCopy.a3_poeng_liga_premie_liste) BergenArkRow(label: p)],
      primary: BergenArkAction(label: 'Skjønner', onTap: () => Navigator.of(context).pop()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _league;
    final rows = _bydel ? (l?.bydelStandings ?? const <LeagueStanding>[]) : (l?.top ?? const <LeagueStanding>[]);

    return A3Scaffold(
      title: A3PoengCopy.a3_poeng_liga_title,
      subtitle: l == null ? null : (l.own != null ? A3PoengCopy.a3_poeng_liga_plass(l.own!.rank) : A3PoengCopy.a3_poeng_liga_ikke_med),
      trailing: TextButton(onPressed: _joinSheet, child: Text(A3PoengCopy.a3_poeng_liga_vilkaar, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orangeLight))),
      child: _loading
          ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    BergenChip(label: A3PoengCopy.a3_poeng_liga_hele, selected: !_bydel, onDark: true, onTap: () => setState(() => _bydel = false)),
                    const SizedBox(width: 8),
                    BergenChip(label: A3PoengCopy.a3_poeng_liga_bydel, selected: _bydel, onDark: true, onTap: () => setState(() => _bydel = true)),
                    const Spacer(),
                    if (l != null) Text('${l.participants} med', style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w700, color: const Color(0xFF9FD3DE))),
                  ],
                ),
                const SizedBox(height: 12),
                BergenCard(
                  onDark: true,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 36, child: Text(A3PoengCopy.a3_poeng_liga_pl, style: _th)),
                          Expanded(child: Text(A3PoengCopy.a3_poeng_liga_klatrer, style: _th)),
                          Text(l == null ? A3PoengCopy.a3_poeng_liga_poeng : A3PoengCopy.a3_poeng_liga_maaned(l.month), style: _th),
                        ],
                      ),
                      const Divider(color: BergenTokens.glassBorder, height: 12),
                      if (rows.isEmpty)
                        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Ingen klatrere ennå denne måneden.', style: BergenTokens.text(BergenTokens.textSmall, color: const Color(0xFFDCE9EC))))
                      else
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(width: 36, child: Text('${r.rank}', style: BergenTokens.display(BergenTokens.textBody, color: r.rank <= 3 ? BergenTokens.lantern : Colors.white))),
                                Expanded(child: Text('${l?.own?.userId == r.userId ? 'Deg' : 'Klatrer'}${r.bydel != null ? ' · ${r.bydel}' : ''}', style: BergenTokens.text(BergenTokens.textBody, weight: l?.own?.userId == r.userId ? FontWeight.w800 : FontWeight.w600, color: Colors.white))),
                                Text('${r.points}', style: BergenTokens.display(BergenTokens.textBody, color: Colors.white)),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
                if (l?.own != null && !rows.any((r) => r.userId == l!.own!.userId))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Du: ${l!.own!.rank}. plass · ${l.own!.points} poeng', style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w700, color: BergenTokens.mint)),
                  ),
                const A3Kicker(A3PoengCopy.a3_poeng_liga_premier),
                Text(A3PoengCopy.a3_poeng_liga_premier_sub, style: BergenTokens.text(BergenTokens.textSmall, color: const Color(0xFFDCE9EC))),
                const SizedBox(height: 8),
                for (final p in A3PoengCopy.a3_poeng_liga_premie_liste)
                  Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(p, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w600, color: Colors.white))),
                const SizedBox(height: 12),
                TextButton(onPressed: _seremoni, child: Text(A3PoengCopy.a3_poeng_liga_slutt, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w800, color: BergenTokens.orangeLight))),
                const SizedBox(height: 8),
                BergenCta3d(
                  label: l?.optedIn == true ? A3PoengCopy.a3_poeng_liga_navn : A3PoengCopy.a3_poeng_liga_bli_med,
                  icon: Icons.emoji_events_rounded,
                  onPressed: _joinSheet,
                ),
              ],
            ),
    );
  }

  TextStyle get _th => BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: const Color(0xFF9FD3DE));
}
