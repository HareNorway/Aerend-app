import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class AddNewAddressRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callAddAddressApi(String address, String addressType, LatLng latLng, String flatNo, String landmark) async {
    final safeFlat = flatNo.trim().isEmpty ? 'N/A' : flatNo.trim();
    final safeLandmark = landmark.trim().isEmpty ? address : landmark.trim();
    final response = await _apiBaseHelper.post(
      ApiConst.endPointAddAddress,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramAddress: address,
        ApiParam.paramType: addressType,
        ApiParam.paramLat: latLng.latitude,
        ApiParam.paramLong: latLng.longitude,
        ApiParam.paramFlatNo: safeFlat,
        ApiParam.paramLandmark: safeLandmark
      },
    );
    return response;
  }

  callEditAddressApi(int addressId, String address, String addressType, LatLng latLng, String flatNo, String landmark) async {
    final safeFlat = flatNo.trim().isEmpty ? 'N/A' : flatNo.trim();
    final safeLandmark = landmark.trim().isEmpty ? address : landmark.trim();
    final response = await _apiBaseHelper.post(
      ApiConst.endPointEditAddress,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramAddressId: addressId,
        ApiParam.paramAddress: address,
        ApiParam.paramType: addressType,
        ApiParam.paramLat: latLng.latitude,
        ApiParam.paramLong: latLng.longitude,
        ApiParam.paramFlatNo: safeFlat,
        ApiParam.paramLandmark: safeLandmark
      },
    );
    return response;
  }
}
