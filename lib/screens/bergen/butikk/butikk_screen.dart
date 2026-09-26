import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';
import 'mote_butikk_screen.dart';
import 'produkt_sheet.dart';
import 'restaurant_body.dart';

export 'restaurant_body.dart'
    show RestaurantButikkBody, RestaurantButikkBodyState;

/// `/bergen/butikk/{id}` (arguments: `id`, optional `name`, `category`,
/// `product_id`). Loads the store and shows the restaurant page
/// (`erButikk` ≈L3035–3520) or, for a fashion / gift store, the
/// `{{ butSideLabel }}` page (≈L2705–3033, [MoteButikkScreen]).
class ButikkScreen extends StatefulWidget {
  const ButikkScreen({
    super.key,
    this.storeId,
    this.name,
    this.category,
    this.productId,
    this.api,
    this.customerApi,
    this.kasseApi,
    this.preloaded,
  });

  final int? storeId;
  final String? name;
  final String? category;
  final int? productId;
  final OpsButikkApi? api;
  final OpsCustomerApi? customerApi;

  /// Tests inject the cart.
  final OpsKasseApi? kasseApi;

  /// Tests inject the store.
  final BergenStoreInfo? preloaded;

  @override
  State<ButikkScreen> createState() => _ButikkScreenState();
}

class _ButikkScreenState extends State<ButikkScreen> {
  bool _routeRead = false;
  int _id = 0;
  String? _name;
  String? _category;
  int? _productId;
  BergenStoreInfo? _store;
  bool _missing = false;
  final GlobalKey<RestaurantButikkBodyState> _bodyKey = GlobalKey();

  OpsButikkApi get _api => widget.api ?? OpsButikkApi();
  OpsCustomerApi get _customer => widget.customerApi ?? OpsCustomerApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _id = widget.storeId ?? int.tryParse(args['id'] ?? '') ?? 0;
    _name = widget.name ?? args['name'];
    _category = widget.category ?? args['category'];
    _productId = widget.productId ?? int.tryParse(args['product_id'] ?? '');
    if (widget.preloaded != null) {
      _store = widget.preloaded;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openRequestedProduct(),
      );
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final store = await _api.store(_id, categoryHint: _category);
    if (!mounted) return;
    setState(() {
      _store = store;
      _missing = store == null;
    });
    _openRequestedProduct();
  }

  void _openRequestedProduct() {
    final store = _store;
    final pid = _productId;
    if (store == null || pid == null) return;
    final item = store.allItems.where((i) => i.id == pid).firstOrNull;
    if (item == null) return;
    _productId = null;
    // After the first frame, so the page is under the sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final body = _bodyKey.currentState;
      if (body != null) {
        body.open(item);
      } else {
        showProduktSheet(
          context,
          item: item,
          api: _api,
          customerApi: _customer,
          readyMinutes: store.deliveryMinutes,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (_missing) {
      return Scaffold(
        backgroundColor: BergenTokens.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: BergenTokens.ink,
        ),
        body: Center(
          child: Text(
            ButikkCopy.a1_butikk_not_found,
            key: const Key('a1_butikk_not_found'),
            style: bText(
              context,
              13,
              weight: FontWeight.w700,
              color: BergenTokens.inkSecondary,
            ),
          ),
        ),
      );
    }
    if (store == null) {
      return Scaffold(
        backgroundColor: BergenTokens.paper,
        body: Center(
          child: CircularProgressIndicator(
            color: BergenTokens.teal,
            semanticsLabel: _name,
          ),
        ),
      );
    }
    if (store.isFashionOrGift) {
      return MoteButikkScreen(store: store, api: _api, customerApi: _customer);
    }
    return RestaurantButikkBody(
      key: _bodyKey,
      store: store,
      api: _api,
      customerApi: _customer,
      kasseApi: widget.kasseApi,
    );
  }
}
