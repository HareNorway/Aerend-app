import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../manageCard/manage_card_dl.dart';

class RbGroupSelectPaymentMethod extends StatefulWidget {
  /// A list of strings that describes each Radio button. Each label must be distinct.
  final List<CardListItem> labels;

  /// Specifies which Radio button to automatically pick.
  /// Every element must match a label.
  /// This is useful for clearing what is picked (set it to "").
  /// If this is non-null, then the user must handle updating this; otherwise, the state of the RadioButtonGroup won't change.
  final int? picked;

  /// Called when the value of the RadioButtonGroup changes.
  final void Function(int label, int index)? onChange;

  /// Called when the user makes a selection.
  final void Function(int selected)? onSelected;

  //RADIO BUTTON FIELDS
  /// The color to use when a Radio button is checked.
  final Color? activeColor;

  //SPACING STUFF
  /// Empty space in which to inset the RadioButtonGroup.
  final EdgeInsetsGeometry padding;

  /// Empty space surrounding the RadioButtonGroup.
  final EdgeInsetsGeometry margin;

  const RbGroupSelectPaymentMethod({
    super.key,
    required this.labels,
    this.picked,
    this.onChange,
    this.onSelected,
    this.activeColor, //defaults to toggleableActiveColor,
    this.padding = const EdgeInsets.all(0.0),
    this.margin = const EdgeInsets.all(0.0),
  });

  @override
  RbGroupSelectPaymentMethodState createState() => RbGroupSelectPaymentMethodState();
}

class RbGroupSelectPaymentMethodState extends State<RbGroupSelectPaymentMethod> {
  int _selected = 0, _previousSelectedPos = -1;

  @override
  void initState() {
    super.initState();
    //Select Default one
    _selected = widget.picked ?? 0;
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
        value: widget.labels[i].cardId,

        //just changed the selected filter to current selection
        //since these are radio buttons, and you can only pick
        //one at a time
        onChanged: (var index) => setState(() {
          _selected = widget.labels.elementAt(i).cardId;
          _previousSelectedPos = i;
          if (widget.onChange != null) widget.onChange!(widget.labels.elementAt(i).cardId, i);
          if (widget.onSelected != null) widget.onSelected!(widget.labels.elementAt(i).cardId);
        }),
      );
      InkWell inkWell = InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: _previousSelectedPos == i
            ? null
            : () {
                if (rb.onChanged != null) {
                  rb.onChanged!(widget.labels.elementAt(i).cardId);
                }
              },
        child: Container(
          margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.006, bottom: deviceHeight * 0.006),
          padding:
              EdgeInsetsDirectional.only(top: deviceHeight * 0.01, bottom: deviceHeight * 0.01, start: deviceWidth * 0.01, end: deviceWidth * 0.01),
          decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.008)), color: colorMainBackground),
          child: Row(
            children: [
              Expanded(
                flex: 0,
                child: Theme(
                  data: Theme.of(context).copyWith(unselectedWidgetColor: colorMainGray),
                  child: rb,
                ),
              ),
              Expanded(
                flex: 0,
                child: Container(
                  margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                  child: Icon(CustomIcons.selectCardAddCard,
                      size: deviceAverageSize * 0.055, color: _selected == widget.labels[i].cardId ? colorPrimary : colorMainGray),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.04),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.008),
                        child: Text(
                          widget.labels[i].cardHolderName,
                          textAlign: TextAlign.start,
                          style: bodyText(fontSize: textSizeSmall, textColor: colorBlack, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        widget.labels[i].cardNumber,
                        textAlign: TextAlign.start,
                        style: bodyText(fontSize: textSizeSmall, textColor: colorTextCommonLight),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
