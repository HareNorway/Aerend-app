import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_state.dart';

/// Light tap when a dugnad bottom sheet presents.
void dugnadSheetOpenHaptic() => HapticFeedback.lightImpact();

/// Softer tick for dismiss / secondary sheet actions.
void dugnadSheetCloseHaptic() => HapticFeedback.selectionClick();

/// Confirmation for primary save / commit in sheets.
void dugnadSheetSaveHaptic() => HapticFeedback.mediumImpact();

class _DugnadSheetHapticScope extends StatefulWidget {
  const _DugnadSheetHapticScope({required this.child});

  final Widget child;

  @override
  State<_DugnadSheetHapticScope> createState() => _DugnadSheetHapticScopeState();
}

class _DugnadSheetHapticScopeState extends State<_DugnadSheetHapticScope> {
  @override
  void initState() {
    super.initState();
    dugnadSheetOpenHaptic();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shared bottom-sheet chrome for dugnad mode so every sheet matches the
/// prototype (`.dg-msheet` / `.dg-csheet`) on corner radius, backdrop, and
/// background. Flutter's [showModalBottomSheet] already animates the slide-up
/// entry and slide-down exit natively (the prototype had to fake the exit via
/// `sheet-exit.js`), so no custom transition is needed here.

/// Prototype `.dg-msheet` / `.dg-csheet` corner radius (26, top only).
const double kDugnadSheetRadius = 26;

/// Prototype `.dg-msheet-overlay` backdrop — rgba(20,12,40,0.42).
const Color kDugnadSheetBarrier = Color(0x6B140C28);

/// Opens a dugnad bottom sheet with the shared radius / backdrop / club
/// background. Mirrors `showModalBottomSheet` but with the dugnad chrome baked
/// in. Pass [backgroundColor] to override the club background default.
Future<T?> showDugnadSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  BoxConstraints? constraints,
}) {
  final clubBg = DugnadState.instance.isDugnadMode
      ? context.dugnadTheme.background
      : ScSaasThemeTokens.background;
  // Scale the prototype 26px radius so corners stay visibly curved on all
  // densities — and clip so the lavender fill doesn't square them off.
  final radius = context.dp(kDugnadSheetRadius);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? clubBg,
    barrierColor: kDugnadSheetBarrier,
    constraints: constraints,
    clipBehavior: Clip.antiAlias,
    // `@keyframes dg-sheet-up` .32s cubic-bezier(.22,1,.36,1) in, and
    // `@keyframes dg-sheet-down` .3s cubic-bezier(.4,0,1,1) out — the exit is
    // ease-*in*, so the sheet accelerates downward rather than easing to rest.
    sheetAnimationStyle: AnimationStyle(
      curve: const Cubic(0.22, 1, 0.36, 1),
      duration: const Duration(milliseconds: 320),
      reverseCurve: const Cubic(0.4, 0, 1, 1),
      reverseDuration: const Duration(milliseconds: 300),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    ),
    builder: (sheetContext) => DugnadClubThemeScope(
      palette: context.dugnadTheme,
      child: _DugnadSheetHapticScope(child: builder(sheetContext)),
    ),
  );
}

/// The prototype drag handle (`.dg-msheet-grab`): 40×5 pill, gray-300, centered.
class DugnadSheetHandle extends StatelessWidget {
  const DugnadSheetHandle({super.key, this.bottom = 14});

  /// Space beneath the handle (prototype `margin: 2px auto 14px`).
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.dp(2), bottom: bottom),
      child: Center(
        child: Container(
          width: context.dp(40),
          height: context.dp(5),
          decoration: BoxDecoration(
            color: ScSaasThemeTokens.gray300,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
