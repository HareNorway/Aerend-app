// ignore_for_file: non_constant_identifier_names
import '../../../main.dart' show languages;

/// Points plan Step 7: Fjordløpet's interface texts (game spec §15), bokmål and English — in the ARB files (`lop_*`)
/// since Fjordløpet v1.3 plan Step 6. The rules page itself comes
/// from the panel (`game.vilkaar`, in `/game/state`).
abstract final class LopetCopy {

  static String get navn => 'Fjordløpet';
  // Points plan Step 12: Ukens liste, the locked rows, the vest once per order.
  static String get ukeliste => languages.lop_ukeliste;
  static String get ukelisteTom => languages.lop_ukeliste_tom;
  static String ukelisteLinje(int n) => languages.lop_ukeliste_linje(n);
  static String get ukelisteIngen => languages.lop_ukeliste_ingen;
  static String premieHylle(String hylle) => languages.lop_premie_hylle(hylle);
  static String premiePoeng(int n) => languages.lop_premie_poeng(n);
  static String plassLosgrad(int? plass, String losgrad) => [if (plass != null) languages.lop_plass_losgrad(plass), if (losgrad.isNotEmpty) losgrad].join(' · ');
  static String megRad(int? m, int? plass, String losgrad) => m == null
      ? 'Fjordløpet'
      : ['Fjordløpet', languages.lop_meg_rad(m), if (plass != null) languages.lop_meg_rad_2(plass), if (losgrad.isNotEmpty) losgrad].join(' · ');
  static String igjenPaaBestilling(int n) => n == 1 ? languages.lop_igjen_paa_bestilling : languages.lop_igjen_paa_bestilling_2(n);
  static String get vestBrukt => languages.lop_vest_brukt;
  static String get mensDuVenter => languages.lop_mens_du_venter;
  static String seilaserIgjen(int n) => n == 1 ? languages.lop_seilaser_igjen : languages.lop_seilaser_igjen_2(n);
  static String seilaser(int n) => languages.lop_seilaser(n);
  static String get hjemKlar => languages.lop_hjem_klar;

  static String get ukensLed => languages.lop_ukens_led;
  static String get settSeil => languages.lop_sett_seil;
  static String get dinBeste => languages.lop_din_beste;
  static String get ukensBeste => languages.lop_ukens_beste;
  static String get sjokort => languages.lop_sjokort;
  static String get takeUkjent => languages.lop_take_ukjent;
  static String get vest => languages.lop_vest;
  static String get vilkaar => languages.lop_vilkaar;
  static String get lyd => languages.lop_lyd;

  static List<String> get porter => [languages.lop_porter, languages.lop_porter_2, languages.lop_porter_3];
  static String omMeter(String port, int m) => languages.lop_om_meter(port, m);

  static String get pause => languages.lop_pause;
  static String get vedDora => languages.lop_ved_dora;
  static String get trengerDeg => languages.lop_trenger_deg;
  static String get fortsett => languages.lop_fortsett;
  static String fortsettOm(int n) => languages.lop_fortsett_om(n);
  static String get tilSporing => languages.lop_til_sporing;

  static String get over => languages.lop_over;
  static String fraRekorden(int m) => languages.lop_fra_rekorden(m);
  static String get nyRekord => languages.lop_ny_rekord;
  static String poengVedLevering(int p) => languages.lop_poeng_ved_levering(p);
  static String seilIgjen(int n) => languages.lop_seil_igjen(n);
  static String get nesteSeilas => languages.lop_neste_seilas;
  static String get snartFremme => languages.lop_snart_fremme;
  static String get forsinket => languages.lop_forsinket;
  static String get vestTok => languages.lop_vest_tok;
  static String get stengt => languages.lop_stengt;
  static String minUnna(int m) => languages.lop_min_unna(m);

  // Fjordløpet v1.3 plan Step 6 (spec §4.6, §5.4–5.7, §12.1, §15).
  static String get naerePaa => languages.lop_naere_paa;
  static String get nyRekordKort => languages.lop_ny_rekord_kort;
  static String portPoeng(String port, int p) => p > 0 ? '$port · +$p ${languages.lop_port_poeng}' : port;
  static String hindring(String? t) => switch (t) {
        'boye' => languages.lop_hindring,
        'stokk' => languages.lop_hindring_2,
        'garn' => languages.lop_hindring_3,
        'kajakk' => languages.lop_hindring_4,
        'beffen' => languages.lop_hindring_5,
        'make' => languages.lop_hindring_6,
        _ => languages.lop_hindring_7,
      };

  /// «Tømmerstokken etter fyret tok deg ved 311 m».
  static String aarsak(String? obstacle, String? landmark, int m) {
    final hva = hindring(obstacle);
    final etter = landmark == null ? '' : languages.lop_aarsak(landmark);
    return languages.lop_aarsak_2(hva, etter, m);
  }

  static String maalMilepael(String port, int gap) => languages.lop_maal_milepael(gap, port);
  static String maalBeste(int gap) => languages.lop_maal_beste(gap);
  static String maalSeiler(String navn, int gap) => languages.lop_maal_seiler(navn, gap);
  static String maalMerke(String merke, String metric, int igjen) => switch (metric) {
        'crates' => languages.lop_maal_merke(igjen, merke),
        'near_misses' => languages.lop_maal_merke_2(igjen, merke),
        'metres' => languages.lop_maal_merke_3(igjen, merke),
        _ => languages.lop_maal_merke_4(igjen, merke),
      };
  static String get kasser => languages.lop_kasser;
  static String get naerePaaTall => languages.lop_naere_paa_tall;
  static String get vestBruk => languages.lop_vest_bruk;
  static String get merker => languages.lop_merker;
  static String get pynt => languages.lop_pynt;
  static String get pyntIngen => languages.lop_pynt_ingen;
  static String get pyntIngenValgt => languages.lop_pynt_ingen_valgt;
  static String pyntPlass(String kind) => switch (kind) {
        'pennant' => languages.lop_pynt_plass,
        'wake' => languages.lop_pynt_plass_2,
        _ => languages.lop_pynt_plass_3,
      };
  static String uker(int n) => n == 1 ? languages.lop_uker : languages.lop_uker_2(n);
  static String rival(String navn, int m) => languages.lop_rival(navn, m);
  static String get herGikkDetGalt => languages.lop_her_gikk_det_galt;
  static String get kartLukk => languages.lop_kart_lukk;
  static String get vestFull => languages.lop_vest_full;

  /// Fjordløpet v1.3 plan Step 7: the server's nearest goal (Levert, Meg, Premiehylla) as a line, or null.
  static String? maalFra(Object? g) {
    if (g is! Map) return null;
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    return switch (g['type']) {
      'badge' => maalMerke('${g['name']}', '${g['metric']}', i(g['remaining'])),
      'milestone' => maalMilepael(porter[i(g['index']).clamp(0, 2)], i(g['gap_m'])),
      'best' => maalBeste(i(g['gap_m'])),
      'rival' || 'top10' => maalSeiler('${g['name']}', i(g['gap_m'])),
      _ => null,
    };
  }

  /// The Sporing tile's second line (spec §8): runs left, your best, the week's best.
  static String flisUnder(int runsLeft, int? mine, int? week) =>
      [seilaserIgjen(runsLeft), if (mine != null) '${dinBeste.toLowerCase()} $mine m', if (week != null) '${ukensBeste.toLowerCase()} $week m'].join(' · ');

  /// Points plan Step 8 (game spec §8 Levert): what the order's runs came to.
  static String levert(String? port, int m, int poeng) {
    final hva = port != null ? languages.lop_levert(port) : languages.lop_levert_2(m);
    return poeng > 0 ? '$hva · +$poeng ${languages.lop_levert_3}' : hva;
  }

  // Design 21 Nov plan Step 7: the quay, the Ukeliste sheet and the Pynt sheet.
  static String kaiUke(String week) => languages.lop_kai_uke(week.contains('W') ? int.tryParse(week.split('W').last) ?? week : week);
  static String gradNeste(int m, String navn) => languages.lop_kai_grad_neste(tallTekst(m), navn);
  static String get gradHoyeste => languages.lop_kai_grad_hoyeste;
  static String get pyntKort => languages.lop_kai_pynt;
  static String seilt(int m) => languages.lop_kai_seilt(tallTekst(m));
  static String get altTake => languages.lop_kai_alt_take;
  static String get take => languages.lop_kai_take;
  static String get nesteMaal => languages.lop_kai_neste_maal;
  static String igjen(int m) => languages.lop_kai_igjen(tallTekst(m));
  static String get ingenForan => languages.lop_kai_ingen_foran;
  static String poeng(int p) => languages.lop_kai_poeng(p);
  static String get forstePlass => languages.lop_kai_forste;
  static String get leder => languages.lop_kai_leder;
  static String get hold => languages.lop_kai_hold;
  static String get ukelisten => languages.lop_kai_ukelisten;
  static String get plass => languages.lop_kai_plass;
  static String get ikkePaa => languages.lop_kai_ikke_paa;
  static String foran(String navn, int m) => languages.lop_kai_foran(navn, tallTekst(m));
  static String bak(String navn, int m) => languages.lop_kai_bak(navn, tallTekst(m));
  static String get premieplass => languages.lop_kai_premieplass;
  static String get toppTi => languages.lop_kai_topp_ti;
  static String tilToppTi(int m) => languages.lop_kai_til_topp_ti(tallTekst(m));
  static String toppVinner(int n) => languages.lop_kai_topp_vinner(n);
  static String get kaiVest => languages.lop_kai_vest;
  static String get vilkaarLenke => languages.lop_kai_vilkaar;
  static String get listePremier => languages.lop_liste_premier;
  static String listePlass(int fra, int til) => fra == til ? languages.lop_liste_plass_en(fra) : til == fra + 1 ? languages.lop_liste_plass_to(fra, til) : languages.lop_liste_plass_til(fra, til);
  static String listeHylle(String hylle) => languages.lop_liste_hylle(hylle);
  static String listePoeng(int p) => languages.lop_liste_poeng(tallTekst(p));
  static String get listeMerker => languages.lop_liste_merker;
  static String listeAv(int n, int av) => languages.lop_liste_av(n, av);
  static String get listeTatt => languages.lop_liste_tatt;
  static String listeRival(int m) => languages.lop_liste_rival(tallTekst(m));
  static String merkeUnder(String metric, int p, int target) => switch (metric) {
        'crates' => languages.lop_merke_crates(p, target),
        'near_misses' => languages.lop_merke_near(p, target),
        'metres' => languages.lop_merke_metres(tallTekst(p), tallTekst(target)),
        'records' => languages.lop_merke_records(p, target),
        'buoy1_no_vest' => languages.lop_merke_torr,
        _ => languages.lop_merke_rad(p, target),
      };
  static String get pyntUnder => languages.lop_pynt_under;
  static String get pyntVanlig => languages.lop_pynt_vanlig;
  static String get pyntStandard => languages.lop_pynt_standard;
  static String pyntTa(String merke) => languages.lop_pynt_ta(merke);

  /// «13 760»: thousands with a narrow space, as the design writes metres.
  static String tallTekst(int n) {
    final s = n.abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('\u00A0');
      b.write(s[i]);
    }
    return b.toString();
  }
}
