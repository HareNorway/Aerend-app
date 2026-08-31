import '../screens/deliveryService/checkout/cart_dl.dart';
import '../screens/rideService/searched_location_dl.dart';

class AddItemInCart {
  final CartItem? cartItem;

  AddItemInCart({this.cartItem});
}

class UpdateAndDeleteItemFromCart {
  int? productId, productQuantity, productCustomize;
  String? productOptions, productToppings;
  bool? isAdd;

  UpdateAndDeleteItemFromCart({this.productId, this.productQuantity, this.productCustomize, this.productOptions, this.productToppings, this.isAdd});
}

class RepeatLastItem {
  int? productId;

  RepeatLastItem({this.productId});
}

class RemoveProductFromCart {
  int? productId;

  RemoveProductFromCart({this.productId});
}

class ClearCartItem {}

class AddSearchedLocation {
  final SearchedLocation? searchedLocation;

  AddSearchedLocation({this.searchedLocation});
}

//Coupons
class AddRemoveSelectedCoupons {
  int? index;
  String? categoryName;
  int? couponId;
  bool? isAdd;

  AddRemoveSelectedCoupons({this.index, this.categoryName, this.couponId, this.isAdd});
}

class ClearSelectedCoupons {}
