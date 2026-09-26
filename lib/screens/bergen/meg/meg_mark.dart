import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Æ mark from the design's `#merke-ink` symbol (the tilted strokes with
/// the short orange bar), drawn in any ink — the medal on the Poeng card, the
/// Nivå row and the Gullbilletten ticket all use it.
class MegMark extends StatelessWidget {
  const MegMark({super.key, required this.color, this.size = 32, this.accent = const Color(0xFFF26D3D)});

  final Color color;
  final double size;
  final Color accent;

  static String _hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-30 -14 172 138">'
        '<g transform="rotate(-5 60 53)">'
        '<path d="M14 90 L60 16 V90 M34 58 H60 M62 16 H104 M62 53 H96 M62 90 H104" fill="none" stroke="${_hex(color)}" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>'
        '<path d="M-14 60 H8 M-8 76 H4" fill="none" stroke="${_hex(accent)}" stroke-width="6.5" stroke-linecap="round"/>'
        '</g></svg>';
    return SvgPicture.string(svg, width: size, height: size * 138 / 172);
  }
}
