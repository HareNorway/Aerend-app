import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/services/ntf/ntf_hooks.dart';
import 'package:aerend_customer/services/ntf/ntf_push.dart';

/// Notifications plan Step 13 — the customer app reports the OS notification permission with the token (the opt-out
/// metric; nothing while it has not been asked), and an INSIGHT push offers «Færre slike», which records «less».
class _FakeCus extends CusApi {
  final List<(int, String)> utfall = [];
  final List<(bool, String, String?)> tillatelser = [];

  @override
  Future<bool> varselUtfall(int notificationId, String utfall, {String? skjerm}) async {
    this.utfall.add((notificationId, utfall));
    return true;
  }

  @override
  Future<bool> pushToken(String token, {String? platform}) async => true;

  @override
  Future<bool> varselTillatelse(bool enabled, String install, {String? platform}) async {
    tillatelser.add((enabled, install, platform));
    return true;
  }
}

void main() {
  late _FakeCus api;

  setUp(() {
    api = _FakeCus();
    NtfHooks.api = () => api;
    NtfHooks.installId = () async => 'inst-1';
  });

  test('the permission is reported with the install id; not asked yet → nothing', () async {
    NtfHooks.permissionEnabled = () async => false;
    expect(await NtfHooks.reportPermission(), isTrue);
    expect(api.tillatelser.single.$1, isFalse);
    expect(api.tillatelser.single.$2, 'inst-1');

    NtfHooks.permissionEnabled = () async => null;
    expect(await NtfHooks.reportPermission(), isFalse);
    expect(api.tillatelser, hasLength(1));

    NtfHooks.permissionEnabled = () async => throw StateError('no Firebase');
    expect(await NtfHooks.reportPermission(), isFalse, reason: 'never throws');
  });

  test('the token report also reports the permission', () async {
    NtfHooks.permissionEnabled = () async => true;
    NtfHooks.reportToken('tok-123456789');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(api.tillatelser.single.$1, isTrue);
  });

  test('«Færre slike» only on an INSIGHT push from the Varselsentral, and it records less', () {
    expect(NtfPayload.offersLess({'class': 'insight', 'notification_id': '42'}), isTrue);
    expect(NtfPayload.offersLess({'class': 'insight'}), isFalse, reason: 'no row to record it on');
    expect(NtfPayload.offersLess({'class': 'operational', 'notification_id': '42'}), isFalse);
    expect(NtfPayload.offersLess({'class': 'critical', 'notification_id': '42'}), isFalse);

    expect(NtfHooks.reportLess({'class': 'insight', 'notification_id': '42'}), isTrue);
    expect(api.utfall.single, (42, 'less'));
    expect(NtfHooks.reportLess({'class': 'insight'}), isFalse);
  });
}
