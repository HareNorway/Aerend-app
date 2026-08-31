import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../googleApi/google_api_dl.dart';
import '../googleApi/google_api_repo.dart';
import 'utils.dart';

class GetRoutesUtils {
  String tag = "GetRoutesUtils>>>";

  getRoutes(
      String origin,
      String destination,
      List<LatLng> wayPoints,
      Function(Map<PolylineId, Polyline> polyLines, int duration, int distance)
          callBack) async {
    try {
      var response = MapDataModel.fromJson(await GoogleApiRepo()
          .directionsApiCall(origin, destination, wayPoints));

      if (response.status!.toLowerCase() == "ok" &&
          response.routes != null &&
          response.routes!.isNotEmpty &&
          response.routes!.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        Map<PolylineId, Polyline> polyLines = {};
        int duration = 0, distance = 0;
        RoutesItem route = response.routes![0];
        List<LegsItem> legsList = route.legs!;
        List<LatLng> points = decodeEncodedPolyline(
            response.routes![0].overviewPolyline!.points!);
        if (points.isNotEmpty) {
          for (var point in points) {
            polylineCoordinates.add(point);
          }
        }
        PolylineId id = const PolylineId("poly");
        Polyline polyline = Polyline(
            polylineId: id,
            color: colorRed,
            // patterns: [
            //   PatternItem.dash(deviceAverageSize * 0.05),
            //   PatternItem.gap(deviceAverageSize * 0.01)
            // ],
            points: polylineCoordinates,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
            width: (deviceWidth * 0.01).toInt());
        polyLines[id] = polyline;

        if (legsList.isNotEmpty) {
          LegsItem leg = legsList[0];
          duration = leg.duration.value;
          distance = leg.distance.value;
        }
        callBack(polyLines, duration, distance);
      }
    } catch (e) {
      logd(tag, e.toString());
      callBack({}, 0, 0);
    }
  }

  List<LatLng> decodeEncodedPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }
}
