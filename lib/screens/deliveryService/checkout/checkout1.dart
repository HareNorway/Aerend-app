import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../commonView/common_view.dart';
import '../../../commonView/custom_text_field.dart';
import '../../../commonView/image_selection.dart';
import '../../../commonView/item_key_value.dart';
import '../../../commonView/no_record_found.dart';
import '../../../dialogs/applyPromoCodeDialog/apply_promocode_dialog.dart';
import '../../../networking/api_base_helper.dart';
import '../../../redux/store.dart';
import '../../../utils/utils.dart';
import '../../common/base_dl.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../storeDetail/store_detail_dl.dart';
import 'checkout.dart';
import 'checkout_bloc.dart';
import 'checkout_dl.dart';
import 'checkout_shimmer.dart';
import 'item_cart_product_list.dart';
import 'item_tip.dart';

class CheckOut1 extends StatefulWidget {
  const CheckOut1({super.key});

  @override
  State<StatefulWidget> createState() => _CheckOut1State();
}

class _CheckOut1State extends State<CheckOut1> {
  late CheckOutBloc _bloc;

  @override
  void didChangeDependencies() {
    _bloc = CheckOutBloc(context, this as State<CheckOut>);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: colorMainBackground,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            languages.checkOut,
            textAlign: TextAlign.start,
            style: toolbarStyle(),
          ),
        ),
        body: checkOutData(),
      );

  txtTip() {
    return StreamBuilder<double>(
      stream: _bloc.streamTip,
      builder: (context, snap) {
        return (snap.hasData && snap.data == 0)
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormFieldCustom(
                          controller: _bloc.tipController,
                          prefix: Text(
                            "${prefGetString(prefSelectedCurrency)} ",
                            textAlign: TextAlign.start,
                            style: bodyText(
                                fontSize: textSizeSmallest,
                                textColor: colorPrimary),
                          ),
                          style: bodyText(
                              fontSize: textSizeSmall, textColor: colorPrimary),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          hint: languages.enterTip,
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                              var hasMatch = getTwoDigitRegExp(newValue.text);
                              if (hasMatch || newValue.text.isEmpty) {
                                return newValue;
                              }
                              return oldValue;
                            }),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _bloc.tipController.text = "";
                          FocusManager.instance.primaryFocus!.unfocus();
                          _bloc.getOrderPreview();
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.clear,
                              size: deviceAverageSize * 0.032,
                            ),
                            Text(
                              languages.clear,
                              style: bodyText(fontSize: textSizeSmall),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.02,
                      ),
                      CustomRoundedButton(context, languages.apply, () {
                        _bloc.getOrderPreview();
                      },
                          elevation: 0,
                          padding: EdgeInsetsDirectional.only(
                            start: deviceWidth * 0.02,
                            end: deviceWidth * 0.02,
                            top: deviceHeight * 0.003,
                            bottom: deviceHeight * 0.003,
                          ),
                          textSize: textSizeSmall)
                    ],
                  ),
                  Divider(
                    color: colorMainView,
                    height: deviceHeight * 0.008,
                    thickness: deviceHeight * 0.001,
                  ),
                ],
              )
            : Container();
      },
    );
  }

  checkOutData() {
    StoreDetailsPojo storeDetailsPojo = StoreDetailsPojo.fromJson(
        jsonDecode(prefGetString(prefSelectedStoreFullResponse)));
    bool isFood = storeDetailsPojo.cartsSelectedStoreCateId == 5;
    bool isReenSportsFood = prefGetBool(prefReenSportsMode) && isFood;

    return StreamBuilder<ApiResponse<OrderPreviewPojo>>(
      stream: _bloc.subject as Stream<ApiResponse<OrderPreviewPojo>>,
      builder: (context, snap) {
        var isLoading = snap.hasData && snap.data?.status == Status.loading;
        var isError = snap.hasData && snap.data?.status == Status.error;
        OrderPreviewPojo? data = snap.data?.data;
        StoreDetailsPojo? storeDetailsPojo;
        if (prefGetString(prefSelectedStoreFullResponse).isNotEmpty) {
          storeDetailsPojo = StoreDetailsPojo.fromJson(
              jsonDecode(prefGetString(prefSelectedStoreFullResponse)));
        }

        Widget shimmerView = CheckOutShimmer(
          enabled: isLoading,
        );
        return isLoading
            ? shimmerView
            : (!isError && data != null && storeDetailsPojo != null)
                ? SingleChildScrollView(
                    padding:
                        EdgeInsetsDirectional.only(top: deviceHeight * 0.015),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: colorWhite,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.040,
                              vertical: deviceHeight * 0.01),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsetsDirectional.only(
                                    top: deviceHeight * 0.005),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LoadImageWithPlaceHolder(
                                      borderRadius: BorderRadius.circular(
                                          deviceAverageSize * 0.016),
                                      width: deviceAverageSize * 0.11,
                                      height: deviceAverageSize * 0.11,
                                      image: data.storeBanner,
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsetsDirectional.only(
                                            start: deviceWidth * 0.015),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data.storeName,
                                              textAlign: TextAlign.start,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: bodyText(
                                                  textColor: colorBlack,
                                                  fontSize: textSizeMediumBig,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              margin:
                                                  EdgeInsetsDirectional.only(
                                                      top:
                                                          deviceHeight * 0.002),
                                              child: Container(
                                                margin:
                                                    EdgeInsetsDirectional.only(
                                                        start: deviceWidth *
                                                            0.005),
                                                child: Text(
                                                  data.storeAddress ?? "--",
                                                  textAlign: TextAlign.start,
                                                  style: bodyText(
                                                      fontSize: textSizeSmall),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: deviceHeight * 0.015,
                              ),
                              Divider(
                                color: colorMainView,
                                thickness: deviceHeight * 0.0012,
                                height: 0,
                              ),
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                separatorBuilder: (context, index) => Divider(
                                  color: colorMainView,
                                  thickness: deviceHeight * 0.0012,
                                  height: 0,
                                ),
                                padding:
                                    const EdgeInsetsDirectional.only(top: 0),
                                itemCount: data.productList.length,
                                itemBuilder: (BuildContext context, position) {
                                  COProductListItem copli =
                                      data.productList[position];
                                  return data.productList.isNotEmpty
                                      ? ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  top: 0),
                                          itemCount:
                                              copli.productQuantityList.length,
                                          itemBuilder: (BuildContext context,
                                              pqPosition) {
                                            ProductQuantityListItem pqli =
                                                copli.productQuantityList[
                                                    pqPosition];
                                            return copli.productQuantityList
                                                    .isNotEmpty
                                                ? StreamBuilder<
                                                        ApiResponse<
                                                            OrderPreviewPojo>>(
                                                    stream: _bloc
                                                        .subjectCartItemLoading,
                                                    builder: (context,
                                                        snapCartLoading) {
                                                      return ItemCartProductList(
                                                        productName:
                                                            copli.productName,
                                                        productQuantityListItem:
                                                            pqli,
                                                        onTapPlush: () {
                                                          StoreProvider.of<
                                                                      AppState>(
                                                                  context)
                                                              .dispatch(
                                                                  UpdateAndDeleteItemFromCart(
                                                            isAdd: true,
                                                            productId:
                                                                copli.productId,
                                                            productCustomize:
                                                                pqli.productSize,
                                                            productQuantity: pqli
                                                                .productQuantity,
                                                            productOptions: pqli
                                                                .productOptions
                                                                .join(",")
                                                                .replaceAll(
                                                                    " ", ""),
                                                            productToppings: pqli
                                                                .productToppings
                                                                .join(",")
                                                                .replaceAll(
                                                                    " ", ""),
                                                          ));
                                                          pqli.isLoading = true;
                                                          _bloc.getOrderPreview();
                                                        },
                                                        onTapMinus: () {
                                                          StoreProvider.of<
                                                                      AppState>(
                                                                  context)
                                                              .dispatch(
                                                                  UpdateAndDeleteItemFromCart(
                                                            isAdd: false,
                                                            productId:
                                                                copli.productId,
                                                            productCustomize:
                                                                pqli.productSize,
                                                            productQuantity: pqli
                                                                .productQuantity,
                                                            productOptions: pqli
                                                                .productOptions
                                                                .join(",")
                                                                .replaceAll(
                                                                    " ", ""),
                                                            productToppings: pqli
                                                                .productToppings
                                                                .join(",")
                                                                .replaceAll(
                                                                    " ", ""),
                                                          ));
                                                          pqli.isLoading = true;
                                                          _bloc.getOrderPreview();
                                                        },
                                                      );
                                                    })
                                                : Container();
                                          },
                                        )
                                      : Container();
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: colorWhite,
                          padding: EdgeInsetsDirectional.only(
                              bottom: deviceHeight * 0.01),
                          child: Container(
                            color: colorGray,
                            padding: EdgeInsets.symmetric(
                                horizontal: deviceWidth * 0.040,
                                vertical: deviceHeight * 0.003),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: deviceHeight * 0.01),
                                  child: Icon(CustomIcons.notesToRestoStore,
                                      size: deviceAverageSize * 0.035,
                                      color: colorTextCommonLight),
                                ),
                                Expanded(
                                    child: TextFormFieldCustom(
                                  controller: _bloc.additionalInfo,
                                  hint:
                                      "${languages.additionNotes} ${isFood ? languages.restaurant : languages.store}?",
                                  textAlign: TextAlign.start,
                                  keyboardType: TextInputType.multiline,
                                  backgroundColor: Colors.transparent,
                                  maxLine: null,
                                ))
                              ],
                            ),
                          ),
                        ),
                        StreamBuilder<int>(
                            stream: _bloc.selectedTakeAway,
                            builder: (context, snapTakeAway) {
                              int selectedDeliveryType = snapTakeAway.data ?? 1;
                              bool isPickupType =
                                  selectedDeliveryType == pickup;
                              return !isPickupType
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: deviceHeight * 0.005,
                                        ),
                                        Container(
                                          width: deviceWidth,
                                          color: colorWhite,
                                          margin: EdgeInsets.symmetric(
                                              vertical: deviceHeight * 0.005),
                                          padding: EdgeInsetsDirectional.only(
                                              start: deviceWidth * 0.03,
                                              end: deviceWidth * 0.03,
                                              top: deviceHeight * 0.018,
                                              bottom: deviceHeight * 0.018),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                CustomIcons.tipToDriver,
                                                color: colorTextCommonLight,
                                                size: deviceAverageSize * 0.035,
                                              ),
                                              SizedBox(
                                                width: deviceWidth * 0.02,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      languages.addTipToDriver,
                                                      textAlign:
                                                          TextAlign.start,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: bodyText(
                                                          fontSize:
                                                              textSizeSmall,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    StreamBuilder<double>(
                                                        stream: _bloc.streamTip,
                                                        builder:
                                                            (context, snapTip) {
                                                          return snapTip.hasData
                                                              ? ItemTip(
                                                                  tipList: const [
                                                                    1,
                                                                    2,
                                                                    5,
                                                                    0
                                                                  ],
                                                                  defaultSelected:
                                                                      (snapTip.data ??
                                                                          0),
                                                                  onSelectionChanged:
                                                                      (tip) {
                                                                    _bloc
                                                                        .tipController
                                                                        .text = "";
                                                                    _bloc.changeTip(
                                                                        tip);
                                                                    _bloc.getOrderPreview();
                                                                  },
                                                                )
                                                              : Container();
                                                        }),
                                                    txtTip(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container();
                            }),
                        applyPromoCode(data.promocodeName),
                        Container(
                          color: colorWhite,
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(
                              vertical: deviceHeight * 0.005),
                          padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.040,
                              vertical: deviceHeight * 0.01),
                          child: StreamBuilder<List<KeyValueModel>>(
                            stream: _bloc.keyValueList,
                            builder: (context, keyValueSnap) {
                              List<KeyValueModel>? dataKeyValueList =
                                  keyValueSnap.data;
                              return ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsetsDirectional.only(top: 0),
                                itemCount: dataKeyValueList?.length ?? 0,
                                itemBuilder: (BuildContext context, position) {
                                  return ItemKeyValue(
                                    keyValueModel: dataKeyValueList?[position],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        if (data.userTakenStatus == 2)
                          Container(
                            color: colorWhite,
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: deviceWidth * 0.040,
                                vertical: deviceHeight * 0.01),
                            margin: EdgeInsets.symmetric(
                                vertical: deviceHeight * 0.01),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsetsDirectional.only(
                                      start: deviceWidth * 0.025),
                                  child: Text(
                                    languages.doYouWant,
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: bodyText(
                                        fontSize: textSizeBig,
                                        textColor: colorBlack,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsetsDirectional.only(
                                      start: deviceWidth * 0.005,
                                      top: deviceHeight * 0.008),
                                  child: StreamBuilder<int>(
                                    stream: _bloc.selectedTakeAway,
                                    builder: (context, snap) {
                                      int? selectedDeliveryType = snap.data;
                                      return Row(
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () {
                                              _bloc.changeSelectedTakeAway(
                                                  delivery);
                                            },
                                            child: Row(
                                              children: [
                                                Radio(
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    groupValue:
                                                        selectedDeliveryType,
                                                    value: delivery,
                                                    onChanged: (var index) => _bloc
                                                        .changeSelectedTakeAway(
                                                            index!)),
                                                Text(
                                                  languages.deliveryOrder,
                                                  textAlign: TextAlign.start,
                                                  style: bodyText(
                                                      textColor: colorBlack,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () {
                                              _bloc.changeSelectedTakeAway(
                                                  pickup);
                                            },
                                            child: Row(
                                              children: [
                                                Radio(
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    groupValue:
                                                        selectedDeliveryType,
                                                    value: pickup,
                                                    onChanged: (var index) => _bloc
                                                        .changeSelectedTakeAway(
                                                            index!)),
                                                Text(
                                                  languages.takeAwayOrder,
                                                  textAlign: TextAlign.start,
                                                  style: bodyText(
                                                      textColor: colorBlack,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isReenSportsFood)
                          StreamBuilder<int>(
                              stream: _bloc.selectedTakeAway,
                              builder: (context, snapTakeAway) {
                                final isPickupType =
                                    (snapTakeAway.data ?? delivery) == pickup;
                                final activeClubName =
                                    prefGetString(prefActiveSportsClubName);
                                final instruction = isPickupType
                                    ? "Pickup from ${activeClubName.isNotEmpty ? activeClubName : 'the active sports club'} at the announced collection point and time."
                                    : "Delivery timing follows ${activeClubName.isNotEmpty ? activeClubName : 'the active sports club'} schedule for today.";
                                return Container(
                                  color: colorWhite,
                                  width: double.infinity,
                                  margin: EdgeInsets.symmetric(
                                      vertical: deviceHeight * 0.005),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: deviceWidth * 0.040,
                                      vertical: deviceHeight * 0.012),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: colorPrimary,
                                          size: deviceAverageSize * 0.03),
                                      SizedBox(width: deviceWidth * 0.02),
                                      Expanded(
                                        child: Text(
                                          instruction,
                                          style: bodyText(
                                              fontSize: textSizeSmall,
                                              textColor: colorTextCommon),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                        StreamBuilder<int>(
                            stream: _bloc.selectedTakeAway,
                            builder: (context, snap) {
                              bool selectedDeliveryType = (snap.data) == pickup;

                              return selectedDeliveryType
                                  ? const SizedBox(
                                      height: 0,
                                      width: 0,
                                    )
                                  : Container(
                                      color: colorWhite,
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: deviceWidth * 0.040,
                                          vertical: deviceHeight * 0.01),
                                      margin: EdgeInsets.symmetric(
                                          vertical: deviceHeight * 0.005),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  languages.deliveryAddress,
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: bodyText(
                                                      fontSize: textSizeBig,
                                                      textColor: colorBlack),
                                                ),
                                              ),
                                              StreamBuilder<AddressListItem?>(
                                                  stream: _bloc.selectedAddress,
                                                  builder:
                                                      (context, addressSnap) {
                                                    AddressListItem?
                                                        addressListItem =
                                                        addressSnap.data;
                                                    return addressListItem
                                                                ?.address !=
                                                            null
                                                        ? Expanded(
                                                            flex: 0,
                                                            child:
                                                                CustomRoundedButton(
                                                              context,
                                                              languages.change,
                                                              () {
                                                                _bloc
                                                                    .openSelectAddressScreen();
                                                              },
                                                              margin:
                                                                  EdgeInsetsDirectional
                                                                      .zero,
                                                              elevation: 0,
                                                              padding: EdgeInsetsDirectional.only(
                                                                  start:
                                                                      deviceWidth *
                                                                          0.02,
                                                                  end:
                                                                      deviceWidth *
                                                                          0.02,
                                                                  top:
                                                                      deviceHeight *
                                                                          0.004,
                                                                  bottom:
                                                                      deviceHeight *
                                                                          0.006),
                                                              materialTapTargetSize:
                                                                  MaterialTapTargetSize
                                                                      .shrinkWrap,
                                                              setBorder: true,
                                                            ),
                                                          )
                                                        : Container();
                                                  }),
                                            ],
                                          ),
                                          StreamBuilder<AddressListItem?>(
                                              stream: _bloc.selectedAddress,
                                              builder: (context, addressSnap) {
                                                AddressListItem?
                                                    addressListItem =
                                                    addressSnap.data;
                                                return addressListItem == null
                                                    ? Align(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .center,
                                                        child: CustomFillButton(
                                                          onPressed: () {
                                                            _bloc
                                                                .openSelectAddressScreen();
                                                          },
                                                          width: deviceWidth *
                                                              commonBtnWidthSmall,
                                                          height: commonBtnHeightSmall,
                                                          margin: EdgeInsetsDirectional
                                                              .only(
                                                                  top: deviceHeight *
                                                                      0.015),
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .zero,
                                                          borderRadius: BorderRadiusDirectional.only(
                                                              topStart:
                                                                  topLeftRadius,
                                                              topEnd:
                                                                  topRightRadius,
                                                              bottomStart:
                                                                  bottomLeftRadius,
                                                              bottomEnd:
                                                                  bottomRightRadius),
                                                          color: colorPrimary,
                                                          elevation: 0,
                                                          child: Text(
                                                            languages
                                                                .addAddress,
                                                            maxLines: 1,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: bodyText(
                                                                fontSize:
                                                                    textSizeRegular,
                                                                textColor:
                                                                    colorWhite,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        margin: EdgeInsetsDirectional
                                                            .only(
                                                                top:
                                                                    deviceHeight *
                                                                        0.008),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              getAddressTypeInString(
                                                                  context,
                                                                  addressListItem
                                                                      .type),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: bodyText(
                                                                  fontSize:
                                                                      textSizeRegular,
                                                                  textColor:
                                                                      colorBlack,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                            Text(
                                                              addressListItem
                                                                  .address,
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              style: bodyText(
                                                                  fontSize:
                                                                      textSizeSmall,
                                                                  textColor:
                                                                      colorTextCommon,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                              }),
                                        ],
                                      ),
                                    );
                            }),
                        if (data.requiredPrescription == 1)
                          Container(
                            color: colorWhite,
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: deviceWidth * 0.040,
                                vertical: deviceHeight * 0.01),
                            margin: EdgeInsets.symmetric(
                                vertical: deviceHeight * 0.005),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languages.prescription,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bodyText(
                                      fontSize: textSizeBig,
                                      textColor: colorBlack,
                                      fontWeight: FontWeight.normal),
                                ),
                                Container(
                                  margin: EdgeInsetsDirectional.only(
                                      top: deviceHeight * 0.008),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            deviceAverageSize * 0.008),
                                        child: StreamBuilder<File>(
                                            stream: _bloc.prescriptionImg,
                                            builder:
                                                (context, snapPrescriptionImg) {
                                              return snapPrescriptionImg.hasData
                                                  ? Image.file(
                                                      snapPrescriptionImg.data!,
                                                      width: deviceAverageSize *
                                                          0.1,
                                                      height:
                                                          deviceAverageSize *
                                                              0.1,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      width: deviceAverageSize *
                                                          0.1,
                                                      height:
                                                          deviceAverageSize *
                                                              0.1,
                                                      color: colorDivider,
                                                    );
                                            }),
                                      ),
                                      CustomRoundedButton(
                                        context,
                                        languages.add,
                                        () {
                                          selectImgFromCameraOrGallery(context,
                                              (file) async {
                                            _bloc.changePrescriptionImg(file);
                                          });
                                        },
                                        setBorder: true,
                                        margin: EdgeInsetsDirectional.zero,
                                        padding: EdgeInsetsDirectional.only(
                                            start: deviceWidth * 0.035,
                                            end: deviceWidth * 0.035,
                                            top: deviceHeight * 0.004,
                                            bottom: deviceHeight * 0.006),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: StreamBuilder<ApiResponse<PlaceOrderPojo>>(
                                stream: _bloc.subjectPlaceScheduleOrder,
                                builder: (context, snapLoading) {
                                  var isLoading = snapLoading.hasData &&
                                      snapLoading.data?.status ==
                                          Status.loading;
                                  return CustomRoundedButton(
                                    context,
                                    languages.scheduleOrder,
                                    () {
                                      _bloc.getOrderPreview();
                                    },
                                    minWidth: 0.2,
                                    setBorder: true,
                                    minHeight: commonBtnHeightMedium,
                                    setProgress: isLoading,
                                    margin: EdgeInsetsDirectional.only(
                                        start: deviceWidth * 0.025,
                                        end: deviceWidth * 0.015,
                                        top: deviceHeight * 0.025,
                                        bottom: deviceHeight * 0.015),
                                    padding: EdgeInsetsDirectional.zero,
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: StreamBuilder<ApiResponse<PlaceOrderPojo>>(
                                stream: _bloc.subjectPlaceOrder,
                                builder: (context, snapLoading) {
                                  var isLoading = snapLoading.hasData &&
                                      snapLoading.data?.status ==
                                          Status.loading;
                                  return CustomRoundedButton(
                                    context,
                                    languages.orderNow,
                                    () {
                                      _bloc.getOrderPreview();
                                    },
                                    minWidth: 0.2,
                                    setProgress: isLoading,
                                    minHeight: commonBtnHeightMedium,
                                    margin: EdgeInsetsDirectional.only(
                                        start: deviceWidth * 0.015,
                                        end: deviceWidth * 0.025,
                                        top: deviceHeight * 0.025,
                                        bottom: deviceHeight * 0.015),
                                    padding: EdgeInsetsDirectional.zero,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Align(
                    alignment: AlignmentDirectional.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NoRecordFound(
                          message: snap.data?.message ?? "",
                        ),
                        if (_bloc.showAddAddressBtn)
                          CustomRoundedButton(context, languages.changeAddress,
                              () {
                            _bloc.openSelectAddressScreen();
                          },
                              fontWeight: FontWeight.w600,
                              textSize: textSizeLarge,
                              minWidth: commonBtnWidth,
                              setBorder: true,
                              textColor: colorPrimary,
                              bgColor: colorPrimary,
                              minHeight: commonBtnHeightMedium,
                              margin: EdgeInsetsDirectional.only(
                                  start: deviceWidth * 0.035,
                                  end: deviceWidth * 0.035,
                                  bottom: deviceHeight * 0.03,
                                  top: deviceHeight * 0.03)),
                      ],
                    ),
                  );
      },
    );
  }

  applyPromoCode(String promoCodeName) =>
      StreamBuilder<List<PromoCodeListItem>>(
          stream: _bloc.promoCodeList,
          builder: (context, snapPromoCodeList) {
            bool isPromoApply = promoCodeName.trim().isNotEmpty;
            return GestureDetector(
              onTap: isPromoApply
                  ? null
                  : () {
                      // `PromoCodeSheet` — a bottom sheet in the design.
                      showAeSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return ApplyPromoCodeDialog(
                              promoCodeList: snapPromoCodeList.data as dynamic,
                              onPromoCodeApply: (promoCode) {
                                _bloc.changeSelectedPromoCodeId(promoCode);
                              },
                            );
                          });
                    },
              child: Container(
                color: colorWhite,
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    horizontal: deviceWidth * 0.040,
                    vertical: deviceHeight * 0.02),
                margin: EdgeInsets.symmetric(vertical: deviceHeight * 0.005),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/discount.png",
                      height: deviceAverageSize * 0.036,
                      width: deviceAverageSize * 0.036,
                      color: colorOfferDiscountRed,
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsetsDirectional.only(
                            start: deviceWidth * 0.015),
                        child: Text(
                          isPromoApply
                              ? promoCodeName.trim()
                              : languages.applyPromoCode,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyText(),
                        ),
                      ),
                    ),
                    StreamBuilder<ApiResponse>(
                        stream: _bloc.subjectApplyPromoCode,
                        builder: (context, snapshot) {
                          bool isLoading =
                              (snapshot.data?.status ?? Status.completed) ==
                                  Status.loading;
                          // isLoading = true;
                          return GestureDetector(
                            onTap: !isPromoApply
                                ? null
                                : () {
                                    _bloc.changeSelectedPromoCodeId("");
                                  },
                            child: isLoading
                                ? CommonCircularProgressIndicator(
                                    color: colorPrimary,
                                    size: deviceAverageSize * 0.035,
                                    strokeWidth: 2,
                                  )
                                : Icon(
                                    !isPromoApply
                                        ? Icons.arrow_forward_ios_rounded
                                        : Icons.cancel_rounded,
                                    color: !isPromoApply
                                        ? colorTextCommon
                                        : colorRed,
                                    size: deviceAverageSize * 0.035,
                                  ),
                          );
                        }),
                  ],
                ),
              ),
            );
          });
}
