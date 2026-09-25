// ignore_for_file: non_constant_identifier_names

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
  static String get a1_kasse_bryggen => 'Bryggen';
  static String get a1_kasse_kassen => _t('Kassen', 'Checkout');
  static String get a1_kasse_ror =>
      _t('Ægil ror til bryggen', 'Ægil rows to the quay');
  static String get a1_kasse_levering => _t('Levering', 'Delivery');
  static String get a1_kasse_henting => _t('Henting', 'Pickup');

  // ── empty ───────────────────────────────────────────────────────────────
  static String get a1_kasse_tom_kicker => 'ÆGIL';
  static String get a1_kasse_tom_title => _t(
    'Kurven er tom — skal vi finne noe i Bergen?',
    'The basket is empty — shall we find something in Bergen?',
  );
  static String get a1_kasse_tom_cta =>
      _t('Bla gjennom Bergen', 'Browse Bergen');
  static String get a1_kasse_tom_tilbud =>
      _t('Tilbud i kveld', 'Tonight\'s offers');
  static String get a1_kasse_tom_rett =>
      _t('Rett i kurven', 'Straight to the basket');

  // ── lines ───────────────────────────────────────────────────────────────
  static String get a1_kasse_legg_mer =>
      _t('Legg til noe mer', 'Add something more');
  static String get a1_kasse_glemte_drikke =>
      _t('Glemte du drikke?', 'Forgot a drink?');
  static String get a1_kasse_fjern => _t('Fjern', 'Remove');

  // ── Endre rows ──────────────────────────────────────────────────────────
  static String get a1_kasse_endre => _t('Endre', 'Change');
  static String get a1_kasse_adr_tittel => _t('Leveres til', 'Deliver to');
  static String get a1_kasse_adr_velg =>
      _t('Velg adresse', 'Choose an address');
  static String get a1_kasse_hent_tittel => _t('Hentes hos', 'Pick up at');
  static String get a1_kasse_se_kart => _t('Se fullt kart', 'See the map');
  static String get a1_kasse_tid_asap =>
      _t('Så fort som mulig', 'As soon as possible');
  static String a1_kasse_tid_innen(String t, int a, int b) =>
      _t('Innen $t · $a–$b min', 'By $t · $a–$b min');
  static String get a1_kasse_betaling_ved =>
      _t('Betales ved bestilling', 'Paid at order');
  static String get a1_kasse_vipps => 'Vipps';
  static String get a1_kasse_kort => _t('Kort', 'Card');
  static String get a1_kasse_beskjed_bud =>
      _t('Beskjed til budet', 'A note for the courier');
  static String get a1_kasse_beskjed_butikk =>
      _t('Beskjed til butikken', 'A note for the shop');
  static String get a1_kasse_beskjed_hint =>
      _t('Porten står åpen …', 'The gate is open …');
  static String get a1_kasse_flere_valg => _t('Flere valg', 'More options');
  static String get a1_kasse_hentetid => _t('Hentetid', 'Pickup time');
  static String get a1_kasse_hentetid_line => _t(
    'Butikken pakker til dette klokkeslettet',
    'The shop packs for this time',
  );

  // ── tips ────────────────────────────────────────────────────────────────
  static String get a1_kasse_tips_title =>
      _t('Gi litt ekstra til budet?', 'Give the courier a little extra?');
  static String get a1_kasse_tips_line =>
      _t('Alt går uavkortet til budet.', 'Every krone goes to the courier.');
  static String get a1_kasse_tips_rad =>
      _t('Tips til budet', 'Tip for the courier');

  // ── summary ─────────────────────────────────────────────────────────────
  static String get a1_kasse_sammendrag => _t('SAMMENDRAG', 'SUMMARY');
  static String get a1_kasse_varer => _t('Varer', 'Items');
  static String get a1_kasse_frakt => _t('Levering', 'Delivery');
  static String get a1_kasse_frakt_fri => _t('Gratis', 'Free');
  static String get a1_kasse_avgifter => _t('Avgifter', 'Fees');
  static String get a1_kasse_rabatt => _t('Rabatt', 'Discount');
  static String a1_kasse_aegil_linjer(String navn, String sum) => _t(
    'Lagt i kurven av Ægil · $navn · $sum',
    'Added by Ægil · $navn · $sum',
  );
  static String get a1_kasse_angre => _t('Angre', 'Undo');
  static String get a1_kasse_angret =>
      _t('Fjernet fra kurven', 'Removed from the basket');
  static String get a1_kasse_doren =>
      _t('DØREN · FOR BUDET', 'THE DOOR · FOR THE COURIER');
  static String get a1_kasse_doren_hint => _t(
    'Etasje, ring på, inngang, kode …',
    'Floor, doorbell, entrance, code …',
  );
  static String get a1_kasse_tolk => _t('Tolk', 'Interpret');
  static String get a1_kasse_kode =>
      _t('Kode ved levering', 'Code at delivery');
  static String get a1_kasse_kode_line => _t(
    'Budet må få koden din før posen leveres',
    'The courier needs your code before handing over',
  );
  static String get a1_kasse_gave_til => _t('Gave til', 'Gift for');
  static String get a1_kasse_gave_navn_hint => _t('Navn', 'Name');
  static String get a1_kasse_overrask => _t('Overrask', 'Surprise');
  static String get a1_kasse_overrask_line =>
      _t('Ingenting før det ringer på', 'Nothing until the doorbell');
  static String get a1_kasse_si_fra => _t('Si fra', 'Tell them');
  static String get a1_kasse_si_fra_line => _t(
    'Lenke med sporing og kortet ved døra',
    'A tracking link and the card at the door',
  );
  static String get a1_kasse_a_betale => _t('Å BETALE NÅ', 'TO PAY NOW');
  static String get a1_kasse_totalt => _t('Totalt', 'Total');
  static String get a1_kasse_inkl => _t(
    'Alt inkl. mva · ingen skjulte gebyrer',
    'All incl. VAT · no hidden fees',
  );
  static String a1_kasse_cashback(String kr) =>
      _t('Gir $kr tilbake i Ærend-kroner', 'Gives $kr back in Ærend-kroner');
  static String get a1_kasse_bergenske => _t(
    'Bergenske butikker — kronene blir i byen.',
    'Bergen shops — the kroner stay in town.',
  );
  static String a1_kasse_krysser(String bud) => _t(
    'Ærendet krysser Vågen med $bud.',
    'The errand crosses Vågen with $bud.',
  );
  static String a1_kasse_betal(String kr) => _t('Betal $kr', 'Pay $kr');
  static String get a1_kasse_betal_vipps =>
      _t('Betal med Vipps', 'Pay with Vipps');
  static String a1_kasse_min_ordre(String kr) =>
      _t('Minsteordre er $kr', 'Minimum order is $kr');
  static String get a1_kasse_velg_adresse_forst =>
      _t('Velg en adresse først', 'Choose an address first');
  static String get a1_kasse_utenfor =>
      _t('Butikken leverer ikke hit', 'The shop does not deliver here');
  static String get a1_kasse_utenfor_line =>
      _t('Du kan hente selv i stedet.', 'You can pick it up yourself instead.');
  static String get a1_kasse_velg_henting =>
      _t('Velg henting', 'Choose pickup');
  static String get a1_kasse_kort_legacy => _t(
    'Kortbetaling åpner den vanlige kassen.',
    'Card payment opens the regular checkout.',
  );

  // ── sheets ──────────────────────────────────────────────────────────────
  static String get a1_kasse_adr_sheet_title =>
      _t('Hvor skal ærendet?', 'Where to?');
  static String get a1_kasse_adr_sheet_line => _t(
    'Butikker og priser følger adressen.',
    'Shops and prices follow the address.',
  );
  static String get a1_kasse_adr_ny =>
      _t('Legg til en adresse', 'Add an address');
  static String get a1_kasse_adr_ny_line => _t(
    'Hytta, kjæresten, foreldrene …',
    'The cabin, your partner, your parents …',
  );
  static String get a1_kasse_adr_dor_kicker =>
      _t('HVORDAN FINNER BUDET FRAM?', 'HOW DOES THE COURIER FIND YOU?');
  static String get a1_kasse_adr_dor_line => _t(
    'Skriv som til en venn: etasje, ring på, inngang, kode …',
    'Write as to a friend: floor, doorbell, entrance, code …',
  );
  static String get a1_kasse_ikke_dekket => _t(
    'Vi leverer ikke hit ennå — si fra, så gir vi beskjed',
    'We do not deliver here yet — tell us and we will let you know',
  );
  static String get a1_kasse_si_fra_cta =>
      _t('Si fra når dere gjør det', 'Tell me when you do');
  static String get a1_kasse_sagt_fra =>
      _t('Vi sier fra.', 'We will let you know.');
  static String get a1_kasse_lev_sheet_title =>
      _t('Når vil du ha det?', 'When do you want it?');
  static String get a1_kasse_lev_middag => _t('Til middag', 'For dinner');
  static String get a1_kasse_lev_middag_line => _t(
    'Budet venter med å hente til det er ferskt',
    'The courier waits until it is fresh',
  );
  static String get a1_kasse_lev_kveld => _t('Kveldskos', 'Evening treat');
  static String get a1_kasse_lev_kveld_line => _t(
    'Etter Fløibanen har gått for kvelden',
    'After the last Fløibanen of the evening',
  );
  static String get a1_kasse_bruk_dette => _t('Bruk dette', 'Use this');
  static String get a1_kasse_bet_sheet_title =>
      _t('Hvordan vil du betale?', 'How would you like to pay?');
  static String get a1_kasse_bet_sheet_line => _t(
    'Prisen er den samme uansett. Ingen skjulte gebyrer.',
    'The price is the same either way. No hidden fees.',
  );
  static String a1_kasse_bet_vipps(String tlf) =>
      tlf.isEmpty ? 'Vipps' : 'Vipps · $tlf';
  static String get a1_kasse_bet_kort =>
      _t('Kort (Visa / Mastercard)', 'Card (Visa / Mastercard)');

  // ── purchase sequence ───────────────────────────────────────────────────
  static String get a1_kasse_bekreftet => _t('Bekreftet', 'Confirmed');
  static String get a1_kasse_bekreftet_line =>
      _t('Butikken har fått ærendet ditt.', 'The shop has your errand.');
  static String get a1_kasse_folg => _t('Følg ærendet', 'Follow the errand');
  static String get a1_kasse_billett_kicker =>
      _t('ÆREND-BILLETT', 'ÆREND TICKET');
  static String get a1_kasse_verv => _t('VERV EN VENN', 'REFER A FRIEND');
  static String a1_kasse_gi_faa(int kr) =>
      _t('Gi $kr kr, få $kr kr', 'Give $kr kr, get $kr kr');
  static String a1_kasse_billett_line(int kr) => _t(
    'Du deler fra dine egne kanaler. Begge får $kr kr når vennens første ordre er levert.',
    'You share from your own channels. You both get $kr kr when your friend\'s first order is delivered.',
  );
  static String get a1_kasse_del_billett =>
      _t('Del billetten', 'Share the ticket');
  static String get a1_kasse_kopier => _t('Kopier', 'Copy');
  static String get a1_kasse_kopiert => _t('Kopiert', 'Copied');
  static String get a1_kasse_lukk => _t('Lukk', 'Close');

  // ── Bestillingsdetaljer ─────────────────────────────────────────────────
  static String get a1_kasse_best_sammendrag => _t('Sammendrag', 'Summary');
  static String get a1_kasse_best_detaljer => _t('Detaljer', 'Details');
  static String get a1_kasse_best_bestilling => _t('BESTILLING', 'ORDER');
  static String get a1_kasse_best_betalt_vipps =>
      _t('BETALT MED VIPPS', 'PAID WITH VIPPS');
  static String get a1_kasse_best_betalt => _t('Betalt', 'Paid');
  static String get a1_kasse_best_kvittering => _t('Kvittering', 'Receipt');
  static String get a1_kasse_best_klar => _t('Klar', 'Done');
  static String get a1_kasse_best_status => _t('ORDRESTATUS', 'ORDER STATUS');
  static String get a1_kasse_best_din => _t('Din bestilling', 'Your order');
  static String get a1_kasse_best_total => _t('Totalsum', 'Total');
  static String get a1_kasse_best_betaling => _t('Betaling', 'Payment');
  static String get a1_kasse_best_butikken => _t('Butikken', 'The shop');
  static String get a1_kasse_best_ordrenr => _t('ORDRENUMMER', 'ORDER NUMBER');
  static String get a1_kasse_best_aerend_id => 'ÆREND-ID';
  static String get a1_kasse_best_tid => _t('TIDSSTEMPEL', 'TIMESTAMP');
  static String get a1_kasse_best_kvitt => _t('KVITTERING', 'RECEIPT');
  static String get a1_kasse_best_meg =>
      _t('Meg · Bestillinger', 'Me · Orders');
  static String get a1_kasse_best_kundeservice =>
      _t('Kontakt kundeservice', 'Contact customer service');
  static String get a1_kasse_best_se_alt => _t('Se alt', 'See all');
  static String a1_kasse_best_antall(int n) =>
      _t(n == 1 ? '1 vare' : '$n varer', n == 1 ? '1 item' : '$n items');
  static String get a1_kasse_best_ikke_funnet =>
      _t('Fant ikke bestillingen.', 'Could not find the order.');
  static String get a1_kasse_best_kopiert =>
      _t('Ordrenummeret er kopiert', 'Order number copied');
}
