import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../constant/constant.dart';
import '../main.dart';
import '../ui/kit/ae_theme.dart';
import '../theme/sc_saas_theme.dart';
import 'common_view.dart';

class ImageSelection extends StatelessWidget {
  final Function onPressedCamera, onPressedGallery;

  const ImageSelection({
    super.key,
    required this.onPressedCamera,
    required this.onPressedGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: deviceHeight * 0.01,
        horizontal: deviceWidth * 0.01,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(deviceAverageSize * 0.05),
          topRight: Radius.circular(deviceAverageSize * 0.05),
        ),
        color: theme.background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: deviceWidth * 0.12,
            child: Divider(
              color: theme.primary,
              thickness: deviceHeight * 0.0035,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: CustomRoundedButton(
                  context,
                  languages.camera.toUpperCase(),
                  () {
                    onPressedCamera();
                  },
                  bgColor: theme.primary,
                  maxLine: 1,
                  textAlign: TextAlign.center,
                  textSize: textSizeRegular,
                  textColor: ScSaasThemeTokens.card,
                  fontWeight: FontWeight.w700,
                  minHeight: commonBtnHeightSmall,
                  setBorder: false,
                  minWidth: 0.4,
                  icon: Icon(
                    Icons.camera_alt,
                    color: ScSaasThemeTokens.card,
                  ),
                  margin: EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.04,
                    end: deviceWidth * 0.04,
                    top: deviceHeight * 0.015,
                    bottom: deviceHeight * 0.015,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: CustomRoundedButton(
                  context,
                  languages.gallery.toUpperCase(),
                  () {
                    onPressedGallery();
                  },
                  bgColor: theme.primary,
                  maxLine: 1,
                  textAlign: TextAlign.center,
                  textSize: textSizeRegular,
                  textColor: ScSaasThemeTokens.card,
                  fontWeight: FontWeight.w700,
                  minHeight: commonBtnHeightSmall,
                  setBorder: false,
                  minWidth: 0.4,
                  icon: Icon(
                    Icons.photo_library_rounded,
                    color: ScSaasThemeTokens.card,
                  ),
                  margin: EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.04,
                    end: deviceWidth * 0.04,
                    top: deviceHeight * 0.015,
                    bottom: deviceHeight * 0.015,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<File?> _getImage(
  BuildContext context,
  bool isCamera,
  String toolbarTitle,
) async {
  final theme = context.aeTheme;
  CroppedFile? croppedFile;
  var pickedFile = await ImagePicker().pickImage(
    source: isCamera ? ImageSource.camera : ImageSource.gallery,
  );

  if (pickedFile != null) {
    croppedFile = (await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: toolbarTitle,
          toolbarColor: theme.primary,
          toolbarWidgetColor: ScSaasThemeTokens.card,
          activeControlsWidgetColor: theme.primary,
          lockAspectRatio: true,
        ),
        IOSUiSettings(minimumAspectRatio: 1.0),
      ],
    ));
  }
  return File(croppedFile != null ? croppedFile.path : "");
}

selectImgFromCameraOrGallery(
  BuildContext context,
  Function(File file) fileCallback,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return ImageSelection(
        onPressedCamera: () {
          Navigator.pop(sheetContext);
          _getImage(context, true, languages.cropper).then((value) {
            if (value != null && value.existsSync()) {
              fileCallback(value);
            }
          });
        },
        onPressedGallery: () {
          Navigator.pop(sheetContext);
          _getImage(context, false, languages.cropper).then((value) {
            if (value != null && value.existsSync()) {
              fileCallback(value);
            }
          });
        },
      );
    },
  );
}
