import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import 'butikk_copy.dart';

/// The product sheet (`visProdukt` ≈L7214–7297 in `Ærend Kunde Bergen.dc.html`).
///
/// A dark sheet rising over a dimmed, blurred page (`arkOpp .46s`): a warm
/// "kitchen spotlight" hero with the product floating in it (`heroLoft`,
/// `heroSvev`, bokeh, steam, a pulsing ring), «Mest bestilt i kveld»,
/// "+N poeng" and "Klar på N min"; then name, description and price, the
/// product's option groups — sizes and single choices as the design's
/// «Størrelse» cards, add-ons as the «Tillegg» check list, a strength group
/// as the «Styrke» segment — the allergens, and the quantity + «Legg til».
///
/// Data: the menu row ([item]), the option groups (`options`), and
/// `ops.customer.product` for the description, allergens, prep time,
/// «Mest bestilt» and the Kjøp points rate. Anything missing stays hidden.
Future<void> showProduktSheet(
  BuildContext context, {
  required BergenMenuItem item,
  OpsButikkApi? api,
  OpsCustomerApi? customerApi,
  int? readyMinutes,
  bool mostOrdered = false,
  List<String> allergens = const [],
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: ButikkCopy.a1_butikk_prod_lukk,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 460),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, _) => _ProduktRoute(
        animation: animation,
        child: ProduktSheet(
          item: item,
          api: api ?? OpsButikkApi(),
          customerApi: customerApi ?? OpsCustomerApi(),
          readyMinutes: readyMinutes,
          mostOrdered: mostOrdered,
          allergens: allergens,
        ),
      ),
    ),
  );
}

/// The dimmed, blurred backdrop (`rgba(15,25,32,.45)`, `blur(3px)`) and the
/// sheet's `arkOpp` rise.
class _ProduktRoute extends StatelessWidget {
  const _ProduktRoute({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = reduced ? 1.0 : animation.value;
        final forward = animation.status != AnimationStatus.reverse;
        final e = forward
            ? kSkjermInn.transform(t)
            : Curves.easeIn.transform(t);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 3 * t, sigmaY: 3 * t),
                  child: ColoredBox(color: rgba(15, 25, 32, .45 * t)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: forward ? .6 + .4 * e : e,
                child: Transform.translate(
                  offset: Offset(0, forward ? 26 * (1 - e) : 80 * (1 - e)),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProduktSheet extends StatefulWidget {
  const ProduktSheet({
    super.key,
    required this.item,
    required this.api,
    required this.customerApi,
    this.readyMinutes,
    this.mostOrdered = false,
    this.allergens = const [],
    this.options,
    this.detail,
  });

  final BergenMenuItem item;
  final OpsButikkApi api;
  final OpsCustomerApi customerApi;
  final int? readyMinutes;
  final bool mostOrdered;
  final List<String> allergens;

  /// Preloaded options (tests).
  final BergenProductOptions? options;

  /// Preloaded `ops.customer.product` (tests).
  final BergenProductDetail? detail;

  /// A single-choice group the design shows as the «Styrke» segment.
  static bool isStrength(BergenOptionGroup g) =>
      g.single &&
      RegExp(
        r'styrke|sterk|chili|spice|spicy|strength',
        caseSensitive: false,
      ).hasMatch(g.name);

  @override
  State<ProduktSheet> createState() => _ProduktSheetState();
}

class _ProduktSheetState extends State<ProduktSheet> {
  BergenProductOptions? _options;
  BergenProductDetail? _detail;
  int _qty = 1;
  int? _size;
  final Set<int> _picked = {};

  /// Bumped on every change of the sum: replays `prisTikk`.
  int _tick = 0;

  /// The option last toggled: replays its `valgTikk`.
  int? _ticked;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _detail = widget.detail;
    if (_options == null) _loadOptions();
    if (_detail == null) _loadDetail();
    _defaults();
  }

  Future<void> _loadOptions() async {
    final o = await widget.api.options(widget.item.id);
    if (!mounted) return;
    setState(() {
      _options = o;
      _defaults();
    });
  }

  Future<void> _loadDetail() async {
    final d = await widget.api.productDetail(widget.item.id);
    if (!mounted || d == null) return;
    setState(() {
      _detail = d;
      _defaults();
    });
  }

  /// The design opens on "Vanlig" — the standard, no-extra-cost choice —
  /// for sizes and for every required or strength group.
  static BergenVariant _standard(List<BergenVariant> options) =>
      options.firstWhere(
        (v) => v.inStock && v.priceDelta == 0,
        orElse: () =>
            options.firstWhere((v) => v.inStock, orElse: () => options.first),
      );

  void _defaults() {
    final o = _options;
    if (o == null) return;
    final sized = widget.item.hasSizes || (_detail?.hasSizes ?? false);
    if (_size == null && o.sizes.isNotEmpty && sized) {
      _size = _standard(o.sizes).id;
    }
    for (final g in o.groups) {
      if (!g.single || g.options.isEmpty) continue;
      if (g.options.any((v) => _picked.contains(v.id))) continue;
      if (g.required || ProduktSheet.isStrength(g)) {
        _picked.add(_standard(g.options).id);
      }
    }
  }

  double get _unit {
    final o = _options;
    var unit = widget.item.price;
    if (o != null) {
      final size = o.sizes.where((v) => v.id == _size).firstOrNull;
      if (size != null) unit += size.priceDelta;
      for (final g in o.groups) {
        for (final v in g.options) {
          if (_picked.contains(v.id)) unit += v.priceDelta;
        }
      }
    }
    return unit;
  }

  double get _sum => _unit * _qty;

  void _change(VoidCallback f) => setState(() {
    f();
    _tick++;
  });

  void _togglePick(BergenOptionGroup g, BergenVariant v) {
    if (!v.inStock) return;
    _change(() {
      _ticked = v.id;
      if (g.single) {
        for (final other in g.options) {
          _picked.remove(other.id);
        }
        _picked.add(v.id);
      } else if (!_picked.remove(v.id)) {
        _picked.add(v.id);
      }
    });
  }

  Future<void> _add() async {
    final name = widget.item.name;
    final ok = await BergenCart.add(
      context,
      storeId: widget.item.storeId,
      productId: widget.item.id,
      quantity: _qty,
      sizeId: _size ?? 0,
      optionIds: _picked.toList(),
      toast: ButikkCopy.a1_butikk_prod_i_kurven(
        _qty > 1 ? '$_qty× $name' : name,
      ),
    );
    if (ok && mounted) Navigator.of(context).maybePop();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final mq = MediaQuery.of(context);
    final item = widget.item;
    final o = _options;
    final d = _detail;
    final allergens = widget.allergens.isNotEmpty
        ? widget.allergens
        : (d?.allergens ?? const <String>[]);
    final rate = d?.pointsPer10Kr;
    final points = rate == null ? 0 : (_sum ~/ 10) * rate;

    final strength = o?.groups.where(ProduktSheet.isStrength).toList() ?? [];
    final cards =
        o?.groups
            .where((g) => g.single && !ProduktSheet.isStrength(g))
            .toList() ??
        [];
    final checks = o?.groups.where((g) => !g.single).toList() ?? [];

    // `trinnInn .4s` staggered .08s from .12s, as the design's sections.
    var step = 0;
    Widget trinn(Widget child) {
      final delay = 120.0 + 80 * step++;
      return _TrinnInn(delayMs: delay, child: child);
    }

    final sections = <Widget>[
      trinn(
        _Head(
          name: item.name,
          description: item.description ?? d?.description,
          price: item.price,
        ),
      ),
      if (o != null && o.sizes.isNotEmpty)
        trinn(
          _CardGroup(
            title: ButikkCopy.a1_butikk_prod_storrelse,
            options: o.sizes,
            selected: {if (_size != null) _size!},
            keyPrefix: 'a1_butikk_prod_size_',
            onTap: (v) => _change(() => _size = v.id),
            sizes: true,
          ),
        ),
      for (final g in cards)
        trinn(
          _CardGroup(
            title: g.name,
            options: g.options,
            selected: _picked,
            keyPrefix: 'a1_butikk_prod_opt_',
            onTap: (v) => _togglePick(g, v),
          ),
        ),
      for (final g in checks)
        trinn(
          _CheckGroup(
            title: g.name.isEmpty ? ButikkCopy.a1_butikk_prod_tillegg : g.name,
            group: g,
            picked: _picked,
            ticked: _ticked,
            tick: _tick,
            onTap: (v) => _togglePick(g, v),
          ),
        ),
      for (final g in strength)
        trinn(
          _StrengthGroup(
            group: g,
            picked: _picked,
            onTap: (v) => _togglePick(g, v),
          ),
        ),
      trinn(_AllergenLine(allergens: allergens)),
    ];

    return Container(
      key: const Key('a1_butikk_produkt_sheet'),
      constraints: BoxConstraints(maxHeight: mq.size.height * .92),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
        gradient: cssLinear(
          180,
          const [Color(0xFF1E4F5C), Color(0xFF173E48), Color(0xFF122F3A)],
          const [0, .55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: rgba(4, 18, 26, .9),
            offset: Offset(0, -24 * s),
            blurRadius: onbBlur(50 * s),
            spreadRadius: -18 * s,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(
                  imageUrl: item.imageUrl ?? d?.imageUrl,
                  mostOrdered: widget.mostOrdered || (d?.mostOrdered ?? false),
                  points: points,
                  readyMinutes: d?.readyMinutes ?? widget.readyMinutes,
                  onClose: _close,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20 * s, 4 * s, 20 * s, 14 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < sections.length; i++) ...[
                          if (i > 0) SizedBox(height: 16 * s),
                          sections[i],
                        ],
                      ],
                    ),
                  ),
                ),
                _TrinnInn(
                  delayMs: 500,
                  child: _BottomBar(
                    qty: _qty,
                    sum: _sum,
                    tick: _tick,
                    bottom: math.max(22 * s, mq.padding.bottom + 8 * s),
                    onMinus: _qty > 1 ? () => _change(() => _qty--) : null,
                    onPlus: () => _change(() => _qty++),
                    onAdd: _add,
                  ),
                ),
              ],
            ),
            bergenInsetTop(radius: 30 * s, alpha: .3),
          ],
        ),
      ),
    );
  }
}

// ── motion ──────────────────────────────────────────────────────────────────

/// `trinnInn .4s <delay> cubic-bezier(.2,.9,.3,1)` — up 18px, faded in.
class _TrinnInn extends StatelessWidget {
  const _TrinnInn({required this.delayMs, required this.child});

  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => BergenOnce(
    durationMs: 400,
    delayMs: delayMs,
    child: child,
    builder: (context, p, child) {
      final e = kSkjermInn.transform(p);
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * context.bs * (1 - e)),
          child: child,
        ),
      );
    },
  );
}

/// `prisTikk .28s` — the number rises 6px into place; replays on [tick].
class _PrisTikk extends StatelessWidget {
  const _PrisTikk({required this.tick, required this.child});

  final int tick;
  final Widget child;

  @override
  Widget build(BuildContext context) => BergenOnce(
    key: ValueKey(tick),
    durationMs: 280,
    child: child,
    builder: (context, p, child) {
      final e = Curves.easeOut.transform(p);
      return Opacity(
        opacity: .3 + .7 * e,
        child: Transform.translate(
          offset: Offset(0, 6 * context.bs * (1 - e)),
          child: child,
        ),
      );
    },
  );
}

// ── hero: the kitchen spotlight ─────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.imageUrl,
    required this.mostOrdered,
    required this.points,
    required this.readyMinutes,
    required this.onClose,
  });

  final String? imageUrl;
  final bool mostOrdered;
  final int points;
  final int? readyMinutes;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: 262 * s,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // radial-gradient(120% 90% at 50% 105%, …)
            Positioned.fill(
              child: CustomPaint(
                painter: _EllipsePainter(
                  center: const Offset(.5, 1.05),
                  rx: 1.2,
                  ry: .9,
                  colors: const [
                    Color(0xFFE9A96E),
                    Color(0xFFB8623A),
                    Color(0xFF4A2A1E),
                    Color(0xFF1E2A30),
                  ],
                  stops: const [0, .38, .7, 1],
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _StripesPainter(s))),
            // The spotlight cone.
            Positioned(
              left: w / 2 - 150 * s,
              top: -40 * s,
              width: 300 * s,
              height: 280 * s,
              child: CustomPaint(painter: _ConePainter()),
            ),
            // The lamp.
            Positioned(
              left: w / 2 - 35 * s,
              top: -6 * s,
              width: 70 * s,
              height: 12 * s,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(10 * s),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2E3A40), Color(0xFF1B2529)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: rgba(255, 214, 150, .35)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(0, 0, 0, .6),
                      offset: Offset(0, 4 * s),
                      blurRadius: onbBlur(10 * s),
                    ),
                  ],
                ),
              ),
            ),
            // radial-gradient(70% 60% at 50% 92%, rgba(255,217,138,.6), 0 70%)
            Positioned.fill(
              child: CustomPaint(
                painter: _EllipsePainter(
                  center: const Offset(.5, .92),
                  rx: .7,
                  ry: .6,
                  colors: [rgba(255, 217, 138, .6), rgba(255, 217, 138, 0)],
                  stops: const [0, .7],
                ),
              ),
            ),
            for (final b in _Bokeh.all) _BokehDot(b: b, width: w),
            _Steam(
              left: .44 * w,
              top: 118 * s,
              w: 22,
              h: 70,
              ms: 6000,
              delay: 0,
            ),
            _Steam(
              left: .56 * w,
              top: 110 * s,
              w: 18,
              h: 60,
              ms: 7000,
              delay: 1600,
            ),
            // The plate's shadow.
            Positioned(
              left: w / 2 - 100 * s,
              top: 206 * s,
              width: 200 * s,
              height: 32 * s,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 10 * s,
                  sigmaY: 10 * s,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: rgba(40, 15, 5, .55),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(100 * s, 16 * s),
                    ),
                  ),
                ),
              ),
            ),
            // `ringPuls 3.4s`.
            Positioned(
              left: w / 2 - 70 * s,
              top: 196 * s,
              width: 140 * s,
              height: 140 * s,
              child: BergenLoop(
                durationMs: 3400,
                builder: (context, p, child) {
                  if (p == null) return const SizedBox.shrink();
                  final e = Curves.easeOut.transform(p);
                  return Opacity(
                    opacity: .6 * (1 - e),
                    child: Transform.scale(scale: .6 + .8 * e, child: child),
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rgba(255, 235, 190, .5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // The product: `heroLoft .6s .05s`, then `heroSvev 5s 1s`.
            Positioned(
              left: w / 2 - 100 * s,
              top: 40 * s,
              width: 200 * s,
              height: 186 * s,
              child: BergenOnce(
                durationMs: 600,
                delayMs: 50,
                builder: (context, p, child) {
                  final y = kf(
                    p,
                    const [0, .6, 1],
                    const [40, -6, 0],
                    kKortInn,
                  );
                  final sc = kf(
                    p,
                    const [0, .6, 1],
                    const [.9, 1.04, 1],
                    kKortInn,
                  );
                  final o = kf(p, const [0, .6, 1], const [0, 1, 1], kKortInn);
                  return Opacity(
                    opacity: o.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, y * s),
                      child: Transform.scale(scale: sc, child: child),
                    ),
                  );
                },
                child: BergenLoop(
                  durationMs: 5000,
                  delayMs: 1000,
                  builder: (context, p, child) {
                    if (p == null) return child!;
                    final y = kf(
                      p,
                      const [0, .5, 1],
                      const [0, -8, 0],
                      Curves.easeInOut,
                    );
                    final r = kf(
                      p,
                      const [0, .5, 1],
                      const [-2, 2, -2],
                      Curves.easeInOut,
                    );
                    return Transform.translate(
                      offset: Offset(0, y * s),
                      child: Transform.rotate(
                        angle: r * math.pi / 180,
                        child: child,
                      ),
                    );
                  },
                  child: _Plate(imageUrl: imageUrl),
                ),
              ),
            ),
            // Handle and close.
            Positioned(
              top: 4 * s,
              left: w / 2 - 40 * s,
              width: 80 * s,
              height: 20 * s,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 6 * s),
                    width: 44 * s,
                    height: 5 * s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3 * s),
                      color: rgba(255, 255, 255, .55),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14 * s,
              right: 14 * s,
              child: OnbPressable(
                key: const Key('a1_butikk_produkt_lukk'),
                onTap: onClose,
                pressDy: 0,
                pressScale: .92,
                child: _GlassPill(
                  circle: 38 * s,
                  child: _Cross(size: 13 * s),
                ),
              ),
            ),
            Positioned(
              left: 14 * s,
              top: 14 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mostOrdered) ...[
                    _GlassPill(
                      padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 11 * s, 6 * s),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _LyktDot(),
                          SizedBox(width: 6 * s),
                          Text(
                            ButikkCopy.a1_butikk_prod_mest_bestilt,
                            style: bText(
                              context,
                              10.5,
                              weight: FontWeight.w800,
                              letterSpacingEm: -.01,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6 * s),
                  ],
                  if (points > 0) _PoengPill(points: points),
                ],
              ),
            ),
            if (readyMinutes != null)
              Positioned(
                right: 14 * s,
                bottom: 16 * s,
                child: _GlassPill(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 5 * s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: Size.square(11 * s),
                        painter: _IconPainter(
                          const Color(0xFF7FF0CB),
                          2.2,
                          (k) => Path()
                            ..addOval(
                              Rect.fromCircle(
                                center: Offset(12 * k, 12 * k),
                                radius: 9 * k,
                              ),
                            )
                            ..moveTo(12 * k, 7 * k)
                            ..lineTo(12 * k, 12 * k)
                            ..lineTo(15 * k, 14 * k),
                        ),
                      ),
                      SizedBox(width: 5 * s),
                      Text(
                        ButikkCopy.a1_butikk_prod_klar(readyMinutes!),
                        style: bText(
                          context,
                          10.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Into the sheet: `linear-gradient(180deg, rgba(30,79,92,0), #1E4F5C)`.
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 36 * s,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x001E4F5C), Color(0xFF1E4F5C)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The product under the lamp. The design floats a cut-out; the stores'
/// photos are rectangles, so they sit on a rounded plate with the same drop.
class _Plate extends StatelessWidget {
  const _Plate({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final fallback = Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 96 * s,
        color: rgba(255, 235, 190, .9),
        shadows: [
          Shadow(
            color: rgba(30, 10, 5, .6),
            offset: Offset(0, 20 * s),
            blurRadius: 22 * s,
          ),
        ],
      ),
    );
    if (imageUrl == null) return fallback;
    return Center(
      child: Container(
        width: 190 * s,
        height: 150 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26 * s),
          boxShadow: [
            BoxShadow(
              color: rgba(30, 10, 5, .6),
              offset: Offset(0, 22 * s),
              blurRadius: 24 * s,
              spreadRadius: -6 * s,
            ),
            BoxShadow(color: rgba(255, 200, 120, .25), blurRadius: 40 * s),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26 * s),
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      ),
    );
  }
}

class _Bokeh {
  const _Bokeh(
    this.x,
    this.y,
    this.size,
    this.color,
    this.blur,
    this.ms,
    this.delay,
  );

  final double x;
  final double y;
  final double size;
  final Color color;
  final double blur;
  final double ms;
  final double delay;

  static const all = [
    _Bokeh(.14, .30, 8, Color(0xCCFFEBBE), 1, 5000, 0),
    _Bokeh(.80, .24, 12, Color(0x99FFEBBE), 1.5, 6000, 1200),
    _Bokeh(.24, .66, 6, Color(0xB3FFFFFF), .6, 4600, 2000),
    _Bokeh(.72, .72, 8, Color(0x99FFFFFF), 1, 5400, 600),
  ];
}

/// `bokeh` — drifting up 10px, growing 15%, .55 ↔ .9.
class _BokehDot extends StatelessWidget {
  const _BokehDot({required this.b, required this.width});

  final _Bokeh b;
  final double width;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: b.x * width,
      top: b.y * 262 * s,
      child: BergenLoop(
        durationMs: b.ms,
        delayMs: b.delay,
        builder: (context, p, child) {
          final q = p ?? 0;
          final y = kf(
            q,
            const [0, .5, 1],
            const [0, -10, 0],
            Curves.easeInOut,
          );
          final sc = kf(
            q,
            const [0, .5, 1],
            const [1, 1.15, 1],
            Curves.easeInOut,
          );
          final o = kf(
            q,
            const [0, .5, 1],
            const [.55, .9, .55],
            Curves.easeInOut,
          );
          return Opacity(
            opacity: o,
            child: Transform.translate(
              offset: Offset(0, y * s),
              child: Transform.scale(scale: sc, child: child),
            ),
          );
        },
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: b.blur * s,
            sigmaY: b.blur * s,
          ),
          child: Container(
            width: b.size * s,
            height: b.size * s,
            decoration: BoxDecoration(shape: BoxShape.circle, color: b.color),
          ),
        ),
      ),
    );
  }
}

/// `dypSvev` — steam rising 84px off the plate and fading.
class _Steam extends StatelessWidget {
  const _Steam({
    required this.left,
    required this.top,
    required this.w,
    required this.h,
    required this.ms,
    required this.delay,
  });

  final double left;
  final double top;
  final double w;
  final double h;
  final double ms;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: BergenLoop(
          durationMs: ms,
          delayMs: delay,
          builder: (context, p, child) {
            if (p == null) return const SizedBox.shrink();
            final e = Curves.easeInOut.transform(p);
            final y = 10 + (-84 - 10) * e;
            final sc = .7 + .3 * e;
            final o = p < .25 ? .6 * (p / .25) : .6 * (1 - (p - .25) / .75);
            return Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, y * s),
                child: Transform.scale(scale: sc, child: child),
              ),
            );
          },
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 6 * s, sigmaY: 6 * s),
            child: Container(
              width: w * s,
              height: h * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(w * s / 2, h * s / 2),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    rgba(255, 255, 255, 0),
                    rgba(255, 255, 255, .35),
                    rgba(255, 255, 255, 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An elliptical CSS `radial-gradient(rx% ry% at cx cy, …)`.
class _EllipsePainter extends CustomPainter {
  _EllipsePainter({
    required this.center,
    required this.rx,
    required this.ry,
    required this.colors,
    required this.stops,
  });

  final Offset center;
  final double rx;
  final double ry;
  final List<Color> colors;
  final List<double> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(center.dx * size.width, center.dy * size.height);
    final rX = rx * size.width;
    final rY = ry * size.height;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(rX / rY, 1);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: rY));
    final inv = rY / rX;
    canvas.drawRect(
      Rect.fromLTRB(
        -c.dx * inv,
        -c.dy,
        (size.width - c.dx) * inv,
        size.height - c.dy,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EllipsePainter old) => false;
}

/// `repeating-linear-gradient(90deg, … 38px, rgba(255,255,255,.04) 38–39px)`.
class _StripesPainter extends CustomPainter {
  _StripesPainter(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = rgba(255, 255, 255, .04);
    for (var x = 38 * s; x < size.width; x += 39 * s) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1 * s, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => false;
}

/// The lamp's light: `radial-gradient(50% 100% at 50% 0%, rgba(255,214,150,.55),
/// 0 70%)` clipped to `polygon(38% 0, 62% 0, 100% 100%, 0 100%)`.
class _ConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cone = Path()
      ..moveTo(.38 * w, 0)
      ..lineTo(.62 * w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.save();
    canvas.clipPath(cone);
    canvas.translate(w / 2, 0);
    canvas.scale((w / 2) / h, 1);
    canvas.drawRect(
      Rect.fromLTRB(-h, 0, h, h),
      Paint()
        ..shader = RadialGradient(
          colors: [rgba(255, 214, 150, .55), rgba(255, 214, 150, 0)],
          stops: const [0, .7],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: h)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ConePainter old) => false;
}

// ── hero pills ──────────────────────────────────────────────────────────────

/// `rgba(15,31,43,.5)` + `blur(18px)`, the white hairline and inset top.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.padding, this.circle});

  final Widget child;
  final EdgeInsets? padding;
  final double? circle;

  @override
  Widget build(BuildContext context) {
    final r = circle == null
        ? BorderRadius.circular(999)
        : BorderRadius.circular(circle! / 2);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          width: circle,
          height: circle,
          padding: padding,
          alignment: circle == null ? null : Alignment.center,
          decoration: BoxDecoration(
            borderRadius: r,
            color: rgba(15, 31, 43, .5),
            border: Border.all(color: rgba(255, 255, 255, .3)),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [child],
          ),
        ),
      ),
    );
  }
}

/// The lantern dot, `lyktPuls 3s` (its glow breathes 8 ↔ 15px).
class _LyktDot extends StatelessWidget {
  const _LyktDot();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenLoop(
      durationMs: 3000,
      builder: (context, p, _) {
        final g = p == null
            ? 8.0
            : kf(p, const [0, .5, 1], const [8, 15, 8], Curves.easeInOut);
        final a = p == null
            ? .9
            : kf(p, const [0, .5, 1], const [.9, 1, .9], Curves.easeInOut);
        return Container(
          width: 7 * s,
          height: 7 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BergenColors.gold,
            boxShadow: [
              BoxShadow(
                color: BergenColors.gold.withValues(alpha: a),
                blurRadius: onbBlur(g * s),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "+N poeng" — mint, with `popp .5s .4s`.
class _PoengPill extends StatelessWidget {
  const _PoengPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenOnce(
      durationMs: 500,
      delayMs: 400,
      builder: (context, p, child) => Transform.scale(
        scale: kf(p, const [0, .35, .7, 1], const [1, 1.16, .96, 1], kPopp),
        child: child,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(6 * s, 4 * s, 9 * s, 4 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FF0CB), Color(0xFF2FB893)],
          ),
          boxShadow: [
            BoxShadow(color: rgba(255, 255, 255, .6), spreadRadius: 1.5),
            BoxShadow(
              color: rgba(47, 184, 147, .9),
              offset: Offset(0, 6 * s),
              blurRadius: onbBlur(12 * s),
              spreadRadius: -6 * s,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size.square(11 * s),
              painter: _IconPainter(
                const Color(0xFF0F1F2B),
                2.8,
                (k) => Path()
                  ..moveTo(12 * k, 4 * k)
                  ..lineTo(12 * k, 20 * k)
                  ..moveTo(8 * k, 8.5 * k)
                  ..lineTo(14 * k, 8.5 * k)
                  ..arcToPoint(
                    Offset(14 * k, 14.5 * k),
                    radius: Radius.circular(3 * k),
                  )
                  ..lineTo(10 * k, 14.5 * k)
                  ..arcToPoint(
                    Offset(10 * k, 20.5 * k),
                    radius: Radius.circular(3 * k),
                    clockwise: false,
                  )
                  ..lineTo(17 * k, 20.5 * k),
              ),
            ),
            SizedBox(width: 5 * s),
            Text(
              ButikkCopy.a1_butikk_prod_poeng(points),
              style: bText(
                context,
                10,
                weight: FontWeight.w800,
                color: const Color(0xFF0F1F2B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cross extends StatelessWidget {
  const _Cross({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _IconPainter(
      Colors.white,
      2.6,
      (k) => Path()
        ..moveTo(6 * k, 6 * k)
        ..lineTo(18 * k, 18 * k)
        ..moveTo(18 * k, 6 * k)
        ..lineTo(6 * k, 18 * k),
    ),
  );
}

/// A 24-unit stroked icon path, scaled to the paint size.
class _IconPainter extends CustomPainter {
  _IconPainter(this.color, this.stroke, this.path);

  final Color color;
  final double stroke;
  final Path Function(double k) path;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.drawPath(
      path(k),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color;
}

// ── body ────────────────────────────────────────────────────────────────────

class _Head extends StatelessWidget {
  const _Head({
    required this.name,
    required this.description,
    required this.price,
  });

  final String name;
  final String? description;
  final double price;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                key: const Key('a1_butikk_produkt_navn'),
                style: bDisplay(
                  context,
                  22,
                  weight: FontWeight.w800,
                  letterSpacingEm: -.025,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              if (description != null) ...[
                SizedBox(height: 5 * s),
                Text(
                  description!,
                  style: bText(
                    context,
                    12,
                    weight: FontWeight.w600,
                    height: 1.45,
                    color: rgba(255, 255, 255, .66),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12 * s),
        _Glass(
          radius: 16 * s,
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ButikkCopy.kr(price),
                style: bDisplay(
                  context,
                  19,
                  weight: FontWeight.w800,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3 * s),
              Text(
                ButikkCopy.a1_butikk_prod_inkl_mva,
                style: bText(
                  context,
                  9.5,
                  weight: FontWeight.w700,
                  color: rgba(255, 255, 255, .55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `linear-gradient(180deg,rgba(255,255,255,a),rgba(255,255,255,b))`, the
/// hairline, the inset top and the soft drop.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.radius,
    required this.padding,
    required this.child,
    this.top = .16,
    this.bottom = .07,
    this.border = .22,
    this.inset = .3,
    this.drop = const [10, 20, -12],
  });

  final double radius;
  final EdgeInsets padding;
  final Widget child;
  final double top;
  final double bottom;
  final double border;
  final double inset;
  final List<double> drop;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCssShadow(
      radius: radius,
      shadows: [
        BoxShadow(
          color: rgba(4, 18, 26, .85),
          offset: Offset(0, drop[0] * s),
          blurRadius: drop[1] * s,
          spreadRadius: drop[2] * s,
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rgba(255, 255, 255, top), rgba(255, 255, 255, bottom)],
          ),
          border: Border.all(color: rgba(255, 255, 255, border)),
        ),
        child: Stack(
          children: [
            bergenInsetTop(radius: radius, alpha: inset),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _GroupHead extends StatelessWidget {
  const _GroupHead({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          title,
          style: bText(
            context,
            12,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

Widget _hint(BuildContext context, String text, Color color) => Text(
  text,
  style: bText(context, 10.5, weight: FontWeight.w700, color: color),
);

/// «Størrelse» — three cards in a row; the chosen one lifts, orange.
class _CardGroup extends StatelessWidget {
  const _CardGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.keyPrefix,
    required this.onTap,
    this.sizes = false,
  });

  final String title;
  final List<BergenVariant> options;
  final Set<int> selected;
  final String keyPrefix;
  final ValueChanged<BergenVariant> onTap;
  final bool sizes;

  String _sub(BergenVariant v) {
    if (v.priceDelta == 0)
      return sizes ? ButikkCopy.a1_butikk_prod_standard : '';
    final sign = v.priceDelta > 0 ? '+' : '−';
    return '$sign${ButikkCopy.kr(v.priceDelta.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHead(
          title: title,
          trailing: _hint(
            context,
            ButikkCopy.a1_butikk_prod_velg_en,
            rgba(255, 255, 255, .5),
          ),
        ),
        SizedBox(height: 9 * s),
        LayoutBuilder(
          builder: (context, c) {
            final gap = 9 * s;
            final perRow = options.length == 2 ? 2 : 3;
            final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap + 4 * s,
              children: [
                for (final v in options)
                  SizedBox(
                    width: w,
                    child: _Card(
                      key: Key('$keyPrefix${v.id}'),
                      name: v.name,
                      sub: _sub(v),
                      on: selected.contains(v.id),
                      enabled: v.inStock,
                      onTap: () => onTap(v),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.name,
    required this.sub,
    required this.on,
    required this.enabled,
    required this.onTap,
  });

  final String name;
  final String sub;
  final bool on;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    const spring = Cubic(.3, 1.2, .5, 1);
    const dur = Duration(milliseconds: 250);
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: OnbPressable(
        onTap: enabled ? onTap : null,
        pressDy: 0,
        pressScale: .95,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: on ? 1 : 0),
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : dur,
          curve: spring,
          builder: (context, t, child) => Transform.translate(
            offset: Offset(0, -4 * s * t),
            child: Transform.scale(scale: 1 + .04 * t, child: child),
          ),
          child: AnimatedContainer(
            duration: dur,
            curve: spring,
            padding: EdgeInsets.fromLTRB(8 * s, 12 * s, 8 * s, 11 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18 * s),
              gradient: on
                  ? cssLinear(
                      180,
                      const [
                        Color(0xFFF9A273),
                        Color(0xFFF26D3D),
                        Color(0xFFDD5A25),
                      ],
                      const [0, .56, 1],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        rgba(255, 255, 255, .14),
                        rgba(255, 255, 255, .06),
                      ],
                    ),
              border: Border.all(
                color: on ? rgba(255, 255, 255, .55) : rgba(255, 255, 255, .18),
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: rgba(233, 92, 44, .85),
                        offset: Offset(0, 16 * s),
                        blurRadius: onbBlur(26 * s),
                        spreadRadius: -10 * s,
                      ),
                      BoxShadow(
                        color: const Color(0xFFC4491A),
                        offset: Offset(0, 3 * s),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: rgba(4, 18, 26, .8),
                        offset: Offset(0, 10 * s),
                        blurRadius: onbBlur(18 * s),
                        spreadRadius: -12 * s,
                      ),
                      BoxShadow(
                        color: rgba(4, 18, 26, .6),
                        offset: Offset(0, 2 * s),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -8 * s,
                  right: -8 * s,
                  top: -12 * s,
                  bottom: -11 * s,
                  child: Stack(
                    children: [
                      bergenInsetTop(radius: 18 * s, alpha: on ? .45 : .25),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bText(
                          context,
                          12.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (sub.isNotEmpty) ...[
                        SizedBox(height: 2 * s),
                        Text(
                          sub,
                          textAlign: TextAlign.center,
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w700,
                            color: on
                                ? const Color(0xFFFFE2D2)
                                : rgba(255, 255, 255, .55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Tillegg» — a glass card of check rows; the box pops (`valgTikk`).
class _CheckGroup extends StatelessWidget {
  const _CheckGroup({
    required this.title,
    required this.group,
    required this.picked,
    required this.ticked,
    required this.tick,
    required this.onTap,
  });

  final String title;
  final BergenOptionGroup group;
  final Set<int> picked;
  final int? ticked;
  final int tick;
  final ValueChanged<BergenVariant> onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final n = group.options.where((v) => picked.contains(v.id)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHead(
          title: title,
          trailing: _hint(
            context,
            n == 0
                ? ButikkCopy.a1_butikk_prod_valgfritt
                : ButikkCopy.a1_butikk_prod_valgt(n),
            const Color(0xFF7FF0CB),
          ),
        ),
        SizedBox(height: 9 * s),
        _Glass(
          radius: 20 * s,
          padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 2 * s),
          top: .12,
          bottom: .05,
          border: .18,
          inset: .22,
          drop: const [16, 28, -18],
          child: Column(
            children: [
              for (var i = 0; i < group.options.length; i++)
                _CheckRow(
                  key: Key('a1_butikk_prod_opt_${group.options[i].id}'),
                  v: group.options[i],
                  on: picked.contains(group.options[i].id),
                  tick: ticked == group.options[i].id ? tick : null,
                  last: i == group.options.length - 1,
                  onTap: () => onTap(group.options[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    super.key,
    required this.v,
    required this.on,
    required this.tick,
    required this.last,
    required this.onTap,
  });

  final BergenVariant v;
  final bool on;
  final int? tick;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24 * s,
      height: 24 * s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8 * s),
        gradient: on
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7FF0CB), Color(0xFF2FB893)],
              )
            : null,
        color: on ? null : rgba(0, 0, 0, .28),
        border: Border.all(
          color: on ? BergenColors.mint : rgba(255, 255, 255, .28),
          width: 1.5,
        ),
        boxShadow: on
            ? [
                BoxShadow(
                  color: rgba(47, 184, 147, .8),
                  offset: Offset(0, 6 * s),
                  blurRadius: onbBlur(12 * s),
                  spreadRadius: -5 * s,
                ),
                BoxShadow(color: rgba(92, 224, 184, .2), spreadRadius: 3 * s),
              ]
            : null,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: on ? 1 : 0,
        child: CustomPaint(
          size: Size.square(12 * s),
          painter: _IconPainter(
            const Color(0xFF0F1F2B),
            3.4,
            (k) => Path()
              ..moveTo(4.5 * k, 12.5 * k)
              ..lineTo(9.5 * k, 17.5 * k)
              ..lineTo(19.5 * k, 6.5 * k),
          ),
        ),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: v.inStock ? onTap : null,
      child: Opacity(
        opacity: v.inStock ? 1 : .4,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11 * s),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: rgba(255, 255, 255, .1))),
          ),
          child: Row(
            children: [
              tick == null
                  ? box
                  : BergenOnce(
                      key: ValueKey(tick),
                      durationMs: 300,
                      builder: (context, p, child) => Transform.scale(
                        scale: kf(
                          p,
                          const [0, .4, 1],
                          const [1, 1.08, 1],
                          Curves.easeOut,
                        ),
                        child: child,
                      ),
                      child: box,
                    ),
              SizedBox(width: 11 * s),
              Expanded(
                child: Text(
                  v.name,
                  style: bText(
                    context,
                    12.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                v.priceDelta == 0
                    ? ButikkCopy.kr(0)
                    : '+${ButikkCopy.kr(v.priceDelta)}',
                style: bText(
                  context,
                  12,
                  weight: FontWeight.w800,
                  color: v.priceDelta == 0
                      ? rgba(255, 255, 255, .45)
                      : const Color(0xFFFFB27A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Styrke» — a segmented pill; the hottest choice turns orange.
class _StrengthGroup extends StatelessWidget {
  const _StrengthGroup({
    required this.group,
    required this.picked,
    required this.onTap,
  });

  final BergenOptionGroup group;
  final Set<int> picked;
  final ValueChanged<BergenVariant> onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final opts = group.options;
    final sel = opts.indexWhere((v) => picked.contains(v.id));
    final hot = sel == opts.length - 1 && opts.length > 1;
    const spring = Cubic(.3, 1.2, .5, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHead(
          title: group.name,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < opts.length && i < 3; i++) ...[
                if (i > 0) SizedBox(width: 3 * s),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: i <= sel ? 1 : .25,
                  child: CustomPaint(
                    size: Size(11 * s, 12 * s),
                    painter: _ChiliPainter(
                      hot ? BergenColors.orange : BergenColors.mint,
                    ),
                  ),
                ),
              ],
              if (sel >= 0) ...[
                SizedBox(width: 6 * s),
                _hint(context, opts[sel].name, rgba(255, 255, 255, .6)),
              ],
            ],
          ),
        ),
        SizedBox(height: 9 * s),
        Container(
          padding: EdgeInsets.all(3 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: rgba(0, 0, 0, .28),
            border: Border.all(color: rgba(255, 255, 255, .12)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < opts.length; i++) ...[
                if (i > 0) SizedBox(width: 3 * s),
                Expanded(
                  child: GestureDetector(
                    key: Key('a1_butikk_prod_opt_${opts[i].id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(opts[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: spring,
                      padding: EdgeInsets.symmetric(vertical: 9 * s),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: i != sel
                            ? null
                            : hot
                            ? cssLinear(
                                180,
                                const [
                                  Color(0xFFF9A273),
                                  Color(0xFFF26D3D),
                                  Color(0xFFDD5A25),
                                ],
                                const [0, .56, 1],
                              )
                            : cssLinear(
                                180,
                                const [
                                  Color(0xFF3FBF9B),
                                  Color(0xFF2FB893),
                                  Color(0xFF249A7B),
                                ],
                                const [0, .6, 1],
                              ),
                        boxShadow: i != sel
                            ? null
                            : [
                                BoxShadow(
                                  color: hot
                                      ? rgba(242, 109, 61, .9)
                                      : rgba(92, 224, 184, .6),
                                  offset: Offset(0, 4 * s),
                                  blurRadius: onbBlur(10 * s),
                                  spreadRadius: -4 * s,
                                ),
                              ],
                      ),
                      child: Text(
                        opts[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bText(
                          context,
                          11.5,
                          weight: FontWeight.w800,
                          color: i == sel
                              ? Colors.white
                              : rgba(255, 255, 255, .6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChiliPainter extends CustomPainter {
  _ChiliPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final body = Path()
      ..moveTo(14 * k, 3 * k)
      ..cubicTo(15 * k, 6 * k, 13 * k, 8 * k, 11 * k, 9 * k)
      ..cubicTo(16 * k, 9 * k, 20 * k, 14 * k, 19 * k, 19 * k)
      ..cubicTo(18 * k, 24 * k, 12 * k, 26 * k, 8 * k, 24 * k)
      ..cubicTo(4 * k, 22 * k, 3 * k, 17 * k, 5 * k, 13 * k)
      ..cubicTo(6 * k, 11 * k, 8 * k, 9 * k, 10 * k, 9 * k)
      ..cubicTo(8 * k, 8 * k, 7 * k, 5 * k, 8 * k, 3 * k)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
      Path()
        ..moveTo(13 * k, 2 * k)
        ..quadraticBezierTo(15 * k, 2 * k, 17 * k, 4 * k),
      Paint()
        ..color = const Color(0xFF3F8F5F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ChiliPainter old) => old.color != color;
}

class _AllergenLine extends StatelessWidget {
  const _AllergenLine({required this.allergens});

  final List<String> allergens;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: const Key('a1_butikk_produkt_allergener'),
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * s),
        color: rgba(255, 255, 255, .08),
        border: Border.all(color: rgba(255, 255, 255, .14)),
      ),
      child: Row(
        children: [
          CustomPaint(
            size: Size.square(14 * s),
            painter: _IconPainter(
              const Color(0xFF9FD3DE),
              2,
              (k) => Path()
                ..addOval(
                  Rect.fromCircle(
                    center: Offset(12 * k, 12 * k),
                    radius: 9 * k,
                  ),
                )
                ..moveTo(12 * k, 8 * k)
                ..lineTo(12 * k, 13 * k)
                ..moveTo(12 * k, 16 * k)
                ..lineTo(12.01 * k, 16 * k),
            ),
          ),
          SizedBox(width: 9 * s),
          Expanded(
            child: Text(
              allergens.isEmpty
                  ? ButikkCopy.a1_butikk_info_allergen_missing
                  : ButikkCopy.a1_butikk_prod_allergen_linje(
                      allergens.join(', '),
                    ),
              style: bText(
                context,
                11.5,
                weight: FontWeight.w700,
                color: rgba(255, 255, 255, .75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── the bar: quantity and «Legg til» ────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.qty,
    required this.sum,
    required this.tick,
    required this.bottom,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  final int qty;
  final double sum;
  final int tick;
  final double bottom;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    Widget step(IconData icon, VoidCallback? onTap, String key, Color color) =>
        OnbPressable(
          key: Key(key),
          onTap: onTap,
          pressDy: 0,
          pressScale: .8,
          child: SizedBox(
            width: 42 * s,
            height: 44 * s,
            child: Icon(icon, size: 20 * s, color: color),
          ),
        );
    return Container(
      padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00122F3A), Color(0xFF122F3A)],
          stops: [0, .4],
        ),
      ),
      child: BergenCssShadow(
        radius: 999,
        shadows: [
          BoxShadow(
            color: rgba(4, 18, 26, .9),
            offset: Offset(0, 18 * s),
            blurRadius: 34 * s,
            spreadRadius: -16 * s,
          ),
        ],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(6 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: rgba(255, 255, 255, .1),
                border: Border.all(color: rgba(255, 255, 255, .22)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: rgba(0, 0, 0, .3),
                      border: Border(
                        bottom: BorderSide(color: rgba(255, 255, 255, .12)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        step(
                          Icons.remove_rounded,
                          onMinus,
                          'a1_butikk_qty_minus',
                          rgba(255, 255, 255, onMinus == null ? .35 : .7),
                        ),
                        SizedBox(
                          width: 24 * s,
                          child: _PrisTikk(
                            tick: qty,
                            child: Text(
                              '$qty',
                              key: const Key('a1_butikk_qty'),
                              textAlign: TextAlign.center,
                              style: bText(
                                context,
                                15,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        step(
                          Icons.add_rounded,
                          onPlus,
                          'a1_butikk_qty_plus',
                          const Color(0xFFF9A273),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: OnbPressable(
                      key: const Key('a1_butikk_produkt_legg'),
                      onTap: onAdd,
                      pressDy: 2,
                      child: Container(
                        height: 52 * s,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: cssLinear(
                            180,
                            const [
                              Color(0xFFF9A273),
                              Color(0xFFF26D3D),
                              Color(0xFFDD5A25),
                            ],
                            const [0, .56, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rgba(233, 92, 44, .9),
                              offset: Offset(0, 14 * s),
                              blurRadius: onbBlur(26 * s),
                              spreadRadius: -10 * s,
                            ),
                            BoxShadow(
                              color: const Color(0xFFC4491A),
                              offset: Offset(0, 2 * s),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            bergenInsetTop(radius: 999, alpha: .45),
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ButikkCopy.a1_butikk_prod_legg_kort,
                                      style: bText(
                                        context,
                                        14.5,
                                        weight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8 * s),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 56 * s,
                                      ),
                                      child: _PrisTikk(
                                        tick: tick,
                                        child: Text(
                                          ButikkCopy.a1_butikk_prod_sum(
                                            ButikkCopy.kr(sum),
                                          ),
                                          key: const Key(
                                            'a1_butikk_produkt_sum',
                                          ),
                                          textAlign: TextAlign.right,
                                          style: bText(
                                            context,
                                            14.5,
                                            weight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ),
      ),
    );
  }
}
