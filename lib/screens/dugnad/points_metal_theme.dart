import 'package:flutter/material.dart';

import 'metal_hero_tokens.dart';

import '../../theme/sc_saas_theme.dart';
import 'dugnad_state.dart';

class SeasonMetalCardStyle {
  final List<Color> gradient;
  final Color textColor;

  const SeasonMetalCardStyle({
    required this.gradient,
    required this.textColor,
  });
}

/// Metal-tier visual theming.
///
/// Colours are driven by admin config: when a backend colour is registered for
/// a metal via [applyColorOverrides], EVERY visual (emblem, ladder, pillar,
/// gradients, progress bars) is derived from that base colour. When no override
/// exists, the built-in per-metal palette below is used so the default look is
/// unchanged.
class PointsMetalTheme {
  PointsMetalTheme._();
  static final Map<String, Color> _runtimeMetalColors = {};

  static void applyColorOverrides(Map<String, String> metalHexByKey) {
    _runtimeMetalColors.clear();
    metalHexByKey.forEach((key, hex) {
      final parsed = _parseHexColor(hex);
      if (parsed != null && key.trim().isNotEmpty) {
        _runtimeMetalColors[key.trim().toLowerCase()] = parsed;
      }
    });
  }

  static Color? _override(String metal) =>
      _runtimeMetalColors[metal.toLowerCase()];

  static Color? _parseHexColor(String? hex) {
    if (hex == null) return null;
    final raw = hex.trim();
    if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(raw)) return null;
    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static Color _lighten(Color base, double amount) =>
      Color.lerp(base, Colors.white, amount) ?? base;

  static Color _darken(Color base, double amount) =>
      Color.lerp(base, Colors.black, amount) ?? base;

  static Color _withLightness(
    Color base,
    double lightness, {
    double? saturation,
  }) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation(
          (saturation ?? hsl.saturation).clamp(0.0, 1.0),
        )
        .toColor();
  }

  /// How strongly an admin hex tints the authored Family A ramp stops.
  ///
  /// The baked ramps (`.lb-level.metal-*`) are matte metal — light gold, mid
  /// gold, deep gold — NOT white washed to the admin colour. We preserve that
  /// stop spread and only tint toward the backend hex.
  static double _familyATintAmount(String metal) {
    switch (metal) {
      case 'solv':
        // Keep silver neutral/metallic; high tint makes it look slate.
        return 0.22;
      case 'gull':
        return 0.35;
      case 'platina':
        return 0.42;
      case 'bronse':
      default:
        return 0.38;
    }
  }

  static Color _tintTowardAdmin(Color base, Color admin, String metal) {
    return Color.lerp(base, admin, _familyATintAmount(metal)) ?? base;
  }

  static List<Color> _tintRampTowardAdmin(
    List<Color> ramp,
    Color admin,
    String metal,
  ) {
    return ramp.map((c) => _tintTowardAdmin(c, admin, metal)).toList();
  }

  static Color _tintAlphaColor(Color base, Color admin, String metal) {
    final tinted = _tintTowardAdmin(base.withValues(alpha: 1.0), admin, metal);
    return tinted.withValues(alpha: base.a);
  }

  static bool _isLight(Color c) => c.computeLuminance() > 0.6;

  static Color _fallbackMetalColor(String metal) {
    switch (metal) {
      case 'solv':
        return const Color(0xFF707C8E);
      case 'gull':
        return const Color(0xFFC8942E);
      case 'platina':
        return const Color(0xFF8D9CC7);
      case 'bronse':
      default:
        return const Color(0xFFA46321);
    }
  }

  static Color colorForMetal(String metal) {
    return _override(metal) ?? _fallbackMetalColor(metal);
  }

  /// Prototype `DG_STO_CHIP` — soft metal-tint chips for STØ badges.
  ///
  /// When admin registers a hex via [applyColorOverrides], the chip is derived
  /// from that base so snitt-STØ / list chips stay in sync with other metal UI.
  static ({Color bg, Color fg}) stoChipColors(String metal) {
    final key = metal.trim().toLowerCase();
    final o = _override(key);
    if (o != null) {
      return (bg: _lighten(o, 0.82), fg: _darken(o, 0.42));
    }
    switch (key) {
      case 'platina':
        return (bg: const Color(0xFFEEF2FB), fg: const Color(0xFF38426B));
      case 'gull':
        return (bg: const Color(0xFFFBF1D8), fg: const Color(0xFF7A5A12));
      case 'solv':
        return (bg: const Color(0xFFEEF1F5), fg: const Color(0xFF3F4A57));
      case 'bronse':
      default:
        return (bg: const Color(0xFFF4E6D6), fg: const Color(0xFF7A4A1F));
    }
  }

  /// T16 STØ-rise disc — prototype `.dgcp-rating.m-*` (`--m1`, `--m2`, `--mi`).
  ///
  /// Distinct from Family A (Dine poeng hero) and Family B (pale points card):
  /// this is the celebration coin. Admin hex overrides keep the same light/dark
  /// spread as the baked stops.
  static ({Color m1, Color m2, Color ink}) stoRiseDisc(String metal) {
    final key = metal.trim().toLowerCase();
    final o = _override(key);
    if (o != null) {
      final sat = HSLColor.fromColor(o).saturation.clamp(0.28, 0.55);
      return (
        m1: _withLightness(o, 0.84, saturation: sat),
        m2: _withLightness(o, 0.52, saturation: sat),
        ink: stoChipColors(key).fg,
      );
    }
    switch (key) {
      case 'solv':
        return (
          m1: const Color(0xFFEEF1F5),
          m2: const Color(0xFFB4BDC9),
          ink: const Color(0xFF3F4A57),
        );
      case 'gull':
        return (
          m1: const Color(0xFFF9E7AE),
          m2: const Color(0xFFD9A72F),
          ink: const Color(0xFF7A5A12),
        );
      case 'platina':
        return (
          m1: const Color(0xFFEAF0FB),
          m2: const Color(0xFFA9B6D8),
          ink: const Color(0xFF38426B),
        );
      case 'bronse':
      default:
        return (
          m1: const Color(0xFFF0D5BA),
          m2: const Color(0xFFC08A4E),
          ink: const Color(0xFF7A4A1F),
        );
    }
  }

  static List<Color> gradientForMetal(String metal) {
    final base = colorForMetal(metal);
    return [
      _lighten(base, 0.55),
      _darken(base, 0.10),
    ];
  }

  /// Archived season card (`.dg-seasoncard.metal-*`) — uses admin metal colour.
  /// `.dg-seasoncard.metal-*` is **Family A** -- byte-identical to
  /// `.lb-level`, `M_BG`, `.dg-playercard` and the ladder step. It was being
  /// derived by lightening and darkening a base colour instead, which lands
  /// near the real ramp without matching it. Sixth surface in the family, and
  /// the second time the ramp has been synthesised rather than used.
  ///
  /// The derivation is kept for club overrides, where there is no authored
  /// ramp to consume.
  static SeasonMetalCardStyle seasonCardForMetal(String metal) {
    final base = colorForMetal(metal);
    final text = _darken(base, 0.38);

    if (_override(metal) == null) {
      return SeasonMetalCardStyle(
        gradient: familyATokens(metal).ramp,
        textColor: text,
      );
    }

    return SeasonMetalCardStyle(
      gradient: pcEntryMetalGradient(metal),
      textColor: levelHeroForegroundColor(metal),
    );
  }

  /// Points-surface background — the PALE metal card (`.dg-points-card.metal-*`
  /// and `.pc-rating-hero.metal-*`, both `linear-gradient(150deg, …)`). These
  /// are hand-tuned light stops on a near-white card, NOT derived from the base
  /// (a single-base lerp cannot reproduce the design's two chosen stops). When
  /// an admin override exists we fall back to the base-derived pale gradient.
  static List<Color> cardGradientForMetal(String metal) {
    final o = _override(metal);
    if (o != null) {
      final hsl = HSLColor.fromColor(o);
      final sat = hsl.saturation.clamp(0.26, 0.55);
      return [
        _withLightness(o, 0.92, saturation: sat),
        _withLightness(o, 0.76, saturation: sat),
      ];
    }
    switch (metal) {
      case 'solv':
        return const [Color(0xFFEFF3F7), Color(0xFFCDD6E0)];
      case 'gull':
        return const [Color(0xFFFDF2CB), Color(0xFFF3DB92)];
      case 'platina':
        return const [Color(0xFFEEF2FB), Color(0xFFD1DBEF)];
      case 'bronse':
      default:
        return const [Color(0xFFFBEADA), Color(0xFFF0D0AA)];
    }
  }

  /// Points-surface border (`.dg-points-card.metal-*` `border-color`).
  static Color cardBorderForMetal(String metal) {
    final o = _override(metal);
    if (o != null) {
      final sat = HSLColor.fromColor(o).saturation.clamp(0.24, 0.5);
      return _withLightness(o, 0.68, saturation: sat);
    }
    switch (metal) {
      case 'solv':
        return const Color(0xFFAEB9C6);
      case 'gull':
        return const Color(0xFFE0BD4A);
      case 'platina':
        return const Color(0xFFB8C5E0);
      case 'bronse':
      default:
        return const Color(0xFFD6AB7E);
    }
  }

  /// Square badge on Dine poeng hero (`.lb-level .badge`).
  static BoxDecoration levelHeroBadgeDecoration(String metal) {
    final o = _override(metal);
    Color bg;
    Color border;
    if (o != null) {
      bg = o.withValues(alpha: 0.16);
      border = o.withValues(alpha: 0.30);
    } else {
      switch (metal) {
        case 'solv':
          bg = const Color(0x29106E7A);
          border = const Color(0x4D6E7A8A);
          break;
        case 'gull':
          bg = const Color(0x2EC89421);
          border = const Color(0x52C89421);
          break;
        case 'platina':
          bg = const Color(0x247F5FC4);
          border = const Color(0x427F5FC4);
          break;
        case 'bronse':
        default:
          bg = const Color(0x249D5F30);
          border = const Color(0x479D5F30);
      }
    }
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border),
    );
  }

  /// Foreground text on `.lb-level` hero (metal-specific).
  static Color levelHeroForegroundColor(String metal) {
    final o = _override(metal);
    if (o != null) {
      final baked = AeMetalHeroTokens.forMetal(metal).text;
      return Color.lerp(baked, _darken(o, 0.40), 0.30) ?? baked;
    }
    switch (metal) {
      case 'solv':
        return const Color(0xFF3F4A57);
      case 'gull':
        return const Color(0xFF2A1D08);
      case 'platina':
        return const Color(0xFF38426B);
      case 'bronse':
      default:
        return const Color(0xFF43260F);
    }
  }

  static Color levelHeroBadgeIconColor(String metal) {
    final o = _override(metal);
    if (o != null) {
      final baked = AeMetalHeroTokens.forMetal(metal).badgeText;
      return _tintTowardAdmin(baked, o, metal);
    }
    switch (metal) {
      case 'solv':
        return const Color(0xFF5D6B7A);
      case 'gull':
        return const Color(0xFF9A6B12);
      case 'platina':
        return const Color(0xFF6B4FA8);
      case 'bronse':
      default:
        return const Color(0xFF9D5F30);
    }
  }

  /// Shared PALE points-surface shell — home anchor card + profile points card
  /// + Dine poeng hero (prototype `.dg-points-card.metal-*`, `border-radius:18`,
  /// `150deg` light gradient, `1.5px` metal border, and the dual shadow
  /// `0 2px 4px rgba(45,27,91,.05), 0 16px 30px -16px rgba(<metal>,.55)`).
  static BoxDecoration pointsCardDecoration(
    String metal, {
    double radius = 18,
  }) {
    return BoxDecoration(
      // 150° ≈ top → bottom-right (matches CSS `linear-gradient(150deg, …)`).
      gradient: LinearGradient(
        begin: const Alignment(-0.5, -0.87),
        end: const Alignment(0.5, 0.87),
        colors: cardGradientForMetal(metal),
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorderForMetal(metal), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: ScSaasThemeTokens.text.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: colorForMetal(metal).withValues(alpha: 0.55),
          blurRadius: 30,
          offset: const Offset(0, 16),
          spreadRadius: -16,
        ),
      ],
    );
  }

  /// Vivid collectible STØ card shell (`.dg-playercard.lvl-*`).
  ///
  /// Unlike [pointsCardDecoration] (the pale points *surface*), this is the
  /// saturated 3-stop 135° metal gradient with no border and a coloured drop
  /// glow — matching the prototype FIFA card. The crisp inset top highlight
  /// (`0 1px 1px rgba(255,255,255,.75) inset`) is supplied by the ambient
  /// glaze layer stacked over this decoration.
  static BoxDecoration playerCardDecoration(String metal, {double radius = 24}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: pcEntryMetalGradient(metal),
        stops: pcEntryMetalGradientStops,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: pcEntryShadowColor(metal)
              .withValues(alpha: playerCardShadowAlpha(metal)),
          blurRadius: 38,
          offset: const Offset(0, 20),
          spreadRadius: -18,
        ),
      ],
    );
  }

  static Color bannerBackground(String metal) {
    final o = _override(metal);
    if (o != null) return _lighten(o, 0.9);
    switch (metal) {
      case 'solv':
        return const Color(0xFFEFF3F7);
      case 'gull':
        return const Color(0xFFFFF8E7);
      case 'platina':
        return const Color(0xFFEEF2FF);
      case 'bronse':
      default:
        return DugnadState.instance.themePalette.primaryTint;
    }
  }

  /// Inner core fill for the 3D star emblem.
  static List<Color> emblemCoreGradient(String metal) {
    final o = _override(metal);
    if (o != null) return [_lighten(o, 0.86), _lighten(o, 0.5)];
    switch (metal) {
      case 'solv':
        return const [Color(0xFFFBFCFE), Color(0xFFDDE3EA)];
      case 'gull':
        return const [Color(0xFFFFF4D6), Color(0xFFF3CD72)];
      case 'platina':
        return const [Color(0xFFF5F8FD), Color(0xFFDCE4F3)];
      case 'bronse':
      default:
        return const [Color(0xFFFBF0DA), Color(0xFFE7C39C)];
    }
  }

  static Color emblemStarColor(String metal) {
    final o = _override(metal);
    if (o != null) return _darken(o, 0.22);
    switch (metal) {
      case 'solv':
        return const Color(0xFF5B6470);
      case 'gull':
        return const Color(0xFF9A6B12);
      case 'platina':
        return const Color(0xFF495680);
      case 'bronse':
      default:
        return const Color(0xFF8A4E22);
    }
  }

  static Color levelProgressTrack(String metal) {
    final baked = AeMetalHeroTokens.forMetal(metal).progTrack;
    final o = _override(metal);
    if (o != null) {
      return _tintAlphaColor(baked, o, metal);
    }
    return baked;
  }

  static List<Color> levelProgressFill(String metal) {
    final o = _override(metal);
    if (o != null) {
      return _tintRampTowardAdmin(
        AeMetalHeroTokens.forMetal(metal).progFill,
        o,
        metal,
      );
    }
    switch (metal) {
      case 'solv':
        return const [Color(0xFFAEB8C4), Color(0xFF7C8896)];
      case 'gull':
        return const [Color(0xFFF3D57A), Color(0xFFD8A92E)];
      case 'platina':
        return const [Color(0xFFA78FDE), Color(0xFF7F5FC4)];
      case 'bronse':
      default:
        return const [Color(0xFFE6A877), Color(0xFFB06F3D)];
    }
  }

  static Color levelStepDot(String metal, {required bool active}) {
    if (active) return levelProgressFill(metal).last;
    final o = _override(metal);
    if (o != null) return o.withValues(alpha: 0.3);
    switch (metal) {
      case 'solv':
        return const Color(0x4D5A6674);
      case 'gull':
        return const Color(0x4D966914);
      case 'platina':
        return const Color(0x47504678);
      case 'bronse':
      default:
        return const Color(0x4778461E);
    }
  }

  /// `.dg-pc-entry.metal-*` — STØ card pillar strip (3-stop 135°).
  static List<Color> pcEntryMetalGradient(String metal) {
    final o = _override(metal);
    if (o != null) {
      return _tintRampTowardAdmin(
        AeMetalHeroTokens.forMetal(metal).ramp,
        o,
        metal,
      );
    }
    switch (metal) {
      case 'solv':
        return const [Color(0xFFF6F8FB), Color(0xFFDCE2EA), Color(0xFFC2CBD6)];
      case 'gull':
        return const [Color(0xFFFFE9A8), Color(0xFFF6CF6B), Color(0xFFE7B542)];
      case 'platina':
        return const [Color(0xFFEFF3FB), Color(0xFFD7E0F1), Color(0xFFBCCAE2)];
      case 'bronse':
      default:
        return const [Color(0xFFF1CDA1), Color(0xFFDCA06B), Color(0xFFBD7D44)];
    }
  }

  /// Family A tokens for home / profile / Dine-poeng hero surfaces.
  ///
  /// When admin registers a metal colour via [applyColorOverrides], every
  /// Family A consumer (home card, profile card, `.lb-level`) shares the same
  /// derived ramp — no more "dark on home, faint on profile".
  static AeMetalHeroTokens familyATokens(String metal) {
    final baked = AeMetalHeroTokens.forMetal(metal);
    final o = _override(metal);
    if (o == null) return baked;

    final ramp = pcEntryMetalGradient(metal);
    final shadow = pcEntryShadowColor(metal);

    return AeMetalHeroTokens(
      text: levelHeroForegroundColor(metal),
      ramp: ramp,
      insetHighlightHome: baked.insetHighlightHome,
      insetHighlightHero: baked.insetHighlightHero,
      dropTint: shadow.withValues(alpha: 0.65),
      specular: baked.specular,
      bounce: baked.bounce,
      badgeBg: _tintAlphaColor(baked.badgeBg, o, metal),
      badgeBorder: _tintAlphaColor(baked.badgeBorder, o, metal),
      badgeText: _tintTowardAdmin(baked.badgeText, o, metal),
      progTrack: _tintAlphaColor(baked.progTrack, o, metal),
      progFill: _tintRampTowardAdmin(baked.progFill, o, metal),
      stepOff: _tintAlphaColor(baked.stepOff, o, metal),
      stepOn: _tintTowardAdmin(baked.stepOn, o, metal),
      shine: baked.shine,
    );
  }

  static const List<double> pcEntryMetalGradientStops = [0.0, 0.48, 1.0];

  static Color pcEntryShadowColor(String metal) {
    final o = _override(metal);
    if (o != null) {
      final baked = switch (metal) {
        'solv' => const Color(0xFF7A8694),
        'gull' => const Color(0xFFD8A028),
        'platina' => const Color(0xFF8D9CC7),
        _ => const Color(0xFF9D5F30),
      };
      return _tintTowardAdmin(baked, o, metal);
    }
    switch (metal) {
      case 'solv':
        return const Color(0xFF7A8694);
      case 'gull':
        return const Color(0xFFD8A028);
      case 'platina':
        return const Color(0xFF8D9CC7);
      case 'bronse':
      default:
        return const Color(0xFF9D5F30);
    }
  }

  /// `.lb-ladder .step.metal-*.on|done` — vivid metal fill from mock.
  static List<Color> ladderStepMetalGradient(String metal) {
    final o = _override(metal);
    if (o != null) {
      return pcEntryMetalGradient(metal);
    }
    switch (metal) {
      case 'solv':
        return const [Color(0xFFF6F8FB), Color(0xFFDCE2EA), Color(0xFFC2CBD6)];
      case 'gull':
        return const [Color(0xFFFFE9A8), Color(0xFFF6CF6B), Color(0xFFE7B542)];
      case 'platina':
        return const [Color(0xFFEFF3FB), Color(0xFFD7E0F1), Color(0xFFBCCAE2)];
      case 'bronse':
      default:
        return const [Color(0xFFF1CDA1), Color(0xFFDCA06B), Color(0xFFBD7D44)];
    }
  }

  /// Softer fallback (unused on ladder when done/on).
  static List<Color> ladderStepGradient(String metal) {
    final baked = switch (metal) {
      'solv' => const [Color(0xFFF7F9FC), Color(0xFFDFE5EC)],
      'gull' => const [Color(0xFFFDF6DA), Color(0xFFF6E2A2)],
      'platina' => const [Color(0xFFF1F4FC), Color(0xFFDAE1F3)],
      _ => const [Color(0xFFFBEEE2), Color(0xFFF1D8BF)],
    };
    final o = _override(metal);
    if (o != null) {
      return _tintRampTowardAdmin(baked, o, metal);
    }
    return baked;
  }

  static Color ladderStepBorder(String metal) {
    final baked = switch (metal) {
      'solv' => const Color(0xFFBCC6D1),
      'gull' => const Color(0xFFE6C558),
      'platina' => const Color(0xFFC3CDE6),
      _ => const Color(0xFFDCB78F),
    };
    final o = _override(metal);
    if (o != null) {
      return _tintTowardAdmin(baked, o, metal);
    }
    return baked;
  }

  /// Inset chips on supporter card (crest, avatar, badge row) — matches `.pc-crest` / `.pc-avatar`.
  /// `.dg-playercard`'s `0 1px 1px rgba(255,255,255,a) inset`.
  ///
  /// White on **every** tone -- the app returned a dark 0x1A3C485F for solv
  /// and platina, which is the opposite of a highlight -- and the alpha is
  /// per tone, not one value: .75 / .6 / .85 / .85. The two pale tones carry
  /// the strongest highlight, which is why flattening it was visible as a
  /// dulled card rather than a wrong colour.
  static Color playerCardInset(String metal) {
    final o = _override(metal);
    if (o != null) {
      return Colors.white.withValues(alpha: _isLight(o) ? 0.85 : 0.6);
    }
    switch (metal) {
      case 'gull':
        return Colors.white.withValues(alpha: 0.75);
      case 'solv':
      case 'platina':
        return Colors.white.withValues(alpha: 0.85);
      case 'bronse':
      default:
        return Colors.white.withValues(alpha: 0.6);
    }
  }

  /// `.dg-playercard`'s drop alpha, per tone: `0 20px 38px -18px` at
  /// .7 / .65 / .6 / .6. The tints were already byte-exact; only the alpha
  /// had been collapsed to a single 0.7 (rule 20).
  static double playerCardShadowAlpha(String metal) {
    switch (metal) {
      case 'gull':
        return 0.7;
      case 'bronse':
        return 0.65;
      case 'solv':
      case 'platina':
      default:
        return 0.6;
    }
  }

  /// Striped metal progress fill (`.pc-rating-hero .pc-rating-track > span`).
  static Widget metalProgressBar({
    required String metal,
    required int progressPercent,
    double height = 6,
  }) {
    final pct = progressPercent.clamp(0, 100);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: levelProgressTrack(metal).withValues(alpha: 0.55),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct / 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: levelProgressFill(metal),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _MetalProgressStripePainter(
                      stripeColor: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Divider above stats row on supporter card.
  static Color playerCardDivider(String metal) {
    final baked = switch (metal) {
      'solv' || 'platina' => const Color(0x33465264),
      'gull' => const Color(0x3878500A),
      _ => const Color(0x3878281C),
    };
    final o = _override(metal);
    if (o != null) {
      return _tintAlphaColor(baked, o, metal);
    }
    return baked;
  }
}

class _MetalProgressStripePainter extends CustomPainter {
  _MetalProgressStripePainter({required this.stripeColor});

  final Color stripeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = stripeColor;
    const cell = 14.0;
    final diagonal = size.height + size.width;
    for (var offset = -diagonal; offset < diagonal; offset += cell) {
      final path = Path()
        ..moveTo(offset, size.height)
        ..lineTo(offset + size.height, 0)
        ..lineTo(offset + size.height + cell * 0.5, 0)
        ..lineTo(offset + cell * 0.5, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MetalProgressStripePainter oldDelegate) {
    return oldDelegate.stripeColor != stripeColor;
  }
}
