import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart' show onbBlur;
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_motion.dart';
import '../kit/bergen_kit.dart';
import '../../snurre/snurre_launcher_policy.dart' show isSnurreLauncherHiddenRoute, snurreLauncherHiddenRoutePrefix;
import 'kasse_copy.dart';

/// Betalt (`betOvergang`, L17590): the moment the payment is through. The
/// slider's knob flies up to the middle (`.64s cubic-bezier(.5,0,.2,1)`,
/// scale 1 → 1.35 → 1.6, a −8° swing), the mint check draws itself, two rings
/// spread, «Betalt · N kr / Ægil gjør seg klar» rises in; at 1.15 s Sporing
/// opens underneath and the water slides down off it (`.68s
/// cubic-bezier(.6,0,.3,1)`).
///
/// The Vipps return opens this screen once the backend has confirmed the
/// payment, so it starts from the full overlay (the prototype grows it out of
/// the slider, which is gone after Vipps).
class KjopBekreftetScreen extends StatefulWidget {
  const KjopBekreftetScreen({super.key, required this.orderId, this.sum, this.customerApi});

  final int orderId;

  /// The paid total; read from the order when not given.
  final double? sum;
  final OpsCustomerApi? customerApi;

  @override
  State<KjopBekreftetScreen> createState() => _KjopBekreftetScreenState();
}

class _KjopBekreftetScreenState extends State<KjopBekreftetScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150));
  double? _sum;
  bool _videre = false;

  @override
  void initState() {
    super.initState();
    _sum = widget.sum;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The Vipps return pushes this screen unnamed, which shows the chat
      // button; the prototype has none here, so step onto a hidden route.
      final route = ModalRoute.of(context);
      if (route != null && !isSnurreLauncherHiddenRoute(route)) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            settings: const RouteSettings(name: '${snurreLauncherHiddenRoutePrefix}betalt'),
            transitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) =>
                KjopBekreftetScreen(orderId: widget.orderId, sum: _sum, customerApi: widget.customerApi),
          ),
        );
        return;
      }
      HapticFeedback.heavyImpact();
      if (_sum == null) _hentSum();
      if (MediaQuery.disableAnimationsOf(context)) {
        _t.value = 1;
        Future.delayed(const Duration(milliseconds: 1150), _follow);
      } else {
        _t.forward().whenComplete(_follow);
      }
    });
  }

  Future<void> _hentSum() async {
    final orders = await (widget.customerApi ?? OpsCustomerApi()).orders(limit: 20);
    final o = orders.where((o) => '${o['order_id']}' == '${widget.orderId}').firstOrNull;
    final v = o?['total_pay'];
    if (mounted && v is num) setState(() => _sum = v.toDouble());
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// Sporing underneath, the water sliding off it.
  void _follow() {
    if (_videre || !mounted) return;
    _videre = true;
    final navn = '/bergen/sporing/${widget.orderId}';
    final key = BergenRoutes.resolve(navn);
    if (key == null) {
      Navigator.of(context).maybePop();
      return;
    }
    // Fresh from the purchase: the panel's slot shows the vervebillett.
    final side = BergenRoutes.generate(RouteSettings(name: navn, arguments: const {'fersk': '1'})) as PageRoute;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final frame = _Ramme(t: 1, sum: _sum);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: side.settings,
        transitionDuration: Duration(milliseconds: reduce ? 0 : 1030),
        pageBuilder: (context, a, sa) => side.buildPage(context, a, sa),
        transitionsBuilder: (context, a, _, child) {
          if (a.status == AnimationStatus.completed) return child;
          // 350 ms on the overlay, then 680 ms down and away.
          final ms = a.value * 1030;
          final e = const Cubic(.6, 0, .3, 1).transform(((ms - 350) / 680).clamp(0.0, 1.0));
          return Stack(
            children: [
              child,
              Positioned.fill(
                child: IgnorePointer(
                  child: FractionalTranslation(
                    translation: Offset(0, e * 1.04),
                    child: Material(type: MaterialType.transparency, child: frame),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E4F5C),
      body: AnimatedBuilder(
        animation: _t,
        builder: (context, _) => _Ramme(t: _t.value, sum: _sum),
      ),
    );
  }
}

/// One frame of the Betalt overlay at [t] (0–1 over 1150 ms).
class _Ramme extends StatelessWidget {
  const _Ramme({required this.t, required this.sum});

  final double t;
  final double? sum;

  static const _knapp = 50.0;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final size = MediaQuery.sizeOf(context);
    final w = size.width, h = size.height;
    final ms = t * 1150;
    // The knob: from the slider (left 16+5, bottom 16+5) to the middle.
    final bunn = math.max(16 * s, MediaQuery.paddingOf(context).bottom);
    final k = _knapp * s;
    final x0 = 21 * s, y0 = h - bunn - 5 * s - k;
    final mx = w / 2 - k / 2 - x0, my = h * .44 - k / 2 - y0;
    final f = (ms / 640).clamp(0.0, 1.0);
    double tx, ty, sc, rot;
    if (f <= .55) {
      final e = const Cubic(.5, 0, .2, 1).transform(f / .55);
      tx = mx * .55 * e;
      ty = (my * .45 - 40 * s) * e;
      sc = 1 + .35 * e;
      rot = -8 * e;
    } else {
      final e = const Cubic(.5, 0, .2, 1).transform((f - .55) / .45);
      tx = mx * .55 + mx * .45 * e;
      ty = (my * .45 - 40 * s) + (my - (my * .45 - 40 * s)) * e;
      sc = 1.35 + .25 * e;
      rot = -8 + 8 * e;
    }
    // From 600 ms: the pulse, the check, the rings and the words.
    final etter = ms - 600;
    if (etter > 0) sc *= 1 + kf((etter / 360).clamp(0.0, 1.0), const [0, .4, 1], const [0, .09375, 0], Curves.easeOut);
    final hake = Curves.easeOut.transform((etter / 320).clamp(0.0, 1.0));
    final ord = Curves.easeOut.transform((etter / 360).clamp(0.0, 1.0));

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)],
                stops: [0, .55, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: .8,
                colors: [rgba(70, 163, 180, .5), rgba(70, 163, 180, 0)],
                stops: const [0, .7],
              ),
            ),
          ),
        ),
        // The light along the top edge.
        Positioned(
          left: 0,
          right: 0,
          top: -1,
          height: 26 * s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.elliptical(w / 2, 22 * s)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [rgba(255, 255, 255, .32), rgba(255, 255, 255, 0)],
              ),
            ),
          ),
        ),
        for (final (d, a) in [(0.0, .5), (160.0, .3)])
          if (etter - d > 0)
            Positioned(
              left: w / 2 - 50 * s,
              top: h * .44 - 50 * s,
              width: 100 * s,
              height: 100 * s,
              child: Builder(
                builder: (context) {
                  final e = const Cubic(.2, .7, .3, 1).transform(((etter - d) / 1000).clamp(0.0, 1.0));
                  return Opacity(
                    opacity: 1 - e,
                    child: Transform.scale(
                      scale: .8 + 1.8 * e,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: rgba(255, 255, 255, a), width: 1.5 * s),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        Positioned(
          left: 0,
          right: 0,
          top: h * .44 + 62 * s,
          child: Opacity(
            opacity: ord,
            child: Transform.translate(
              offset: Offset(0, 8 * s * (1 - ord)),
              child: Column(
                key: const Key('a1_kasse_bekreftet'),
                children: [
                  Text(
                    sum == null ? KasseCopy.a1_kasse_betalt : KasseCopy.a1_kasse_betalt_sum(KasseCopy.tall(sum!)),
                    style: bDisplay(context, 20, letterSpacingEm: -.01),
                  ),
                  SizedBox(height: 6 * s),
                  Text(
                    KasseCopy.a1_kasse_gjor_klar,
                    style: bText(context, 13, weight: FontWeight.w600, color: rgba(255, 255, 255, .78)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: x0,
          top: y0,
          width: k,
          height: k,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(tx, ty, 0)
              ..rotateZ(rot * math.pi / 180)
              ..scaleByDouble(sc, sc, 1, 1),
            child: _Knapp(hake: hake),
          ),
        ),
      ],
    );
  }
}

/// The slider's knob (`radial-gradient(circle at 36% 26%, #4F9AAB, #2A6272
/// 40%, #1E4F5C 78%, #143C46)`, white ring, dark ledge) with the mint check
/// drawn to [hake].
class _Knapp extends StatelessWidget {
  const _Knapp({required this.hake});

  final double hake;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * s),
        gradient: const RadialGradient(
          center: Alignment(-.28, -.48),
          radius: .9,
          colors: [Color(0xFF4F9AAB), Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF143C46)],
          stops: [0, .4, .78, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: rgba(0, 20, 30, .75),
            offset: Offset(0, 14 * s),
            blurRadius: onbBlur(22 * s),
            spreadRadius: -6 * s,
          ),
          BoxShadow(color: const Color(0xFF0F2E36), offset: Offset(0, 3 * s), spreadRadius: 2 * s),
          BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 2 * s),
        ],
      ),
      child: CustomPaint(size: Size.square(20 * s), painter: _Hake(hake)),
    );
  }
}

class _Hake extends CustomPainter {
  const _Hake(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    canvas.scale(size.width / 24);
    final path = Path()
      ..moveTo(5, 12.5)
      ..lineTo(9.5, 17)
      ..lineTo(19, 7.5);
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF5CE0B8),
    );
  }

  @override
  bool shouldRepaint(_Hake old) => old.t != t;
}

/// Step 4: the referral ticket, once per order after Levert. Returns without
/// showing anything when the referral route is not on this tree, or when the
/// order already had its ticket.
Future<void> showVervebillett(BuildContext context, {required int orderId, OpsCustomerApi? api}) async {
  final key = 'a1_kasse_billett_$orderId';
  if (prefGetBool(key)) return;
  final json = await (api ?? OpsCustomerApi()).referral();
  final referral = json?['referral'];
  if (referral is! Map) return;
  final code = '${referral['code'] ?? ''}';
  if (code.isEmpty || !context.mounted) return;
  prefSetBool(key, true);
  final kr = ((referral['points_for_me'] as num?)?.toInt() ?? 100);
  final link = '${referral['link'] ?? ''}';
  await showBergenArk<void>(
    context,
    title: KasseCopy.a1_kasse_verv,
    subtitle: KasseCopy.a1_kasse_gi_faa(kr),
    copyText: code,
    body: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KasseCopy.a1_kasse_billett_kicker,
            style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.inkFaint),
          ),
          const SizedBox(height: 4),
          Text(
            KasseCopy.a1_kasse_billett_line(kr),
            style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: BergenTokens.inkSecondary),
          ),
        ],
      ),
    ),
    primary: BergenArkAction(
      label: KasseCopy.a1_kasse_del_billett,
      icon: Icons.ios_share_rounded,
      onTap: () => Share.share(link.isEmpty ? code : '$code · $link'),
    ),
    secondary: BergenArkAction(label: KasseCopy.a1_kasse_lukk, onTap: () => Navigator.of(context).pop()),
  );
}
