// ignore_for_file: non_constant_identifier_names

import '../../../main.dart' show languages;
import '../../../utils/utils.dart';

/// Copy for Søk (`sok` ≈L4067–4228 in `Ærend Kunde Bergen.dc.html`).
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
  static String get a1_sok_aegil_line => languages.ops_sok_aegil_line;
  static String get a1_sok_aegil_eks1 => languages.ops_sok_aegil_eks1;
  static String get a1_sok_aegil_eks2 => languages.ops_sok_aegil_eks2;
  static String get a1_sok_aegil_start => languages.ops_sok_aegil_start;
  static String get a1_sok_aegil_skriv => languages.ops_sok_aegil_skriv;

  // recent / trending / mission
  static String get a1_sok_nylig => languages.ops_sok_nylig;
  static String get a1_sok_populaert => languages.ops_sok_populaert;
  static String a1_sok_oppdrag_kicker(int points) => languages.ops_sok_oppdrag_kicker(points);
  static String get a1_sok_oppdrag_se => languages.ops_sok_oppdrag_se;
  static String get a1_sok_clear_recent => languages.ops_sok_clear_recent;
}
