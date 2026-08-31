import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../blocs/bloc.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../address_order_chrome.dart';
import '../auth/auth_style.dart';
import '../../../ui/kit/ae_inline_address.dart';
import 'item_address_list.dart';
import 'manage_address_bloc.dart';
import 'manage_address_dl.dart';

/// Leveringsadresse — same address cards and inline add/edit form as
/// Velg leveringsadresse. `AddNewAddress` is kept in the project but this
/// screen no longer navigates there.
class ManageAddress extends StatefulWidget {
  final bool showSelect;

  const ManageAddress({super.key, this.showSelect = false});

  @override
  State<ManageAddress> createState() => _ManageAddressState();
}

class _ManageAddressState extends State<ManageAddress> {
  late final ManageAddressBloc _bloc;
  final GlobalKey _formKey = GlobalKey();
  bool _adding = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _bloc = ManageAddressBloc(context, this);
    _bloc.getAddressList();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  void _cancelForm() {
    setState(() {
      _adding = false;
      _editingId = null;
    });
  }

  void _openAdd(ManageAddressBloc bloc) {
    if (bloc.addressListLength < bloc.maxAddressLimit) {
      setState(() {
        _adding = true;
        _editingId = null;
      });
      _ensureFormVisible();
    } else {
      openSimpleSnackbar(languages.maxAddressMsg(bloc.maxAddressLimit));
    }
  }

  void _openEdit(AddressListItem address) {
    setState(() {
      _adding = false;
      _editingId = address.addressId;
    });
    _ensureFormVisible();
  }

  void _ensureFormVisible() {
    void go() {
      final ctx = _formKey.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      go();
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    });
  }

  Future<void> _onFormSaved(dynamic _) async {
    _bloc.setResult = true;
    _cancelForm();
    _bloc.getAddressList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.aeTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AoTkHead(
              title: languages.deliveryAddress,
              onBack: () => Navigator.pop(context, _bloc.setResult),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = context.aeTheme;
    return StreamBuilder<ApiResponse<AddressListPojo>>(
      stream: _bloc.subject,
      builder: (context, snap) {
        final isLoading =
            !snap.hasData || snap.data?.status == Status.loading;
        final isError = snap.hasData && snap.data?.status == Status.error;
        final addressList = snap.data?.data?.addressList ?? [];

        if (isLoading && addressList.isEmpty && !_adding && _editingId == null) {
          return Center(
            child: CircularProgressIndicator(color: theme.primary),
          );
        }

        if (isError && addressList.isEmpty && !_adding) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.dp(24)),
              child: Text(
                snap.data?.message ?? languages.internetConnLostTitle,
                textAlign: TextAlign.center,
                style: aoText(
                  15,
                  FontWeight.w700,
                  height: 1.45,
                  color: ScSaasThemeTokens.gray500,
                ),
              ),
            ),
          );
        }

        return _buildAddressList(addressList, _bloc);
      },
    );
  }

  Widget _buildAddressList(
    List<AddressListItem> addresses,
    ManageAddressBloc bloc,
  ) {
    var step = 0;
    Widget rise(Widget child) {
      final delay = Duration(milliseconds: 120 + 70 * step++);
      return AeRiseIn(delay: delay, child: child);
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        context.dp(20),
        0,
        context.dp(20),
        context.dp(40),
      ),
      children: [
        if (addresses.isNotEmpty) ...[
          rise(const AoSectionLabel(kAoYourAddressesLabel, bottom: 0)),
          SizedBox(height: context.dp(12)),
        ],
        ...addresses.map((a) {
          final selectedId = prefGetInt(prefNewDeliveryAddressId);
          final selected = a.addressId == selectedId;
          if (_editingId == a.addressId) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.dp(14)),
              child: AeInlineAddressForm(
                key: _formKey,
                initialLine: a.address,
                editingId: a.addressId,
                addressType: a.type,
                onCancel: _cancelForm,
                onSaved: _onFormSaved,
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.only(bottom: context.dp(14)),
            child: rise(
              ItemAddressList(
                addressListItem: a,
                showSelect: widget.showSelect,
                isSelected: selected,
                isDefault: selected,
                enabled: !_adding && _editingId == null,
                onPressSelect: () => _selectAddress(a),
                onPressEdit: () => _openEdit(a),
                onPressDelete: () => _confirmDelete(bloc, a),
              ),
            ),
          );
        }),
        if (_editingId == null) ...[
          if (_adding)
            AeInlineAddressForm(
              key: _formKey,
              onCancel: _cancelForm,
              onSaved: _onFormSaved,
            )
          else
            rise(
              AeAddAddressCard(onTap: () => _openAdd(bloc)),
            ),
        ],
        SizedBox(height: context.dp(14)),
        rise(
          AoInfoBox(
            icon: Icons.local_shipping_outlined,
            text: languages.dugnadAddressSavedInfo,
          ),
        ),
      ],
    );
  }

  Future<void> _selectAddress(AddressListItem address) async {
    await prefSetInt(prefNewDeliveryAddressId, address.addressId);
    await prefSetString(
      prefNewDeliveryAddress,
      jsonEncode(address.toJson()),
    );
    final la = double.tryParse(address.lat);
    final lo = double.tryParse(address.long);
    if (la != null && lo != null && la.abs() > 1e-7 && lo.abs() > 1e-7) {
      await prefSetLatLng(LatLng(la, lo));
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete(
    ManageAddressBloc bloc,
    AddressListItem address,
  ) {
    return showAeSheet<void>(
      context: context,
      builder: (sheetContext) => _DeleteAddressSheet(
        address: address.address,
        onConfirm: () => bloc.deleteAddress(address.addressId),
      ),
    );
  }
}

/// Delete confirmation — `.dg-mem-head` head, `.dga-warn` blurb, red
/// `.dga-del` button, `.dga-cancel` text button.
class _DeleteAddressSheet extends StatelessWidget {
  const _DeleteAddressSheet({required this.address, required this.onConfirm});

  final String address;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 22 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AeSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: ScSaasThemeTokens.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages.deleteAddress,
                        style: aoText(
                          18,
                          FontWeight.w800,
                          letterSpacingEm: -0.02,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: aoText(
                          12.5,
                          FontWeight.w600,
                          height: 1.45,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0x14D9534F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              languages.deleteAddressDialogMsg,
              style: aoText(
                13.5,
                FontWeight.w600,
                height: 1.5,
                color: const Color(0xFF96322F),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AuthPressable(
              onTap: () {
                aeSheetSaveHaptic();
                onConfirm();
              },
              builder: (context, pressed) => Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.danger,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      languages.delete,
                      style: aoText(
                        15,
                        FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                aeSheetCloseHaptic();
                Navigator.maybePop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Center(
                  child: Text(
                    languages.cancel,
                    style: aoText(
                      14.5,
                      FontWeight.w700,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dg-label` — prototype "Dine adresser".
const String kAoYourAddressesLabel = 'Dine adresser'; // TODO(l10n)
