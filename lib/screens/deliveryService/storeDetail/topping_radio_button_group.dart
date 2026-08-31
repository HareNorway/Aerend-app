import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'store_detail_dl.dart';

class ToppingRadioButtonGroup extends StatefulWidget {
  /// A list of strings that describes each Radio button. Each label must be distinct.
  final List<OptionsItem> labels;

  /// Specifies which Radio button to automatically pick.
  /// Every element must match a label.
  /// This is useful for clearing what is picked (set it to "").
  /// If this is non-null, then the user must handle updating this; otherwise, the state of the RadioButtonGroup won't change.
  final int? picked;
  final int customizeType;
  final double addOnAmount;

  /// Specifies which buttons should be disabled.
  /// If this is non-null, no buttons will be disabled.
  /// The strings passed to this must match the labels.
  final List<String>? disabled;

  /// Called when the value of the RadioButtonGroup changes.
  final void Function(int label, int index)? onChange;

  /// Called when the user makes a selection.
  final void Function(int selected, double amount, double addOnAmount)? onSelected;

  //RADIO BUTTON FIELDS
  /// The color to use when a Radio button is checked.
  final Color? activeColor;

  //SPACING STUFF
  /// Empty space in which to inset the RadioButtonGroup.
  final EdgeInsetsGeometry padding;

  /// Empty space surrounding the RadioButtonGroup.
  final EdgeInsetsGeometry margin;

  const ToppingRadioButtonGroup({
    super.key,
    required this.labels,
    required this.customizeType,
    required this.addOnAmount,
    this.picked,
    this.disabled,
    this.onChange,
    this.onSelected,
    this.activeColor, //defaults to toggleableActiveColor,
    this.padding = const EdgeInsets.all(0.0),
    this.margin = const EdgeInsets.all(0.0),
  });

  @override
  ToppingRadioButtonGroupState createState() => ToppingRadioButtonGroupState();
}

class ToppingRadioButtonGroupState extends State<ToppingRadioButtonGroup> {
  int _selected = 0, _previousSelectedPos = 0;
  double mainAmount = 0, addOnAmount = 0;

  @override
  void initState() {
    super.initState();

    //set the selected to the picked (if not null)
    _selected = widget.picked ?? 0;
    //Select Default one
    _selected = widget.labels[0].id;
    addOnAmount = widget.addOnAmount;
    if (widget.customizeType == 1) {
      mainAmount = getDoubleFromDynamic(widget.labels[0].amount);
    } else {
      addOnAmount = addOnAmount + getDoubleFromDynamic(widget.labels[0].amount);
    }
    if (widget.onSelected != null) {
      widget.onSelected!(_selected, mainAmount, addOnAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    //set the selected to the picked (if not null)
    _selected = widget.picked ?? _selected;

    List<Widget> content = [];
    for (int i = 0; i < widget.labels.length; i++) {
      Radio rb = Radio(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeColor: widget.activeColor ?? colorPrimary,
        groupValue: _selected,
        value: widget.labels[i].id,

        //just changed the selected filter to current selection
        //since these are radio buttons, and you can only pick
        //one at a time
        onChanged: (var index) => setState(() {
          _selected = widget.labels.elementAt(i).id;

          if (widget.customizeType == 1) {
            mainAmount = getDoubleFromDynamic(widget.labels.elementAt(i).amount);
          } else {
            addOnAmount = (addOnAmount + getDoubleFromDynamic(widget.labels.elementAt(i).amount)) -
                getDoubleFromDynamic(widget.labels.elementAt(_previousSelectedPos).amount);
          }
          _previousSelectedPos = i;
          if (widget.onChange != null) widget.onChange!(widget.labels.elementAt(i).id, i);
          if (widget.onSelected != null) widget.onSelected!(widget.labels.elementAt(i).id, mainAmount, addOnAmount);
        }),
      );
      InkWell inkWell = InkWell(
        onTap: _previousSelectedPos == i
            ? null
            : () {
                if (rb.onChanged != null) {
                  rb.onChanged!(widget.labels.elementAt(i).id);
                }
              },
        child: Row(
          children: [
            Expanded(
              flex: 0,
              child: rb,
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.labels[i].name,
                textAlign: TextAlign.start,
                style: bodyText(fontSize: textSizeSmall, textColor: colorBlack, fontWeight: FontWeight.normal),
              ),
            ),
            Expanded(
              flex: 0,
              child: Row(
                children: [
                  (getDoubleFromDynamic(widget.labels[i].discountPrice ?? 0) > 0)
                      ? Text(
                          getAmountWithCurrency(getDoubleFromDynamic(widget.labels[i].discountPrice ?? 0)),
                          textAlign: TextAlign.start,
                          style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.normal)
                              .copyWith(decoration: TextDecoration.lineThrough),
                        )
                      : Container(),
                  Container(
                    margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                    child: Text(
                      getAmountWithCurrency(getDoubleFromDynamic(widget.labels[i].amount ?? 0)),
                      textAlign: TextAlign.start,
                      style: bodyText(fontSize: textSizeSmall, textColor: colorBlack, fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      content.add(inkWell);
    }

    return Container(
      padding: widget.padding,
      margin: widget.margin,
      child: Column(children: content),
    );
  }
}
