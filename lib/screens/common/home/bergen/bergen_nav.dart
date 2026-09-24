import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../auth/onboarding_kit.dart';
import 'bergen_copy.dart';
import 'bergen_kit.dart';

// ── Bottom nav (`visNav`) ───────────────────────────────────────────────────
// A pill with Hjem · Utforsk · Kurv · Meg and, to its right, the search orb.
// Tapping the orb turns the pill into a search field with an Ægil mic pill;
// holding the orb opens Ægil directly.

const double kBergenNavHeight = 62;
const double kBergenNavBottomGap = 16;

/// Space a page must leave free above the nav.
double bergenNavReserve(BuildContext context) =>
    context.bx(kBergenNavHeight + kBergenNavBottomGap) +
    math.max(
      MediaQuery.paddingOf(context).bottom - context.bx(kBergenNavBottomGap),
      0,
    );

enum BergenTab { home, explore, cart, me }

class BergenBottomNav extends StatefulWidget {
  const BergenBottomNav({
    super.key,
    required this.index,
    required this.onTab,
    required this.cartCount,
    required this.onSearch,
    required this.onAegil,
    this.showHint = true,
  });

  final int index;
  final ValueChanged<int> onTab;
  final ValueListenable<int> cartCount;

  /// Called with the typed query when the user submits the search field.
  final ValueChanged<String> onSearch;

  /// Called with the current draft when the Ægil pill or a long press on the
  /// orb asks for Ægil.
  final ValueChanged<String> onAegil;

  /// `aegilHint` — the one-off "Søk i Bergen" bubble above the orb.
  final bool showHint;

  @override
  State<BergenBottomNav> createState() => _BergenBottomNavState();
}

class _BergenBottomNavState extends State<BergenBottomNav> {
  bool _search = false;
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _hold;
  bool _held = false;
  int _lastCount = 0;
  int _pulse = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.cartCount.value;
    widget.cartCount.addListener(_onCount);
  }

  void _onCount() {
    if (widget.cartCount.value > _lastCount) setState(() => _pulse++);
    _lastCount = widget.cartCount.value;
  }

  @override
  void dispose() {
    widget.cartCount.removeListener(_onCount);
    _hold?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _search = !_search);
    if (_search) {
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted && _search) _focus.requestFocus();
      });
    } else {
      _focus.unfocus();
      _query.clear();
    }
  }

  void _submit() {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    widget.onSearch(q);
    _toggleSearch();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 16 * s);
    return SizedBox(
      height: 62 * s + bottom + 80 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14 * s,
            right: 86 * s,
            bottom: bottom,
            height: 62 * s,
            child: _pill(context),
          ),
          Positioned(right: 14 * s, bottom: bottom, child: _orb(context)),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context) {
    final s = context.bs;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      padding: EdgeInsets.symmetric(horizontal: 7 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B5F6E), BergenColors.teal2],
        ),
        border: Border.all(color: const Color(0x47FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(4, 18, 26, .85),
            offset: Offset(0, 18 * s),
            blurRadius: onbBlur(34 * s),
            spreadRadius: -14 * s,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          bergenInsetTop(radius: 999, alpha: .3),
          IgnorePointer(
            ignoring: _search,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _search ? 0 : 1,
              child: Row(
                children: [
                  _tab(context, 0, BergenCopy.navHome, _HomeIcon()),
                  SizedBox(width: 3 * s),
                  _tab(context, 1, BergenCopy.navExplore, _ExploreIcon()),
                  SizedBox(width: 3 * s),
                  _tab(context, 2, BergenCopy.navCart, _CartIcon(), cart: true),
                  SizedBox(width: 3 * s),
                  _tab(context, 3, BergenCopy.navMe, _MeIcon()),
                ],
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !_search,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _search ? 1 : 0,
              child: _searchRow(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    int i,
    String label,
    Widget icon, {
    bool cart = false,
  }) {
    final s = context.bs;
    final on = widget.index == i;
    final color = on ? Colors.white : const Color(0xC7FFFFFF);
    return Expanded(
      child: OnbPressable(
        onTap: () => widget.onTab(i),
        pressScale: .94,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(4 * s, 7 * s, 4 * s, 6 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * s),
                gradient: on ? kBergenNavActiveGradient : null,
                boxShadow: on
                    ? [
                        const BoxShadow(
                          color: Color.fromRGBO(150, 60, 15, .85),
                          offset: Offset(0, 2.5),
                        ),
                        BoxShadow(
                          color: const Color.fromRGBO(4, 18, 26, .8),
                          offset: Offset(0, 9 * s),
                          blurRadius: onbBlur(15 * s),
                          spreadRadius: -7 * s,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (on) bergenInsetTop(radius: 18 * s, alpha: .4),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 19 * s,
                        height: 19 * s,
                        child: IconTheme(
                          data: IconThemeData(color: color, size: 19 * s),
                          child: icon,
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      cart
                          ? ValueListenableBuilder<int>(
                              valueListenable: widget.cartCount,
                              builder: (context, n, _) => Text(
                                n > 0 ? BergenCopy.cartItems(n) : label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bText(
                                  context,
                                  9.5,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: -.01,
                                  color: color,
                                ),
                              ),
                            )
                          : Text(
                              label,
                              maxLines: 1,
                              style: bText(
                                context,
                                9.5,
                                weight: FontWeight.w800,
                                letterSpacingEm: -.01,
                                color: color,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
            if (cart)
              Positioned(
                top: 0,
                right: 6 * s,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.cartCount,
                  builder: (context, n, _) {
                    if (n <= 0 || on) return const SizedBox.shrink();
                    return OnbTimeline(
                      key: ValueKey('badge-$_pulse'),
                      durationMs: 420,
                      builder: (context, t, child) {
                        final sc = _pulse == 0
                            ? 1.0
                            : onbKf(
                                onbP(t, 0, 420),
                                const [0, .35, .7, 1],
                                const [1, 1.16, .96, 1],
                                const Cubic(.34, 1.56, .64, 1),
                              );
                        return Transform.scale(scale: sc, child: child);
                      },
                      child: Container(
                        constraints: BoxConstraints(minWidth: 15 * s),
                        height: 15 * s,
                        padding: EdgeInsets.symmetric(horizontal: 4 * s),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BergenColors.orange,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: BergenColors.orange.withValues(alpha: .9),
                              offset: Offset(0, 3 * s),
                              blurRadius: onbBlur(7 * s),
                              spreadRadius: -3 * s,
                            ),
                          ],
                        ),
                        child: Text(
                          '$n',
                          style: bText(context, 9.5, weight: FontWeight.w800),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchRow(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(left: 10 * s),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20 * s, color: BergenColors.orange),
          SizedBox(width: 9 * s),
          Expanded(
            child: TextField(
              controller: _query,
              focusNode: _focus,
              onSubmitted: (_) => _submit(),
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              cursorColor: BergenColors.mint,
              style: bDisplay(context, 14, weight: FontWeight.w700),
              decoration: onbBareInput(
                hint: BergenCopy.searchHint,
                hintStyle: bDisplay(
                  context,
                  14,
                  weight: FontWeight.w700,
                  color: const Color(0x99FFFFFF),
                ),
              ),
            ),
          ),
          if (_query.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(_query.clear),
              child: Container(
                width: 24 * s,
                height: 24 * s,
                margin: EdgeInsets.only(right: 6 * s),
                decoration: const BoxDecoration(
                  color: Color(0x29FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 12 * s,
                  color: Colors.white,
                ),
              ),
            ),
          Container(width: 1, height: 26 * s, color: const Color(0x1F23201D)),
          SizedBox(width: 6 * s),
          OnbPressable(
            onTap: () {
              final draft = _query.text.trim();
              _toggleSearch();
              widget.onAegil(draft);
            },
            pressScale: .95,
            child: Container(
              height: 46 * s,
              padding: EdgeInsets.only(left: 5 * s, right: 13 * s),
              decoration: BoxDecoration(
                gradient: kBergenOrangeGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(120, 50, 10, .9),
                    offset: Offset(0, 8 * s),
                    blurRadius: onbBlur(14 * s),
                    spreadRadius: -8 * s,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36 * s,
                    height: 36 * s,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment(-.34, -.94),
                        end: Alignment(.34, .94),
                        colors: [Color(0xFFDCE9EC), Color(0xFF9FB6C2)],
                      ),
                    ),
                    child: OnbLoopClock(
                      child: Transform.translate(
                        offset: Offset(-8 * s, 2 * s),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Image.asset(
                            BergenAssets.aegilPopup,
                            width: 52 * s,
                          ),
                        ),
                      ),
                      builder: (context, t, child) {
                        final p = (onbLoop(t, 0, 2600) ?? 0);
                        final r = onbKf(
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
                    ),
                  ),
                  SizedBox(width: 7 * s),
                  Icon(
                    Icons.mic_none_rounded,
                    size: 16 * s,
                    color: BergenColors.cream,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(BuildContext context) {
    final s = context.bs;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        if (widget.showHint && !_search)
          Positioned(
            right: 0,
            bottom: 72 * s,
            width: 176 * s,
            child: IgnorePointer(
              child: OnbTimeline(
                durationMs: 15400,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * s,
                    vertical: 9 * s,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16 * s),
                      topRight: Radius.circular(16 * s),
                      bottomLeft: Radius.circular(16 * s),
                      bottomRight: Radius.circular(4 * s),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC0C222C), Color(0xA80C222C)],
                    ),
                    border: Border.all(color: const Color(0x47FFFFFF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(4, 18, 26, .8),
                        offset: Offset(0, 14 * s),
                        blurRadius: onbBlur(26 * s),
                        spreadRadius: -12 * s,
                      ),
                    ],
                  ),
                  child: Text(
                    BergenCopy.searchTip,
                    style: bText(context, 11.5, height: 1.35),
                  ),
                ),
                builder: (context, t, child) {
                  // aegilHint 14s 1.4s — pops in, lingers, fades.
                  final p = onbP(t, 1400, 14000);
                  const st = [0.0, .05, .07, .4, .46, 1.0];
                  final sc = onbKf(p, st, const [
                    .6,
                    1.04,
                    1,
                    1,
                    .8,
                    .8,
                  ], const Cubic(.3, 1.3, .5, 1));
                  final dy = onbKf(p, st, const [
                    8,
                    -2,
                    0,
                    0,
                    6,
                    6,
                  ], const Cubic(.3, 1.3, .5, 1));
                  final o = onbKf(p, st, const [
                    0,
                    1,
                    1,
                    1,
                    0,
                    0,
                  ], Curves.easeInOut);
                  if (o <= 0) return const SizedBox.shrink();
                  return Opacity(
                    opacity: o.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, dy * s),
                      child: Transform.scale(
                        alignment: Alignment.bottomRight,
                        scale: sc,
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            _held = false;
            _hold?.cancel();
            _hold = Timer(const Duration(milliseconds: 480), () {
              _held = true;
              widget.onAegil(_query.text.trim());
            });
          },
          onTapUp: (_) {
            _hold?.cancel();
            if (!_held) _toggleSearch();
          },
          onTapCancel: () => _hold?.cancel(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: const Cubic(.3, 1.2, .5, 1),
            width: 58 * s,
            height: 58 * s,
            transform: Matrix4.rotationZ(_search ? math.pi / 2 : 0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22 * s),
              gradient: _search
                  ? const LinearGradient(
                      begin: Alignment(-.34, -.94),
                      end: Alignment(.34, .94),
                      colors: [BergenColors.orangeSoft, BergenColors.orangeHot],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2B5F6E), BergenColors.teal2],
                    ),
              border: Border.all(color: const Color(0x4DFFFFFF)),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(4, 18, 26, .85),
                  offset: Offset(0, 18 * s),
                  blurRadius: onbBlur(30 * s),
                  spreadRadius: -16 * s,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                bergenInsetTop(radius: 22 * s, alpha: .32),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _search ? 0 : 1,
                  child: Icon(
                    Icons.search_rounded,
                    size: 26 * s,
                    color: Colors.white,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _search ? 1 : 0,
                  child: Transform.rotate(
                    angle: -math.pi / 2,
                    child: Icon(
                      Icons.close_rounded,
                      size: 22 * s,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Nav icons (the design's inline SVG paths) ───────────────────────────────

class _HomeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StrokePainter(
      IconTheme.of(context).color!,
      2,
      (k) => Path()
        ..moveTo(4 * k, 10.5 * k)
        ..lineTo(12 * k, 4 * k)
        ..lineTo(20 * k, 10.5 * k)
        ..moveTo(6 * k, 9.5 * k)
        ..lineTo(6 * k, 20 * k)
        ..lineTo(18 * k, 20 * k)
        ..lineTo(18 * k, 9.5 * k),
    ),
  );
}

class _ExploreIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StrokePainter(
      IconTheme.of(context).color!,
      1.9,
      (k) => Path()
        ..addOval(
          Rect.fromCircle(center: Offset(12 * k, 12 * k), radius: 8.5 * k),
        )
        ..moveTo(15.5 * k, 8.5 * k)
        ..lineTo(13.3 * k, 13.3 * k)
        ..lineTo(8.5 * k, 15.5 * k)
        ..lineTo(10.7 * k, 10.7 * k)
        ..close(),
    ),
  );
}

class _CartIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StrokePainter(
      IconTheme.of(context).color!,
      1.9,
      (k) => Path()
        ..moveTo(5 * k, 7 * k)
        ..lineTo(19 * k, 7 * k)
        ..lineTo(17.7 * k, 18 * k)
        ..lineTo(6.3 * k, 18 * k)
        ..close()
        ..moveTo(9 * k, 7 * k)
        ..lineTo(9 * k, 5.5 * k)
        ..arcToPoint(Offset(15 * k, 5.5 * k), radius: Radius.circular(3 * k))
        ..lineTo(15 * k, 7 * k),
    ),
  );
}

class _MeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StrokePainter(
      IconTheme.of(context).color!,
      1.9,
      (k) => Path()
        ..addOval(
          Rect.fromCircle(center: Offset(12 * k, 8 * k), radius: 3.6 * k),
        )
        ..moveTo(5.5 * k, 20 * k)
        ..cubicTo(6.8 * k, 16.7 * k, 9.1 * k, 15 * k, 12 * k, 15 * k)
        ..cubicTo(14.9 * k, 15 * k, 17.2 * k, 16.7 * k, 18.5 * k, 20 * k),
    ),
  );
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.color, this.width, this.build);
  final Color color;
  final double width;
  final Path Function(double k) build;

  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 24;
    c.drawPath(
      build(k),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_StrokePainter old) => old.color != color;
}
