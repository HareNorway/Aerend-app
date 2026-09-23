import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/customCountryCodePicker/country_code.dart';
import '../../../commonView/image_selection.dart';
import '../../../dialogs/simple_dialog_util.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import '../login/login_dl.dart';
import 'edit_profile.dart';
import 'edit_profile_repo.dart';

class EditProfileBloc extends Bloc {
  BuildContext context;
  final EditProfileRepo _editProfileRepo = EditProfileRepo();
  bool isChangedData = false;
  String userId = ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
  late DatabaseReference _referenceUser;

  State<EditProfile> state;

  EditProfileBloc(this.context, this.state) {
    _referenceUser = FirebaseDatabase.instance
        .ref()
        .child(ChatConstant.chat)
        .child(ChatConstant.users)
        .child("a_1");
    setProfileData();
  }

  TextEditingController fullNameTEC = TextEditingController();
  TextEditingController emailTEC = TextEditingController();
  TextEditingController mobileNoTEC = TextEditingController();
  TextEditingController emergencyContactTEC = TextEditingController();

  final _profileImgController = BehaviorSubject<String>();
  final _countryCodeController = BehaviorSubject<CountryCode?>();
  final _imgFileController = BehaviorSubject<File>();
  final formKey = GlobalKey<FormState>();
  final _deleteAccountSubject = BehaviorSubject<ApiResponse<BaseModel>>();

  final submitValid = BehaviorSubject<bool>();
  final _subject = BehaviorSubject<ApiResponse<LoginPojo>>();

  BehaviorSubject<ApiResponse<LoginPojo>> get subject => _subject;

  BehaviorSubject<ApiResponse<BaseModel>> get deleteAccountSubject =>
      _deleteAccountSubject;

  Stream<File> get imgFile => _imgFileController.stream;

  Stream<String> get profileImg => _profileImgController.stream;

  Stream<CountryCode?> get countryCode => _countryCodeController.stream;

  Function(File) get changeImgFile => _imgFileController.sink.add;

  Function(String) get changeProfileImg => _profileImgController.sink.add;

  Function(CountryCode?) get changeCountryCode =>
      _countryCodeController.sink.add;

  setProfileData() {
    changeProfileImg(prefGetString(prefProfileImage));
    fullNameTEC.text = prefGetString(prefUserName);
    emailTEC.text = prefGetString(prefEmail);
    mobileNoTEC.text = prefGetString(prefContactNumber);
    emergencyContactTEC.text = prefGetString(prefEmergencyContact);
    changeCountryCode(CountryCode(dialCode: prefGetString(prefCountryCode)));
    buttonHide();
    checkAndSetUser();
  }

  checkAndSetUser() {
    _referenceUser
        .orderByChild(ChatConstant.userId)
        .equalTo(userId)
        .once()
        .then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        Map data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
        var updateMap = <String, dynamic>{};
        updateMap[ChatConstant.userProfile] = prefGetString(prefProfileImage);
        updateMap[ChatConstant.userName] = prefGetString(prefUserName);
        _referenceUser
            .orderByChild(ChatConstant.userId)
            .equalTo(userId)
            .ref
            .child(data.keys.elementAt(0))
            .update(updateMap);
      }
    });
  }

  updateProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (formKey.currentState!.validate()) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        MultipartFile? multipartFile;
        if (_imgFileController.hasValue &&
            _imgFileController.value.path.isNotEmpty) {
          multipartFile = MultipartFile.fromFileSync(
              _imgFileController.value.path,
              filename: _imgFileController.value.path.split('/').last);
        }
        _subject.sink.add(ApiResponse.loading());
        try {
          var response = LoginPojo.fromJson(
              await _editProfileRepo.editProfileApi(
                  fullNameTEC.text.trim(),
                  _countryCodeController.value?.dialCode ??
                      defaultCountryCode.dialCode!,
                  mobileNoTEC.text.trim(),
                  emailTEC.text.trim(),
                  emergencyContactTEC.text.trim(),
                  multipartFile: multipartFile,
                  progress: (double progress) => _subject.sink.add(
                        ApiResponse.loading(progress: progress),
                      )));

          if (!state.mounted) return;
          String message =
              getApiMsg(context, response.messageCode, response.message);
          if (isApiStatus(context, response.status, message, true)) {
            _subject.sink.add(ApiResponse.completed(response));
            prefSetString(prefUserName, response.userName);
            prefSetString(prefProfileImage, response.profileImage);
            prefSetString(prefCountryCode, response.selectCountryCode);
            prefSetString(prefContactNumber, response.contactNumber);
            prefSetString(prefEmail, response.email);
            prefSetString(prefEmergencyContact, response.emergencyContact);
            isChangedData = true;
            setProfileData();
            openSimpleSnackbar(languages.profileUpdateSuccessfully);
          } else {
            _subject.sink.add(ApiResponse.error(message));
          }
        } catch (e) {
          if (!state.mounted) return;
          openSimpleSnackbar(e.toString());
          _subject.sink.add(ApiResponse.error(e.toString()));
        }
      } else {
        if (!state.mounted) return;
        openSimpleSnackbar(languages.internetConnLostTitle);
      }
    }
  }

  deleteAccountApiCall() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _deleteAccountSubject.sink.add(ApiResponse.loading());
      try {
        var response =
            BaseModel.fromJson(await _editProfileRepo.deleteAccountApi());

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _deleteAccountSubject.sink.add(ApiResponse.completed(response));
          logout(context);
        } else {
          if (response.status != 3) openSimpleSnackbar(message);
          _deleteAccountSubject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _deleteAccountSubject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _deleteAccountSubject.sink
          .add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  addProfileImage() {
    selectImgFromCameraOrGallery(context, (file) async {
      File compressFile = await compressImage(file) ?? file;
      changeImgFile(compressFile);
    });
  }

  Future<File?> compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
    final compressedImage = await FlutterImageCompress.compressAndGetFile(
        filePath, outPath,
        quality: 85);
    if (compressedImage != null) {
      return File(compressedImage.path);
    } else {
      return null;
    }
  }

  buttonHide() {
    String fullName = fullNameValidate(fullNameTEC.text) ?? "";
    String email = validateEmailOrNumber(emailTEC.text);
    String mobile = mobileNumberValidate(mobileNoTEC.text) ?? "";

    if (fullName.isEmpty && email.isEmpty && mobile.isEmpty) {
      submitValid.add(true);
    } else {
      submitValid.add(false);
    }
  }

  openDeleteAccountDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleDialogUtil(
            title: languages.accountDelete,
            message: languages.accountDeleteMsg,
            positiveButtonTxt: languages.delete,
            negativeButtonTxt: languages.cancel,
            onPositivePress: () {
              Navigator.pop(context, true);
              deleteAccountApiCall();
            },
            onNegativePress: () {
              Navigator.pop(context, true);
            },
          );
        });
  }

  @override
  void dispose() {
    _profileImgController.close();
    fullNameTEC.dispose();
    emailTEC.dispose();
    _countryCodeController.close();
    mobileNoTEC.dispose();
    emergencyContactTEC.dispose();
    _subject.close();
    submitValid.close();
    _deleteAccountSubject.close();
    _imgFileController.close();
  }
}
