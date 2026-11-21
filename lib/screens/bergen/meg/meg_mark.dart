import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Æ mark from the design's `#merke-ink` symbol (the tilted strokes with
/// the short orange bar), drawn in any ink — the medal on the Poeng card, the
/// Nivå row and the Gullbilletten ticket all use it.
class MegMark extends StatelessWidget {
  const MegMark({super.key, required this.color, this.size = 32, this.accent = const Color(0xFFF26D3D), this.medAksent = true, this.grav = false});

  final Color color;
  final double size;
  final Color accent;

  /// The short orange bar (the Gullbillett watermark has none).
  final bool medAksent;

  /// Design 21 Nov (`#merke-grav`): the engraved mark — a white stroke at .72 under the ink, offset 5 units down, a
  /// faint light stroke over it and a brighter accent — for the coins and medals.
  final bool grav;

  static String _hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    const d = 'M14 90 L60 16 V90 M34 58 H60 M62 16 H104 M62 53 H96 M62 90 H104';
    const a = 'M-14 60 H8 M-8 76 H4';
    final svg = grav
        ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-30 -14 172 138">'
            '<g transform="translate(0,5)"><g transform="rotate(-5 60 53)">'
            '<path d="$d" fill="none" stroke="#FFFFFF" stroke-opacity=".72" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>'
            '${medAksent ? '<path d="$a" fill="none" stroke="#FFFFFF" stroke-opacity=".72" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round"/>' : ''}'
            '</g></g>'
            '<g transform="rotate(-5 60 53)">'
            '<path d="$d" fill="none" stroke="${_hex(color)}" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>'
            '${medAksent ? '<path d="$a" fill="none" stroke="#C24A1C" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round"/>' : ''}'
            '</g>'
            '<g transform="translate(0,3.2)"><g transform="rotate(-5 60 53)">'
            '<path d="$d" fill="none" stroke="#FFF1C8" stroke-opacity=".24" stroke-width="8.4" stroke-linecap="round" stroke-linejoin="round"/>'
            '</g></g>'
            '${medAksent ? '<g transform="translate(0,1.4)"><g transform="rotate(-5 60 53)"><path d="$a" fill="none" stroke="#FF8F5C" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></g></g>' : ''}'
            '</svg>'
        : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-30 -14 172 138">'
            '<g transform="rotate(-5 60 53)">'
            '<path d="$d" fill="none" stroke="${_hex(color)}" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>'
            '${medAksent ? '<path d="$a" fill="none" stroke="${_hex(accent)}" stroke-width="6.5" stroke-linecap="round"/>' : ''}'
            '</g></svg>';
    return SvgPicture.string(svg, width: size, height: size * 138 / 172);
  }
}
