/// The cart as the Kurv screen sees it (AGIL-1 v2 Phase 5), mapped from the
/// legacy `get-order-cart` response.
class KurvLine {
  const KurvLine({
    required this.cartId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.storeId,
    this.imageUrl,
    this.description,
    this.addedByAegil = false,
  });

  final int cartId;
  final int productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final int storeId;
  final String? imageUrl;
  final String? description;

  /// A line Ægil put in the basket (the cart row carries a Snurre
  /// conversation) — rendered as "Lagt i kurven av Ægil … · Angre".
  final bool addedByAegil;

  double get sum => unitPrice * quantity;

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

  factory KurvLine.fromJson(Map<String, dynamic> j) {
    final amount = _d(j['product_amount']);
    final discount = _d(j['discount_amount']);
    final image = '${j['product_image'] ?? j['product_image_token'] ?? ''}';
    return KurvLine(
      cartId: (j['id'] as num?)?.toInt() ?? 0,
      productId: (j['product_id'] as num?)?.toInt() ?? 0,
      name: '${j['product_name'] ?? ''}',
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: discount > 0 && discount < amount ? discount : amount,
      storeId: (j['store_id'] as num?)?.toInt() ?? 0,
      imageUrl: image.isEmpty ? null : image,
      description: '${j['description'] ?? ''}'.isEmpty
          ? null
          : '${j['description']}',
      addedByAegil:
          j['snurre_conversation_id'] != null || j['added_by'] == 'aegil',
    );
  }
}

class KurvState {
  const KurvState({
    this.lines = const [],
    this.storeId = 0,
    this.serviceCategoryId = 0,
    this.count = 0,
  });

  final List<KurvLine> lines;
  final int storeId;
  final int serviceCategoryId;
  final int count;

  bool get isEmpty => lines.isEmpty;
  double get subtotal => lines.fold(0, (a, l) => a + l.sum);
  List<KurvLine> get aegilLines => [
    for (final l in lines)
      if (l.addedByAegil) l,
  ];

  factory KurvState.fromCartJson(Map<String, dynamic> json) {
    final list = json['order_list'];
    return KurvState(
      lines: [
        for (final e in (list is List ? list : const []))
          if (e is Map) KurvLine.fromJson(Map<String, dynamic>.from(e)),
      ],
      storeId: (json['store_id'] as num?)?.toInt() ?? 0,
      serviceCategoryId: (json['service_cat_id'] as num?)?.toInt() ?? 0,
      count: (json['count_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A delivery slot on the Levering sheet.
class KasseSlot {
  const KasseSlot({
    required this.id,
    required this.label,
    required this.line,
    this.at,
  });

  final String id;
  final String label;
  final String line;

  /// Null for "så fort som mulig".
  final DateTime? at;

  String? get scheduleDateTime {
    final t = at;
    if (t == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:00';
  }
}
