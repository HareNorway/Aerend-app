import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aerend_customer/commonView/customCountryCodePicker/custom_country_code_picker.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/common/location/customize_map_picker.dart';
import 'package:aerend_customer/screens/common/manageAddress/add_new_address_repo.dart';

import '../../../utils/utils.dart';
import '../../../utils/dropdown_search.dart';

class AddLocation extends StatefulWidget {
  final Widget locate;
  const AddLocation({super.key, this.locate = const HomeMainV1(homeIndex: 2)});

  @override
  AddLocationState createState() => AddLocationState();
}

class AddLocationState extends State<AddLocation> {
  final List<String> countries = getCountryNameList();
  final List<String> locationTypes = [
    'House',
    'Apartment',
    'Office',
    'Other',
  ];

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  String country = 'Norge';
  String locationType = 'House';

  LatLng latLng = defaultLatLng;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isDark
          ? colorGreen.withOpacity(0.15)
          : const Color.fromARGB(255, 224, 252, 225),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(width: 1.5, color: colorGreen),
      elevation: 0,
    );

    final inactiveButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Stack(
          children: [
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  languages.locationAddNew,
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorBlack),
                ),
              ),
            ),
            Positioned(
              left: 15,
              child: ElevatedButton(
                onPressed: () => openScreenWithResult(context, widget.locate),
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    elevation: 1,
                    padding: const EdgeInsets.all(10),
                    shape: const CircleBorder()),
                child: SvgPicture.asset('assets/svgs/icons/back.svg',
                    height: 16, width: 16),
              ),
            )
          ],
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsetsDirectional.only(
                  bottom: 100, top: 20, start: 20, end: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(languages.locationCountry,
                      style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600) ??
                          const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 0.1,
                          blurRadius: 11,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: country,
                      dropdownColor: theme.colorScheme.surface,
                      icon: const Icon(Icons.expand_more),
                      onChanged: (String? newValue) {
                        setState(() {
                          country = newValue ?? country;
                        });
                      },
                      items: countries
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      underline: Container(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(languages.locationStreet,
                      style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600) ??
                          const TextStyle(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 0.1,
                          blurRadius: 11,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownSearch(
                      textController: _controller,
                      hintText: languages.locationStreetHint,
                      contentPadding: const EdgeInsets.all(10),
                      country: country,
                      dropdownBgColor: theme.colorScheme.surface,
                      dropdownHeight: 200,
                      updateLatLng: (newLatLng) {
                        setState(() {
                          latLng = newLatLng;
                        });
                      },
                      textFieldBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(languages.locationYourType,
                      style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600) ??
                          const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 0.1,
                          blurRadius: 11,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: locationType,
                      dropdownColor: theme.colorScheme.surface,
                      icon: const Icon(Icons.expand_more),
                      onChanged: (String? newValue) {
                        setState(() {
                          locationType = newValue ?? locationType;
                        });
                      },
                      items: locationTypes
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      underline: Container(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(languages.locationAddressDetails,
                      style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600) ??
                          const TextStyle(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 0.1,
                          blurRadius: 11,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _numberController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.all(10),
                        hintText: languages.locationDoorHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    languages.locationOptional,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7) ??
                              colorMainLightGray,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          color: colorMainLightGray,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 0.1,
                          blurRadius: 11,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _landmarkController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.all(10),
                        hintText: languages.locationCourierInstruction,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    languages.locationSelectFromMaps,
                    style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600) ??
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    languages.locationMapsHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7) ??
                              colorMainLightGray,
                        ) ??
                        const TextStyle(color: colorMainLightGray),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 224, 252, 225),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0),
                      onPressed: () async {
                        final result = await openScreenWithResult(
                          context,
                          CustomMapPicker(
                              latLng: latLng,
                              updateLatLng: (newLatLng) {
                                setState(() {
                                  latLng = newLatLng;
                                });
                              }),
                        );

                        if (result != null) {
                          final picked = (result as String).trim();
                          if (picked.isNotEmpty) {
                            _controller.text = picked;
                          } else {
                            final fallbackAddress = await getStringAddress(
                                latLng.latitude, latLng.longitude);
                            _controller.text = fallbackAddress;
                          }

                          // Autofill country based on selected coordinates to reduce manual input.
                          final placemarks =
                              await getAddress(latLng.latitude, latLng.longitude);
                          if (placemarks != null && placemarks.isNotEmpty) {
                            final countryName = placemarks.first.country ?? '';
                            if (countryName.isNotEmpty) {
                              final match = countries.firstWhere(
                                  (c) => c.toLowerCase() ==
                                      countryName.toLowerCase(),
                                  orElse: () => '');
                              if (match.isNotEmpty && mounted) {
                                setState(() {
                                  country = match;
                                });
                              }
                            }
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/svgs/location-add.svg'),
                          const SizedBox(width: 10),
                          const Text(
                            'Add Location From Maps',
                            style: TextStyle(
                              color: colorGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Address type and label',
                    style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600) ??
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add or create labels to easily choose between delivery addresses',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7) ??
                              colorMainLightGray,
                        ) ??
                        const TextStyle(color: colorMainLightGray),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: deviceWidth * 0.25,
                            height: 70,
                            child: ElevatedButton(
                              style: locationType == 'House' ||
                                      locationType == 'Apartment'
                                  ? activeButtonStyle
                                  : inactiveButtonStyle,
                              onPressed: () {},
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SvgPicture.asset(
                                    'assets/svgs/home-2.svg',
                                    color: locationType == 'House' ||
                                            locationType == 'Apartment'
                                        ? colorGreen
                                        : (isDark ? colorWhite : colorBlack),
                                  ),
                                  Text(
                                    'Home',
                                    style: TextStyle(
                                      color: locationType == 'House' ||
                                              locationType == 'Apartment'
                                          ? colorGreen
                                          : (isDark ? colorWhite : colorBlack),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: deviceWidth * 0.25,
                            height: 70,
                            child: ElevatedButton(
                              style: locationType == 'Office'
                                  ? activeButtonStyle
                                  : inactiveButtonStyle,
                              onPressed: () {},
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SvgPicture.asset(
                                    'assets/svgs/briefcase.svg',
                                    color: locationType == 'Office'
                                        ? colorGreen
                                        : (isDark ? colorWhite : colorBlack),
                                  ),
                                  Text(
                                    'Work',
                                    style: TextStyle(
                                        color: locationType == 'Office'
                                            ? colorGreen
                                            : (isDark ? colorWhite : colorBlack)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: deviceWidth * 0.25,
                            height: 70,
                            child: ElevatedButton(
                              style: locationType == 'Other'
                                  ? activeButtonStyle
                                  : inactiveButtonStyle,
                              onPressed: () {},
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SvgPicture.asset(
                                    'assets/svgs/location.svg',
                                    color: locationType == 'Other'
                                        ? colorGreen
                                        : (isDark ? colorWhite : colorBlack),
                                  ),
                                  Text(
                                    'Other',
                                    style: TextStyle(
                                        color: locationType == 'Other'
                                            ? colorGreen
                                            : (isDark ? colorWhite : colorBlack)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final flatNo =
                      _numberController.text.trim().isEmpty ? 'N/A' : _numberController.text.trim();
                    final response = await AddNewAddressRepo()
                      .callAddAddressApi(
                        _controller.text,
                        locationType == "House" ||
                            locationType == "Apartment"
                          ? "home"
                          : locationType == "Office"
                            ? "work"
                            : "other",
                        latLng,
                        flatNo,
                        _landmarkController.text);
                    if (response["status"] == 1) {
                      prefSetInt(
                          prefNewDeliveryAddressId, response["address_id"]);
                      if (!mounted) return;
                      openScreenWithClearPrevious(context, widget.locate);
                    } else {
                      openSimpleSnackbar(response["message"]);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(languages.locationAddButton,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
