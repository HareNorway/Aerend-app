import '../../../main.dart' show navigatorKey;
import '../../../networking/ops/cus_api.dart';
import '../kit/bergen_routes.dart';
import 'ai_bekreft.dart';
import 'ai_overlays.dart';
import 'ai_store.dart';

/// Customer plan Step 14: the FCM data message `kind = ai_request` (the push
/// gate's «{AI} vil bestille») while the app is open → the in-app banner
/// with «Se bestillingen» / «Avvis»; on tap from the system tray the
/// `deep_link` (`/bergen/ai/foresporsel/{id}`) opens the request. Customer v2
/// Step 3: both open the confirmation sheet (`AiBekreft`) over the screen the
/// customer is on; the request screen stays for the hand-off link.
abstract final class AiPushHook {
  /// True when the banner was shown (the caller then skips the system notification).
  static Future<bool> vis(Map<String, dynamic> data) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final link = '${data['deep_link'] ?? ''}';
    final id = link.startsWith('/bergen/ai/foresporsel/') ? link.substring('/bergen/ai/foresporsel/'.length) : '';
    CusAiRequest? r;
    if (id.isNotEmpty) r = await AiStore.instance.api.aiRequest(id);
    r ??= await AiStore.instance.api.aiRequestLatest();
    if (r == null || !ctx.mounted) return false;
    final req = r;
    AiOverlays.push(ctx, req, onAvvis: () => AiStore.instance.api.aiRequestDecline(req.id), onApne: (_) {
      final c = navigatorKey.currentContext;
      if (c != null && c.mounted) AiBekreft.vis(c, req);
    });
    return true;
  }

  /// A tapped push with a `/bergen/…` deep link.
  static bool apne(Map<String, dynamic> data) {
    final link = '${data['deep_link'] ?? ''}';
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !link.startsWith('/bergen/')) return false;
    if (link.startsWith('/bergen/ai/foresporsel/')) {
      final id = link.substring('/bergen/ai/foresporsel/'.length);
      AiStore.instance.api.aiRequest(id).then((r) {
        final c = navigatorKey.currentContext;
        if (c == null || !c.mounted) return;
        r == null ? BergenRoutes.push<void>(c, link) : AiBekreft.vis(c, r);
      });
      return true;
    }
    BergenRoutes.push<void>(ctx, link);
    return true;
  }
}
