import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../commonView/dropdown_button2.dart';
import '../../../utils/utils.dart';
import 'deliveriesHistory/deliveries_history.dart';
import 'deliveriesHistory/deliveries_history_dl.dart';
import 'order_history_bloc_copy.dart';
import 'order_history_dl.dart';
import 'rideHistory/rides_history.dart';
import 'rideHistory/rides_history_dl.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  OrderHistoryState createState() => OrderHistoryState();
}

class OrderHistoryState extends State<OrderHistory> {
  OrderHistoryBloc? _bloc;
  final PagingController<int, RidesItem> _rideHistoryPC =
      PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);
  final PagingController<int, DeliveriesHistoryItem> _deliveriesHistoryPC =
      PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  @override
  void didChangeDependencies() {
    _bloc = _bloc ?? OrderHistoryBloc(context, this);
    _rideHistoryPC.addPageRequestListener((pageKey) {
      _bloc?.ridesHistoryBloc.getRideHistory(pageKey, _rideHistoryPC);
    });
    _deliveriesHistoryPC.addPageRequestListener((pageKey) {
      _bloc?.deliveriesHistoryBloc
          .getDSOrderHistory(pageKey, _deliveriesHistoryPC);
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 0,
        ),
        backgroundColor: colorMainBackground,
        body: _buildOrderHistory(context),
      ),
    );
  }

  _buildOrderHistory(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: colorWhite),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: 0,
            child: TabBar(
              onTap: (value) {},
              tabs: [
                Tab(
                  child: Text(
                    languages.courier,
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    languages.deliveries,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              labelPadding: EdgeInsetsDirectional.zero,
              unselectedLabelStyle: bodyText(
                  fontSize: textSizeSmall,
                  fontWeight: FontWeight.bold,
                  textColor: colorTextCommonLight),
              labelStyle: bodyText(
                  fontSize: textSizeSmall, fontWeight: FontWeight.bold),
              unselectedLabelColor: colorMainTabTextColor,
              labelColor: colorPrimary,
              indicatorColor: colorPrimaryDark,
            ),
          ),
          Expanded(
            flex: 0,
            child: Container(
              alignment: AlignmentDirectional.center,
              width: deviceWidth,
              height: deviceHeight * 0.05,
              color: colorPrimary,
              child: filterSp(),
            ),
          ),
          Expanded(
            flex: 1,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                RideHistory(
                  bloc: _bloc!.ridesHistoryBloc,
                  pagingController: _rideHistoryPC,
                ),
                DeliveriesHistory(
                  bloc: _bloc!.deliveriesHistoryBloc,
                  pagingController: _deliveriesHistoryPC,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  filterSp() => StreamBuilder(
        stream: _bloc!.streamFilterList,
        builder: (context, snapshot) {
          final results = snapshot.data;
          if (results == null) {
            return _circularProgressIndicator();
          }
          return StreamBuilder<HistoryFilterModel>(
            stream: _bloc!.streamSelectedFilter,
            builder: (context, selectedItemSnapshot) {
              if (!selectedItemSnapshot.hasData) {
                return _circularProgressIndicator();
              }
              return DropdownButton2<HistoryFilterModel>(
                value: selectedItemSnapshot.data,
                onChanged: (data) {
                  _bloc?.changeSelectedFilter(data);
                  _rideHistoryPC.notifyPageRequestListeners(1);
                  _deliveriesHistoryPC.notifyPageRequestListeners(1);
                },
                isExpanded: true,
                iconSize: 0,
                underline: Container(),
                selectedItemBuilder: (BuildContext context) {
                  return results.map<Widget>((HistoryFilterModel value) {
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              selectedItemSnapshot.data?.filterName ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bodyText(
                                  fontSize: textSizeSmall,
                                  textColor: colorWhite,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: colorWhite,
                            size: deviceHeight * 0.03,
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                items: results.map<DropdownMenuItem<HistoryFilterModel>>(
                    (HistoryFilterModel e) {
                  return DropdownMenuItem<HistoryFilterModel>(
                    value: e,
                    child: Center(
                      child: Text(
                        e.filterName,
                        textAlign: TextAlign.center,
                        style: bodyText(
                            fontSize: textSizeSmall,
                            textColor: colorBlack,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      );

  _circularProgressIndicator() {
    return CommonCircularProgressIndicator(
      strokeWidth: deviceHeight * cpiStrokeWidthSmallest,
      size: deviceHeight * cpiSizeSmallest,
      color: colorWhite,
    );
  }
}
