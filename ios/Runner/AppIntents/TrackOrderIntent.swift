import AppIntents

/// «Følg bestillingen i Ærend»: Sporing for the order under way (or the
/// newest one); Ordrehistorikk when there is none.
@available(iOS 16.0, *)
struct TrackOrderIntent: AppIntent {
  static var title: LocalizedStringResource = "Følg bestillingen"
  static var description = IntentDescription("Åpner sporingen av bestillingen som er på vei.")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    await AerendLink.open("/siste-bestilling")
    return .result()
  }
}
