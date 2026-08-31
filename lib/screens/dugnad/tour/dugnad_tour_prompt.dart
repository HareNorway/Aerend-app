import 'package:flutter/material.dart';

import '../../../main.dart' show navigatorKey;
import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart' show languages;
import '../dugnad_celebration_orchestrator.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_state.dart';
import 'dugnad_tour_controller.dart';

/// The tour invite (prototype `TourPrompt`). Built in Chunk 2 but NOT
/// auto-triggered — Chunk 4 wires the real trigger. For now the kDebugMode
/// launcher shows it via [show].
class DugnadTourPrompt {
  DugnadTourPrompt._();

  static OverlayEntry? _entry;
  static bool _holdingCelebrations = false;

  /// True while the invite is on screen.
  static bool get isVisible => _entry != null;

  /// Shows the prompt in the root Overlay. [onStart] fires when the user takes
  /// the tour; [onLater] when they dismiss. Both hide the prompt first.
  static void show({
    required VoidCallback onStart,
    required VoidCallback onLater,
  }) {
    hide();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    // This card's scrim is `Positioned.fill` + `HitTestBehavior.opaque`, and a
    // root Overlay entry sits above every route — so a celebration pushed
    // underneath would be covered and, worse, unreachable: its close button
    // never sees the pointer. Hold the queue until the invite is gone.
    DugnadCelebrationOrchestrator.instance.holdCriticalFlow();
    _holdingCelebrations = true;
    _entry = OverlayEntry(
      builder: (_) => _DugnadTourPromptCard(
        onStart: () {
          hide();
          onStart();
        },
        onLater: () {
          hide();
          onLater();
        },
      ),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
    if (_holdingCelebrations) {
      _holdingCelebrations = false;
      DugnadCelebrationOrchestrator.instance.releaseCriticalFlow();
    }
  }
}

class _DugnadTourPromptCard extends StatefulWidget {
  const _DugnadTourPromptCard({required this.onStart, required this.onLater});

  final VoidCallback onStart;
  final VoidCallback onLater;

  @override
  State<_DugnadTourPromptCard> createState() => _DugnadTourPromptCardState();
}

class _DugnadTourPromptCardState extends State<_DugnadTourPromptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    // Kick the entrance after first layout so reduced-motion can settle it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _in.value = 1;
      } else {
        _in.forward();
      }
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// Club theme from admin portal colours. Overlay sits above
  /// [DugnadClubThemeScope], so resolve via [DugnadState] rather than inherited.
  DugnadClubThemePalette get _theme {
    final st = DugnadState.instance;
    if (st.isDugnadMode && st.hasClub) return st.themePalette;
    return context.dugnadTheme;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final l = languages;
    // Reward strip hidden once the reward is paid (read-only; never written here).
    final rewardPaid = prefGetBool(prefDugnadTourRewardPaid);

    return Stack(
      children: [
        // Scrim rgba(20,12,40,.42), fades in over 280ms. Absorbs input; tapping
        // it does not dismiss (only the buttons do).
        Positioned.fill(
          child: FadeTransition(
            opacity: _in,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const ColoredBox(color: Color(0x6B140C28)),
            ),
          ),
        ),
        // Card pinned to the bottom, padding 0/16/26, rises 26px with fade.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
            child: SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _in,
                builder: (context, child) {
                  final t = _in.value;
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 26 * (1 - t)),
                      child: child,
                    ),
                  );
                },
                child: _card(context, theme, l, rewardPaid),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, DugnadClubThemePalette theme,
      dynamic l, bool rewardPaid) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.dp(20),
        context.dp(22),
        context.dp(20),
        context.dp(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80140C28),
            blurRadius: 40,
            offset: Offset(0, -8),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon tile 48×48 — Lucide `sparkle` (prototype), club theme fill.
          Container(
            width: context.dp(48),
            height: context.dp(48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(15)),
              gradient: theme.shinyGradient,
              boxShadow: theme.shadowButton,
            ),
            alignment: Alignment.center,
            child: _SparkleIcon(size: context.dp(22), color: Colors.white),
          ),
          SizedBox(height: context.dp(13)),
          Text(
            l.dugnadTourPromptTitle,
            textAlign: TextAlign.center,
            style: aeH3(color: theme.text).copyWith(
              fontSize: context.dp(19),
              fontWeight: FontWeight.w800,
              letterSpacing: context.dp(19) * -0.02,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: context.dp(7)),
          Text(
            l.dugnadTourPromptBody,
            textAlign: TextAlign.center,
            style: aeBody(color: ScSaasThemeTokens.gray500).copyWith(
              fontSize: context.dp(13.5),
              fontWeight: FontWeight.w600,
              height: 1.45,
              decoration: TextDecoration.none,
            ),
          ),
          if (!rewardPaid) ...[
            SizedBox(height: context.dp(16)),
            _RewardStrip(points: DugnadTourController.rewardPoints, l: l),
          ],
          SizedBox(height: context.dp(16)),
          _PrimaryButton(
            label: l.dugnadTourPromptStart,
            theme: theme,
            onTap: widget.onStart,
          ),
          SizedBox(height: context.dp(4)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onLater,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.dp(13)),
              child: Text(
                l.dugnadTourPromptLater,
                style: aeLabel(color: ScSaasThemeTokens.gray500).copyWith(
                  fontSize: context.dp(13.5),
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold reward strip. Colours are the reward's own design constants (not the
/// brand palette). Hidden by the caller once the reward is paid.
class _RewardStrip extends StatelessWidget {
  const _RewardStrip({required this.points, required this.l});

  final int points;
  final dynamic l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(13), vertical: context.dp(10)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(15)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0C2), Color(0xFFF8D779), Color(0xFFECBD4E)],
          stops: [0.0, 0.46, 1.0],
        ),
        border: Border.all(color: const Color(0x73D69E28)),
      ),
      child: Row(
        children: [
          // 34px coin tile — solid star, no sheen sweep (matches design ref).
          Container(
            width: context.dp(34),
            height: context.dp(34),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(10)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE49A), Color(0xFFE7B542), Color(0xFFCF971F)],
                stops: [0.0, 0.6, 1.0],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xD9BE871E),
                  blurRadius: 13,
                  offset: Offset(0, 6),
                  spreadRadius: -5,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(Icons.star_rounded,
                color: Colors.white, size: context.dp(17)),
          ),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: aeLabel(color: const Color(0xFF7A5410)).copyWith(
                  fontSize: context.dp(13),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  decoration: TextDecoration.none,
                ),
                children: [
                  TextSpan(
                    text: '+$points ',
                    style: TextStyle(
                      fontSize: context.dp(16),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3F2C07),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  TextSpan(
                    text: '${l.dugnadTourPromptReward}\n',
                    style: const TextStyle(decoration: TextDecoration.none),
                  ),
                  TextSpan(
                    text: l.dugnadTourPromptRewardNote,
                    style: TextStyle(
                      fontSize: context.dp(11.5),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF936410),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final DugnadClubThemePalette theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: context.dp(52),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: theme.shinyGradient,
          borderRadius: BorderRadius.circular(context.dp(14)),
          boxShadow: theme.shadowButton,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SparkleIcon(size: context.dp(17), color: Colors.white),
            SizedBox(width: context.dp(8)),
            Text(
              label,
              style: aeLabel(color: Colors.white).copyWith(
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lucide-style filled `sparkle` from `ui_kits/icons.jsx` — single 4-point
/// diamond (not Material `auto_awesome` multi-sparkle).
class _SparkleIcon extends StatelessWidget {
  const _SparkleIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparklePainter(color: color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final path = Path()
      ..moveTo(12, 2)
      ..lineTo(14, 9)
      ..lineTo(21, 12)
      ..lineTo(14, 15)
      ..lineTo(12, 22)
      ..lineTo(10, 15)
      ..lineTo(3, 12)
      ..lineTo(10, 9)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}
