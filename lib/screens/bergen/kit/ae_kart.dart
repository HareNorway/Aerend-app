import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/ops/kart_models.dart';

/// 2026-11-14 (manager): the real map in the drawn maps' clothes — Kassen's pickup «Se fullt kart» (light, as the
/// drawn sheet: cream land, white streets, the soft blue water) and Sporing's «På vei» card (the evening). The orange
/// route with its teal halo, the orange pin with its rings, «Du er her», and Ægil on the bike or in the van are the
/// drawn maps' own marks, painted into marker bitmaps here.
enum AeKartStil { lys, kveld }

class AeKart extends StatefulWidget {
  const AeKart({
    super.key,
    required this.data,
    this.stil = AeKartStil.lys,
    this.du,
    this.duLabel = 'Du er her',
    this.maalLabel,
    this.rider,
    this.riderVan = false,
    this.interaktiv = false,
    this.padding = 46,
    this.bunn = 0,
  });

  final AeKartData data;
  final AeKartStil stil;

  /// The customer's own position (pickup: the walk starts here).
  final AePunkt? du;
  final String duLabel;

  /// The pin's label: the store (pickup) or the door (delivery).
  final String? maalLabel;

  /// Ægil's place (the courier, or an estimate along the road).
  final AePunkt? rider;
  final bool riderVan;

  /// Pan and zoom (the full-map sheet); the Sporing card is a live picture.
  final bool interaktiv;
  final double padding;

  /// A share of the route's height kept free at the bottom (Sporing: the panel covers the card's lower part).
  final double bunn;

  /// Off in widget tests (no platform view there; `flutter test` sets FLUTTER_TEST): the callers keep their drawn
  /// maps then. Tests that want the real path set it.
  static bool aktiv = kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  @override
  State<AeKart> createState() => _AeKartState();
}

class _AeKartState extends State<AeKart> {
  GoogleMapController? _c;
  Set<Marker> _markers = const {};
  int _versjon = 0;

  AePunkt? get _maal => widget.data.door ?? widget.data.store;

  @override
  void initState() {
    super.initState();
    _lagMarkers();
  }

  @override
  void didUpdateWidget(AeKart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data || old.rider != widget.rider || old.du != widget.du) {
      _lagMarkers();
      _tilpass();
    }
  }

  Future<void> _lagMarkers() async {
    final v = ++_versjon;
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final m = <Marker>{};
    final maal = _maal;
    if (maal != null) {
      m.add(Marker(
        markerId: const MarkerId('maal'),
        position: LatLng(maal.$1, maal.$2),
        icon: await AeKartMerker.pin(dpr, label: widget.maalLabel),
        anchor: const Offset(.5, 1),
        zIndexInt: 2,
      ));
    }
    // Delivery: the store where the road begins (a small white disc with the orange ring).
    if (widget.data.door != null && widget.data.store != null) {
      final s = widget.data.store!;
      m.add(Marker(markerId: const MarkerId('butikk'), position: LatLng(s.$1, s.$2), icon: await AeKartMerker.butikk(dpr), anchor: const Offset(.5, .5), zIndexInt: 1));
    }
    if (widget.du != null) {
      m.add(Marker(
        markerId: const MarkerId('du'),
        position: LatLng(widget.du!.$1, widget.du!.$2),
        icon: await AeKartMerker.du(dpr, widget.duLabel),
        anchor: const Offset(.5, .2),
        zIndexInt: 3,
      ));
    }
    if (widget.rider != null) {
      m.add(Marker(
        markerId: const MarkerId('aegil'),
        position: LatLng(widget.rider!.$1, widget.rider!.$2),
        icon: await AeKartMerker.aegil(dpr, van: widget.riderVan),
        anchor: Offset(.5, widget.riderVan ? .92 : .88),
        zIndexInt: 4,
      ));
    }
    if (!mounted || v != _versjon) return;
    setState(() => _markers = m);
  }

  List<LatLng> get _alle => [
    for (final p in widget.data.route) LatLng(p.$1, p.$2),
    if (_maal case final p?) LatLng(p.$1, p.$2),
    if (widget.data.store case final p?) LatLng(p.$1, p.$2),
    if (widget.du case final p?) LatLng(p.$1, p.$2),
    if (widget.rider case final p?) LatLng(p.$1, p.$2),
  ];

  void _tilpass() {
    final c = _c;
    final pts = _alle;
    if (c == null || pts.isEmpty) return;
    if (pts.length == 1 || pts.every((p) => (p.latitude - pts.first.latitude).abs() < 1e-5 && (p.longitude - pts.first.longitude).abs() < 1e-5)) {
      unawaited(c.moveCamera(CameraUpdate.newLatLngZoom(pts.first, 16)));
      return;
    }
    var s = pts.first.latitude, n = s, w = pts.first.longitude, e = w;
    for (final p in pts) {
      s = math.min(s, p.latitude);
      n = math.max(n, p.latitude);
      w = math.min(w, p.longitude);
      e = math.max(e, p.longitude);
    }
    // The pin and its label stand above their point: leave them room at the top (the bounds' padding is the same
    // on every side, so stretch the north edge by a share of the height).
    final ekstra = (n - s) * .28;
    unawaited(c.moveCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(s - (n - s) * widget.bunn, w), northeast: LatLng(n + ekstra, e)), widget.padding)));
  }

  @override
  Widget build(BuildContext context) {
    final rute = [for (final p in widget.data.route) LatLng(p.$1, p.$2)];
    final maal = _maal;
    final start = _alle.isEmpty ? const LatLng(60.3929, 5.3241) : _alle.first;
    final kveld = widget.stil == AeKartStil.kveld;
    return GoogleMap(
      key: const Key('ae-kart'),
      initialCameraPosition: CameraPosition(target: start, zoom: 15),
      style: kveld ? AeKartStiler.kveld : AeKartStiler.lys,
      markers: _markers,
      polylines: {
        if (rute.length >= 2) ...{
          // The halo under the route (the drawn maps' rgba(30,79,92,.2) at 10 px), then the orange line.
          Polyline(polylineId: const PolylineId('halo'), points: rute, width: 11, color: kveld ? const Color(0x5C0B2A30) : const Color(0x331E4F5C), jointType: JointType.round, startCap: Cap.roundCap, endCap: Cap.roundCap, zIndex: 1),
          Polyline(polylineId: const PolylineId('rute'), points: rute, width: 5, color: const Color(0xFFF26D3D), jointType: JointType.round, startCap: Cap.roundCap, endCap: Cap.roundCap, zIndex: 2),
        },
      },
      circles: {
        // The rings at the goal (`ringUt`), held still: two soft orange circles.
        if (maal != null) ...{
          Circle(circleId: const CircleId('ring1'), center: LatLng(maal.$1, maal.$2), radius: 28, strokeWidth: 2, strokeColor: const Color(0x80F26D3D), fillColor: const Color(0x14F26D3D)),
          Circle(circleId: const CircleId('ring2'), center: LatLng(maal.$1, maal.$2), radius: 55, strokeWidth: 1, strokeColor: const Color(0x40F26D3D), fillColor: Colors.transparent),
        },
      },
      onMapCreated: (c) {
        _c = c;
        // Once the map has a size.
        WidgetsBinding.instance.addPostFrameCallback((_) => _tilpass());
        Future<void>.delayed(const Duration(milliseconds: 350), () => mounted ? _tilpass() : null);
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      buildingsEnabled: false,
      indoorViewEnabled: false,
      trafficEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      scrollGesturesEnabled: widget.interaktiv,
      zoomGesturesEnabled: widget.interaktiv,
      liteModeEnabled: false,
    );
  }
}

/// The drawn maps' palettes as Google map styles.
abstract final class AeKartStiler {
  /// Kassen's drawn map: land #EEEAE2, houses #D9D3C7, streets #FBFAF6, water #8FBFCB, trees #3E6E58 at .55.
  static const String lys = '''
[
  {"elementType":"geometry","stylers":[{"color":"#eeeae2"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6e6862"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f3ef"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#e2ddd3"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#d9d3c7"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#cfdccb"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#fbfaf6"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e3ddd1"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8c847c"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#8fbfcb"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#7aaebb"}]}
]''';

  /// Sporing's evening map: the night scene's slate land, lit streets, deep Vågen.
  static const String kveld = '''
[
  {"elementType":"geometry","stylers":[{"color":"#2b4049"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#bbd3d9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1c3039"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#33505a"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#3d5d67"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#2f4a44"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#56727a"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#22363e"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#d6e6ea"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#6b8890"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#173f4a"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#8fb3bc"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#0f2d36"}]}
]''';
}

/// The drawn maps' marks as marker bitmaps (logical size × the screen's pixel ratio), made once.
abstract final class AeKartMerker {
  static final Map<String, Future<BitmapDescriptor>> _cache = {};

  static Future<BitmapDescriptor> _tegn(String key, double dpr, Size size, void Function(Canvas c) paint) =>
      _cache.putIfAbsent('$key@$dpr', () async {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        c.scale(dpr);
        paint(c);
        final img = await rec.endRecording().toImage((size.width * dpr).ceil(), (size.height * dpr).ceil());
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
      });

  static TextPainter _tekst(String s, {double size = 10, Color color = const Color(0xFFF5F3EF), double maxW = 180}) =>
      TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter')),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxW);

  /// The drawn pin (`M14 30 C14 30 26 19 26 11 A12 12 0 1 0 2 11 …`, orange, white rim and dot), optionally with its
  /// dark label above (the drawn map's «Red Sun · Kong Oscars gate 4»). Anchor: the pin's tip (bottom centre).
  static Future<BitmapDescriptor> pin(double dpr, {String? label}) {
    final tp = label == null || label.isEmpty ? null : _tekst(label, size: 9.5);
    final lw = tp == null ? 0.0 : tp.width + 16;
    final lh = tp == null ? 0.0 : 22.0;
    final w = math.max(32.0, lw);
    final h = 36 + lh;
    return _tegn('pin:$label', dpr, Size(w, h), (c) {
      if (tp != null) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH((w - lw) / 2, 0, lw, 18), const Radius.circular(8));
        c.drawRRect(r.shift(const Offset(0, 1.5)), Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
        c.drawRRect(r, Paint()..color = const Color(0xD123201D));
        tp.paint(c, Offset((w - tp.width) / 2, (18 - tp.height) / 2));
      }
      c.save();
      c.translate((w - 28) / 2 + 0, lh + 3);
      final naal = Path()
        ..moveTo(14, 30)
        ..cubicTo(14, 30, 26, 19, 26, 11)
        ..arcToPoint(const Offset(2, 11), radius: const Radius.circular(12), largeArc: true, clockwise: false)
        ..cubicTo(2, 19, 14, 30, 14, 30)
        ..close();
      c.drawPath(naal.shift(const Offset(0, 2)), Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      c.drawPath(naal, Paint()..color = const Color(0xFFF26D3D));
      c.drawPath(naal, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round);
      c.drawCircle(const Offset(14, 11), 4.4, Paint()..color = Colors.white);
      c.restore();
    });
  }

  /// «Du er her»: the teal dot with its white rim, and the teal label under it. Anchor ≈ the dot.
  static Future<BitmapDescriptor> du(double dpr, String label) {
    final tp = _tekst(label, size: 9.5);
    final lw = tp.width + 16;
    final w = math.max(22.0, lw);
    return _tegn('du:$label', dpr, Size(w, 46), (c) {
      final cx = w / 2;
      c.drawCircle(Offset(cx, 10), 12, Paint()..color = const Color(0x331E4F5C));
      c.drawCircle(Offset(cx, 10), 7, Paint()..color = const Color(0xFF1E4F5C));
      c.drawCircle(Offset(cx, 10), 7, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH((w - lw) / 2, 25, lw, 18), const Radius.circular(8));
      c.drawRRect(r, Paint()..color = const Color(0xFF1E4F5C));
      tp.paint(c, Offset((w - tp.width) / 2, 25 + (18 - tp.height) / 2));
    });
  }

  /// The store where the road begins: a white disc with the orange ring and the teal dot.
  static Future<BitmapDescriptor> butikk(double dpr) => _tegn('butikk', dpr, const Size(22, 22), (c) {
    c.drawCircle(const Offset(11, 11), 9, Paint()..color = Colors.white);
    c.drawCircle(const Offset(11, 11), 9, Paint()..color = const Color(0xFFF26D3D)..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(const Offset(11, 11), 3.5, Paint()..color = const Color(0xFF1E4F5C));
  });

  /// Ægil on the bike (76², anchored 50 % 88 %) or in the van (86 × 56, 50 % 92 %), with the soft shadow under him.
  static Future<BitmapDescriptor> aegil(double dpr, {bool van = false}) => _cache.putIfAbsent('aegil:$van@$dpr', () async {
    final w = van ? 86.0 : 64.0, h = van ? 56.0 : 64.0;
    final data = await rootBundle.load(van ? 'assets/images/dashboard/van.png' : 'assets/images/aegil/bike.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: (w * dpr).round());
    final img = (await codec.getNextFrame()).image;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final W = w * dpr, H = h * dpr;
    c.drawOval(Rect.fromCenter(center: Offset(W / 2, H * .9), width: W * .5, height: 6 * dpr), Paint()..color = const Color(0x55000000)..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * dpr));
    final scale = W / img.width;
    final ih = img.height * scale;
    c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), Rect.fromLTWH(0, H - ih, W, ih), Paint()..filterQuality = FilterQuality.medium);
    final out = await rec.endRecording().toImage(W.ceil(), H.ceil());
    final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  });
}
