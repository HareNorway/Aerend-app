import 'package:flutter/material.dart';

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
    return Container(
      key: const Key('lopet-laast-rad'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x29FFFFFF))),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFF7D57E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [LopetCopy.megRad(best, (s['place'] as num?)?.toInt(), '${s['losgrad'] ?? ''}'), if (weeks > 0) LopetCopy.uker(weeks)].join(' · '),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                if (maal != null)
                  Text(maal, style: const TextStyle(color: Color(0xFF7FF0CB), fontSize: 12, fontWeight: FontWeight.w700)),
                Text(LopetCopy.nesteSeilas, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
