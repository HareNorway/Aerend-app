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
import '../../bergen/kit/ae_primitiver.dart' show AeKnappPille;
import '../auth/launch/lf_css.dart' show inter;
import '../../bergen/meg/a3_scaffold.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';

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

  // T3 (Vivo): this was the old purple «My Profile» (Material AppBar, purple buttons) inside the Bergen app. It now
  // uses the Bergen frame (A3Scaffold, fjord gradient), glass fields and the kit's pill; the bloc is unchanged.
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: A3Scaffold(
          title: languages.myProfile,
          padding: EdgeInsets.zero,
          child: _buildEditProfile(context),
        ),
        onWillPop: () async {
          Navigator.pop(context, _bloc.isChangedData);
          return false;
        });
  }

  static const _mint = Color(0xFF7FF0CB);

  InputDecoration _felt(String label, {Widget? prefix}) {
    final lys = context.lys;
    final kant = lys ? LysPalett.kantFarge : const Color.fromRGBO(255, 255, 255, .22);
    return InputDecoration(
      labelText: label,
      labelStyle: inter(13, weight: FontWeight.w700, color: lys ? LysPalett.sekundar : const Color(0xFFB8D4DA)),
      floatingLabelStyle: inter(13, weight: FontWeight.w800, color: lys ? LysPalett.mintTekst : _mint),
      filled: true,
      fillColor: lys ? Colors.white : const Color.fromRGBO(255, 255, 255, .08),
      prefixIcon: prefix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lys ? LysPalett.mintTekst : _mint, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF8A6A))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF8A6A), width: 1.5)),
      errorStyle: inter(12, weight: FontWeight.w700, color: const Color(0xFFFFB199)),
    );
  }

  TextStyle get _tekst => inter(15.5, weight: FontWeight.w700, color: context.lys ? LysPalett.tittel : Colors.white);

  _buildEditProfile(BuildContext context) {
    final lys = context.lys;
    final emailKanEndres = prefGetString(prefLoginType) == loginTypeEmail;
    // A3Scaffold already scrolls its child: a plain column (a CustomScrollView inside it had no height → blank page).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Form(
              key: _bloc.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () => _bloc.addProfileImage(),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: lys ? LysPalett.mintTekst : _mint, width: 2)),
                          child: ClipOval(child: profileImage()),
                        ),
                        const SizedBox(height: 8),
                        Text(languages.changePicture, style: inter(14, weight: FontWeight.w800, color: lys ? LysPalett.mintTekst : _mint)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    key: const Key('profil-navn'),
                    controller: _bloc.fullNameTEC,
                    style: _tekst,
                    textCapitalization: TextCapitalization.words,
                    decoration: _felt(languages.fullName),
                    validator: (value) {
                      _bloc.buttonHide();
                      return fullNameValidate(value);
                    },
                    onChanged: (_) => _bloc.buttonHide(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('profil-epost'),
                    controller: _bloc.emailTEC,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: !emailKanEndres,
                    style: _tekst.copyWith(color: emailKanEndres ? null : (lys ? LysPalett.sekundar : const Color(0xFFB8D4DA))),
                    decoration: _felt(languages.emailAddress),
                    validator: (value) {
                      _bloc.buttonHide();
                      final e = validateEmailOrNumber(value ?? '');
                      return e.isEmpty ? null : e; // '' means valid; a TextFormField takes '' as an error
                    },
                    onChanged: (_) => _bloc.buttonHide(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('profil-mobil'),
                    controller: _bloc.mobileNoTEC,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: _tekst,
                    decoration: _felt(
                      languages.mobileNumber,
                      prefix: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
                        child: CustomCountryCodePicker(
                          showDropDownButton: true,
                          arrowColor: context.lys ? LysPalett.sekundar : const Color(0xFFB8D4DA),
                          showFlag: false,
                          showFlagDialog: true,
                          padding: EdgeInsets.zero,
                          dialogSize: Size(deviceWidth * 0.9, deviceHeight * 0.9),
                          textStyle: _tekst,
                          dialogTextStyle: bodyText(fontSize: textSizeMediumBig, fontWeight: FontWeight.w600),
                          onChanged: _bloc.changeCountryCode,
                          onInit: (value) {
                            if (value != null) _bloc.changeCountryCode(value);
                          },
                          initialSelection: prefGetString(prefCountryCode).trim().isNotEmpty ? prefGetString(prefCountryCode) : defaultCountryCode.name,
                        ),
                      ),
                    ),
                    validator: (value) {
                      _bloc.buttonHide();
                      return mobileNumberValidate(value);
                    },
                    onChanged: (_) => _bloc.buttonHide(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('profil-nod'),
                    controller: _bloc.emergencyContactTEC,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    style: _tekst,
                    decoration: _felt(languages.emergencyContact),
                  ),
                ],
              ),
            ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 28, 16, 20 + MediaQuery.paddingOf(context).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            updateButton(),
            const SizedBox(height: 6),
            deleteButton(),
          ]),
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
        final isEnable = snap.data ?? false;
        return StreamBuilder<ApiResponse<LoginPojo>>(
          stream: _bloc.subject,
          builder: (context, snapLoading) {
            final isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
            return Opacity(
              opacity: isEnable || isLoading ? 1 : .55,
              child: AeKnappPille(
                key: const Key('profil-lagre'),
                label: isLoading ? '…' : languages.update,
                onPressed: (isLoading || !isEnable) ? null : () => _bloc.updateProfile(),
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
        final isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
        return TextButton(
          key: const Key('profil-slett'),
          onPressed: isLoading ? null : () => _bloc.openDeleteAccountDialog(),
          child: Text(isLoading ? '…' : languages.accountDelete,
              style: inter(14, weight: FontWeight.w800, color: context.lys ? const Color(0xFFB4421C) : const Color(0xFFFFB199))),
        );
      },
    );
  }
}
