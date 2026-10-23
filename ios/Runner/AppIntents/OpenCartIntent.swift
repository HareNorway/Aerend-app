import AppIntents

/// «Åpne handlekurven i Ærend»: the Kurv screen.
@available(iOS 16.0, *)
struct OpenCartIntent: AppIntent {
  static var title: LocalizedStringResource = "Åpne handlekurven"
  static var description = IntentDescription("Åpner handlekurven din i Ærend.")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    await AerendLink.open("/kurv")
    return .result()
  }
}
