import 'package:dio/dio.dart';

import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';

class EditProfileRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  editProfileApi(String fullName, String selectedCountryCode, String contactNum,
      String email, String emergencyContact,
      {MultipartFile? multipartFile, progress}) async {
    final body = {
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      ApiParam.paramFullName: fullName,
      ApiParam.paramSelectCountryCode: selectedCountryCode,
      ApiParam.paramContactNumber: contactNum,
      ApiParam.paramEmail: email,
      ApiParam.paramEmergencyContact: emergencyContact,
      ApiParam.paramDescription: "",
    };

    if (multipartFile != null) {
      body[ApiParam.paramProfileImage] = multipartFile;
    }

    final response = await _apiBaseHelper.postFormData(
      ApiConst.endPointEditProfile,
      body: body,
      onProgress: progress,
    );
    return response;
  }

  deleteAccountApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointRemoveAccount,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken)
      },
    );
    return response;
  }
}
