/// Feature toggles for Dugnad surfaces that depend on backend/payment readiness.
class DugnadFeatureFlags {
  DugnadFeatureFlags._();

  /// When `false`, Fast støtte is hidden/disabled regardless of backend flag.
  /// Set `true` when the donation API slice is deployed.
  static const bool donationsEnabled = true;
}
