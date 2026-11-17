import 'package:flutter/painting.dart';

import '../../screens/common/auth/launch/lf_css.dart' show CssBg, CssLinear, CssRadial, CssShadow, CssSolid;

/// Lys modus · Skydans: the design's light palette (`<style data-lys-palett>`,
/// `--lys-*`), the light primary-CTA fill (`--x-kft` / `--x-kfts`) and the
/// light sheet tone (`[data-arkmork][data-arktone="lys"]`, `--am-*`).
/// Values as written in the export; the dark twins stay where the app has them.
abstract final class LysPalett {
  /// `--lys-ull`: screen background.
  static const Color ull = Color(0xFFF7FBFD);

  /// `--lys-hvit`: cards.
  static const Color hvit = Color(0xFFFFFFFF);

  /// `--lys-dis`: wells, chips, fields.
  static const Color dis = Color(0xFFE7F5FA);

  /// `--lys-dis-ull`.
  static const Color disUll = Color.fromRGBO(31, 82, 95, .07);
  static const Color mintDis = Color(0xFFD4FBEB);
  static const Color glodDis = Color(0xFFFFEAE1);
  static const Color gullDis = Color(0xFFFFF3C9);

  /// `--lys-tittel`: headings.
  static const Color tittel = Color(0xFF03313C);

  /// `--lys-brod`: body text.
  static const Color brod = Color(0xFF142226);
  static const Color sekundar = Color(0xFF4B5E64);
  static const Color dempet = Color(0xFF627276);
  static const Color fjord = Color(0xFF1E4F5C);

  /// `--lys-fjord-fyll`: `linear-gradient(180deg,#235E6D,#124A58)`.
  static const List<CssBg> fjordFyll = [CssLinear(180, [Color(0xFF235E6D), Color(0xFF124A58)])];
  static const Color mint = Color(0xFF5CE0B8);
  static const Color mintTekst = Color(0xFF046850);

  /// `--lys-glod`: `linear-gradient(180deg,#F9A273,#F26D3D 56%,#DD5A25)`.
  static const List<CssBg> glod = [
    CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
  ];
  static const Color glodTekst = Color(0xFFA63B0E);
  static const Color gullTekst = Color(0xFF4A300A);

  /// `--lys-kant-farge` (`--lys-kant` = 1px solid this).
  static const Color kantFarge = Color.fromRGBO(31, 82, 95, .09);
  static const Color skille = Color.fromRGBO(31, 82, 95, .08);

  /// `--lys-kortskygge`.
  static const List<CssShadow> kortskygge = [
    CssShadow(0, 1, 1, 0, Color.fromRGBO(6, 52, 62, .04)),
    CssShadow(0, 10, 26, -14, Color.fromRGBO(6, 52, 62, .2)),
  ];

  /// `--lys-arkskygge`.
  static const List<CssShadow> arkskygge = [CssShadow(0, -24, 50, -20, Color.fromRGBO(15, 31, 43, .35))];

  /// `--lys-ark`: sheet background.
  static const Color ark = Color.fromRGBO(247, 251, 253, .96);
  static const Color haandtak = Color.fromRGBO(31, 82, 95, .24);

  // ── primary CTA (`--x-kft` / `--x-kfts`) ────────────────────────────────

  /// Dark: the orange glød.
  static const List<CssBg> kftMork = glod;
  static const List<CssShadow> kftsMork = [
    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
    CssShadow(0, 4, 10, -4, Color.fromRGBO(242, 109, 61, .9)),
  ];

  /// Light: the fjord gradient.
  static const List<CssBg> kftLys = [
    CssLinear(180, [Color(0xFF2B6A7A), Color(0xFF1E4F5C), Color(0xFF174553)], [0, .58, 1]),
  ];
  static const List<CssShadow> kftsLys = [
    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
    CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .16)),
    CssShadow(0, 2, 0, 0, Color(0xFF123B46)),
    CssShadow(0, 9, 14, -6, Color.fromRGBO(6, 40, 52, .55)),
  ];
}

/// The dark-sheet tokens (`[data-arkmork]`, `--am-*`) in both tones: [mork] =
/// the fjord sheet, [lys] = `data-arktone="lys"`.
class ArkTone {
  const ArkTone._({
    required this.bg,
    required this.sh,
    required this.handtak,
    required this.tittel,
    required this.linje,
    required this.sek,
    required this.knappBg,
    required this.knappBd,
    required this.knappSh,
    required this.sekkBg,
    required this.sekkBd,
    required this.sekkSh,
    required this.ikon,
    required this.mint,
    required this.dyp,
    required this.dis10,
    required this.dis12,
    required this.kant18,
    required this.kant22,
    required this.felt,
    required this.kr,
  });

  final List<CssBg> bg;
  final List<CssShadow> sh;
  final Color handtak, tittel, linje, sek;
  final List<CssBg> knappBg;
  final Color knappBd;
  final List<CssShadow> knappSh;
  final List<CssBg> sekkBg;
  final Color sekkBd;
  final List<CssShadow> sekkSh;
  final Color ikon, mint, dyp, dis10, dis12, kant18, kant22;
  final List<CssBg> felt;
  final Color kr;

  bool get erLys => identical(this, lys);

  static const ArkTone mork = ArkTone._(
    bg: [
      CssRadial([Color.fromRGBO(127, 240, 203, .12), Color.fromRGBO(127, 240, 203, 0)], stops: [0, .6], rx: .9, ry: .4, cx: .2, cy: 0),
      CssLinear(180, [Color(0xFF22596A), Color(0xFF1A4652), Color(0xFF122F3A)], [0, .45, 1]),
    ],
    sh: [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
      CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .08)),
      CssShadow(0, -30, 60, -20, Color.fromRGBO(8, 24, 32, .6)),
    ],
    handtak: Color.fromRGBO(255, 255, 255, .28),
    tittel: Color(0xFFFFFFFF),
    linje: Color.fromRGBO(255, 255, 255, .7),
    sek: Color.fromRGBO(255, 255, 255, .62),
    knappBg: [CssLinear(180, [Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, .08)])],
    knappBd: Color.fromRGBO(255, 255, 255, .28),
    knappSh: [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
      CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 0, 0, .6)),
    ],
    sekkBg: [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)])],
    sekkBd: Color.fromRGBO(255, 255, 255, .26),
    sekkSh: [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
      CssShadow(0, 12, 18, -12, Color.fromRGBO(4, 18, 26, .8)),
    ],
    ikon: Color(0xFFFFFFFF),
    mint: Color(0xFF7FF0CB),
    dyp: Color.fromRGBO(0, 0, 0, .5),
    dis10: Color.fromRGBO(255, 255, 255, .1),
    dis12: Color.fromRGBO(255, 255, 255, .12),
    kant18: Color.fromRGBO(255, 255, 255, .18),
    kant22: Color.fromRGBO(255, 255, 255, .22),
    felt: [CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .08)])],
    kr: Color.fromRGBO(255, 255, 255, .7),
  );

  static const ArkTone lys = ArkTone._(
    bg: [CssSolid(Color.fromRGBO(247, 251, 253, .94))],
    sh: [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
      CssShadow(0, -30, 60, -20, Color.fromRGBO(8, 24, 32, .5)),
    ],
    handtak: Color.fromRGBO(31, 82, 95, .16),
    tittel: LysPalett.tittel,
    linje: LysPalett.sekundar,
    sek: LysPalett.sekundar,
    knappBg: [CssSolid(LysPalett.hvit)],
    knappBd: LysPalett.kantFarge,
    knappSh: LysPalett.kortskygge,
    sekkBg: [CssSolid(LysPalett.hvit)],
    sekkBd: LysPalett.kantFarge,
    sekkSh: LysPalett.kortskygge,
    ikon: LysPalett.fjord,
    mint: LysPalett.mintTekst,
    dyp: Color.fromRGBO(23, 62, 72, 0),
    dis10: LysPalett.dis,
    dis12: LysPalett.dis,
    kant18: LysPalett.kantFarge,
    kant22: LysPalett.kantFarge,
    felt: [CssSolid(LysPalett.dis)],
    kr: LysPalett.sekundar,
  );
}
