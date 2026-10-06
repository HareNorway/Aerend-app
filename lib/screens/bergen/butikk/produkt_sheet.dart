import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import '../../snurre/snurre_launcher_policy.dart';
import '../hjem/hjem_harness.dart';
import '../hjem/hjem_vann.dart';
import 'butikk_copy.dart';
import 'produkt_launch.dart';

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
  List<BergenMenuItem> med = const [],
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      // The Snurre launcher stays off over the sheet.
      settings: const RouteSettings(name: '${snurreLauncherHiddenRoutePrefix}produkt'),
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
          med: med,
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
    this.med = const [],
  });

  /// «Ofte kjøpt med»: other dishes from the store.
  final List<BergenMenuItem> med;

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

  /// `pRull`: the hero folds over the first 190px of scroll.
  final ScrollController _rull = ScrollController();
  final ValueNotifier<double> _fold = ValueNotifier(0);

  /// «Ofte kjøpt med» already in the basket.
  final Set<int> _medLagt = {};

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _detail = widget.detail;
    if (_options == null) _loadOptions();
    if (_detail == null) _loadDetail();
    _defaults();
    _rull.addListener(() {
      if (!mounted) return;
      _fold.value = produktRullE(_rull.offset, context.bs);
    });
    if (kDebugMode && HjemHarness.produktScroll != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _rull.hasClients) {
          _rull.jumpTo(HjemHarness.produktScroll! * context.bs);
        }
      });
    }
  }

  @override
  void dispose() {
    _rull.dispose();
    _fold.dispose();
    super.dispose();
  }

  Future<void> _addMed(BergenMenuItem m) async {
    final ok = await BergenCart.add(
      context,
      storeId: m.storeId,
      productId: m.id,
      toast: ButikkCopy.a1_butikk_prod_i_kurven(m.name),
    );
    if (ok && mounted) setState(() => _medLagt.add(m.id));
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
          ProduktTilvalg(
            tittel: ButikkCopy.a1_butikk_prod_storrelse,
            en: true,
            options: o.sizes,
            picked: {if (_size != null) _size!},
            keyPrefix: 'a1_butikk_prod_size_',
            onTap: (v) => _change(() {
                      _size = v.id;
            }),
          ),
        ),
      // `Tilvalg · {tittel}`: one choice as round checks, several as square.
      for (final g in [...cards, ...strength, ...checks])
        trinn(
          ProduktTilvalg(
            tittel: g.name.isEmpty ? ButikkCopy.a1_butikk_prod_tillegg : g.name,
            en: g.single,
            paakrevd: g.required,
            options: g.options,
            picked: _picked,
            keyPrefix: 'a1_butikk_prod_opt_',
            onTap: (v) => _togglePick(g, v),
          ),
        ),
      if (widget.med.isNotEmpty)
        trinn(
          Padding(
            padding: EdgeInsets.only(top: 4 * s),
            child: ProduktOfteMed(items: widget.med, lagt: _medLagt, onAdd: _addMed),
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
                ProduktHero(
                  fold: _fold,
                  imageUrl: item.imageUrl ?? d?.imageUrl,
                  name: item.name,
                  sum: ButikkCopy.kr(_sum),
                  onClose: _close,
                ),
                Flexible(
                  // `pVann`: scrolled, the content sinks under a moving
                  // water surface.
                  child: HjemVann(
                    controller: _rull,
                    s: s,
                    bobler: false,
                    bunn: false,
                    flate: (st) {
                      if (st <= 2) return null;
                      final f = math.min(1.0, st / 40);
                      return (y: 6 + 10 * f, a: f);
                    },
                    child: SingleChildScrollView(
                      controller: _rull,
                      padding: EdgeInsets.fromLTRB(20 * s, 4 * s, 20 * s, 14 * s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < sections.length; i++) ...[
                            if (i > 0) SizedBox(height: 18 * s),
                            sections[i],
                          ],
                        ],
                      ),
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

// ── hero pills ──────────────────────────────────────────────────────────────

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
  });

  final double radius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCssShadow(
      radius: radius,
      shadows: [
        BoxShadow(
          color: rgba(4, 18, 26, .85),
          offset: Offset(0, 10 * s),
          blurRadius: 20 * s,
          spreadRadius: -12 * s,
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rgba(255, 255, 255, .16), rgba(255, 255, 255, .07)],
          ),
          border: Border.all(color: rgba(255, 255, 255, .22)),
        ),
        child: Stack(
          children: [
            bergenInsetTop(radius: radius),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
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
