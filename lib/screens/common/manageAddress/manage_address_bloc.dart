import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import 'add_new_address.dart';
import 'manage_address.dart';
import 'manage_address_dl.dart';
import 'manage_address_repo.dart';

class ManageAddressBloc extends Bloc {
  String tag = "ManageAddBloc>>>";
  BuildContext context;
  final ManageAddressRepo _manageAddressRepo = ManageAddressRepo();
  bool setResult = false;
  int maxAddressLimit = 0;
  int addressListLength = 0;

  State<ManageAddress> state;
  int _requestGen = 0;

  ManageAddressBloc(this.context, this.state);

  final _subject = BehaviorSubject<ApiResponse<AddressListPojo>>();
  final _subjectDeleteAddress = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<AddressListPojo>> get subject => _subject;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectDeleteAddress =>
      _subjectDeleteAddress;

  /// Keep prefs in sync with the server list so profile/checkout never show
  /// stale address text after an edit elsewhere.
  void _syncSelectedAddressPref(List<AddressListItem> list) {
    if (list.isEmpty) {
      prefSetString(prefNewDeliveryAddress, "");
      return;
    }

    final savedId = prefGetInt(prefNewDeliveryAddressId);
    AddressListItem selected;
    try {
      selected = list.firstWhere((a) => a.addressId == savedId);
    } catch (_) {
      selected = list.first;
    }

    prefSetInt(prefNewDeliveryAddressId, selected.addressId);
    final lat = double.tryParse(selected.lat);
    final long = double.tryParse(selected.long);
    if (lat != null &&
        long != null &&
        lat.abs() > 1e-7 &&
        long.abs() > 1e-7) {
      prefSetLatLng(LatLng(lat, long));
    }
    prefSetString(
      prefNewDeliveryAddress,
      jsonEncode(selected.toJson()),
    );
  }

  getAddressList() async {
    final gen = ++_requestGen;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (gen != _requestGen) return;
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = AddressListPojo.fromJson(
          await _manageAddressRepo.callAddressListApi(),
        );

        if (gen != _requestGen || !state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _syncSelectedAddressPref(response.addressList);
          _subject.sink.add(ApiResponse.completed(response));
          maxAddressLimit = response.maxAddressLimit;
          addressListLength = response.addressList.length;
          if (response.addressList.isEmpty) {
            prefSetString(prefNewDeliveryAddress, "");
          }
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (gen != _requestGen || !state.mounted) return;
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (gen != _requestGen) return;
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  openAddNewAddress({AddressListItem? addressListItem}) {
    if (addressListItem == null) {
      if (addressListLength < maxAddressLimit) {
        openScreenWithResult(context, AddNewAddress(addressListItem: addressListItem)).then((value) {
          getAddressList();
          if (prefGetString(prefNewDeliveryAddress).trim().isNotEmpty) {
            if (addressListItem?.addressId == AddressListItem.fromJson(jsonDecode(prefGetString(prefNewDeliveryAddress))).addressId) {
              setResult = true;
            }
          }
        });
      } else {
        openSimpleSnackbar( languages.maxAddressMsg(maxAddressLimit));
      }
    } else {
      openScreenWithResult(context, AddNewAddress(addressListItem: addressListItem)).then((value) {
        getAddressList();
        if (prefGetString(prefNewDeliveryAddress).trim().isNotEmpty) {
          if (addressListItem.addressId == AddressListItem.fromJson(jsonDecode(prefGetString(prefNewDeliveryAddress))).addressId) {
            setResult = true;
          }
        }
      });
    }
  }

  deleteAddress(int addressId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectDeleteAddress.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _manageAddressRepo.callDeleteAddressApi(addressId));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectDeleteAddress.sink.add(ApiResponse.completed(response));
          if (prefGetString(prefNewDeliveryAddress).trim().isNotEmpty &&
              AddressListItem.fromJson(jsonDecode(prefGetString(prefNewDeliveryAddress))).addressId == addressId) {
            prefSetString(prefNewDeliveryAddress, "");
            setResult = true;
          }
          Navigator.pop(context, true);
          openSimpleSnackbar( languages.addressDeletedSuccessMsg);
          getAddressList();
        } else {
          _subjectDeleteAddress.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subjectDeleteAddress.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
    _subjectDeleteAddress.close();
  }
}
