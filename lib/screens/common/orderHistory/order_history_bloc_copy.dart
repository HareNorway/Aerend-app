import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../main.dart';
import 'deliveriesHistory/deliveries_history_bloc.dart';
import 'order_history_dl.dart';
import 'rideHistory/rides_history_bloc.dart';

class OrderHistoryBloc extends Bloc {
  BuildContext context;

  late RidesHistoryBloc ridesHistoryBloc;
  late DeliveriesHistoryBloc deliveriesHistoryBloc;

  State<StatefulWidget> state;

  OrderHistoryBloc(this.context, this.state) {
    ridesHistoryBloc = RidesHistoryBloc(context, state);
    deliveriesHistoryBloc = DeliveriesHistoryBloc(context, state);
    getFilterData();
  }

  final _filterListController = BehaviorSubject<List<HistoryFilterModel>>();
  final _selectedFilterController = BehaviorSubject<HistoryFilterModel>();

  Stream<List<HistoryFilterModel>> get streamFilterList =>
      _filterListController.stream;

  Stream<HistoryFilterModel> get streamSelectedFilter =>
      _selectedFilterController.stream;

  Function(List<HistoryFilterModel>) get changeFilterList =>
      _filterListController.sink.add;

  changeSelectedFilter(HistoryFilterModel? data) {
    if (data != null) {
      _selectedFilterController.sink.add(data);
      ridesHistoryBloc.setFilterType(data.filterType);
      deliveriesHistoryBloc.setFilterType(data.filterType);
    }
  }

  getFilterData() {
    List<HistoryFilterModel> filterList = [];
    filterList.add(HistoryFilterModel(1, languages.filterToday));
    filterList.add(HistoryFilterModel(5, languages.filterUpcoming));
    filterList.add(HistoryFilterModel(2, languages.filterLast7Days));
    filterList.add(HistoryFilterModel(3, languages.filterThisMonth));
    filterList.add(HistoryFilterModel(4, languages.filterYear));
    filterList.add(HistoryFilterModel(0, languages.filterAll));
    changeSelectedFilter(filterList[0]);
    changeFilterList(filterList);
  }

  @override
  void dispose() {
    _filterListController.close();
    _selectedFilterController.close();
    ridesHistoryBloc.dispose();
    deliveriesHistoryBloc.dispose();
  }
}
