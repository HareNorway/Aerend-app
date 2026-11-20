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
}
