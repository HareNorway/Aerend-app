import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import 'min_bio.dart';
import 'min_bio_bits.dart';

/// The chips under the score (`bioKortChips`): allergies, avoids, diets,
/// likes and dislikes, the first five and «+N».
List<({String tx, BioStil stil, String ik})> bioKortChips(BioEff E) => [
      for (final k in E.all.keys.where((k) => E.all[k] == BioAll.allergi)) (tx: 'Ingen ${k.toLowerCase()}', stil: BioStil.ora, ik: BioIk.varsel),
      for (final k in E.all.keys.where((k) => E.all[k] == BioAll.unnga)) (tx: 'Unngår ${k.toLowerCase()}', stil: BioStil.gul, ik: BioIk.varsel),
      for (final k in E.kost.where((k) => k != 'Spiser alt')) (tx: k, stil: BioStil.mint, ik: BioIk.blad),
      for (final k in E.liker) (tx: k, stil: BioStil.mint, ik: BioIk.hjerte),
      for (final k in E.ikke) (tx: 'Ikke ${k.toLowerCase()}', stil: BioStil.nei, ik: BioIk.nei),
    ];

Color bioNivC(int score) => score == 5 ? const Color(0xFFFFDD86) : const Color(0xFF7FF0CB);

/// Min Bio on Meg (design L7458–7478): Ægil in the turning ring, «Min Bio ·
/// Ærend Intelligence», the score, the chips and Ægil's sentence. [puls]
/// changes after a save (`bioKortGlod`).
///
/// The design's «BRUKES I HELE APPEN» strip (Hjem, Hurtig, Menyer, Feed,
/// Poser, AI) is left out: only Ægil's own suggestions read the bio today.
class MinBioKort extends StatelessWidget {
  const MinBioKort({super.key, required this.bio, required this.onTap, this.puls = 0});

  final MinBio bio;
  final VoidCallback onTap;
  final int puls;

  @override
  Widget build(BuildContext context) {
    final E = bioEff(bio);
    final score = bioScore(bio, E);
    final kc = bioKortChips(E);
    return BioOmstart(
      key: const Key('meg-min-bio'),
      trigger: puls,
      ms: 1200,
      vedStart: false,
      builder: (context, t, child) {
        final s = puls == 0 ? 1.0 : kf(kfP(t, 0, 1200), const [0, .25, 1], const [1, 1.015, 1], const Cubic(.3, 1.3, .5, 1));
        return Transform.scale(scale: s, child: child);
      },
      child: LfPress(
        onTap: onTap,
        dy: 2,
        scale: .994,
        ms: 140,
        child: CssBox(
          radius: BorderRadius.circular(24),
          clip: true,
          bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .06)])],
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
          shadows: const [
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
            CssShadow(0, 20, 30, -20, Color.fromRGBO(4, 18, 26, .9)),
          ],
          child: Stack(
            children: [
              const Positioned(
                right: -50,
                top: -60,
                width: 190,
                height: 150,
                child: IgnorePointer(
                  child: CssBox(radius: BorderRadius.all(Radius.elliptical(95, 75)), bg: [CssRadial.closestSide([Color.fromRGBO(92, 224, 184, .2), Color.fromRGBO(92, 224, 184, 0)])]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const BioRingPortrett(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(BioCopy.tittel, style: jakarta(17, em: -.02)),
                                  const BioIntelligence(),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(BioCopy.kortLinje, style: inter(11.5, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .72))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const BioBlyant(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: BioSegmenter(score: score)),
                        const SizedBox(width: 10),
                        Text(
                          BioCopy.nivaa(score),
                          style: inter(11, weight: FontWeight.w800, color: bioNivC(score)).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final (i, c) in kc.take(5).indexed) LfRise(delay: 50 + i * 50.0, dur: 350, child: BioSmaaChip(tx: c.tx, stil: c.stil, ik: c.ik)),
                        if (kc.length > 5) BioSmaaChip(tx: '+${kc.length - 5}', stil: BioStil.av, ik: BioIk.pluss),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CssBox(
                      radius: BorderRadius.circular(14),
                      bg: const [CssSolid(Color.fromRGBO(0, 0, 0, .18))],
                      shadows: const [CssShadow.inset(0, 1, 3, 0, Color.fromRGBO(0, 0, 0, .3))],
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: BioCopy.aegil, style: inter(12, weight: FontWeight.w700, height: 1.45, color: const Color(0xFF7FF0CB))),
                          TextSpan(text: bioSetning(E)),
                        ]),
                        style: inter(12, weight: FontWeight.w700, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
