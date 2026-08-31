import 'package:location/location.dart';

import 'utils.dart';

class GetLocationUtils {
  Location location = Location();
  LocationData? locationData;
  String? address;

  getLocationUtils(
      Function(LocationData locationData) onLocationDataGet, Function(LocationData locationData, String address) onLocationDataGetWithAddress,
      {bool getForceFully = false, bool isGetAddress = true}) async {
    if (!getForceFully && locationData != null && address != null) {
      onLocationDataGet(locationData!);
      onLocationDataGetWithAddress(locationData!, address!);
      return;
    }
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData l = await fetchCurrentLocation(location);
    locationData = l;
    onLocationDataGet(l);
    if (isGetAddress) {
      try {
        getStringAddress(l.latitude!, l.longitude!).then((addressLine) {
          address = addressLine;
          onLocationDataGetWithAddress(l, addressLine);
        });
      } catch (e) {
        getStringAddress(l.latitude!, l.longitude!).then((addressLine) {
          address = addressLine;
          onLocationDataGetWithAddress(l, addressLine);
        });
      }
    } else {
      onLocationDataGetWithAddress(l, address ?? "");
    }
  }

  fetchCurrentLocation(Location location) async {
    LocationData? l = await Future.any([
      location.getLocation(),
      Future.delayed(const Duration(seconds: 2), () => null),
    ]);
    return l ?? await fetchCurrentLocation(location);
  }
}
