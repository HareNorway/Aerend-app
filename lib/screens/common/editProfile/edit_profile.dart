import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commonView/common_view.dart';
import '../../../commonView/customCountryCodePicker/custom_country_code_picker.dart';
import '../../../commonView/custom_text_field.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import '../login/login_dl.dart';
import 'edit_profile_bloc.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  EditProfileState createState() => EditProfileState();
}

class EditProfileState extends State<EditProfile> {
  late EditProfileBloc _bloc;

  double formSpacingVertical = deviceHeight * 0.025;

  @override
  void didChangeDependencies() {
    _bloc = EditProfileBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              languages.myProfile,
              style: toolbarStyle(),
            ),
          ),
          body: _buildEditProfile(context),
        ),
        onWillPop: () async {
          Navigator.pop(context, _bloc.isChangedData);
          return false;
        });
  }

  _buildEditProfile(BuildContext context) {
    var textStyle =
        bodyText(fontSize: textSizeMediumBig, fontWeight: FontWeight.w600);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.04),
            child: Column(
              children: [
                Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(deviceAverageSize * 0.06),
                      child: profileImage(),
                    ),
                    GestureDetector(
                      onTap: () {
                        _bloc.addProfileImage();
                      },
                      child: Container(
                        margin: EdgeInsetsDirectional.only(
                            top: deviceHeight * 0.008),
                        child: Text(
                          languages.changePicture,
                          textAlign: TextAlign.center,
                          style: bodyText(
                              fontSize: textSizeBig,
                              textColor: colorPrimary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: AlignmentDirectional.topStart,
                  margin: EdgeInsetsDirectional.only(
                      start: deviceWidth * 0.04,
                      end: deviceWidth * 0.04,
                      top: deviceHeight * 0.05),
                  child: Form(
                    key: _bloc.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormFieldCustom(
                          controller: _bloc.fullNameTEC,
                          useLabelWithBorder: true,
                          decoration:
                              InputDecoration(labelText: languages.fullName),
                          suffix: Padding(
                            padding: EdgeInsetsDirectional.only(
                                end: deviceWidth * 0.04),
                            child: Icon(
                              CustomIcons.edit,
                              size: deviceHeight * 0.02,
                              color: colorMainLightGray,
                            ),
                          ),
                          style: textStyle,
                          setError: true,
                          validator: (value) {
                            _bloc.buttonHide();
                            return fullNameValidate(value);
                          },
                        ),
                        SizedBox(height: formSpacingVertical),
                        TextFormFieldCustom(
                          controller: _bloc.emailTEC,
                          keyboardType: TextInputType.emailAddress,
                          readOnly:
                              prefGetString(prefLoginType) != loginTypeEmail,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.emailAddress),
                          suffix: prefGetString(prefLoginType) == loginTypeEmail
                              ? Padding(
                                  padding: EdgeInsetsDirectional.only(
                                      end: deviceWidth * 0.04),
                                  child: Icon(
                                    CustomIcons.edit,
                                    size: deviceHeight * 0.02,
                                    color: colorMainLightGray,
                                  ),
                                )
                              : const SizedBox(width: 0, height: 0),
                          style: textStyle,
                          setError: true,
                          validator: (value) {
                            _bloc.buttonHide();
                            return validateEmailOrNumber(value);
                          },
                        ),
                        SizedBox(height: formSpacingVertical),
                        TextFormFieldCustom(
                          controller: _bloc.mobileNoTEC,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.mobileNumber),
                          suffix: Padding(
                            padding: EdgeInsetsDirectional.only(
                                end: deviceWidth * 0.04),
                            child: Icon(
                              CustomIcons.edit,
                              size: deviceHeight * 0.02,
                              color: colorMainLightGray,
                            ),
                          ),
                          prefix: CustomCountryCodePicker(
                            showDropDownButton: true,
                            flagWidth: deviceHeight * 0.035,
                            showFlag: false,
                            showFlagDialog: true,
                            padding: const EdgeInsets.all(0),
                            dialogSize:
                                Size(deviceWidth * 0.9, deviceHeight * 0.9),
                            textStyle: textStyle,
                            dialogTextStyle: textStyle,
                            onChanged: _bloc.changeCountryCode,
                            onInit: (value) {
                              if (value != null) {
                                _bloc.changeCountryCode(value);
                              }
                            },
                            initialSelection:
                                prefGetString(prefCountryCode).trim().isNotEmpty
                                    ? prefGetString(prefCountryCode)
                                    : defaultCountryCode.name,
                          ),
                          style: textStyle,
                          setError: true,
                          validator: (value) {
                            _bloc.buttonHide();
                            return mobileNumberValidate(value);
                          },
                        ),
                        SizedBox(height: formSpacingVertical),
                        TextFormFieldCustom(
                          controller: _bloc.emergencyContactTEC,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          useLabelWithBorder: true,
                          decoration: InputDecoration(
                              labelText: languages.emergencyContact),
                          suffix: Padding(
                            padding: EdgeInsetsDirectional.only(
                                end: deviceWidth * 0.04),
                            child: Icon(
                              CustomIcons.edit,
                              size: deviceHeight * 0.02,
                              color: colorMainLightGray,
                            ),
                          ),
                          style: textStyle,
                          setError: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 1, child: deleteButton()),
                Expanded(flex: 1, child: updateButton()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  profileImage() {
    return StreamBuilder<File?>(
        stream: _bloc.imgFile,
        builder: (context, snap) {
          return snap.data != null
              ? Image.file(
                  snap.data!,
                  width: deviceAverageSize * 0.12,
                  height: deviceAverageSize * 0.12,
                  fit: BoxFit.cover,
                )
              : StreamBuilder<String>(
                  stream: _bloc.profileImg,
                  builder: (context, snap) {
                    return Hero(
                      tag: snap.data ?? "",
                      createRectTween: (Rect? begin, Rect? end) {
                        return MaterialRectCenterArcTween(
                            begin: begin, end: end);
                      },
                      child: GestureDetector(
                        onTap: () {
                          /*if (snap.data != null && snap.data!.isNotEmpty) {
                          Navigator.of(context).push(
                            PageRouteBuilder<void>(
                              opaque: false,
                              transitionDuration: const Duration(milliseconds: 400),
                              reverseTransitionDuration: const Duration(milliseconds: 500),
                              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: const Interval(0.0, 1.0, curve: Curves.linear).transform(animation.value),
                                      child: ZoomImageView(image: snap.data ?? ""),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        }*/
                        },
                        child: LoadImageWithPlaceHolder(
                          width: deviceAverageSize * 0.12,
                          height: deviceAverageSize * 0.12,
                          image: (snap.data ?? "").trim(),
                          defaultAssetImage: "assets/images/avatar_user.png",
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    );
                  },
                );
        });
  }

  updateButton() {
    return StreamBuilder<bool>(
      stream: _bloc.submitValid,
      builder: (context, snap) {
        bool isEnable = snap.data ?? false;
        return StreamBuilder<ApiResponse<LoginPojo>>(
          stream: _bloc.subject,
          builder: (context, snapLoading) {
            var isLoading = snapLoading.hasData &&
                snapLoading.data?.status == Status.loading;
            return CustomRoundedButton(
              context,
              languages.update,
              (isLoading || !isEnable)
                  ? null
                  : () {
                      _bloc.updateProfile();
                    },
              setProgress: isLoading,
              fontWeight: FontWeight.w700,
              textSize: textSizeLarge,
              minWidth: deviceWidth,
              bgColor: colorPrimary,
              textColor: colorWhite,
              minHeight: commonBtnHeight,
              padding: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.02, end: deviceWidth * 0.02),
              margin: EdgeInsetsDirectional.only(
                start: deviceWidth * 0.02,
                end: deviceWidth * 0.05,
                top: deviceHeight * 0.05,
                bottom: deviceHeight * 0.035,
              ),
            );
          },
        );
      },
    );
  }

  deleteButton() {
    return StreamBuilder<ApiResponse<BaseModel>>(
      stream: _bloc.deleteAccountSubject,
      builder: (context, snapLoading) {
        var isLoading =
            snapLoading.hasData && snapLoading.data?.status == Status.loading;
        return CustomRoundedButton(
          context,
          languages.delete,
          isLoading
              ? null
              : () {
                  _bloc.openDeleteAccountDialog();
                },
          setProgress: isLoading,
          fontWeight: FontWeight.w700,
          textSize: textSizeLarge,
          minWidth: deviceWidth,
          bgColor: colorPrimary,
          textColor: colorWhite,
          minHeight: commonBtnHeight,
          padding: EdgeInsetsDirectional.only(
              start: deviceWidth * 0.02, end: deviceWidth * 0.02),
          margin: EdgeInsetsDirectional.only(
            start: deviceWidth * 0.05,
            end: deviceWidth * 0.02,
            top: deviceHeight * 0.05,
            bottom: deviceHeight * 0.035,
          ),
        );
      },
    );
  }
}
