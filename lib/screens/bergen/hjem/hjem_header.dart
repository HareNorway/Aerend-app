import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;

// ── Hjem · header (`visKromOver`, L2217) ────────────────────────────────────
// `left:16px; right:16px; top:10px; height:56px`: the address chip
// (`Adresse-knapp`) and the bell. Design px.

/// The address chip's icon (`adrErHus` / `adrErJobb` / `adrErHytte`).
enum HjemAdrType { hjem, jobb, hytte, annet }

HjemAdrType hjemAdrType(String raw) {
  final t = raw.trim().toLowerCase();
  if (t == 'home' || t == 'hjem' || t == 'hjemme') return HjemAdrType.hjem;
  if (t == 'work' || t == 'jobb' || t == 'office') return HjemAdrType.jobb;
  if (t == 'hytte' || t == 'hytta' || t == 'cabin') return HjemAdrType.hytte;
  return HjemAdrType.annet;
}

class HjemHeader extends StatelessWidget {
  const HjemHeader({
    super.key,
    required this.address,
    required this.type,
    required this.eta,
    required this.unread,
    required this.onAddress,
    required this.onBell,
  });

  /// `adresseKort`; empty → `adrChipVelg` ("Velg adresse").
  final String address;
  final HjemAdrType type;

  /// Coverage ETA ("25–35 min") when the address is covered.
  final String? eta;
  final int unread;
  final VoidCallback onAddress;
  final VoidCallback onBell;

  static const List<CssShadow> _sh = [
    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
    CssShadow(0, 2, 0, 0, Color.fromRGBO(15, 45, 55, .9)),
    CssShadow(0, 10, 16, -9, Color.fromRGBO(15, 45, 55, .7)),
  ];
  static const CssLinear _bg = CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1]);

  String get _eyebrow {
    final m = switch (type) {
      HjemAdrType.hjem => 'hjem',
      HjemAdrType.jobb => 'jobb',
      HjemAdrType.hytte => 'hytta',
      HjemAdrType.annet => '',
    };
    final base = m.isEmpty ? 'Leverer til' : 'Leverer til $m';
    return (eta ?? '').isEmpty ? base : '$base · $eta';
  }

  @override
  Widget build(BuildContext context) {
    final velg = address.trim().isEmpty;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Endre leveringsadresse',
              child: LfPress(
                dy: 2,
                onTap: onAddress,
                child: CssBox(
                  height: 52,
                  radius: BorderRadius.circular(17),
                  bg: const [_bg],
                  shadows: _sh,
                  clip: true,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Row(
                    children: [
                      _icon(velg),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              velg ? 'Hvor skal ærendet?' : _eyebrow,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: inter(11, weight: FontWeight.w700, color: const Color(0xFF9FD3DE)),
                            ),
                            Text(
                              velg ? 'Velg adresse' : address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(16, em: -.02, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 11),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: const Color.fromRGBO(255, 255, 255, .1),
                          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.string(velg ? _kPluss : _kBlyant, width: velg ? 13 : 14, height: velg ? 13 : 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'Varsler',
            child: LfPress(
              scale: .93,
              onTap: onBell,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: CssBox(radius: BorderRadius.all(Radius.circular(999)), bg: [_bg], shadows: _sh),
                    ),
                    Center(child: SvgPicture.string(_kBjelle, width: 21, height: 21)),
                    // `vsPrikk` (1–2) / `vsTall` (3+).
                    if (unread > 0 && unread < 3)
                      Positioned(
                        top: 6,
                        right: 7,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF2C14E),
                            boxShadow: [BoxShadow(color: Color(0xFF173E48), spreadRadius: 2)],
                          ),
                        ),
                      ),
                    if (unread >= 3)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFF23201D),
                            boxShadow: const [BoxShadow(color: Colors.white, spreadRadius: 2)],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: inter(11, weight: FontWeight.w800, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(bool velg) {
    if (velg) {
      // Graph-paper tile with a dashed house drawing itself (`adrTegn`).
      return SizedBox(
        width: 38,
        height: 38,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(painter: _RuterPainter(), child: SvgPicture.string(_kVelgHus, width: 38, height: 38)),
        ),
      );
    }
    final svg = switch (type) {
      HjemAdrType.jobb => _kJobb,
      HjemAdrType.hytte => _kHytte,
      _ => _kHus,
    };
    return CssBox(
      width: 38,
      height: 38,
      radius: BorderRadius.circular(12),
      clip: true,
      bg: const [CssLinear(180, [Color(0xFF3E8697), Color(0xFF285F6E)])],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
        CssShadow(0, 1.5, 0, 0, Color.fromRGBO(6, 24, 32, .45)),
      ],
      child: SvgPicture.string(svg, width: 38, height: 38),
    );
  }
}

class _RuterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1B4A57));
    final p = Paint()..color = const Color.fromRGBO(159, 240, 212, .16);
    for (double v = 0; v < size.width; v += 8) {
      canvas.drawRect(Rect.fromLTWH(v, 0, 1, size.height), p);
      canvas.drawRect(Rect.fromLTWH(0, v, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const String _kHus =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 46 46">'
    '<rect x="12" y="21" width="22" height="18" fill="#3E8FA3"/>'
    '<rect x="12" y="21" width="22" height="18" fill="#04141C" fill-opacity=".12"/>'
    '<rect x="27" y="11" width="4" height="8" fill="#7A3E2C"/>'
    '<path d="M9 22.5L23 10l14 12.5Z" fill="#2B3A40"/>'
    '<path d="M8 23L23 9.5 38 23" fill="none" stroke="#F4EFE6" stroke-width="1.8" stroke-linejoin="round"/>'
    '<rect x="14.5" y="24" width="5" height="5" fill="#FFD27A" stroke="#F4EFE6" stroke-width="1"/>'
    '<rect x="26.5" y="24" width="5" height="5" fill="#BFFBE6" stroke="#F4EFE6" stroke-width="1"/>'
    '<rect x="20.5" y="30" width="5" height="9" fill="#E95C2C" stroke="#F4EFE6" stroke-width="1"/></svg>';

const String _kJobb =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 46 46">'
    '<rect x="13" y="9" width="20" height="30" rx="1.5" fill="#D4DCDE"/>'
    '<rect x="13" y="9" width="20" height="3" rx="1.5" fill="#A9B6BA"/>'
    '<rect x="16" y="15" width="5" height="4" fill="#BFF5E4"/><rect x="25" y="15" width="5" height="4" fill="#FFD27A"/>'
    '<rect x="16" y="22" width="5" height="4" fill="#FFD27A"/><rect x="25" y="22" width="5" height="4" fill="#BFF5E4"/>'
    '<rect x="19" y="31" width="8" height="8" fill="#2C5562"/>'
    '<circle cx="28" cy="7" r="1.4" fill="#FF6B5A"/></svg>';

const String _kHytte =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 46 46">'
    '<rect x="11" y="24" width="24" height="15" fill="#A8382A"/>'
    '<path d="M7.5 25L23 13l15.5 12Z" fill="#5E8C3A"/>'
    '<path d="M7 25.5L23 12.5 39 25.5" fill="none" stroke="#3D5E26" stroke-width="1.8" stroke-linejoin="round"/>'
    '<rect x="14" y="27" width="5" height="5" fill="#FFD27A" stroke="#F4EFE6" stroke-width="1"/>'
    '<rect x="20.5" y="30" width="5" height="9" fill="#2F5A3A" stroke="#F4EFE6" stroke-width="1"/>'
    '<rect x="38" y="13" width="1.2" height="26" fill="#E4E0D6"/>'
    '<path d="M39.2 14l6 1.6-6 1.6z" fill="#E95C2C"/></svg>';

const String _kVelgHus =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 46 46">'
    '<path d="M11 22L23 11.5 35 22v14H11z" fill="none" stroke="#9FF0D4" stroke-width="2" stroke-dasharray="3 2.5" stroke-linejoin="round"/></svg>';

const String _kBlyant =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#DCEFF3" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M4 20h4.2L19.4 8.8a2.4 2.4 0 0 0 0-3.4l-.8-.8a2.4 2.4 0 0 0-3.4 0L4 15.8z"/><path d="M13.5 6.5l4 4"/></svg>';

const String _kPluss =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#DCEFF3" stroke-width="2.8" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>';

const String _kBjelle =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M18 8.6a6 6 0 1 0-12 0c0 5.9-2.2 7.4-2.2 7.4h16.4S18 14.5 18 8.6z"/><path d="M10.3 19.6a2 2 0 0 0 3.4 0"/></svg>';
