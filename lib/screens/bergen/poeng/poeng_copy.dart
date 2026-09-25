// ignore_for_file: constant_identifier_names, non_constant_identifier_names
/// Copy for the Points screens (agil-3 Phase 7). Keys `a3_poeng_*`; the
/// design's wording (`premier`, `velger`, `liga`, `opprykk`, `fiske`,
/// `Napp-kort`) verbatim. Moved to ARB by agil-1 in its Phase 8.
abstract final class A3PoengCopy {
  // Premiehylla (design ≈L6178)
  static const String a3_poeng_premiehylla_title = 'Premiehylla';
  static const String a3_poeng_premiehylla_sub = 'Bytt poeng i noe godt fra Bergen';
  static const String a3_poeng_maal_label = 'MÅLET DITT';
  static const String a3_poeng_mine_premier = 'Mine premier';
  static const String a3_poeng_hylla_intro = 'Hylla denne måneden. Prisene står i poeng — aldri i kroner. Sett én premie som mål, så følger Ægil deg dit.';
  static const String a3_poeng_badge_maal = 'MÅL';
  static const String a3_poeng_badge_utsolgt = 'UTSOLGT';
  static const String a3_poeng_hent = 'Hent';
  static const String a3_poeng_sett_maal = 'Sett som mål';
  static const String a3_poeng_er_maal = 'Målet ditt';
  static const String a3_poeng_laast_title = 'Låst ennå';
  static const String a3_poeng_gjelder = 'Premier gjelder i 60 dager fra du henter dem. Utsolgte kommer tilbake neste måned.';
  static const String a3_poeng_nivaa = 'Nivå';
  static const String a3_poeng_poeng = 'poeng';
  static String a3_poeng_igjen(int n) => '$n igjen';
  static String a3_poeng_til_laas(int n) => '$n poeng til';

  // Ægil velger (≈L6306)
  static const String a3_poeng_velger_kicker = 'ÆGIL VELGER';
  static const String a3_poeng_velger_title = 'Premien Ægil valgte';
  static const String a3_poeng_velger_sub = 'Én premie fra hylla di — valgt for deg.';
  static const String a3_poeng_velger_verdi = 'Verdi minst 300 kr';
  static const String a3_poeng_velger_hent = 'Hent premien';
  static const String a3_poeng_velger_bra = 'Bra';
  static const String a3_poeng_velger_ikke = 'Ikke for meg';
  static const String a3_poeng_velger_hopp = 'Hopp over';
  static const String a3_poeng_velger_tilbake = 'Tilbake til Premiehylla';
  static const String a3_poeng_velger_tom = 'Hylla er tom akkurat nå.';

  // Liga (≈L6368)
  static const String a3_poeng_liga_title = 'Fløyen-ligaen';
  static const String a3_poeng_liga_vilkaar = 'Vilkår';
  static const String a3_poeng_liga_hele = 'Hele Bergen';
  static const String a3_poeng_liga_bydel = 'Din bydel';
  static const String a3_poeng_liga_pl = 'PL.';
  static const String a3_poeng_liga_klatrer = 'KLATRER';
  static const String a3_poeng_liga_poeng = 'POENG';
  static const String a3_poeng_liga_premier = 'Månedens premier';
  static const String a3_poeng_liga_premier_sub = 'Kan ikke kjøpes på hylla';
  static const List<String> a3_poeng_liga_premie_liste = [
    '1. Kveld på Fløyen for fire · transport, mat og utsikt',
    '2. Du velger månedens oppdrag for hele Bergen · Ægil bruker det neste måned',
    '3. Navnet ditt på Ægils båt i én måned · synlig for alle i Hjem',
    '4.–10. 100 poeng',
  ];
  static const String a3_poeng_liga_slutt = 'Se månedsslutten';
  static const String a3_poeng_liga_navn = 'Navn i ligaen';
  static const String a3_poeng_liga_bli_med = 'Bli med';
  static const String a3_poeng_liga_meld_av = 'Meld av';
  static const String a3_poeng_liga_ikke_med = 'Du er ikke med i ligaen ennå.';
  static const String a3_poeng_liga_seremoni_title = 'Månedsslutten';
  static const String a3_poeng_liga_seremoni_sub = 'Den første i måneden deles premiene ut, og ligaen nullstilles. Nivået ditt beholder du.';
  static String a3_poeng_liga_plass(int rank) => 'Du ligger på $rank. plass';
  static String a3_poeng_liga_maaned(String month) => 'POENG I ${month.toUpperCase()}';

  // Nivåopprykk (≈L6124)
  static const String a3_poeng_opprykk_kicker = 'NIVÅOPPRYKK';
  static const String a3_poeng_opprykk_gave = 'HER ER NOE TIL DEG';
  static const String a3_poeng_opprykk_valgt = 'Ægil valgte den til deg. Koster ingen poeng.';
  static const String a3_poeng_opprykk_hent = 'Hent';
  static const String a3_poeng_opprykk_hylla = 'Hylla di har fått tre nye premier.';
  static const String a3_poeng_opprykk_se = 'Se hylla';
  static const String a3_poeng_opprykk_hopp = 'Hopp over';
  static const String a3_poeng_opprykk_ferdig = 'Ferdig';
  static String a3_poeng_opprykk_naa(String tier) => 'Du er nå $tier';

  // Fjordfiske (≈L6436)
  static const String a3_poeng_fiske_title = 'Fjordfiske';
  static const String a3_poeng_fiske_sub = 'Du og Ægil fisker i Vågen';
  static const String a3_poeng_fiske_kast = 'Kast ut';
  static const String a3_poeng_fiske_ute = 'Snøret er ute … vent på napp';
  static const String a3_poeng_fiske_dra = 'DRA INN!';
  static const String a3_poeng_fiske_napp = 'Napp!';
  static const String a3_poeng_fiske_plus = '+5 poeng';
  static const String a3_poeng_fiske_slipp = 'Slipp';
  static const String a3_poeng_fiske_legg = 'Legg i kurven';
  static const String a3_poeng_fiske_lagre = 'Lagre';
  static const String a3_poeng_fiske_hent = 'Hent';
  static const String a3_poeng_fiske_fra_hylla = 'Fra hylla di';
  static const String a3_poeng_fiske_agn = 'Agn';
  static const String a3_poeng_fiske_fangst = 'Fangst';
  static const String a3_poeng_fiske_premiefangst = 'Premiefangst';
  static const String a3_poeng_fiske_se_lagret = 'Se det jeg lagret';
  static const String a3_poeng_fiske_i_morgen = 'Kast ut igjen i morgen';
  static const String a3_poeng_fiske_hint = 'Trykk på snøret når det rykker.';
  static String a3_poeng_fiske_snakk(int kast, int av, int lagret) => 'Kast $kast av $av · $lagret lagret';
  static String a3_poeng_fiske_slutt(int lagret, int kjopt) => 'Det var alt for nå. Du lagret $lagret og la $kjopt i kurven.';

  // Napp-kort (≈L2115)
  static const String a3_poeng_napp_dagens = 'Dagens napp: +5';
  static const String a3_poeng_napp_bergensk = 'Bergensk';
  static const String a3_poeng_napp_legg = 'Legg til';
  static const String a3_poeng_napp_ikke_naa = 'Ikke nå';
  static const String a3_poeng_napp_aldri = 'Aldri dette';

  // Hjem entry
  static const String a3_poeng_entry_title = 'Poeng';
  static const String a3_poeng_entry_sub = 'Se hylla og nivået ditt';
}
