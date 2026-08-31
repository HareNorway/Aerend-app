/// Toggle celebration dev tooling without removing code.
class CelebrationDebugFlags {
  CelebrationDebugFlags._();

  /// Show the chip panel on DG Home (debug builds only).
  static const bool showPanel =     false;

  /// Ignore session cap while previewing from the dev panel.
  static const bool bypassSessionCap = true;

  /// Fire-and-forget server enqueue when tapping a chip (integration smoke).
  static const bool alsoCallDevApi =  false;
}
