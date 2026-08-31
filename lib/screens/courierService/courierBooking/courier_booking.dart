import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../commonView/custom_text_field.dart';
import '../../../utils/utils.dart';
import '../../rideService/rideAddLocation/ride_add_location.dart';
import '../../rideService/searched_location_dl.dart';
import 'courier_booking_detail_bloc.dart';
import 'courier_booking_detail_dl.dart';

class CourierBooking extends StatefulWidget {
  const CourierBooking({super.key});

  @override
  CourierBookingState createState() => CourierBookingState();
}

class CourierBookingState extends State<CourierBooking> {
  CourierBookingDetailBloc? _bloc;
  final _formKey = GlobalKey<FormState>();

  double formSpacingVertical = deviceHeight * 0.025;

  InputBorder commonBorder = const UnderlineInputBorder(
    borderSide: BorderSide(color: colorDivider),
  );

  @override
  void didChangeDependencies() {
    _bloc = _bloc ?? CourierBookingDetailBloc(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(languages.courierDetail, style: toolbarStyle()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.01),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(
                    horizontal: deviceWidth * 0.025,
                    vertical: deviceHeight * 0.01),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _courierDetailBuild(context),
                    ],
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(
                    horizontal: deviceWidth * 0.025,
                    vertical: deviceHeight * 0.01),
                elevation: 3,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(deviceAverageSize * 0.015),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages.pickUpInformation,
                        style: bodyText(fontWeight: FontWeight.w600).copyWith(
                            fontSize: textSizeMediumBig),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.pickupAddress,
                          suffix: Icon(
                            Icons.search,
                            size: deviceAverageSize * 0.04,
                          ),
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.pickUpLocation),
                          style: bodyText(),
                          readOnly: true,
                          setError: true,
                          onTap: () {
                            openScreenWithResult(
                                    context, const RideAddLocation())
                                .then((value) {
                              if (value != null && value["lat_long"] != null) {
                                LatLng latLng = value["lat_long"];
                                String address = value["address"];
                                _bloc!.pickupLatLng = SearchedLocation(
                                    name: address,
                                    lat: latLng.latitude,
                                    lng: latLng.longitude);
                                _bloc!.pickupAddress.text = value["address"];
                                // changeLocation(value["address"]);
                              }
                            });
                          },
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterPickUpLocation;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.pickupBuildingName,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.shopBuildingName),
                          style: bodyText(),
                          setError: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterShopBuildingName;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.pickupLandmark,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.houseNameLandmark),
                          style: bodyText(),
                          setError: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterHouseOrLandmarkName;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.pickupSenderName,
                          useLabelWithBorder: true,
                          decoration:
                              InputDecoration(labelText: languages.senderName),
                          style: bodyText(),
                          setError: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterSenderName;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical,
                            bottom: deviceHeight * 0.015),
                        child: TextFormFieldCustom(
                          controller: _bloc!.pickupSenderContact,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.senderContactNum),
                          style: bodyText(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          setError: true,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterSenderContactNum;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(
                    horizontal: deviceWidth * 0.025,
                    vertical: deviceHeight * 0.01),
                elevation: 3,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(deviceAverageSize * 0.015),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages.receiverInformation,
                        style: bodyText(fontWeight: FontWeight.w600).copyWith(
                            fontSize: textSizeMediumBig),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.recipientAddress,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.dropLocation),
                          readOnly: true,
                          suffix: Icon(
                            Icons.search,
                            size: deviceAverageSize * 0.04,
                          ),
                          onTap: () {
                            openScreenWithResult(
                                    context, const RideAddLocation())
                                .then((value) {
                              if (value != null && value["lat_long"] != null) {
                                if (value["address"] != null) {
                                  LatLng latLng = value["lat_long"];
                                  String address = value["address"];
                                  _bloc!.recipientLatLng = SearchedLocation(
                                      name: address,
                                      lat: latLng.latitude,
                                      lng: latLng.longitude);
                                  _bloc!.recipientAddress.text =
                                      value["address"];
                                  // changeLocation(value["address"]);
                                }
                              }
                            });
                          },
                          style: bodyText(),
                          setError: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterDropLocation;
                            }
                            return "";
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.recipientBuildingName,
                          useLabelWithBorder: true,
                          decoration:
                              InputDecoration(labelText: languages.houseName),
                          style: bodyText(),
                          setError: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterHouseName;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.recipientLandmark,
                          useLabelWithBorder: true,
                          decoration:
                              InputDecoration(labelText: languages.landmark),
                          style: bodyText(),
                          setError: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterLandmark;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical),
                        child: TextFormFieldCustom(
                          controller: _bloc!.recipientName,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.receiverName),
                          style: bodyText(),
                          setError: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterReceiverName;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical,
                            bottom: deviceHeight * 0.015),
                        child: TextFormFieldCustom(
                          controller: _bloc!.recipientContact,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.receiverContactNum),
                          style: bodyText(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          setError: true,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value.isEmpty) {
                              return languages.enterReceiverContactNum;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(
                    horizontal: deviceWidth * 0.025,
                    vertical: deviceHeight * 0.01),
                elevation: 3,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(deviceAverageSize * 0.015),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages.remarks,
                        style: bodyText(fontWeight: FontWeight.w600).copyWith(
                            fontSize: textSizeMediumBig),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: formSpacingVertical,
                            bottom: deviceHeight * 0.015),
                        child: TextFormFieldCustom(
                          controller: _bloc!.remark,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.additionalRemark),
                          onTap: () {},
                          style: bodyText(),
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomFillButton(
                margin: EdgeInsetsDirectional.all(deviceWidth * 0.025),
                color: colorPrimary,
                width: deviceWidth * 0.26,
                height: deviceHeight * 0.045,
                padding: EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                borderRadius: BorderRadiusDirectional.only(
                    topStart: topLeftRadius,
                    topEnd: topRightRadius,
                    bottomStart: bottomLeftRadius,
                    bottomEnd: bottomRightRadius),
                onPressed: () {
                  // openSimpleSnackbar( '${_formKey.currentState!.validate()}');
                  if (_formKey.currentState!.validate()) {
                    _bloc!.proceed();
                  }
                },
                child: Text(
                  languages.proceed,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: bodyText().copyWith(color: colorWhite),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _courierDetailBuild(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
              top: deviceHeight * 0.01, start: deviceWidth * 0.035),
          child: Text(languages.iWant, style: bodyText()),
        ),
        StreamBuilder<ParcelType>(
          stream: _bloc!.parcelTypeController,
          builder: (context, snapshotType) {
            ParcelType? parcelType = snapshotType.data;
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    _bloc?.parcelTypeController.add(ParcelType.transport);
                  },
                  child: Row(
                    children: [
                      Radio(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        groupValue: parcelType,
                        value: ParcelType.transport,
                        onChanged: (value) {
                          _bloc?.parcelTypeController.add(value as ParcelType);
                        },
                      ),
                      Text(
                        languages.transportMyItem,
                        style: bodyText(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _bloc?.parcelTypeController.add(ParcelType.purchase);
                  },
                  child: Row(
                    children: [
                      Radio(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        groupValue: parcelType,
                        value: ParcelType.purchase,
                        onChanged: (value) {
                          _bloc?.parcelTypeController.add(value as ParcelType);
                        },
                      ),
                      Text(
                        languages.purchaseDeliver,
                        style: bodyText(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                (parcelType == ParcelType.purchase)
                    ? Container(
                        padding: EdgeInsetsDirectional.only(
                          start: deviceAverageSize * 0.015,
                          top: deviceAverageSize * 0.015,
                          end: deviceAverageSize * 0.015,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languages.itemToPurchase,
                              style: bodyText(fontWeight: FontWeight.w600)
                                  .copyWith(
                                      fontSize: textSizeMediumBig),
                            ),
                            StreamBuilder<List<ItemToPurchase>>(
                                stream: _bloc!.itemToPurchaseSubject,
                                builder: (context, snapshot) {
                                  List<ItemToPurchase> itemToPurchase =
                                      snapshot.data ?? [];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListView.builder(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        key: Key(
                                            itemToPurchase.length.toString()),
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          ItemToPurchase item =
                                              itemToPurchase[index];
                                          return Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .only(
                                                          end: deviceWidth *
                                                              0.05,
                                                          top:
                                                              formSpacingVertical),
                                                  child: TextFormFieldCustom(
                                                    controller: item.itemName,
                                                    setError: true,
                                                    useLabelWithBorder: true,
                                                    decoration: InputDecoration(
                                                        labelText:
                                                            languages.itemName),
                                                    validator: (value) {
                                                      if (value.isEmpty) {
                                                        return languages
                                                            .enterItemName;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .only(
                                                          top:
                                                              formSpacingVertical),
                                                  child: TextFormFieldCustom(
                                                    controller: item.itemQty,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    setError: true,
                                                    useLabelWithBorder: true,
                                                    decoration: InputDecoration(
                                                        labelText:
                                                            languages.qty),
                                                    validator: (value) {
                                                      if (value.isEmpty) {
                                                        return languages
                                                            .enterQty;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ),
                                              if (itemToPurchase.length > 1)
                                                InkWell(
                                                  onTap: () {
                                                    _bloc!.removeMoreItem(item);
                                                  },
                                                  child: Icon(
                                                    Icons.close,
                                                    size: deviceAverageSize *
                                                        0.03,
                                                  ),
                                                )
                                            ],
                                          );
                                        },
                                        itemCount: itemToPurchase.length,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          _bloc!.addMoreItem();
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: deviceHeight * 0.02),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add,
                                                size: deviceAverageSize * 0.03,
                                                color: colorPrimary,
                                              ),
                                              Text(
                                                languages.addMoreItem,
                                                style: bodyText(
                                                        fontWeight:
                                                            FontWeight.w600)
                                                    .copyWith(
                                                        color: colorPrimary),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                            Text(
                              languages.estimatedPriceOfItem,
                              style: bodyText(fontWeight: FontWeight.w600)
                                  .copyWith(
                                      fontSize: textSizeMediumBig),
                            ),
                            Text(
                              languages.estimatedPriceMsg,
                              style: bodyText().copyWith(
                                  fontSize: textSizeSmall),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                  top: formSpacingVertical,
                                  bottom: formSpacingVertical),
                              child: TextFormFieldCustom(
                                controller: _bloc!.estimatedPrice,
                                prefix: Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: deviceWidth * 0.005),
                                    child: Text(
                                      prefGetString(prefSelectedCurrency),
                                      style: bodyText(),
                                    )),
                                useLabelWithBorder: true,
                                decoration: InputDecoration(
                                    labelText: languages.estimatedPriceOfItem),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: false),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(
                                      '^[1-9][0-9]{0,}(\\.[0-9]{0,})?\$')),
                                ],
                                setError: true,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return languages.pleaseEnterAmount;
                                  }
                                  return null;
                                },
                              ),
                            )
                          ],
                        ),
                      )
                    : Container(
                        padding: EdgeInsetsDirectional.only(
                          start: deviceAverageSize * 0.015,
                          top: deviceAverageSize * 0.015,
                          end: deviceAverageSize * 0.015,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsetsDirectional.only(
                                  top: formSpacingVertical,
                                  bottom: formSpacingVertical),
                              child: TextFormFieldCustom(
                                controller: _bloc!.whatIsParcel,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return languages.enterItemName;
                                  }
                                  return null;
                                },
                                useLabelWithBorder: true,
                                setError: true,
                                decoration: InputDecoration(
                                    labelText: languages.whatIsParcelGoods),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            );
          },
        ),
      ],
    );
  }
}
