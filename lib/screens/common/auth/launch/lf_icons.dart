import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ── Launch onboarding · icons ───────────────────────────────────────────────
// The prototype's inline SVGs, verbatim (viewBox, paths, stroke widths).

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// A 24×24 stroke icon (`fill="none" stroke-linecap="round"`).
class LfStroke extends StatelessWidget {
  const LfStroke(
    this.d, {
    super.key,
    required this.size,
    required this.color,
    this.width = 2,
    this.join = true,
    this.extra = '',
    this.viewBox = '0 0 24 24',
    this.h,
  });

  final String d;
  final double size;
  final double? h;
  final Color color;
  final double width;
  final bool join;
  final String extra;
  final String viewBox;

  @override
  Widget build(BuildContext context) {
    final lj = join ? ' stroke-linejoin="round"' : '';
    final paths = d.isEmpty ? '' : '<path d="$d"/>';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox" fill="none" '
      'stroke="${_hex(color)}" stroke-opacity="${color.a}" stroke-width="$width" '
      'stroke-linecap="round"$lj>$paths$extra</svg>',
      width: size,
      height: h ?? size,
    );
  }
}

abstract final class LfIco {
  static const arrowRight = 'M5 12h14M13 6l6 6-6 6';
  static const check = 'M20 7L9 18l-5-5';
  static const checkLest = 'M5 12l5 5 9-10';
  static const chevronRight = 'M9 5.5l6.5 6.5-6.5 6.5';
  static const chevronLeft = 'M15 6l-6 6 6 6';
  static const plus = 'M12 5v14M5 12h14';
  static const pencil = 'M4 20l5-1 10-10-4-4L5 15z';
  static const kickOff = 'M5 19L19 5M11 5h8v8';
  static const store = 'M4 10h16l-1.5-5h-13zM5 10v10h14V10M10 20v-5h4v5';
  static const bikeExtra =
      '<circle cx="6" cy="17" r="3"/><circle cx="18" cy="17" r="3"/>'
      '<path d="M6 17l4-8h5l3 8M10 9l-1-3H7M15 9h3"/>';
  static const star =
      'M12 3l2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.4 6.7 19.4l1.2-6L3.4 9.3l6-.7z';
  static const userExtra =
      '<circle cx="12" cy="8" r="3.6"/><path d="M4.5 20c1.2-3.8 4-5.8 7.5-5.8s6.3 2 7.5 5.8"/>';
  static const mailExtra =
      '<rect x="3" y="5.5" width="18" height="13" rx="3"/><path d="M4 8l8 5.5L20 8"/>';
  static const lockExtra =
      '<rect x="4" y="10.5" width="16" height="10" rx="3"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>';
  static const searchExtra =
      '<circle cx="11" cy="11" r="7"/><path d="M16.5 16.5L21 21"/>';
  static const ticketExtra =
      '<path d="M3.5 8.5V6a1.5 1.5 0 0 1 1.5-1.5h14A1.5 1.5 0 0 1 20.5 6v2.5a2.5 2.5 0 0 0 0 5V18a1.5 1.5 0 0 1-1.5 1.5H5A1.5 1.5 0 0 1 3.5 18v-4.5a2.5 2.5 0 0 0 0-5z"/>'
      '<path d="M14 4.5v15" stroke-dasharray="2 2.5"/>';
}

/// Google "G" (18×18).
const String kLfGoogleSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M21.6 12.2c0-.7-.06-1.37-.18-2H12v3.8h5.4a4.62 4.62 0 0 1-2 3.03v2.5h3.22c1.88-1.73 2.98-4.28 2.98-7.33z" fill="#4285F4"/>'
    '<path d="M12 22c2.7 0 4.96-.9 6.62-2.43l-3.22-2.5c-.9.6-2.04.95-3.4.95a5.98 5.98 0 0 1-5.62-4.13H3.04v2.6A10 10 0 0 0 12 22z" fill="#34A853"/>'
    '<path d="M6.38 13.89a6 6 0 0 1 0-3.78v-2.6H3.04a10 10 0 0 0 0 8.98l3.34-2.6z" fill="#FBBC05"/>'
    '<path d="M12 6.18c1.47 0 2.79.5 3.83 1.5l2.85-2.85A9.6 9.6 0 0 0 12 2a10 10 0 0 0-8.96 5.51l3.34 2.6A5.98 5.98 0 0 1 12 6.18z" fill="#EA4335"/>'
    '</svg>';

/// Apple logo (16×18).
const String kLfAppleSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 24" fill="#0F1F2B">'
    '<path d="M14.6 12.7c0-2.5 2-3.7 2.1-3.8-1.1-1.7-2.9-1.9-3.5-1.9-1.5-.1-2.8.9-3.5.9s-1.9-.9-3.1-.8C4.8 7.2 3 8.4 2 10.4c-1.1 2-.7 5.7 1 8.4.8 1.3 1.9 2.8 3.3 2.7 1.3 0 1.8-.8 3.4-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.2-2.6.9-1.4 1.3-2.7 1.3-2.8-.1 0-2.9-1.2-3-4.4zM12.2 4.9c.7-.9 1.2-2 1-3.2-1 0-2.3.7-3 1.5-.7.8-1.2 2-1.1 3.1 1.1.1 2.3-.6 3.1-1.4z"/>'
    '</svg>';

/// Vilkår document tile glyph (30×30, viewBox 32).
const String kLfDocSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
    '<path d="M8 4h11l6 6v17a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z" fill="#A63A12" transform="translate(.8 1.2)"/>'
    '<path d="M8 4h11l6 6v17a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z" fill="#FFFFFF"/>'
    '<path d="M19 4v4.5A1.5 1.5 0 0 0 20.5 10H25z" fill="#FFD9C6"/>'
    '<path d="M10 14h11M10 18h11M10 22h7" stroke="#F26D3D" stroke-width="2" stroke-linecap="round"/>'
    '</svg>';

/// Personvern shield tile glyph (30×30, viewBox 32).
const String kLfShieldSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
    '<path d="M16 3l10 4v8c0 6.4-4.2 11.6-10 13.6C10.2 26.6 6 21.4 6 15V7z" fill="#23946F" transform="translate(.8 1.2)"/>'
    '<path d="M16 3l10 4v8c0 6.4-4.2 11.6-10 13.6C10.2 26.6 6 21.4 6 15V7z" fill="#1E4F5C"/>'
    '<path d="M16 3v25.6C10.2 26.6 6 21.4 6 15V7z" fill="#2A6272"/>'
    '<path d="M11.5 15.5l3.2 3.2 6-6.6" fill="none" stroke="#7FF0CB" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>'
    '</svg>';

/// `#merke-ink` (the coin's embossed Æ), drawn in [color].
String lfMerkeInk(Color color) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-30 -14 172 138">'
    '<g transform="rotate(-5 60 53)">'
    '<path d="M14 90 L60 16 V90 M34 58 H60 M62 16 H104 M62 53 H96 M62 90 H104" fill="none" stroke="${_hex(color)}" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M-14 60 H8 M-8 76 H4" fill="none" stroke="#F26D3D" stroke-width="6.5" stroke-linecap="round"/>'
    '</g></svg>';

class LfSvg extends StatelessWidget {
  const LfSvg(this.svg, {super.key, required this.w, required this.h});

  final String svg;
  final double w;
  final double h;

  @override
  Widget build(BuildContext context) => SvgPicture.string(svg, width: w, height: h);
}

class LfSvgAsset extends StatelessWidget {
  const LfSvgAsset(this.name, {super.key, required this.w, required this.h});

  /// File under `assets/svgs/onboarding/` without `.svg`.
  final String name;
  final double w;
  final double h;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/svgs/onboarding/$name.svg', width: w, height: h);
}
