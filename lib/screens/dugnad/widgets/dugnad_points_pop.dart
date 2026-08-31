import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/global_loading_overlay.dart';
import '../../../main.dart' show navigatorKey;
import '../dugnad_celebration_orchestrator.dart';
import '../dugnad_club_theme.dart';

/// Global « for `window.dgAwardPoints` — Design `dugnad/points-pop.jsx`.
class DugnadPointsAward {
  const DugnadPointsAward({
    required this.points,
    this.reason,
    this.unit,
  });

  final int points;
  final String? reason;
  final String? unit;
}

/// Overlay titles from Design `Custom Dugnad Future.html` tweak options.
class DugnadPointsPopReasons {
  static String clubShop(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Club shop purchase';
      case 'es':
        return 'Compra en la tienda del club';
      case 'sv':
        return 'Köp i klubbshopen';
      case 'da':
        return 'Køb i klubshoppen';
      default:
        return 'Kjøp i klubbshopen';
    }
  }

  static String campaign(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Campaign purchase';
      case 'es':
        return 'Compra de campaña';
      case 'sv':
        return 'Köp i kampanj';
      case 'da':
        return 'Køb i kampagne';
      default:
        return 'Kjøp i kampanje';
    }
  }

  static String monthlySupport(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Monthly support';
      case 'es':
        return 'Apoyo mensual';
      case 'sv':
        return 'Fast månadsstöd';
      case 'da':
        return 'Fast månedlig støtte';
      default:
        return 'Fast månedlig støtte';
    }
  }

  static String welcome(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Welcome bonus';
      case 'es':
        return 'Bonus de bienvenida';
      case 'sv':
        return 'Välkomstbonus';
      case 'da':
        return 'Velkomstbonus';
      default:
        return 'Velkomstbonus';
    }
  }

  static String referralJoin(BuildContext context) {
    return referralJoinFromCode(Localizations.localeOf(context).languageCode);
  }

  static String referralJoinFromCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'Referral bonus';
      case 'es':
        return 'Bonus de referido';
      case 'sv':
        return 'Värvningsbonus';
      case 'da':
        return 'Værvebonus';
      default:
        return 'Vervebonus';
    }
  }

  static String weeklyMission(BuildContext context) {
    return weeklyMissionFromCode(Localizations.localeOf(context).languageCode);
  }

  static String weeklyMissionFromCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'Weekly mission';
      case 'es':
        return 'Misión semanal';
      case 'sv':
        return 'Veckouppdrag';
      case 'da':
        return 'Ugentlig mission';
      default:
        return 'Ukesoppdrag';
    }
  }

  static String seasonGoal(BuildContext context) {
    return seasonGoalFromCode(Localizations.localeOf(context).languageCode);
  }

  static String seasonGoalFromCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'Season goal';
      case 'es':
        return 'Objetivo de temporada';
      case 'sv':
        return 'Säsongsmål';
      case 'da':
        return 'Sæsonmål';
      default:
        return 'Sesongmål';
    }
  }

  static String missionFromAction(String languageCode, String action) {
    if (action == 'season_goal_bonus') {
      return seasonGoalFromCode(languageCode);
    }
    return weeklyMissionFromCode(languageCode);
  }

  static String tour(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'App tour';
      case 'es':
        return 'Recorrido de la app';
      case 'sv':
        return 'Appgenomgång';
      case 'da':
        return 'App-gennemgang';
      default:
        return 'Gjennomgang';
    }
  }
}

/// Queue + host for the points pop. Call [award] from anywhere points land.
class DugnadPointsPop {
  DugnadPointsPop._();

  static final Queue<_QueuedAward> _queue = Queue<_QueuedAward>();
  static bool _busy = false;
  static OverlayEntry? _entry;
  static bool _inserting = false;
  static bool _holdingCelebrations = false;

  /// The pop's scrim is a full-screen `GestureDetector` in a root Overlay
  /// entry, so it sits above every route. Over a celebration ceremonial
  /// (T13/T14) it hides the ceremony and eats its close button — hold the
  /// queue for as long as a pop is on screen.
  static void _holdCelebrations() {
    if (_holdingCelebrations) return;
    _holdingCelebrations = true;
    DugnadCelebrationOrchestrator.instance.holdCriticalFlow();
  }

  static void _releaseCelebrations() {
    if (!_holdingCelebrations) return;
    _holdingCelebrations = false;
    DugnadCelebrationOrchestrator.instance.releaseCriticalFlow();
  }

  /// Drop any queued/visible pop. Call before a route change (e.g. home).
  static void dismissNow() {
    _queue.clear();
    _busy = false;
    _inserting = false;
    _removeOverlay();
  }

  static void _removeOverlay() {
    final entry = _entry;
    _entry = null;
    _releaseCelebrations();
    if (entry == null) return;
    try {
      entry.remove();
    } catch (_) {}
  }

  /// `window.dgAwardPoints(points, { reason, unit })`.
  static void award(
    int points, {
    BuildContext? context,
    String? reason,
    String? unit,
  }) {
    if (points <= 0) return;
    _queue.add(_QueuedAward(
      award: DugnadPointsAward(
        points: points,
        reason: reason,
        unit: unit,
      ),
      context: context,
    ));
    _pump();
  }

  static void _pump() {
    if (_busy || _queue.isEmpty) return;
    _busy = true;
    final next = _queue.removeFirst();
    unawaited(_revealWhenReady(next));
  }

  static Future<void> _revealWhenReady(_QueuedAward queued) async {
    for (var i = 0; i < 180; i++) {
      if (!isGlobalLoadingOverlayVisible) break;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    OverlayState? overlay;
    for (var i = 0; i < 30; i++) {
      overlay = _overlayOf(queued.context);
      if (overlay != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    if (overlay == null) {
      _busy = false;
      _pump();
      return;
    }
    _removeOverlay();
    _inserting = true;
    final entry = OverlayEntry(
      builder: (context) => RepaintBoundary(
        child: ExcludeSemantics(
          child: _DgppLayer(
            award: queued.award,
            onDone: _finished,
          ),
        ),
      ),
    );
    _entry = entry;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_inserting || _entry != entry) return;
      _inserting = false;
      if (!overlay!.mounted) {
        _entry = null;
        _busy = false;
        _pump();
        return;
      }
      try {
        _holdCelebrations();
        overlay.insert(entry);
      } catch (_) {
        _releaseCelebrations();
        _entry = null;
        _busy = false;
        _pump();
      }
    });
  }

  /// [Overlay.maybeOf] only walks ancestors. [navigatorKey.currentContext] is
  /// the Navigator itself, whose Overlay is a child — so we fall back to
  /// [NavigatorState.overlay] the same way the tour host does.
  static OverlayState? _overlayOf(BuildContext? ctx) {
    if (ctx != null && ctx.mounted) {
      final fromCtx = Overlay.maybeOf(ctx, rootOverlay: true);
      if (fromCtx != null) return fromCtx;
    }
    return navigatorKey.currentState?.overlay;
  }

  static void _finished() {
    _removeOverlay();
    _busy = false;
    _inserting = false;
    _pump();
  }
}

class _QueuedAward {
  const _QueuedAward({required this.award, this.context});
  final DugnadPointsAward award;
  final BuildContext? context;
}

/// Place on a confirmation screen. Waits until that route has finished
/// sliding in and painted, then shows the points pop — never over the loader.
class DugnadPointsPopTrigger extends StatefulWidget {
  const DugnadPointsPopTrigger({
    super.key,
    required this.points,
    this.reason,
    this.enabled = true,
    this.extraDelay = Duration.zero,
  });

  final int points;
  final String? reason;
  final bool enabled;
  /// Extra wait after the shared route-in delay, so a follow-up pop can
  /// enqueue after the first `award` call.
  final Duration extraDelay;

  @override
  State<DugnadPointsPopTrigger> createState() => _DugnadPointsPopTriggerState();
}

class _DugnadPointsPopTriggerState extends State<DugnadPointsPopTrigger> {
  bool _armed = false;
  bool _cancelled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_armed || !widget.enabled || widget.points <= 0) return;
    _armed = true;
    unawaited(_waitThenAward());
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _waitThenAward() async {
    final animation = ModalRoute.of(context)?.animation;
    if (animation != null && animation.value < 0.999) {
      final done = Completer<void>();
      void tick() {
        if (animation.value >= 0.999) {
          animation.removeListener(tick);
          if (!done.isCompleted) done.complete();
        }
      }

      animation.addListener(tick);
      try {
        await done.future.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        animation.removeListener(tick);
      }
    }
    if (!mounted || _cancelled) return;
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (widget.extraDelay > Duration.zero) {
      await Future<void>.delayed(widget.extraDelay);
    }
    if (!mounted || _cancelled) return;
    DugnadPointsPop.award(
      widget.points,
      context: context,
      reason: widget.reason,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DgppLayer extends StatefulWidget {
  const _DgppLayer({
    required this.award,
    required this.onDone,
  });

  final DugnadPointsAward award;
  final VoidCallback onDone;

  @override
  State<_DgppLayer> createState() => _DgppLayerState();
}

class _DgppLayerState extends State<_DgppLayer> with TickerProviderStateMixin {
  static const _goldLight = Color(0xFFF7D979);
  static const _goldMid = Color(0xFFE0A93A);
  static const _goldDark = Color(0xFFC2871C);
  static const _goldAmt = Color(0xFF9A6B12);
  static const _goldUnit = Color(0xFFB4791B);

  late final AnimationController _bg;
  late final AnimationController _card;
  late final AnimationController _coin;
  late final AnimationController _ring;
  late final AnimationController _count;
  late final AnimationController _out;
  late final AnimationController _confettiAnim;
  Timer? _hold;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final pts = widget.award.points;
    final countMs = math.min(900, 260 + pts * 5);

    _bg = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _card = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _coin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _count = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: countMs),
    );
    _out = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _confettiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      HapticFeedback.mediumImpact();
      if (reduce) {
        _bg.value = 1;
        _card.value = 1;
        _coin.value = 1;
        _count.value = 1;
      } else {
        _bg.forward();
        _card.forward();
        _coin.forward();
        _confettiAnim.forward();
        Future<void>.delayed(const Duration(milliseconds: 160), () {
          if (mounted) _ring.forward();
        });
        _count.forward().whenComplete(() {
          if (mounted && _count.value < 1) _count.value = 1;
        });
        // Same safety net as design useCountUp — never leave the amount at 0.
        Future<void>.delayed(Duration(milliseconds: countMs + 40), () {
          if (mounted && _count.value < 1) _count.value = 1;
        });
      }
      _hold = Timer(const Duration(milliseconds: 4200), _dismiss);
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _bg.dispose();
    _card.dispose();
    _coin.dispose();
    _ring.dispose();
    _count.dispose();
    _out.dispose();
    _confettiAnim.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _hold?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onDone();
      return;
    }
    await _out.forward();
    if (mounted) widget.onDone();
  }

  String _unit(BuildContext context) {
    final raw = widget.award.unit?.trim() ?? '';
    if (raw.isNotEmpty && raw.length <= 12) return raw.toUpperCase();
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'en':
        return 'POINTS';
      case 'es':
        return 'PUNTOS';
      case 'sv':
        return 'POÄNG';
      case 'da':
        return 'POINT';
      default:
        return 'POENG';
    }
  }

  String _note(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Added to your account';
      case 'es':
        return 'Añadido a tu cuenta';
      case 'sv':
        return 'Tillagt på ditt konto';
      case 'da':
        return 'Lagt på din konto';
      default:
        return 'Lagt til kontoen din';
    }
  }

  String? _reason(BuildContext context) {
    final unit = widget.award.unit?.trim() ?? '';
    if (widget.award.reason != null && widget.award.reason!.isNotEmpty) {
      return widget.award.reason;
    }
    if (unit.length > 12) return unit;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final reason = _reason(context);

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bg,
          _card,
          _coin,
          _ring,
          _count,
          _out,
          _confettiAnim,
        ]),
        builder: (context, _) {
          final shown = (_count.value * widget.award.points).round();
          final leave = _out.value;
          final bgT = reduce ? 1.0 : (_leaving ? (1 - leave) : _bg.value);
          final popT = reduce ? 1.0 : _card.value;
          const popCurve = Cubic(0.22, 1.5, 0.4, 1);
          final cardY = (1 - popCurve.transform(popT.clamp(0.0, 1.0))) * 26;
          final cardS = 0.82 + 0.18 * popCurve.transform(popT.clamp(0.0, 1.0));
          final cardOp = reduce ? 1.0 : popT.clamp(0.0, 1.0);
          final awayY = leave < 0.4 ? 0.0 : ((leave - 0.4) / 0.6) * 14;
          final awayS = leave < 0.4 ? 1.0 : 1 - ((leave - 0.4) / 0.6) * 0.06;
          final awayOp = leave <= 0.4
              ? 1 - (leave / 0.4) * 0.28
              : 0.72 * (1 - (leave - 0.4) / 0.6);

          return GestureDetector(
            onTap: _dismiss,
            child: ColoredBox(
              color: Color.fromRGBO(16, 10, 34, 0.34 * bgT.clamp(0.0, 1.0)),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(context.dp(30)),
                  child: Opacity(
                    opacity: _leaving ? awayOp.clamp(0.0, 1.0) : cardOp,
                    child: Transform.translate(
                      offset: Offset(0, _leaving ? awayY : cardY),
                      child: Transform.scale(
                        scale: _leaving ? awayS : cardS,
                        child: GestureDetector(
                          onTap: () {},
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: context.dp(280),
                            ),
                            child: _cardBody(
                              context,
                              theme,
                              shown: shown,
                              reason: reason,
                              reduce: reduce,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cardBody(
    BuildContext context,
    DugnadClubThemePalette theme, {
    required int shown,
    required String? reason,
    required bool reduce,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(26)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29140C28),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x9E140C28),
            offset: Offset(0, 26),
            blurRadius: 54,
            spreadRadius: -22,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(24),
              context.dp(26),
              context.dp(24),
              context.dp(22),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: SizedBox(
                      width: context.dp(84),
                      height: context.dp(84),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          if (!reduce) ...[
                            for (var i = 0; i < 10; i++)
                              _ray(context, theme, i),
                            _ringBurst(context),
                          ],
                          _coinFace(context, reduce),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.dp(14)),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '+$shown',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.dp(44),
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 44 * -0.03,
                        color: _goldAmt,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  SizedBox(height: context.dp(4)),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _unit(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.dp(12),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 12 * 0.12,
                        color: _goldUnit,
                      ),
                    ),
                  ),
                  if (reason != null) ...[
                    SizedBox(height: context.dp(13)),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        reason,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.dp(14.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 14.5 * -0.01,
                          color: theme.text,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: context.dp(5)),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _note(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.dp(12.5),
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: context.dp(14),
            right: context.dp(14),
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                width: context.dp(38),
                height: context.dp(38),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x122D1B5B),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: context.dp(18),
                  color: theme.text,
                ),
              ),
            ),
          ),
          if (!reduce && !_confettiAnim.isCompleted)
            Positioned.fill(
              child: IgnorePointer(child: _confetti(context, theme)),
            ),
        ],
      ),
    );
  }

  Widget _coinFace(BuildContext context, bool reduce) {
    final t = reduce ? 1.0 : Curves.easeOutBack.transform(_coin.value);
    final angle = (1 - t) * math.pi;
    final scale = 0.5 + 0.5 * t;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle)
        ..scale(scale),
      child: Container(
        width: context.dp(68),
        height: context.dp(68),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment(-0.5, -0.85),
            end: Alignment(0.5, 0.85),
            colors: [_goldLight, _goldMid, _goldDark],
            stops: [0, 0.62, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              offset: const Offset(0, 1),
              blurRadius: 1,
            ),
            const BoxShadow(
              color: Color(0xB3D8A028),
              offset: Offset(0, 14),
              blurRadius: 28,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: context.dp(30),
        ),
      ),
    );
  }

  Widget _ringBurst(BuildContext context) {
    final t = Curves.easeOut.transform(_ring.value);
    final scale = 0.7 + 1.15 * t;
    final opacity = t <= 0 ? 0.0 : (0.9 * (1 - t)).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: context.dp(68),
        height: context.dp(68),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0x8CD8A028).withValues(alpha: opacity),
            width: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _ray(BuildContext context, DugnadClubThemePalette theme, int i) {
    final delay = 0.1;
    final local = ((_coin.value - delay) / 0.5).clamp(0.0, 1.0);
    double opacity = 0;
    if (local > 0 && local < 0.3) {
      opacity = 0.85 * (local / 0.3);
    } else if (local >= 0.3) {
      opacity = 0.85 * (1 - (local - 0.3) / 0.7);
    }
    final lift = local * 42;
    return Transform.rotate(
      angle: i * 36 * math.pi / 180,
      child: Transform.translate(
        offset: Offset(0, -lift),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: context.dp(2.5),
            height: context.dp(12),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _confetti(BuildContext context, DugnadClubThemePalette theme) {
    final colors = [
      theme.primary,
      const Color(0xFFE0A93A),
      theme.primaryDisabled,
      const Color(0xFFF7D979),
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < 12; i++)
          _confettiBit(context, i, colors[i % 4]),
      ],
    );
  }

  Widget _confettiBit(BuildContext context, int i, Color color) {
    final delay = 0.08 + i * 0.018;
    final span = (1.0 - delay).clamp(0.2, 1.0);
    final t = ((_confettiAnim.value - delay) / span).clamp(0.0, 1.0);
    // Fade fully out by t=1 so bits never freeze on the card.
    final opacity = t <= 0
        ? 0.0
        : (t < 0.12 ? t / 0.12 : (1 - (t - 0.12) / 0.88));
    final dx = (i - 5.5) * 26 * t;
    final dy = (78 + i * 7) * t;
    final rot = i * 96 * t * math.pi / 180;
    final scale = 0.6 + 0.4 * t;
    final round = i % 4 == 2;
    return Positioned(
      left: context.dp(140) + dx,
      top: context.dp(34) + dy,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: context.dp(round ? 6 : 7),
              height: context.dp(round ? 6 : 9),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(round ? 99 : 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
