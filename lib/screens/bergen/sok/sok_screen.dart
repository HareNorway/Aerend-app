import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../data/ops/sok_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_home.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../butikk/produkt_sheet.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import 'sok_copy.dart';

/// `sok` (≈L4067–4228 in `Ærend Kunde Bergen.dc.html`).
///
/// Ægil landed at Flesland under the "BERGEN?" sign, asking "Hva leter du
/// etter?"; below, a teal panel with the design's four states: `sokTom`
/// (category stickers, the Spør Ægil card, Nylig / Populært nå, the week's
/// mission), `sokOnske` (the text reads like an errand — ask Ægil),
/// `sokHarTreff` + `sokVanlig` (shops, a product grid and the compare card)
/// and `sokIngen` (no hits — let Ægil find the nearest).
///
/// The screen has no field of its own: the design types into the nav pill.
/// In the shell, [controller] is that pill's field (the orb opened this
/// screen and closes it again). At `/bergen/sok` the screen mounts the same
/// nav, already in search mode, and closing it pops the route.
///
/// Results come from the app's search endpoints through
/// [OpsCustomerApi.search]; "Populært nå" from `ops.search.trending`; the
/// mission from agil-2's `points.mission` (guarded — hidden on 404).
class SokScreen extends StatefulWidget {
  const SokScreen({
    super.key,
    this.initialQuery,
    this.api,
    this.controller,
    this.onClose,
  });

  /// Overrides the route's `q` argument.
  final String? initialQuery;

  /// Injected in tests.
  final OpsCustomerApi? api;

  /// The shell's nav field. Null: the screen owns a field and its own nav.
  final TextEditingController? controller;

  /// The shell closes Søk; standalone, the route pops.
  final VoidCallback? onClose;

  static const String prefRecent = 'a1_sok_recent';
  static const String prefTried = 'a1_sok_tried';
  static const int maxRecent = 8;

  /// `onske` (design L7806): four or more words, or an errand word.
  static bool isWish(String q) {
    final ql = q.trim().toLowerCase();
    if (ql.isEmpty) return false;
    final words = ql.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words >= 4) return true;
    if (ql.contains('?')) return true;
    return RegExp(
      r'\b(for|under|til|noe|billig|billigste|uten|med|kr)\b',
    ).hasMatch(ql);
  }

  static List<String> readRecent() => _readList(prefRecent);

  static void remember(String q) {
    final term = q.trim();
    if (term.length < 2) return;
    final list = [
      term,
      ...readRecent().where((e) => e.toLowerCase() != term.toLowerCase()),
    ];
    prefSetString(prefRecent, jsonEncode(list.take(maxRecent).toList()));
  }

  static List<String> _readList(String key) {
    final raw = prefGetString(key);
    if (raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      return list is List
          ? list.map((e) => '$e').where((e) => e.isNotEmpty).toList()
          : const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  State<SokScreen> createState() => SokScreenState();
}

class SokScreenState extends State<SokScreen> {
  TextEditingController? _own;
  Timer? _debounce;
  int _seq = 0;
  bool _routeRead = false;
  String _lastQ = '';

  SokTreff? _treff;
  List<String> _recent = const [];
  List<SokTrend> _trending = const [];
  List<String> _tried = const [];
  Map<String, dynamic>? _mission;

  /// Standalone: the nav this screen mounts, held in search mode.
  final ValueNotifier<bool> _navOpen = ValueNotifier(true);
  final ValueNotifier<int> _cartCount = ValueNotifier(
    prefGetInt(prefCartCount),
  );

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  TextEditingController get _field =>
      widget.controller ?? (_own ??= TextEditingController());

  String get _q => _field.text.trim();

  @override
  void initState() {
    super.initState();
    _recent = SokScreen.readRecent();
    _tried = SokScreen._readList(SokScreen.prefTried);
    _field.addListener(_onChanged);
    _navOpen.addListener(_onNav);
    _load();
    if (_q.isNotEmpty) _onChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final q =
        widget.initialQuery ??
        (widget.controller == null ? BergenRoutes.argsOf(context)['q'] : null);
    if (q != null && q.trim().isNotEmpty) {
      _field.text = q.trim();
    }
  }

  @override
  void didUpdateWidget(SokScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_onChanged);
      _field.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _field.removeListener(_onChanged);
    _own?.dispose();
    _navOpen.dispose();
    _cartCount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trending = await _api.trendingItems();
    if (mounted) setState(() => _trending = trending);
    final mission = await _api.mission();
    if (mounted) {
      setState(() => _mission = mission?['mission'] as Map<String, dynamic>?);
    }
  }

  void _onChanged() {
    final q = _q;
    if (q == _lastQ) return;
    _lastQ = q;
    _debounce?.cancel();
    if (q.length < 2 || SokScreen.isWish(q)) {
      setState(() => _treff = null);
      return;
    }
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    final result = await _api.search(q);
    if (!mounted || seq != _seq) return;
    setState(() => _treff = result);
  }

  void _onNav() {
    if (!_navOpen.value) _close();
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// `sokEks*` / Nylig / Populært nå: the term goes into the field.
  void _use(String term) {
    _field.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    SokScreen.remember(term);
    setState(() => _recent = SokScreen.readRecent());
  }

  /// `sokTast` Enter: remembered, and to Ægil when it is a wish or found
  /// nothing.
  void submit() {
    final q = _q;
    if (q.isEmpty) return;
    SokScreen.remember(q);
    setState(() => _recent = SokScreen.readRecent());
    if (SokScreen.isWish(q) || (_treff?.isEmpty ?? false)) {
      _askAegil(q);
    }
  }

  /// `sokTilAegil` / `tilAgent`.
  void _askAegil([String? draft]) {
    HapticFeedback.selectionClick();
    final q = draft ?? _q;
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      arguments: {'q': q},
      orElse: () =>
          openScreen(context, SnurreChatScreen(draftFromHomeSearch: q)),
    );
  }

  void _openStore(int id, String name) => BergenRoutes.pushOr(
    context,
    '/bergen/butikk/$id',
    arguments: {'name': name},
    orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
  );

  /// A hit's card and its pill open the product sheet (`produkt`), where the
  /// customer picks options and adds — never a silent add from the grid.
  void _openProduct(SokProdukt p) {
    FocusManager.instance.primaryFocus?.unfocus();
    showProduktSheet(
      context,
      item: BergenMenuItem(
        id: p.id,
        name: p.name,
        storeId: p.storeId,
        storeName: p.storeName,
        price: p.price,
        wasPrice: p.wasPrice,
        imageUrl: p.imageUrl,
      ),
    );
  }

  /// `aapneKat(n)`; the category counts toward "Utforsker · n av 5".
  void _openCategory(String name) {
    final slug = BergenHomeSlug.of(name);
    if (!_tried.contains(slug)) {
      final tried = [..._tried, slug];
      prefSetString(SokScreen.prefTried, jsonEncode(tried));
      setState(() => _tried = tried);
    }
    BergenRoutes.pushOr(
      context,
      '/bergen/kategori/$slug',
      arguments: {'name': name},
      orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    // The design's hero is laid out under a 30px fake status bar; the real
    // one moves everything below it down by the difference.
    final dy = math.max(0.0, safeTop - 30 * s);
    final panelTop = 290 * s + dy;

    final screen = BergenOnce(
      durationMs: 340,
      builder: (context, p, child) {
        final e = kSkjermInn.transform(p);
        return Opacity(
          opacity: e.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - e)),
            child: Transform.scale(scale: .985 + .015 * e, child: child),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: cssLinear(
            180,
            const [
              Color(0xFF7E93A3),
              Color(0xFF9FB2BD),
              Color(0xFFB6BFB8),
              Color(0xFF456E7C),
              Color(0xFF2F5462),
              Color(0xFF1E4F5C),
              Color(0xFF173E48),
            ],
            const [0, .14, .19, .22, .34, .342, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: panelTop,
              child: _Hero(dy: dy),
            ),
            Positioned(
              top: safeTop + 10 * s,
              left: 16 * s,
              right: 16 * s,
              child: const _Bubble(),
            ),
            Positioned(
              top: panelTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: _panel(context),
            ),
          ],
        ),
      ),
    );

    if (widget.controller != null) {
      return Material(type: MaterialType.transparency, child: screen);
    }
    return Scaffold(
      backgroundColor: BergenColors.teal3,
      body: Stack(
        children: [
          Positioned.fill(child: screen),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BergenBottomNav(
              index: -1,
              onTab: (_) => _close(),
              cartCount: _cartCount,
              onSearch: (_) => submit(),
              onAegil: _askAegil,
              showHint: false,
              searchController: _field,
              searchOpen: _navOpen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final s = context.bs;
    final q = _q;
    final wish = q.isNotEmpty && SokScreen.isWish(q);
    final vanlig = q.isNotEmpty && !wish;
    final treff = vanlig ? _treff : null;
    final ingen = vanlig && q.length >= 2 && treff != null && treff.isEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26 * s)),
        gradient: cssLinear(
          180,
          const [Color(0xFF22586A), Color(0xFF1B4854), Color(0xFF173E48)],
          const [0, .4, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: rgba(4, 18, 26, .8),
            offset: Offset(0, -16 * s),
            blurRadius: onbBlur(34 * s),
            spreadRadius: -18 * s,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26 * s)),
        border: Border.all(color: rgba(255, 255, 255, .14)),
      ),
      child: Stack(
        children: [
          bergenInsetTop(radius: 26 * s, alpha: .28),
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26 * s)),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                0,
                6 * s,
                0,
                bergenNavReserve(context) + 22 * s,
              ),
              children: [
                for (final w in <Widget>[
                  if (wish)
                    _WishCard(
                      key: ValueKey('onske-$q'),
                      query: q,
                      onTap: () => _askAegil(),
                    ),
                  if (treff != null && !treff.isEmpty)
                    _Results(
                      treff: treff,
                      onStore: (b) => _openStore(b.id, b.name),
                      onProduct: _openProduct,
                    ),
                  if (vanlig) _CompareCard(query: q, onTap: () => _askAegil()),
                  if (ingen) _NoHits(query: q, onAsk: () => _askAegil()),
                  if (q.isEmpty) ..._tom(context),
                ])
                  w is _Categories
                      ? w
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16 * s),
                          child: w,
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _tom(BuildContext context) {
    final s = context.bs;
    final recent = _recent.take(3).toList();
    final trending = _trending.take(3).toList();
    return [
      _Categories(
        tried: _tried.length.clamp(0, 5),
        onOpen: _openCategory,
        onAll: () => BergenRoutes.push(context, '/bergen/utforsk'),
      ),
      SizedBox(height: 4 * s),
      _AegilCard(onStart: () => _askAegil(''), onExample: _use),
      if (recent.isNotEmpty || trending.isNotEmpty) ...[
        SizedBox(height: 12 * s),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (recent.isNotEmpty)
                Expanded(
                  child: _TermCard(
                    key: const Key('a1_sok_nylig'),
                    kicker: SokCopy.a1_sok_nylig,
                    icon: _ClockIcon(),
                    rows: [
                      for (final t in recent)
                        _TermRow(term: t, onTap: () => _use(t)),
                    ],
                  ),
                ),
              if (recent.isNotEmpty && trending.isNotEmpty)
                SizedBox(width: 12 * s),
              if (trending.isNotEmpty)
                Expanded(
                  child: _TermCard(
                    key: const Key('a1_sok_populaert'),
                    kicker: SokCopy.a1_sok_populaert,
                    icon: const _GlodDot(),
                    rows: [
                      for (final t in trending)
                        _TermRow(
                          term: t.term,
                          count: t.count,
                          onTap: () => _use(t.term),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      if (_mission != null) ...[
        SizedBox(height: 12 * s),
        _MissionCard(
          mission: _mission!,
          onSee: () => BergenRoutes.push(context, '/bergen/meg'),
        ),
      ],
    ];
  }
}

// ── shared pieces ───────────────────────────────────────────────────────────

const List<Color> _kOrange = [Color(0xFFF58A55), Color(0xFFE95C2C)];
const String _kGevir = 'assets/images/dashboard/sok_gevir.png';
const String _kVarde = 'assets/images/dashboard/sok_v_varde.png';
const String _kNoresto = 'assets/images/dashboard/noresto.png';

/// `linear-gradient(180deg,rgba(255,255,255,.14),rgba(255,255,255,.07))`,
/// the white hairline and the soft drop every glass card on the panel has.
class _Glass extends StatelessWidget {
  const _Glass({
    super.key,
    required this.radius,
    required this.padding,
    required this.child,
    this.top = .14,
    this.bottom = .07,
    this.border = .22,
    this.inset = .3,
  });

  final double radius;
  final EdgeInsets padding;
  final Widget child;
  final double top;
  final double bottom;
  final double border;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCssShadow(
      radius: radius,
      shadows: [
        BoxShadow(
          color: rgba(4, 18, 26, .8),
          offset: Offset(0, 14 * s),
          blurRadius: 24 * s,
          spreadRadius: -16 * s,
        ),
      ],
      child: Container(
        padding: padding,
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
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -padding.left,
              right: -padding.right,
              top: -padding.top,
              bottom: -padding.bottom,
              child: Stack(
                children: [bergenInsetTop(radius: radius, alpha: inset)],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// `linear-gradient(160deg,#2A6272,#1E4F5C 60%,#173E48)` with the mint ring —
/// the Spør Ægil card and the compare card.
BoxDecoration _aegilDeco(
  BuildContext context,
  double radius, {
  double lift = 20,
}) {
  final s = context.bs;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: cssLinear(
      160,
      const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)],
      const [0, .6, 1],
    ),
    border: Border.all(color: rgba(92, 224, 184, .45), width: 1.5),
    boxShadow: [
      BoxShadow(color: rgba(92, 224, 184, .1), spreadRadius: 4 * s),
      BoxShadow(
        color: rgba(30, 79, 92, .7),
        offset: Offset(0, (lift == 20 ? 20 : 14) * s),
        blurRadius: onbBlur((lift == 20 ? 34 : 24) * s),
        spreadRadius: (lift == 20 ? -16 : -14) * s,
      ),
    ],
  );
}

/// The design's 3D orange pill (`#F58A55 → #E95C2C`, a hard 2–3px drop).
class _OrangePill extends StatelessWidget {
  const _OrangePill({
    required this.height,
    required this.child,
    this.padding,
    this.width,
    this.drop = 3,
    this.soft = const [10, 16, -6],
  });

  final double height;
  final double? width;
  final EdgeInsets? padding;
  final Widget child;
  final double drop;
  final List<double> soft;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      height: height,
      width: width,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _kOrange,
        ),
        boxShadow: [
          BoxShadow(color: rgba(150, 60, 15, .85), offset: Offset(0, drop * s)),
          if (soft.isNotEmpty)
            BoxShadow(
              color: rgba(120, 50, 10, .72),
              offset: Offset(0, soft[0] * s),
              blurRadius: onbBlur(soft[1] * s),
              spreadRadius: soft[2] * s,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [bergenInsetTop(radius: 999, height: 1, alpha: .35), child],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.size, required this.color, this.stroke = 2.4});

  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _PathPainter(
      color,
      stroke,
      (k) => Path()
        ..moveTo(9 * k, 6 * k)
        ..lineTo(15 * k, 12 * k)
        ..lineTo(9 * k, 18 * k),
    ),
  );
}

/// A 24-unit stroked icon path, scaled to the paint size.
class _PathPainter extends CustomPainter {
  _PathPainter(this.color, this.stroke, this.path);

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
  bool shouldRepaint(_PathPainter old) =>
      old.color != color || old.stroke != stroke;
}

Widget _gevir(double w, double h, Color color) => Image.asset(
  _kGevir,
  width: w,
  height: h,
  fit: BoxFit.contain,
  color: color,
  colorBlendMode: BlendMode.srcIn,
);

/// The blurred `nl-grad` stroke (`#5CE0B8 → #9C7BE8`) behind the Ægil cards,
/// breathing with `glod 4s`.
class _NordlysGlow extends StatelessWidget {
  const _NordlysGlow({
    required this.width,
    required this.height,
    required this.path,
    required this.opacity,
  });

  final double width;
  final double height;
  final List<double> path;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return IgnorePointer(
      child: BergenLoop(
        durationMs: 4000,
        builder: (context, p, child) {
          final g = p == null
              ? .7
              : kf(p, const [0, .5, 1], const [.7, 1, .7], Curves.easeInOut);
          return Opacity(opacity: opacity * .7 * g, child: child);
        },
        child: CustomPaint(
          size: Size(width * s, height * s),
          painter: _GlowPainter(path, s),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.p, this.s);

  /// `M p0 p1 C p2..p7 C p8..p13`.
  final List<double> p;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(p[0] * s, p[1] * s)
      ..cubicTo(p[2] * s, p[3] * s, p[4] * s, p[5] * s, p[6] * s, p[7] * s)
      ..cubicTo(p[8] * s, p[9] * s, p[10] * s, p[11] * s, p[12] * s, p[13] * s);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22 * s
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * s)
        ..shader = const LinearGradient(
          colors: [Color(0xFF5CE0B8), Color(0xFF9C7BE8)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => false;
}

/// `bobleInn` — scale(.6) translateY(8px), faded in.
class _BobleInn extends StatelessWidget {
  const _BobleInn({required this.durationMs, required this.child});

  final double durationMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => BergenOnce(
    durationMs: durationMs,
    child: child,
    builder: (context, p, child) {
      final e = kBobleInn.transform(p);
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 8 * context.bs * (1 - e)),
          child: Transform.scale(scale: .6 + .4 * e, child: child),
        ),
      );
    },
  );
}

// ── hero: Flesland ──────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.dy});

  /// How far the real status bar pushes the design's layout down.
  final double dy;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // `kameradrift 26s` — the arrivals hall drifts under the camera.
          Positioned.fill(
            child: BergenLoop(
              durationMs: 26000,
              builder: (context, p, child) {
                final x = p == null
                    ? -4.0
                    : kf(
                        p,
                        const [0, .5, 1],
                        const [-4, 4, -4],
                        Curves.easeInOut,
                      );
                return Transform.translate(
                  offset: Offset(x * s, 0),
                  child: child,
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -6 * s,
                    left: -10 * s,
                    width: 410 * s,
                    height: 300 * s + dy,
                    child: Image.asset(
                      'assets/images/dashboard/sok_fl_flesland.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 42 * s,
            top: 120 * s + dy,
            width: 308 * s,
            height: 83 * s,
            child: Image.asset(
              'assets/images/dashboard/sok_fl_skiltet.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 70 * s,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x001E4F5C), Color(0xD91E4F5C)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 250 * s + dy,
            height: 38 * s,
            child: const _Railing(),
          ),
          Positioned(
            left: 24 * s,
            bottom: 4 * s,
            width: 120 * s,
            height: 96 * s,
            child: const _AegilLanded(),
          ),
          // `inset 0 -60px 60px -40px rgba(30,79,92,.9), inset 0 24px 40px
          // -20px rgba(4,18,26,.5)`.
          Positioned.fill(
            child: IgnorePointer(
              child: Column(
                children: [
                  Container(
                    height: 30 * s,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [rgba(4, 18, 26, .3), rgba(4, 18, 26, 0)],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 50 * s,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [rgba(30, 79, 92, 0), rgba(30, 79, 92, .6)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Railing extends StatelessWidget {
  const _Railing();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    Widget bar(double top) => Positioned(
      left: 0,
      right: 0,
      top: top * s,
      height: 5 * s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC9CFCC), Color(0xFF8F9694)],
          ),
          boxShadow: [
            BoxShadow(
              color: rgba(0, 0, 0, .3),
              offset: Offset(0, 2 * s),
              blurRadius: onbBlur(3 * s),
            ),
          ],
        ),
      ),
    );
    Widget post(double left) => Positioned(
      left: left * s,
      top: 6 * s,
      width: 6 * s,
      height: 30 * s,
      child: const ColoredBox(color: Color(0xFF9BA19E)),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [bar(8), bar(22), post(52), post(180), post(306)],
    );
  }
}

/// Ægil with his suitcase; `aegilNikk 3.6s 1s`.
class _AegilLanded extends StatelessWidget {
  const _AegilLanded();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 14 * s,
          bottom: 2 * s,
          width: 86 * s,
          height: 12 * s,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5 * s, sigmaY: 5 * s),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: rgba(0, 0, 0, .45),
                borderRadius: BorderRadius.all(
                  Radius.elliptical(43 * s, 6 * s),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 6 * s,
          width: 66 * s,
          child: BergenLoop(
            durationMs: 3600,
            delayMs: 1000,
            builder: (context, p, child) {
              if (p == null) return child!;
              final y = kf(
                p,
                const [0, .5, 1],
                const [0, -3, 0],
                Curves.easeInOut,
              );
              final r = kf(
                p,
                const [0, .5, 1],
                const [0, -2, 0],
                Curves.easeInOut,
              );
              return Transform.translate(
                offset: Offset(0, y * s),
                child: Transform.rotate(
                  angle: r * math.pi / 180,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              );
            },
            child: Image.asset(BergenAssets.aegilFront, width: 66 * s),
          ),
        ),
        Positioned(
          left: 62 * s,
          bottom: 6 * s,
          width: 34 * s,
          height: 46 * s,
          child: Image.asset(
            'assets/images/dashboard/sok_fl_koffert.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

/// "Hva leter du etter?" — `bobleFraAegil .55s .7s`.
class _Bubble extends StatelessWidget {
  const _Bubble();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenOnce(
      durationMs: 550,
      delayMs: 700,
      builder: (context, p, child) {
        final x = kf(p, const [0, .6, 1], const [-14, 2, 0], kBobleInn);
        final sc = kf(p, const [0, .6, 1], const [.7, 1.03, 1], kBobleInn);
        final o = kf(p, const [0, .6, 1], const [0, 1, 1], kBobleInn);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(x * s, 0),
            child: Transform.scale(
              scale: sc,
              alignment: Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
      child: BergenCssShadow(
        radius: 20 * s,
        shadows: [
          BoxShadow(
            color: rgba(4, 18, 26, .8),
            offset: Offset(0, 14 * s),
            blurRadius: 24 * s,
            spreadRadius: -14 * s,
          ),
        ],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 26 * s,
              bottom: -7 * s,
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Container(
                  width: 14 * s,
                  height: 14 * s,
                  decoration: BoxDecoration(
                    color: rgba(12, 34, 44, .66),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(3 * s),
                    ),
                    border: Border(
                      left: BorderSide(color: rgba(255, 255, 255, .28)),
                      bottom: BorderSide(color: rgba(255, 255, 255, .28)),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 14 * s,
                vertical: 10 * s,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20 * s),
                  topRight: Radius.circular(20 * s),
                  bottomRight: Radius.circular(20 * s),
                  bottomLeft: Radius.circular(6 * s),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(12, 34, 44, .72), rgba(12, 34, 44, .58)],
                ),
                border: Border.all(color: rgba(255, 255, 255, .28)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -14 * s,
                    right: -14 * s,
                    top: -10 * s,
                    bottom: -10 * s,
                    child: Stack(
                      children: [bergenInsetTop(radius: 20 * s, alpha: .3)],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SokCopy.a1_sok_title,
                        key: const Key('a1_sok_title'),
                        style: bDisplay(
                          context,
                          19,
                          weight: FontWeight.w800,
                          letterSpacingEm: -.02,
                          height: 1.05,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        SokCopy.a1_sok_subtitle,
                        style: bText(
                          context,
                          11,
                          weight: FontWeight.w600,
                          color: rgba(255, 255, 255, .75),
                        ),
                      ),
                    ],
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

// ── `sokOnske` ──────────────────────────────────────────────────────────────

class _WishCard extends StatelessWidget {
  const _WishCard({super.key, required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(top: 14 * s),
      child: _BobleInn(
        durationMs: 400,
        child: OnbPressable(
          onTap: onTap,
          pressDy: 0,
          pressScale: .985,
          child: Container(
            key: const Key('a1_sok_onske'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22 * s),
              gradient: cssLinear(
                160,
                const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)],
                const [0, .6, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: rgba(30, 79, 92, .75),
                  offset: Offset(0, 20 * s),
                  blurRadius: onbBlur(34 * s),
                  spreadRadius: -16 * s,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -16 * s,
                  top: -30 * s,
                  child: const _NordlysGlow(
                    width: 390,
                    height: 80,
                    opacity: .55,
                    path: [
                      0,
                      70,
                      80,
                      30,
                      160,
                      60,
                      240,
                      26,
                      300,
                      4,
                      350,
                      20,
                      390,
                      0,
                    ],
                  ),
                ),
                bergenInsetTop(radius: 22 * s, height: 1, alpha: .25),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * s,
                    vertical: 12 * s,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50 * s,
                        height: 50 * s,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16 * s),
                          color: rgba(255, 255, 255, .14),
                          border: Border.all(color: rgba(255, 255, 255, .25)),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -6 * s,
                              top: 4 * s,
                              width: 62 * s,
                              child: Image.asset(BergenAssets.aegilPopup),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              SokCopy.a1_sok_onske_title,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w800,
                                color: BergenColors.mint,
                              ),
                            ),
                            Text(
                              SokCopy.a1_sok_onske_ask(query),
                              style: bText(
                                context,
                                13.5,
                                weight: FontWeight.w800,
                                height: 1.3,
                                color: BergenColors.cream,
                              ),
                            ),
                            SizedBox(height: 2 * s),
                            Text(
                              SokCopy.a1_sok_onske_line,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFFB9CBD5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      _Chevron(
                        size: 16 * s,
                        color: BergenColors.cream,
                        stroke: 2.2,
                      ),
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

// ── `Søk · treff` ───────────────────────────────────────────────────────────

class _Results extends StatelessWidget {
  const _Results({
    required this.treff,
    required this.onStore,
    required this.onProduct,
  });

  final SokTreff treff;
  final ValueChanged<SokButikk> onStore;
  final ValueChanged<SokProdukt> onProduct;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final products = treff.produkter;
    return Padding(
      key: const Key('a1_sok_treff'),
      padding: EdgeInsets.only(top: 14 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (treff.butikker.isNotEmpty) ...[
            _SectionHead(
              label: SokCopy.a1_sok_butikker_label,
              count: SokCopy.a1_sok_butikker(treff.butikker.length),
            ),
            for (final b in treff.butikker) ...[
              SizedBox(height: 8 * s),
              _StoreRow(
                key: ValueKey('b-${b.id}'),
                butikk: b,
                onTap: () => onStore(b),
              ),
            ],
          ],
          if (treff.butikker.isNotEmpty && products.isNotEmpty)
            SizedBox(height: 16 * s),
          if (products.isNotEmpty) ...[
            _SectionHead(
              label: SokCopy.a1_sok_produkter_label,
              count: SokCopy.a1_sok_produkter(products.length),
            ),
            for (var i = 0; i < products.length; i += 2) ...[
              SizedBox(height: i == 0 ? 8 * s : 10 * s),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ProductCard(
                        key: ValueKey('p-${products[i].id}'),
                        produkt: products[i],
                        onAdd: () => onProduct(products[i]),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: i + 1 < products.length
                          ? _ProductCard(
                              key: ValueKey('p-${products[i + 1].id}'),
                              produkt: products[i + 1],
                              onAdd: () => onProduct(products[i + 1]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.label, required this.count});

  final String label;
  final String count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 6 * context.bs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style: bDisplay(
              context,
              15,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          count,
          style: bText(
            context,
            11,
            weight: FontWeight.w700,
            color: rgba(255, 255, 255, .6),
          ),
        ),
      ],
    ),
  );
}

/// `#FBF7EE` tile with the white ring and the cream 3D edge.
class _CreamTile extends StatelessWidget {
  const _CreamTile({
    required this.width,
    required this.height,
    required this.radius,
    required this.child,
    this.edge = true,
  });

  final double width;
  final double height;
  final double radius;
  final Widget child;
  final bool edge;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFFFBF7EE),
        boxShadow: [
          if (edge) ...[
            BoxShadow(
              color: rgba(0, 8, 12, .6),
              offset: Offset(0, 8 * s),
              blurRadius: onbBlur(12 * s),
              spreadRadius: -8 * s,
            ),
            BoxShadow(color: rgba(180, 170, 150, .9), offset: Offset(0, 3 * s)),
          ],
          BoxShadow(
            color: rgba(255, 255, 255, edge ? .55 : .5),
            spreadRadius: 1.5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            bergenInsetTop(radius: radius, height: 1, alpha: .7),
          ],
        ),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({super.key, required this.butikk, required this.onTap});

  final SokButikk butikk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final b = butikk;
    final line = [
      if (b.category != null) b.category!,
      if (b.etaMinutes != null) SokCopy.a1_sok_eta(b.etaMinutes!),
      if (!b.open) SokCopy.a1_sok_closed,
    ].join(' · ');
    return _BobleInn(
      durationMs: 350,
      child: OnbPressable(
        onTap: onTap,
        pressDy: 0,
        pressScale: .985,
        child: _Glass(
          radius: 20 * s,
          padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 12 * s, 10 * s),
          child: Row(
            children: [
              _CreamTile(
                width: 52 * s,
                height: 52 * s,
                radius: 16 * s,
                child: b.bannerUrl != null
                    ? Image.network(
                        b.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _StoreFallback(),
                      )
                    : const _StoreFallback(),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bDisplay(
                        context,
                        14,
                        weight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    if (line.isNotEmpty) ...[
                      SizedBox(height: 3 * s),
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bText(
                          context,
                          11.5,
                          weight: FontWeight.w600,
                          color: rgba(255, 255, 255, .7),
                        ),
                      ),
                    ],
                    if (b.rating != null || b.feeText != null) ...[
                      SizedBox(height: 5 * s),
                      Row(
                        children: [
                          if (b.rating != null) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 11 * s,
                              color: BergenColors.gold,
                            ),
                            SizedBox(width: 2 * s),
                            Text(
                              b.rating!,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          if (b.rating != null && b.feeText != null)
                            Container(
                              width: 3 * s,
                              height: 3 * s,
                              margin: EdgeInsets.symmetric(horizontal: 6 * s),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: rgba(255, 255, 255, .4),
                              ),
                            ),
                          if (b.feeText != null)
                            Flexible(
                              child: Text(
                                b.feeText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bText(
                                  context,
                                  10.5,
                                  weight: FontWeight.w700,
                                  color: BergenColors.mint,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12 * s),
              Container(
                width: 34 * s,
                height: 34 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rgba(255, 255, 255, .1),
                  border: Border.all(color: rgba(255, 255, 255, .2)),
                ),
                child: _Chevron(size: 14 * s, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `b.hero` — the teal tile with the category icon when there is no logo.
class _StoreFallback extends StatelessWidget {
  const _StoreFallback();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: cssLinear(160, const [Color(0xFF2F6B7B), Color(0xFF1B4854)]),
    ),
    child: Icon(
      Icons.storefront_rounded,
      size: 24 * context.bs,
      color: Colors.white70,
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({super.key, required this.produkt, required this.onAdd});

  final SokProdukt produkt;
  final VoidCallback onAdd;

  static String kr(double v) =>
      '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)} kr';

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final p = produkt;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: cssLinear(
          165,
          const [Color(0xFFF6D9B4), Color(0xFFE9A96E), Color(0xFFD2854A)],
          const [0, .52, 1],
        ),
      ),
      child: Icon(Icons.restaurant_rounded, size: 34 * s, color: Colors.white),
    );
    return _BobleInn(
      durationMs: 350,
      child: OnbPressable(
        onTap: onAdd,
        pressDy: 0,
        pressScale: .975,
        child: _Glass(
          radius: 22 * s,
          padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 8 * s, 10 * s),
          top: .13,
          bottom: .06,
          border: .2,
          inset: .28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: LayoutBuilder(
                  builder: (context, c) => _CreamTile(
                    width: c.maxWidth,
                    height: c.maxHeight,
                    radius: 16 * s,
                    edge: false,
                    child: p.imageUrl != null
                        ? Image.network(
                            p.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => fallback,
                          )
                        : fallback,
                  ),
                ),
              ),
              SizedBox(height: 8 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bDisplay(
                        context,
                        13,
                        weight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2 * s),
                    Text(
                      p.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bText(
                        context,
                        11,
                        weight: FontWeight.w600,
                        color: rgba(255, 255, 255, .7),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(height: 8 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        kr(p.price),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: bDisplay(
                          context,
                          14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    _OrangePill(
                      height: 32 * s,
                      padding: EdgeInsets.symmetric(horizontal: 12 * s),
                      drop: 2,
                      soft: const [6, 10, -5],
                      child: Text(
                        SokCopy.a1_sok_add,
                        style: bText(
                          context,
                          11.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
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
    );
  }
}

// ── `sokVanlig`: compare on price and delivery ──────────────────────────────

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(top: 14 * s),
      child: OnbPressable(
        onTap: onTap,
        pressDy: 0,
        pressScale: .985,
        child: Container(
          key: const Key('a1_sok_vanlig_footer'),
          padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 12 * s, 12 * s),
          decoration: _aegilDeco(context, 20 * s, lift: 14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -14 * s,
                right: -12 * s,
                top: -12 * s,
                bottom: -12 * s,
                child: Stack(
                  children: [
                    bergenInsetTop(radius: 20 * s, height: 1, alpha: .25),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40 * s,
                    height: 40 * s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14 * s),
                      color: rgba(92, 224, 184, .14),
                      border: Border.all(color: rgba(92, 224, 184, .35)),
                    ),
                    child: _gevir(20 * s, 12 * s, BergenColors.mint),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SokCopy.a1_sok_ask_aegil,
                          style: bText(
                            context,
                            11,
                            weight: FontWeight.w800,
                            letterSpacingEm: .06,
                            color: BergenColors.mint,
                          ),
                        ),
                        SizedBox(height: 2 * s),
                        Text(
                          SokCopy.a1_sok_compare(query),
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w700,
                            height: 1.3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  _OrangePill(
                    height: 34 * s,
                    width: 34 * s,
                    drop: 2,
                    soft: const [],
                    child: _Chevron(
                      size: 14 * s,
                      color: Colors.white,
                      stroke: 2.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── `sokIngen` ──────────────────────────────────────────────────────────────

class _NoHits extends StatelessWidget {
  const _NoHits({required this.query, required this.onAsk});

  final String query;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(top: 14 * s),
      child: _Glass(
        key: const Key('a1_sok_ingen'),
        radius: 22 * s,
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 16 * s),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              BergenLoop(
                durationMs: 3600,
                builder: (context, p, child) {
                  final y = p == null
                      ? 0.0
                      : kf(
                          p,
                          const [0, .5, 1],
                          const [0, -2.5, 0],
                          Curves.easeInOut,
                        );
                  return Transform.translate(
                    offset: Offset(0, y * s),
                    child: child,
                  );
                },
                child: Image.asset(
                  _kNoresto,
                  width: 72 * s,
                  height: 72 * s,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 10 * s),
              Text(
                SokCopy.a1_sok_ingen_title(query),
                textAlign: TextAlign.center,
                style: bDisplay(
                  context,
                  15,
                  weight: FontWeight.w800,
                  height: 1.25,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10 * s),
              Text(
                SokCopy.a1_sok_ingen_line,
                textAlign: TextAlign.center,
                style: bText(
                  context,
                  12,
                  weight: FontWeight.w600,
                  height: 1.4,
                  color: rgba(255, 255, 255, .7),
                ),
              ),
              SizedBox(height: 14 * s),
              OnbPressable(
                onTap: onAsk,
                pressDy: 0,
                pressScale: .96,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _OrangePill(
                    height: 42 * s,
                    padding: EdgeInsets.symmetric(horizontal: 18 * s),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _gevir(18 * s, 11 * s, Colors.white),
                        SizedBox(width: 8 * s),
                        Text(
                          SokCopy.a1_sok_ingen_cta,
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w800,
                            color: Colors.white,
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
    );
  }
}

// ── `sokTom`: category stickers ─────────────────────────────────────────────

class _Categories extends StatelessWidget {
  const _Categories({
    required this.tried,
    required this.onOpen,
    required this.onAll,
  });

  final int tried;
  final ValueChanged<String> onOpen;
  final VoidCallback onAll;

  /// The design's five stickers (their labels are drawn in), the app's
  /// category names they open, and the tilt each one is stuck on with.
  static const List<(String, String, double)> stickers = [
    ('restaurant', 'Restaurant', -5),
    ('fisk', 'Fisk', 3),
    ('mote', 'Mote', -2),
    ('interior', 'Interiør', 2),
    ('gaver', 'Gaver', -3),
  ];

  /// `Alle 12` — the design's full category count. TODO(api): the live count.
  static const int alle = 12;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(22 * s, 14 * s, 22 * s, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  SokCopy.a1_sok_kategorier,
                  style: bDisplay(
                    context,
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _Glass(
                radius: 999,
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * s,
                  vertical: 4 * s,
                ),
                inset: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(_kVarde, width: 10 * s, height: 12 * s),
                    SizedBox(width: 6 * s),
                    Text(
                      SokCopy.a1_sok_utforsker(tried, stickers.length),
                      style: bText(
                        context,
                        10.5,
                        weight: FontWeight.w800,
                        color: BergenColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8 * s),
        // Full-bleed (`margin: 8px -16px 0; padding: 0 10px 14px`).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(10 * s, 0, 10 * s, 8 * s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stickers.length; i++) ...[
                _Sticker(
                  asset: stickers[i].$1,
                  tilt: stickers[i].$3,
                  label: kBergenLive[i % kBergenLive.length],
                  onTap: () => onOpen(stickers[i].$2),
                ),
                SizedBox(width: 2 * s),
              ],
              _Sticker(
                asset: 'mer',
                tilt: 2,
                label: SokCopy.a1_sok_alle(alle),
                onTap: onAll,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({
    required this.asset,
    required this.tilt,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final double tilt;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 96 * s,
        child: Column(
          children: [
            Transform.rotate(
              angle: tilt * math.pi / 180,
              child: Image.asset(
                'assets/images/dashboard/sok_stk_$asset.png',
                width: 94 * s,
                height: 94 * s,
              ),
            ),
            Transform.translate(
              offset: Offset(0, -6 * s),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 4 * s, sigmaY: 4 * s),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * s,
                      vertical: 4 * s,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: rgba(15, 31, 43, .45),
                      border: Border.all(color: rgba(255, 255, 255, .22)),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: bText(
                        context,
                        10.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

// ── `Søk · Spør Ægil` ───────────────────────────────────────────────────────

class _AegilCard extends StatelessWidget {
  const _AegilCard({required this.onStart, required this.onExample});

  final VoidCallback onStart;
  final ValueChanged<String> onExample;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onStart,
      pressDy: 0,
      pressScale: .985,
      child: Container(
        key: const Key('a1_sok_aegil_card'),
        decoration: _aegilDeco(context, 24 * s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.5 * s),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -20 * s,
                top: -34 * s,
                child: const _NordlysGlow(
                  width: 360,
                  height: 90,
                  opacity: .5,
                  path: [
                    0,
                    80,
                    70,
                    34,
                    140,
                    68,
                    210,
                    30,
                    260,
                    6,
                    310,
                    22,
                    360,
                    0,
                  ],
                ),
              ),
              bergenInsetTop(radius: 24 * s, height: 1, alpha: .25),
              Padding(
                padding: EdgeInsets.fromLTRB(18 * s, 16 * s, 16 * s, 14 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _gevir(18 * s, 11 * s, BergenColors.mint),
                        SizedBox(width: 8 * s),
                        Text(
                          SokCopy.a1_sok_aegil_kicker,
                          style: bText(
                            context,
                            11,
                            weight: FontWeight.w800,
                            letterSpacingEm: .06,
                            color: BergenColors.mint,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * s),
                    Padding(
                      padding: EdgeInsets.only(right: 76 * s),
                      child: Text(
                        SokCopy.a1_sok_aegil_line,
                        style: bDisplay(
                          context,
                          17,
                          weight: FontWeight.w800,
                          letterSpacingEm: -.015,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 14 * s),
                    Padding(
                      padding: EdgeInsets.only(right: 70 * s),
                      child: Wrap(
                        spacing: 7 * s,
                        runSpacing: 7 * s,
                        children: [
                          for (final ex in [
                            SokCopy.a1_sok_aegil_eks1,
                            SokCopy.a1_sok_aegil_eks2,
                          ])
                            OnbPressable(
                              onTap: () => onExample(ex),
                              pressDy: 0,
                              pressScale: .96,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 13 * s,
                                  vertical: 9 * s,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: rgba(255, 255, 255, .14),
                                  border: Border.all(
                                    color: rgba(255, 255, 255, .26),
                                  ),
                                ),
                                child: Text(
                                  ex,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: bText(
                                    context,
                                    12,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14 * s),
                    Padding(
                      // `padding-right:70px` with `nowrap`: the hint runs on under Ægil.
                      padding: EdgeInsets.zero,
                      child: LayoutBuilder(
                        builder: (context, c) => Row(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: c.maxWidth - 10 * s,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _OrangePill(
                                  height: 44 * s,
                                  padding: EdgeInsets.fromLTRB(
                                    16 * s,
                                    0,
                                    18 * s,
                                    0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomPaint(
                                        size: Size.square(15 * s),
                                        painter: _PathPainter(
                                          Colors.white,
                                          2.4,
                                          (k) => Path()
                                            ..moveTo(4 * k, 5 * k)
                                            ..lineTo(20 * k, 5 * k)
                                            ..lineTo(20 * k, 16 * k)
                                            ..lineTo(9 * k, 16 * k)
                                            ..lineTo(4 * k, 20 * k)
                                            ..close(),
                                        ),
                                      ),
                                      SizedBox(width: 8 * s),
                                      Text(
                                        SokCopy.a1_sok_aegil_start,
                                        style: bText(
                                          context,
                                          13,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8 * s),
                                      _Chevron(
                                        size: 14 * s,
                                        color: Colors.white,
                                        stroke: 2.6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10 * s),
                            Flexible(
                              child: Text(
                                SokCopy.a1_sok_aegil_skriv,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: bText(
                                  context,
                                  11,
                                  weight: FontWeight.w700,
                                  color: rgba(255, 255, 255, .65),
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
              // `aegVink 2.6s` — Ægil waves from the corner.
              Positioned(
                right: 2 * s,
                bottom: -12 * s,
                width: 70 * s,
                child: IgnorePointer(
                  child: BergenLoop(
                    durationMs: 2600,
                    builder: (context, p, child) {
                      if (p == null) return child!;
                      final r = kf(
                        p,
                        const [0, .25, .75, 1],
                        const [0, -6, 6, 0],
                        Curves.easeInOut,
                      );
                      return Transform.rotate(
                        angle: r * math.pi / 180,
                        alignment: Alignment.bottomCenter,
                        child: child,
                      );
                    },
                    child: Opacity(
                      opacity: .98,
                      child: Image.asset(BergenAssets.aegilPopup),
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

// ── Nylig / Populært nå ─────────────────────────────────────────────────────

class _TermCard extends StatelessWidget {
  const _TermCard({
    super.key,
    required this.kicker,
    required this.icon,
    required this.rows,
  });

  final String kicker;
  final Widget icon;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return _Glass(
      radius: 22 * s,
      padding: EdgeInsets.all(14 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              icon,
              SizedBox(width: 6 * s),
              Text(
                kicker,
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w800,
                  letterSpacingEm: .06,
                  color: rgba(255, 255, 255, .7),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: 4 * s),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.term, required this.onTap, this.count});

  final String term;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final nylig = count == null;
    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .97,
      child: Container(
        constraints: BoxConstraints(minHeight: 36 * s),
        padding: EdgeInsets.only(left: 10 * s, right: (nylig ? 4 : 10) * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * s),
          color: rgba(255, 255, 255, .08),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                term,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bText(
                  context,
                  13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8 * s),
            if (nylig)
              _Chevron(size: 14 * s, color: rgba(255, 255, 255, .5))
            else
              Text(
                '$count',
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w800,
                  color: BergenColors.mint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClockIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(12 * context.bs),
    painter: _PathPainter(
      rgba(255, 255, 255, .7),
      2.4,
      (k) => Path()
        ..addOval(
          Rect.fromCircle(center: Offset(12 * k, 12 * k), radius: 9 * k),
        )
        ..moveTo(12 * k, 7 * k)
        ..lineTo(12 * k, 12 * k)
        ..lineTo(15 * k, 14 * k),
    ),
  );
}

/// The orange live dot, `glod 1.6s`.
class _GlodDot extends StatelessWidget {
  const _GlodDot();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenLoop(
      durationMs: 1600,
      builder: (context, p, child) => Opacity(
        opacity: p == null
            ? .7
            : kf(p, const [0, .5, 1], const [.7, 1, .7], Curves.easeInOut),
        child: child,
      ),
      child: Container(
        width: 7 * s,
        height: 7 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BergenColors.orange,
          boxShadow: [
            BoxShadow(
              color: rgba(242, 109, 61, .9),
              blurRadius: onbBlur(8 * s),
            ),
          ],
        ),
      ),
    );
  }
}

// ── `Søk · Ukens oppdrag` ───────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.onSee});

  final Map<String, dynamic> mission;
  final VoidCallback onSee;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final points = (mission['points'] as num?)?.toInt() ?? 0;
    final body = '${mission['body'] ?? ''}';
    return OnbPressable(
      onTap: onSee,
      pressDy: 0,
      pressScale: .985,
      child: _Glass(
        key: const Key('a1_sok_oppdrag'),
        radius: 22 * s,
        padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 12 * s, 12 * s),
        child: Row(
          children: [
            Container(
              width: 44 * s,
              height: 44 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14 * s),
                color: rgba(92, 224, 184, .14),
                border: Border.all(color: rgba(92, 224, 184, .35)),
              ),
              child: Image.asset(_kVarde, width: 22 * s, height: 28 * s),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SokCopy.a1_sok_oppdrag_kicker(points),
                    style: bText(
                      context,
                      11,
                      weight: FontWeight.w800,
                      letterSpacingEm: .06,
                      color: BergenColors.mint,
                    ),
                  ),
                  SizedBox(height: 3 * s),
                  Text(
                    '${mission['title'] ?? ''}',
                    style: bDisplay(
                      context,
                      14,
                      weight: FontWeight.w800,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    SizedBox(height: 2 * s),
                    Text(
                      body,
                      style: bText(
                        context,
                        11.5,
                        weight: FontWeight.w600,
                        color: rgba(255, 255, 255, .7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12 * s),
            _OrangePill(
              height: 36 * s,
              padding: EdgeInsets.symmetric(horizontal: 14 * s),
              soft: const [8, 14, -6],
              child: Text(
                SokCopy.a1_sok_oppdrag_se,
                style: bText(
                  context,
                  12,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
