import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Utforsk feed's line icons, verbatim from `Ærend Kunde Bergen.dc.html`
/// (`#g-alle`, `#g-pizza`, `#g-fiskikon`, `#g-bok`, `#g-blad`, `#g-plagg`, and
/// the inline SVGs on the segment control, the post card rail and the CTA).
///
/// Kept as strings rather than assets so a category orb and its icon ship in
/// one file, and so the stroke colour can follow the design's per-state value.
abstract final class FeedIcons {
  static const String _open =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">';
  static const String _close = '</svg>';

  // ── Category orbs (design `STORIES`) ────────────────────────────────────
  static const String alle =
      '$_open<rect x="3.5" y="3.5" width="7" height="7" rx="2"/><rect x="13.5" y="3.5" width="7" height="7" rx="2"/><rect x="3.5" y="13.5" width="7" height="7" rx="2"/><rect x="13.5" y="13.5" width="7" height="7" rx="2"/>$_close';
  static const String restaurant =
      '$_open<path d="M12 4l8 15H4z"/><circle cx="10" cy="13" r="1.2"/><circle cx="14" cy="15.5" r="1.2"/>$_close';
  static const String fisk =
      '$_open<path d="M4 12c4-5 10-6 13-3 1 1 2 2 3 3-1 1-2 2-3 3-3 3-9 2-13-3z"/><path d="M20 12l2.5-2.5v5z"/>$_close';
  static const String bakeri =
      '$_open<path d="M4 5h7a2 2 0 0 1 2 2v13H6a2 2 0 0 1-2-2z"/><path d="M20 5h-7a2 2 0 0 0-2 2v13h7a2 2 0 0 0 2-2z"/>$_close';
  static const String gront =
      '$_open<path d="M19 5C11 5 5 9 5 16c0 2 1 3 3 3 7 0 11-6 11-14z"/><path d="M8 18C10 13 13 10 17 8"/>$_close';
  static const String mote =
      '$_open<path d="M9 4l3 2 3-2 5 3-2 4-2-1v10H8V10L6 11 4 7z"/>$_close';

  static String orb(String slug) => switch (slug) {
    'restaurant' => restaurant,
    'fisk' => fisk,
    'bakeri' => bakeri,
    'gront' => gront,
    'mote' => mote,
    _ => alle,
  };

  // ── Segment control ─────────────────────────────────────────────────────
  static const String segFeed =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linejoin="round"><rect x="3.5" y="4.5" width="17" height="15" rx="3"/><path d="M7 9h6M7 13h10M7 16.5h7"/></svg>';
  static const String segFiske =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v8a4 4 0 0 0 8 0"/><circle cx="12" cy="3" r="1.4" fill="#FFFFFF"/></svg>';
  static const String segPose =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linejoin="round"><path d="M5 8.5h14l-1 11.5H6zM9 8.5V6a3 3 0 0 1 6 0v2.5"/></svg>';

  // ── Post card ───────────────────────────────────────────────────────────
  static String heart({required bool filled}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${filled ? '#F26D3D' : 'none'}" stroke="#FFFFFF" stroke-width="1.9" stroke-linejoin="round"><path d="M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z"/></svg>';
  static const String comment =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linejoin="round"><path d="M20 12a8 8 0 1 1-3.4-6.5"/><path d="M4.5 19.5l1.2-3.6M20 4.5v5h-5"/></svg>';
  static const String share =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15V4M7.5 8.5L12 4l4.5 4.5M5 14v5h14v-5"/></svg>';
  static const String play =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFFFFF"><path d="M8 5v14l11-7z"/></svg>';
  static const String chevron =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.55)" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5l7 7-7 7"/></svg>';
  static const String clock =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#5CE0B8" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v5l3 2"/><circle cx="12" cy="12" r="9"/></svg>';
  static const String bag =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8h12l-1 12H7zM9 8V6.5a3 3 0 0 1 6 0V8"/></svg>';
  static const String close =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#5CE0B8" stroke-width="3.2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>';
}

/// One of the strings above at a size, optionally recoloured.
Widget feedIcon(String svg, double size, {Color? color}) => SvgPicture.string(
  svg,
  width: size,
  height: size,
  colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
);
