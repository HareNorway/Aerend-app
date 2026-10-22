// ignore_for_file: non_constant_identifier_names
import '../../../utils/utils.dart';

/// Customer plan Step 14: every line of the AI-assistant feature (design
/// §4d: `aiInngang`, `aiVelg`, `aiQr`, `aiSamtykke`, `aiKoblet`,
/// `aiKoblede`, `aiDetalj`, `aiKobleFra`, `aiFeil`, `aiBekreft`, the
/// «Handlekurv fra assistent» screen, the overlays, the chips and the
/// Varsler items). Keys `cus_ai_*`; Norwegian first, English beside it.
abstract final class AiCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String nf(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return (n < 0 ? '-' : '') + b.toString();
  }

  static String kr(int n) => '${nf(n)} kr';

  // Entry points
  static String get cus_ai_hurtig_logo => _t('Bestill med Claude eller ChatGPT', 'Order with Claude or ChatGPT');
  static String get cus_ai_hurtig_rad => _t('Bestill med en annen AI', 'Order with another AI');
  static String cus_ai_hurtig_sub_koblet(String navn) => _t('$navn er koblet · du bekrefter her', '$navn is linked · you confirm here');
  static String get cus_ai_hurtig_sub => _t('Claude, ChatGPT eller Gemini · du bekrefter her', 'Claude, ChatGPT or Gemini · you confirm here');
  static String get cus_ai_meg_rad => _t('Bestill via AI-assistent', 'Order through an AI assistant');
  static String get cus_ai_meg_rad_sub => _t('Claude, ChatGPT, Gemini og Siri · alltid med din bekreftelse', 'Claude, ChatGPT, Gemini and Siri · always with your confirmation');
  static String get cus_ai_meg_koblede => _t('Koblede assistenter', 'Linked assistants');
  static String cus_ai_meg_koblede_sub(int n) => n == 0 ? _t('Ingen koblet ennå', 'None linked yet') : (n == 1 ? _t('1 aktiv', '1 active') : _t('$n aktive', '$n active'));

  // aiInngang
  static String get cus_ai_inngang_tittel => _t('Bestill der du allerede er', 'Order where you already are');
  static String get cus_ai_inngang_linje => _t('Spør assistenten du bruker. Du bekrefter alltid her i Ærend.', 'Ask the assistant you use. You always confirm here in Ærend.');
  static String get cus_ai_inngang_aegil => _t('Jeg hjelper deg her i appen. Claude, ChatGPT og Gemini kan bestille gjennom Ærend – alltid med din bekreftelse.', 'I help you here in the app. Claude, ChatGPT and Gemini can order through Ærend – always with your confirmation.');
  static String get cus_ai_stottede => _t('Støttede assistenter', 'Supported assistants');
  static String get cus_ai_koblet => _t('Koblet', 'Linked');
  static String get cus_ai_ikke_koblet => _t('Ikke koblet', 'Not linked');
  static String get cus_ai_snarveier => _t('Snarveier', 'Shortcuts');
  static String get cus_ai_snarvei => _t('Snarvei', 'Shortcut');
  static String cus_ai_allerede_koblet(String navn) => _t('$navn er allerede koblet til', '$navn is already linked');
  static String get cus_ai_se_rettigheter => _t('Se rettigheter', 'See permissions');
  static String get cus_ai_slik_fungerer => _t('Slik fungerer det', 'How it works');
  static String cus_ai_fl1(String navn) => _t('Du spør $navn', 'You ask $navn');
  static String get cus_ai_fl2 => _t('Ærend lager et tilbud', 'Ærend makes an offer');
  static String get cus_ai_fl3 => _t('Du bekrefter her', 'You confirm here');
  static String cus_ai_steg_tittel(String navn) => _t('Slik kobler du til $navn', 'How to link $navn');
  static List<String> cus_ai_steg(String navn) => [
    _t('Åpne $navn og legg til Ærend som kobling.', 'Open $navn and add Ærend as a connector.'),
    _t('Logg inn med Ærend-kontoen din og velg hva $navn får lov til.', 'Sign in with your Ærend account and choose what $navn may do.'),
    _t('Be $navn om å bestille. Du bekrefter alltid i Ærend før noe sendes.', 'Ask $navn to order. You always confirm in Ærend before anything is sent.'),
  ];
  static List<String> get cus_ai_steg_siri => [
    _t('Si «Bestill det vanlige med Ærend».', 'Say «Order the usual with Ærend».'),
    _t('Siri åpner Ærend med handlekurven klar.', 'Siri opens Ærend with the cart ready.'),
    _t('Du bekrefter i appen før noe sendes.', 'You confirm in the app before anything is sent.'),
  ];
  static String get cus_ai_steg_hint => _t('Trykk når steget er gjort', 'Tap when the step is done');
  static String get cus_ai_steg_hint_sist => _t('Trykk når du er klar', 'Tap when you are ready');
  static String get cus_ai_klart => _t('Klart · du bekrefter alltid i Ærend', 'Ready · you always confirm in Ærend');
  static String cus_ai_hva_ser(String navn) => _t('Hva $navn ser', 'What $navn sees');
  static String get cus_ai_kan_se => _t('Kan se', 'Can see');
  static String get cus_ai_ser_aldri => _t('Ser aldri', 'Never sees');
  static List<String> get cus_ai_kan_se_liste => [_t('Menyer og priser', 'Menus and prices'), _t('Dine bestillinger', 'Your orders'), _t('Dine adresser', 'Your addresses')];
  static List<String> get cus_ai_ser_aldri_liste => [_t('Betalingskortet ditt', 'Your payment card'), _t('Andre personers opplysninger', 'Other people\'s details')];
  static String get cus_ai_les_mer => _t('Les mer om personvern', 'Read more about privacy');
  static String get cus_ai_bruk_siri => _t('Bruk Siri', 'Use Siri');
  static String get cus_ai_siri_linje => _t('Si «Bestill det vanlige med Ærend», så bekrefter du i appen.', 'Say «Order the usual with Ærend», then confirm in the app.');
  static List<String> get cus_ai_siri_snarveier => [_t('Bestill det vanlige', 'Order the usual'), _t('Følg bestillingen', 'Track the order'), _t('Åpne handlekurven', 'Open the cart')];
  static String cus_ai_siri_antall(int n) => n == 0 ? _t('Trykk for å legge til', 'Tap to add') : _t('$n av 3 lagt til', '$n of 3 added');
  static String get cus_ai_siri_alle => _t('Legg til alle snarveier', 'Add all shortcuts');
  static String get cus_ai_siri_lagt => _t('Tre snarveier lagt til i Siri', 'Three shortcuts added to Siri');
  static String cus_ai_snarvei_lagt(String s) => _t('Snarvei lagt til · «$s»', 'Shortcut added · «$s»');
  static String get cus_ai_snarvei_fjernet => _t('Fjernet snarvei', 'Shortcut removed');
  static String cus_ai_koble_til(String navn) => _t('Koble til $navn', 'Link $navn');
  static String get cus_ai_vis_qr => _t('Vis QR-kode', 'Show QR code');
  static String get cus_ai_bekrefter_alltid => _t('Du bekrefter alltid i Ærend', 'You always confirm in Ærend');
  static String get cus_ai_menyer_synlige => _t('Menyer og priser er alltid synlige', 'Menus and prices are always visible');

  // aiVelg
  static String get cus_ai_velg_tittel => _t('Bestill med en annen AI', 'Order with another AI');
  static String get cus_ai_velg_linje => _t('Assistenten bygger handlekurven. Du bekrefter alltid prisen her i Ærend.', 'The assistant builds the cart. You always confirm the price here in Ærend.');
  static String cus_ai_velg_koblet_under(int kr, String bet) => _t('Maks ${nf(kr)} kr per bestilling · $bet', 'Max ${nf(kr)} kr per order · $bet');
  static String get cus_ai_velg_ukoblet_under => _t('Koble til på et halvt minutt', 'Link in half a minute');
  static String get cus_ai_velg_siri_under => _t('Si «Bestill det vanlige med Ærend»', 'Say «Order the usual with Ærend»');
  static String get cus_ai_bestill => _t('Bestill', 'Order');
  static String get cus_ai_legg_til => _t('Legg til', 'Add');
  static String get cus_ai_koble => _t('Koble til', 'Link');
  static List<String> get cus_ai_velg_steg => [_t('Du spør assistenten', 'You ask the assistant'), _t('Ærend lager tilbudet', 'Ærend makes the offer'), _t('Du bekrefter her', 'You confirm here')];
  static String cus_ai_bestill_med(String navn) => _t('Bestill med $navn', 'Order with $navn');
  static String get cus_ai_lukk => _t('Lukk', 'Close');

  // aiQr
  static String cus_ai_qr_tittel(String navn) => _t('Koble til $navn', 'Link $navn');
  static String cus_ai_qr_linje_mobil(String navn) => _t('Har du $navn på denne mobilen? Vi hopper dit og tilbake. Ingen kode å skanne.', 'Have $navn on this phone? We hop there and back. No code to scan.');
  static String cus_ai_qr_linje_qr(String navn) => _t('Skann koden med mobilen eller nettbrettet der du bruker $navn.', 'Scan the code with the phone or tablet where you use $navn.');
  static String get cus_ai_paa_mobilen => _t('På denne mobilen', 'On this phone');
  static String get cus_ai_annen_enhet => _t('Annen enhet', 'Another device');
  static String get cus_ai_begge_appene => _t('Begge appene på denne mobilen · ingen skanning', 'Both apps on this phone · no scanning');
  static String get cus_ai_eller_kode => _t('Eller bruk en kode', 'Or use a code');
  static String cus_ai_gyldig_min(int m) => _t('Gyldig i $m min', 'Valid for $m min');
  static String cus_ai_lim_inn(String navn) => _t('Lim inn koden i $navn når den ber om det. Fungerer også hvis $navn ikke åpner seg av seg selv.', 'Paste the code into $navn when it asks. Also works if $navn does not open by itself.');
  static String get cus_ai_kopier_kode => _t('Kopier kode', 'Copy code');
  static String get cus_ai_kopiert => _t('Kopiert', 'Copied');
  static String cus_ai_kode_kopiert(String kode, String navn) => _t('Koden $kode er kopiert · lim den inn i $navn', 'Code $kode copied · paste it into $navn');
  static String cus_ai_lenke_kopiert(String navn) => _t('Lenken er kopiert · åpne den i $navn', 'Link copied · open it in $navn');
  static String cus_ai_venter(String navn) => _t('Venter på at $navn bruker koden …', 'Waiting for $navn to use the code …');
  static String cus_ai_brukte_koden(String navn) => _t('$navn brukte koden', '$navn used the code');
  static String cus_ai_kode_for(String navn, int m) => _t('Kode for $navn · gyldig i $m minutter', 'Code for $navn · valid for $m minutes');
  static List<String> cus_ai_qr_steg_mobil(String navn) => [_t('Trykk «Åpne $navn»', 'Tap «Open $navn»'), _t('Godkjenn i $navn', 'Approve in $navn'), _t('Velg rettigheter her', 'Choose permissions here')];
  static List<String> cus_ai_qr_steg_qr(String navn) => [_t('Åpne $navn på den andre enheten', 'Open $navn on the other device'), _t('Skann koden', 'Scan the code'), _t('Velg rettigheter her', 'Choose permissions here')];
  static String cus_ai_apne(String navn) => _t('Åpne $navn', 'Open $navn');
  static String get cus_ai_jeg_har_skannet => _t('Jeg har skannet', 'I have scanned');
  static String get cus_ai_tilbake => _t('Tilbake', 'Back');
  static String get cus_ai_kode_feil => _t('Fikk ikke laget en kode. Prøv igjen.', 'Could not make a code. Try again.');
  static String get cus_ai_kode_utlopt => _t('Koden utløp · lag en ny', 'The code expired · make a new one');

  // aiSamtykke / rights
  static String cus_ai_sam_tittel(String navn) => _t('$navn ber om tilgang til Ærend-kontoen din', '$navn asks for access to your Ærend account');
  static String cus_ai_sam_linje(String navn) => _t('Du bestemmer hva $navn får gjøre. Du kan endre eller koble fra når som helst.', 'You decide what $navn may do. You can change or unlink at any time.');
  static String cus_ai_sam_samtykke(String navn) => _t('Ved å koble til godtar du at Ærend deler opplysningene over med $navn på dine vegne.', 'By linking you agree that Ærend shares the details above with $navn on your behalf.');
  static String get cus_ai_venter_svar => _t('Venter på svaret ditt', 'Waiting for your answer');
  static String get cus_ai_logg_inn_forst => _t('Logg inn først', 'Sign in first');
  static String get cus_ai_logg_tittel => _t('Logg inn for å fortsette', 'Sign in to continue');
  static String get cus_ai_logg_linje => _t('Du kommer tilbake hit etter innlogging.', 'You come back here after signing in.');
  static String cus_ai_logg_tx(String navn) => _t('$navn ber om tilgang til Ærend-kontoen din', '$navn asks for access to your Ærend account');
  static String get cus_ai_logg_under => _t('Logg inn med Vipps eller Ærend-kontoen din. Ingenting deles før du har valgt rettigheter.', 'Sign in with Vipps or your Ærend account. Nothing is shared before you choose permissions.');
  static String get cus_ai_logg_vipps => _t('Logg inn med Vipps', 'Sign in with Vipps');
  static String get cus_ai_logg_inn => _t('Logg inn', 'Sign in');
  static String get cus_ai_avbryt => _t('Avbryt', 'Cancel');
  static String cus_ai_rett_tittel(String navn) => _t('Dette kan $navn gjøre', 'This is what $navn can do');
  static String cus_ai_rett_antall(int n) => _t('$n av 6 på', '$n of 6 on');
  static String get cus_ai_alltid_paa => _t('Alltid på', 'Always on');
  static String get cus_ai_paakrevd => _t('Påkrevd', 'Required');
  static List<List<String>> get cus_ai_rett => [
    [_t('Se menyer og priser', 'See menus and prices'), _t('Det samme som alle ser i appen', 'The same as everyone sees in the app')],
    [_t('Bygge handlekurv for deg', 'Build a cart for you'), _t('Du ser alltid kurven før noe sendes', 'You always see the cart before anything is sent')],
    [_t('Se bestillingene dine', 'See your orders'), _t('Status og tidligere ordrer', 'Status and earlier orders')],
    [_t('Bestille for deg – alltid med din bekreftelse', 'Order for you – always with your confirmation'), _t('Kan ikke slås av', 'Cannot be switched off')],
    [_t('Bruke adressene og favorittene dine', 'Use your addresses and favourites'), _t('Hjemme, Jobb og favorittbutikker', 'Home, Work and favourite stores')],
    [_t('Åpne en supportsak for deg', 'Open a support case for you'), _t('Når noe mangler eller er feil', 'When something is missing or wrong')],
  ];
  static String get cus_ai_dine_grenser => _t('Dine grenser', 'Your limits');
  static String cus_ai_grense_tittel(String navn) => _t('$navn går aldri over disse', '$navn never goes above these');
  static String get cus_ai_maks_per_best => _t('Maks per bestilling', 'Max per order');
  static String get cus_ai_maks_per_dag => _t('Maks per dag', 'Max per day');
  static String cus_ai_forslag(int kr) => _t('Forslag: ${nf(kr)} kr', 'Suggested: ${nf(kr)} kr');
  static String get cus_ai_betaling => _t('Betaling', 'Payment');
  static String get cus_ai_betaling_under => _t('Brukes når assistenten ber om å bestille', 'Used when the assistant asks to order');
  static String get cus_ai_vipps => 'Vipps';
  static String get cus_ai_lagret_kort => _t('Lagret kort', 'Saved card');
  static String get cus_ai_spor_hver_gang => _t('Spør hver gang', 'Ask every time');
  static String get cus_ai_leveringsadresse => _t('Leveringsadresse', 'Delivery address');
  static String cus_ai_hjemme_er(String adr) => _t('Hjemme er $adr', 'Home is $adr');
  static String get cus_ai_hjemme => _t('Hjemme', 'Home');
  static String get cus_ai_del_bio => _t('Del matpreferansene mine fra Min bio', 'Share my food preferences from Min bio');
  static String cus_ai_bio_tx(String navn) => _t('Da kan $navn ta hensyn til allergener og preferanser når den foreslår mat. Opplysningene deles bare med $navn, og du kan slå det av når du vil.', 'Then $navn can take allergens and preferences into account when suggesting food. The details are shared only with $navn, and you can switch it off whenever you like.');
  static String cus_ai_grense_sum(int per, int dag) => _t('Maks ${nf(per)} kr · ${nf(dag)} kr per dag', 'Max ${nf(per)} kr · ${nf(dag)} kr per day');
  static String get cus_ai_per_best => _t('Per bestilling', 'Per order');
  static String get cus_ai_levering => _t('Levering', 'Delivery');

  // aiKoblet
  static String cus_ai_koblet_tittel(String navn) => _t('$navn er koblet til Ærend', '$navn is linked to Ærend');
  static String cus_ai_koblet_linje(String navn) => _t('$navn kan nå bygge handlekurv og foreslå bestillinger. Ingenting sendes før du har bekreftet i Ærend.', '$navn can now build a cart and suggest orders. Nothing is sent before you confirm in Ærend.');
  static String get cus_ai_koblet_naa => _t('Koblet nå', 'Linked now');
  static String get cus_ai_prov_naa => _t('Prøv nå', 'Try now');
  static String get cus_ai_prompt => _t('Bestill det vanlige fra Torgboden til i morgen tidlig.', 'Order the usual from Torgboden for tomorrow morning.');
  static String get cus_ai_kopier_forslag => _t('Kopier forslag', 'Copy suggestion');
  static String cus_ai_kopiert_lim(String navn) => _t('Kopiert · lim inn hos $navn', 'Copied · paste it into $navn');
  static String cus_ai_bestill_naa(String navn) => _t('Bestill med $navn nå', 'Order with $navn now');
  static String get cus_ai_ferdig => _t('Ferdig', 'Done');
  static String get cus_ai_endre_grenser => _t('Endre grenser', 'Change limits');

  // aiKoblede
  static String get cus_ai_koblede_tittel => _t('Koblede assistenter', 'Linked assistants');
  static String get cus_ai_koblede_tom => _t('Ingen assistenter er koblet til', 'No assistants are linked');
  static String cus_ai_koblede_linje(int n) => n == 0 ? cus_ai_koblede_tom : (n == 1 ? _t('1 aktiv · trykk for rettigheter, grenser og aktivitet', '1 active · tap for permissions, limits and activity') : _t('$n aktive · trykk for rettigheter, grenser og aktivitet', '$n active · tap for permissions, limits and activity'));
  static String get cus_ai_ingen_aktive => _t('Ingen aktive koblinger', 'No active links');
  static String get cus_ai_tom_tekst => _t('Koble til Claude, ChatGPT eller Gemini for å bestille derfra.', 'Link Claude, ChatGPT or Gemini to order from there.');
  static String get cus_ai_aktiv => _t('Aktiv', 'Active');
  static String get cus_ai_frakoblet => _t('Frakoblet', 'Unlinked');
  static String cus_ai_sist_brukt(String naar, int kr) => _t('Sist brukt $naar · maks ${nf(kr)} kr per bestilling', 'Last used $naar · max ${nf(kr)} kr per order');
  static String cus_ai_frakoblet_dato(String naar) => _t('Frakoblet $naar', 'Unlinked $naar');
  static String get cus_ai_brukt_i_dag => _t('Brukt i dag', 'Used today');
  static String cus_ai_av(String a, String b) => _t('$a av $b', '$a of $b');
  static String get cus_ai_koble_fra_alle => _t('Koble fra alle', 'Unlink all');
  static String get cus_ai_slik_kobler => _t('Slik kobler du til', 'How to link');
  static String get cus_ai_koble_ny => _t('Koble til en ny', 'Link a new one');
  static List<List<String>> get cus_ai_rett_kort => [['cart:write', _t('Handlekurv', 'Cart')], ['orders:read', _t('Bestillinger', 'Orders')], ['profile:read', _t('Adresser', 'Addresses')], ['support:write', 'Support']];

  // aiDetalj
  static String cus_ai_detalj_linje(String navn) => _t('Rettigheter, grenser og alt $navn har gjort', 'Permissions, limits and everything $navn has done');
  static String cus_ai_detalj_ikke(String navn) => _t('$navn har ikke lenger tilgang', '$navn no longer has access');
  static String cus_ai_koblet_til(String naar, String sist) => _t('Koblet til $naar · sist brukt $sist', 'Linked $naar · last used $sist');
  static String get cus_ai_bestilling => _t('Bestilling', 'Order');
  static String get cus_ai_bestillinger => _t('Bestillinger', 'Orders');
  static String get cus_ai_sist_brukt_lbl => _t('Sist brukt', 'Last used');
  static String get cus_ai_aktivitet => _t('Aktivitet', 'Activity');
  static String get cus_ai_ingen_aktivitet => _t('Ingen aktivitet ennå', 'No activity yet');
  static String cus_ai_koble_fra(String navn) => _t('Koble fra $navn', 'Unlink $navn');
  static String cus_ai_koble_igjen(String navn) => _t('Koble til $navn igjen', 'Link $navn again');
  static String get cus_ai_ikke_koblet_hs => _t('Ikke koblet', 'Not linked');
  static String cus_ai_ikke_koblet_linje(String navn) => _t('$navn er ikke koblet til Ærend-kontoen din.', '$navn is not linked to your Ærend account.');
  static String get cus_ai_lagret => _t('Lagret', 'Saved');
  static String get cus_ai_lagret_feil => _t('Fikk ikke lagret. Prøv igjen.', 'Could not save. Try again.');
  static String cus_ai_akt(String tool) => switch (tool) {
    'search_stores' => _t('Fant butikker', 'Found stores'),
    'search_products' => _t('Søkte i menyer', 'Searched menus'),
    'get_store' => _t('Leste menyen', 'Read the menu'),
    'get_product' => _t('Leste en vare', 'Read a product'),
    'create_cart' => _t('Bygde handlekurv', 'Built a cart'),
    'update_cart' => _t('Endret handlekurven', 'Changed the cart'),
    'quote' => _t('Hentet tilbud', 'Fetched a quote'),
    'start_checkout' => _t('Ba om å bestille', 'Asked to order'),
    'confirm_order' => _t('Bestilte', 'Ordered'),
    'list_orders' || 'get_order' => _t('Så på bestillingene', 'Looked at orders'),
    'track_order' => _t('Fulgte en bestilling', 'Tracked an order'),
    'reorder' => _t('Bestilte igjen', 'Reordered'),
    'get_profile' || 'list_addresses' || 'list_favorites' => _t('Leste profilen', 'Read the profile'),
    'open_support' => _t('Åpnet en supportsak', 'Opened a support case'),
    _ => tool,
  };

  // aiKobleFra
  static String cus_ai_fra_tittel(String navn) => _t('Koble fra $navn?', 'Unlink $navn?');
  static String get cus_ai_fra_alle_tittel => _t('Koble fra alle assistenter?', 'Unlink all assistants?');
  static String cus_ai_fra_linje(String navn) => _t('$navn mister tilgangen med en gang. Bestillinger som allerede er sendt, påvirkes ikke.', '$navn loses access at once. Orders already sent are not affected.');
  static String get cus_ai_fra_alle_linje => _t('Alle assistenter mister tilgangen med en gang. Bestillinger som allerede er sendt, påvirkes ikke.', 'All assistants lose access at once. Orders already sent are not affected.');
  static String get cus_ai_mister => _t('Mister tilgang med en gang', 'Loses access at once');
  static String get cus_ai_alle_mister => _t('Alle mister tilgang', 'All lose access');
  static List<String> get cus_ai_fra_info => [_t('Tilgangen stopper med en gang', 'Access stops at once'), _t('Bestillinger som er sendt, påvirkes ikke', 'Orders already sent are not affected'), _t('Du kan koble til igjen når som helst', 'You can link again at any time')];
  static String get cus_ai_koble_fra_cta => _t('Koble fra', 'Unlink');
  static String cus_ai_er_koblet_fra(String navn) => _t('$navn er koblet fra', '$navn is unlinked');
  static String get cus_ai_alle_koblet_fra => _t('Alle assistenter er koblet fra', 'All assistants are unlinked');
  static String cus_ai_assistenter(int n) => n == 1 ? _t('1 assistent', '1 assistant') : _t('$n assistenter', '$n assistants');

  // aiFeil
  static String cus_ai_feil_ikke_koblet(String navn) => _t('Koble til $navn for å bestille', 'Link $navn to order');
  static String cus_ai_feil_ikke_koblet_linje(String navn) => _t('$navn kan se menyer, men må kobles til kontoen din for å bestille.', '$navn can see menus, but must be linked to your account to order.');
  static String get cus_ai_ikke_koblet_enna => _t('Ikke koblet ennå', 'Not linked yet');
  static String get cus_ai_feil_bekreft => _t('Denne bestillingen trenger din bekreftelse', 'This order needs your confirmation');
  static String cus_ai_feil_bekreft_linje(int kr) => _t('Beløpet er over grensen din på ${nf(kr)} kr.', 'The amount is above your limit of ${nf(kr)} kr.');
  static String get cus_ai_se_bestillingen => _t('Se bestillingen', 'See the order');
  static String get cus_ai_feil_generisk => _t('Noe gikk galt', 'Something went wrong');
  static String get cus_ai_feil_generisk_linje => _t('Ingenting er bestilt. Prøv igjen om litt.', 'Nothing is ordered. Try again shortly.');
  static String get cus_ai_prov_igjen => _t('Prøv igjen', 'Try again');
  static String get cus_ai_ingenting_bestilt => _t('Ingenting er bestilt', 'Nothing is ordered');
  static String cus_ai_grensen_din(int kr) => _t('Grensen din er ${nf(kr)} kr', 'Your limit is ${nf(kr)} kr');

  // aiBekreft / aiKurv
  static String cus_ai_bekreft_tittel(String navn) => _t('Bekreft bestilling fra $navn', 'Confirm order from $navn');
  static String cus_ai_bekreft_linje(String butikk, String bet) => _t('$butikk · betales med $bet', '$butikk · paid with $bet');
  static String get cus_ai_med_vipps => _t('Vipps', 'Vipps');
  static String get cus_ai_med_kort => _t('lagret kort', 'saved card');
  static String cus_ai_kurv_tittel(String navn) => _t('Handlekurv fra $navn', 'Cart from $navn');
  static String cus_ai_fra(String navn) => _t('Fra $navn', 'From $navn');
  static String get cus_ai_ingenting_sendes => _t('Ingenting sendes før du bekrefter her', 'Nothing is sent before you confirm here');
  static String cus_ai_bygde(String navn) => _t('$navn bygde handlekurven', '$navn built the cart');
  static String cus_ai_ber_om(String navn) => _t('$navn ber om å bestille', '$navn asks to order');
  static String cus_ai_apnet_fra(String navn) => _t('Åpnet fra $navn · nå', 'Opened from $navn · now');
  static String cus_ai_foresporsel(String butikk) => _t('Forespørsel · $butikk', 'Request · $butikk');
  static String get cus_ai_henter_tilbud => _t('Henter tilbud fra Ærend …', 'Fetching the offer from Ærend …');
  static String get cus_ai_varer => _t('Varer', 'Items');
  static String cus_ai_antall_varer(int n) => n == 1 ? _t('1 vare', '1 item') : _t('$n varer', '$n items');
  static String get cus_ai_utsolgt_naa => _t('Utsolgt akkurat nå', 'Sold out right now');
  static String cus_ai_fjern_tx(String navn) => _t('Fjern $navn?', 'Remove $navn?');
  static String get cus_ai_fjern_under => _t('Resten av kurven får et nytt tilbud', 'The rest of the cart gets a new offer');
  static String get cus_ai_fjern => _t('Fjern', 'Remove');
  static String get cus_ai_tilbudet_ditt => _t('Tilbudet ditt', 'Your offer');
  static String get cus_ai_tilbudet_gjelder => _t('Tilbudet gjelder i', 'The offer is valid for');
  static String get cus_ai_bekreft_innen => _t('Bekreft innen', 'Confirm within');
  static String get cus_ai_leveringsvindu => _t('Leveringsvindu', 'Delivery window');
  static String get cus_ai_leveres_til => _t('Leveres til', 'Delivered to');
  static String get cus_ai_totalt => _t('Totalt', 'Total');
  static String get cus_ai_ny_total => _t('Ny totalsum', 'New total');
  static String get cus_ai_ny => _t('Ny', 'New');
  static String cus_ai_innenfor(int kr) => _t('Innenfor grensen din på ${nf(kr)} kr', 'Within your limit of ${nf(kr)} kr');
  static String cus_ai_over(int kr) => _t('Over grensen din på ${nf(kr)} kr', 'Above your limit of ${nf(kr)} kr');
  static String cus_ai_grense(int kr) => _t('Grense ${nf(kr)} kr', 'Limit ${nf(kr)} kr');
  static String get cus_ai_endre_kurv => _t('Endre handlekurven', 'Change the cart');
  static String get cus_ai_endre_under => _t('Endringer gir et nytt tilbud.', 'Changes give a new offer.');
  static String get cus_ai_avvis => _t('Avvis', 'Decline');
  static String get cus_ai_avvist => _t('Avvist · ingenting er bestilt', 'Declined · nothing is ordered');
  static String get cus_ai_tilbud_utlopt => _t('Tilbudet har utløpt', 'The offer has expired');
  static String get cus_ai_tilbud_utlopt_tx => _t('Prisen kan ha endret seg. Vi har hentet et nytt tilbud.', 'The price may have changed. We fetched a new offer.');
  static String get cus_ai_for_utlopt => _t('Forespørselen har utløpt', 'The request has expired');
  static String cus_ai_for_utlopt_tx(String navn) => _t('Ingenting er bestilt. Be $navn om å prøve igjen.', 'Nothing is ordered. Ask $navn to try again.');
  static String get cus_ai_for_utlopt_steg => _t('Forespørselen utløp · ingenting bestilt', 'The request expired · nothing ordered');
  static String cus_ai_trukket(String navn) => _t('$navn trakk forespørselen', '$navn withdrew the request');
  static String get cus_ai_trukket_tx => _t('Ingenting er bestilt.', 'Nothing is ordered.');
  static String get cus_ai_bet_feilet => _t('Betalingen gikk ikke gjennom', 'The payment did not go through');
  static String get cus_ai_bet_feilet_tx => _t('Ingenting er bestilt. Prøv igjen eller velg en annen betalingsmåte.', 'Nothing is ordered. Try again or choose another payment method.');
  static String get cus_ai_bytt_bet => _t('Bytt betalingsmåte', 'Change payment method');
  static String cus_ai_betaler_med(String b) => _t('Betaler med $b', 'Paying with $b');
  static String cus_ai_over_banner(int kr) => _t('Over grensen din på ${nf(kr)} kr', 'Above your limit of ${nf(kr)} kr');
  static String get cus_ai_over_banner_tx => _t('Du kan bekrefte likevel. Grensen gjelder fortsatt for neste bestilling.', 'You can confirm anyway. The limit still applies to the next order.');
  static String get cus_ai_bekreft_likevel => _t('Bekreft likevel', 'Confirm anyway');
  static String get cus_ai_bekreft_betal => _t('Bekreft og betal', 'Confirm and pay');
  static String get cus_ai_logg_inn_fortsett => _t('Logg inn for å fortsette', 'Sign in to continue');
  static String cus_ai_kurv_venter(String navn) => _t('Du kommer tilbake hit etter innlogging. Handlekurven fra $navn venter.', 'You come back here after signing in. The cart from $navn is waiting.');
  static String get cus_ai_leverer_ikke => _t('Vi leverer ikke hit ennå', 'We do not deliver here yet');
  static String get cus_ai_si_fra => _t('Si fra, så gir vi beskjed når vi kommer.', 'Tell us, and we let you know when we arrive.');
  static String get cus_ai_venteliste => _t('Sett meg på ventelisten', 'Put me on the waitlist');
  static String get cus_ai_paa_venteliste => _t('Du står på ventelisten', 'You are on the waitlist');
  static String cus_ai_paa_venteliste_tx(String sted) => _t('Vi sier fra med en gang vi leverer til $sted. Ingenting er bestilt.', 'We tell you as soon as we deliver to $sted. Nothing is ordered.');
  static String get cus_ai_til_hjem => _t('Til Hjem', 'To Home');
  static String get cus_ai_endre => _t('Endre', 'Change');
  static String get cus_ai_godkjenner_vipps => _t('Du godkjenner i Vipps', 'You approve in Vipps');
  static String get cus_ai_bekreftes_faceid => _t('Bekreftes med Face ID', 'Confirmed with Face ID');
  static String get cus_ai_kort_ved_bet => _t('Kort, Apple Pay eller Google Pay', 'Card, Apple Pay or Google Pay');
  static String cus_ai_ingen_betdata(String navn) => _t('Ingen betalingsdata deles med $navn', 'No payment data is shared with $navn');
  static String cus_ai_betal_med_vipps(int kr) => _t('Betal med Vipps · ${nf(kr)} kr', 'Pay with Vipps · ${nf(kr)} kr');
  static String get cus_ai_apner_vipps => _t('Åpner Vipps …', 'Opening Vipps …');
  static String get cus_ai_bekrefter => _t('Bekrefter …', 'Confirming …');
  static String get cus_ai_face_id => 'Face ID';
  static String cus_ai_aerend_sum(String sum) => 'Ærend · $sum';
  static String get cus_ai_tilbake_etterpaa => _t('Du kommer tilbake hit etterpå', 'You come back here afterwards');
  static String cus_ai_betaling_med(String b) => _t('Betaling med $b', 'Payment with $b');
  static String cus_ai_bestilt_via(String navn, String kode) => _t('Bestilt via $navn · $kode', 'Ordered via $navn · $kode');
  static String get cus_ai_bestilling_feilet => _t('Bestillingen kunne ikke opprettes.', 'The order could not be created.');
  static String get cus_ai_enhet_avvist => _t('Ikke bekreftet på enheten · prøv igjen', 'Not confirmed on the device · try again');

  // Overlays
  static String cus_ai_bytt_apner(String navn) => _t('Åpner $navn …', 'Opening $navn …');
  static String cus_ai_bytt_fortsetter(String navn) => _t('Fortsetter i $navn …', 'Continuing in $navn …');
  static String cus_ai_bytt_godkjenn(String navn) => _t('Godkjenn Ærend i $navn. Du kommer rett tilbake hit.', 'Approve Ærend in $navn. You come straight back here.');
  static String cus_ai_bytt_si(String navn) => _t('Si hva du vil ha. $navn bygger kurven, og du bekrefter i Ærend.', 'Say what you want. $navn builds the cart, and you confirm in Ærend.');
  static String get cus_ai_bygger_kurv => _t('Bygger handlekurv hos Ærend …', 'Building the cart at Ærend …');
  static String get cus_ai_tilbake_i => _t('Tilbake i Ærend', 'Back in Ærend');
  static String cus_ai_bytt_inn_kurv(String navn) => _t('$navn har bygget handlekurven. Nå bekrefter du prisen.', '$navn has built the cart. Now you confirm the price.');
  static String cus_ai_bytt_inn_sam(String navn) => _t('$navn godkjente. Nå velger du hva $navn får lov til.', '$navn approved. Now you choose what $navn may do.');
  static String get cus_ai_push_naa => _t('NÅ', 'NOW');
  static String cus_ai_push_tittel(String navn) => _t('$navn vil bestille', '$navn wants to order');
  static String cus_ai_push_tx(String navn, String sum, String butikk) => _t('$navn vil bestille for $sum fra $butikk. Bekreft i Ærend.', '$navn wants to order for $sum from $butikk. Confirm in Ærend.');

  // Chips / Varsler
  static String cus_ai_via(String navn) => _t('Via $navn', 'Via $navn');
  static String cus_ai_bestilt_via_dato(String navn, String dato) => _t('Bestilt via $navn · $dato', 'Ordered via $navn · $dato');
  static String get cus_ai_sporing_via => _t('Sporing · via assistent', 'Tracking · via assistant');
  static String get cus_ai_i_dag => _t('i dag', 'today');
  static String get cus_ai_naa => _t('nå', 'now');
  static String get cus_ai_aldri => _t('aldri', 'never');
}
