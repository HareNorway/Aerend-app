/// Client-side brand scrub for CMS / legacy HTML that still says «Hare».
///
/// Support pages are stored in Admin `page_settings` and often still contain
/// the old brand. We rewrite on display so users always see Reen Dugnad —
/// even before the DB migration lands on every environment.
String scrubLegacyBrandHtml(String html) {
  var out = html;

  // Emails first (contain "hare" as a substring).
  const emailMap = <String, String>{
    'norwayhare@gmail.com': 'ailogisticsas@gmail.com',
    'hareappen@gmail.com': 'ailogisticsas@gmail.com',
    'Whitelabelfoxapp@gmail.com': 'ailogisticsas@gmail.com',
    'whitelabelfoxapp@gmail.com': 'ailogisticsas@gmail.com',
  };
  emailMap.forEach((from, to) {
    out = out.replaceAll(from, to);
  });

  // Phrase / title replacements (order matters — longer first).
  const phrases = <String, String>{
    'Hare App': 'Reen Dugnad',
    'Hare app': 'Reen Dugnad',
    'HareApp': 'Reen Dugnad',
    'Food Delivery': 'Reen Dugnad',
    'food delivery': 'Reen Dugnad',
    'the Hare app': 'the Reen Dugnad app',
    'the Hare': 'Reen Dugnad',
    'with Hare': 'with Reen Dugnad',
    '© Copyright 2024 Hare.': '© Copyright Ai Logistics AS / Reen Dugnad.',
    '© Copyright 2024 Hare': '© Copyright Ai Logistics AS / Reen Dugnad',
    'the Ærend app': 'the Reen Dugnad app',
    'the Aerend app': 'the Reen Dugnad app',
  };
  phrases.forEach((from, to) {
    out = out.replaceAll(from, to);
  });

  // Standalone brand token (HTML-safe word edges). Avoids "share", "Shared",
  // "hare.io", "HareCustomer", etc.
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])Ærend(?![A-Za-z0-9_])'),
    (_) => 'Reen Dugnad',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])Aerend(?![A-Za-z0-9_])'),
    (_) => 'Reen Dugnad',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])ÆREND(?![A-Za-z0-9_])'),
    (_) => 'REEN DUGNAD',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])Hare(?![A-Za-z0-9_])'),
    (_) => 'Reen Dugnad',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])HARE(?![A-Za-z0-9_])'),
    (_) => 'REEN DUGNAD',
  );

  return out;
}
