import 'package:flutter/material.dart';

import '../../../../utils/utils.dart';
import '../filter_model.dart';

class ItemDsFilter extends StatefulWidget {
  final List<FilterModel> itemList;
  final String defaultSelected;
  final bool singleSelection;
  final Function(List<FilterModel>) onSelectionChanged;

  const ItemDsFilter({
    super.key,
    required this.itemList,
    required this.onSelectionChanged,
    this.singleSelection = false,
    this.defaultSelected = defaultLanguage,
  });

  @override
  State createState() => _ItemDsFilterState();
}

class _ItemDsFilterState extends State<ItemDsFilter> {
  FilterModel? oldSelection;

  @override
  void initState() {
    super.initState();
    for (FilterModel filterModel in widget.itemList) {
      if (filterModel.isSelect) {
        oldSelection = filterModel;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: deviceWidth * 0.035,
      children: widget.itemList
          .map<ChoiceChip>((filterModel) => ChoiceChip(
                label: Text(filterModel.filterName ?? ""),
                labelStyle: bodyText(
                    textColor: filterModel.isSelect? colorWhite : colorTextCommonLight, fontSize: textSizeSmallest, fontWeight: FontWeight.w600),
                backgroundColor: filterModel.isSelect? colorPrimary : Colors.transparent,
                selectedColor: filterModel.isSelect? colorPrimary : Colors.transparent,
                pressElevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusDirectional.all(Radius.circular(deviceAverageSize * 0.007)),
                    side: BorderSide(color: filterModel.isSelect? colorPrimary : colorTextCommonLight)),
                selected: filterModel.isSelect,
                onSelected: (selected) {
                  setState(() {
                    filterModel.isSelect = !filterModel.isSelect;

                    if (widget.singleSelection) {
                      if (oldSelection != filterModel) {
                        oldSelection?.isSelect = false;
                      }
                    }
                    oldSelection = filterModel;
                    widget.onSelectionChanged(widget.itemList);
                  });
                },
              ))
          .toList(),
    );
  }
}
