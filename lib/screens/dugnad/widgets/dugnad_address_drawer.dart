import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../common/address_order_chrome.dart';
import '../../common/manageAddress/dugnad_inline_address.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../common/manageAddress/manage_address_repo.dart';
import '../dugnad_club_theme.dart';

Future<bool?> showDugnadAddressDrawer(
  BuildContext context, {
  required BuildContext parentContext,
  VoidCallback? onAddressChanged,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.dp(24))),
    ),
    builder: (_) => DugnadAddressDrawer(
      parentContext: parentContext,
      onAddressChanged: onAddressChanged,
    ),
  );
}

class DugnadAddressDrawer extends StatefulWidget {
  final BuildContext parentContext;
  final VoidCallback? onAddressChanged;

  const DugnadAddressDrawer({
    super.key,
    required this.parentContext,
    this.onAddressChanged,
  });

  @override
  State<DugnadAddressDrawer> createState() => DugnadAddressDrawerState();
}

class DugnadAddressDrawerState extends State<DugnadAddressDrawer> {
  final ManageAddressRepo _repo = ManageAddressRepo();
  List<AddressListItem> _addresses = [];
  bool _loading = true;
  bool _busy = false;
  bool _adding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = AddressListPojo.fromJson(
        await _repo.callAddressListApi(),
      );
      if (!mounted) return;
      if (response.status == 1) {
        setState(() => _addresses = response.addressList);
      } else {
        setState(() => _error = response.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectAddress(AddressListItem address) async {
    await _saveSelectedAddress(address);
    widget.onAddressChanged?.call();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteAddress(AddressListItem address) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final response = await _repo.callDeleteAddressApi(address.addressId);
      final ok = response is Map && response['status'] == 1;
      if (!mounted) return;
      if (ok) {
        if (address.addressId == prefGetInt(prefNewDeliveryAddressId)) {
          await prefSetInt(prefNewDeliveryAddressId, 0);
          await prefSetString(prefNewDeliveryAddress, '');
        }
        openSimpleSnackbar(languages.addressDeletedSuccessMsg);
        widget.onAddressChanged?.call();
        await _loadAddresses();
      } else {
        openSimpleSnackbar(addressApiMessage(context, response));
      }
    } catch (e) {
      if (mounted) openSimpleSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openInlineAdd() async {
    if (_busy) return;
    setState(() => _adding = true);
  }

  Future<void> _onFormSaved(dynamic response) async {
    setState(() => _adding = false);
    await _loadAddresses(showSpinner: false);
    final newId = int.tryParse('${response['address_id'] ?? ''}');
    AddressListItem? created;
    if (newId != null) {
      for (final a in _addresses) {
        if (a.addressId == newId) {
          created = a;
          break;
        }
      }
    }
    created ??= _addresses.isEmpty ? null : _addresses.last;
    if (created != null) {
      await _saveSelectedAddress(created);
      widget.onAddressChanged?.call();
    }
  }

  Future<void> _saveSelectedAddress(AddressListItem address) async {
    await prefSetInt(prefNewDeliveryAddressId, address.addressId);
    await prefSetString(prefNewDeliveryAddress, jsonEncode(address.toJson()));
    final lat = double.tryParse(address.lat);
    final long = double.tryParse(address.long);
    if (lat != null && long != null && lat.abs() > 1e-7 && long.abs() > 1e-7) {
      await prefSetLatLng(LatLng(lat, long));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F7FF),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.dp(30))),
          ),
          padding: EdgeInsets.fromLTRB(
            context.dp(20),
            context.dp(12),
            context.dp(20),
            context.dp(20),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: context.dp(48),
                  height: context.dp(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DDE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: context.dp(18)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      languages.checkoutSelectDeliveryAddress,
                      style: aoText(
                        18,
                        FontWeight.w800,
                        letterSpacingEm: -0.02,
                        color: theme.text,
                      ),
                    ),
                  ),
                  SizedBox(width: context.dp(12)),
                  _drawerCloseButton(),
                ],
              ),
              SizedBox(height: context.dp(18)),
              if (_loading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.dugnadTheme.primary,
                    ),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: aeBody(color: ScSaasThemeTokens.gray500),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ..._addresses.map(_savedAddressItem),
                      if (_addresses.isNotEmpty) SizedBox(height: context.dp(14)),
                      if (_adding)
                        DugnadInlineAddressForm(
                          onCancel: () => setState(() => _adding = false),
                          onSaved: _onFormSaved,
                        )
                      else
                        DugnadAddAddressCard(
                          onTap: _busy ? null : _openInlineAdd,
                        ),
                      SizedBox(height: context.dp(14)),
                      AoInfoBox(
                        icon: Icons.local_shipping_outlined,
                        text: languages.dugnadAddressSavedInfo,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerCloseButton() {
    final theme = context.dugnadTheme;
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: context.dp(40),
        height: context.dp(40),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A1C274C),
              blurRadius: context.dp(12),
              offset: Offset(0, context.dp(4)),
              spreadRadius: context.dp(-2),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: context.dp(22),
          color: theme.primaryHover,
        ),
      ),
    );
  }

  Widget _savedAddressItem(AddressListItem address) {
    final selected = address.addressId == prefGetInt(prefNewDeliveryAddressId);
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(14)),
      child: DugnadAddressPickCard(
        address: address,
        selected: selected,
        enabled: !_busy && !_adding,
        showCheckWhenSelected: true,
        onTap: _busy || _adding ? null : () => _selectAddress(address),
        onDelete: selected ? null : () => _deleteAddress(address),
      ),
    );
  }
}
