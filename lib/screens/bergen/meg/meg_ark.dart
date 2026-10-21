
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart' show AeIkon;
import 'package:aerend_customer/utils/route_names.dart';
import '../kit/bergen_kit.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../kit/bergen_perf.dart';

/// The design's Ark (`kVisArk` ≈L7333): the cream frosted sheet the Meg rows
/// open — `rgba(245,243,239,.94)` + blur, 28px top corners, the title (19px),
/// the line under it, the 38×38 close square, a scrolling body with 8px gaps,
/// and the two 52px footer pills (white secondary, dark primary).
/// Inter at the design's exact size — every small label on the Meg tab and its
/// sheets (a bare TextStyle would fall back to Roboto).
TextStyle megInter(double size, FontWeight weight, {Color? color, double? letterSpacing, double? height, List<FontFeature>? fontFeatures}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height, fontFeatures: fontFeatures);

abstract final class MegArkInk {
  static const Color ink = Color(0xFF23201D);
  static const Color sub = Color(0xFF57534B);
  static const Color muted = Color(0xFF6E6862);
  static const Color faint = Color(0xFF8C847C);
  static const Color teal = Color(0xFF1E4F5C);
  static const Color green = Color(0xFF2E6B47);

  /// Default primary: the design's `GT` (`linear-gradient(180deg,#F68450,
  /// #E65A28)`), what every Ark's CTA uses unless the sheet says otherwise.
  static const LinearGradient gtCta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF68450), Color(0xFFE65A28)],
  );

  /// «Meld deg av» (`linear-gradient(168deg,#D0552A,#B9441A 60%,#8E3413)`).
  static const LinearGradient redCta = LinearGradient(colors: [Color(0xFFD0552A), Color(0xFFB9441A), Color(0xFF8E3413)], stops: [0, .6, 1]);

  /// A CTA that is not ready yet (`linear-gradient(180deg,#A9BEC3,#87A0A7)`).
  static const LinearGradient disabledCta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFA9BEC3), Color(0xFF87A0A7)],
  );

  /// The Gullbilletten primary: `linear-gradient(180deg,#6B5120,#463316 58%,#33240E)`.
  static const LinearGradient goldCta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6B5120), Color(0xFF463316), Color(0xFF33240E)],
    stops: [0, .58, 1],
  );
}

class MegArkButton {
  const MegArkButton({required this.label, required this.onTap, this.gradient, this.deg = 180, this.key, this.av = false});

  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;

  /// Done / not available (`kArkCtaBg: '#A9BEC3'`): on the dark Ark a glass
  /// pill with dimmed text instead of the orange key.
  final bool av;

  /// The CSS angle of [gradient] (`linear-gradient(<deg>, …)`).
  final double deg;
  final Key? key;
}

typedef MegArkBody = Widget Function(BuildContext context, StateSetter setState);

Future<T?> showMegArk<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  MegArkBody? body,
  MegArkButton? primary,
  MegArkButton? secondary,
  Key? key,
  /// A primary that follows the sheet's state (rebuilt with [body]).
  MegArkButton Function(BuildContext context)? primaryBuilder,
  /// The dark Ark of new Bergen (`kArkMork`, L9688): teal glass, white type.
  bool mork = false,

  /// The sheet has a text field: it rides up on the keyboard.
  bool tastatur = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    routeSettings: const RouteSettings(name: '${appRoutePrefix}ark'),
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color.fromRGBO(15, 25, 30, .5),
    sheetAnimationStyle: AnimationStyle(
      curve: const Cubic(.2, .9, .3, 1),
      duration: BergenTokens.motion(context, const Duration(milliseconds: 300)),
      reverseDuration: BergenTokens.motion(context, BergenTokens.motionBase),
    ),
    builder: (ctx) {
      final ark = MegArkSkala(
        child: StatefulBuilder(
          builder: (ctx, setState) =>
              MegArk(key: key, title: title, subtitle: subtitle, body: body == null ? null : body(ctx, setState), primary: primaryBuilder?.call(ctx) ?? primary, secondary: secondary, mork: mork),
        ),
      );
      return tastatur
          ? Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
              child: ark,
            )
          : ark;
    },
  );
}

/// The dark Ark that glides (`ARK_GLID`, L18934–18947, L18969–18977): up with
/// a little overshoot (640 ms, `translate3d(0,100%)` → −1.2 % at .72 → 0),
/// the backdrop fading in over 420 ms; closing lifts 10 px and drops below
/// the edge (440 ms). Min Bio is the one sheet that does this. A modal bottom
/// sheet cannot take the curve, so it is a route of its own; the keyboard
/// pushes the sheet up.
Future<T?> showMegArkGlid<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required MegArkBody body,
  required MegArkButton Function(BuildContext context) primaryBuilder,
  Key? key,
}) {
  final still = BergenPerf.of(context) == BergenTier.still;
  return Navigator.of(context).push<T>(
    _GlidRute<T>(
      still: still,
      builder: (ctx) => MegArkSkala(
        child: StatefulBuilder(
          builder: (ctx, setState) => MegArk(key: key, title: title, subtitle: subtitle, body: body(ctx, setState), primary: primaryBuilder(ctx), mork: true),
        ),
      ),
    ),
  );
}

class _GlidRute<T> extends PopupRoute<T> {
  _GlidRute({required this.builder, required this.still}) : super(settings: const RouteSettings(name: '${appRoutePrefix}ark'));

  final WidgetBuilder builder;
  final bool still;

  static const Cubic _inn = Cubic(.22, 1, .36, 1);
  static const Cubic _ut = Cubic(.45, 0, .65, .25);

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Lukk';

  @override
  Duration get transitionDuration => still ? Duration.zero : const Duration(milliseconds: 640);

  @override
  Duration get reverseTransitionDuration => still ? Duration.zero : const Duration(milliseconds: 440);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      // The text fields need a Material, as the modal sheet gives one.
      Material(type: MaterialType.transparency, child: builder(context));

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = animation.value;
        double frac, px, bak;
        if (animation.status == AnimationStatus.reverse) {
          final e = _ut.transform(1 - v);
          frac = e < .18 ? 0 : 1.04 * (e - .18) / .82;
          px = e < .18 ? -10 * e / .18 : -10 * (1 - (e - .18) / .82);
          bak = 1 - cssEaseIn.transform(1 - v);
        } else {
          final e = _inn.transform(v);
          frac = e < .72 ? 1 + (-.012 - 1) * e / .72 : -.012 * (1 - (e - .72) / .28);
          px = 0;
          bak = cssEaseOut.transform((v * 640 / 420).clamp(0.0, 1.0));
        }
        return Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color.fromRGBO(15, 25, 30, .5 * bak)))),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: inset),
                child: IgnorePointer(
                  ignoring: animation.status == AnimationStatus.reverse,
                  child: FractionalTranslation(
                    translation: Offset(0, frac),
                    child: Transform.translate(offset: Offset(0, px), child: child),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The Ark in the design's 390-px frame, scaled to the device width like
/// the screens it opens over (`LfFrame`): `MediaQuery` inside reports design
/// px, so the 86 % height cap, the home indicator and the keyboard line up.
class MegArkSkala extends StatelessWidget {
  const MegArkSkala({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final s = mq.size.width / 390;
    if ((s - 1).abs() < .001) return child;
    EdgeInsets d(EdgeInsets e) => EdgeInsets.fromLTRB(e.left / s, e.top / s, e.right / s, e.bottom / s);
    // The sheet's width is loose: give the box the device width, so the
    // 390-px Ark is scaled up to it.
    return SizedBox(
      width: mq.size.width,
      child: FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.bottomCenter,
      child: MediaQuery(
        data: mq.copyWith(
          size: Size(390, mq.size.height / s),
          padding: d(mq.padding),
          viewPadding: d(mq.viewPadding),
          viewInsets: d(mq.viewInsets),
          devicePixelRatio: mq.devicePixelRatio * s,
        ),
        child: SizedBox(width: 390, child: child),
      ),
      ),
    );
  }
}

class MegArk extends StatelessWidget {
  const MegArk({super.key, required this.title, this.subtitle, this.body, this.primary, this.secondary, this.mork = false});

  final String title;
  final String? subtitle;
  final Widget? body;
  final MegArkButton? primary;
  final MegArkButton? secondary;

  /// New Bergen's dark Ark (`kArkMork`, L9688–9692): a mint glow over
  /// `#22596A → #1A4652 → #122F3A`, the 30 px blur, a light top edge, the
  /// 21 px white title, 70 % white line, glass close key and footer.
  final bool mork;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .86;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          enabled: BergenPerf.blurOn(context),
          filter: BergenPerf.blur(context, 30, 30),
          child: DecoratedBox(
            decoration: mork
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF22596A), Color(0xFF1A4652), Color(0xFF122F3A)],
                      stops: [0, .45, 1],
                    ),
                  )
                : BoxDecoration(
                    color: const Color(0xFFF5F3EF).withValues(alpha: .96),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .95), width: 1.5)),
                  ),
            // The dark Ark's mint glow and inner edge are drawn over the fill.
            child: CustomPaint(
              painter: mork ? const _MorkKant() : null,
              child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The handle: 40 × 5, `rgba(35,32,29,.16)` (dark: white .28), 8 px from the top.
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(color: mork ? const Color.fromRGBO(255, 255, 255, .28) : const Color.fromRGBO(35, 32, 29, .16), borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  Padding(
                    padding: mork ? const EdgeInsets.fromLTRB(18, 14, 18, 10) : const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: mork
                                    ? BergenTokens.display(21, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.03)
                                    : BergenTokens.display(19, weight: FontWeight.w800, color: MegArkInk.ink, letterSpacingEm: -0.02),
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty) ...[
                                SizedBox(height: mork ? 4 : 3),
                                Text(
                                  subtitle!,
                                  style: BergenTokens.text(12.5, weight: FontWeight.w600, color: mork ? const Color.fromRGBO(255, 255, 255, .7) : MegArkInk.sub, height: 1.45),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: mork ? 12 : 10),
                        _CloseSquare(onTap: () => Navigator.of(context).maybePop(), mork: mork),
                      ],
                    ),
                  ),
                  if (body != null)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: mork ? const EdgeInsets.fromLTRB(18, 8, 18, 8) : const EdgeInsets.fromLTRB(18, 0, 18, 8),
                        child: body,
                      ),
                    ),
                  if (primary != null || secondary != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      child: Row(
                        children: [
                          if (secondary != null) Expanded(flex: 10, child: _ArkSecondary(button: secondary!, mork: mork)),
                          if (secondary != null && primary != null) const SizedBox(width: 8),
                          if (primary != null) Expanded(flex: 16, child: _ArkPrimary(button: primary!, mork: mork)),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark Ark's light: the mint glow top-left (`radial-gradient(90% 40% at
/// 20% 0%, rgba(127,240,203,.12), transparent 60%)`), the inner top edge
/// (`inset 0 1.5px 0 .3`) and the faint ring (`inset 0 0 0 1px .08`).
class _MorkKant extends CustomPainter {
  const _MorkKant();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.save();
    canvas.translate(size.width * .2, 0);
    canvas.scale(size.width * .9, size.height * .4);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()..shader = const RadialGradient(colors: [Color.fromRGBO(127, 240, 203, .12), Color.fromRGBO(127, 240, 203, 0)], stops: [0, .6]).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
    );
    canvas.restore();
    final rr = RRect.fromRectAndCorners(r, topLeft: const Radius.circular(28), topRight: const Radius.circular(28));
    canvas.drawRRect(rr.deflate(.5), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color.fromRGBO(255, 255, 255, .08));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1.5), Paint()..color = const Color.fromRGBO(255, 255, 255, .3));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MorkKant old) => false;
}

/// The 40 px round close key (`#FFFFFF → #E9EEED`, the teal ✕).
class _CloseSquare extends StatelessWidget {
  const _CloseSquare({required this.onTap, this.mork = false});

  final VoidCallback onTap;
  final bool mork;

  @override
  Widget build(BuildContext context) {
    if (mork) {
      // Dark: glass (`.22 → .08`), a .28 white ring, the white ✕.
      return GestureDetector(
        key: const Key('meg-ark-lukk'),
        onTap: onTap,
        child: const CssBox(
          width: 40,
          height: 40,
          radius: BorderRadius.all(Radius.circular(20)),
          bg: [CssLinear(180, [Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, .08)])],
          shadows: [
            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .28)),
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
            CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 0, 0, .6)),
          ],
          child: Center(child: AeIkon('M6 6l12 12M18 6L6 18', size: 14, stroke: 2.8, color: Colors.white)),
        ),
      );
    }
    return GestureDetector(
      key: const Key('meg-ark-lukk'),
      onTap: onTap,
      child: const CssBox(
        width: 40,
        height: 40,
        radius: BorderRadius.all(Radius.circular(20)),
        bg: [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)])],
        shadows: [
          CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(30, 79, 92, .14)),
          CssShadow(0, 8, 14, -8, Color.fromRGBO(8, 24, 32, .45)),
        ],
        child: Center(child: AeIkon('M6 6l12 12M18 6L6 18', size: 14, stroke: 2.8, color: Color(0xFF1E4F5C))),
      ),
    );
  }
}

class _ArkSecondary extends StatelessWidget {
  const _ArkSecondary({required this.button, this.mork = false});

  final MegArkButton button;
  final bool mork;

  @override
  Widget build(BuildContext context) {
    if (mork) {
      // Dark (L9957): glass `.2 → .07`, a .26 ring, the top light, white 14 px.
      return LfPress(
        key: button.key,
        onTap: button.onTap,
        dy: 2,
        ms: 140,
        child: CssBox(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          radius: BorderRadius.circular(999),
          bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)])],
          shadows: const [
            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .26)),
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
            CssShadow(0, 12, 18, -12, Color.fromRGBO(4, 18, 26, .8)),
          ],
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(button.label, textAlign: TextAlign.center, style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      key: button.key,
      onTap: button.onTap,
      // `height:52px; background:linear-gradient(180deg,#FFFFFF,#E9EEED);
      // box-shadow: inset 0 -3px 6px rgba(30,79,92,.14), 0 12px 18px -12px
      // rgba(8,24,32,.5)`.
      child: CssBox(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        radius: BorderRadius.circular(999),
        bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)])],
        shadows: const [
          CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(30, 79, 92, .14)),
          CssShadow(0, 12, 18, -12, Color.fromRGBO(8, 24, 32, .5)),
        ],
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(button.label, textAlign: TextAlign.center, style: BergenTokens.text(14, weight: FontWeight.w800, color: const Color(0xFF1B4A57))),
          ),
        ),
      ),
    );
  }
}

class _ArkPrimary extends StatelessWidget {
  const _ArkPrimary({required this.button, this.mork = false});

  final MegArkButton button;
  final bool mork;

  @override
  Widget build(BuildContext context) {
    if (mork) {
      // Dark (L19012): the orange 3D key — or, done, a glass pill with
      // dimmed text (`#A9BEC3` in the design's data).
      final av = button.av;
      return LfPress(
        key: button.key,
        onTap: button.onTap,
        dy: 3,
        ms: 140,
        child: CssBox(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          radius: BorderRadius.circular(999),
          bg: [
            av
                ? const CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .07)])
                : const CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
          ],
          shadows: av
              ? const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .2))]
              : const [
                  CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .45)),
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                  CssShadow(0, 3, 0, 0, Color(0xFFC4491A)),
                  CssShadow(0, 5, 0, 0, Color.fromRGBO(120, 45, 15, .22)),
                  CssShadow(0, 14, 18, -10, Color.fromRGBO(200, 70, 25, .8)),
                ],
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                button.label,
                textAlign: TextAlign.center,
                style: BergenTokens.text(14.5, weight: FontWeight.w800, color: av ? const Color.fromRGBO(255, 255, 255, .62) : Colors.white),
              ),
            ),
          ),
        ),
      );
    }
    final g = button.gradient ?? MegArkInk.gtCta;
    return GestureDetector(
      key: button.key,
      onTap: button.onTap,
      // `height:52px; border-radius:999px; background:{{ kArkCtaBg }};
      // box-shadow: inset 0 1.5px 0 rgba(255,255,255,.4), inset 0 -3px 6px
      // rgba(80,30,10,.28), 0 14px 20px -12px rgba(8,24,32,.55)`. The
      // design's CTA gradients are all vertical (180deg).
      child: CssBox(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        radius: BorderRadius.circular(999),
        bg: [CssLinear(button.gradient == null ? 180 : button.deg, g.colors, g.stops)],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
          CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(80, 30, 10, .28)),
          CssShadow(0, 14, 20, -12, Color.fromRGBO(8, 24, 32, .55)),
        ],
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(button.label, textAlign: TextAlign.center, style: BergenTokens.display(14.5, weight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// A row in the Ark — the design's `rad(navn, under, verdi, fn, valgt)`:
/// a 20 px card (`#FFFFFF → #FAF8F4`, a 1.5 px `rgba(35,32,29,.05)` ring,
/// the top highlight, a soft drop), the title (14/800) and the line under it
/// (12/600 `#6E6862`), the value as a pill (orange for «Må…», «Nytt…»,
/// «Velg…»), and on the right the teal check ball when chosen — the card then
/// turns mint (`#F1FBF7 → #E3F6EF`, ring `#5CE0B8`) — or the round chevron
/// key when the row opens something and has no value.
class MegArkRow extends StatelessWidget {
  const MegArkRow({super.key, required this.title, this.sub, this.value, this.onTap, this.selected = false, this.leading, this.trailing});

  final String title;
  final String? sub;
  final String? value;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final v = value ?? '';
    final ny = RegExp(r'^(Må|Nytt|Velg)').hasMatch(v);
    // `seksjon`: «1 · …» without a tap heads a group (11/800 caps, teal).
    if (onTap == null && RegExp(r'^\d+ · ').hasMatch(title)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: BergenTokens.text(11, weight: FontWeight.w800, color: MegArkInk.teal).copyWith(letterSpacing: 1.1)),
                  if (sub != null && sub!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub!, style: BergenTokens.text(12, weight: FontWeight.w600, color: MegArkInk.muted, height: 1.4)),
                  ],
                ],
              ),
            ),
            if (v.isNotEmpty) ...[const SizedBox(width: 10), _pill(v, ny)],
          ],
        ),
      );
    }
    final pil = onTap != null && !selected && v.isEmpty && trailing == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: CssBox(
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
          radius: BorderRadius.circular(20),
          bg: [CssLinear(180, selected ? const [Color(0xFFF1FBF7), Color(0xFFE3F6EF)] : const [Color(0xFFFFFFFF), Color(0xFFFAF8F4)])],
          shadows: [
            CssShadow(0, 0, 0, 1.5, selected ? const Color(0xFF5CE0B8) : const Color.fromRGBO(35, 32, 29, .05)),
            const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
            const CssShadow(0, 10, 18, -14, Color.fromRGBO(8, 24, 32, .45)),
          ],
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BergenTokens.text(14, weight: FontWeight.w800, color: MegArkInk.ink).copyWith(letterSpacing: -.14)),
                    if (sub != null && sub!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(sub!, style: BergenTokens.text(12, weight: FontWeight.w600, color: MegArkInk.muted, height: 1.4)),
                    ],
                  ],
                ),
              ),
              if (v.isNotEmpty) ...[const SizedBox(width: 12), _pill(v, ny)],
              if (selected) ...[const SizedBox(width: 12), const MegArkValgt()],
              if (pil) ...[const SizedBox(width: 12), const MegArkPil()],
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

Widget _pill(String v, bool ny) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: ny ? const Color.fromRGBO(242, 109, 61, .14) : const Color.fromRGBO(30, 79, 92, .09),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(v, style: BergenTokens.text(11, weight: FontWeight.w800, color: ny ? const Color(0xFFC2461A) : MegArkInk.teal)),
);

/// The chosen row's 26 px teal ball with the mint check.
class MegArkValgt extends StatelessWidget {
  const MegArkValgt({super.key});

  @override
  Widget build(BuildContext context) => CssBox(
    width: 26,
    height: 26,
    radius: BorderRadius.circular(13),
    bg: const [CssRadial([Color(0xFF4A93A4), Color(0xFF1E4F5C)], stops: [0, .7], cx: .34, cy: .28)],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
      CssShadow.inset(0, -2, 3, 0, Color.fromRGBO(4, 20, 28, .45)),
      CssShadow(0, 4, 8, -3, Color.fromRGBO(8, 24, 32, .5)),
    ],
    child: const Center(child: AeIkon('M5 12.5l4.5 4.5L19 7.5', size: 12, stroke: 3.6, color: Color(0xFF5CE0B8))),
  );
}

/// The 30 px round chevron key (`#FFFFFF → #E9EEED`).
class MegArkPil extends StatelessWidget {
  const MegArkPil({super.key});

  @override
  Widget build(BuildContext context) => CssBox(
    width: 30,
    height: 30,
    radius: BorderRadius.circular(15),
    bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)])],
    shadows: const [
      CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(30, 79, 92, .14)),
      CssShadow(0, 4, 8, -4, Color.fromRGBO(8, 24, 32, .4)),
    ],
    child: const Center(child: AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3, color: Color(0xFF1E4F5C))),
  );
}

/// The 40 px teal icon tile a row can lead with (`harIkon`).
class MegArkIkon extends StatelessWidget {
  const MegArkIkon(this.d, {super.key});

  /// SVG path data on a 24 px grid.
  final String d;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 40,
    height: 40,
    radius: BorderRadius.circular(13),
    bg: const [CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1])],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
      CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(4, 20, 28, .42)),
      CssShadow(0, 8, 12, -6, Color.fromRGBO(8, 24, 32, .55)),
    ],
    child: Center(child: AeIkon(d, size: 18, stroke: 2, color: Colors.white)),
  );
}

/// The white paper card inside an Ark (`linear-gradient(168deg,#FFFFFF,#F4F0E6)`).
class MegArkCard extends StatelessWidget {
  const MegArkCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(begin: Alignment(-.2, -1), end: Alignment(.2, 1), colors: [Colors.white, Color(0xFFF4F0E6)]),
        border: Border.all(color: MegArkInk.ink.withValues(alpha: .07)),
      ),
      child: child,
    );
  }
}

/// The gold card (`kVisArkTekst`, L9217): the label, the text in Jakarta,
/// the dark-gold «Kopier» pill, and the `skinn` sweep (5 s, 1 s in).
/// Gullbilletten's code and Noe galt's case reference.
class MegArkCodeCard extends StatelessWidget {
  const MegArkCodeCard({super.key, required this.label, required this.code, required this.onCopy, this.tapKey = const Key('meg-ark-kode'), this.codeKey});

  final String label;
  final String code;
  final VoidCallback onCopy;
  final Key tapKey;
  final Key? codeKey;

  static const _kopi = 'M11.5 9h6a2.5 2.5 0 0 1 2.5 2.5v6a2.5 2.5 0 0 1-2.5 2.5h-6A2.5 2.5 0 0 1 9 17.5v-6A2.5 2.5 0 0 1 11.5 9zM15 5.5H6.5A2 2 0 0 0 4.5 7.5V16';

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.all(Radius.circular(22));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        key: tapKey,
        behavior: HitTestBehavior.opaque,
        onTap: onCopy,
        child: CssBox(
          radius: r,
          bg: const [CssLinear(152, [Color(0xFFFFF6DC), Color(0xFFF2DDA8), Color(0xFFE3C377)], [0, .55, 1])],
          shadows: const [
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .75)),
            CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(150, 100, 20, .18)),
            CssShadow(0, 14, 22, -14, Color.fromRGBO(120, 80, 10, .65)),
          ],
          child: ClipRRect(
            borderRadius: r,
            child: Stack(
              children: [
                // `skinn`: translateX(-120% → 220%), 5 s ease-in-out, 1 s in.
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, box) => LfLoop(
                        frozenMs: -1,
                        builder: (context, t, child) {
                          if (t < 1000) return const SizedBox.shrink();
                          final p = cssEaseInOut.transform(((t - 1000) / 5000) % 1.0);
                          return Transform.translate(offset: Offset((-1.2 + 3.4 * p) * box.maxWidth, 0), child: child);
                        },
                        child: const CssBox(
                          bg: [CssLinear(112, [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .5), Color.fromRGBO(255, 255, 255, 0)], [.38, .5, .62])],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: inter(10.5, weight: FontWeight.w800, em: .14, color: const Color(0xFF7A5A1A))),
                            const SizedBox(height: 4),
                            Text(code, key: codeKey, style: jakarta(16, em: -.01, color: const Color(0xFF3A2708)).copyWith(height: 1.35)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CssBox(
                        height: 36,
                        radius: const BorderRadius.all(Radius.circular(999)),
                        bg: const [CssLinear(180, [Color(0xFF6B5120), Color(0xFF3E2D12)])],
                        shadows: const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 240, 200, .3)),
                          CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(0, 0, 0, .3)),
                          CssShadow(0, 6, 10, -6, Color.fromRGBO(40, 26, 6, .7)),
                        ],
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AeIkon(_kopi, size: 12, stroke: 2.2, color: Color(0xFFFBE8B4)),
                            const SizedBox(width: 5),
                            Text('Kopier', style: inter(12, weight: FontWeight.w800, color: const Color(0xFFFBE8B4))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
