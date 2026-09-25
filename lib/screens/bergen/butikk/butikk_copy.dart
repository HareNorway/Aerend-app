// ignore_for_file: non_constant_identifier_names

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
  static String a1_butikk_kat_open(int n) =>
      _t('$n åpne nå · Bergen', '$n open now · Bergen');
  static String get a1_butikk_kat_bestill_bilde =>
      _t('Bestill fra bilde', 'Order from a photo');
  static String get a1_butikk_kat_butikker => _t('Butikker', 'Shops');
  static String get a1_butikk_kat_produkter => _t('Produkter', 'Products');
  static String a1_butikk_kat_pulse(String kat, int n) => _t(
    'Akkurat nå i $kat: $n bestillinger siste time',
    'Right now in $kat: $n orders in the last hour',
  );
  static String get a1_butikk_kat_bestiller_naa =>
      _t('bestiller nå', 'ordering now');
  static String get a1_butikk_kat_video => 'VIDEO';
  static String get a1_butikk_kat_f_open => _t('Åpen nå', 'Open now');
  static String get a1_butikk_kat_f_free =>
      _t('Gratis levering', 'Free delivery');
  static String get a1_butikk_kat_f_fast => _t('Under 30 min', 'Under 30 min');
  static String get a1_butikk_kat_f_top => _t('Topprangert', 'Top rated');
  static String get a1_butikk_kat_empty =>
      _t('Ingen butikker her ennå.', 'No shops here yet.');
  static String get a1_butikk_kat_empty_products =>
      _t('Ingen produkter her ennå.', 'No products here yet.');
  static String get a1_butikk_kat_free => _t('Gratis', 'Free');
  static String a1_butikk_kat_eta(int min) => '$min min';

  // Gaver variant
  static String get a1_butikk_gave_idag =>
      _t('Rekker fram i dag', 'Arrives today');
  static String a1_butikk_gave_innen(String time) =>
      _t('Innen $time', 'By $time');
  static String get a1_butikk_gave_aegil =>
      _t('La Ægil finne en gave ›', 'Let Ægil find a gift ›');
  static String get a1_butikk_gave_utstilling =>
      _t('Ukens utstilling · Gaver', 'This week\'s display · Gifts');
  static String get a1_butikk_gave_anledninger =>
      _t('Anledninger', 'Occasions');
  static String get a1_butikk_gave_naerheten =>
      _t('Butikker i nærheten', 'Shops nearby');
  static String get a1_butikk_gave_innpakning =>
      _t('GRATIS INNPAKNING', 'FREE WRAPPING');
  static String a1_butikk_gave_populaert(String bydel) =>
      _t('Populært til bursdag i $bydel', 'Popular for birthdays in $bydel');
  static List<String> get a1_butikk_gave_anledning_liste => _en
      ? const ['Birthday', 'Housewarming', 'Thank you', 'Just because']
      : const ['Bursdag', 'Innflytting', 'Takk', 'Bare fordi'];

  // Mote variant
  static String get a1_butikk_mote_utstilling =>
      _t('Ukens utstilling · Mote', 'This week\'s display · Fashion');
  static String a1_butikk_mote_antall(int n) => _t('$n plagg', '$n pieces');

  // ── Dreieskiven ─────────────────────────────────────────────────────────
  static String get a1_butikk_skive_lagre => _t(
    'Lagre · si fra hvis prisen faller',
    'Save · tell me if the price drops',
  );
  static String get a1_butikk_skive_lagret => _t('Lagret', 'Saved');
  static String get a1_butikk_skive_legg => _t('Legg til', 'Add');
  static String get a1_butikk_skive_hint =>
      _t('Dra for å snurre', 'Drag to spin');

  // ── Butikk (restaurant) ─────────────────────────────────────────────────
  static String a1_butikk_open_til(String t) =>
      _t('Åpent til $t', 'Open until $t');
  static String a1_butikk_apner(String t) => _t('Åpner $t', 'Opens $t');
  static String get a1_butikk_stengt => _t('Stengt nå', 'Closed now');
  static String get a1_butikk_kjokken =>
      _t('Kjøkkenet er i gang', 'The kitchen is running');
  static String get a1_butikk_pauset =>
      _t('Pause i kjøkkenet', 'The kitchen is paused');
  static String a1_butikk_km(double km) =>
      '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  static String a1_butikk_levering(String fee) =>
      _t('Levering $fee', 'Delivery $fee');
  static String a1_butikk_aerend_idag(int n) =>
      _t('$n ærend i dag', '$n errands today');
  static String a1_butikk_kikker(int n) => _t('$n kikker nå', '$n looking now');
  static String get a1_butikk_seilas => _t('SEILASEN DIN', 'YOUR VOYAGE');
  static String get a1_butikk_kjokkenet => _t('Kjøkkenet', 'The kitchen');
  static String get a1_butikk_din_dor => _t('Din dør', 'Your door');
  static String get a1_butikk_gratis_frakt =>
      _t('Gratis frakt', 'Free delivery');
  static String get a1_butikk_dessert => _t('Dessert', 'Dessert');
  static String get a1_butikk_ti_prosent => '10 %';
  static String a1_butikk_min(num kr) =>
      _t('MIN. ${kr.toInt()} KR', 'MIN. ${kr.toInt()} KR');
  static String get a1_butikk_neste => _t('NESTE FORDEL', 'NEXT PERK');
  static String a1_butikk_igjen(num kr, String navn) =>
      _t('${kr.toInt()} kr igjen til $navn', '${kr.toInt()} kr to $navn');
  static String get a1_butikk_havn => _t(
    'Båten er i havn — alt låst opp',
    'The boat is in — everything unlocked',
  );
  static String get a1_butikk_frakt_naadd =>
      _t('Nå fikser jeg gratis frakt for deg', 'Now I get you free delivery');
  static String get a1_butikk_allergener => _t('Allergener', 'Allergens');
  static String get a1_butikk_apningstider =>
      _t('Åpningstider', 'Opening hours');
  static String get a1_butikk_mer => _t('Mer', 'More');
  static String get a1_butikk_del => _t('Del', 'Share');
  static String get a1_butikk_spor_aegil => _t('Spør Ægil', 'Ask Ægil');
  static String get a1_butikk_spor_aegil_line => _t(
    'Meny, allergener, hva som går fort',
    'Menu, allergens, what is quick',
  );
  static String get a1_butikk_spesial =>
      _t('Ærend spesialtilbud', 'Ærend specials');
  static String get a1_butikk_kjokkenluka => 'Kjøkkenluka';
  static String a1_butikk_spar(num kr) =>
      _t('Spar ${kr.toInt()} kr', 'Save ${kr.toInt()} kr');
  static String a1_butikk_kroner(num kr) =>
      _t('+${kr.toInt()} kr', '+${kr.toInt()} kr');
  static String get a1_butikk_mest_bestilt =>
      _t('Mest bestilt', 'Most ordered');
  static String get a1_butikk_inkl_mva =>
      _t('Priser inkl. mva', 'Prices incl. VAT');
  static String get a1_butikk_ingen_allergener =>
      _t('Ingen allergener', 'No allergens');
  static String get a1_butikk_legg_til => _t('Legg til', 'Add');
  static String get a1_butikk_ny => _t('Ny', 'New');
  static String get a1_butikk_i_kurven => _t('I kurven', 'In the basket');
  static String get a1_butikk_tom_kurven =>
      _t('Tøm kurven', 'Empty the basket');
  static String a1_butikk_kurv_antall(int n) =>
      _t(n == 1 ? '1 vare' : '$n varer', n == 1 ? '1 item' : '$n items');
  static String get a1_butikk_til_kassen => _t('Til kassen', 'To checkout');
  static String get a1_butikk_menu_empty => _t(
    'Menyen legges inn av butikken. Prøv igjen om litt.',
    'The shop is adding its menu. Try again shortly.',
  );
  static String get a1_butikk_not_found =>
      _t('Fant ikke butikken.', 'Could not find the shop.');
  static String get a1_butikk_drikke_hint => _t(
    'Drikke legges inn av butikken denne uken. Vann fra kranen i Bergen er uansett blant landets beste.',
    'Drinks are being added by the shop this week. Bergen tap water is among the country\'s best anyway.',
  );

  // ── Mote / gave page ────────────────────────────────────────────────────
  static String get a1_butikk_mote_label => _t('Mote-butikk', 'Fashion shop');
  static String a1_butikk_gave_label(String navn) =>
      _t('Gavebutikk · $navn', 'Gift shop · $navn');
  static String a1_butikk_anledning_label(String x) =>
      _t('Anledning · $x', 'Occasion · $x');
  static String get a1_butikk_ukens => _t('UKENS', 'THIS WEEK');
  static String get a1_butikk_personalets =>
      _t('PERSONALETS FAVORITT', 'STAFF PICK');
  static String get a1_butikk_spor_butikken =>
      _t('Spør butikken', 'Ask the shop');
  static String a1_butikk_til_denne(String navn, String pris) =>
      _t('Til denne: $navn · $pris', 'With this: $navn · $pris');
  static String get a1_butikk_pluss_legg => _t('+ Legg til', '+ Add');
  static String get a1_butikk_lagt_til => _t('Lagt til', 'Added');
  static String get a1_butikk_til_hvem => _t('Til hvem', 'For whom');
  static List<String> get a1_butikk_til_hvem_liste => _en
      ? const ['Partner', 'Friend', 'Parent', 'Colleague', 'Child']
      : const ['Kjæresten', 'Venn', 'Forelder', 'Kollega', 'Barn'];
  static String get a1_butikk_merker => _t('Merker', 'Brands');
  static String get a1_butikk_alle => _t('Alle', 'All');
  static String get a1_butikk_hyllene => _t('Hyllene', 'The shelves');
  static String get a1_butikk_populaer =>
      _t('Populær i Bergen', 'Popular in Bergen');
  static String get a1_butikk_bergensk => _t('Bergensk', 'From Bergen');
  static String get a1_butikk_innpakning => _t('INNPAKNING', 'WRAPPING');
  static String a1_butikk_storrelse_hint(String navn) => _t(
    'Usikker på størrelsen? Spør butikken — $navn svarer i Varsler.',
    'Unsure about the size? Ask the shop — $navn replies in Varsler.',
  );
  static String get a1_butikk_storrelse_hint_generic => _t(
    'Usikker på størrelsen? Spør butikken — de svarer i Varsler.',
    'Unsure about the size? Ask the shop — they reply in Varsler.',
  );
  static String get a1_butikk_melding_sendt =>
      _t('Meldingen er sendt til butikken', 'Your message went to the shop');
  static String get a1_butikk_melding_hint =>
      _t('Hva lurer du på?', 'What would you like to know?');
  static String get a1_butikk_send => _t('Send', 'Send');

  // ── Klede sheet ─────────────────────────────────────────────────────────
  static String get a1_butikk_klede_farge => _t('Farge', 'Colour');
  static String get a1_butikk_klede_storrelse => _t('Størrelse', 'Size');
  static String get a1_butikk_klede_paa_lager => _t('På lager', 'In stock');
  static String get a1_butikk_klede_utsolgt => _t('Utsolgt', 'Sold out');
  static String get a1_butikk_klede_prov => _t(
    'Prøv hjemme. Budet henter returen gratis innen 14 dager.',
    'Try it at home. The courier collects the return for free within 14 days.',
  );
  static String a1_butikk_klede_legg(String pris) =>
      _t('Legg i kurv · $pris', 'Add to basket · $pris');
  static String get a1_butikk_klede_velg_str =>
      _t('Velg størrelse', 'Choose a size');

  // ── Food product sheet ──────────────────────────────────────────────────
  static String get a1_butikk_prod_mest_bestilt =>
      _t('Mest bestilt i kveld', 'Most ordered tonight');
  static String a1_butikk_prod_poeng(int n) => _t('+$n poeng', '+$n points');
  static String a1_butikk_prod_klar(int min) =>
      _t('Klar på $min min', 'Ready in $min min');
  static String get a1_butikk_prod_inkl_mva => _t('inkl. mva', 'incl. VAT');
  static String get a1_butikk_prod_storrelse => _t('Størrelse', 'Size');
  static String get a1_butikk_prod_velg_en => _t('Velg én', 'Choose one');
  static String get a1_butikk_prod_tillegg => _t('Tillegg', 'Extras');
  static String get a1_butikk_prod_styrke => _t('Styrke', 'Heat');
  static String get a1_butikk_prod_allergener => _t('Allergener', 'Allergens');
  static String a1_butikk_prod_legg(String pris) =>
      _t('Legg til · $pris', 'Add · $pris');
  static String get a1_butikk_prod_standard => _t('Standard', 'Standard');

  // ── Info sheet ──────────────────────────────────────────────────────────
  static String get a1_butikk_info_allergen_line => _t(
    'Alle retter merkes med allergener på samme sted, alltid. Spør gjerne budet om noe er uklart.',
    'Every dish carries its allergens in the same place, always. Ask the courier if anything is unclear.',
  );
  static String get a1_butikk_info_allergen_missing => _t(
    'Butikken har ikke lagt inn allergener ennå — spør butikken før du bestiller.',
    'The shop has not listed allergens yet — ask the shop before ordering.',
  );
  static String get a1_butikk_info_idag => _t('I dag', 'Today');
  static String get a1_butikk_info_stengt => _t('Stengt', 'Closed');
  static String a1_butikk_info_minste(String kr) =>
      _t('Minsteordre $kr', 'Minimum order $kr');
  static String a1_butikk_info_levering(String kr) =>
      _t('levering $kr', 'delivery $kr');
  static String get a1_butikk_info_henting =>
      _t('henting mulig', 'pickup possible');
  static String get a1_butikk_info_del => _t('Del butikken', 'Share the shop');
  static String get a1_butikk_info_kopiert =>
      _t('Lenken er kopiert', 'Link copied');

  // ── Category sheet (`arkAapent`) ────────────────────────────────────────
  static String a1_butikk_ark_under(String bydel) =>
      _t('Åpne nå · $bydel', 'Open now · $bydel');
  static String get a1_butikk_ark_open => _t('Åpen', 'Open');

  // ── Poseautomaten ───────────────────────────────────────────────────────
  static String get a1_butikk_automat_title =>
      _t('Poseautomaten', 'The bag machine');
  static String get a1_butikk_automat_line => _t(
    'Kveldens overskudd fra butikkene. Alltid verdt minst det dobbelte.',
    'Tonight\'s surplus from the shops. Always worth at least double.',
  );
  static String a1_butikk_automat_igjen(int n) => _t('$n igjen', '$n left');
  static String a1_butikk_automat_verdi(int kr) =>
      _t('verdi minst $kr', 'worth at least $kr');
  static String get a1_butikk_automat_styr => _t(
    'Styr klypen med pilene · posen lander her',
    'Steer the claw with the arrows · the bag lands here',
  );
  static String get a1_butikk_automat_din =>
      _t('POSEN ER DIN', 'THE BAG IS YOURS');
  static String a1_butikk_automat_hentes(String w) =>
      _t('Hentes $w', 'Pick up $w');
  static String a1_butikk_automat_sikre(int kr) =>
      _t('Sikre posen · $kr kr', 'Secure the bag · $kr kr');
  static String get a1_butikk_automat_igjen_cta =>
      _t('Prøv igjen', 'Try again');
  static String get a1_butikk_automat_avslores => _t(
    'Innholdet avsløres under nordlys ved henting',
    'The contents are revealed under the northern lights at pickup',
  );
  static String a1_butikk_automat_trekk(int kr) =>
      _t('Trekk i spaken · $kr kr', 'Pull the lever · $kr kr');
  static String get a1_butikk_automat_se_kurv =>
      _t('Se posen i kurven', 'See the bag in the basket');
  static String get a1_butikk_automat_footer => _t(
    'Ingen nedtelling. Ingen niter. Verdigulvet står på maskinen.',
    'No countdown. No blanks. The value floor is on the machine.',
  );
  static String get a1_butikk_automat_empty =>
      _t('Ingen poser i automaten i kveld.', 'No bags in the machine tonight.');
}
