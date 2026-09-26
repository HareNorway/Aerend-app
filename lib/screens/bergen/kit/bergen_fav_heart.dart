import 'package:flutter/material.dart';

import '../../../data/ops/favourite_stores.dart';
import '../../../networking/ops/ops_customer_api.dart';
import 'bergen_toast.dart';

/// Copy for the store hearts (design `toggleFavBK` / `si(...)`).
class FavCopy {
  static const String lagtTil = 'Lagt til i favoritter';
  static const String fjernet = 'Fjernet fra favoritter';
  static const String loggInn = 'Logg inn for å lagre favoritter';
  static const String feil = 'Fikk ikke lagret akkurat nå. Prøv igjen.';
  static const String leggTil = 'Legg til i favoritter';
  static const String fjern = 'Fjern fra favoritter';
}

/// A store heart that works wherever it sits: filled orange when the store is
/// a favourite, the design's `popp` on heart (.42s, scale 1 → 1.16 → .96 → 1,
/// cubic-bezier(.34,1.56,.64,1)), and the design's toast either way.
///
/// [onDark] is the store-page look (dark glass circle, like the back button);
/// otherwise it is Hjem's white card chip.
class BergenFavHeart extends StatefulWidget {
  const BergenFavHeart({
    super.key,
    required this.storeId,
    this.size = 30,
    this.iconSize = 15,
    this.onDark = false,
  });

  final int storeId;
  final double size;
  final double iconSize;
  final bool onDark;

  @override
  State<BergenFavHeart> createState() => _BergenFavHeartState();
}

class _BergenFavHeartState extends State<BergenFavHeart>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFF26D3D);
  static const _ink = Color(0xFF23201D);

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  // CSS applies animation-timing-function to each keyframe step, so the
  // curve goes on every segment and the controller runs linearly. (On the
  // whole sequence the overshoot would push t past 1.0, which TweenSequence
  // asserts against.)
  static const _popp = Cubic(.34, 1.56, .64, 1);
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16).chain(CurveTween(curve: _popp)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.16, end: .96).chain(CurveTween(curve: _popp)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: .96, end: 1.0).chain(CurveTween(curve: _popp)), weight: 30),
  ]).animate(_pop);

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    FavouriteStores.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy || widget.storeId <= 0) return;
    if (OpsCustomerApi.authParams() == null) {
      showBergenToast(context, FavCopy.loggInn);
      return;
    }
    final favs = FavouriteStores.instance;
    final next = !favs.isFavourite(widget.storeId);
    if (next) _pop.forward(from: 0);
    _busy = true;
    final ok = await favs.set(widget.storeId, next);
    _busy = false;
    if (!mounted) return;
    showBergenToast(
      context,
      !ok ? FavCopy.feil : (next ? FavCopy.lagtTil : FavCopy.fjernet),
      icon: ok && next ? Icons.favorite_rounded : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: FavouriteStores.instance.ids,
      builder: (context, ids, _) {
        final on = ids.contains(widget.storeId);
        return Semantics(
          button: true,
          selected: on,
          label: on ? FavCopy.fjern : FavCopy.leggTil,
          child: GestureDetector(
            key: Key('fav-heart-${widget.storeId}'),
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.onDark
                    ? const Color(0x59000000)
                    : Colors.white.withValues(alpha: .72),
                border: widget.onDark
                    ? Border.all(color: const Color(0x40FFFFFF))
                    : null,
              ),
              child: ScaleTransition(
                scale: _scale,
                child: Icon(
                  on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: widget.iconSize,
                  color: on
                      ? _orange
                      : (widget.onDark ? Colors.white : _ink),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
