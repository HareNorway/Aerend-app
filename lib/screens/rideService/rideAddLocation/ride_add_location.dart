import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../commonView/common_view.dart';
import '../../../../googleApi/place_model_dl.dart';
import '../../../../utils/utils.dart';
import '../../../commonView/custom_text_field.dart';
import 'ride_add_location_bloc.dart';

class RideAddLocation extends StatefulWidget {
  const RideAddLocation({super.key});

  @override
  State<RideAddLocation> createState() => _RideAddLocationState();
}

class _RideAddLocationState extends State<RideAddLocation> {
  RideAddLocationBloc? _bloc;

  @override
  void didChangeDependencies() {
    _bloc = _bloc ?? RideAddLocationBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        automaticallyImplyLeading: true,
        title: Text(
          languages.selectLocation.toUpperCase(),
          textAlign: TextAlign.start,
          style: toolbarStyle(),
        ),
      ),
      body: _buildRideAddLocation(context),
    );
  }

  _buildRideAddLocation(BuildContext context) {
    return StreamBuilder<bool>(
        stream: _bloc!.loading,
        builder: (context, snapshot) {
          bool isLoading = snapshot.data == null ? false : snapshot.data!;
          return Stack(
            alignment: AlignmentDirectional.center,
            children: [
              GoogleMap(
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                mapType: MapType.normal,
                initialCameraPosition: initCameraPosition,
                onCameraMove: (cameraPosition) {
                  _bloc!.onCameraMoved(cameraPosition);
                  FocusManager.instance.primaryFocus?.unfocus();
                  _bloc!.textEditingController.clear();
                },
                onCameraIdle: _bloc!.onCameraIdle,
                onMapCreated: _bloc!.onMapCreated,
                myLocationButtonEnabled: false,
              ),
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  isLoading ? "assets/images/ic_pin_current_location_disable.png" : "assets/images/ic_pin_current_location.png",
                  width: deviceAverageSize * 0.065,
                  height: deviceAverageSize * 0.065,
                ),
              ),
              Container(
                alignment: AlignmentDirectional.bottomCenter,
                child: confirmButton(isLoading),
              ),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        _bloc!.getCurrentLocation(forcefullyGetLocation: true);
                      },
                child: Container(
                  alignment: AlignmentDirectional.bottomEnd,
                  margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.025, end: deviceWidth * 0.035),
                  child: Card(
                      elevation: deviceAverageSize * 0.01,
                      color: colorWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(deviceAverageSize * 0.1),
                      ),
                      child: SizedBox(
                          height: deviceAverageSize * 0.06,
                          width: deviceAverageSize * 0.06,
                          child: Icon(
                            CustomIcons.gps,
                            size: deviceAverageSize * 0.035,
                            color: colorBlack,
                          ))),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      elevation: deviceAverageSize * 0.02,
                      margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02, start: deviceWidth * 0.04, end: deviceWidth * 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(deviceAverageSize * 0.004),
                      ),
                      child: Container(
                        width: deviceWidth,
                        color: colorWhite,
                        padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, top: deviceHeight * 0.003, bottom: deviceHeight * 0.003, end: deviceWidth * 0.02),
                        child: searchLocation(),
                      ),
                    ),
                    Flexible(
                      child: Card(
                        elevation: deviceAverageSize * 0.02,
                        margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01, start: deviceWidth * 0.04, end: deviceWidth * 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(deviceAverageSize * 0.004),
                        ),
                        child: placesList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  searchLocation() {
    return StreamBuilder<String>(
      stream: _bloc!.locationSearch,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _bloc!.textEditingController.value = _bloc!.textEditingController.value.copyWith(text: snapshot.data ?? "");
        }
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.01, end: deviceWidth * 0.01),
                child: TextFormFieldCustom(
                  setError: true,
                  suffix: Container(),
                  controller: _bloc!.textEditingController,
                  onChanged: (value) {
                    _bloc!.getPlaces(value);
                  },
                  hint: languages.searchLocation,
                  // setClear: true,
                  prefix: Padding(
                    padding: EdgeInsetsDirectional.only(end: deviceWidth * 0.02),
                    child: Icon(
                      CustomIcons.search,
                      size: deviceAverageSize * 0.035,
                      color: colorTextCommon,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 0,
              child: (snapshot.data != null && snapshot.data!.isNotEmpty)
                  ? GestureDetector(
                      onTap: () {
                        _bloc!.changeLocationSearch("");
                        _bloc!.textEditingController.clear();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: Icon(
                        CustomIcons.cancelled,
                        color: colorPrimary,
                        size: deviceAverageSize * 0.035,
                      ),
                    )
                  : Container(),
            ),
          ],
        );
      },
    );
  }

  confirmButton(bool isLoading) {
    return StreamBuilder<String>(
      stream: _bloc!.locationSearch,
      builder: (context, snapshot) {
        return SizedBox(
          width: deviceWidth * commonBtnWidth,
          child: CustomRoundedButton(context, isLoading ? languages.fetchingLocation : languages.confirmPlace,
              (snapshot.data != null && snapshot.data!.isNotEmpty && !isLoading) ? _bloc!.confirmPlace : () {},
              minHeight: commonBtnHeightMedium,
              minWidth: commonBtnWidth,
              fontWeight: FontWeight.w600,
              textColor: colorWhite,
              roundedRectangleBorder: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(topStart: topLeftRadius, topEnd: topRightRadius, bottomStart: bottomLeftRadius, bottomEnd: bottomRightRadius),
              ),
              textAlign: TextAlign.center,
              bgColor: colorPrimary,
              maxLine: 1,
              elevation: 0,
              textSize: textSizeBig,
              padding: EdgeInsetsDirectional.zero,
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02, bottom: deviceHeight * 0.02)),
        );
      },
    );
  }

  placesList() {
    return StreamBuilder<String>(
      stream: _bloc!.locationSearch,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return StreamBuilder<List<Predictions>>(
            stream: _bloc?.placesList,
            builder: (context, snapPlacesList) {
              List<Predictions> data = snapPlacesList.data ?? [];
              return data.isNotEmpty
                  ? ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => Container(
                        margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.12),
                        child: Divider(
                          color: colorMainView,
                          thickness: deviceHeight * 0.002,
                          height: 0,
                        ),
                      ),
                      padding: const EdgeInsetsDirectional.only(top: 0),
                      itemCount: data.length,
                      itemBuilder: (BuildContext context, position) {
                        return ListTile(
                          tileColor: colorWhite,
                          onTap: () {
                            _bloc!.onPlaceListClick(data[position].description ?? "", data[position].placeId ?? "");
                          },
                          horizontalTitleGap: 0,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data[position].description ?? "",
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyText(fontSize: textSizeRegular, fontWeight: FontWeight.normal, textColor: colorBlack),
                              ),
                              Text(
                                (data[position].structuredFormatting != null && data[position].structuredFormatting?.secondaryText != null)
                                    ? data[position].structuredFormatting?.secondaryText ?? ""
                                    : "",
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyText(fontSize: textSizeSmall, fontWeight: FontWeight.normal, textColor: colorTextCommon),
                              ),
                            ],
                          ),
                          leading: FaIcon(
                            FontAwesomeIcons.locationDot,
                            size: deviceAverageSize * 0.03,
                            color: colorTextCommonLight,
                          ),
                        );
                      },
                    )
                  : Container(height: 0);
            },
          );
        } else {
          return Container(
            height: 0,
          );
        }
      },
    );
  }
}
