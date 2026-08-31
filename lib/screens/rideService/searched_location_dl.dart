import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchedLocation {
  dynamic lat, lng;
  String? name;
  LatLng? latLng;

  SearchedLocation({required this.name, required this.lat, required this.lng, this.latLng});

  static SearchedLocation? fromJson(dynamic json) {
    return json != null
        ? SearchedLocation(
            name: json["address"],
            lat: json["address_lat"],
            lng: json["address_long"],
          )
        : null;
  }

  dynamic toJson() {
    return {
      "address": name,
      "address_lat": lat,
      "address_long": lng,
    };
  }
}
