import '../../../networking/api_base_helper.dart';

class ExploreCityRepo {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  callGetHareCitiesApi() async {
    final response = await _apiBaseHelper.post(
      ApiConst.endPointGetHareCities,
      body: {},
    );
    return response;
  }
}
