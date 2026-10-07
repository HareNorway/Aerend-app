// ignore_for_file: non_constant_identifier_names

import '../../../main.dart' show languages;
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
  static String a1_sporing_live(String stadie) => languages.ops_sporing_live(stadie);
  static String get order_status_finding_courier => languages.order_status_finding_courier;
  static String a1_sporing_om_min(int n) => languages.ops_sporing_om_min(n);
  static String get a1_sporing_kommer => languages.ops_sporing_kommer;
  static String get a1_sporing_klar_naa => languages.ops_sporing_klar_naa;
  static String a1_sporing_klar_kl(String t) => languages.ops_sporing_klar_kl(t);
  static String a1_sporing_hentes_hos(String s) => languages.ops_sporing_hentes_hos(s);
  static String get a1_sporing_star_klar => languages.ops_sporing_star_klar;
  static String get a1_sporing_hentet_takk => languages.ops_sporing_hentet_takk;
  static String get a1_sporing_butikken_paa_vei => languages.ops_sporing_butikken_paa_vei;
  static String a1_sporing_levert_av(String s) => languages.ops_sporing_levert_av(s);
  static String a1_sporing_leveres_av(String s) => languages.ops_sporing_leveres_av(s);
  static String get a1_sporing_levert_for_tiden => languages.ops_sporing_levert_for_tiden;
  static String a1_sporing_levert_min_for(int m) => _t('Levert · ${minutterOrd(m)} før tiden', 'Delivered · ${minutterOrd(m)} early');
  static String get a1_sporing_avbestilt => languages.ops_sporing_avbestilt;
  static String a1_sporing_gave_venter(String navn) => languages.ops_sporing_gave_venter(navn);

  // ── stages ──────────────────────────────────────────────────────────────
  static List<String> stages(bool pickup) => pickup
      ? [_t('Bekreftet', 'Confirmed'), _t('Tilberedes', 'Preparing'), _t('Klar for henting', 'Ready for pickup'), _t('Hentet', 'Picked up')]
      : [_t('Bekreftet', 'Confirmed'), _t('Tilberedes', 'Preparing'), _t('På vei', 'On its way'), _t('Levert', 'Delivered')];
  static String a1_sporing_steg(int n, int of) => languages.ops_sporing_steg(n, of);
  static String a1_sporing_pluss_poeng(int n) => languages.ops_sporing_pluss_poeng(n);

  // ── Ægil-veileder ───────────────────────────────────────────────────────
  static String get a1_sporing_aegil => languages.ops_sporing_aegil;
  static String get a1_sporing_aegil_folger => languages.ops_sporing_aegil_folger;
  static String a1_sporing_neste(String navn) => languages.ops_sporing_neste(navn);
  static String get a1_sporing_oppdrag_fullfort => languages.ops_sporing_oppdrag_fullfort;
  static String get a1_sporing_finner_bud_hint => languages.ops_sporing_finner_bud_hint;

  /// Ægil's lines per stage (Launch L19409–19427): first person, with the
  /// store, the street, the minutes left, the pickup name and the window
  /// when they are known.
  static List<String> lines(bool pickup, {bool partner = false, bool bike = true, String? store, String? gate, int? minutter, String? navn, String? vindu, String? klokke}) {
    final s = store ?? _t('butikken', 'the shop');
    final min = minutter == null ? '' : ' ${_minutter(minutter)} ${_t('til', 'to')} ${gate ?? _t('deg', 'you')}.';
    if (pickup) {
      return [
        _t('Jeg rodde inn til Bryggen og leverte bestillingen. Kokken hos $s leser den nå.', 'I rowed in and delivered the order. The kitchen at $s is reading it now.'),
        _t('Du kan gå ut døren nå — maten er snart klar.', 'You can head out now — the food is nearly ready.'),
        _t(
          'Maten er ferdig! Hent den i disken hos $s${gate == null ? '' : ', $gate'}${navn == null ? '' : ' — si «$navn»'}.',
          'The food is ready! Pick it up at the counter at $s${gate == null ? '' : ', $gate'}${navn == null ? '' : ' — say «$navn»'}.',
        ),
        _t('Hentet${klokke == null ? '' : ' $klokke'}. Håper det smaker.', 'Picked up${klokke == null ? '' : ' $klokke'}. Enjoy.'),
      ];
    }
    if (partner) {
      return [
        _t('Bestillingen er hos $s. Kokken leser den nå — de leverer selv i kveld.', 'The order is with $s. The kitchen is reading it — they deliver themselves tonight.'),
        _t('Kokken har satt i gang. $s kjører den ut selv når den er klar.', 'The kitchen has started. $s drives it out when it is ready.'),
        _t('$s er på vei med bestillingen.${vindu == null ? '' : ' De regner med $vindu.'}', '$s is on its way with the order.${vindu == null ? '' : ' They expect $vindu.'}'),
        _t('Levert av $s. Håper det smaker.', 'Delivered by $s. Enjoy.'),
      ];
    }
    return [
      _t('Jeg rodde inn til Bryggen og leverte bestillingen. Kokken hos $s leser den nå.', 'I rowed in and delivered the order. The kitchen at $s is reading it now.'),
      _t('Kokken har satt i gang — grillen står på og maten steker.', 'The kitchen has started — the grill is on and the food is sizzling.'),
      bike ? _t('Jeg sykler fra $s nå.$min', 'I am cycling from $s now.$min') : _t('Jeg kjører fra $s nå.$min', 'I am driving from $s now.$min'),
      _t('Levert. Håper det smaker.', 'Delivered. Enjoy.'),
    ];
  }

  /// «fire minutter» — the small numbers in words, as the prototype says them.
  static String minutterOrd(int n) => _minutter(n).toLowerCase().replaceFirst(RegExp(r'^\w'), _minutter(n)[0].toLowerCase());

  /// «Fire minutter» — capitalised, for the start of a sentence.
  static String _minutter(int n) {
    const no = ['Null', 'Ett', 'To', 'Tre', 'Fire', 'Fem', 'Seks', 'Sju', 'Åtte', 'Ni', 'Ti', 'Elleve', 'Tolv'];
    const en = ['Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve'];
    if (n >= 0 && n < no.length) return _t('${no[n]} ${n == 1 ? 'minutt' : 'minutter'}', '${en[n]} ${n == 1 ? 'minute' : 'minutes'}');
    return _t('$n minutter', '$n minutes');
  }

  // ── stage cards ─────────────────────────────────────────────────────────
  static String get a1_sporing_mottatt => languages.ops_sporing_mottatt;
  static String get a1_sporing_tilberedes_kicker => languages.ops_sporing_tilberedes_kicker;
  static String get a1_sporing_paa_komfyren => languages.ops_sporing_paa_komfyren;
  static String a1_sporing_min_igjen(int m) => languages.ops_sporing_min_igjen(m);
  static String get a1_sporing_klar_kicker => languages.ops_sporing_klar_kicker;
  static String a1_sporing_disken(String navn) => languages.ops_sporing_disken(navn);
  static String get a1_sporing_vis_veien => languages.ops_sporing_vis_veien;
  static String get a1_sporing_forseglet => languages.ops_sporing_forseglet;
  static String get a1_sporing_ankommer_om => languages.ops_sporing_ankommer_om;
  static String get a1_sporing_haaper => languages.ops_sporing_haaper;
  static String get a1_sporing_spart_tid => languages.ops_sporing_spart_tid;
  static String get a1_sporing_kart_kommer => languages.ops_sporing_kart_kommer;
  static String get a1_sporing_ingen_kart_partner => languages.ops_sporing_ingen_kart_partner;

  // ── Avslutt ─────────────────────────────────────────────────────────────
  static String get a1_sporing_avslutt => languages.ops_sporing_avslutt;
  static String get a1_sporing_fjordfiske => languages.ops_sporing_fjordfiske;
  static String get a1_sporing_mens_du_venter => languages.ops_sporing_mens_du_venter;
  static String get a1_sporing_sammendrag => languages.ops_sporing_sammendrag;
  static String get a1_sporing_detaljer => languages.ops_sporing_detaljer;
  static String get a1_sporing_hjelp => languages.ops_sporing_hjelp;

  // ── completion layer ────────────────────────────────────────────────────
  static String get a1_sporing_bankid => languages.ops_sporing_bankid;
  static String get a1_sporing_kode_tittel => languages.ops_sporing_kode_tittel;
  static String get a1_sporing_kode_under => languages.ops_sporing_kode_under;
  static String get a1_sporing_kode_offline => languages.ops_sporing_kode_offline;
  static String get a1_sporing_kode_no_door => languages.ops_sporing_kode_no_door;
  static String get a1_sporing_kode_laast => languages.ops_sporing_kode_laast;
  static String get a1_sporing_kode_bekreftet => languages.ops_sporing_kode_bekreftet;
  static String reasonCopy(String key) {
    switch (key) {
      case 'a1_sporing_kode_reason_value':
        return _t('Denne leveringen har høy verdi, så vi ber om kode ved døren.', 'This delivery is high value, so we ask for a code at the door.');
      case 'a1_sporing_kode_reason_age_restricted':
        return _t('Varene har aldersgrense, så budet må sjekke kode ved levering.', 'The goods are age restricted, so the courier checks a code at delivery.');
      case 'a1_sporing_kode_reason_customer_choice':
        return _t('Du har valgt kode ved levering.', 'You chose a code at delivery.');
      case 'a1_sporing_kode_reason_business':
        return _t('Levering til bedriftsadresse krever kode.', 'Delivery to a business address needs a code.');
      default:
        return _t('Vi ber om kode ved døren på denne leveringen.', 'We ask for a code at the door on this delivery.');
    }
  }

  static String a1_sporing_valg_tittel(String butikk) => languages.ops_sporing_valg_tittel(butikk);
  static String get a1_sporing_valg_line => languages.ops_sporing_valg_line;
  static String get a1_sporing_vent => languages.ops_sporing_vent;
  static String get a1_sporing_avbestill => languages.ops_sporing_avbestill;
  static String get a1_sporing_venter => languages.ops_sporing_venter;
  static String get a1_sporing_refundert => languages.ops_sporing_refundert;
  static String get a1_sporing_uten_nett => languages.ops_sporing_uten_nett;

  // ── notifications (store-delivered variant) ─────────────────────────────
  static String get a1_sporing_notif_store_on_the_way => languages.ops_sporing_notif_store_on_the_way;
  static String get a1_sporing_notif_store_delivered => languages.ops_sporing_notif_store_delivered;

  // ── Hjelp ───────────────────────────────────────────────────────────────
  static String a1_sporing_hjelp_ring(String rolle) => languages.ops_sporing_hjelp_ring(rolle);
  static String a1_sporing_hjelp_melding(String rolle) => languages.ops_sporing_hjelp_melding(rolle);
  static String get a1_sporing_hjelp_ring_kort => languages.ops_sporing_hjelp_ring_kort;
  static String get a1_sporing_hjelp_send => languages.ops_sporing_hjelp_send;
  static String a1_sporing_hjelp_kort_bud(int min, String siden, String rating) => languages.ops_sporing_hjelp_kort_bud(min, siden, rating);
  static String get a1_sporing_hjelp_kort_bud_enkel => languages.ops_sporing_hjelp_kort_bud_enkel;
  static String get a1_sporing_hjelp_kort_butikk => languages.ops_sporing_hjelp_kort_butikk;
  static String get a1_sporing_hjelp_vanlige => languages.ops_sporing_hjelp_vanlige;
  static String get a1_sporing_hjelp_dor => languages.ops_sporing_hjelp_dor;
  static String get a1_sporing_hjelp_dor_line => languages.ops_sporing_hjelp_dor_line;
  static String get a1_sporing_hjelp_mangler => languages.ops_sporing_hjelp_mangler;
  static String get a1_sporing_hjelp_mangler_line => languages.ops_sporing_hjelp_mangler_line;
  static String get a1_sporing_hjelp_kundeservice => languages.ops_sporing_hjelp_kundeservice;
  static String get a1_sporing_hjelp_kundeservice_line => languages.ops_sporing_hjelp_kundeservice_line;
  static String get a1_sporing_ring_kobler => languages.ops_sporing_ring_kobler;
  static String get a1_sporing_ring_maskert => languages.ops_sporing_ring_maskert;
  static String get a1_sporing_ring_ingen => languages.ops_sporing_ring_ingen;
  static String get a1_sporing_demp => languages.ops_sporing_demp;
  static String get a1_sporing_avslutt_samtale => languages.ops_sporing_avslutt_samtale;
  static String get a1_sporing_hoyttaler => languages.ops_sporing_hoyttaler;
  static String get a1_sporing_tilbake => languages.ops_sporing_tilbake;
  static String get a1_sporing_aktiv => languages.ops_sporing_aktiv;
  static String get a1_sporing_skriver => languages.ops_sporing_skriver;
  static String get a1_sporing_meld_hint => languages.ops_sporing_meld_hint;
  static String get a1_sporing_send => languages.ops_sporing_send;
  static List<String> get a1_sporing_hurtig => _en ? const ['Ring on the door', 'Leave it at the door', 'I am 2 min late'] : const ['Ring på', 'Sett den utenfor døra', 'Jeg er 2 min sen'];
  static String a1_sporing_dor_tittel(String navn) => languages.ops_sporing_dor_tittel(navn);
  static String get a1_sporing_lev_adresse => languages.ops_sporing_lev_adresse;
  static String get a1_sporing_veibeskrivelse => languages.ops_sporing_veibeskrivelse;
  static String get a1_sporing_dor_hint => languages.ops_sporing_dor_hint;
  static String a1_sporing_send_til(String navn) => languages.ops_sporing_send_til(navn);
  static String a1_sporing_ring_navn(String navn) => languages.ops_sporing_ring_navn(navn);
  static String get a1_sporing_skriv_selv => languages.ops_sporing_skriv_selv;
  static String get a1_sporing_hva_mangler => languages.ops_sporing_hva_mangler;
  static String get a1_sporing_mangler_line => languages.ops_sporing_mangler_line;
  static String get a1_sporing_mangler_refusjon => languages.ops_sporing_mangler_refusjon;
  static String a1_sporing_meld_mangler(int n) => _t(n == 0 ? 'Velg det som mangler' : 'Meld $n som mangler', n == 0 ? 'Pick what is missing' : 'Report $n missing');
  static String get a1_sporing_ks_tittel => languages.ops_sporing_ks_tittel;
  static String get a1_sporing_ks_line => languages.ops_sporing_ks_line;
  static String get a1_sporing_ks_chat => languages.ops_sporing_ks_chat;
  static String get a1_sporing_ks_chat_line => languages.ops_sporing_ks_chat_line;
  static String get a1_sporing_ks_ring => languages.ops_sporing_ks_ring;
  static String get a1_sporing_ks_ring_line => languages.ops_sporing_ks_ring_line;
  static String a1_sporing_ks_ordre(String nr) => languages.ops_sporing_ks_ordre(nr);
  static String get a1_sporing_ks_nummer => languages.ops_sporing_ks_nummer;
  static String get a1_sporing_sendt_tittel => languages.ops_sporing_sendt_tittel;
  static String a1_sporing_sendt_tekst(String rolle) => languages.ops_sporing_sendt_tekst(rolle);
  static String get a1_sporing_meldt_tittel => languages.ops_sporing_meldt_tittel;
  static String get a1_sporing_ferdig => languages.ops_sporing_ferdig;
  static String get a1_sporing_butikken => languages.ops_sporing_butikken;
  static String get a1_sporing_bud => languages.ops_sporing_bud;
  static String get a1_sporing_Butikken => languages.ops_sporing_Butikken;
  static String get a1_sporing_Budet => languages.ops_sporing_Budet;

  // ── Levert ──────────────────────────────────────────────────────────────
  static String get a1_sporing_levert_punkt => languages.ops_sporing_levert_punkt;
  static String get a1_sporing_poeng_for_ordren => languages.ops_sporing_poeng_for_ordren;
  static String a1_sporing_liga_gap(int n, int plass) => languages.ops_sporing_liga_gap(n, plass);
  static String a1_sporing_forste_gang(int n, String butikk) => languages.ops_sporing_forste_gang(n, butikk);
  static String get a1_sporing_en_gang => languages.ops_sporing_en_gang;
  static String a1_sporing_levert_til_deg(String hvem) => languages.ops_sporing_levert_til_deg(hvem);
  static String a1_sporing_levert_til_deg_uten(String hvem) => languages.ops_sporing_levert_til_deg_uten(hvem);
  static String a1_sporing_takk(String navn) => languages.ops_sporing_takk(navn);
  static String get a1_sporing_hvordan => languages.ops_sporing_hvordan;
  static String get a1_sporing_takk_vurdering => languages.ops_sporing_takk_vurdering;
  static String get a1_sporing_noe_galt => languages.ops_sporing_noe_galt;
  static String get a1_sporing_ikke_funnet => languages.ops_sporing_ikke_funnet;
  static String get a1_sporing_laster => languages.ops_sporing_laster;

  // ── demo panel ──────────────────────────────────────────────────────────
  static String get a1_sporing_demo_ny => languages.ops_sporing_demo_ny;
  static String get a1_sporing_demo_neste => languages.ops_sporing_demo_neste;
  static String get a1_sporing_demo_usett => languages.ops_sporing_demo_usett;
  static String get a1_sporing_demo_kode_ok => languages.ops_sporing_demo_kode_ok;
  static String get a1_sporing_demo_pin_feil => languages.ops_sporing_demo_pin_feil;
  static String get a1_sporing_demo_offline => languages.ops_sporing_demo_offline;

  // ── Launch (Step 8): the scene screen, the sheets and Levert ────────────
  static String get a1_sporing_live_ord => 'LIVE';
  static String get a1_sporing_tilbake_knapp => _t('Tilbake', 'Back');
  static String get a1_sporing_hjelp_knapp => _t('Hjelp', 'Help');
  static String a1_sporing_levert_av_label(String s) => _t('Levert av $s', 'Delivered by $s');
  static String get a1_sporing_mottatt_stempel => 'MOTTATT';
  static String get a1_sporing_klar_stempel => 'KLAR';
  static String get a1_sporing_tilberedes_stempel => 'TILBEREDES';
  static String a1_sporing_kl_stempel(String t) => _t('kl. $t', 'at $t');
  static String get a1_sporing_koker => _t('Det koker greit her på kjøkkenet, men jeg er i rute!', 'It is busy in the kitchen, but I am on schedule!');
  static String a1_sporing_i_disken_si(String navn) => _t('Den står i disken. Si «$navn» så får du den.', 'It is at the counter. Say «$navn» and it is yours.');
  static String get a1_sporing_ankommer => _t('Ankommer om', 'Arriving in');
  static String a1_sporing_km_igjen(String km) => _t('$km km igjen', '$km km left');
  static String get a1_sporing_hjem_etikett => _t('hjem', 'home');
  static String get a1_sporing_god_appetitt => _t('God appetitt!', 'Enjoy your meal!');
  static String get a1_sporing_haaper_smaker => _t('Håper det smaker.', 'Hope it tastes good.');
  static String get a1_sporing_levert_haaper => _t('Levert.\nHåper det smaker.', 'Delivered.\nHope it tastes good.');
  static String get a1_sporing_spart => 'SPART TID';
  static String a1_sporing_steg_av(int n, int of) => _t('Steg $n av $of', 'Step $n of $of');
  static String get a1_sporing_folger => _t('· følger ærendet ditt', '· following your errand');
  static String a1_sporing_neste_poeng(String navn, int poeng) => _t('Neste: $navn · +$poeng poeng', 'Next: $navn · +$poeng points');
  static String get a1_sporing_fullfort => _t('Oppdrag fullført', 'Errand complete');
  static String a1_sporing_fullfort_poeng(int poeng) => _t('Oppdrag fullført · +$poeng poeng totalt', 'Errand complete · +$poeng points in all');
  static String get a1_sporing_avslutt_bestillingen => _t('Avslutt bestillingen', 'Finish the order');
  static String get a1_sporing_mens_du_venter_kort => _t('mens du venter', 'while you wait');
  static String get a1_sporing_vis_veien_knapp => _t('Vis veien', 'Show the way');
  static String a1_sporing_min_aa_gaa(String adr, int min) => _t('$adr · $min min å gå', '$adr · $min min walk');
  static String get a1_sporing_chat_bud => _t('Chat med budet', 'Chat with the courier');
  static String get a1_sporing_ring_butikken => _t('Ring butikken', 'Call the shop');
  // The Bestillingsdetaljer sheet.
  static String get a1_sporing_ordresammendrag => _t('Ordresammendrag', 'Order summary');
  static String get a1_sporing_bestillingsdetaljer => _t('Bestillingsdetaljer', 'Order details');
  static String a1_sporing_ordre_over(String kode, String modus) => _t('Ordre $kode · $modus', 'Order $kode · $modus');
  static String get a1_sporing_levering_ord => _t('levering', 'delivery');
  static String get a1_sporing_henting_ord => _t('henting', 'pickup');
  static String get a1_sporing_leveres_til => _t('LEVERES TIL', 'DELIVERED TO');
  static String get a1_sporing_hentes_hos_stor => _t('HENTES HOS', 'PICKED UP AT');
  static String get a1_sporing_ring_paa => _t('Ring på', 'Ring the bell');
  static String a1_sporing_ring_paa_hos(String navn) => _t('Ring på hos $navn', 'Ring the bell at $navn');
  static String a1_sporing_du_henter(String navn) => _t('Du henter i disken · si «$navn»', 'You pick up at the counter · say «$navn»');
  static String get a1_sporing_bestilling_stor => 'BESTILLING';
  static String a1_sporing_varer(int n) => _t('$n ${n == 1 ? 'vare' : 'varer'}', '$n ${n == 1 ? 'item' : 'items'}');
  static String get a1_sporing_se_alt => _t('Se alt', 'See all');
  static String get a1_sporing_betalt_med_vipps => _t('BETALT MED VIPPS', 'PAID WITH VIPPS');
  static String a1_sporing_betalt_kl(String t) => _t('Betalt $t', 'Paid $t');
  static String get a1_sporing_kvittering => _t('Kvittering', 'Receipt');
  static String get a1_sporing_klar_knapp => _t('Klar', 'Done');
  static String get a1_sporing_ordrestatus => 'ORDRESTATUS';
  static String get a1_sporing_din_bestilling => _t('Din bestilling', 'Your order');
  static String get a1_sporing_totalsum => _t('Totalsum', 'Total');
  static String get a1_sporing_betaling => _t('Betaling', 'Payment');
  static String get a1_sporing_betalt_ord => _t('Betalt', 'Paid');
  static String get a1_sporing_butikken_tittel => _t('Butikken', 'The shop');
  static String get a1_sporing_ordrenummer => 'ORDRENUMMER';
  static String get a1_sporing_aerend_id => 'ÆREND-ID';
  static String get a1_sporing_tidsstempel => 'TIDSSTEMPEL';
  static String get a1_sporing_kvittering_stor => 'KVITTERING';
  static String get a1_sporing_meg_bestillinger => _t('Meg · Bestillinger', 'Me · Orders');
  static String get a1_sporing_kontakt_kundeservice => _t('Kontakt kundeservice', 'Contact customer service');
  static String get a1_sporing_kvittering_feil => _t('Kvitteringen kan ikke lages akkurat nå', "The receipt can't be made right now");
  static String a1_sporing_kvittering_sendt(String epost) => _t('Kvittering sendt til $epost', 'Receipt sent to $epost');
  // Levert.
  static String a1_sporing_min_for_tiden(String t, int m) => _t('$t · ${minutterOrd(m)} før tiden', '$t · ${minutterOrd(m)} early');
  static String a1_sporing_balansen(String n) => _t('Balansen din: $n poeng', 'Your balance: $n points');
  static String get a1_sporing_poeng_ord => _t('poeng', 'points');
  static String get a1_sporing_takk_til_budet => _t('Takk til budet', 'Thank the courier');
  static String a1_sporing_tips_linje(String navn) =>
      _t('$navn får hele beløpet, med én gang. Frivillig og aldri forventet.', '$navn gets the whole amount, right away. Voluntary and never expected.');
  static String a1_sporing_tips_til(String navn) => _t('100 % til $navn', '100 % to $navn');
  static String a1_sporing_tips_sendt(int kr, String navn) => _t('Tips $kr kr sendt til $navn', 'Tip $kr kr sent to $navn');
  static String get a1_sporing_ikke_naa => _t('Ikke nå', 'Not now');
  static String get a1_sporing_hvordan_gikk_leveringen => _t('Hvordan gikk leveringen?', 'How did the delivery go?');
  static String a1_sporing_ett_trykk(String butikk, String navn) => _t('Ett trykk. Går til $butikk og $navn, aldri til andre kunder.', 'One tap. Goes to $butikk and $navn, never to other customers.');
  static String get a1_sporing_alt_stemte => _t('Alt stemte', 'Everything was right');
  static String get a1_sporing_noe_var_galt => _t('Noe var galt', 'Something was wrong');
  static String get a1_sporing_takk_sendt => _t('Takk · sendt', 'Thanks · sent');
  static String get a1_sporing_ks_hei => _t('Hei, dette er Ærend i Bergen. Vi har mottatt saken. Hva kan vi hjelpe med?', 'Hi, this is Ærend in Bergen. We have received the case. How can we help?');
  static String get a1_sporing_ks_ordre_for => _t('Ordre ', 'Order ');
  static String get a1_sporing_ks_ordre_hale => _t(' er allerede lagt ved, så du slipper å forklare.', ' is already attached, so you need not explain.');
  static String a1_sporing_lokalt(String butikk, int n) =>
      _t('Du støttet en lokal butikk i Bergen — ditt $n. lokale ærend denne måneden.', 'You supported a local shop in Bergen — your $n. local errand this month.');
  static String get a1_sporing_levert_poeng_toast => _t('Levert · poeng lagt til', 'Delivered · points added');
  // Help sheet (Launch wording).
  /// «sykler» / «sykler siden mars» (courier.since; the year when not this year).
  static String a1_sporing_sykler_siden(DateTime? siden) {
    if (siden == null) return _t('sykler', 'cycles');
    const no = ['januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'];
    const en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final aar = siden.year == DateTime.now().year ? '' : ' ${siden.year}';
    return _t('sykler siden ${no[siden.month - 1]}$aar', 'cycling since ${en[siden.month - 1]}$aar');
  }
  static String a1_sporing_er_budet(String navn) => _t('$navn er budet ditt', '$navn is your courier');
  static String a1_sporing_leverer_selv(String s) => _t('$s leverer selv', '$s delivers itself');
  static String get a1_sporing_ring_kort => _t('Ring', 'Call');
  static String get a1_sporing_send_melding => _t('Send melding', 'Send a message');
  static String get a1_sporing_feil_vare => _t('Feil vare', 'Wrong item');
  static String get a1_sporing_fikk_noe_annet => _t('Fikk noe annet', 'Got something else');
  static String get a1_sporing_kom_aldri => _t('Kom aldri', 'Never arrived');
  static String get a1_sporing_staar_som_levert => _t('Står som levert', 'Marked as delivered');
  static String get a1_sporing_snakk_med => _t('Snakk med Ærend i Bergen', 'Talk to Ærend in Bergen');
  static String get a1_sporing_ks_aapent => _t('Kundeservice · åpent til 23:00', 'Customer service · open until 23:00');
  static String get a1_sporing_ringer => _t('Ringer …', 'Calling …');
  static String a1_sporing_samtale_med(String navn) => _t('Samtale med $navn', 'Call with $navn');
  static String get a1_sporing_tilbake_til_hjelp => _t('Tilbake til hjelp', 'Back to help');
  static String get a1_sporing_aktiv_naa => _t('Aktiv nå · svarer raskt', 'Active now · replies quickly');
  static String a1_sporing_skriv_til(String navn) => _t('Skriv til $navn …', 'Write to $navn …');
  static List<String> get a1_sporing_hurtig_launch =>
      _en ? const ['I am outside', 'Ring the bell', 'How long?', 'Leave it at the door'] : const ['Jeg står utenfor', 'Ring på', 'Hvor lang tid?', 'Legg den ved døra'];
  static String a1_sporing_dette_ser(String navn) => _t('Dette er det $navn ser nå.', 'This is what $navn sees now.');
  static String a1_sporing_send_veibeskrivelsen(String navn) => _t('Send veibeskrivelsen til $navn', 'Send the directions to $navn');
  static String get a1_sporing_hva_var_feil => _t('Hvilken vare var feil?', 'Which item was wrong?');
  static String get a1_sporing_feil_line => _t('Trykk på det som ikke stemte. Vi ordner resten.', 'Tap what was wrong. We handle the rest.');
  static String get a1_sporing_mangler_line_launch => _t('Trykk på det som ikke kom. Vi ordner resten.', 'Tap what did not arrive. We handle the rest.');
  static String a1_sporing_svarer_innen(int min) =>
      _t('Vi ser på det og svarer innen $min min. Du følger saken på bestillingen.', 'We look at it and answer within $min min. You follow the case on the order.');
  static String a1_sporing_meld_fra_om(int n) =>
      _t(n == 0 ? 'Velg det som mangler' : 'Meld fra om $n ${n == 1 ? 'vare' : 'varer'}', n == 0 ? 'Pick what is missing' : 'Report $n ${n == 1 ? 'item' : 'items'}');
  static String get a1_sporing_aerend_i_bergen => _t('Ærend i Bergen', 'Ærend in Bergen');
  static String get a1_sporing_aapent_til => _t('Åpent til 23:00 · svarer innen 2 min', 'Open until 23:00 · replies within 2 min');
  static String get a1_sporing_chat_med_oss => _t('Chat med oss', 'Chat with us');
  static String get a1_sporing_raskest => _t('Raskest · Kari og Ola er på vakt', 'Fastest · Kari and Ola are on duty');
  static String get a1_sporing_ring_nummer => _t('Ring 55 00 12 34', 'Call 55 00 12 34');
  /// «Ring 55 00 12 34» with the number from `support/config` (backend plan Step 5).
  static String a1_sporing_ring_nummer_til(String tlf) => _t('Ring $tlf', 'Call $tlf');
  static String get a1_sporing_vanlig_takst => _t('Vanlig takst · ca. 1 min ventetid', 'Standard rate · about 1 min wait');
  static String get a1_sporing_vi_har_mottatt => _t('Vi har mottatt saken.', 'We have received the case.');
  static String a1_sporing_fikk_beskjeden(String navn) => _t('$navn har fått beskjeden', '$navn got the message');
  static String get a1_sporing_veibeskrivelse_sendt => _t('Veibeskrivelsen er sendt. Svar kommer vanligvis innen ett minutt.', 'The directions were sent. A reply usually comes within a minute.');
  static String get a1_sporing_uten_nett_kode => _t('Uten nett vises bare PIN.', 'Without a connection only the PIN shows.');
  static String a1_sporing_leverer_bare(String navn) => _t('$navn leverer bare til deg.', '$navn delivers only to you.');
  static String a1_sporing_gir_bare_ut(String butikk) => _t('$butikk gir bare ut posen til deg.', '$butikk hands the bag only to you.');
  static String get a1_sporing_vis_disken => _t('VIS DENNE I DISKEN', 'SHOW THIS AT THE COUNTER');
  static String get a1_sporing_vis_sjaforen => _t('VIS DENNE TIL SJÅFØREN', 'SHOW THIS TO THE DRIVER');
  static String get a1_sporing_vis_budet => _t('VIS DENNE TIL BUDET', 'SHOW THIS TO THE COURIER');
  static String get a1_sporing_bankid_verifisert => _t('BankID-verifisert', 'BankID verified');
}
