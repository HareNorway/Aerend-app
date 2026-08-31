import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/utils.dart';
import 'select_payment_method_dl.dart';

/// Payment-method radio list — mirrors design `checkout-screens.jsx`
/// (`.dg-label` + `.dgsp-row` cards + `.dn-addteam` add-card row).
class ItemSelectPaymentMethod extends StatefulWidget {
  /// A list of strings that describes each Radio button. Each label must be distinct.
  final List<SelectPaymentMethodModel> labels;

  /// Specifies which Radio button to automatically pick.
  /// Every element must match a label.
  /// This is useful for clearing what is picked (set it to "").
  /// If this is non-null, then the user must handle updating this; otherwise, the state of the RadioButtonGroup won't change.
  final int? picked;

  /// Called when the value of the RadioButtonGroup changes.
  final void Function(int label, int index)? onChange;

  /// Called when the user makes a selection.
  final void Function(int selected, SelectPaymentMethodItem selectPaymentMethodItem)? onSelected;

  final void Function(bool add)? onAddCard;

  //RADIO BUTTON FIELDS
  /// The color to use when a Radio button is checked.
  final Color? activeColor;

  //SPACING STUFF
  /// Empty space in which to inset the RadioButtonGroup.
  final EdgeInsetsGeometry padding;

  /// Empty space surrounding the RadioButtonGroup.
  final EdgeInsetsGeometry margin;

  const ItemSelectPaymentMethod({
    super.key,
    required this.labels,
    this.picked,
    this.onChange,
    this.onSelected,
    this.onAddCard,
    this.activeColor, //defaults to toggleableActiveColor,
    this.padding = const EdgeInsets.all(0.0),
    this.margin = const EdgeInsets.all(0.0),
  });

  @override
  RbGroupSelectPaymentMethodState createState() => RbGroupSelectPaymentMethodState();
}

class RbGroupSelectPaymentMethodState extends State<ItemSelectPaymentMethod> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    //Select Default one
    _selected = widget.picked ?? 0;
  }

  void _select(SelectPaymentMethodItem item, int indexInModel) {
    if (_selected == item.id) return;
    setState(() => _selected = item.id);
    if (widget.onChange != null) widget.onChange!(item.id, indexInModel);
    if (widget.onSelected != null) widget.onSelected!(item.id, item);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [];
    bool showAddCard = false;

    // `.dg-label` (margin override `2px 2px 0` in JSX).
    content.add(Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Text(
        "Velg betalingsmåte".toUpperCase(), // TODO(l10n)
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 11 * 0.08,
          color: ScSaasThemeTokens.gray500,
        ),
      ),
    ));

    for (int i = 0; i < widget.labels.length; i++) {
      SelectPaymentMethodModel selectPaymentMethodModel = widget.labels[i];
      if (selectPaymentMethodModel.showAddCard) showAddCard = true;
      for (int j = 0; j < selectPaymentMethodModel.selectPaymentMethodList.length; j++) {
        SelectPaymentMethodItem item = selectPaymentMethodModel.selectPaymentMethodList[j];
        content.add(const SizedBox(height: 12));
        content.add(_DgspRow(
          item: item,
          selected: _selected == item.id,
          activeColor: widget.activeColor ?? ScSaasThemeTokens.primary,
          onTap: () => _select(item, j),
        ));
      }
    }

    if (showAddCard) {
      content.add(const SizedBox(height: 12));
      content.add(_AddCardRow(onTap: () {
        if (widget.onAddCard != null) widget.onAddCard!(true);
      }));
    }

    return Container(
      padding: widget.padding,
      margin: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }
}

/// `.dgsp-row` — white card row: radio circle `.rb` + logo box `.lg` + texts.
class _DgspRow extends StatelessWidget {
  final SelectPaymentMethodItem item;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _DgspRow({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  /// Splits "Lommebok (821 kr)"-style names into title + availability sub.
  (String, String?) _nameAndSub() {
    if (item.type == paymentTypeWallet) {
      final match = RegExp(r'^(.*) \((.*)\)$').firstMatch(item.name);
      if (match != null) {
        return (match.group(1)!, "${match.group(2)!} tilgjengelig"); // TODO(l10n)
      }
    }
    if (item.type == paymentTypeCash) {
      return (item.name, "Betal budet direkte"); // TODO(l10n)
    }
    if (item.cardListItem != null && item.cardListItem!.cardHolderName.isNotEmpty) {
      return (item.name, item.cardListItem!.cardHolderName);
    }
    return (item.name, null);
  }

  @override
  Widget build(BuildContext context) {
    final (name, sub) = _nameAndSub();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? ScSaasThemeTokens.background : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1.5,
            color: selected ? activeColor : const Color(0xFFE2DDF0),
          ),
        ),
        child: Row(
          children: [
            // `.rb` — 21px radio circle with scaling 11px dot.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.ease,
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: selected ? activeColor : const Color(0xFFD5CFE4),
                ),
              ),
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.ease,
                  scale: selected ? 1 : 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // `.lg` — 42×30 midnight logo box.
            Container(
              width: 42,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.text,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // `.tx` — `.nm` + `.s`.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ScSaasThemeTokens.text,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: ScSaasThemeTokens.gray500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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
}

/// `.dn-addteam` — dashed «Legg til kort» row.
class _AddCardRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCardRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedRoundedBorderPainter(
          color: Color(0xFFD9CEF0),
          radius: 16,
          strokeWidth: 1.5,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A2D1B5B),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // `.ic` — 42×42 purple-100 chip.
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 19,
                  color: ScSaasThemeTokens.primaryHover,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.addCard,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 14.5 * -0.01,
                        color: ScSaasThemeTokens.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Visa eller Mastercard", // TODO(l10n)
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: ScSaasThemeTokens.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        final extractPath = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extractPath, paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
