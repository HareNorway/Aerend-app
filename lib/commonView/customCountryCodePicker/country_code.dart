import 'package:flutter/cupertino.dart';

import 'custom_country_code_picker.dart';


class CountryCode {
  /// the name of the country
  String? name;

  /// the flag of the country
  final String? flagUri;

  /// the country code (IT,AF..)
  final String? code;

  /// the dial code (+39,+93..)
  final String? dialCode;

  CountryCode({
    this.name,
    this.flagUri,
    this.code,
    this.dialCode,
  });

  @Deprecated('Use `fromCountryCode` instead.')
  factory CountryCode.fromCode(String isoCode) {
    return CountryCode.fromCountryCode(isoCode);
  }

  factory CountryCode.fromCountryCode(String countryCode) {
    final Map<String, String> jsonCode = myCountryList.firstWhere((code) => code['code'] == countryCode, orElse: () {
      return myCountryList.first;
    });
    return CountryCode.fromJson(jsonCode);
  }

  factory CountryCode.fromDialCode(String dialCode) {
    final Map<String, String> jsonCode = myCountryList.firstWhere((code) => code['dial_code'] == dialCode, orElse: () {
      return myCountryList.first;
    });
    return CountryCode.fromJson(jsonCode);
  }

  CountryCode localize(BuildContext context) {
    return this..name; /*= CountryPickerLocalizations.of(context)?.translate(this.code) ??*/
  }

  factory CountryCode.fromJson(Map<String, dynamic> json) {
    return CountryCode(
      name: json['name'],
      code: json['code'],
      dialCode: json['dial_code'],
      flagUri: 'assets/flags/${json['code'].toLowerCase()}.png',
    );
  }

  @override
  String toString() => "$dialCode";

  String toLongString() => "$dialCode ${toCountryStringOnly()}";

  String toCountryStringOnly() {
    return '$_cleanName';
  }

  String? get _cleanName {
    return name?.replaceAll(RegExp(r'[[\]]'), '').split(',').first;
  }
}
