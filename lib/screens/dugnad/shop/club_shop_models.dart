class ClubShopMemberInfo {
  final String number;
  final String name;

  const ClubShopMemberInfo({this.number = '', this.name = ''});

  factory ClubShopMemberInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ClubShopMemberInfo();
    final rawName = json['name']?.toString();
    return ClubShopMemberInfo(
      number: (json['no'] ?? json['membership_number'] ?? '').toString(),
      name: rawName == null || rawName == 'null' ? '' : rawName,
    );
  }

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }
}

class ClubShopAccess {
  final bool enabled;
  final bool unlocked;
  final ClubShopMemberInfo? member;

  const ClubShopAccess({
    this.enabled = false,
    this.unlocked = false,
    this.member,
  });

  factory ClubShopAccess.fromJson(Map<String, dynamic> json) {
    final memberRaw = json['member'];
    return ClubShopAccess(
      enabled: json['club_shop_enabled'] == true,
      unlocked: json['unlocked'] == true,
      member: memberRaw is Map
          ? ClubShopMemberInfo.fromJson(Map<String, dynamic>.from(memberRaw))
          : null,
    );
  }
}

class ClubShopUnlockResult {
  final bool ok;
  final String reason;
  final String message;
  final ClubShopMemberInfo? member;

  const ClubShopUnlockResult({
    required this.ok,
    this.reason = '',
    this.message = '',
    this.member,
  });

  factory ClubShopUnlockResult.fromJson(Map<String, dynamic> json) {
    final memberRaw = json['member'];
    final ok = json['status'] == 1 || json['unlocked'] == true;
    return ClubShopUnlockResult(
      ok: ok,
      reason: json['reason']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      member: memberRaw is Map
          ? ClubShopMemberInfo.fromJson(Map<String, dynamic>.from(memberRaw))
          : null,
    );
  }
}

class ClubShopCatalog {
  final ClubShopPartnerInfo? partner;
  final ClubShopCollectionInfo? collection;
  final List<ClubShopProduct> products;
  final int pointsPerOrder;

  const ClubShopCatalog({
    this.partner,
    this.collection,
    this.products = const [],
    this.pointsPerOrder = 75,
  });

  factory ClubShopCatalog.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'] is Map
        ? Map<String, dynamic>.from(json['catalog'] as Map)
        : json;
    final productsRaw = catalog['products'] as List? ?? [];
    final partnerRaw = catalog['partner'];
    final collectionRaw = catalog['collection'];
    return ClubShopCatalog(
      partner: partnerRaw is Map
          ? ClubShopPartnerInfo.fromJson(Map<String, dynamic>.from(partnerRaw))
          : null,
      collection: collectionRaw is Map
          ? ClubShopCollectionInfo.fromJson(
              Map<String, dynamic>.from(collectionRaw),
            )
          : null,
      products: productsRaw
          .whereType<Map>()
          .map((e) => ClubShopProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pointsPerOrder: (catalog['points_per_order'] as num?)?.toInt() ?? 75,
    );
  }
}

class ClubShopPartnerInfo {
  final String name;
  final String address;
  final String pickupPoint;

  const ClubShopPartnerInfo({
    this.name = '',
    this.address = '',
    this.pickupPoint = '',
  });

  factory ClubShopPartnerInfo.fromJson(Map<String, dynamic> json) {
    return ClubShopPartnerInfo(
      name: _shopText(json['name']),
      address: _shopText(json['address']),
      pickupPoint: _shopText(json['pickup_point'] ?? json['pickup']),
    );
  }
}

class ClubShopCollectionInfo {
  final int id;
  final String name;
  final String season;
  final String blurb;
  final String? heroImageUrl;
  final int pointsPerOrder;

  const ClubShopCollectionInfo({
    this.id = 0,
    this.name = '',
    this.season = '',
    this.blurb = '',
    this.heroImageUrl,
    this.pointsPerOrder = 75,
  });

  factory ClubShopCollectionInfo.fromJson(Map<String, dynamic> json) {
    final hero = json['hero_image_url']?.toString();
    return ClubShopCollectionInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: _shopText(json['name']),
      season: _shopText(json['season']),
      blurb: _shopText(json['blurb']),
      heroImageUrl:
          (hero == null || hero.isEmpty || hero == 'null') ? null : hero,
      pointsPerOrder: (json['points_per_order'] as num?)?.toInt() ?? 75,
    );
  }
}

class ClubShopProduct {
  final int id;
  final String name;
  final String description;
  final String category;
  final int ordinaryPrice;
  final int discountPct;
  final int memberPrice;
  final List<String> audiences;
  final bool soldOut;
  final List<String> imageUrls;
  final List<ClubShopSize> sizes;

  const ClubShopProduct({
    required this.id,
    this.name = '',
    this.description = '',
    this.category = '',
    this.ordinaryPrice = 0,
    this.discountPct = 0,
    this.memberPrice = 0,
    this.audiences = const [],
    this.soldOut = false,
    this.imageUrls = const [],
    this.sizes = const [],
  });

  factory ClubShopProduct.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List? ?? [];
    final sizes = json['sizes'] as List? ?? [];
    final aud = json['audiences'] as List? ?? [];
    return ClubShopProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      ordinaryPrice: (json['ordinary_price'] as num?)?.toInt() ?? 0,
      discountPct: (json['discount_pct'] as num?)?.toInt() ?? 0,
      memberPrice: (json['member_price'] as num?)?.toInt() ?? 0,
      audiences:
          aud.map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
      soldOut: json['sold_out'] == true,
      imageUrls: images
          .whereType<Map>()
          .map((e) => e['url']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      sizes: sizes
          .whereType<Map>()
          .map((e) => ClubShopSize.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  bool matchesAudience(String audience) {
    if (audiences.isEmpty) return true;
    return audiences.contains(audience);
  }
}

class ClubShopSize {
  final String label;
  final int quantity;
  final String stockLabel;
  final bool available;

  const ClubShopSize({
    this.label = '',
    this.quantity = 0,
    this.stockLabel = '',
    this.available = false,
  });

  factory ClubShopSize.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 0;
    return ClubShopSize(
      label: (json['size'] ?? json['size_label'] ?? '').toString(),
      quantity: qty,
      stockLabel: json['stock_label']?.toString() ?? '',
      available: json['available'] == true || qty > 0,
    );
  }
}

class ClubShopReceiptLine {
  final String name;
  final String size;
  final int qty;
  final int memberUnit;
  final int ordinaryUnit;

  const ClubShopReceiptLine({
    this.name = '',
    this.size = '',
    this.qty = 1,
    this.memberUnit = 0,
    this.ordinaryUnit = 0,
  });

  factory ClubShopReceiptLine.fromJson(Map<String, dynamic> json) {
    return ClubShopReceiptLine(
      name: _shopText(json['name'] ?? json['product_name']),
      size: _shopText(json['size'] ?? json['size_label']),
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      memberUnit: (json['member_unit'] as num?)?.toInt() ?? 0,
      ordinaryUnit: (json['ordinary_unit'] as num?)?.toInt() ?? 0,
    );
  }

  int get lineMember => memberUnit * qty;
}

class ClubShopPaidOrder {
  final String orderNumber;
  final String verifyUrl;
  final String membershipNumber;
  final String partnerName;
  final String partnerAddress;
  final String pickupPoint;
  final String status;
  final int ordinarySum;
  final int discountSum;
  final int amountPaid;
  final int pointsAwarded;
  final DateTime? paidAt;
  final List<ClubShopReceiptLine> items;

  const ClubShopPaidOrder({
    this.orderNumber = '',
    this.verifyUrl = '',
    this.membershipNumber = '',
    this.partnerName = '',
    this.partnerAddress = '',
    this.pickupPoint = '',
    this.status = '',
    this.ordinarySum = 0,
    this.discountSum = 0,
    this.amountPaid = 0,
    this.pointsAwarded = 0,
    this.paidAt,
    this.items = const [],
  });

  /// QR payload: landing verify URL when the API sent one, else the order number.
  String get qrPayload {
    final url = verifyUrl.trim();
    if (url.isNotEmpty) return url;
    return orderNumber;
  }

  factory ClubShopPaidOrder.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? json['lines'] as List? ?? [];
    final paidRaw = json['paid_at']?.toString();
    return ClubShopPaidOrder(
      orderNumber: _shopText(json['order_number'] ?? json['no']),
      verifyUrl: _shopText(json['verify_url']),
      membershipNumber: _shopText(
        json['membership_number'] ?? json['member'],
      ),
      partnerName: _shopText(json['partner_name']),
      partnerAddress: _shopText(json['partner_address']),
      pickupPoint: _shopText(json['pickup_point'] ?? json['pickup']),
      status: _shopText(json['status']),
      ordinarySum: (json['ordinary_sum'] as num?)?.toInt() ?? 0,
      discountSum: (json['discount_sum'] as num?)?.toInt() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toInt() ?? 0,
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ??
          (json['points'] as num?)?.toInt() ??
          0,
      paidAt: paidRaw == null || paidRaw.isEmpty
          ? null
          : DateTime.tryParse(paidRaw),
      items: itemsRaw
          .whereType<Map>()
          .map((e) => ClubShopReceiptLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ClubShopCartLine {
  final ClubShopProduct product;
  final String size;
  final int qty;

  const ClubShopCartLine({
    required this.product,
    required this.size,
    this.qty = 1,
  });
}

String _shopText(dynamic value) {
  if (value == null) return '';
  final text = value.toString();
  return text == 'null' ? '' : text;
}

String shopKr(int n) {
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) buf.write('\u00A0');
    buf.write(digits[i]);
  }
  return n < 0 ? '−${buf.toString()} kr' : '${buf.toString()} kr';
}
