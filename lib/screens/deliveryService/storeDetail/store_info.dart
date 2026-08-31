import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../commonView/no_record_found.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import 'store_detail_bloc.dart';
import 'store_detail_dl.dart';
import 'store_detail_shimmer.dart';

class StoreInfo extends StatefulWidget {
  final int storeId;
  final String storeName;

  const StoreInfo({super.key, required this.storeId, required this.storeName});

  @override
  StoreInfoState createState() => StoreInfoState();
}

class StoreInfoState extends State<StoreInfo> {
  late StoreDetailBloc bloc;
  GoogleMapController? _mapController;

  Future<void> _applyMapStyleForBrightness(Brightness brightness) async {
    if (_mapController == null) return;
    final String path = brightness == Brightness.dark
        ? 'assets/mapStyle/map_style_dark.txt'
        : 'assets/mapStyle/map_style.txt';
    try {
      await _mapController!.setMapStyle(await rootBundle.loadString(path));
    } catch (_) {
      try {
        await _mapController!.setMapStyle(
          await rootBundle.loadString('assets/mapStyle/map_style.txt'),
        );
      } catch (_) {}
    }
  }

  Future<void> onMapCreated(
    BuildContext context,
    GoogleMapController googleMapController,
  ) async {
    _mapController = googleMapController;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _applyMapStyleForBrightness(Theme.of(context).brightness);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    bloc = StoreDetailBloc(context, widget.storeId, this);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApiResponse<StoreDetailsPojo>>(
      stream: bloc.subject,
      builder: (context, snap) {
        if (snap.hasData) {
          switch (snap.data?.status) {
            case Status.loading:
              return shimmerView(context, true);
            case Status.completed:
              StoreDetailsPojo data = snap.data!.data!;
              return storeInfoView(context, data, bloc);
            case Status.error:
              return noRecordView(context, snap.data?.message ?? "");
            default:
              break;
          }
        }
        return shimmerView(context, true);
      },
    );
  }

  Widget storeInfoView(
    BuildContext context,
    StoreDetailsPojo data,
    StoreDetailBloc bloc,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color pageBg = theme.scaffoldBackgroundColor;
    final Color panelBg = cs.surface;
    final Color onSurface = cs.onSurface;
    final Color onMuted = onSurface.withOpacity(0.72);

    final TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: onSurface,
    );
    final TextStyle bodyStyle = TextStyle(
      fontSize: 14,
      color: onMuted,
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 4,
                  child: googleMap(context, data),
                ),
                Expanded(
                  flex: 6,
                  child: ColoredBox(color: pageBg),
                ),
              ],
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Material(
                color: panelBg,
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.35),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: deviceHeight * 0.72,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                data.storeName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: data.storeStatus == 1
                                    ? colorGreen
                                    : colorPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 15,
                              ),
                              child: Text(
                                data.storeStatus == 1 ? languages.open : languages.close,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: colorWhite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(languages.storeDescription, style: titleStyle),
                        const SizedBox(height: 10),
                        Text(
                          data.description,
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 22),
                        Text(languages.storePosition, style: titleStyle),
                        const SizedBox(height: 10),
                        Text(data.address, style: bodyStyle),
                        const SizedBox(height: 22),
                        Text(languages.storeOpeningTime, style: titleStyle),
                        const SizedBox(height: 10),
                        ...data.storeOpenCloseTime.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.displayDay,
                                    style: bodyStyle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    '${item.storeOpenTime} ~ ${item.storeCloseTime}',
                                    style: bodyStyle,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(languages.storeContact, style: titleStyle),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(languages.email, style: bodyStyle),
                            Flexible(
                              child: Text(
                                data.storeEmail,
                                style: bodyStyle,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(languages.storePhoneNumber, style: bodyStyle),
                            Flexible(
                              child: Text(
                                data.storeContactNumber,
                                style: bodyStyle,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        data.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                          shadows: [
                            Shadow(
                              color: panelBg.withOpacity(0.9),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    child: Material(
                      color: panelBg,
                      elevation: 2,
                      shape: const CircleBorder(),
                      child: IconButton(
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: SvgPicture.asset(
                          'assets/svgs/icons/back.svg',
                          height: 18,
                          width: 18,
                          colorFilter: ColorFilter.mode(
                            onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget googleMap(BuildContext context, StoreDetailsPojo data) => GoogleMap(
        zoomControlsEnabled: false,
        zoomGesturesEnabled: true,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            double.parse(data.latitude),
            double.parse(data.longitude),
          ),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('storeLocation'),
            position: LatLng(
              double.parse(data.latitude),
              double.parse(data.longitude),
            ),
          ),
        },
        onMapCreated: (c) => onMapCreated(context, c),
      );

  Widget shimmerView(BuildContext context, bool isLoading) {
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 150,
        backgroundColor: colorPrimary,
        title: const SizedBox(height: 120),
      ),
      body: StoreDetailShimmer(enabled: isLoading),
    );
  }

  Widget noRecordView(BuildContext context, String message) {
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          languages.restaurant.toUpperCase(),
          textAlign: TextAlign.start,
          style: toolbarStyle(),
        ),
      ),
      body: NoRecordFound(
        message: message,
        height: deviceAverageSize * 0.1,
      ),
    );
  }
}
