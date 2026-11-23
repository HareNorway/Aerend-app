import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/api_base_helper.dart';
import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_copy.dart';

import '../a3/a3_fakes.dart';

class _Url extends ApiBaseHelper {
  _Url() : super(baseUrl: 'http://test.local/');

  final List<Uri> hentet = [];

  @override
  Future<dynamic> get(String url) async {
    hentet.add(Uri.parse(url));
    return {'status': 1, 'activity': [{'tool': 'place_order', 'outcome': 'ok', 'at': '2026-11-23T11:32:15+01:00'}], 'products': []};
  }
}

/// T2 (MCP-D04): «Aktivitet» said «Ingen aktivitet ennå» because the activity and «Bytt» calls put their own
/// query in the path, so the login params came after a second `?` and the server answered AUTH_REQUIRED.
void main() {
  setUp(() async => a3Bootstrap(prefs: {'UserId': 815, 'AccessToken': 'tok'}));

  test('the activity call sends the login and the limit as one query', () async {
    final h = _Url();
    final a = await CusApi(helper: h).aiLinkActivity(1);
    final u = h.hentet.single;
    expect(u.path, endsWith('ai/links/1/activity'));
    expect(u.queryParameters, {'user_id': '815', 'access_token': 'tok', 'limit': '30'});
    expect(a!.single.tool, 'place_order');
  });

  test('«Bytt» sends the line id next to the login', () async {
    final h = _Url();
    await CusApi(helper: h).aiRequestAlternatives('q_abc', 2);
    final u = h.hentet.single;
    expect(u.path, endsWith('ai/requests/q_abc/alternatives'));
    expect(u.queryParameters, {'user_id': '815', 'access_token': 'tok', 'line_id': '2'});
  });

  test('the MCP tools have their own activity lines, never the raw tool name', () {
    for (final t in ['search_stores', 'search_products', 'get_store', 'get_product', 'list_addresses', 'get_cart', 'update_cart', 'reorder_to_cart', 'get_quote', 'place_order', 'get_order', 'list_orders', 'cancel_order', 'contact_support']) {
      expect(AiCopy.cus_ai_akt(t), isNot(t), reason: t);
    }
  });
}
