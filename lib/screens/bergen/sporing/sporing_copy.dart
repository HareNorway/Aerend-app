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
  static String a1_sporing_levert_min_for(int m) => _t(
    m == 1 ? 'Levert · ett minutt før tiden' : 'Levert · $m minutter før tiden',
    'Delivered · $m min early',
  );
  static String get a1_sporing_avbestilt => languages.ops_sporing_avbestilt;
  static String a1_sporing_gave_venter(String navn) => languages.ops_sporing_gave_venter(navn);

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
  static String a1_sporing_steg(int n, int of) => languages.ops_sporing_steg(n, of);
  static String a1_sporing_pluss_poeng(int n) => languages.ops_sporing_pluss_poeng(n);

  // ── Ægil-veileder ───────────────────────────────────────────────────────
  static String get a1_sporing_aegil => languages.ops_sporing_aegil;
  static String get a1_sporing_aegil_folger => languages.ops_sporing_aegil_folger;
  static String a1_sporing_neste(String navn) => languages.ops_sporing_neste(navn);
  static String get a1_sporing_oppdrag_fullfort => languages.ops_sporing_oppdrag_fullfort;
  static String get a1_sporing_finner_bud_hint => languages.ops_sporing_finner_bud_hint;
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
  static List<String> get a1_sporing_hurtig => _en
      ? const ['Ring on the door', 'Leave it at the door', 'I am 2 min late']
      : const ['Ring på', 'Sett den utenfor døra', 'Jeg er 2 min sen'];
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
  static String a1_sporing_meld_mangler(int n) => _t(
    n == 0 ? 'Velg det som mangler' : 'Meld $n som mangler',
    n == 0 ? 'Pick what is missing' : 'Report $n missing',
  );
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
}
