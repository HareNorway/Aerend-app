import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/ops/butikk_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../aegil/aegil_bits.dart' show AeIkon;
import '../kit/svg_sti.dart';
import '../meg/meg_ark.dart';

abstract final class HentKartCopy {
  static const String duErHer = 'Du er her';
  static const String henterSelv = 'Du henter selv i disken.';
  static String aapentTil(String kl) => 'Åpent til $kl.';
  static String aapner(String kl) => 'Stengt nå · åpner $kl.';
  static const String veibeskrivelse = 'Veibeskrivelse';
  static String gaa(int min, String avstand) => '$min min å gå · $avstand';
}

/// «Se fullt kart» on Kassen's pickup row (`kArk kart`, L18984 / L9339):
/// the drawn map of the way to the shop (the route drawing itself, `rute 8s`,
/// and the rings at the shop, `ringUt 2.6s`), «Du er her», the shop and its
/// street, how far it is to walk, and the two keys: «Veibeskrivelse» (the
/// phone's maps, walking) and the round call key (only with a number).
Future<void> visHentKart(BuildContext context, {required BergenStoreInfo store}) {
  final gate = (store.address ?? '').split(',').first.trim();
  final navn = gate.isEmpty ? store.name : '${store.name} · $gate';
  String? kl(String? t) => t == null || t.length < 5 ? null : t.substring(0, 5);
  final stenger = kl(store.closeTime), aapner = kl(store.openTime);
  // Open: until when; closed: when it opens (as Kassen's own row says).
  final tid = store.open ? (stenger == null ? null : HentKartCopy.aapentTil(stenger)) : (aapner == null ? null : HentKartCopy.aapner(aapner));
  return showMegArk<void>(
    context,
    key: const Key('hent-kart'),
    title: navn,
    subtitle: [HentKartCopy.henterSelv, ?tid].join(' '),
    body: (ctx, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Kart(butikk: navn, gaa: _gaa(store.distanceKm)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LfPress(
                key: const Key('hent-kart-vei'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _veibeskrivelse(store.address ?? store.name);
                },
                dy: 2.5,
                scale: 1,
                child: CssBox(
                  height: 48,
                  radius: BorderRadius.all(Radius.circular(999)),
                  bg: const [CssLinear(165, [Color(0xFF2A6272), Color(0xFF1E4F5C)])],
                  shadows: const [
                    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
                    CssShadow(0, 3, 0, 0, Color.fromRGBO(11, 38, 45, .9)),
                    CssShadow(0, 10, 15, -8, Color.fromRGBO(15, 45, 55, .8)),
                  ],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AeIkon('M12 2.5 21.5 12 12 21.5 2.5 12zM9.5 14v-2.6a2 2 0 0 1 2-2H15M13 7.6 15.4 9.4 13 11.2', size: 16, stroke: 2.2, color: Colors.white),
                      const SizedBox(width: 7),
                      Text(HentKartCopy.veibeskrivelse, style: inter(13.5, weight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            if ((store.contactNumber ?? '').trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              LfPress(
                key: const Key('hent-kart-ring'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  launchUrl(Uri(scheme: 'tel', path: store.contactNumber!.replaceAll(RegExp(r'[^0-9+]'), '')));
                },
                dy: 2.5,
                scale: 1,
                child: const CssBox(
                  width: 56,
                  height: 48,
                  radius: BorderRadius.all(Radius.circular(999)),
                  bg: [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF1ECE1)])],
                  shadows: [
                    CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .95)),
                    CssShadow(0, 2, 0, 0, Color(0xFFD9D2C4)),
                    CssShadow(0, 3.5, 0, 0, Color.fromRGBO(90, 74, 48, .32)),
                    CssShadow(0, 9, 14, -8, Color.fromRGBO(35, 32, 29, .5)),
                  ],
                  child: Center(
                    child: AeIkon('M5.5 4.5h4l2 5-2.5 1.5a10 10 0 0 0 4.5 4.5L15 17l5 2v4h-1A15.5 15.5 0 0 1 3.5 7.5v-3z', size: 17, stroke: 2, color: Color(0xFF1B4A57)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

/// «N min å gå · 400 m» at the prototype's walking pace (400 m in 5 min);
/// nothing without a distance.
String? _gaa(double? km) {
  if (km == null || km <= 0) return null;
  final m = (km * 1000 / 50).round() * 50;
  final min = math.max(1, (km * 1000 / 80).ceil());
  final avstand = m < 1000 ? '${math.max(50, m)} m' : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return HentKartCopy.gaa(min, avstand);
}

/// The phone's own maps, walking to the shop's address.
void _veibeskrivelse(String adresse) {
  final q = Uri.encodeComponent(adresse);
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final url = ios ? 'https://maps.apple.com/?daddr=$q&dirflg=w' : 'https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=walking';
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class _Kart extends StatelessWidget {
  const _Kart({required this.butikk, required this.gaa});

  final String butikk;
  final String? gaa;

  static final TextStyle _merke = inter(9.5, weight: FontWeight.w800, color: const Color(0xFFF5F3EF));

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: const BorderRadius.all(Radius.circular(22)),
      bg: const [CssSolid(Color(0xFFEEEAE2))],
      shadows: const [
        CssShadow.inset(0, 2, 0, 0, Color.fromRGBO(255, 255, 255, .9)),
        CssShadow(0, 20, 34, -20, Color.fromRGBO(15, 31, 43, .55)),
      ],
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: AspectRatio(
          aspectRatio: 362 / 360,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: LfLoop(
                  // Rests on the drawn route in the calm tiers.
                  frozenMs: 8300,
                  builder: (context, t, _) => CustomPaint(painter: _KartMaler(t)),
                ),
              ),
              Positioned(
                left: 44,
                bottom: 12,
                child: _Lapp(bg: const Color(0xFF1E4F5C), child: Text(HentKartCopy.duErHer, style: _merke)),
              ),
              Positioned(
                right: 12,
                top: 14,
                child: _Lapp(bg: const Color.fromRGBO(35, 32, 29, .82), child: Text(butikk, style: _merke)),
              ),
              if (gaa != null)
                Positioned(
                  left: 12,
                  top: 14,
                  child: CssBox(
                    radius: const BorderRadius.all(Radius.circular(999)),
                    bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .9))],
                    shadows: const [CssShadow(0, 6, 12, -7, Color.fromRGBO(15, 31, 43, .6))],
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AeIkon('M15 4.2a2 2 0 1 1-4 0 2 2 0 0 1 4 0zM14.4 8.2 10.6 10 9 14.2l3.4 1.6 1.2 5.4M10.6 10 7 12.6M12.4 15.8 9 20.6', size: 12, stroke: 2, color: Color(0xFFB8501F)),
                        const SizedBox(width: 6),
                        Text(gaa!, style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFF23201D))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Lapp extends StatelessWidget {
  const _Lapp({required this.bg, required this.child});
  final Color bg;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: child),
  );
}

/// The map's SVG (viewBox 0 0 362 360), with `rute 8s .3s ease-in-out` on
/// the orange route and two `ringUt 2.6s ease-out` rings, 1.3 s apart.
class _KartMaler extends CustomPainter {
  _KartMaler(this.ms);

  final double ms;

  static final Path _vann = svgSti('M226 -10 C236 40 256 70 300 92 C330 106 350 118 362 128 V-10 Z M150 262 L172 244 L212 244 L234 262 L212 280 L172 280 Z');
  static const List<Rect> _hus = [
    Rect.fromLTWH(20, 40, 70, 56), Rect.fromLTWH(110, 30, 56, 60), Rect.fromLTWH(190, 110, 60, 50), Rect.fromLTWH(40, 130, 80, 60),
    Rect.fromLTWH(250, 176, 60, 70), Rect.fromLTWH(290, 270, 60, 60), Rect.fromLTWH(150, 310, 90, 46), Rect.fromLTWH(20, 230, 70, 60),
  ];
  static final Path _gater = svgSti('M0 110 H180 M100 0 V360 M0 210 C60 206 120 200 190 200 M240 100 C250 170 260 250 250 360 M0 300 H150 M300 160 C280 240 270 320 330 360');
  static final Path _rute = svgSti('M68 330 C74 296 88 268 118 256 C150 244 165 230 180 204 C195 186 215 166 250 150 C280 136 300 110 300 70');
  static final Path _naal = svgSti('M14 30 C14 30 26 19 26 11 A12 12 0 1 0 2 11 C2 19 14 30 14 30 Z');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 362, size.height / 360);
    canvas.drawPath(_vann, Paint()..color = const Color(0xFF8FBFCB));
    final hus = Paint()..color = const Color(0xFFD9D3C7);
    for (final r in _hus) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), hus);
    }
    final tre = Paint()..color = const Color(0xFF3E6E58).withValues(alpha: .55);
    for (final (x, y, r) in const [(150.0, 240.0, 6.0), (236.0, 286.0, 6.0), (300.0, 60.0, 7.0), (120.0, 120.0, 5.0)]) {
      canvas.drawCircle(Offset(x, y), r, tre);
    }
    Paint strek(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_gater, strek(const Color(0xFFFBFAF6), 9));
    canvas.drawPath(_rute, strek(const Color.fromRGBO(30, 79, 92, .2), 10));
    // `rute`: stroke-dashoffset 100 → 0 of pathLength 100, 8 s from .3 s.
    final p = ((ms - 300) / 8000) % 1.0;
    final andel = ms < 300 ? 0.0 : cssEaseInOut.transform(p < 0 ? p + 1 : p);
    final m = _rute.computeMetrics().first;
    canvas.drawPath(m.extractPath(0, m.length * andel), strek(const Color(0xFFF26D3D), 4.5));
    // `ringUt`: scale .7 → 1.5, opacity .5 → 0, ease-out, twice.
    for (final d in const [0.0, 1300.0]) {
      if (ms < d) continue;
      final q = Curves.easeOut.transform(((ms - d) / 2600) % 1.0);
      final s = .7 + .8 * q;
      canvas.drawCircle(const Offset(300, 70), 16 * s, strek(const Color(0xFFF26D3D).withValues(alpha: .5 * (1 - q)), 2 * s));
    }
    canvas.drawCircle(const Offset(68, 330), 7, Paint()..color = const Color(0xFF1E4F5C));
    canvas.drawCircle(const Offset(68, 330), 7, strek(Colors.white, 3));
    canvas.save();
    canvas.translate(286, 52);
    canvas.drawPath(_naal, Paint()..color = const Color(0xFFF26D3D));
    canvas.drawPath(_naal, strek(Colors.white, 2.5)..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(const Offset(14, 11), 4.4, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KartMaler old) => old.ms != ms;
}
