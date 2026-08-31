import 'package:flutter/material.dart';

/// Which Family A surface is being painted.
///
/// Family A is one *ramp* set with two *surface scales*. The hero is
/// consistently brighter and its drop larger:
///
/// | tone | home inset | hero inset |
/// |---|---|---|
/// | bronse | .55 | .60 |
/// | solv | .75 | .85 |
/// | gull | .60 | .75 |
/// | platina | .75 | .85 |
///
/// A single multiplier cannot express this — the delta is +0.05 on bronse but
/// +0.15 on gull — so the alpha is stored per tone per surface.
enum AeMetalSurfaceScale {
  /// `M_SHADOW` — home's `DGPointsCard`. Drop `0 14px 26px -16px`.
  home,

  /// `.lb-level.metal-*` — the Dine poeng hero. Drop `0 18px 36px -16px`.
  hero,
}

/// **Family A — the "hero" metal surface.**
///
/// `.lb-level.metal-*` (dugnad.css:2262–2296) and `M_BG`/`M_SHADOW` in
/// club-select.jsx are the *same* ramp set — `.lb-level.metal-bronse` is
/// byte-identical to `M_BG.bronze`. They differ only in drop-shadow size, so
/// this is one family with a scale knob, not two.
///
/// A tone is **not** a ramp plus a shadow. Each carries ten tone-keyed tokens,
/// and the two stacked radial overlays are what make the surface read as *lit
/// metal* rather than a flat linear ramp: a bright specular off the top-right
/// and a warm bounce from the bottom-left. Port the ramp without them and the
/// result looks like coloured plastic no matter how exact the hex values are.
///
/// Distinct from Family B (`.dg-points-card` / `.pc-rating-hero`), which is a
/// paler 150deg two-stop ramp with a 1.5px toned border. **Family A has no
/// border.** See `PointsMetalTheme.cardGradientForMetal` for Family B.
@immutable
class AeMetalHeroTokens {
  /// `.lb-level.metal-* { color: … }`
  final Color text;

  /// `background: linear-gradient(135deg, c0 0%, c1 48%, c2 100%)`.
  /// The 48% midpoint is what gives the ramp its metallic turn — a two-stop
  /// gradient with no explicit stops looks plastic.
  final List<Color> ramp;

  /// `box-shadow: … inset` — the white top-edge highlight, per surface.
  /// Flutter has no inset shadow, so this is painted as an edge gradient (see
  /// [AeMetalHeroSurface]).
  final Color insetHighlightHome;
  final Color insetHighlightHero;

  /// The inset highlight for [scale].
  Color insetFor(AeMetalSurfaceScale scale) =>
      scale == AeMetalSurfaceScale.hero
          ? insetHighlightHero
          : insetHighlightHome;

  /// The outer, tone-tinted drop: `0 18px 36px -16px <tint>` on the hero,
  /// `0 14px 26px -16px <tint>` on home.
  final Color dropTint;

  /// `.lb-level-bg` first layer — `radial-gradient(150px 130px at 88% -25%, …)`
  final Color specular;

  /// `.lb-level-bg` second layer — `radial-gradient(130px 120px at 2% 130%, …)`
  final Color bounce;

  /// `.badge`
  final Color badgeBg, badgeBorder, badgeText;

  /// `.lb-level-prog` track and `> span` fill (a 90deg two-stop).
  final Color progTrack;
  final List<Color> progFill;

  /// `.lb-level-foot .steps em` / `em.on`
  final Color stepOff, stepOn;

  /// `.lb-level-shine` override — **platina only**; a four-stop holographic
  /// band with a purple pass. Null for every other tone.
  final LinearGradient? shine;

  const AeMetalHeroTokens({
    required this.text,
    required this.ramp,
    required this.insetHighlightHome,
    required this.insetHighlightHero,
    required this.dropTint,
    required this.specular,
    required this.bounce,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeText,
    required this.progTrack,
    required this.progFill,
    required this.stepOff,
    required this.stepOn,
    this.shine,
  });

  /// `linear-gradient(135deg, …)` → topLeft → bottomRight, stops [0, .48, 1].
  LinearGradient get background => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: ramp,
        stops: const [0.0, 0.48, 1.0],
      );

  /// `linear-gradient(90deg, …)` → centreLeft → centreRight.
  LinearGradient get progressFill => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: progFill,
      );

  static const _bronse = AeMetalHeroTokens(
    text: Color(0xFF43260F),
    ramp: [Color(0xFFF1CDA1), Color(0xFFDCA06B), Color(0xFFBD7D44)],
    insetHighlightHome: Color(0x8CFFFFFF), // .55 / .60
    insetHighlightHero: Color(0x99FFFFFF),
    dropTint: Color(0xA69D5F30), // rgba(157,95,48,.65)
    specular: Color(0x73FFFFFF), // rgba(255,255,255,.45)
    bounce: Color(0x47B46E37), // rgba(180,110,55,.28)
    badgeBg: Color(0x249D5F30),
    badgeBorder: Color(0x479D5F30),
    badgeText: Color(0xFF9D5F30),
    // Track alpha raised from design .18 — too faint on the metal ramp.
    progTrack: Color(0x7378461E),
    progFill: [Color(0xFFE6A877), Color(0xFFB06F3D)],
    stepOff: Color(0x4778461E),
    stepOn: Color(0xFFB06F3D),
  );

  static const _solv = AeMetalHeroTokens(
    text: Color(0xFF3F4A57),
    ramp: [Color(0xFFF6F8FB), Color(0xFFDCE2EA), Color(0xFFC2CBD6)],
    insetHighlightHome: Color(0xBFFFFFFF), // .75 / .85
    insetHighlightHero: Color(0xD9FFFFFF),
    dropTint: Color(0x997A8694), // rgba(122,134,148,.6)
    specular: Color(0x99FFFFFF), // .6
    bounce: Color(0x47788696), // rgba(120,134,150,.28)
    badgeBg: Color(0x296E7A8A),
    badgeBorder: Color(0x4D6E7A8A),
    badgeText: Color(0xFF5D6B7A),
    // Track alpha raised from design .20 — silver ramp washed it out.
    progTrack: Color(0x805A6674),
    progFill: [Color(0xFFAEB8C4), Color(0xFF7C8896)],
    stepOff: Color(0x4D5A6674),
    stepOn: Color(0xFF7C8896),
  );

  static const _gull = AeMetalHeroTokens(
    text: Color(0xFF2A1D08),
    ramp: [Color(0xFFFFE9A8), Color(0xFFF6CF6B), Color(0xFFE7B542)],
    insetHighlightHome: Color(0x99FFFFFF), // .60 / .75
    insetHighlightHero: Color(0xBFFFFFFF),
    dropTint: Color(0xB3D8A028), // rgba(216,160,40,.7)
    specular: Color(0x8CFFFFFF), // .55
    bounce: Color(0x4DD2A028), // rgba(210,160,40,.3)
    badgeBg: Color(0x2EC89421),
    badgeBorder: Color(0x52C89421),
    badgeText: Color(0xFF9A6B12),
    progTrack: Color(0x73966914),
    progFill: [Color(0xFFF3D57A), Color(0xFFD8A92E)],
    stepOff: Color(0x4D966914),
    stepOn: Color(0xFFD8A92E),
  );

  static const _platina = AeMetalHeroTokens(
    text: Color(0xFF38426B),
    ramp: [Color(0xFFEFF3FB), Color(0xFFD7E0F1), Color(0xFFBCCAE2)],
    insetHighlightHome: Color(0xBFFFFFFF), // .75 / .85
    insetHighlightHero: Color(0xD9FFFFFF),
    dropTint: Color(0x998D9CC6), // rgba(141,156,198,.6)
    specular: Color(0x337F5FC4), // rgba(127,95,196,.2) — purple, not white
    bounce: Color(0x8096B9EB), // rgba(150,185,235,.5)
    badgeBg: Color(0x247F5FC4),
    badgeBorder: Color(0x427F5FC4),
    badgeText: Color(0xFF6B4FA8),
    progTrack: Color(0x73504678),
    progFill: [Color(0xFFA78FDE), Color(0xFF7F5FC4)],
    stepOff: Color(0x47504678),
    stepOn: Color(0xFF7F5FC4),
    // .lb-level.metal-platina .lb-level-shine — the holographic override.
    shine: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x00FFFFFF),
        Color(0xD9FFFFFF),
        Color(0x73AA96E6),
        Color(0x00FFFFFF),
      ],
      stops: [0.16, 0.44, 0.60, 0.84],
    ),
  );

  static AeMetalHeroTokens forMetal(String metal) {
    switch (metal) {
      case 'solv':
        return _solv;
      case 'gull':
        return _gull;
      case 'platina':
        return _platina;
      case 'bronse':
      default:
        return _bronse;
    }
  }
}
