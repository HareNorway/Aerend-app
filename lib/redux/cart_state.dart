import '../screens/deliveryService/checkout/cart_dl.dart';

class CartItemState {
  final List<CartItem> cartItemsList;

  CartItemState({required this.cartItemsList});

  factory CartItemState.initial() {
    return CartItemState(cartItemsList: []);
  }

  static CartItemState? fromJson(dynamic json) {
    return json != null
        ? CartItemState(
            cartItemsList: parseList(json),
          )
        : null;
  }

  dynamic toJson() {
    return {'cartItemsList': cartItemsList.map((cartItems) => cartItems.toJson()).toList()};
  }

  CartItemState copyWith({List<CartItem>? cartItemsList}) {
    return CartItemState(cartItemsList: cartItemsList ?? this.cartItemsList);
  }
}

List<CartItem> parseList(dynamic json) {
  List<CartItem> list = [];
  json["cartItemsList"].forEach((item) {
    CartItem? cartItem = CartItem.fromJson(item);
    if (cartItem != null) {
      list.add(cartItem);
    }
  });
  return list;
}
