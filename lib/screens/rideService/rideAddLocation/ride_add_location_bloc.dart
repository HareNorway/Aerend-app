import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../blocs/bloc.dart';
import '../../../../googleApi/google_api_repo.dart';
import '../../../../googleApi/place_model_dl.dart';
import '../../../../googleApi/place_name_dl.dart';
import '../../../../utils/utils.dart';
import 'ride_add_location.dart';

class RideAddLocationBloc extends Bloc {
  String tag = "AddLocationBloc>>>";

  BuildContext context;
  CameraPosition? cameraPosition;
  GoogleMapController? googleMapController;
  bool setAddress = false, isSearched = true, setFromPlaceList = false, isFirstTime = true;
  LatLng latLng = defaultLatLng;
  final GoogleApiRepo _googleApiRepo = GoogleApiRepo();
  TextEditingController textEditingController = TextEditingController();

  State<RideAddLocation> state;

  RideAddLocationBloc(this.context, this.state) {
    // textEditingController.addListener(() {
    //   getPlaces(textEditingController.text);
    // });
  }

  final _locationSearchController = BehaviorSubject<String>();
  final _placesListController = BehaviorSubject<List<Predictions>>();
  final _loadingController = BehaviorSubject<bool>.seeded(false);

  Stream<String> get locationSearch => _locationSearchController.stream;

  Stream<bool> get loading => _loadingController.stream;

  Stream<List<Predictions>> get placesList => _placesListController.stream;

  Function(bool) get changeLoading => _loadingController.sink.add;

  changeLocationSearch(String search) {
    _locationSearchController.sink.add(search);
    if (isSearched) {
      _placesListController.sink.add([]);
      isSearched = false;
    } else {
      if (search.trim().isNotEmpty) {
        if (!setFromPlaceList) {
          getPlaces(search);
        }
      } else {
        _placesListController.sink.add([]);
        isSearched = false;
      }
    }
  }

  getPlaces(String search) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = PlaceModel.fromJson(await _googleApiRepo.placeApiCall(search, latLng));

        _placesListController.sink.add(response.predictions ?? []);
      } catch (e) {
        logd(tag, e.toString());
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  onPlaceListClick(String placeName, String placeId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      changeLoading(true);
      isSearched = true;
      setFromPlaceList = true;
      _locationSearchController.sink.add(placeName);
      try {
        var response = PlaceName.fromJson(await _googleApiRepo.getPlaceNameFormID(placeId));
        changeLoading(false);
        Result? result = response.result;
        if (result != null) {
          Geometry? geometry = result.geometry;
          if (geometry != null) {
            PlaceNameLocation? locationLatLong = geometry.location;
            latLng = LatLng(locationLatLong?.lat ?? 0, locationLatLong?.lng ?? 0);
            focusInMap(googleMapController!, locationLatLong?.lat ?? 0, locationLatLong?.lng ?? 0, true);
            FocusManager.instance.primaryFocus!.unfocus();
          }
        }
      } catch (e) {
        logd(tag, e.toString());
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  onMapCreated(GoogleMapController googleMapController) async {
    this.googleMapController = googleMapController;
    this.googleMapController?.setMapStyle(await rootBundle.loadString('assets/mapStyle/map_style.txt'));
    getCurrentLocation(forcefullyGetLocation: true);
  }

  getCurrentLocation({bool forcefullyGetLocation = false}) {
    changeLoading(true);

    getLocationUtils.getLocationUtils((locationData) {
      latLng = LatLng(locationData.latitude ?? 0, locationData.longitude ?? 0);
    }, (l, address) {
      changeLoading(false);
      isSearched = true;
      if (!state.mounted) return;
      setFromPlaceList = true;
      changeLocationSearch(address);
      focusInMap(googleMapController!, l.latitude ?? 0, l.longitude ?? 0, true);
    }, getForceFully: forcefullyGetLocation);
  }

  onCameraMoved(CameraPosition cameraPosition) {
    changeLoading(true);
    if (!setFromPlaceList) {
      setAddress = true;
      _locationSearchController.sink.add("");
    }
    this.cameraPosition = cameraPosition;
  }

  onCameraIdle() {
    _placesListController.sink.add([]);
    if (setFromPlaceList) {
      changeLoading(false);
    }
    if (cameraPosition != null && googleMapController != null && setAddress && !setFromPlaceList) {
      changeLoading(true);
      isSearched = true;
      latLng = cameraPosition!.target;
      getStringAddress(cameraPosition!.target.latitude, cameraPosition!.target.longitude).then((value) {
        changeLoading(false);
        setAddress = false;
        _locationSearchController.sink.add(value);
        // changeLocationSearch(value.first.addressLine),
        // focusInMap(googleMapController!, cameraPosition!.target.latitude, cameraPosition!.target.longitude, false);
      });
    } else {
      setFromPlaceList = false;
    }
  }

  void confirmPlace() {
    Navigator.pop(context, {"address": _locationSearchController.value, "lat_long": latLng});
  }

  @override
  void dispose() {
    _locationSearchController.close();
    _placesListController.close();
    _loadingController.close();
    textEditingController.dispose();
  }
}
