import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../main.dart' show languages;
import '../../../bergen/kit/bergen_css.dart';
import '../../../bergen/kit/bergen_fav_heart.dart';
import '../../../bergen/kit/bergen_kit.dart';
import '../../../bergen/kit/bergen_motion.dart';
import '../../auth/onboarding_kit.dart';
import 'bergen_category_rad.dart';
import 'bergen_copy.dart';
import 'bergen_kit.dart';
import 'bergen_rails.dart';

// ignore_for_file: non_constant_identifier_names

/// Copy for the Ark (keys `ops_hjem_ark_*` in the ARB).
abstract final class HjemArkCopy {
  static String butikker(int n) => languages.ops_hjem_ark_butikker(n);
  static String under(String live, int n) => languages.ops_hjem_ark_under(live, butikker(n));
  static String populaert(String kat) => languages.ops_hjem_ark_populaert(kat);
  static String get mer => languages.ops_hjem_ark_mer;
  static String get lukk => languages.ops_hjem_ark_lukk;
  static String get gratisLevering => languages.ops_hjem_ark_gratis_levering;
  static String levering(String fee) => languages.ops_hjem_ark_levering(fee);
  static String get ingenVarer => languages.ops_hjem_ark_ingen_varer;
  static String legg(String navn) => languages.ops_hjem_ark_legg(navn);
}

/// A product of «Populært i {kategori}» (`ops/products?kind=populaert`).
class HjemArkProduct {
  const HjemArkProduct({
    required this.id,
    required this.name,
    required this.storeId,
    required this.storeName,
    required this.priceOre,
    this.imageUrl,
  });

  final int id;
  final String name;
  final int storeId;
  final String storeName;
  final int priceOre;
  final String? imageUrl;

  factory HjemArkProduct.fromJson(Map<String, dynamic> j) => HjemArkProduct(
    id: int.tryParse('${j['id']}') ?? 0,
    name: '${j['name'] ?? ''}',
    storeId: (j['store_id'] as num?)?.toInt() ?? 0,
    storeName: '${j['store_name'] ?? ''}',
    priceOre: (j['price_ore'] as num?)?.toInt() ?? 0,
    imageUrl: (j['image'] is String && (j['image'] as String).isNotEmpty) ? j['image'] as String : null,
  );

  /// `189 kr` / `1 299 kr` / `59,90 kr`.
  String get priceText {
    final kr = priceOre ~/ 100;
    final ore = priceOre % 100;
    final digits = '$kr';
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(' ');
      b.write(digits[i]);
    }
    return ore == 0 ? '$b kr' : '$b,${ore.toString().padLeft(2, '0')} kr';
  }
}

/// The design's orb art and chip icon per category look.
abstract final class _Look {
  static String orb(BergenCategoryLook? l) => switch (l) {
    BergenCategoryLook.fish => 'orb_fish',
    BergenCategoryLook.fashion => 'orb_mote',
    BergenCategoryLook.interior => 'orb_interior',
    BergenCategoryLook.gifts => 'orb_gaver',
    _ => 'orb_mat',
  };

  /// `romKat` P[] (24-box stroke paths): fork, fish, hanger, sofa, gift.
  static String chip(BergenCategoryLook? l) => switch (l) {
    BergenCategoryLook.fish => 'M3 12c3-5 8-7 13-6 2 1 3 3 4 6-1 3-2 5-4 6-5 1-10-1-13-6zM20 8l1-3-4 1M20 16l1 3-4-1',
    BergenCategoryLook.fashion => 'M12 4a2 2 0 1 1 2 2v2l8 5v3H2v-3l8-5V6',
    BergenCategoryLook.interior => 'M5 11V6a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v5M3 13h18v4H3zM5 17v3M19 17v3',
    BergenCategoryLook.gifts => 'M3 9h18v4H3zM5 13v8h14v-8M12 9v12',
    _ => 'M7 3v8M4 3v5a3 3 0 0 0 6 0V3M7 11v10M16 3c-2 2-2 6-2 8h4V3M17 11v10',
  };

  static const String dots = 'M5 12h.01M12 12h.01M19 12h.01';
}

Widget _strokeIcon(String d, double size, Color color, double width) => SvgPicture.string(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
  'stroke="#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}" '
  'stroke-width="$width" stroke-linecap="round" stroke-linejoin="round"><path d="$d"/></svg>',
  width: size,
  height: size,
);

/// The Hjem Ark (design L7146–7212, `st.ark`): what both «Se alle» buttons on
/// Hjem open — «Butikker på Bryggen» and «Populært i kveld» alike.
///
/// ## Design ledger — design → Flutter
///
/// **Sheet** — `top:96; left/right/bottom 0; r28 28 0 0; rgba(250,249,246,.86)
/// blur(40px) saturate(1.35); border-top 1px white .7; inset 0 1px 0 white
/// .7; 0 −20px 46px −20px rgba(15,31,43,.5); arkOpp .38s
/// cubic-bezier(.2,.9,.3,1)` (translateY 26 → 0, opacity .6 → 1); z above
/// Hjem, under the tab nav. Handle `44×5 r3 rgba(35,32,29,.28) margin 9
/// auto`, tap closes; also a downward drag past 80 px closes.
///
/// **Header** — `padding 6 16 0`; title `PJS 22px 800 −.025em #23201D`
/// (`katNavn`); line `11.5px 700 #6E6862` («{live} · N butikker»); close `36
/// circle 180deg #FFFFFF→#F6F2E9 · 0 0 0 1px white .9 · 0 2px 0
/// rgba(190,178,155,.8) · 0 8px 14px −8px rgba(35,32,29,.4)`, X `14 stroke 2.6`.
///
/// **Category chips** (`romKat`) — `padding 10 16 2; gap 8; h38; padding 0 13
/// 0 11; r14; gap 6; 11.5px 800 −.015em #23201D`; on: `180deg #FFDFC4 →
/// #F5B981 55% → #EDA366 · 0 0 0 2px white .9 · 0 2px 0 rgba(208,138,80,.9) ·
/// 0 3px 0 rgba(120,100,70,.35) · 0 14px 20px −10px rgba(0,0,0,.45)`, label
/// «Navn · live»; off: `180deg #FFFFFF→#F6F2E9 · 0 2px 0 rgba(190,178,155,.9) ·
/// 0 3px 0 rgba(120,100,70,.3) · 0 14px 20px −10px rgba(0,0,0,.35)`; icon `14
/// stroke 2.4` (#23201D on / #1E4F5C off) — fork, fish, hanger, sofa, gift,
/// «Mer» dots → Utforsk; pressed `translateY(1px) scale(.97)`. Choosing a chip
/// moves Hjem's orb row too (`hoppTil`).
///
/// **Scroll** — `top:112; padding 0 16 128`. «Butikker {på/i} {bydel}» `PJS
/// 15px 800 −.01em` + the Bergensk pill (`white .1 · border .18 · 3 9 ·
/// 6px #F2C14E lyktPuls 3s · 10px 800 #23201D`).
///
/// **Store grid** — 2 columns, gap 11, mt 10; card `180deg #FFFFFF→#F8F5EE ·
/// r22 · 0 0 0 1px white .9 · 0 2px 0 rgba(190,178,155,.75) · 0 3px 0
/// rgba(120,100,70,.28) · 0 16px 24px −12px rgba(35,32,29,.42)`, pressed
/// `translateY(1px) scale(.98)`; hero `88 {katHero}` + `radial 120% 80% at 26%
/// 8% white .55 → 0 62%`, orb `44 @ top 18`; «Åpen» pill `top8 left8 · 3 8 ·
/// white .5 blur 16 · border white .5 · 10px 700` with the lyktPuls dot;
/// heart `26 @7,7 white .5 blur 16 · border .55 · 13 stroke 1.9`; body `9 12
/// 11`: name `PJS 14px 800 −.015em`, ETA (clock `11 stroke 2.4 #6E6862`, `11px
/// 800`) + fee (`11px 800`; the design's truck is stroked with an unset
/// `b.fraktC` and renders invisible, so only its gap is kept), rating (`★ 11 #C9963B`, `11px 800`).
/// *Deviations:* a store with a banner shows the photo instead of the
/// category orb (the prototype has no photos in the Ark); the fee shows only
/// when the store list carries one (it does not today); «Stengt» replaces
/// «Åpen» for a closed store; the rating hides when the store has none.
///
/// **«Populært i {kat}»** — `padding 16 0 0 2`; pill `rgba(242,109,61,.12) ·
/// 10px 800 #B9441A · dot 5 #F26D3D` with the district; product card same
/// shell, hero `72` + `radial 120% 80% at 28% 8% .55 → 0 60%`, orb `38 @14`,
/// heart `24 @6,6` (the store's heart — hearts are per store in the app),
/// body `8 11 10`: name `PJS 13px 800`, store `11px 600 #8C847C`, price `PJS
/// 14px 800 −.01em`, add `30 · 160deg #F58A55→#E95C2C · 0 0 0 1.5px white .8
/// · 0 6px 12px −5px rgba(233,92,44,.8)`, `+ 14 stroke 2.6`, pressed
/// `scale(.84)`. Products come from `ops/products?kind=populaert` (most
/// ordered in 7 days first). *Deviation:* the product photo replaces the orb
/// when there is one; tapping the card opens the store on the product.
class HjemArk extends StatefulWidget {
  const HjemArk({
    super.key,
    required this.categories,
    required this.index,
    required this.stores,
    required this.openCount,
    required this.loadProducts,
    required this.onIndexChanged,
    required this.onClose,
    required this.onMore,
    required this.onOpenStore,
    required this.onOpenProduct,
    required this.onAdd,
  });

  final List<BergenCategory> categories;
  final int index;

  /// The focused category's stores (Hjem's own list).
  final List<BergenStoreCard> stores;
  final int openCount;
  final Future<List<HjemArkProduct>> Function(int categoryId) loadProducts;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onClose;
  final VoidCallback onMore;
  final ValueChanged<BergenStoreCard> onOpenStore;
  final ValueChanged<HjemArkProduct> onOpenProduct;
  final ValueChanged<HjemArkProduct> onAdd;

  @override
  State<HjemArk> createState() => _HjemArkState();
}

class _HjemArkState extends State<HjemArk> {
  final Map<int, List<HjemArkProduct>> _products = {};
  final Set<int> _loading = {};
  double _drag = 0;

  BergenCategory get _cat => widget.categories[widget.index.clamp(0, widget.categories.length - 1)];

  @override
  void initState() {
    super.initState();
    _ensure();
  }

  @override
  void didUpdateWidget(HjemArk old) {
    super.didUpdateWidget(old);
    _ensure();
  }

  Future<void> _ensure() async {
    final id = _cat.id;
    if (id == 0 || _products.containsKey(id) || _loading.contains(id)) return;
    _loading.add(id);
    final list = await widget.loadProducts(id);
    if (!mounted) return;
    setState(() {
      _loading.remove(id);
      _products[id] = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final cat = _cat;
    final look = cat.look;
    final bydel = look?.district ?? 'Bergen';
    final hero = look?.hero ?? BergenCategoryLook.restaurant.hero;
    final live = widget.openCount > 0 ? BergenCopy.openNow(widget.openCount) : cat.liveText;
    final products = _products[cat.id] ?? const <HjemArkProduct>[];
    final loadingProducts = _loading.contains(cat.id);

    return BergenOnce(
      key: const Key('a1_hjem_ark'),
      durationMs: 380,
      builder: (context, p, child) {
        final q = const Cubic(.2, .9, .3, 1).transform(p);
        return Opacity(
          opacity: .6 + .4 * q,
          child: Transform.translate(offset: Offset(0, 26 * (1 - q) * s + _drag), child: child),
        );
      },
      child: BergenCssShadow(
        radius: 28 * s,
        shadows: [BoxShadow(color: rgba(15, 31, 43, .5), offset: Offset(0, -20 * s), blurRadius: onbBlur(46 * s), spreadRadius: -20 * s)],
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28 * s)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 40 * s, sigmaY: 40 * s),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: rgba(250, 249, 246, .86),
                border: Border(top: BorderSide(color: rgba(255, 255, 255, .7))),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 112 * s,
                    bottom: 0,
                    child: ListView(
                      key: const Key('a1_hjem_ark_list'),
                      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 128 * s),
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(2 * s, 8 * s, 0, 0),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  BergenCopy.storesIn(bydel),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bDisplay(context, 15, letterSpacingEm: -.01, color: BergenColors.ink),
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              _Pill(
                                dot: const Color(0xFFF2C14E),
                                glow: true,
                                text: BergenCopy.bergensk,
                                bg: rgba(255, 255, 255, .1),
                                border: rgba(255, 255, 255, .18),
                                fg: BergenColors.ink,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10 * s),
                        if (widget.stores.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12 * s),
                            child: Text(BergenCopy.noStoresYet, style: bText(context, 12, weight: FontWeight.w600, color: const Color(0xFF6E6862))),
                          )
                        else
                          _Grid(
                            children: [
                              for (final st in widget.stores)
                                _StoreCard(store: st, hero: hero, orb: _Look.orb(look), onTap: () => widget.onOpenStore(st)),
                            ],
                          ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(2 * s, 16 * s, 0, 0),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  HjemArkCopy.populaert(cat.name),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bDisplay(context, 15, letterSpacingEm: -.01, color: BergenColors.ink),
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              _Pill(
                                dot: const Color(0xFFF26D3D),
                                dotSize: 5,
                                text: bydel,
                                bg: rgba(242, 109, 61, .12),
                                fg: const Color(0xFFB9441A),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10 * s),
                        if (products.isEmpty && !loadingProducts)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12 * s),
                            child: Text(HjemArkCopy.ingenVarer, key: const Key('a1_hjem_ark_ingen_varer'), style: bText(context, 12, weight: FontWeight.w600, color: const Color(0xFF6E6862))),
                          )
                        else
                          _Grid(
                            children: [
                              for (final pr in products)
                                _ProductCard(
                                  product: pr,
                                  hero: hero,
                                  orb: _Look.orb(look),
                                  onTap: () => widget.onOpenProduct(pr),
                                  onAdd: () => widget.onAdd(pr),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Handle + header + chips (fixed, above the scroll).
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, 400)),
                      onVerticalDragEnd: (_) {
                        if (_drag > 80 * s) {
                          widget.onClose();
                        } else {
                          setState(() => _drag = 0);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            key: const Key('a1_hjem_ark_handle'),
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onClose,
                            child: Padding(
                              padding: EdgeInsets.only(top: 9 * s),
                              child: Center(
                                child: Container(
                                  width: 44 * s,
                                  height: 5 * s,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(3 * s), color: rgba(35, 32, 29, .28)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(16 * s, 6 * s, 16 * s, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cat.name, key: const Key('a1_hjem_ark_title'), maxLines: 1, overflow: TextOverflow.ellipsis, style: bDisplay(context, 22, letterSpacingEm: -.025, color: BergenColors.ink)),
                                      SizedBox(height: 1 * s),
                                      Text(HjemArkCopy.under(live, widget.stores.length), style: bText(context, 11.5, color: const Color(0xFF6E6862))),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10 * s),
                                Semantics(
                                  button: true,
                                  label: HjemArkCopy.lukk,
                                  child: OnbPressable(
                                    key: const Key('a1_hjem_ark_lukk'),
                                    onTap: widget.onClose,
                                    pressScale: .92,
                                    child: Container(
                                      width: 36 * s,
                                      height: 36 * s,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF6F2E9)]),
                                        boxShadow: [
                                          BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 1),
                                          BoxShadow(color: rgba(190, 178, 155, .8), offset: Offset(0, 2 * s)),
                                          BoxShadow(color: rgba(35, 32, 29, .4), offset: Offset(0, 8 * s), blurRadius: onbBlur(14 * s), spreadRadius: -8 * s),
                                        ],
                                      ),
                                      child: _strokeIcon('M6 6l12 12M18 6L6 18', 14 * s, BergenColors.ink, 2.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 50 * s,
                            child: ListView(
                              key: const Key('a1_hjem_ark_chips'),
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 2 * s),
                              clipBehavior: Clip.none,
                              children: [
                                for (var i = 0; i < widget.categories.length; i++) ...[
                                  _Chip(
                                    key: Key('a1_hjem_ark_chip_$i'),
                                    label: i == widget.index ? '${widget.categories[i].name} · $live' : widget.categories[i].name,
                                    icon: _Look.chip(widget.categories[i].look),
                                    on: i == widget.index,
                                    onTap: () => widget.onIndexChanged(i),
                                  ),
                                  SizedBox(width: 8 * s),
                                ],
                                _Chip(key: const Key('a1_hjem_ark_mer'), label: HjemArkCopy.mer, icon: _Look.dots, on: false, onTap: widget.onMore),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bergenInsetTop(radius: 28 * s, height: 1 * s, alpha: .7),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: 11 * s),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(SizedBox(height: 11 * s));
    }
    return Column(children: rows);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.dot, required this.text, required this.bg, required this.fg, this.border, this.glow = false, this.dotSize = 6});

  final Color dot;
  final String text;
  final Color bg;
  final Color fg;
  final Color? border;
  final bool glow;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: dot, size: dotSize, glow: glow),
          SizedBox(width: 5 * s),
          Text(text, style: bText(context, 10, weight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

/// A dot, optionally on `lyktPuls 3s` (box-shadow 8px → 15px).
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, this.glow = false});

  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    if (!glow) {
      return Container(width: size * s, height: size * s, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
    }
    return BergenLoop(
      durationMs: 3000,
      builder: (context, p, _) {
        final q = kf(p ?? 0, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
        return Container(
          width: size * s,
          height: size * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: .9 + .1 * q), blurRadius: onbBlur((8 + 7 * q) * s))],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.icon, required this.on, required this.onTap});

  final String label;
  final String icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressScale: .97,
      child: AnimatedContainer(
        duration: BergenTokens.motion(context, const Duration(milliseconds: 200)),
        height: 38 * s,
        padding: EdgeInsets.only(left: 11 * s, right: 13 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14 * s),
          gradient: on
              ? cssLinear(180, const [Color(0xFFFFDFC4), Color(0xFFF5B981), Color(0xFFEDA366)], const [0, .55, 1])
              : cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF6F2E9)]),
          boxShadow: [
            BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 2 * s),
            BoxShadow(color: on ? rgba(208, 138, 80, .9) : rgba(190, 178, 155, .9), offset: Offset(0, 2 * s)),
            BoxShadow(color: on ? rgba(120, 100, 70, .35) : rgba(120, 100, 70, .3), offset: Offset(0, 3 * s)),
            BoxShadow(color: rgba(0, 0, 0, on ? .45 : .35), offset: Offset(0, 14 * s), blurRadius: onbBlur(20 * s), spreadRadius: -10 * s),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _strokeIcon(icon, 14 * s, on ? BergenColors.ink : const Color(0xFF1E4F5C), 2.4),
            SizedBox(width: 6 * s),
            Text(label, style: bText(context, 11.5, weight: FontWeight.w800, letterSpacingEm: -.015, color: BergenColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// The paper card shell both grids share.
class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22 * s),
        gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF8F5EE)]),
        boxShadow: [
          BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 1),
          BoxShadow(color: rgba(190, 178, 155, .75), offset: Offset(0, 2 * s)),
          BoxShadow(color: rgba(120, 100, 70, .28), offset: Offset(0, 3 * s)),
          BoxShadow(color: rgba(35, 32, 29, .42), offset: Offset(0, 16 * s), blurRadius: onbBlur(24 * s), spreadRadius: -12 * s),
        ],
      ),
      child: child,
    );
  }
}

/// The hero: the category gradient + sheen + orb, or the photo.
class _Hero extends StatelessWidget {
  const _Hero({required this.height, required this.hero, required this.orb, required this.orbSize, required this.orbTop, required this.sheenX, required this.sheenStop, this.imageUrl, this.children = const []});

  final double height;
  final LinearGradient hero;
  final String orb;
  final double orbSize;
  final double orbTop;
  final double sheenX;
  final double sheenStop;
  final String? imageUrl;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      height: height * s,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: hero)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(sheenX * 2 - 1, -.84),
                radius: 1.2,
                colors: [rgba(255, 255, 255, .55), rgba(255, 255, 255, 0)],
                stops: [0, sheenStop],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: orbTop * s),
              child: SizedBox(width: orbSize * s, height: orbSize * s, child: bergenSvg(orb)),
            ),
          ),
          if (imageUrl != null)
            Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
          ...children,
        ],
      ),
    );
  }
}

Widget _glassHeart(BuildContext context, int storeId, double size, double icon) =>
    BergenFavHeart(
      storeId: storeId,
      size: size,
      iconSize: icon,
      fill: rgba(255, 255, 255, .5),
      border: rgba(255, 255, 255, .55),
      strokeInk: BergenColors.ink,
    );

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.hero, required this.orb, required this.onTap});

  final BergenStoreCard store;
  final LinearGradient hero;
  final String orb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final fee = store.fee;
    return OnbPressable(
      key: Key('a1_hjem_ark_butikk_${store.id}'),
      onTap: onTap,
      pressScale: .98,
      child: _Shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              height: 88,
              hero: hero,
              orb: orb,
              orbSize: 44,
              orbTop: 18,
              sheenX: .26,
              sheenStop: .62,
              imageUrl: store.bannerUrl,
              children: [
                Positioned(
                  top: 8 * s,
                  left: 8 * s,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16 * s, sigmaY: 16 * s),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: rgba(255, 255, 255, .5),
                          border: Border.all(color: rgba(255, 255, 255, .5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Dot(color: store.open ? const Color(0xFFF2C14E) : const Color(0xFF9A9188), size: 6, glow: store.open),
                            SizedBox(width: 5 * s),
                            Text(store.open ? BergenCopy.open : BergenCopy.closed, style: bText(context, 10, color: BergenColors.ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (store.id != 0)
                  Positioned(top: 7 * s, right: 7 * s, child: _glassHeart(context, store.id, 26 * s, 13 * s)),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12 * s, 9 * s, 12 * s, 11 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: bDisplay(context, 14, letterSpacingEm: -.015, color: BergenColors.ink)),
                  SizedBox(height: 5 * s),
                  Row(
                    children: [
                      if (store.eta != null) ...[
                        _strokeIcon('M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17zM12 7.5V12l3 2', 11 * s, const Color(0xFF6E6862), 2.4),
                        SizedBox(width: 4 * s),
                        Text(store.eta!, style: bText(context, 11, weight: FontWeight.w800, color: BergenColors.ink)),
                        SizedBox(width: 7 * s),
                      ],
                      if (fee != null)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // The design's truck takes `b.fraktC`, which the
                              // store list never sets, so it renders invisible;
                              // only its 12 px + 4 px gap remain.
                              SizedBox(width: 16 * s),
                              Flexible(
                                child: Text(
                                  store.feeIsFree ? HjemArkCopy.gratisLevering : HjemArkCopy.levering(fee),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bText(context, 11, weight: FontWeight.w800, color: BergenColors.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (store.rating != null && store.rating != '0' && store.rating != '0.0' && store.rating != '0.00') ...[
                    SizedBox(height: 4 * s),
                    Row(
                      children: [
                        SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="#C9963B" d="M12 2.5l2.9 5.9 6.6 1-4.8 4.6 1.2 6.5L12 17.4l-5.9 3.1 1.2-6.5L2.5 9.4l6.6-1z"/></svg>',
                          width: 11 * s,
                          height: 11 * s,
                        ),
                        SizedBox(width: 4 * s),
                        Text(store.rating!, style: bText(context, 11, weight: FontWeight.w800, color: BergenColors.ink)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.hero, required this.orb, required this.onTap, required this.onAdd});

  final HjemArkProduct product;
  final LinearGradient hero;
  final String orb;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      key: Key('a1_hjem_ark_vare_${product.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _Shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              height: 72,
              hero: hero,
              orb: orb,
              orbSize: 38,
              orbTop: 14,
              sheenX: .28,
              sheenStop: .6,
              imageUrl: product.imageUrl,
              children: [
                if (product.storeId != 0)
                  Positioned(top: 6 * s, right: 6 * s, child: _glassHeart(context, product.storeId, 24 * s, 12 * s)),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(11 * s, 8 * s, 11 * s, 10 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: bDisplay(context, 13, letterSpacingEm: -.015, color: BergenColors.ink)),
                  SizedBox(height: 1 * s),
                  Text(product.storeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11, weight: FontWeight.w600, color: const Color(0xFF8C847C))),
                  SizedBox(height: 6 * s),
                  Row(
                    children: [
                      Expanded(
                        child: Text(product.priceText, maxLines: 1, overflow: TextOverflow.ellipsis, style: bDisplay(context, 14, letterSpacingEm: -.01, color: BergenColors.ink)),
                      ),
                      Semantics(
                        button: true,
                        label: HjemArkCopy.legg(product.name),
                        child: OnbPressable(
                          key: Key('a1_hjem_ark_legg_${product.id}'),
                          onTap: onAdd,
                          pressScale: .84,
                          child: Container(
                            width: 30 * s,
                            height: 30 * s,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: cssLinear(160, const [Color(0xFFF58A55), Color(0xFFE95C2C)]),
                              boxShadow: [
                                BoxShadow(color: rgba(255, 255, 255, .8), spreadRadius: 1.5),
                                BoxShadow(color: rgba(233, 92, 44, .8), offset: Offset(0, 6 * s), blurRadius: onbBlur(12 * s), spreadRadius: -5 * s),
                              ],
                            ),
                            child: _strokeIcon('M12 5v14M5 12h14', 14 * s, Colors.white, 2.6),
                          ),
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
