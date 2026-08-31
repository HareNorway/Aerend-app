import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:aerend_customer/utils/utils.dart';

class ToppingOptionWidget extends StatefulWidget {
  final List optionList;
  final Function validate;
  const ToppingOptionWidget({
    super.key,
    required this.optionList,
    required this.validate,
  });

  @override
  ToppingOptionState createState() => ToppingOptionState();
}

class ToppingOptionState extends State<ToppingOptionWidget> {
  List checkedOptionList =
      jsonDecode(prefGetStringWithDefaultValue('checkedOptionList', '[]'));

  void validateAddOns() {
    for (int i = 0; i < widget.optionList.length; i++) {
      int selectionType = widget.optionList[i]['selection_type'];
      int optionalType = widget.optionList[i]['optional_type'];
      int minimum = 0;
      int maximum = 100;
      String message = '';

      if (selectionType == 1) {
        if (optionalType == 0) {
          minimum = 1;
          maximum = 1;
          message = 'At least one ${widget.optionList[i]['name']} is required.';
        } else {
          minimum = 0;
          maximum = 1;
        }
      } else {
        if (optionalType == 0) {
          minimum = widget.optionList[i]['minimum'] ?? 1;
          maximum = widget.optionList[i]['maximum'] ?? 6;
          message =
              'Select at least $minimum ~ $maximum ${widget.optionList[i]['name']}.';
        }
      }

      List options = widget.optionList[i]['options'];
      List selectedOptions =
          jsonDecode(prefGetStringWithDefaultValue('checkedOptionList', '[]'));
      int includedCount = options
          .where((option) => selectedOptions.contains(option['id']))
          .length;
      if (includedCount < minimum || includedCount > maximum) {
        prefSetString('checkedOptionList', '[]');
        widget.validate(message);
        return;
      }
    }
    widget.validate('');
  }

  @override
  void initState() {
    super.initState();
    validateAddOns();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.optionList.map((category) {
        List options = category['options'];
        bool isSingleChoice = category['selection_type'] == 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category['name'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: options.map((item) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSingleChoice) {
                        List categoryOptionIds =
                            options.map((e) => e['id']).toList();
                        if (checkedOptionList.contains(item['id'])) {
                          checkedOptionList.remove(item['id']);
                        } else {
                          checkedOptionList.removeWhere(
                              (id) => categoryOptionIds.contains(id));
                          checkedOptionList.add(item['id']);
                        }
                      } else {
                        checkedOptionList.contains(item['id'])
                            ? checkedOptionList.remove(item['id'])
                            : checkedOptionList.add(item['id']);
                      }
                      prefSetString(
                          'checkedOptionList', jsonEncode(checkedOptionList));
                    });
                    validateAddOns();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        checkedOptionList.contains(item['id'])
                            ? const Icon(Icons.check_circle,
                                color: colorPrimary)
                            : Icon(Icons.check_circle_outline,
                                color: colorMainLightGray.withOpacity(0.5)),
                        const SizedBox(width: 10),
                        Text(item['name'],
                            style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        Text(
                          'NOK ${item['amount']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}
