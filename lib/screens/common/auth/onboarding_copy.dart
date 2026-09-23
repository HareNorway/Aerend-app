import '../../../utils/utils.dart';

/// Copy for the Ærend Bergen onboarding flow (`Design/Ærend Kunde Bergen
/// (frittstående).html`, `data-screen-label="Onboarding"`). Norwegian is the
/// design's copy; English follows the NO/EN toggle. Every other locale falls
/// back to Norwegian, the app's primary market.
abstract final class OnbCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';

  static String _t(String no, String en) => _en ? en : no;

  // ── Step ladder ───────────────────────────────────────────────────────────
  static List<String> get ladder => _en
      ? const ['Terms', 'Account', 'Number', 'Ready']
      : const ['Vilkår', 'Konto', 'Nummer', 'Klar'];

  // ── Ægil ──────────────────────────────────────────────────────────────────
  static String get aegilLanding => _t(
    'Hei! Jeg er Ægil. Jeg finner varene, budet henter — du slapper av.',
    "Hi! I'm Ægil. I find the goods, the courier picks up — you relax.",
  );
  static String get aegilTerms => _t(
    'Kjedelig, men viktig. Jeg lagrer bare det ærendet trenger.',
    'Boring, but important. I only store what the errand needs.',
  );
  static String get aegilAccount => _t(
    'Lag en konto, så husker jeg favorittene dine til neste gang.',
    "Make an account and I'll remember your favourites for next time.",
  );
  static String get aegilPhone => _t(
    'Budet ringer deg når han står i porten — derfor trenger vi nummeret.',
    "The courier calls you when they're at the gate — that's why we need your number.",
  );
  static String get aegilCode => _t(
    'Fire tall, så er vi nesten i havn.',
    "Four digits and we're nearly there.",
  );
  static String get aegilDone => _t(
    'Velkommen om bord! Første ærend gir deg 50 poeng.',
    'Welcome aboard! Your first errand gives you 50 points.',
  );
  static String get aegilDoneTier => _t(
    'Du er på Bronse — hvert ærend klatrer deg oppover hylla.',
    "You're on Bronze — every errand climbs you up the shelf.",
  );
  static String get aegilLabel => 'ÆGIL';

  // ── Landing ───────────────────────────────────────────────────────────────
  static String get landingTitle =>
      _t('Alt du trenger, ett ærend', 'Everything you need, one errand');
  static String get landingSubtitle => _t(
    'Bergenske butikker, ett bud, og Ægil som husker hva du liker.',
    'Bergen shops, one courier, and Ægil who remembers what you like.',
  );
  static String get invitedTitle => _t('Du er vervet', "You've been invited");
  static String get invitedPoints =>
      _t('+50 poeng til dere begge', '+50 points for you both');
  static String get referralHint =>
      _t('F.eks. BERGEN-4827', 'E.g. BERGEN-4827');
  static String get referralApply => _t('Bruk', 'Apply');
  static String get referralPrompt =>
      _t('Har du en vervekode?', 'Got a referral code?');
  static String get referralSaved => _t(
    'Lagt til · +50 poeng til dere begge når kontoen står',
    "Added · +50 points for you both once your account's set up",
  );
  static String get referralEmpty =>
      _t('Skriv inn en vervekode', 'Enter a referral code');
  static String get continueGoogle =>
      _t('Fortsett med Google', 'Continue with Google');
  static String get continueApple =>
      _t('Fortsett med Apple', 'Continue with Apple');
  static String get withEmail => _t('eller med e-post', 'or with email');
  static String get browseFirst =>
      _t('Se deg rundt først', 'Look around first');

  // ── Vilkår ────────────────────────────────────────────────────────────────
  static String get termsTitle =>
      _t('Vilkår og personvern', 'Terms and privacy');
  static String get termsDoc => _t('Vilkår for bruk', 'Terms of use');
  static String get termsDocSub => _t(
    'Regler for bruk av app og levering',
    'Rules for the app and delivery',
  );
  static String get privacyDoc => _t('Personvernerklæring', 'Privacy policy');
  static String get privacyDocSub => _t(
    'Hvordan vi behandler opplysningene dine',
    'How we handle your information',
  );
  static String get acceptPrefix =>
      _t('Jeg har lest og godtar ', "I've read and accept the ");
  static String get acceptTerms => _t('vilkårene for bruk', 'terms of use');
  static String get acceptAnd => _t(' og ', ' and the ');
  static String get acceptPrivacy =>
      _t('personvernerklæringen', 'privacy policy');
  static String get acceptCta => _t('Godta og fortsett', 'Accept and continue');
  static String get decline => _t('Avvis', 'Decline');
  static String get declinedToast => _t(
    'Du kan lage konto når som helst',
    'You can create an account any time',
  );
  static String get backToTerms =>
      _t('Tilbake til vilkårene', 'Back to the terms');

  // ── Konto ─────────────────────────────────────────────────────────────────
  static String get tabRegister => _t('Opprett konto', 'Create account');
  static String get tabLogin => _t('Logg inn', 'Log in');
  static String get registerTitle => _t('Opprett konto', 'Create account');
  static String get loginTitle => _t('Velkommen tilbake', 'Welcome back');
  static String get registerSubtitle => _t(
    'Bli med i Ærend Bergen — hvert ærend gir poeng på hylla di.',
    'Join Ærend Bergen — every errand earns points on your shelf.',
  );
  static String get loginSubtitle => _t(
    'Logg inn, så ligger kurven og Ægils hukommelse der du forlot dem.',
    "Log in and your basket and Ægil's memory are right where you left them.",
  );
  static String get fullName => _t('FULLT NAVN', 'FULL NAME');
  static String get fullNameHint => _t('Ola Nordmann', 'Ola Nordmann');
  static String get email => _t('E-POST', 'EMAIL');
  static String get emailHint => _t('deg@eksempel.no', 'you@example.com');
  static String get password => _t('PASSORD', 'PASSWORD');
  static String get passwordHintNew =>
      _t('Minst 6 tegn', 'At least 6 characters');
  static String get passwordHintLogin =>
      _t('Skriv inn passordet ditt', 'Enter your password');
  static String get strengthShort => _t('For kort', 'Too short');
  static String get strengthOk => _t('Greit', 'Okay');
  static String get strengthStrong => _t('Sterkt', 'Strong');
  static String get bonusReferral => _t(
    'Ægil legger 100 startpoeng på hylla di: 50 for kontoen og 50 fra vervingen.',
    'Ægil puts 100 starting points on your shelf: 50 for the account and 50 from the referral.',
  );
  static String get bonusOrganic => _t(
    'Ægil legger 50 startpoeng på hylla di så snart kontoen står.',
    'Ægil puts 50 starting points on your shelf as soon as your account is set up.',
  );
  static String get registerMissing => _t(
    'Fyll ut navn, e-post og passord (minst 6 tegn)',
    'Fill in name, email and password (at least 6 characters)',
  );
  static String get loginMissing =>
      _t('Skriv inn e-post og passord', 'Enter email and password');
  static String get haveAccount =>
      _t('Har du konto allerede? ', 'Already have an account? ');
  static String get forgotPassword => _t('Glemt passord?', 'Forgot password?');
  static String get backToLanding =>
      _t('Tilbake til innlogging', 'Back to sign-in');

  // ── Telefon ───────────────────────────────────────────────────────────────
  static String get phoneTitle =>
      _t('Bekreft nummeret ditt', 'Confirm your number');
  static String get phoneSubtitle => _t(
    'Vi sender en kode på SMS. Budet ringer dette nummeret når han står i porten.',
    "We'll text you a code. The courier calls this number when they're at the gate.",
  );
  static String get phoneLabel => _t('TELEFONNUMMER', 'PHONE NUMBER');
  static String get phoneHint => '400 12 345';
  static String get phoneMissing =>
      _t('Skriv inn et norsk mobilnummer', 'Enter a mobile number');
  static String get sendCode => _t('Send kode', 'Send code');
  static String get back => _t('Tilbake', 'Back');

  // ── Kode ──────────────────────────────────────────────────────────────────
  static String get codeTitle => _t('Skriv inn koden', 'Enter the code');
  static String get codeSentTo =>
      _t('Vi sendte en 4-sifret kode til ', 'We sent a 4-digit code to ');
  static String get codeDemo => _t('Demo: bruk ', 'Demo: use ');
  static String get confirm => _t('Bekreft', 'Confirm');
  static String get codeMissing =>
      _t('Skriv inn de fire sifrene', 'Enter the four digits');
  static String resendIn(int s) =>
      _t('Send kode på nytt om $s s', 'Resend code in $s s');
  static String get resend => _t('Send kode på nytt', 'Resend code');
  static String get changeNumber =>
      _t('Endre telefonnummer', 'Change phone number');

  // ── Ferdig ────────────────────────────────────────────────────────────────
  static String welcome(String firstName) =>
      _t('Velkommen, $firstName', 'Welcome, $firstName');
  static String get fallbackFirstName => _t('bergenser', 'friend');
  static String get startPoints => _t('STARTPOENG', 'STARTING POINTS');
  static String get pointsCounting =>
      _t('Legger poeng på hylla …', 'Adding points to your shelf …');
  static String get pointsReferral => _t(
    '50 for kontoen + 50 fra vervingen',
    '50 for the account + 50 from the referral',
  );
  static String get pointsOrganic => _t(
    '50 for kontoen · første ærend gir mer',
    '50 for the account · your first errand gives more',
  );
  static String get missionFirst => _t('Første ærend', 'First errand');
  static String get missionFish => _t('Fisk i Vågen', 'Fish in Vågen');
  static String get missionRefer => _t('Verv en nabo', 'Refer a neighbour');
  static String get getStarted => _t('Kom i gang', 'Get started');
}
