import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/utils.dart';

typedef SelectedDateValue = Function(DateTime);

class YearMonthPicker extends StatefulWidget {
  final DateTime maxDate, minDate;
  final SelectedDateValue callback;

  const YearMonthPicker(this.callback, {super.key, required this.minDate, required this.maxDate});

  @override
  State<StatefulWidget> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<YearMonthPicker> {
  DateTime? selectedDate, maxDate, minDate;
  int? displayedYear;
  PageController? pageController;

  @override
  void initState() {
    super.initState();
    minDate = widget.minDate;
    maxDate = widget.maxDate;
    selectedDate = minDate;
    displayedYear = selectedDate!.year;
    pageController = PageController(initialPage: displayedYear!);
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(builder: (context) {
              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                return IntrinsicWidth(
                  child: Column(children: [
                    buildHeader(),
                    Material(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [buildPager()],
                      ),
                    )
                  ]),
                );
              }
              return IntrinsicHeight(
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  buildHeader(),
                  Material(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [buildPager()],
                    ),
                  )
                ]),
              );
            }),
          ],
        ),
      );

  buildHeader() {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding:
            EdgeInsetsDirectional.only(top: deviceHeight * 0.018, start: deviceWidth * 0.04, end: deviceWidth * 0.025, bottom: deviceHeight * 0.005),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              DateFormat.yMMM().format(selectedDate!),
              style: bodyText(textColor: colorWhite, fontWeight: FontWeight.normal),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(DateFormat.y().format(DateTime(displayedYear!)), style: bodyText(textColor: colorWhite)),
                Row(
                  children: <Widget>[
                    minDate!.year < displayedYear!
                        ? IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up, color: colorWhite),
                            onPressed: () => pageController!.animateToPage(
                              displayedYear! - 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ),
                          )
                        : Container(),
                    maxDate!.year > displayedYear!
                        ? IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down, color: colorWhite),
                            onPressed: () => pageController!.animateToPage(
                              displayedYear! + 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ),
                          )
                        : Container(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  buildPager() => Container(
        color: colorWhite,
        height: deviceHeight * 0.3,
        width: deviceWidth * 0.9,
        child: Theme(
            data: Theme.of(context).copyWith(
                buttonTheme: ButtonThemeData(padding: const EdgeInsets.all(0.0), shape: const CircleBorder(), minWidth: deviceWidth * 0.002)),
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  displayedYear = index;
                });
              },
              itemBuilder: (context, year) {
                return GridView.count(
                  padding: EdgeInsets.all(deviceAverageSize * 0.02),
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 5,
                  children: List<int>.generate(12, (i) => i + 1)
                      .map((month) => DateTime(year, month))
                      .map(
                        (date) => Padding(
                          padding: EdgeInsets.all(deviceAverageSize * 0.008),
                          child: TextButton(
                            onPressed: () => setState(() {
                              selectedDate = DateTime(date.year, date.month);
                              widget.callback(date);
                            }),
                            style: TextButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor: date.month == selectedDate!.month && date.year == selectedDate!.year ? colorPrimary : null,
                            ),
                            child: Text(
                              DateFormat.MMM().format(date),
                              style: bodyText(
                                textColor: date.month == selectedDate!.month && date.year == selectedDate!.year
                                    ? colorWhite
                                    : date.month == DateTime.now().month && date.year == DateTime.now().year
                                        ? colorPrimary
                                        : colorBlack,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            )),
      );
}
