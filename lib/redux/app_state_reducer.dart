import 'package:redux/redux.dart';

import '../screens/rideService/searched_location_dl.dart';
import '../utils/utils.dart';
import 'actions.dart';
import 'app_state.dart';
import 'cart_state.dart';
import 'searched_location_state.dart';

AppState appReducer(AppState state, dynamic action) => AppState(
      cartItemState: cartItemsReducer(state.cartItemState, action),
      searchedLocationItemState: searchedLocationItemsReducer(state.searchedLocationItemState, action),
    );

final cartItemsReducer = combineReducers<CartItemState>([
  TypedReducer<CartItemState, AddItemInCart>(_addItemInCartAction).call,
  TypedReducer<CartItemState, UpdateAndDeleteItemFromCart>(_updateAndDeleteItemFromCartAction).call,
  TypedReducer<CartItemState, RepeatLastItem>(_repeatLastItem).call,
  TypedReducer<CartItemState, RemoveProductFromCart>(_removeProduct).call,
  TypedReducer<CartItemState, ClearCartItem>(_clearCartItemAction).call,
]);

final searchedLocationItemsReducer = combineReducers<SearchedLocationItemState>([
  TypedReducer<SearchedLocationItemState, AddSearchedLocation>(_addSearchedLocation).call,
]);

// final selectedCouponsReducer = combineReducers<SelectedCouponsState>([
//   // TypedReducer<SelectedCouponsState, AddRemoveSelectedCoupons>(_addRemoveSelectedCoupons),
//   // TypedReducer<SelectedCouponsState, ClearSelectedCoupons>(_clearSelectedCouponsAction),
// ]);

CartItemState _addItemInCartAction(CartItemState state, AddItemInCart action) {
  var cartItemList = state.cartItemsList;
  int pos = state.cartItemsList.indexWhere((element) {
    bool productId = action.cartItem!.prodId == element.prodId;
    bool productAmount = action.cartItem!.prodTotalAmount == element.prodTotalAmount;
    bool options = action.cartItem!.prodCustomizeOption == element.prodCustomizeOption;
    bool toppings = action.cartItem!.prodCustomizeToppings == element.prodCustomizeToppings;
    bool customizeSize = action.cartItem!.prodCustomizeSize != 0 ? (action.cartItem!.prodCustomizeSize == element.prodCustomizeSize) : true;
    return (productId && productAmount && customizeSize && options && toppings);
  });
  if (pos >= 0) {
    cartItemList[pos].prodQuantity = cartItemList[pos].prodQuantity + 1;
  } else {
    cartItemList.add(action.cartItem!);
  }
  return state.copyWith(cartItemsList: cartItemList);
}

CartItemState _updateAndDeleteItemFromCartAction(CartItemState state, UpdateAndDeleteItemFromCart action) {
  var cartItemList = state.cartItemsList;
  int pos = state.cartItemsList.indexWhere((element) {
    bool productId = action.productId == element.prodId;
    bool options = action.productOptions!.isNotEmpty ? (action.productOptions == element.prodCustomizeOption) : true;
    bool toppings = action.productToppings!.isNotEmpty ? (action.productToppings == element.prodCustomizeToppings) : true;
    bool customizeSize = action.productCustomize != 0 ? (action.productCustomize == element.prodCustomizeSize) : true;
    bool productQuantity = action.productQuantity == element.prodQuantity;
    return (productId && customizeSize && productQuantity && options && toppings);
  });
  if (pos >= 0) {
    int qyt = cartItemList[pos].prodQuantity;
    if (action.isAdd!) {
      qyt = qyt + 1;
    } else {
      qyt = qyt - 1;
    }
    if (qyt > 0) {
      cartItemList[pos].prodQuantity = qyt;
    } else {
      cartItemList.removeAt(pos);
    }
    if (!action.isAdd! && cartItemList.isEmpty) {
      prefSetString(prefSelectedStoreFullResponse, "");
    }
  }
  return state.copyWith(cartItemsList: cartItemList);
}

CartItemState _removeProduct(CartItemState state, RemoveProductFromCart action) {
  var cartItemList = state.cartItemsList;
  cartItemList.removeWhere((element) => element.prodId == action.productId);
  return state.copyWith(cartItemsList: cartItemList);
}

CartItemState _repeatLastItem(CartItemState state, RepeatLastItem action) {
  var cartItemList = state.cartItemsList;
  int pos = state.cartItemsList.lastIndexWhere((element) => element.prodId == action.productId);
  if (pos >= 0) {
    cartItemList[pos].prodQuantity = cartItemList[pos].prodQuantity + 1;
  }
  return state.copyWith(cartItemsList: cartItemList);
}

CartItemState _clearCartItemAction(CartItemState state, ClearCartItem action) => state.copyWith(cartItemsList: []);

SearchedLocationItemState _addSearchedLocation(SearchedLocationItemState state, AddSearchedLocation action) {
  List<SearchedLocation>? searchedLocationItemsList = state.searchedLocationItemsList;
  if (searchedLocationItemsList != null) {
    int pos = state.searchedLocationItemsList!.indexWhere((element) {
      bool name = action.searchedLocation!.name == element.name;
      bool lat = getDoubleFromDynamic(action.searchedLocation!.lat) == getDoubleFromDynamic(element.lat);
      bool lng = getDoubleFromDynamic(action.searchedLocation!.lng) == getDoubleFromDynamic(element.lng);
      return (name && lat && lng);
    });
    if (pos == -1) {
      searchedLocationItemsList.add(action.searchedLocation!);
    }
  }
  return state.copyWith(searchedLocationItemsList: searchedLocationItemsList);
}
