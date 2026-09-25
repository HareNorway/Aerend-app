import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// "Uten nett · viser siste kjente status" (design `.offline`). Grows in
/// above the content when [visible]; the copy is the contract wording.
class BergenOfflineBanner extends StatelessWidget {
  const BergenOfflineBanner({super.key, this.visible = true});

  static const String copy = 'Uten nett · viser siste kjente status';

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: BergenTokens.motion(context, BergenTokens.motionBase),
      curve: BergenTokens.motionCurve,
      alignment: Alignment.topCenter,
      child: visible
          ? Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: BergenTokens.tealNight,
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 16,
                      color: BergenTokens.lantern,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        copy,
                        style: BergenTokens.text(
                          BergenTokens.textSmall,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
