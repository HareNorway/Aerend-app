// ignore_for_file: non_constant_identifier_names

import '../../../utils/utils.dart';
import '../kasse/kasse_copy.dart';

/// Copy for Hurtigbestilling (`Ærend Kunde Launch.dc.html` L4245–4520 and the
/// `hb*` handlers ≈L14790–15160). Norwegian exactly as the prototype writes
/// it; English for the language switch.
abstract final class HurtigCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String kr(num v) => KasseCopy.kr(v);

  // ── header ──────────────────────────────────────────────────────────────
  static String get tilbake => _t('Tilbake', 'Back');
  static String laert(int n) => _t('Kjenner $n ${n == 1 ? 'bestilling' : 'bestillinger'}', 'Knows $n ${n == 1 ? 'order' : 'orders'}');
  static String get kicker => _t('ÆGIL BESTILLER FOR DEG', 'ÆGIL ORDERS FOR YOU');
  static String get tittel => _t('Hurtigbestilling', 'Quick order');
  static String get under => _t('Si hva du vil ha, eller velg under. Jeg kjenner vanene dine og ordner resten.', 'Say what you want, or pick below. I know your habits and handle the rest.');

  // ── context ─────────────────────────────────────────────────────────────
  static String get tarHensyn => _t('ÆGIL TAR HENSYN TIL', 'ÆGIL TAKES INTO ACCOUNT');
  static String get startPaaNytt => _t('Start på nytt', 'Start over');
  static String personer(int n) => _t('$n ${n == 1 ? 'person' : 'personer'}', '$n ${n == 1 ? 'person' : 'people'}');
  static String get vipps => 'Vipps';
  static String get sjekkerVanene => _t('Sjekker vanene dine', 'Checking your habits');

  // ── module cards ────────────────────────────────────────────────────────
  static String get oftestBestilt => _t('OFTEST BESTILT', 'MOST ORDERED');
  static String oftUnder(int n, String maaned) => _t('$n bestillinger siden $maaned', '$n orders since $maaned');
  static String ganger(int n) => _t('$n ${n == 1 ? 'gang' : 'ganger'}', '$n ${n == 1 ? 'time' : 'times'}');
  static String get leggIUtkastet => _t('Legg i utkastet', 'Add to the draft');
  static String get fjernFraUtkastet => _t('Fjern fra utkastet', 'Remove from the draft');
  static String get settOpp => _t('Sett opp', 'Set up');
  static String dagsfavoritt(String dag) => _t('${dag}SFAVORITTEN', '$dag FAVOURITE').toUpperCase();
  static String get dinFavoritt => _t('DIN FAVORITT', 'YOUR FAVOURITE');
  static String kl(String t) => _t('kl $t', 'at $t');

  static String get bestiltForrigeGang => _t('BESTILT FORRIGE GANG', 'ORDERED LAST TIME');
  static String get levert => _t('LEVERT', 'DELIVERED');
  static String get betalt => _t('Betalt', 'Paid');
  static String get bestillDetSammeIgjen => _t('Bestill det samme igjen', 'Order the same again');
  static String get tidligere => _t('TIDLIGERE', 'EARLIER');
  static String get igjen => _t('Igjen', 'Again');
  static String get bestillIgjen => _t('Bestill igjen', 'Order again');

  static String get dinePreferanser => _t('DINE PREFERANSER', 'YOUR PREFERENCES');
  static String laertAv(int n) => _t('Lært av $n bestillinger', 'Learned from $n orders');
  static String get liker => _t('Liker', 'Likes');
  static String get butikker => _t('Butikker', 'Shops');
  static String get husstand => _t('Husstand', 'Household');
  static String get faerre => _t('Færre', 'Fewer');
  static String get flere => _t('Flere', 'More');
  static String get allergier => _t('Allergier', 'Allergies');
  static String get unngaarSkalldyr => _t('Unngår skalldyr', 'Avoids shellfish');
  static String get skalldyrOk => _t('Skalldyr er ok', 'Shellfish is fine');
  static String get trykkForAaEndre => _t('Trykk for å endre', 'Tap to change');
  static String get middag => _t('Middag', 'Dinner');
  static String rundt(String dager, String kl) => _t('$dager · rundt $kl', '$dager · around $kl');
  static String get betaling => _t('Betaling', 'Payment');
  static String get vippsPaaDora => _t('Vipps · på døra med kode', 'Vipps · at the door with a code');
  static String get foreslaarIKveld => _t('ÆGIL FORESLÅR I KVELD', 'ÆGIL SUGGESTS TONIGHT');
  static String settOppSum(String kr) => _t('Sett opp · $kr', 'Set up · $kr');
  static String get endreDetAegilVet => _t('Endre det Ægil vet om deg', 'Change what Ægil knows about you');

  // ── new Bergen: the dark cards (L4264–4431) ─────────────────────────────
  static String get leggTilKnapp => _t('Legg til', 'Add');
  static String get lagtTilKnapp => _t('Lagt til', 'Added');
  static String get dinFavorittChip => _t('Din favoritt', 'Your favourite');
  static String get levertChip => _t('Levert', 'Delivered');
  static String get slikKjenner => _t('Slik kjenner Ægil deg', 'How Ægil knows you');
  static String get endre => _t('Endre', 'Edit');
  static String get duLikerKicker => _t('DU LIKER', 'YOU LIKE');
  static String get favorittbutikker => _t('Favorittbutikker', 'Favourite shops');
  static String lagret(int n) => _t('$n lagret', '$n saved');
  static String personOrd(int n) => _t(n == 1 ? 'person' : 'personer', n == 1 ? 'person' : 'people');
  static String get unngaarKicker => _t('UNNGÅR', 'AVOIDS');
  static String get tillattKicker => _t('TILLATT', 'ALLOWED');
  static String get skalldyr => _t('Skalldyr', 'Shellfish');
  static String get holdesUnna => _t('Holdes unna forslagene', 'Kept out of the suggestions');
  static String get kanKomme => _t('Kan komme i forslagene', 'Can come up in the suggestions');
  static String get middagsrytme => _t('Middagsrytme', 'Dinner rhythm');
  static String rundtKl(String kl) => _t('rundt kl $kl', 'around $kl');
  static String get iDagKicker => _t('I DAG', 'TODAY');
  static String dagKort(int i) => (_en ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] : const ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'])[i];
  static String retter(int n) => _t('$n ${n == 1 ? 'rett' : 'retter'}', '$n ${n == 1 ? 'dish' : 'dishes'}');
  static String erMiddagsdag(String dag) => _t('$dag er middagsdag', '$dag is dinner day');
  static String duLiker(String hva) => _t('Du liker $hva', 'You like $hva');
  static String get regnNoeVarmt => _t('Regn, noe varmt', 'Rain, something warm');
  static String get utenSkalldyr => _t('Uten skalldyr', 'Without shellfish');
  static String get rekerErOk => _t('Reker er ok', 'Shrimp is fine');

  static String bestiltKode(String kode) => _t('BESTILT · $kode', 'ORDERED · $kode');
  static String get folgBestillingen => _t('Følg bestillingen', 'Follow the order');
  static String aerendKroner(int n) => _t('+$n Ærend-kroner', '+$n Ærend kroner');

  // ── the draft ───────────────────────────────────────────────────────────
  static String get aegilsUtkast => _t('ÆGILS UTKAST', 'ÆGIL\'S DRAFT');
  static String hosDegCa(String t) => _t('Hos deg ca. $t', 'At yours around $t');
  static String leveringTid(String t) => _t('Levering $t', 'Delivery $t');
  static String perStk(String kr) => _t('$kr / stk', '$kr each');
  static String get varer => _t('Varer', 'Items');
  static String get snarest => _t('Snarest', 'Soonest');
  // Design 21 Nov plan Step 4 (A1): the draft hands over to the checkout.
  static String get passerTil => _t('Passer til', 'Goes with');
  static String get aegilForeslaar => _t('Ægil foreslår', 'Ægil suggests');
  static String get gratisLevering => _t('Gratis levering', 'Free delivery');
  static String tilGratisLevering(String kr) => _t('$kr til gratis levering', '$kr to free delivery');
  static String kasseTekst(String? tid) => _t('Levering, tid og betaling velger du i kassen${tid != null ? ' · ønsket tid $tid' : ''}.', 'Delivery, time and payment are chosen at checkout${tid != null ? ' · wanted time $tid' : ''}.');
  static String gaaTilKassen(String kr) => _t('Gå til kassen · $kr', 'Go to checkout · $kr');
  static String get ingentingBestilles => _t('Ingenting bestilles før du bekrefter i kassen', 'Nothing is ordered before you confirm at checkout');
  static String lagtIKassen(String linjer, String butikk) => _t('Lagt i kassen: $linjer fra $butikk. Der velger du levering, tid og betaling.', 'In the checkout: $linjer from $butikk. Pick delivery, time and payment there.');
  static String get tilKassen => _t('Til kassen', 'To checkout');
  static String liggerIKassen(int n, String butikk) => _t('$n ${n == 1 ? 'vare' : 'varer'} fra $butikk ligger i kassen', '$n ${n == 1 ? 'item' : 'items'} from $butikk in the checkout');
  static String get daLeggerJeg => _t('Da legger jeg det i kassen. Der ser du over levering og betaling før du bestiller.', 'Then I\'ll put it in the checkout. You check delivery and payment there before you order.');
  static String get leggerIKassen => _t(' Jeg legger det i kassen, så bekrefter du der.', ' I\'ll put it in the checkout and you confirm there.');
  static String klokken(String t) => _t('Kl. $t', 'At $t');

  // ── bottom bar ──────────────────────────────────────────────────────────
  static String get modOftest => _t('Oftest bestilt', 'Most ordered');
  static String get modForrige => _t('Bestilt forrige gang', 'Ordered last time');
  static String get modPref => _t('Dine preferanser', 'Your preferences');
  static String get placeholder => _t('Si hva du vil ha, f.eks. «det vanlige»', 'Say what you want, e.g. "the usual"');
  static String get skrivTilAegil => _t('Skriv til Ægil', 'Write to Ægil');
  static String get sendTilAegil => _t('Send til Ægil', 'Send to Ægil');

  // ── module questions (HB_MODTEKST) ──────────────────────────────────────
  static String get spOftest => _t('Hva bestiller jeg oftest?', 'What do I order most?');
  static String get spForrige => _t('Hva bestilte jeg forrige gang?', 'What did I order last time?');
  static String get spPref => _t('Vis preferansene mine', 'Show my preferences');

  // ── Ægil's lines ────────────────────────────────────────────────────────
  static String velkomst(String dag, String navn, String linjer, String butikk) => _t(
    '$dag igjen, $navn! Du pleier å ta $linjer fra $butikk rundt nå. Skal jeg sette det opp?',
    '$dag again, $navn! You usually get $linjer from $butikk about now. Shall I set it up?',
  );
  static String velkomstTom(String navn) => _t(
    'Hei, $navn! Jeg kjenner ikke vanene dine ennå. Si hva du har lyst på, så setter jeg opp bestillingen.',
    'Hi, $navn! I don\'t know your habits yet. Tell me what you feel like and I\'ll set up the order.',
  );
  static String jaDetVanlige(String kr) => _t('Ja, det vanlige · $kr', 'Yes, the usual · $kr');
  static String get noeAnnet => _t('Noe annet', 'Something else');
  static String get detVanlige => _t('Det vanlige', 'The usual');
  static String get hvaForeslaarDu => _t('Hva foreslår du?', 'What do you suggest?');
  static String get sammeSomSist => _t('Samme som sist', 'Same as last time');
  static String get neiTakk => _t('Nei takk', 'No thanks');
  static String get jaLikevel => _t('Ja, likevel', 'Yes, anyway');
  static String get neiLaVaere => _t('Nei, la være', 'No, leave it');
  static String get angreBytte => _t('Angre bytte', 'Undo switch');
  static String get finnNoeBilligere => _t('Finn noe billigere', 'Find something cheaper');
  static String get foreslaaNoeAnnet => _t('Foreslå noe annet', 'Suggest something else');
  static String jaTa(String vare) => _t('Ja, ta $vare', 'Yes, get $vare');

  static String oftestSvar(String a, String aB, String? b, String? bB) => _t(
    '$a fra $aB er favoritten din${b != null ? ', tett fulgt av $b fra $bB' : ''}. Trykk på pluss, så legger jeg det i utkastet.',
    '$a from $aB is your favourite${b != null ? ', closely followed by $b from $bB' : ''}. Tap plus and I\'ll put it in the draft.',
  );
  static String forrigeSvar(String dato, String linjer, String butikk) => _t(
    'Sist var $dato: $linjer fra $butikk. Vil du ha det samme igjen?',
    'Last time was $dato: $linjer from $butikk. Want the same again?',
  );
  static String prefSvar(String linjer, String butikk) => _t(
    'Dette har jeg lært om deg. Ut fra det ville jeg tatt $linjer fra $butikk i kveld.',
    'This is what I\'ve learned about you. Based on it I\'d get $linjer from $butikk tonight.',
  );
  static String get ingenHistorikk => _t('Jeg har ingen bestillinger å gå ut fra ennå. Si hva du har lyst på, så setter jeg det opp.', 'I have no orders to go by yet. Tell me what you feel like and I\'ll set it up.');
  static String vanligSvar(String dag, String linjer, String butikk) => _t(
    'Det vanlige på en $dag er $linjer fra $butikk. Utkastet er klart.',
    'The usual on a $dag is $linjer from $butikk. The draft is ready.',
  );
  static String sammeSomSvar(String dato, String linjer, String butikk) => _t(
    'Samme som $dato, altså $linjer fra $butikk.',
    'Same as $dato, that is $linjer from $butikk.',
  );
  static String prefSattOpp(String linjer, String butikk) => _t(
    'Jeg har satt opp $linjer fra $butikk. Det passer med det jeg vet om deg.',
    'I\'ve set up $linjer from $butikk. It fits what I know about you.',
  );
  static String get heisann => _t(
    'Heisann! Si «det vanlige», «samme som sist» eller bare hva du har lyst på, så setter jeg opp bestillingen.',
    'Hi there! Say "the usual", "same as last time" or just what you feel like, and I\'ll set up the order.',
  );
  static String get bareHyggelig => _t('Bare hyggelig! Si fra hvis du vil ha noe mer.', 'You\'re welcome! Say so if you want anything else.');
  static String get ikkeIUtkastet => _t('Det står ikke i utkastet, så alt er som før.', 'That isn\'t in the draft, so everything is as before.');
  static String fjernet(String hva) => _t('Fjernet $hva.', 'Removed $hva.');
  static String fjernetTomt(String hva) => _t('Fjernet $hva. Nå er utkastet tomt. Hva vil du ha i stedet?', 'Removed $hva. The draft is empty now. What would you like instead?');
  static String stengt(String butikk, String aapner, String alt, String altVare) => _t(
    '$butikk er stengt nå og $aapner. $alt er åpen. Vil du ha $altVare derfra?',
    '$butikk is closed now and $aapner. $alt is open. Want $altVare from there?',
  );
  static String stengtIngenAlt(String butikk, String aapner) => _t(
    '$butikk er stengt nå og $aapner. Si fra hvis du vil ha noe annet.',
    '$butikk is closed now and $aapner. Say so if you want something else.',
  );
  static String aapnerKl(String t) => _t('åpner kl. $t', 'opens at $t');
  static String get aapnerSenere => _t('åpner senere', 'opens later');
  static String skalldyrLikevel(String vare) => _t(
    'Du har bedt meg unngå skalldyr. Skal jeg legge til $vare likevel?',
    'You asked me to avoid shellfish. Shall I add $vare anyway?',
  );
  static String lagtInn(String vare, String butikk) => _t('Lagt inn: $vare fra $butikk.', 'Added: $vare from $butikk.');
  static String byttet(String ny, String gammel) => _t(
    'Byttet til $ny. Det er én butikk per bestilling, så utkastet fra $gammel er lagt til side.',
    'Switched to $ny. It\'s one shop per order, so the draft from $gammel is set aside.',
  );
  static String tilbakeTil(String butikk) => _t('Tilbake til $butikk.', 'Back to $butikk.');
  static String get lagtTil => _t('Lagt til: ', 'Added: ');
  static String get sattOpp => _t('Satt opp: ', 'Set up: ');
  static String fra(String butikk) => _t(' fra $butikk.', ' from $butikk.');
  static String duPleierAaTa(String n) => _t(' Du pleier å ta $n.', ' You usually take $n.');
  static String lagtTilSide(String butikk) => _t(' Utkastet fra $butikk er lagt til side.', ' The draft from $butikk is set aside.');
  static String finnesBareHos(String vare, String butikk) => _t(
    ' $vare finnes bare hos $butikk, så den må bli en egen bestilling.',
    ' $vare is only at $butikk, so it has to be a separate order.',
  );
  static String billigereIkke(String kr) => _t(
    'Billigere enn $kr blir det ikke uten å fjerne hovedretten. Vil du at jeg finner noe annet?',
    'It won\'t get cheaper than $kr without removing the main. Want me to find something else?',
  );
  static String naaErDet(String ny, String fra, bool kanIkkeLavere) => _t(
    'Nå er det $ny i stedet for $fra.${kanIkkeLavere ? ' Lavere klarer jeg ikke uten å fjerne hovedretten.' : ''}',
    'Now it\'s $ny instead of $fra.${kanIkkeLavere ? ' I can\'t go lower without removing the main.' : ''}',
  );
  static String rimeligste(String vare, String butikk) => _t(
    '$vare fra $butikk er den rimeligste middagen du pleier å ta.',
    '$vare from $butikk is the cheapest dinner you usually get.',
  );
  static String notertTid(String tid) => _t('Notert. Jeg ber om levering $tid.', 'Noted. I\'ll ask for delivery $tid.');
  static String leveringNaa(String klar, bool gratis, String frakt, String over) => _t(
    'Bestiller du nå, er det $klar. ${gratis ? 'Leveringen er gratis.' : 'Levering koster $frakt, men er gratis over $over.'}',
    'If you order now, it\'s $klar. ${gratis ? 'Delivery is free.' : 'Delivery costs $frakt, but is free over $over.'}',
  );
  static String leveringUten(String butikk, int min) => _t(
    'Det kommer an på butikken. $butikk bruker rundt $min minutter i kveld.',
    'It depends on the shop. $butikk takes about $min minutes tonight.',
  );
  static String get greitLarDetVaere => _t('Greit, jeg lar det være.', 'Fine, I\'ll leave it.');
  static String get fikkIkke => _t(
    'Den fikk jeg ikke helt. Prøv «det vanlige» eller «samme som sist», eller si en rett, for eksempel «pad thai for to».',
    'I didn\'t quite get that. Try "the usual" or "same as last time", or name a dish, for example "pad thai for two".',
  );
  static String bestiltSvar(String butikk) => _t(
    'Bestilt! $butikk har fått ordren, og budet er varslet. Jeg sier fra når maten er på vei.',
    'Ordered! $butikk has the order and the courier is notified. I\'ll tell you when the food is on its way.',
  );
  static String bestiltToast(String kode) => _t('Bestilt · $kode', 'Ordered · $kode');
  static String get sattOppVane => _t('Satt opp! ', 'Set up! ');
  static String liggerIUtkastet(String hva) => _t('$hva ligger i utkastet.', '$hva is in the draft.');
  static String sammeSomLigger(String dato) => _t('Samme som $dato ligger i utkastet.', 'Same as $dato is in the draft.');
  static String get sattOppEtterPref => _t('Satt opp etter preferansene dine. Du kan justere alt i utkastet.', 'Set up from your preferences. You can adjust everything in the draft.');

  // ── days and dates ──────────────────────────────────────────────────────
  static const List<String> dagerNo = ['mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'];
  static const List<String> dagerEn = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  static const List<String> maanederNo = ['januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'];
  static const List<String> maanederEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  /// `tirsdag`, lower case (DateTime.weekday 1 = Monday).
  static String dag(int weekday) => (_en ? dagerEn : dagerNo)[(weekday - 1).clamp(0, 6)];
  static String maaned(int month) => (_en ? maanederEn : maanederNo)[(month - 1).clamp(0, 11)];
  static String forrige(String dag) => _t('forrige $dag', 'last $dag');
  static String get iDag => _t('i dag', 'today');
  static String get iGaar => _t('i går', 'yesterday');
  static String datoDag(int d, String m) => _t('$d. $m', '$d $m');
  static String get og => _t(' og ', ' and ');

  /// The prototype's number words (`ORD`).
  static const List<String> ord = ['', 'én', 'to', 'tre', 'fire', 'fem', 'seks'];
}
