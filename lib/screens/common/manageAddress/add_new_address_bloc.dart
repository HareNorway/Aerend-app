import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../../rideService/rideAddLocation/ride_add_location.dart';
import '../base_dl.dart';
import 'add_new_address.dart';
import 'add_new_address_repo.dart';
import 'manage_address_dl.dart';

class AddNewAddressBloc extends Bloc {
  String tag = "AddNewAddressB>>>";

  BuildContext context;
  final AddNewAddressRepo _addNewAddressRepo = AddNewAddressRepo();
  AddressListItem? addressListItem;
  LatLng? latLng;
  var houseNumberController = TextEditingController();
  var locationController = TextEditingController();
  var landmarkController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  State<AddNewAddress> state;

  AddNewAddressBloc(this.context, this.addressListItem, this.state);

  final BehaviorSubject<int> _addressTypeController =
      BehaviorSubject<int>.seeded(0);
  final _subject = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<BaseModel>> get subject => _subject;

  Stream<int> get addressType => _addressTypeController.stream;

  Function(int) get changeAddressType => _addressTypeController.sink.add;

  gotoSelectLocation(BuildContext context) {
    openScreenWithResult(context, const RideAddLocation()).then((value) {
      if (value != null && value["lat_long"] != null) {
        // LatLng latLng = value["lat_long"];
        // String address = value["address"] ?? "";

        if (value["address"] != null) {
          locationController.text = value["address"];
        }
        if (value["lat_long"] != null) {
          latLng = value["lat_long"];
        }
      }
    });
  }

  submit() {
    FocusManager.instance.primaryFocus!.unfocus();
    if (locationController.text.trim().isEmpty) {
      openSimpleSnackbar(languages.selectLocationMsg);
    } else if (landmarkController.text.trim().isEmpty) {
      openSimpleSnackbar(languages.enterLandmark);
    } else {
      if (addressListItem != null) {
        editAddress();
      } else {
        addAddress();
      }
    }
  }

  editAddress() async {
    latLng ??= LatLng(double.parse(addressListItem?.lat ?? "0"),
        double.parse(addressListItem?.long ?? "0"));
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        final flatNo = houseNumberController.text.trim().isEmpty
          ? 'N/A'
          : houseNumberController.text.trim();
        var response = BaseModel.fromJson(
          await _addNewAddressRepo.callEditAddressApi(
            addressListItem?.addressId ?? 0,
            locationController.text.trim(),
            getAddressTypeIntToString(_addressTypeController.value),
            latLng!,
            flatNo,
            landmarkController.text.trim()));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _subject.sink.add(ApiResponse.completed(response));
          if (prefGetString(prefNewDeliveryAddress).trim().isNotEmpty) {
            AddressListItem prefAddressListItem = AddressListItem.fromJson(
                jsonDecode(prefGetString(prefNewDeliveryAddress)));
            if (prefAddressListItem.addressId == addressListItem?.addressId) {
              prefAddressListItem.setAddress(locationController.text.trim());
              prefAddressListItem.setFlatNo(flatNo);
              prefAddressListItem.setLandmark(landmarkController.text.trim());
              prefAddressListItem.setLat((latLng?.latitude ?? 0).toString());
              prefAddressListItem.setLong((latLng?.longitude ?? 0).toString());
              prefAddressListItem.setType(
                  getAddressTypeIntToString(_addressTypeController.value));
              prefSetString(
                  prefNewDeliveryAddress, jsonEncode(prefAddressListItem.toJson()));
            }
          }
          Navigator.pop(context, true);
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  addAddress() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        final flatNo = houseNumberController.text.trim().isEmpty
          ? 'N/A'
          : houseNumberController.text.trim();
        var response = BaseModel.fromJson(
          await _addNewAddressRepo.callAddAddressApi(
            locationController.text.trim(),
            getAddressTypeIntToString(_addressTypeController.value),
            latLng!,
            flatNo,
            landmarkController.text.trim()));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subject.sink.add(ApiResponse.completed(response));
          Navigator.pop(context, true);
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _addressTypeController.close();
    locationController.dispose();
    houseNumberController.dispose();
    landmarkController.dispose();
    _subject.close();
  }
}
