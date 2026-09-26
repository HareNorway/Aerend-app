import 'package:flutter/material.dart';

/// The design's art for each prize (Kunde Bergen `PREMIER`: `tint` at 160deg,
/// the 3D icon and its drawn size), keyed by `pts_prizes.slug`. Unknown slugs
/// fall back by name so a new catalogue row still gets a sensible tile.
class PrizeArt {
  const PrizeArt({required this.tint, required this.icon, required this.width, required this.height});

  final List<Color> tint;

  /// Asset under `assets/svgs/dashboard/` (without `.svg`).
  final String icon;
  final double width;
  final double height;

  LinearGradient get gradient => LinearGradient(begin: const Alignment(-.34, -.94), end: const Alignment(.34, .94), colors: tint);

  // The Hjem's own 3D assets where the design reuses the same drawing.
  static const _boat = ('longship3d', 96.0, 50.0);
  static const _mat = ('meg_ico_mat', 74.0, 70.0);
  static const _fisk = ('meg_ico_fisk', 100.0, 66.0);
  static const _gaver = ('meg_ico_gaver', 70.0, 74.0);
  static const _interior = ('meg_ico_interior', 64.0, 72.0);
  static const _pose = ('bag3d', 72.0, 72.0);
  static const _varde = ('meg_varde3d', 58.0, 72.0);

  static PrizeArt _a(int a, int b, (String, double, double) i) => PrizeArt(tint: [Color(a), Color(b)], icon: i.$1, width: i.$2, height: i.$3);

  static final Map<String, PrizeArt> _bySlug = {
    'gratis-levering': _a(0xFFDCE9EC, 0xFF7FA9B6, _boat),
    'kanelboller': _a(0xFFFBE9C4, 0xFFE9B76A, _mat),
    'sjokolade-bryggen': _a(0xFFF6DCC8, 0xFFC98A62, _gaver),
    'kaffepose': _a(0xFFE6D7BE, 0xFF9A7A4E, _pose),
    'klubbdonasjon': _a(0xFFCFE6D6, 0xFF3E6E58, _varde),
    'fiskesuppe': _a(0xFFCFE3E8, 0xFF6FA3B2, _fisk),
    'bok-om-bergen': _a(0xFFEDE4D2, 0xFFB7A283, _interior),
    'gratis-pizza': _a(0xFFFBE0C4, 0xFFDE8E4E, _mat),
    'keramikkrus': _a(0xFFE3E7E2, 0xFF8C9B92, _interior),
    'buket-sandviken': _a(0xFFF3DCE4, 0xFFC08196, _gaver),
    'floybanen': _a(0xFFDCE9EC, 0xFF5C8391, _varde),
    'middag-bryggen': _a(0xFFFBE0C4, 0xFFC07A3A, _mat),
    'baat-i-vaagen': _a(0xFFCFE3E8, 0xFF2B5F6D, _boat),
    'klistremerker': _a(0xFFEDE4D2, 0xFFB7A283, _gaver),
    'forundringspose': _a(0xFFE6D7BE, 0xFF9A7A4E, _pose),
  };

  /// "Ægil velger" (design `velger`): the deep teal tile with Ægil on it.
  static const List<Color> velgerTint = [Color(0xFF2A6272), Color(0xFF122F3A)];

  static PrizeArt of({String? slug, required String name}) {
    final bySlug = slug == null ? null : _bySlug[slug];
    if (bySlug != null) return bySlug;
    final n = name.toLowerCase();
    if (n.contains('båt') || n.contains('baat') || n.contains('levering')) return _a(0xFFCFE3E8, 0xFF2B5F6D, _boat);
    if (n.contains('fisk') || n.contains('reke') || n.contains('suppe')) return _a(0xFFCFE3E8, 0xFF6FA3B2, _fisk);
    if (n.contains('middag') || n.contains('pizza') || n.contains('bolle') || n.contains('mat')) return _a(0xFFFBE0C4, 0xFFC07A3A, _mat);
    if (n.contains('kaffe') || n.contains('pose')) return _a(0xFFE6D7BE, 0xFF9A7A4E, _pose);
    if (n.contains('bok') || n.contains('krus') || n.contains('keramikk')) return _a(0xFFEDE4D2, 0xFFB7A283, _interior);
    if (n.contains('gave') || n.contains('sjokolade') || n.contains('buket')) return _a(0xFFF6DCC8, 0xFFC98A62, _gaver);
    return _a(0xFFDCE9EC, 0xFF5C8391, _varde);
  }
}
