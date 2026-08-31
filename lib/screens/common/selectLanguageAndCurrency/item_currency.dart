import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'select_language_and_currency_dl.dart';

class ItemCurrency extends StatefulWidget {
  final List<CurrencyListItem> currencyList;
  final int defaultSelected;
  final Function(CurrencyListItem) onSelectionChanged;

  const ItemCurrency({super.key, required this.currencyList, required this.onSelectionChanged, this.defaultSelected = 0});

  @override
  State createState() => _ItemCurrencyState();
}

class _ItemCurrencyState extends State<ItemCurrency> {
  int selectedChoice = 0;

  @override
  void initState() {
    int index = 0;
    if (widget.currencyList.isNotEmpty) {
      if (widget.defaultSelected != 0) {
        selectedChoice = widget.defaultSelected;
        index = widget.currencyList.indexWhere((element) => element.currencyId == selectedChoice);
      } else {
        selectedChoice = widget.currencyList[0].currencyId;
      }
      widget.onSelectionChanged(widget.currencyList[index >= 0 ? index : 0]);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: deviceWidth * 0.035,
      children: widget.currencyList
          .map<Padding>((s) => Padding(
                padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                child: ChoiceChip(
                  label: Text("${s.currencyName} ${s.currencySymbol}"),
                  labelPadding: EdgeInsetsDirectional.only(
                      top: deviceHeight * 0.008, bottom: deviceHeight * 0.008, start: deviceWidth * 0.025, end: deviceWidth * 0.025),
                  labelStyle: bodyText(
                      textColor: selectedChoice == s.currencyId ? colorWhite : colorTextCommonLight,
                      fontSize: textSizeSmall,
                      fontWeight: FontWeight.w500),
                  backgroundColor: selectedChoice == s.currencyId ? colorPrimary : Colors.transparent,
                  selectedColor: selectedChoice == s.currencyId ? colorPrimary : Colors.transparent,
                  pressElevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.only(
                          topStart: Radius.circular(deviceAverageSize * 0.005),
                          topEnd: Radius.circular(deviceAverageSize * 0.005),
                          bottomStart: Radius.circular(deviceAverageSize * 0.005),
                          bottomEnd: Radius.circular(deviceAverageSize * 0.005)),
                      side: BorderSide(color: selectedChoice == s.currencyId ? colorPrimary : colorTextCommonLight)),
                  selected: selectedChoice == s.currencyId,
                  onSelected: (selected) {
                    setState(() {
                      selectedChoice = s.currencyId;
                      widget.onSelectionChanged(s);
                    });
                  },
                ),
              ))
          .toList(),
    );
  }
}
