import 'package:flutter/foundation.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../services/customer/client_flags.dart';
import '../hjem/hjem_harness.dart';
import 'ai_bits.dart';

/// Customer plan Step 14: what the AI sheets share — the linked assistants
/// (`customer/ai/links`), the vendors to pick, the newest open request for
/// the banner — loaded once and refreshed after every change. In debug
/// builds the harness (`aiStart`: `koblet` | `ingen`) replaces the server's
/// list so every sheet renders without a link.
class AiStore extends ChangeNotifier {
  AiStore._();

  static final AiStore instance = AiStore._();

  CusApi api = CusApi();

  List<CusAiLink>? links;
  List<CusAiClient> clients = const [];
  CusAiRequest? latest;
  bool loading = false;

  /// The design's seeded link for the harness (`aiStd`).
  static CusAiLink harnessLink(String navn, {bool active = true}) => CusAiLink(
    id: 1, clientId: AiNavn.clientId(navn), name: navn, vendor: AiNavn.vendor(navn), active: active,
    scopes: const ['catalog:read', 'cart:write', 'orders:read', 'orders:write', 'profile:read'],
    permissions: [for (final s in const ['catalog:read', 'cart:write', 'orders:read', 'orders:write', 'profile:read', 'support:write']) CusAiRett(scope: s, on: s != 'support:write', locked: s == 'catalog:read' || s == 'orders:write', title: '', line: '', lockedLabel: s == 'catalog:read' ? 'Alltid på' : (s == 'orders:write' ? 'Påkrevd' : null))],
    capPerOrder: const CusMoney(ore: 50000, display: '500 kr'), capPerDay: const CusMoney(ore: 100000, display: '1 000 kr'), usedToday: const CusMoney(ore: 41200, display: '412 kr'), orders: 1,
    grantedAt: DateTime(2026, 10, 12, 20, 15), lastUsedAt: DateTime.now().subtract(const Duration(minutes: 20)), revokedAt: active ? null : DateTime.now(),
  );

  bool get harness => kDebugMode && HjemHarness.aiStart != null;

  /// Customer Step 15: Siri's chip and card need `cus.ai.intents` (the App
  /// Intents / shortcuts ship with it); the harness shows them regardless.
  bool get siri => harness || ClientFlags.on(ClientFlags.aiIntents);

  /// The assistants to show.
  List<String> get navn => siri ? AiNavn.alle : AiNavn.alle.where((n) => n != 'Siri').toList();

  List<CusAiLink> get alle => links ?? const [];
  List<CusAiLink> get aktive => alle.where((l) => l.active).toList();
  CusAiLink? linkFor(String navn) => alle.where((l) => l.name == navn || l.vendor == AiNavn.vendor(navn)).firstOrNull;
  CusAiLink? aktivFor(String navn) => aktive.where((l) => l.name == navn || l.vendor == AiNavn.vendor(navn)).firstOrNull;

  Future<void> load({bool force = false}) async {
    if (harness) {
      links = HjemHarness.aiStart == 'koblet' ? [harnessLink(HjemHarness.aiNavn ?? 'Claude')] : [];
      clients = [for (final n in const ['Claude', 'ChatGPT', 'Gemini']) CusAiClient(clientId: AiNavn.clientId(n), name: n, vendor: AiNavn.vendor(n))];
      notifyListeners();
      return;
    }
    if (loading && !force) return;
    if (!ClientFlags.on(ClientFlags.aiLinking) && !force) {
      links ??= [];
      notifyListeners();
      return;
    }
    loading = true;
    try {
      // Customer Step 16 (fallback audit): a failing call answers nothing; the others still land.
      Future<T?> safe<T>(Future<T?> f) => f.then<T?>((v) => v, onError: (Object _) => null);
      final r = await Future.wait<Object?>([safe(api.aiLinks()), safe(api.aiClients()), safe(api.aiRequestLatest())]);
      links = (r[0] as List<CusAiLink>?) ?? links ?? [];
      clients = (r[1] as List<CusAiClient>?) ?? clients;
      latest = r[2] as CusAiRequest?;
    } finally {
      loading = false;
    }
    notifyListeners();
  }

  /// Harness: a link changed locally (the sheets keep working without the server).
  void settLokalt(List<CusAiLink> l) {
    links = l;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    links = null;
    clients = const [];
    latest = null;
    loading = false;
    api = CusApi();
  }
}
