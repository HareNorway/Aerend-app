// ignore_for_file: constant_identifier_names, non_constant_identifier_names
/// Copy for the rebuilt Meg tab (agil-4). Keys `a4_meg_*`; the design's
/// wording (`Ærend Kunde Bergen.dc.html` `meg` ≈L5912–6124 and the Ark
/// sheets `slikPoeng`, `nivaa`, `ligaNavn`, `kodeInnst`, `anledninger`,
/// `ukeshandel`, `nivaa4`, `sprak`, `support`, `ai`) verbatim.
abstract final class A4MegCopy {
  // Hero bubble (maalBoble)
  static String a4_meg_boble_til(int n, String label) => '$n poeng til ${label.toLowerCase()}.';
  static String a4_meg_boble_klar(String label) => '$label er klar å hente.';
  static const String a4_meg_boble_ingen = 'Sett et mål på Premiehylla.';

  // Header
  static String a4_meg_fra(String name, String bydel) => '$name fra $bydel';
  static const String a4_meg_bydel = 'Møhlenpris';
  static const String a4_meg_region = 'Bergenhus';
  static const String a4_meg_premie_levering = 'Premie: gratis levering';
  static const String a4_meg_gullbilletten = 'Gullbilletten';
  static String a4_meg_gi_faa(int give, int get) => 'Gi $give · få $get poeng';
  static String a4_meg_gi_faa_kode(int give, int get, String code) => 'Gi $give poeng, få $get poeng · $code';
  static const String a4_meg_del = 'Del';
  static String a4_meg_del_tekst(int points, String code, String? link) => 'Her er en gullbillett til Ærend: bruk koden $code, så får vi $points poeng hver når din første bestilling er levert.${link == null ? '' : ' $link'}';
  static String a4_meg_kopiert(String code) => 'Gullbilletten $code er kopiert';

  // Poeng card
  static const String a4_meg_ditt_nivaa = 'DITT NIVÅ';
  static String a4_meg_til_neste(int n, String next) => '${_nf(n)} poeng til $next';
  static const String a4_meg_hoyeste = 'Høyeste nivå';
  static const String a4_meg_naa = 'NÅ';
  static const String a4_meg_poeng_bruke = 'POENG Å BRUKE';
  static String a4_meg_opptjent(int n) => 'Opptjent i alt: ${_nf(n)} poeng';
  static const String a4_meg_poeng = 'poeng';
  static String a4_meg_kommer(int n) => '+${_nf(n)} kommer når ordren er levert';
  static String a4_meg_maal(String label, int igjen) => 'Mål: ${label.toLowerCase()} · ${_nf(igjen)} poeng igjen';
  static String a4_meg_maal_klar(String label) => 'Mål: ${label.toLowerCase()} · klar';
  static const String a4_meg_hent_premien = 'Hent premien';
  static const String a4_meg_premiehylla = 'Premiehylla';
  static const String a4_meg_slik = 'Slik får\ndu poeng';

  // Meg-rader
  static const String a4_meg_rad_nivaa = 'Nivå';
  static const String a4_meg_nivaa_note = 'Nivået påvirkes aldri av at du bruker poeng';
  static String a4_meg_avstand(int n, String next) => '${_nf(n)} til $next';
  static const String a4_meg_rad_liga = 'Fløyen-ligaen';
  static const String a4_meg_liga_med = 'Du klatrer denne måneden';
  static const String a4_meg_liga_ute = 'Ikke med · bli med når du vil';
  static const String a4_meg_bli_med = 'Bli med';
  static String a4_meg_plass(int rank) => '$rank. plass';
  static const String a4_meg_oppdrag = 'UKENS OPPDRAG';
  static const String a4_meg_godta = 'Godta';
  static const String a4_meg_ikke_dette = 'Ikke dette';
  static String a4_meg_oppdrag_status(int progress, int target) => '$progress av $target';
  static String a4_meg_oppdrag_ditt(String title) => 'Oppdraget er ditt · $title';
  static const String a4_meg_oppdrag_nei = 'Greit · nytt oppdrag neste uke';
  static String a4_meg_pluss(int n) => '+$n poeng';

  // Innstillinger-rader
  static const String a4_meg_anledninger = 'Anledninger';
  static const String a4_meg_anledninger_paaminnelse = 'én påminnelse sju dager før';
  static const String a4_meg_anledninger_tom = 'Ingen ennå · legg til en dato';
  static const String a4_meg_ukeshandel = 'Ukeshandel';
  static const String a4_meg_ukeshandel_sub = 'Handleliste · Middag denne uken · Ukens kurv';
  static const String a4_meg_saa_mye = 'Så mye kan Ægil gjøre';
  static String a4_meg_nivaa_n(int n, String name) => 'Nivå $n · $name';
  static const String a4_meg_nivaa4 = 'Nivå 4 →';
  static const String a4_meg_fast = 'Fast bestilling';
  static const String a4_meg_krev_kode = 'Krev alltid kode ved levering';
  static const String a4_meg_kode_paa = 'På · budet leverer bare til deg';
  static String a4_meg_kode_av(int kr) => 'Av · kreves over $kr kr';
  static const String a4_meg_paa = 'På';
  static const String a4_meg_av = 'Av';
  static const String a4_meg_adresser = 'Adresser';
  static const String a4_meg_adresser_bare = 'bare for deg';
  static const String a4_meg_adresser_tom = 'Legg til adresse';
  static const String a4_meg_betaling = 'Betaling';
  static const String a4_meg_betaling_vipps = 'Vipps';
  static const String a4_meg_varsler = 'Varsler';
  static const String a4_meg_varsler_sub = 'Oppdrag, premier og verving';
  static const String a4_meg_navn_liga = 'Navn i ligaen';
  static const String a4_meg_navn_liga_ute = 'Ikke med i Fløyen-ligaen';
  static const String a4_meg_velg_navn = 'Velg navn';
  static const String a4_meg_spraak = 'Språk';
  static const String a4_meg_favoritter = 'Favoritter';
  static const String a4_meg_nytt = 'Nytt fra butikkene';
  static const String a4_meg_hjelp = 'Hjelp og kontakt';

  // Ark · Slik får du poeng (slikPoeng)
  static const String a4_meg_slik_title = 'Slik får du poeng';
  static const String a4_meg_slik_linje = 'Poengene dine gjør tre ting: du bruker dem på hylla, de bestemmer nivået ditt, og de rangerer deg i ligaen hvis du blir med.';
  static const List<List<String>> a4_meg_poengrater = [
    ['Handel', '1 poeng per krone du handler for'],
    ['Første gang hos en ny butikk', '+50 poeng, én gang per butikk'],
    ['Dagens napp', '+5 poeng for det første funnet hver dag'],
    ['Ægils oppdrag', '+50 poeng når du fullfører'],
    ['Verving', '+200 poeng når vennen får sin første ordre levert'],
  ];
  static const Map<String, String> a4_meg_nivaa_gaver = {
    'Bronse': 'Gratis levering',
    'Sølv': 'Seks kanelboller',
    'Gull': 'Fiskesuppe for to',
    'Platina': 'Din egen båt i Vågen',
  };
  static String a4_meg_fra_poeng(int n, String gift) => 'Fra ${_nf(n)} poeng opptjent · f.eks. $gift';
  static const String a4_meg_du_er_her = 'Du er her';
  static const String a4_meg_bruk_senker_aldri = 'Å bruke poeng senker aldri nivået';
  static const String a4_meg_bruk_senker_sub = 'Nivået følger poengene du har tjent opp, ikke saldoen din';

  // Ark · Nivå
  static const String a4_meg_nivaa_title = 'Nivå';
  static String a4_meg_nivaa_linje(String name) => 'Du er på $name.';

  // Ark · Navn i ligaen (ligaNavn / ligaBli)
  static const String a4_meg_liga_bli_title = 'Bli med i Fløyen-ligaen';
  static const String a4_meg_liga_navn_linje = 'Navnet du velger er det eneste andre ser. Nivået ditt vises aldri.';
  static const String a4_meg_navn_fornavn = 'Bare fornavnet ditt';
  static const String a4_meg_navn_initial = 'Fornavn og initial';
  static const String a4_meg_navn_bydel = 'Fornavn og bydel';
  static const String a4_meg_navn_anonym = 'Helt anonymt — ingen kan se at det er deg';
  static const String a4_meg_syn_title = 'HVEM SER NAVNET';
  static const List<List<String>> a4_meg_ligasyn = [
    ['alle', 'Alle i Bergen', 'Navnet ditt står i topplisten for hele byen'],
    ['bydel', 'Bare min bydel', 'Bare klatrere i bydelen din ser navnet ditt'],
    ['skjult', 'Skjult', 'Du står som «Skjult klatrer» — plassen og premien er din likevel'],
  ];
  static const String a4_meg_lagre = 'Lagre';
  static const String a4_meg_lagret = 'Lagret';
  static const String a4_meg_liga_vilkaar = 'Vilkår';

  // Ark · Krev alltid kode (kodeInnst)
  static const String a4_meg_kode_linje = 'Budet leverer bare til deg. Uten svar går ordren tilbake til butikken — aldri ved døren.';
  static const String a4_meg_slaa_paa = 'Slå på';
  static const String a4_meg_slaa_av = 'Slå av';
  static const String a4_meg_kode_alltid = 'Kode kreves alltid';
  static String a4_meg_kode_bare(int kr) => 'Kode kreves bare over $kr kr';

  // Ark · Anledninger
  static const String a4_meg_anl_linje = 'Personer og datoer du legger inn. Lagres bare for én påminnelse sju dager før — aldri en nedtelling, aldri to push. Kan fjernes når som helst.';
  static const String a4_meg_anl_legg = 'Legg til anledning';
  static const String a4_meg_anl_legg_sub = 'Navn, dato og hva det er';
  static const String a4_meg_anl_hvem = 'Hvem';
  static const String a4_meg_anl_hva = 'Hva (f.eks. Bursdag)';
  static const String a4_meg_anl_dato = 'Velg dato';
  static const String a4_meg_anl_fjern = 'Fjern';
  static const String a4_meg_lukk = 'Lukk';

  // Ark · Ukeshandel / Nivå 4
  static const String a4_meg_handleliste = 'Handleliste';
  static const String a4_meg_handleliste_tom = 'Lista er tom. Si «legg til melk» til Ægil, så havner det her.';
  static const String a4_meg_se_ukens_kurv = 'Se ukens kurv';
  static const String a4_meg_nivaa4_title = 'Fast bestilling · nivå 4';
  static const String a4_meg_nivaa4_linje = 'Ægil bygger kurven mandag 10:00, du kan endre til 18:00, tak 900 kr. Krever en Vipps-avtale for gjentakende trekk.';
  static const List<List<String>> a4_meg_nivaa4_rader = [
    ['Dag og tid', 'Mandag 10:00 · gjennomgang til 18:00'],
    ['Tak', 'Aldri over 900 kr'],
    ['Vipps-avtale', 'Gjentakende trekk · kan avsluttes når som helst'],
  ];
  static const String a4_meg_avbryt = 'Avbryt';
  static const String a4_meg_til_aegil = 'Til Ægil-innstillingene';

  // Ark · Språk
  static const String a4_meg_spraak_linje = 'Gjelder appen. Butikknavn og adresser oversettes ikke.';
  static const Map<String, String> a4_meg_spraak_navn = {
    'no': 'Norsk bokmål',
    'nb': 'Norsk bokmål',
    'nn': 'Norsk nynorsk',
    'en': 'English',
    'sv': 'Svenska',
    'da': 'Dansk',
    'es': 'Español',
  };

  // Ark · Hjelp / Om Ægil
  static const String a4_meg_hjelp_title = 'Hjelp';
  static const String a4_meg_hjelp_linje = 'Ægil svarer først. Et menneske tar over når du ber om det.';
  static const String a4_meg_spor_aegil = 'Spør Ægil';
  static const String a4_meg_spor_aegil_sub = 'Om ordrer, saldo og butikker';
  static const String a4_meg_menneske = 'Snakk med et menneske';
  static const String a4_meg_menneske_sub = 'Svar innen 2 timer';
  static const String a4_meg_om_aegil = 'Om Ægil';
  static const String a4_meg_om_aegil_linje = 'Ægil er en assistent laget av Ærend, ikke et menneske. Ægil gjør ingenting med pengene dine uten et trykk fra deg under nivå 3, og alt Ægil gjør kan angres i 7 dager. Ærend-innlegg i feeden skrives aldri i Ægils stemme.';

  // Ark · Gullbilletten din (billett) / Vilkår
  static const String a4_meg_billett_title = 'Gullbilletten din';
  static String a4_meg_billett_linje(int them, int me) => 'Gi $them poeng, få $me poeng når vennen din får sin første bestilling levert. Poengene lander på begge samtidig.';
  static const String a4_meg_delingskode = 'DIN DELINGSKODE';
  static const String a4_meg_vilkaar = 'Vilkår';
  static const String a4_meg_del_billetten = 'Del gullbilletten';
  static const String a4_meg_billettene_dine = 'BILLETTENE DINE';
  static const String a4_meg_ingen_grense = 'Ingen grense';
  static String a4_meg_maks_mnd(int n) => 'Maks $n i måneden';
  static const String a4_meg_venner_vervet = 'venner vervet';
  static String a4_meg_vervet_poeng(int points, int per) => '${_nf(points)} poeng hentet inn · $per for hver ny';
  static const String a4_meg_ingen_merke = 'INGEN MERKE ENNÅ';
  static String a4_meg_naadd(String name) => '${name.toUpperCase()} NÅDD';
  static String a4_meg_neste_billett(String name, int at, int bonus) => '$name ved $at vervede · +${_nf(bonus)} bonus';
  static const String a4_meg_toppen = 'Du har nådd toppen av billettstigen';
  static String a4_meg_igjen(int n) => '$n igjen';
  static const String a4_meg_neste_venn = 'Neste venn';
  static const String a4_meg_lastet_ned = 'Lastet ned';
  static String a4_meg_verv_mnd(int n, int cap) => n == 0 ? 'Ingen vervet denne måneden ennå — del billetten, så teller neste bestilling.' : 'Du har vervet $n denne måneden${cap > 0 ? ' av maks $cap' : ''}.';
  static const String a4_meg_vilkaar_title = 'Vilkår for poeng';
  static const String a4_meg_vilkaar_linje = 'Poeng er ikke penger og kan ikke veksles i kroner.';
  static const List<List<String>> a4_meg_vilkaar_rader = [
    ['Verving', '200 poeng til hver når vennens første ordre over 200 kr er levert'],
    ['Billettstigen', 'Bonus ved 3, 10, 25 og 50 vervede — én gang per trinn'],
    ['Poeng', 'Utløper 12 måneder etter at de er tjent'],
    ['Ligaen', 'Krever at du melder deg på, og viser bare navnet du selv velger'],
  ];

  // Ark · Nivå (detail)
  static String a4_meg_poeng_til(String next) => 'poeng til $next';
  static const String a4_meg_hoyeste_linje = 'poeng opptjent — høyeste nivå';
  static String a4_meg_opptjent_12(int n) => 'Opptjent siste 12 måneder: ${_nf(n)}';
  static const String a4_meg_da_aapner = 'Da åpner disse på hylla di:';
  static const String a4_meg_hele_hylla = 'Hele hylla er åpen for deg.';
  static String a4_meg_vurdering(String date, String tier) => 'Neste vurdering $date · du beholder $tier fram til da.';
  static const String a4_meg_nivaa_note_punkt = 'Nivået påvirkes aldri av at du bruker poeng.';

  // Ark · Ukeshandel / Hjelp / Språk / Betaling / Adresser
  static const String a4_meg_aegil_la_til = 'Ægil la til';
  static const String a4_meg_kjopt = 'Kjøpt';
  static const String a4_meg_om_aegil_sub = 'AI-opplysning og vilkår';
  static const List<List<String>> a4_meg_spraak_valg = [
    ['no', 'Norsk bokmål'],
    ['en', 'English'],
    ['sv', 'Svenska'],
    ['da', 'Dansk'],
    ['es', 'Español'],
  ];
  static const String a4_meg_betaling_linje = 'Vipps er standard. Kort brukes bare hvis Vipps feiler.';
  static const String a4_meg_betaling_standard = 'Standard — raskest i Norge';
  static const String a4_meg_reserve = 'Reserve';
  static const String a4_meg_betaling_kort = 'Kort og betalingsmåter';
  static const String a4_meg_adresser_linje = 'Dørteksten tolkes til chips. Samtykke styrer om budene ser den.';

  static String _nf(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return (n < 0 ? '-' : '') + b.toString();
  }

  static String nf(int n) => _nf(n);
}
