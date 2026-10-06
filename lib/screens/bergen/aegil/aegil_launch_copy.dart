// ignore_for_file: non_constant_identifier_names

import '../../../utils/utils.dart';

/// Copy for Ægil (`erAgent` L4500–5120 in `Ærend Kunde Launch.dc.html`):
/// the start view, the chat, Det Ægil vet om deg, Så mye kan Ægil gjøre, the
/// first-time disclosure, the five onboarding questions, the basket strip
/// and the composer. The design's wording verbatim; NO and EN.
abstract final class AeCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  // ── Header (`hodeVals` / `vcVals`) ────────────────────────────────────────
  static String get navn => 'Ægil';
  static String get lytter => _t('Lytter', 'Listening');
  static String get skriver => _t('Skriver …', 'Typing …');
  static String get herForDeg => _t('Her for deg', 'Here for you');
  static String get fantTre => _t('Fant tre valg', 'Found three options');
  static String get fantNoe => _t('Fant noe', 'Found something');
  static String get fikser => _t('Fikser kurven', 'Fixing the basket');
  static String get sammenlikner => _t('Sammenlikner', 'Comparing');
  static String get beklager => _t('Beklager', 'Sorry');
  static String get ikkeSikker => _t('Ikke sikker', 'Not sure');
  static String get saaMye => _t('Så mye kan jeg gjøre', 'What I can do');
  static String get detJegVet => _t('Det jeg vet om deg', 'What I know about you');
  static String get sporDeg => _t('Spør deg', 'Asking you');
  static String get foreslaa => _t('Foreslå', 'Suggest');
  static String get handle => _t('Handle i kurven', 'Shop in the basket');
  static String get toastForeslaa => _t('Ægil foreslår — du legger i kurven', 'Ægil suggests — you add to the basket');
  static String get toastHandle => _t('Ægil kan nå legge til og bytte for deg', 'Ægil can now add and swap for you');

  // ── Start (`agS0`, L4634) ─────────────────────────────────────────────────
  static String kicker(String klokke, String dag) => 'ÆGIL · $klokke ${dag.toUpperCase()}';
  static String sporsmaal(int hour) =>
      hour >= 17 || hour < 5 ? _t('Hva trenger du i kveld?', 'What do you need tonight?') : _t('Hva trenger du i dag?', 'What do you need today?');
  static String igjen(String dag, String butikk) =>
      _t('${_stor(dag)} igjen. Samme som sist fra $butikk?', '${_stor(dag)} again. Same as last time from $butikk?');
  static String get husker => _t('Husker:', 'Remembers:');
  static String og(String a, String b) => _t('$a og $b', '$a and $b');
  static String get minneTilbud =>
      _t('Vil du at jeg husker hva du liker? Da kan jeg si fra når det er tilbud på det.', 'Want me to remember what you like? Then I can tell you when it’s on offer.');
  static String get jaLaOss => _t('Ja, la oss', 'Yes, let’s');
  static String get ikkeNaa => _t('Ikke nå', 'Not now');

  // ── Ægil tipper (L4641) ───────────────────────────────────────────────────
  static String get tipper => _t('ÆGIL TIPPER', 'ÆGIL TIPS');
  static String get pleier => _t('Du pleier å bestille nå', 'You usually order now');
  static String get forrige => _t('Forrige bestilling', 'Last order');
  static String get sammeSomSist => _t('Samme som sist', 'Same as last time');
  static String bestillingen(String dag) => _t('${dag}sbestillingen', '$dag’s order');
  static String levertOm(int min) => _t('Levert om ca. $min min', 'Delivered in about $min min');
  static String get bestillIgjen => _t('Bestill igjen', 'Order again');
  static String get endre => _t('Endre', 'Change');
  static String endreSist(String butikk) =>
      _t('Jeg vil ha samme som sist fra $butikk, men endre litt', 'I want the same as last time from $butikk, but change it a bit');
  static String get iKurven => _t('ligger i kurven', 'is in the basket');

  // ── Be Ægil om noe (L4665) ────────────────────────────────────────────────
  static String get beOm => _t('Be Ægil om noe', 'Ask Ægil for something');
  static String get ordner => _t('Han ordner resten', 'He handles the rest');
  static String get taco => _t('Tacokveld for fire', 'Taco night for four');
  static String get tacoSub => _t('Under 500 kr', 'Under 500 kr');
  static String get tacoSi => _t('Tacokveld for fire under 500 kr', 'Taco night for four under 500 kr');
  static String get reker => _t('Billigste reker', 'Cheapest prawns');
  static String rekerSub(int kr) => _t('Fra $kr kr', 'From $kr kr');
  static String get rekerSubTom => _t('I nærheten', 'Nearby');
  static String get rekerSi => _t('Finn de billigste rekene i nærheten', 'Find the cheapest prawns nearby');
  static String get gave => _t('Gave til mamma', 'Gift for mum');
  static String get gaveSub => _t('Til lørdag', 'For Saturday');
  static String get gaveSi => _t('Jeg trenger en gave til mamma til lørdag', 'I need a gift for mum for Saturday');
  static String get sokSelv => _t('Eller søk og bla selv', 'Or search and browse yourself');

  // ── Chat (`vcAktiv`, L4574) ───────────────────────────────────────────────
  static String get nyPrat => _t('Ny prat med Ægil', 'New chat with Ægil');
  static String get leggIKurven => _t('Legg i kurven', 'Add to basket');
  static String get lagtIKurven => _t('I kurven', 'In basket');
  static String get aapne => _t('Åpne', 'Open');
  static String get se => _t('Se', 'See');
  static String get utenNett =>
      _t('Jeg får ikke kontakt med Vågen akkurat nå. Prøv igjen om litt.', 'I can’t reach Vågen right now. Try again in a moment.');
  static String get leggAlt => _t('Legg alt i kurven', 'Add all to basket');
  static String get aegilLeggerAlt => _t('Ægil legger alt i kurven', 'Ægil adds all to the basket');
  static String get byttButikk => _t('Bytt butikk', 'Change store');
  static String get sammenlignSi => _t('Sammenlign prisene i nærheten', 'Compare prices nearby');
  static String varer(int n) => _t('$n ${n == 1 ? 'vare' : 'varer'}', '$n ${n == 1 ? 'item' : 'items'}');
  static String get derfor => _t('Derfor:', 'Why:');
  static String aapenMin(int a, int b) => _t('Åpen · $a–$b min', 'Open · $a–$b min');
  static String get billigst => _t('Billigst', 'Cheapest');
  static String get velg => _t('Velg', 'Choose');
  static String get prisNote => _t('Prisene er butikkenes egne i kveld.', 'Prices are the stores’ own tonight.');
  static String get funn => _t('Funn', 'Find');
  static String get ikkeFunnet => _t('Ikke funnet', 'Not found');
  static String get alderTittel => _t('18+ · ikke verifisert', '18+ · not verified');
  static String get alderLinje => _t('Jeg legger ikke inn alkohol før alderssjekken er gjort.', 'I won’t add alcohol until the age check is done.');
  static String get bankId => 'BankID';
  static String get kvittering => _t('Kvittering', 'Receipt');
  static String get beskjedTilBudet => _t('Beskjed til budet', 'Note for the courier');
  static String get lagre => _t('Lagre', 'Save');
  static String get angre => _t('Angre', 'Undo');
  static String get lagret => _t('Lagret for budet', 'Saved for the courier');
  static String get bytt => _t('Bytt', 'Swap');
  static String get behold => _t('Behold', 'Keep');
  static String grunn(String g) => _t('Grunn: $g', 'Reason: $g');
  static String get allergen =>
      _t('Jeg bruker allergeninformasjonen fra butikken. Spør dem hvis du er usikker.', 'I use the store’s allergen information. Ask them if you’re unsure.');

  // Chips (`CHIPS`), sent to Ægil as they read.
  static String get chipKurv => _t('Vis kurven', 'Show the basket');
  static String get chipBillig => _t('Billigste i nærheten', 'Cheapest nearby');
  static String get chipGave => _t('Finn en gave', 'Find a gift');
  static String get chipSulten => _t('Jeg er sulten', 'I’m hungry');
  static String get chipHjelp => _t('Hva kan du hjelpe med?', 'What can you help with?');
  static String get chipUtenOl => _t('Uten øl, takk', 'No beer, thanks');
  static String get chipAnnenDag => _t('Prøv noe annet', 'Try something else');
  static String get chipTaco => _t('Tacokveld for fire under 500 kr', 'Taco night for four under 500 kr');
  static String get chipFerdig => _t('Ferdig', 'Done');
  static String get chipPoeng => _t('Hvordan får jeg poeng?', 'How do I get points?');
  static String get chipFiske => _t('Hva er Fjordfiske?', 'What is Fjordfiske?');
  static String get chipBud => _t('Hvor er budet?', 'Where is the courier?');

  // Ægil's own lines for the app topics (`vcLokal`), used when the request is
  // about the app rather than something to buy.
  static String get svHjelp => _t(
    'Selvsagt, det er jo det jeg er her for! Jeg finner mat og varer fra butikkene i Bergen, holder øye med budet ditt og viser deg premiene du kan vinne. Hvor vil du starte?',
    'Of course, that’s what I’m here for! I find food and goods from the stores in Bergen, keep an eye on your courier and show you the prizes you can win. Where do you want to start?',
  );
  static String get svSvar => _t('Klart jeg er her! Jeg sitter på sykkelsetet og venter på neste ærend. Hva kan jeg hjelpe deg med?', 'Of course I’m here! I’m on the bike seat waiting for the next errand. What can I help you with?');
  static String svHei(String navn) => navn.isEmpty
      ? _t('Heisann! Kjekt å se deg. Er du sulten, på gavejakt, eller bare innom for en prat?', 'Hi there! Nice to see you. Hungry, hunting for a gift, or just stopping by for a chat?')
      : _t('Heisann, $navn! Kjekt å se deg. Er du sulten, på gavejakt, eller bare innom for en prat?', 'Hi there, $navn! Nice to see you. Hungry, hunting for a gift, or just stopping by for a chat?');
  static String get svPose => _t(
    'Sparejakt? Da må du prøve Poseautomaten! Butikkene legger overskuddet i en forundringspose, og den er alltid verdt mer enn du betaler.',
    'Bargain hunting? Then try the bag machine! The stores put their surplus in a surprise bag, and it’s always worth more than you pay.',
  );
  static String get svFiske => _t(
    'Bli med ut i Vågen! I Fjordfiske kaster du snøret og drar inn ekte premier fra butikkene. Jeg holder stanga for deg.',
    'Come out on Vågen! In Fjordfiske you cast the line and reel in real prizes from the stores. I’ll hold the rod for you.',
  );
  static String svPoeng(int? n) => n == null
      ? _t('Du får poeng på hvert kjøp, og kan løse dem inn på Premiehylla.', 'You get points on every purchase and can redeem them on the prize shelf.')
      : _t('Du har $n poeng. Du får poeng på hvert kjøp, og kan løse dem inn på Premiehylla.', 'You have $n points. You get points on every purchase and can redeem them on the prize shelf.');
  static String get svSporing => _t(
    'Jeg sjekker med budet! Du kan følge hele turen live, fra butikken og helt til døra di.',
    'I’ll check with the courier! You can follow the whole trip live, from the store right to your door.',
  );
  static String get svKurv => _t('Kurven din ligger klar. Vil du at jeg tar en titt og ser om det er noe du har glemt?', 'Your basket is ready. Want me to take a look and see if you’ve forgotten anything?');
  static String get svTakk => _t('Bare hyggelig, det er jo det venner er til for! Si fra hvis du trenger noe mer i kveld.', 'My pleasure, that’s what friends are for! Let me know if you need anything else tonight.');
  static String get ingenAktiv => _t('Du har ingen bestilling på vei akkurat nå', 'You have no order on its way right now');
  static String get chipHvaPose => _t('Hva er i posen?', 'What’s in the bag?');
  static String get chipPremier => _t('Hvilke premier?', 'Which prizes?');
  static String get chipNytt => _t('Hva er nytt i dag?', 'What’s new today?');
  static String get chipGull => _t('Hvordan når jeg Gull?', 'How do I reach Gold?');

  // App cards (`VC_APP`).
  static String get appFiske => 'Fjordfiske';
  static String get appFiskeSub => _t('Kast ut og vinn premier', 'Cast out and win prizes');
  static String get appFiskeCta => _t('Spill', 'Play');
  static String get appPose => _t('Forundringspose', 'Surprise bag');
  static String get appPoseSub => _t('Butikkenes overskudd i en pose', 'The stores’ surplus in a bag');
  static String get appPoseCta => _t('Trekk', 'Draw');
  static String get appSporing => _t('Bestillingen din', 'Your order');
  static String get appSporingSub => _t('Følg budet live', 'Follow the courier live');
  static String get appSporingCta => _t('Følg', 'Follow');
  static String get appPoeng => _t('Poeng og premier', 'Points and prizes');
  static String appPoengSub(int n) => _t('$n poeng · Premiehylla', '$n points · Prize shelf');
  static String get appKurv => _t('Kurven din', 'Your basket');
  static String get appKurvSub => _t('Se og betal', 'Review and pay');
  static String get appUtforsk => _t('Utforsk Bergen', 'Explore Bergen');
  static String get appUtforskSub => _t('Alle butikkene på ett sted', 'All the stores in one place');
  static String get appUtforskCta => _t('Utforsk', 'Explore');

  // Primary buttons (`knapper`) for the app topics.
  static String get kastUt => _t('Kast ut nå', 'Cast out now');
  static String get trekkPose => _t('Trekk en pose', 'Draw a bag');
  static String get sePremiehylla => _t('Se Premiehylla', 'See the prize shelf');
  static String get folgBestillingen => _t('Følg bestillingen', 'Follow the order');
  static String get gaaTilKurven => _t('Gå til kurven', 'Go to the basket');

  // ── Minne (`agMinne`) ─────────────────────────────────────────────────────
  static String get minneTittel => _t('Det Ægil vet om deg', 'What Ægil knows about you');
  static String get minneSub =>
      _t('Alt her er ditt. Hver linje kan fjernes, og Ægil bruker ingenting som ikke står her.', 'All of this is yours. Every line can be removed, and Ægil uses nothing that isn’t here.');
  static String get minneTom => _t('Jeg vet ingenting om deg ennå. Vil du fortelle meg litt?', 'I don’t know anything about you yet. Want to tell me a little?');
  static String get duLiker => _t('DU LIKER', 'YOU LIKE');
  static String get butikker => _t('BUTIKKER', 'STORES');
  static String get husstand => _t('HUSSTAND', 'HOUSEHOLD');
  static String get kosthold => _t('KOSTHOLD', 'DIET');
  static String get middagsrytme => _t('MIDDAGSRYTME', 'DINNER RHYTHM');
  static String get lagtMerkeTil => _t('ÆGIL HAR LAGT MERKE TIL', 'ÆGIL HAS NOTICED');
  static String get varsler => _t('VARSLER', 'NOTIFICATIONS');
  static String get leggTil => _t('Legg til', 'Add');
  static String get fjern => _t('Fjern', 'Remove');
  static String get stemmer => _t('Stemmer', 'That’s right');
  static String get brukesAlltid => _t('Brukes alltid, også når Ægil handler for deg.', 'Always used, also when Ægil shops for you.');
  static String get bekreftet => _t('Bekreftet — styrer automatikk', 'Confirmed — drives automation');
  static String get kunForslag => _t('kun forslag til du bekrefter', 'suggestions only until you confirm');
  static String get fraChat => _t('Fra praten', 'From the chat');
  static String get saaMyeRad => _t('Så mye kan Ægil gjøre', 'What Ægil can do');
  static String get glemAlt => _t('Glem alt', 'Forget everything');
  static String get glemAltSub => _t('Bestillingshistorikken blir. Preferansene forsvinner.', 'Your order history stays. The preferences go.');
  static String get glemtAlt => _t('Alt Ægil visste er slettet', 'Everything Ægil knew is deleted');
  static String get personer1 => _t('person', 'person');
  static String get personer => _t('personer', 'people');
  static String varselLinje(String push, String? ro) => ro == null ? push : '$push · ${_t('rolig', 'quiet')} $ro';
  static String get pushAldri => _t('Aldri', 'Never');
  static String get pushDag => _t('Én om dagen', 'One a day');
  static String get pushBra => _t('Når det er noe bra', 'When there’s something good');
  static String get pushBraMaks => _t('Når det er noe bra · maks 3 per uke', 'When there’s something good · max 3 a week');

  // ── Nivå (`agNivaaSkjerm`) ────────────────────────────────────────────────
  static String get nivaaTittel => _t('Så mye kan Ægil gjøre', 'What Ægil can do');
  static String get nivaaSub =>
      _t('Du velger. Ægil gjør aldri mer enn nivået sier, og du får kvittering på alt.', 'You choose. Ægil never does more than the level says, and you get a receipt for everything.');
  static String get standard => 'Standard';
  static String get bareDagligvarer => _t('Bare dagligvarer', 'Groceries only');
  static String get rammer => _t('RAMMER', 'LIMITS');
  static String get rmBut => _t('Butikker Ægil kan bruke', 'Stores Ægil can use');
  static String get rmButAlle => _t('Alle i nærheten', 'All nearby');
  static String get rmButFav => _t('Bare favoritter', 'Favourites only');
  static String get rmButListe => _t('Egen liste', 'My own list');
  static String get rmKat => _t('Kategorier', 'Categories');
  static String get rmKatAlle => _t('Alle fem', 'All five');
  static String get rmKatMat => _t('Bare Mat & fisk', 'Only Food & fish');
  static String get rmKatMatRest => _t('Mat, fisk og restaurant', 'Food, fish and restaurant');
  static String get rmBel => _t('Beløpsgrense', 'Spending limit');
  static String rmBelVerdi(int ordre, int uke) => _t('$ordre kr per handel · ${_kr(uke)} kr per uke', '$ordre kr per order · ${_kr(uke)} kr per week');
  static String get rmBelIngen => _t('Ingen grense satt', 'No limit set');
  static String get rmRo => _t('Rolige timer', 'Quiet hours');
  static String get rmRoIngen => _t('Ingen', 'None');
  static String get rmLaer => _t('Ægil lærer av bestillingene mine', 'Ægil learns from my orders');
  static String get paa => _t('På', 'On');
  static String get av => _t('Av', 'Off');
  static String get slaaAv => _t('Slå av', 'Turn off');
  static String get slaaPaa => _t('Slå på', 'Turn on');
  static String get pause => _t('Pause Ægil', 'Pause Ægil');
  static String get startIgjen => _t('Start Ægil igjen', 'Start Ægil again');
  static String get pauset => _t('Ægil er pauset — ingen forslag eller varsler', 'Ægil is paused — no suggestions or notifications');
  static String get iGangIgjen => _t('Ægil er i gang igjen', 'Ægil is running again');
  static String get tilbake => _t('Tilbake til Ægil', 'Back to Ægil');
  static String get fastUkeshandel =>
      _t('Fast ukeshandel krever Vipps faste betalinger — settes opp ved første handel', 'A weekly shop needs Vipps recurring payments — set up at the first order');

  // ── Tillatelse (`agTillatelse`) ───────────────────────────────────────────
  static String get tlTittel => _t('Jeg er Ærends assistent, og jeg heter Ægil.', 'I’m Ærend’s assistant, and my name is Ægil.');
  static String get tlTekst =>
      _t('Jeg er en AI. Jeg kan finne varer, sammenlikne priser med levering og foreslå kurver. Du betaler alltid selv.', 'I’m an AI. I can find items, compare prices with delivery and suggest baskets. You always pay yourself.');
  static String get tlHva => _t('Hva Ægil får gjøre', 'What Ægil may do');
  static String get tlAlle => _t('Alle fem nivåer', 'All five levels');
  static String get tlForeslaaSub => _t('Ægil viser kort — du trykker for å legge i kurven', 'Ægil shows cards — you tap to add to the basket');
  static String get tlHandleSub =>
      _t('Ægil legger til og bytter når du ber om det — du ser kvittering og betaler', 'Ægil adds and swaps when you ask — you see a receipt and pay');
  static String get komIGang => _t('Kom i gang', 'Get started');

  // ── Onboarding (`agOb1`–`agOb5`, `agObSum`) ───────────────────────────────
  static String get hoppOverAlt => _t('Hopp over alt', 'Skip all');
  static String get hoppOver => _t('Hopp over', 'Skip');
  static String get neste => _t('Neste', 'Next');
  static String get ferdig => _t('Ferdig', 'Done');
  static String poeng(int n) => _t('+$n Ægil-poeng', '+$n Ægil points');
  static String get ob1 => _t('Hva pleier du å bestille?', 'What do you usually order?');
  static String get ob2 => _t('Hva liker du å spise?', 'What do you like to eat?');
  static String get ob3 => _t('Noen butikker du er glad i?', 'Any stores you love?');
  static String get ob4 => _t('Hvor mange er dere hjemme?', 'How many are you at home?');
  static String get ob5 => _t('Når spiser dere middag ute?', 'When do you eat dinner out?');
  static String get ob1Hint => _t('Velg så mange du vil — jeg husker alle', 'Pick as many as you like — I remember them all');
  static String get ob2Hint => _t('Da løfter jeg fram det som passer', 'Then I’ll bring forward what fits');
  static String get ob3Hint => _t('Jeg sier fra når de har tilbud', 'I’ll tell you when they have offers');
  static String get ob4Hint => _t('Kostholdet bruker jeg alltid, også når jeg handler', 'I always use the diet, also when I shop');
  static String get ob5Hint => _t('Så vet jeg når jeg skal foreslå noe', 'Then I know when to suggest something');
  static String get visFlere => _t('Vis flere butikker', 'Show more stores');
  static String get unngaar => _t('DETTE UNNGÅR JEG ALLTID', 'I ALWAYS AVOID THIS');
  static String get naarTilbud => _t('NÅR KAN JEG SI FRA OM TILBUD?', 'WHEN CAN I TELL YOU ABOUT OFFERS?');
  static String roligeTimer(String ro) => _t('Rolige timer $ro — da er jeg stille.', 'Quiet hours $ro — I stay quiet then.');
  static String get sumTittel => _t('Nå kjenner jeg deg litt!', 'Now I know you a little!');
  static String sumTekst(String s) => s.isEmpty ? _t('Ikke så mye ennå — jeg lærer av bestillingene dine.', 'Not much yet — I learn from your orders.') : '$s.';
  static String get minnetStartet => _t('Minnet er startet', 'Memory started');
  static String minnetLinje(int poeng, int linjer) => _t('+$poeng Ægil-poeng · $linjer linjer lagret', '+$poeng Ægil points · $linjer lines saved');
  static String get ingen => _t('ingen', 'no');
  static String get middag => _t('middag', 'dinner');
  static String get obToast =>
      _t('Jeg lærer resten av bestillingene dine. Alt jeg vet ligger under Det Ægil vet om deg.', 'I’ll learn the rest from your orders. Everything I know is under What Ægil knows about you.');
  static String get obFeil => _t('Fikk ikke lagret — prøv igjen', 'Couldn’t save — try again');

  static List<String> get kat => _en ? const ['Restaurant', 'Food & fish', 'Fashion', 'Interior', 'Gifts'] : const ['Restaurant', 'Mat & fisk', 'Mote', 'Interiør', 'Gaver'];
  static List<String> get mat => _en
      ? const ['Pizza', 'Sushi', 'Fish', 'Indian', 'Thai', 'Burger', 'Salad', 'Vegetarian', 'Home-made', 'Something else']
      : const ['Pizza', 'Sushi', 'Fisk', 'Indisk', 'Thai', 'Burger', 'Salat', 'Vegetar', 'Hjemmelaget', 'Noe annet'];
  static const List<String> hus = ['1', '2', '3–4', '5+'];
  static List<String> get kost => _en
      ? const ['Nuts', 'Gluten', 'Lactose', 'Shellfish', 'Vegetarian', 'Vegan', 'Halal', 'None']
      : const ['Nøtter', 'Gluten', 'Laktose', 'Skalldyr', 'Vegetar', 'Vegansk', 'Halal', 'Ingen'];
  static List<String> get dager => _en ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] : const ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];
  static List<String> get dagerLang =>
      _en ? const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] : const ['mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'];
  static List<String> get varsel => [pushAldri, pushDag, pushBra];

  // ── Alle butikker (`butArk`) ──────────────────────────────────────────────
  static String get alleButikker => _t('Alle butikker', 'All stores');
  static String butArkSub(int valgt, int n) => _t('$valgt valgt · $n i Bergen', '$valgt chosen · $n in Bergen');
  static String get alle => _t('Alle', 'All');
  static String km(double km) => km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  static String min(int m) => '$m min';

  // ── Basket strip and composer ─────────────────────────────────────────────
  static String kurvAnt(int n) => _t('Kurv · ${varer(n)}', 'Basket · ${varer(n)}');
  static String innen(String hhmm) => _t('Innen $hhmm', 'By $hhmm');
  static String get betalVipps => _t('Betal med Vipps', 'Pay with Vipps');
  static String get promptStart => _t('Si hva du trenger i kveld', 'Say what you need tonight');
  static String get promptEndre => _t('Skriv hva du vil endre', 'Write what you want to change');
  static String get promptChat => _t('Skriv til Ægil …', 'Write to Ægil …');
  static String get sendTil => _t('Send til Ægil', 'Send to Ægil');
  static String get snakk => _t('Snakk med Ægil', 'Talk to Ægil');
  static String get stemme =>
      _t('Stemme: hold inne for å snakke — teksten vises før Ægil gjør noe', 'Voice: hold to talk — the text shows before Ægil does anything');

  // ── Ægil-guide (L9495, `gTips`) ───────────────────────────────────────────
  static String get gNeste => _t('Neste', 'Next');
  static String get gSkjonner => _t('Skjønner', 'Got it');
  static String get gSpor => _t('Spør Ægil', 'Ask Ægil');
  static String get gUtforsk => _t('Utforsk', 'Explore');
  static String get gUtforsk1 =>
      _t('Her ser du det ferskeste fra butikkene rundt deg. Trykk på et innlegg for å se butikken.', 'Here’s the freshest from the stores around you. Tap a post to see the store.');
  static String get gUtforsk2 => _t('Følg butikkene du liker. Da kommer de først i feeden din.', 'Follow the stores you like. Then they come first in your feed.');
  static String get gUtforsk3 => _t('Vil du ha noe bestemt? Spør meg, så finner jeg det.', 'Want something specific? Ask me and I’ll find it.');
  static String get gKategori => _t('Kategori', 'Category');
  static String get gKategori1 => _t('Her er butikkene som leverer til deg nå. De nærmeste står først.', 'These are the stores delivering to you now. The nearest come first.');
  static String get gKategori2 => _t('Trykk på en butikk for å se hele menyen.', 'Tap a store to see the whole menu.');
  static String get gButikk => _t('Butikken', 'The store');
  static String get gButikk1 => _t('Trykk + ved en rett for å legge den i kurven.', 'Tap + next to a dish to add it to the basket.');
  static String gButikk2(int over) => _t('Over $over kr blir leveringen gratis. Jeg sier fra når du er der.', 'Over $over kr delivery is free. I’ll tell you when you’re there.');
  static String get gButikkGratis => _t('Du har gratis levering nå. Bra handlet.', 'You have free delivery now. Nice shopping.');
  static String get gKurv => _t('Kurven', 'The basket');
  static String get gKurvTom => _t('Kurven er tom ennå. Skal jeg finne noe godt til deg?', 'The basket is still empty. Shall I find something nice for you?');
  static String gKurvIgjen(int kr) => _t('Du er $kr kr fra gratis levering. Legg til litt, så slipper du frakten.', 'You’re $kr kr from free delivery. Add a little and skip the fee.');
  static String get gKurvGratis => _t('Gratis levering er låst opp. Betal, så ror jeg av gårde med en gang.', 'Free delivery is unlocked. Pay and I’ll row off right away.');
  static String get gKurv2 => _t('Du kan endre adresse og leveringstid før du betaler.', 'You can change address and delivery time before you pay.');

  static String _stor(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  static String _kr(int n) => n >= 1000 ? '${n ~/ 1000} ${(n % 1000).toString().padLeft(3, '0')}' : '$n';
}
