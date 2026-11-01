/// The Ægil-runden tables (Onboarding plan §3 #4, prototype `RT_SEK` L16538
/// and `rtSteg()` L16545): five sections, seventeen steps, the design's
/// bokmål copy. Data only, so copy and order change in one place.
library;

/// A section (station in the HUD, a stamp when it is done).
class OnbSek {
  const OnbSek(this.id, this.navn, this.ikon);
  final String id;
  final String navn;

  /// SVG path (24-unit box) of the station icon.
  final String ikon;
}

const List<OnbSek> kOnbSeksjoner = [
  OnbSek('hjem', 'Hjem', 'M4 10.5L12 4l8 6.5M6 9.5V20h12V9.5'),
  OnbSek('utforsk', 'Utforsk', 'M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17zM15.5 8.5l-2.2 4.8-4.8 2.2 2.2-4.8z'),
  OnbSek('butikk', 'Butikk', 'M4 10l1.5-5h13L20 10M4 10v10h16V10M10 20v-6h4v6'),
  OnbSek('kurv', 'Kurv', 'M5 7h14l-1.3 11H6.3zM9 7V5.5a3 3 0 0 1 6 0V7'),
  OnbSek('meg', 'Meg', 'M12 4.4a3.6 3.6 0 1 0 0 7.2 3.6 3.6 0 0 0 0-7.2zM5.5 20c1.3-3.3 3.6-5 6.5-5s5.2 1.7 6.5 5'),
];

/// Ægil's poses, one PNG each in `assets/images/aegil/`.
enum OnbPose { front, popup, find, findplace, explore, discount, store, voucher, invitation, bike }

/// One step of the tour.
class OnbSteg {
  const OnbSteg({
    required this.id,
    required this.sek,
    required this.skjerm,
    required this.pose,
    required this.tx,
    this.mal,
    this.oppdrag,
    this.intro = false,
    this.navAuto = false,
    this.handling,
    this.malAlt,
    this.txAlt,
    this.oppdragAlt,
  });

  final String id;
  final String sek;

  /// The screen it lives on: `hjem`, `utforsk`, `butikk`, `kurv`, `meg`.
  final String skjerm;
  final OnbPose pose;
  final String tx;

  /// Anchor id ([OnbMaal]); null for the intro.
  final String? mal;

  /// The mission text; the step waits for the user to do it.
  final String? oppdrag;
  final bool intro;

  /// «Vis meg» on a mission that is only a navigation completes it first.
  final bool navAuto;

  /// Label of the action chip («Bruk posisjonen min»).
  final String? handling;

  /// `legg`: when the product sheet is open the mark, text and mission move.
  final String? malAlt;
  final String? txAlt;
  final String? oppdragAlt;

  bool get harOppdrag => oppdrag != null;
}

/// The seventeen steps (`rtSteg()`), in order. [bio] = the design's
/// `onbMinBio` (the Min Bio step exists only with it); [posisjonGitt] hides
/// the position chip when the phone already answered.
List<OnbSteg> onbStegListe({required bool bio, required bool posisjonGitt}) => [
  const OnbSteg(id: 'intro', sek: 'hjem', skjerm: 'hjem', intro: true, pose: OnbPose.popup, tx: 'Hei, jeg er Ægil! Bli med på en kjapp runde, så viser jeg deg hele appen.'),
  OnbSteg(id: 'adresse', sek: 'hjem', skjerm: 'hjem', mal: 'adresse', pose: OnbPose.findplace, tx: 'Her velger du hvor jeg skal levere. Hjemme, på jobb eller der du er.', handling: posisjonGitt ? null : 'Bruk posisjonen min'),
  const OnbSteg(id: 'fiske', sek: 'hjem', skjerm: 'hjem', mal: 'fjordfiske', pose: OnbPose.explore, tx: 'Kast snøret i Vågen og få napp på tilbud. Noen ganger biter en premie!'),
  const OnbSteg(id: 'kategori', sek: 'hjem', skjerm: 'hjem', mal: 'kategorirad', pose: OnbPose.popup, tx: 'Bla mellom restaurant, mat og fisk, mote, interiør og gaver.'),
  const OnbSteg(id: 'hurtig', sek: 'hjem', skjerm: 'hjem', mal: 'hurtig', pose: OnbPose.find, tx: 'Si hva du vil ha, så setter jeg sammen bestillingen. Du bekrefter alltid selv.'),
  const OnbSteg(id: 'utforsk', sek: 'hjem', skjerm: 'hjem', mal: 'nav-utforsk', pose: OnbPose.popup, tx: 'Nå tar vi en tur i byen.', oppdrag: 'Trykk på Utforsk', navAuto: true),
  const OnbSteg(id: 'feed', sek: 'utforsk', skjerm: 'utforsk', mal: 'fpost', pose: OnbPose.explore, tx: 'Butikkene legger ut nyheter og tilbud her. Følg dem du liker, så kommer de først.'),
  const OnbSteg(id: 'poser', sek: 'utforsk', skjerm: 'utforsk', mal: 'karusell-u', pose: OnbPose.discount, tx: 'Forundringsposer er overskuddsmat til lav pris. Sikre en, og hent før stengetid.'),
  const OnbSteg(id: 'butikk', sek: 'butikk', skjerm: 'butikk', mal: 'seilas', pose: OnbPose.store, tx: 'Velkommen til Burger King! Jeg ror bestillingen fra kjøkkenet på Bryggen til deg.'),
  const OnbSteg(
    id: 'legg', sek: 'butikk', skjerm: 'butikk', mal: 'legg', pose: OnbPose.popup,
    tx: 'Dette er det folk bestiller mest her. Trykk + for å legge retten i kurven.', oppdrag: 'Trykk + på retten',
    malAlt: 'legg-ark', txAlt: 'Her velger du meny og tilbehør. Trykk «Legg til», så havner retten i kurven.', oppdragAlt: 'Trykk «Legg til»',
  ),
  const OnbSteg(id: 'tilkurv', sek: 'butikk', skjerm: 'butikk', mal: 'butikk-kurv', pose: OnbPose.voucher, tx: 'Godt valg! Retten ligger i kurven nå.', oppdrag: 'Åpne kurven', navAuto: true),
  const OnbSteg(id: 'levhent', sek: 'kurv', skjerm: 'kurv', mal: 'levhent', pose: OnbPose.bike, tx: 'Velg levering eller henting. Tid og pris oppdateres med en gang.'),
  const OnbSteg(id: 'flere', sek: 'kurv', skjerm: 'kurv', mal: 'flere', pose: OnbPose.find, tx: 'Her gir du beskjed til butikken, tips til budet og instrukser til døra.'),
  const OnbSteg(id: 'betal', sek: 'kurv', skjerm: 'kurv', mal: 'betspor', pose: OnbPose.popup, tx: 'Når alt stemmer, drar du for å betale. Så følger du budet live helt fram.'),
  const OnbSteg(id: 'poeng', sek: 'meg', skjerm: 'meg', mal: 'poeng', pose: OnbPose.front, tx: 'Du får poeng når du handler lokalt, og stiger i nivå. Poengene blir premier.'),
  if (bio) const OnbSteg(id: 'bio', sek: 'meg', skjerm: 'meg', mal: 'bio', pose: OnbPose.find, tx: 'Fortell meg hva du spiser én gang. Allergier følger med i alt jeg foreslår.'),
  const OnbSteg(id: 'ai', sek: 'meg', skjerm: 'meg', mal: 'ai', pose: OnbPose.invitation, tx: 'Bruker du Claude eller ChatGPT? De kan bestille gjennom Ærend. Du bekrefter alltid her.'),
];

/// The strings around the steps (prototype L11215–11302).
abstract final class OnbCopy {
  static const velkommen = 'Velkommen';
  static const ettMinutt = 'Ett minutt';
  static String stegAv(int i, int n) => 'Steg $i av $n';
  static const hoppOver = 'Hopp over';
  static const tilbake = 'Tilbake';
  static const senere = 'Senere';
  static const visMeg = 'Vis meg';
  static const bliMed = 'Bli med';
  static const neste = 'Neste';
  static const fullfor = 'Fullfør';
  static const oppdragSelv = 'Oppdrag · gjør det selv';
  static const oppdragFerdig = 'Oppdrag fullført';
  static const stempelTatt = 'Stempel tatt';
  static const ferdigTittel = 'Runden er fullført!';
  static const ferdigTekst = 'Du har sett hele Ærend. Nå er det din tur. Jeg er her om du trenger meg.';
  static const startHandle = 'Start å handle';
  static const klarTilAaHandle = 'Klar til å handle!';
  static const posTillatt = 'Posisjon tillatt · butikker nær deg';
  static const posAvslatt = 'Uten posisjon · skriv inn adressen i kassen';
}
