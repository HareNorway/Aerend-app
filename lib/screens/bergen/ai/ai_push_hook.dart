import '../../../main.dart' show navigatorKey;
import '../../../networking/ops/cus_api.dart';
import '../kit/bergen_routes.dart';
import 'ai_overlays.dart';
import 'ai_store.dart';

/// Customer plan Step 14: the FCM data message `kind = ai_request` (the push
/// gate's «{AI} vil bestille») while the app is open → the in-app banner
/// with «Se bestillingen» / «Avvis»; on tap from the system tray the
/// `deep_link` (`/bergen/ai/foresporsel/{id}`) opens the request.
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
    AiOverlays.push(ctx, r, onAvvis: () => AiStore.instance.api.aiRequestDecline(r!.id));
    return true;
  }

  /// A tapped push with a `/bergen/…` deep link.
  static bool apne(Map<String, dynamic> data) {
    final link = '${data['deep_link'] ?? ''}';
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !link.startsWith('/bergen/')) return false;
    BergenRoutes.push<void>(ctx, link);
    return true;
  }
}
