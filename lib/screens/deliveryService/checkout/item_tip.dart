import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/utils.dart';

class ItemTip extends StatefulWidget {
  final List<double>? tipList;
  final double? defaultSelected;
  final Function(double)? onSelectionChanged;

  const ItemTip({super.key, @required this.tipList, @required this.onSelectionChanged, this.defaultSelected = 0});

  @override
  State createState() => _ItemTipState();
}

class _ItemTipState extends State<ItemTip> {
  double? selectedChoice = 0;

  @override
  void didChangeDependencies() {
    if (widget.defaultSelected! > 0) {
      selectedChoice = widget.defaultSelected!;
    } else {
      selectedChoice = widget.tipList![widget.tipList!.length - 1];
    }
    super.didChangeDependencies();
  }

  _buildChoiceList() {
    List<Widget> choices = [];
    for (var item in widget.tipList!) {
      bool selected = (selectedChoice == item);
      choices.add(Container(
        padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.012, end: deviceWidth * 0.012),
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          ),
          child: ChoiceChip(
            label: Row(
              children: [
                Text(item != 0 ? getAmountWithCurrency(item) : languages.other),
                if (selected && item > 0) SizedBox(width: deviceWidth * 0.005),
                if (selected && item > 0) Icon(Icons.cancel, size: iconSize, color: colorRed),
              ],
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            labelStyle: bodyText(
              textColor: selected ? colorPrimary : colorTextCommonLight,
              fontSize: textSizeSmallest,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: Colors.transparent,
            selectedColor: colorPrimary.withOpacity(0.07),
            pressElevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.all(Radius.circular(deviceAverageSize * 0.008)),
                side: BorderSide(color: selected ? colorPrimary : colorTextCommonLight)),
            selected: selected,
            onSelected: (selected) {
              setState(() {
                if (selectedChoice == item) {
                  selectedChoice = null;
                } else {
                  selectedChoice = item;
                }
                widget.onSelectionChanged!(selectedChoice!);
              });
            },
          ),
        ),
      ));
    }
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(end: deviceWidth * 0.02, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
      scrollDirection: Axis.horizontal,
      child: Wrap(
        children: _buildChoiceList(),
      ),
    );
  }
}
