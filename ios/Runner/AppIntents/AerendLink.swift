import AppIntents
import UIKit

/// Customer Step 15 (Commerce spec §10, D-K19): every intent only opens the
/// app at a Bergen route through the `aerendapp://` scheme the app already
/// handles (`main.dart`). Nothing is ordered from a voice command alone —
/// OrderAgain lands on Hurtig's confirmation step.
@available(iOS 16.0, *)
enum AerendLink {
  static let scheme = "aerendapp://bergen"

  @MainActor
  static func open(_ path: String) async {
    guard let url = URL(string: scheme + path) else { return }
    _ = await UIApplication.shared.open(url)
  }

  static func query(_ value: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&=+?")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
  }
}
