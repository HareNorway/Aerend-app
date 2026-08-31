import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../commonView/surface_decorations.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../../ui/kit/ae_sheet.dart';

/// "Bytt modus" bottom sheet — Dugnad (active, checkmark) and
/// Kommersiell (locked, "Kommer snart", toast on tap).
///
/// Design spec: dugnad/auth.jsx → ModeSheet.
Future<void> showModeSheet(BuildContext context) {
  return showAeSheet<void>(
    context: context,
    builder: (_) => const _ModeSheetBody(),
  );
}

class _ModeSheetBody extends StatelessWidget {
  const _ModeSheetBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(12), context.dp(18), context.dp(32)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AeSheetHandle(),
          // Title + close
          Row(
            children: [
              Expanded(child: Text(languages.dugnadSwitchMode, style: aeH2())),
              GestureDetector(
                onTap: () {
                  aeSheetCloseHaptic();
                  Navigator.pop(context);
                },
                child: Icon(Icons.close_rounded,
                    color: ScSaasThemeTokens.gray500, size: context.dp(22)),
              ),
            ],
          ),
          SizedBox(height: context.dp(20)),

          // ── Dugnad row (active) ─────────────────────────────────────
          Container(
            padding: EdgeInsets.all(context.dp(14)),
            decoration: AeSurface.card(borderRadius: BorderRadius.circular(context.dp(14))),
            child: Row(
              children: [
                Container(
                  width: context.dp(40),
                  height: context.dp(40),
                  decoration: AeSurface.shinyPurple(isCircle: true),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/svgs/menu/heart.svg',
                      width: context.dp(18),
                      height: context.dp(18),
                      colorFilter: const ColorFilter.mode(
                          Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
                SizedBox(width: context.dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(languages.dugnadModeDugnad, style: aeTitle()),
                      Text(languages.dugnadActiveNow,
                          style: aeCaption()),
                    ],
                  ),
                ),
                Container(
                  width: context.dp(28),
                  height: context.dp(28),
                  decoration: const BoxDecoration(
                    color: ScSaasThemeTokens.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      color: Colors.white, size: context.dp(16)),
                ),
              ],
            ),
          ),

          SizedBox(height: context.dp(10)),

          // ── Kommersiell row (locked) ─────────────────────────────────
          GestureDetector(
            onTap: () {
              openSimpleSnackbar(languages.dugnadCommercialComingSoonToast);
            },
            child: Opacity(
              opacity: 0.55,
              child: Container(
                padding: EdgeInsets.all(context.dp(14)),
                decoration:
                    AeSurface.card(borderRadius: BorderRadius.circular(context.dp(14))),
                child: Row(
                  children: [
                    Container(
                      width: context.dp(40),
                      height: context.dp(40),
                      decoration: BoxDecoration(
                        color: ScSaasThemeTokens.gray100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.store_rounded,
                          color: ScSaasThemeTokens.gray500, size: context.dp(20)),
                    ),
                    SizedBox(width: context.dp(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  languages.dugnadModeCommercial,
                                  style: aeTitle(
                                      color: ScSaasThemeTokens.gray500),
                                ),
                              ),
                              SizedBox(width: context.dp(7)),
                              // "Kommer snart" badge (clock + label).
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ScSaasThemeTokens.gray100,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: context.dp(10),
                                        color: ScSaasThemeTokens.gray500),
                                    SizedBox(width: context.dp(3)),
                                    Text(
                                      languages.dugnadModeComingSoon,
                                      style: aeOverline(
                                              color: ScSaasThemeTokens.gray500)
                                          .copyWith(fontSize: 9.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.dp(2)),
                          Text(languages.dugnadModeCommercialSub,
                              style: aeCaption()),
                        ],
                      ),
                    ),
                    SizedBox(width: context.dp(8)),
                    // Right-side shield (prototype `.lock`).
                    Icon(Icons.shield_outlined,
                        size: context.dp(15), color: ScSaasThemeTokens.gray500),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
