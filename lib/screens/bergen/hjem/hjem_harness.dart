import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
      debugPrint('HJEM_HARNESS applied');
    } catch (_) {}
  }
}
