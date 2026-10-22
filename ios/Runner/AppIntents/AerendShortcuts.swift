import AppIntents

/// The App Shortcuts Siri and the Shortcuts app list under Ærend (Commerce
/// spec §10). The Norwegian phrases come first; the English ones let an
/// English-language device find them too. `\(.applicationName)` is the
/// app's display name («Ærend»).
@available(iOS 16.0, *)
struct AerendShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OrderAgainIntent(),
      phrases: [
        "Bestill det vanlige med \(.applicationName)",
        "Bestill det vanlige i \(.applicationName)",
        "Order the usual with \(.applicationName)",
      ],
      shortTitle: "Bestill det vanlige",
      systemImageName: "bolt.fill"
    )
    AppShortcut(
      intent: TrackOrderIntent(),
      phrases: [
        "Følg bestillingen i \(.applicationName)",
        "Hvor er bestillingen min i \(.applicationName)",
        "Track my order in \(.applicationName)",
      ],
      shortTitle: "Følg bestillingen",
      systemImageName: "location.fill"
    )
    AppShortcut(
      intent: FindStoresNearMeIntent(),
      phrases: [
        "Finn butikker nær meg i \(.applicationName)",
        "Butikker nær meg i \(.applicationName)",
        "Find stores near me in \(.applicationName)",
      ],
      shortTitle: "Butikker nær meg",
      systemImageName: "mappin.and.ellipse"
    )
    AppShortcut(
      intent: OpenCartIntent(),
      phrases: [
        "Åpne handlekurven i \(.applicationName)",
        "Open my cart in \(.applicationName)",
      ],
      shortTitle: "Åpne handlekurven",
      systemImageName: "cart.fill"
    )
  }

  static var shortcutTileColor: ShortcutTileColor = .teal
}
