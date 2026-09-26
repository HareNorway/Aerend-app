// ignore_for_file: non_constant_identifier_names

import '../../../main.dart' show languages;

/// Copy for Fjordfiske (`fiske` ≈L6435–6641 in `Ærend Kunde Bergen.dc.html`).
///
/// AGIL-UI-CONTRACT §2: every string lives in `intl_no.arb` / `intl_en.arb`
/// under `ops_fiske_*`; the `a1_fiske_*` member names are the traceability
/// key from the design. No widget spells a string.
abstract final class FiskeCopy {
  // ── header ──────────────────────────────────────────────────────────────
  static String get a1_fiske_title => languages.ops_fiske_title;
  static String get a1_fiske_sub => languages.ops_fiske_sub;
  static String a1_fiske_status(int kast, int av, int lagret) =>
      languages.ops_fiske_status(kast, av, lagret);
  static String get a1_fiske_aegil => languages.ops_fiske_aegil;
  static String get a1_fiske_tilbake => languages.ops_fiske_tilbake;

  // ── Ægil snakker (design `snakk[f]`) ────────────────────────────────────
  static String get a1_fiske_snakk_klar => languages.ops_fiske_snakk_klar;
  static String get a1_fiske_snakk_venter => languages.ops_fiske_snakk_venter;
  static String get a1_fiske_snakk_napp => languages.ops_fiske_snakk_napp;
  static String a1_fiske_snakk_fangst(String navn, String? butikk) =>
      butikk == null || butikk.isEmpty
          ? languages.ops_fiske_snakk_fangst_uten(navn)
          : languages.ops_fiske_snakk_fangst(navn, butikk);
  static String get a1_fiske_snakk_premie => languages.ops_fiske_snakk_premie;
  static String a1_fiske_snakk_premie_maal(String navn) =>
      languages.ops_fiske_snakk_premie_maal(navn);
  static String get a1_fiske_snakk_mistet => languages.ops_fiske_snakk_mistet;
  static String get a1_fiske_snakk_din => languages.ops_fiske_snakk_din;

  // ── Fiske-kontroller ────────────────────────────────────────────────────
  static String get a1_fiske_kast => languages.ops_fiske_kast;
  static String get a1_fiske_kast_igjen => languages.ops_fiske_kast_igjen;
  static String get a1_fiske_venter => languages.ops_fiske_venter;
  static String get a1_fiske_dra => languages.ops_fiske_dra;
  static String get a1_fiske_slipp => languages.ops_fiske_slipp;
  static String get a1_fiske_legg => languages.ops_fiske_legg;
  static String get a1_fiske_lagre => languages.ops_fiske_lagre;
  static String get a1_fiske_hent => languages.ops_fiske_hent;
  static String get a1_fiske_sett_maal => languages.ops_fiske_sett_maal;
  static String get a1_fiske_er_maal => languages.ops_fiske_er_maal;

  // ── hint line (design `fiskeHint`) ──────────────────────────────────────
  static String a1_fiske_hint_klar(int n) => languages.ops_fiske_hint_klar(n);
  static String get a1_fiske_hint_venter => languages.ops_fiske_hint_venter;
  static String get a1_fiske_hint_napp => languages.ops_fiske_hint_napp;
  static String get a1_fiske_hint_fangst => languages.ops_fiske_hint_fangst;
  static String get a1_fiske_hint_premie => languages.ops_fiske_hint_premie;
  static String a1_fiske_hint_capped(int max) =>
      languages.ops_fiske_hint_capped(max);

  // ── Fangst / Premiefangst ───────────────────────────────────────────────
  static String a1_fiske_plus(int n) => languages.ops_fiske_plus(n);
  static String get a1_fiske_napp => languages.ops_fiske_napp;
  static String get a1_fiske_fra_hylla => languages.ops_fiske_fra_hylla;
  static String a1_fiske_poeng_har(String pris, String har) =>
      languages.ops_fiske_poeng_har(pris, har);
  static String a1_fiske_poeng(String pris) => languages.ops_fiske_poeng(pris);
  static String get a1_fiske_tom => languages.ops_fiske_tom;
  static String get a1_fiske_bydel_bergen => languages.ops_fiske_bydel_bergen;
  static String get a1_fiske_eta_kommer => languages.ops_fiske_eta_kommer;

  // ── Ferdig ──────────────────────────────────────────────────────────────
  static String get a1_fiske_ferdig_title => languages.ops_fiske_ferdig_title;
  static String a1_fiske_ferdig_line(int lagret, int kjopt) =>
      languages.ops_fiske_ferdig_line(lagret, kjopt);
  static String get a1_fiske_se_lagret => languages.ops_fiske_se_lagret;
  static String get a1_fiske_i_morgen => languages.ops_fiske_i_morgen;

  // ── Agn (design `FKAT`) ─────────────────────────────────────────────────
  static String get a1_fiske_agn_alle => languages.ops_fiske_agn_alle;
  static String get a1_fiske_agn_fisk => languages.ops_fiske_agn_fisk;
  static String get a1_fiske_agn_mat => languages.ops_fiske_agn_mat;
  static String get a1_fiske_agn_mote => languages.ops_fiske_agn_mote;
  static String get a1_fiske_agn_interior => languages.ops_fiske_agn_interior;
  static String get a1_fiske_agn_gaver => languages.ops_fiske_agn_gaver;

  // ── toasts ──────────────────────────────────────────────────────────────
  static String get a1_fiske_toast_lagret => languages.ops_fiske_toast_lagret;
  static String a1_fiske_toast_din(String navn) =>
      languages.ops_fiske_toast_din(navn);
  static String get a1_fiske_toast_kunne_ikke =>
      languages.ops_fiske_toast_kunne_ikke;
  static String a1_fiske_toast_satt_maal(String navn) =>
      languages.ops_fiske_toast_satt_maal(navn);
}
