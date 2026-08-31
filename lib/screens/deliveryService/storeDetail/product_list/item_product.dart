import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

import '../../../../commonView/common_view.dart';
import '../../../../commonView/zoom_image_view.dart';
import '../../../../dialogs/simple_dialog_util.dart';
import '../../../../redux/store.dart';
import '../../../../utils/utils.dart';
import '../../checkout/cart_dl.dart';
import '../../checkout/checkout.dart';
import '../store_detail_dl.dart';
import '../topping_check_box_group.dart';
import '../topping_radio_button_group.dart';

class ItemProduct extends StatefulWidget {
  final ProductListItem productListItem;
  final StoreDetailsPojo storeDetailsPojo;
  final bool isGrid;

  const ItemProduct({
    super.key,
    required this.productListItem,
    required this.storeDetailsPojo,
    this.isGrid = false,
  });

  @override
  State createState() => _ItemProductState();
}

class _ItemProductState extends State<ItemProduct> {
  double mainAmount = 0, addOnAmountForSingleChoice = 0, addOnAmount = 0;

  @override
  Widget build(BuildContext context) {
    var addButton = StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          int prodQuantity = 0;
          if (state.cartItemState.cartItemsList.isNotEmpty) {
            for (var element in state.cartItemState.cartItemsList) {
              if (element.prodId == widget.productListItem.productId) {
                prodQuantity = prodQuantity + element.prodQuantity;
              }
            }
          }
          return InkWell(
            onTap: () {
              if (prodQuantity > 0) return;
              // if (widget.storeDetailsPojo.storeStatus == 1) {
              addProduct(context);
              // } else {
              //   openSimpleSnackbar( languages.closeStore);
              // }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: deviceWidth * 0.01,
                vertical: prodQuantity > 0
                    ? deviceHeight * 0.004
                    : deviceHeight * 0.004,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(1.0, 1.0), //(x,y)
                    blurRadius: 3.0,
                  ),
                ],
                borderRadius:
                    BorderRadius.all(Radius.circular(deviceAverageSize * 0.01)),
              ),
              constraints: BoxConstraints(minWidth: deviceWidth * 0.2),
              child: prodQuantity > 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                            onTap: () {
                              removeProduct(context, prodQuantity);
                            },
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                  end: deviceWidth * 0.01,
                                  start: deviceWidth * 0.01),
                              child: Icon(Icons.remove,
                                  size: deviceAverageSize * 0.04,
                                  color: colorPrimary),
                            )),
                        Text(
                          "$prodQuantity",
                          style: bodyText(
                              fontWeight: FontWeight.w600,
                              textColor: colorPrimary,
                              fontSize: textSizeMediumBig),
                        ),
                        InkWell(
                            onTap: () {
                              _showRepeat(context);
                            },
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                  end: deviceWidth * 0.01,
                                  start: deviceWidth * 0.01),
                              child: Icon(Icons.add,
                                  size: deviceAverageSize * 0.04,
                                  color: colorPrimary),
                            )),
                      ],
                    )
                  : Text(
                      languages.add.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: bodyText(
                          fontWeight: FontWeight.w600,
                          textColor: colorBlack,
                          fontSize: textSizeMediumBig),
                    ),
            ),
          );
        });

    if (widget.isGrid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(PageRouteBuilder<void>(
                    opaque: false,
                    transitionDuration: const Duration(milliseconds: 400),
                    reverseTransitionDuration:
                        const Duration(milliseconds: 500),
                    pageBuilder: (BuildContext context,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation) {
                      return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? child) {
                            return Opacity(
                              opacity:
                                  const Interval(0.0, 1.0, curve: Curves.linear)
                                      .transform(animation.value),
                              child: ZoomImageView(
                                image: /*widget.productListItem.productBigImage*/
                                    widget.productListItem.productImage,
                              ),
                            );
                          });
                    }));
              },
              child: LoadImageWithPlaceHolder(
                width: double.infinity,
                height: double.infinity,
                image: widget.productListItem.productImage,
                borderRadius: BorderRadius.all(
                    Radius.circular(deviceAverageSize * 0.012)),
              ),
            ),
          ),
          SizedBox(height: deviceHeight * 0.005),
          Flexible(
            flex: 0,
            child: Text(
              widget.productListItem.productName,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  bodyText(fontWeight: FontWeight.w600, fontSize: textSizeBig),
            ),
          ),
          SizedBox(height: deviceHeight * 0.005),
          Row(
            children: [
              Flexible(
                flex: 0,
                child: Text(
                  getAmountWithCurrency(getDoubleFromDynamic(
                      widget.productListItem.productAmount)),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bodyText(fontSize: textSizeSmall),
                ),
              ),
              SizedBox(width: deviceWidth * 0.01),
              if (getDoubleFromDynamic(widget.productListItem.discountAmount) >
                  0)
                Flexible(
                  flex: 0,
                  child: Text(
                    getAmountWithCurrency(getDoubleFromDynamic(
                        widget.productListItem.discountAmount)),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(
                            textColor: colorMainLightGray,
                            fontSize: textSizeSmallest)
                        .copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.005),
          Row(
            children: [
              addButton,
              SizedBox(width: deviceWidth * 0.020),
              if ((widget.productListItem.customizeList).isNotEmpty)
                Expanded(
                  child: Text(
                    languages.addOns,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontSize: 0.022),
                  ),
                ),
            ],
          )
        ],
      );
    }
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: deviceAverageSize * 0.01,
          vertical: deviceAverageSize * 0.02),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  widget.productListItem.productName,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: headerText(fontSize: textSizeBig),
                ),
                SizedBox(height: deviceHeight * 0.01),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        getAmountWithCurrency(getDoubleFromDynamic(
                            widget.productListItem.productAmount)),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(),
                      ),
                    ),
                    SizedBox(width: deviceWidth * 0.01),
                    if (getDoubleFromDynamic(
                            widget.productListItem.discountAmount) >
                        0)
                      Flexible(
                        child: Text(
                          getAmountWithCurrency(getDoubleFromDynamic(
                              widget.productListItem.discountAmount)),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyText(
                                  textColor: colorMainLightGray,
                                  fontSize: textSizeSmallest)
                              .copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: deviceHeight * 0.005),
                ReadMoreText(
                  widget.productListItem.description,
                  trimLines: 2,
                  style: bodyText(
                      textColor: colorMainLightGray,
                      fontSize: textSizeSmallest),
                  trimMode: TrimMode.Line,
                  trimCollapsedText: languages.showMore,
                  trimExpandedText: languages.showLess,
                  lessStyle: bodyText(
                      textColor: colorBlack,
                      fontSize: textSizeSmallest,
                      fontWeight: FontWeight.w600),
                  moreStyle: bodyText(
                      textColor: colorBlack,
                      fontSize: textSizeSmallest,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          SizedBox(width: deviceWidth * 0.025),
          Expanded(
            flex: 0,
            child: Column(
              children: [
                Stack(
                  fit: StackFit.loose,
                  children: [
                    if ((widget.productListItem.productImage).isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(PageRouteBuilder<void>(
                              opaque: false,
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              reverseTransitionDuration:
                                  const Duration(milliseconds: 500),
                              pageBuilder: (BuildContext context,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation) {
                                return AnimatedBuilder(
                                    animation: animation,
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return Opacity(
                                        opacity: const Interval(0.0, 1.0,
                                                curve: Curves.linear)
                                            .transform(animation.value),
                                        child: ZoomImageView(
                                          image: widget.productListItem
                                              .productImage /*widget.productListItem.productBigImage*/,
                                        ),
                                      );
                                    });
                              }));
                        },
                        child: LoadImageWithPlaceHolder(
                          width: deviceWidth * 0.2826,
                          height: deviceWidth * 0.2826,
                          image: widget.productListItem.productImage,
                          borderRadius: BorderRadius.all(
                              Radius.circular(deviceAverageSize * 0.015)),
                        ),
                      ),
                    if ((widget.productListItem.productImage).isNotEmpty)
                      Container(
                        width: deviceWidth * 0.2826,
                        margin: EdgeInsets.only(top: deviceWidth * 0.25),
                        child: Center(child: addButton),
                      )
                    else
                      SizedBox(
                        width: deviceWidth * 0.2826,
                        height: deviceWidth * 0.26,
                        child: Center(child: addButton),
                      ),
                  ],
                ),
                SizedBox(height: deviceHeight * 0.002),
                if ((widget.productListItem.customizeList).isNotEmpty)
                  Text(
                    languages.addOns,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontSize: 0.022),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  addProduct(BuildContext context) {
    String selectedStoreDetails = prefGetString(prefSelectedStoreFullResponse);
    if (selectedStoreDetails.trim().isNotEmpty) {
      StoreDetailsPojo selectedStoreDetailsPojo = StoreDetailsPojo.fromJson(
          jsonDecode(prefGetString(prefSelectedStoreFullResponse)));
      if (selectedStoreDetailsPojo.storeId != widget.storeDetailsPojo.storeId) {
        updateCartDialog(context);
      } else {
        _showToppings(context);
      }
    } else {
      _showToppings(context);
    }
  }

  updateCartDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialogUtil(
            title: languages.updateCart,
            message: languages.updateCartMsg,
            positiveButtonTxt: languages.proceed,
            negativeButtonTxt: languages.cancel,
            onPositivePress: () {
              StoreProvider.of<AppState>(context).dispatch(ClearCartItem());
              prefSetString(prefSelectedStoreFullResponse, "");
              Navigator.pop(context, true);
              _showToppings(context);
            },
            onNegativePress: () {
              Navigator.pop(context, true);
            },
          );
        });
  }

  _showToppings(BuildContext context) {
    // if ((widget?.productListItem?.customizeList?.length ?? 0) > 0) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        mainAmount = getDoubleFromDynamic(widget.productListItem.productAmount);
        addOnAmount = 0;
        addOnAmountForSingleChoice = 0;
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: deviceHeight * 0.7,
            ),
            child: Container(
              padding: EdgeInsetsDirectional.only(
                start: deviceWidth * 0.03,
                top: deviceHeight * 0.015,
                bottom: deviceHeight * 0.015,
                end: deviceWidth * 0.03,
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.only(
                      topEnd: topRightRadiusMediumBs,
                      topStart: topLeftRadiusMediumBs),
                  color: Theme.of(context).scaffoldBackgroundColor),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topCenter,
                          child: SizedBox(
                            width: deviceWidth * 0.1,
                            child: Divider(
                              color: colorPrimary,
                              thickness: deviceHeight * 0.003,
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                widget.productListItem.productName,
                                textAlign: TextAlign.start,
                                style: bodyText(
                                    textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : colorBlack,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 0,
                              child: Text(
                                getAmountWithCurrency((mainAmount +
                                            addOnAmountForSingleChoice +
                                            addOnAmount) >
                                        0
                                    ? mainAmount +
                                        addOnAmountForSingleChoice +
                                        addOnAmount
                                    : getDoubleFromDynamic(
                                        widget.productListItem.productAmount)),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyText(
                                    fontSize: textSizeBig,
                                    textColor: colorPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Container(
                            margin: EdgeInsetsDirectional.only(
                                top: deviceHeight * 0.008),
                            child: SingleChildScrollView(
                              padding: EdgeInsetsDirectional.only(
                                  top: 0, bottom: deviceHeight * 0.08),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.productListItem.description,
                                    textAlign: TextAlign.start,
                                    style: bodyText(
                                        fontSize: textSizeSmall,
                                        textColor: colorTextCommon,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  ...(widget.productListItem.customizeList)
                                      .mapWithIndex((item, i) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsetsDirectional.only(
                                              top: deviceHeight * 0.01,
                                              bottom:
                                                  deviceAverageSize * 0.008),
                                          child: Text(
                                            item.categoryName,
                                            textAlign: TextAlign.start,
                                            style: bodyText(
                                                fontSize: textSizeSmall,
                                                textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : colorBlack,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                        item.selectionType == 1
                                            ? ToppingRadioButtonGroup(
                                                addOnAmount:
                                                    addOnAmountForSingleChoice,
                                                customizeType:
                                                    item.customizeType,
                                                labels: item.options,
                                                onSelected: (selected, amount,
                                                    addOnAmount) {
                                                  widget
                                                          .productListItem
                                                          .customizeList[i]
                                                          .selected =
                                                      selected.toString();
                                                  widget
                                                          .productListItem
                                                          .customizeList[i]
                                                          .totalAmount =
                                                      addOnAmount;
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                    (_) => setState(
                                                      () {
                                                        if (item.customizeType ==
                                                            1) {
                                                          mainAmount = amount;
                                                        } else {
                                                          double addAmount = 0;
                                                          for (CustomizeItem customizeItem
                                                              in widget
                                                                  .productListItem
                                                                  .customizeList) {
                                                            addAmount +=
                                                                customizeItem
                                                                    .totalAmount;
                                                          }
                                                          debugPrint(
                                                              "addAmount: $addAmount");
                                                          addOnAmountForSingleChoice =
                                                              addAmount;
                                                        }
                                                      },
                                                    ),
                                                  );
                                                },
                                              )
                                            : ToppingCheckboxGroup(
                                                labels: item.options,
                                                onSelected: (selected,
                                                    isChecked, amount) {
                                                  widget
                                                          .productListItem
                                                          .customizeList[i]
                                                          .selected =
                                                      selected.join(",");
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) => setState(() {
                                                                if (isChecked) {
                                                                  addOnAmount =
                                                                      addOnAmount +
                                                                          amount;
                                                                } else {
                                                                  addOnAmount =
                                                                      addOnAmount -
                                                                          amount;
                                                                }
                                                              }));
                                                },
                                              ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: StoreConnector<AppState, AppState>(
                          converter: (store) => store.state,
                          builder: (context, state) {
                            int productCustomizeSize = 0;
                            String productCustomizeOption = "",
                                productCustomizeToppings = "";
                            return CustomRoundedButton(
                              context,
                              languages.addToCart,
                              () {
                                for (int i = 0;
                                    i <
                                        (widget.productListItem.customizeList)
                                            .length;
                                    i++) {
                                  if ((widget.productListItem.customizeList[i]
                                          .selected)
                                      .isNotEmpty) {
                                    if (widget.productListItem.customizeList[i]
                                            .customizeType ==
                                        1) {
                                      productCustomizeSize = int.parse(widget
                                          .productListItem
                                          .customizeList[i]
                                          .selected);
                                    } else if (widget.productListItem
                                            .customizeList[i].customizeType ==
                                        2) {
                                      if (productCustomizeOption.isEmpty) {
                                        productCustomizeOption = widget
                                            .productListItem
                                            .customizeList[i]
                                            .selected;
                                      } else {
                                        productCustomizeOption =
                                            "$productCustomizeOption,${widget.productListItem.customizeList[i].selected}";
                                      }
                                    } else if (widget.productListItem
                                            .customizeList[i].customizeType ==
                                        3) {
                                      if (productCustomizeToppings.isEmpty) {
                                        productCustomizeToppings = widget
                                            .productListItem
                                            .customizeList[i]
                                            .selected;
                                      } else {
                                        productCustomizeToppings =
                                            "$productCustomizeToppings,${widget.productListItem.customizeList[i].selected}";
                                      }
                                    }
                                  }
                                }
                                widget.storeDetailsPojo
                                    .setCartsSelectedStoreCateId(
                                        prefGetInt(prefSelectedServiceCateId));
                                widget.storeDetailsPojo.setStoreCatName(
                                    prefGetString(prefSelectedServiceCateName));
                                widget.storeDetailsPojo.setStoreCatIcon(
                                    prefGetString(prefSelectedServiceCateIcon));
                                prefSetString(prefSelectedStoreFullResponse,
                                    jsonEncode(widget.storeDetailsPojo));
                                StoreProvider.of<AppState>(context).dispatch(
                                    AddItemInCart(
                                        cartItem: CartItem(
                                            prodId: widget
                                                .productListItem.productId,
                                            prodQuantity: 1,
                                            prodCustomizeSize:
                                                productCustomizeSize,
                                            prodTotalAmount: (mainAmount +
                                                        addOnAmountForSingleChoice +
                                                        addOnAmount) >
                                                    0
                                                ? (mainAmount +
                                                    addOnAmountForSingleChoice +
                                                    addOnAmount)
                                                : getDoubleFromDynamic(widget
                                                    .productListItem
                                                    .productAmount),
                                            prodCustomizeOption:
                                                productCustomizeOption,
                                            prodCustomizeToppings:
                                                productCustomizeToppings,
                                            productName: widget
                                                .productListItem.productName)));
                                productCustomizeSize = 0;
                                productCustomizeOption = "";
                                productCustomizeToppings = "";
                                mainAmount = 0;
                                addOnAmount = 0;
                                for (var element
                                    in widget.productListItem.customizeList) {
                                  element.selected = "";
                                }
                                Navigator.pop(context);
                              },
                              minHeight: commonBtnHeightMedium,
                              setBorder: false,
                              minWidth: double.infinity,
                              margin: EdgeInsetsDirectional.only(
                                  top: deviceHeight * 0.035,
                                  start: deviceWidth * 0.025,
                                  end: deviceWidth * 0.025),
                              padding: EdgeInsetsDirectional.zero,
                              textSize: textSizeBig,
                              textColor: colorWhite,
                              fontWeight: FontWeight.normal,
                            );
                          }),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    // }
    // else {
    //   directAddProduct(context);
    // }
  }

  _showRepeat(BuildContext context) {
    if (widget.productListItem.customizeList.isNotEmpty) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: deviceHeight * 0.7,
            ),
            child: Container(
              padding: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.03,
                  top: deviceHeight * 0.015,
                  bottom: deviceHeight * 0.015,
                  end: deviceWidth * 0.03),
              decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.only(
                      topEnd: topRightRadiusMediumBs,
                      topStart: topLeftRadiusMediumBs),
                  color: Theme.of(context).scaffoldBackgroundColor),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topCenter,
                          child: SizedBox(
                            width: deviceWidth * 0.1,
                            child: Divider(
                              color: colorPrimary,
                              thickness: deviceHeight * 0.003,
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsetsDirectional.only(
                              top: deviceHeight * 0.008,
                              bottom: deviceHeight * 0.005),
                          child: Text(
                            widget.productListItem.productName,
                            textAlign: TextAlign.start,
                            style: bodyText(
                                fontSize: textSizeRegular,
                                textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : colorBlack,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          widget.productListItem.description,
                          textAlign: TextAlign.start,
                          style: bodyText(
                              fontSize: textSizeSmall,
                              textColor: colorTextCommon,
                              fontWeight: FontWeight.normal),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: CustomRoundedButton(
                                context,
                                languages.iWillChoose.toUpperCase(),
                                () {
                                  Navigator.pop(context);
                                  _showToppings(context);
                                },
                                margin: EdgeInsetsDirectional.only(
                                    top: deviceHeight * 0.04,
                                    start: deviceWidth * 0.02,
                                    end: deviceWidth * 0.02),
                                minWidth: double.infinity,
                                minHeight: commonBtnHeight,
                                setBorder: true,
                                textColor: colorPrimary,
                                textSize: textSizeRegular,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: CustomRoundedButton(
                                context,
                                languages.repeat.toUpperCase(),
                                () {
                                  Navigator.pop(context);
                                  StoreProvider.of<AppState>(context).dispatch(
                                      RepeatLastItem(
                                          productId: widget
                                              .productListItem.productId));
                                },
                                padding: EdgeInsetsDirectional.zero,
                                margin: EdgeInsetsDirectional.only(
                                    top: deviceHeight * 0.04,
                                    start: deviceWidth * 0.02,
                                    end: deviceWidth * 0.02),
                                minHeight: commonBtnHeight,
                                textSize: textSizeRegular,
                                textColor: colorWhite,
                                fontWeight: FontWeight.normal,
                                setBorder: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      directAddProduct(context);
    }
  }

  directAddProduct(BuildContext context) {
    widget.storeDetailsPojo
        .setCartsSelectedStoreCateId(prefGetInt(prefSelectedServiceCateId));
    widget.storeDetailsPojo
        .setStoreCatName(prefGetString(prefSelectedServiceCateName));
    widget.storeDetailsPojo
        .setStoreCatIcon(prefGetString(prefSelectedServiceCateIcon));
    prefSetString(
        prefSelectedStoreFullResponse, jsonEncode(widget.storeDetailsPojo));
    return StoreProvider.of<AppState>(context).dispatch(AddItemInCart(
        cartItem: CartItem(
            prodId: widget.productListItem.productId,
            prodQuantity: 1,
            prodCustomizeSize: 0,
            prodTotalAmount:
                getDoubleFromDynamic(widget.productListItem.productAmount),
            prodCustomizeOption: "",
            prodCustomizeToppings: "",
            productName: widget.productListItem.productName)));
  }

  removeProduct(BuildContext context, int prodQuantity) {
    if (widget.productListItem.customizeList.isNotEmpty) {
      openScreen(context, const CheckOut());
    } else {
      StoreProvider.of<AppState>(context).dispatch(UpdateAndDeleteItemFromCart(
        isAdd: false,
        productId: widget.productListItem.productId,
        productCustomize: 0,
        productQuantity: prodQuantity,
        productOptions: "",
        productToppings: "",
      ));
    }
  }
}
