import 'package:flutter/foundation.dart';

import '../../../utils/shared_pref_utill.dart';

import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../data/points/points_app_repo.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../common/manageAddress/manage_address_repo.dart';
import '../../common/manageCard/manage_card_dl.dart';
import '../../common/manageCard/manage_card_repo.dart';

/// The agil-3 screens resolve their data sources here so widget tests can
/// swap in fakes without threading constructors through named routes.
abstract final class A3Services {
  static PointsAppApi Function() points = () => PointsAppRepo();
  static AegilAppApi Function() aegil = () => AegilAppRepo();
  static AegilRepo Function() aegilRepo = () => AegilRepo();

  /// "Roligere bevegelse" (Konto): honoured by every agil-3 screen through
  /// [A3Motion] until agil-1 lifts it into the app-wide MediaQuery.
  static final ValueNotifier<bool> reducedMotion = ValueNotifier<bool>(false);

  /// The Meg rows "Adresser" and "Betaling" read one line each from the
  /// legacy address and card lists (agil-4); tests swap these.
  static Future<String?> Function() addressLine = _defaultAddressLine;
  static Future<String?> Function() paymentLine = _defaultPaymentLine;
  static Future<List<String>> Function() addresses = _defaultAddresses;
  static Future<List<String>> Function() cards = _defaultCards;

  @visibleForTesting
  static void reset() {
    points = () => PointsAppRepo();
    aegil = () => AegilAppRepo();
    aegilRepo = () => AegilRepo();
    reducedMotion.value = false;
    addressLine = _defaultAddressLine;
    paymentLine = _defaultPaymentLine;
    addresses = _defaultAddresses;
    cards = _defaultCards;
  }
}

Future<List<String>> _defaultAddresses() async {
  final pojo = AddressListPojo.fromJson(await ManageAddressRepo().callAddressListApi());
  return [
    for (final a in pojo.addressList)
      if (a.address.trim().isNotEmpty) a.flatNo.trim().isEmpty ? a.address : '${a.address}, ${a.flatNo.trim()}',
  ];
}

Future<List<String>> _defaultCards() async {
  final model = CardModel.fromJson(await ManageCardRepo().getCardList());
  return [
    for (final c in model.cardList)
      if (c.cardNumber.replaceAll(RegExp(r'\D'), '').length >= 4) 'Visa •• ${c.cardNumber.replaceAll(RegExp(r'\D'), '').substring(c.cardNumber.replaceAll(RegExp(r'\D'), '').length - 4)}',
  ];
}

Future<String?> _defaultAddressLine() async {
  final pojo = AddressListPojo.fromJson(await ManageAddressRepo().callAddressListApi());
  final first = pojo.addressList.firstOrNull;
  if (first == null) return null;
  final flat = first.flatNo.trim();
  return flat.isEmpty ? first.address : '${first.address}, $flat';
}

Future<String?> _defaultPaymentLine() async {
  final model = CardModel.fromJson(await ManageCardRepo().getCardList());
  final first = model.cardList.firstOrNull;
  if (first == null) return null;
  final digits = first.cardNumber.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 4 ? 'Visa •• ${digits.substring(digits.length - 4)}' : null;
}

/// Runs [f] and turns any failure — including a synchronous throw from an
/// uninitialised global such as the prefs — into `null`, so a screen can
/// always build its first frame.
Future<T?> a3Try<T>(Future<T?> Function() f) async {
  try {
    return await f();
  } catch (_) {
    return null;
  }
}

/// A pref read that returns '' instead of throwing before prefs are ready.
String a3Pref(String key) {
  try {
    return prefGetString(key);
  } catch (_) {
    return '';
  }
}
