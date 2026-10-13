import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import 'a3_services.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';

/// «Ægil de siste 30 dagene» (new Bergen kArk `logg`, L20344; Gap Step 3):
/// the light Ark from «Mens du var borte» › «Se de siste 30 dagene». One row
/// per thing Ægil did (`GET agent/me/actions?days=30`), newest first, then
/// «Lukk». The design's «Alt kan angres i 7 dager.» is left out: there is no
/// undo route.
abstract final class AegilLogg {
  static const tittel = 'Ægil de siste 30 dagene';
  static const linje = 'Alt Ægil har gjort mens du var borte.';
  static const tom = 'Ægil har ikke gjort noe de siste 30 dagene.';
  static const _dager = ['mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'];
  static const _mnd = ['januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'];

  /// «i dag 10:00», «i går 21:04», «mandag 10:00» this week, «forrige
  /// torsdag» the week before, «28. august» before that.
  static String naar(DateTime t, DateTime naa) {
    String hm() => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final d = DateTime(naa.year, naa.month, naa.day).difference(DateTime(t.year, t.month, t.day)).inDays;
    if (d <= 0) return 'i dag ${hm()}';
    if (d == 1) return 'i går ${hm()}';
    if (d < 7) return '${_dager[t.weekday - 1]} ${hm()}';
    if (d < 14) return 'forrige ${_dager[t.weekday - 1]}';
    return '${t.day}. ${_mnd[t.month - 1]}';
  }

  static Future<void> vis(BuildContext context, {AegilAppApi? api, DateTime? naa}) async {
    final items = await (api ?? A3Services.aegil()).actions();
    if (!context.mounted) return;
    final no = naa ?? DateTime.now();
    await showMegArk<void>(
      context,
      key: const Key('aegil-logg-sheet'),
      title: tittel,
      subtitle: linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty) const MegArkRow(title: tom),
          for (final AwayItem a in items) MegArkRow(title: a.text, sub: a.at == null ? null : naar(a.at!, no)),
        ],
      ),
      primary: MegArkButton(key: const Key('aegil-logg-lukk'), label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }
}
