import 'package:flutter/material.dart';

import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_kit.dart';
import '../poeng/poeng_copy.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';
import '../poeng/poeng_feil.dart';
import 'mork_rad.dart';

/// The league's dark sheets (new Bergen `kArk ligaBli` / `ligaNavn` /
/// `ligaVilkaar`, L20251–20287; the field L9900–9915).
abstract final class LigaArk {
  /// «Bli med i Bergen-ligaen» / «Navn i ligaen»: write the name you want
  /// (20 characters) or be anonymous («Klatrer N»), see how others will see
  /// you, then who sees the name (Alle i Bergen / Skjult — new Bergen drops
  /// «Bare min bydel» with the filter). Anonymous keeps any old name out of
  /// sight: the name is left as it is and the visibility set to `skjult`, so
  /// everyone else sees «Klatrer N» (`LeagueService::nameFor`).
  static Future<League?> navn(BuildContext context, {required PointsAppApi api, required League league, VoidCallback? onMeldAv}) {
    final bli = !league.optedIn;
    final rang = league.own?.rank;
    final anonNavn = 'Klatrer ${rang ?? (league.participants + 1)}';
    final har = (league.displayName ?? '').trim();
    var anonym = league.optedIn && (har.isEmpty || league.visibility == 'skjult' && har.startsWith('Klatrer '));
    final felt = TextEditingController(text: anonym ? '' : har);
    final fokus = FocusNode();
    var syn = league.visibility == 'skjult' ? 'skjult' : 'alle';
    String? valgt() => anonym ? anonNavn : (felt.text.trim().isEmpty ? null : felt.text.trim());
    final synListe = A4MegCopy.a4_meg_ligasyn.where((s) => s[0] != 'bydel').toList();

    return showMegArk<League?>(
      context,
      key: const Key('meg-liga-navn-sheet'),
      mork: true,
      tastatur: true,
      title: bli ? A4MegCopy.a4_meg_liga_bli_title : A4MegCopy.a4_meg_navn_liga,
      subtitle: A4MegCopy.a4_meg_liga_navn_linje,
      body: (ctx, setState) {
        final v = valgt();
        final synRad = synListe.where((s) => s[0] == syn).firstOrNull ?? synListe.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MorkSeksjon(A4MegCopy.a4_meg_liga_steg1_ny, A4MegCopy.a4_meg_liga_steg1_under),
            const SizedBox(height: 8),
            _Felt(
              controller: felt,
              fokus: fokus,
              anonym: anonym,
              forhaandsvis: v,
              plass: rang,
              onEndret: () => setState(() {}),
            ),
            const SizedBox(height: 8),
            _Anonym(
              paa: anonym,
              navn: anonNavn,
              onTap: () {
                setState(() => anonym = !anonym);
                if (anonym) fokus.unfocus();
                showBergenToast(context, anonym ? A4MegCopy.a4_meg_liga_anonym_paa(anonNavn) : A4MegCopy.a4_meg_liga_anonym_av);
              },
            ),
            MorkSeksjon(A4MegCopy.a4_meg_liga_steg2, synRad[2]),
            const SizedBox(height: 8),
            for (final (i, s) in synListe.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              MorkRad(
                key: Key('liga-syn-${s[0]}'),
                delayMs: i * 40.0,
                ikon: s[0] == 'skjult' ? MorkIk.skjold : MorkIk.person,
                navn: s[1],
                under: s[2],
                valgt: syn == s[0],
                onTap: () => setState(() => syn = s[0]),
              ),
            ],
            const SizedBox(height: 8),
            MorkRad(delayMs: 80, ikon: MorkIk.skjold, navn: A4MegCopy.a4_meg_liga_aldri, under: A4MegCopy.a4_meg_liga_aldri_sub, onTap: () {}),
          ],
        );
      },
      secondary: !bli && onMeldAv != null
          ? MegArkButton(
              label: A4MegCopy.a4_meg_liga_meld_av,
              onTap: () {
                Navigator.of(context).pop();
                onMeldAv();
              },
            )
          : MegArkButton(label: A4MegCopy.a4_meg_liga_vilkaar, onTap: () => vilkaar(context)),
      primaryBuilder: (ctx) {
        final v = valgt();
        return MegArkButton(
          key: const Key('liga-navn-lagre'),
          label: v == null ? A4MegCopy.a4_meg_liga_skriv_forst : (bli ? A4MegCopy.a4_meg_liga_bli_som(v) : A4MegCopy.a4_meg_lagre),
          av: v == null,
          onTap: () async {
            if (v == null) {
              showBergenToast(context, A4MegCopy.a4_meg_liga_skriv_eller_anonym);
              return;
            }
            final nav = Navigator.of(context);
            if (bli) await api.leagueOptIn(true);
            final r = await api.setLeagueName(name: anonym ? null : v, visibility: anonym ? 'skjult' : syn);
            if (r.league == null) {
              // Customer Step 12: LEAGUE_NAME_INVALID / LEAGUE_MONTH_CLOSED / LEAGUE_NOT_OPTED_IN in words; the sheet stays open.
              if (context.mounted) showBergenToast(context, CusPoengFeil.tekst(r.error, ellers: A4MegCopy.a4_meg_lagret_feil), icon: Icons.error_outline_rounded);
              return;
            }
            nav.pop(r.league);
          },
        );
      },
    );
  }

  /// «Vilkår for Bergen-ligaen» (`ligaVilkaar`).
  static Future<void> vilkaar(BuildContext context) {
    const ik = [MorkIk.stjerne, MorkIk.pokal, MorkIk.klokke, MorkIk.skjold];
    return showMegArk<void>(
      context,
      key: const Key('liga-vilkaar-sheet'),
      mork: true,
      title: A3PoengCopy.a3_poeng_liga_vilkaar_title,
      subtitle: A3PoengCopy.a3_poeng_liga_vilkaar_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in A3PoengCopy.a3_poeng_liga_vilkaar_rader.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            MorkRad(delayMs: i * 40.0, ikon: ik[i % ik.length], navn: r[0], under: r[1], onTap: () {}),
          ],
        ],
      ),
    );
  }
}

/// The name field (`lnFelt`): VISNINGSNAVN and the count, the 20-character
/// field, «Slik ser andre deg» with the preview pill and your place.
class _Felt extends StatelessWidget {
  const _Felt({required this.controller, required this.fokus, required this.anonym, required this.forhaandsvis, required this.plass, required this.onEndret});

  final TextEditingController controller;
  final FocusNode fokus;
  final bool anonym;
  final String? forhaandsvis;
  final int? plass;
  final VoidCallback onEndret;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: fokus,
    builder: (context, _) {
      final fok = fokus.hasFocus && !anonym;
      final v = forhaandsvis;
      final init = anonym ? '?' : (v == null ? '·' : v.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w.characters.first).take(2).join().toUpperCase());
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: anonym ? .45 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
            border: Border.all(color: fok ? const Color.fromRGBO(127, 240, 203, .85) : const Color.fromRGBO(255, 255, 255, .16)),
            boxShadow: [if (fok) const BoxShadow(color: Color.fromRGBO(92, 224, 184, .18), spreadRadius: 3)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(A4MegCopy.a4_meg_liga_visningsnavn, style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .6))),
                  const Spacer(),
                  Text('${anonym ? 0 : controller.text.length}/20', style: aeTab(inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .5)))),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('liga-navn-felt'),
                controller: controller,
                focusNode: fokus,
                enabled: !anonym,
                maxLength: 20,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => onEndret(),
                cursorColor: const Color(0xFF5CE0B8),
                style: jakarta(20, em: -.02),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                  hintText: A4MegCopy.a4_meg_liga_navn_hint,
                  hintStyle: jakarta(20, em: -.02, color: const Color.fromRGBO(255, 255, 255, .35)),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 11),
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .1)))),
                child: Row(
                  children: [
                    Text(A4MegCopy.a4_meg_liga_slik_ser, style: inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .55))),
                    const SizedBox(width: 9),
                    Expanded(
                      child: CssBox(
                        height: 30,
                        radius: BorderRadius.circular(999),
                        bg: const [CssSolid(Color.fromRGBO(0, 0, 0, .2))],
                        shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12))],
                        padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: anonym ? const Color.fromRGBO(255, 255, 255, .2) : null,
                                gradient: anonym ? null : const LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFFF9A273), Color(0xFFE95C2C)]),
                              ),
                              child: Text(init, style: inter(10, weight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                v ?? A4MegCopy.a4_meg_liga_skriv_navn,
                                key: const Key('liga-navn-forhaand'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: inter(12.5, weight: FontWeight.w800, color: v == null ? const Color.fromRGBO(255, 255, 255, .5) : Colors.white),
                              ),
                            ),
                            if (plass != null) Text('$plass. plass', style: aeTab(inter(11, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// «Vær anonym» (`lnAnonym`): the eye-off key, the line and the switch.
class _Anonym extends StatelessWidget {
  const _Anonym({required this.paa, required this.navn, required this.onTap});
  final bool paa;
  final String navn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: paa,
    child: AePress(
      key: const Key('liga-anonym'),
      onTap: onTap,
      dy: 0,
      scale: .99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .04)]),
          border: Border.all(color: paa ? const Color.fromRGBO(127, 240, 203, .55) : const Color.fromRGBO(255, 255, 255, .16)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .06)]),
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
              ),
              child: const Center(
                child: AeIkon(
                  'M3 3l18 18 M10.6 10.6a2 2 0 0 0 2.8 2.8 M9.4 5.2A9.8 9.8 0 0 1 12 5c5 0 9 4.5 10 7-.4 1-1.2 2.3-2.4 3.5M6.3 6.3C4.3 7.6 2.7 9.6 2 12c1 2.5 5 7 10 7 1.7 0 3.2-.5 4.6-1.3',
                  size: 17,
                  stroke: 2.2,
                  color: Color(0xFF9FF0D4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(A4MegCopy.a4_meg_liga_anonym, style: inter(13.5, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(A4MegCopy.a4_meg_liga_anonym_under(navn), style: inter(11.5, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .66))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            MorkBryter(paa: paa),
          ],
        ),
      ),
    ),
  );
}
