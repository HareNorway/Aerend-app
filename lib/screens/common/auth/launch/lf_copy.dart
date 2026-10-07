import '../../../../utils/utils.dart';

/// Copy for the Launch onboarding (`Design-New/Ærend Kunde Launch.dc.html`,
/// L1887–2214 and `onbVals`). Norwegian is the prototype's copy, verbatim;
/// English follows the NO/EN toggle.
abstract final class LfCopy {
  static bool get en => resolveSelectedLanguage() == 'en';

  static String _t(String no, String e) => en ? e : no;

  // ── Ladder ────────────────────────────────────────────────────────────────
  static List<String> get ladder =>
      en ? const ['Terms', 'Account', 'Number', 'Ready'] : const ['Vilkår', 'Konto', 'Nummer', 'Klar'];
  static List<String> get ladderVipps => en ? const ['Terms', 'Ready'] : const ['Vilkår', 'Klar'];

  // ── Ægil (`onbAegilTx`) ───────────────────────────────────────────────────
  static String get aegilVilkaar =>
      _t('Kjapp sjekk først. Jeg lagrer bare det ærendet trenger, aldri mer.',
          'A quick check first. I only store what the errand needs, never more.');
  static String get aegilVilkaarVipps => _t(
      'Vipps har gitt meg navnet og nummeret ditt, så dette er siste steg. Jeg lagrer bare det ærendet trenger.',
      'Vipps gave me your name and number, so this is the last step. I only store what the errand needs.');
  static String get aegilKonto => _t('Nå lager vi kontoen din. Da husker jeg favorittene dine til neste gang.',
      "Now let's make your account. Then I'll remember your favourites next time.");
  static String get aegilTelefon => _t('Budet ringer deg når han står i porten — derfor trenger vi nummeret.',
      "The courier calls you when they're at the gate — that's why we need your number.");
  static String get aegilKode => _t('Fire tall, så er vi nesten i havn.', "Four digits and we're nearly there.");
  static String get aegilFerdig => _t('Velkommen om bord! Gaven din er åpnet. Du er på Bronse, og hvert ærend tar deg et steg opp.',
      'Welcome aboard! Your gift is open. You are on Bronze, and every errand takes you a step up.');

  // ── Landing ───────────────────────────────────────────────────────────────
  static String get tittel => _t('Alt du trenger, ett ærend', 'Everything you need, one errand');
  static String tittelVerv(String navn) => _t('$navn har sendt deg et ærend', '$navn has sent you an errand');
  static String get under => _t('Jeg er Ægil. Jeg finner varene, budet henter, og du er i gang på under ett minutt.',
      "I'm Ægil. I find the goods, the courier picks up, and you're set up in under a minute.");
  static String get heiTittel => _t('Hei! Jeg er Ægil.', "Hi! I'm Ægil.");
  static String get heiUnder => _t('Butikkene i Bergen, levert av ett bud.', "Bergen's shops, delivered by one courier.");
  static String get chipButikker => _t('Butikker i hele Bergen', 'Shops all over Bergen');
  static String get chipBud => _t('Ett bud henter alt', 'One courier gets it all');
  static String get chipPoeng => _t('Poeng på hvert kjøp', 'Points on every order');
  static String invitasjonFra(String navn) => _t('Invitasjon fra $navn', 'Invitation from $navn');
  static String get poeng => _t('poeng', 'points');
  static String get tilDereBegge =>
      _t('til dere begge når du henter ditt første ærend', 'for you both when you collect your first errand');
  static String get annenKode => _t('Har du en annen kode?', 'Got another code?');
  static String get harVervekode => _t('Har du en vervekode?', 'Got a referral code?');
  static String get vervekode => _t('Vervekode', 'Referral code');
  static String get bruk => _t('Bruk', 'Apply');
  static String get vervHint => _t('Prøv: BERGEN-4827 (gyldig)', 'Try: BERGEN-4827 (valid)');
  /// [poeng]: `points/rules` referral.referee; null until it answers.
  static String vervLagtTil(int? poeng) => poeng == null || poeng <= 0
      ? _t('Lagt til', 'Added')
      : _t('Lagt til · +$poeng poeng til dere begge', 'Added · +$poeng points for you both');
  static String get vervTom => _t('Skriv inn en vervekode', 'Enter a referral code');
  static String invitasjonen(String navn) => _t('${navn}s invitasjon', "$navn's invitation");
  static String get fortsettMed => _t('Fortsett med', 'Continue with');
  static String get brukEpost => _t('Bruk e-post', 'Use email');
  static String get seRundt => _t('Se deg rundt først', 'Look around first');
  static String get seRundtToast =>
      _t('Du ser deg rundt · lag konto når du vil handle', "You're looking around · make an account when you want to shop");
  static String get avvisToast => _t('Du kan lage konto når som helst', 'You can make an account any time');

  // ── Vilkår ────────────────────────────────────────────────────────────────
  static String get vilkaarTittel => _t('Vilkår og personvern', 'Terms and privacy');
  static String get vilkaarDoc => _t('Vilkår for bruk', 'Terms of use');
  static String get vilkaarDocSub => _t('Regler for bruk av app og levering', 'Rules for the app and delivery');
  static String get vilkaarDocTid => _t('Ca. 3 min å lese', 'About 3 min to read');
  static String get personvernDoc => _t('Personvernerklæring', 'Privacy policy');
  static String get personvernDocSub => _t('Hvordan vi behandler opplysningene dine', 'How we handle your information');
  static String get personvernDocTid => _t('Ca. 2 min å lese', 'About 2 min to read');
  static String get lest => _t('Lest', 'Read');
  static String get godtarA => _t('Jeg har lest og godtar ', "I've read and accept the ");
  static String get godtarB => _t('vilkårene for bruk', 'terms of use');
  static String get godtarC => _t(' og ', ' and the ');
  static String get godtarD => _t('personvernerklæringen', 'privacy policy');
  static String get godtaFortsett => _t('Godta og fortsett', 'Accept and continue');
  static String get avvis => _t('Avvis', 'Decline');
  static String get personvern => _t('Personvern', 'Privacy');
  static String get oppdatert => _t('OPPDATERT 2. APRIL 2026', 'UPDATED 2 APRIL 2026');
  static String get tilbakeVilkaar => _t('Tilbake til vilkårene', 'Back to the terms');

  static List<(String, String, List<String>)> get vilkaarBolker => const [
    ('Velkommen til Ærend', 'Disse vilkårene beskriver reglene for bruk av Ærend-appen og leveringstjenesten i Bergen.', []),
    ('Lisens', 'Med mindre annet er oppgitt eier Ærend og våre lisensgivere alle immaterielle rettigheter til innholdet i appen. Du kan bruke innholdet til eget personlig bruk, innenfor rammene av disse vilkårene.', []),
    ('Du kan ikke', '', ['Publisere Ærends innhold på nytt', 'Selge, leie ut eller viderelisensiere innholdet', 'Kopiere eller duplisere innholdet', 'Distribuere innholdet videre']),
    ('Ægil og anbefalinger', 'Ægil kan foreslå varer, bytte til billigere alternativ og si «vent» når det lurer seg. Du bestemmer alltid til slutt, og ingenting legges i kurven uten at du ser det.', []),
    ('Poeng og premier', 'Poeng er ikke penger og kan ikke veksles i kroner. En hentet premie gjelder i 60 dager. Poeng fra et ærend trekkes tilbake hvis ærendet refunderes.', []),
    ('Levering i Bergen', 'Leveringstid er et estimat, ikke en garanti. Bud som ikke når fram, kontakter deg på telefonnummeret du bekrefter i registreringen.', []),
  ];

  static List<(String, String, List<String>)> get personvernBolker => const [
    ('Hva vi lagrer', 'Navn, telefonnummer, e-post og leveringsadresse — det vi trenger for å levere ærendet ditt og gi deg poengene dine.', []),
    ('Hva vi aldri gjør', 'Vi selger aldri dataene dine. Butikken ser bare det den må for å pakke ordren, aldri hele historikken din.', []),
    ('Ægils hukommelse', 'Det Ægil husker om deg — rytmer, allergier, favoritter — ligger på din konto. Du kan lese, endre og slette hvert enkelt minne under Meg.', []),
    ('Synlighet i bydelsligaen', 'Du velger selv om navnet ditt vises. Du kan bruke visningsnavn, bare fornavn, eller være helt anonym.', []),
    ('Dine rettigheter', 'Du kan når som helst be om innsyn i, retting av eller sletting av dataene dine fra Meg → Personvern.', []),
  ];

  // ── Konto ─────────────────────────────────────────────────────────────────
  static String get opprettKonto => _t('Opprett konto', 'Create account');
  static String get loggInn => _t('Logg inn', 'Log in');
  static String get velkommenTilbake => _t('Velkommen tilbake', 'Welcome back');
  static String get regUnder => _t('Bli med i Ærend Bergen — hvert ærend gir poeng på hylla di.',
      'Join Ærend Bergen — every errand earns points on your shelf.');
  static String get loggUnder => _t('Logg inn, så ligger kurven og Ægils hukommelse der du forlot dem.',
      "Log in and your basket and Ægil's memory are right where you left them.");
  static String get fulltNavn => _t('FULLT NAVN', 'FULL NAME');
  static String get epost => _t('E-POST', 'EMAIL');
  static String get passord => _t('PASSORD', 'PASSWORD');
  static String get navnHint => 'Didrik Eide';
  static String get epostHint => _t('deg@eksempel.no', 'you@example.com');
  static String get epostHintLogg => _t('didrik@eksempel.no', 'didrik@example.com');
  static String get passHint => _t('Minst 6 tegn', 'At least 6 characters');
  static String get passHintLogg => _t('Skriv inn passordet ditt', 'Enter your password');
  static String get sterkt => _t('Sterkt', 'Strong');
  static String get greit => _t('Greit', 'Okay');
  static String get forKort => _t('For kort', 'Too short');
  // The numbers come from `points/rules` (backend plan Step 3): [konto] is the
  // sign-up bonus (0 while it is off), [verv] the referee's points, which
  // arrive with the first errand.
  static String bonusVerv(int konto, int verv) => konto > 0
      ? _t('Ægil legger $konto startpoeng på hylla di, og $verv til fra vervingen når du henter første ærend.',
          'Ægil puts $konto starting points on your shelf, and $verv more from the referral when you collect your first errand.')
      : _t('Vervingen gir deg $verv poeng når du henter første ærend.',
          'The referral gives you $verv points when you collect your first errand.');
  static String bonusOrg(int konto) => _t('Ægil legger $konto startpoeng på hylla di så snart kontoen står.',
      'Ægil puts $konto starting points on your shelf as soon as your account is set up.');
  static String get regMangler =>
      _t('Fyll ut navn, e-post og passord (minst 6 tegn)', 'Fill in name, email and password (at least 6 characters)');
  static String get loggMangler => _t('Skriv inn e-post og passord', 'Enter email and password');
  static String get harKonto => _t('Har du konto allerede? ', 'Already have an account? ');
  static String get glemtPassord => _t('Glemt passord?', 'Forgot password?');
  static String get tilbakeInnlogging => _t('Tilbake til innlogging', 'Back to sign-in');

  // ── Telefon ───────────────────────────────────────────────────────────────
  static String get tlfTittel => _t('Bekreft nummeret ditt', 'Confirm your number');
  static String get tlfUnder => _t('Vi sender en kode på SMS. Budet ringer dette nummeret når han står i porten.',
      "We'll text you a code. The courier calls this number when they're at the gate.");
  static String get tlfLabel => _t('TELEFONNUMMER', 'PHONE NUMBER');
  static String get tlfHint => '400 12 345';
  static String get sendKode => _t('Send kode', 'Send code');
  static String get tlfMangler => _t('Skriv inn et norsk mobilnummer', 'Enter a Norwegian mobile number');
  static String get tilbake => _t('Tilbake', 'Back');

  // ── Kode ──────────────────────────────────────────────────────────────────
  static String get kodeTittel => _t('Skriv inn koden', 'Enter the code');
  static String get kodeSendt => _t('Vi sendte en 4-sifret kode til ', 'We sent a 4-digit code to ');
  static String get demoBruk => _t('Demo: bruk ', 'Demo: use ');
  static String get bekreft => _t('Bekreft', 'Confirm');
  static String get kodeMangler => _t('Skriv inn de fire sifrene', 'Enter the four digits');
  static String sendPaaNyttOm(int s) => _t('Send kode på nytt om $s s', 'Resend code in $s s');
  static String get sendPaaNytt => _t('Send kode på nytt', 'Resend code');
  static String get endreTlf => _t('Endre telefonnummer', 'Change phone number');

  // ── Ferdig ────────────────────────────────────────────────────────────────
  static String velkommen(String fornavn) => _t('Velkommen, $fornavn', 'Welcome, $fornavn');
  static String get bergenser => _t('bergenser', 'friend');
  static String get startpoeng => _t('STARTPOENG', 'STARTING POINTS');
  static String get leggerPoeng => _t('Legger poeng på hylla …', 'Adding points to your shelf …');
  static String poengVerv(int konto, int verv, String navn) => _t('$konto for kontoen · $verv fra ${navn}s verving ved første ærend',
      "$konto for the account · $verv from $navn's referral on your first errand");
  static String poengOrg(int konto) => _t('$konto for kontoen · første ærend gir mer', '$konto for the account · your first errand gives more');
  static String get oppdragForste => _t('Første ærend', 'First errand');
  static String get oppdragFisk => _t('Fisk i Vågen', 'Fish in Vågen');
  static String get oppdragVerv => _t('Verv en nabo', 'Refer a neighbour');
  static String get komIGang => _t('Kom i gang', 'Get started');
  static String velkommenToast(int p) => p <= 0
      ? _t('Velkommen til Ærend', 'Welcome to Ærend')
      : _t('Velkommen til Ærend · $p startpoeng på hylla', 'Welcome to Ærend · $p starting points on your shelf');

  // ── Laster ────────────────────────────────────────────────────────────────
  static String get henter => _t('Henter ærendet', 'Fetching the errand');
}
