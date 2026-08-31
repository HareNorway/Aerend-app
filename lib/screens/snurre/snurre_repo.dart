import '../../networking/api_base_helper.dart';
import '../../utils/shared_pref_utill.dart';
import '../../utils/utils.dart';

class SnurreRepo {
  final ApiBaseHelper _api = ApiBaseHelper();

  /// Same delivery address + session as the home screen ([prefGetLatLngForStoreSearch]).
  Map<String, dynamic> _clientBody({String? lat, String? long}) {
    final ll = prefGetLatLngForStoreSearch();
    final addressId = prefGetInt(prefNewDeliveryAddressId);
    return {
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      ApiParam.paramLat: lat ?? '${ll.latitude}',
      ApiParam.paramLong: long ?? '${ll.longitude}',
      if (addressId > 0) ApiParam.paramDeliveryAddressId: addressId,
    };
  }

  /// Called when Snurre screen opens — confirms login, address, and cart access.
  Future<dynamic> postContext() async {
    return _api.post(ApiConst.endPointSnurreContext, body: _clientBody());
  }

  /// Snurre resolves service from the user's message only — not the home-screen tab.
  Future<dynamic> postChat({
    required String message,
    int? conversationId,
    String? lat,
    String? long,
  }) async {
    final body = _clientBody(lat: lat, long: long);
    body[ApiParam.paramSnurreMessage] = message;
    if (conversationId != null) {
      body[ApiParam.paramSnurreConversationId] = conversationId;
    }
    return _api.post(ApiConst.endPointSnurreChat, body: body);
  }

  Future<dynamic> listConversations() async {
    return _api.post(
      ApiConst.endPointSnurreConversationsList,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
  }

  Future<dynamic> conversationMessages(int conversationId) async {
    return _api.post(
      ApiConst.endPointSnurreConversationMessages,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        ApiParam.paramSnurreConversationId: conversationId,
      },
    );
  }
}
