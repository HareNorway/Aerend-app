// ignore_for_file: non_constant_identifier_names

import '../../../utils/utils.dart';

/// Copy for Søk (`sok` L5122–5297 in `Ærend Kunde Launch.dc.html`).
/// AGIL-CONTRACT §3.2: class `SokCopy`, keys `a1_sok_*`, NO and EN.
abstract final class SokCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get a1_sok_title => languages.ops_sok_title;
  static String get a1_sok_subtitle => languages.ops_sok_subtitle;
  static String get a1_sok_hint => languages.ops_sok_hint;
  static String get a1_sok_voice => languages.ops_sok_voice;

  // wish banner (`sokOnske`)
  static String get a1_sok_onske_title => languages.ops_sok_onske_title;
  static String get a1_sok_onske_line => languages.ops_sok_onske_line;
  static String get a1_sok_onske_cta => languages.ops_sok_onske_cta;
  static String a1_sok_onske_ask(String q) => languages.ops_sok_onske_ask(q);

  // results (`Søk · treff`)
  static String a1_sok_butikker(int n) => languages.ops_sok_butikker(n);
  static String a1_sok_produkter(int n) => languages.ops_sok_produkter(n);
  static String get a1_sok_butikker_label => languages.ops_sok_butikker_label;
  static String get a1_sok_produkter_label => languages.ops_sok_produkter_label;
  static String a1_sok_treff(int n) => languages.ops_sok_treff(n);
  static String a1_sok_eta(int min) => languages.ops_sok_eta(min);
  static String get a1_sok_add => languages.ops_sok_add;
  static String get a1_sok_see => languages.ops_sok_see;
  static String get a1_sok_free => languages.ops_sok_free;
  static String get a1_sok_closed => languages.ops_sok_closed;

  // `sokVanlig` footer
  static String get a1_sok_ask_aegil => languages.ops_sok_ask_aegil;
  static String a1_sok_compare(String q) => languages.ops_sok_compare(q);

  // `sokIngen`
  static String a1_sok_ingen_title(String q) => languages.ops_sok_ingen_title(q);
  static String get a1_sok_ingen_line => languages.ops_sok_ingen_line;
  static String get a1_sok_ingen_cta => languages.ops_sok_ingen_cta;

  // `sokTom`
  static String get a1_sok_kategorier => languages.ops_sok_kategorier;
  static String a1_sok_utforsker(int tried, int total) => languages.ops_sok_utforsker(tried, total);
  static String a1_sok_alle(int n) => languages.ops_sok_alle(n);

  // Spør Ægil card
  static String get a1_sok_aegil_kicker => languages.ops_sok_aegil_kicker;
  static String get a1_sok_aegil_line => _t(
    'Si hva du trenger, så ordner jeg ærendet.',
    'Say what you need, and I run the errand.',
  );
  static String get a1_sok_aegil_eks1 => languages.ops_sok_aegil_eks1;
  static String get a1_sok_aegil_eks2 => languages.ops_sok_aegil_eks2;
  static String get a1_sok_aegil_start => languages.ops_sok_aegil_start;
  static String get a1_sok_aegil_skriv => languages.ops_sok_aegil_skriv;

  // recent / trending / mission
  static String get a1_sok_nylig => _t('Nylige søk', 'Recent searches');
  static String get a1_sok_populaert =>
      _t('Populært i Bergen nå', 'Popular in Bergen now');
  static String get a1_sok_ingen_nylig => _t(
    'Ingen søk ennå. Det du søker etter, dukker opp her.',
    'No searches yet. What you search for shows up here.',
  );
  static String a1_sok_antall(int n) => _t('$n søk', '$n searches');

  // `nar(n)` — how long ago a recent search was
  static String get a1_sok_nar_naa => _t('Akkurat nå', 'Just now');
  static String a1_sok_nar_min(int m) => _t('$m min siden', '$m min ago');
  static String a1_sok_nar_t(int h) => _t('$h t siden', '${h}h ago');
  static String get a1_sok_nar_igaar => _t('I går', 'Yesterday');
  static String a1_sok_nar_dager(int d) =>
      _t('$d dager siden', '$d days ago');

  // Ukens oppdrag
  static String get a1_sok_oppdrag_tittel =>
      _t('UKENS OPPDRAG', 'THIS WEEK’S MISSION');
  static String a1_sok_oppdrag_poeng(int p) => _t('+$p p', '+$p pts');

  /// "Én bestilling teller." — or how far along a longer mission is.
  static String a1_sok_oppdrag_teller(int gjort, int maal) {
    if (maal <= 1) return _t('Én bestilling teller.', 'One order counts.');
    if (gjort > 0) {
      return _t('$gjort av $maal bestillinger', '$gjort of $maal orders');
    }
    return _t('$maal bestillinger teller.', '$maal orders count.');
  }
  static String a1_sok_oppdrag_kicker(int points) => languages.ops_sok_oppdrag_kicker(points);
  static String get a1_sok_oppdrag_se => languages.ops_sok_oppdrag_se;
  static String get a1_sok_clear_recent => languages.ops_sok_clear_recent;
}
