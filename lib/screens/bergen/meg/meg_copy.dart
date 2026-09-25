// ignore_for_file: constant_identifier_names, non_constant_identifier_names
/// Copy for the Meg screens (agil-3 Phase 7). Keys `a3_meg_*`; the design's
/// wording (`meg`, `favoritter`, `konto`, `varsler`, `borte`) verbatim.
abstract final class A3MegCopy {
  // Header (≈L5942)
  static String a3_meg_fra(String name, String bydel) => '$name fra $bydel';
  static const String a3_meg_bydel_sub = 'Bergenhus';
  static const String a3_meg_premie_boble = 'Premie: gratis levering';
  static const String a3_meg_gullbillett = 'Gullbilletten';
  static const String a3_meg_gullbillett_sub = 'Gi 200 · få 200 poeng';
  static const String a3_meg_del = 'Del';
  static String a3_meg_gullbillett_kode(int give, int get, String code) => 'Gi $give poeng, få $get poeng · $code';

  // Poeng card
  static const String a3_meg_ditt_nivaa = 'DITT NIVÅ';
  static const String a3_meg_poeng_bruke = 'POENG Å BRUKE';
  static const String a3_meg_hent_premien = 'Hent premien';
  static const String a3_meg_premiehylla = 'Premiehylla';
  static const String a3_meg_slik = 'Slik får du poeng';
  static const String a3_meg_nivaa_note = 'Nivået påvirkes aldri av at du bruker poeng';
  static String a3_meg_til_neste(int n, String next) => '$n poeng til $next';
  static String a3_meg_venter(int n) => '$n poeng er på vei';
  static String a3_meg_opptjent(int n) => '$n poeng opptjent siste 12 mnd';

  // Meg-rader (≈L6031)
  static const String a3_meg_rad_nivaa = 'Nivå';
  static const String a3_meg_rad_liga = 'Fløyen-ligaen';
  static const String a3_meg_rad_liga_bli = 'Bli med';
  static const String a3_meg_rad_oppdrag = 'UKENS OPPDRAG';
  static const String a3_meg_rad_godta = 'Godta';
  static const String a3_meg_rad_ikke = 'Ikke dette';
  static const String a3_meg_rad_favoritter = 'Favoritter';
  static const String a3_meg_rad_nytt = 'Nytt fra butikkene';
  static const String a3_meg_rad_hjelp = 'Hjelp og kontakt';
  static const String a3_meg_rad_konto = 'Konto';
  static const String a3_meg_rad_bestillinger = 'Bestillinger';
  static const String a3_meg_rad_varsler = 'Varsler';
  static String a3_meg_liga_plass(int rank) => '$rank. plass';
  static String a3_meg_favoritter_antall(int n) => '$n steder';

  // Slik får du poeng (Ark)
  static const String a3_meg_slik_title = 'Slik får du poeng';
  static const List<String> a3_meg_slik_rader = [
    '1 poeng per 10 kr du handler',
    '+5 for dagens napp i Fjordfiske',
    '+200 når en venn bestiller første gang',
    'Ukens oppdrag gir bonus',
  ];

  // Favoritter (≈L6699)
  static const String a3_meg_fav_title = 'Favoritter';
  static const String a3_meg_fav_tom = 'Ingen favoritter ennå';
  static const String a3_meg_fav_tom_sub = 'Trykk på hjertet der du liker deg — eller kast ut i Fjordfiske.';
  static const String a3_meg_fav_kast = 'Kast ut';
  static const String a3_meg_fav_fot = 'Favorittene dine dukker opp først i «Bestill igjen» — og gir poeng hver gang.';

  // Konto (≈L6746)
  static const String a3_meg_konto_title = 'Konto';
  static const String a3_meg_konto_verifisert = 'Vipps-verifisert';
  static const String a3_meg_konto_adresser = 'Adresser';
  static const String a3_meg_konto_legg_adresse = 'Legg til adresse';
  static const String a3_meg_konto_betaling = 'Betaling';
  static const String a3_meg_konto_vipps_std = 'Standard — raskest i Norge';
  static const String a3_meg_konto_innstillinger = 'Innstillinger';
  static const String a3_meg_konto_varsler = 'Varsler om krysningen';
  static const String a3_meg_konto_varsler_sub = 'Live på låseskjermen';
  static const String a3_meg_konto_rolig = 'Roligere bevegelse';
  static const String a3_meg_konto_rolig_sub = 'Færre animasjoner i byen';
  static const String a3_meg_konto_hjelp = 'Hjelp og personvern';
  static const String a3_meg_konto_data = 'Dine data lagres i Norge';
  static const String a3_meg_konto_logg_ut = 'Logg ut';

  // Bestillinger
  static const String a3_meg_best_title = 'Bestillinger';
  static const String a3_meg_best_tom = 'Ingen bestillinger ennå';
  static const String a3_meg_best_tom_sub = 'Når du bestiller, finner du sporing og kvitteringer her.';
  static const String a3_meg_best_live = 'PÅ VEI NÅ';
  static const String a3_meg_best_igjen = 'Bestill igjen';
  static const String a3_meg_best_sporing = 'Vis sporing';

  // Varsler (≈L6809)
  static const String a3_meg_varsler_title = 'Varsler';
  static const String a3_meg_varsler_lukk = 'Lukk';
  static const String a3_meg_varsler_vis_sporing = 'Vis sporing';
  static const String a3_meg_varsler_ikke_slike = 'Ikke slike varsler';
  static const String a3_meg_varsler_fjern = 'Fjern';
  static const String a3_meg_varsler_tom = 'Ingenting nytt siden sist';
  static const String a3_meg_varsler_tom_sub = 'Fin utsikt.';
  static const String a3_meg_varsler_slaa_paa = 'Slå på varsler for tilbud';
  static const String a3_meg_varsler_angre = 'Angre';
  static const List<String> a3_meg_varsler_filtre = ['Alle', 'Ordre', 'Tilbud', 'Ægil'];
  static String a3_meg_varsler_fjernet(String t) => 'Fjernet «$t»';

  // Mens du var borte (≈L7322)
  static const String a3_meg_borte_kicker = 'MENS DU VAR BORTE';
  static const String a3_meg_borte_title = 'Tre ting fra Ægil';
  static const String a3_meg_borte_se = 'Se de siste 30 dagene';
}
