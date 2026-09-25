// ignore_for_file: non_constant_identifier_names

import '../../../main.dart' show languages;
import '../../../utils/utils.dart';

/// Copy for the Utforsk group (`utforsk` ≈L4389 and `feed` ≈L6643 in
/// `Ærend Kunde Bergen.dc.html`). AGIL-CONTRACT §3.2: class `UtforskCopy`,
/// keys `a1_utforsk_*`, NO and EN; moved to ARB as `ops_utforsk_*` in Phase 8.
abstract final class UtforskCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  // ── screen ──────────────────────────────────────────────────────────────
  static String get a1_utforsk_title => languages.ops_utforsk_title;
  static String get a1_utforsk_tab_feed => languages.ops_utforsk_tab_feed;
  static String get a1_utforsk_tab_fiske => languages.ops_utforsk_tab_fiske;
  static String get a1_utforsk_tab_pose => languages.ops_utforsk_tab_pose;
  static String get a1_utforsk_filter_alle => languages.ops_utforsk_filter_alle;
  static String get a1_utforsk_kommer_snart => languages.ops_utforsk_kommer_snart;

  // ── Drift notice ────────────────────────────────────────────────────────
  static String get a1_utforsk_drift_title => languages.ops_utforsk_drift_title;
  static String a1_utforsk_drift_pinned(String until) => languages.ops_utforsk_drift_pinned(until);

  // ── Fjordfiske landing ──────────────────────────────────────────────────
  static String get a1_utforsk_fiske_intro => languages.ops_utforsk_fiske_intro;
  static String a1_utforsk_fiske_napp(int n) => languages.ops_utforsk_fiske_napp(n);
  static String get a1_utforsk_fiske_line => languages.ops_utforsk_fiske_line;
  static String get a1_utforsk_fiske_cta => languages.ops_utforsk_fiske_cta;

  // ── Forundringspose tab ─────────────────────────────────────────────────
  static String get a1_utforsk_pose_title => languages.ops_utforsk_pose_title;
  static String a1_utforsk_pose_left_today(int n) => languages.ops_utforsk_pose_left_today(n);
  static String get a1_utforsk_pose_line => languages.ops_utforsk_pose_line;
  static String a1_utforsk_pose_left(int n) => languages.ops_utforsk_pose_left(n);
  static String a1_utforsk_pose_value(int kr) => languages.ops_utforsk_pose_value(kr);
  static String a1_utforsk_pose_pickup(String window) => languages.ops_utforsk_pose_pickup(window);
  static String a1_utforsk_pose_price(int kr) => languages.ops_utforsk_pose_price(kr);
  static String get a1_utforsk_pose_secure => languages.ops_utforsk_pose_secure;
  static String get a1_utforsk_pose_empty => languages.ops_utforsk_pose_empty;
  static String get a1_utforsk_automat => languages.ops_utforsk_automat;
  static String a1_utforsk_automat_line(int kr) => languages.ops_utforsk_automat_line(kr);

  // ── Feed promo (design `visPromo`) ──────────────────────────────────────
  static String get a1_utforsk_promo_label => languages.ops_utforsk_promo_label;
  static String get a1_utforsk_promo_cta => languages.ops_utforsk_promo_cta;
  static String a1_utforsk_promo_left(int n) => languages.ops_utforsk_promo_left(n);

  // ── Feed empty state ────────────────────────────────────────────────────
  static String get a1_utforsk_feed_empty_title => languages.ops_utforsk_feed_empty_title;
  static String get a1_utforsk_feed_empty_text => languages.ops_utforsk_feed_empty_text;

  // ── Nytt fra butikkene (`feed` ≈L6643) ──────────────────────────────────
  static String a1_utforsk_nyheter_chip(String bydel) => languages.ops_utforsk_nyheter_chip(bydel);
  static String get a1_utforsk_nyheter_title => languages.ops_utforsk_nyheter_title;
  static String get a1_utforsk_nyheter_bergensk => languages.ops_utforsk_nyheter_bergensk;
  static String a1_utforsk_nyheter_order(String price) => languages.ops_utforsk_nyheter_order(price);
  static String get a1_utforsk_nyheter_see_store => languages.ops_utforsk_nyheter_see_store;
  static String get a1_utforsk_nyheter_see => languages.ops_utforsk_nyheter_see;
  static String get a1_utforsk_nyheter_footer => languages.ops_utforsk_nyheter_footer;
  static String get a1_utforsk_nyheter_empty => languages.ops_utforsk_nyheter_empty;
}
