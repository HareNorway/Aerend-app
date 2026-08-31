import 'package:flutter/material.dart';

import '../../../../commonView/common_view.dart';
import '../../../../utils/utils.dart';
import '../filter_model.dart';
import 'item_ds_filter.dart';
import 'item_ds_filter_bloc.dart';

class StoreFilterBottomSheet extends StatefulWidget {
  final Function(bool, bool) applyFilter;
  final List<FilterModel> filterCuisine;
  final List<FilterModel> filterList;
  final List<FilterModel> filterSort;

  const StoreFilterBottomSheet(
      {super.key, required this.applyFilter, required this.filterCuisine, required this.filterList, required this.filterSort});

  @override
  State createState() => _StoreFilterBottomSheetState();
}

class _StoreFilterBottomSheetState extends State<StoreFilterBottomSheet> {
  late ItemDsFilterBloc itemDsFilterBloc;

  @override
  void initState() {
    itemDsFilterBloc = ItemDsFilterBloc(widget.filterCuisine, widget.filterList, widget.filterSort);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isFood = prefGetInt(prefSelectedServiceCateId) == 5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: deviceHeight * 0.02),
      decoration: const BoxDecoration(
        borderRadius: BorderRadiusDirectional.vertical(top: Radius.circular(20)),
        color: colorWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.015),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                  languages.filterYourSearch,
                  style: headerText(fontWeight: FontWeight.bold),
                )),
                InkWell(
                  child: const Icon(Icons.close),
                  onTap: () {
                    widget.applyFilter(false, true);
                  },
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (itemDsFilterBloc.filterCuisine.isNotEmpty)
                    Text(
                      isFood ? languages.selectCuisine : languages.selectCategories,
                      style: bodyText(fontWeight: FontWeight.bold, fontSize: textSizeSmall),
                    ),
                  ItemDsFilter(itemList: itemDsFilterBloc.filterCuisine, onSelectionChanged: (s) => itemDsFilterBloc.enableDisableButton()),
                  SizedBox(height: deviceHeight * 0.02),
                  Text(
                    isFood ? languages.filterRestaurantWith : languages.filterStoreWith,
                    style: bodyText(fontWeight: FontWeight.bold, fontSize: textSizeSmall),
                  ),
                  ItemDsFilter(itemList: itemDsFilterBloc.filterList, onSelectionChanged: (s) => itemDsFilterBloc.enableDisableButton()),
                  SizedBox(height: deviceHeight * 0.02),
                  Text(
                    languages.sort,
                    style: bodyText(fontWeight: FontWeight.bold, fontSize: textSizeSmall),
                  ),
                  ItemDsFilter(
                      itemList: itemDsFilterBloc.filterSort,
                      singleSelection: true,
                      onSelectionChanged: (s) => itemDsFilterBloc.enableDisableButton()),
                  SizedBox(height: deviceHeight * 0.02),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: CustomRoundedButton(context, languages.reset, () {
                widget.applyFilter(false, false);
              },
                      setBorder: true,
                      textColor: colorTextCommon,
                      fontWeight: FontWeight.bold,
                      minHeight: commonBtnHeightMedium,
                      roundedRectangleBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadiusDirectional.all(Radius.circular(deviceAverageSize * 0.008)),
                      ))),
              SizedBox(width: deviceWidth * 0.02),
              Expanded(
                  child: StreamBuilder<bool>(
                      stream: itemDsFilterBloc.enableButton,
                      builder: (context, snapshot) {
                        bool enableButton = snapshot.data ?? false;
                        return CustomRoundedButton(
                            context,
                            languages.applyFilter,
                            enableButton
                                ? () {
                                    widget.filterCuisine.clear();
                                    widget.filterCuisine.addAll(itemDsFilterBloc.filterCuisine.map((e) {
                                      return e;
                                    }));
                                    widget.filterList.clear();
                                    widget.filterList.addAll(itemDsFilterBloc.filterList.map((e) => e));
                                    widget.filterSort.clear();
                                    widget.filterSort.addAll(itemDsFilterBloc.filterSort.map((e) => e));

                                    widget.applyFilter(true, false);
                                  }
                                : null,
                            fontWeight: FontWeight.bold,
                            elevation: 0,
                            minHeight: commonBtnHeightMedium,
                            roundedRectangleBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadiusDirectional.all(Radius.circular(deviceAverageSize * 0.008)),
                            ));
                      })),
            ],
          ),
          SizedBox(
            height: deviceHeight * 0.02,
          ),
        ],
      ),
    );
  }
}
