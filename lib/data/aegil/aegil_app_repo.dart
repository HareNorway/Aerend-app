import '../../networking/api_base_helper.dart';
import '../../utils/shared_pref_utill.dart';
import '../../utils/utils.dart';
import 'aegil_app_models.dart';
import 'chat_card_models.dart';
import 'suggestion_models.dart';

/// The Ægil screen's calls (agil-3 Phase 7): chat turns, the suggestion
/// tray by context, feedback on a suggestion, "Mens du var borte", the trust
/// ledger, C3 photo and C4 door. Same auth shape as [AegilRepo].
///
/// Screens take an [AegilAppApi] so tests can inject a fake; this class is
/// the network implementation.
abstract class AegilAppApi {
  /// One chat turn. [storeId], [category] and [recipient] (sent as `for`)
  /// are the context Ægil was opened with (D-K20).
  ///
  /// Customer Step 5: [conversationId] continues a chat (`cv_…`); [orderId]
  /// is the order «Spør Ægil» was opened from on its tracking view.
  Future<AegilTurn?> chat({String? text, String? intent, int? storeId, String? category, String? recipient, String? conversationId, int? orderId});

  /// Customer Step 5: the customer's chats, newest first, and one chat's
  /// lines — the screen resumes the last one after a relaunch.
  Future<List<AegilSamtale>> conversations();
  Future<List<AegilSamtaleLinje>?> conversation(String id);

  /// «Ny prat»: the chat is closed; the next line starts a new one.
  Future<bool> closeConversation(String id);

  /// The customer's tap on a cart proposal (`pa_…`): the card back as a
  /// receipt — or [feil], the server's words, when it could not be done.
  Future<({AeVerktoy? kort, String? feil})> applyAction(String id);

  /// Angre: the basket as it was before the tap.
  Future<({AeVerktoy? kort, String? feil})> undoAction(String id);

  /// «Aldri dette» on a Hjem float: stored as a product exclusion.
  Future<bool> neverProduct(int storeProductId);

  Future<List<Suggestion>> suggestions({String? context});
  Future<bool> add(int suggestionId);
  Future<bool> dismiss(int suggestionId);
  Future<bool> never(int suggestionId, String reasonCode);
  Future<List<AwayItem>> away();
  /// Gap Step 1: marks Ægil's actions seen (`POST agent/me/away/seen`).
  Future<bool> awaySeen();
  /// Gap Step 3: everything Ægil did in the last [days] (`GET agent/me/actions`).
  Future<List<AwayItem>> actions({int days = 30});
  Future<TrustLedger?> trustLedger();
  Future<AegilTurn?> photoOrder(List<String> items);
  Future<String?> doorNote(String note);

  // agil-4: the Meg tab.
  Future<List<Occasion>> occasions();
  Future<List<Occasion>> addOccasion({required String person, required String date, String? label});
  Future<List<Occasion>> removeOccasion(int id);
  Future<List<ShoppingListItem>> shoppingList();

  // Customer Step 7: learned patterns, the level-3 merge's lines and receipts, the push invitation.
  // Plain defaults, so a fake that does not know them still compiles.
  Future<List<LearnedPatternItem>> patterns() async => const [];
  Future<LearnedPatternItem?> decidePattern(int id, {required bool confirm}) async => null;
  Future<List<AgentLine>> agentLines() async => const [];
  Future<bool> undoLine(int cartId) async => false;
  Future<bool> undoAgentAction(int actionId) async => false;
  Future<bool> pushInvite({required bool accept}) async => false;
}

class AegilAppRepo implements AegilAppApi {
  ApiBaseHelper get _api => ApiBaseHelper(baseUrl: ApiConst.baseAgentUrl);

  Map<String, dynamic> _auth() => {
    ApiParam.paramUserId: prefGetInt(prefUserId),
    ApiParam.paramAccessToken: prefGetString(prefAccessToken),
  };

  String _query(Map<String, dynamic> params) => Uri(
    queryParameters: params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
  ).query;

  Map<String, dynamic>? _ok(dynamic response) {
    if (response is! Map) return null;
    final json = response.cast<String, dynamic>();
    return json['status'] == 1 ? json : null;
  }

  @override
  Future<AegilTurn?> chat({String? text, String? intent, int? storeId, String? category, String? recipient, String? conversationId, int? orderId}) async {
    try {
      final json = _ok(await _api.post('chat', body: {
        ..._auth(),
        if (text != null) 'text': text,
        if (intent != null) 'intent': intent,
        if (storeId != null) 'store_id': storeId,
        if (category != null) 'category': category,
        if (recipient != null) 'for': recipient,
        if (conversationId != null) 'conversation_id': conversationId,
        if (orderId != null) 'order_id': orderId,
      }));
      return json == null ? null : AegilTurn.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AegilSamtale>> conversations() async {
    try {
      final json = _ok(await _api.get('chat/conversations?${_query(_auth())}'));
      return ((json?['conversations'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AegilSamtale.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<AegilSamtaleLinje>?> conversation(String id) async {
    try {
      final json = _ok(await _api.get('chat/conversations/$id?${_query(_auth())}'));
      if (json == null) return null;
      return ((json['messages'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AegilSamtaleLinje.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> closeConversation(String id) async {
    try {
      return _ok(await _api.post('chat/conversations/$id/close', body: _auth())) != null;
    } catch (_) {
      return false;
    }
  }

  Future<({AeVerktoy? kort, String? feil})> _action(String id, String what) async {
    try {
      final r = await _api.post('chat/actions/$id/$what', body: _auth());
      final json = _ok(r);
      if (json != null && json['card'] is Map) return (kort: AeVerktoy.fromJson((json['card'] as Map).cast<String, dynamic>()), feil: null);
      return (kort: null, feil: r is Map ? r['message'] as String? : null);
    } catch (_) {
      return (kort: null, feil: null);
    }
  }

  @override
  Future<({AeVerktoy? kort, String? feil})> applyAction(String id) => _action(id, 'apply');

  @override
  Future<({AeVerktoy? kort, String? feil})> undoAction(String id) => _action(id, 'undo');

  @override
  Future<bool> neverProduct(int storeProductId) async {
    try {
      return _ok(await _api.post('me/never', body: {..._auth(), 'store_product_id': storeProductId})) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Suggestion>> suggestions({String? context}) async {
    try {
      final json = _ok(await _api.get('me/suggestions?${_query({..._auth(), if (context != null) 'context': context})}'));
      if (json == null) return const [];
      return ((json['suggestions'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Suggestion.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> add(int suggestionId) => _feedback('me/suggestions/$suggestionId/add');

  @override
  Future<bool> dismiss(int suggestionId) => _feedback('me/suggestions/$suggestionId/dismiss');

  @override
  Future<bool> awaySeen() => _feedback('me/away/seen');

  // ── Customer Step 7 ──────────────────────────────────────────────────────

  @override
  Future<List<LearnedPatternItem>> patterns() async {
    try {
      final json = _ok(await _api.get('me/patterns?${_query(_auth())}'));
      if (json == null) return const [];
      return ((json['patterns'] as List?) ?? const []).whereType<Map>().map((e) => LearnedPatternItem.fromJson(e.cast<String, dynamic>())).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<LearnedPatternItem?> decidePattern(int id, {required bool confirm}) async {
    try {
      final json = _ok(await _api.post('me/patterns/$id/${confirm ? 'confirm' : 'reject'}', body: _auth()));
      return json != null && json['pattern'] is Map ? LearnedPatternItem.fromJson((json['pattern'] as Map).cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AgentLine>> agentLines() async {
    try {
      final json = _ok(await _api.get('me/cart/agent-lines?${_query(_auth())}'));
      if (json == null) return const [];
      return ((json['lines'] as List?) ?? const []).whereType<Map>().map((e) => AgentLine.fromJson(e.cast<String, dynamic>())).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> undoLine(int cartId) => _feedback('me/cart/lines/$cartId/undo');

  @override
  Future<bool> undoAgentAction(int actionId) => _feedback('me/agent_actions/$actionId/undo');

  @override
  Future<bool> pushInvite({required bool accept}) => _feedback('me/push-invite', {'accept': accept});

  @override
  Future<List<AwayItem>> actions({int days = 30}) async {
    try {
      final json = _ok(await _api.get('me/actions?${_query({..._auth(), 'days': '$days'})}'));
      if (json == null) return const [];
      return ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AwayItem.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> never(int suggestionId, String reasonCode) => _feedback('me/suggestions/$suggestionId/never', {'reason_code': reasonCode});

  Future<bool> _feedback(String path, [Map<String, dynamic> extra = const {}]) async {
    try {
      return _ok(await _api.post(path, body: {..._auth(), ...extra})) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AwayItem>> away() async {
    try {
      final json = _ok(await _api.get('me/away?${_query(_auth())}'));
      if (json == null) return const [];
      return ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AwayItem.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<TrustLedger?> trustLedger() async {
    try {
      final json = _ok(await _api.get('me/trust-ledger?${_query(_auth())}'));
      final ledger = json?['ledger'];
      return ledger is Map ? TrustLedger.fromJson(ledger.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AegilTurn?> photoOrder(List<String> items) async {
    try {
      final json = _ok(await _api.post('photo-order', body: {..._auth(), 'items': items}));
      return json == null ? null : AegilTurn.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> doorNote(String note) async {
    try {
      final json = _ok(await _api.post('door-note', body: {..._auth(), 'note': note}));
      return json?['courier_line'] as String?;
    } catch (_) {
      return null;
    }
  }

  List<Occasion> _occasionList(Map<String, dynamic>? json) => ((json?['occasions'] as List?) ?? const [])
      .whereType<Map>()
      .map((e) => Occasion.fromJson(e.cast<String, dynamic>()))
      .toList();

  @override
  Future<List<Occasion>> occasions() async {
    try {
      return _occasionList(_ok(await _api.get('me/occasions?${_query(_auth())}')));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Occasion>> addOccasion({required String person, required String date, String? label}) async {
    try {
      return _occasionList(_ok(await _api.post('me/occasions', body: {..._auth(), 'person': person, 'date': date, if (label != null) 'label': label})));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Occasion>> removeOccasion(int id) async {
    try {
      return _occasionList(_ok(await _api.delete('me/occasions/$id?${_query(_auth())}')));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<ShoppingListItem>> shoppingList() async {
    try {
      final json = _ok(await _api.get('me/shopping-list?${_query(_auth())}'));
      return ((json?['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ShoppingListItem.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
