import AppIntents

/// «Finn butikker nær meg i Ærend»: Søk, which lists the stores around the
/// delivery address first.
@available(iOS 16.0, *)
struct FindStoresNearMeIntent: AppIntent {
  static var title: LocalizedStringResource = "Finn butikker nær meg"
  static var description = IntentDescription("Åpner søket med butikkene nær deg.")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    await AerendLink.open("/sok?naer=1")
    return .result()
  }
}
