import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart' show Visibility, Widget;
import 'package:path_provider/path_provider.dart';

import '../../common/auth/launch/lf_css.dart';
import '../kit/bergen_bakt.dart';
import '../kit/bergen_perf.dart';
import '../kit/perf_video_test.dart';
import '../kit/lag_cache.dart';
import 'hjem_hero.dart';

/// Debug builds only: `Documents/kunde_state.json` (Customer plan Step 0;
/// `hjem_state.json` when it is absent) pins Hjem's weather, uses the
/// prototype's sample floats, opens screens and sheets, so each state can be
/// compared with the prototype. Ignored in release. `kunde_state.json` also
/// takes neutral names: `route` / `routeArg` / `tab` for `rute` / `ruteArg` /
/// `fane`, and `sheet` for the open screen's sheet key (`sporingArk` with
/// `sporing`, else `megArk` on the Meg tab). Keys: `ui-tools/kunde_states.md`.
abstract final class HjemHarness {
  /// Pin the motion tier (`"full"`, `"lite"`, `"still"`; parity plan §3.1).
  static String? perf;

  /// Light «Ny i bydelen» on «Mat & fisk», as the prototype's sample data
  /// does (no shop joined locally in the last 14 days).
  static bool nyButikk = false;

  /// Kassen plays Betalt out of its slider for this order id (parity Step 6).
  static int? betaltKurv;

  static HjemVaer? vaer;
  static bool demoFloats = false;
  static int? unread;

  /// Scroll the sheet this far (device px) once loaded.
  static double? scroll;

  /// Perf: 2.5 s after load, animate the sheet to `rull` device px over
  /// `rullMs` (default 1800) and back, and log the frame times of that span
  /// (`HJEM_RULL …` in the log: n, over 16 ms, build/raster p50 p90 max).
  static double? rull;
  static int? rullMs;

  /// Perf: `vann: false` bypasses the sheet's water clip and foam (HjemVann);
  /// `heroAv: true` leaves the hero out — to measure what each costs.
  static bool vann = true, heroAv = false, skyggeAv = false, heroStille = false, arkStille = false;

  /// Open the Kommer snart sheet for this wheel slot.
  static int? snart;

  /// Show the Forundringspose card whatever the hour.
  static bool pose = false;

  /// Bergen Step 3: open the Forundringspose sheet of bag N on Utforsk's
  /// segment (`poseArk`), and press its «Sikre en» (`poseSikre`: one real cart
  /// line, no payment).
  static int? poseArk;
  static bool poseSikre = false, poseArkRull = false;

  /// Bergen Step 4: Butikkprofil's tab (`bpFane`: tilbud / aerend) and the
  /// post viewer at post N of that tab (`bpPost`).
  static String? bpFane;
  static int? bpPost;

  /// Open the window (`sone: 'vindu'`).
  static bool vindu = false;

  /// Show "Mens du var borte" with the prototype's three lines.
  static bool borte = false;

  /// Switch to this tab a moment after loading.
  static int? fane;

  /// Onboarding Step 1: start Ægil-runden at this step (0 = the intro), and
  /// run it in reduced motion (`onbRolig`, the design's tweak).
  static int? onbRunde;
  static bool onbRolig = false;

  /// Step 2: after the start step is reached, press «Neste» / «Vis meg» /
  /// «Start å handle» by itself 1.5 s later (`onbAuto`: neste | vismeg | start),
  /// so the stamp, the done card and the kai-hopp can be shot without taps.
  static String? onbAuto;

  /// Step 3: forget the onboarding state (local, and the server's answer for
  /// this session) before the trigger runs: the tour starts as for a new customer.
  static bool onbNull = false;

  /// Step 3: as if a delivery had been seen (the Hjem card's condition).
  static bool onbLevert = false;

  /// Step 4: force this Ægil-tips coach mark (the design's `cmTving`): goes to
  /// its screen and shows it; `kode` / `abo` need `sporing` / `levert` too.
  static String? onbTips;

  /// Onboarding Step 6: on Kategori › Produkter, press the hero's «+» once
  /// after the products load (a real cart line) so the stepper can be shot.
  static bool katLegg = false;

  /// Focus this wheel slot.
  static int? hjul;

  /// Open the address sheet (`'adresse'`) or the new-place sheet (`'ny'`).
  static String? adresse;

  /// Coverage for every address (`'dekket'`, `'pauset'`, `'ikke'`) while
  /// `/api/geo/coverage` is off locally.
  static String? dekning;

  /// Typed into the address search / the door note when the sheet opens.
  static String? adrSok, adrDor;

  /// Pick the first address suggestion.
  static bool adrVelg = false;

  /// Open Søk with this query (`""` for the overview).
  static String? sok;

  /// Søk's recent searches, written to the device before Søk opens:
  /// `[["sushi", 2], …]` (term, hours ago).
  static List<List<Object>>? sokNylig;

  /// Show the prototype's three "Populært i Bergen nå" rows while the local
  /// trending list is empty (no orders in the last seven days).
  static bool sokPop = false;

  /// Give the search field focus once Søk is open.
  static bool sokFokus = false;

  /// Open the Kategori screen for this wheel slot (0 Restaurant … 4 Gaver),
  /// on this tab (`'butikker'` / `'produkter'`).
  static int? kat;
  static String? katFane;

  /// Scroll the Kategori list this far (design px) once loaded.
  static double? katScroll;

  /// Open this store's page (`/bergen/butikk/{id}`), optionally with a
  /// product sheet (`butikkProdukt`) or the info sheet tab (`butikkInfo`:
  /// `a` / `t` / `m`). `butikkKat` passes the category the way Kategori
  /// does (the store page picks the Mote layout from it).
  static int? butikk;
  static String? butikkKat;
  static int? butikkProdukt;
  static String? butikkInfo;

  /// Scroll the store page this far (design px) once loaded.
  static double? butikkScroll;

  /// Pick this orb on the store page (0 Alt, 1 Tilbud when it has specials).
  static int? butikkOrb;

  /// Add these products to the (real, local) cart once the store page is
  /// open, the way its + keys do; `butikkMini` opens the basket list.
  static List<int>? butikkLegg;

  /// Empty the basket (through the app's own cart API) before `butikkLegg`.
  static bool kurvTom = false;

  /// Scroll the Kurv panel this far (design px); `kurvFlere` opens Flere valg,
  /// `kurvHenting` picks Henting.
  static double? kurvScroll;
  static bool kurvFlere = false;
  static bool kurvHenting = false;

  /// Onboarding Step 7: tips «Eget beløp» preset (digits, e.g. "35").
  static String? kurvTipsEget;

  /// With `kurvHenting`: open «Se fullt kart» once the shop has loaded (parity Step 13).
  static bool kurvKart = false;

  /// Open the Kurv's `levering` or `betaling` sheet once loaded.
  static String? kurvArk;

  /// Kassen's back key once loaded, then 4 s later the store's back key
  /// (`maybePop`) — the Kassen ⇄ store round trip.
  static bool kurvTilbake = false;

  /// Open «Betalt» (the payment-confirmed sequence) for this order.
  static int? betalt;

  /// Scroll the product sheet this far (design px) once it is open.
  static double? produktScroll;
  static bool butikkMini = false;

  /// Treat every category as live (the launch gate off), so Mote and Gaver
  /// can be checked against the prototype's `launchModus: false`.
  static bool katLive = false;

  /// Open Hurtigbestilling (`/bergen/hurtig`); `hurtigMod` presses a module
  /// key (`oftest` / `forrige` / `pref`), `hurtigSi` sends a line,
  /// `hurtigTekst` types into the composer, `hurtigFokus` focuses it,
  /// `hurtigBestilt` shows the
  /// «Bestilt» card for that (paid) order, `hurtigTeller` freezes the
  /// countdown at N seconds (nothing is ordered), `hurtigScroll` scrolls the
  /// conversation (design px).
  static bool hurtig = false, hurtigTenk = false, hurtigFokus = false;
  static String? hurtigMod, hurtigSi, hurtigTekst, hurtigAct;
  static int? hurtigBestilt, hurtigTeller;
  static double? hurtigScroll;

  /// Open Sporing for this order (`/bergen/sporing/{id}`); `sporingArk`
  /// opens `sammendrag` / `detaljer`, `sporingSkifte` replays the stage
  /// change, `sporingHjelp` opens the help sheet in that state (`main`,
  /// `ring`, `melding`, `dor`, `mangler`, `kundeservice`), `sporingFersk`
  /// shows the vervebillett slot. `levert` opens Levert for this order;
  /// `levertArk` opens `tips` / `vurder`.
  static int? sporing, levert;
  static String? sporingArk, sporingHjelp, levertArk;
  static bool sporingSkifte = false, sporingFersk = false;

  /// Customer Step 2: the Leveringskode card's view for this order (`pin` /
  /// `qr`), and Sporing held offline (the PIN-only card).
  static String? sporingKode;
  static bool sporingOffline = false;

  /// Customer Step 5: the order sheet scrolled this far (design px), for its lower rows.
  static double? sporingRull;

  /// Taps the Live pill once Hjem has settled (`liveApne`: Sporing grows out
  /// of it and its pieces fly in).
  static bool liveApne = false;

  /// Meg: scroll to this design px once loaded (parity Step 9).
  static double? megScroll;

  /// Meg: open this Ark sheet once loaded (`billett`, `nivaa`, `slik`,
  /// `vilkaar`, `nivaa4`, `adresser`, `betaling`, `sprak`, `kode`, `liga`,
  /// `varsler`, `anledninger`, `ukeshandel`).
  static String? megArk;

  /// Customer Step 8, with `megArk: ukeshandel`: the step to open (`liste`,
  /// the default, or `kurv`).
  static String? ukeSteg;

  /// With `ukeSteg: kurv`: run the step's key once the sheet is up —
  /// `kasse` says yes to a waiting swap and opens the first store's
  /// confirmation, `betal` also confirms it (the local order, then Vipps).
  static String? ukeAuto;

  /// Premiehylla as if nothing had been claimed (`hyllaTom`, Bergen Step 8).
  static bool hyllaTom = false;

  /// Meg's «Logge ut?» question open (`loggUt`, gap audit).
  static bool loggUt = false;

  /// Customer Step 6, with `megArk: bio`: the consent ticked (`bioSamtykke`),
  /// «Slett bioen»'s «Er du sikker?» open (`bioSlett`).
  static bool bioSamtykke = false, bioSlett = false;

  /// Customer Step 7: Hjem's push invitation card shown (`hjemInvitasjon`).
  static bool hjemInvitasjon = false;
  static double? bioScroll;

  /// Open the Varsler panel on this filter (`varsler`: "Alle", "Bestillinger",
  /// …; Gap Step 1).
  static String? varsler;

  /// Customer Step 3: the Varsler card at this index swiped open
  /// (`varslerSveip`), or removed with the «Angre» toast showing (`varslerFjern`).
  static int? varslerSveip, varslerFjern;

  /// Gap Step 3: Premiehylla opens «Vilkår for premier» (`hyllaArk: "vilkaar"`);
  /// Hjem opens «Ægil de siste 30 dagene» (`logg`).
  static String? hyllaArk;
  static bool logg = false;

  /// Sporing: runs «Kvittering» once loaded (the PDF in the share sheet).
  static bool sporingKvittering = false;

  /// Utforsk (Step 9): `utfSeg` (`feed` / `pose`), `feedFane` (`naer` /
  /// `folger` / `aerend`), `feedKat` (an orb slug), `utfScroll` (design px),
  /// `feedDrift` (show the prototype's Drift note — no API carries one
  /// locally), `feedSpill` (play this post's video). `automat` opens
  /// Poseautomaten; `autoValg` steers the claw (0–3), `autoHentet` marks
  /// slots as taken today, `autoAct` runs `trekk` (pull), `pose` (the bag
  /// landed), `fisk` (Ægil rowing out — no cart call) or `fisket` (in the
  /// basket — no cart call).
  static String? utfSeg, feedFane, feedKat, feedSpill, autoAct;

  /// Parity Step 8: `feedRapport` (post id) opens its «Rapporter» reasons
  /// sheet once the feed has loaded; `feedInnlegg` (post id) opens its detail.
  static String? feedRapport, feedInnlegg;
  static double? utfScroll;
  static bool feedDrift = false, automat = false;
  static int? autoValg;
  static List<int>? autoHentet;

  /// Fjordfiske (Step 10), opened with `utfSeg: "fiske"`: `fiskeFase`
  /// (`klar` / `venter` / `napp` / `fangst` / `mistet` / `premie` — a
  /// sample prize, as no prizes exist locally — / `ferdig`), `fiskeAgn`
  /// (a bait key).
  static String? fiskeFase, fiskeAgn;

  /// Ægil (Step 11), opened from Hjem: `aegil` is the view (`start`,
  /// `chat`, `minne`, `nivaa`, `tillatelse`, `ob1`–`ob5`, `obSum`); `aegSi`
  /// sends these lines to `agent/chat` in turn; `aegTekst` types into the
  /// composer (or, with `aegTenk`, holds Ægil thinking after that line);
  /// `aegFokus` focuses the composer; `aegOb` fills the onboarding with a
  /// sample (nothing is stored until «Stemmer»); `aegButArk` opens «Alle
  /// butikker»; `aegScroll` scrolls the sheet (design px). `guide` shows the
  /// Ægil-guide on that screen at once (`utforsk`, `kategori`, `butikk`,
  /// `kurv`), `guideIdx` on that tip.
  static String? aegil, aegTekst, guide;

  /// Step 12: push this `/bergen/…` route from Hjem (`rute`), with `ruteArg` as
  /// its argument (a string, or a JSON object for a `Map`).
  static String? rute;

  /// Perf plan: open the calibration page (blank + one spinner).
  static bool perfKalib = false;

  /// Perf plan (bisect probe, debug/profile): sections laid out but not
  /// painted — `hjul`, `hurtig`, `butikker`, `utforsk`, `tilbud`, `populaert`,
  /// `nav`, `live`, `topp` — to measure what each costs per frame.
  static Set<String> skjul = const {};

  /// Wraps a section for the [skjul] probe (identity outside it).
  static Widget probe(String id, Widget w) => !kReleaseMode && skjul.contains(id)
      ? Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: w)
      : w;
  static Object? ruteArg;

  /// 29 Oct loaders and transitions: `ruteTilbake` pops the pushed route
  /// after N ms (the Menisk back); `draLaster` runs the pull-to-refresh on
  /// Hjem (`"demo"` = the design's `ldrDemo`, `"hold"` = stays at
  /// «Oppdaterer …»); `favPop` bursts the heart of that store id (0 = the
  /// first heart) 2.5s after the route opens; `arkLukk` closes Meg's
  /// `megArk` sheet after N ms (the Bølge sink).
  static int? ruteTilbake, favPop, arkLukk;

  /// Wait this long (ms) before the `rute` push (the address is loaded by then).
  static int? ruteVent;
  static String? draLaster;

  /// Bergen Step 9: heart these products first (`favProdukter`), through
  /// [FavouriteProducts] as the product sheet's heart does.
  static List<int>? favProdukter;

  /// Step 13: in the support chat, send these lines in turn (`hjelpSi`);
  /// `hjelpMenneske` asks for a person and lets one take over (the only way
  /// to see that state: there is no support desk behind the app yet);
  /// `hjelpGjest` opens the chat as a guest; `hjelpHub` shows the hub even
  /// with an order on its way.
  static List<String>? hjelpSi;
  static bool hjelpMenneske = false, hjelpGjest = false, hjelpHub = false;

  /// With `hjelpHub`: start the support chat from the hub (parity Step 10).
  static bool hjelpChat = false;

  /// Step 13: Ordrehistorikk opens this order's sheet (`ohOrdre`), or its
  /// «Noe galt» flow (`ohNoeGalt`).
  static int? ohOrdre;
  static bool ohNoeGalt = false;

  /// With `ohNoeGalt`: open «Noe galt» at step 2 or 3 (parity Step 10).
  static int ohNoeGaltSteg = 1;
  static List<String>? aegSi;
  static bool aegTenk = false, aegFokus = false, aegOb = false, aegButArk = false;

  /// Customer Step 5: after `aegSi`, tap the last proposal (`aegBruk`), then
  /// «Angre» (`aegAngre`) — the receipt and the undone card.
  static bool aegBruk = false, aegAngre = false;

  /// Customer Step 6: tap «Vis likevel» on the products card (`aegVisLikevel`).
  static bool aegVisLikevel = false;

  /// Customer Step 9, with `aegil: chat`: `aegGave` runs the gift flow to
  /// `brief` (the chips), `funn` (three cards), `kort` (the card text) or
  /// `tom` (nothing arrives in time); `aegBilde` the photo flow to `prompt`
  /// or `skann` (a scan of `aegBildeData`, a data URL, else a 1 × 1 JPEG);
  /// `adrDor` (the existing key) types the line into the address sheet's
  /// door field; `adrDorAuto` presses Lagre once the chips are up and
  /// `adrDorSamtykke` switches the code consent on first.
  static String? aegGave, aegBilde, aegBildeData;
  static bool adrDorAuto = false, adrDorSamtykke = false;

  /// Customer Step 10: with `ohOrdre`, `ohSak` opens the C2 «Noe galt» sheet
  /// on that order (`ohSakSteg: tenker` holds Ægil's thinking state;
  /// `ohSakJson` renders a given issue as the outcome without the server);
  /// with `sporing`, `sporingSak` opens it from the delivered panel;
  /// `hjelpSamtale` continues that support conversation in the Hjelp chat.
  static bool ohSak = false, sporingSak = false;
  static String? ohSakSteg;
  static Map<String, dynamic>? ohSakJson;
  static int? hjelpSamtale;

  /// Customer Step 12: Meg's Ukens oppdrag row in a given state (`ny`,
  /// `tatt`, `ferdig`, `nei`) without the server; `megArk: oppdrag` /
  /// `oppsummering` open the two sheets.
  static String? megOppdrag;

  /// Customer Step 12, on Premiehylla: the claim's sheet open (`hyllaClaim`,
  /// the claim id) and, with `hyllaAngre`, its «Angre premien» pressed.
  static int? hyllaClaim;
  static bool hyllaAngre = false;

  /// Customer Step 14: the AI-assistant states (design §4d, `aiFlyt`).
  /// `ai` names the state (`inngang`, `velg`, `qr`, `qrAnnen`, `qrKopiert`,
  /// `samtykke`, `samtykkeGjest`, `koblet`, `koblede`, `detalj`, `kobleFra`,
  /// `kobleFraAlle`, `feilIkkeKoblet`, `feilBekreft`, `feilGenerisk`,
  /// `bekreft`, `bekreftOver`, `bekreftFeilet`, `bekreftUtlopt`,
  /// `bekreftTrukket`, `faceid`, `vipps`, `push`, `bytt`, `byttKurv`,
  /// `kurv`, `kurvLaster`, `kurvGjest`, `kurvDekning`, `kurvUtsolgt`,
  /// `kurvUtlopt`, `kurvVente`, `varsler`); `aiNavn` the assistant (Claude …);
  /// `aiStart` `koblet` | `ingen` fakes the linked list; `aiReq` a real
  /// request id (else the design's sample request renders).
  static String? ai, aiNavn, aiStart, aiReq;

  /// `aiBetal: true` releases the request screen's slider once the real request has loaded (Vipps).
  static bool aiBetal = false;

  /// Customer Step 0: open Ægil's Brett (all his finds) over Hjem.
  static bool brett = false;

  /// Heat plan Step 0: the scripted 30-minute customer journey (see
  /// `_BergenHomeState._reise`); the Mac side adds swipes (`heat_reise.sh`).
  static bool reise = false;
  static double? aegScroll;
  static int? guideIdx;

  static Future<void> load() async {
    if (kReleaseMode) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final kunde = File('${dir.path}/kunde_state.json');
      final f = await kunde.exists() ? kunde : File('${dir.path}/hjem_state.json');
      if (!await f.exists()) {
        // Heat plan Step 12: back to "heat never changes the motion".
        final varme = BergenPerf.varmeTrinnGammel;
        BergenPerf.varmeTrinnGammel = false;
        // `termisk` absent: the real thermal readings again.
        if (BergenPerf.termisk != null) BergenPerf.termiskTvang(null);
        if (perf != null || varme) BergenPerf.force(null);
        perf = null;
        nyButikk = false;
        betaltKurv = null;
        vaer = null;
        demoFloats = false;
        unread = null;
        scroll = null;
        rull = null;
        rullMs = null;
        vann = true;
        heroAv = false;
        skyggeAv = false;
        CssBoxPainter.debugUtenBlur = false;
        CssBake.paa = true;
        BergenPerf.hvilePaa = true;
        BergenPerf.usynligPaa = true;
        BergenPerf.pauseSovPaa = true;
        BergenPerf.stegRammerPaa = true;
        BergenPerf.malerVertPaa = true;
        BergenPerf.pass2KlippPaa = true;
        BergenPerf.pass2CssPaa = false;
        BergenPerf.pass2BaktPaa = false;
        BergenPerf.dekketPaa = true;
        BergenBakt.paa = true;
        BergenPerf.shaderFrys = false;
        BergenPerf.shaderFrysKun = null;
        BergenPerf.frysMs = null;
        heroStille = false;
        arkStille = false;
        snart = null;
        pose = false;
        poseArk = null;
        poseSikre = poseArkRull = false;
        bpFane = null;
        bpPost = null;
        vindu = false;
        borte = false;
        fane = null;
        onbRunde = null;
        onbRolig = false;
        onbAuto = null;
        onbNull = false;
        onbLevert = false;
        onbTips = null;
        katLegg = false;
        ruteTilbake = favPop = arkLukk = ruteVent = null;
        draLaster = null;
        hjul = null;
        adresse = null;
        dekning = null;
        adrSok = null;
        adrDor = null;
        adrVelg = false;
        sok = null;
        sokNylig = null;
        sokPop = false;
        sokFokus = false;
        kat = null;
        katFane = null;
        katScroll = null;
        butikk = null;
        butikkKat = null;
        butikkProdukt = null;
        butikkInfo = null;
        butikkScroll = null;
        butikkOrb = null;
        butikkLegg = null;
        produktScroll = null;
        butikkMini = false;
        kurvTom = false;
        kurvScroll = null;
        kurvFlere = false;
        kurvTipsEget = null;
        kurvHenting = false;
        kurvKart = false;
        kurvArk = null;
        kurvTilbake = false;
        betalt = null;
        katLive = false;
        hurtig = hurtigTenk = hurtigFokus = false;
        hurtigMod = hurtigSi = hurtigTekst = hurtigAct = null;
        hurtigBestilt = hurtigTeller = null;
        hurtigScroll = null;
        sporing = levert = null;
        sporingArk = sporingHjelp = levertArk = null;
        sporingSkifte = sporingFersk = liveApne = sporingKvittering = false;
        sporingKode = null;
        sporingOffline = false;
        megScroll = null;
        megArk = null;
        ukeSteg = null;
        ukeAuto = null;
        hyllaTom = false;
        loggUt = false;
        bioSamtykke = bioSlett = false;
        hjemInvitasjon = false;
        bioScroll = null;
        varsler = null;
        varslerSveip = varslerFjern = null;
        hyllaArk = null;
        logg = false;
        utfSeg = feedFane = feedKat = feedSpill = autoAct = null;
        feedRapport = feedInnlegg = null;
        fiskeFase = fiskeAgn = null;
        aegil = aegTekst = guide = null;
        rute = ruteArg = null;
        favProdukter = null;
        hjelpSi = null;
        hjelpMenneske = hjelpGjest = hjelpHub = false;
        ohOrdre = null;
        ohNoeGalt = false;
        ohNoeGaltSteg = 1;
        aegSi = null;
        aegGave = aegBilde = aegBildeData = null;
        ohSak = sporingSak = false;
        ohSakSteg = null;
        ohSakJson = null;
        megOppdrag = null;
        hyllaClaim = null;
        hyllaAngre = false;
        ai = aiNavn = aiStart = aiReq = null;
        aiBetal = false;
        hjelpSamtale = null;
        adrDorAuto = adrDorSamtykke = false;
        aegTenk = aegFokus = aegOb = aegButArk = false;
        aegBruk = aegAngre = false;
        aegVisLikevel = false;
        sporingRull = null;
        aegScroll = null;
        guideIdx = null;
        brett = false;
        reise = false;
        utfScroll = null;
        feedDrift = automat = false;
        autoValg = null;
        autoHentet = null;
        return;
      }
      final m = {...jsonDecode(await f.readAsString()) as Map<String, dynamic>};
      void alias(String navn, String nokkel) {
        if (m.containsKey(navn) && !m.containsKey(nokkel)) m[nokkel] = m[navn];
      }

      alias('route', 'rute');
      alias('routeArg', 'ruteArg');
      alias('tab', 'fane');
      alias('sheet', m['sporing'] != null ? 'sporingArk' : 'megArk');
      perf = m['perf'] as String?;
      nyButikk = m['nyButikk'] == true;
      betaltKurv = (m['betaltKurv'] as num?)?.toInt();
      // Heat plan Step 12: `varmeTrinn: true` brings back the old thermal
      // step-down (fair → lite, serious → still) for A/B on one build; the
      // force below applies it.
      BergenPerf.varmeTrinnGammel = m['varmeTrinn'] == true;
      // `termisk: 0..3` (debug / profile): the thermal state as if the
      // platform reported it (fair / serious / critical for a device check);
      // absent = the real readings.
      BergenPerf.termiskTvang((m['termisk'] as num?)?.toInt());
      BergenPerf.force(perf == null ? null : BergenTier.values.byName(perf!));
      vaer = m['vaer'] == null ? null : HjemVaer.values.byName(m['vaer'] as String);
      demoFloats = m['demoFloats'] == true;
      unread = m['unread'] as int?;
      scroll = (m['scroll'] as num?)?.toDouble();
      rull = (m['rull'] as num?)?.toDouble();
      rullMs = m['rullMs'] as int?;
      vann = m['vann'] != false;
      heroAv = m['heroAv'] == true;
      skyggeAv = m['skyggeAv'] == true;
      CssBoxPainter.debugUtenBlur = skyggeAv;
      // Perf plan: `cssCache: false` paints every CssBox live (A/B on one build).
      CssBake.paa = m['cssCache'] != false;
      // Perf plan: `hvile: false` keeps off-screen loops and scenes ticking (A/B).
      BergenPerf.hvilePaa = m['hvile'] != false;
      // Heat plan Step 2: `usynlig: false` keeps invisible work running (A/B).
      BergenPerf.usynligPaa = m['usynlig'] != false;
      // Heat plan Step 3: `pauseSov: false` keeps loops ticking through their
      // keyframe holds (A/B).
      BergenPerf.pauseSovPaa = m['pauseSov'] != false;
      // Heat plan Step 4: `stegRammer: false` keeps the shader scenes asking
      // for a frame on every vsync, as before (A/B on one build).
      BergenPerf.stegRammerPaa = m['stegRammer'] != false;
      // Heat plan Step 6: `malerVert: false` keeps the shader hosts on setState
      // + RawImage per frame and the unsplit shaders (A/B on one build).
      BergenPerf.malerVertPaa = m['malerVert'] != false;
      // Heat plan Step 7 (A/B on one build): `pass2Klipp: false` keeps the big
      // shadow clips; `pass2Css: true` returns still CssBoxes to the raster;
      // `pass2Bakt: true` puts BergenBakt's raster on the device pixel grid.
      BergenPerf.pass2KlippPaa = m['pass2Klipp'] != false;
      BergenPerf.pass2CssPaa = m['pass2Css'] == true;
      BergenPerf.pass2BaktPaa = m['pass2Bakt'] == true;
      // Perf plan: `dekket: false` paints covered scenes; `bakt: false` paints
      // every BergenBakt live (A/B on one build).
      BergenPerf.dekketPaa = m['dekket'] != false;
      BergenBakt.paa = m['bakt'] != false;
      heroStille = m['heroStille'] == true;
      BergenPerf.shaderFrys = m['shaderFrys'] == true;
      BergenPerf.shaderFrysKun = m['shaderFrysKun'] as String?;
      BergenPerf.frysMs = (m['klokke'] as num?)?.toDouble();
      // A loop asleep in a hold wakes now for the frozen clock / `pauseSov`.
      BergenPerf.vekkSovende();
      arkStille = m['arkStille'] == true;
      snart = m['snart'] as int?;
      pose = m['pose'] == true;
      poseArk = m['poseArk'] as int?;
      poseSikre = m['poseSikre'] == true;
      poseArkRull = m['poseArkRull'] == true;
      bpFane = m['bpFane'] as String?;
      bpPost = m['bpPost'] as int?;
      vindu = m['vindu'] == true;
      borte = m['borte'] == true;
      fane = m['fane'] as int?;
      onbRunde = (m['onbRunde'] as num?)?.toInt();
      onbRolig = m['onbRolig'] == true;
      onbAuto = m['onbAuto'] as String?;
      onbNull = m['onbNull'] == true;
      onbLevert = m['onbLevert'] == true;
      onbTips = m['onbTips'] as String?;
      katLegg = m['katLegg'] == true;
      hjul = m['hjul'] as int?;
      adresse = m['adresse'] as String?;
      dekning = m['dekning'] as String?;
      adrSok = m['adrSok'] as String?;
      adrDor = m['adrDor'] as String?;
      adrVelg = m['adrVelg'] == true;
      sok = m['sok'] as String?;
      sokNylig = (m['sokNylig'] as List?)?.map((e) => List<Object>.from(e as List)).toList();
      sokPop = m['sokPop'] == true;
      sokFokus = m['sokFokus'] == true;
      kat = m['kat'] as int?;
      katFane = m['katFane'] as String?;
      katScroll = (m['katScroll'] as num?)?.toDouble();
      butikk = m['butikk'] as int?;
      butikkKat = m['butikkKat'] as String?;
      butikkProdukt = m['butikkProdukt'] as int?;
      butikkInfo = m['butikkInfo'] as String?;
      butikkScroll = (m['butikkScroll'] as num?)?.toDouble();
      butikkOrb = m['butikkOrb'] as int?;
      butikkLegg = (m['butikkLegg'] as List?)?.cast<int>();
      produktScroll = (m['produktScroll'] as num?)?.toDouble();
      butikkMini = m['butikkMini'] == true;
      kurvTom = m['kurvTom'] == true;
      kurvScroll = (m['kurvScroll'] as num?)?.toDouble();
      kurvFlere = m['kurvFlere'] == true;
      kurvHenting = m['kurvHenting'] == true;
      kurvTipsEget = m['kurvTipsEget']?.toString();
      kurvKart = m['kurvKart'] == true;
      kurvArk = m['kurvArk'] as String?;
      kurvTilbake = m['kurvTilbake'] == true;
      betalt = m['betalt'] as int?;
      // `treg`: slow every animation down this many times (frame checks).
      timeDilation = (m['treg'] as num?)?.toDouble() ?? 1.0;
      katLive = m['katLive'] == true;
      hurtig = m['hurtig'] == true;
      hurtigTenk = m['hurtigTenk'] == true;
      hurtigMod = m['hurtigMod'] as String?;
      hurtigSi = m['hurtigSi'] as String?;
      hurtigTekst = m['hurtigTekst'] as String?;
      hurtigFokus = m['hurtigFokus'] == true;
      hurtigAct = m['hurtigAct'] as String?;
      hurtigBestilt = m['hurtigBestilt'] as int?;
      hurtigTeller = m['hurtigTeller'] as int?;
      hurtigScroll = (m['hurtigScroll'] as num?)?.toDouble();
      sporing = m['sporing'] as int?;
      levert = m['levert'] as int?;
      sporingArk = m['sporingArk'] as String?;
      sporingHjelp = m['sporingHjelp'] as String?;
      levertArk = m['levertArk'] as String?;
      sporingSkifte = m['sporingSkifte'] == true;
      sporingFersk = m['sporingFersk'] == true;
      sporingKode = m['sporingKode'] as String?;
      sporingOffline = m['sporingOffline'] == true;
      liveApne = m['liveApne'] == true;
      megScroll = (m['megScroll'] as num?)?.toDouble();
      megArk = m['megArk'] as String?;
      ukeSteg = m['ukeSteg'] as String?;
      ukeAuto = m['ukeAuto'] as String?;
      hyllaTom = m['hyllaTom'] == true;
      loggUt = m['loggUt'] == true;
      bioSamtykke = m['bioSamtykke'] == true;
      hjemInvitasjon = m['hjemInvitasjon'] == true;
      bioSlett = m['bioSlett'] == true;
      bioScroll = (m['bioScroll'] as num?)?.toDouble();
      varsler = m['varsler'] as String?;
      varslerSveip = m['varslerSveip'] as int?;
      varslerFjern = m['varslerFjern'] as int?;
      hyllaArk = m['hyllaArk'] as String?;
      logg = m['logg'] == true;
      sporingKvittering = m['sporingKvittering'] == true;
      utfSeg = m['utfSeg'] as String?;
      feedFane = m['feedFane'] as String?;
      feedRapport = m['feedRapport']?.toString();
      feedInnlegg = m['feedInnlegg']?.toString();
      feedKat = m['feedKat'] as String?;
      feedSpill = m['feedSpill']?.toString();
      utfScroll = (m['utfScroll'] as num?)?.toDouble();
      feedDrift = m['feedDrift'] == true;
      automat = m['automat'] == true;
      autoValg = m['autoValg'] as int?;
      autoHentet = (m['autoHentet'] as List?)?.cast<int>();
      autoAct = m['autoAct'] as String?;
      fiskeFase = m['fiskeFase'] as String?;
      fiskeAgn = m['fiskeAgn'] as String?;
      aegil = m['aegil'] as String?;
      rute = m['rute'] as String?;
      perfKalib = m['perfKalib'] == true;
      skjul = {...((m['skjul'] as List?) ?? const []).map((e) => '$e')};
      ruteTilbake = m['ruteTilbake'] as int?;
      ruteVent = m['ruteVent'] as int?;
      favPop = m['favPop'] as int?;
      arkLukk = m['arkLukk'] as int?;
      draLaster = m['draLaster'] as String?;
      favProdukter = (m['favProdukter'] as List?)?.cast<int>();
      ruteArg = m['ruteArg'] is Map ? Map<String, String>.from((m['ruteArg'] as Map).map((k, v) => MapEntry('$k', '$v'))) : m['ruteArg']?.toString();
      hjelpSi = (m['hjelpSi'] as List?)?.cast<String>();
      hjelpMenneske = m['hjelpMenneske'] == true;
      hjelpGjest = m['hjelpGjest'] == true;
      hjelpHub = m['hjelpHub'] == true;
      hjelpChat = m['hjelpChat'] == true;
      ohOrdre = (m['ohOrdre'] as num?)?.toInt();
      ohNoeGalt = m['ohNoeGalt'] == true;
      ohNoeGaltSteg = (m['ohNoeGaltSteg'] as num?)?.toInt() ?? 1;
      aegTekst = m['aegTekst'] as String?;
      aegSi = (m['aegSi'] as List?)?.cast<String>();
      aegTenk = m['aegTenk'] == true;
      aegBruk = m['aegBruk'] == true;
      aegVisLikevel = m['aegVisLikevel'] == true;
      aegGave = m['aegGave'] as String?;
      aegBilde = m['aegBilde'] as String?;
      aegBildeData = m['aegBildeData'] as String?;
      adrDorAuto = m['adrDorAuto'] == true;
      adrDorSamtykke = m['adrDorSamtykke'] == true;
      ohSak = m['ohSak'] == true;
      sporingSak = m['sporingSak'] == true;
      ohSakSteg = m['ohSakSteg'] as String?;
      ohSakJson = m['ohSakJson'] is Map ? Map<String, dynamic>.from(m['ohSakJson'] as Map) : null;
      hjelpSamtale = (m['hjelpSamtale'] as num?)?.toInt();
      megOppdrag = m['megOppdrag'] as String?;
      hyllaClaim = (m['hyllaClaim'] as num?)?.toInt();
      hyllaAngre = m['hyllaAngre'] == true;
      ai = m['ai'] as String?;
      aiNavn = m['aiNavn'] as String?;
      aiStart = m['aiStart'] as String?;
      aiReq = m['aiReq'] as String?;
      aiBetal = m['aiBetal'] == true;
      sporingRull = (m['sporingRull'] as num?)?.toDouble();
      aegAngre = m['aegAngre'] == true;
      aegFokus = m['aegFokus'] == true;
      aegOb = m['aegOb'] == true;
      aegButArk = m['aegButArk'] == true;
      aegScroll = (m['aegScroll'] as num?)?.toDouble();
      guide = m['guide'] as String?;
      guideIdx = m['guideIdx'] as int?;
      brett = m['brett'] == true;
      reise = m['reise'] == true;
      if (m['lagCache'] == true) LagCache.start();
      if (m['videoTest'] is String) PerfVideoTest.start(m['videoTest'] as String);
      debugPrint('HJEM_HARNESS applied');
    } catch (_) {}
  }
}
