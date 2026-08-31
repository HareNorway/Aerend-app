import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aerend_customer/googleApi/geocoding_api_call.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/utils/utils.dart';

import '../address_order_chrome.dart';
import '../auth/auth_style.dart';
import '../../../ui/kit/ae_theme.dart';

/// Map picker used by the address forms — restyled to the Ærend design
/// language (`.ae-back` shiny circle, white `--ae-shadow-card` info card,
/// `.co-foot` sticky confirm). Camera / geocoding / result contract unchanged.
class CustomMapPicker extends StatefulWidget {
  final LatLng latLng;
  final Function(LatLng) updateLatLng;

  const CustomMapPicker({
    super.key,
    required this.latLng,
    required this.updateLatLng,
  });

  @override
  CustomMapPickerState createState() => CustomMapPickerState();
}

class CustomMapPickerState extends State<CustomMapPicker> {
  late GoogleMapController _controller;
  LatLng position = defaultLatLng;
  String pickedAddress = "";
  bool _isLoading = true;
  GeoCodingApiCall geoCodingApiCall = GeoCodingApiCall();

  _onMapCreated(GoogleMapController googleMapController) async {
    _controller = googleMapController;
    setMapStyle();
  }

  setMapStyle() async {
    _controller.setMapStyle(
        await rootBundle.loadString('assets/mapStyle/map_style.txt'));
  }

  void _onCameraMove(CameraPosition newPosition) {
    setState(() {
      position = newPosition.target;
    });
  }

  void _onCameraIdle() async {
    await _fetchAddressFor(position);
  }

  Future<void> _fetchAddressFor(LatLng target) async {
    try {
      final placemarks =
          await geoCodingApiCall.findFormattedAddressesFromCoordinates(target);

      if (placemarks != null && placemarks.isNotEmpty) {
        setState(() {
          pickedAddress = placemarks[0];
        });
      }
    } catch (e) {
      logd('CustomMapPicker>>>', e.toString());
    }

    widget.updateLatLng(target);
  }

  void _zoomIn() {
    _controller.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _controller.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void initState() {
    super.initState();
    position = widget.latLng;
    _isLoading = false;
    _fetchAddressFor(position);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MapLoader();
    }

    final topInset = MediaQuery.viewPaddingOf(context).top;
    final theme = context.aeTheme;

    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: position,
              zoom: 15,
            ),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          // Fixed centre pin (the camera moves under it).
          Center(
            child: AoMapPin(
              color: theme.primary,
              shadowColor: theme.text.withValues(alpha: 0.35),
            ),
          ),
          // `.tk-head .ae-back` floating over the map.
          Positioned(
            top: topInset + 8,
            left: 18,
            child: AoShinyBackButton(
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          // Picked-address card — white, radius 18, `--ae-shadow-card`.
          Positioned(
            top: topInset + 8,
            left: 74,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: ScSaasThemeTokens.shadowCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kAoPickedPositionLabel,
                    style: aoText(
                      11.5,
                      FontWeight.w800,
                      letterSpacingEm: 0.05,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pickedAddress.trim().isEmpty
                        ? '${position.latitude.toStringAsFixed(6)}, '
                            '${position.longitude.toStringAsFixed(6)}'
                        : pickedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: aoText(14.5, FontWeight.w700, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          // Zoom controls — white `.ae-back`-style circles.
          Positioned(
            right: 18,
            bottom: 150,
            child: Column(
              children: [
                _zoomButton(Icons.add_rounded, _zoomIn),
                const SizedBox(height: 10),
                _zoomButton(Icons.remove_rounded, _zoomOut),
              ],
            ),
          ),
          // `.co-foot` — sticky confirm over the lavender fade.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AoStickyFooter(
              child: AuthPrimaryButton(
                label: languages.locationChooseThis,
                onPressed: _confirm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    // Ensure latest coordinates propagate even if camera idle hasn't fired yet.
    widget.updateLatLng(position);
    if (pickedAddress.trim().isEmpty) {
      await _fetchAddressFor(position);
    }
    final fallback =
        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    if (!mounted) return;
    Navigator.pop(
      context,
      pickedAddress.trim().isEmpty ? fallback : pickedAddress,
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return AoPressable(
      scale: 0.93,
      onTap: onTap,
      builder: (context, pressed) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: ScSaasThemeTokens.shadowCard,
        ),
        child: Icon(icon, size: 20, color: ScSaasThemeTokens.text),
      ),
    );
  }
}

class MapLoader extends StatelessWidget {
  final bool enabled;

  const MapLoader({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: deviceWidth,
      child: Center(
        child: LoadImageSimple(
          image: 'assets/images/google-map-loading.png',
          width: deviceWidth / 2,
        ),
      ),
    );
  }
}

/// Info-card eyebrow on the map picker.
const String kAoPickedPositionLabel = 'Valgt posisjon'; // TODO(l10n)
