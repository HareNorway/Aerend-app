import 'package:flutter/foundation.dart';

import '../../../utils/shared_pref_utill.dart';

import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../data/points/points_app_repo.dart';

/// The agil-3 screens resolve their data sources here so widget tests can
/// swap in fakes without threading constructors through named routes.
abstract final class A3Services {
  static PointsAppApi Function() points = () => PointsAppRepo();
  static AegilAppApi Function() aegil = () => AegilAppRepo();
  static AegilRepo Function() aegilRepo = () => AegilRepo();

  /// "Roligere bevegelse" (Konto): honoured by every agil-3 screen through
  /// [A3Motion] until agil-1 lifts it into the app-wide MediaQuery.
  static final ValueNotifier<bool> reducedMotion = ValueNotifier<bool>(false);

  @visibleForTesting
  static void reset() {
    points = () => PointsAppRepo();
    aegil = () => AegilAppRepo();
    aegilRepo = () => AegilRepo();
    reducedMotion.value = false;
  }
}

/// Runs [f] and turns any failure — including a synchronous throw from an
/// uninitialised global such as the prefs — into `null`, so a screen can
/// always build its first frame.
Future<T?> a3Try<T>(Future<T?> Function() f) async {
  try {
    return await f();
  } catch (_) {
    return null;
  }
}

/// A pref read that returns '' instead of throwing before prefs are ready.
String a3Pref(String key) {
  try {
    return prefGetString(key);
  } catch (_) {
    return '';
  }
}
