import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../kit/bergen_kit.dart';
import 'a3_scaffold.dart';
import 'meg_copy_a4.dart';

/// The Poeng card (design `Poeng` ≈L5978): the medal, DITT NIVÅ, the distance
/// to the next tier, the four-rung ladder, POENG Å BRUKE with "Opptjent i alt",
/// the pending line, the goal bar, and Premiehylla / "Slik får du poeng".
class MegNivaaCard extends StatelessWidget {
  const MegNivaaCard({
    super.key,
    required this.balance,
    this.goal,
    this.onOpenPremiehylla,
    this.onOpenNivaa,
    this.onOpenSlik,
    this.onHentPremie,
  });

  final PointsBalance balance;
  final PointGoal? goal;
  final VoidCallback? onOpenPremiehylla;
  final VoidCallback? onOpenNivaa;
  final VoidCallback? onOpenSlik;
  final VoidCallback? onHentPremie;

  @override
  Widget build(BuildContext context) {
    final b = balance;
    final metal = medalFor(b.tierName);
    final g = goal;

    return BergenCard(
      key: const Key('meg-nivaa-card'),
      onDark: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            key: const Key('meg-nivaa-open'),
            behavior: HitTestBehavior.opaque,
            onTap: onOpenNivaa,
            child: Row(
              children: [
                MegMedal(name: b.tierName, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(A4MegCopy.a4_meg_ditt_nivaa, style: _kicker),
                      Text(
                        b.tierName.toUpperCase(),
                        key: const Key('meg-tier-name'),
                        style: BergenTokens.display(30, weight: FontWeight.w800, color: metal.accent, letterSpacingEm: -0.02),
                      ),
                      Text(
                        b.nextTierName == null || b.pointsToNextTier == null
                            ? A4MegCopy.a4_meg_hoyeste
                            : A4MegCopy.a4_meg_til_neste(b.pointsToNextTier!, b.nextTierName!),
                        key: const Key('meg-tier-progress-line'),
                        style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w700, color: BergenTokens.mint),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: A3Ink.muted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MegLadder(balance: b),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: BergenTokens.lantern),
                child: const Icon(Icons.stars_rounded, size: 16, color: Color(0xFF5A4010)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(A4MegCopy.a4_meg_poeng_bruke, style: _kicker)),
              const SizedBox(width: 8),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: BergenChip(label: A4MegCopy.a4_meg_opptjent(b.lifetime > 0 ? b.lifetime : b.earned12m), onDark: true, selected: true))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(A4MegCopy.nf(b.available), key: const Key('meg-available-points'), style: BergenTokens.display(44, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.03)))),
              const SizedBox(width: 8),
              Text(A4MegCopy.a4_meg_poeng, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: A3Ink.sub)),
            ],
          ),
          if (b.pending > 0)
            Text(A4MegCopy.a4_meg_kommer(b.pending), key: const Key('meg-pending-line'), style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: A3Ink.muted)),
          if (g != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('meg-goal'),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: BergenTokens.tealNight.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BergenTokens.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.reached ? A4MegCopy.a4_meg_maal_klar(g.label) : A4MegCopy.a4_meg_maal(g.label, g.remaining),
                          key: const Key('meg-goal-label'),
                          style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${g.percent} %', style: BergenTokens.display(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.mint)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (g.percent / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: BergenTokens.glassBorder,
                      color: g.reached ? BergenTokens.mint : BergenTokens.orange,
                    ),
                  ),
                  if (g.reached) ...[
                    const SizedBox(height: 10),
                    BergenCta3d(key: const Key('meg-hent-premien'), label: A4MegCopy.a4_meg_hent_premien, icon: Icons.redeem_rounded, onPressed: onHentPremie ?? onOpenPremiehylla),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: BergenCta3d(key: const Key('meg-open-premiehylla'), label: A4MegCopy.a4_meg_premiehylla, icon: Icons.chevron_right_rounded, onPressed: onOpenPremiehylla)),
              const SizedBox(width: 12),
              TextButton(
                key: const Key('meg-open-slik'),
                onPressed: onOpenSlik,
                child: Text(A4MegCopy.a4_meg_slik, textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.mint)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get _kicker => BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: A3Ink.muted).copyWith(letterSpacing: 1.4);
}

/// The four medals with the current one raised (design `nivMedaljer`).
class MegLadder extends StatelessWidget {
  const MegLadder({super.key, required this.balance});

  final PointsBalance balance;

  @override
  Widget build(BuildContext context) {
    final steps = balance.tiers.isNotEmpty
        ? balance.tiers
        : [TierStep(index: balance.tier, name: balance.tierName, threshold: 0), if (balance.nextTierName != null) TierStep(index: balance.tier + 1, name: balance.nextTierName!, threshold: 0)];
    final current = balance.tier;
    final total = steps.length;
    final fill = total <= 1 ? 1.0 : ((current + (1 - balance.progressToNextTier() == 0 ? 1 : balance.progressToNextTier())) / (total - 1)).clamp(0.0, 1.0);

    return Column(
      key: const Key('meg-ladder'),
      children: [
        LayoutBuilder(
          builder: (context, c) => Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 6, decoration: BoxDecoration(color: BergenTokens.glassBorder, borderRadius: BorderRadius.circular(999))),
              Container(
                height: 6,
                width: c.maxWidth * fill,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFC98A62), Color(0xFFF2D591), BergenTokens.lantern]),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final s in steps)
                    _Rung(name: s.name, reached: s.index <= current, current: s.index == current, locked: s.index > current),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final s in steps)
              Text(
                s.name,
                style: BergenTokens.text(BergenTokens.textMicro, weight: s.index == current ? FontWeight.w800 : FontWeight.w600, color: s.index == current ? Colors.white : A3Ink.muted),
              ),
          ],
        ),
      ],
    );
  }
}

class _Rung extends StatelessWidget {
  const _Rung({required this.name, required this.reached, required this.current, required this.locked});

  final String name;
  final bool reached;
  final bool current;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (current) return MegMedal(name: name, size: 30, glow: true);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? medalFor(name).accent : BergenTokens.tealNight,
        border: Border.all(color: reached ? Colors.white70 : BergenTokens.glassBorder, width: 1.5),
      ),
      child: Icon(reached ? Icons.check_rounded : Icons.lock_rounded, size: 12, color: reached ? const Color(0xFF3A2708) : A3Ink.muted),
    );
  }
}

/// The Æ medal in the tier's metal (design `nivMetall`).
class MegMedal extends StatelessWidget {
  const MegMedal({super.key, required this.name, this.size = 64, this.glow = false});

  final String name;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.35, -.5), colors: m.gradient),
        border: Border.all(color: m.ring, width: 2),
        boxShadow: [BoxShadow(color: glow ? m.accent.withValues(alpha: .6) : Colors.black26, blurRadius: glow ? 14 : 8, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Text('Æ', style: BergenTokens.display(size * .42, weight: FontWeight.w800, color: m.ink)),
      ),
    );
  }
}

class MedalStyle {
  const MedalStyle({required this.gradient, required this.ink, required this.ring, required this.accent});

  final List<Color> gradient;
  final Color ink;
  final Color ring;
  final Color accent;
}

MedalStyle medalFor(String name) {
  switch (name.toLowerCase()) {
    case 'platina':
    case 'ulriken':
      return const MedalStyle(gradient: [Color(0xFFFFFFFF), Color(0xFFE8EDF0), Color(0xFFAEB9C2), Color(0xFF8C98A3)], ink: Color(0xFF263038), ring: Color(0x998C98A3), accent: Color(0xFFDCE3E6));
    case 'gull':
    case 'rundemanen':
      return const MedalStyle(gradient: [Color(0xFFFFFCF0), Color(0xFFF2D591), Color(0xFFC99B2A)], ink: Color(0xFF5A4010), ring: Color(0x99C99B2A), accent: Color(0xFFF2C14E));
    case 'sølv':
    case 'solv':
    case 'løvstakken':
      return const MedalStyle(gradient: [Color(0xFFFFFFFF), Color(0xFFDCE3E6), Color(0xFF9AA8AE)], ink: Color(0xFF2A3538), ring: Color(0x999AA8AE), accent: Color(0xFFCBD6DA));
    default:
      return const MedalStyle(gradient: [Color(0xFFF6DCC8), Color(0xFFC98A62), Color(0xFF8E5B38)], ink: Color(0xFF4A2A16), ring: Color(0x998E5B38), accent: Color(0xFFE0A47E));
  }
}
