import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/chat_card_models.dart';
import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../../data/points/points_rules.dart';
import '../../common/auth/launch/lf_css.dart' show CssBox, CssLinear, CssShadow;
import '../../common/auth/launch/lf_motion.dart' show LfRise;
import '../../common/home/bergen/bergen_kit.dart' show bergenSvg;
import '../../common/notifications/notifications_dl.dart';
import '../poeng/prize_art.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_toast.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';
import 'meg_mark.dart';
import 'meg_bergen.dart';
import 'meg_billett.dart';
import 'meg_nivaa_card.dart' show medalFor, MegMedal;
import 'mork_rad.dart';
import 'meg_shine.dart';

/// Every Ark the Meg tab opens (design `kArkVals`), on the design's own sheet
/// shell ([MegArk]): Gullbilletten, Vilkår, Nivå, Slik får du poeng, Navn i
/// ligaen, Krev alltid kode, Anledninger, Ukeshandel, Fast bestilling,
/// Hjelp / Om Ægil, Språk, Betaling and Adresser.
abstract final class MegSheets {
  // ---------------------------------------------------------------- Gullbilletten

  /// `billett` (new Bergen L9805–9858, dark): the gold code ticket
  /// («Kopier»), «BILLETTENE DINE» (the cap, the count, the friends'
  /// tickets) and Vilkår / «Del gullbilletten».
  static Future<void> billett(BuildContext context, {required Referral referral, required VoidCallback onCopy, required VoidCallback onShare}) {
    void del() {
      Navigator.of(context).pop();
      onShare();
    }

    return showMegArk<void>(
      context,
      key: const Key('meg-billett-sheet'),
      mork: true,
      title: A4MegCopy.a4_meg_billett_title,
      subtitle: A4MegCopy.a4_meg_billett_linje(referral.pointsForThem, referral.pointsForMe),
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 2),
          LfRise(
            dur: 350,
            child: MegGullBillett(ark: true, kode: referral.code, linje: MegB8Copy.duOgVennenN(referral.pointsForMe), onTap: onCopy, onStubb: onCopy),
          ),
          const SizedBox(height: 16),
          GbBillettene(referral: referral, onNeste: del),
        ],
      ),
      secondary: MegArkButton(key: const Key('meg-billett-vilkaar'), label: A4MegCopy.a4_meg_vilkaar, onTap: () => vilkaar(context)),
      primary: MegArkButton(key: const Key('meg-billett-del'), label: A4MegCopy.a4_meg_del_billetten, onTap: del),
    );
  }

  /// `vilkaar`: the points terms, stated as the backend enforces them (dark).
  static Future<void> vilkaar(BuildContext context) {
    const ik = {'Verving': MorkIk.person, 'Billettstigen': MorkIk.opp, 'Poeng': MorkIk.stjerne, 'Ligaen': MorkIk.pokal};
    return showMegArk<void>(
      context,
      key: const Key('meg-vilkaar-sheet'),
      mork: true,
      title: A4MegCopy.a4_meg_vilkaar_title,
      subtitle: A4MegCopy.a4_meg_vilkaar_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in A4MegCopy.a4_meg_vilkaar_rader.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            MorkRad(delayMs: i * 40.0, ikon: ik[r[0]] ?? MorkIk.bok, navn: r[0], under: r[1], onTap: () {}),
          ],
        ],
      ),
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

  /// `slikPoeng` (new Bergen L20208–20222, dark): «Du er Gull · N poeng
  /// opptjent» with the distance and the medal ladder, «1 · Slik tjener du
  /// poeng» (the rates from `points/rules` as gold chips), «2 · Nivåene»
  /// (Nådd / Du er her / N igjen) and the promise.
  static Future<void> slikPoeng(BuildContext context, PointsBalance balance, {PointsRules? regler}) {
    final b = balance;
    final hasNext = b.nextTierName != null && b.pointsToNextTier != null;
    final rater = <(String, String, String?, String)>[
      if (regler != null) ...[
        (
          A4MegCopy.a4_meg_poengrater[0][0],
          regler.kjopPer10kr == 10 ? A4MegCopy.a4_meg_poengrater[0][1] : A4MegCopy.a4_meg_rate_kjop(regler.kjopPer10kr),
          regler.kjopPer10kr == 10 ? A4MegCopy.a4_meg_rate_kr : A4MegCopy.a4_meg_rate_per10(regler.kjopPer10kr),
          MorkIk.pose,
        ),
        (A4MegCopy.a4_meg_poengrater[1][0], A4MegCopy.a4_meg_rate_forste(regler.firstOrderBonus), '+${regler.firstOrderBonus}', MorkIk.butikk),
        (A4MegCopy.a4_meg_poengrater[2][0], A4MegCopy.a4_meg_rate_napp(regler.fiskePerCatch), '+${regler.fiskePerCatch}', MorkIk.krok),
        (A4MegCopy.a4_meg_poengrater[3][0], A4MegCopy.a4_meg_poengrater[3][1], null, MorkIk.flagg),
        (A4MegCopy.a4_meg_poengrater[4][0], A4MegCopy.a4_meg_rate_verving(regler.referrer), '+${regler.referrer}', MorkIk.person),
      ] else
        for (final (i, r) in A4MegCopy.a4_meg_poengrater.indexed) (r[0], r[1], null, [MorkIk.pose, MorkIk.butikk, MorkIk.krok, MorkIk.flagg, MorkIk.person][i]),
    ];
    var k = 0;
    return showMegArk<void>(
      context,
      key: const Key('meg-slik-sheet'),
      mork: true,
      title: A4MegCopy.a4_meg_slik_title,
      subtitle: A4MegCopy.a4_meg_slik_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CssBox(
            radius: BorderRadius.circular(22),
            bg: const [
              CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
            ],
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
            shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)), CssShadow(0, 12, 20, -14, Color.fromRGBO(0, 10, 16, .85))],
            padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    MegMedal(name: b.tierName, size: 34, animate: false),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(A4MegCopy.a4_meg_du_er(b.tierName), style: BergenTokens.display(15.5, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.02)),
                          Text(A4MegCopy.a4_meg_poeng_opptjent(b.earned12m), style: megInter(11.5, FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .7))),
                        ],
                      ),
                    ),
                    if (hasNext) MorkVerdi('↑ ${A4MegCopy.a4_meg_avstand(b.pointsToNextTier!, b.nextTierName!)}', stil: MorkStil.nesteNiv),
                  ],
                ),
                const SizedBox(height: 14),
                MegMedalLadder(balance: b, mork: true),
              ],
            ),
          ),
          MorkSeksjon(A4MegCopy.a4_meg_slik_s1, A4MegCopy.a4_meg_slik_s1_under),
          for (final r in rater) ...[
            const SizedBox(height: 8),
            MorkRad(delayMs: k++ * 40.0, ikon: r.$4, navn: r.$1, under: r.$2, verdi: r.$3, stil: MorkStil.gull, onTap: () {}),
          ],
          const SizedBox(height: 8),
          MorkSeksjon(A4MegCopy.a4_meg_slik_s2, A4MegCopy.a4_meg_slik_s2_under),
          for (final t in b.tiers) ...[
            const SizedBox(height: 8),
            () {
              final m = medalFor(t.name);
              final naa = t.index == b.tier, neste = t.index == b.tier + 1, naadd = t.index < b.tier;
              return MorkRad(
                delayMs: k++ * 40.0,
                ikon: MorkIk.stjerne,
                metall: MorkMetall(farger: m.gradient, stopp: m.stops, ink: m.ink),
                navn: A4MegCopy.a4_meg_tier_rad(t.name, t.threshold),
                under: A4MegCopy.a4_meg_tier_eks(A4MegCopy.a4_meg_nivaa_gaver[t.name] ?? ''),
                verdi: naa
                    ? A4MegCopy.a4_meg_du_er_her
                    : neste && b.pointsToNextTier != null
                    ? A4MegCopy.a4_meg_tier_igjen(b.pointsToNextTier!)
                    : (naadd ? A4MegCopy.a4_meg_naadd_chip : null),
                stil: neste ? MorkStil.nesteNiv : (naadd ? MorkStil.naadd : MorkStil.vanlig),
                valgt: naa,
                laast: t.index > b.tier + 1,
                onTap: () {},
              );
            }(),
          ],
          const SizedBox(height: 8),
          MorkRad(delayMs: k++ * 40.0, ikon: MorkIk.skjold, navn: A4MegCopy.a4_meg_bruk_senker_aldri, under: A4MegCopy.a4_meg_bruk_senker_sub, onTap: () {}),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Liga

  /// `ligaNavn` / `ligaBli`: pick a name shape and who may see it; saves through
  /// `points/league/name` (opting in first when needed). As the design:
  /// nothing is chosen until the customer picks a name (the CTA stays grey
  /// and says so), «1 · Velg visningsnavn» / «2 · Hvem ser navnet» head the
  /// two groups, and once in, the second key leaves the league ([onMeldAv]).
  static Future<League?> ligaNavn(
    BuildContext context, {
    required PointsAppApi api,
    required League league,
    required String firstName,
    String? bydel,
    VoidCallback? onMeldAv,
  }) {
    final options = <String, String>{
      firstName: A4MegCopy.a4_meg_navn_fornavn,
      '$firstName ${firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : ''}.': A4MegCopy.a4_meg_navn_initial,
      if (bydel != null && bydel.isNotEmpty) '$firstName · $bydel': A4MegCopy.a4_meg_navn_bydel,
      'Klatrer ${league.own?.rank ?? 1}': A4MegCopy.a4_meg_navn_anonym,
    };
    String? name = league.displayName;
    var syn = league.visibility;
    final bli = !league.optedIn;

    return showMegArk<League?>(
      context,
      key: const Key('meg-liga-navn-sheet'),
      title: bli ? A4MegCopy.a4_meg_liga_bli_title : A4MegCopy.a4_meg_navn_liga,
      subtitle: A4MegCopy.a4_meg_liga_navn_linje,
      body: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegArkRow(
            title: A4MegCopy.a4_meg_liga_steg1,
            sub: name == null ? A4MegCopy.a4_meg_liga_steg1_tom : A4MegCopy.a4_meg_liga_valgt(name!),
            value: name == null ? A4MegCopy.a4_meg_liga_maa_velges : A4MegCopy.a4_meg_liga_valgt_pill,
          ),
          for (final e in options.entries)
            MegArkRow(
              key: Key('liga-navn-${options.keys.toList().indexOf(e.key)}'),
              title: e.key,
              sub: e.value,
              selected: name == e.key,
              onTap: () => setState(() => name = e.key),
            ),
          MegArkRow(title: A4MegCopy.a4_meg_liga_steg2, sub: (A4MegCopy.a4_meg_ligasyn.where((x) => x[0] == syn).firstOrNull ?? A4MegCopy.a4_meg_ligasyn.first)[2]),
          for (final s in A4MegCopy.a4_meg_ligasyn)
            MegArkRow(key: Key('liga-syn-${s[0]}'), title: s[1], sub: s[2], selected: syn == s[0], onTap: () => setState(() => syn = s[0])),
          const MegArkRow(title: A4MegCopy.a4_meg_liga_aldri, sub: A4MegCopy.a4_meg_liga_aldri_sub),
        ],
      ),
      secondary: !bli && onMeldAv != null
          ? MegArkButton(label: A4MegCopy.a4_meg_liga_meld_av, onTap: () {
              Navigator.of(context).pop();
              onMeldAv();
            })
          : MegArkButton(label: A4MegCopy.a4_meg_liga_vilkaar, onTap: () => vilkaar(context)),
      primaryBuilder: (ctx) => MegArkButton(
        key: const Key('liga-navn-lagre'),
        label: name == null ? A4MegCopy.a4_meg_liga_velg_forst : (bli ? A4MegCopy.a4_meg_liga_bli_som(name!) : A4MegCopy.a4_meg_lagre),
        gradient: name == null ? MegArkInk.disabledCta : null,
        onTap: () async {
          if (name == null) {
            showBergenToast(context, A4MegCopy.a4_meg_liga_velg_forst);
            return;
          }
          final nav = Navigator.of(context);
          if (bli) await api.leagueOptIn(true);
          final updated = await api.setLeagueName(name: name!, visibility: syn);
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
      // One CTA, as the design (`kodeInnst`); the ✕ cancels.
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
                // The design's value pill («Fjern»).
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color.fromRGBO(30, 79, 92, .09), borderRadius: BorderRadius.circular(999)),
                  child: Text(A4MegCopy.a4_meg_anl_fjern, style: BergenTokens.text(11, weight: FontWeight.w800, color: MegArkInk.teal)),
                ),
              ),
            ),
          MegArkRow(
            key: const Key('anledning-legg'),
            title: A4MegCopy.a4_meg_anl_legg,
            sub: A4MegCopy.a4_meg_anl_legg_sub,
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

  /// `sprak` (dark): the app languages, each on a two-letter tile; picking
  /// one switches the app.
  static Future<String?> spraak(BuildContext context, {required String current}) {
    const kort = {'no': 'NB', 'nb': 'NB', 'en': 'EN', 'sv': 'SV', 'da': 'DA', 'es': 'ES'};
    return showMegArk<String>(
      context,
      key: const Key('meg-spraak-sheet'),
      mork: true,
      title: A4MegCopy.a4_meg_spraak,
      subtitle: A4MegCopy.a4_meg_spraak_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in A4MegCopy.a4_meg_spraak_valg.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            () {
              final valgt = e[0] == current || (current == 'nb' && e[0] == 'no');
              return MorkRad(
                key: Key('spraak-${e[0]}'),
                delayMs: i * 40.0,
                tileTx: kort[e[0]] ?? e[0].toUpperCase(),
                navn: e[1],
                valgt: valgt,
                pil: !valgt,
                onTap: () => Navigator.of(context).pop(e[0]),
              );
            }(),
          ],
        ],
      ),
    );
  }

  /// `betaling`: Vipps first, cards as the fallback, and the card screen.
  static Future<void> betaling(BuildContext context, {required List<String> cards, required VoidCallback onManage, String vippsNr = ''}) {
    // «•• 47 21»: the Vipps number's last four, as the design shows it.
    final d = vippsNr.replaceAll(RegExp(r'\D'), '');
    final vippsSub = d.length >= 4 ? '•• ${d.substring(d.length - 4, d.length - 2)} ${d.substring(d.length - 2)}' : A4MegCopy.a4_meg_betaling_standard;
    return showMegArk<void>(
      context,
      key: const Key('meg-betaling-sheet'),
      title: A4MegCopy.a4_meg_betaling,
      subtitle: A4MegCopy.a4_meg_betaling_linje,
      body: (ctx, _) => Column(
        children: [
          MegArkRow(title: A4MegCopy.a4_meg_betaling_vipps, sub: vippsSub, value: 'Standard', selected: true),
          for (final c in cards) MegArkRow(title: c, value: A4MegCopy.a4_meg_reserve),
          MegArkRow(key: const Key('betaling-kort'), title: A4MegCopy.a4_meg_betaling_kort, onTap: () {
            Navigator.of(context).pop();
            onManage();
          }),
        ],
      ),
    );
  }

  /// `adresser`: the saved addresses — the delivery address chosen (street,
  /// the door details under it, its type as a pill, the check), the others
  /// open the address screen — and "Legg til adresse".
  static Future<void> adresser(BuildContext context, {required List<MegAdresse> addresses, required VoidCallback onManage, required VoidCallback onAdd}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-adresser-sheet'),
      title: A4MegCopy.a4_meg_adresser,
      subtitle: A4MegCopy.a4_meg_adresser_linje,
      body: (ctx, _) => Column(
        children: [
          for (final a in addresses)
            MegArkRow(
              title: a.gate,
              sub: [if (a.detaljer.isNotEmpty) a.detaljer, A4MegCopy.a4_meg_adresser_bare].join(' · '),
              value: a.valgt ? a.type : null,
              selected: a.valgt,
              onTap: a.valgt
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onManage();
                    },
            ),
          MegArkRow(key: const Key('adresser-legg'), title: A4MegCopy.a4_meg_adresser_tom, onTap: () {
            Navigator.of(context).pop();
            onAdd();
          }),
        ],
      ),
    );
  }

  /// `varslinger` (dark): the newest notices («Nytt» when they arrived
  /// after the last visit; order notices open Ordrehistorikk), then what is
  /// notified.
  static Future<void> varsler(BuildContext context, {required List<MassNotificationItem> items, DateTime? seenAt, VoidCallback? onOrdre}) {
    bool ny(MassNotificationItem n) {
      final t = DateTime.tryParse(n.datetime);
      return seenAt == null || (t != null && t.isAfter(seenAt));
    }

    bool ordre(MassNotificationItem n) {
      final t = '${n.title} ${n.message}'.toLowerCase();
      return t.contains('ordre') || t.contains('bestilling') || t.contains('levert') || t.contains('på vei');
    }

    final nye = items.where(ny).length;
    const innstIk = [MorkIk.gave, MorkIk.stjerne, MorkIk.pokal];
    var k = 0;
    return showMegArk<void>(
      context,
      key: const Key('meg-varsler-sheet'),
      mork: true,
      title: A4MegCopy.a4_meg_varsler,
      subtitle: A4MegCopy.a4_meg_varsler_linje(nye),
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final n in items.take(12)) ...[
            if (k > 0) const SizedBox(height: 8),
            MorkRad(
              delayMs: k++ * 40.0,
              ikon: RegExp('Gull|Sølv').hasMatch('${n.title} ${n.message}') ? MorkIk.opp : MorkIk.bjelle,
              navn: n.title.trim().isEmpty ? n.message : n.title,
              under: n.title.trim().isEmpty ? null : n.message,
              verdi: ny(n) ? A4MegCopy.a4_meg_nytt_pill : null,
              stil: MorkStil.ny,
              ny: ny(n),
              pil: ordre(n) && onOrdre != null,
              onTap: ordre(n) && onOrdre != null
                  ? () {
                      Navigator.of(context).pop();
                      onOrdre();
                    }
                  : () {},
            ),
          ],
          // UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
          // (No per-kind notification settings exist; these pushes are always sent, so «På» holds.
          // The design's switches are shown as a plain «På» until they can be turned off.)
          for (final (i, r) in A4MegCopy.a4_meg_varsel_innst.indexed) ...[
            if (k > 0) const SizedBox(height: 8),
            MorkRad(delayMs: k++ * 40.0, ikon: innstIk[i % innstIk.length], navn: r[0], under: r[1], verdi: A4MegCopy.a4_meg_paa, stil: MorkStil.valgt, onTap: () {}),
          ],
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
  const MegMedalLadder({super.key, required this.balance, this.mork = false});

  final PointsBalance balance;

  /// On the dark Ark: white names, a light track, the mint NÅ and ticks.
  final bool mork;

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
              child: Container(height: 4, decoration: BoxDecoration(color: mork ? const Color.fromRGBO(255, 255, 255, .14) : MegArkInk.ink.withValues(alpha: .1), borderRadius: BorderRadius.circular(99))),
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
                for (final s in steps) Expanded(child: _LadderMedal(step: s, current: s.index == balance.tier, reached: s.index <= balance.tier, mork: mork)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LadderMedal extends StatelessWidget {
  const _LadderMedal({required this.step, required this.current, required this.reached, this.mork = false});

  final TierStep step;
  final bool current;
  final bool reached;
  final bool mork;

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
        Text(
          step.name,
          maxLines: 1,
          style: BergenTokens.text(
            11.5,
            weight: FontWeight.w800,
            color: mork ? (reached ? Colors.white : const Color.fromRGBO(255, 255, 255, .6)) : (current ? MegArkInk.ink : (reached ? const Color(0xFF4E4943) : MegArkInk.muted)),
          ),
        ),
        const SizedBox(height: 4),
        Text(step.threshold == 0 ? '0' : A4MegCopy.nf(step.threshold), style: megInter(10, FontWeight.w800, color: mork ? const Color.fromRGBO(255, 255, 255, .55) : MegArkInk.faint)),
        const SizedBox(height: 5),
        Container(
          constraints: const BoxConstraints(minHeight: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: current ? (mork ? const Color(0xFF5CE0B8) : MegArkInk.ink) : Colors.transparent, borderRadius: BorderRadius.circular(999)),
          child: Text(current ? A4MegCopy.a4_meg_naa : '', style: megInter(8.5, FontWeight.w800, letterSpacing: .9, color: mork ? const Color(0xFF0F2B33) : const Color(0xFFFFF7E4))),
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
              gradient: PrizeArt.of(slug: p.slug, name: p.name).gradient,
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
                    final art = PrizeArt.of(slug: p.slug, name: p.name);
                    return bergenSvg(art.icon, width: art.width * .5, height: art.height * .5);
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

/// One saved address for the Adresser Ark.
class MegAdresse {
  const MegAdresse({required this.gate, required this.detaljer, required this.type, required this.valgt});

  /// «Nygårdsgaten 5».
  final String gate;

  /// The rest: flat, place, door note («3. etasje · Ring på hos Hansen»).
  final String detaljer;

  /// «Hjem», «Jobb», «Annen».
  final String type;
  final bool valgt;
}
