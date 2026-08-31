import 'package:flutter/material.dart';

import '../redux/store.dart';
import '../screens/deliveryService/checkout/checkout.dart';
import '../utils/utils.dart';

class BottomCartLayout extends StatefulWidget {
  const BottomCartLayout({super.key});

  @override
  State<BottomCartLayout> createState() => _BottomCartLayoutState();
}

class _BottomCartLayoutState extends State<BottomCartLayout> {
  bool _isOpeningCheckout = false;

  Future<void> _navigateToCheckout(BuildContext context) async {
    // Prevent multiple taps
    if (_isOpeningCheckout) return;

    setState(() {
      _isOpeningCheckout = true;
    });

    try {
      if (!mounted) return;
      await openScreenWithResult(context, const CheckOut());
    } finally {
      // Add a small delay before allowing next tap
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _isOpeningCheckout = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          int prodQuantity = 0;
          double productTotalAmount = 0;
          if (state.cartItemState.cartItemsList.isNotEmpty) {
            for (var element in state.cartItemState.cartItemsList) {
              prodQuantity = prodQuantity + element.prodQuantity;
              productTotalAmount = productTotalAmount +
                  (element.prodTotalAmount * element.prodQuantity);
            }
            return GestureDetector(
              onTap: _isOpeningCheckout
                  ? null
                  : () => _navigateToCheckout(context),
              child: Container(
                color: _isOpeningCheckout
                    ? colorPrimary.withOpacity(0.7)
                    : colorPrimary,
                height: deviceHeight * 0.06,
                padding: EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.025, end: deviceWidth * 0.025),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            "$prodQuantity ${languages.item}",
                            textAlign: TextAlign.center,
                            style: bodyText(
                                fontWeight: FontWeight.bold,
                                textColor: colorWhite),
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(
                                start: deviceWidth * 0.02,
                                end: deviceWidth * 0.02),
                            padding: EdgeInsets.symmetric(
                                vertical: deviceHeight * 0.018),
                            child: VerticalDivider(
                              color: colorWhite,
                              thickness: deviceWidth * 0.004,
                              width: deviceWidth * 0.008,
                            ),
                          ),
                          Text(
                            getAmountWithCurrency(productTotalAmount),
                            textAlign: TextAlign.center,
                            style: bodyText(
                                fontWeight: FontWeight.bold,
                                textColor: colorWhite),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 0,
                      child: Row(
                        children: [
                          Text(
                            _isOpeningCheckout
                                ? 'Opening...'
                                : languages.viewCart,
                            textAlign: TextAlign.center,
                            style: bodyText(
                                fontWeight: FontWeight.bold,
                                textColor: colorWhite,
                                fontSize: textSizeMediumBig),
                          ),
                          Container(
                              margin: EdgeInsetsDirectional.only(
                                  start: deviceWidth * 0.008),
                              child: _isOpeningCheckout
                                  ? SizedBox(
                                      width: iconSize,
                                      height: iconSize,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                colorWhite),
                                      ),
                                    )
                                  : Icon(
                                      CustomIcons.cartOrderDetailsScreen,
                                      color: colorWhite,
                                      size: iconSize,
                                    ))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Container();
          }
        });
  }
}
