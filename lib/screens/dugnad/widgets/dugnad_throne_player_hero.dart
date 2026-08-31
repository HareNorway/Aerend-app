import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../../../services/dugnad_data_cache.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_form_utils.dart';
import '../dugnad_state.dart';
import 'dugnad_player_card.dart';

/// Player card + floating gold emoji badge (T10–T12 season personal titles).
///
/// Card drops in from the top-right; the emoji badge stamps on after confetti
/// finishes — same overshoot settle as T14 `SIGNERT` (`dgseq-stamp`).
class DugnadThronePlayerHero extends StatefulWidget {
  const DugnadThronePlayerHero({
    super.key,
    required this.badgeEmoji,
    this.displayName,
    /// When the emoji stamp fires. Defaults to 0.5s after confetti starts.
    this.stampDelay = const Duration(milliseconds: 500),
  });

  final String badgeEmoji;
  final String? displayName;
  final Duration stampDelay;

  @override
  State<DugnadThronePlayerHero> createState() => _DugnadThronePlayerHeroState();
}

class _DugnadThronePlayerHeroState extends State<DugnadThronePlayerHero>
    with TickerProviderStateMixin {
  late final AnimationController _card;
  late final AnimationController _stamp;
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _cardTilt;
  late final Animation<double> _cardFade;
  bool _started = false;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _card = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    // Design `dgseq-stamp` — 0.46s overshoot settle.
    _stamp = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    // Short drop from top-right corner — not a long fall.
    _cardOffset = Tween<Offset>(
      begin: const Offset(0.06, -0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _card, curve: Curves.easeOutCubic));

    _cardTilt = Tween<double>(begin: 0.09, end: 0).animate(
      CurvedAnimation(parent: _card, curve: Curves.easeOutCubic),
    );

    _cardFade = CurvedAnimation(parent: _card, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != null && reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (_started) return;
    _started = true;
    if (reduce) {
      _card.value = 1;
      _stamp.value = 1;
      return;
    }
    _card.forward(from: 0);
    // Stamp after confetti ends (not when the card settles).
    Future<void>.delayed(widget.stampDelay, () {
      if (!mounted || _reduceMotion == true) return;
      HapticFeedback.mediumImpact();
      _stamp.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _card.dispose();
    _stamp.dispose();
    super.dispose();
  }

  /// Design `dgseq-stamp`: scale 2.6 → 0.94 → 1.
  double _stampScale(double t) {
    if (t < 0.7) return 2.6 - (1.66 * (t / 0.7));
    return 0.94 + (0.06 * ((t - 0.7) / 0.3));
  }

  @override
  Widget build(BuildContext context) {
    final summary = DugnadDataCache.instance.peekPointsSummary();
    final name = (widget.displayName != null &&
            widget.displayName!.trim().isNotEmpty)
        ? widget.displayName!.trim()
        : (prefGetString(prefUserName).trim().isNotEmpty
            ? prefGetString(prefUserName)
            : 'Spiller');
    final crestName = DugnadState.instance.hasPointsTeam
        ? DugnadState.instance.pointsTeamName
        : DugnadClubBranding.compactName();
    final crestLogo = DugnadState.instance.hasPointsTeam &&
            DugnadState.instance.pointsTeamLogo.isNotEmpty
        ? DugnadState.instance.pointsTeamLogo
        : (DugnadState.instance.clubLogo.isNotEmpty
            ? DugnadState.instance.clubLogo
            : null);
    final cardWidth = context.dp(248);
    final badgeSize = context.dp(52);
    final reduce = _reduceMotion == true;

    final card = DugnadPlayerCard(
      name: name,
      tier: summary?.currentTier,
      points: summary?.lifetimePoints ?? 0,
      stoRating: summary?.stoRating ?? 40,
      isCaptain: DugnadState.instance.hasPointsTeam,
      crestName: crestName.isNotEmpty ? crestName : 'Klubb',
      crestLogo: crestLogo,
      purchases: summary?.actionCounts.campaignPurchases ?? 0,
      referrals: summary?.actionCounts.referralConversions ?? 0,
      width: cardWidth,
      animateIn: false,
      showRisingChevron: true,
      formStatus: DugnadFormStatus.up,
    );

    final badge = Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE7A0),
            Color(0xFFE0B84A),
            Color(0xFFC99828),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0B84A).withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 2.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.badgeEmoji,
        style: TextStyle(fontSize: context.dp(22), height: 1),
      ),
    );

    return SizedBox(
      width: cardWidth + context.dp(28),
      child: AnimatedBuilder(
        animation: Listenable.merge([_card, _stamp]),
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: context.dp(10),
                  right: context.dp(8),
                ),
                child: FadeTransition(
                  opacity: reduce
                      ? const AlwaysStoppedAnimation(1)
                      : _cardFade,
                  child: SlideTransition(
                    position: reduce
                        ? const AlwaysStoppedAnimation(Offset.zero)
                        : _cardOffset,
                    child: Transform.rotate(
                      angle: reduce ? 0 : _cardTilt.value,
                      alignment: Alignment.topRight,
                      child: card,
                    ),
                  ),
                ),
              ),
              if (reduce || _stamp.value > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Transform.scale(
                      scale: reduce ? 1 : _stampScale(_stamp.value),
                      child: badge,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
