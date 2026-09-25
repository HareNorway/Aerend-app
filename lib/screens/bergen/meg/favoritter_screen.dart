import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../utils/shared_pref_utill.dart';
import '../../deliveryService/favouriteStore/favourite_store_screen.dart';
import 'a3_scaffold.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';

/// Favoritter (design `favoritter` ≈L5960): the intro, the empty state with
/// "Kast ut" (→ Fjordfiske), the list through the existing
/// [FavouriteStoreScreen] (favourite-store-lists), and the footer line about
/// "Bestill igjen".
class FavoritterScreen extends StatelessWidget {
  const FavoritterScreen({super.key});

  LatLng _here() {
    double read(String key) {
      try {
        return double.tryParse(prefGetString(key)) ?? 0;
      } catch (_) {
        return 0;
      }
    }

    final lat = read('latitude');
    final lng = read('longitude');
    return (lat == 0 && lng == 0) ? const LatLng(60.3913, 5.3221) : LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return A3Scaffold(
      title: A3MegCopy.a3_meg_fav_title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 12),
          A3Row(
            key: const Key('fav-liste'),
            title: A3MegCopy.a3_meg_fav_title,
            subtitle: 'Butikkene du har merket med hjerte',
            icon: Icons.favorite_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FavouriteStoreScreen(selectedLatLng: _here()))),
          ),
          const SizedBox(height: 8),
          Text(A3MegCopy.a3_meg_fav_fot, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: A3Ink.muted)),
        ],
      ),
    );
  }
}
