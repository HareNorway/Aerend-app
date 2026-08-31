import 'package:flutter/material.dart';

import '../commonView/common_view.dart';
import '../commonView/modal_ui.dart';
import '../commonView/custom_text_field.dart';
import '../commonView/dropdown_button2.dart';
import '../commonView/widget_util.dart';
import '../theme/sc_saas_theme.dart';
import '../utils/utils.dart';

class RideCommonDialog extends StatefulWidget {
  final String title;
  final String msg;
  final String dialogImg;
  final String positiveBtnTxt;
  final String textFieldHint;
  final String dropDownLabelText;
  final String textFieldEmptyErrorMsg;
  final Function(int, String) positiveBtnOnClick;
  final String negativeBtnTxt;
  final Function() negativeBtnOnClick;
  final List<String>? spinnerList;
  final Function(int)? spinnerSelectedItem;
  final int defaultSpinnerSelectionPos;
  final bool isLoading;

  const RideCommonDialog({
    super.key,
    this.title = "",
    this.msg = "",
    this.dialogImg = "",
    this.positiveBtnTxt = "",
    this.negativeBtnTxt = "",
    this.textFieldHint = "",
    this.textFieldEmptyErrorMsg = "",
    required this.positiveBtnOnClick,
    required this.negativeBtnOnClick,
    this.spinnerList,
    this.spinnerSelectedItem,
    this.defaultSpinnerSelectionPos = 0,
    this.isLoading = false,
    this.dropDownLabelText = "",
  });

  @override
  RideCommonDialogState createState() => RideCommonDialogState();
}

class RideCommonDialogState extends State<RideCommonDialog> {
  String spinnerSelectedItem = "";
  final TextEditingController _textEditingController = TextEditingController();

  // bool setError = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    spinnerSelectedItem = widget.spinnerList != null ? widget.spinnerList![widget.defaultSpinnerSelectionPos] : "";
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) => Dialog(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          insetPadding: EdgeInsets.only(left: deviceWidth * 0.035, right: deviceWidth * 0.035, bottom: MediaQuery.of(context).viewInsets.bottom),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(deviceAverageSize * 0.02)),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModalUi.handle(),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Image.asset(
                        "assets/images/dialog_image_bg.png",
                        width: deviceWidth,
                        fit: BoxFit.fitHeight,
                      ),
                      widget.dialogImg.trim().isNotEmpty
                          ? Image.asset(
                              widget.dialogImg,
                              width: deviceWidth,
                              fit: BoxFit.fitHeight,
                            )
                          : Container(),
                    ],
                  ),
                  widget.title.trim().isNotEmpty
                      ? Container(
                          alignment: AlignmentDirectional.center,
                          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, top: deviceHeight * 0.025),
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: bodyText(fontSize: textSizeLargest, textColor: ScSaasThemeTokens.text, fontWeight: FontWeight.w700),
                          ),
                        )
                      : Container(),
                  widget.msg.trim().isNotEmpty
                      ? Container(
                          alignment: AlignmentDirectional.center,
                          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, top: deviceHeight * 0.01),
                          child: Text(
                            widget.msg,
                            textAlign: TextAlign.center,
                            style: bodyText(fontSize: textSizeSmall, textColor: ScSaasThemeTokens.muted, fontWeight: FontWeight.normal),
                          ),
                        )
                      : Container(),
                  widget.spinnerList != null
                      ? Container(
                          alignment: Alignment.center,
                          margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02, start: deviceWidth * 0.05, end: deviceWidth * 0.05),
                          padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.025),
                          width: deviceWidth,
                          child: DropdownButtonFormField2<String>(
                            iconSize: deviceAverageSize * 0.045,
                            isExpanded: true,
                            decoration: getInputDecorationCommon(labelText: widget.dropDownLabelText),
                            value: spinnerSelectedItem.trim().isNotEmpty
                                ? spinnerSelectedItem
                                : widget.spinnerList![
                                    (widget.spinnerList!.length > widget.defaultSpinnerSelectionPos) ? widget.defaultSpinnerSelectionPos : 0],
                            onChanged: (value) {
                              setState(() {
                                spinnerSelectedItem = value ?? "";
                              });
                            },
                            items: widget.spinnerList!
                                .map<DropdownMenuItem<String>>(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          e,
                                          textAlign: TextAlign.center,
                                          style: bodyText(fontSize: textSizeMediumBig, fontWeight: FontWeight.w700, textColor: ScSaasThemeTokens.text),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      : Container(),
                  widget.textFieldHint.trim().isNotEmpty
                      ? Container(
                          color: colorMainBackground,
                          padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.05, end: deviceWidth * 0.05, top: deviceHeight * 0.01),
                          alignment: Alignment.centerLeft,
                          child: Form(
                            key: _formKey,
                            child: TextFormFieldCustom(
                                backgroundColor: colorMainBackground,
                                keyboardType: TextInputType.multiline,
                                maxLine: 3,
                                minLine: 1,
                                controller: _textEditingController,
                                setError: true,
                                hint: widget.textFieldHint,
                                validator: (value) {
                                  return validateEmptyField(value, languages.enterCancelReason);
                                },
                                onChanged: (value) {
                                  // if (value.isEmpty) {
                                  //   setState(() {
                                  //     setError = true;
                                  //   });
                                  // } else {
                                  //   setState(() {
                                  //     setError = false;
                                  //   });
                                  // }
                                }),
                          ),
                        )
                      : Container(),
                  Container(
                    margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.08, end: deviceWidth * 0.08),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        widget.negativeBtnTxt.trim().isNotEmpty
                            ? Flexible(
                                flex: 1,
                                child: CustomRoundedButton(
                                  context,
                                  widget.negativeBtnTxt,
                                  widget.negativeBtnOnClick,
                                  roundedRectangleBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusDirectional.only(
                                        topStart: topLeftRadius, topEnd: topRightRadius, bottomStart: bottomLeftRadius, bottomEnd: bottomRightRadius),
                                    side: BorderSide(color: ScSaasThemeTokens.border, width: deviceHeight * 0.002, style: BorderStyle.solid),
                                  ),
                                  setBorder: true,
                                  fontWeight: FontWeight.w700,
                                  textColor: ScSaasThemeTokens.text,
                                  textSize: textSizeBig,
                                  maxLine: 1,
                                  textAlign: TextAlign.center,
                                  minHeight: commonBtnHeight,
                                  minWidth: 0.5,
                                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.04, end: deviceWidth * 0.03, bottom: deviceHeight * 0.02),
                                ),
                              )
                            : Container(),
                        widget.positiveBtnTxt.trim().isNotEmpty
                            ? Flexible(
                                flex: 1,
                                child: CustomRoundedButton(
                                  context,
                                  widget.positiveBtnTxt,
                                  widget.isLoading
                                      ? null
                                      : () {
                                          int spinnerSelectedPos = 0;
                                          String textFieldValue = "";
                                          if (widget.spinnerList != null) {
                                            spinnerSelectedPos = widget.spinnerList?.indexOf(spinnerSelectedItem) ?? 0;
                                          }
                                          if (widget.textFieldHint.trim().isNotEmpty && _textEditingController.value.text.trim().isEmpty) {
                                            // setState(() {
                                            //   setError = true;
                                            // });
                                            _formKey.currentState!.validate();
                                            return;
                                          } else {
                                            textFieldValue = _textEditingController.value.text.trim();
                                            widget.positiveBtnOnClick(spinnerSelectedPos, textFieldValue);
                                          }
                                        },
                                  minWidth: 0.5,
                                  minHeight: commonBtnHeight,
                                  padding: EdgeInsetsDirectional.zero,
                                  margin:
                                      EdgeInsetsDirectional.only(top: deviceHeight * 0.04, start: deviceWidth * 0.03, bottom: deviceHeight * 0.02),
                                  setBorder: false,
                                  textSize: textSizeBig,
                                  textColor: colorWhite,
                                  maxLine: 1,
                                  fontWeight: FontWeight.w700,
                                  elevation: 0,
                                  bgColor: ScSaasThemeTokens.primary,
                                  textAlign: TextAlign.center,
                                  setProgress: widget.isLoading,
                                  progressStrokeWidth: cpiStrokeWidthSmallest,
                                  progressSize: 0.026,
                                  progressColor: colorWhite,
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
