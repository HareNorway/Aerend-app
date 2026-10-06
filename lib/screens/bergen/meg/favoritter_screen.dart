import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/ops/favourite_stores.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_fav_heart.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';
import 'meg_torg.dart';

/// Favoritter (`erFavoritter`, L8164–8210 in `Ærend Kunde Launch.dc.html`,
/// design px): the Torg header with «N steder», one glass card per hearted
/// store (its tinted tile, name, address, time and open state, and the heart
/// to un-heart it), «Ingen favoritter ennå» with «Kast ut» (→ Fjordfiske)
/// while there are none, and the varde card about «Bestill igjen».
///
/// Reads `ops.customer.favourites` through [FavouriteStores], the same list
/// every Bergen heart writes.
class FavoritterScreen extends StatefulWidget {
  const FavoritterScreen({super.key});

  @override
  State<FavoritterScreen> createState() => _FavoritterScreenState();
}

class _FavoritterScreenState extends State<FavoritterScreen> {
  final FavouriteStores _favs = FavouriteStores.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _favs.refresh().whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _open(FavouriteStore s) => BergenRoutes.pushOr(
    context,
    '/bergen/butikk/${s.storeId}',
    arguments: {'name': s.name},
    orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
  );

  Future<void> _fjern(FavouriteStore s) async {
    if (OpsCustomerApi.authParams() == null) {
      showBergenToast(context, FavCopy.loggInn);
      return;
    }
    final ok = await _favs.set(s.storeId, false);
    if (!mounted) return;
    showBergenToast(context, ok ? FavCopy.fjernet : FavCopy.feil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: LfFrame(
        child: ValueListenableBuilder<Set<int>>(
          valueListenable: _favs.ids,
          builder: (context, ids, _) {
            // A card un-hearted here leaves at once; the server list follows.
            final stores = _favs.stores.where((s) => ids.contains(s.storeId)).toList();
            return MegTorgSkjerm(
              tittel: A3MegCopy.a3_meg_fav_title,
              pille: FavTekst.steder(stores.length),
              pilleKey: const Key('fav-antall'),
              listKey: const Key('fav-liste'),
              glod: const [
                MegGlod(top: 60, right: -70, size: 250, color: Color.fromRGBO(242, 128, 63, .26)),
                MegGlod(top: 340, left: -80, size: 260, color: Color.fromRGBO(58, 125, 140, .26)),
              ],
              children: [
                if (stores.isEmpty && _loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  ),
                if (stores.isEmpty && !_loading) _Tom(onKast: () => Navigator.of(context).pushNamed('/bergen/fjordfiske')),
                for (final s in stores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FavKort(key: Key('fav-store-${s.storeId}'), s: s, onOpen: () => _open(s), onFjern: () => _fjern(s)),
                  ),
                const Padding(padding: EdgeInsets.only(top: 6), child: _Info()),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The tile's art: the store's kind read from its name (the favourites list
/// carries no category), with the prototype's tint for it.
enum _Slag { mat, fisk, burger }

_Slag _slag(String navn) {
  final n = navn.toLowerCase();
  if (RegExp(r'fisk|sjømat|reke|laks|sushi|fish').hasMatch(n)) return _Slag.fisk;
  if (RegExp(r'burger').hasMatch(n)) return _Slag.burger;
  return _Slag.mat;
}

class _FavKort extends StatelessWidget {
  const _FavKort({super.key, required this.s, required this.onOpen, required this.onFjern});

  final FavouriteStore s;
  final VoidCallback onOpen;
  final VoidCallback onFjern;

  static const _tint = {
    _Slag.mat: [Color(0xFFF6D9B4), Color(0xFFD2854A)],
    _Slag.fisk: [Color(0xFFCFE3E8), Color(0xFF6FA3B2)],
    _Slag.burger: [Color(0xFFFBEBD6), Color(0xFFF0B27A)],
  };

  Widget _art(_Slag k) => switch (k) {
    _Slag.mat => const Positioned(left: 13, top: 15, child: _Skygge(child: AeIco('ico_mat', w: 38, h: 34, viewBox: '13 5 34 32'))),
    _Slag.fisk => const Positioned(left: 10, top: 17, child: _Skygge(child: AeIco('ico_fisk', w: 44, h: 30, viewBox: '6 6 60 38'))),
    _Slag.burger => const Positioned(left: 8, top: 10, child: _Skygge(child: AeIco('ico_burger', w: 48, h: 46, viewBox: '0 0 64 60'))),
  };

  @override
  Widget build(BuildContext context) {
    final k = _slag(s.name);
    final meta = [
      if (s.etaMinutes != null) '${s.etaMinutes} min',
      s.open ? FavTekst.aapen : FavTekst.stengt,
      if (s.rating != null && s.rating! > 0) '★ ${s.rating!.toStringAsFixed(1)}',
    ].join(' · ');
    return MegLysKort(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpen,
            child: CssBox(
              width: 64,
              height: 64,
              radius: const BorderRadius.all(Radius.circular(18)),
              clip: true,
              bg: [CssLinear(165, _tint[k]!)],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
                CssShadow.inset(0, -10, 18, 0, Color.fromRGBO(60, 35, 10, .18)),
                CssShadow(0, 8, 14, -8, Color.fromRGBO(60, 35, 10, .45)),
              ],
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CssBox(bg: [CssRadial([Color.fromRGBO(255, 255, 255, .5), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .62], rx: 1.2, ry: .9, cx: .3, cy: .1)]),
                  ),
                  _art(k),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(13.5, weight: FontWeight.w800, color: MegTorgSkjerm.blekk)),
                  if ((s.address ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(s.address!.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, weight: FontWeight.w500, color: const Color(0xFF6E6862))),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: s.open ? const Color(0xFF3F8F5F) : const Color(0xFFB4ADA5))),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: aeTab(inter(11, weight: FontWeight.w700, color: const Color(0xFF57534B)))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          AePress(
            key: Key('fav-heart-${s.storeId}'),
            onTap: onFjern,
            dy: 0,
            scale: .88,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(242, 109, 61, .1)),
              alignment: Alignment.center,
              child: const AeIkon(
                'M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z',
                size: 17,
                stroke: 1.6,
                color: Color(0xFFB9441A),
                fill: Color(0xFFF26D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `filter:drop-shadow(0 3px 4px rgba(20,25,30,.45))` on the tile art.
class _Skygge extends StatelessWidget {
  const _Skygge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Transform.translate(
        offset: const Offset(0, 3),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.compose(
            outer: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            inner: const ColorFilter.mode(Color.fromRGBO(20, 25, 30, .45), BlendMode.srcIn),
          ),
          child: child,
        ),
      ),
      child,
    ],
  );
}

class _Tom extends StatelessWidget {
  const _Tom({required this.onKast});
  final VoidCallback onKast;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: const BorderRadius.all(Radius.circular(24)),
    bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .6))],
    border: const Border.fromBorderSide(BorderSide(color: Color.fromRGBO(255, 255, 255, .9))),
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
      CssShadow(0, 18, 30, -18, Color.fromRGBO(90, 60, 30, .5)),
    ],
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 84,
            height: 84,
            color: const Color(0xFFEFEAF8),
            child: Image.asset('assets/images/dashboard/find.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 10),
        Text(A3MegCopy.a3_meg_fav_tom, key: const Key('fav-intro'), textAlign: TextAlign.center, style: jakarta(16, color: MegTorgSkjerm.blekk)),
        const SizedBox(height: 4),
        Text(A3MegCopy.a3_meg_fav_tom_sub, textAlign: TextAlign.center, style: inter(12, color: const Color(0xFF57534B), height: 1.45)),
        const SizedBox(height: 12),
        AePress(
          key: const Key('fav-kast'),
          onTap: onKast,
          child: Container(
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFF1E4F5C), borderRadius: BorderRadius.circular(999)),
            alignment: Alignment.center,
            child: Text(A3MegCopy.a3_meg_fav_kast, style: inter(12.5, weight: FontWeight.w800)),
          ),
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) => CssBox(
    radius: const BorderRadius.all(Radius.circular(22)),
    bg: const [CssSolid(Color.fromRGBO(220, 233, 236, .5))],
    border: const Border.fromBorderSide(BorderSide(color: Color.fromRGBO(255, 255, 255, .85))),
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .9)),
      CssShadow(0, 14, 26, -16, Color.fromRGBO(30, 79, 92, .4)),
    ],
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        SvgPicture.asset('assets/svgs/dashboard/varde3d.svg', width: 26, height: 32),
        const SizedBox(width: 12),
        Expanded(child: Text(A3MegCopy.a3_meg_fav_fot, style: inter(11.5, color: const Color(0xFF173E48), height: 1.45))),
      ],
    ),
  );
}

/// Copy for Favoritter.
abstract final class FavTekst {
  static String steder(int n) => '$n ${n == 1 ? 'sted' : 'steder'}';
  static const String aapen = 'Åpen nå';
  static const String stengt = 'Stengt nå';
}
