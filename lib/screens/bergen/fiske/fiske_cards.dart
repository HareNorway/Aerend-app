import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/suggestion_models.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import 'fiske_copy.dart';
import 'fiske_frame.dart';
import 'fiske_game.dart';
import 'fiske_motion.dart';

/// One card of the deck as the screen shows it: the suggestion plus what the
/// store read added (name, price) — the design's `fNavn / fButikk / fPris /
/// fBydel / fEta / fNapp`.
class FiskeCatch {
  const FiskeCatch({
    required this.suggestion,
    required this.name,
    this.storeName,
    this.priceKr,
    this.productId,
    this.bydel,
    this.eta,
    this.napp = false,
  });

  final Suggestion suggestion;
  final String name;
  final String? storeName;
  final int? priceKr;
  final int? productId;
  final String? bydel;
  final String? eta;

  /// The daily catch (`FISKE[].napp`): the «Napp!» badge and Ægil's shock.
  final bool napp;

  FiskeAgn? get agn => FiskeAgn.of(suggestion);

  FiskeCatch copyWith({bool? napp}) => FiskeCatch(
    suggestion: suggestion,
    name: name,
    storeName: storeName,
    priceKr: priceKr,
    productId: productId,
    bydel: bydel,
    eta: eta,
    napp: napp ?? this.napp,
  );
}

/// The card's `animation:` (design `st.fiskeAnim`).
enum FiskeCardAnim { fangstOpp, kortInn, kastVenstre, kastHoyre, kastOpp }

/// Plays [anim] on [child] (a 250-wide card); re-key with [seq] to replay.
///
/// * `fangstOpp .75s cubic-bezier(.2,1.1,.4,1)`: 0 % translateY(260)
///   scale(.6) rotate(−6°) opacity 0 → 55 % translateY(−16) scale(1.04)
///   rotate(1.5°) → 100 % rest.
/// * `kortInn .5s cubic-bezier(.3,1.2,.5,1)`: translateY(140) scale(.86)
///   opacity 0 → rest.
/// * `kastVenstre/Hoyre .42s ease-in`: → translateX(∓170 %) rotate(∓22°)
///   opacity 0. `kastOpp`: → translateY(−150 %) scale(.86) opacity 0.
class FiskeCardMotion extends StatelessWidget {
  const FiskeCardMotion({
    super.key,
    required this.anim,
    required this.seq,
    required this.child,
  });

  final FiskeCardAnim anim;
  final int seq;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final (dur, curve) = switch (anim) {
      FiskeCardAnim.fangstOpp => (750.0, kFangstOpp),
      FiskeCardAnim.kortInn => (500.0, kKortInn),
      _ => (420.0, Curves.easeIn),
    };
    return FiskeOnce(
      key: ValueKey('a1_fiske_kort_anim_$seq'),
      durationMs: dur,
      child: child,
      builder: (context, p, child) {
        double tx = 0, ty = 0, sc = 1, rot = 0, op = 1;
        switch (anim) {
          case FiskeCardAnim.fangstOpp:
            const st = [0.0, .55, 1.0];
            ty = kf(p, st, const [260, -16, 0], curve);
            sc = kf(p, st, const [.6, 1.04, 1], curve);
            rot = kf(p, st, const [-6, 1.5, 0], curve);
            op = kf(p, st, const [0, 1, 1], curve);
          case FiskeCardAnim.kortInn:
            final q = curve.transform(p);
            ty = 140 * (1 - q);
            sc = .86 + .14 * q;
            op = q;
          case FiskeCardAnim.kastVenstre:
          case FiskeCardAnim.kastHoyre:
            final q = curve.transform(p);
            final dir = anim == FiskeCardAnim.kastVenstre ? -1 : 1;
            tx = dir * 1.7 * 250 * q;
            rot = dir * 22 * q;
            op = 1 - q;
          case FiskeCardAnim.kastOpp:
            final q = curve.transform(p);
            ty = -1.5 * 250 * q;
            sc = 1 - .14 * q;
            op = 1 - q;
        }
        return Opacity(
          opacity: op.clamp(0, 1),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(tx * s, ty * s)
              ..scale(sc)
              ..rotateZ(rot * math.pi / 180),
            child: child,
          ),
        );
      },
    );
  }
}

/// The paper shell both catch cards share: `width:250;border-radius:28;
/// background:linear-gradient(180deg,#FFFFFF,#F6F2E9);border:1px #FFFFFF;
/// box-shadow:inset 0 2px 0 #FFFFFF, 0 0 0 1px rgba(255,255,255,.5),
/// 0 30px 50px -20px rgba(4,18,26,.85)`.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.key2});

  final Widget child;
  final Key? key2;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: key2,
      width: 250 * s,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF6F2E9)],
        ),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: rgba(255, 255, 255, .5), spreadRadius: 1),
          BoxShadow(
            color: rgba(4, 18, 26, .85),
            offset: Offset(0, 30 * s),
            blurRadius: onbBlur(50 * s),
            spreadRadius: -20 * s,
          ),
        ],
      ),
      child: Stack(
        children: [
          child,
          bergenInsetTop(radius: 28 * s, height: 2 * s, alpha: 1),
        ],
      ),
    );
  }
}

/// The 150 px hero: the tint, the `radial-gradient(120% 90% at 30% 10%,
/// rgba(255,255,255,.6), 0 62%)` sheen, the `rgba(60,35,10,.18)` foot, and
/// the art bobbing (`bob 4s ease-in-out infinite`, translateY 0 → −5 → 0).
/// The art's `drop-shadow(0 12px 14px rgba(20,25,30,.45))` is not applied
/// to the moving layer (see the screen ledger).
class _Hero extends StatelessWidget {
  const _Hero({
    required this.tint,
    required this.art,
    required this.artRect,
    required this.children,
  });

  final List<Color> tint;
  final Widget art;

  /// The art's `left/top/width/height` in design px inside the 250×150 hero.
  final Rect artRect;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      height: 150 * s,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: cssLinear(165, tint))),
            CustomPaint(
              painter: _SheenPainter(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 60 * s,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: cssLinear(180, [rgba(60, 35, 10, 0), rgba(60, 35, 10, .18)]),
                ),
              ),
            ),
            Positioned(
              left: artRect.left * s,
              top: artRect.top * s,
              width: artRect.width * s,
              height: artRect.height * s,
              child: FiskeLoop(
                durationMs: 4000,
                child: art,
                builder: (context, p, child) => Transform.translate(
                  offset: Offset(
                    0,
                    kf(p ?? 0, const [0, .5, 1], const [0, -5, 0], Curves.easeInOut) * s,
                  ),
                  child: child,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(.3 * size.width, .1 * size.height);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-.4, -.8),
          radius: 1.2,
          colors: [rgba(255, 255, 255, .6), rgba(255, 255, 255, 0)],
          stops: const [0, .62],
        ).createShader(Rect.fromCenter(
          center: c,
          width: size.width,
          height: size.height * .75,
        )),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => false;
}

/// `Fangst` (design ≈L6540–6565): the catch card.
class FiskeFangstCard extends StatelessWidget {
  const FiskeFangstCard({
    super.key,
    required this.item,
    required this.earned,
    this.onNappTap,
  });

  final FiskeCatch item;

  /// Points this reel earned (the `+5 poeng` coin); 0 hides it.
  final int earned;
  final VoidCallback? onNappTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final art = FiskeArt.of(item.agn);
    return _CardShell(
      key2: const Key('a1_fiske_fangst'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              _Hero(
                tint: art.tint,
                art: bergenSvg(art.asset),
                artRect: Rect.fromLTWH(art.left, art.top, art.width, art.height),
                children: [
                  if (item.napp) ...[
                    Positioned(
                      left: 10 * s,
                      top: 10 * s,
                      child: GestureDetector(
                        key: const Key('a1_fiske_napp_badge'),
                        onTap: onNappTap,
                        child: FiskeOnce(
                          durationMs: 600,
                          builder: (context, p, child) => Transform.scale(
                            scale: kf(p, const [0, .35, .7, 1], const [1, 1.16, .96, 1], kPopp),
                            child: child,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: cssLinear(90, const [Color(0xFF5CE0B8), Color(0xFF9C7BE8)]),
                              boxShadow: [
                                BoxShadow(
                                  color: rgba(92, 224, 184, .8),
                                  offset: Offset(0, 8 * s),
                                  blurRadius: onbBlur(14 * s),
                                  spreadRadius: -6 * s,
                                ),
                              ],
                            ),
                            child: Text(
                              FiskeCopy.a1_fiske_napp,
                              style: bText(context, 10.5, weight: FontWeight.w800, color: const Color(0xFF0F1F2B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6 * s,
                      bottom: 6 * s,
                      width: 58 * s,
                      child: FiskeOnce(
                        durationMs: 600,
                        delayMs: 150,
                        builder: (context, p, child) => Transform.scale(
                          scale: kf(p, const [0, .35, .7, 1], const [1, 1.16, .96, 1], kPopp),
                          child: child,
                        ),
                        child: Image.asset('assets/images/dashboard/shock.png', width: 58 * s),
                      ),
                    ),
                  ],
                  Positioned(
                    top: 10 * s,
                    right: 10 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: rgba(255, 255, 255, .85),
                      ),
                      child: Text(
                        item.bydel ?? FiskeCopy.a1_fiske_bydel_bergen,
                        style: bText(context, 9.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                      ),
                    ),
                  ),
                ],
              ),
              // `+5 poeng`: `top:10;left:10;padding:4px 9px;#0F1F2B;
              // 0 0 0 1.5px #7FF0CB; myntOpp 1.4s .3s ease-out both`.
              if (earned > 0)
                Positioned(
                  top: 10 * s,
                  left: 10 * s,
                  child: FiskeOnce(
                    durationMs: 1400,
                    delayMs: 300,
                    builder: (context, p, child) {
                      final q = Curves.easeOut.transform(p);
                      const st = [0.0, .25, .75, 1.0];
                      return Opacity(
                        opacity: kf(q, st, const [0, 1, 1, 0]),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translate(0.0, kf(q, st, const [6, -14, -20, -30]) * s)
                            ..scale(kf(q, st, const [.6, 1.05, 1, .9])),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: const Key('a1_fiske_plus'),
                      padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFF0F1F2B),
                        boxShadow: const [BoxShadow(color: Color(0xFF7FF0CB), spreadRadius: 1.5)],
                      ),
                      child: Text(
                        FiskeCopy.a1_fiske_plus(earned),
                        style: bText(context, 10, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 12 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bDisplay(context, 16, letterSpacingEm: -.015, height: 1.2, color: const Color(0xFF23201D)),
                ),
                if (item.storeName != null) ...[
                  SizedBox(height: 3 * s),
                  Text(
                    item.storeName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bText(context, 11.5, weight: FontWeight.w600, color: const Color(0xFF57534B)),
                  ),
                ],
                SizedBox(height: 8 * s),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        item.priceKr == null ? '' : '${item.priceKr} kr',
                        style: bDisplay(context, 19, color: const Color(0xFFB9441A)),
                      ),
                    ),
                    Text(
                      item.eta ?? FiskeCopy.a1_fiske_eta_kommer,
                      style: bText(context, 10.5, color: const Color(0xFF6E6862)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The design's `nivMetall` per tier band (Bronse, Sølv, Gull, Platina).
List<Color> fiskeMetal(int band) => switch (band) {
  >= 3 => const [Color(0xFFFFFFFF), Color(0xFFE8EDF0), Color(0xFFAEB9C2), Color(0xFF8C98A3)],
  2 => const [Color(0xFFFFFCF0), Color(0xFFF2D591), Color(0xFFC99B2A)],
  1 => const [Color(0xFFFFFFFF), Color(0xFFDCE3E6), Color(0xFF9AA8AE)],
  _ => const [Color(0xFFF6DCC8), Color(0xFFC98A62), Color(0xFF8E5B38)],
};

/// The prize hero tint per band (design `PREMIER[].tint`, one per band).
List<Color> fiskePrizeTint(int band) => switch (band) {
  >= 3 => const [Color(0xFFDCE9EC), Color(0xFF5C8391)],
  2 => const [Color(0xFFCFE3E8), Color(0xFF6FA3B2)],
  1 => const [Color(0xFFFBE9C4), Color(0xFFE9B76A)],
  _ => const [Color(0xFFDCE9EC), Color(0xFF7FA9B6)],
};

/// `Premiefangst` (design ≈L6566–6598): the prize card.
class FiskePremieCard extends StatelessWidget {
  const FiskePremieCard({
    super.key,
    required this.pick,
    this.balance,
    this.isGoal = false,
  });

  final AegilPick pick;
  final int? balance;
  final bool isGoal;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final prize = pick.prize ?? const <String, dynamic>{};
    final band = (prize['tier_band'] as num?)?.toInt() ?? 0;
    final tier = (prize['tier_name'] as String?) ?? '';
    final type = (prize['type'] as String?) ?? '';
    final (asset, w, h) = switch (type) {
      'delivery' || 'auto' => ('longship3d', 96.0, 50.0),
      'donation' || 'gave' || 'club' => ('varde3d', 58.0, 72.0),
      'food' || 'kode' => ('ico_mat', 74.0, 70.0),
      _ => ('ico_gaver', 70.0, 74.0),
    };
    final metal = fiskeMetal(band);
    final price = pick.pointPrice;
    return _CardShell(
      key2: const Key('a1_fiske_premiefangst'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              _Hero(
                tint: fiskePrizeTint(band),
                // `left:50%;top:50%;translate(-50%,-46%)`.
                art: bergenSvg(asset),
                artRect: Rect.fromLTWH(125 - w / 2, 75 - h * .46, w, h),
                children: [
                  if (tier.isNotEmpty)
                    Positioned(
                      top: 8 * s,
                      right: 10 * s,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(3 * s, 3 * s, 8 * s, 3 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: rgba(255, 255, 255, .9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16 * s,
                              height: 16 * s,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-.32, -.48),
                                  radius: .9,
                                  colors: metal,
                                ),
                                boxShadow: [BoxShadow(color: rgba(255, 255, 255, .8), spreadRadius: 1)],
                              ),
                            ),
                            SizedBox(width: 5 * s),
                            Text(
                              tier,
                              style: bText(context, 9.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                top: 10 * s,
                left: 10 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFF0F1F2B),
                  ),
                  child: Text(
                    FiskeCopy.a1_fiske_fra_hylla,
                    style: bText(context, 10, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 12 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pick.prizeName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bDisplay(context, 16, letterSpacingEm: -.015, height: 1.2, color: const Color(0xFF23201D)),
                ),
                if (price != null) ...[
                  SizedBox(height: 5 * s),
                  Text(
                    balance == null
                        ? FiskeCopy.a1_fiske_poeng(fiskeNfp(price))
                        : FiskeCopy.a1_fiske_poeng_har(fiskeNfp(price), fiskeNfp(balance!)),
                    style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFFB9441A)),
                  ),
                ],
                SizedBox(height: 4 * s),
                Text(
                  (prize['line'] as String?) ?? pick.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bText(context, 11, weight: FontWeight.w600, height: 1.4, color: const Color(0xFF57534B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `fiskeFerdig` (design ≈L6599–6608): the end card when the deck is empty.
class FiskeFerdigCard extends StatelessWidget {
  const FiskeFerdigCard({
    super.key,
    required this.lagret,
    required this.kjopt,
    required this.onSeLagret,
    required this.onIgjen,
  });

  final int lagret;
  final int kjopt;
  final VoidCallback onSeLagret;
  final VoidCallback onIgjen;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return FiskeOnce(
      durationMs: 500,
      builder: (context, p, child) {
        final q = kKortInn.transform(p);
        return Opacity(
          opacity: q.clamp(0, 1),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, 140 * (1 - q) * s)
              ..scale(.86 + .14 * q),
            child: child,
          ),
        );
      },
      child: Container(
        key: const Key('a1_fiske_ferdig'),
        padding: EdgeInsets.all(18 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28 * s),
          color: rgba(255, 255, 255, .88),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: rgba(10, 30, 40, .7),
              offset: Offset(0, 30 * s),
              blurRadius: onbBlur(50 * s),
              spreadRadius: -20 * s,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FiskeLoop(
              durationMs: 3400,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24 * s),
                child: Container(
                  width: 88 * s,
                  height: 88 * s,
                  color: const Color(0xFFEAF2F4),
                  child: Image.asset('assets/images/dashboard/noresto.png', fit: BoxFit.cover),
                ),
              ),
              builder: (context, p, child) => Transform.translate(
                offset: Offset(0, kf(p ?? 0, const [0, .5, 1], const [0, -2.5, 0], Curves.easeInOut) * s),
                child: child,
              ),
            ),
            SizedBox(height: 12 * s),
            Text(
              FiskeCopy.a1_fiske_ferdig_title,
              textAlign: TextAlign.center,
              style: bDisplay(context, 18, letterSpacingEm: -.02, color: const Color(0xFF23201D)),
            ),
            SizedBox(height: 4 * s),
            Text(
              FiskeCopy.a1_fiske_ferdig_line(lagret, kjopt),
              textAlign: TextAlign.center,
              style: bText(context, 12, weight: FontWeight.w600, height: 1.45, color: const Color(0xFF57534B)),
            ),
            SizedBox(height: 14 * s),
            OnbPressable(
              onTap: onSeLagret,
              pressScale: .97,
              child: Container(
                key: const Key('a1_fiske_se_lagret'),
                height: 46 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF1E4F5C),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(30, 79, 92, .7),
                      offset: Offset(0, 12 * s),
                      blurRadius: onbBlur(22 * s),
                      spreadRadius: -10 * s,
                    ),
                  ],
                ),
                child: Text(FiskeCopy.a1_fiske_se_lagret, style: bText(context, 13.5, weight: FontWeight.w800)),
              ),
            ),
            SizedBox(height: 8 * s),
            OnbPressable(
              onTap: onIgjen,
              pressScale: .97,
              child: Container(
                key: const Key('a1_fiske_igjen'),
                height: 42 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: rgba(30, 79, 92, .08),
                ),
                child: Text(
                  FiskeCopy.a1_fiske_i_morgen,
                  style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFF1E4F5C)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
