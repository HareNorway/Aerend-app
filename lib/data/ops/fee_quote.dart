/// The delivery fee as the pricing engine quotes it (Customer v2 Step 1; pricing
/// spec §2.4): the lines in the spec's words, the total, and how long the price
/// holds. Kassen, the agentic basket and the tracking details read the same
/// shape, so the customer sees one fee everywhere. The app never does the
/// arithmetic — the lines come from the server and sum to the total there.
class FeeLine {
  const FeeLine({required this.key, required this.label, required this.amountOre, this.detail = ''});

  factory FeeLine.fromJson(Map<String, dynamic> j) =>
      FeeLine(key: '${j['key'] ?? ''}', label: '${j['label'] ?? ''}', amountOre: _int(j['amount_ore']), detail: '${j['detail'] ?? ''}');

  final String key;
  final String label;
  final int amountOre;
  final String detail;
}

class FeeQuoteView {
  const FeeQuoteView({required this.quoteId, required this.totalOre, required this.lines, this.expiresAt, this.flex = false});

  /// `order-preview` with `pricing.engine` on: `quote_id`, `fee_components`, `fee_total_ore`, `quote_expires_at`.
  static FeeQuoteView? fromPreview(Map<String, dynamic> j) {
    final id = j['quote_id'];
    if (id is! String || id.isEmpty) return null;
    return FeeQuoteView(
      quoteId: id,
      totalOre: _int(j['fee_total_ore']),
      lines: _lines(j['fee_components']),
      expiresAt: DateTime.tryParse('${j['quote_expires_at'] ?? ''}'),
      flex: j['flex'] == true,
    );
  }

  /// The engine's `toApi()` (a 422 `QUOTE_EXPIRED` carries the new one): `quote_id`, `components`, `total_ore`, `expires_at`, `flex`.
  static FeeQuoteView? fromApi(Map<String, dynamic>? j) {
    if (j == null || j['quote_id'] is! String) return null;
    return FeeQuoteView(
      quoteId: j['quote_id'] as String,
      totalOre: _int(j['total_ore']),
      lines: _lines(j['components']),
      expiresAt: DateTime.tryParse('${j['expires_at'] ?? ''}'),
      flex: j['flex'] == true,
    );
  }

  /// The backend's `FeeBreakdown` (agentic basket `delivery_breakdown`, tracking `fee_breakdown`).
  static FeeQuoteView? fromBreakdown(dynamic j) {
    if (j is! Map || j['quote_id'] is! String) return null;
    return FeeQuoteView(quoteId: j['quote_id'] as String, totalOre: _int(j['total_ore']), lines: _lines(j['lines']), flex: j['flex'] == true);
  }

  final String quoteId;
  final int totalOre;
  final List<FeeLine> lines;
  final DateTime? expiresAt;
  final bool flex;

  double get totalKr => totalOre / 100;

  bool isExpired(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);

  static List<FeeLine> _lines(dynamic v) => v is List
      ? [
          for (final c in v)
            if (c is Map) FeeLine.fromJson(Map<String, dynamic>.from(c)),
        ]
      : const [];
}

int _int(dynamic v) => v is num ? v.round() : (int.tryParse('$v') ?? 0);
