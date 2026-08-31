import 'package:flutter/foundation.dart';

import '../dugnad_state.dart';
import 'club_shop_models.dart';

/// Local cart, keyed by club. Switching club clears lines.
class ClubShopCart extends ChangeNotifier {
  ClubShopCart._();
  static final ClubShopCart instance = ClubShopCart._();

  int _clubId = 0;
  final List<ClubShopCartLine> _lines = [];
  ClubShopMemberInfo _member = const ClubShopMemberInfo();
  ClubShopPartnerInfo _partner = const ClubShopPartnerInfo();
  int _pointsPerOrder = 75;

  List<ClubShopCartLine> get lines => List.unmodifiable(_lines);

  ClubShopMemberInfo get member => _member;
  ClubShopPartnerInfo get partner => _partner;
  int get pointsPerOrder => _pointsPerOrder;

  int get itemCount => _lines.fold(0, (s, l) => s + l.qty);

  int get ordinaryTotal =>
      _lines.fold(0, (s, l) => s + l.product.ordinaryPrice * l.qty);

  int get totalMember =>
      _lines.fold(0, (s, l) => s + l.product.memberPrice * l.qty);

  int get discountTotal => (ordinaryTotal - totalMember).clamp(0, 1 << 30);

  void attachContext({
    ClubShopMemberInfo? member,
    ClubShopPartnerInfo? partner,
    int? pointsPerOrder,
  }) {
    _bindClub();
    if (member != null) _member = member;
    if (partner != null) _partner = partner;
    if (pointsPerOrder != null) _pointsPerOrder = pointsPerOrder;
  }

  void _bindClub() {
    final clubId = DugnadState.instance.clubId;
    if (clubId != _clubId) {
      _clubId = clubId;
      _lines.clear();
    }
  }

  int qtyFor({required int productId, String? size}) {
    _bindClub();
    return _lines
        .where((l) =>
            l.product.id == productId && (size == null || l.size == size))
        .fold(0, (s, l) => s + l.qty);
  }

  int remainingStock(ClubShopProduct product, String size) {
    final row = product.sizes.where((s) => s.label == size).toList();
    if (row.isEmpty) return 0;
    return (row.first.quantity - qtyFor(productId: product.id, size: size))
        .clamp(0, 1 << 30);
  }

  bool add(ClubShopProduct product, String size) {
    _bindClub();
    if (remainingStock(product, size) <= 0) return false;
    final i = _lines.indexWhere(
      (l) => l.product.id == product.id && l.size == size,
    );
    if (i >= 0) {
      final cur = _lines[i];
      _lines[i] = ClubShopCartLine(
        product: cur.product,
        size: cur.size,
        qty: cur.qty + 1,
      );
    } else {
      _lines.add(ClubShopCartLine(product: product, size: size, qty: 1));
    }
    notifyListeners();
    return true;
  }

  void setQty(ClubShopProduct product, String size, int qty) {
    _bindClub();
    final i = _lines.indexWhere(
      (l) => l.product.id == product.id && l.size == size,
    );
    if (qty <= 0) {
      if (i >= 0) {
        _lines.removeAt(i);
        notifyListeners();
      }
      return;
    }
    final max = product.sizes
        .where((s) => s.label == size)
        .fold<int>(0, (s, row) => row.quantity);
    final next = qty.clamp(1, max <= 0 ? 1 : max);
    if (i >= 0) {
      _lines[i] = ClubShopCartLine(
        product: product,
        size: size,
        qty: next,
      );
    } else {
      _lines.add(ClubShopCartLine(product: product, size: size, qty: next));
    }
    notifyListeners();
  }

  void removeLine(ClubShopProduct product, String size) {
    setQty(product, size, 0);
  }

  void clear() {
    _bindClub();
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toApiLines() {
    _bindClub();
    return _lines
        .map((l) => {
              'product_id': l.product.id,
              'size': l.size,
              'qty': l.qty,
            })
        .toList();
  }
}
