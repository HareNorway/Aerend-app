import '../screens/rideService/searched_location_dl.dart';

class SearchedLocationItemState {
  final List<SearchedLocation>? searchedLocationItemsList;

  SearchedLocationItemState({this.searchedLocationItemsList});

  factory SearchedLocationItemState.initial() {
    return SearchedLocationItemState(searchedLocationItemsList: []);
  }

  static SearchedLocationItemState? fromJson(dynamic json) {
    return json != null
        ? SearchedLocationItemState(
            searchedLocationItemsList: parseList(json),
          )
        : null;
  }

  dynamic toJson() {
    return {'searchedLocationItemsList': searchedLocationItemsList!.map((searchedLocationItems) => searchedLocationItems.toJson()).toList()};
  }

  SearchedLocationItemState copyWith({List<SearchedLocation>? searchedLocationItemsList}) {
    return SearchedLocationItemState(searchedLocationItemsList: searchedLocationItemsList ?? this.searchedLocationItemsList);
  }
}

List<SearchedLocation> parseList(dynamic json) {
  List<SearchedLocation> list = [];
  json["searchedLocationItemsList"].forEach((item) => list.add(SearchedLocation.fromJson(item)!));
  return list;
}
