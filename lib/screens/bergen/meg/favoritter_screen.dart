import 'package:flutter/material.dart';

import '../../../data/ops/favourite_stores.dart';
import '../kit/bergen_fav_heart.dart';
import 'a3_scaffold.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';

/// Favoritter (design `favoritter` ≈L5960): the intro and "Kast ut"
/// (→ Fjordfiske) while there are none, otherwise one row per hearted store
/// (`favListe`: name, meta, its heart to un-heart, tap to open the store),
/// then the footer line about "Bestill igjen".
///
/// Reads `ops.customer.favourites` through [FavouriteStores], the same list
/// every Bergen heart writes, so a store hearted on Hjem, on its page or in
/// Fjordfiske is here whatever its service category.
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

  String _meta(FavouriteStore s) => [
    if (s.etaMinutes != null) '${s.etaMinutes} min',
    s.open ? 'Åpen nå' : 'Stengt nå',
    if (s.rating != null && s.rating! > 0) '★ ${s.rating!.toStringAsFixed(1)}',
  ].join(' · ');

  void _open(FavouriteStore s) => BergenRoutes.pushOr(
    context,
    '/bergen/butikk/${s.storeId}',
    arguments: {'name': s.name},
    orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
  );

  @override
  Widget build(BuildContext context) {
    return A3Scaffold(
      title: A3MegCopy.a3_meg_fav_title,
      child: ValueListenableBuilder<Set<int>>(
        valueListenable: _favs.ids,
        builder: (context, ids, _) {
          // A row un-hearted here leaves at once; the server list follows.
          final stores = _favs.stores.where((s) => ids.contains(s.storeId)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stores.isEmpty && !_loading)
                BergenCard(
                  onDark: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(A3MegCopy.a3_meg_fav_tom, key: const Key('fav-intro'), style: BergenTokens.display(BergenTokens.textSection, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(A3MegCopy.a3_meg_fav_tom_sub, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
                      const SizedBox(height: 10),
                      BergenCta3d(key: const Key('fav-kast'), label: A3MegCopy.a3_meg_fav_kast, icon: Icons.phishing_rounded, onPressed: () => Navigator.of(context).pushNamed('/bergen/fjordfiske')),
                    ],
                  ),
                ),
              if (stores.isEmpty && _loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                ),
              if (stores.isNotEmpty)
                Column(
                  key: const Key('fav-liste'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in stores)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BergenCard(
                          key: Key('fav-store-${s.storeId}'),
                          onDark: true,
                          onTap: () => _open(s),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.display(BergenTokens.textBody, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(_meta(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              BergenFavHeart(storeId: s.storeId, size: 36, iconSize: 18, onDark: true),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(A3MegCopy.a3_meg_fav_fot, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: A3Ink.muted)),
            ],
          );
        },
      ),
    );
  }
}
