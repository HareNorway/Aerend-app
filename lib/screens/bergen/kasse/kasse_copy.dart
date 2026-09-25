// ignore_for_file: non_constant_identifier_names

import '../../../main.dart' show languages;
import '../../../utils/utils.dart';

/// Copy for the Kasse group (`kurv` ≈L4973–5250, the Adresse / Ny adresse /
/// Levering / Betaling sheets ≈L6913–7142, `kjopSteg2–4` ≈L5249,
/// Bestillingsdetaljer ≈L5641 in `Ærend Kunde Bergen.dc.html`).
/// AGIL-CONTRACT §3.2: class `KasseCopy`, keys `a1_kasse_*`, NO and EN.
abstract final class KasseCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String kr(num v) =>
      '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)} kr';

  // ── Seilas · kassen ─────────────────────────────────────────────────────
  static String get a1_kasse_bryggen => languages.ops_kasse_bryggen;
  static String get a1_kasse_kassen => languages.ops_kasse_kassen;
  static String get a1_kasse_ror => languages.ops_kasse_ror;
  static String get a1_kasse_levering => languages.ops_kasse_levering;
  static String get a1_kasse_henting => languages.ops_kasse_henting;

  // ── empty ───────────────────────────────────────────────────────────────
  static String get a1_kasse_tom_kicker => languages.ops_kasse_tom_kicker;
  static String get a1_kasse_tom_title => languages.ops_kasse_tom_title;
  static String get a1_kasse_tom_cta => languages.ops_kasse_tom_cta;
  static String get a1_kasse_tom_tilbud => languages.ops_kasse_tom_tilbud;
  static String get a1_kasse_tom_rett => languages.ops_kasse_tom_rett;

  // ── lines ───────────────────────────────────────────────────────────────
  static String get a1_kasse_legg_mer => languages.ops_kasse_legg_mer;
  static String get a1_kasse_glemte_drikke => languages.ops_kasse_glemte_drikke;
  static String get a1_kasse_fjern => languages.ops_kasse_fjern;

  // ── Endre rows ──────────────────────────────────────────────────────────
  static String get a1_kasse_endre => languages.ops_kasse_endre;
  static String get a1_kasse_adr_tittel => languages.ops_kasse_adr_tittel;
  static String get a1_kasse_adr_velg => languages.ops_kasse_adr_velg;
  static String get a1_kasse_hent_tittel => languages.ops_kasse_hent_tittel;
  static String get a1_kasse_se_kart => languages.ops_kasse_se_kart;
  static String get a1_kasse_tid_asap => languages.ops_kasse_tid_asap;
  static String a1_kasse_tid_innen(String t, int a, int b) => languages.ops_kasse_tid_innen(t, a, b);
  static String get a1_kasse_betaling_ved => languages.ops_kasse_betaling_ved;
  static String get a1_kasse_vipps => languages.ops_kasse_vipps;
  static String get a1_kasse_kort => languages.ops_kasse_kort;
  static String get a1_kasse_beskjed_bud => languages.ops_kasse_beskjed_bud;
  static String get a1_kasse_beskjed_butikk => languages.ops_kasse_beskjed_butikk;
  static String get a1_kasse_beskjed_hint => languages.ops_kasse_beskjed_hint;
  static String get a1_kasse_flere_valg => languages.ops_kasse_flere_valg;
  static String get a1_kasse_hentetid => languages.ops_kasse_hentetid;
  static String get a1_kasse_hentetid_line => languages.ops_kasse_hentetid_line;

  // ── tips ────────────────────────────────────────────────────────────────
  static String get a1_kasse_tips_title => languages.ops_kasse_tips_title;
  static String get a1_kasse_tips_line => languages.ops_kasse_tips_line;
  static String get a1_kasse_tips_rad => languages.ops_kasse_tips_rad;

  // ── summary ─────────────────────────────────────────────────────────────
  static String get a1_kasse_sammendrag => languages.ops_kasse_sammendrag;
  static String get a1_kasse_varer => languages.ops_kasse_varer;
  static String get a1_kasse_frakt => languages.ops_kasse_frakt;
  static String get a1_kasse_frakt_fri => languages.ops_kasse_frakt_fri;
  static String get a1_kasse_avgifter => languages.ops_kasse_avgifter;
  static String get a1_kasse_rabatt => languages.ops_kasse_rabatt;
  static String a1_kasse_aegil_linjer(String navn, String sum) => languages.ops_kasse_aegil_linjer(navn, sum);
  static String get a1_kasse_angre => languages.ops_kasse_angre;
  static String get a1_kasse_angret => languages.ops_kasse_angret;
  static String get a1_kasse_doren => languages.ops_kasse_doren;
  static String get a1_kasse_doren_hint => languages.ops_kasse_doren_hint;
  static String get a1_kasse_tolk => languages.ops_kasse_tolk;
  static String get a1_kasse_kode => languages.ops_kasse_kode;
  static String get a1_kasse_kode_line => languages.ops_kasse_kode_line;
  static String get a1_kasse_gave_til => languages.ops_kasse_gave_til;
  static String get a1_kasse_gave_navn_hint => languages.ops_kasse_gave_navn_hint;
  static String get a1_kasse_overrask => languages.ops_kasse_overrask;
  static String get a1_kasse_overrask_line => languages.ops_kasse_overrask_line;
  static String get a1_kasse_si_fra => languages.ops_kasse_si_fra;
  static String get a1_kasse_si_fra_line => languages.ops_kasse_si_fra_line;
  static String get a1_kasse_a_betale => languages.ops_kasse_a_betale;
  static String get a1_kasse_totalt => languages.ops_kasse_totalt;
  static String get a1_kasse_inkl => languages.ops_kasse_inkl;
  static String a1_kasse_cashback(String kr) => languages.ops_kasse_cashback(kr);
  static String get a1_kasse_bergenske => languages.ops_kasse_bergenske;
  static String a1_kasse_krysser(String bud) => languages.ops_kasse_krysser(bud);
  static String a1_kasse_betal(String kr) => languages.ops_kasse_betal(kr);
  static String get a1_kasse_betal_vipps => languages.ops_kasse_betal_vipps;
  static String a1_kasse_min_ordre(String kr) => languages.ops_kasse_min_ordre(kr);
  static String get a1_kasse_velg_adresse_forst => languages.ops_kasse_velg_adresse_forst;
  static String get a1_kasse_utenfor => languages.ops_kasse_utenfor;
  static String get a1_kasse_utenfor_line => languages.ops_kasse_utenfor_line;
  static String get a1_kasse_velg_henting => languages.ops_kasse_velg_henting;
  static String get a1_kasse_kort_legacy => languages.ops_kasse_kort_legacy;

  // ── sheets ──────────────────────────────────────────────────────────────
  static String get a1_kasse_adr_sheet_title => languages.ops_kasse_adr_sheet_title;
  static String get a1_kasse_adr_sheet_line => languages.ops_kasse_adr_sheet_line;
  static String get a1_kasse_adr_ny => languages.ops_kasse_adr_ny;
  static String get a1_kasse_adr_ny_line => languages.ops_kasse_adr_ny_line;
  static String get a1_kasse_adr_dor_kicker => languages.ops_kasse_adr_dor_kicker;
  static String get a1_kasse_adr_dor_line => languages.ops_kasse_adr_dor_line;
  static String get a1_kasse_ikke_dekket => languages.ops_kasse_ikke_dekket;
  static String get a1_kasse_si_fra_cta => languages.ops_kasse_si_fra_cta;
  static String get a1_kasse_sagt_fra => languages.ops_kasse_sagt_fra;
  static String get a1_kasse_lev_sheet_title => languages.ops_kasse_lev_sheet_title;
  static String get a1_kasse_lev_middag => languages.ops_kasse_lev_middag;
  static String get a1_kasse_lev_middag_line => languages.ops_kasse_lev_middag_line;
  static String get a1_kasse_lev_kveld => languages.ops_kasse_lev_kveld;
  static String get a1_kasse_lev_kveld_line => languages.ops_kasse_lev_kveld_line;
  static String get a1_kasse_bruk_dette => languages.ops_kasse_bruk_dette;
  static String get a1_kasse_bet_sheet_title => languages.ops_kasse_bet_sheet_title;
  static String get a1_kasse_bet_sheet_line => languages.ops_kasse_bet_sheet_line;
  static String a1_kasse_bet_vipps(String tlf) =>
      tlf.isEmpty ? 'Vipps' : 'Vipps · $tlf';
  static String get a1_kasse_bet_kort => languages.ops_kasse_bet_kort;

  // ── purchase sequence ───────────────────────────────────────────────────
  static String get a1_kasse_bekreftet => languages.ops_kasse_bekreftet;
  static String get a1_kasse_bekreftet_line => languages.ops_kasse_bekreftet_line;
  static String get a1_kasse_folg => languages.ops_kasse_folg;
  static String get a1_kasse_billett_kicker => languages.ops_kasse_billett_kicker;
  static String get a1_kasse_verv => languages.ops_kasse_verv;
  static String a1_kasse_gi_faa(int kr) => languages.ops_kasse_gi_faa(kr);
  static String a1_kasse_billett_line(int kr) => languages.ops_kasse_billett_line(kr);
  static String get a1_kasse_del_billett => languages.ops_kasse_del_billett;
  static String get a1_kasse_kopier => languages.ops_kasse_kopier;
  static String get a1_kasse_kopiert => languages.ops_kasse_kopiert;
  static String get a1_kasse_lukk => languages.ops_kasse_lukk;

  // ── Bestillingsdetaljer ─────────────────────────────────────────────────
  static String get a1_kasse_best_sammendrag => languages.ops_kasse_best_sammendrag;
  static String get a1_kasse_best_detaljer => languages.ops_kasse_best_detaljer;
  static String get a1_kasse_best_bestilling => languages.ops_kasse_best_bestilling;
  static String get a1_kasse_best_betalt_vipps => languages.ops_kasse_best_betalt_vipps;
  static String get a1_kasse_best_betalt => languages.ops_kasse_best_betalt;
  static String get a1_kasse_best_kvittering => languages.ops_kasse_best_kvittering;
  static String get a1_kasse_best_klar => languages.ops_kasse_best_klar;
  static String get a1_kasse_best_status => languages.ops_kasse_best_status;
  static String get a1_kasse_best_din => languages.ops_kasse_best_din;
  static String get a1_kasse_best_total => languages.ops_kasse_best_total;
  static String get a1_kasse_best_betaling => languages.ops_kasse_best_betaling;
  static String get a1_kasse_best_butikken => languages.ops_kasse_best_butikken;
  static String get a1_kasse_best_ordrenr => languages.ops_kasse_best_ordrenr;
  static String get a1_kasse_best_aerend_id => languages.ops_kasse_best_aerend_id;
  static String get a1_kasse_best_tid => languages.ops_kasse_best_tid;
  static String get a1_kasse_best_kvitt => languages.ops_kasse_best_kvitt;
  static String get a1_kasse_best_meg => languages.ops_kasse_best_meg;
  static String get a1_kasse_best_kundeservice => languages.ops_kasse_best_kundeservice;
  static String get a1_kasse_best_se_alt => languages.ops_kasse_best_se_alt;
  static String a1_kasse_best_antall(int n) => languages.ops_kasse_best_antall(n);
  static String get a1_kasse_best_ikke_funnet => languages.ops_kasse_best_ikke_funnet;
  static String get a1_kasse_best_kopiert => languages.ops_kasse_best_kopiert;
}
