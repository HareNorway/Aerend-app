import AppIntents

/// «Bestill det vanlige med Ærend»: Hurtig with the last order drafted
/// («Bestilt forrige gang»), or a named favourite as the line to Ægil. The
/// customer confirms in the app; the intent never places an order.
@available(iOS 16.0, *)
struct OrderAgainIntent: AppIntent {
  static var title: LocalizedStringResource = "Bestill det vanlige"
  static var description = IntentDescription("Åpner Ærend med forrige bestilling klar. Ingenting sendes før du bekrefter i appen.")
  static var openAppWhenRun: Bool = true

  @Parameter(title: "Favoritt", description: "En favoritt å bestille, f.eks. «fiskesuppe fra Torgboden». Tom: det vanlige.")
  var favoritt: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Bestill \(\.$favoritt) med Ærend")
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    let fav = (favoritt ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if fav.isEmpty {
      await AerendLink.open("/hurtig?mod=forrige")
    } else {
      await AerendLink.open("/hurtig?si=" + AerendLink.query("Bestill " + fav))
    }
    return .result()
  }
}
