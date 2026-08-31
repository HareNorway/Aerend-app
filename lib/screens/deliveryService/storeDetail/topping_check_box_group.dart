import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'store_detail_dl.dart';

class ToppingCheckboxGroup extends StatefulWidget {
  /// A list of strings that describes each Checkbox. Each label must be distinct.
  final List<OptionsItem> labels;

  /// Specifies which boxes to be automatically check.
  /// Every element must match a label.
  /// This is useful for clearing all selections (set it to []).
  /// If this is non-null, then the user must handle updating this list; otherwise, the state of the CheckboxGroup won't change.
  final List<int>? checked;

  /// Specifies which boxes should be disabled.
  /// If this is non-null, no boxes will be disabled.
  /// The strings passed to this must match the labels.
  final List<String>? disabled;

  /// Called when the value of the CheckboxGroup changes.
  final void Function(bool isChecked, OptionsItem label, int index)? onChange;

  /// Called when the user makes a selection.
  final void Function(List<int> selected, bool isChecked, double amount) onSelected;

  /// The style to use for the labels.
  final TextStyle labelStyle;

  /// Called when needed to build a CheckboxGroup element.
  final Widget Function(Checkbox checkBox, Text label, int index)? itemBuilder;

  //THESE FIELDS ARE FOR THE CHECKBOX

  /// The color to use when a Checkbox is checked.
  final Color? activeColor;

  /// The color to use for the check icon when a Checkbox is checked.
  final Color checkColor;

  /// If true the checkbox's value can be true, false, or null.
  final bool tristate;

  //SPACING STUFF

  /// Empty space in which to inset the CheckboxGroup.
  final EdgeInsetsGeometry padding;

  /// Empty space surrounding the CheckboxGroup.
  final EdgeInsetsGeometry margin;

  const ToppingCheckboxGroup({
    super.key,
    required this.labels,
    this.checked,
    this.disabled,
    this.onChange,
    required this.onSelected,
    this.labelStyle = const TextStyle(),
    this.activeColor, //defaults to toggleableActiveColor,
    this.checkColor = const Color(0xFFFFFFFF),
    this.tristate = false,
    this.itemBuilder,
    this.padding = const EdgeInsets.all(0.0),
    this.margin = const EdgeInsets.all(0.0),
  });

  @override
  ToppingCheckboxGroupState createState() => ToppingCheckboxGroupState();
}

class ToppingCheckboxGroupState extends State<ToppingCheckboxGroup> {
  List<int> _selected = [];
  double amount = 0;

  @override
  void initState() {
    super.initState();

    //set the selected to the checked (if not null)
    _selected = widget.checked ?? [];
  }

  @override
  Widget build(BuildContext context) {
    //set the selected to the checked (if not null)
    if (widget.checked != null) {
      _selected = [];
      _selected.addAll(widget.checked!); //use add all to prevent a shallow copy
    }

    List<Widget> content = [];

    for (int i = 0; i < widget.labels.length; i++) {
      Checkbox cb = Checkbox(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        value: _selected.contains(widget.labels.elementAt(i).id),
        onChanged: (bool? isChecked) => onChanged(isChecked ?? false, i),
        checkColor: widget.checkColor,
        activeColor: widget.activeColor ?? colorPrimary,
        tristate: widget.tristate,
      );

      InkWell inkWell = InkWell(
        onTap: () {
          if (cb.onChanged != null) {
            if (_selected.contains(widget.labels.elementAt(i).id)) {
              return cb.onChanged!(false);
            } else {
              return cb.onChanged!(true);
            }
          }
        },
        child: Row(
          children: [
            Expanded(
              flex: 0,
              child: cb,
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
                  (double.parse((widget.labels[i].discountPrice ?? 0).toString()) > 0)
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

  void onChanged(bool isChecked, int i) {
    bool isAlreadyContained = _selected.contains(widget.labels.elementAt(i).id);

    if (mounted) {
      setState(() {
        if (!isChecked && isAlreadyContained) {
          _selected.remove(widget.labels.elementAt(i).id);
        } else if (isChecked && !isAlreadyContained) {
          _selected.add(widget.labels.elementAt(i).id);
        }

        if (widget.onChange != null) widget.onChange!(isChecked, widget.labels.elementAt(i), i);
        widget.onSelected(_selected, isChecked, getDoubleFromDynamic(widget.labels.elementAt(i).amount));
      });
    }
  }
}
