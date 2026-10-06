import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../bergen/kit/svg_sti.dart';
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
    this.searchController,
    this.searchOpen,
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

  /// The search field's text, shared with the Søk screen it drives.
  final TextEditingController? searchController;

  /// Search mode, when the owner shows Søk while it is on. Submitting then
  /// stays in search mode (the design's Enter never closes Søk).
  final ValueNotifier<bool>? searchOpen;

  /// The Meg tab, for effects that fly to it (onboarding `myntRegn`).
  static final GlobalKey megTabKey = GlobalKey(debugLabel: 'megTab');

  /// Bumps the Meg tab (scale 1 → 1.18 → 1, 480ms) when incremented.
  static final ValueNotifier<int> megBump = ValueNotifier<int>(0);

  /// Incremented to give the search field focus (a Nylige søk chip).
  static final ValueNotifier<int> focusSearch = ValueNotifier<int>(0);

  @override
  State<BergenBottomNav> createState() => _BergenBottomNavState();
}

class _BergenBottomNavState extends State<BergenBottomNav> {
  bool _ownSearch = false;
  TextEditingController? _ownQuery;
  final FocusNode _focus = FocusNode();
  Timer? _hold;
  bool _held = false;
  int _lastCount = 0;
  int _pulse = 0;

  bool get _search => widget.searchOpen?.value ?? _ownSearch;

  TextEditingController get _query =>
      widget.searchController ?? (_ownQuery ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _lastCount = widget.cartCount.value;
    widget.cartCount.addListener(_onCount);
    widget.searchOpen?.addListener(_onOpen);
    BergenBottomNav.focusSearch.addListener(_onFocusRequest);
  }

  void _onFocusRequest() {
    if (mounted && _search) _focus.requestFocus();
  }

  @override
  void didUpdateWidget(BergenBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchOpen != widget.searchOpen) {
      oldWidget.searchOpen?.removeListener(_onOpen);
      widget.searchOpen?.addListener(_onOpen);
    }
  }

  /// The owner opened or closed search mode (the orb, or [openSearch]).
  /// Opening leaves the field unfocused, as the design's `gaa('sok')` does;
  /// a tap on it (or a Nylige søk chip) brings the keyboard.
  void _onOpen() {
    if (!mounted) return;
    setState(() {});
    if (!_search) _focus.unfocus();
  }

  void _onCount() {
    if (widget.cartCount.value > _lastCount) setState(() => _pulse++);
    _lastCount = widget.cartCount.value;
  }

  @override
  void dispose() {
    widget.cartCount.removeListener(_onCount);
    widget.searchOpen?.removeListener(_onOpen);
    BergenBottomNav.focusSearch.removeListener(_onFocusRequest);
    _hold?.cancel();
    _ownQuery?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final open = !_search;
    if (!open) _query.clear();
    final owner = widget.searchOpen;
    if (owner != null) {
      owner.value = open; // [_onOpen] follows.
      return;
    }
    setState(() => _ownSearch = open);
    if (!open) _focus.unfocus();
  }

  void _submit() {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    widget.onSearch(q);
    if (widget.searchOpen == null) _toggleSearch();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 16 * s);
    return SizedBox(
      height: 62 * s + bottom + 80 * s,
      child: ListenableBuilder(
        listenable: Listenable.merge([_focus, _query]),
        builder: (context, _) {
          final har = _query.text.trim().isNotEmpty;
          // `fok` (design `sbVals`): in search, focused or holding text.
          final fok = _search && (_focus.hasFocus || har);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // `right: sbR` — 86 beside the orb, 14 once the field is in use.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(.3, 1.15, .4, 1),
                left: 14 * s,
                right: (fok ? 14 : 86) * s,
                bottom: bottom,
                height: 62 * s,
                child: _pill(context, fok, har),
              ),
              Positioned(
                right: 14 * s,
                bottom: bottom,
                child: _orb(context, fok),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(BuildContext context, bool fok, bool har) {
    final s = context.bs;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.ease,
      padding: EdgeInsets.symmetric(horizontal: 7 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        // `sbBg`, `sbKant`, `sbGlod`.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fok
              ? const [Color(0xFF31697A), Color(0xFF21566A)]
              : const [Color(0xFF2B5F6E), BergenColors.teal2],
        ),
        border: Border.all(
          color: fok
              ? const Color.fromRGBO(92, 224, 184, .6)
              : const Color(0x47FFFFFF),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(92, 224, 184, fok ? .14 : 0),
            spreadRadius: 4 * s,
          ),
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
        clipBehavior: Clip.none,
        children: [
          bergenInsetTop(
            radius: 999,
            alpha: .3,
            pad: EdgeInsets.symmetric(horizontal: 7 * s),
          ),
          // The one orange pill that glides between the tabs (`navPill`).
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _search ? 0 : 1,
                child: _NavPille(index: widget.index, s: s),
              ),
            ),
          ),
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
                  _tab(context, 3, BergenCopy.navMe, _MeIcon(), meg: true),
                ],
              ),
            ),
          ),
          // `padding:0 6px 0 17px` from the pill's edge (it pads 7).
          Positioned(
            left: 10 * s,
            right: -1 * s,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_search,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _search ? 1 : 0,
                child: _searchRow(context, fok, har),
              ),
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
    bool meg = false,
  }) {
    final s = context.bs;
    final on = widget.index == i;
    final color = on ? Colors.white : const Color.fromRGBO(255, 255, 255, .78);
    Widget wrapMeg(Widget w) => meg
        ? KeyedSubtree(key: BergenBottomNav.megTabKey, child: _MegBump(child: w))
        : w;
    return Expanded(
      child: wrapMeg(OnbPressable(
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
              // Tabs are transparent; the pill behind them moves (`fane`).
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * s),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
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
      )),
    );
  }

  /// The search field row (`sokOp`): lupe, field, ✕, divider and the
  /// orange key that is Ægil + mic at rest and a go-lupe with text.
  Widget _searchRow(BuildContext context, bool fok, bool har) {
    final s = context.bs;
    const gap = 9.0;
    return Row(
      children: [
        // `sbLupeC` / `sbLupeTr`: rotate(-14deg) scale(1.12), .45s.
        _Tw(
          v: fok ? 1 : 0,
          ms: 450,
          curve: const Cubic(.3, 1.5, .5, 1),
          builder: (t) => Transform.rotate(
            angle: -14 * t * math.pi / 180,
            child: Transform.scale(
              scale: 1 + .12 * t,
              child: _Tw(
                v: fok ? 1 : 0,
                ms: 300,
                curve: Curves.ease,
                builder: (c) => _SvgIkon(
                  '${_SvgIkon.sirkel(11, 11, 7)}M20.5 20.5l-4.3-4.3',
                  size: 18 * s,
                  stroke: 2.4,
                  color: Color.lerp(
                    BergenColors.orange,
                    BergenColors.mint,
                    c,
                  )!,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: gap * s),
        Expanded(
          child: TextField(
            key: const Key('a1_sok_field'),
            controller: _query,
            focusNode: _focus,
            onSubmitted: (_) => _submit(),
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
        if (har) ...[
          SizedBox(width: gap * s),
          GestureDetector(
            key: const Key('a1_sok_null'),
            behavior: HitTestBehavior.opaque,
            onTap: _query.clear,
            child: Container(
              width: 24 * s,
              height: 24 * s,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0x29FFFFFF),
                shape: BoxShape.circle,
              ),
              child: _SvgIkon(
                'M6 6l12 12M18 6L6 18',
                size: 9 * s,
                stroke: 3,
                color: Colors.white,
              ),
            ),
          ),
        ],
        SizedBox(width: gap * s),
        // `sbSkilleOp`.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
          opacity: fok ? 0 : 1,
          child: Container(
            width: 1,
            height: 26 * s,
            color: const Color.fromRGBO(255, 255, 255, .14),
          ),
        ),
        SizedBox(width: gap * s),
        _sokKnapp(context, fok, har),
      ],
    );
  }

  /// `sbKnFn`: with text, search (`sokGaa`); empty, Ægil (`gaa('agent')`).
  Widget _sokKnapp(BuildContext context, bool fok, bool har) {
    final s = context.bs;
    return OnbPressable(
      key: const Key('a1_sok_knapp'),
      onTap: () {
        if (har) {
          _submit();
        } else {
          HapticFeedback.selectionClick();
          _toggleSearch();
          widget.onAegil('');
        }
      },
      pressDy: 0,
      pressScale: .92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: const Cubic(.3, 1.25, .4, 1),
        width: (fok ? 46 : 92) * s,
        height: 46 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment(-.34, -.94),
            end: Alignment(.34, .94),
            colors: [Color(0xFFFF9466), Color(0xFFE95C2C)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA63A12),
              offset: Offset(0, 2.5 * s),
            ),
            BoxShadow(
              color: const Color.fromRGBO(3, 16, 24, .75),
              offset: Offset(0, 10 * s),
              blurRadius: onbBlur(14 * s),
              spreadRadius: -8 * s,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // `inset 0 -2px 0 rgba(0,0,0,.08)`.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 2 * s,
                child: const ColoredBox(color: Color.fromRGBO(0, 0, 0, .08)),
              ),
              bergenInsetTop(radius: 999, height: 1, alpha: .45),
              // Ægil (`sbAvOp` .28s, `sbAvTr` .45s cubic(.3,1.3,.5,1)).
              Positioned(
                left: 5 * s,
                top: 5 * s,
                width: 36 * s,
                height: 36 * s,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.ease,
                  opacity: fok ? 0 : 1,
                  child: _Tw(
                    v: fok ? 1 : 0,
                    ms: 450,
                    curve: const Cubic(.3, 1.3, .5, 1),
                    builder: (t) => Transform.translate(
                      offset: Offset(-22 * s * t, 0),
                      child: Transform.scale(
                        scale: 1 - .5 * t,
                        child: Transform.rotate(
                          angle: -20 * t * math.pi / 180,
                          child: const _SokAegil(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Mic (`sbMikX` .5s, `sbMikOp` .22s, `sbMikTr` .4s).
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(.3, 1.25, .4, 1),
                left: (fok ? 16 : 61) * s,
                top: 16 * s,
                width: 14 * s,
                height: 14 * s,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.ease,
                  opacity: har ? 0 : 1,
                  child: _Tw(
                    v: har ? 1 : 0,
                    ms: 400,
                    curve: const Cubic(.3, 1.4, .5, 1),
                    builder: (t) => Transform.scale(
                      scale: 1 - .7 * t,
                      child: Transform.rotate(
                        angle: -30 * t * math.pi / 180,
                        child: _SvgIkon(
                          'M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-3 3a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3z'
                          'M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21',
                          size: 14 * s,
                          stroke: 2.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Go-lupe (`sbGaOp` .22s, `sbGaTr` .45s cubic(.3,1.5,.5,1)).
              Positioned(
                left: 14 * s,
                top: 14 * s,
                width: 18 * s,
                height: 18 * s,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.ease,
                  opacity: har ? 1 : 0,
                  child: _Tw(
                    v: har ? 0 : 1,
                    ms: 450,
                    curve: const Cubic(.3, 1.5, .5, 1),
                    builder: (t) => Transform.translate(
                      offset: Offset(0, 14 * s * t),
                      child: Transform.scale(
                        scale: 1 - .5 * t,
                        child: Transform.rotate(
                          angle: 40 * t * math.pi / 180,
                          child: _SvgIkon(
                            '${_SvgIkon.sirkel(11, 11, 6.5)}M20 20l-4-4',
                            size: 18 * s,
                            stroke: 2.8,
                            color: Colors.white,
                          ),
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
    );
  }

  Widget _orb(BuildContext context, bool fok) {
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
        // `orbSkjulOp` / `orbSnu`: in use, the orb spins away (180°, .4)
        // and the pill takes its place.
        IgnorePointer(
          ignoring: fok,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            opacity: fok ? 0 : 1,
            child: _orbKnapp(context, fok),
          ),
        ),
      ],
    );
  }

  Widget _orbKnapp(BuildContext context, bool fok) {
    final snu = !_search ? 0.0 : (fok ? 180.0 : 90.0);
    return _Tw(
      v: snu,
      ms: 450,
      curve: const Cubic(.3, 1.2, .5, 1),
      builder: (deg) => Transform.rotate(
        angle: deg * math.pi / 180,
        child: _Tw(
          v: fok ? .4 : 1,
          ms: 450,
          curve: const Cubic(.3, 1.2, .5, 1),
          builder: (sc) => Transform.scale(scale: sc, child: _orbFlate(context)),
        ),
      ),
    );
  }

  Widget _orbFlate(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
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
            curve: Curves.ease,
            width: 58 * s,
            height: 58 * s,
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
                  curve: Curves.ease,
                  opacity: _search ? 0 : 1,
                  child: _SvgIkon(
                    '${_SvgIkon.sirkel(11, 11, 7)}M20.5 20.5l-4.3-4.3',
                    size: 24 * s,
                    stroke: 2.4,
                    color: Colors.white,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                  opacity: _search ? 1 : 0,
                  child: Transform.rotate(
                    angle: -math.pi / 2,
                    child: _SvgIkon(
                      'M6 6l12 12M18 6L6 18',
                      size: 20 * s,
                      stroke: 2.6,
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

// ── Nav icons (the design's inline SVG paths) ───────────────────────────────

/// Eases [builder]'s value to [v] over [ms] whenever [v] changes (a CSS
/// `transition` on one property).
class _Tw extends StatelessWidget {
  const _Tw({
    required this.v,
    required this.ms,
    required this.curve,
    required this.builder,
  });

  final double v;
  final int ms;
  final Curve curve;
  final Widget Function(double v) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: v),
    duration: Duration(milliseconds: ms),
    curve: curve,
    builder: (context, t, _) => builder(t),
  );
}

/// A 24-unit stroked icon from the design's SVG `d`.
class _SvgIkon extends StatelessWidget {
  const _SvgIkon(
    this.d, {
    required this.size,
    required this.stroke,
    required this.color,
  });

  final String d;
  final double size;
  final double stroke;
  final Color color;

  static String sirkel(double cx, double cy, double r) =>
      'M${cx - r} ${cy}a$r $r 0 1 0 ${2 * r} 0a$r $r 0 1 0 ${-2 * r} 0';

  static final Map<String, Path> _cache = {};

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _StrokePainter(
      color,
      stroke,
      (k) => _cache
          .putIfAbsent(d, () => svgSti(d))
          .transform((Matrix4.identity()..scaleByDouble(k, k, 1, 1)).storage),
    ),
  );
}

/// Ægil in the search key's 36px window (`aegVink 2.6s`).
class _SokAegil extends StatelessWidget {
  const _SokAegil();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(-.34, -.94),
          end: Alignment(.34, .94),
          colors: [Color(0xFFDCE9EC), Color(0xFF9FB6C2)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -8 * s,
            top: 2 * s,
            width: 52 * s,
            child: RepaintBoundary(
              child: OnbLoopClock(
                child: Image.asset(BergenAssets.aegilPopup, width: 52 * s),
                builder: (context, t, child) {
                  final p = onbLoop(t, 0, 2600) ?? 0;
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
          ),
          bergenInsetTop(radius: 999, height: 1, alpha: .6),
        ],
      ),
    );
  }
}

/// `myntRegn`'s landing bump on the Meg tab.
class _MegBump extends StatelessWidget {
  const _MegBump({required this.child});

  final Widget child;

  static const Cubic _c = Cubic(.3, 1.5, .5, 1);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: BergenBottomNav.megBump,
      child: child,
      builder: (context, n, child) => n == 0
          ? child!
          : TweenAnimationBuilder<double>(
              key: ValueKey(n),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 480),
              child: child,
              builder: (context, v, child) {
                final k = v <= .5 ? _c.transform(v * 2) : 1 - _c.transform((v - .5) * 2);
                return Transform.scale(scale: 1 + .18 * k, child: child);
              },
            ),
    );
  }
}

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


/// `navPill`: left 7, 52 high, (100% − 23)/4 wide; glides
/// `translateX(i × (w + 3))` over .52s cubic(.32,1.28,.42,1) and squashes
/// (520ms) as it leaves.
class _NavPille extends StatefulWidget {
  const _NavPille({required this.index, required this.s});

  final int index;
  final double s;

  @override
  State<_NavPille> createState() => _NavPilleState();
}

class _NavPilleState extends State<_NavPille> with SingleTickerProviderStateMixin {
  late final AnimationController _sq = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didUpdateWidget(_NavPille old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) _sq.forward(from: 0);
  }

  @override
  void dispose() {
    _sq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final rolig = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        // The box is already inside the nav's 7px padding, so the design's
        // left 7 / (100% − 23px) / 4 become 0 / (inner − 3 gaps × 3px) / 4:
        // the pill lines up with the tab it sits behind.
        final w = (box.maxWidth - 9 * s) / 4;
        return TweenAnimationBuilder<double>(
          tween: Tween(end: widget.index * (w + 3 * s)),
          duration: Duration(milliseconds: rolig ? 0 : 520),
          curve: const Cubic(.32, 1.28, .42, 1),
          builder: (context, x, child) => Stack(
            children: [
              Positioned(
                left: x,
                top: (box.maxHeight - 52 * s) / 2,
                width: w,
                height: 52 * s,
                child: AnimatedBuilder(
                  animation: _sq,
                  builder: (context, child) {
                    final p = const Cubic(.3, .7, .3, 1).transform(_sq.value);
                    final sx = onbKf(p, const [0, .35, .7, 1], const [1, 1.22, .96, 1], Curves.linear);
                    final sy = onbKf(p, const [0, .35, .7, 1], const [1, .9, 1.03, 1], Curves.linear);
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(sx, sy, 1),
                      child: child,
                    );
                  },
                  child: child,
                ),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18 * s),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF58A55), Color(0xFFE95C2C)],
              ),
              boxShadow: [
                const BoxShadow(color: Color.fromRGBO(150, 60, 15, .85), offset: Offset(0, 2.5)),
                BoxShadow(
                  color: const Color.fromRGBO(4, 18, 26, .8),
                  offset: Offset(0, 9 * s),
                  blurRadius: onbBlur(15 * s),
                  spreadRadius: -7 * s,
                ),
              ],
            ),
            child: Stack(children: [bergenInsetTop(radius: 18 * s, alpha: .4)]),
          ),
        );
      },
    );
  }
}
