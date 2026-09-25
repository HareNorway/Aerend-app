// ignore_for_file: constant_identifier_names, non_constant_identifier_names
/// Copy for the Ægil screens (agil-3 Phase 7). Keys `a3_aegil_*`; the
/// design's wording (`agent`, `Det Ægil vet`, `brett`) verbatim.
// ignore: unused_import
import '../../../main.dart' show languages;

abstract final class A3AegilCopy {
  // Header states (agTilstand)
  static const String a3_aegil_lytter = 'Lytter';
  static const String a3_aegil_leter = 'Leter i Vågen';
  static const String a3_aegil_fant_tre = 'Fant tre valg';
  static const String a3_aegil_fant_noe = 'Fant noe';
  static const String a3_aegil_fikser = 'Fikser kurven';
  static const String a3_aegil_byttet = 'Byttet';
  static const String a3_aegil_sammenlikner = 'Sammenlikner';
  static const String a3_aegil_beklager = 'Beklager…';
  static const String a3_aegil_det_jeg_vet = 'Det jeg vet';
  static String a3_aegil_nivaa(String name) => languages.aegil_nivaa(name);

  // Hilsen
  static const String a3_aegil_hilsen = 'Jeg finner det i Vågen, sjekker pris hos bergenske butikker og legger det klart i kurven.';
  static const String a3_aegil_hilsen_tom = 'Vil du at jeg husker hva du liker? Da kan jeg si fra når det er tilbud på det.';
  static const String a3_aegil_ja = 'Ja, la oss';
  static const String a3_aegil_ikke_naa = 'Ikke nå';
  static const String a3_aegil_forslag_kicker = 'FORSLAG I KVELD';
  static const String a3_aegil_bla_selv = 'ELLER BLA SELV';
  static const String a3_aegil_sok_kat = 'Søk og kategorier';
  static const String a3_aegil_spor = 'Hva trenger du i kveld?';
  static const String a3_aegil_send = 'Send';

  // Kort (the four evening cards, fallback copy when the tray is empty)
  static const List<List<String>> a3_aegil_kveld = [
    ['Tacokveld for fire', 'Under 500 kr · 3 butikker'],
    ['Billigste reker', 'I nærheten · fra 149 kr'],
    ['Gave til mamma', 'Lørdag · pakkes inn'],
    ['Samme som sist', 'Torgboden · torsdag · 402 kr'],
  ];

  // agForslag
  static String a3_aegil_varer(int n) => languages.aegil_varer(n);
  static const String a3_aegil_derfor = 'Derfor:';
  static const String a3_aegil_legg = 'Legg i kurven';
  static const String a3_aegil_bytt_butikk = 'Bytt butikk';
  static const String a3_aegil_kvittering = 'Kvittering';
  static const String a3_aegil_angre = 'Angre';
  static const String a3_aegil_funn = 'Funn';
  static const String a3_aegil_billigst = 'Billigst';
  static const String a3_aegil_velg = 'Velg';
  static const String a3_aegil_totaler = 'Alle totaler inkl. levering.';
  static const String a3_aegil_bytt = 'Bytt';
  static const String a3_aegil_behold = 'Behold';
  static const String a3_aegil_grunn = 'Grunn:';

  // agTillatelse
  static const String a3_aegil_tillatelse = 'Jeg er Ærends assistent, og jeg heter Ægil. Jeg er en AI. Jeg kan finne varer, sammenlikne priser med levering og foreslå kurver. Du betaler alltid selv.';
  static const String a3_aegil_hva_faar = 'Hva Ægil får gjøre';
  static const String a3_aegil_alle_nivaaer = 'Alle fem nivåer';
  static const String a3_aegil_foreslaa = 'Foreslå';
  static const String a3_aegil_foreslaa_sub = 'Ægil viser kort — du trykker for å legge i kurven';
  static const String a3_aegil_standard = 'Standard';
  static const String a3_aegil_handle = 'Handle i kurven';
  static const String a3_aegil_handle_sub = 'Ægil legger i kurven; du betaler alltid selv';
  static const String a3_aegil_saa_mye = 'Så mye kan Ægil gjøre';

  // agIkkeFunnet / agAldersblokk / allergen
  static const String a3_aegil_ikke_funnet = 'Fant ikke noe i Vågen for det.';
  static const String a3_aegil_ikke_funnet_sub = 'Prøv et annet ord, eller bla selv.';
  static const String a3_aegil_alder = '18+ · ikke verifisert';
  static const String a3_aegil_alder_sub = 'Bekreft alderen din med BankID i Konto før jeg kan hjelpe med dette.';
  static const String a3_aegil_bankid = 'Til Konto · BankID';
  static const String a3_aegil_allergen = 'Sjekk alltid allergener på varen. Ægil kan ta feil.';

  // Onboarding (agOb1–5)
  static const List<String> a3_aegil_ob_titler = ['Hva liker du?', 'Hvilke butikker?', 'Hvem handler du for?', 'Kosthold', 'Når spiser dere?'];
  static String a3_aegil_ob_poeng(int n) => languages.aegil_ob_poeng(n);
  static const String a3_aegil_ob_ferdig = 'Da vet jeg nok til å begynne.';

  // Kurv-bar
  static String a3_aegil_kurv_bar(int n, int kr, String tid) => languages.aegil_kurv_bar(n, kr, tid);
  static const String a3_aegil_betal_vipps = 'Betal med Vipps';

  // Minne (Det Ægil vet om deg)
  static const String a3_aegil_minne_title = 'Det Ægil vet om deg';
  static const List<String> a3_aegil_minne_grupper = ['DU LIKER', 'BUTIKKER', 'HUSSTAND', 'KOSTHOLD', 'MIDDAGSRYTME', 'ÆGIL HAR LAGT MERKE TIL'];
  static const String a3_aegil_minne_stemmer = 'Stemmer';
  static const String a3_aegil_minne_fjern = 'Fjern';
  static const String a3_aegil_minne_legg = 'Legg til';
  static const String a3_aegil_minne_varsler = 'VARSLER';
  static const String a3_aegil_minne_glem = 'Glem alt';
  static const String a3_aegil_minne_glem_sub = 'Ægil sletter alt den har lært om deg. Nivået ditt beholder du.';
  static const String a3_aegil_minne_tom = 'Ægil husker ingenting ennå.';
  static const String a3_aegil_tillit = 'Tillitsregnskap';
  static String a3_aegil_tillit_spart(int kr) => languages.aegil_tillit_spart(kr);
  static String a3_aegil_tillit_funn(int n) => languages.aegil_tillit_funn(n);
  static String a3_aegil_tillit_mot(int n) => languages.aegil_tillit_mot(n);

  // Brett (kBrettKort)
  static const String a3_aegil_brett_title = 'Ægil fant';
  static const String a3_aegil_brett_legg = 'Legg til';
  static const String a3_aegil_brett_ikke = 'Ikke for meg';
  static const String a3_aegil_brett_tom = 'Ingenting nytt akkurat nå.';

  // Hjem greeting
  static const String a3_aegil_greeting = 'Hei! Hva trenger du i kveld?';
}
