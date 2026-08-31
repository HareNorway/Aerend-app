import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../networking/api_base_helper.dart';
import '../utils/utils.dart';

class GoogleApiRepo {
  final ApiBaseHelper _apiBaseHelper =
      ApiBaseHelper(baseUrl: BaseUrl.domain + BaseUrl.endPointBaseUrlApi);

  placeApiCall(String text, LatLng latLng) async {
    final response = await _apiBaseHelper
        .post(ApiConst.endPointGoogleMap, body: {
      ApiParam.paramUrl: getPlaceQuery(text, latLng.latitude, latLng.longitude)
    });
    return response;
  }

  getPlaceNameFormID(String placeId) async {
    final response = await _apiBaseHelper.post(ApiConst.endPointGoogleMap,
        body: {ApiParam.paramUrl: getPlaceIDQuery(placeId)});
    return response;
  }

  getAddressListFromKeyword(String keyword, String country) async {
    final response = await _apiBaseHelper.post(ApiConst.endPointGoogleMap,
        body: {ApiParam.paramUrl: getGeoCodingAddress(keyword, country)});
    return response;
  }

  directionsApiCall(
      String origin, String destination, List<LatLng> wayPoints) async {
    final response = await _apiBaseHelper
        .post(ApiConst.endPointGoogleMap, body: {
      ApiParam.paramUrl: getRouteWithMultiStop(origin, destination, wayPoints)
    });
    return response;
  }

  geoCodingApiCall(double latitude, double longitude) async {
    final response = await _apiBaseHelper.post(ApiConst.endPointGoogleMap,
        body: {ApiParam.paramUrl: getGeoCodingQuery(latitude, longitude)});
    return response;
  }
}
