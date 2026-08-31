import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../campaign_repo.dart';
import '../models/campaign_detail_pojo.dart';

class CampaignCartItem {
  final CampaignProduct product;
  int quantity;

  CampaignCartItem({required this.product, this.quantity = 1});

  double get lineTotal => product.price * quantity;
}

class CampaignDetailBloc extends Bloc {
  final BuildContext context;
  final State state;
  final String slug;
  final CampaignRepo _repo = CampaignRepo();

  final _detailSubject = BehaviorSubject<ApiResponse<CampaignDetailPojo>>();
  final _cartSubject = BehaviorSubject<List<CampaignCartItem>>.seeded([]);

  Stream<ApiResponse<CampaignDetailPojo>> get detailStream =>
      _detailSubject.stream;
  Stream<List<CampaignCartItem>> get cartStream => _cartSubject.stream;

  List<CampaignCartItem> get currentCart => _cartSubject.value;
  CampaignDetail? get currentCampaign =>
      _detailSubject.valueOrNull?.data?.campaign;
  double get cartTotal =>
      currentCart.fold(0, (sum, item) => sum + item.lineTotal);
  int get cartItemCount =>
      currentCart.fold(0, (sum, item) => sum + item.quantity);

  CampaignDetailBloc(this.context, this.state, this.slug) {
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      _detailSubject.sink.add(ApiResponse.loading());
      try {
        var response =
            CampaignDetailPojo.fromJson(await _repo.getCampaignDetail(slug));

        if (!state.mounted) return;
        if (response.isNotFound) {
          _detailSubject.sink.add(ApiResponse.error('Campaign not found'));
        } else {
          _detailSubject.sink.add(ApiResponse.completed(response));
        }
      } catch (e) {
        if (!state.mounted) return;
        _detailSubject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  void addToCart(CampaignProduct product) {
    final cart = List<CampaignCartItem>.from(currentCart);
    final idx = cart.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      cart[idx].quantity++;
    } else {
      cart.add(CampaignCartItem(product: product));
    }
    _cartSubject.sink.add(cart);
  }

  void incrementQty(int productId) {
    final cart = List<CampaignCartItem>.from(currentCart);
    final idx = cart.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      cart[idx].quantity++;
      _cartSubject.sink.add(cart);
    }
  }

  void decrementQty(int productId) {
    final cart = List<CampaignCartItem>.from(currentCart);
    final idx = cart.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      if (cart[idx].quantity <= 1) {
        cart.removeAt(idx);
      } else {
        cart[idx].quantity--;
      }
      _cartSubject.sink.add(cart);
    }
  }

  void removeFromCart(int productId) {
    final cart = List<CampaignCartItem>.from(currentCart);
    cart.removeWhere((i) => i.product.id == productId);
    _cartSubject.sink.add(cart);
  }

  void clearCart() {
    _cartSubject.sink.add([]);
  }

  int getQty(int productId) {
    final item = currentCart.where((i) => i.product.id == productId);
    return item.isNotEmpty ? item.first.quantity : 0;
  }

  Future<void> refresh() => _fetchDetail();

  @override
  void dispose() {
    _detailSubject.close();
    _cartSubject.close();
  }
}
