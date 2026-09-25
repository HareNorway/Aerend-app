// ignore_for_file: non_constant_identifier_names

import '../../../utils/utils.dart';

/// Copy for the Sporing group (`sporing` ≈L5287–5760, the completion layer
/// ≈L7294, `sheetHjelp` ≈L7000–7130, `levert` ≈L5881 in
/// `Ærend Kunde Bergen.dc.html`). AGIL-CONTRACT §3.2: class `SporingCopy`,
/// keys `a1_sporing_*`, NO and EN. The spec §7 key
/// `order_status_finding_courier` is used verbatim (contract §3.4).
abstract final class SporingCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  // ── top line ────────────────────────────────────────────────────────────
  static String a1_sporing_live(String stadie) => 'Live · $stadie';
  static String get order_status_finding_courier =>
      _t('Finner bud', 'Finding a courier');
  static String a1_sporing_om_min(int n) => _t('om $n min', 'in $n min');
  static String get a1_sporing_kommer => _t('Kommer', 'Arriving');
  static String get a1_sporing_klar_naa => _t('Klar nå', 'Ready now');
  static String a1_sporing_klar_kl(String t) => _t('Klar $t', 'Ready $t');
  static String a1_sporing_hentes_hos(String s) =>
      _t('Hentes hos $s', 'Pick up at $s');
  static String get a1_sporing_star_klar =>
      _t('Står klar i disken', 'Waiting at the counter');
  static String get a1_sporing_hentet_takk =>
      _t('Hentet · takk!', 'Picked up · thanks!');
  static String get a1_sporing_butikken_paa_vei =>
      _t('Butikken er på vei', 'The shop is on its way');
  static String a1_sporing_levert_av(String s) =>
      _t('Levert av $s', 'Delivered by $s');
  static String a1_sporing_leveres_av(String s) =>
      _t('Leveres av $s', 'Delivered by $s');
  static String get a1_sporing_levert_for_tiden =>
      _t('Levert · før tiden', 'Delivered · early');
  static String a1_sporing_levert_min_for(int m) => _t(
    m == 1 ? 'Levert · ett minutt før tiden' : 'Levert · $m minutter før tiden',
    'Delivered · $m min early',
  );
  static String get a1_sporing_avbestilt => _t('Avbestilt', 'Cancelled');
  static String a1_sporing_gave_venter(String navn) =>
      _t('$navn venter på kaien', '$navn is waiting on the quay');

  // ── stages ──────────────────────────────────────────────────────────────
  static List<String> stages(bool pickup) => pickup
      ? [
          _t('Bekreftet', 'Confirmed'),
          _t('Tilberedes', 'Preparing'),
          _t('Klar for henting', 'Ready for pickup'),
          _t('Hentet', 'Picked up'),
        ]
      : [
          _t('Bekreftet', 'Confirmed'),
          _t('Tilberedes', 'Preparing'),
          _t('På vei', 'On its way'),
          _t('Levert', 'Delivered'),
        ];
  static String a1_sporing_steg(int n, int of) =>
      _t('Steg $n av $of', 'Step $n of $of');
  static String a1_sporing_pluss_poeng(int n) => _t('+$n poeng', '+$n points');

  // ── Ægil-veileder ───────────────────────────────────────────────────────
  static String get a1_sporing_aegil => 'Ægil';
  static String get a1_sporing_aegil_folger =>
      _t('· følger ærendet ditt', '· follows your errand');
  static String a1_sporing_neste(String navn) =>
      _t('Neste: $navn', 'Next: $navn');
  static String get a1_sporing_oppdrag_fullfort =>
      _t('Oppdrag fullført', 'Errand complete');
  static String get a1_sporing_finner_bud_hint => _t(
    'Jeg finner et bud til deg nå — det tar vanligvis et par minutter.',
    'I am finding you a courier — it usually takes a couple of minutes.',
  );
  static List<String> lines(
    bool pickup, {
    bool partner = false,
    bool bike = true,
    String? store,
  }) {
    final s = store ?? _t('butikken', 'the shop');
    if (pickup) {
      return [
        _t(
          'Jeg rodde inn til Bryggen og leverte bestillingen. Kokken hos $s leser den nå.',
          'I rowed in and delivered the order. The kitchen at $s is reading it now.',
        ),
        _t(
          'Du kan gå ut døren nå — maten er snart klar.',
          'You can head out now — the food is nearly ready.',
        ),
        _t(
          'Maten er ferdig! Hent den i disken hos $s.',
          'The food is ready! Pick it up at the counter at $s.',
        ),
        _t('Hentet. Håper det smaker.', 'Picked up. Enjoy.'),
      ];
    }
    if (partner) {
      return [
        _t(
          'Bestillingen er hos $s. Kokken leser den nå — de leverer selv i kveld.',
          'The order is with $s. The kitchen is reading it — they deliver themselves tonight.',
        ),
        _t(
          'Kokken har satt i gang. $s kjører den ut selv når den er klar.',
          'The kitchen has started. $s drives it out when it is ready.',
        ),
        _t(
          '$s er på vei med bestillingen.',
          '$s is on its way with the order.',
        ),
        _t('Levert av $s. Håper det smaker.', 'Delivered by $s. Enjoy.'),
      ];
    }
    return [
      _t(
        'Jeg rodde inn til Bryggen og leverte bestillingen. Kokken hos $s leser den nå.',
        'I rowed in and delivered the order. The kitchen at $s is reading it now.',
      ),
      _t('Kokken har satt i gang.', 'The kitchen has started.'),
      bike
          ? _t('Budet sykler fra $s nå.', 'The courier is cycling from $s now.')
          : _t(
              'Budet kjører fra $s nå.',
              'The courier is driving from $s now.',
            ),
      _t('Levert. Håper det smaker.', 'Delivered. Enjoy.'),
    ];
  }

  // ── stage cards ─────────────────────────────────────────────────────────
  static String get a1_sporing_mottatt => _t('MOTTATT', 'RECEIVED');
  static String get a1_sporing_tilberedes_kicker =>
      _t('TILBEREDES', 'PREPARING');
  static String get a1_sporing_paa_komfyren =>
      _t('På komfyren', 'On the stove');
  static String a1_sporing_min_igjen(int m) =>
      _t('$m min igjen', '$m min left');
  static String get a1_sporing_klar_kicker => _t('KLAR', 'READY');
  static String a1_sporing_disken(String navn) => _t(
    'Den står i disken. Si «$navn» så får du den.',
    'It is at the counter. Say «$navn» and it is yours.',
  );
  static String get a1_sporing_vis_veien => _t('Vis veien', 'Show the way');
  static String get a1_sporing_forseglet => _t('Forseglet', 'Sealed');
  static String get a1_sporing_ankommer_om => _t('Ankommer om', 'Arriving in');
  static String get a1_sporing_haaper => _t('Håper det smaker.', 'Enjoy.');
  static String get a1_sporing_spart_tid => _t('SPART TID', 'TIME SAVED');
  static String get a1_sporing_kart_kommer => _t(
    'Kartet kommer når budet har hentet.',
    'The map appears once the courier has picked up.',
  );
  static String get a1_sporing_ingen_kart_partner => _t(
    'Butikken kjører selv — ingen live-posisjon.',
    'The shop drives itself — no live position.',
  );

  // ── Avslutt ─────────────────────────────────────────────────────────────
  static String get a1_sporing_avslutt =>
      _t('Avslutt bestillingen', 'Finish the order');
  static String get a1_sporing_fjordfiske => 'Fjordfiske';
  static String get a1_sporing_mens_du_venter =>
      _t('mens du venter', 'while you wait');
  static String get a1_sporing_sammendrag => _t('Sammendrag', 'Summary');
  static String get a1_sporing_detaljer => _t('Detaljer', 'Details');
  static String get a1_sporing_hjelp => _t('Hjelp', 'Help');

  // ── completion layer ────────────────────────────────────────────────────
  static String get a1_sporing_bankid =>
      _t('BankID-verifisert', 'BankID verified');
  static String get a1_sporing_kode_tittel =>
      _t('Kode ved levering', 'Code at delivery');
  static String get a1_sporing_kode_under => _t(
    'Vis koden til budet, eller les den opp.',
    'Show the code to the courier, or read it out.',
  );
  static String get a1_sporing_kode_offline => _t(
    'Uten nett vises bare PIN.',
    'Without a connection only the PIN is shown.',
  );
  static String get a1_sporing_kode_no_door => _t(
    'Posen kan ikke settes igjen ved døren.',
    'The bag cannot be left at the door.',
  );
  static String get a1_sporing_kode_laast => _t(
    'Koden er låst etter for mange forsøk — budet tar bilde og navn.',
    'The code is locked after too many tries — the courier takes a photo and a name.',
  );
  static String get a1_sporing_kode_bekreftet =>
      _t('Koden ble bekreftet', 'The code was confirmed');
  static String reasonCopy(String key) {
    switch (key) {
      case 'a1_sporing_kode_reason_value':
        return _t(
          'Denne leveringen har høy verdi, så vi ber om kode ved døren.',
          'This delivery is high value, so we ask for a code at the door.',
        );
      case 'a1_sporing_kode_reason_age_restricted':
        return _t(
          'Varene har aldersgrense, så budet må sjekke kode ved levering.',
          'The goods are age restricted, so the courier checks a code at delivery.',
        );
      case 'a1_sporing_kode_reason_customer_choice':
        return _t(
          'Du har valgt kode ved levering.',
          'You chose a code at delivery.',
        );
      case 'a1_sporing_kode_reason_business':
        return _t(
          'Levering til bedriftsadresse krever kode.',
          'Delivery to a business address needs a code.',
        );
      default:
        return _t(
          'Vi ber om kode ved døren på denne leveringen.',
          'We ask for a code at the door on this delivery.',
        );
    }
  }

  static String a1_sporing_valg_tittel(String butikk) =>
      _t('$butikk har ikke sett ordren', '$butikk has not seen the order');
  static String get a1_sporing_valg_line => _t(
    'Vent på nytt vindu, eller avbestill med full refusjon. Ingenting skjer før du velger.',
    'Wait for a new window, or cancel with a full refund. Nothing happens until you choose.',
  );
  static String get a1_sporing_vent => _t('Vent', 'Wait');
  static String get a1_sporing_avbestill => _t('Avbestill', 'Cancel');
  static String get a1_sporing_venter =>
      _t('Vi venter på butikken.', 'We are waiting for the shop.');
  static String get a1_sporing_refundert => _t(
    'Avbestilt — pengene kommer tilbake på Vipps.',
    'Cancelled — the money returns to Vipps.',
  );
  static String get a1_sporing_uten_nett => _t(
    'Uten nett · viser siste kjente status',
    'Offline · showing the last known status',
  );

  // ── notifications (store-delivered variant) ─────────────────────────────
  static String get a1_sporing_notif_store_on_the_way =>
      _t('Butikken er på vei', 'The shop is on its way');
  static String get a1_sporing_notif_store_delivered =>
      _t('Levert av butikken', 'Delivered by the shop');

  // ── Hjelp ───────────────────────────────────────────────────────────────
  static String a1_sporing_hjelp_ring(String rolle) =>
      _t('Ring $rolle', 'Call $rolle');
  static String a1_sporing_hjelp_melding(String rolle) =>
      _t('Melding til $rolle', 'Message $rolle');
  static String get a1_sporing_hjelp_ring_kort => _t('Ring', 'Call');
  static String get a1_sporing_hjelp_send =>
      _t('Send melding', 'Send a message');
  static String a1_sporing_hjelp_kort_bud(
    int min,
    String siden,
    String rating,
  ) => _t(
    'På vei · $min min unna · sykler siden $siden · $rating',
    'On the way · $min min away · cycling since $siden · $rating',
  );
  static String get a1_sporing_hjelp_kort_bud_enkel =>
      _t('På vei til deg', 'On the way to you');
  static String get a1_sporing_hjelp_kort_butikk =>
      _t('Leverer selv i kveld', 'Delivers itself tonight');
  static String get a1_sporing_hjelp_vanlige =>
      _t('VANLIGE SPØRSMÅL', 'COMMON QUESTIONS');
  static String get a1_sporing_hjelp_dor =>
      _t('Finner ikke døra', 'Cannot find the door');
  static String get a1_sporing_hjelp_dor_line =>
      _t('Send veibeskrivelse eller ring', 'Send directions or call');
  static String get a1_sporing_hjelp_mangler =>
      _t('Noe mangler i bestillingen', 'Something is missing from the order');
  static String get a1_sporing_hjelp_mangler_line =>
      _t('Refusjon på Vipps innen 2 min', 'Refund on Vipps within 2 min');
  static String get a1_sporing_hjelp_kundeservice =>
      _t('Snakk med Ærend i Bergen', 'Talk to Ærend in Bergen');
  static String get a1_sporing_hjelp_kundeservice_line => _t(
    'Kundeservice · åpent til 23:00',
    'Customer service · open until 23:00',
  );
  static String get a1_sporing_ring_kobler =>
      _t('Kobler til …', 'Connecting …');
  static String get a1_sporing_ring_maskert => _t(
    'Nummeret er maskert — ingen ser hverandres telefon.',
    'The number is masked — nobody sees the other\'s phone.',
  );
  static String get a1_sporing_ring_ingen => _t(
    'Ingen linje ennå — ring nummeret under.',
    'No line yet — call the number below.',
  );
  static String get a1_sporing_demp => _t('Demp', 'Mute');
  static String get a1_sporing_avslutt_samtale => _t('Avslutt', 'End');
  static String get a1_sporing_hoyttaler => _t('Høyttaler', 'Speaker');
  static String get a1_sporing_tilbake =>
      _t('Tilbake til hjelp', 'Back to help');
  static String get a1_sporing_aktiv =>
      _t('Aktiv nå · svarer raskt', 'Active now · replies quickly');
  static String get a1_sporing_skriver => _t('skriver …', 'typing …');
  static String get a1_sporing_meld_hint =>
      _t('Skriv en melding', 'Write a message');
  static String get a1_sporing_send => _t('Send', 'Send');
  static List<String> get a1_sporing_hurtig => _en
      ? const ['Ring on the door', 'Leave it at the door', 'I am 2 min late']
      : const ['Ring på', 'Sett den utenfor døra', 'Jeg er 2 min sen'];
  static String a1_sporing_dor_tittel(String navn) =>
      _t('Dette er det $navn ser nå', 'This is what $navn sees now');
  static String get a1_sporing_lev_adresse =>
      _t('LEVERINGSADRESSE', 'DELIVERY ADDRESS');
  static String get a1_sporing_veibeskrivelse =>
      _t('VEIBESKRIVELSE', 'DIRECTIONS');
  static String get a1_sporing_dor_hint => _t(
    'Inngang på baksiden, gul dør, 3. etasje …',
    'Entrance at the back, yellow door, 3rd floor …',
  );
  static String a1_sporing_send_til(String navn) =>
      _t('Send til $navn', 'Send to $navn');
  static String a1_sporing_ring_navn(String navn) =>
      _t('Ring $navn', 'Call $navn');
  static String get a1_sporing_skriv_selv =>
      _t('Skriv selv', 'Write it yourself');
  static String get a1_sporing_hva_mangler =>
      _t('Hva mangler?', 'What is missing?');
  static String get a1_sporing_mangler_line => _t(
    'Trykk på det som ikke kom. Vi ordner resten.',
    'Tap what did not arrive. We handle the rest.',
  );
  static String get a1_sporing_mangler_refusjon => _t(
    'Du får pengene tilbake på Vipps innen 2 min — eller ny levering hvis du heller vil det.',
    'You get the money back on Vipps within 2 min — or a new delivery if you prefer.',
  );
  static String a1_sporing_meld_mangler(int n) => _t(
    n == 0 ? 'Velg det som mangler' : 'Meld $n som mangler',
    n == 0 ? 'Pick what is missing' : 'Report $n missing',
  );
  static String get a1_sporing_ks_tittel =>
      _t('Ærend i Bergen', 'Ærend in Bergen');
  static String get a1_sporing_ks_line => _t(
    'Åpent til 23:00 · svarer innen 2 min',
    'Open until 23:00 · replies within 2 min',
  );
  static String get a1_sporing_ks_chat => _t('Chat med oss', 'Chat with us');
  static String get a1_sporing_ks_chat_line => _t(
    'Raskest · Kari og Ola er på vakt',
    'Fastest · Kari and Ola are on duty',
  );
  static String get a1_sporing_ks_ring =>
      _t('Ring 55 00 12 34', 'Call 55 00 12 34');
  static String get a1_sporing_ks_ring_line => _t(
    'Vanlig takst · ca. 1 min ventetid',
    'Standard rate · about 1 min wait',
  );
  static String a1_sporing_ks_ordre(String nr) => _t(
    'Ordre #$nr er allerede lagt ved, så du slipper å forklare.',
    'Order #$nr is already attached, so you need not explain.',
  );
  static String get a1_sporing_ks_nummer => '+4755001234';
  static String get a1_sporing_sendt_tittel => _t('Sendt', 'Sent');
  static String a1_sporing_sendt_tekst(String rolle) =>
      _t('$rolle har fått beskjeden.', '$rolle has your message.');
  static String get a1_sporing_meldt_tittel => _t('Meldt', 'Reported');
  static String get a1_sporing_ferdig => _t('Ferdig', 'Done');
  static String get a1_sporing_butikken => _t('butikken', 'the shop');
  static String get a1_sporing_bud => _t('bud', 'the courier');
  static String get a1_sporing_Butikken => _t('Butikken', 'The shop');
  static String get a1_sporing_Budet => _t('Budet', 'The courier');

  // ── Levert ──────────────────────────────────────────────────────────────
  static String get a1_sporing_levert_punkt => _t('Levert.', 'Delivered.');
  static String get a1_sporing_poeng_for_ordren =>
      _t('poeng for denne ordren', 'points for this order');
  static String a1_sporing_liga_gap(int n, int plass) =>
      _t('$n fra $plass. plass', '$n from $plass. place');
  static String a1_sporing_forste_gang(int n, String butikk) => _t(
    '+$n poeng · første gang hos $butikk',
    '+$n points · first time at $butikk',
  );
  static String get a1_sporing_en_gang =>
      _t('Gjelder én gang per butikk', 'Once per shop');
  static String a1_sporing_levert_til_deg(String hvem) => _t(
    'Levert til deg · koden ble bekreftet av $hvem',
    'Delivered to you · the code was confirmed by $hvem',
  );
  static String a1_sporing_levert_til_deg_uten(String hvem) =>
      _t('Levert til deg av $hvem', 'Delivered to you by $hvem');
  static String a1_sporing_takk(String navn) =>
      _t('Takk til $navn', 'Thanks to $navn');
  static String get a1_sporing_hvordan =>
      _t('Hvordan gikk det?', 'How did it go?');
  static String get a1_sporing_takk_vurdering =>
      _t('Takk for vurderingen', 'Thanks for the rating');
  static String get a1_sporing_noe_galt =>
      _t('Noe galt med bestillingen?', 'Something wrong with the order?');
  static String get a1_sporing_ikke_funnet =>
      _t('Fant ikke bestillingen.', 'Could not find the order.');
  static String get a1_sporing_laster =>
      _t('Henter status …', 'Fetching status …');

  // ── demo panel ──────────────────────────────────────────────────────────
  static String get a1_sporing_demo_ny =>
      _t('Ny ordre → Bekreftet', 'New order → Confirmed');
  static String get a1_sporing_demo_neste => _t('Neste stadie', 'Next stage');
  static String get a1_sporing_demo_usett => _t('Usett butikk', 'Unseen shop');
  static String get a1_sporing_demo_kode_ok => _t('Kode OK', 'Code OK');
  static String get a1_sporing_demo_pin_feil =>
      _t('PIN feil ×3', 'PIN wrong ×3');
  static String get a1_sporing_demo_offline =>
      _t('Uten nett / på nett', 'Offline / online');
}
