import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/custom_text_field.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../address_order_chrome.dart';
import '../auth/auth_style.dart';
import '../base_dl.dart';
import '../location/customize_map_picker.dart';
import 'add_new_address_bloc.dart';
import 'manage_address_dl.dart';

/// Ny / rediger adresse — prototype `AddAddressScreen` in
/// `dugnad/address-order.jsx`: `.tk-head`, `.dgm-map` picker, `.dga-flabel` +
/// `.dgm-types` type tiles, `.ae-field`/`.ae-input` form (`.dgm-locwrap` for
/// the position field), `.dg-info`, `.co-foot` sticky save.
///
/// All geocoding / map-picker / save wiring is unchanged; only the skin and
/// layout were rebuilt. Type sizes are fixed px on the 375×812 frame.
class AddNewAddress extends StatefulWidget {
  final AddressListItem? addressListItem;

  const AddNewAddress({super.key, this.addressListItem});

  @override
  State<StatefulWidget> createState() => _AddNewAddressState();
}

class _AddNewAddressState extends State<AddNewAddress> {
  late AddNewAddressBloc _addNewAddressBloc;

  bool get _isEditing => widget.addressListItem != null;

  @override
  void didChangeDependencies() {
    _addNewAddressBloc = AddNewAddressBloc(
      context,
      widget.addressListItem,
      this,
    );
    _prefillFromExisting();
    super.didChangeDependencies();
  }

  /// Seeds the freshly built bloc with the address being edited (previously
  /// done inline in `build`, which reset the fields on every rebuild).
  void _prefillFromExisting() {
    final item = widget.addressListItem;
    if (item == null) return;
    _addNewAddressBloc.changeAddressType(getAddressTypeInInt(item.type));
    _addNewAddressBloc.locationController.text = item.address;
    _addNewAddressBloc.houseNumberController.text = item.flatNo;
    _addNewAddressBloc.landmarkController.text = item.landmark;
  }

  @override
  void dispose() {
    _addNewAddressBloc.dispose();
    super.dispose();
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
              title: _isEditing ? kAoEditAddressTitle : kAoNewAddressTitle,
            ),
            Expanded(child: _buildForm()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// `.ae-body { padding: 0 18px 120px; gap: 18px }`.
  Widget _buildForm() {
    var step = 0;
    Widget rise(Widget child) {
      final delay = Duration(milliseconds: 120 + 70 * step++);
      return AeRiseIn(delay: delay, child: child);
    }

    return Form(
      key: _addNewAddressBloc.formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          rise(
            AoMapPlate(
              label: kAoUseMyPosition,
              onTap: _openLocationPicker,
            ),
          ),
          const SizedBox(height: 18),
          rise(_buildTypeSelector()),
          const SizedBox(height: 18),
          rise(_buildLocationField()),
          const SizedBox(height: 18),
          rise(
            AoField(
              label: languages.houseFlatNo,
              hint: kAoHouseNumberHint,
              controller: _addNewAddressBloc.houseNumberController,
              validator: (value) =>
                  validateEmptyField(value, languages.enterFlatNo),
            ),
          ),
          const SizedBox(height: 18),
          rise(
            AoField(
              label: languages.landmark,
              hint: kAoLandmarkHint,
              textInputAction: TextInputAction.done,
              controller: _addNewAddressBloc.landmarkController,
              validator: (value) =>
                  validateEmptyField(value, languages.enterLandmark),
            ),
          ),
          const SizedBox(height: 18),
          rise(
            const AoInfoBox(
              icon: Icons.local_shipping_outlined,
              text: kAoLandmarkInfoNote,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final initialLatLng = _addNewAddressBloc.latLng ?? defaultLatLng;
    final picked = await openScreenWithResult(
      context,
      CustomMapPicker(
        latLng: initialLatLng,
        updateLatLng: (newLatLng) => _addNewAddressBloc.latLng = newLatLng,
      ),
    );
    if (picked is String && picked.trim().isNotEmpty) {
      _addNewAddressBloc.locationController.text = picked.trim();
      if (mounted) setState(() {});
    }
  }

  /// `.dga-flabel` + `.dgm-types` — "Lagre som" Hjem / Jobb / Annet.
  Widget _buildTypeSelector() {
    return StreamBuilder<int>(
      stream: _addNewAddressBloc.addressType,
      builder: (context, snap) {
        final selected = snap.data ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 9),
              child: Text(
                languages.saveAs.toUpperCase(),
                style: aoText(
                  12,
                  FontWeight.w800,
                  letterSpacingEm: 0.06,
                  color: ScSaasThemeTokens.gray500,
                ),
              ),
            ),
            Row(
              children: [
                _typeTile(0, Icons.home_outlined, languages.home, selected),
                const SizedBox(width: 9),
                _typeTile(
                  1,
                  Icons.work_outline_rounded,
                  languages.work,
                  selected,
                ),
                const SizedBox(width: 9),
                _typeTile(2, Icons.place_outlined, languages.other, selected),
              ],
            ),
          ],
        );
      },
    );
  }

  /// `.dgm-types .tp` — flex:1, radius 15, 1.5px gray-200; `.on` swaps to a
  /// purple-600 border on lavender with purple-700 icon + label.
  Widget _typeTile(int value, IconData icon, String label, int selected) {
    final on = selected == value;
    final theme = context.aeTheme;
    return Expanded(
      child: AoPressable(
        scale: 0.97,
        onTap: () => _addNewAddressBloc.changeAddressType(value),
        builder: (context, pressed) => AnimatedContainer(
          duration: kAoColorDuration,
          curve: Curves.ease,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            color: on ? theme.background : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              width: 1.5,
              color: on ? theme.primary : kAoGray200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: on ? theme.primaryHover : kAoGray400,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: aoText(
                  13,
                  FontWeight.w800,
                  color: on ? theme.primaryHover : ScSaasThemeTokens.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.ae-field` + `.dgm-locwrap` — `.ae-input` with a 32px `.gpsic` button
  /// pinned 8px from the right edge. Tapping either opens the location picker.
  Widget _buildLocationField() {
    final theme = context.aeTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(languages.location, style: aoFieldLabelStyle(context)),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormFieldCustom(
              controller: _addNewAddressBloc.locationController,
              onTap: _openLocationPicker,
              setError: true,
              useLabelWithBorder: false,
              backgroundColor: Colors.white,
              radius: 14,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.text,
              validator: (value) =>
                  validateEmptyField(value, languages.selectLocationMsg),
              decoration: InputDecoration(
                hintText: kAoLocationHint,
                // .dgm-locwrap .ae-input { padding-right: 46px }
                contentPadding: const EdgeInsets.fromLTRB(18, 16, 46, 16),
                enabledBorder: _inputBorder(Colors.transparent),
                focusedBorder: _inputBorder(theme.primary),
                errorBorder: _inputBorder(ScSaasThemeTokens.danger),
                focusedErrorBorder: _inputBorder(ScSaasThemeTokens.danger),
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: ScSaasThemeTokens.gray500,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: GoogleFonts.plusJakartaSans(
                color: ScSaasThemeTokens.ink,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            Positioned(
              right: 8,
              child: AoPressable(
                scale: 0.94,
                onTap: _openLocationPicker,
                builder: (context, pressed) => Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.near_me_outlined,
                    size: 16,
                    color: theme.primaryHover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static OutlineInputBorder _inputBorder(Color color) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(width: 1.5, color: color),
      );

  /// `.co-foot` — sticky primary save action over the lavender fade.
  Widget _buildFooter() {
    return StreamBuilder<ApiResponse<BaseModel>>(
      stream: _addNewAddressBloc.subject,
      builder: (context, snap) {
        final isLoading = snap.hasData && snap.data?.status == Status.loading;
        return AoStickyFooter(
          child: AuthPrimaryButton(
            label: _isEditing ? kAoSaveChanges : languages.saveAddress,
            isLoading: isLoading,
            onPressed: () {
              if (_addNewAddressBloc.formKey.currentState!.validate()) {
                _addNewAddressBloc.submit();
              }
            },
          ),
        );
      },
    );
  }
}

// ── Prototype copy with no matching l10n key ─────────────────────────────
const String kAoNewAddressTitle = 'Ny adresse'; // TODO(l10n)
const String kAoEditAddressTitle = 'Rediger adresse'; // TODO(l10n)
const String kAoSaveChanges = 'Lagre endringer'; // TODO(l10n)
const String kAoUseMyPosition = 'Bruk min posisjon'; // TODO(l10n)
const String kAoLocationHint = 'Gateadresse, postnr. og sted'; // TODO(l10n)
const String kAoHouseNumberHint = '7B, 3. etasje'; // TODO(l10n)
const String kAoLandmarkHint = 'Ved Bergen Storsenter'; // TODO(l10n)
const String kAoLandmarkInfoNote =
    'Budet ser landemerket i appen — det gjør leveringen raskere.'; // TODO(l10n)
