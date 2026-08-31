import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'select_language_and_currency_dl.dart';

class ItemLanguage extends StatefulWidget {
  final List<LanguageListItem> languageList;
  final int defaultSelected;
  final Function(LanguageListItem) onSelectionChanged;

  const ItemLanguage({super.key, required this.languageList, required this.onSelectionChanged, this.defaultSelected = 0});

  @override
  State createState() => _ItemLanguageState();
}

class _ItemLanguageState extends State<ItemLanguage> {
  LanguageListItem? selectedChoice;

  @override
  void initState() {
    if (widget.languageList.isNotEmpty) {
      if (widget.defaultSelected != -1) {
        selectedChoice = widget.languageList[widget.defaultSelected];
      } else {
        selectedChoice = widget.languageList[0];
      }
      widget.onSelectionChanged(selectedChoice!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: deviceWidth * 0.035,
      children: widget.languageList
          .map<Padding>((s) => Padding(
                padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                child: ChoiceChip(
                  label: Text(s.languageName),
                  labelPadding: EdgeInsetsDirectional.only(
                      top: deviceHeight * 0.008, bottom: deviceHeight * 0.008, start: deviceWidth * 0.025, end: deviceWidth * 0.025),
                  labelStyle: bodyText(
                      textColor: selectedChoice!.languageCode == s.languageCode ? colorWhite : colorTextCommonLight,
                      fontSize: textSizeSmall,
                      fontWeight: FontWeight.w500),
                  backgroundColor: selectedChoice!.languageCode == s.languageCode ? colorPrimary : Colors.transparent,
                  selectedColor: selectedChoice!.languageCode == s.languageCode ? colorPrimary : Colors.transparent,
                  pressElevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.only(
                          topStart: Radius.circular(deviceAverageSize * 0.005),
                          topEnd: Radius.circular(deviceAverageSize * 0.005),
                          bottomStart: Radius.circular(deviceAverageSize * 0.005),
                          bottomEnd: Radius.circular(deviceAverageSize * 0.005)),
                      side: BorderSide(color: selectedChoice!.languageCode == s.languageCode ? colorPrimary : colorTextCommonLight)),
                  selected: selectedChoice!.languageCode == s.languageCode,
                  onSelected: (selected) {
                    setState(() {
                      selectedChoice = s;
                      widget.onSelectionChanged(selectedChoice!);
                    });
                  },
                ),
              ))
          .toList(),
    );
  }
}
