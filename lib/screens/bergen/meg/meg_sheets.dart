import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/chat_card_models.dart';
import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../common/home/bergen/bergen_kit.dart' show bergenSvg;
import '../kit/bergen_kit.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';
import 'meg_mark.dart';
import 'meg_nivaa_card.dart' show medalFor;
import 'meg_shine.dart';

/// Every Ark the Meg tab opens (design `kArkVals`), on the design's own sheet
/// shell ([MegArk]): Gullbilletten, Vilkår, Nivå, Slik får du poeng, Navn i
/// ligaen, Krev alltid kode, Anledninger, Ukeshandel, Fast bestilling,
/// Hjelp / Om Ægil, Språk, Betaling and Adresser.
abstract final class MegSheets {
  // ---------------------------------------------------------------- Gullbilletten

  /// `billett`: the code card, "BILLETTENE DINE" (count, points, the ladder
  /// step with its tick bar, the row of friend tickets) and Vilkår / Del.
  static Future<void> billett(BuildContext context, {required Referral referral, required VoidCallback onCopy, required VoidCallback onShare}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-billett-sheet'),
      title: A4MegCopy.a4_meg_billett_title,
      subtitle: A4MegCopy.a4_meg_billett_linje(referral.pointsForThem, referral.pointsForMe),
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegArkCodeCard(label: A4MegCopy.a4_meg_delingskode, code: referral.code, onCopy: onCopy),
          _BillettBoard(referral: referral, onNext: onShare),
        ],
      ),
      secondary: MegArkButton(key: const Key('meg-billett-vilkaar'), label: A4MegCopy.a4_meg_vilkaar, onTap: () => vilkaar(context)),
      primary: MegArkButton(
        key: const Key('meg-billett-del'),
        label: A4MegCopy.a4_meg_del_billetten,
        gradient: MegArkInk.goldCta,
        onTap: () {
          Navigator.of(context).pop();
          onShare();
        },
      ),
    );
  }

  /// `vilkaar`: the points terms, stated as the backend enforces them.
  static Future<void> vilkaar(BuildContext context) {
    return showMegArk<void>(
      context,
      key: const Key('meg-vilkaar-sheet'),
      title: A4MegCopy.a4_meg_vilkaar_title,
      subtitle: A4MegCopy.a4_meg_vilkaar_linje,
      body: (ctx, _) => Column(children: [for (final r in A4MegCopy.a4_meg_vilkaar_rader) MegArkRow(title: r[0], sub: r[1])]),
      primary: MegArkButton(label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }

  // ---------------------------------------------------------------- Nivå

  /// `nivaa`: the four medals on their track with thresholds and NÅ, then the
  /// detail card (distance, bar, earned in 12 months, the three prizes the
  /// next tier opens, the review line and the promise).
  static Future<void> nivaa(BuildContext context, PointsBalance balance, {List<PrizePreview> opens = const [], VoidCallback? onOpenPremiehylla}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-nivaa-sheet'),
      title: A4MegCopy.a4_meg_nivaa_title,
      subtitle: A4MegCopy.a4_meg_nivaa_linje(balance.tierName),
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegArkCard(padding: const EdgeInsets.fromLTRB(13, 16, 13, 14), child: MegMedalLadder(balance: balance)),
          _NivaaDetail(balance: balance, opens: opens, onOpenPremiehylla: onOpenPremiehylla),
        ],
      ),
    );
  }

  /// `slikPoeng`: the medal ladder, the earning rates, each tier, the promise.
  static Future<void> slikPoeng(BuildContext context, PointsBalance balance) {
    return showMegArk<void>(
      context,
      key: const Key('meg-slik-sheet'),
      title: A4MegCopy.a4_meg_slik_title,
      subtitle: A4MegCopy.a4_meg_slik_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegArkCard(padding: const EdgeInsets.fromLTRB(13, 16, 13, 14), child: MegMedalLadder(balance: balance)),
          for (final r in A4MegCopy.a4_meg_poengrater) MegArkRow(title: r[0], sub: r[1]),
          for (final s in balance.tiers)
            MegArkRow(
              title: s.name,
              sub: A4MegCopy.a4_meg_fra_poeng(s.threshold, A4MegCopy.a4_meg_nivaa_gaver[s.name] ?? ''),
              value: s.index == balance.tier ? A4MegCopy.a4_meg_du_er_her : null,
              selected: s.index == balance.tier,
            ),
          const MegArkRow(title: A4MegCopy.a4_meg_bruk_senker_aldri, sub: A4MegCopy.a4_meg_bruk_senker_sub),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Liga

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

    return showMegArk<League?>(
      context,
      key: const Key('meg-liga-navn-sheet'),
      title: league.optedIn ? A4MegCopy.a4_meg_navn_liga : A4MegCopy.a4_meg_liga_bli_title,
      subtitle: A4MegCopy.a4_meg_liga_navn_linje,
      body: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in options.entries)
            MegArkRow(
              key: Key('liga-navn-${options.keys.toList().indexOf(e.key)}'),
              title: e.key,
              sub: e.value,
              selected: name == e.key,
              onTap: () => setState(() => name = e.key),
            ),
          const _ArkKicker(A4MegCopy.a4_meg_syn_title),
          for (final s in A4MegCopy.a4_meg_ligasyn)
            MegArkRow(key: Key('liga-syn-${s[0]}'), title: s[1], sub: s[2], selected: syn == s[0], onTap: () => setState(() => syn = s[0])),
        ],
      ),
      secondary: MegArkButton(label: A4MegCopy.a4_meg_liga_vilkaar, onTap: () => vilkaar(context)),
      primary: MegArkButton(
        key: const Key('liga-navn-lagre'),
        label: league.optedIn ? A4MegCopy.a4_meg_lagre : A4MegCopy.a4_meg_bli_med,
        onTap: () async {
          final nav = Navigator.of(context);
          if (!league.optedIn) await api.leagueOptIn(true);
          final updated = await api.setLeagueName(name: name, visibility: syn);
          nav.pop(updated);
        },
      ),
    );
  }

  // ---------------------------------------------------------------- Innstillinger

  /// `kodeInnst`: explain, then Slå på / Slå av → `points/me/prefs`.
  static Future<bool?> kodeInnst(BuildContext context, {required bool on}) {
    return showMegArk<bool>(
      context,
      key: const Key('meg-kode-sheet'),
      title: A4MegCopy.a4_meg_krev_kode,
      subtitle: A4MegCopy.a4_meg_kode_linje,
      secondary: MegArkButton(label: A4MegCopy.a4_meg_avbryt, onTap: () => Navigator.of(context).pop()),
      primary: MegArkButton(label: on ? A4MegCopy.a4_meg_slaa_av : A4MegCopy.a4_meg_slaa_paa, onTap: () => Navigator.of(context).pop(!on)),
    );
  }

  /// `anledninger`: the list with Fjern, and "Legg til anledning".
  static Future<List<Occasion>?> anledninger(BuildContext context, {required AegilAppApi api, required List<Occasion> initial}) {
    var items = initial;
    return showMegArk<List<Occasion>>(
      context,
      key: const Key('meg-anledninger-sheet'),
      title: A4MegCopy.a4_meg_anledninger,
      subtitle: A4MegCopy.a4_meg_anl_linje,
      body: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in items)
            MegArkRow(
              key: Key('anledning-${o.id}'),
              title: o.person,
              sub: [if (o.label != null && o.label!.isNotEmpty) o.label!, pretty(o.next ?? o.date), A4MegCopy.a4_meg_anledninger_paaminnelse].join(' · '),
              trailing: GestureDetector(
                onTap: () async {
                  final next = await api.removeOccasion(o.id);
                  setState(() => items = next);
                },
                child: Text(A4MegCopy.a4_meg_anl_fjern, style: BergenTokens.text(13, weight: FontWeight.w800, color: const Color(0xFFB9441A))),
              ),
            ),
          MegArkRow(
            key: const Key('anledning-legg'),
            title: A4MegCopy.a4_meg_anl_legg,
            sub: A4MegCopy.a4_meg_anl_legg_sub,
            value: '+',
            onTap: () async {
              final added = await _leggTilAnledning(ctx, api);
              if (added != null) setState(() => items = added);
            },
          ),
        ],
      ),
      primary: MegArkButton(label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop(items)),
    );
  }

  static Future<List<Occasion>?> _leggTilAnledning(BuildContext context, AegilAppApi api) {
    final person = TextEditingController();
    final label = TextEditingController();
    DateTime? date;
    return showMegArk<List<Occasion>>(
      context,
      key: const Key('meg-anledning-ny-sheet'),
      title: A4MegCopy.a4_meg_anl_legg,
      subtitle: A4MegCopy.a4_meg_anl_legg_sub,
      body: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ArkField(key: const Key('anledning-person'), controller: person, hint: A4MegCopy.a4_meg_anl_hvem),
          _ArkField(key: const Key('anledning-label'), controller: label, hint: A4MegCopy.a4_meg_anl_hva),
          MegArkRow(
            key: const Key('anledning-dato'),
            title: date == null ? A4MegCopy.a4_meg_anl_dato : pretty(_iso(date!)),
            value: date == null ? '›' : null,
            onTap: () async {
              final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
              if (picked != null) setState(() => date = picked);
            },
          ),
        ],
      ),
      secondary: MegArkButton(label: A4MegCopy.a4_meg_avbryt, onTap: () => Navigator.of(context).pop()),
      primary: MegArkButton(
        key: const Key('anledning-lagre'),
        label: A4MegCopy.a4_meg_lagre,
        onTap: () async {
          if (person.text.trim().isEmpty || date == null) return;
          final nav = Navigator.of(context);
          final list = await api.addOccasion(person: person.text.trim(), date: _iso(date!), label: label.text.trim().isEmpty ? null : label.text.trim());
          nav.pop(list);
        },
      ),
    );
  }

  /// `ukeshandel`: the shopping list, and "Se ukens kurv" → nivå 4.
  static Future<void> ukeshandel(BuildContext context, {required List<ShoppingListItem> items, required int level, VoidCallback? onOpenAegilSettings}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-ukeshandel-sheet'),
      title: A4MegCopy.a4_meg_handleliste,
      subtitle: items.isEmpty ? A4MegCopy.a4_meg_handleliste_tom : null,
      body: items.isEmpty
          ? null
          : (ctx, _) => Column(
                children: [
                  for (final i in items)
                    MegArkRow(
                      title: '${i.qty > 1 ? '${i.qty} × ' : ''}${i.text}',
                      sub: i.addedByAgent ? A4MegCopy.a4_meg_aegil_la_til : null,
                      value: i.done ? A4MegCopy.a4_meg_kjopt : null,
                    ),
                ],
              ),
      primary: MegArkButton(
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
    return showMegArk<void>(
      context,
      key: const Key('meg-nivaa4-sheet'),
      title: A4MegCopy.a4_meg_nivaa4_title,
      subtitle: A4MegCopy.a4_meg_nivaa4_linje,
      body: (ctx, _) => Column(children: [for (final r in A4MegCopy.a4_meg_nivaa4_rader) MegArkRow(title: r[0], sub: r[1])]),
      secondary: MegArkButton(label: A4MegCopy.a4_meg_avbryt, onTap: () => Navigator.of(context).pop()),
      primary: MegArkButton(
        label: A4MegCopy.a4_meg_til_aegil,
        onTap: () {
          Navigator.of(context).pop();
          onOpenAegilSettings?.call();
        },
      ),
    );
  }

  /// `support` + `ai`: Spør Ægil / Snakk med et menneske / Om Ægil.
  static Future<void> hjelp(BuildContext context, {required VoidCallback onAegil, required VoidCallback onHuman}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-hjelp-sheet'),
      title: A4MegCopy.a4_meg_hjelp_title,
      subtitle: A4MegCopy.a4_meg_hjelp_linje,
      body: (ctx, _) => Column(
        children: [
          MegArkRow(title: A4MegCopy.a4_meg_spor_aegil, sub: A4MegCopy.a4_meg_spor_aegil_sub, value: '›', onTap: () {
            Navigator.of(context).pop();
            onAegil();
          }),
          MegArkRow(title: A4MegCopy.a4_meg_menneske, sub: A4MegCopy.a4_meg_menneske_sub, value: '›', onTap: () {
            Navigator.of(context).pop();
            onHuman();
          }),
          MegArkRow(title: A4MegCopy.a4_meg_om_aegil, sub: A4MegCopy.a4_meg_om_aegil_sub, value: '›', onTap: () => omAegil(context)),
        ],
      ),
    );
  }

  static Future<void> omAegil(BuildContext context) {
    return showMegArk<void>(
      context,
      key: const Key('meg-om-aegil-sheet'),
      title: A4MegCopy.a4_meg_om_aegil,
      subtitle: A4MegCopy.a4_meg_om_aegil_linje,
      primary: MegArkButton(label: A4MegCopy.a4_meg_vilkaar, onTap: () => vilkaar(context)),
    );
  }

  /// `sprak`: the app languages; picking one switches the app.
  static Future<String?> spraak(BuildContext context, {required String current}) {
    return showMegArk<String>(
      context,
      key: const Key('meg-spraak-sheet'),
      title: A4MegCopy.a4_meg_spraak,
      subtitle: A4MegCopy.a4_meg_spraak_linje,
      body: (ctx, _) => Column(
        children: [
          for (final e in A4MegCopy.a4_meg_spraak_valg)
            MegArkRow(
              key: Key('spraak-${e[0]}'),
              title: e[1],
              selected: e[0] == current || (current == 'nb' && e[0] == 'no'),
              onTap: () => Navigator.of(context).pop(e[0]),
            ),
        ],
      ),
    );
  }

  /// `betaling`: Vipps first, cards as the fallback, and the card screen.
  static Future<void> betaling(BuildContext context, {required List<String> cards, required VoidCallback onManage}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-betaling-sheet'),
      title: A4MegCopy.a4_meg_betaling,
      subtitle: A4MegCopy.a4_meg_betaling_linje,
      body: (ctx, _) => Column(
        children: [
          const MegArkRow(title: A4MegCopy.a4_meg_betaling_vipps, sub: A4MegCopy.a4_meg_betaling_standard, selected: true),
          for (final c in cards) MegArkRow(title: c, value: A4MegCopy.a4_meg_reserve),
          MegArkRow(key: const Key('betaling-kort'), title: A4MegCopy.a4_meg_betaling_kort, value: '›', onTap: () {
            Navigator.of(context).pop();
            onManage();
          }),
        ],
      ),
    );
  }

  /// `adresser`: the saved addresses and "Legg til adresse".
  static Future<void> adresser(BuildContext context, {required List<String> addresses, required VoidCallback onManage, required VoidCallback onAdd}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-adresser-sheet'),
      title: A4MegCopy.a4_meg_adresser,
      subtitle: A4MegCopy.a4_meg_adresser_linje,
      body: (ctx, _) => Column(
        children: [
          for (final a in addresses)
            MegArkRow(title: a, sub: A4MegCopy.a4_meg_adresser_bare, value: '›', onTap: () {
              Navigator.of(context).pop();
              onManage();
            }),
          MegArkRow(key: const Key('adresser-legg'), title: A4MegCopy.a4_meg_adresser_tom, value: '+', onTap: () {
            Navigator.of(context).pop();
            onAdd();
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  static String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const List<String> _months = ['januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'];

  /// `2027-03-14` → `14. mars`
  static String pretty(String iso) {
    final p = iso.split('T').first.split('-');
    if (p.length < 3) return iso;
    final m = int.tryParse(p[1]) ?? 0;
    final d = int.tryParse(p[2]) ?? 0;
    if (m < 1 || m > 12) return iso;
    return '$d. ${_months[m - 1]}';
  }
}

class _ArkKicker extends StatelessWidget {
  const _ArkKicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
      child: Text(text, style: megInter(11, FontWeight.w800, letterSpacing: .7, color: MegArkInk.faint)),
    );
  }
}

class _ArkField extends StatelessWidget {
  const _ArkField({super.key, required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        style: BergenTokens.text(14, weight: FontWeight.w700, color: MegArkInk.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: BergenTokens.text(14, weight: FontWeight.w600, color: MegArkInk.faint),
          filled: true,
          fillColor: Colors.white.withValues(alpha: .62),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: MegArkInk.teal, width: 1.5)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Nivå parts

/// The Ark's medal row (design `kNivStige`): 46px medals on a thin track, the
/// fill up to the current tier, names, thresholds, and the NÅ badge.
class MegMedalLadder extends StatelessWidget {
  const MegMedalLadder({super.key, required this.balance});

  final PointsBalance balance;

  @override
  Widget build(BuildContext context) {
    final steps = balance.tiers;
    if (steps.isEmpty) return const SizedBox.shrink();
    final n = steps.length;
    final pct = balance.tierProgress;
    final fill = n <= 1 ? 1.0 : ((balance.tier + pct) / (n - 1)).clamp(0.0, 1.0);

    return LayoutBuilder(
      key: const Key('meg-medal-ladder'),
      builder: (context, c) {
        final inset = c.maxWidth / n / 2;
        final track = c.maxWidth - inset * 2;
        return Stack(
          children: [
            Positioned(
              left: inset,
              right: inset,
              top: 21,
              child: Container(height: 4, decoration: BoxDecoration(color: MegArkInk.ink.withValues(alpha: .1), borderRadius: BorderRadius.circular(99))),
            ),
            Positioned(
              left: inset,
              top: 21,
              child: Container(
                height: 4,
                width: track * fill,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(colors: [Color(0xFFC98A62), Color(0xFFC7CDD1), Color(0xFFE7C471), Color(0xFFAEB9C2)], stops: [0, .38, .74, 1]),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in steps) Expanded(child: _LadderMedal(step: s, current: s.index == balance.tier, reached: s.index <= balance.tier)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LadderMedal extends StatelessWidget {
  const _LadderMedal({required this.step, required this.current, required this.reached});

  final TierStep step;
  final bool current;
  final bool reached;

  /// `saturate(.22) brightness(1.09)`.
  static const List<double> _desaturate = [
    .45, .43, .06, 0, 12, //
    .13, .75, .06, 0, 12,
    .13, .43, .38, 0, 12,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final m = medalFor(step.name);
    final coin = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.32, -.48), colors: m.gradient, stops: m.stops),
        border: current ? Border.all(color: const Color.fromRGBO(242, 193, 78, .95), width: 3) : null,
        boxShadow: const [BoxShadow(color: Color.fromRGBO(35, 32, 29, .45), offset: Offset(0, 2), blurRadius: 5, spreadRadius: -3)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            right: 12,
            top: 5,
            child: Container(
              height: 13,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: .62), Colors.white.withValues(alpha: 0)]),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF5A3C0A).withValues(alpha: .4), width: 1.3))),
            ),
          ),
          MegMark(color: m.ink, size: 28),
        ],
      ),
    );

    return Column(
      children: [
        Opacity(
          opacity: reached ? 1 : .5,
          child: reached
              ? (current ? MegShine(borderRadius: BorderRadius.circular(46), period: const Duration(seconds: 3), bandFraction: .4, opacity: .45, child: coin) : coin)
              : ColorFiltered(colorFilter: const ColorFilter.matrix(_desaturate), child: coin),
        ),
        const SizedBox(height: 6),
        Text(step.name, maxLines: 1, style: BergenTokens.text(11.5, weight: FontWeight.w800, color: current ? MegArkInk.ink : (reached ? const Color(0xFF4E4943) : MegArkInk.muted))),
        const SizedBox(height: 4),
        Text(step.threshold == 0 ? '0' : A4MegCopy.nf(step.threshold), style: megInter(10, FontWeight.w800, color: MegArkInk.faint)),
        const SizedBox(height: 5),
        Container(
          constraints: const BoxConstraints(minHeight: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: current ? MegArkInk.ink : Colors.transparent, borderRadius: BorderRadius.circular(999)),
          child: Text(current ? A4MegCopy.a4_meg_naa : '', style: megInter(8.5, FontWeight.w800, letterSpacing: .9, color: Color(0xFFFFF7E4))),
        ),
      ],
    );
  }
}

class _NivaaDetail extends StatelessWidget {
  const _NivaaDetail({required this.balance, required this.opens, this.onOpenPremiehylla});

  final PointsBalance balance;
  final List<PrizePreview> opens;
  final VoidCallback? onOpenPremiehylla;

  static const List<List<Color>> _tints = [
    [Color(0xFFCFE3E8), Color(0xFF2B5F6D)],
    [Color(0xFFFBE0C4), Color(0xFFC07A3A)],
    [Color(0xFFDCE9EC), Color(0xFF5C8391)],
  ];

  /// The design's icon per prize and its size in the tile (`iw × ih` scaled .5).
  static (String, double, double) _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('båt') || n.contains('baat') || n.contains('skip')) return ('meg_langskip3d', 48, 25);
    if (n.contains('fisk') || n.contains('reke') || n.contains('suppe')) return ('meg_ico_fisk', 50, 33);
    if (n.contains('middag') || n.contains('mat') || n.contains('pizza') || n.contains('bolle') || n.contains('kaffe')) return ('meg_ico_mat', 37, 35);
    if (n.contains('gave') || n.contains('bok') || n.contains('keramikk')) return ('meg_ico_gaver', 35, 37);
    return ('meg_varde3d', 29, 36);
  }

  /// Tile tint per prize (design PREMIER `tint`, 160deg).
  static List<Color> _tint(String name, int i) {
    final n = name.toLowerCase();
    if (n.contains('båt') || n.contains('baat')) return const [Color(0xFFCFE3E8), Color(0xFF2B5F6D)];
    if (n.contains('middag') || n.contains('mat') || n.contains('pizza')) return const [Color(0xFFFBE0C4), Color(0xFFC07A3A)];
    if (n.contains('fløy') || n.contains('floy') || n.contains('fjell')) return const [Color(0xFFDCE9EC), Color(0xFF5C8391)];
    return _tints[i % _tints.length];
  }

  @override
  Widget build(BuildContext context) {
    final b = balance;
    final hasNext = b.nextTierName != null && b.pointsToNextTier != null;
    final pct = b.tierProgress;
    final three = opens.take(3).toList();

    return MegArkCard(
      padding: const EdgeInsets.fromLTRB(13, 15, 13, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(hasNext ? A4MegCopy.nf(b.pointsToNextTier!) : A4MegCopy.nf(b.earned12m), style: BergenTokens.display(22, weight: FontWeight.w800, color: MegArkInk.ink, letterSpacingEm: -0.03, height: 1)),
              const SizedBox(width: 7),
              Expanded(child: Text(hasNext ? A4MegCopy.a4_meg_poeng_til(b.nextTierName!) : A4MegCopy.a4_meg_hoyeste_linje, style: BergenTokens.text(12.5, weight: FontWeight.w800, color: MegArkInk.ink, height: 1.25))),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            height: 9,
            width: double.infinity,
            decoration: BoxDecoration(color: MegArkInk.ink.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(colors: [Color(0xFFF2C14E), Color(0xFFE0A32C)]),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .6))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(A4MegCopy.a4_meg_opptjent_12(b.earned12m), style: BergenTokens.text(12, weight: FontWeight.w700, color: MegArkInk.sub)),
          const SizedBox(height: 16),
          Text(hasNext ? A4MegCopy.a4_meg_da_aapner : A4MegCopy.a4_meg_hele_hylla, style: BergenTokens.text(12.5, weight: FontWeight.w800, color: MegArkInk.ink)),
          if (three.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  Expanded(child: i < three.length ? _prizeTile(context, i, three[i]) : const SizedBox.shrink()),
                ],
              ],
            ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: MegArkInk.ink.withValues(alpha: .08)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.reviewAt != null && b.tier > 0) ...[
                  Text(
                    b.keepGap > 0
                        ? A4MegCopy.a4_meg_vurdering_gap(MegSheets.pretty(b.reviewAt!.toIso8601String()), b.keepGap, b.tierName)
                        : A4MegCopy.a4_meg_vurdering(MegSheets.pretty(b.reviewAt!.toIso8601String()), b.tierName),
                    key: const Key('nivaa-vurdering'),
                    style: BergenTokens.text(12, weight: FontWeight.w700, color: MegArkInk.sub, height: 1.45),
                  ),
                  const SizedBox(height: 7),
                ],
                Text(A4MegCopy.a4_meg_nivaa_note_punkt, style: BergenTokens.text(12, weight: FontWeight.w800, color: MegArkInk.green, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prizeTile(BuildContext context, int i, PrizePreview p) {
    return GestureDetector(
      key: Key('nivaa-premie-$i'),
      onTap: onOpenPremiehylla == null
          ? null
          : () {
              Navigator.of(context).pop();
              onOpenPremiehylla!();
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(begin: const Alignment(-.34, -.94), end: const Alignment(.34, .94), colors: _tint(p.name, i)),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(60, 40, 15, .45), offset: Offset(0, 4), blurRadius: 9, spreadRadius: -5)],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: RadialGradient(center: const Alignment(-.44, -.88), radius: 1.1, colors: [Colors.white.withValues(alpha: .55), Colors.white.withValues(alpha: 0)], stops: const [0, .6]),
                    ),
                  ),
                ),
                Center(
                  child: Builder(builder: (_) {
                    final (asset, w, h) = _icon(p.name);
                    return bergenSvg(asset, width: w, height: h);
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: BergenTokens.text(10.5, weight: FontWeight.w800, color: MegArkInk.ink, height: 1.25)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Gullbilletten parts

/// "BILLETTENE DINE" (design `kArkErBrygge`).
class _BillettBoard extends StatelessWidget {
  const _BillettBoard({required this.referral, required this.onNext});

  final Referral referral;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final r = referral;
    final total = r.qualifiedTotal;
    final steps = r.ladder;
    final reached = steps.where((s) => total >= s.at).toList();
    final naa = reached.isEmpty ? null : reached.last;
    final neste = steps.where((s) => total < s.at).firstOrNull;
    final forrige = naa?.at ?? 0;
    final span = neste == null ? 1 : (neste.at - forrige).clamp(1, 1 << 30);
    final pct = neste == null ? 1.0 : ((total - forrige) / span).clamp(0.0, 1.0);
    final points = r.pointsEarned > 0 ? r.pointsEarned : total * r.pointsForMe;

    return Container(
      key: const Key('meg-billett-board'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(begin: Alignment(-.2, -1), end: Alignment(.2, 1), colors: [Color(0xFFFFFCF2), Color(0xFFF6EFDD), Color(0xFFEFE3C6)], stops: [0, .58, 1]),
        border: Border.all(color: Colors.white.withValues(alpha: .9)),
        boxShadow: const [BoxShadow(color: Color(0xFFE9E1D0), offset: Offset(0, 2)), BoxShadow(color: Color.fromRGBO(150, 120, 70, .2), offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(A4MegCopy.a4_meg_billettene_dine, style: megInter(11, FontWeight.w800, letterSpacing: .66, color: Color(0xFF7A5A16)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF8E4), Color(0xFFEFDBA4)]),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(150, 110, 20, .35), offset: Offset(0, 1.5))],
                ),
                child: Text(r.monthlyCap > 0 ? A4MegCopy.a4_meg_maks_mnd(r.monthlyCap) : A4MegCopy.a4_meg_ingen_grense, style: megInter(10, FontWeight.w800, color: Color(0xFF3A2708))),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$total', key: const Key('meg-billett-antall'), style: BergenTokens.display(40, weight: FontWeight.w800, color: const Color(0xFF3A2708), letterSpacingEm: -0.04, height: .92)),
              const SizedBox(width: 9),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(A4MegCopy.a4_meg_venner_vervet, style: megInter(12.5, FontWeight.w800, color: Color(0xFF3F2C06), height: 1.2)),
                      const SizedBox(height: 2),
                      Text(A4MegCopy.a4_meg_vervet_poeng(points, r.pointsForMe), style: megInter(10.5, FontWeight.w700, color: Color(0xFF5A4010))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _LadderStep(naa: naa, neste: neste, total: total, pct: pct, forrige: forrige),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 122,
            child: ListView(
              key: const Key('meg-billett-rad'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(bottom: 6, top: 2),
              children: [
                _FriendTicket.next(onTap: onNext, points: r.pointsForMe),
                for (final f in r.friends.reversed) ...[const SizedBox(width: 8), _FriendTicket.friend(friend: f, points: r.pointsForMe)],
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.only(top: 11),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(120, 80, 10, .22)))),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(center: Alignment(-.32, -.44), colors: [Color(0xFFFFF6DE), Color(0xFFD69A23)])),
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(A4MegCopy.a4_meg_verv_mnd(r.qualifiedThisMonth, r.monthlyCap), style: megInter(11, FontWeight.w800, color: Color(0xFF3A2708), height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LadderStep extends StatelessWidget {
  const _LadderStep({required this.naa, required this.neste, required this.total, required this.pct, required this.forrige});

  final VervStep? naa;
  final VervStep? neste;
  final int total;
  final double pct;
  final int forrige;

  @override
  Widget build(BuildContext context) {
    final n = neste == null ? 1 : (neste!.at - forrige).clamp(1, 1 << 30);
    final ticks = <double>[for (var i = 1; i < (n < 12 ? n : 12); i++) i / n];
    final metal = naa == null ? null : (naa!.at >= 25 ? medalFor('Gull') : (naa!.at >= 10 ? medalFor('Sølv') : medalFor('Bronse')));

    return Container(
      key: const Key('meg-billett-stige'),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        // linear-gradient(180deg,#FFF8E4,#F2E2B6) with the inset top light and
        // the inset bottom shade (inset 0 -2px 4px rgba(120,80,10,.18)).
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF8E4), Color(0xFFF5E8C3), Color(0xFFF2E2B6), Color(0xFFE6D19C)],
          stops: [0, .025, .6, .94, 1],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // No step yet: rgba(120,80,10,.12) on the cream, drawn opaque so the
                  // shadow cannot show through (CSS never paints it under the fill).
                  color: metal == null ? const Color(0xFFEBDDBA) : null,
                  gradient: metal == null ? null : RadialGradient(center: const Alignment(-.32, -.48), colors: metal.gradient, stops: metal.stops),
                  boxShadow: metal == null ? null : const [BoxShadow(color: Color.fromRGBO(120, 80, 10, .55), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2)],
                ),
                child: Center(child: _Star(color: metal == null ? const Color(0xFF7A5A16) : (naa!.at >= 10 ? const Color(0xFF3A2708) : const Color(0xFFFFF3E4)))),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(naa == null ? A4MegCopy.a4_meg_ingen_merke : A4MegCopy.a4_meg_naadd(naa!.name), style: megInter(9.5, FontWeight.w800, letterSpacing: .95, color: Color(0xFF7A5A16))),
                    const SizedBox(height: 2),
                    Text(
                      neste == null ? A4MegCopy.a4_meg_toppen : A4MegCopy.a4_meg_neste_billett(neste!.name, neste!.at, neste!.bonus),
                      style: megInter(12, FontWeight.w800, color: Color(0xFF3A2708), height: 1.25),
                    ),
                  ],
                ),
              ),
              if (neste != null) Text(A4MegCopy.a4_meg_igjen(neste!.at - total), style: megInter(11, FontWeight.w800, color: Color(0xFF5A4010))),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) => Container(
              key: const Key('meg-billett-stige-bar'),
              height: 9,
              width: c.maxWidth,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromRGBO(120, 80, 10, .26), Color.fromRGBO(120, 80, 10, .14), Color.fromRGBO(120, 80, 10, .12)],
                  stops: [0, .45, 1],
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 9,
                    width: c.maxWidth * pct,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(colors: [Color(0xFFF2C14E), Color(0xFFD69A23)]),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .6))),
                    ),
                  ),
                  for (final t in ticks) Positioned(left: c.maxWidth * t, top: 0, bottom: 0, child: Container(width: 1.5, color: const Color.fromRGBO(120, 80, 10, .26))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Kind { next, downloaded, delivered }

/// A ticket in the row: "Neste venn" (outline, dark plus) or a friend (lastet
/// ned / levert — the delivered one in gold with a shine).
class _FriendTicket extends StatelessWidget {
  const _FriendTicket._({required this.name, required this.status, required this.kind, this.onTap});

  factory _FriendTicket.next({required VoidCallback onTap, required int points}) =>
      _FriendTicket._(name: A4MegCopy.a4_meg_neste_venn, status: '+$points poeng', kind: _Kind.next, onTap: onTap);

  factory _FriendTicket.friend({required VervFriend friend, required int points}) => _FriendTicket._(
        name: friend.name,
        status: friend.delivered ? '+$points poeng' : A4MegCopy.a4_meg_lastet_ned,
        kind: friend.delivered ? _Kind.delivered : _Kind.downloaded,
      );

  final String name;
  final String status;
  final _Kind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final delivered = kind == _Kind.delivered;
    final downloaded = kind == _Kind.downloaded;
    const notch = Color(0xFFF8F1DF);

    final body = Container(
      width: 96,
      padding: const EdgeInsets.fromLTRB(8, 11, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: kind == _Kind.next ? Colors.white.withValues(alpha: .55) : null,
        gradient: delivered
            ? const LinearGradient(begin: Alignment(-.4, -1), end: Alignment(.4, 1), colors: [Color(0xFFFFF3D0), Color(0xFFF2D591), Color(0xFFDCAE43)], stops: [0, .46, 1])
            : downloaded
                ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFBF5E5), Color(0xFFF3E3BE)], stops: [.42, 1])
                : null,
        border: Border.all(
          color: kind == _Kind.next ? const Color.fromRGBO(120, 80, 10, .3) : (delivered ? const Color.fromRGBO(201, 155, 42, .55) : const Color.fromRGBO(201, 155, 42, .4)),
          width: 1.5,
        ),
        boxShadow: delivered ? const [BoxShadow(color: Color(0xFFC99B2A), offset: Offset(0, 2)), BoxShadow(color: Color.fromRGBO(120, 80, 10, .32), offset: Offset(0, 4))] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, right: 0, top: 24, child: CustomPaint(size: const Size(80, 1.5), painter: _DashH(color: Color.fromRGBO(120, 80, 10, delivered ? .4 : .22)))),
          const Positioned(left: -13, top: 19, child: _Notch(color: notch)),
          const Positioned(right: -13, top: 19, child: _Notch(color: notch)),
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kind == _Kind.next
                      ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B5120), Color(0xFF463316)])
                      : delivered
                          ? const RadialGradient(center: Alignment(-.32, -.48), colors: [Color(0xFFFFFCF0), Color(0xFFF2D591), Color(0xFFC99B2A)], stops: [0, .55, 1])
                          : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF6E9C6), Color(0xFFE3CE97)]),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(120, 80, 10, .6), offset: Offset(0, 2), blurRadius: 5, spreadRadius: -2)],
                ),
                child: Icon(
                  kind == _Kind.next ? Icons.add_rounded : (delivered ? Icons.check_rounded : Icons.download_rounded),
                  size: 14,
                  color: kind == _Kind.next ? const Color(0xFFFBE8B4) : const Color(0xFF5A4010),
                ),
              ),
              const SizedBox(height: 17),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: megInter(12.5, FontWeight.w800, color: Color(0xFF4A3208))),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(120, 80, 10, .14)),
                child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: megInter(9, FontWeight.w800, color: Color(0xFF5A4010))),
              ),
            ],
          ),
        ],
      ),
    );

    final shown = delivered ? MegShine(borderRadius: BorderRadius.circular(13), period: const Duration(milliseconds: 4400), delay: Duration.zero, opacity: .5, child: body) : body;
    return GestureDetector(key: kind == _Kind.next ? const Key('meg-billett-neste') : null, onTap: onTap, child: shown);
  }
}

/// The design's outline star (`M12 3l2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9L3.5 9.2l5.9-.8z`).
class _Star extends StatelessWidget {
  const _Star({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 3l2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9L3.5 9.2l5.9-.8z" fill="none" stroke="$hex" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      width: 16,
      height: 16,
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _DashH extends CustomPainter {
  const _DashH({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset((x + 3).clamp(0, size.width), 0), p);
      x += 6;
    }
  }

  @override
  bool shouldRepaint(_DashH old) => old.color != color;
}
