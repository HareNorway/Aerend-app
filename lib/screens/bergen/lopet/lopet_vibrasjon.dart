import 'package:flutter/material.dart';

import '../../../game/fjordlopet/haptics/game_haptics.dart';
import '../../../game/fjordlopet/haptics/haptikk_moenster.dart';
import '../kit/bergen_kit.dart';
import 'lopet_copy.dart';

/// Fjordløpet haptics plan Step 6 (haptics spec §8, DH2, DH4): «Vibrasjon» Full · Dempet · Av, on the pause card
/// under «Lyd» and in the quay's «Lyd · Vibrasjon» row.
///
/// Stored on the device. Choosing Full or Dempet plays H03 at that level, so the player feels the choice. With the
/// phone's vibration off (tier Off) it shows Av with «Telefonen din har slått av vibrasjon»; with the app-wide
/// «Vibrasjon» under Konto off it shows Av, disabled, with «Vibrasjon er slått av under Konto» — the game's setting
/// never changes the app-wide one. Haptics do not follow reduce motion.
class LopetVibrasjon extends StatefulWidget {
  const LopetVibrasjon({super.key, required this.haptics, this.kompakt = false});

  final GameHaptics haptics;

  /// The quay's row: the three choices without the title line.
  final bool kompakt;

  @override
  State<LopetVibrasjon> createState() => _LopetVibrasjonState();
}

class _LopetVibrasjonState extends State<LopetVibrasjon> {
  GameHaptics get _h => widget.haptics;

  void _velg(HaptikkNivaaValg v) {
    setState(() => _h.setLevel(v));
    GameHaptics.lagreNivaa(v);
    if (v != HaptikkNivaaValg.off) _h.preview(HaptikkId.h03);
  }

  @override
  Widget build(BuildContext context) {
    final konto = !_h.appPaa;
    final telefon = !konto && _h.tier == HaptikkTier.off && _h.tierWhy == 'system_off';
    final laast = konto || telefon;
    final valgt = laast ? HaptikkNivaaValg.off : _h.nivaa;
    final linje = konto ? LopetCopy.vibKontoAv : (telefon ? LopetCopy.vibTelefonAv : null);
    final valg = Row(
      children: [
        for (final (v, tekst) in [
          (HaptikkNivaaValg.full, LopetCopy.vibFull),
          (HaptikkNivaaValg.soft, LopetCopy.vibDempet),
          (HaptikkNivaaValg.off, LopetCopy.vibAv),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                button: true,
                selected: v == valgt,
                enabled: !laast,
                child: GestureDetector(
                  key: Key('lopet-vib-${v.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: laast ? null : () => _velg(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: v == valgt ? const Color(0xFF5CE0B8).withValues(alpha: laast ? .25 : .9) : Colors.white.withValues(alpha: .06),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tekst,
                        style: BergenTokens.text(13, weight: FontWeight.w800, color: v == valgt && !laast ? const Color(0xFF0C2A38) : Colors.white.withValues(alpha: laast ? .5 : .85)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return Column(
      key: const Key('lopet-vibrasjon'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.kompakt)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Row(children: [
              Icon(Icons.vibration_rounded, color: Colors.white.withValues(alpha: .85), size: 20),
              const SizedBox(width: 10),
              Text(LopetCopy.vibrasjon, style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        valg,
        if (linje != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(linje, key: const Key('lopet-vib-linje'), style: BergenTokens.text(12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: .7))),
          ),
      ],
    );
  }
}
