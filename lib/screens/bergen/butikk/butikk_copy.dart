// ignore_for_file: non_constant_identifier_names

import '../../../main.dart' show languages;
import '../../../utils/utils.dart';

/// Copy for the Butikk group (`kategori` ≈L4748, `butikk` ≈L3035,
/// `{{ butSideLabel }}` ≈L2705, `visKlede` ≈L2630, `visProdukt` ≈L7211, the
/// Info sheet ≈L6913, `arkAapent` ≈L7143, `automat` ≈L4636). AGIL-CONTRACT
/// §3.2: class `ButikkCopy`, keys `a1_butikk_*`, NO and EN.
abstract final class ButikkCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  /// Norwegian money: "149 kr", "65,80 kr", "1 299 kr".
  static String kr(num v) {
    final hel = v == v.roundToDouble();
    final t = hel ? '${v.toInt()}' : v.toStringAsFixed(2);
    final deler = t.split('.');
    final b = StringBuffer();
    final heltall = deler[0];
    for (var i = 0; i < heltall.length; i++) {
      if (i > 0 && (heltall.length - i) % 3 == 0 && heltall[i - 1] != '-') b.write(' ');
      b.write(heltall[i]);
    }
    return '$b${deler.length > 1 ? ',${deler[1]}' : ''} kr';
  }

  // ── Kategori ────────────────────────────────────────────────────────────
  static String a1_butikk_kat_open(int n) => languages.ops_butikk_kat_open(n);
  static String get a1_butikk_kat_bestill_bilde => languages.ops_butikk_kat_bestill_bilde;
  static String get a1_butikk_kat_butikker => languages.ops_butikk_kat_butikker;
  static String get a1_butikk_kat_produkter => languages.ops_butikk_kat_produkter;
  static String a1_butikk_kat_pulse(String kat, int n) => languages.ops_butikk_kat_pulse(kat, n);
  static String get a1_butikk_kat_bestiller_naa => languages.ops_butikk_kat_bestiller_naa;
  static String get a1_butikk_kat_video => languages.ops_butikk_kat_video;
  static String get a1_butikk_kat_f_open => languages.ops_butikk_kat_f_open;
  static String get a1_butikk_kat_f_free => languages.ops_butikk_kat_f_free;
  static String get a1_butikk_kat_f_fast => languages.ops_butikk_kat_f_fast;
  static String get a1_butikk_kat_f_top => languages.ops_butikk_kat_f_top;
  static String get a1_butikk_kat_empty => languages.ops_butikk_kat_empty;
  static String get a1_butikk_kat_empty_products => languages.ops_butikk_kat_empty_products;
  static String get a1_butikk_kat_free => languages.ops_butikk_kat_free;
  static String a1_butikk_kat_eta(int min) => languages.ops_butikk_kat_eta(min);

  // Gaver variant
  static String get a1_butikk_gave_idag => languages.ops_butikk_gave_idag;
  static String a1_butikk_gave_innen(String time) => languages.ops_butikk_gave_innen(time);
  static String get a1_butikk_gave_aegil => languages.ops_butikk_gave_aegil;
  static String get a1_butikk_gave_utstilling => languages.ops_butikk_gave_utstilling;
  static String get a1_butikk_gave_anledninger => languages.ops_butikk_gave_anledninger;
  static String get a1_butikk_gave_naerheten => languages.ops_butikk_gave_naerheten;
  static String get a1_butikk_gave_innpakning => languages.ops_butikk_gave_innpakning;
  static String a1_butikk_gave_populaert(String bydel) => languages.ops_butikk_gave_populaert(bydel);
  static List<String> get a1_butikk_gave_anledning_liste => _en
      ? const ['Birthday', 'Housewarming', 'Thank you', 'Just because']
      : const ['Bursdag', 'Innflytting', 'Takk', 'Bare fordi'];

  // Mote variant
  static String get a1_butikk_mote_utstilling => languages.ops_butikk_mote_utstilling;
  static String a1_butikk_mote_antall(int n) => languages.ops_butikk_mote_antall(n);

  // ── Dreieskiven ─────────────────────────────────────────────────────────
  static String get a1_butikk_skive_lagre => languages.ops_butikk_skive_lagre;
  static String get a1_butikk_skive_lagret => languages.ops_butikk_skive_lagret;
  static String get a1_butikk_skive_legg => languages.ops_butikk_skive_legg;
  static String get a1_butikk_skive_hint => languages.ops_butikk_skive_hint;

  // ── Butikk (restaurant) ─────────────────────────────────────────────────
  static String a1_butikk_open_til(String t) => languages.ops_butikk_open_til(t);
  static String a1_butikk_apner(String t) => languages.ops_butikk_apner(t);
  static String get a1_butikk_stengt => languages.ops_butikk_stengt;
  static String get a1_butikk_kjokken => languages.ops_butikk_kjokken;
  static String a1_butikk_per_kjop(int n) => _t('+$n per kjøp', '+$n per order');
  static String get a1_butikk_tilbud => _t('Tilbud', 'Offers');
  static String get a1_butikk_tilbud_note => _t(
    'Butikken setter tilbudet selv · gjelder i denne bestillingen',
    'The store sets the offer · applies to this order',
  );
  static String a1_butikk_tilbud_spar(String grunn, int kr) =>
      _t('$grunn · spar $kr kr', '$grunn · save $kr kr');
  static String get a1_butikk_tilbud_grunn => _t('Fra kjøkkenet', 'From the kitchen');
  static String get a1_butikk_pauset => languages.ops_butikk_pauset;
  static String a1_butikk_km(double km) =>
      '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  static String a1_butikk_levering(String fee) => languages.ops_butikk_levering(fee);
  static String a1_butikk_aerend_idag(int n) => languages.ops_butikk_aerend_idag(n);
  static String a1_butikk_kikker(int n) => languages.ops_butikk_kikker(n);
  static String get a1_butikk_seilas => languages.ops_butikk_seilas;
  static String get a1_butikk_kjokkenet => languages.ops_butikk_kjokkenet;
  static String get a1_butikk_din_dor => languages.ops_butikk_din_dor;
  static String get a1_butikk_gratis_frakt => languages.ops_butikk_gratis_frakt;
  static String get a1_butikk_dessert => languages.ops_butikk_dessert;
  static String get a1_butikk_ti_prosent => languages.ops_butikk_ti_prosent;
  static String a1_butikk_min(num kr) => languages.ops_butikk_min('${kr.toInt()}');
  static String get a1_butikk_neste => languages.ops_butikk_neste;
  static String a1_butikk_igjen(num kr, String navn) => languages.ops_butikk_igjen('${kr.toInt()}', navn);
  static String get a1_butikk_havn => languages.ops_butikk_havn;
  static String get a1_butikk_frakt_naadd => languages.ops_butikk_frakt_naadd;
  static String get a1_butikk_allergener => languages.ops_butikk_allergener;
  static String get a1_butikk_apningstider => languages.ops_butikk_apningstider;
  static String get a1_butikk_mer => languages.ops_butikk_mer;
  static String get a1_butikk_del => languages.ops_butikk_del;
  static String get a1_butikk_spor_aegil => languages.ops_butikk_spor_aegil;
  static String get a1_butikk_spor_aegil_line => languages.ops_butikk_spor_aegil_line;
  static String get a1_butikk_spesial => languages.ops_butikk_spesial;
  static String get a1_butikk_kjokkenluka => languages.ops_butikk_kjokkenluka;
  static String a1_butikk_spar(num kr) => languages.ops_butikk_spar('${kr.toInt()}');
  static String a1_butikk_kroner(num kr) => languages.ops_butikk_kroner('${kr.toInt()}');
  static String get a1_butikk_mest_bestilt => languages.ops_butikk_mest_bestilt;
  static String get a1_butikk_inkl_mva => languages.ops_butikk_inkl_mva;
  static String get a1_butikk_ingen_allergener => languages.ops_butikk_ingen_allergener;
  static String get a1_butikk_legg_til => languages.ops_butikk_legg_til;
  static String get a1_butikk_ny => languages.ops_butikk_ny;
  static String get a1_butikk_i_kurven => languages.ops_butikk_i_kurven;
  static String get a1_butikk_tom_kurven => languages.ops_butikk_tom_kurven;
  static String a1_butikk_kurv_antall(int n) => languages.ops_butikk_kurv_antall(n);
  static String get a1_butikk_til_kassen => languages.ops_butikk_til_kassen;
  static String get a1_butikk_menu_empty => languages.ops_butikk_menu_empty;
  static String get a1_butikk_not_found => languages.ops_butikk_not_found;
  static String get a1_butikk_drikke_hint => languages.ops_butikk_drikke_hint;
  static String get a1_butikk_bare_for_deg => languages.ops_butikk_bare_for_deg;
  static String get a1_butikk_spesial_under => languages.ops_butikk_spesial_under;
  static String a1_butikk_lev_min(int min) => languages.ops_butikk_lev_min(min);
  static String get a1_butikk_om_stedet => languages.ops_butikk_om_stedet;
  static String get a1_butikk_alt => languages.ops_butikk_alt;
  static String get a1_butikk_sok_meny => languages.ops_butikk_sok_meny;
  static String get a1_butikk_tom => languages.ops_butikk_tom;
  static String a1_butikk_varer_i_kurven(int n) => languages.ops_butikk_varer_i_kurven(n);
  static String get a1_butikk_endre_kurv => languages.ops_butikk_endre_kurv;
  static String a1_butikk_ut_av_kurven(String navn) => languages.ops_butikk_ut_av_kurven(navn);
  static String a1_butikk_til_navn(String navn) => languages.ops_butikk_til_navn(navn);
  static String get a1_butikk_gratis_levering => languages.ops_butikk_gratis_levering;
  static String get a1_butikk_minstebestilling => languages.ops_butikk_minstebestilling;
  static String a1_butikk_ingen_treff_meny(String q) => languages.ops_butikk_ingen_treff_meny(q);
  static String a1_butikk_sum_kr(String kr) => languages.ops_butikk_sum_kr(kr);
  static String a1_butikk_av_mal(String kr) => languages.ops_butikk_av_mal(kr);
  static String a1_butikk_stk(int n) => languages.ops_butikk_stk(n);

  // ── Mote / gave page ────────────────────────────────────────────────────
  static String get a1_butikk_mote_label => languages.ops_butikk_mote_label;
  static String a1_butikk_gave_label(String navn) => languages.ops_butikk_gave_label(navn);
  static String a1_butikk_anledning_label(String x) => languages.ops_butikk_anledning_label(x);
  static String get a1_butikk_ukens => languages.ops_butikk_ukens;
  static String get a1_butikk_personalets => languages.ops_butikk_personalets;
  static String get a1_butikk_spor_butikken => languages.ops_butikk_spor_butikken;
  static String a1_butikk_til_denne(String navn, String pris) => languages.ops_butikk_til_denne(navn, pris);
  static String get a1_butikk_pluss_legg => languages.ops_butikk_pluss_legg;
  static String get a1_butikk_lagt_til => languages.ops_butikk_lagt_til;
  static String get a1_butikk_til_hvem => languages.ops_butikk_til_hvem;
  static List<String> get a1_butikk_til_hvem_liste => _en
      ? const ['Partner', 'Friend', 'Parent', 'Colleague', 'Child']
      : const ['Kjæresten', 'Venn', 'Forelder', 'Kollega', 'Barn'];
  static String get a1_butikk_merker => languages.ops_butikk_merker;
  static String get a1_butikk_alle => languages.ops_butikk_alle;
  static String get a1_butikk_hyllene => languages.ops_butikk_hyllene;
  static String get a1_butikk_populaer => languages.ops_butikk_populaer;
  static String get a1_butikk_bergensk => languages.ops_butikk_bergensk;
  static String get a1_butikk_innpakning => languages.ops_butikk_innpakning;
  static String a1_butikk_storrelse_hint(String navn) => languages.ops_butikk_storrelse_hint(navn);
  static String get a1_butikk_storrelse_hint_generic => languages.ops_butikk_storrelse_hint_generic;
  static String get a1_butikk_melding_sendt => languages.ops_butikk_melding_sendt;
  static String get a1_butikk_melding_hint => languages.ops_butikk_melding_hint;
  static String get a1_butikk_send => languages.ops_butikk_send;

  // ── Klede sheet ─────────────────────────────────────────────────────────
  static String get a1_butikk_klede_farge => languages.ops_butikk_klede_farge;
  static String get a1_butikk_klede_storrelse => languages.ops_butikk_klede_storrelse;
  static String get a1_butikk_klede_paa_lager => languages.ops_butikk_klede_paa_lager;
  static String get a1_butikk_klede_utsolgt => languages.ops_butikk_klede_utsolgt;
  static String get a1_butikk_klede_prov => languages.ops_butikk_klede_prov;
  static String a1_butikk_klede_legg(String pris) => languages.ops_butikk_klede_legg(pris);
  static String get a1_butikk_klede_velg_str => languages.ops_butikk_klede_velg_str;

  // ── Food product sheet ──────────────────────────────────────────────────
  static String get a1_butikk_prod_mest_bestilt => languages.ops_butikk_prod_mest_bestilt;
  static String a1_butikk_prod_poeng(int n) => languages.ops_butikk_prod_poeng(n);
  static String a1_butikk_prod_klar(int min) => languages.ops_butikk_prod_klar(min);
  static String get a1_butikk_prod_inkl_mva => languages.ops_butikk_prod_inkl_mva;
  static String get a1_butikk_prod_storrelse => languages.ops_butikk_prod_storrelse;
  static String get a1_butikk_prod_velg_en => languages.ops_butikk_prod_velg_en;
  static String get a1_butikk_prod_tillegg => languages.ops_butikk_prod_tillegg;
  static String get a1_butikk_prod_styrke => languages.ops_butikk_prod_styrke;
  static String get a1_butikk_prod_allergener => languages.ops_butikk_prod_allergener;
  static String a1_butikk_prod_legg(String pris) => languages.ops_butikk_prod_legg(pris);
  static String get a1_butikk_prod_standard => languages.ops_butikk_prod_standard;
  static String get a1_butikk_prod_legg_kort => languages.ops_butikk_prod_legg_kort;
  static String a1_butikk_prod_sum(String pris) => languages.ops_butikk_prod_sum(pris);
  static String get a1_butikk_prod_valgfritt => languages.ops_butikk_prod_valgfritt;
  static String a1_butikk_prod_valgt(int n) => languages.ops_butikk_prod_valgt(n);
  static String a1_butikk_prod_allergen_linje(String liste) => languages.ops_butikk_prod_allergen_linje(liste);
  static String a1_butikk_prod_i_kurven(String navn) => languages.ops_butikk_prod_i_kurven(navn);
  static String get a1_butikk_prod_lukk => languages.ops_butikk_prod_lukk;
  static String get a1_butikk_prod_valgt_en => _t('✓ Valgt', '✓ Chosen');
  // ── Mote / gave page (Launch) ───────────────────────────────────────────
  static String a1_mote_apen_til(String t) => _t('Åpen til $t', 'Open until $t');
  static String a1_mote_apner(String t) => _t('Åpner $t', 'Opens $t');
  static String get a1_mote_stengt => _t('Stengt nå', 'Closed now');
  static String get a1_mote_gratis_lev => _t('Gratis levering', 'Free delivery');
  static String a1_mote_lev(String kr) => _t('Levering $kr', 'Delivery $kr');
  static List<String> get a1_mote_seg => _en ? const ['Men', 'Women', 'Kids'] : const ['Herre', 'Dame', 'Barn'];
  static List<String> get a1_gave_seg => const ['Under 300', '300–600', '600+'];
  static List<String> get a1_mote_filtre =>
      _en ? const ['All', 'T-shirts', 'Sweaters', 'Trousers'] : const ['Alle', 'T-skjorter', 'Gensere', 'Bukser'];
  static List<String> get a1_gave_filtre =>
      _en ? const ['All', 'Flowers', 'Chocolate', 'Interior'] : const ['Alle', 'Blomster', 'Sjokolade', 'Interiør'];
  static String get a1_mote_sok_hint => _t('Søk i butikken — jeans, ull, str. M …', 'Search the store — jeans, wool, size M …');
  static String get a1_mote_gave_aegil => _t('La Ægil finne en gave', 'Let Ægil find a gift');
  static String get a1_mote_ingen_treff => _t('Ingen varer passer her ennå.', 'Nothing matches here yet.');
  static String get a1_butikk_info_kan_inneholde => _t('KAN INNEHOLDE', 'MAY CONTAIN');
  static String get a1_butikk_info_apen_naa => _t('Åpen nå', 'Open now');
  static String get a1_butikk_info_stengt_naa => _t('Stengt nå', 'Closed now');
  static String a1_butikk_info_stenger(String t) => _t('· stenger $t', '· closes $t');
  static String a1_butikk_info_aapner(String t) => _t('· åpner $t', '· opens $t');
  static String get a1_butikk_info_adresse => _t('Adresse', 'Address');
  static String get a1_butikk_info_minsteordre => _t('Minsteordre', 'Minimum order');
  static String get a1_butikk_info_lev => _t('Levering', 'Delivery');
  static String get a1_butikk_info_gratis => _t('Gratis', 'Free');
  static String get a1_butikk_info_henting_rad => _t('Henting', 'Pickup');
  static String get a1_butikk_info_ja => _t('Ja', 'Yes');
  static String get a1_butikk_info_nei => _t('Nei', 'No');
  static String get a1_butikk_prod_paakrevd => _t('Påkrevd', 'Required');
  static String get a1_butikk_prod_inkludert => _t('Inkludert', 'Included');
  static String get a1_butikk_prod_ofte_med => _t('Ofte kjøpt med', 'Often bought with');

  // ── Info sheet ──────────────────────────────────────────────────────────
  static String get a1_butikk_info_allergen_line => languages.ops_butikk_info_allergen_line;
  static String get a1_butikk_info_allergen_missing => languages.ops_butikk_info_allergen_missing;
  static String get a1_butikk_info_idag => languages.ops_butikk_info_idag;
  static String get a1_butikk_info_stengt => languages.ops_butikk_info_stengt;
  static String a1_butikk_info_minste(String kr) => languages.ops_butikk_info_minste(kr);
  static String a1_butikk_info_levering(String kr) => languages.ops_butikk_info_levering(kr);
  static String get a1_butikk_info_henting => languages.ops_butikk_info_henting;
  static String get a1_butikk_info_del => languages.ops_butikk_info_del;
  static String get a1_butikk_info_kopiert => languages.ops_butikk_info_kopiert;

  // ── Category sheet (`arkAapent`) ────────────────────────────────────────
  static String a1_butikk_ark_under(String bydel) => languages.ops_butikk_ark_under(bydel);
  static String get a1_butikk_ark_open => languages.ops_butikk_ark_open;

  // ── Poseautomaten ───────────────────────────────────────────────────────
  static String get a1_butikk_automat_title => languages.ops_butikk_automat_title;
  static String get a1_butikk_automat_line => languages.ops_butikk_automat_line;
  static String a1_butikk_automat_igjen(int n) => languages.ops_butikk_automat_igjen(n);
  static String a1_butikk_automat_verdi(int kr) => languages.ops_butikk_automat_verdi(kr);
  static String get a1_butikk_automat_styr => languages.ops_butikk_automat_styr;
  static String get a1_butikk_automat_din => languages.ops_butikk_automat_din;
  static String a1_butikk_automat_hentes(String w) => languages.ops_butikk_automat_hentes(w);
  static String a1_butikk_automat_sikre(int kr) => languages.ops_butikk_automat_sikre(kr);
  static String get a1_butikk_automat_igjen_cta => languages.ops_butikk_automat_igjen_cta;
  static String get a1_butikk_automat_avslores => languages.ops_butikk_automat_avslores;
  static String a1_butikk_automat_trekk(int kr) => languages.ops_butikk_automat_trekk(kr);
  static String get a1_butikk_automat_se_kurv => languages.ops_butikk_automat_se_kurv;
  static String get a1_butikk_automat_footer => languages.ops_butikk_automat_footer;
  static String get a1_butikk_automat_empty => languages.ops_butikk_automat_empty;
}
