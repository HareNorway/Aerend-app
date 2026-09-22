import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../theme/reen_pre_club_theme.dart';

/// A prize from the band above the customer's, shown blurred.
///
/// Per `designs/Ærend Kunde Bergen.dc.html`: at most three, dearest first, each with a
/// "Fra <tier> · N poeng til" line, and **no padlock**. The absence of the padlock is the
/// point — the shelf should read as "not yet", not "forbidden". The shared design rules also
/// forbid gamification pressure, and a lock icon is exactly that.
class PrizePreviewCard extends StatelessWidget {
  const PrizePreviewCard({super.key, required this.preview});

  final PrizePreview preview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${preview.name}. ${preview.unlockLine}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // The prize itself is blurred: recognisable as something, not readable as a
            // specific temptation.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                height: 116,
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AerendBergenAuthTokens.navyTop,
                      AerendBergenAuthTokens.navyMid,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AerendBergenAuthTokens.ink,
                      ),
                    ),
                    if (preview.teaser != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          preview.teaser!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AerendBergenAuthTokens.textSoft,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // The unlock line stays sharp — it is the actionable part.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: AerendBergenAuthTokens.navyBottom.withValues(alpha: 0.72),
                child: Text(
                  preview.unlockLine,
                  key: const Key('prize-preview-unlock-line'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AerendBergenAuthTokens.textSubtitle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
