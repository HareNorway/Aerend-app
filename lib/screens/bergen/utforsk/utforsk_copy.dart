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

  /// The flag beside share (backend plan Step 9).
  static const String a1_feed_report = 'Rapporter innlegget';
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

  /// The heart without its number, when «Antall likes» is off (Step 13).
  static String get a1_feed_like => languages.post_detail_like;
  static String a1_feed_comments(int n) => languages.ops_feed_comments(n);

  // ── Launch (Step 9) ─────────────────────────────────────────────────────
  static String get a1_feed_folger_tom_title => _t('Du følger ingen ennå', 'You don’t follow anyone yet');
  static String get a1_feed_folger_tom_text =>
      _t('Følg butikkene du liker, så samles det nye her.', 'Follow the shops you like, and what’s new gathers here.');
  static String a1_feed_image_from(String store) => _t('Bilde fra $store', 'Photo from $store');

  // Forundringspose segment (L5632–5707).
  static String a1_pose_rabatt(int pct) => '−$pct %';

  // ── Bergen Step 3: the carousel, the module and the bag sheet ───────────
  static String get a1_pose_linje => _t(
    'Overskudd fra butikkene til en brøkdel av prisen. Trykk på en pose for å se hva butikken har lagt i den.',
    'Surplus from the shops at a fraction of the price. Tap a bag to see what the shop has put in it.',
  );
  static String a1_pose_hentes(String vindu) => _t('hentes $vindu', 'pick up $vindu');
  static String get a1_pose_sikret => _t('Sikret', 'Secured');
  static String get a1_pose_sikre_label => _t('Sikre en pose', 'Secure a bag');
  static String a1_pose_sikret_toast(String vindu) =>
      vindu.isEmpty ? _t('Posen er sikret', 'The bag is secured') : _t('Posen er sikret · hentes i dag $vindu', 'The bag is secured · pick up today $vindu');
  static String a1_pose_avstand(double km) {
    if (km < 1) {
      final m = (km * 1000 / 50).round() * 50;
      return '${m < 50 ? 50 : m} m';
    }
    return '${km.toStringAsFixed(1).replaceAll('.', _en ? '.' : ',')} km';
  }
  static String get a1_pose_tilfeldig => _t('Tilfeldig pose', 'Random bag');
  static String get a1_pose_automat_linje => _t('En pose fra kveldens butikker, alltid verdt minst det dobbelte.', 'A bag from tonight’s shops, always worth at least double.');
  static String get a1_pose_trekk => _t('Trekk i spaken', 'Pull the lever');
  static String get a1_pose_automat_label => _t('Åpne Poseautomaten', 'Open the bag machine');
  static String a1_pose_tittel_under(String? kat) => kat == null ? 'Forundringspose' : 'Forundringspose · $kat';
  static String get a1_pose_se_butikken => _t('Se butikken', 'See the shop');
  static String a1_pose_sikre_cta(int kr) => _t('Sikre en · $kr kr', 'Secure one · $kr kr');
  static String a1_pose_sikret_cta(String vindu) => vindu.isEmpty ? _t('Sikret', 'Secured') : _t('Sikret · hentes $vindu', 'Secured · pick up $vindu');
  static String get a1_pose_overraskelse => _t('Overraskelse fra dagens overskudd', 'A surprise from today’s surplus');
  static String a1_pose_poeng(int n) => _t('+$n poeng', '+$n points');
  static String a1_pose_pluss_poeng(int n) => _t('+$n poeng', '+$n points');
  static String a1_pose_du_betaler(int kr) => _t('Du betaler $kr kr', 'You pay $kr kr');
  static String a1_pose_du_sparer(int kr) => _t('Du sparer minst $kr kr', 'You save at least $kr kr');
  static String get a1_pose_hentes_idag => _t('Hentes i dag', 'Pick up today');
  static String get a1_pose_lagt_ut_idag => _t('Lagt ut i dag', 'Put out today');
  static String a1_pose_lagt_ut_kl(String kl) => _t('Lagt ut i dag $kl', 'Put out today $kl');
  static String get a1_pose_skriver => _t('1 · Butikken skriver om posen', '1 · The shop on the bag');

  // ── Bergen Step 4: Butikkprofil (L10189–10320) ──────────────────────────
  static String get a1_bp_innlegg => _t('innlegg', 'posts');
  static String get a1_bp_folgere => _t('følgere', 'followers');
  static String a1_bp_folgere_tall(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1).replaceAll('.', _en ? '.' : ',')}k';
    final s = '$n';
    return s.length <= 3 ? s : '${s.substring(0, s.length - 3)}${_en ? ',' : ' '}${s.substring(s.length - 3)}';
  }
  static String get a1_bp_min_levering => _t('min levering', 'min delivery');
  static String get a1_bp_folg => _t('Følg', 'Follow');
  static String get a1_bp_folger => _t('Følger', 'Following');
  static String a1_bp_folger_toast(String navn) => _t('Du følger $navn · innleggene havner under «Følger» i Utforsk', 'You follow $navn · their posts land under «Følger» in Explore');
  static String a1_bp_folger_ikke_toast(String navn) => _t('Du følger ikke $navn lenger', 'You no longer follow $navn');
  static String get a1_bp_se_menyen => _t('Se menyen', 'See the menu');
  static String get a1_bp_apen => _t('Åpen', 'Open');
  static String a1_bp_apen_til(String kl) => _t('Åpen · stenger $kl', 'Open · closes $kl');
  static String get a1_bp_stengt => _t('Stengt', 'Closed');
  static String a1_bp_stengt_til(String kl) => _t('Stengt · åpner $kl', 'Closed · opens $kl');
  static String get a1_bp_fane_innlegg => _t('Innlegg', 'Posts');
  static String get a1_bp_fane_tilbud => _t('Tilbud', 'Offers');
  static String get a1_bp_fane_aerend => _t('Fra Ærend', 'From Ærend');
  static String a1_bp_aerend_info(String navn) => _t('Ærend skriver om butikker i nærheten. $navn ser innleggene og kan skjule dem.', 'Ærend writes about shops nearby. $navn sees the posts and can hide them.');
  static String get a1_bp_nytt => _t('NYTT', 'NEW');
  static String get a1_bp_video => _t('Video', 'Video');
  static String get a1_bp_tom_tilbud => _t('Ingen tilbud akkurat nå', 'No offers right now');
  static String a1_bp_tom_tilbud_under(String navn) => _t('Følg $navn, så ser du nye tilbud i «Følger».', 'Follow $navn to see new offers in «Følger».');
  static String a1_bp_tom_aerend(String navn) => _t('Ærend har ikke skrevet om $navn ennå', 'Ærend hasn’t written about $navn yet');
  static String get a1_bp_tom_aerend_under => _t('Ærend skriver om butikker i nærheten når det skjer noe der.', 'Ærend writes about shops nearby when something happens there.');
  static String get a1_bp_tom_innlegg => _t('Ingen innlegg ennå', 'No posts yet');
  static String a1_bp_tom_innlegg_under(String navn) => _t('$navn har ikke lagt ut noe ennå.', '$navn hasn’t posted anything yet.');
  static String get a1_bp_over_innlegg => _t('INNLEGG', 'POSTS');
  static String get a1_bp_over_tilbud => _t('TILBUD', 'OFFERS');
  static String get a1_bp_over_aerend => _t('FRA ÆREND', 'FROM ÆREND');
  static String a1_bp_aerend_skriver(String dato) => _t('Ærend skriver · $dato', 'Ærend writes · $dato');
  static String a1_bp_i_dag(String kl) => _t('i dag $kl', 'today $kl');
  static String a1_bp_i_gar(String kl) => _t('i går $kl', 'yesterday $kl');
  static String a1_bp_ukedag(int d) => (_en ? const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] : const ['man', 'tir', 'ons', 'tor', 'fre', 'lør', 'søn'])[d - 1];
  static String get a1_bp_legg_i_kurven => _t('Legg i kurven', 'Add to basket');
  static String a1_bp_legg_i_kurven_vare(String vare) => _t('Legg i kurven · $vare', 'Add to basket · $vare');
  static String a1_pose_kort_under(String what, int valueKr) =>
      _t('$what · verdi minst $valueKr kr', '$what · worth at least $valueKr kr');
  static String a1_pose_hentes_til(String time) => _t('Hentes til $time', 'Pick up by $time');
  static String a1_pose_aapner(String time) => _t('Åpner $time', 'Opens $time');
  static String get a1_pose_stengt => _t('Stengt i dag', 'Closed today');
  static String get a1_pose_feed_title => _t('Ærend-feed', 'Ærend feed');
  static String a1_pose_feed_nye(int n) => _t('$n nye', '$n new');
  static String a1_pose_feed_linje(String store, String title) => '$store: $title';
  static String get a1_pose_feed_tom => _t('Nytt fra butikkene i Bergen', 'New from the shops in Bergen');
  static String a1_maal_igjen(String prize, int left) =>
      _t('Mål: $prize · ${_nf(left)} poeng igjen', 'Goal: $prize · ${_nf(left)} points to go');
  static String a1_maal_klar(String prize) => _t('Mål: $prize · klar å hente', 'Goal: $prize · ready to claim');
  static String get a1_maal_ingen =>
      _t('Ingen mål satt · velg en premie på hylla', 'No goal set · pick a prize on the shelf');
  static String a1_poeng(int n) => _t('${_nf(n)} poeng', '${_nf(n)} points');
  static String get a1_premiehylla => _t('Premiehylla', 'Prize shelf');

  // Poseautomaten (L5715–5906).
  static String a1_auto_igjen(int n) => _t('$n igjen i dag · ekte antall', '$n left today · real count');
  static String get a1_auto_title => _t('Poseautomaten', 'The bag machine');
  static String get a1_auto_line =>
      _t('Kveldens overskudd fra butikkene. Alltid verdt minst det dobbelte.', 'Tonight’s surplus from the shops. Always worth at least double.');
  static String get a1_auto_skilt => _t('POSEAUTOMATEN', 'BAG MACHINE');
  static String a1_auto_verdi(int kr) => _t('verdi minst $kr', 'worth at least $kr');
  static String a1_auto_kr(int kr) => '$kr KR';
  static String get a1_auto_utgang => _t('UTGANG', 'EXIT');
  static String get a1_auto_hint_start =>
      _t('Styr klypen med pilene. Posen lander i Vågen.', 'Steer the claw with the arrows. The bag lands in Vågen.');
  static String get a1_auto_hint_en =>
      _t('Én pose per butikk. Velg en ny butikk med pilene.', 'One bag per shop. Pick another shop with the arrows.');
  static String get a1_auto_hint_alle =>
      _t('Alle posene er hentet i dag. Nye kommer i morgen kl. 16.', 'Every bag is taken today. New ones come tomorrow at 16.');
  static String get a1_auto_din => _t('POSEN ER DIN', 'THE BAG IS YOURS');
  static String get a1_auto_fisker => _t('ÆGIL FISKER', 'ÆGIL IS FISHING');
  static String get a1_auto_i_kurven_merke => _t('I KURVEN', 'IN THE BASKET');
  static String get a1_auto_i_kurven => _t('I kurven', 'In the basket');
  static String get a1_auto_linje_flyter =>
      _t('Posen flyter i Vågen. Ægil fisker den inn til deg.', 'The bag is afloat in Vågen. Ægil fishes it in for you.');
  static String get a1_auto_linje_ror => _t('Ægil ror ut og kaster snøret …', 'Ægil rows out and casts …');
  static String a1_auto_linje_kurv(String hentes) =>
      _t('Ligger i kurven · ${hentes.toLowerCase()} · én pose per butikk', 'In the basket · ${hentes.toLowerCase()} · one bag per shop');
  static String a1_auto_fisk_inn(int kr) => _t('Fisk den inn · $kr kr', 'Fish it in · $kr kr');
  static String get a1_auto_prov_igjen => _t('Prøv igjen', 'Try again');
  static String get a1_auto_en_til => _t('Trekk en til', 'Pull another');
  static String get a1_auto_alle_hentet => _t('Alle posene er hentet i dag', 'Every bag is taken today');
  static String a1_auto_trekk(int kr) => _t('Trekk i spaken · $kr kr', 'Pull the lever · $kr kr');
  static String get a1_auto_se_kurven => _t('Se posen i kurven', 'See the bag in the basket');
  static String get a1_auto_fot =>
      _t('Ingen nedtelling. Ingen niter. Verdigulvet står på maskinen.', 'No countdown. No blanks. The value floor is on the machine.');
  static String get a1_auto_fisket_toast =>
      _t('Ægil fisket opp posen · den ligger i kurven', 'Ægil fished up the bag · it is in the basket');
  static String get a1_auto_tilbake => _t('Tilbake', 'Back');
  static String get a1_auto_spak => _t('Trekk i spaken', 'Pull the lever');
  static String get a1_auto_venstre => _t('Flytt klypen til venstre', 'Move the claw left');
  static String get a1_auto_hoyre => _t('Flytt klypen til høyre', 'Move the claw right');
  static String a1_auto_velg(String store) => _t('Velg $store', 'Pick $store');
  static String get a1_auto_tom =>
      _t('Ingen poser i automaten i kveld — butikkene legger ut når de har overskudd.', 'No bags in the machine tonight — the shops add them when they have surplus.');

  /// `1 240` — the prototype's `nf` (thin-space thousands).
  static String _nf(int n) {
    final s = n.abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}
