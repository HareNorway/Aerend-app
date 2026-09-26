import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../auth/onboarding_kit.dart';
import 'bergen_copy.dart';
import '../../../bergen/kit/bergen_fav_heart.dart';
import 'bergen_kit.dart';

// ── The two 3D rails (`railVals` / `pRailVals`) ─────────────────────────────
// Three cards on a turntable: the focused card faces you, the other two sit
// behind at ±134px, rotated 30° and scaled .92, blurred and dimmed. The rail
// advances by itself (stores every 5.4s, products every 6.2s); tapping a
// side card or a dot brings it to the front, tapping the front card opens it.

class BergenStoreCard {
  const BergenStoreCard({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.open,
    this.bannerUrl,
    this.bannerAsset,
    this.logoUrl,
    this.logoAsset,
    this.eta,
    this.fee,
    this.rating,
    this.offer,
    this.video = false,
  });

  final int id;
  final String name;
  final String subtitle;
  final bool open;
  final String? bannerUrl;
  final String? bannerAsset;
  final String? logoUrl;
  final String? logoAsset;
  final String? eta;

  /// Delivery fee text ("45 kr" / "Gratis"); null hides the chip.
  final String? fee;
  final String? rating;
  final String? offer;
  final bool video;

  bool get feeIsFree => fee != null && fee!.toLowerCase().startsWith('gratis');
}

class BergenProductCard {
  const BergenProductCard({
    required this.id,
    required this.name,
    required this.store,
    required this.priceText,
    required this.price,
    this.storeId = 0,
    this.imageUrl,
    this.imageAsset,
    this.wasPrice,
    this.offer,
    this.hero,
  });

  final int id;
  final String name;
  final String store;
  final String priceText;
  final double price;
  final int storeId;
  final String? imageUrl;
  final String? imageAsset;
  final String? wasPrice;
  final String? offer;
  final Gradient? hero;
}

/// Generic turntable of up to three children. Each card sits at an angle on
/// the ring — 0 faces you, ±120° are the two behind — and the ring turns as
/// one continuous angle, so a card swings round the back instead of cutting
/// across the front (the design's `railSving`).
class _Rail extends StatefulWidget {
  const _Rail({
    required this.height,
    required this.cardTop,
    required this.count,
    required this.intervalMs,
    required this.builder,
    required this.onOpen,
  });

  final double height;
  final double cardTop;
  final int count;
  final int intervalMs;
  final Widget Function(BuildContext, int index, bool front) builder;
  final ValueChanged<int> onOpen;

  @override
  State<_Rail> createState() => _RailState();
}

class _RailState extends State<_Rail> {
  int _focus = 0;

  /// How many steps the ring has turned in total; drives the angle tween.
  double _turns = 0;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_Rail old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      _focus = 0;
      _turns = 0;
      _start();
    }
  }

  void _start() {
    _auto?.cancel();
    if (widget.count < 2) return;
    _auto = Timer.periodic(Duration(milliseconds: widget.intervalMs), (_) {
      if (!mounted) return;
      _advance(1);
    });
  }

  void _advance(int steps) {
    setState(() {
      _focus = (_focus + steps) % widget.count;
      _turns += steps;
    });
  }

  void _pick(int i) {
    final n = widget.count;
    _advance((i - _focus + n) % n);
    _start();
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final n = widget.count;
    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final pa = (a - _focus + n) % n;
        final pb = (b - _focus + n) % n;
        return (pa == 0 ? 1 : 0).compareTo(pb == 0 ? 1 : 0);
      });
    return Column(
      children: [
        SizedBox(
          height: widget.height * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [for (final i in order) _card(context, i, n)],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) SizedBox(width: 6 * s),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pick(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: const Cubic(.3, 1.2, .5, 1),
                  width: (i == _focus ? 22 : 6) * s,
                  height: 6 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3 * s),
                    gradient: i == _focus
                        ? const LinearGradient(
                            colors: [
                              BergenColors.orangeSoft,
                              BergenColors.orangeHot,
                            ],
                          )
                        : null,
                    color: i == _focus ? null : const Color(0x59F28A55),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _card(BuildContext context, int i, int n) {
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    final step = 2 * math.pi / math.max(n, 3);
    final front = i == _focus;
    return Positioned(
      left: w / 2 - 126 * s,
      top: widget.cardTop * s,
      width: 252 * s,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: (i - _turns) * step),
        duration: const Duration(milliseconds: 1250),
        curve: const Cubic(.62, .02, .34, 1),
        builder: (context, a, child) {
          // Design slots at ±120°: x ±134, z −170, rotateY ∓30°, scale .92,
          // opacity .48, blur 1.6.
          final sn = math.sin(a);
          final back = (1 - math.cos(a)) / 1.5; // 0 front … 1 at ±120°
          final tx = 154.7 * sn;
          final tz = -170 * back;
          final ry = -34.6 * sn;
          final sc = 1 - .08 * back;
          final op = 1 - .52 * back;
          final bl = 1.6 * back;
          final m = Matrix4.identity()
            ..setEntry(3, 2, -1 / 1100)
            ..translateByDouble(tx * s, 0, tz * s, 1)
            ..rotateY(ry * math.pi / 180)
            ..scaleByDouble(sc, sc, 1, 1);
          Widget out = Transform(
            alignment: Alignment.center,
            transform: m,
            child: Opacity(opacity: op.clamp(0.0, 1.0), child: child),
          );
          if (bl > .05) out = onbBlurred(bl, out);
          return out;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => front ? widget.onOpen(i) : _pick(i),
          child: Container(
            decoration: BoxDecoration(
              gradient: kBergenCardGradient,
              borderRadius: BorderRadius.circular(26 * s),
              border: Border.all(color: const Color(0xF2FFFFFF)),
              boxShadow: [
                const BoxShadow(
                  color: Color.fromRGBO(120, 80, 40, .16),
                  offset: Offset(0, 2),
                  blurRadius: 3,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: Color.fromRGBO(90, 60, 30, front ? .65 : .5),
                  offset: Offset(0, (front ? 30 : 16) * s),
                  blurRadius: onbBlur((front ? 44 : 26) * s),
                  spreadRadius: (front ? -20 : -18) * s,
                ),
              ],
            ),
            child: widget.builder(context, i, front),
          ),
        ),
      ),
    );
  }
}

// ── Store rail ──────────────────────────────────────────────────────────────

class BergenStoreRail extends StatelessWidget {
  const BergenStoreRail({
    super.key,
    required this.stores,
    required this.onOpen,
  });

  final List<BergenStoreCard> stores;
  final ValueChanged<BergenStoreCard> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    if (stores.isEmpty) {
      return SizedBox(
        height: 120 * s,
        child: Center(
          child: Text(
            BergenCopy.noStoresYet,
            style: bText(context, 12, color: const Color(0x99FFFFFF)),
          ),
        ),
      );
    }
    final list = stores.take(3).toList();
    return _Rail(
      height: 252,
      cardTop: 6,
      count: list.length,
      intervalMs: 5400,
      onOpen: (i) => onOpen(list[i]),
      builder: (context, i, front) => _StoreCardBody(store: list[i], seed: i),
    );
  }
}

class _StoreCardBody extends StatelessWidget {
  const _StoreCardBody({required this.store, required this.seed});
  final BergenStoreCard store;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(26 * s)),
              child: SizedBox(
                height: 124 * s,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: BergenColors.plate),
                    _KenBurns(
                      seconds: 9 + seed,
                      reverse: seed.isOdd,
                      child: _image(
                        store.bannerUrl,
                        store.bannerAsset,
                        BoxFit.cover,
                      ),
                    ),
                    if (store.video) ...[const _Grain(), const _Sweep()],
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(12, 28, 34, .24),
                            Color.fromRGBO(12, 28, 34, .04),
                            Color.fromRGBO(12, 28, 34, .18),
                          ],
                          stops: [0, .46, 1],
                        ),
                      ),
                    ),
                    if (store.video)
                      Positioned(
                        left: 9 * s,
                        bottom: 9 * s,
                        child: _videoTag(context),
                      ),
                    if (store.offer != null)
                      Positioned(
                        right: 8 * s,
                        bottom: 8 * s,
                        child: Transform.rotate(
                          angle: -6 * math.pi / 180,
                          child: _offerTag(context, store.offer!),
                        ),
                      ),
                    Positioned(
                      left: 9 * s,
                      top: 9 * s,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9 * s,
                          vertical: 4 * s,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .78),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Pulse(
                              child: Container(
                                width: 6 * s,
                                height: 6 * s,
                                decoration: BoxDecoration(
                                  color: store.open
                                      ? BergenColors.gold
                                      : const Color(0xFFB9AF9C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 5 * s),
                            Text(
                              store.open ? BergenCopy.open : BergenCopy.closed,
                              style: bText(
                                context,
                                10.5,
                                weight: FontWeight.w800,
                                color: store.open
                                    ? BergenColors.green
                                    : BergenColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8 * s,
                      top: 8 * s,
                      child: BergenFavHeart(
                        storeId: store.id,
                        size: 30 * s,
                        iconSize: 15 * s,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 11 * s,
              top: 62 * s,
              child: Transform.rotate(
                angle: -5 * math.pi / 180,
                child: Container(
                  width: 40 * s,
                  height: 40 * s,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5 * s),
                    boxShadow: [
                      const BoxShadow(
                        color: Color.fromRGBO(35, 32, 29, .22),
                        offset: Offset(0, 2),
                        blurRadius: 3,
                        spreadRadius: -1,
                      ),
                      BoxShadow(
                        color: const Color.fromRGBO(35, 32, 29, .45),
                        offset: Offset(0, 8 * s),
                        blurRadius: onbBlur(14 * s),
                        spreadRadius: -7 * s,
                      ),
                    ],
                  ),
                  child: store.logoUrl != null || store.logoAsset != null
                      ? _image(store.logoUrl, store.logoAsset, BoxFit.cover)
                      : Center(
                          child: Text(
                            store.name.isEmpty ? '' : store.name[0],
                            style: bDisplay(
                              context,
                              15,
                              color: BergenColors.ink,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(13 * s, 11 * s, 13 * s, 12 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bDisplay(
                  context,
                  15,
                  letterSpacingEm: -.015,
                  color: BergenColors.ink,
                ),
              ),
              SizedBox(height: 1 * s),
              Text(
                store.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w600,
                  color: BergenColors.inkFaint,
                ),
              ),
              SizedBox(height: 10 * s),
              Row(
                children: [
                  if (store.eta != null)
                    _chip(
                      context,
                      Icon(
                        Icons.schedule_rounded,
                        size: 11 * s,
                        color: BergenColors.inkSoft,
                      ),
                      store.eta!,
                      BergenColors.ink,
                    ),
                  if (store.eta != null &&
                      (store.fee != null || store.rating != null))
                    SizedBox(width: 7 * s),
                  if (store.fee != null)
                    Expanded(
                      child: _chip(
                        context,
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 12 * s,
                          color: store.feeIsFree
                              ? BergenColors.greenDeep
                              : BergenColors.inkSoft,
                        ),
                        store.feeIsFree ? BergenCopy.free : store.fee!,
                        store.feeIsFree
                            ? BergenColors.greenDeep
                            : BergenColors.inkSoft,
                      ),
                    )
                  else if (store.rating != null)
                    Expanded(
                      child: _chip(
                        context,
                        Icon(
                          Icons.star_rounded,
                          size: 12 * s,
                          color: BergenColors.gold,
                        ),
                        store.rating!,
                        BergenColors.inkSoft,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, Widget icon, String text, Color color) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.fromLTRB(4 * s, 4 * s, 10 * s, 4 * s),
      decoration: BoxDecoration(
        color: const Color(0x0E23201D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20 * s,
            height: 20 * s,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF1ECE1)],
              ),
              boxShadow: [
                BoxShadow(color: Color(0xE6D2C8B6), offset: Offset(0, 1)),
                BoxShadow(
                  color: Color.fromRGBO(35, 32, 29, .25),
                  offset: Offset(0, 2),
                  blurRadius: 3,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: icon,
          ),
          SizedBox(width: 6 * s),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bText(context, 12, weight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product rail ────────────────────────────────────────────────────────────

class BergenProductRail extends StatelessWidget {
  const BergenProductRail({
    super.key,
    required this.products,
    required this.onOpen,
    required this.onAdd,
  });

  final List<BergenProductCard> products;
  final ValueChanged<BergenProductCard> onOpen;
  final ValueChanged<BergenProductCard> onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    if (products.isEmpty) {
      return SizedBox(
        height: 100 * s,
        child: Center(
          child: Text(
            BergenCopy.noProductsYet,
            style: bText(context, 12, color: const Color(0x99FFFFFF)),
          ),
        ),
      );
    }
    final list = products.take(3).toList();
    return _Rail(
      height: 214,
      cardTop: 4,
      count: list.length,
      intervalMs: 6200,
      onOpen: (i) => onOpen(list[i]),
      builder: (context, i, front) => _ProductCardBody(
        product: list[i],
        seed: i,
        onAdd: () => onAdd(list[i]),
      ),
    );
  }
}

class _ProductCardBody extends StatelessWidget {
  const _ProductCardBody({
    required this.product,
    required this.seed,
    required this.onAdd,
  });
  final BergenProductCard product;
  final int seed;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26 * s)),
          child: SizedBox(
            height: 126 * s,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient:
                        product.hero ?? BergenCategoryLook.restaurant.hero,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-.4, -.8),
                      radius: 1.1,
                      colors: [Color(0x6BFFFFFF), Color(0x00FFFFFF)],
                      stops: [0, .6],
                    ),
                  ),
                ),
                if (product.imageUrl != null || product.imageAsset != null)
                  _KenBurns(
                    seconds: 8 + seed,
                    reverse: seed.isOdd,
                    product: true,
                    child: ColoredBox(
                      color: const Color(0xFFFBF7EE),
                      child: _image(
                        product.imageUrl,
                        product.imageAsset,
                        BoxFit.contain,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 126 * s * .44,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(60, 35, 10, 0),
                          Color.fromRGBO(60, 35, 10, .22),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10 * s,
                  bottom: 10 * s,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * s,
                      vertical: 4 * s,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .82),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xF2FFFFFF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(35, 32, 29, .35),
                          offset: Offset(0, 4 * s),
                          blurRadius: onbBlur(10 * s),
                          spreadRadius: -6 * s,
                        ),
                      ],
                    ),
                    child: Text(
                      product.priceText,
                      style: bText(
                        context,
                        12,
                        weight: FontWeight.w800,
                        color: BergenColors.ink,
                      ),
                    ),
                  ),
                ),
                if (product.wasPrice != null)
                  Positioned(
                    left: 10 * s,
                    bottom: 34 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7 * s,
                        vertical: 3 * s,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(8 * s),
                      ),
                      child: Text(
                        product.wasPrice!,
                        style: bText(
                          context,
                          9.5,
                          color: BergenColors.inkMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                if (product.offer != null)
                  Positioned(
                    right: 8 * s,
                    top: 8 * s,
                    child: Transform.rotate(
                      angle: 6 * math.pi / 180,
                      child: _offerTag(context, product.offer!, small: true),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 10 * s, 9 * s),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bDisplay(
                        context,
                        13.5,
                        letterSpacingEm: -.01,
                        color: BergenColors.ink,
                      ),
                    ),
                    Text(
                      product.store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bText(
                        context,
                        11,
                        weight: FontWeight.w600,
                        color: BergenColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * s),
              OnbPressable(
                onTap: onAdd,
                pressScale: .84,
                child: Container(
                  width: 32 * s,
                  height: 32 * s,
                  decoration: BoxDecoration(
                    color: BergenColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BergenColors.orange.withValues(alpha: .75),
                        offset: Offset(0, 6 * s),
                        blurRadius: onbBlur(12 * s),
                        spreadRadius: -5 * s,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18 * s,
                    color: BergenColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared pieces ───────────────────────────────────────────────────────────

Widget _image(String? url, String? asset, BoxFit fit) {
  if (asset != null) return Image.asset(asset, fit: fit);
  if (url == null || url.isEmpty) return const SizedBox.shrink();
  return CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    fadeInDuration: const Duration(milliseconds: 250),
    errorWidget: (_, __, ___) => const SizedBox.shrink(),
  );
}

Widget _videoTag(BuildContext context) {
  final s = context.bs;
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 3 * s),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(12, 28, 34, .58),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pulse(
          fast: true,
          child: Container(
            width: 5 * s,
            height: 5 * s,
            decoration: const BoxDecoration(
              color: BergenColors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 4 * s),
        Text(
          BergenCopy.video,
          style: bText(
            context,
            8,
            weight: FontWeight.w800,
            letterSpacingEm: .09,
          ),
        ),
      ],
    ),
  );
}

Widget _offerTag(BuildContext context, String text, {bool small = false}) {
  final s = context.bs;
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: (small ? 8 : 9) * s,
      vertical: 4 * s,
    ),
    decoration: BoxDecoration(
      gradient: kBergenOrangeGradient,
      borderRadius: BorderRadius.circular(10 * s),
      border: Border.all(color: Colors.white, width: 2 * s),
      boxShadow: [
        const BoxShadow(
          color: Color.fromRGBO(35, 32, 29, .25),
          offset: Offset(0, 2),
          blurRadius: 3,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: const Color.fromRGBO(120, 50, 20, .6),
          offset: Offset(0, 8 * s),
          blurRadius: onbBlur(14 * s),
          spreadRadius: -7 * s,
        ),
      ],
    ),
    child: Text(
      text,
      style: bText(
        context,
        small ? 10 : 10.5,
        weight: FontWeight.w800,
        color: BergenColors.ink,
      ),
    ),
  );
}

/// `kenBurns` — slow zoom and drift on a banner.
class _KenBurns extends StatelessWidget {
  const _KenBurns({
    required this.child,
    required this.seconds,
    required this.reverse,
    this.product = false,
  });
  final Widget child;
  final int seconds;
  final bool reverse;
  final bool product;

  @override
  Widget build(BuildContext context) => OnbLoopClock(
    child: child,
    builder: (context, t, child) {
      var p = (onbLoop(t, 0, seconds * 1000.0) ?? 0);
      p = p < .5 ? p * 2 : 2 - p * 2; // alternate
      if (reverse) p = 1 - p;
      final e = Curves.easeInOut.transform(p);
      final sc = product ? 1.1 + .12 * e : 1 + .14 * e;
      final tx = product ? 0.0 : -2.5 * e;
      final ty = product ? 0.0 : 1.5 * e;
      final rot = product ? -2 * e : 0.0;
      return ClipRect(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(tx, ty, 0, 1)
            ..rotateZ(rot * math.pi / 180)
            ..scaleByDouble(sc, sc, 1, 1),
          child: child,
        ),
      );
    },
  );
}

/// `vidGrain` — a faint scanline shimmer over "video" banners.
class _Grain extends StatelessWidget {
  const _Grain();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: OnbLoopClock(
      builder: (context, t, _) {
        final step = ((t / 200).floor() % 4);
        const shifts = [
          Offset(0, 0),
          Offset(-1, 1),
          Offset(1, -1),
          Offset(-1, -1),
        ];
        return Opacity(
          opacity: .35,
          child: Transform.translate(
            offset: shifts[step],
            child: CustomPaint(painter: _ScanlinePainter()),
          ),
        );
      },
    ),
  );
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final light = Paint()..color = Colors.white.withValues(alpha: .07);
    final dark = Paint()..color = Colors.black.withValues(alpha: .07);
    for (var y = -2.0; y < size.height + 2; y += 2) {
      c.drawRect(Rect.fromLTWH(-2, y, size.width + 4, 1), light);
      c.drawRect(Rect.fromLTWH(-2, y + 1, size.width + 4, 1), dark);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

/// `vidSveip` — a light sweep across the banner every 6.5s.
class _Sweep extends StatelessWidget {
  const _Sweep();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ClipRect(
      child: OnbLoopClock(
        builder: (context, t, _) {
          final p = (onbLoop(t, 0, 6500) ?? 0);
          final x = p < .55 ? -1.2 + 2.4 * (p / .55) : 1.2;
          return LayoutBuilder(
            builder: (context, box) => Transform.translate(
              offset: Offset(x * box.maxWidth, 0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1, -.3),
                    end: Alignment(1, .3),
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x33FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [.38, .5, .62],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// `lyktPuls` / `vidPuls` — a dot glowing or blinking.
class _Pulse extends StatelessWidget {
  const _Pulse({required this.child, this.fast = false});
  final Widget child;
  final bool fast;
  @override
  Widget build(BuildContext context) => OnbLoopClock(
    child: child,
    builder: (context, t, child) {
      final p = (onbLoop(t, 0, fast ? 1400 : 3000) ?? 0);
      final o = fast
          ? onbKf(p, const [0, .5, 1], const [1, .35, 1], Curves.easeInOut)
          : 1.0;
      final sc = fast
          ? onbKf(p, const [0, .5, 1], const [1, .7, 1], Curves.easeInOut)
          : 1.0;
      return Opacity(
        opacity: o,
        child: Transform.scale(scale: sc, child: child),
      );
    },
  );
}
