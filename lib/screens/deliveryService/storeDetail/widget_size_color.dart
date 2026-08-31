import 'package:flutter/material.dart';
import 'package:aerend_customer/utils/utils.dart';

class SizeColorWidget extends StatefulWidget {
  final int sizeOptional;
  final int colorOptional;
  final List sizeList;
  final List colorList;
  final Function validate;
  const SizeColorWidget({
    super.key,
    required this.sizeOptional,
    required this.colorOptional,
    required this.sizeList,
    required this.colorList,
    required this.validate,
  });

  @override
  SizeColorState createState() => SizeColorState();
}

class SizeColorState extends State<SizeColorWidget> {
  int checkedSize = 0;
  int checkedColor = 0;

  int getCheckedValue(List list, int optional, String prefKey) {
    if (list.isEmpty) return 0;
    final int prefSelectedId = prefGetInt(prefKey);
    final bool hasPrefSelection =
        list.any((item) => item is Map && item['id'] == prefSelectedId);
    if (hasPrefSelection) return prefSelectedId;
    return optional == 0 ? (list[0]['id'] ?? 0) : 0;
  }

  bool isOutOfStock(List list, int checkedId) {
    if (list.isEmpty) return false;
    final selectedItem = list.firstWhere(
      (item) => item['id'] == checkedId,
      orElse: () => null,
    );
    return selectedItem != null && selectedItem['stock'] == 0;
  }

  void validateSizeColor() {
    if (isOutOfStock(widget.sizeList, checkedSize) ||
        isOutOfStock(widget.colorList, checkedColor)) {
      widget.validate(false);
      return;
    }

    widget.validate(true);
  }

  @override
  initState() {
    super.initState();
    checkedSize = getCheckedValue(widget.sizeList, widget.sizeOptional, 'checkedSize');
    checkedColor =
        getCheckedValue(widget.colorList, widget.colorOptional, 'checkedColor');
    prefSetInt('checkedSize', checkedSize);
    prefSetInt('checkedColor', checkedColor);
    validateSizeColor();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.sizeList.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(languages.sizeLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: widget.sizeList.map((item) {
                  return GestureDetector(
                    onTap: () => setState(() {
                      checkedSize = item['id'];
                      prefSetInt('checkedSize', item['id']);
                      validateSizeColor();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: checkedSize == item['id']
                            ? item['stock'] == 1
                                ? colorGreen
                                : colorRed
                            : colorWhite,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: colorGray,
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Text(
                        item['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: checkedSize == item['id']
                              ? colorWhite
                              : item['stock'] == 1
                                  ? colorBlack
                                  : colorRed,
                        ),
                      ),
                    ),
                  );
                }).toList()),
              ),
              const SizedBox(height: 8),
              if (checkedSize != 0 &&
                  widget.sizeList.firstWhere(
                          (item) => item['id'] == checkedSize)['stock'] ==
                      0)
                Text(languages.outOfStock, style: const TextStyle(color: colorRed)),
            ],
          ),
        if (widget.colorList.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(languages.colorLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: widget.colorList.map((item) {
                  return GestureDetector(
                    onTap: () => setState(() {
                      checkedColor = item['id'];
                      prefSetInt('checkedColor', item['id']);
                      validateSizeColor();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: checkedColor == item['id']
                            ? item['stock'] == 1
                                ? colorGreen
                                : colorRed
                            : colorWhite,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: colorGray,
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Text(
                        item['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: checkedColor == item['id']
                              ? colorWhite
                              : item['stock'] == 1
                                  ? colorBlack
                                  : colorRed,
                        ),
                      ),
                    ),
                  );
                }).toList()),
              ),
              const SizedBox(height: 8),
              if (checkedColor != 0 &&
                  widget.colorList.firstWhere(
                          (item) => item['id'] == checkedColor)['stock'] ==
                      0)
                Text(languages.outOfStock, style: const TextStyle(color: colorRed)),
            ],
          )
      ],
    );
  }
}
