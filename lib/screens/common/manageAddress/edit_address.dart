import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aerend_customer/commonView/customCountryCodePicker/custom_country_code_picker.dart';
import 'package:aerend_customer/screens/common/location/customize_map_picker.dart';
import 'package:aerend_customer/screens/common/manageAddress/add_new_address_repo.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import '../../../utils/utils.dart';
import '../../../utils/dropdown_search.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../address_order_chrome.dart';
import '../auth/auth_style.dart';

/// Rediger adresse (map-search variant) — same design language as
/// `AddAddressScreen` in `dugnad/address-order.jsx`: `.tk-head`,
/// `.dgm-map` picker plate, `.dga-flabel` labels, `.ae-input` fields,
/// `.dgm-types` type tiles, `.dg-info` and a `.co-foot` sticky save.
///
/// Country / street lookup, map-picker and the save API call are unchanged.
class EditAddress extends StatefulWidget {
  const EditAddress({super.key});

  @override
  EditAddressState createState() => EditAddressState();
}

class EditAddressState extends State<EditAddress> {
  final List<String> countries = getCountryNameList();

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  String country = 'Norge';
  String locationType = 'House';

  LatLng latLng = defaultLatLng;

  @override
  void dispose() {
    _controller.dispose();
    _numberController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var step = 0;
    Widget rise(Widget child) {
      final delay = Duration(milliseconds: 120 + 70 * step++);
      return AeRiseIn(delay: delay, child: child);
    }

    return Scaffold(
      backgroundColor: context.aeTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AoTkHead(title: languages.locationEditTitle),
            Expanded(
              // .ae-body { padding: 0 18px 120px; gap: 18px }
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  rise(_buildMapCard()),
                  const SizedBox(height: 18),
                  rise(
                    _labelled(
                      languages.locationCountry,
                      _countryDropdown(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  rise(
                    _labelled(languages.locationStreet, _streetSearch()),
                  ),
                  const SizedBox(height: 18),
                  rise(_buildTypeSelector()),
                  const SizedBox(height: 18),
                  rise(
                    _labelled(
                      languages.locationAddressDetails,
                      _plainField(
                        _numberController,
                        languages.locationDoorHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  rise(
                    _labelled(
                      languages.locationOptional,
                      _plainField(
                        _landmarkController,
                        languages.locationCourierInstruction,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  rise(
                    AoInfoBox(
                      icon: Icons.map_outlined,
                      text: languages.locationMapsHelp,
                    ),
                  ),
                ],
              ),
            ),
            // .co-foot
            AoStickyFooter(
              child: AuthPrimaryButton(
                label: languages.locationEditTitle,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    AddNewAddressRepo().callAddAddressApi(
      _controller.text,
      locationType == 'House' || locationType == 'Apartment'
          ? 'home'
          : locationType == 'Office'
              ? 'work'
              : 'other',
      latLng,
      _numberController.text,
      _landmarkController.text,
    );
  }

  /// `.ae-field` — `.ae-flabel` label above the control, 8px gap.
  Widget _labelled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: authLabelStyle(context)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// `.dgm-map` — tapping the plate opens the existing [CustomMapPicker].
  Widget _buildMapCard() {
    return AoMapPlate(
      label: languages.locationSelectFromMaps,
      onTap: () => openScreenWithResult(
        context,
        CustomMapPicker(
          latLng: latLng,
          updateLatLng: (newLatLng) => setState(() => latLng = newLatLng),
        ),
      ),
    );
  }

  /// `.ae-input` shell around the country dropdown.
  Widget _countryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _inputShell,
      child: DropdownButton<String>(
        isExpanded: true,
        value: country,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        icon: const Icon(
          Icons.expand_more_rounded,
          color: ScSaasThemeTokens.gray500,
        ),
        style: _fieldTextStyle,
        underline: const SizedBox.shrink(),
        onChanged: (String? newValue) =>
            setState(() => country = newValue ?? country),
        items: countries
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: _fieldTextStyle),
              ),
            )
            .toList(),
      ),
    );
  }

  /// `.ae-input` shell around the geocoding street search.
  Widget _streetSearch() {
    return Container(
      decoration: _inputShell,
      clipBehavior: Clip.antiAlias,
      child: DropdownSearch(
        textController: _controller,
        hintText: languages.locationStreetHint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        country: country,
        dropdownBgColor: Colors.white,
        dropdownHeight: 200,
        updateLatLng: (newLatLng) => setState(() => latLng = newLatLng),
        textFieldBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _plainField(
    TextEditingController controller,
    String hint, {
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final theme = context.aeTheme;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      textInputAction: textInputAction,
      style: _fieldTextStyle,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintText: hint,
        hintStyle: _fieldTextStyle.copyWith(
          color: ScSaasThemeTokens.gray500,
        ),
        enabledBorder: _fieldBorder(Colors.transparent),
        focusedBorder: _fieldBorder(theme.primary),
        border: _fieldBorder(Colors.transparent),
      ),
    );
  }

  /// `.dga-flabel` + `.dgm-types` — Hjem / Jobb / Annet.
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Text(
            languages.locationYourType.toUpperCase(),
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
            _typeTile(
              'House',
              Icons.home_outlined,
              languages.home,
              on: locationType == 'House' || locationType == 'Apartment',
            ),
            const SizedBox(width: 9),
            _typeTile(
              'Office',
              Icons.work_outline_rounded,
              languages.work,
              on: locationType == 'Office',
            ),
            const SizedBox(width: 9),
            _typeTile(
              'Other',
              Icons.place_outlined,
              languages.other,
              on: locationType == 'Other',
            ),
          ],
        ),
      ],
    );
  }

  /// `.dgm-types .tp` / `.dgm-types .tp.on`.
  Widget _typeTile(
    String value,
    IconData icon,
    String label, {
    required bool on,
  }) {
    final theme = context.aeTheme;
    return Expanded(
      child: AoPressable(
        scale: 0.97,
        onTap: () => setState(() => locationType = value),
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

  static final BoxDecoration _inputShell = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
  );

  static final TextStyle _fieldTextStyle = GoogleFonts.plusJakartaSans(
    color: ScSaasThemeTokens.ink,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(width: 1.5, color: color),
      );
}
