/// Client-side brand scrub for CMS / legacy HTML that still says «Hare» or
/// «Reen Dugnad».
///
/// Support pages are stored in Admin `page_settings` and often still contain a
/// superseded brand. We normalize on display so users always see Ærend — even
/// before the DB migration lands on every environment.
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

  // Phrase / title replacements. ORDER MATTERS — a longer phrase must come
  // before any shorter phrase it contains, otherwise the shorter one consumes
  // it first (e.g. 'the Hare app' must precede 'Hare app', and
  // 'the Reen Dugnad app' must precede 'Reen Dugnad').
  const phrases = <String, String>{
    // Copyright lines (most specific).
    '© Copyright Ai Logistics AS / Reen Dugnad.':
        '© Copyright Ai Logistics AS / Ærend.',
    '© Copyright Ai Logistics AS / Reen Dugnad':
        '© Copyright Ai Logistics AS / Ærend',
    '© Copyright 2024 Hare.': '© Copyright Ai Logistics AS / Ærend.',
    '© Copyright 2024 Hare': '© Copyright Ai Logistics AS / Ærend',

    // "the <brand> app" — before the bare brand tokens below.
    'the Reen Dugnad app': 'the Ærend app',
    'the Hare app': 'the Ærend app',
    'the Aerend app': 'the Ærend app',

    // Superseded product name.
    'REEN DUGNAD': 'ÆREND',
    'Reen Dugnad': 'Ærend',

    // Legacy Hare brand.
    'Hare App': 'Ærend',
    'Hare app': 'Ærend',
    'HareApp': 'Ærend',
    'the Hare': 'Ærend',
    'with Hare': 'with Ærend',

    // Legacy generic product label.
    'Food Delivery': 'Ærend',
    'food delivery': 'Ærend',
  };
  phrases.forEach((from, to) {
    out = out.replaceAll(from, to);
  });

  // Standalone brand tokens (HTML-safe word edges). The lookaround excludes
  // identifiers and compounds — "share", "Shared", "hare.io", "HareCustomer",
  // "ReenPreClub", "prefReenSportsMode", "aerend_customer" are all left alone.
  // Norwegian genitive of the standalone product name — before bare `Reen`.
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])Reens(?![A-Za-z0-9_])'),
    (_) => 'Ærends',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])Reen(?![A-Za-z0-9_])'),
    (_) => 'Ærend',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])REEN(?![A-Za-z0-9_])'),
    (_) => 'ÆREND',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])Hare(?![A-Za-z0-9_])'),
    (_) => 'Ærend',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])HARE(?![A-Za-z0-9_])'),
    (_) => 'ÆREND',
  );
  // Normalize the ASCII spelling of the brand to the canonical one.
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])Aerend(?![A-Za-z0-9_])'),
    (_) => 'Ærend',
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9_])AEREND(?![A-Za-z0-9_])'),
    (_) => 'ÆREND',
  );

  return out;
}
