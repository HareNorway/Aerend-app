import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import '../kit/svg_sti.dart';
import 'butikk_copy.dart';
import 'kategori_kort.dart'
    show
        KatHolo,
        KatLoop,
        KatMyntPille,
        katPerspektiv,
        katZ,
        kKatHoloLys,
        kKatHoloLysStopp,
        kKatHoloSterk,
        kKatHoloSterkStopp;
import 'info_sheet.dart';
import 'produkt_launch.dart' show produktOfteMed;
import 'produkt_sheet.dart';

/// The restaurant page (`erButikk` ≈L3035–3520 in `Ærend Kunde Bergen.dc.html`).
///
/// Top to bottom: the banner hero (logo, name, address · km · Åpent til,
/// "Kjøkkenet er i gang"); the cream card with **SEILASEN DIN** — Ægil rows
/// from the kitchen towards your door as the basket grows, past the store's
/// real minimum order and free-delivery threshold — and the Del / Allergener /
/// Åpent til / Om stedet tiles; **Ærend spesialtilbud** on the Kjøkkenluka
/// stage (the store's discounted dishes on plates under a lamp); the category
/// orbs on an arc; "Mest bestilt" with the menu search pill; the 2-column
/// menu; and the basket: the mini list ("I kurven") and the bar where Ægil
/// pushes the cart, with the total to the Kurv (and the payment).
///
/// The basket is the real cart (`OpsKasseApi.cart`) — plus, minus and remove
/// go through the cart API, so the boat, the bar and the Kurv agree.
class RestaurantButikkBody extends StatefulWidget {
  const RestaurantButikkBody({
    super.key,
    required this.store,
    required this.api,
    required this.customerApi,
    this.kasseApi,
  });

  final BergenStoreInfo store;
  final OpsButikkApi api;
  final OpsCustomerApi customerApi;

  /// Injected in tests.
  final OpsKasseApi? kasseApi;

  @override
  State<RestaurantButikkBody> createState() => RestaurantButikkBodyState();
}

class RestaurantButikkBodyState extends State<RestaurantButikkBody> with TickerProviderStateMixin {
  int _cat = 0; // 0 = Alt, then the store's categories.

  /// The orb whose dishes the grid shows; trails [_cat] by the fade-out.
  int _vist = 0;

  /// `bkBytt`: the grid fades down and out (130 ms), then the new dishes
  /// glide in one after another (360 ms, 40 ms apart).
  late final AnimationController _byttUt = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
  );
  late final AnimationController _byttInn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _kInnMs),
    value: 1,
  );
  Timer? _byttT;
  double _catDx = 0;
  bool _catDrag = false;

  bool _sokOpen = false;
  final TextEditingController _sok = TextEditingController();
  final FocusNode _sokFocus = FocusNode();

  bool _mini = false;
  List<KurvLine> _lines = const [];

  /// Bumped when something lands in the cart: `kurvDunk` + `varefall`.
  int _pulse = 0;

  BergenProductDetail? _detail;
  Map<String, dynamic>? _availability;

  final ScrollController _scroll = ScrollController();

  BergenStoreInfo get store => widget.store;
  OpsKasseApi get _kasse => widget.kasseApi ?? OpsKasseApi();

  @override
  void initState() {
    super.initState();
    _sok.addListener(() => setState(() {}));
    _loadCart();
    _loadSide();
    if (kDebugMode && HjemHarness.butikkOrb != null) {
      _cat = _vist = HjemHarness.butikkOrb!;
    }
    if (kDebugMode && HjemHarness.butikkLegg != null) {
      Future.delayed(const Duration(milliseconds: 1200), () async {
        for (final id in HjemHarness.butikkLegg!) {
          final item = store.allItems.where((i) => i.id == id).firstOrNull;
          if (item != null && mounted) await _plus(item);
        }
        if (mounted && HjemHarness.butikkMini) setState(() => _mini = true);
      });
    }
    if (kDebugMode && HjemHarness.butikkInfo != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final tab = switch (HjemHarness.butikkInfo) {
          't' => InfoTab.apningstider,
          'm' => InfoTab.mer,
          _ => InfoTab.allergener,
        };
        showInfoSheet(context, store: store, initial: tab);
      });
    }
    if (kDebugMode && HjemHarness.butikkScroll != null) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(HjemHarness.butikkScroll! * context.bs);
        }
      });
    }
  }

  @override
  void dispose() {
    _byttT?.cancel();
    _byttUt.dispose();
    _byttInn.dispose();
    _scroll.dispose();
    _sok.dispose();
    _sokFocus.dispose();
    super.dispose();
  }

  void _bytt(int i) {
    if (i == _vist && _byttT == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _vist = i);
      return;
    }
    _byttT?.cancel();
    _byttInn.value = 1;
    _byttUt.forward(from: 0);
    _byttT = Timer(const Duration(milliseconds: 120), () {
      _byttT = null;
      if (!mounted) return;
      setState(() => _vist = i);
      _byttUt.value = 0;
      _byttInn.forward(from: 0);
    });
  }

  Future<void> _loadCart({bool pulse = false}) async {
    final cart = await _kasse.cart();
    if (!mounted) return;
    setState(() {
      _lines = [
        for (final l in cart.lines)
          if (l.storeId == store.id) l,
      ];
      if (pulse) _pulse++;
      if (_lines.isEmpty) _mini = false;
    });
  }

  Future<void> _loadSide() async {
    final first = store.allItems.firstOrNull;
    if (first != null) {
      final d = await widget.api.productDetail(first.id);
      if (mounted && d != null) setState(() => _detail = d);
    }
    final avail = await widget.customerApi.driftNotice(storeId: store.id);
    if (mounted && avail != null) setState(() => _availability = avail);
  }

  // ── the basket ──────────────────────────────────────────────────────────

  double get _subtotal => _lines.fold(0, (a, l) => a + l.sum);
  int get _count => _lines.fold(0, (a, l) => a + l.quantity);

  /// Free delivery when the store charges none, or past its threshold.
  bool get _freeDelivery {
    final fee = store.deliveryChargeKr ?? 0;
    if (fee <= 0) return true;
    final t = store.offerMinAmountKr ?? 0;
    return t > 0 && _subtotal >= t;
  }

  double get _total => _subtotal + (_freeDelivery ? 0 : (store.deliveryChargeKr ?? 0));

  int _qtyOf(int productId) => _lines.where((l) => l.productId == productId).fold(0, (a, l) => a + l.quantity);

  Future<void> _plus(BergenMenuItem item) async {
    final ok = await BergenCart.add(
      context,
      storeId: item.storeId,
      productId: item.id,
      toast: ButikkCopy.a1_butikk_prod_i_kurven(item.name),
    );
    if (ok) await _loadCart(pulse: true);
  }

  Future<void> _minusLine(KurvLine l) async {
    HapticFeedback.selectionClick();
    final ok = l.quantity > 1 ? await _kasse.changeQuantity(l.cartId, l.quantity - 1) : await _kasse.remove(l.cartId);
    if (ok) await _loadCart();
  }

  Future<void> _plusLine(KurvLine l) async {
    HapticFeedback.selectionClick();
    final ok = await _kasse.changeQuantity(l.cartId, l.quantity + 1);
    if (ok) await _loadCart(pulse: true);
  }

  Future<void> _removeLine(KurvLine l) async {
    HapticFeedback.selectionClick();
    final ok = await _kasse.remove(l.cartId);
    if (!mounted) return;
    if (ok) showBergenToast(context, ButikkCopy.a1_butikk_ut_av_kurven(l.name));
    await _loadCart();
  }

  Future<void> _minus(BergenMenuItem item) async {
    final l = _lines.where((l) => l.productId == item.id).lastOrNull;
    if (l != null) await _minusLine(l);
  }

  Future<void> _empty() async {
    for (final l in [..._lines]) {
      await _kasse.remove(l.cartId);
    }
    await _loadCart();
  }

  void _toKurv() => BergenRoutes.push(context, '/bergen/kurv');

  void open(BergenMenuItem item, {bool mostOrdered = false}) {
    showProduktSheet(
      context,
      item: item,
      api: widget.api,
      customerApi: widget.customerApi,
      readyMinutes: _detail?.readyMinutes ?? store.deliveryMinutes,
      mostOrdered: mostOrdered,
      med: produktOfteMed(item, store.allItems),
    ).then((_) {
      if (mounted) _loadCart(pulse: true);
    });
  }

  void _askAegil() => BergenRoutes.pushOr(
    context,
    kAegilRoute,
    arguments: {'intent': 'store', 'store_id': '${store.id}', 'store': store.name},
    orElse: () => openScreen(context, const SnurreChatScreen()),
  );

  Future<void> _share() async {
    await Clipboard.setData(ClipboardData(text: 'aerend://bergen/butikk/${store.id}'));
    if (mounted) showBergenToast(context, ButikkCopy.a1_butikk_info_kopiert);
  }

  // ── the menu ────────────────────────────────────────────────────────────

  /// `bkListe`: Alt, Tilbud (when the kitchen has specials), then the
  /// store's own categories.
  List<String> get _orbNavn => [
    ButikkCopy.a1_butikk_alt,
    if (store.specials.isNotEmpty) ButikkCopy.a1_butikk_tilbud,
    for (final c in store.menu) c.name,
  ];

  int get _menyStart => store.specials.isNotEmpty ? 2 : 1;

  /// `visTilbud`: the Tilbud orb shows the specials as offer cards.
  bool get _erTilbud => store.specials.isNotEmpty && _vist == 1 && _sok.text.trim().isEmpty;

  List<BergenMenuItem> get _visible {
    final q = _sok.text.trim().toLowerCase();
    final base = _vist == 0 || _vist < _menyStart
        ? store.allItems
        : store.menu[(_vist - _menyStart).clamp(0, store.menu.length - 1)].items;
    if (q.isEmpty) return base;
    return [
      for (final i in store.allItems)
        if (i.name.toLowerCase().contains(q) || (i.description ?? '').toLowerCase().contains(q)) i,
    ];
  }

  void _toggleSok() {
    setState(() => _sokOpen = !_sokOpen);
    if (_sokOpen) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted && _sokOpen) _sokFocus.requestFocus();
      });
    } else {
      _sok.clear();
      _sokFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final mq = MediaQuery.of(context);
    final specials = store.specials.take(3).toList();
    final items = _visible;
    final hasCart = _lines.isNotEmpty;
    final barBottom = math.max(18 * s, mq.padding.bottom);

    return Scaffold(
      backgroundColor: BergenColors.teal3,
      body: BergenOnce(
        durationMs: 340,
        builder: (context, p, child) {
          final e = kSkjermInn.transform(p);
          return Opacity(
            opacity: e.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, 10 * (1 - e)), child: child),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinear(180, const [Color(0xFF1E4F5C), Color(0xFF1B4854), Color(0xFF173E48)], const [0, .4, 1]),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                key: const Key('a1_butikk_scroll'),
                controller: _scroll,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: 180 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(
                      store: store,
                      kitchen: _kitchenText,
                      onBack: () => Navigator.of(context).maybePop(),
                      perKjop: _perKjop,
                    ),
                    Transform.translate(
                      offset: Offset(0, -22 * s),
                      child: _CreamCard(
                        store: store,
                        subtotal: _subtotal,
                        onAegil: _askAegil,
                        onShare: _share,
                        onInfo: (tab) => showInfoSheet(context, store: store, initial: tab),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -22 * s),
                      child: _CategoryRail(
                        names: _orbNavn,
                        active: _cat,
                        dx: _catDx,
                        dragging: _catDrag,
                        onPick: (i) {
                          setState(() => _cat = i);
                          _bytt(i);
                        },
                        onDrag: (dx) => setState(() {
                          _catDrag = true;
                          _catDx = dx;
                        }),
                        onRelease: () {
                          final n = _orbNavn.length;
                          final steps = (_catDx / _CategoryRail.step).round();
                          setState(() {
                            _cat = ((_cat - steps) % n + n) % n;
                            _catDx = 0;
                            _catDrag = false;
                          });
                          if (steps != 0) HapticFeedback.selectionClick();
                          _bytt(_cat);
                        },
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -22 * s),
                      child: _MenuHead(
                        title: _vist == 0 ? ButikkCopy.a1_butikk_mest_bestilt : _orbNavn[_vist],
                        open: _sokOpen,
                        controller: _sok,
                        focus: _sokFocus,
                        onToggle: _toggleSok,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -22 * s),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_byttUt, _byttInn]),
                        builder: (context, child) {
                          final u = const Cubic(.4, 0, 1, 1).transform(_byttUt.value);
                          final inn = (_byttInn.value * _kInnMs / 160).clamp(0.0, 1.0);
                          if (u == 0 && inn == 1) return child!;
                          return Opacity(
                            opacity: (1 - u) * inn,
                            child: Transform.translate(offset: Offset(0, 8 * s * u), child: child),
                          );
                        },
                        child: _erTilbud
                            ? _KortInn(
                                anim: _byttInn,
                                i: 0,
                                child: _TilbudGrid(specials: specials, onOpen: (i) => open(i), onAdd: (i) => _plus(i)),
                              )
                            : _Grid(
                                items: items,
                                inn: _byttInn,
                                query: _sok.text.trim(),
                                readyMinutes: _detail?.readyMinutes,
                                mostOrderedId: _vist == 0 && _sok.text.trim().isEmpty
                                    ? store.allItems.firstOrNull?.id
                                    : null,
                                qtyOf: _qtyOf,
                                onOpen: open,
                                onPlus: _plus,
                                onMinus: _minus,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_mini && hasCart)
                Positioned(
                  left: 16 * s,
                  right: 16 * s,
                  bottom: barBottom + 72 * s,
                  child: ButikkMiniKurv(
                    lines: _lines,
                    onEmpty: _empty,
                    onMinus: _minusLine,
                    onPlus: _plusLine,
                    onRemove: _removeLine,
                  ),
                ),
              if (hasCart)
                Positioned(
                  left: 16 * s,
                  right: 16 * s,
                  bottom: barBottom,
                  child: ButikkKurvBar(
                    lines: _lines,
                    count: _count,
                    total: _total,
                    pulse: _pulse,
                    mini: _mini,
                    onToggle: () => setState(() => _mini = !_mini),
                    onPay: _toKurv,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "+N per kjøp": the points a typical 300 kr order earns at this store's
  /// rate (`points_per_10kr`); hidden until the rate is known.
  int? get _perKjop {
    final r = _detail?.pointsPer10Kr;
    return r == null || r <= 0 ? null : r * 30;
  }

  String get _kitchenText {
    final a = _availability;
    if (a != null && a['state'] != null && a['state'] != 'open') {
      return ButikkCopy.a1_butikk_pauset;
    }
    if (!store.open) {
      return store.openTime != null ? ButikkCopy.a1_butikk_apner(store.openTime!) : ButikkCopy.a1_butikk_stengt;
    }
    return ButikkCopy.a1_butikk_kjokken;
  }
}

// ── shared ──────────────────────────────────────────────────────────────────

/// CSS `radial-gradient(<rx>% <ry>% at <cx>% <cy>%, …)` for a [RadialGradient]
/// with `radius: 1` and its centre at (cx, cy): stretches Flutter's circle
/// (radius = the box's shortest side) into the CSS ellipse.
class _CssRadial extends GradientTransform {
  const _CssRadial(this.cx, this.cy, this.rx, this.ry);

  final double cx, cy, rx, ry;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final r = math.min(bounds.width, bounds.height);
    final c = Offset(bounds.left + bounds.width * cx, bounds.top + bounds.height * cy);
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(rx * bounds.width / r, ry * bounds.height / r, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

const List<Color> _kOrange3 = [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)];

/// A 24-unit stroked icon path, scaled to [size].
class _Ico extends StatelessWidget {
  const _Ico(this.size, this.color, this.stroke, this.path, {this.fill});

  final double size;
  final Color color;
  final double stroke;
  final Path Function(double k) path;
  final Color? fill;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _IcoPainter(color, stroke, path, fill));
}

class _IcoPainter extends CustomPainter {
  _IcoPainter(this.color, this.stroke, this.path, this.fill);

  final Color color;
  final double stroke;
  final Path Function(double k) path;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = path(k);
    if (fill != null) canvas.drawPath(p, Paint()..color = fill!);
    if (stroke > 0) {
      canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * k
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_IcoPainter old) => old.color != color || old.fill != fill;
}

Path _chevron(double k, {bool left = false, bool up = false}) {
  if (up) {
    return Path()
      ..moveTo(6 * k, 15 * k)
      ..lineTo(12 * k, 9 * k)
      ..lineTo(18 * k, 15 * k);
  }
  return left
      ? (Path()
          ..moveTo(15 * k, 6 * k)
          ..lineTo(9 * k, 12 * k)
          ..lineTo(15 * k, 18 * k))
      : (Path()
          ..moveTo(9 * k, 6 * k)
          ..lineTo(15 * k, 12 * k)
          ..lineTo(9 * k, 18 * k));
}

Path _plusPath(double k, [double a = 5, double b = 19]) => Path()
  ..moveTo(12 * k, a * k)
  ..lineTo(12 * k, b * k)
  ..moveTo(a * k, 12 * k)
  ..lineTo(b * k, 12 * k);

Widget _logo(String? url) => url == null
    ? const ColoredBox(color: Color(0xFFFBF7EE))
    : Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFFBF7EE)),
      );

/// `livePuls` — a ring breathing out of a dot.
class _LivePuls extends StatelessWidget {
  const _LivePuls({required this.size, required this.color, this.inset = 3});

  final double size;
  final Color color;
  final double inset;

  @override
  Widget build(BuildContext context) => Positioned(
    left: -inset,
    top: -inset,
    width: size + inset * 2,
    height: size + inset * 2,
    child: IgnorePointer(
      child: BergenLoop(
        durationMs: 1800,
        builder: (context, p, child) {
          if (p == null) return const SizedBox.shrink();
          final e = Curves.easeOut.transform(p);
          return Opacity(
            opacity: .9 * (1 - e),
            child: Transform.scale(scale: .6 + 1.3 * e, child: child),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
      ),
    ),
  );
}

/// `damp` — a puff of steam rising 38px and spreading.
class _Damp extends StatelessWidget {
  const _Damp({
    required this.left,
    required this.top,
    required this.w,
    required this.h,
    required this.color,
    this.delay = 0,
  });

  final double left;
  final double top;
  final double w;
  final double h;
  final Color color;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: left * s,
      top: top * s,
      child: IgnorePointer(
        child: BergenLoop(
          durationMs: 2400,
          delayMs: delay,
          builder: (context, p, child) {
            if (p == null) return const SizedBox.shrink();
            final e = Curves.easeOut.transform(p);
            final o = p < .28 ? .5 * p / .28 : .5 * (1 - (p - .28) / .72);
            return Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (8 - 38 * e) * s),
                child: Transform.scale(scaleX: .7 + .65 * e, scaleY: 1, child: child),
              ),
            );
          },
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s),
            child: Container(
              width: w * s,
              height: h * s,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(Radius.elliptical(w * s / 2, h * s / 2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatefulWidget {
  const _Hero({required this.store, required this.kitchen, required this.onBack, this.perKjop});

  final BergenStoreInfo store;
  final String kitchen;
  final VoidCallback onBack;

  /// "+65 per kjøp"; null hides the coin.
  final int? perKjop;

  @override
  State<_Hero> createState() => _HeroState();
}

/// The store's photo in 3D: it follows the finger (`data-tilt="6"`), the
/// photo sits behind (`translateZ(-30px) scale(1.08)`) under a slow Ken
/// Burns, a colour-dodge holo and a light sweep; the coin, the logo and the
/// name stand out in front.
class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  Offset _tilt = Offset.zero, _tiltFra = Offset.zero;
  Offset _lys = const Offset(.4, .3), _lysFra = const Offset(.4, .3);

  @override
  void initState() {
    super.initState();
    _back.addListener(() {
      final e = const Cubic(.3, 1.4, .5, 1).transform(_back.value);
      setState(() {
        _tilt = Offset.lerp(_tiltFra, Offset.zero, e)!;
        _lys = Offset.lerp(_lysFra, const Offset(.4, .3), e)!;
      });
    });
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _move(PointerEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final l = box.globalToLocal(e.position);
    final x = (l.dx / box.size.width).clamp(0.0, 1.0);
    final y = (l.dy / box.size.height).clamp(0.0, 1.0);
    _back.stop();
    setState(() {
      _tilt = Offset((.5 - y) * 6, (x - .5) * 6 * 1.3);
      _lys = Offset(x, y);
    });
  }

  void _release() {
    _tiltFra = _tilt;
    _lysFra = _lys;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final store = widget.store;
    final safeTop = MediaQuery.paddingOf(context).top;
    final dy = math.max(0.0, safeTop - 20 * s);
    final address = (store.address ?? '').split(',').first.trim();
    final meta = <String>[
      if (address.isNotEmpty) address,
      if (store.distanceKm != null) ButikkCopy.a1_butikk_km(store.distanceKm!),
      if (store.closeTime != null) ButikkCopy.a1_butikk_open_til(store.closeTime!),
    ];
    final shadowText = [Shadow(color: rgba(10, 5, 2, .9), blurRadius: 10 * s)];
    const d = math.pi / 180;
    return SizedBox(
      height: 266 * s + dy,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF2A1410)),
            Listener(
              onPointerDown: _move,
              onPointerMove: _move,
              onPointerUp: (_) => _release(),
              onPointerCancel: (_) => _release(),
              child: Transform(
                alignment: Alignment.center,
                transform: katPerspektiv(900)
                  ..rotateX(_tilt.dx * d)
                  ..rotateY(_tilt.dy * d),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // The photo layer, set back (`translateZ(-30px) scale(1.08)`).
                    Positioned(
                      left: -14 * s,
                      top: -14 * s,
                      right: -14 * s,
                      bottom: -14 * s,
                      child: katZ(
                        -30 * s,
                        Transform.scale(
                          scale: 1.08,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const ColoredBox(color: Color(0xFF2A1410)),
                                if (store.bannerUrl != null) RepaintBoundary(child: _KenBurns(url: store.bannerUrl!)),
                                const IgnorePointer(
                                  child: KatHolo(
                                    farger: kKatHoloSterk,
                                    stopp: kKatHoloSterkStopp,
                                    dodge: .3,
                                    halvMs: 6000,
                                  ),
                                ),
                                const IgnorePointer(child: _SveipLys()),
                                IgnorePointer(child: CustomPaint(painter: _LysOverlay(_lys))),
                                // `radial-gradient(120% 78% at 52% 26%, transparent 34%,
                                // rgba(14,6,3,.55))`.
                                const IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment(.04, -.48),
                                        radius: 1,
                                        colors: [Color(0x000E0603), Color(0x000E0603), Color(0x8C0E0603)],
                                        stops: [0, .34, 1],
                                        transform: _CssRadial(.52, .26, 1.2, .78),
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
                    Positioned(
                      left: -14 * s,
                      right: -14 * s,
                      top: -14 * s,
                      height: 118 * s + dy,
                      child: const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x8C0E0703), Color(0x240E0703), Color(0x000E0703)],
                              stops: [0, .62, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -14 * s,
                      right: -14 * s,
                      bottom: -14 * s,
                      height: 184 * s,
                      child: const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x000D0603), Color(0x730D0603), Color(0xE60D0603)],
                              stops: [0, .42, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.perKjop != null)
                      Positioned(
                        right: 18 * s,
                        bottom: 122 * s,
                        child: katZ(
                          22 * s,
                          KatMyntPille(
                            key: const Key('a1_butikk_per_kjop'),
                            tekst: ButikkCopy.a1_butikk_per_kjop(widget.perKjop!),
                            hoyde: 30,
                            mynt: 16,
                            fontPx: 12,
                            faseMs: 0,
                            skygge: true,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 24 * s,
                      right: 20 * s,
                      bottom: 38 * s,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          katZ(
                            30 * s,
                            Container(
                              width: 68 * s,
                              height: 68 * s,
                              padding: EdgeInsets.all(7 * s),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: rgba(10, 5, 2, .6),
                                    offset: Offset(0, 16 * s),
                                    blurRadius: onbBlur(22 * s),
                                    spreadRadius: -8 * s,
                                  ),
                                  BoxShadow(color: const Color(0xFFFFFBF5), spreadRadius: 4 * s),
                                ],
                              ),
                              child: ClipOval(child: _logo(store.logoUrl)),
                            ),
                          ),
                          SizedBox(width: 14 * s),
                          Expanded(
                            child: katZ(
                              16 * s,
                              Padding(
                                padding: EdgeInsets.only(bottom: 4 * s),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      key: const Key('a1_butikk_navn'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          bDisplay(
                                            context,
                                            28,
                                            weight: FontWeight.w800,
                                            letterSpacingEm: -.038,
                                            height: 1,
                                            color: Colors.white,
                                          ).copyWith(
                                            shadows: [
                                              Shadow(
                                                color: rgba(10, 5, 2, .8),
                                                offset: Offset(0, 2 * s),
                                                blurRadius: 16 * s,
                                              ),
                                            ],
                                          ),
                                    ),
                                    SizedBox(height: 6 * s),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 7 * s,
                                      runSpacing: 2 * s,
                                      children: [
                                        for (var i = 0; i < meta.length; i++) ...[
                                          if (i > 0)
                                            Container(
                                              width: 3 * s,
                                              height: 3 * s,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: rgba(255, 255, 255, .55),
                                              ),
                                            ),
                                          Text(
                                            meta[i],
                                            style: bText(
                                              context,
                                              11.5,
                                              weight: FontWeight.w700,
                                              color: rgba(255, 255, 255, .93),
                                              shadows: shadowText,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: dy + 14 * s,
              left: 16 * s,
              right: 16 * s,
              child: Row(
                children: [
                  OnbPressable(
                    key: const Key('a1_butikk_back'),
                    onTap: widget.onBack,
                    pressDy: 0,
                    pressScale: .9,
                    child: Container(
                      width: 38 * s,
                      height: 38 * s,
                      alignment: Alignment.center,
                      decoration: _heroGlass(s, circle: true),
                      child: _Ico(15 * s, BergenColors.ink, 2.6, (k) => _chevron(k, left: true)),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.fromLTRB(11 * s, 7 * s, 13 * s, 7 * s),
                    decoration: _heroGlass(s),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 7 * s,
                          height: 7 * s,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0662C)),
                              ),
                              _LivePuls(size: 7 * s, color: rgba(224, 102, 44, .55), inset: 3 * s),
                            ],
                          ),
                        ),
                        SizedBox(width: 7 * s),
                        Text(
                          widget.kitchen,
                          key: const Key('a1_butikk_kjokken'),
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w800,
                            letterSpacingEm: .01,
                            color: BergenColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `kenBurns 16s ease-in-out infinite alternate`: scale 1 → 1.14 and
/// translate(-2.5%, 1.5%).
class _KenBurns extends StatelessWidget {
  const _KenBurns({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => KatLoop(
    durationMs: 32000,
    child: Image.network(
      url,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -.2),
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
    builder: (context, p, child) {
      final raw = p * 2;
      final e = Curves.easeInOut.transform(raw <= 1 ? raw : 2 - raw);
      return LayoutBuilder(
        builder: (context, c) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(1 + .14 * e, 1 + .14 * e, 1, 1)
            ..translateByDouble(-.025 * c.maxWidth * e, .015 * c.maxHeight * e, 0, 1),
          child: child,
        ),
      );
    },
  );
}

/// `sveipLys 8s 1.2s ease-in-out infinite` — a soft light band crossing the
/// photo (100°, white .2 at the centre) in the first 45% of each cycle.
class _SveipLys extends StatelessWidget {
  const _SveipLys();

  @override
  Widget build(BuildContext context) => BergenLoop(
    durationMs: 8000,
    delayMs: 1200,
    builder: (context, p, _) {
      if (p == null || p > .45) return const SizedBox.shrink();
      final x = kf(p, const [0, .45], const [-1.2, 1.2], Curves.easeInOut);
      return LayoutBuilder(
        builder: (context, c) {
          // The band's box is the photo grown by 40% / 60% each side.
          final w = c.maxWidth * 2.2, h = c.maxHeight * 1.8;
          return OverflowBox(
            maxWidth: w,
            maxHeight: h,
            child: Transform.translate(
              offset: Offset(x * w, 0),
              child: SizedBox(
                width: w,
                height: h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: cssLinear(
                      100,
                      const [
                        Color.fromRGBO(255, 255, 255, 0),
                        Color.fromRGBO(255, 255, 255, .2),
                        Color.fromRGBO(255, 255, 255, 0),
                      ],
                      const [.44, .5, .56],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// `radial-gradient(circle at var(--mx) var(--my), rgba(255,255,255,.45),
/// transparent 45%)`, `mix-blend-mode: overlay`.
class _LysOverlay extends CustomPainter {
  _LysOverlay(this.lys);

  final Offset lys;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(lys.dx * size.width, lys.dy * size.height);
    final r = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((k) => (k - c).distance).reduce(math.max);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.overlay
        ..shader = ui.Gradient.radial(
          c,
          r,
          const [Color.fromRGBO(255, 255, 255, .45), Color.fromRGBO(255, 255, 255, 0)],
          const [0, .45],
        ),
    );
  }

  @override
  bool shouldRepaint(_LysOverlay old) => old.lys != lys;
}

BoxDecoration _heroGlass(double s, {bool circle = false}) => BoxDecoration(
  color: rgba(255, 255, 255, .92),
  shape: circle ? BoxShape.circle : BoxShape.rectangle,
  borderRadius: circle ? null : BorderRadius.circular(999),
  boxShadow: [
    BoxShadow(color: rgba(10, 5, 2, .9), offset: Offset(0, 10 * s), blurRadius: onbBlur(20 * s), spreadRadius: -10 * s),
    BoxShadow(color: rgba(255, 255, 255, .5), offset: Offset(0, 2 * s)),
  ],
);

// ── the cream card: Seilas + tiles ──────────────────────────────────────────

class _CreamCard extends StatelessWidget {
  const _CreamCard({
    required this.store,
    required this.subtotal,
    required this.onAegil,
    required this.onShare,
    required this.onInfo,
  });

  final BergenStoreInfo store;
  final double subtotal;
  final VoidCallback onAegil;
  final VoidCallback onShare;
  final ValueChanged<InfoTab> onInfo;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    // `radial-gradient(90% 40% at 20% 0%, rgba(255,255,255,.14), transparent
    // 60%), linear-gradient(180deg,#2F6C7E,#225868 40%,#1B4854)`.
    return Container(
      padding: EdgeInsets.only(bottom: 18 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * s),
        gradient: cssLinear(180, const [Color(0xFF2F6C7E), Color(0xFF225868), Color(0xFF1B4854)], const [0, .4, 1]),
        boxShadow: [
          BoxShadow(
            color: rgba(4, 26, 34, .35),
            offset: Offset(0, 10 * s),
            blurRadius: onbBlur(16 * s),
            spreadRadius: -8 * s,
          ),
          BoxShadow(
            color: rgba(4, 18, 26, .6),
            offset: Offset(0, -6 * s),
            blurRadius: onbBlur(14 * s),
            spreadRadius: -8 * s,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * s),
        gradient: RadialGradient(
          center: const Alignment(-.6, -1),
          radius: 1,
          colors: [rgba(255, 255, 255, .14), rgba(255, 255, 255, 0)],
          stops: const [0, .6],
          transform: const _CssRadial(.2, 0, .9, .4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
            child: _Seilas(store: store, subtotal: subtotal, onAegil: onAegil),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 0),
            child: Row(
              children: [
                _Tile(
                  key: const Key('a1_butikk_del'),
                  label: ButikkCopy.a1_butikk_del,
                  inset: .3,
                  colors: const [Color(0xFF3A7080), Color(0xFF22515E)],
                  edge: rgba(11, 38, 45, .55),
                  glow: rgba(23, 62, 72, .9),
                  icon: (k) => Path()
                    ..moveTo(12 * k, 15 * k)
                    ..lineTo(12 * k, 4 * k)
                    ..moveTo(7.5 * k, 8.5 * k)
                    ..lineTo(12 * k, 4 * k)
                    ..lineTo(16.5 * k, 8.5 * k)
                    ..moveTo(5 * k, 14 * k)
                    ..lineTo(5 * k, 19 * k)
                    ..lineTo(19 * k, 19 * k)
                    ..lineTo(19 * k, 14 * k),
                  onTap: onShare,
                ),
                SizedBox(width: 8 * s),
                _Tile(
                  key: const Key('a1_butikk_info_a'),
                  label: ButikkCopy.a1_butikk_allergener,
                  inset: .4,
                  colors: _kOrange3,
                  stops: const [0, .6, 1],
                  edge: const Color(0xFFC4491A),
                  glow: rgba(200, 70, 25, .9),
                  icon: (k) => Path()
                    ..moveTo(12 * k, 3 * k)
                    ..lineTo(14.6 * k, 8.6 * k)
                    ..lineTo(20.6 * k, 9.4 * k)
                    ..lineTo(16.2 * k, 13.6 * k)
                    ..lineTo(17.3 * k, 19.6 * k)
                    ..lineTo(12 * k, 16.8 * k)
                    ..lineTo(6.7 * k, 19.6 * k)
                    ..lineTo(7.8 * k, 13.6 * k)
                    ..lineTo(3.4 * k, 9.4 * k)
                    ..lineTo(9.4 * k, 8.6 * k)
                    ..close(),
                  onTap: () => onInfo(InfoTab.allergener),
                ),
                SizedBox(width: 8 * s),
                _Tile(
                  key: const Key('a1_butikk_info_t'),
                  label: store.closeTime != null
                      ? ButikkCopy.a1_butikk_open_til(store.closeTime!)
                      : ButikkCopy.a1_butikk_apningstider,
                  colors: const [Color(0xFF7FF0CB), Color(0xFF2FB893)],
                  edge: const Color(0xFF1F8F6E),
                  glow: rgba(47, 184, 147, .9),
                  ink: const Color(0xFF0F1F2B),
                  icon: (k) => Path()
                    ..addOval(Rect.fromCircle(center: Offset(12 * k, 12 * k), radius: 8.5 * k))
                    ..moveTo(12 * k, 7.5 * k)
                    ..lineTo(12 * k, 12 * k)
                    ..lineTo(15 * k, 14 * k),
                  onTap: () => onInfo(InfoTab.apningstider),
                ),
                SizedBox(width: 8 * s),
                _Tile(
                  key: const Key('a1_butikk_info_m'),
                  label: ButikkCopy.a1_butikk_om_stedet,
                  colors: const [Color(0xFFF2C14E), Color(0xFFD9A020)],
                  edge: const Color(0xFFA87A12),
                  glow: rgba(217, 160, 32, .9),
                  ink: BergenColors.ink,
                  icon: (k) => Path()
                    ..addOval(Rect.fromCircle(center: Offset(12 * k, 12 * k), radius: 8.5 * k))
                    ..moveTo(12 * k, 11 * k)
                    ..lineTo(12 * k, 16 * k)
                    ..moveTo(12 * k, 7.5 * k)
                    ..lineTo(12 * k, 8 * k),
                  onTap: () => onInfo(InfoTab.mer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.colors,
    this.stops,
    required this.edge,
    required this.glow,
    required this.icon,
    required this.onTap,
    this.ink = Colors.white,
    this.inset = .45,
  });

  /// The icon square's `inset 0 1.5px 0 rgba(255,255,255,a)`.
  final double inset;

  final String label;
  final List<Color> colors;
  final List<double>? stops;
  final Color edge;
  final Color glow;
  final Path Function(double k) icon;
  final VoidCallback onTap;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Expanded(
      child: OnbPressable(
        onTap: onTap,
        pressDy: 0,
        pressScale: .95,
        child: Container(
          height: 58 * s,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16 * s),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [rgba(255, 255, 255, .14), rgba(255, 255, 255, .06)],
            ),
            boxShadow: [
              BoxShadow(
                color: rgba(4, 18, 26, .7),
                offset: Offset(0, 10 * s),
                blurRadius: onbBlur(18 * s),
                spreadRadius: -12 * s,
              ),
              BoxShadow(color: rgba(4, 18, 26, .45), offset: Offset(0, 2 * s)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30 * s,
                height: 30 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10 * s),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors,
                    stops: stops,
                  ),
                  boxShadow: [
                    BoxShadow(color: glow, offset: Offset(0, 8 * s), blurRadius: onbBlur(12 * s), spreadRadius: -8 * s),
                    BoxShadow(color: edge, offset: Offset(0, 2 * s)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    bergenInsetTop(radius: 10 * s, height: 1.5 * s, alpha: inset),
                    _Ico(15 * s, ink, 2.3, icon),
                  ],
                ),
              ),
              SizedBox(height: 5 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * s),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bText(context, 9.5, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SEILASEN DIN — the boat rows from the kitchen to your door. The marks
/// are the store's real minimum order and free-delivery threshold; the
/// design's Dessert / 10 % / 800 kr tiers have no backend and are not shown.
class _Seilas extends StatelessWidget {
  const _Seilas({required this.store, required this.subtotal, required this.onAegil});

  final BergenStoreInfo store;
  final double subtotal;
  final VoidCallback onAegil;

  /// The free-delivery threshold, when delivery costs anything.
  double? get _free {
    final t = store.offerMinAmountKr ?? 0;
    final fee = store.deliveryChargeKr ?? 0;
    return t > 0 && fee > 0 ? t : null;
  }

  double? get _min {
    final m = store.minOrderKr ?? 0;
    return m > 0 ? m : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final free = _free;
    final min = _min;
    final goal = free ?? min;
    // The boat reaches the free-delivery mark (at .7 of the water) at the
    // threshold, as the design places it; with no threshold, the goal is the
    // door.
    final double frac;
    if (free != null) {
      frac = .7 * (subtotal / free).clamp(0.0, 1.0);
    } else if (min != null) {
      frac = (subtotal / min).clamp(0.0, 1.0);
    } else {
      frac = subtotal > 0 ? 1.0 : 0.0;
    }
    final reached = free != null && subtotal >= free;
    final (double, String)? next = min != null && subtotal < min
        ? (min, ButikkCopy.a1_butikk_minstebestilling)
        : free != null && subtotal < free
        ? (free, ButikkCopy.a1_butikk_gratis_levering)
        : null;
    final mins = store.deliveryMinutes;

    // `border-radius:26px; overflow:hidden; background:transparent` — the
    // voyage sits straight on the teal sheet.
    return Container(
      key: const Key('a1_butikk_seilas'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26 * s)),
      child: Stack(
        children: [
          // `onbLysDrift` light and the `onbRing` wake.
          Positioned(
            left: -60 * s,
            top: -50 * s,
            child: IgnorePointer(
              child: BergenLoop(
                durationMs: 17000,
                builder: (context, p, child) {
                  final q = p ?? 0;
                  final e = Curves.easeInOut.transform(q < .5 ? q * 2 : (1 - q) * 2);
                  return Transform.translate(
                    offset: Offset(14 * s * e, -10 * s * e),
                    child: Transform.scale(scale: 1 + .06 * e, child: child),
                  );
                },
                // The `blur(22px)` is folded into a wider, softer radial:
                // the same light without re-blurring every frame.
                child: Container(
                  width: 240 * s,
                  height: 150 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [rgba(255, 255, 255, .12), rgba(255, 255, 255, .05), rgba(255, 255, 255, 0)],
                      stops: const [0, .55, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, .16),
              child: IgnorePointer(
                child: BergenLoop(
                  durationMs: 9000,
                  builder: (context, p, child) {
                    if (p == null) return const SizedBox.shrink();
                    final sc = p < .12 ? .55 : .55 + 1.35 * ((p - .12) / .88);
                    final o = p < .12
                        ? 0.0
                        : p < .18
                        ? .5 * (p - .12) / .06
                        : p < .6
                        ? .5 - .32 * (p - .18) / .42
                        : .18 * (1 - (p - .6) / .4);
                    return Opacity(
                      opacity: o.clamp(0.0, 1.0),
                      child: Transform.scale(scale: sc, child: child),
                    );
                  },
                  child: Container(
                    width: 260 * s,
                    height: 80 * s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(130 * s, 40 * s)),
                      border: Border.all(color: rgba(255, 255, 255, .5)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Stack(children: [bergenInsetTop(radius: 26 * s, alpha: .22)]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ButikkCopy.a1_butikk_seilas,
                            style: bText(
                              context,
                              9.5,
                              weight: FontWeight.w800,
                              letterSpacingEm: .09,
                              color: rgba(200, 232, 229, .85),
                            ),
                          ),
                          SizedBox(height: 2 * s),
                          if (mins != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    ButikkCopy.a1_butikk_lev_min(mins),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: bDisplay(
                                      context,
                                      14,
                                      weight: FontWeight.w800,
                                      letterSpacingEm: -.015,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5 * s),
                                _Ico(
                                  12 * s,
                                  rgba(255, 255, 255, .7),
                                  2.6,
                                  (k) => Path()
                                    ..moveTo(6 * k, 9 * k)
                                    ..lineTo(12 * k, 15 * k)
                                    ..lineTo(18 * k, 9 * k),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    OnbPressable(
                      key: const Key('a1_butikk_spor_aegil'),
                      onTap: onAegil,
                      pressDy: 0,
                      pressScale: .95,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(4 * s, 4 * s, 11 * s, 4 * s),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: rgba(3, 16, 24, .9),
                              offset: Offset(0, 10 * s),
                              blurRadius: onbBlur(18 * s),
                              spreadRadius: -12 * s,
                            ),
                            BoxShadow(color: rgba(180, 171, 160, .7), offset: Offset(0, 2 * s)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BergenLoop(
                              durationMs: 3400,
                              builder: (context, p, child) => Transform.translate(
                                offset: Offset(
                                  0,
                                  p == null ? 0 : kf(p, const [0, .5, 1], const [0, -2.5, 0], Curves.easeInOut) * s,
                                ),
                                child: child,
                              ),
                              child: Container(
                                width: 26 * s,
                                height: 26 * s,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE6E0D3)),
                                child: Image.asset(BergenAssets.aegilFront, fit: BoxFit.cover),
                              ),
                            ),
                            SizedBox(width: 7 * s),
                            Text(
                              ButikkCopy.a1_butikk_spor_aegil,
                              style: bText(context, 11, weight: FontWeight.w800, color: BergenColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2 * s),
              SizedBox(
                height: 104 * s,
                child: LayoutBuilder(
                  builder: (context, c) => _Water(
                    width: c.maxWidth,
                    frac: frac,
                    freeMark: free != null,
                    reached: reached,
                    logoUrl: store.logoUrl,
                  ),
                ),
              ),
              ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(14 * s, 11 * s, 14 * s, 12 * s),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [rgba(8, 26, 36, .18), rgba(8, 26, 36, .34)],
                      ),
                      border: Border(top: BorderSide(color: rgba(255, 255, 255, .14))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ButikkCopy.a1_butikk_neste,
                                style: bText(
                                  context,
                                  9,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: .09,
                                  color: rgba(200, 232, 229, .8),
                                ),
                              ),
                              SizedBox(height: 2 * s),
                              Text.rich(
                                next == null
                                    ? TextSpan(
                                        text: ButikkCopy.a1_butikk_havn,
                                        style: const TextStyle(color: Color(0xFF7FF0CB)),
                                      )
                                    : TextSpan(
                                        children: [
                                          TextSpan(
                                            text: ButikkCopy.a1_butikk_sum_kr('${(next.$1 - subtotal).ceil()}'),
                                            style: const TextStyle(color: Color(0xFFF9A273)),
                                          ),
                                          TextSpan(text: ' ${ButikkCopy.a1_butikk_til_navn(next.$2)}'),
                                        ],
                                      ),
                                key: const Key('a1_butikk_neste'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bDisplay(
                                  context,
                                  13,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: -.01,
                                  height: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (min != null)
                              Text(
                                ButikkCopy.a1_butikk_min(min),
                                style: bText(
                                  context,
                                  9,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: .06,
                                  color: rgba(200, 232, 229, .7),
                                ),
                              ),
                            SizedBox(height: 2 * s),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${subtotal.round()}'),
                                  TextSpan(
                                    text: goal == null ? ' kr' : ButikkCopy.a1_butikk_av_mal('${goal.round()}'),
                                    style: TextStyle(color: rgba(255, 255, 255, .5)),
                                  ),
                                ],
                              ),
                              key: const Key('a1_butikk_seilas_sum'),
                              style: bDisplay(context, 13, weight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
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
}

/// The water: the dashed course, the kitchen dock with the store's logo,
/// the "Gratis frakt" buoy, the door, and Ægil rowing at [frac].
class _Water extends StatelessWidget {
  const _Water({
    required this.width,
    required this.frac,
    required this.freeMark,
    required this.reached,
    required this.logoUrl,
  });

  final double width;
  final double frac;
  final bool freeMark;
  final bool reached;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    double at(double f) => 124 * s + (width - 200 * s) * f;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: CustomPaint(painter: _CoursePainter(width / (390 * s), s))),
        // Kjøkkenet — the dock with the logo and the kitchen's steam.
        Positioned(
          left: 0,
          top: 14 * s,
          width: 72 * s,
          height: 74 * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 34 * s,
                width: 66 * s,
                height: 14 * s,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(5 * s)),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF8A6238), Color(0xFF5E4024)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rgba(3, 16, 24, .8),
                        offset: Offset(0, 6 * s),
                        blurRadius: onbBlur(10 * s),
                        spreadRadius: -6 * s,
                      ),
                    ],
                  ),
                ),
              ),
              for (final x in [14.0, 52.0])
                Positioned(
                  left: x * s,
                  top: 46 * s,
                  width: 4 * s,
                  height: 12 * s,
                  child: const ColoredBox(color: Color(0xFF4A3018)),
                ),
              Positioned(
                left: 10 * s,
                top: 0,
                width: 40 * s,
                height: 40 * s,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13 * s),
                    boxShadow: [
                      BoxShadow(
                        color: rgba(3, 16, 24, .9),
                        offset: Offset(0, 8 * s),
                        blurRadius: onbBlur(14 * s),
                        spreadRadius: -8 * s,
                      ),
                      BoxShadow(color: rgba(255, 255, 255, .8), spreadRadius: 2 * s),
                    ],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(13 * s), child: _logo(logoUrl)),
                ),
              ),
              _Damp(left: 22, top: -7, w: 8, h: 8, color: rgba(255, 255, 255, .7)),
              _Damp(left: 31, top: -5, w: 6, h: 6, color: rgba(255, 255, 255, .6), delay: 900),
              Positioned(
                left: 0,
                top: 60 * s,
                width: 60 * s,
                child: Text(
                  ButikkCopy.a1_butikk_kjokkenet,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: bText(
                    context,
                    8.5,
                    weight: FontWeight.w800,
                    letterSpacingEm: .04,
                    color: rgba(255, 255, 255, .85),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Din dør.
        Positioned(
          right: 14 * s,
          top: 22 * s,
          width: 60 * s,
          child: Column(
            children: [
              Container(
                width: 38 * s,
                height: 38 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13 * s),
                  gradient: cssLinear(
                    180,
                    const [Color(0xFFFF7A45), Color(0xFFF1591F), Color(0xFFD9450F)],
                    const [0, .6, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(233, 92, 44, .9),
                      offset: Offset(0, 10 * s),
                      blurRadius: onbBlur(16 * s),
                      spreadRadius: -10 * s,
                    ),
                    BoxShadow(color: const Color(0xFFB83A0C), offset: Offset(0, 2 * s)),
                  ],
                ),
                child: _Ico(
                  18 * s,
                  Colors.white,
                  2.2,
                  (k) => Path()
                    ..moveTo(4 * k, 11 * k)
                    ..lineTo(12 * k, 4 * k)
                    ..lineTo(20 * k, 11 * k)
                    ..lineTo(20 * k, 20 * k)
                    ..lineTo(4 * k, 20 * k)
                    ..close()
                    ..moveTo(10 * k, 20 * k)
                    ..lineTo(10 * k, 14 * k)
                    ..lineTo(14 * k, 14 * k)
                    ..lineTo(14 * k, 20 * k),
                ),
              ),
              SizedBox(height: 4 * s),
              Text(
                ButikkCopy.a1_butikk_din_dor,
                maxLines: 1,
                style: bText(
                  context,
                  8.5,
                  weight: FontWeight.w800,
                  letterSpacingEm: .04,
                  color: rgba(255, 255, 255, .85),
                ),
              ),
            ],
          ),
        ),
        if (freeMark)
          Positioned(
            left: at(.7) - 40 * s,
            top: 46 * s,
            width: 80 * s,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10 * s,
                  height: 10 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? const Color(0xFF3F8F5F) : const Color(0xFFD8D2C6),
                    boxShadow: [BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 2.5 * s)],
                  ),
                ),
                SizedBox(height: 4 * s),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 1 * s),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: rgba(8, 26, 36, .45)),
                  child: Text(
                    ButikkCopy.a1_butikk_gratis_frakt,
                    maxLines: 1,
                    style: bText(context, 8, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        // Ægil rows: `left` eases over .9s as the basket changes.
        TweenAnimationBuilder<double>(
          tween: Tween(end: frac),
          duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 900),
          curve: const Cubic(.3, 1.05, .4, 1),
          builder: (context, f, child) => Positioned(left: at(f) - 32 * s, top: 8 * s, child: child!),
          child: _Boat(bubble: reached),
        ),
      ],
    );
  }
}

class _CoursePainter extends CustomPainter {
  _CoursePainter(this.kx, this.s);

  final double kx;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    final sy = size.height / 104;
    final path = Path()
      ..moveTo(62 * sx, 52 * sy)
      ..cubicTo(130 * sx, 32 * sy, 220 * sx, 74 * sy, 320 * sx, 52 * sy);
    final paint = Paint()
      ..color = rgba(255, 255, 255, .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5 * s, m.length)), paint);
        d += 12 * s;
      }
    }
  }

  @override
  bool shouldRepaint(_CoursePainter old) => false;
}

/// Ægil in the rowing boat: `roVugg`, oars `aareA` / `aareB`, the wake
/// (`roKjolvann`) and the sea shadow (`sjoSkygge`), all on 2.2s.
class _Boat extends StatelessWidget {
  const _Boat({required this.bubble});

  final bool bubble;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenLoop(
      durationMs: 2200,
      builder: (context, p, _) {
        final q = p ?? 0;
        final w = kf(q, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
        final vugg = -1.5 + 3 * w;
        final oar = w; // 0 → -28°/28°, 1 → 22°/-22°
        final wake = Curves.easeOut.transform(q);
        return SizedBox(
          width: 64 * s,
          height: 50 * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (bubble) Positioned(right: 72 * s, top: 2 * s, child: const _FraktBoble()),
              Transform.translate(
                offset: Offset(0, -2 * s * w),
                child: Transform.rotate(
                  angle: vugg * math.pi / 180,
                  child: SizedBox(
                    width: 64 * s,
                    height: 44 * s,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 14 * s,
                          top: 2 * s,
                          width: 36 * s,
                          height: 36 * s,
                          child: Image.asset(BergenAssets.aegilFront, fit: BoxFit.contain),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BoatPainter(a: -28 + 50 * oar, b: 28 - 50 * oar),
                          ),
                        ),
                        Positioned(
                          left: -6 * s,
                          top: 38 * s,
                          child: Opacity(
                            opacity: p == null ? 0 : .5 * (1 - wake),
                            child: Transform.translate(
                              offset: Offset(-22 * s * wake, 0),
                              child: Transform.scale(
                                scaleX: .6 + .8 * wake,
                                child: Container(
                                  width: 22 * s,
                                  height: 4 * s,
                                  decoration: BoxDecoration(
                                    color: rgba(255, 255, 255, .55),
                                    borderRadius: BorderRadius.all(Radius.elliptical(11 * s, 2 * s)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10 * s,
                top: 44 * s,
                child: Opacity(
                  opacity: .55 - .15 * w,
                  child: Transform.scale(
                    scaleX: 1 - .08 * w,
                    child: Container(
                      width: 44 * s,
                      height: 6 * s,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(22 * s, 3 * s)),
                        gradient: RadialGradient(
                          colors: [rgba(255, 255, 255, .45), rgba(255, 255, 255, 0)],
                          stops: const [0, .72],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoatPainter extends CustomPainter {
  _BoatPainter({required this.a, required this.b});

  /// Oar angles in degrees.
  final double a;
  final double b;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 64;
    canvas.save();
    canvas.scale(k);
    void oar(double ox, double oy, double tx, double ty, double deg, double blade) {
      canvas.save();
      canvas.translate(ox, oy);
      canvas.rotate(deg * math.pi / 180);
      canvas.translate(-ox, -oy);
      canvas.drawLine(
        Offset(ox, oy),
        Offset(tx, ty),
        Paint()
          ..color = const Color(0xFF8A5A2B)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(blade * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 3.2),
        Paint()..color = const Color(0xFFB07A3C),
      );
      canvas.restore();
      canvas.restore();
    }

    oar(14, 27, 3, 40, a, -50);
    oar(50, 27, 61, 40, b, 50);
    canvas.drawPath(
      Path()
        ..moveTo(6, 24)
        ..cubicTo(10, 36, 54, 36, 58, 24)
        ..lineTo(62, 22)
        ..cubicTo(60, 30, 52, 40, 32, 40)
        ..cubicTo(12, 40, 4, 30, 2, 22)
        ..close(),
      Paint()..color = const Color(0xFF6B4A2A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(4, 22)
        ..cubicTo(14, 33, 50, 33, 60, 22)
        ..lineTo(62, 22)
        ..cubicTo(56, 34, 46, 38, 32, 38)
        ..cubicTo(18, 38, 8, 34, 2, 22)
        ..close(),
      Paint()..color = const Color(0xFF8C6338),
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 24)
        ..cubicTo(14, 30, 50, 30, 58, 24)
        ..lineTo(61, 22)
        ..cubicTo(54, 30, 10, 30, 3, 22)
        ..close(),
      Paint()..color = const Color(0xFFA5763D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(4, 23)
        ..cubicTo(14, 29, 50, 29, 60, 23),
      Paint()
        ..color = BergenColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(12, 32),
      const Offset(52, 32),
      Paint()
        ..color = rgba(255, 255, 255, .25)
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoatPainter old) => old.a != a || old.b != b;
}

/// "Nå fikser jeg gratis frakt for deg" — `onbBoble .45s`.
class _FraktBoble extends StatelessWidget {
  const _FraktBoble();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenOnce(
      durationMs: 450,
      builder: (context, p, child) {
        final e = const Cubic(.2, 1.1, .4, 1).transform(p);
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 8 * s * (1 - e)),
            child: Transform.scale(scale: .92 + .08 * e, child: child),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12 * s),
                topRight: Radius.circular(12 * s),
                bottomLeft: Radius.circular(12 * s),
                bottomRight: Radius.circular(4 * s),
              ),
              boxShadow: [
                BoxShadow(
                  color: rgba(3, 16, 24, .9),
                  offset: Offset(0, 12 * s),
                  blurRadius: onbBlur(20 * s),
                  spreadRadius: -12 * s,
                ),
                BoxShadow(color: rgba(180, 171, 160, .8), offset: Offset(0, 2 * s)),
              ],
            ),
            child: Text(
              ButikkCopy.a1_butikk_frakt_naadd,
              key: const Key('a1_butikk_frakt_naadd'),
              style: bText(context, 9.5, weight: FontWeight.w800, color: BergenColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ── the category orbs ───────────────────────────────────────────────────────

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.names,
    required this.active,
    required this.dx,
    required this.dragging,
    required this.onPick,
    required this.onDrag,
    required this.onRelease,
  });

  final List<String> names;
  final int active;
  final double dx;
  final bool dragging;
  final ValueChanged<int> onPick;
  final ValueChanged<double> onDrag;
  final VoidCallback onRelease;

  static const double step = 50;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final n = names.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
      child: SizedBox(
        height: 104 * s,
        child: LayoutBuilder(
          builder: (context, c) {
            final cx = c.maxWidth / 2;
            final orbs = <(double, Widget)>[];
            for (var i = 0; i < n; i++) {
              var d0 = (i - active) % n;
              if (d0 > n / 2) d0 -= n;
              if (n <= 4 && d0 < -(n ~/ 2)) d0 += n;
              final u = d0 + dx / step;
              final a = u.abs();
              if (a > 2.5) continue;
              final on = a < .5;
              final ang = u * .215;
              final bx = math.sin(ang) * 320 * s;
              final by = (1 - math.cos(ang)) * 320 * s;
              final sc = math.max(.72, 1.18 - a * .2);
              orbs.add((
                a,
                AnimatedPositioned(
                  key: ValueKey('orb-$i'),
                  duration: dragging || MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 520),
                  curve: const Cubic(.3, 1.05, .35, 1),
                  left: cx - 23 * s + bx,
                  top: 7 * s + by,
                  width: 46 * s,
                  height: 46 * s,
                  child: _Orb(
                    key: Key('a1_butikk_kat_$i'),
                    name: names[i],
                    index: i,
                    on: on,
                    scale: sc,
                    opacity: math.max(.55, 1 - a * .18),
                    nameOpacity: on ? 1 : (a > 1.5 ? 0 : .7),
                    onTap: () => onPick(i),
                  ),
                ),
              ));
            }
            orbs.sort((x, y) => y.$1.compareTo(x.$1));
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) => onDrag((dx + d.delta.dx * 1.25).clamp(-1.05 * step, 1.05 * step)),
              onHorizontalDragEnd: (_) => onRelease(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: cx - 32 * s,
                    top: -2 * s,
                    width: 64 * s,
                    height: 64 * s,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(0, -.56),
                            colors: [rgba(255, 255, 255, .22), rgba(255, 255, 255, .06), rgba(255, 255, 255, 0)],
                            stops: const [0, .58, .75],
                          ),
                          border: Border.all(color: rgba(255, 255, 255, .18), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  for (final o in orbs) o.$2,
                  Positioned(
                    left: cx - 17 * s,
                    bottom: 0,
                    width: 34 * s,
                    height: 4 * s,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2 * s),
                        color: BergenColors.mint,
                        boxShadow: [
                          BoxShadow(color: BergenColors.mint, blurRadius: 6 * s),
                          BoxShadow(color: rgba(92, 224, 184, .5), blurRadius: 11 * s),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    super.key,
    required this.name,
    required this.index,
    required this.on,
    required this.scale,
    required this.opacity,
    required this.nameOpacity,
    required this.onTap,
  });

  final String name;
  final int index;
  final bool on;
  final double scale;
  final double opacity;
  final double nameOpacity;
  final VoidCallback onTap;

  /// The design's icons: Alt (grid), then by the category's name.
  Path Function(double k) get _icon {
    if (index == 0) {
      return (k) => Path()
        ..addRect(Rect.fromLTWH(4.5 * k, 4.5 * k, 6 * k, 6 * k))
        ..addRect(Rect.fromLTWH(13.5 * k, 4.5 * k, 6 * k, 6 * k))
        ..addRect(Rect.fromLTWH(4.5 * k, 13.5 * k, 6 * k, 6 * k))
        ..addRect(Rect.fromLTWH(13.5 * k, 13.5 * k, 6 * k, 6 * k));
    }
    final n = name.toLowerCase();
    if (n == ButikkCopy.a1_butikk_tilbud.toLowerCase()) {
      // The tag (`erTilbud`).
      return (k) => svgSti(
        'M3.5 12.2V4.5a1 1 0 0 1 1-1h7.7l8.3 8.3a1.4 1.4 0 0 1 0 2l-6.6 6.6a1.4 1.4 0 0 1-2 0z'
        'M9.9 8.4a1.5 1.5 0 1 1-3 0a1.5 1.5 0 1 1 3 0z',
      ).transform((Matrix4.identity()..scaleByDouble(k, k, 1, 1)).storage);
    }
    if (RegExp(r'drikk|brus|soda|juice|kaffe|vann|øl').hasMatch(n)) {
      return (k) => Path()
        ..moveTo(6.4 * k, 6.2 * k)
        ..lineTo(17.6 * k, 6.2 * k)
        ..lineTo(16.2 * k, 19.8 * k)
        ..lineTo(7.8 * k, 19.8 * k)
        ..close()
        ..moveTo(7.1 * k, 11 * k)
        ..lineTo(16.9 * k, 11 * k)
        ..moveTo(13.4 * k, 6.2 * k)
        ..lineTo(16.4 * k, 3 * k);
    }
    if (RegExp(r'tilbeh|fries|frites|side|snacks').hasMatch(n)) {
      return (k) => Path()
        ..moveTo(8.2 * k, 9.5 * k)
        ..lineTo(8.2 * k, 4.2 * k)
        ..moveTo(12 * k, 9 * k)
        ..lineTo(12 * k, 3 * k)
        ..moveTo(15.8 * k, 9.5 * k)
        ..lineTo(15.8 * k, 4.2 * k)
        ..moveTo(5.4 * k, 10.2 * k)
        ..lineTo(18.6 * k, 10.2 * k)
        ..lineTo(17 * k, 20.2 * k)
        ..lineTo(7 * k, 20.2 * k)
        ..close();
    }
    if (RegExp(r'kylling|chicken|wings').hasMatch(n)) {
      return (k) => Path()
        ..addOval(Rect.fromCircle(center: Offset(14 * k, 8.4 * k), radius: 5.6 * k))
        ..moveTo(11.6 * k, 12.4 * k)
        ..lineTo(7.4 * k, 16.6 * k)
        ..addOval(Rect.fromCircle(center: Offset(5.6 * k, 18.4 * k), radius: 2.1 * k))
        ..addOval(Rect.fromCircle(center: Offset(8.2 * k, 20.6 * k), radius: 1.7 * k));
    }
    // Burgers and every other dish: the bun.
    return (k) => Path()
      ..moveTo(4 * k, 9.5 * k)
      ..cubicTo(4 * k, 6.5 * k, 7.6 * k, 4 * k, 12 * k, 4 * k)
      ..cubicTo(16.4 * k, 4 * k, 20 * k, 6.5 * k, 20 * k, 9.5 * k)
      ..close()
      ..moveTo(3.6 * k, 12.8 * k)
      ..lineTo(20.4 * k, 12.8 * k)
      ..moveTo(4.4 * k, 16 * k)
      ..lineTo(19.6 * k, 16 * k)
      ..cubicTo(19.6 * k, 18.4 * k, 17.7 * k, 20 * k, 15.4 * k, 20 * k)
      ..lineTo(8.6 * k, 20 * k)
      ..cubicTo(6.3 * k, 20 * k, 4.4 * k, 18.4 * k, 4.4 * k, 16 * k)
      ..close();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    const dur = Duration(milliseconds: 300);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 520),
        opacity: opacity,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 520),
          curve: const Cubic(.3, 1.05, .35, 1),
          scale: scale,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: dur,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: on
                      ? cssLinear(160, const [Color(0xFFF2884E), Color(0xFFE0662C)])
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0xFFF1ECE1)],
                        ),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: rgba(120, 50, 10, .75),
                            offset: Offset(0, 10 * s),
                            blurRadius: onbBlur(15 * s),
                            spreadRadius: -6 * s,
                          ),
                          BoxShadow(color: rgba(150, 60, 15, .85), offset: Offset(0, 3 * s)),
                        ]
                      : [
                          BoxShadow(
                            color: rgba(35, 32, 29, .35),
                            offset: Offset(0, 4 * s),
                            blurRadius: onbBlur(7 * s),
                            spreadRadius: -4 * s,
                          ),
                          BoxShadow(color: const Color(0xFFD9D2C4), offset: Offset(0, 1.5 * s)),
                          BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 1),
                        ],
                ),
                child: _Ico(18 * s, on ? Colors.white : BergenColors.inkMuted, 2.1, _icon),
              ),
              Positioned(
                top: 46 * s + 7 * s,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: nameOpacity,
                  child: Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    style: bDisplay(
                      context,
                      10.5,
                      weight: FontWeight.w800,
                      letterSpacingEm: -.01,
                      color: on ? const Color(0xFFFF9A5E) : rgba(255, 255, 255, .75),
                    ),
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

// ── "Mest bestilt" and the menu search pill ─────────────────────────────────

class _MenuHead extends StatelessWidget {
  const _MenuHead({
    required this.title,
    required this.open,
    required this.controller,
    required this.focus,
    required this.onToggle,
  });

  final String title;
  final bool open;
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    const spring = Cubic(.3, 1.05, .35, 1);
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 16 * s, 0),
      child: SizedBox(
        height: 38 * s,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  opacity: open ? 0 : 1,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 420),
                    curve: const Cubic(.3, 1, .4, 1),
                    offset: Offset(open ? -.06 : 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: bDisplay(
                            context,
                            15,
                            weight: FontWeight.w800,
                            letterSpacingEm: -.01,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2 * s),
                        Text(
                          ButikkCopy.a1_butikk_inkl_mva,
                          style: bText(context, 10.5, weight: FontWeight.w600, color: rgba(255, 255, 255, .55)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -5 * s,
                top: -5 * s,
                width: 48 * s,
                height: 48 * s,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 260),
                    opacity: open ? 0 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -.56),
                          colors: [rgba(255, 255, 255, .16), rgba(255, 255, 255, .04), rgba(255, 255, 255, 0)],
                          stops: const [0, .58, .75],
                        ),
                        border: Border.all(color: rgba(255, 255, 255, .12)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                height: 38 * s,
                child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 460),
                  curve: spring,
                  width: open ? c.maxWidth : 38 * s,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19 * s),
                    gradient: open
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [rgba(0, 0, 0, .3), rgba(0, 0, 0, .18)],
                          )
                        : cssLinear(165, const [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
                    border: Border.all(color: open ? rgba(92, 224, 184, .55) : Colors.transparent),
                    boxShadow: open
                        ? [
                            BoxShadow(
                              color: rgba(4, 18, 26, .8),
                              offset: Offset(0, 10 * s),
                              blurRadius: onbBlur(18 * s),
                              spreadRadius: -12 * s,
                            ),
                            BoxShadow(color: rgba(92, 224, 184, .14), spreadRadius: 3 * s),
                          ]
                        : [
                            BoxShadow(
                              color: rgba(15, 45, 55, .75),
                              offset: Offset(0, 7 * s),
                              blurRadius: onbBlur(11 * s),
                              spreadRadius: -5 * s,
                            ),
                            BoxShadow(color: rgba(11, 38, 45, .85), offset: Offset(0, 2 * s)),
                          ],
                  ),
                  child: Stack(
                    children: [
                      if (!open) bergenInsetTop(radius: 19 * s, alpha: .28),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: 38 * s,
                        child: IgnorePointer(
                          ignoring: !open,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 260),
                            opacity: open ? 1 : 0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const Key('a1_butikk_meny_sok'),
                                    controller: controller,
                                    focusNode: focus,
                                    cursorColor: BergenColors.mint,
                                    style: bDisplay(context, 13, weight: FontWeight.w700, color: Colors.white),
                                    decoration: onbBareInput(
                                      hint: ButikkCopy.a1_butikk_sok_meny,
                                      hintStyle: bDisplay(
                                        context,
                                        13,
                                        weight: FontWeight.w700,
                                        color: rgba(255, 255, 255, .45),
                                      ),
                                    ).copyWith(contentPadding: EdgeInsets.only(left: 16 * s)),
                                  ),
                                ),
                                if (controller.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: controller.clear,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4 * s),
                                      child: Text(
                                        ButikkCopy.a1_butikk_tom,
                                        style: bText(context, 10.5, weight: FontWeight.w800, color: BergenColors.mint),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: OnbPressable(
                          key: const Key('a1_butikk_meny_sok_knapp'),
                          onTap: onToggle,
                          pressDy: 0,
                          pressScale: .9,
                          child: SizedBox(
                            width: 36 * s,
                            height: 36 * s,
                            child: Center(
                              child: AnimatedRotation(
                                duration: const Duration(milliseconds: 420),
                                curve: const Cubic(.3, 1.1, .4, 1),
                                turns: open ? .25 : 0,
                                child: _Ico(
                                  17 * s,
                                  Colors.white,
                                  2.4,
                                  open
                                      ? (k) => Path()
                                          ..moveTo(6 * k, 6 * k)
                                          ..lineTo(18 * k, 18 * k)
                                          ..moveTo(18 * k, 6 * k)
                                          ..lineTo(6 * k, 18 * k)
                                      : (k) => Path()
                                          ..addOval(Rect.fromCircle(center: Offset(11 * k, 11 * k), radius: 7 * k))
                                          ..moveTo(20.5 * k, 20.5 * k)
                                          ..lineTo(16.2 * k, 16.2 * k),
                                ),
                              ),
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
    );
  }
}

// ── Tilbud (`visTilbud`, L4058) ─────────────────────────────────────────────

class _TilbudGrid extends StatelessWidget {
  const _TilbudGrid({required this.specials, required this.onOpen, required this.onAdd});

  final List<BergenMenuItem> specials;
  final ValueChanged<BergenMenuItem> onOpen;
  final ValueChanged<BergenMenuItem> onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    // In the grid (`margin-top:52px`), the note sits 22px up and the cards
    // 26px up from their rows.
    return Padding(
      key: const Key('a1_butikk_tilbud'),
      padding: EdgeInsets.fromLTRB(16 * s, 30 * s, 16 * s, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 7 * s,
                height: 7 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9A5E),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF9A5E), blurRadius: onbBlur(8 * s))],
                ),
              ),
              SizedBox(width: 8 * s),
              Expanded(
                child: Text(
                  ButikkCopy.a1_butikk_tilbud_note,
                  style: bText(context, 11.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .72)),
                ),
              ),
            ],
          ),
          SizedBox(height: 30 * s),
          for (var i = 0; i < specials.length; i += 2) ...[
            if (i > 0) SizedBox(height: 30 * s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _kort(specials[i], i)),
                SizedBox(width: 12 * s),
                Expanded(child: i + 1 < specials.length ? _kort(specials[i + 1], i + 1) : const SizedBox.shrink()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kort(BergenMenuItem i, int n) => _TilbudKort(
    key: Key('a1_butikk_tilbud_${i.id}'),
    item: i,
    fase: .7 + n * .7,
    onOpen: () => onOpen(i),
    onAdd: () => onAdd(i),
  );
}

/// `Tilbud · {navn}`: a cream card, the photo (4:3) with its sheen and
/// colour-dodge holo, the discount tag tilted on the corner, why it is on
/// offer and the saving, the price with the old one struck through, and the
/// floating key.
class _TilbudKort extends StatelessWidget {
  const _TilbudKort({super.key, required this.item, required this.fase, required this.onOpen, required this.onAdd});

  final BergenMenuItem item;
  final double fase;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final was = item.wasPrice ?? item.price;
    final pct = was > 0 ? ((1 - item.price / was) * 100).round() : 0;
    final spar = (was - item.price).round();
    const ink = BergenColors.ink;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(7 * s, 7 * s, 7 * s, 11 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24 * s),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFBF5), Color(0xFFF7EEE2)],
            ),
            boxShadow: [
              BoxShadow(color: rgba(255, 255, 255, .55), spreadRadius: 1),
              BoxShadow(color: rgba(4, 18, 26, .25), offset: Offset(0, 3 * s)),
              BoxShadow(
                color: rgba(4, 18, 26, .85),
                offset: Offset(0, 22 * s),
                blurRadius: onbBlur(30 * s),
                spreadRadius: -18 * s,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The pastel holo over the lower half.
              Positioned(
                left: -7 * s,
                right: -7 * s,
                bottom: -11 * s,
                height: 140 * s,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24 * s)),
                  child: const IgnorePointer(
                    child: KatHolo(farger: kKatHoloLys, stopp: kKatHoloLysStopp),
                  ),
                ),
              ),
              bergenInsetTop(
                radius: 24 * s,
                height: 1.5 * s,
                alpha: 1,
                pad: EdgeInsets.fromLTRB(7 * s, 7 * s, 7 * s, 11 * s),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: onOpen,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18 * s),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: Color(0xFFFBF7EE)),
                            if ((item.imageUrl ?? '').isNotEmpty)
                              Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.fromRGBO(255, 255, 255, .18),
                                    Color.fromRGBO(255, 255, 255, 0),
                                    Color.fromRGBO(0, 0, 0, 0),
                                    Color.fromRGBO(0, 0, 0, .22),
                                  ],
                                  stops: [0, .35, .62, 1],
                                ),
                              ),
                            ),
                            const IgnorePointer(
                              child: KatHolo(farger: kKatHoloSterk, stopp: kKatHoloSterkStopp, dodge: .3),
                            ),
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18 * s),
                                  border: Border.all(color: rgba(0, 0, 0, .08)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [rgba(0, 0, 0, .18), rgba(0, 0, 0, 0)],
                                    stops: const [0, .06],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9 * s),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3 * s),
                    child: GestureDetector(
                      onTap: onOpen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: bDisplay(context, 14, letterSpacingEm: -.02, height: 1.2, color: ink),
                          ),
                          SizedBox(height: 3 * s),
                          Text(
                            ButikkCopy.a1_butikk_tilbud_spar(
                              (item.categoryName ?? '').trim().isNotEmpty
                                  ? item.categoryName!.trim()
                                  : ButikkCopy.a1_butikk_tilbud_grunn,
                              spar,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bText(context, 11, weight: FontWeight.w700, color: const Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 9 * s),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3 * s),
                    child: CustomPaint(
                      painter: const _Stiplet(),
                      child: Padding(
                        padding: EdgeInsets.only(top: 9 * s),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _kr(item.price),
                                    style: bDisplay(
                                      context,
                                      17,
                                      letterSpacingEm: -.02,
                                      color: ink,
                                    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                  ),
                                  if (item.wasPrice != null)
                                    Text(
                                      _kr(was),
                                      style: bText(
                                        context,
                                        11,
                                        weight: FontWeight.w700,
                                        color: const Color(0xFF9A9188),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _SvevKnapp(
                              key: Key('a1_butikk_tilbud_legg_${item.id}'),
                              size: 40,
                              ikonPx: 15,
                              fase: fase,
                              onTap: onAdd,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (pct > 0)
          Positioned(
            top: -8 * s,
            right: -5 * s,
            child: Transform.rotate(
              angle: 5 * math.pi / 180,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9 * s),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _kOrange3,
                    stops: [0, .56, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(120, 50, 20, .6),
                      offset: Offset(0, 8 * s),
                      blurRadius: onbBlur(14 * s),
                      spreadRadius: -6 * s,
                    ),
                    BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 3 * s)),
                    BoxShadow(color: Colors.white, spreadRadius: 2 * s),
                  ],
                ),
                child: Text(
                  '−$pct %',
                  style: bText(context, 11, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// `border-top: 1px dashed rgba(60,40,20,.16)` along the painter's top.
class _Stiplet extends CustomPainter {
  const _Stiplet();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color.fromRGBO(60, 40, 20, .16)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .5), Offset(math.min(x + 3, size.width), .5), p);
    }
  }

  @override
  bool shouldRepaint(_Stiplet old) => false;
}

// ── the menu grid ───────────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  const _Grid({
    required this.items,
    required this.inn,
    required this.query,
    required this.readyMinutes,
    required this.mostOrderedId,
    required this.qtyOf,
    required this.onOpen,
    required this.onPlus,
    required this.onMinus,
  });

  final List<BergenMenuItem> items;
  final Animation<double> inn;
  final String query;
  final int? readyMinutes;
  final int? mostOrderedId;
  final int Function(int productId) qtyOf;
  final void Function(BergenMenuItem, {bool mostOrdered}) onOpen;
  final ValueChanged<BergenMenuItem> onPlus;
  final ValueChanged<BergenMenuItem> onMinus;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16 * s, 34 * s, 16 * s, 0),
        child: Container(
          key: const Key('a1_butikk_menu_empty'),
          padding: EdgeInsets.all(14 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * s),
            color: rgba(255, 255, 255, .08),
            border: Border.all(color: rgba(255, 255, 255, .14)),
          ),
          child: Text(
            query.isEmpty ? ButikkCopy.a1_butikk_menu_empty : ButikkCopy.a1_butikk_ingen_treff_meny(query),
            style: bText(context, 12, weight: FontWeight.w600, height: 1.45, color: rgba(255, 255, 255, .75)),
          ),
        ),
      );
    }
    // `margin:52px 16px 0; gap:56px 12px; align-items:start`.
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 52 * s, 16 * s, 0),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i += 2) ...[
            if (i > 0) SizedBox(height: 56 * s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _card(items[i], i)),
                SizedBox(width: 12 * s),
                Expanded(child: i + 1 < items.length ? _card(items[i + 1], i + 1) : const SizedBox.shrink()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(BergenMenuItem item, int n) => _KortInn(anim: inn, i: n, child: _card0(item, n));

  Widget _card0(BergenMenuItem item, int n) => _MenuCard(
    key: Key('a1_butikk_menu_${item.id}'),
    item: item,
    mostOrdered: item.id == mostOrderedId,
    qty: qtyOf(item.id),
    // The keys float out of step (`animation-delay` −1.4s, −2.1s, …).
    fase: 1.4 + n * .7,
    onOpen: () => onOpen(item, mostOrdered: item.id == mostOrderedId),
    onPlus: () => onPlus(item),
    onMinus: () => onMinus(item),
  );
}

const _kInnMs = 600;

/// One card of the new orb gliding in: `opacity 0, translate 0 16px,
/// scale .98` → rest over 360 ms, `delay min(i,6)·40ms`.
class _KortInn extends StatelessWidget {
  const _KortInn({required this.anim, required this.i, required this.child});

  final Animation<double> anim;
  final int i;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final ms = anim.value * _kInnMs - math.min(i, 6) * 40;
        final t = const Cubic(.22, 1, .36, 1).transform((ms / 360).clamp(0.0, 1.0));
        if (t >= 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * s * (1 - t)),
            child: Transform.scale(scale: .98 + .02 * t, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

/// A dish on the menu (L4376): glass card with a warm glow at the top, the
/// dish floating up out of it (`aegBob 4.2s`), name, price and the orange
/// key that floats too (`aeKnSvev`); once in the basket, the dark stepper.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    super.key,
    required this.item,
    required this.mostOrdered,
    required this.qty,
    required this.fase,
    required this.onOpen,
    required this.onPlus,
    required this.onMinus,
  });

  final BergenMenuItem item;
  final bool mostOrdered;
  final int qty;

  /// The key's float phase (`animation-delay`, seconds before zero).
  final double fase;
  final VoidCallback onOpen;
  final VoidCallback onPlus;
  final VoidCallback onMinus;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(24 * s);
    return Container(
      padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 12 * s),
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: cssLinear(
          165,
          [rgba(255, 255, 255, .19), rgba(255, 255, 255, .08), rgba(255, 255, 255, .04)],
          const [0, .4, 1],
        ),
        border: Border.all(color: rgba(255, 255, 255, .24)),
        boxShadow: [
          BoxShadow(
            color: rgba(2, 12, 18, .95),
            offset: Offset(0, 22 * s),
            blurRadius: onbBlur(32 * s),
            spreadRadius: -18 * s,
          ),
          BoxShadow(color: rgba(8, 30, 38, .5), offset: Offset(0, 2 * s)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // `radial-gradient(90% 55% at 50% 0%, rgba(255,190,120,.2), …)`
          // and the two inset edges.
          Positioned(
            left: -12 * s,
            right: -12 * s,
            top: -8 * s,
            bottom: -12 * s,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: r,
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1,
                    colors: [rgba(255, 190, 120, .2), rgba(255, 190, 120, 0)],
                    stops: const [0, .7],
                    transform: const _CssRadial(.5, 0, .9, .55),
                  ),
                ),
              ),
            ),
          ),
          bergenInsetTop(
            radius: 24 * s,
            height: 1.5 * s,
            alpha: .38,
            pad: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 12 * s),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The picture is 128px tall and lifted 44px out of the card
              // (`margin-top:-44px`).
              SizedBox(
                height: 84 * s,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -44 * s,
                      height: 128 * s,
                      child: GestureDetector(
                        onTap: onOpen,
                        child: _MenuBilde(item: item, mostOrdered: mostOrdered),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8 * s),
              GestureDetector(
                onTap: onOpen,
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bDisplay(context, 14, letterSpacingEm: -.02, height: 1.2, color: Colors.white),
                ),
              ),
              SizedBox(height: 10 * s),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kr(item.price),
                            maxLines: 1,
                            style: bDisplay(
                              context,
                              17,
                              letterSpacingEm: -.02,
                              color: Colors.white,
                            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                          if (item.wasPrice != null)
                            Text(
                              _kr(item.wasPrice!),
                              maxLines: 1,
                              style: bText(
                                context,
                                11,
                                weight: FontWeight.w700,
                                color: rgba(255, 255, 255, .5),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  if (qty == 0)
                    _SvevKnapp(key: Key('a1_butikk_legg_${item.id}'), size: 44, ikonPx: 17, fase: fase, onTap: onPlus)
                  else
                    _GridStepper(id: item.id, qty: qty, onMinus: onMinus, onPlus: onPlus),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _kr(double v) => ButikkCopy.kr(v);

/// The dish above its card: the warm glow behind, the shadow it casts and,
/// bobbing, the shop's photo as a rounded print (shop photos are not
/// cut-outs like the design's PNGs) with the "Mest bestilt" badge.
class _MenuBilde extends StatelessWidget {
  const _MenuBilde({required this.item, required this.mostOrdered});

  final BergenMenuItem item;
  final bool mostOrdered;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final url = item.imageUrl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -14 * s,
          top: -14 * s,
          right: -14 * s,
          bottom: -14 * s,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -.1),
                  colors: [rgba(255, 190, 120, .28), rgba(255, 190, 120, 0)],
                  stops: const [0, .7],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -3 * s,
          height: 12 * s,
          child: FractionallySizedBox(
            widthFactor: .76,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(60 * s, 6 * s)),
                gradient: RadialGradient(colors: [rgba(0, 8, 12, .55), rgba(0, 8, 12, 0)], stops: const [0, .72]),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: BergenLoop(
              durationMs: 4200,
              builder: (context, p, child) => Transform.translate(
                offset: Offset(0, p == null ? 0 : kf(p, const [0, .5, 1], const [0, -2.5, 0], Curves.easeInOut) * s),
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20 * s),
                        boxShadow: [
                          BoxShadow(
                            color: rgba(0, 8, 12, .5),
                            offset: Offset(0, 16 * s),
                            blurRadius: onbBlur(12 * s) + 6 * s,
                            spreadRadius: -6 * s,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20 * s),
                        child: url == null || url.isEmpty
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment(-.4, -.8),
                                    radius: 1.2,
                                    colors: [Color(0xFFFDF0D8), Color(0xFFF6D9A6), Color(0xFFE7B66C)],
                                    stops: [0, .52, 1],
                                  ),
                                ),
                              )
                            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                    ),
                  ),
                  if (mostOrdered)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(6 * s, 3 * s, 8 * s, 3 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: rgba(15, 42, 51, .72),
                          border: Border.all(color: rgba(255, 178, 122, .55)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Ico(9 * s, const Color(0xFFFFB27A), 0, (k) => _starPath(k), fill: const Color(0xFFFFB27A)),
                            SizedBox(width: 4 * s),
                            Text(
                              ButikkCopy.a1_butikk_mest_bestilt,
                              style: bText(context, 9.5, weight: FontWeight.w800, color: const Color(0xFFFFB27A)),
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
    );
  }
}

Path _starPath(double k) => Path()
  ..moveTo(12 * k, 2 * k)
  ..lineTo(14.6 * k, 8.4 * k)
  ..lineTo(21.5 * k, 8.9 * k)
  ..lineTo(16.2 * k, 13.4 * k)
  ..lineTo(17.9 * k, 20.1 * k)
  ..lineTo(12 * k, 16.5 * k)
  ..lineTo(6.1 * k, 20.1 * k)
  ..lineTo(7.8 * k, 13.4 * k)
  ..lineTo(2.5 * k, 8.9 * k)
  ..lineTo(9.4 * k, 8.4 * k)
  ..close();

/// The orange round key that floats (`aeKnSvev 3.4s`: up 5px and back) over
/// its shadow (`aeKnSkygge`: the ellipse narrows and fades as it rises).
class _SvevKnapp extends StatelessWidget {
  const _SvevKnapp({super.key, required this.size, required this.ikonPx, required this.fase, required this.onTap});

  final double size;
  final double ikonPx;
  final double fase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .94,
      child: RepaintBoundary(
        child: KatLoop(
          durationMs: 3400,
          phaseMs: fase * 1000,
          builder: (context, p, _) {
            final e = kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
            return SizedBox(
              width: size * s,
              height: size * s,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 4 * s,
                    right: 4 * s,
                    top: size * s + 1 * s,
                    height: 12 * s,
                    child: Opacity(
                      opacity: 1 - .4 * e,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.translationValues(0, 5 * s * e, 0)..scaleByDouble(1 - .18 * e, 1, 1, 1),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.elliptical(size * s / 2, 6 * s)),
                            gradient: RadialGradient(
                              colors: [rgba(8, 26, 32, .5), rgba(0, 0, 0, 0)],
                              stops: const [0, .72],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -5 * s * e),
                    child: Container(
                      width: size * s,
                      height: size * s,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF68450), Color(0xFFE65A28)],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          sokInsetBunnRund(size * s),
                          bergenInsetTop(radius: 999, height: 1.5 * s, alpha: .4),
                          _Ico(ikonPx * s, Colors.white, 2.8, _plusPath),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// `inset 0 -3px 6px rgba(150,40,10,.3)` inside a round key.
Widget sokInsetBunnRund(double d) => Positioned.fill(
  child: IgnorePointer(
    child: ClipOval(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: d * .2,
          width: double.infinity,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color.fromRGBO(150, 40, 10, .3), Color.fromRGBO(150, 40, 10, 0)],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// In the basket: `height:38px; background:rgba(0,0,0,.28)` with two white
/// 30px keys around the count.
class _GridStepper extends StatelessWidget {
  const _GridStepper({required this.id, required this.qty, required this.onMinus, required this.onPlus});

  final int id;
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    Widget btn(String key, Path Function(double k) icon, VoidCallback onTap) => OnbPressable(
      key: Key(key),
      onTap: onTap,
      pressDy: 0,
      pressScale: .9,
      child: Container(
        width: 30 * s,
        height: 30 * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: rgba(35, 32, 29, .4),
              offset: Offset(0, 3 * s),
              blurRadius: onbBlur(8 * s),
              spreadRadius: -4 * s,
            ),
          ],
        ),
        child: _Ico(13 * s, const Color(0xFFB9441A), 2.6, icon),
      ),
    );
    return Container(
      height: 38 * s,
      padding: EdgeInsets.symmetric(horizontal: 4 * s),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: rgba(0, 0, 0, .28)),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rgba(0, 0, 0, .3), rgba(0, 0, 0, 0), rgba(0, 0, 0, 0), rgba(255, 255, 255, .1)],
          stops: const [0, .2, .94, 1],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(
            'a1_butikk_minus_$id',
            (k) => Path()
              ..moveTo(5 * k, 12 * k)
              ..lineTo(19 * k, 12 * k),
            onMinus,
          ),
          SizedBox(width: 4 * s),
          SizedBox(
            width: 18 * s,
            child: Text(
              '$qty',
              key: Key('a1_butikk_qty_$id'),
              textAlign: TextAlign.center,
              style: bText(context, 13, weight: FontWeight.w800),
            ),
          ),
          SizedBox(width: 4 * s),
          btn('a1_butikk_plus_$id', _plusPath, onPlus),
        ],
      ),
    );
  }
}

// ── the basket ──────────────────────────────────────────────────────────────

/// "I kurven" — `stigOpp .32s`: each line with −/+ and remove.
class ButikkMiniKurv extends StatelessWidget {
  const ButikkMiniKurv({
    super.key,
    required this.lines,
    required this.onEmpty,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
    this.mork = false,
  });

  final List<KurvLine> lines;
  final VoidCallback onEmpty;
  final ValueChanged<KurvLine> onMinus;
  final ValueChanged<KurvLine> onPlus;
  final ValueChanged<KurvLine> onRemove;

  /// The Mote page's dark basket (`#1E4F5C → #122F3A`, glass keys).
  final bool mork;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final maxH = MediaQuery.sizeOf(context).height * .45;
    return BergenOnce(
      durationMs: 320,
      builder: (context, p, child) {
        final e = kSkjermInn.transform(p);
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 26 * s * (1 - e)), child: child),
        );
      },
      child: Container(
        key: const Key('a1_butikk_minikurv'),
        constraints: BoxConstraints(maxHeight: maxH),
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          color: mork ? null : const Color(0xFFFDFCF9),
          gradient: mork
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E4F5C), Color(0xFF122F3A)],
                )
              : null,
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(color: mork ? rgba(255, 255, 255, .22) : rgba(255, 255, 255, .95)),
          boxShadow: [
            BoxShadow(
              color: mork ? rgba(4, 18, 26, .9) : rgba(15, 31, 43, .55),
              offset: Offset(0, 22 * s),
              blurRadius: onbBlur(40 * s),
              spreadRadius: -18 * s,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ButikkCopy.a1_butikk_i_kurven,
                    style: bText(context, 12, weight: FontWeight.w800, color: mork ? Colors.white : BergenColors.ink),
                  ),
                ),
                GestureDetector(
                  key: const Key('a1_butikk_tom_kurven'),
                  onTap: onEmpty,
                  child: Text(
                    ButikkCopy.a1_butikk_tom_kurven,
                    style: bText(
                      context,
                      11,
                      weight: FontWeight.w800,
                      color: mork ? const Color(0xFFF2884E) : const Color(0xFFB9441A),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(child: Column(children: [for (final l in lines) _line(context, l)])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, KurvLine l) {
    final s = context.bs;
    Widget step(String key, Path Function(double k) icon, VoidCallback onTap) => OnbPressable(
      key: Key(key),
      onTap: onTap,
      pressDy: 1.5,
      child: Container(
        width: 36 * s,
        height: 36 * s,
        alignment: Alignment.center,
        decoration: mork
            ? BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(255, 255, 255, .2), rgba(255, 255, 255, .1)],
                ),
                border: Border.all(color: rgba(255, 255, 255, .3)),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF3EFE6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: rgba(35, 32, 29, .5),
                    offset: Offset(0, 5 * s),
                    blurRadius: onbBlur(7 * s),
                    spreadRadius: -4 * s,
                  ),
                  BoxShadow(color: rgba(90, 74, 48, .3), offset: Offset(0, 2.5 * s)),
                  BoxShadow(color: const Color(0xFFD9D2C4), offset: Offset(0, 1.5 * s)),
                ],
              ),
        child: _Ico(12 * s, mork ? Colors.white : BergenColors.ink, 3.2, icon),
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9 * s),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: mork ? rgba(255, 255, 255, .14) : rgba(35, 32, 29, .07))),
      ),
      child: Row(
        children: [
          Container(
            width: 40 * s,
            height: 40 * s,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13 * s),
              gradient: cssLinear(165, const [Color(0xFFF6D9B4), Color(0xFFD2854A)]),
              boxShadow: [
                BoxShadow(
                  color: rgba(35, 32, 29, .4),
                  offset: Offset(0, 2 * s),
                  blurRadius: onbBlur(4 * s),
                  spreadRadius: -2 * s,
                ),
              ],
            ),
            child: l.imageUrl == null
                ? null
                : Image.network(l.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bText(
                    context,
                    12.5,
                    weight: FontWeight.w800,
                    letterSpacingEm: -.01,
                    color: mork ? Colors.white : BergenColors.ink,
                  ),
                ),
                SizedBox(height: 1 * s),
                Text(
                  '${ButikkCopy.a1_butikk_stk(l.quantity)} · ${ButikkCopy.kr(l.sum)}',
                  style: bText(
                    context,
                    10.5,
                    weight: FontWeight.w700,
                    color: mork ? rgba(255, 255, 255, .65) : BergenColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10 * s),
          Container(
            padding: EdgeInsets.all(3 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: mork ? rgba(0, 0, 0, .26) : rgba(35, 32, 29, .07),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                step(
                  'a1_butikk_linje_minus_${l.cartId}',
                  (k) => Path()
                    ..moveTo(6 * k, 12 * k)
                    ..lineTo(18 * k, 12 * k),
                  () => onMinus(l),
                ),
                SizedBox(width: 3 * s),
                SizedBox(
                  width: 17 * s,
                  child: Text(
                    '${l.quantity}',
                    textAlign: TextAlign.center,
                    style: bText(context, 12, weight: FontWeight.w800, color: mork ? Colors.white : BergenColors.ink),
                  ),
                ),
                SizedBox(width: 3 * s),
                step('a1_butikk_linje_plus_${l.cartId}', (k) => _plusPath(k, 6, 18), () => onPlus(l)),
              ],
            ),
          ),
          SizedBox(width: 10 * s),
          OnbPressable(
            key: Key('a1_butikk_linje_fjern_${l.cartId}'),
            onTap: () => onRemove(l),
            pressDy: 1.5,
            child: Container(
              width: (mork ? 32 : 30) * s,
              height: (mork ? 32 : 30) * s,
              alignment: Alignment.center,
              decoration: mork
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF2884E), Color(0xFFE0662C)],
                      ),
                      boxShadow: [BoxShadow(color: rgba(150, 60, 15, .8), offset: Offset(0, 3 * s))],
                    )
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFCEDE7), Color(0xFFF6DACE)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: rgba(120, 50, 25, .5),
                          offset: Offset(0, 5 * s),
                          blurRadius: onbBlur(8 * s),
                          spreadRadius: -4 * s,
                        ),
                        BoxShadow(color: rgba(120, 50, 25, .32), offset: Offset(0, 2.5 * s)),
                        BoxShadow(color: const Color(0xFFE3BCAA), offset: Offset(0, 1.5 * s)),
                      ],
                    ),
              child: _Ico(
                13 * s,
                mork ? Colors.white : const Color(0xFFB9441A),
                2.4,
                (k) => Path()
                  ..moveTo(4 * k, 7 * k)
                  ..lineTo(20 * k, 7 * k)
                  ..moveTo(9.5 * k, 7 * k)
                  ..lineTo(9.5 * k, 5 * k)
                  ..lineTo(14.5 * k, 5 * k)
                  ..lineTo(14.5 * k, 7 * k)
                  ..moveTo(6.5 * k, 7 * k)
                  ..lineTo(7.5 * k, 20 * k)
                  ..lineTo(16.5 * k, 20 * k)
                  ..lineTo(17.5 * k, 7 * k)
                  ..moveTo(10.5 * k, 11 * k)
                  ..lineTo(10.5 * k, 17 * k)
                  ..moveTo(13.5 * k, 11 * k)
                  ..lineTo(13.5 * k, 17 * k),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bar: Ægil pushes the cart (`aegSkyv`, wheels `hjulSnurr`, speed
/// lines `fartStrek`), the last three dishes riding in it (`varefall` when
/// one lands, the cart `kurvDunk`s, else `kurvRull`s); the count, and the
/// total → the Kurv and the payment.
class ButikkKurvBar extends StatelessWidget {
  const ButikkKurvBar({
    super.key,
    required this.lines,
    required this.count,
    required this.total,
    required this.pulse,
    required this.mini,
    required this.onToggle,
    required this.onPay,
    this.oransje = false,
  });

  final List<KurvLine> lines;
  final int count;
  final double total;
  final int pulse;
  final bool mini;
  final VoidCallback onToggle;
  final VoidCallback onPay;

  /// The Mote page's bar: orange, floating (`aeKnSvev 3.4s`) over its
  /// shadow (`aeKnSkygge`).
  final bool oransje;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final recent = lines.length <= 3 ? lines : lines.sublist(lines.length - 3);
    final names = [for (final l in lines.reversed.take(2)) l.name].join(' · ');
    final bar = OnbPressable(
      key: const Key('a1_butikk_kurvbar'),
      onTap: onPay,
      pressDy: 0,
      pressScale: .985,
      child: Container(
        height: 60 * s,
        padding: EdgeInsets.fromLTRB(8 * s, 0, 7 * s, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: oransje
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF68450), Color(0xFFE65A28)],
                )
              : cssLinear(160, const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], const [0, .6, 1]),
          border: Border.all(color: rgba(255, 255, 255, .22)),
          boxShadow: oransje
              ? null
              : [
                  BoxShadow(
                    color: rgba(30, 79, 92, .8),
                    offset: Offset(0, 18 * s),
                    blurRadius: onbBlur(32 * s),
                    spreadRadius: -12 * s,
                  ),
                ],
        ),
        foregroundDecoration: oransje
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(150, 40, 10, 0), rgba(150, 40, 10, .3)],
                  stops: const [.8, 1],
                ),
              )
            : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(children: [bergenInsetTop(radius: 999, alpha: oransje ? .4 : .32)]),
            ),
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: SizedBox(
                    width: 104 * s,
                    height: 52 * s,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const _Fart(left: -2, bottom: 30, w: 12, a: .75, delay: 0),
                        const _Fart(left: 1, bottom: 22, w: 9, a: .6, delay: 350),
                        const _Fart(left: -3, bottom: 13, w: 11, a: .5, delay: 700),
                        Positioned(
                          left: 6 * s,
                          bottom: 1 * s,
                          width: 42 * s,
                          child: BergenLoop(
                            durationMs: 1050,
                            builder: (context, p, child) {
                              final w = p == null ? 0.0 : kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                              return Transform.translate(
                                offset: Offset(0, -2.5 * s * w),
                                child: Transform.rotate(
                                  angle: (1 - 2.5 * w) * math.pi / 180,
                                  alignment: Alignment.bottomCenter,
                                  child: Transform.flip(flipX: true, child: child),
                                ),
                              );
                            },
                            child: Image.asset('assets/images/dashboard/side.png'),
                          ),
                        ),
                        Positioned(
                          left: 40 * s,
                          bottom: 0,
                          width: 64 * s,
                          height: 48 * s,
                          child: _Cart(recent: recent, pulse: pulse),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8 * s),
                Expanded(
                  child: GestureDetector(
                    key: const Key('a1_butikk_kurvbar_toggle'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggle,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ButikkCopy.a1_butikk_varer_i_kurven(count),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bText(
                                  context,
                                  14,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: -.02,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 5 * s),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 280),
                              curve: const Cubic(.3, 1.2, .5, 1),
                              turns: mini ? .5 : 0,
                              child: _Ico(13 * s, rgba(255, 255, 255, .85), 3.2, (k) => _chevron(k, up: true)),
                            ),
                          ],
                        ),
                        Text(
                          mini ? ButikkCopy.a1_butikk_endre_kurv : names,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bText(context, 10.5, weight: FontWeight.w600, color: rgba(255, 255, 255, .8)),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8 * s),
                Container(
                  key: const Key('a1_butikk_kurvbar_total'),
                  padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 9 * s),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: cssLinear(180, _kOrange3, const [0, .56, 1]),
                    boxShadow: [
                      BoxShadow(
                        color: rgba(200, 70, 25, .85),
                        offset: Offset(0, 10 * s),
                        blurRadius: onbBlur(14 * s),
                        spreadRadius: -7 * s,
                      ),
                      BoxShadow(color: rgba(120, 45, 15, .42), offset: Offset(0, 3 * s)),
                      BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 1.5 * s)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ButikkCopy.kr(total),
                        style: bText(context, 13.5, weight: FontWeight.w800, color: Colors.white),
                      ),
                      SizedBox(width: 6 * s),
                      _Ico(13 * s, Colors.white, 2.6, (k) => _chevron(k)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!oransje) return bar;
    return BergenLoop(
      durationMs: 3400,
      child: bar,
      builder: (context, p, child) {
        final e = p == null ? 0.0 : kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // `aeKnSkygge`: the shadow on the ground narrows as it lifts.
            Positioned(
              left: 0,
              right: 0,
              top: 61 * s,
              height: 15 * s,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 1 - .4 * e,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.translationValues(0, 5 * s * e, 0)..scaleByDouble(.8 * (1 - .18 * e), 1, 1, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [rgba(8, 26, 32, .5), rgba(8, 26, 32, 0)],
                          stops: const [0, .72],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(offset: Offset(0, -5 * s * e), child: child),
          ],
        );
      },
    );
  }
}

/// `fartStrek` — a speed line streaking back behind Ægil.
class _Fart extends StatelessWidget {
  const _Fart({required this.left, required this.bottom, required this.w, required this.a, required this.delay});

  final double left;
  final double bottom;
  final double w;
  final double a;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: left * s,
      bottom: bottom * s,
      child: BergenLoop(
        durationMs: 1050,
        delayMs: delay,
        builder: (context, p, child) {
          if (p == null) return const SizedBox.shrink();
          final o = p < .25 ? .9 * p / .25 : .9 * (1 - (p - .25) / .75);
          return Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset((7 - 20 * p) * s, 0),
              child: Transform.scale(scaleX: .5 + .9 * p, child: child),
            ),
          );
        },
        child: Container(
          width: w * s,
          height: 2.5 * s,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2 * s), color: rgba(220, 233, 236, a)),
        ),
      ),
    );
  }
}

class _Cart extends StatelessWidget {
  const _Cart({required this.recent, required this.pulse});

  final List<KurvLine> recent;
  final int pulse;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final cart = Stack(
      clipBehavior: Clip.none,
      children: [
        for (var n = 0; n < recent.length; n++)
          Positioned(
            left: (20 + n * 11) * s,
            bottom: (n == 1 ? 23 : 20) * s,
            width: 17 * s,
            height: 17 * s,
            child: n == recent.length - 1 && pulse > 0
                ? BergenOnce(
                    key: ValueKey('fall-$pulse'),
                    durationMs: 520,
                    builder: (context, p, child) {
                      final y = kf(p, const [0, .72, 1], const [-20, 2, 0], kBobleInn);
                      final sc = kf(p, const [0, .72, 1], const [.5, 1.12, 1], kBobleInn);
                      return Opacity(
                        opacity: (p / .4).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, y * s),
                          child: Transform.scale(scale: sc, child: child),
                        ),
                      );
                    },
                    child: _Ball(line: recent[n]),
                  )
                : _Ball(line: recent[n]),
          ),
        Positioned.fill(
          child: BergenLoop(
            durationMs: 1050,
            builder: (context, p, _) => CustomPaint(painter: _CartPainter((p ?? 0) * 2 * math.pi)),
          ),
        ),
      ],
    );
    // `kurvDunk` when a dish lands, else the idle `kurvRull`.
    return BergenOnce(
      key: ValueKey('dunk-$pulse'),
      durationMs: pulse == 0 ? 1 : 580,
      builder: (context, p, child) {
        if (pulse == 0 || p >= 1) {
          return BergenLoop(
            durationMs: 3400,
            builder: (context, q, child) {
              final w = q == null ? 0.0 : kf(q, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
              return Transform.translate(
                offset: Offset(1.5 * s * w, 0),
                child: Transform.rotate(
                  angle: (-.8 + 1.6 * w) * math.pi / 180,
                  alignment: const Alignment(.28, 1),
                  child: child,
                ),
              );
            },
            child: child,
          );
        }
        final x = kf(p, const [0, .22, .55, .8, 1], const [0, -3.5, 2.5, -1, 0], const Cubic(.3, 1.2, .5, 1));
        final r = kf(p, const [0, .22, .55, .8, 1], const [0, -4, 2.5, -1, 0], const Cubic(.3, 1.2, .5, 1));
        return Transform.translate(
          offset: Offset(x * s, 0),
          child: Transform.rotate(angle: r * math.pi / 180, alignment: const Alignment(.28, 1), child: child),
        );
      },
      child: cart,
    );
  }
}

class _Ball extends StatelessWidget {
  const _Ball({required this.line});

  final KurvLine line;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: cssLinear(165, const [Color(0xFFF6D9B4), Color(0xFFD2854A)]),
      border: Border.all(color: Colors.white, width: 1.6),
      boxShadow: [BoxShadow(color: rgba(0, 20, 26, .8), offset: const Offset(0, 2), blurRadius: 2, spreadRadius: -2)],
    ),
    child: line.imageUrl == null
        ? null
        : Image.network(line.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
  );
}

class _CartPainter extends CustomPainter {
  _CartPainter(this.spin);

  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 64;
    canvas.save();
    canvas.scale(k);
    const ink = Color(0xFFDCE9EC);
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(1, 20)
        ..lineTo(8, 20)
        ..lineTo(13.5, 15.5),
      line..strokeWidth = 2.8,
    );
    final basket = Path()
      ..moveTo(13, 15)
      ..lineTo(54, 15)
      ..lineTo(48, 33.5)
      ..lineTo(19.5, 33.5)
      ..close();
    canvas.drawPath(basket, Paint()..color = rgba(255, 255, 255, .14));
    canvas.drawPath(basket, line..strokeWidth = 2.4);
    final thin = Paint()
      ..color = rgba(220, 233, 236, .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(23.5, 17), const Offset(26, 31.5), thin);
    canvas.drawLine(const Offset(32.5, 17), const Offset(33.5, 31.5), thin);
    canvas.drawLine(const Offset(41.5, 17), const Offset(41, 31.5), thin);
    canvas.drawLine(
      const Offset(15.5, 23),
      const Offset(51.5, 23),
      Paint()
        ..color = rgba(220, 233, 236, .35)
        ..strokeWidth = 1.4,
    );
    for (final cx in [24.0, 44.0]) {
      canvas.save();
      canvas.translate(cx, 40);
      canvas.rotate(spin);
      canvas.drawCircle(Offset.zero, 4.4, Paint()..color = const Color(0xFF12333C));
      canvas.drawCircle(
        Offset.zero,
        4.4,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final spoke = Paint()
        ..color = rgba(220, 233, 236, .7)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(0, -3.8), const Offset(0, 3.8), spoke);
      canvas.drawLine(const Offset(-3.8, 0), const Offset(3.8, 0), spoke);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CartPainter old) => old.spin != spin;
}
