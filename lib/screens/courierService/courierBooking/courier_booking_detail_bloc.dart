import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../../rideService/rideBook/ride_book.dart';
import '../../rideService/searched_location_dl.dart';
import 'courier_booking_detail_dl.dart';

class CourierBookingDetailBloc extends Bloc {
  String tag = "CourierBookingBloc>>>";
  BuildContext context;

  late Validator validator;

  CourierBookingDetailData? courierBookingDetailData;

  SearchedLocation? pickupLatLng;
  SearchedLocation? recipientLatLng;

  TextEditingController whatIsParcel = TextEditingController();
  TextEditingController dimensionsWidth = TextEditingController();
  TextEditingController dimensionsHeight = TextEditingController();
  TextEditingController dimensionsLength = TextEditingController();
  TextEditingController dimensionsWeight = TextEditingController();
  TextEditingController estimatedPrice = TextEditingController();

  TextEditingController pickupAddress = TextEditingController();
  TextEditingController pickupBuildingName = TextEditingController();
  TextEditingController pickupLandmark = TextEditingController();
  TextEditingController pickupSenderName = TextEditingController();
  TextEditingController pickupSenderContact = TextEditingController();

  TextEditingController recipientAddress = TextEditingController();
  TextEditingController recipientBuildingName = TextEditingController();
  TextEditingController recipientLandmark = TextEditingController();
  TextEditingController recipientName = TextEditingController();
  TextEditingController recipientContact = TextEditingController();
  TextEditingController remark = TextEditingController();

  CourierBookingDetailBloc(this.context) {
    addMoreItem();
    validator = Validator(context);
    pickupSenderName.text = prefGetString(prefUserName);
    pickupSenderContact.text = prefGetString(prefContactNumber);
    /*whatIsParcel.text = "aaa";
    dimensionsLength.text = "2";
    dimensionsWidth.text = "2";
    dimensionsHeight.text = "2";
    goodsWeight.text = "2";
    // pickupAddress.text="";
    pickupBuildingName.text = "namm";
    pickupLandmark.text = "lam";
    // pickupSenderName.text="s";
    // pickupSenderContact.text="123456";
    // recipientAddress.text="";
    recipientBuildingName.text = "bnnnn";
    recipientLandmark.text = "lmmm";
    recipientName.text = "rnm";
    recipientContact.text = "123456";
    remark.text = "rrr";*/
  }

  final BehaviorSubject<List<ItemToPurchase>> itemToPurchaseSubject = BehaviorSubject<List<ItemToPurchase>>();

  final parcelTypeController = BehaviorSubject<ParcelType>.seeded(ParcelType.transport);

  getCurrentLocation() async {
    getLocationUtils.getLocationUtils((locationData) {}, (locationData, address) {}, getForceFully: true);
  }

  addMoreItem() {
    List<ItemToPurchase> itemList = itemToPurchaseSubject.valueOrNull ?? [];
    if(itemList.length < maxItems){
      itemList.add(ItemToPurchase());
      itemToPurchaseSubject.add(itemList);
    }else{
      openSimpleSnackbar( languages.canNotAdd);
    }

  }

  removeMoreItem(ItemToPurchase itemToPurchase) {
    List<ItemToPurchase> itemList = itemToPurchaseSubject.valueOrNull ?? [];
    itemList.remove(itemToPurchase);
    itemToPurchaseSubject.add(itemList);
  }

  proceed() async {
    List<SearchedLocation> allLocationList = [];
    allLocationList.add(pickupLatLng!);
    allLocationList.add(recipientLatLng!);

    var addressList = allLocationList.map((v) => jsonEncode(v.toJson())).toList();
    var itemList = itemToPurchaseSubject.valueOrNull?.map((v) => jsonEncode(v.toJson())).toList();

    // var list = allLocationList.map((v) => jsonEncode(v.toJson())).toList();
    // jsonDecode(allLocationList.map((v) => v.toJson()).toList(),List<SearchedLocation>);

    Map<String, dynamic> data = {
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      ApiParam.paramServiceCatId: prefGetInt(prefSelectedServiceCateId),
      ApiParam.paramGoodName: whatIsParcel.text,
      ApiParam.paramPurchaseItems: "$itemList",
      ApiParam.paramEstimatePrice: estimatedPrice.text,
      ApiParam.paramAddressList: "$addressList",
      /*ApiParam.PARAM_GOODS_HEIGHT:  parcelTypeController.valueOrNull == ParcelType.transport ? dimensionsHeight.text : "0",
      ApiParam.PARAM_GOODS_WIDTH:  parcelTypeController.valueOrNull == ParcelType.transport ? dimensionsWidth.text : "0",
      ApiParam.PARAM_GOODS_LENGTH:  parcelTypeController.valueOrNull == ParcelType.transport ? dimensionsLength.text : "0",
      ApiParam.PARAM_GOODS_WEIGHT: parcelTypeController.valueOrNull == ParcelType.transport ? dimensionsWeight.text : "0",*/
      ApiParam.paramShopName: pickupBuildingName.text,
      ApiParam.paramShopLandmark: pickupLandmark.text,
      ApiParam.paramSenderName: pickupSenderName.text,
      ApiParam.paramSenderContactNumber: pickupSenderContact.text,
      ApiParam.paramRecipientName: recipientName.text,
      ApiParam.paramRHouseName: recipientBuildingName.text,
      ApiParam.paramRecipientLandmark: recipientLandmark.text,
      ApiParam.paramRecipientContactNo: recipientContact.text,
      ApiParam.paramDeliveryInstruction: remark.text,
      ApiParam.paramCourierType:  parcelTypeController.valueOrNull == ParcelType.purchase ? 2 : 1,
    };
    openScreen(context, RideBook(locationList: allLocationList, courierData: data));
  }

  @override
  void dispose() {
    itemToPurchaseSubject.close();
    parcelTypeController.close();
  }
}

class ItemToPurchase {
  TextEditingController itemName = TextEditingController();
  TextEditingController itemQty = TextEditingController();

  dynamic toJson() {
    return {
      "item_name": itemName.text,
      "item_value": itemQty.text,
    };
  }
}
