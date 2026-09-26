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

  // ── Feed tab (design `utforsk` · Feed segment, ≈L4402–4511) ────────────
  static String a1_feed_orb(String slug) => switch (slug) {
    'restaurant' => languages.ops_feed_orb_restaurant,
    'fisk' => languages.ops_feed_orb_fisk,
    'bakeri' => languages.ops_feed_orb_bakeri,
    'gront' => languages.ops_feed_orb_gront,
    'mote' => languages.ops_feed_orb_mote,
    _ => languages.ops_feed_orb_alle,
  };
  static String get a1_feed_follow => languages.ops_feed_follow;
  static String get a1_feed_following => languages.ops_feed_following;
  static String a1_feed_follow_toast(String name) => languages.ops_feed_follow_toast(name);
  static String a1_feed_unfollow_toast(String name) => languages.ops_feed_unfollow_toast(name);
  static String get a1_feed_share => languages.ops_feed_share;
  static String a1_feed_share_text(String title, String store) => languages.ops_feed_share_text(title, store);
  static String get a1_feed_published_by_aerend => languages.ops_feed_published_by_aerend;
  static String a1_feed_distance_m(int m) => languages.ops_feed_distance_m(m);
  static String a1_feed_distance_km(String km) => languages.ops_feed_distance_km(km);
  static String a1_feed_status_open(String eta) => languages.ops_feed_status_open(eta);
  static String get a1_feed_status_open_plain => languages.ops_feed_status_open_plain;
  static String get a1_feed_status_closed => languages.ops_feed_status_closed;
  static String a1_feed_status_opens(String time) => languages.ops_feed_status_opens(time);
  static String a1_feed_eta(int a, int b) => languages.ops_feed_eta(a, b);
  static String get a1_feed_cta_add => languages.ops_feed_cta_add;
  static String get a1_feed_cta_add_again => languages.ops_feed_cta_add_again;
  static String get a1_feed_cta_store => languages.ops_feed_cta_store;
  static String get a1_feed_cta_post => languages.ops_feed_cta_post;
  static String a1_feed_price(int kr) => languages.ops_feed_price(kr);
  static String a1_feed_price_from(int kr) => languages.ops_feed_price_from(kr);
  static String a1_feed_hint_ordered_days(int n) => languages.ops_feed_hint_ordered_days(n);
  static String a1_feed_hint_ordered_weeks(int n) => languages.ops_feed_hint_ordered_weeks(n);
  static String a1_feed_badge(String postType, {required bool today}) => switch (postType) {
    'tilbud' => languages.ops_feed_badge_tilbud,
    'ny_i_hyllene' => languages.ops_feed_badge_ny_i_hyllene,
    'dagens_rett' => languages.ops_feed_badge_dagens_rett,
    'ny_pa_aerend' => languages.ops_feed_badge_ny_pa_aerend,
    'nytt_i_hyllene' => languages.ops_feed_badge_nytt_i_hyllene,
    'tilbud_i_naerheten' => languages.ops_feed_badge_tilbud_i_naerheten,
    'apent_sent' => languages.ops_feed_badge_apent_sent,
    'populaert_i_kveld' => languages.ops_feed_badge_populaert_i_kveld,
    'butikk_i_fokus' => languages.ops_feed_badge_butikk_i_fokus,
    'drift' => languages.ops_feed_badge_drift,
    _ => today ? languages.ops_feed_badge_today : languages.ops_feed_badge_generic,
  };
  static String get a1_feed_video_muted => languages.ops_feed_video_muted;
  static String get a1_feed_video_muted_stop => languages.ops_feed_video_muted_stop;
  static String get a1_feed_video_play => languages.ops_feed_video_play;
  static String a1_feed_time_today(String time) => languages.ops_feed_time_today(time);
  static String get a1_feed_time_yesterday => languages.ops_feed_time_yesterday;
  static String a1_feed_time_minutes(int n) => languages.ops_feed_time_minutes(n);
  static String a1_feed_time_hours(int n) => languages.ops_feed_time_hours(n);
  static String a1_feed_time_days(int n) => languages.ops_feed_time_days(n);
  static String get a1_feed_empty_cat_title => languages.ops_feed_empty_cat_title;
  static String get a1_feed_empty_cat_text => languages.ops_feed_empty_cat_text;
  static String get a1_feed_empty_cat_cta => languages.ops_feed_empty_cat_cta;
  static String get a1_feed_empty_title => languages.ops_feed_empty_title;
  static String get a1_feed_empty_text => languages.ops_feed_empty_text;
  static String get a1_feed_empty_cta => languages.ops_feed_empty_cta;
  static String get a1_feed_error_title => languages.ops_feed_error_title;
  static String get a1_feed_error_text => languages.ops_feed_error_text;
  static String get a1_feed_retry => languages.ops_feed_retry;
  static String a1_feed_promo_price(int kr, int value) => languages.ops_feed_promo_price(kr, value);
  static String a1_feed_open_store(String store) => languages.ops_feed_open_store(store);
  static String a1_feed_likes(int n) => languages.ops_feed_likes(n);
  static String a1_feed_comments(int n) => languages.ops_feed_comments(n);
}
