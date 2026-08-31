import 'dugnad_state.dart';

/// Organization branding helpers for Phase 3 dynamic club identity.
class DugnadClubBranding {
  DugnadClubBranding._();

  static DugnadState get _state => DugnadState.instance;

  /// Full organization name for hero labels, e.g. "DU STOTTER {name}".
  static String fullName([DugnadState? state]) {
    final name = (state ?? _state).clubName.trim();
    return name;
  }

  /// Compact name from API `short_name` — never derived by splitting [fullName].
  static String compactName([DugnadState? state]) {
    final s = state ?? _state;
    final short = s.clubShortName.trim();
    if (short.isNotEmpty) return short;
    return s.clubName.trim();
  }

  /// Metal tier label prefix, e.g. `{short_name}-helt`.
  static String tierTitle(String tierKey, [DugnadState? state]) {
    final prefix = compactName(state);
    if (prefix.isEmpty) return tierKey;
    return '$prefix-$tierKey';
  }
}
