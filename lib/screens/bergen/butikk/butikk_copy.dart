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

  static String kr(num v) =>
      '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)} kr';

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
