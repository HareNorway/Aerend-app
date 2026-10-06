import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:path_provider/path_provider.dart';

import 'hjem_hero.dart';

/// Debug builds only: `Documents/hjem_state.json` pins Hjem's weather, uses
/// the prototype's sample floats and sets the unread count, so the screen
/// can be compared with the prototype's default state. Ignored in release.
abstract final class HjemHarness {
  static HjemVaer? vaer;
  static bool demoFloats = false;
  static int? unread;

  /// Scroll the sheet this far (device px) once loaded.
  static double? scroll;

  /// Open the Kommer snart sheet for this wheel slot.
  static int? snart;

  /// Show the Forundringspose card whatever the hour.
  static bool pose = false;

  /// Open the window (`sone: 'vindu'`).
  static bool vindu = false;

  /// Show "Mens du var borte" with the prototype's three lines.
  static bool borte = false;

  /// Switch to this tab a moment after loading.
  static int? fane;

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

  /// Open the Kurv's `levering` or `betaling` sheet once loaded.
  static String? kurvArk;

  /// Open «Betalt» (the payment-confirmed sequence) for this order.
  static int? betalt;

  /// Scroll the product sheet this far (design px) once it is open.
  static double? produktScroll;
  static bool butikkMini = false;

  /// Treat every category as live (the launch gate off), so Mote and Gaver
  /// can be checked against the prototype's `launchModus: false`.
  static bool katLive = false;

  static Future<void> load() async {
    if (!kDebugMode) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/hjem_state.json');
      if (!await f.exists()) {
        vaer = null;
        demoFloats = false;
        unread = null;
        scroll = null;
        snart = null;
        pose = false;
        vindu = false;
        borte = false;
        fane = null;
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
        kurvHenting = false;
        kurvArk = null;
        betalt = null;
        katLive = false;
        return;
      }
      final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      vaer = m['vaer'] == null ? null : HjemVaer.values.byName(m['vaer'] as String);
      demoFloats = m['demoFloats'] == true;
      unread = m['unread'] as int?;
      scroll = (m['scroll'] as num?)?.toDouble();
      snart = m['snart'] as int?;
      pose = m['pose'] == true;
      vindu = m['vindu'] == true;
      borte = m['borte'] == true;
      fane = m['fane'] as int?;
      hjul = m['hjul'] as int?;
      adresse = m['adresse'] as String?;
      dekning = m['dekning'] as String?;
      adrSok = m['adrSok'] as String?;
      adrDor = m['adrDor'] as String?;
      adrVelg = m['adrVelg'] == true;
      sok = m['sok'] as String?;
      sokNylig = (m['sokNylig'] as List?)
          ?.map((e) => List<Object>.from(e as List))
          .toList();
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
      kurvArk = m['kurvArk'] as String?;
      betalt = m['betalt'] as int?;
      // `treg`: slow every animation down this many times (frame checks).
      timeDilation = (m['treg'] as num?)?.toDouble() ?? 1.0;
      katLive = m['katLive'] == true;
      debugPrint('HJEM_HARNESS applied');
    } catch (_) {}
  }
}
