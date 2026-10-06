import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import 'meg_nav.dart';

/// The page under Meg that opens on the Torg (`erFavoritter` / `erKonto`,
/// L8164–8270 in `Ærend Kunde Launch.dc.html`, design px): the teal page,
/// the 104-px Torg header with the glass back key, a pill on the right and
/// the dark title, then a scrolling body (`padding:12px 16px 130px`) with
/// two soft glows behind it, and the bottom bar.
///
/// The header is the baked Torg scene (`assets/images/meg/favoritter.jpg`);
/// above it, under the status bar, the sky carries on in the scene's own
/// colour.
class MegTorgSkjerm extends StatelessWidget {
  const MegTorgSkjerm({
    super.key,
    required this.tittel,
    required this.pille,
    required this.glod,
    required this.children,
    this.pilleKey,
    this.onPille,
    this.listKey,
  });

  final String tittel;
  final String pille;
  final Key? pilleKey;
  final VoidCallback? onPille;

  /// The two glows (`position:absolute` in the scroll box), in body px.
  final List<MegGlod> glod;
  final List<Widget> children;
  final Key? listKey;

  static const Color blekk = Color(0xFF23201D);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final hode = 104 + (top - 12).clamp(0.0, double.infinity);
    return AeOnce(
      kind: AeInn.skjermInn,
      ms: 340,
      curve: const Cubic(.2, .9, .3, 1),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CssBox(
              bg: [
                CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
                CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .42, 1]),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: hode,
            bottom: 0,
            child: ClipRect(
              child: SingleChildScrollView(
                key: listKey,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final g in glod) g._plassert(),
                    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: hode,
            child: _Hode(top: top, tittel: tittel, pille: pille, pilleKey: pilleKey, onPille: onPille),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: MegNav()),
        ],
      ),
    );
  }
}

class _Hode extends StatelessWidget {
  const _Hode({required this.top, required this.tittel, required this.pille, this.pilleKey, this.onPille});

  final double top;
  final String tittel;
  final String pille;
  final Key? pilleKey;
  final VoidCallback? onPille;

  @override
  Widget build(BuildContext context) {
    final y = (top - 12).clamp(0.0, double.infinity);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CssBox(bg: [CssLinear(180, [Color(0xFF7E93A3), Color(0xFF5D8088)])]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 104,
            child: Image.asset('assets/images/meg/favoritter.jpg', fit: BoxFit.cover, gaplessPlayback: true),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: y + 12,
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AePress(
                  key: const Key('torg-tilbake'),
                  onTap: () => Navigator.of(context).maybePop(),
                  dy: 0,
                  scale: .92,
                  child: const CssBox(
                    width: 36,
                    height: 36,
                    radius: BorderRadius.all(Radius.circular(13)),
                    bg: [CssSolid(Color.fromRGBO(255, 255, 255, .6))],
                    border: Border.fromBorderSide(BorderSide(color: Color.fromRGBO(255, 255, 255, .75))),
                    child: Center(child: AeIkon('M15 6l-6 6 6 6', size: 15, stroke: 2.2, color: MegTorgSkjerm.blekk)),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: GestureDetector(
                    key: pilleKey,
                    behavior: HitTestBehavior.opaque,
                    onTap: onPille,
                    child: CssBox(
                      radius: const BorderRadius.all(Radius.circular(999)),
                      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .55))],
                      border: const Border.fromBorderSide(BorderSide(color: Color.fromRGBO(255, 255, 255, .5))),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      child: Text(
                        pille,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: aeTab(inter(11, weight: FontWeight.w800, color: MegTorgSkjerm.blekk)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: y + 54,
            child: Text(tittel, maxLines: 1, style: jakarta(22, em: -.02, color: MegTorgSkjerm.blekk)),
          ),
        ],
      ),
    );
  }
}

/// A soft glow behind the body (`radial-gradient(circle, c, transparent 68%)`).
/// [top]/[left]/[right] are the prototype's, from the scroll box's edge.
class MegGlod {
  const MegGlod({required this.top, required this.size, required this.color, this.left, this.right});

  final double top;
  final double size;
  final Color color;
  final double? left;
  final double? right;

  Widget _plassert() => Positioned(
    top: top - 12,
    left: left == null ? null : left! - 16,
    right: right == null ? null : right! - 16,
    width: size,
    height: size,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)], stops: const [0, .68]),
        ),
      ),
    ),
  );
}

/// The light glass card (`rgba(255,255,255,.6)`, `1px rgba(255,255,255,.9)`,
/// `inset 0 1.5px 0 .95`, `0 16px 28px -16px rgba(90,60,30,.5)`).
class MegLysKort extends StatelessWidget {
  const MegLysKort({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 4), this.radius = 22});

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(radius),
    bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .6))],
    border: const Border.fromBorderSide(BorderSide(color: Color.fromRGBO(255, 255, 255, .9))),
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
      CssShadow(0, 16, 28, -16, Color.fromRGBO(90, 60, 30, .5)),
    ],
    padding: padding,
    child: child,
  );
}
