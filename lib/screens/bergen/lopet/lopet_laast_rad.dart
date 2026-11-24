import 'package:flutter/material.dart';

import '../../../game/fjordlopet/haptics/game_haptics.dart';
import '../../../game/fjordlopet/haptics/haptikk_moenster.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';
import 'lopet_copy.dart';
import 'lopet_liste.dart';

/// Fjordløpet v1.3 plan Step 7 (spec §8 «Meg · Poeng, and Premiehylla»): the locked Fjordløpet row — best distance
/// this week, place on the ladder, losgrad and weeks sailed, the nearest goal and «Neste seilas ved neste
/// bestilling». It shows results only and never opens the game (no run starts outside the window). Hidden when the
/// game is not for this customer (the summary does not answer).
class LopetLaastRad extends StatefulWidget {
  const LopetLaastRad({super.key, this.api, this.summary});

  final LopetListeApi? api;

  /// A summary already fetched (tests, or a screen that has it).
  final Map<String, dynamic>? summary;

  @override
  State<LopetLaastRad> createState() => _LopetLaastRadState();
}

class _LopetLaastRadState extends State<LopetLaastRad> {
  Map<String, dynamic>? _s;

  @override
  void initState() {
    super.initState();
    _s = widget.summary;
    if (_s == null) {
      (widget.api ?? LopetListeApi()).summary().then((v) {
        if (mounted && v != null) setState(() => _s = v);
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) return const SizedBox.shrink();
    final best = (s['best_m'] as num?)?.toInt();
    final weeks = (s['weeks_sailed'] as num?)?.toInt() ?? 0;
    final maal = LopetCopy.maalFra(s['nearest_goal']);
    // Haptics plan Step 5: a tap on the locked row says «not now» (U09); it still opens nothing.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => GameHaptics.felles.play(HaptikkId.u09),
      child: Container(
      key: const Key('lopet-laast-rad'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      // Lys: Premiehylla is light, so the row needs dark text on a light card (T3: white on white).
      decoration: BoxDecoration(
          color: context.aeM(const Color(0x14FFFFFF), Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.aeM(const Color(0x29FFFFFF), LysPalett.kantFarge))),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: context.aeM(const Color(0xFFF7D57E), LysPalett.gullTekst), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [LopetCopy.megRad(best, (s['place'] as num?)?.toInt(), '${s['losgrad'] ?? ''}'), if (weeks > 0) LopetCopy.uker(weeks)].join(' · '),
                  style: TextStyle(color: context.aeM(Colors.white, LysPalett.tittel), fontSize: 13, fontWeight: FontWeight.w800),
                ),
                if (maal != null)
                  Text(maal, style: TextStyle(color: context.aeM(const Color(0xFF7FF0CB), LysPalett.mintTekst), fontSize: 12, fontWeight: FontWeight.w700)),
                Text(LopetCopy.nesteSeilas, style: TextStyle(color: context.aeM(const Color(0xB3FFFFFF), LysPalett.sekundar), fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
