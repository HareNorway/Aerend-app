import 'package:flutter/material.dart';

import 'cart_state.dart';
import 'searched_location_state.dart';

@immutable
class AppState {
  final CartItemState cartItemState;
  final SearchedLocationItemState searchedLocationItemState;

  const AppState({required this.cartItemState, required this.searchedLocationItemState});

  factory AppState.initial() {
    return AppState(
      cartItemState: CartItemState.initial(),
      searchedLocationItemState: SearchedLocationItemState.initial(),
    );
  }

  dynamic toJson() {
    return {
      'cartItemState': cartItemState.toJson(),
      'searchedLocationItemState': searchedLocationItemState.toJson(),
    };
  }

  static AppState? fromJson(dynamic json) {
    return json != null
        ? AppState(
            cartItemState: CartItemState.fromJson(json["cartItemState"])!,
            searchedLocationItemState: SearchedLocationItemState.fromJson(json["searchedLocationItemState"])!)
        : null;
  }

  AppState copyWith({CartItemState? cartItemState, SearchedLocationItemState? searchedLocationItemState}) {
    return AppState(
        cartItemState: cartItemState ?? this.cartItemState,
        searchedLocationItemState: searchedLocationItemState ?? this.searchedLocationItemState);
  }
}
