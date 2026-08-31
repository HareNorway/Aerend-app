import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sc_saas_theme.dart';

/// Fixed px sizes from Ærend `colors_and_type.css` (375px reference frame).
abstract final class AeFontSize {
  static const double display = 30;
  static const double h1 = 26;
  static const double h2 = 22;
  static const double h3 = 17;
  static const double title = 15;
  static const double titleMd = 15.5;
  static const double titleLg = 16;
  static const double body = 15;
  static const double label = 14;
  static const double labelMd = 14.5;
  static const double caption = 12;
  static const double captionSm = 11.5;
  static const double overline = 10.5;
  static const double micro = 10;
  static const double tiny = 9.5;
  static const double heroTitle = 25;
  static const double heroSub = 12.5;
  static const double clubHeroName = 21;
  static const double statNum = 20;
  static const double statKr = 13;
  static const double refCode = 28;
  static const double pointsAmt = 22;
}

/// Layout tokens from `h-feed`, `.dn-feed`, `.dg-quick` (375px frame).
abstract final class AeDugnadSpace {
  AeDugnadSpace._();

  static const double pageH = 20;

  /// `.dg-msheet { border-radius: 26px 26px 0 0 }` -- deliberately larger than
  /// `--ae-r-xl`'s 24. Shared because two sheets had independently settled on
  /// 22: a low-value delta repeated across files is not low value, since the
  /// repetition is what makes it invisible to every comparison but the source.
  static const double sheetTopRadius = 26;

  // Home `.h-feed` (club-select.jsx / app.css)
  static const double homeFeedOverlap = 18;
  static const double homeFeedPadTop = 24;
  static const double homeFeedRadius = 24;
  /// `DGClubHome` overrides `.h-feed`'s base `gap: 22` to 14 inline
  /// (club-select.jsx:556) — the club home is denser than the generic feed.
  static const double homeFeedGap = 14;

  // Sub-page `.dn-feed` (refer, donate)
  static const double subFeedOverlap = 12;
  static const double subFeedPadTop = 18;
  static const double subFeedPadH = 18;
  static const double subFeedGap = 18;

  static const double quickGap = 11;
  static const double sectionHeadMb = 10;
  static const double heroPadBottom = 40;
  static const double clubHeroPadBottom = 34;
  static const double heroPadTop = 10;
  static const double cardSubtitleGap = 2;
  static const double campSubtitleGap = 3;
}

TextStyle _sans({
  required double size,
  required FontWeight weight,
  Color? color,
  double? height,
  double? letterSpacingEm,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacingEm != null ? size * letterSpacingEm : null,
    color: color ?? ScSaasThemeTokens.text,
  );
}

// ---------------------------------------------------------------------------
// Global Ærend semantic scale (colors_and_type.css)
// ---------------------------------------------------------------------------

TextStyle aeDisplay({Color? color}) => _sans(
      size: AeFontSize.display,
      weight: FontWeight.w800,
      height: 1.05,
      letterSpacingEm: -0.02,
      color: color,
    );

TextStyle aeH1({Color? color}) => _sans(
      size: AeFontSize.h1,
      weight: FontWeight.w800,
      height: 1.15,
      letterSpacingEm: -0.02,
      color: color,
    );

TextStyle aeH2({Color? color}) => _sans(
      size: AeFontSize.h2,
      weight: FontWeight.w800,
      height: 1.2,
      letterSpacingEm: -0.015,
      color: color,
    );

TextStyle aeH3({Color? color}) => _sans(
      size: AeFontSize.h3,
      weight: FontWeight.w800,
      height: 1.2,
      letterSpacingEm: -0.01,
      color: color,
    );

TextStyle aeTitle({Color? color}) => _sans(
      size: AeFontSize.title,
      weight: FontWeight.w700,
      height: 1.25,
      letterSpacingEm: -0.005,
      color: color,
    );

TextStyle aeBody({Color? color}) => _sans(
      size: AeFontSize.body,
      weight: FontWeight.w500,
      height: 1.45,
      color: color ?? ScSaasThemeTokens.ink,
    );

TextStyle aeLabel({Color? color}) => _sans(
      size: AeFontSize.label,
      weight: FontWeight.w600,
      height: 1.3,
      letterSpacingEm: -0.005,
      color: color,
    );

TextStyle aeCaption({Color? color}) => _sans(
      size: AeFontSize.caption,
      weight: FontWeight.w500,
      height: 1.4,
      color: color ?? ScSaasThemeTokens.gray500,
    );

TextStyle aeOverline({Color? color}) => _sans(
      size: AeFontSize.overline,
      weight: FontWeight.w800,
      height: 1.2,
      letterSpacingEm: 0.08,
      color: color ?? ScSaasThemeTokens.gray500,
    );

TextStyle aeMono({Color? color, double? fontSize}) => GoogleFonts.jetBrainsMono(
      fontSize: fontSize ?? AeFontSize.label,
      fontWeight: FontWeight.w500,
      letterSpacing: (fontSize ?? AeFontSize.label) * -0.01,
      color: color ?? ScSaasThemeTokens.text,
    );

// ---------------------------------------------------------------------------
// Dugnad component typography (dugnad.css / gamify.css)
// ---------------------------------------------------------------------------

abstract final class AeDugnadText {
  AeDugnadText._();

  /// `.h-loc .label`
  static TextStyle heroDeliveryLabel({Color? color}) => _sans(
        size: 11,
        weight: FontWeight.w500,
        height: 1.2,
        letterSpacingEm: 0.03,
        color: color,
      );

  /// `.h-loc .place`
  static TextStyle heroDeliveryPlace({Color? color}) => _sans(
        size: AeFontSize.title,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.dg-myklubb .k`
  static TextStyle myKlubbKey({Color? color}) => _sans(
        size: AeFontSize.tiny,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: 0.08,
        color: color,
      );

  /// `.dg-myklubb .v`
  static TextStyle myKlubbValue({Color? color}) => _sans(
        size: AeFontSize.labelMd,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.dg-clubhero .ch-eyebrow`
  static TextStyle clubHeroEyebrow({Color? color}) => _sans(
        size: AeFontSize.overline,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: 0.07,
        color: color ?? ScSaasThemeTokens.primary,
      );

  /// `.dg-clubhero .ch-nm`
  static TextStyle clubHeroName({Color? color}) => _sans(
        size: AeFontSize.clubHeroName,
        weight: FontWeight.w800,
        height: 1.12,
        letterSpacingEm: -0.02,
        color: color,
      );

  /// `.dg-clubhero .ch-loc`
  static TextStyle clubHeroLocation({Color? color}) => _sans(
        size: AeFontSize.captionSm,
        weight: FontWeight.w600,
        height: 1.3,
        color: color ?? ScSaasThemeTokens.gray500,
      );

  /// `.dg-clubhero .ch-stat-label`
  static TextStyle clubStatLabel({Color? color}) => _sans(
        size: AeFontSize.micro,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: 0.02,
        color: color ?? ScSaasThemeTokens.gray500,
      );

  /// `.dg-clubhero .ch-stat-num`
  static TextStyle clubStatValue({Color? color}) => _sans(
        size: AeFontSize.statNum,
        weight: FontWeight.w900,
        height: 1.05,
        letterSpacingEm: -0.02,
        color: color,
      );

  /// `.dg-clubhero .ch-stat-num span` (kr suffix)
  static TextStyle clubStatKr({Color? color}) => _sans(
        size: AeFontSize.statKr,
        weight: FontWeight.w800,
        color: color ?? ScSaasThemeTokens.success,
      );

  /// `.dg-clubhero .ch-cta-tx`
  static TextStyle clubCtaLine({Color? color}) => _sans(
        size: 13.5,
        weight: FontWeight.w800,
        height: 1.3,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.dg-ref-banner .t`
  static TextStyle bannerTitle({Color? color}) => _sans(
        size: AeFontSize.titleMd,
        weight: FontWeight.w800,
        height: 1.25,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.dg-ref-banner .s`
  static TextStyle bannerSubtitle({Color? color}) => _sans(
        size: AeFontSize.captionSm,
        weight: FontWeight.w600,
        height: 1.35,
        color: color,
      );

  /// `.lb-entry .t`
  static TextStyle leagueEntryTitle({Color? color}) => _sans(
        size: AeFontSize.titleLg,
        weight: FontWeight.w900,
        height: 1.2,
        letterSpacingEm: -0.02,
        color: color,
      );

  /// `.lb-entry .s`
  static TextStyle leagueEntrySubtitle({Color? color}) => _sans(
        size: AeFontSize.caption,
        weight: FontWeight.w700,
        height: 1.35,
        color: color,
      );

  /// `.dg-campcta .t`
  static TextStyle campCtaTitle({Color? color}) => _sans(
        size: AeFontSize.titleLg,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: -0.015,
        color: color,
      );

  /// `.dg-campcta .s`
  static TextStyle campCtaSubtitle({Color? color}) => _sans(
        size: AeFontSize.caption,
        weight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  /// `.lb-hero-title`
  static TextStyle pageHeroTitle({Color? color}) => _sans(
        size: AeFontSize.heroTitle,
        weight: FontWeight.w800,
        height: 1.1,
        letterSpacingEm: -0.025,
        color: color,
      );

  /// `.lb-hero-sub`
  static TextStyle pageHeroSub({Color? color}) => _sans(
        size: AeFontSize.heroSub,
        weight: FontWeight.w600,
        height: 1.35,
        color: color,
      );

  /// `.lb-org`
  static TextStyle pageHeroOrg({Color? color}) => _sans(
        size: AeFontSize.titleLg,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: -0.015,
        color: color,
      );

  /// `.dg-label`
  static TextStyle sectionLabel({Color? color}) => _sans(
        size: 11,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: 0.08,
        color: color ?? ScSaasThemeTokens.gray500,
      );

  /// `.h-section-head h3`
  static TextStyle sectionHead({Color? color}) => _sans(
        size: AeFontSize.h3,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.h-see-all`
  static TextStyle seeAllLink({Color? color}) => _sans(
        size: AeFontSize.captionSm,
        weight: FontWeight.w600,
        height: 1.2,
        color: color ?? ScSaasThemeTokens.primary,
      );

  /// `.mk-camp2-body .ttl` — campaign card title (not section head)
  static TextStyle sectionTitle({Color? color}) => _sans(
        size: 19,
        weight: FontWeight.w800,
        height: 1.12,
        letterSpacingEm: -0.02,
        color: color,
      );

  /// `.dg-ref-code`
  static TextStyle referralCode({Color? color}) => _sans(
        size: AeFontSize.refCode,
        weight: FontWeight.w900,
        height: 1.1,
        letterSpacingEm: 0.02,
        color: color,
      );

  /// `.dg-ptsearn .tx .t`
  static TextStyle pointsEarnTitle({Color? color}) => _sans(
        size: 13.5,
        weight: FontWeight.w900,
        height: 1.3,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.dg-ptsearn .tx .s`
  static TextStyle pointsEarnSub({Color? color}) => _sans(
        size: 11,
        weight: FontWeight.w700,
        height: 1.35,
        color: color,
      );

  /// `.dg-ref-stats .v`
  static TextStyle statTileValue({Color? color}) => _sans(
        size: AeFontSize.pointsAmt,
        weight: FontWeight.w900,
        height: 1.1,
        letterSpacingEm: -0.02,
        color: color,
      );

  /// `.dg-ref-stats .k`
  static TextStyle statTileLabel({Color? color}) => _sans(
        size: 11,
        weight: FontWeight.w700,
        height: 1.3,
        color: color ?? ScSaasThemeTokens.gray500,
      );

  /// `.dn-chips button`
  static TextStyle amountChip({Color? color}) => _sans(
        size: 14.5,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.dn-fee-tx`
  static TextStyle feeBreakdown({Color? color}) => _sans(
        size: 13,
        weight: FontWeight.w600,
        height: 1.5,
        color: color ?? ScSaasThemeTokens.gray700,
      );

  /// `.dn-nudge .t`
  static TextStyle nudgeTitle({Color? color}) => _sans(
        size: 13.5,
        weight: FontWeight.w800,
        height: 1.3,
        letterSpacingEm: -0.01,
        color: color,
      );

  /// `.dn-nudge .s`
  static TextStyle nudgeBody({Color? color}) => _sans(
        size: AeFontSize.caption,
        weight: FontWeight.w600,
        height: 1.45,
        color: color ?? ScSaasThemeTokens.gray700,
      );
}
