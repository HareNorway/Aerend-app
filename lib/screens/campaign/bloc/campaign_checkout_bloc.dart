import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../campaign_repo.dart';
import '../models/campaign_order_pojo.dart';
import 'campaign_detail_bloc.dart';

class CampaignCheckoutBloc extends Bloc {
  final BuildContext context;
  final State state;
  final CampaignRepo _repo = CampaignRepo();

  final _loadingSubject = BehaviorSubject<bool>.seeded(false);
  final _errorSubject = BehaviorSubject<String?>.seeded(null);

  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;

  CampaignCheckoutBloc(this.context, this.state);

  void setLoading(bool value) => _loadingSubject.sink.add(value);

  Future<CampaignPlaceOrderPojo?> submitOrder({
    required String slug,
    required String name,
    required String email,
    required String phone,
    required String deliveryMethod,
    required String paymentMethod,
    String? streetAddress,
    String? postalCode,
    String? city,
    int? addressId,
    String? notes,
    required List<CampaignCartItem> cartItems,
  }) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (state.mounted) openSimpleSnackbar(languages.internetConnLostTitle);
      return null;
    }

    _loadingSubject.sink.add(true);
    _errorSubject.sink.add(null);

    try {
      final body = <String, dynamic>{
        'slug': slug,
        'name': name,
        'email': email,
        'phone': phone,
        'delivery_method': deliveryMethod,
        'payment_method': paymentMethod,
        'items': cartItems
            .map((c) => {
                  'product_id': c.product.id,
                  'quantity': c.quantity,
                })
            .toList(),
      };

      if (deliveryMethod == 'delivery') {
        if (addressId != null) body['address_id'] = addressId;
        if (streetAddress != null) body['street_address'] = streetAddress;
        if (postalCode != null) body['postal_code'] = postalCode;
        if (city != null) body['city'] = city;
      }
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;

      final response =
          CampaignPlaceOrderPojo.fromJson(await _repo.placeOrder(body));

      if (!state.mounted) return null;
      String message =
          getApiMsg(context, response.messageCode, response.message);

      if (isApiStatus(context, response.status, message, true)) {
        // Keep loading true — checkout continues into Stripe/Vipps UI and
        // clears loading once that sheet/redirect is underway (avoids a gap
        // where swipe-to-pay re-enables before the payment UI appears).
        return response;
      } else {
        _errorSubject.sink.add(message);
        _loadingSubject.sink.add(false);
        return null;
      }
    } catch (e) {
      if (!state.mounted) return null;
      _errorSubject.sink.add(e.toString());
      _loadingSubject.sink.add(false);
      openSimpleSnackbar(e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _loadingSubject.close();
    _errorSubject.close();
  }
}
