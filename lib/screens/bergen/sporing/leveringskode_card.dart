// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr/qr.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';

/// **Bud-identitet** (Launch L8995): the white glass pill with the
/// courier's initial, «{navn} · el-sykkel» and «BankID-verifisert» — or the
/// store's icon and «{butikk} leverer selv» for a partner delivery. The pill
/// never shows a courier identity for partner orders (spec §5).
class BudIdentitetPill extends StatelessWidget {
  const BudIdentitetPill({super.key, required this.tracking});

  final OpsTracking tracking;

  static String kjoretoy(OpsCourier c) => switch (c.vehicle) {
    'sykkel' => 'el-sykkel',
    'bil' => 'bil',
    final v? => v,
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final courier = tracking.isPartner ? null : tracking.courier;
    final partner = tracking.isPartner;
    final navn = partner ? SporingCopy.a1_sporing_leverer_selv(tracking.deliveredByLabel) : (courier?.firstName ?? SporingCopy.a1_sporing_Budet);
    final kj = courier == null ? '' : kjoretoy(courier);
    final tittel = kj.isEmpty ? navn : '$navn · $kj';
    final verifisert = partner || (courier?.verified ?? false);
    return LfOnce(
      key: const Key('a1_sporing_bud_pill'),
      ms: 340,
      builder: (context, t, child) {
        final p = cssSkjerm.transform(kfP(t, 0, 340));
        return Opacity(
          opacity: kf(p, const [0, .55, 1], const [0, 1, 1]),
          child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.978 + .022 * p, .978 + .022 * p, 1, 1), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
        decoration: BoxDecoration(
          color: rgba(255, 255, 255, .62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: rgba(255, 255, 255, .85)),
          boxShadow: [
            BoxShadow(color: rgba(8, 24, 32, .12), offset: const Offset(0, 2), blurRadius: 3, spreadRadius: -1),
            BoxShadow(color: rgba(8, 24, 32, .4), offset: const Offset(0, 12), blurRadius: 20, spreadRadius: -14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: partner
                    ? const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFF2A6272), Color(0xFF1E4F5C)])
                    : const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFFDCE9EC), Color(0xFF9FB6C2)]),
              ),
              child: Center(
                child: partner
                    ? spIkon(kSpIkonButikk, size: 15, color: const Color(0xFFF5F3EF), width: 2.2, key: const Key('a1_sporing_bud_store_icon'))
                    : Text(_initial(courier), style: jakarta(13, color: kSpTeal)),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tittel,
                  key: const Key('a1_sporing_bud_navn'),
                  style: inter(12, weight: FontWeight.w800, color: kSpInk),
                ),
                if (kj.isNotEmpty) SizedBox(key: const Key('a1_sporing_bud_kjoretoy'), width: 0, height: 0),
                if (verifisert)
                  Row(
                    key: const Key('a1_sporing_bud_verifisert'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      spIkon(kSpIkonSkjold, size: 10, color: const Color(0xFF2E7E4F), width: 3),
                      const SizedBox(width: 4),
                      Text(
                        SporingCopy.a1_sporing_bankid_verifisert,
                        style: inter(10, weight: FontWeight.w800, color: const Color(0xFF2E7E4F)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initial(OpsCourier? c) => (c?.firstName.isNotEmpty ?? false) ? c!.firstName[0].toUpperCase() : 'B';
}

/// Copy for the 21 Oct delivery-code card (Customer Step 2).
abstract final class CusKodeCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get cus_kode_bare_pin => _t('Bare PIN', 'PIN only');
  static String get cus_kode_vis_qr => _t('Vis QR', 'Show QR');
  static String cus_kode_skanner(String hvem) => _t('$hvem skanner, eller taster PIN-en', '$hvem scans, or types the PIN');
  static String cus_kode_les(String h) => _t('Les PIN-en høyt · $h taster den inn', 'Read the PIN aloud · $h types it in');
  static String cus_kode_uten_nett(String h) => _t('Uten nett · les PIN-en høyt for $h', 'Offline · read the PIN aloud to $h');
  static String get cus_kode_disken => _t('Disken', 'The counter');
  static String get cus_kode_sjaforen => _t('Sjåføren', 'The driver');
  static String get cus_kode_budet => _t('Budet', 'The courier');
  static String get cus_kode_qr_label => _t('QR-kode for leveringen', 'Delivery QR code');
}

/// **Leveringskode** (21 Oct, L7202–7224; `kQrEkte` L21673): the glass card
/// with the real QR the courier scans — `delivery_code.qr_url`,
/// `https://aerend.no/k/<code>-<pin>` (D-K17; QR version 3, level M, mask 0
/// as the design draws it) inside four pulsing corners and the `kodeSkann`
/// line — the PIN as four tiles popping in one after another, and who takes
/// it. «Bare PIN» / «Vis QR» switches (remembered per order); offline, or
/// without a QR URL, the card shows the large PIN tiles alone with «Uten
/// nett · les PIN-en høyt for …».
class LeveringskodeCard extends StatefulWidget {
  const LeveringskodeCard({super.key, required this.code, this.offline = false, this.tracking});

  final OpsDeliveryCode code;

  /// No connection: the PIN alone, no switch.
  final bool offline;

  /// Who takes the code (the title and the lines).
  final OpsTracking? tracking;

  /// Pref per order: `pin` or `qr`.
  static String prefVis(String orderId) => 'cus_kode_vis_$orderId';

  /// The QR modules for [payload] (version 3, level M, mask 0 — the design's
  /// `kQrEkte`), row by row.
  static List<List<bool>> moduler(String payload) {
    final code = QrCode(3, QrErrorCorrectLevel.M)..addData(payload);
    final img = QrImage.withMaskPattern(code, 0);
    return [
      for (var y = 0; y < img.moduleCount; y++) [for (var x = 0; x < img.moduleCount; x++) img.isDark(y, x)],
    ];
  }

  @override
  State<LeveringskodeCard> createState() => _LeveringskodeCardState();
}

class _LeveringskodeCardState extends State<LeveringskodeCard> {
  late bool _pin = prefGetString(LeveringskodeCard.prefVis(widget.tracking?.orderId ?? '')) == 'pin';

  void _vis(bool pin) {
    HapticFeedback.selectionClick();
    final id = widget.tracking?.orderId ?? '';
    if (id.isNotEmpty) prefSetString(LeveringskodeCard.prefVis(id), pin ? 'pin' : 'qr');
    setState(() => _pin = pin);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tracking;
    final pin = widget.code.pin ?? '';
    final url = widget.code.qrUrl;
    final henting = t?.isPickup ?? false;
    final partner = t?.isPartner ?? false;
    final tittel = henting
        ? SporingCopy.a1_sporing_vis_disken
        : partner
        ? SporingCopy.a1_sporing_vis_sjaforen
        : SporingCopy.a1_sporing_vis_budet;
    final navn = t?.courier?.firstName.trim() ?? '';
    final hvem = henting
        ? CusKodeCopy.cus_kode_disken
        : partner
        ? CusKodeCopy.cus_kode_sjaforen
        : (navn.isEmpty ? CusKodeCopy.cus_kode_budet : navn);
    final h = henting || partner || navn.isEmpty ? hvem.toLowerCase() : hvem;
    final kanQr = !widget.offline && url != null && url.isNotEmpty;
    final visPin = !kanQr || _pin;
    return SpBobleInn(
      dur: 450,
      child: CssBox(
        key: const Key('ops-delivery-code-card'),
        radius: BorderRadius.circular(22),
        clip: true,
        padding: const EdgeInsets.fromLTRB(12, 12, 13, 12), // 11 12 11 11 + the CSS border
        border: Border.all(color: rgba(255, 255, 255, .18)),
        bg: [
          CssLinear(180, [rgba(255, 255, 255, .16), rgba(255, 255, 255, .06)]),
        ],
        shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .26)), CssShadow(0, 14, 22, -12, rgba(4, 18, 26, .85))],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -41,
              top: -51,
              width: 160,
              height: 130,
              child: IgnorePointer(
                child: CssBox(
                  bg: [
                    CssRadial.closestSide([rgba(92, 224, 184, .22), rgba(92, 224, 184, 0)]),
                  ],
                ),
              ),
            ),
            KeyedSubtree(
              key: ValueKey(visPin),
              child: _Stag(
                child: visPin
                    ? _PinVariant(tittel: tittel, pin: pin, linje: widget.offline ? CusKodeCopy.cus_kode_uten_nett(h) : CusKodeCopy.cus_kode_les(h), bytt: kanQr ? () => _vis(false) : null)
                    : _QrVariant(tittel: tittel, pin: pin, url: url, linje: CusKodeCopy.cus_kode_skanner(hvem), bytt: () => _vis(true)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `kortStag .35s` when the card switches between QR and PIN.
class _Stag extends StatelessWidget {
  const _Stag({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 350,
    child: child,
    builder: (context, t, child) {
      final p = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 350));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 18 * (1 - p), 0)..scaleByDouble(.97 + .03 * p, .97 + .03 * p, 1, 1), child: child),
      );
    },
  );
}

class _QrVariant extends StatelessWidget {
  const _QrVariant({required this.tittel, required this.pin, required this.url, required this.linje, required this.bytt});

  final String tittel, pin, url, linje;
  final VoidCallback bytt;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _QrBlokk(url: url),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Hode(tittel: tittel, bryter: _Bryter(key: const Key('cus-kode-bare-pin'), tekst: CusKodeCopy.cus_kode_bare_pin, ikon: 'M5 7h3M5 12h3M5 17h3M11 7h3M11 12h3M11 17h3M17 7h2M17 12h2M17 17h2', bredde: 2.6, onTap: bytt)),
            const SizedBox(height: 7),
            Row(
              children: [
                for (final (i, c) in pin.split('').indexed) ...[if (i > 0) const SizedBox(width: 5), _Flis(tegn: c, stor: false, delay: 80 + i * 60.0)],
              ],
            ),
            const SizedBox(height: 7),
            Text(
              linje,
              key: const Key('cus-kode-qr-linje'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: inter(11, weight: FontWeight.w600, height: 1.3, color: rgba(255, 255, 255, .72)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PinVariant extends StatelessWidget {
  const _PinVariant({required this.tittel, required this.pin, required this.linje, required this.bytt});

  final String tittel, pin, linje;
  final VoidCallback? bytt;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _Hode(
        tittel: tittel,
        bryter: bytt == null ? null : _Bryter(key: const Key('cus-kode-vis-qr'), tekst: CusKodeCopy.cus_kode_vis_qr, ikon: 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h2v2h-2zM18 18h2v2h-2z', bredde: 2.2, onTap: bytt!),
      ),
      const SizedBox(height: 8),
      Row(
        key: const Key('ops-delivery-code-pin'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (i, c) in pin.split('').indexed) ...[if (i > 0) const SizedBox(width: 8), _Flis(tegn: c, stor: true, delay: 80 + i * 60.0)],
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          spIkon('M12 3a3 3 0 0 0-3 3v5a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3zM6 11a6 6 0 0 0 12 0M12 17v3', size: 12, color: const Color(0xFF7FF0CB)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              linje,
              key: const Key('cus-kode-pin-linje'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: inter(11, weight: FontWeight.w600, color: rgba(255, 255, 255, .72)),
            ),
          ),
        ],
      ),
    ],
  );
}

/// The title with its live dot, and the «Bare PIN» / «Vis QR» switch.
class _Hode extends StatelessWidget {
  const _Hode({required this.tittel, this.bryter});

  final String tittel;
  final Widget? bryter;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 26,
    child: Row(
      children: [
        const _LiveDot(),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            tittel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: inter(10, weight: FontWeight.w800, em: .09, color: const Color(0xFF7FF0CB)),
          ),
        ),
        if (bryter != null) ...[const SizedBox(width: 6), bryter!],
      ],
    ),
  );
}

/// The 6 px mint dot with its `livePuls` ring (1.8 s).
class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 6,
    height: 6,
    child: LfLoop(
      builder: (context, t, _) {
        final p = (t % 1800) / 1800;
        final e = cssEaseOut.transform(p);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: .9 * (1 - e),
                child: Transform.scale(scale: .6 + 1.3 * e, child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8)))),
              ),
            ),
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8)))),
          ],
        );
      },
    ),
  );
}

class _Bryter extends StatelessWidget {
  const _Bryter({super.key, required this.tekst, required this.ikon, required this.bredde, required this.onTap});

  final String tekst, ikon;
  final double bredde;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    onTap: onTap,
    scale: .94,
    dy: 0,
    child: Container(
      height: 26, // 24 + the CSS border
      padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
      decoration: BoxDecoration(
        color: rgba(255, 255, 255, .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: rgba(255, 255, 255, .24)),
        boxShadow: [BoxShadow(color: rgba(255, 255, 255, .2), offset: const Offset(0, 1), blurStyle: BlurStyle.inner)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          spIkon(ikon, size: 11, color: const Color(0xFF7FF0CB), width: bredde),
          const SizedBox(width: 5),
          Text(tekst, style: inter(10.5, weight: FontWeight.w800)),
        ],
      ),
    ),
  );
}

/// One PIN tile (`aiPopp`, staggered 60 ms): 38 × 38 next to the QR, 54 × 50
/// alone.
class _Flis extends StatelessWidget {
  const _Flis({required this.tegn, required this.stor, required this.delay});

  final String tegn;
  final bool stor;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final dur = stor ? 450.0 : 400.0;
    final tile = CssBox(
      width: stor ? 54 : 38,
      height: stor ? 50 : 38,
      radius: BorderRadius.circular(stor ? 14 : 11),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF2F2)]),
      ],
      shadows: stor
          ? [const CssShadow.inset(0, 2, 0, 0, Color(0xFFFFFFFF)), CssShadow.inset(0, -3, 4, 0, rgba(30, 79, 92, .16)), CssShadow(0, 4, 0, 0, rgba(4, 18, 26, .38)), CssShadow(0, 12, 16, -12, rgba(0, 0, 0, .7))]
          : [const CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow.inset(0, -2, 3, 0, rgba(30, 79, 92, .14)), CssShadow(0, 3, 0, 0, rgba(4, 18, 26, .35))],
      child: Center(
        child: Text(
          tegn,
          style: GoogleFonts.ibmPlexMono(fontSize: stor ? 30 : 21, fontWeight: FontWeight.w700, color: const Color(0xFF1E4F5C), height: 1),
        ),
      ),
    );
    return LfOnce(
      ms: delay + dur,
      child: tile,
      builder: (context, t, child) {
        final p = kfP(t, delay, dur);
        const c = Cubic(.3, 1.4, .5, 1);
        return Opacity(
          opacity: kf(p, const [0, .6, 1], const [0, 1, 1], c).clamp(0.0, 1.0),
          child: Transform.scale(scale: kf(p, const [0, .6, 1], const [.4, 1.1, 1], c), child: child),
        );
      },
    );
  }
}

/// The 94 × 94 QR block: the corners (`aiHjorne` 2.4 s, staggered 0.3 s), the
/// white plate (inset 5, radius 11, padding 3) and the `kodeSkann` line.
class _QrBlokk extends StatelessWidget {
  const _QrBlokk({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Semantics(
    label: CusKodeCopy.cus_kode_qr_label,
    image: true,
    child: SizedBox(
      key: const Key('ops-delivery-code-qr'),
      width: 94,
      height: 94,
      child: LfLoop(
        builder: (context, t, _) {
          Widget hjorne(int i, Alignment a) {
            final p = ((t - i * 300) % 2400) / 2400;
            final s = kf(p < 0 ? p + 1 : p, const [0, .5, 1], const [1, 1.06, 1], cssEaseInOut);
            final o = kf(p < 0 ? p + 1 : p, const [0, .5, 1], const [.85, 1, .85], cssEaseInOut);
            return Align(
              alignment: a,
              child: Opacity(
                opacity: o,
                child: Transform.scale(scale: s, child: CustomPaint(size: const Size(14, 14), painter: _HjornePainter(i))),
              ),
            );
          }

          final sp = (t % 2600) / 2600;
          final sy = kf(sp, const [0, .5, 1], const [0, 78, 0], cssEaseInOut);
          final so = kf(sp, const [0, .1, .9, 1], const [.2, 1, 1, .2], cssEaseInOut);
          return Stack(
            children: [
              hjorne(0, Alignment.topLeft),
              hjorne(1, Alignment.topRight),
              hjorne(2, Alignment.bottomLeft),
              hjorne(3, Alignment.bottomRight),
              Positioned.fill(
                left: 5,
                top: 5,
                right: 5,
                bottom: 5,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [BoxShadow(color: rgba(0, 0, 0, .7), offset: const Offset(0, 10), blurRadius: 9, spreadRadius: -10)],
                  ),
                  child: RepaintBoundary(child: CustomPaint(painter: _QrPainter(LeveringskodeCard.moduler(url)))),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                top: 10 + sy,
                height: 2,
                child: Opacity(
                  opacity: so.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(colors: [rgba(92, 224, 184, 0), const Color(0xFF5CE0B8), rgba(92, 224, 184, 0)]),
                      boxShadow: [BoxShadow(color: rgba(92, 224, 184, .55), blurRadius: 10, spreadRadius: 2)],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// One 14 px corner: 2.5 px mint, radius 8 on the outside corner.
class _HjornePainter extends CustomPainter {
  const _HjornePainter(this.hjorne);

  /// 0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right.
  final int hjorne;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 2.5, r = 8.0, m = w / 2;
    final path = Path()
      ..moveTo(m, size.height)
      ..lineTo(m, r)
      ..arcToPoint(const Offset(r, m), radius: const Radius.circular(r - m))
      ..lineTo(size.width, m);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(hjorne == 1 || hjorne == 3 ? -1 : 1, hjorne >= 2 ? -1 : 1);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = const Color(0xFF5CE0B8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HjornePainter old) => old.hjorne != hjorne;
}

/// The QR modules in the design's viewBox (2 modules of quiet zone), crisp.
class _QrPainter extends CustomPainter {
  _QrPainter(this.moduler);

  final List<List<bool>> moduler;

  @override
  void paint(Canvas canvas, Size size) {
    final n = moduler.length;
    final m = size.width / (n + 4);
    final paint = Paint()
      ..color = const Color(0xFF0B1014)
      ..isAntiAlias = false;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (moduler[y][x]) canvas.drawRect(Rect.fromLTWH((x + 2) * m, (y + 2) * m, m + .3, m + .3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.moduler != moduler;
}

/// **Valg som venter** (Launch L9008): the store has not seen the order —
/// wait for a new window, or cancel with a full refund.
class ValgSomVenterCard extends StatelessWidget {
  const ValgSomVenterCard({super.key, required this.storeName, required this.onWait, required this.onCancel});

  final String storeName;
  final VoidCallback onWait;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('a1_sporing_valg'),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: rgba(255, 255, 255, .9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: rgba(242, 109, 61, .5), width: 1.5),
      boxShadow: [BoxShadow(color: rgba(8, 24, 32, .55), offset: const Offset(0, 24), blurRadius: 44, spreadRadius: -22)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            aegil('invitation', w: 34, h: 34),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SporingCopy.a1_sporing_valg_tittel(storeName),
                    style: inter(14, weight: FontWeight.w800, color: kSpInk),
                  ),
                  Text(
                    SporingCopy.a1_sporing_valg_line,
                    style: inter(12, weight: FontWeight.w600, height: 1.35, color: const Color(0xFF57534B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LfPress(
                key: const Key('a1_sporing_valg_vent'),
                onTap: onWait,
                scale: .97,
                child: CssBox(
                  height: 46,
                  radius: BorderRadius.circular(999),
                  bg: const [
                    CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1]),
                  ],
                  child: Center(
                    child: Text(SporingCopy.a1_sporing_vent, style: inter(13.5, weight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LfPress(
                key: const Key('a1_sporing_valg_avbestill'),
                onTap: onCancel,
                scale: .97,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFB9441A), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      SporingCopy.a1_sporing_avbestill,
                      style: inter(13.5, weight: FontWeight.w800, color: const Color(0xFFB9441A)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
