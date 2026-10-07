import '../api_base_helper.dart';
import 'ops_customer_api.dart';

/// The customer app's calls into the monolith's ops feed endpoints.
///
/// Separate from `FeedRepo`, which talks to the feed *service*. Vågen lives in
/// the monolith because the event it emits is what agil-2's Points reads, and
/// the once-a-day limit needs a transactional store behind it — so it is a
/// different base URL and a different failure mode, and mixing the two in one
/// client would hide that.
class OpsFeedApi {
  OpsFeedApi({ApiBaseHelper? helper})
    : _helper = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);

  final ApiBaseHelper _helper;

  /// The house `user_id` + `access_token` (backend plan Step 1): `ops.actor`
  /// takes the customer from the login, not from `customer_id`, and refuses
  /// a call without one once `ops.auth.enforce` is `enforce`.
  static String _query([Map<String, String> extra = const {}]) => Uri(
    queryParameters: {...?OpsCustomerApi.authParams(), ...extra},
  ).query;

  /// Does this customer still have today's pull?
  ///
  /// Returns true on any failure. Showing the card and having the pull refused
  /// is recoverable; hiding it because a status call timed out silently takes
  /// the day's reward away.
  Future<bool> vaagenAvailable(int customerId) async {
    try {
      final dynamic json = await _helper.get(
        'api/ops/feed/vaagen?${_query({'customer_id': '$customerId'})}',
      );

      if (json is Map<String, dynamic>) {
        return json['available'] != false;
      }
    } catch (_) {
      // Fall through to the optimistic default; see above.
    }

    return true;
  }

  /// Pull today's catch. Emits `suggestion.reeled` server-side.
  ///
  /// `already` true means the customer had spent today's pull — not an error,
  /// and the caller shows the spent state rather than a failure.
  Future<VaagenReelResult> reel({
    required int customerId,
    String? postId,
    String? suggestionId,
  }) async {
    final dynamic json = await _helper.post(
      'api/ops/feed/vaagen/reel?${_query()}',
      body: <String, dynamic>{
        'customer_id': customerId,
        if (postId != null) 'post_id': postId,
        if (suggestionId != null) 'suggestion_id': suggestionId,
      },
    );

    if (json is! Map<String, dynamic>) {
      throw StateError('Unexpected Vågen response');
    }

    return VaagenReelResult(
      reeled: json['reeled'] == true,
      already: json['already'] == true,
      day: json['day']?.toString(),
    );
  }
}

class VaagenReelResult {
  const VaagenReelResult({
    required this.reeled,
    required this.already,
    this.day,
  });

  final bool reeled;
  final bool already;
  final String? day;

  /// Either outcome means today's pull is spent.
  bool get spent => reeled || already;
}
