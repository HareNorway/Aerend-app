import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../auth/onboarding_kit.dart';

// ── Bergen dashboard kit ────────────────────────────────────────────────────
// Tokens and helpers shared by the Hjem screen and the bottom nav, ported from
// `erHjem` in `Design/Ærend Kunde Bergen.dc.html`. The design is a 390×844
// frame; [BergenScale.bx] maps its px onto the device width.

const double kBergenFrameWidth = 390;

extension BergenScale on BuildContext {
  /// Design px → device px, 1.0 on a 390pt-wide screen.
  double get bs => MediaQuery.sizeOf(this).width / kBergenFrameWidth;
  double bx(double designPx) => designPx * bs;
}

abstract final class BergenColors {
  /// `linear-gradient(180deg,#2A6272 0%,#1E4F5C 42%,#173E48 100%)` — the
  /// screen and the sheet.
  static const Color teal1 = Color(0xFF2A6272);
  static const Color teal2 = Color(0xFF1E4F5C);
  static const Color teal3 = Color(0xFF173E48);
  static const Color ink = Color(0xFF23201D);
  static const Color inkSoft = Color(0xFF57534B);
  static const Color inkMuted = Color(0xFF8C847C);
  static const Color inkFaint = Color(0xFF9A9188);
  static const Color orange = Color(0xFFF26D3D);
  static const Color orangeHot = Color(0xFFE95C2C);
  static const Color orangeSoft = Color(0xFFF58A55);
  static const Color orangeText = Color(0xFFFF9A5E);
  static const Color mint = Color(0xFF5CE0B8);
  static const Color mintDeep = Color(0xFF2FB893);
  static const Color mintText = Color(0xFF9FE0C8);
  static const Color mintPale = Color(0xFF7FF0CB);
  static const Color gold = Color(0xFFF2C14E);
  static const Color goldLight = Color(0xFFFFDD86);
  static const Color skyText = Color(0xFF9FD3DE);
  static const Color cream = Color(0xFFF5F3EF);
  static const Color green = Color(0xFF2E7E4F);
  static const Color greenDeep = Color(0xFF2E6B47);
  static const Color cardTop = Color(0xFFFDFBF6);
  static const Color cardBottom = Color(0xFFF6F1E7);
  static const Color plate = Color(0xFFEFE6D3);
  static const Color quayWood = Color(0xFF4A3C2A);
}

/// `linear-gradient(180deg,#2A6272 0%,#1E4F5C 42%,#173E48 100%)`.
const LinearGradient kBergenScreenGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [BergenColors.teal1, BergenColors.teal2, BergenColors.teal3],
  stops: [0, .42, 1],
);

/// `linear-gradient(160deg,#2A6272,#1E4F5C 60%,#173E48)` — header chips.
const LinearGradient kBergenChipGradient = LinearGradient(
  begin: Alignment(-.34, -.94),
  end: Alignment(.34, .94),
  colors: [BergenColors.teal1, BergenColors.teal2, BergenColors.teal3],
  stops: [0, .6, 1],
);

/// `linear-gradient(160deg,#F2884E,#E0662C)` — orange action pills.
const LinearGradient kBergenOrangeGradient = LinearGradient(
  begin: Alignment(-.34, -.94),
  end: Alignment(.34, .94),
  colors: [Color(0xFFF2884E), Color(0xFFE0662C)],
);

/// `linear-gradient(180deg,#F58A55,#E95C2C)` — active nav tab.
const LinearGradient kBergenNavActiveGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [BergenColors.orangeSoft, BergenColors.orangeHot],
);

/// `linear-gradient(180deg,#FDFBF6 0%,#F6F1E7 100%)` — rail cards.
const LinearGradient kBergenCardGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [BergenColors.cardTop, BergenColors.cardBottom],
);

/// The header chip shadow: `inset 0 1.5px 0 rgba(255,255,255,.3),
/// 0 2px 0 rgba(15,45,55,.9), 0 10px 16px -9px rgba(15,45,55,.7)`.
List<BoxShadow> bergenChipShadow(BuildContext c) => [
  const BoxShadow(color: Color.fromRGBO(15, 45, 55, .9), offset: Offset(0, 2)),
  BoxShadow(
    color: const Color.fromRGBO(15, 45, 55, .7),
    offset: Offset(0, c.bx(10)),
    blurRadius: onbBlur(c.bx(16)),
    spreadRadius: c.bx(-9),
  ),
];

/// `linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,.8),…)` — the
/// 1px highlight along the top inner edge of a card/pill.
Widget bergenInsetTop({
  required double radius,
  double height = 1.5,
  double alpha = .3,
}) => Positioned.fill(
  child: IgnorePointer(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ColoredBox(color: Colors.white.withValues(alpha: alpha)),
        ),
      ),
    ),
  ),
);

/// Plus Jakarta Sans (display) / Inter (body) with design px scaled.
TextStyle bDisplay(
  BuildContext c,
  double px, {
  FontWeight weight = FontWeight.w800,
  double letterSpacingEm = 0,
  double? height,
  Color color = Colors.white,
  List<Shadow>? shadows,
}) => onbDisplay(
  c.bx(px),
  weight: weight,
  letterSpacingEm: letterSpacingEm,
  height: height,
  color: color,
).copyWith(shadows: shadows);

TextStyle bText(
  BuildContext c,
  double px, {
  FontWeight weight = FontWeight.w700,
  double letterSpacingEm = 0,
  double? height,
  Color color = Colors.white,
  List<Shadow>? shadows,
  TextDecoration? decoration,
}) =>
    onbText(
      c.bx(px),
      weight: weight,
      letterSpacingEm: letterSpacingEm,
      height: height,
      color: color,
      decoration: decoration,
    ).copyWith(
      shadows: shadows,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// A design SVG from `assets/svgs/dashboard/`.
Widget bergenSvg(
  String name, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) => SvgPicture.asset(
  'assets/svgs/dashboard/$name.svg',
  width: width,
  height: height,
  fit: fit,
);

abstract final class BergenAssets {
  static const String aegilFront = 'assets/images/dashboard/front.png';
  static const String aegilRear = 'assets/images/dashboard/rear.png';
  static const String aegilExplore = 'assets/images/dashboard/explore.png';
  static const String aegilPopup = 'assets/images/dashboard/popup.png';
  static const String bkBanner = 'assets/images/dashboard/bk-banner.png';
  static const String bkLogo = 'assets/images/dashboard/bk-logo.png';
  static const String bkWhopper = 'assets/images/dashboard/bk-whopper.png';
}

// ── Weather (design `VAER`) ─────────────────────────────────────────────────

enum BergenWeather { regn, sol, solnedgang, natt }

/// Sky, water tint, light and text colours per weather. There is no weather
/// API; [BergenWeatherLook.forHour] picks by time of day, with Bergen's
/// default rainy look for the daytime.
class BergenWeatherLook {
  const BergenWeatherLook({
    required this.kind,
    required this.sky,
    required this.waterTint,
    required this.mist,
    required this.glow,
    required this.text,
    required this.textShadow,
    required this.houseDim,
  });

  final BergenWeather kind;
  final LinearGradient sky;
  final Color waterTint;
  final LinearGradient mist;
  final double glow;
  final Color text;
  final List<Shadow> textShadow;

  /// CSS `filter: brightness(…)` on the houses, as a darkening overlay alpha.
  final double houseDim;

  bool get isRain => kind == BergenWeather.regn;
  bool get isSun => kind == BergenWeather.sol;
  bool get isNight => kind == BergenWeather.natt;

  static const _lightShadow = [
    Shadow(color: Color.fromRGBO(255, 255, 255, .7), offset: Offset(0, 1)),
    Shadow(color: Color.fromRGBO(255, 255, 255, .7), blurRadius: 14),
  ];
  static const _darkShadow = [
    Shadow(
      color: Color.fromRGBO(0, 10, 20, .6),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    Shadow(color: Color.fromRGBO(0, 10, 20, .5), blurRadius: 18),
  ];

  static const regn = BergenWeatherLook(
    kind: BergenWeather.regn,
    sky: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFB7C6D2),
        Color(0xFFC6D2DA),
        Color(0xFFD3DCDF),
        Color(0xFFC9D3D5),
      ],
      stops: [0, .3, .58, 1],
    ),
    waterTint: Color.fromRGBO(40, 70, 78, .55),
    mist: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.fromRGBO(203, 215, 222, .92),
        Color.fromRGBO(203, 215, 222, .78),
        Color.fromRGBO(203, 215, 222, .42),
        Color.fromRGBO(203, 215, 222, 0),
      ],
      stops: [0, .34, .62, 1],
    ),
    glow: 1,
    text: BergenColors.ink,
    textShadow: _lightShadow,
    houseDim: .1,
  );

  static const sol = BergenWeatherLook(
    kind: BergenWeather.sol,
    sky: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFA8D2EC), Color(0xFFC4E1F0), Color(0xFFDDEDF2)],
      stops: [0, .46, 1],
    ),
    waterTint: Color.fromRGBO(60, 110, 135, .34),
    mist: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.fromRGBO(255, 240, 215, .22),
        Color.fromRGBO(230, 236, 240, .1),
        Color.fromRGBO(230, 236, 240, 0),
      ],
      stops: [0, .45, 1],
    ),
    glow: 0,
    text: BergenColors.ink,
    textShadow: _lightShadow,
    houseDim: .06,
  );

  static const solnedgang = BergenWeatherLook(
    kind: BergenWeather.solnedgang,
    sky: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF7E7890),
        Color(0xFF9C8492),
        Color(0xFFC9906E),
        Color(0xFFD9A176),
      ],
      stops: [0, .3, .66, 1],
    ),
    waterTint: Color.fromRGBO(46, 76, 86, .48),
    mist: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.fromRGBO(20, 40, 60, .35),
        Color.fromRGBO(20, 40, 60, .15),
        Color.fromRGBO(20, 40, 60, 0),
      ],
      stops: [0, .5, 1],
    ),
    glow: .9,
    text: Color(0xFFF7F2EA),
    textShadow: _darkShadow,
    houseDim: .06,
  );

  static const natt = BergenWeatherLook(
    kind: BergenWeather.natt,
    sky: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF101E30), Color(0xFF16324A), Color(0xFF1F4460)],
      stops: [0, .52, 1],
    ),
    waterTint: Color.fromRGBO(12, 32, 44, .6),
    mist: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.fromRGBO(20, 40, 60, .35),
        Color.fromRGBO(20, 40, 60, .15),
        Color.fromRGBO(20, 40, 60, 0),
      ],
      stops: [0, .5, 1],
    ),
    glow: 1,
    text: BergenColors.cream,
    textShadow: _darkShadow,
    houseDim: .4,
  );

  /// Night 23–05, sunset 19–23, sun 09–15, otherwise Bergen's rainy default.
  static BergenWeatherLook forHour(int hour) {
    if (hour >= 23 || hour < 5) return natt;
    if (hour >= 19) return solnedgang;
    if (hour >= 9 && hour < 15) return sol;
    return regn;
  }
}

// ── Categories (design `KAT` / `LIVE`) ──────────────────────────────────────

/// The five design categories, with the 3D icon and district each carries.
/// API categories are matched onto these by name; unknown ones fall back to
/// the API's own icon.
class BergenCategoryLook {
  const BergenCategoryLook({
    required this.icon,
    required this.district,
    required this.hero,
    required this.aliases,
  });

  final String icon;
  final String district;
  final LinearGradient hero;
  final List<String> aliases;

  static const restaurant = BergenCategoryLook(
    icon: 'cat_restaurant',
    district: 'Bryggen',
    hero: LinearGradient(
      begin: Alignment(-.42, -.9),
      end: Alignment(.42, .9),
      colors: [Color(0xFFF6D9B4), Color(0xFFE9A96E), Color(0xFFD2854A)],
      stops: [0, .52, 1],
    ),
    aliases: ['restaurant', 'mat', 'food', 'takeaway', 'kafe', 'cafe'],
  );
  static const fish = BergenCategoryLook(
    icon: 'cat_fish',
    district: 'Fisketorget',
    hero: LinearGradient(
      begin: Alignment(-.42, -.9),
      end: Alignment(.42, .9),
      colors: [Color(0xFFCFE4EA), Color(0xFF88B6C4), Color(0xFF4C7F92)],
      stops: [0, .52, 1],
    ),
    aliases: ['fisk', 'fish', 'sjømat', 'seafood', 'dagligvare', 'grocery'],
  );
  static const fashion = BergenCategoryLook(
    icon: 'cat_fashion',
    district: 'Torgallmenningen',
    hero: LinearGradient(
      begin: Alignment(-.42, -.9),
      end: Alignment(.42, .9),
      colors: [Color(0xFFF4F1E8), Color(0xFFD8D3C4), Color(0xFF1B2A44)],
      stops: [0, .52, 1],
    ),
    aliases: ['mote', 'fashion', 'klær', 'clothes', 'sko', 'shoes'],
  );
  static const interior = BergenCategoryLook(
    icon: 'cat_interior',
    district: 'Møhlenpris',
    hero: LinearGradient(
      begin: Alignment(-.42, -.9),
      end: Alignment(.42, .9),
      colors: [Color(0xFFDCEBDF), Color(0xFF94BFA1), Color(0xFF54886A)],
      stops: [0, .52, 1],
    ),
    aliases: ['interiør', 'interior', 'hjem', 'home', 'møbler', 'furniture'],
  );
  static const gifts = BergenCategoryLook(
    icon: 'cat_gifts',
    district: 'Nordnes',
    hero: LinearGradient(
      begin: Alignment(-.42, -.9),
      end: Alignment(.42, .9),
      colors: [Color(0xFFF7E6C2), Color(0xFFDEBB78), Color(0xFFB8903F)],
      stops: [0, .52, 1],
    ),
    aliases: ['gaver', 'gift', 'blomster', 'flowers', 'apotek'],
  );

  static const all = [restaurant, fish, fashion, interior, gifts];

  /// Match an API category name onto a design look; null when nothing fits.
  static BergenCategoryLook? forName(String name) {
    final n = name.toLowerCase();
    for (final look in all) {
      if (look.aliases.any(n.contains)) return look;
    }
    return null;
  }
}
