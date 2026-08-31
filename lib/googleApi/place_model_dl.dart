/// predictions : [{"description":"Rajkot, Gujarat, India","matched_substrings":[{"length":5,"offset":0}],"place_id":"ChIJD98cx4rJWTkRO62Tvs8V3XY","reference":"ChIJD98cx4rJWTkRO62Tvs8V3XY","structured_formatting":{"main_text":"Rajkot","main_text_matched_substrings":[{"length":5,"offset":0}],"secondary_text":"Gujarat, India"},"terms":[{"offset":0,"value":"Rajkot"},{"offset":8,"value":"Gujarat"},{"offset":17,"value":"India"}],"types":["locality","political","geocode"]},{"description":"Rajkot Airport, Gandhigram, Rajkot, Gujarat, India","matched_substrings":[{"length":5,"offset":0}],"place_id":"ChIJIfj9KYzJWTkRKGuWqzn_cNg","reference":"ChIJIfj9KYzJWTkRKGuWqzn_cNg","structured_formatting":{"main_text":"Rajkot Airport","main_text_matched_substrings":[{"length":5,"offset":0}],"secondary_text":"Gandhigram, Rajkot, Gujarat, India"},"terms":[{"offset":0,"value":"Rajkot Airport"},{"offset":16,"value":"Gandhigram"},{"offset":28,"value":"Rajkot"},{"offset":36,"value":"Gujarat"},{"offset":45,"value":"India"}],"types":["airport","point_of_interest","establishment"]},{"description":"Rajkot S.T Bus Stand, Karanpara, Rajkot, Gujarat","matched_substrings":[{"length":5,"offset":0}],"place_id":"ChIJ80oxig_KWTkRA8Na6qjJa5s","reference":"ChIJ80oxig_KWTkRA8Na6qjJa5s","structured_formatting":{"main_text":"Rajkot S.T Bus Stand","main_text_matched_substrings":[{"length":5,"offset":0}],"secondary_text":"Karanpara, Rajkot, Gujarat"},"terms":[{"offset":0,"value":"Rajkot S.T Bus Stand"},{"offset":22,"value":"Karanpara"},{"offset":33,"value":"Rajkot"},{"offset":41,"value":"Gujarat"}],"types":["bus_station","transit_station","point_of_interest","establishment"]},{"description":"Rajkot Railway Station, Railway Station Road, Junction Plot, Rajkot, Gujarat, India","matched_substrings":[{"length":5,"offset":0}],"place_id":"ChIJ75chAG3JWTkRoFci2AKTqfQ","reference":"ChIJ75chAG3JWTkRoFci2AKTqfQ","structured_formatting":{"main_text":"Rajkot Railway Station","main_text_matched_substrings":[{"length":5,"offset":0}],"secondary_text":"Railway Station Road, Junction Plot, Rajkot, Gujarat, India"},"terms":[{"offset":0,"value":"Rajkot Railway Station"},{"offset":24,"value":"Railway Station Road"},{"offset":46,"value":"Junction Plot"},{"offset":61,"value":"Rajkot"},{"offset":69,"value":"Gujarat"},{"offset":78,"value":"India"}],"types":["point_of_interest","establishment"]},{"description":"Rajkot Central Bus Station, Dhebar Road, Karanpara, Rajkot, Gujarat, India","matched_substrings":[{"length":5,"offset":0}],"place_id":"ChIJUcXtjQ_KWTkRMpRu6dbrVvE","reference":"ChIJUcXtjQ_KWTkRMpRu6dbrVvE","structured_formatting":{"main_text":"Rajkot Central Bus Station","main_text_matched_substrings":[{"length":5,"offset":0}],"secondary_text":"Dhebar Road, Karanpara, Rajkot, Gujarat, India"},"terms":[{"offset":0,"value":"Rajkot Central Bus Station"},{"offset":28,"value":"Dhebar Road"},{"offset":41,"value":"Karanpara"},{"offset":52,"value":"Rajkot"},{"offset":60,"value":"Gujarat"},{"offset":69,"value":"India"}],"types":["point_of_interest","establishment"]}]
/// status : "OK"
library;

class PlaceModel {
  List<Predictions>? _predictions;
  String? _status;

  List<Predictions>? get predictions => _predictions;

  String? get status => _status;

  PlaceModel({List<Predictions>? predictions, String? status}) {
    _predictions = predictions;
    _status = status;
  }

  PlaceModel.fromJson(dynamic json) {
    if (json["predictions"] != null) {
      _predictions = [];
      json["predictions"].forEach((v) {
        _predictions!.add(Predictions.fromJson(v));
      });
    }
    _status = json["status"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_predictions != null) {
      map["predictions"] = _predictions!.map((v) => v.toJson()).toList();
    }
    map["status"] = _status;
    return map;
  }
}

/// description : "Rajkot, Gujarat, India"
/// matched_substrings : [{"length":5,"offset":0}]
/// place_id : "ChIJD98cx4rJWTkRO62Tvs8V3XY"
/// reference : "ChIJD98cx4rJWTkRO62Tvs8V3XY"
/// structured_formatting : {"main_text":"Rajkot","main_text_matched_substrings":[{"length":5,"offset":0}],"secondary_text":"Gujarat, India"}
/// terms : [{"offset":0,"value":"Rajkot"},{"offset":8,"value":"Gujarat"},{"offset":17,"value":"India"}]
/// types : ["locality","political","geocode"]

class Predictions {
  String? _description;
  List<MatchedSubstring>? _matchedSubstrings;
  String? _placeId;
  String? _reference;
  StructuredFormatting? _structuredFormatting;
  List<Terms>? _terms;
  List<String>? _types;

  String? get description => _description;

  List<MatchedSubstring>? get matchedSubstrings => _matchedSubstrings;

  String? get placeId => _placeId;

  String? get reference => _reference;

  StructuredFormatting? get structuredFormatting => _structuredFormatting;

  List<Terms>? get terms => _terms;

  List<String>? get types => _types;

  Predictions(
      {String? description,
      List<MatchedSubstring>? matchedSubstrings,
      String? placeId,
      String? reference,
      StructuredFormatting? structuredFormatting,
      List<Terms>? terms,
      List<String>? types}) {
    _description = description;
    _matchedSubstrings = matchedSubstrings;
    _placeId = placeId;
    _reference = reference;
    _structuredFormatting = structuredFormatting;
    _terms = terms;
    _types = types;
  }

  Predictions.fromJson(dynamic json) {
    _description = json["description"];
    if (json["matched_substrings"] != null) {
      _matchedSubstrings = [];
      json["matched_substrings"].forEach((v) {
        _matchedSubstrings!.add(MatchedSubstring.fromJson(v));
      });
    }
    _placeId = json["place_id"];
    _reference = json["reference"];
    _structuredFormatting = json["structured_formatting"] != null ? StructuredFormatting.fromJson(json["structured_formatting"]) : null;
    if (json["terms"] != null) {
      _terms = [];
      json["terms"].forEach((v) {
        _terms!.add(Terms.fromJson(v));
      });
    }
    _types = json["types"] != null ? json["types"].cast<String>() : [];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["description"] = _description;
    if (_matchedSubstrings != null) {
      map["matched_substrings"] = _matchedSubstrings!.map((v) => v.toJson()).toList();
    }
    map["place_id"] = _placeId;
    map["reference"] = _reference;
    if (_structuredFormatting != null) {
      map["structured_formatting"] = _structuredFormatting!.toJson();
    }
    if (_terms != null) {
      map["terms"] = _terms!.map((v) => v.toJson()).toList();
    }
    map["types"] = _types;
    return map;
  }
}

/// offset : 0
/// value : "Rajkot"

class Terms {
  int? _offset;
  String? _value;

  int? get offset => _offset;

  String? get value => _value;

  Terms({int? offset, String? value}) {
    _offset = offset;
    _value = value;
  }

  Terms.fromJson(dynamic json) {
    _offset = json["offset"];
    _value = json["value"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["offset"] = _offset;
    map["value"] = _value;
    return map;
  }
}

/// main_text : "Rajkot"
/// main_text_matched_substrings : [{"length":5,"offset":0}]
/// secondary_text : "Gujarat, India"

class StructuredFormatting {
  String? _mainText;
  List<MainTextMatchedSubstring>? _mainTextMatchedSubstrings;
  String? _secondaryText;

  String? get mainText => _mainText;

  List<MainTextMatchedSubstring>? get mainTextMatchedSubstrings => _mainTextMatchedSubstrings;

  String? get secondaryText => _secondaryText;

  StructuredFormatting({String? mainText, List<MainTextMatchedSubstring>? mainTextMatchedSubstrings, String? secondaryText}) {
    _mainText = mainText;
    _mainTextMatchedSubstrings = mainTextMatchedSubstrings;
    _secondaryText = secondaryText;
  }

  StructuredFormatting.fromJson(dynamic json) {
    _mainText = json["main_text"];
    if (json["main_text_matched_substrings"] != null) {
      _mainTextMatchedSubstrings = [];
      json["main_text_matched_substrings"].forEach((v) {
        _mainTextMatchedSubstrings!.add(MainTextMatchedSubstring.fromJson(v));
      });
    }
    _secondaryText = json["secondary_text"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["main_text"] = _mainText;
    if (_mainTextMatchedSubstrings != null) {
      map["main_text_matched_substrings"] = _mainTextMatchedSubstrings!.map((v) => v.toJson()).toList();
    }
    map["secondary_text"] = _secondaryText;
    return map;
  }
}

/// length : 5
/// offset : 0

class MainTextMatchedSubstring {
  int? _length;
  int? _offset;

  int? get length => _length;

  int? get offset => _offset;

  MainTextMatchedSubstring({int? length, int? offset}) {
    _length = length;
    _offset = offset;
  }

  MainTextMatchedSubstring.fromJson(dynamic json) {
    _length = json["length"];
    _offset = json["offset"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["length"] = _length;
    map["offset"] = _offset;
    return map;
  }
}

/// length : 5
/// offset : 0

class MatchedSubstring {
  int? _length;
  int? _offset;

  int? get length => _length;

  int? get offset => _offset;

  MatchedSubstring({int? length, int? offset}) {
    _length = length;
    _offset = offset;
  }

  MatchedSubstring.fromJson(dynamic json) {
    _length = json["length"];
    _offset = json["offset"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["length"] = _length;
    map["offset"] = _offset;
    return map;
  }
}
