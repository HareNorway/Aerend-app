import 'package:flutter/foundation.dart';

/// T1 — inline points count-up on the visible home anchor card (not orchestrator).
class DugnadT1Controller extends ChangeNotifier {
  DugnadT1Controller._();

  static final DugnadT1Controller instance = DugnadT1Controller._();

  int _displayPoints = 0;
  int? _pulseDelta;
  bool _cardAttached = false;
  bool _cardVisible = true;

  int get displayPoints => _displayPoints;
  int? get pulseDelta => _pulseDelta;
  bool get isPulsing => _pulseDelta != null;

  void attachCard() {
    _cardAttached = true;
  }

  void detachCard() {
    _cardAttached = false;
    _pulseDelta = null;
  }

  void setCardVisible(bool visible) {
    _cardVisible = visible;
  }

  /// Seed display total when summary first arrives (no animation).
  void syncBaseline(int points) {
    if (_displayPoints == points && _pulseDelta == null) return;
    if (_pulseDelta != null) return;
    _displayPoints = points;
    notifyListeners();
  }

  /// Confirmed increase from ledger / home refresh.
  Future<void> onPointsIncreased({
    required int previous,
    required int next,
  }) async {
    if (next <= previous) {
      _displayPoints = next;
      notifyListeners();
      return;
    }
    await _runPulse(from: previous, to: next, delta: next - previous);
  }

  /// Dev panel — force a +delta count-up on the anchor card.
  Future<void> debugPulse({int delta = 55}) async {
    if (!_cardAttached || delta <= 0) return;
    final from = _displayPoints;
    await _runPulse(from: from, to: from + delta, delta: delta);
  }

  Future<void> _runPulse({
    required int from,
    required int to,
    required int delta,
  }) async {
    if (!_cardAttached || !_cardVisible) {
      _displayPoints = to;
      _pulseDelta = null;
      notifyListeners();
      return;
    }

    _displayPoints = from;
    _pulseDelta = delta;
    notifyListeners();

    const steps = 14;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 45));
      _displayPoints = from + ((to - from) * i / steps).round();
      notifyListeners();
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    _pulseDelta = null;
    _displayPoints = to;
    notifyListeners();
  }

  /// Instant swap under reduced motion.
  void applyInstant(int points) {
    _displayPoints = points;
    _pulseDelta = null;
    notifyListeners();
  }
}
