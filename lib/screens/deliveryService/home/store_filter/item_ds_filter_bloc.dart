import '../../../../blocs/bloc.dart';
import '../filter_model.dart';

class ItemDsFilterBloc extends Bloc {
  final List<FilterModel> filterCuisine = [];
  final List<FilterModel> filterList = [];
  final List<FilterModel> filterSort = [];

  final enableButton = BehaviorSubject<bool>();

  ItemDsFilterBloc(List<FilterModel> filterCuisine, List<FilterModel> filterList, List<FilterModel> filterSort) {
    this.filterCuisine.addAll(filterCuisine.map((e) => FilterModel(filter: e.filter, filterName: e.filterName, isSelect: e.isSelect)));
    this.filterList.addAll(filterList.map((e) => FilterModel(filter: e.filter, filterName: e.filterName, isSelect: e.isSelect)));
    this.filterSort.addAll(filterSort.map((e) => FilterModel(filter: e.filter, filterName: e.filterName, isSelect: e.isSelect)));

    enableDisableButton();
  }

  enableDisableButton() {
    var l1 = filterCuisine.where((element) => element.isSelect);
    var l2 = filterList.where((element) => element.isSelect);
    var l3 = filterSort.where((element) => element.isSelect);

    if (l1.isNotEmpty || l2.isNotEmpty || l3.isNotEmpty) {
      enableButton.add(true);
    } else {
      enableButton.add(false);
    }
  }

  @override
  void dispose() {
    enableButton.close();
  }
}
