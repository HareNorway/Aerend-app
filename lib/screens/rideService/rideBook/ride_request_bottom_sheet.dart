import 'package:flutter/material.dart';

import '../../../commonView/common_view.dart';
import '../../../commonView/ripplesAnimationView/ripples_animation_view.dart';
import '../../../utils/utils.dart';
import 'ride_book_bloc.dart';

class RideRequestBottomSheet extends StatefulWidget {
  final RideBookBloc? bloc;

  const RideRequestBottomSheet({super.key, @required this.bloc});

  @override
  State createState() => _RideRequestBottomSheetState();
}

class _RideRequestBottomSheetState extends State<RideRequestBottomSheet> {
  late RideBookBloc _bloc;

  @override
  void didChangeDependencies() {
    _bloc = widget.bloc!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadiusDirectional.only(
                topEnd: topRightRadiusBs, topStart: topLeftRadiusBs),
            color: colorMainBackground),
        child: StreamBuilder<bool>(
            stream: _bloc.requestTimeOut,
            builder: (context, snapshot) {
              bool isTimeout = snapshot.data ?? true;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: RipplesAnimationView(
                      size: deviceAverageSize * 0.08,
                      color: colorRipple,
                      child: Padding(
                        padding: EdgeInsets.all(deviceAverageSize * 0.02),
                        child: Icon(
                          isTimeout
                              ? CustomIcons.nothingFound
                              : CustomIcons.findingDriver,
                          color: colorPrimary,
                          size: deviceAverageSize * 0.09,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    isTimeout
                        ? languages.notFindDriver
                        : languages.findDriver,
                    textAlign: TextAlign.center,
                    style: headerText(
                        fontWeight: FontWeight.w600,
                        textColor: colorTextCommon,
                        fontSize: textSizeLargest),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(
                        top: deviceHeight * 0.01,
                        bottom: deviceHeight * 0.03,
                        start: deviceWidth * 0.03,
                        end: deviceWidth * 0.03),
                    child: Text(
                      isTimeout
                          ? languages.notFindDriverMsg
                          : languages.findDriverMsg,
                      textAlign: TextAlign.center,
                      style: bodyText(
                          fontWeight: FontWeight.w500,
                          textColor: colorTextCommonLight,
                          fontSize: textSizeRegular),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsetsDirectional.only(
                        top: deviceHeight * 0.01,
                        bottom: deviceHeight * 0.03,
                        start: deviceWidth * 0.04,
                        end: deviceWidth * 0.04),
                    child: isTimeout
                        ? Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Container(
                                  margin: EdgeInsetsDirectional.only(
                                      end: deviceWidth * 0.02),
                                  child: CustomRoundedButton(
                                    context,
                                    languages.cancel,
                                    () {
                                      _bloc.cancelRideDialog();
                                    },
                                    fontWeight: FontWeight.w700,
                                    textColor: colorTextCommon,
                                    textSize: textSizeLarge,
                                    minHeight: commonBtnHeight,
                                    padding: EdgeInsetsDirectional.only(
                                        top: deviceHeight * 0.006,
                                        end: deviceWidth * 0.006,
                                        start: deviceWidth * 0.006,
                                        bottom: deviceHeight * 0.006),
                                    setBorder: true,
                                    elevation: 0,
                                    roundedRectangleBorder:
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadiusDirectional.only(
                                                    topStart: topLeftRadius,
                                                    topEnd: topRightRadius,
                                                    bottomStart:
                                                        bottomLeftRadius,
                                                    bottomEnd:
                                                        bottomRightRadius),
                                            side: BorderSide(
                                                color: colorPrimary,
                                                width:
                                                    deviceAverageSize * 0.005,
                                                style: BorderStyle.solid)),
                                    textAlign: TextAlign.center,
                                    maxLine: 1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsetsDirectional.only(
                                      start: deviceWidth * 0.02),
                                  child: CustomRoundedButton(
                                    context,
                                    languages.tryAgain,
                                    () {
                                      _bloc.requestAgain();
                                      Navigator.pop(context);
                                    },
                                    minHeight: commonBtnHeight,
                                    maxLine: 1,
                                    setBorder: false,
                                    elevation: 0,
                                    padding: EdgeInsetsDirectional.only(
                                        top: deviceHeight * 0.006,
                                        end: deviceWidth * 0.006,
                                        start: deviceWidth * 0.006,
                                        bottom: deviceHeight * 0.006),
                                    bgColor: colorPrimary,
                                    textAlign: TextAlign.center,
                                    textSize: textSizeLarge,
                                    textColor: colorWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            ],
                          )
                        : CustomRoundedButton(
                            context,
                            languages.cancel,
                            () {
                              _bloc.cancelRideDialog();
                            },
                            textColor: colorWhite,
                            fontWeight: FontWeight.w600,
                            textSize: textSizeBig,
                            bgColor: colorPrimary,
                            elevation: 0,
                            setBorder: false,
                            maxLine: 1,
                            minHeight: commonBtnHeight,
                            padding: EdgeInsetsDirectional.only(
                                top: deviceHeight * 0.006,
                                end: deviceWidth * 0.006,
                                start: deviceWidth * 0.006,
                                bottom: deviceHeight * 0.006),
                          ),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
