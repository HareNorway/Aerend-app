// ignore_for_file: non_constant_identifier_names

import '../../../utils/utils.dart';

/// Copy for Søk (`sok` ≈L4067–4228 in `Ærend Kunde Bergen.dc.html`).
/// AGIL-CONTRACT §3.2: class `SokCopy`, keys `a1_sok_*`, NO and EN.
abstract final class SokCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get a1_sok_title =>
      _t('Hva leter du etter?', 'What are you looking for?');
  static String get a1_sok_subtitle => _t(
    'Et ord — så søker jeg. Et ønske — så ordner jeg ærendet.',
    'A word — and I search. A wish — and I run the errand.',
  );
  static String get a1_sok_hint => _t(
    'Søk i Bergen — butikker, varer, bydeler',
    'Search Bergen — shops, goods, districts',
  );
  static String get a1_sok_voice => _t('Snakk', 'Speak');

  // wish banner (`sokOnske`)
  static String get a1_sok_onske_title =>
      _t('Dette høres ut som et ærend', 'This sounds like an errand');
  static String get a1_sok_onske_line => _t(
    'Kurv med levering på under 20 sekunder — du betaler selv',
    'A basket with delivery in under 20 seconds — you pay yourself',
  );
  static String get a1_sok_onske_cta => _t('Spør Ægil', 'Ask Ægil');

  // results (`Søk · treff`)
  static String a1_sok_butikker(int n) =>
      _t(n == 1 ? '1 butikk' : '$n butikker', n == 1 ? '1 shop' : '$n shops');
  static String a1_sok_produkter(int n) => _t(
    n == 1 ? '1 produkt' : '$n produkter',
    n == 1 ? '1 product' : '$n products',
  );
  static String get a1_sok_butikker_label => _t('Butikker', 'Shops');
  static String get a1_sok_produkter_label => _t('Produkter', 'Products');
  static String a1_sok_treff(int n) =>
      _t('$n treff i Bergen', '$n hits in Bergen');
  static String a1_sok_eta(int min) => '$min min';
  static String get a1_sok_add => _t('Legg til', 'Add');
  static String get a1_sok_see => _t('Se', 'See');
  static String get a1_sok_free => _t('Gratis', 'Free');
  static String get a1_sok_closed => _t('Stengt', 'Closed');

  // `sokVanlig` footer
  static String get a1_sok_ask_aegil => _t('SPØR ÆGIL', 'ASK ÆGIL');
  static String a1_sok_compare(String q) => _t(
    'Sammenlikn «$q» på pris og levering',
    'Compare «$q» on price and delivery',
  );

  // `sokIngen`
  static String a1_sok_ingen_title(String q) =>
      _t('Ingen treff på «$q» i Bergen ennå', 'No hits for «$q» in Bergen yet');
  static String get a1_sok_ingen_line => _t(
    'Prøv et annet ord, eller la Ægil lete for deg.',
    'Try another word, or let Ægil look for you.',
  );
  static String get a1_sok_ingen_cta =>
      _t('La Ægil finne nærmeste', 'Let Ægil find the nearest');

  // `sokTom`
  static String get a1_sok_kategorier => _t('Kategorier', 'Categories');
  static String a1_sok_utforsker(int tried, int total) => _t(
    'Utforsker · $tried av $total prøvd',
    'Explorer · $tried of $total tried',
  );
  static String a1_sok_alle(int n) => _t('Alle $n', 'All $n');

  // Spør Ægil card
  static String get a1_sok_aegil_kicker => _t('SPØR ÆGIL', 'ASK ÆGIL');
  static String get a1_sok_aegil_line => _t(
    'Si hva du trenger. Jeg ordner ærendet.',
    'Say what you need. I run the errand.',
  );
  static String get a1_sok_aegil_eks1 =>
      _t('Tacokveld for fire under 500 kr', 'Taco night for four under 500 kr');
  static String get a1_sok_aegil_eks2 =>
      _t('Billigste reker i nærheten', 'Cheapest shrimp nearby');
  static String get a1_sok_aegil_start => _t('Start samtale', 'Start a chat');
  static String get a1_sok_aegil_skriv =>
      _t('Skriv eller snakk', 'Type or speak');

  // recent / trending / mission
  static String get a1_sok_nylig => _t('NYLIG', 'RECENT');
  static String get a1_sok_populaert => _t('POPULÆRT NÅ', 'POPULAR NOW');
  static String a1_sok_oppdrag_kicker(int points) => _t(
    'UKENS OPPDRAG · +$points POENG',
    'THIS WEEK\'S MISSION · +$points POINTS',
  );
  static String get a1_sok_oppdrag_se => _t('Se', 'See');
  static String get a1_sok_clear_recent => _t('Tøm', 'Clear');
}
