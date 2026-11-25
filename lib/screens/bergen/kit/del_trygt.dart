import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../../../main.dart' show languages;
import 'bergen_toast.dart';

/// TestFlight 6 feedback («Share button is not working on the posts»): from iOS 26 the share sheet is a popover on
/// the iPhone too, and share_plus then refuses an anchor that is empty or not inside the screen — it answers an error
/// and nothing opens. The feed anchored the sheet on the whole feed tab, taller than the screen as soon as the list
/// ran past it. The anchor is now the tapped key, kept inside the screen.
///
/// The screen in UIKit points: the root view's size (our 390-wide LfFrame scales its own MediaQuery, not this).
Rect delAnker(BuildContext anker) {
  final view = View.maybeOf(anker);
  final skjerm = view == null ? Rect.zero : Offset.zero & (view.physicalSize / view.devicePixelRatio);
  final ro = anker.findRenderObject();
  Rect r = Rect.zero;
  if (ro is RenderBox && ro.hasSize && ro.attached) {
    r = MatrixUtils.transformRect(ro.getTransformTo(null), Offset.zero & ro.size);
  }
  if (skjerm.isEmpty) return r;
  final inne = r.intersect(skjerm);
  if (inne.width >= 1 && inne.height >= 1) return inne;
  // Off screen or not laid out: a small anchor at the screen's foot, where the sheet rises from.
  return Rect.fromCenter(center: Offset(skjerm.width / 2, skjerm.height - 40), width: 40, height: 40);
}

/// Opens the share sheet anchored on [anker]; when the platform still refuses, the text goes to the clipboard and a
/// toast says so ([kopiert], default «Kopiert»), so a tap never does nothing. True when the sheet opened.
Future<bool> delTrygt(BuildContext anker, String tekst, {String? emne, String? kopiert}) async {
  try {
    await Share.share(tekst, subject: emne, sharePositionOrigin: delAnker(anker));
    return true;
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: tekst));
    if (anker.mounted) showBergenToast(anker, kopiert ?? languages.ops_kasse_kopiert);
    return false;
  }
}
