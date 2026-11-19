import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/api_base_helper.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/services/lopet_utboks.dart';

import '../a3/a3_fakes.dart';

/// Points plan Step 8 (game spec §10.2, T12): the outbox keeps runs until the server has decided on them.
class _Svar extends ApiBaseHelper {
  _Svar(this.koder) : super(baseUrl: 'http://test.local/');

  final List<int> koder; // status code per call; 0 = network failure
  final List<Map<String, dynamic>> sendt = [];

  @override
  Future<ApiClientResult> postAllowClientError(String url, {dynamic body}) async {
    final k = koder.isEmpty ? 0 : koder.removeAt(0);
    if (k == 0) throw Exception('offline');
    sendt.add(Map<String, dynamic>.from(body as Map));
    return ApiClientResult(k, k == 200 ? {'status': 1, 'state': 'verified'} : {'status': 0, 'message': 'RUN_REJECTED'});
  }
}

LopetState _s() => LopetState.fromJson({
      'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 3, 'tokens': ['rt_a', 'rt_b', 'rt_c']},
      'course': {'id': 9, 'week': '2026-W47', 'engine_version': 1, 'params': {}, 'rows': []},
      'rewards': {},
    })!;

Future<void> _tre() async {
  for (final t in ['rt_a', 'rt_b', 'rt_c']) {
    await LopetLager.lagre(token: t, s: _s(), inputs: const [[30, 1]], result: const {'distance_m': 120, 'ticks': 600, 'crates': 0}, startedMs: 1);
  }
}

void main() {
  setUp(() async => a3Bootstrap(prefs: {'UserId': 815, 'AccessToken': 'tok'}));

  test('a 200 or a 422 takes a run out; a network failure keeps the rest for the next try', () async {
    await _tre();
    final h = _Svar([200, 422, 0]);
    expect(await LopetUtboks.send(helper: h), 2);
    expect(LopetLager.utboks().map((r) => r['token']), ['rt_c'], reason: 'kept: offline');
    expect(h.sendt.first['token'], 'rt_a');
    expect(h.sendt.first['inputs'], [[30, 1]]);
    expect(h.sendt.first['duration_ticks'], 600);

    expect(await LopetUtboks.send(helper: _Svar([200])), 1);
    expect(LopetLager.utboks(), isEmpty);
  });

  test('a guest sends nothing', () async {
    await a3Bootstrap();
    await _tre();
    expect(await LopetUtboks.send(helper: _Svar([200, 200, 200])), 0);
    expect(LopetLager.utboks(), hasLength(3));
  });

  test('a run finished while a send is under way goes in the same round (it is not left waiting)', () async {
    await _tre();
    final h = _Svar([200, 200, 200, 200]);
    final first = LopetUtboks.send(helper: h);
    await LopetLager.lagre(token: 'rt_d', s: _s(), inputs: const [], result: const {'distance_m': 50, 'ticks': 300, 'crates': 0}, startedMs: 2);
    final second = LopetUtboks.send(helper: h);
    expect(await second, 0, reason: 'joins the send under way');
    expect(await first, 4);
    expect(LopetLager.utboks(), isEmpty);
  });
}
