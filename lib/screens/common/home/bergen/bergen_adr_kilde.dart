import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../googleApi/google_api_repo.dart';
import '../../../../googleApi/place_model_dl.dart';
import '../../../../networking/ops/ops_customer_api.dart';
import '../../../../ui/kit/ae_inline_address.dart' show resolveAddressLatLng;
import '../../../../utils/utils.dart';
import '../../../bergen/adresse/adr_ark.dart';
import '../../../bergen/hjem/hjem_harness.dart';
import '../../manageAddress/add_new_address_repo.dart';
import '../../manageAddress/manage_address_dl.dart';
import '../home_bloc.dart';

/// The address sheets' data on Hjem: the saved places and the chosen one
/// from [HomeBloc], coverage and the waitlist from `/api/geo/*`, place search
/// through the Google proxy, and add / edit through the address API.
class BergenAdrKilde implements AdrKilde {
  BergenAdrKilde(this.bloc);
  final HomeBloc bloc;

  @override
  Stream<List<AddressListItem>?> get liste => bloc.addressList;

  @override
  Stream<AddressListItem?> get valgt => bloc.deliveryAddress;

  @override
  void velg(int addressId) => bloc.updateDeliveryAddress(addressId: addressId);

  @override
  Future<void> slett(int addressId) async => bloc.deleteAddress(addressId);

  static LatLng? _latLng(AddressListItem a) {
    final lat = double.tryParse(a.lat), lng = double.tryParse(a.long);
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  /// Coverage per place, fetched once per session.
  static final Map<int, AdrDekning?> _dekning = {};

  @override
  Future<AdrDekning?> dekning(AddressListItem a) async {
    if (HjemHarness.dekning case final h?) return _harness(h);
    if (_dekning.containsKey(a.addressId)) return _dekning[a.addressId];
    final p = _latLng(a);
    if (p == null) return null;
    final j = await OpsCustomerApi().coverage(p.latitude, p.longitude);
    final d = j == null ? null : AdrDekning.fraJson(j);
    _dekning[a.addressId] = d;
    return d;
  }

  /// Debug harness only: `/api/geo/coverage` is off on the local stack.
  static AdrDekning _harness(String h) => switch (h) {
    'pauset' => const AdrDekning(dekket: true, pauset: true, pausetTil: '17:00', butikker: 12),
    'ikke' => const AdrDekning(dekket: false),
    _ => const AdrDekning(dekket: true, butikker: 12, gebyrKr: 39, eta: '25–35 min'),
  };

  @override
  Future<AdrDekning?> dekningForslag(AdrForslag f) async {
    if (HjemHarness.dekning case final h?) return _harness(h);
    try {
      final p = await resolveAddressLatLng(line: f.full, picked: f.placeId == null ? null : Predictions(placeId: f.placeId));
      final j = await OpsCustomerApi().coverage(p.latitude, p.longitude);
      return j == null ? null : AdrDekning.fraJson(j);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> siFra(AddressListItem a) async {
    final p = _latLng(a);
    if (p == null) return;
    await OpsCustomerApi().waitlist(p.latitude, p.longitude, address: a.address);
  }

  static String _dorNokkel(int id) => 'adr_dorbeskjed_$id';

  /// The full note kept on this device first (the address' `landmark`
  /// holds 30 characters), else the landmark.
  @override
  String dor(AddressListItem a) {
    final lokal = prefGetString(_dorNokkel(a.addressId));
    return lokal.isNotEmpty ? lokal : adrDor(a);
  }

  @override
  Future<bool> lagreDor(AddressListItem a, String tekst) async {
    await prefSetString(_dorNokkel(a.addressId), tekst);
    // The courier sees the address' landmark; it holds 30 characters, so a
    // longer note stays on this device rather than being cut.
    if (tekst.length > 30) return true;
    final p = _latLng(a) ?? prefGetLatLng();
    try {
      final r = await AddNewAddressRepo().callEditAddressApi(a.addressId, a.address, a.type, p, a.flatNo, tekst.isEmpty ? 'N/A' : tekst);
      if (r is Map && r['status'] == 1) {
        bloc.getAddressList();
        return true;
      }
      openSimpleSnackbar((r is Map ? r['message'] : null)?.toString() ?? 'Kunne ikke lagre');
    } catch (_) {
      openSimpleSnackbar('Kunne ikke lagre');
    }
    return false;
  }

  @override
  Future<List<AdrForslag>> forslag(String q) async {
    if (q.trim().length < 2) return const [];
    try {
      final m = PlaceModel.fromJson(await GoogleApiRepo().placeApiCall(q, prefGetLatLng()));
      return [
        for (final p in m.predictions ?? const <Predictions>[])
          AdrForslag(
            gate: p.structuredFormatting?.mainText ?? p.description ?? '',
            sted: (p.structuredFormatting?.secondaryText ?? '').replaceFirst(RegExp(r',?\s*(Norge|Norway)$'), ''),
            placeId: p.placeId,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<int?> leggTil({required String adresse, required String type, required AdrForslag? fra, required String info}) async {
    try {
      final p = await resolveAddressLatLng(line: adresse, picked: fra?.placeId == null ? null : Predictions(placeId: fra!.placeId));
      final kort = info.length <= 30 ? info : '';
      final r = await AddNewAddressRepo().callAddAddressApi(adresse, type, p, '', kort.isEmpty ? 'N/A' : kort);
      if (r is! Map || r['status'] != 1) {
        openSimpleSnackbar((r is Map ? r['message'] : null)?.toString() ?? 'Kunne ikke lagre adressen');
        return null;
      }
      final id = (r['address_id'] as num?)?.toInt() ?? 0;
      if (id != 0 && info.isNotEmpty) await prefSetString(_dorNokkel(id), info);
      prefSetInt(prefNewDeliveryAddressId, id);
      await bloc.getAddressList();
      bloc.updateDeliveryAddress(addressId: id);
      return id;
    } catch (_) {
      openSimpleSnackbar('Kunne ikke lagre adressen');
      return null;
    }
  }

  @override
  void minPosisjon(void Function() ferdig) {
    // HomeBloc.getCurrentLocation does the same and then pops whatever route
    // is on top; here the sheet closes itself once the place is chosen.
    getLocationUtils.getLocationUtils((_) {}, (data, address) async {
      try {
        final p = LatLng(data.latitude!, data.longitude!);
        prefSetLatLng(p);
        final r = await AddNewAddressRepo().callAddAddressApi(address, 'home', p, 'current-location', address);
        if (r is Map && r['status'] == 1) {
          final id = (r['address_id'] as num?)?.toInt() ?? 0;
          prefSetInt(prefNewDeliveryAddressId, id);
          await bloc.getAddressList();
          bloc.updateDeliveryAddress(addressId: id);
        } else {
          openSimpleSnackbar((r is Map ? r['message'] : null)?.toString() ?? 'Kunne ikke lagre adressen');
        }
      } catch (e) {
        openSimpleSnackbar('Kunne ikke finne posisjonen');
      }
      ferdig();
    }, getForceFully: true);
  }

  @override
  void toast(String tekst) => openSimpleSnackbar(tekst);
}
