import 'package:flutter/material.dart';

import '../../../services/customer/client_flags.dart';
import 'sporing_copy.dart';

/// Battery plan Step 7 (courier battery spec §4.3, §4.4): the courier's app
/// sends positions in batches and less often when still, so the server never
/// promises a cadence — instead of a frozen dot the tracking card says «Sist
/// oppdatert for 40 s siden» (minutes from 60 s: «for 2 min siden») once
/// `live_position.recorded_at` is older than [staleAfter]. Nothing while it is
/// fresh, without a position, or with `cus.tracking.last_updated` off.
///
/// No timer of its own: it reads the clock when its parent rebuilds (the map
/// card's one-second countdown tick).
class SpSistOppdatert extends StatelessWidget {
  const SpSistOppdatert({super.key, required this.at, required this.style, this.now});

  /// When the position was recorded.
  final DateTime? at;
  final TextStyle style;

  /// Tests: the clock (defaults to now).
  final DateTime? now;

  static const Duration staleAfter = Duration(seconds: 30);

  /// The line for a position recorded [at], read at [now]; null while fresh.
  static String? tekst(DateTime? at, DateTime now) {
    if (at == null) return null;
    final alder = now.difference(at);
    if (alder <= staleAfter) return null;
    return SporingCopy.a1_sporing_sist_oppdatert(alder.inSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final linje = ClientFlags.on(ClientFlags.trackingLastUpdated) ? tekst(at, now ?? DateTime.now()) : null;
    if (linje == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(linje, key: const Key('a1_sporing_sist_oppdatert'), maxLines: 2, style: style),
    );
  }
}
