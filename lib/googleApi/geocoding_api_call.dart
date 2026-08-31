import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'google_api_repo.dart';

class GeoCodingApiCall {
  final GoogleApiRepo _googleApiRepo = GoogleApiRepo();

  Future<List<Placemark>?> findAddressesFromCoordinates(
      LatLng coordinates) async {
    return _send(coordinates);
  }

  Future<List<Placemark>?> _send(LatLng coordinates) async {
    final response = await _googleApiRepo.geoCodingApiCall(
        coordinates.latitude, coordinates.longitude);
    var results = response["results"];
    if (results == null) return null;
    return results
        .map(_convertAddress)
        .map<Placemark>((map) => Placemark.fromMap(map))
        .toList();
  }

  Future<dynamic> findFormattedAddressesFromCoordinates(
      LatLng coordinates) async {
    final response = await _googleApiRepo.geoCodingApiCall(
        coordinates.latitude, coordinates.longitude);
    var results = response["results"];
    if (results == null) return null;
    results =
        results.map((result) => result['formatted_address'] ?? '').toList();
    return results;
  }

  Map? _convertCoordinates(dynamic geometry) {
    if (geometry == null) return null;

    var location = geometry["location"];
    if (location == null) return null;

    return {
      "latitude": location["lat"],
      "longitude": location["lng"],
    };
  }

  Map _convertAddress(dynamic data) {
    Map result = {};

    result["coordinates"] = _convertCoordinates(data["geometry"]);
    result["addressLine"] = data["formatted_address"];

    var addressComponents = data["address_components"];

    addressComponents.forEach((item) {
      List types = item["types"];

      if (types.contains("route")) {
        result["thoroughfare"] = item["long_name"];
      } else if (types.contains("street_number")) {
        result["subThoroughfare"] = item["long_name"];
      } else if (types.contains("country")) {
        result["countryName"] = item["long_name"];
        result["countryCode"] = item["short_name"];
      } else if (types.contains("locality")) {
        result["locality"] = item["long_name"];
      } else if (types.contains("postal_code")) {
        result["postalCode"] = item["long_name"];
      } else if (types.contains("postal_code")) {
        result["postalCode"] = item["long_name"];
      } else if (types.contains("administrative_area_level_1")) {
        result["adminArea"] = item["long_name"];
      } else if (types.contains("administrative_area_level_2")) {
        result["subAdminArea"] = item["long_name"];
      } else if (types.contains("sublocality") ||
          types.contains("sublocality_level_1")) {
        result["subLocality"] = item["long_name"];
      } else if (types.contains("premise")) {
        result["featureName"] = item["long_name"];
      }

      result["featureName"] = result["featureName"] ?? result["addressLine"];
    });

    return result;
  }
}
