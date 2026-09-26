import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/chat_card_models.dart';
import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../kit/bergen_kit.dart';
import 'a3_scaffold.dart';
import 'meg_copy_a4.dart';
import 'meg_nivaa_card.dart';
import 'meg_pill.dart';

/// The Ark sheets the Meg tab opens (design `kArkVals`): Slik får du poeng,
/// Nivå, Navn i ligaen, Krev alltid kode, Anledninger, Ukeshandel / nivå 4,
/// Hjelp and Om Ægil. Each is a function so the screen stays a list of rows.
abstract final class MegSheets {
  /// `slikPoeng`: the earning rates, the ladder with "Du er her", the promise.
  static Future<void> slikPoeng(BuildContext context, PointsBalance balance) {
    final steps = balance.tiers;
    return showBergenArk<void>(
      context,
      onDark: true,
      title: A4MegCopy.a4_meg_slik_title,
      subtitle: A4MegCopy.a4_meg_slik_linje,
      body: Padding(padding: const EdgeInsets.only(bottom: 8), child: MegLadder(balance: balance)),
      rows: [
        for (final r in A4MegCopy.a4_meg_poengrater) BergenArkRow(label: r[0], value: r[1]),
        for (final s in steps)
          BergenArkRow(
            label: s.name,
            value: A4MegCopy.a4_meg_fra_poeng(s.threshold, A4MegCopy.a4_meg_nivaa_gaver[s.name] ?? ''),
            trailing: s.index == balance.tier ? A4MegCopy.a4_meg_du_er_her : null,
          ),
        const BergenArkRow(label: A4MegCopy.a4_meg_bruk_senker_aldri, value: A4MegCopy.a4_meg_bruk_senker_sub),
      ],
      primary: BergenArkAction(label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }

  /// `nivaa`: where you are and what the next rung unlocks.
  static Future<void> nivaa(BuildContext context, PointsBalance balance, {VoidCallback? onOpenPremiehylla}) {
    return showBergenArk<void>(
      context,
      onDark: true,
      title: A4MegCopy.a4_meg_nivaa_title,
      subtitle: A4MegCopy.a4_meg_nivaa_linje(balance.tierName),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegLadder(balance: balance),
          const SizedBox(height: 12),
          Text(
            balance.nextTierName == null || balance.pointsToNextTier == null ? A4MegCopy.a4_meg_hoyeste : A4MegCopy.a4_meg_til_neste(balance.pointsToNextTier!, balance.nextTierName!),
            style: BergenTokens.display(BergenTokens.textSection, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(A4MegCopy.a4_meg_nivaa_note, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
        ],
      ),
      primary: BergenArkAction(label: A4MegCopy.a4_meg_premiehylla, onTap: () {
        Navigator.of(context).pop();
        onOpenPremiehylla?.call();
      }),
    );
  }

  /// `ligaNavn` / `ligaBli`: pick a name shape and who may see it; saves through
  /// `points/league/name` (opting in first when needed).
  static Future<League?> ligaNavn(
    BuildContext context, {
    required PointsAppApi api,
    required League league,
    required String firstName,
    String? bydel,
  }) {
    final options = <String, String>{
      firstName: A4MegCopy.a4_meg_navn_fornavn,
      '$firstName ${firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : ''}.': A4MegCopy.a4_meg_navn_initial,
      if (bydel != null && bydel.isNotEmpty) '$firstName · $bydel': A4MegCopy.a4_meg_navn_bydel,
      'Klatrer ${league.own?.rank ?? 1}': A4MegCopy.a4_meg_navn_anonym,
    };
    var name = league.displayName ?? options.keys.first;
    var syn = league.visibility;

    return showBergenSheet<League?>(
      context,
      onDark: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          key: const Key('meg-liga-navn-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Text(league.optedIn ? A4MegCopy.a4_meg_navn_liga : A4MegCopy.a4_meg_liga_bli_title, style: BergenTokens.display(BergenTokens.textTitle, color: Colors.white)),
            const SizedBox(height: 4),
            Text(A4MegCopy.a4_meg_liga_navn_linje, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
            const SizedBox(height: 12),
            for (final e in options.entries)
              A3Row(
                key: Key('liga-navn-${options.keys.toList().indexOf(e.key)}'),
                title: e.key,
                subtitle: e.value,
                onTap: () => setState(() => name = e.key),
                trailing: Icon(name == e.key ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: name == e.key ? BergenTokens.mint : A3Ink.muted),
              ),
            const A3Kicker(A4MegCopy.a4_meg_syn_title),
            for (final s in A4MegCopy.a4_meg_ligasyn)
              A3Row(
                key: Key('liga-syn-${s[0]}'),
                title: s[1],
                subtitle: s[2],
                onTap: () => setState(() => syn = s[0]),
                trailing: Icon(syn == s[0] ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: syn == s[0] ? BergenTokens.mint : A3Ink.muted),
              ),
            const SizedBox(height: 8),
            MegPill(
              key: const Key('liga-navn-lagre'),
              label: league.optedIn ? A4MegCopy.a4_meg_lagre : A4MegCopy.a4_meg_bli_med,
              icon: Icons.emoji_events_rounded,
              onPressed: () async {
                if (!league.optedIn) await api.leagueOptIn(true);
                final updated = await api.setLeagueName(name: name, visibility: syn);
                if (ctx.mounted) Navigator.of(ctx).pop(updated);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// `kodeInnst`: explain, then Slå på / Slå av → `points/me/prefs`.
  static Future<bool?> kodeInnst(BuildContext context, {required bool on}) {
    return showBergenArk<bool>(
      context,
      onDark: true,
      title: A4MegCopy.a4_meg_krev_kode,
      subtitle: A4MegCopy.a4_meg_kode_linje,
      primary: BergenArkAction(label: on ? A4MegCopy.a4_meg_slaa_av : A4MegCopy.a4_meg_slaa_paa, onTap: () => Navigator.of(context).pop(!on)),
      secondary: BergenArkAction(label: A4MegCopy.a4_meg_avbryt, onTap: () => Navigator.of(context).pop()),
    );
  }

  /// `anledninger`: the list with Fjern, and "Legg til anledning".
  static Future<List<Occasion>?> anledninger(BuildContext context, {required AegilAppApi api, required List<Occasion> initial}) {
    var items = initial;
    return showBergenSheet<List<Occasion>>(
      context,
      onDark: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          key: const Key('meg-anledninger-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Text(A4MegCopy.a4_meg_anledninger, style: BergenTokens.display(BergenTokens.textTitle, color: Colors.white)),
            const SizedBox(height: 4),
            Text(A4MegCopy.a4_meg_anl_linje, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
            const SizedBox(height: 12),
            if (items.isEmpty) Text(A4MegCopy.a4_meg_anledninger_tom, style: BergenTokens.text(BergenTokens.textBody, color: Colors.white)),
            for (final o in items)
              A3Row(
                key: Key('anledning-${o.id}'),
                title: o.person,
                subtitle: '${o.label ?? ''} · ${_pretty(o.next ?? o.date)} · ${A4MegCopy.a4_meg_anledninger_paaminnelse}'.replaceFirst(RegExp(r'^ · '), ''),
                icon: Icons.cake_rounded,
                trailing: TextButton(
                  onPressed: () async {
                    final next = await api.removeOccasion(o.id);
                    if (ctx.mounted) setState(() => items = next);
                  },
                  child: Text(A4MegCopy.a4_meg_anl_fjern, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orangeLight)),
                ),
              ),
            A3Row(
              key: const Key('anledning-legg'),
              title: A4MegCopy.a4_meg_anl_legg,
              subtitle: A4MegCopy.a4_meg_anl_legg_sub,
              icon: Icons.add_rounded,
              onTap: () async {
                final added = await _leggTilAnledning(ctx, api);
                if (added != null && ctx.mounted) setState(() => items = added);
              },
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: () => Navigator.of(ctx).pop(items), child: Text(A4MegCopy.a4_meg_lukk, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w800, color: BergenTokens.mint))),
          ],
        ),
      ),
    );
  }

  static Future<List<Occasion>?> _leggTilAnledning(BuildContext context, AegilAppApi api) async {
    final person = TextEditingController();
    final label = TextEditingController();
    DateTime? date;
    return showBergenSheet<List<Occasion>>(
      context,
      onDark: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Text(A4MegCopy.a4_meg_anl_legg, style: BergenTokens.display(BergenTokens.textTitle, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(key: const Key('anledning-person'), controller: person, style: _field, decoration: _deco(A4MegCopy.a4_meg_anl_hvem)),
            const SizedBox(height: 8),
            TextField(key: const Key('anledning-label'), controller: label, style: _field, decoration: _deco(A4MegCopy.a4_meg_anl_hva)),
            const SizedBox(height: 8),
            A3Row(
              key: const Key('anledning-dato'),
              title: date == null ? A4MegCopy.a4_meg_anl_dato : _pretty(_iso(date!)),
              icon: Icons.event_rounded,
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
                if (picked != null) setState(() => date = picked);
              },
            ),
            MegPill(
              key: const Key('anledning-lagre'),
              label: A4MegCopy.a4_meg_lagre,
              onPressed: () async {
                if (person.text.trim().isEmpty || date == null) return;
                final list = await api.addOccasion(person: person.text.trim(), date: _iso(date!), label: label.text.trim().isEmpty ? null : label.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop(list);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// `ukeshandel`: the shopping list, and "Se ukens kurv" → nivå 4.
  static Future<void> ukeshandel(BuildContext context, {required List<ShoppingListItem> items, required int level, VoidCallback? onOpenAegilSettings}) {
    return showBergenArk<void>(
      context,
      onDark: true,
      title: A4MegCopy.a4_meg_handleliste,
      subtitle: items.isEmpty ? A4MegCopy.a4_meg_handleliste_tom : null,
      rows: [for (final i in items) BergenArkRow(label: '${i.qty > 1 ? '${i.qty} × ' : ''}${i.text}', value: i.done ? 'Kjøpt' : (i.addedByAgent ? 'Ægil la til' : null), icon: i.done ? Icons.check_circle_rounded : Icons.circle_outlined)],
      primary: BergenArkAction(
        label: A4MegCopy.a4_meg_se_ukens_kurv,
        onTap: () {
          Navigator.of(context).pop();
          if (level >= 4) {
            showBergenToast(context, A4MegCopy.a4_meg_fast, icon: Icons.shopping_basket_rounded);
          } else {
            nivaa4(context, onOpenAegilSettings: onOpenAegilSettings);
          }
        },
      ),
    );
  }

  /// `nivaa4`: what "Fast bestilling" means before it can be switched on.
  static Future<void> nivaa4(BuildContext context, {VoidCallback? onOpenAegilSettings}) {
    return showBergenArk<void>(
      context,
      onDark: true,
      title: A4MegCopy.a4_meg_nivaa4_title,
      subtitle: A4MegCopy.a4_meg_nivaa4_linje,
      rows: [for (final r in A4MegCopy.a4_meg_nivaa4_rader) BergenArkRow(label: r[0], value: r[1])],
      primary: BergenArkAction(label: A4MegCopy.a4_meg_til_aegil, onTap: () {
        Navigator.of(context).pop();
        onOpenAegilSettings?.call();
      }),
      secondary: BergenArkAction(label: A4MegCopy.a4_meg_avbryt, onTap: () => Navigator.of(context).pop()),
    );
  }

  /// `support`: Spør Ægil / Snakk med et menneske, and Om Ægil.
  static Future<void> hjelp(BuildContext context, {required VoidCallback onAegil, required VoidCallback onHuman}) {
    return showBergenArk<void>(
      context,
      onDark: true,
      title: A4MegCopy.a4_meg_hjelp_title,
      subtitle: A4MegCopy.a4_meg_hjelp_linje,
      rows: [
        BergenArkRow(label: A4MegCopy.a4_meg_spor_aegil, value: A4MegCopy.a4_meg_spor_aegil_sub, icon: Icons.auto_awesome_rounded, onTap: () {
          Navigator.of(context).pop();
          onAegil();
        }),
        BergenArkRow(label: A4MegCopy.a4_meg_menneske, value: A4MegCopy.a4_meg_menneske_sub, icon: Icons.support_agent_rounded, onTap: () {
          Navigator.of(context).pop();
          onHuman();
        }),
      ],
      primary: BergenArkAction(label: A4MegCopy.a4_meg_om_aegil, onTap: () {
        Navigator.of(context).pop();
        showBergenArk<void>(
          context,
          onDark: true,
          title: A4MegCopy.a4_meg_om_aegil,
          subtitle: A4MegCopy.a4_meg_om_aegil_linje,
          primary: BergenArkAction(label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
        );
      }),
    );
  }

  static TextStyle get _field => BergenTokens.text(BergenTokens.textBody, color: Colors.white);

  static InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: BergenTokens.text(BergenTokens.textBody, color: A3Ink.muted),
        filled: true,
        fillColor: BergenTokens.glassFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton), borderSide: const BorderSide(color: BergenTokens.glassBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton), borderSide: const BorderSide(color: BergenTokens.glassBorder)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  static String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const List<String> _months = ['januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'];

  /// `2027-03-14` → `14. mars`
  static String _pretty(String iso) {
    final p = iso.split('-');
    if (p.length < 3) return iso;
    final m = int.tryParse(p[1]) ?? 0;
    final d = int.tryParse(p[2]) ?? 0;
    if (m < 1 || m > 12) return iso;
    return '$d. ${_months[m - 1]}';
  }

  static String pretty(String iso) => _pretty(iso);
}
