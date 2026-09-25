// ignore_for_file: non_constant_identifier_names

import '../../../utils/utils.dart';

/// Copy for the Utforsk group (`utforsk` ≈L4389 and `feed` ≈L6643 in
/// `Ærend Kunde Bergen.dc.html`). AGIL-CONTRACT §3.2: class `UtforskCopy`,
/// keys `a1_utforsk_*`, NO and EN; moved to ARB as `ops_utforsk_*` in Phase 8.
abstract final class UtforskCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  // ── screen ──────────────────────────────────────────────────────────────
  static String get a1_utforsk_title => _t('Utforsk', 'Explore');
  static String get a1_utforsk_tab_feed => 'Feed';
  static String get a1_utforsk_tab_fiske => 'Fjordfiske';
  static String get a1_utforsk_tab_pose =>
      _t('Forundringspose', 'Surprise bag');
  static String get a1_utforsk_filter_alle => _t('Alle', 'All');
  static String get a1_utforsk_kommer_snart =>
      _t('Kommer snart', 'Coming soon');

  // ── Drift notice ────────────────────────────────────────────────────────
  static String get a1_utforsk_drift_title => 'Ærend · Drift';
  static String a1_utforsk_drift_pinned(String until) =>
      _t('Festet til $until', 'Pinned until $until');

  // ── Fjordfiske landing ──────────────────────────────────────────────────
  static String get a1_utforsk_fiske_intro => _t(
    'For kveldene du bare vil se — aldri i veien når du er sulten.',
    'For the evenings you just want to look — never in the way when you are hungry.',
  );
  static String a1_utforsk_fiske_napp(int n) =>
      _t('$n napp igjen i dag', '$n bites left today');
  static String get a1_utforsk_fiske_line => _t(
    'Kast ut — finn ting du ikke visste du ville ha. Høyre lagrer, opp legger i kurven.',
    'Cast out — find things you did not know you wanted. Right saves, up adds to the basket.',
  );
  static String get a1_utforsk_fiske_cta => _t('Kast ut', 'Cast out');

  // ── Forundringspose tab ─────────────────────────────────────────────────
  static String get a1_utforsk_pose_title =>
      _t('Forundringsposer i nærheten', 'Surprise bags nearby');
  static String a1_utforsk_pose_left_today(int n) =>
      _t('$n igjen i dag', '$n left today');
  static String get a1_utforsk_pose_line => _t(
    'Overskudd fra butikkene til en brøkdel. Innholdet avsløres under nordlys ved levering.',
    'Surplus from the shops at a fraction. The contents are revealed under the northern lights at delivery.',
  );
  static String a1_utforsk_pose_left(int n) => _t('$n igjen', '$n left');
  static String a1_utforsk_pose_value(int kr) =>
      _t('verdi minst $kr kr', 'worth at least $kr kr');
  static String a1_utforsk_pose_pickup(String window) =>
      _t('Hentes $window', 'Pick up $window');
  static String a1_utforsk_pose_price(int kr) => '$kr kr';
  static String get a1_utforsk_pose_secure => _t('Sikre en', 'Grab one');
  static String get a1_utforsk_pose_empty => _t(
    'Ingen poser i nærheten akkurat nå — butikkene legger ut når de har overskudd.',
    'No bags nearby right now — the shops list them when they have surplus.',
  );
  static String get a1_utforsk_automat =>
      _t('Poseautomaten', 'The bag machine');
  static String a1_utforsk_automat_line(int kr) =>
      _t('Trekk i spaken · $kr kr', 'Pull the lever · $kr kr');

  // ── Feed promo (design `visPromo`) ──────────────────────────────────────
  static String get a1_utforsk_promo_label =>
      _t('FORUNDRINGSPOSE · GRØNT & GODT', 'SURPRISE BAG · GREENS & GOODIES');
  static String get a1_utforsk_promo_cta => _t('Hent posen', 'Get the bag');
  static String a1_utforsk_promo_left(int n) =>
      _t('$n igjen · ekte antall', '$n left · real count');

  // ── Feed empty state ────────────────────────────────────────────────────
  static String get a1_utforsk_feed_empty_title =>
      _t('Ingenting nytt her ennå', 'Nothing new here yet');
  static String get a1_utforsk_feed_empty_text => _t(
    'Følg butikker i nærheten, så dukker de opp her.',
    'Follow shops nearby and they show up here.',
  );

  // ── Nytt fra butikkene (`feed` ≈L6643) ──────────────────────────────────
  static String a1_utforsk_nyheter_chip(String bydel) =>
      _t('$bydel · i dag', '$bydel · today');
  static String get a1_utforsk_nyheter_title =>
      _t('Nytt fra butikkene', 'New from the shops');
  static String get a1_utforsk_nyheter_bergensk =>
      _t('Bergensk', 'From Bergen');
  static String a1_utforsk_nyheter_order(String price) =>
      _t('Bestill · $price', 'Order · $price');
  static String get a1_utforsk_nyheter_see_store => _t('Se butikk', 'See shop');
  static String get a1_utforsk_nyheter_see => _t('Se', 'See');
  static String get a1_utforsk_nyheter_footer => _t(
    'Bare butikker i nærheten av deg · ingen reklame',
    'Only shops near you · no ads',
  );
  static String get a1_utforsk_nyheter_empty =>
      _t('Ingen nyheter fra butikkene i dag.', 'No news from the shops today.');
}
