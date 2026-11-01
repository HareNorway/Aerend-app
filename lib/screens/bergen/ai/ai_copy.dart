// ignore_for_file: non_constant_identifier_names
import '../../../utils/utils.dart';

/// Customer plan Step 14: every line of the AI-assistant feature (design
/// §4d: `aiInngang`, `aiVelg`, `aiQr`, `aiSamtykke`, `aiKoblet`,
/// `aiKoblede`, `aiDetalj`, `aiKobleFra`, `aiFeil`, `aiBekreft`, the
/// «Handlekurv fra assistent» screen, the overlays, the chips and the
/// Varsler items). The text lives in the ARB files (`lib/l10n/intl_*.arb`)
/// under the getter's own `cus_ai_*` name, or under the spec's suggested key
/// (agents spec §5, e.g. `assistants_entry`, `revoke_all`) where one fits.
abstract final class AiCopy {
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
  static String get cus_ai_hurtig_logo => languages.cus_ai_hurtig_logo;
  static String get cus_ai_hurtig_rad => languages.cus_ai_hurtig_rad;
  static String cus_ai_hurtig_sub_koblet(String navn) => languages.cus_ai_hurtig_sub_koblet(navn);
  static String get cus_ai_hurtig_sub => languages.cus_ai_hurtig_sub;
  static String get cus_ai_meg_rad => languages.assistants_entry;
  static String get cus_ai_meg_rad_sub => languages.cus_ai_meg_rad_sub;
  static String get cus_ai_meg_koblede => languages.cus_ai_meg_koblede;
  static String cus_ai_meg_koblede_sub(int n) => n == 0 ? languages.cus_ai_meg_koblede_sub_0 : (n == 1 ? languages.cus_ai_meg_koblede_sub_1 : languages.cus_ai_meg_koblede_sub_n(n));

  // aiInngang
  static String get cus_ai_inngang_tittel => languages.cus_ai_inngang_tittel;
  static String get cus_ai_inngang_linje => languages.cus_ai_inngang_linje;
  static String get cus_ai_inngang_aegil => languages.cus_ai_inngang_aegil;
  static String get cus_ai_stottede => languages.cus_ai_stottede;
  static String get cus_ai_koblet => languages.cus_ai_koblet;
  static String get cus_ai_ikke_koblet => languages.cus_ai_ikke_koblet;
  static String get cus_ai_snarveier => languages.cus_ai_snarveier;
  static String get cus_ai_snarvei => languages.cus_ai_snarvei;
  static String cus_ai_allerede_koblet(String navn) => languages.cus_ai_allerede_koblet(navn);
  static String get cus_ai_se_rettigheter => languages.cus_ai_se_rettigheter;
  static String get cus_ai_slik_fungerer => languages.cus_ai_slik_fungerer;
  static String cus_ai_fl1(String navn) => languages.cus_ai_fl1(navn);
  static String get cus_ai_fl2 => languages.cus_ai_fl2;
  static String get cus_ai_fl3 => languages.cus_ai_fl3;
  static String cus_ai_steg_tittel(String navn) => languages.cus_ai_steg_tittel(navn);
  static List<String> cus_ai_steg(String navn) => [
    languages.cus_ai_steg_1(navn),
    languages.cus_ai_steg_2(navn),
    languages.cus_ai_steg_3(navn),
  ];
  static List<String> get cus_ai_steg_siri => [
    languages.cus_ai_steg_siri_1,
    languages.cus_ai_steg_siri_2,
    languages.cus_ai_steg_siri_3,
  ];
  static String get cus_ai_steg_hint => languages.cus_ai_steg_hint;
  static String get cus_ai_steg_hint_sist => languages.cus_ai_steg_hint_sist;
  static String get cus_ai_klart => languages.cus_ai_klart;
  static String cus_ai_hva_ser(String navn) => languages.cus_ai_hva_ser(navn);
  static String get cus_ai_kan_se => languages.cus_ai_kan_se;
  static String get cus_ai_ser_aldri => languages.cus_ai_ser_aldri;
  static List<String> get cus_ai_kan_se_liste => [languages.cus_ai_kan_se_liste_1, languages.cus_ai_kan_se_liste_2, languages.cus_ai_kan_se_liste_3];
  static List<String> get cus_ai_ser_aldri_liste => [languages.cus_ai_ser_aldri_liste_1, languages.cus_ai_ser_aldri_liste_2];
  static String get cus_ai_les_mer => languages.cus_ai_les_mer;
  static String get cus_ai_bruk_siri => languages.cus_ai_bruk_siri;
  static String get cus_ai_siri_linje => languages.cus_ai_siri_linje;
  static List<String> get cus_ai_siri_snarveier => [languages.cus_ai_siri_snarveier_1, languages.cus_ai_siri_snarveier_2, languages.cus_ai_siri_snarveier_3];
  static String cus_ai_siri_antall(int n) => n == 0 ? languages.cus_ai_siri_antall_0 : languages.cus_ai_siri_antall_n(n);
  static String get cus_ai_siri_alle => languages.cus_ai_siri_alle;
  static String get cus_ai_siri_lagt => languages.cus_ai_siri_lagt;
  static String cus_ai_snarvei_lagt(String s) => languages.cus_ai_snarvei_lagt(s);
  static String get cus_ai_snarvei_fjernet => languages.cus_ai_snarvei_fjernet;
  static String cus_ai_koble_til(String navn) => languages.cus_ai_koble_til(navn);
  static String get cus_ai_vis_qr => languages.cus_ai_vis_qr;
  static String get cus_ai_bekrefter_alltid => languages.cus_ai_bekrefter_alltid;
  static String get cus_ai_menyer_synlige => languages.cus_ai_menyer_synlige;

  // aiVelg
  static String get cus_ai_velg_tittel => languages.cus_ai_velg_tittel;
  static String get cus_ai_velg_linje => languages.cus_ai_velg_linje;
  static String cus_ai_velg_koblet_under(int kr, String bet) => languages.cus_ai_velg_koblet_under(nf(kr), bet);
  static String get cus_ai_velg_ukoblet_under => languages.cus_ai_velg_ukoblet_under;
  static String get cus_ai_velg_siri_under => languages.cus_ai_velg_siri_under;
  static String get cus_ai_bestill => languages.cus_ai_bestill;
  static String get cus_ai_legg_til => languages.cus_ai_legg_til;
  static String get cus_ai_ingen_bestilling => languages.cus_ai_ingen_bestilling;
  static String get cus_ai_koble => languages.cus_ai_koble;
  static List<String> get cus_ai_velg_steg => [languages.cus_ai_velg_steg_1, languages.cus_ai_velg_steg_2, languages.cus_ai_velg_steg_3];
  static String cus_ai_bestill_med(String navn) => languages.cus_ai_bestill_med(navn);
  static String get cus_ai_lukk => languages.cus_ai_lukk;

  // aiQr
  static String cus_ai_qr_tittel(String navn) => languages.cus_ai_qr_tittel(navn);
  static String cus_ai_qr_linje_mobil(String navn) => languages.cus_ai_qr_linje_mobil(navn);
  static String cus_ai_qr_linje_qr(String navn) => languages.cus_ai_qr_linje_qr(navn);
  static String get cus_ai_paa_mobilen => languages.cus_ai_paa_mobilen;
  static String get cus_ai_annen_enhet => languages.cus_ai_annen_enhet;
  static String get cus_ai_begge_appene => languages.cus_ai_begge_appene;
  static String get cus_ai_eller_kode => languages.cus_ai_eller_kode;
  static String cus_ai_gyldig_min(int m) => languages.cus_ai_gyldig_min(m);
  static String cus_ai_lim_inn(String navn) => languages.cus_ai_lim_inn(navn);
  static String get cus_ai_kopier_kode => languages.cus_ai_kopier_kode;
  static String get cus_ai_kopiert => languages.cus_ai_kopiert;
  static String cus_ai_kode_kopiert(String kode, String navn) => languages.cus_ai_kode_kopiert(kode, navn);
  static String cus_ai_lenke_kopiert(String navn) => languages.cus_ai_lenke_kopiert(navn);
  static String cus_ai_venter(String navn) => languages.cus_ai_venter(navn);
  static String cus_ai_brukte_koden(String navn) => languages.cus_ai_brukte_koden(navn);
  static String cus_ai_kode_for(String navn, int m) => languages.cus_ai_kode_for(navn, m);
  static List<String> cus_ai_qr_steg_mobil(String navn) => [languages.cus_ai_qr_steg_mobil_1(navn), languages.cus_ai_qr_steg_mobil_2(navn), languages.cus_ai_qr_steg_mobil_3];
  static List<String> cus_ai_qr_steg_qr(String navn) => [languages.cus_ai_qr_steg_qr_1(navn), languages.cus_ai_qr_steg_qr_2, languages.cus_ai_qr_steg_qr_3];
  static String cus_ai_apne(String navn) => languages.cus_ai_apne(navn);
  static String get cus_ai_jeg_har_skannet => languages.cus_ai_jeg_har_skannet;
  static String get cus_ai_tilbake => languages.cus_ai_tilbake;
  static String get cus_ai_kode_feil => languages.cus_ai_kode_feil;
  static String get cus_ai_kode_utlopt => languages.cus_ai_kode_utlopt;

  // aiSamtykke / rights
  static String cus_ai_sam_tittel(String navn) => languages.consent_title(navn);
  static String cus_ai_sam_linje(String navn) => languages.cus_ai_sam_linje(navn);
  static String cus_ai_sam_samtykke(String navn) => languages.consent_line(navn);
  static String get cus_ai_venter_svar => languages.cus_ai_venter_svar;
  static String get cus_ai_logg_inn_forst => languages.cus_ai_logg_inn_forst;
  static String get cus_ai_logg_tittel => languages.cus_ai_logg_tittel;
  static String get cus_ai_logg_linje => languages.cus_ai_logg_linje;
  static String cus_ai_logg_tx(String navn) => languages.cus_ai_logg_tx(navn);
  static String get cus_ai_logg_under => languages.cus_ai_logg_under;
  static String get cus_ai_logg_vipps => languages.cus_ai_logg_vipps;
  static String get cus_ai_logg_inn => languages.cus_ai_logg_inn;
  static String get cus_ai_avbryt => languages.cus_ai_avbryt;
  static String cus_ai_rett_tittel(String navn) => languages.cus_ai_rett_tittel(navn);
  static String cus_ai_rett_antall(int n) => languages.cus_ai_rett_antall(n);
  static String get cus_ai_alltid_paa => languages.cus_ai_alltid_paa;
  static String get cus_ai_paakrevd => languages.cus_ai_paakrevd;
  static List<List<String>> get cus_ai_rett => [
    [languages.consent_rights_catalog_read, languages.consent_rights_catalog_read_sub],
    [languages.consent_rights_cart_write, languages.consent_rights_cart_write_sub],
    [languages.consent_rights_orders_read, languages.consent_rights_orders_read_sub],
    [languages.consent_rights_orders_write, languages.consent_rights_orders_write_sub],
    [languages.consent_rights_profile_read, languages.consent_rights_profile_read_sub],
    [languages.consent_rights_support_write, languages.consent_rights_support_write_sub],
  ];
  static String get cus_ai_dine_grenser => languages.cus_ai_dine_grenser;
  static String cus_ai_grense_tittel(String navn) => languages.cus_ai_grense_tittel(navn);
  static String get cus_ai_maks_per_best => languages.consent_limit_per_order;
  static String get cus_ai_maks_per_dag => languages.consent_limit_per_day;
  static String cus_ai_forslag(int kr) => languages.cus_ai_forslag(nf(kr));
  static String get cus_ai_betaling => languages.consent_payment_mode;
  static String get cus_ai_betaling_under => languages.cus_ai_betaling_under;
  static String get cus_ai_vipps => 'Vipps';
  static String get cus_ai_lagret_kort => languages.cus_ai_lagret_kort;
  // Customer v2 Step 4: the saved card is a real payment path.
  static String get cus_ai_lagret_kort_hint => languages.cus_ai_lagret_kort_hint;
  static String get cus_ai_lagret_kort_mangler => languages.cus_ai_lagret_kort_mangler;
  static String get cus_ai_spor_hver_gang => languages.cus_ai_spor_hver_gang;
  static String get cus_ai_leveringsadresse => languages.consent_address_mode;
  static String cus_ai_hjemme_er(String adr) => languages.cus_ai_hjemme_er(adr);
  static String get cus_ai_hjemme => languages.cus_ai_hjemme;
  static String get cus_ai_del_bio => languages.consent_share_bio;
  static String cus_ai_bio_tx(String navn) => languages.cus_ai_bio_tx(navn);
  static String cus_ai_grense_sum(int per, int dag) => languages.cus_ai_grense_sum(nf(per), nf(dag));
  static String get cus_ai_per_best => languages.cus_ai_per_best;
  static String get cus_ai_levering => languages.cus_ai_levering;

  // aiKoblet
  static String cus_ai_koblet_tittel(String navn) => languages.linked_success_title(navn);
  static String cus_ai_koblet_linje(String navn) => languages.cus_ai_koblet_linje(navn);
  static String get cus_ai_koblet_naa => languages.cus_ai_koblet_naa;
  static String get cus_ai_prov_naa => languages.cus_ai_prov_naa;
  static String get cus_ai_prompt => languages.cus_ai_prompt;
  static String get cus_ai_kopier_forslag => languages.cus_ai_kopier_forslag;
  static String cus_ai_kopiert_lim(String navn) => languages.cus_ai_kopiert_lim(navn);
  static String cus_ai_bestill_naa(String navn) => languages.cus_ai_bestill_naa(navn);
  static String get cus_ai_ferdig => languages.cus_ai_ferdig;
  static String get cus_ai_endre_grenser => languages.cus_ai_endre_grenser;

  // aiKoblede
  static String get cus_ai_koblede_tittel => languages.linked_assistants_title;
  static String get cus_ai_koblede_tom => languages.linked_empty_title;
  static String cus_ai_koblede_linje(int n) => n == 0 ? cus_ai_koblede_tom : (n == 1 ? languages.cus_ai_koblede_linje_1 : languages.cus_ai_koblede_linje_n(n));
  static String get cus_ai_ingen_aktive => languages.cus_ai_ingen_aktive;
  static String get cus_ai_tom_tekst => languages.cus_ai_tom_tekst;
  static String get cus_ai_aktiv => languages.cus_ai_aktiv;
  static String get cus_ai_frakoblet => languages.cus_ai_frakoblet;
  static String cus_ai_sist_brukt(String naar, int kr) => languages.cus_ai_sist_brukt(naar, nf(kr));
  static String cus_ai_frakoblet_dato(String naar) => languages.cus_ai_frakoblet_dato(naar);
  static String get cus_ai_brukt_i_dag => languages.cus_ai_brukt_i_dag;
  static String cus_ai_av(String a, String b) => languages.cus_ai_av(a, b);
  static String get cus_ai_koble_fra_alle => languages.revoke_all;
  static String get cus_ai_slik_kobler => languages.assistants_how_to_link;
  static String get cus_ai_koble_ny => languages.cus_ai_koble_ny;
  static List<List<String>> get cus_ai_rett_kort => [['cart:write', languages.cus_ai_rett_kort_cart], ['orders:read', languages.cus_ai_rett_kort_orders], ['profile:read', languages.cus_ai_rett_kort_addresses], ['support:write', 'Support']];

  // aiDetalj
  static String cus_ai_detalj_linje(String navn) => languages.cus_ai_detalj_linje(navn);
  static String cus_ai_detalj_ikke(String navn) => languages.cus_ai_detalj_ikke(navn);
  static String cus_ai_koblet_til(String naar, String sist) => languages.cus_ai_koblet_til(naar, sist);
  static String get cus_ai_bestilling => languages.cus_ai_bestilling;
  static String get cus_ai_bestillinger => languages.cus_ai_bestillinger;
  static String get cus_ai_sist_brukt_lbl => languages.cus_ai_sist_brukt_lbl;
  static String get cus_ai_aktivitet => languages.activity_title;
  static String get cus_ai_ingen_aktivitet => languages.cus_ai_ingen_aktivitet;
  static String cus_ai_koble_fra(String navn) => languages.revoke_assistant(navn);
  static String cus_ai_koble_igjen(String navn) => languages.cus_ai_koble_igjen(navn);
  static String get cus_ai_ikke_koblet_hs => languages.cus_ai_ikke_koblet_hs;
  static String cus_ai_ikke_koblet_linje(String navn) => languages.cus_ai_ikke_koblet_linje(navn);
  static String get cus_ai_lagret => languages.cus_ai_lagret;
  static String get cus_ai_lagret_feil => languages.cus_ai_lagret_feil;
  static String cus_ai_akt(String tool) => switch (tool) {
    'search_stores' => languages.cus_ai_akt_search_stores,
    'search_products' => languages.cus_ai_akt_search_products,
    'get_store' => languages.cus_ai_akt_get_store,
    'get_product' => languages.cus_ai_akt_get_product,
    'create_cart' => languages.cus_ai_akt_create_cart,
    'update_cart' => languages.cus_ai_akt_update_cart,
    'quote' => languages.cus_ai_akt_quote,
    'start_checkout' => languages.cus_ai_akt_start_checkout,
    'confirm_order' => languages.cus_ai_akt_confirm_order,
    'list_orders' || 'get_order' => languages.cus_ai_akt_orders,
    'track_order' => languages.cus_ai_akt_track_order,
    'reorder' => languages.cus_ai_akt_reorder,
    'get_profile' || 'list_addresses' || 'list_favorites' => languages.cus_ai_akt_profile,
    'open_support' => languages.cus_ai_akt_open_support,
    _ => tool,
  };

  // aiKobleFra
  static String cus_ai_fra_tittel(String navn) => languages.cus_ai_fra_tittel(navn);
  static String get cus_ai_fra_alle_tittel => languages.cus_ai_fra_alle_tittel;
  static String cus_ai_fra_linje(String navn) => languages.cus_ai_fra_linje(navn);
  static String get cus_ai_fra_alle_linje => languages.cus_ai_fra_alle_linje;
  static String get cus_ai_mister => languages.cus_ai_mister;
  static String get cus_ai_alle_mister => languages.cus_ai_alle_mister;
  static List<String> get cus_ai_fra_info => [languages.cus_ai_fra_info_1, languages.cus_ai_fra_info_2, languages.cus_ai_fra_info_3];
  static String get cus_ai_koble_fra_cta => languages.cus_ai_koble_fra_cta;
  static String cus_ai_er_koblet_fra(String navn) => languages.cus_ai_er_koblet_fra(navn);
  static String get cus_ai_alle_koblet_fra => languages.cus_ai_alle_koblet_fra;
  static String cus_ai_assistenter(int n) => n == 1 ? languages.cus_ai_assistenter_1 : languages.cus_ai_assistenter_n(n);

  // aiFeil
  static String cus_ai_feil_ikke_koblet(String navn) => languages.cus_ai_feil_ikke_koblet(navn);
  static String cus_ai_feil_ikke_koblet_linje(String navn) => languages.cus_ai_feil_ikke_koblet_linje(navn);
  static String get cus_ai_ikke_koblet_enna => languages.cus_ai_ikke_koblet_enna;
  static String get cus_ai_feil_bekreft => languages.cus_ai_feil_bekreft;
  static String cus_ai_feil_bekreft_linje(int kr) => languages.cus_ai_feil_bekreft_linje(nf(kr));
  static String get cus_ai_se_bestillingen => languages.cus_ai_se_bestillingen;
  static String get cus_ai_feil_generisk => languages.cus_ai_feil_generisk;
  static String get cus_ai_feil_generisk_linje => languages.cus_ai_feil_generisk_linje;
  static String get cus_ai_prov_igjen => languages.cus_ai_prov_igjen;
  static String get cus_ai_ingenting_bestilt => languages.nothing_ordered;
  static String cus_ai_grensen_din(int kr) => languages.cus_ai_grensen_din(nf(kr));

  // aiBekreft / aiKurv
  static String cus_ai_bekreft_tittel(String navn) => languages.confirm_request_title(navn);
  static String cus_ai_bekreft_linje(String butikk, String bet) => languages.cus_ai_bekreft_linje(butikk, bet);
  static String get cus_ai_med_vipps => languages.cus_ai_med_vipps;
  static String get cus_ai_med_kort => languages.cus_ai_med_kort;
  static String cus_ai_kurv_tittel(String navn) => languages.handoff_title(navn);
  static String cus_ai_fra(String navn) => languages.cus_ai_fra(navn);
  static String get cus_ai_ingenting_sendes => languages.cus_ai_ingenting_sendes;
  static String cus_ai_bygde(String navn) => languages.cus_ai_bygde(navn);
  static String cus_ai_ber_om(String navn) => languages.cus_ai_ber_om(navn);
  static String cus_ai_apnet_fra(String navn) => languages.cus_ai_apnet_fra(navn);
  static String cus_ai_foresporsel(String butikk) => languages.cus_ai_foresporsel(butikk);
  static String get cus_ai_henter_tilbud => languages.cus_ai_henter_tilbud;
  static String get cus_ai_varer => languages.cus_ai_varer;
  static String cus_ai_antall_varer(int n) => n == 1 ? languages.cus_ai_antall_varer_1 : languages.cus_ai_antall_varer_n(n);
  static String get cus_ai_utsolgt_naa => languages.item_sold_out;
  static String cus_ai_fjern_tx(String navn) => languages.cus_ai_fjern_tx(navn);
  static String get cus_ai_fjern_under => languages.cus_ai_fjern_under;
  static String get cus_ai_fjern => languages.cus_ai_fjern;
  static String get cus_ai_tilbudet_ditt => languages.cus_ai_tilbudet_ditt;
  static String get cus_ai_tilbudet_gjelder => languages.quote_valid_for;
  static String get cus_ai_bekreft_innen => languages.cus_ai_bekreft_innen;
  static String get cus_ai_leveringsvindu => languages.cus_ai_leveringsvindu;
  static String get cus_ai_leveres_til => languages.cus_ai_leveres_til;
  static String get cus_ai_totalt => languages.cus_ai_totalt;
  static String get cus_ai_ny_total => languages.quote_new_total;
  static String get cus_ai_ny => languages.cus_ai_ny;
  static String cus_ai_innenfor(int kr) => languages.within_limit(nf(kr));
  static String cus_ai_over(int kr) => languages.cus_ai_over(nf(kr));
  static String cus_ai_grense(int kr) => languages.cus_ai_grense(nf(kr));
  static String get cus_ai_endre_kurv => languages.cus_ai_endre_kurv;
  static String get cus_ai_endre_under => languages.cus_ai_endre_under;
  static String get cus_ai_avvis => languages.reject;
  static String get cus_ai_avvist => languages.cus_ai_avvist;
  static String get cus_ai_tilbud_utlopt => languages.quote_expired_title;
  static String get cus_ai_tilbud_utlopt_tx => languages.cus_ai_tilbud_utlopt_tx;
  static String get cus_ai_for_utlopt => languages.cus_ai_for_utlopt;
  static String cus_ai_for_utlopt_tx(String navn) => languages.cus_ai_for_utlopt_tx(navn);
  static String get cus_ai_for_utlopt_steg => languages.cus_ai_for_utlopt_steg;
  static String cus_ai_trukket(String navn) => languages.cus_ai_trukket(navn);
  static String get cus_ai_trukket_tx => languages.cus_ai_trukket_tx;
  static String get cus_ai_bet_feilet => languages.cus_ai_bet_feilet;
  static String get cus_ai_bet_feilet_tx => languages.cus_ai_bet_feilet_tx;
  static String get cus_ai_bytt_bet => languages.cus_ai_bytt_bet;
  static String cus_ai_betaler_med(String b) => languages.cus_ai_betaler_med(b);
  static String cus_ai_over_banner(int kr) => languages.over_limit_title(nf(kr));
  static String get cus_ai_over_banner_tx => languages.cus_ai_over_banner_tx;
  static String get cus_ai_bekreft_likevel => languages.cus_ai_bekreft_likevel;
  static String get cus_ai_bekreft_betal => languages.cus_ai_bekreft_betal;
  static String get cus_ai_logg_inn_fortsett => languages.cus_ai_logg_inn_fortsett;
  static String cus_ai_kurv_venter(String navn) => languages.cus_ai_kurv_venter(navn);
  static String get cus_ai_leverer_ikke => languages.out_of_coverage_title;
  static String get cus_ai_si_fra => languages.cus_ai_si_fra;
  static String get cus_ai_venteliste => languages.cus_ai_venteliste;
  static String get cus_ai_paa_venteliste => languages.cus_ai_paa_venteliste;
  static String cus_ai_paa_venteliste_tx(String sted) => languages.cus_ai_paa_venteliste_tx(sted);
  static String get cus_ai_til_hjem => languages.cus_ai_til_hjem;
  static String get cus_ai_endre => languages.cus_ai_endre;
  static String get cus_ai_godkjenner_vipps => languages.cus_ai_godkjenner_vipps;
  static String get cus_ai_bekreftes_faceid => languages.cus_ai_bekreftes_faceid;
  static String get cus_ai_kort_ved_bet => languages.cus_ai_kort_ved_bet;
  static String cus_ai_ingen_betdata(String navn) => languages.cus_ai_ingen_betdata(navn);
  static String cus_ai_betal_med_vipps(int kr) => languages.pay_with_vipps(nf(kr));
  static String get cus_ai_apner_vipps => languages.cus_ai_apner_vipps;
  static String get cus_ai_bekrefter => languages.cus_ai_bekrefter;
  static String get cus_ai_face_id => 'Face ID';
  static String cus_ai_aerend_sum(String sum) => 'Ærend · $sum';
  static String get cus_ai_tilbake_etterpaa => languages.cus_ai_tilbake_etterpaa;
  static String cus_ai_betaling_med(String b) => languages.cus_ai_betaling_med(b);
  static String cus_ai_bestilt_via(String navn, String kode) => languages.cus_ai_bestilt_via(navn, kode);
  static String get cus_ai_bestilling_feilet => languages.cus_ai_bestilling_feilet;
  static String get cus_ai_enhet_avvist => languages.cus_ai_enhet_avvist;

  // Overlays
  static String cus_ai_bytt_apner(String navn) => languages.cus_ai_bytt_apner(navn);
  static String cus_ai_bytt_fortsetter(String navn) => languages.cus_ai_bytt_fortsetter(navn);
  static String cus_ai_bytt_godkjenn(String navn) => languages.cus_ai_bytt_godkjenn(navn);
  static String cus_ai_bytt_si(String navn) => languages.cus_ai_bytt_si(navn);
  static String get cus_ai_bygger_kurv => languages.cus_ai_bygger_kurv;
  static String get cus_ai_tilbake_i => languages.cus_ai_tilbake_i;
  static String cus_ai_bytt_inn_kurv(String navn) => languages.cus_ai_bytt_inn_kurv(navn);
  static String cus_ai_bytt_inn_sam(String navn) => languages.cus_ai_bytt_inn_sam(navn);
  static String get cus_ai_push_naa => languages.cus_ai_push_naa;
  static String cus_ai_push_tittel(String navn) => languages.cus_ai_push_tittel(navn);
  static String cus_ai_push_tx(String navn, String sum, String butikk) => languages.cus_ai_push_tx(navn, sum, butikk);

  // Chips / Varsler
  static String cus_ai_via(String navn) => languages.via_assistant_chip(navn);
  static String cus_ai_bestilt_via_dato(String navn, String dato) => languages.cus_ai_bestilt_via_dato(navn, dato);
  static String get cus_ai_sporing_via => languages.cus_ai_sporing_via;
  static String get cus_ai_i_dag => languages.cus_ai_i_dag;
  static String get cus_ai_naa => languages.cus_ai_naa;
  static String get cus_ai_aldri => languages.cus_ai_aldri;

  // Customer v2 Step 2 (spec §4.10 A, B): the privacy line, linking on another device, the consent text's version, «Del Min bio» since.
  static String assistants_privacy_line(String navn) => languages.assistants_privacy_line(navn);
  static String get cus_ai_annen_enhet_tittel => languages.cus_ai_annen_enhet_tittel;
  static String cus_ai_annen_enhet_linje(String navn) => languages.cus_ai_annen_enhet_linje(navn);
  static String get cus_ai_kopier_kobling => languages.cus_ai_kopier_kobling;
  static String cus_ai_samtykke_versjon(String versjon) => languages.cus_ai_samtykke_versjon(versjon);
  static String cus_ai_bio_delt_siden(String dato) => languages.cus_ai_bio_delt_siden(dato);

  // Customer v2 Step 3 (spec §4.10 C, D; D2-5, D2-7): the method switch, waiting for the payment, «Bytt».
  static String cus_ai_betal_med_kort(int kr) => languages.pay_with_card(nf(kr));
  static String get cus_ai_betalingsmate => languages.cus_ai_betalingsmate;
  static String get cus_ai_venter_betaling => languages.cus_ai_venter_betaling;
  static String get cus_ai_venter_betaling_tx => languages.cus_ai_venter_betaling_tx;
  static String get cus_ai_sjekk_betaling => languages.cus_ai_sjekk_betaling;
  static String get cus_ai_bytt => languages.cus_ai_bytt;
  static String cus_ai_bytt_tittel(String navn) => languages.cus_ai_bytt_tittel(navn);
  static String get cus_ai_bytt_linje => languages.cus_ai_bytt_linje;
  static String get cus_ai_bytt_ingen => languages.cus_ai_bytt_ingen;
}
