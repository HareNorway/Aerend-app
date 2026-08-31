import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/image_selection.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../auth/auth_style.dart';
import '../editProfile/edit_profile_repo.dart';
import '../login/login_dl.dart';
import 'account_widgets.dart';

/// "Oppdater profilbilde" — club-themed when in dugnad mode.
class EditProfilePicture extends StatefulWidget {
  const EditProfilePicture({super.key});

  @override
  State<EditProfilePicture> createState() => _EditProfilePictureState();
}

class _EditProfilePictureState extends State<EditProfilePicture> {
  File? _selectedFile;
  bool _isSaving = false;
  double _progress = 0;

  TextStyle _flabel(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 12 * 0.06,
        color: color,
      );

  BoxDecoration _card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScSaasThemeTokens.shadowCard,
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AccountTkHead(
              title: 'Oppdater profilbilde', // TODO(l10n)
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                children: [
                  DugnadRiseIn(
                    delay: const Duration(milliseconds: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            languages.editPicCurrent.toUpperCase(),
                            style: _flabel(ScSaasThemeTokens.gray500),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: _card(),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LoadImageWithPlaceHolder(
                                image: prefGetString(prefProfileImage).trim(),
                                width: 140,
                                height: 140,
                                defaultAssetImage:
                                    'assets/images/avatar_user.png',
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DugnadRiseIn(
                    delay: const Duration(milliseconds: 190),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            languages.editPicNew.toUpperCase(),
                            style: _flabel(ScSaasThemeTokens.gray500),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: _card(),
                          child: Column(
                            children: [
                              if (_selectedFile != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    _selectedFile!,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              _chooseImageButton(theme),
                              if (_progress > 0 && _progress < 1) ...[
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 6,
                                    backgroundColor: theme.primaryTint,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: AuthPrimaryButton(
            label: 'Oppdater bilde', // TODO(l10n)
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _updateProfileImage,
          ),
        ),
      ),
    );
  }

  Widget _chooseImageButton(DugnadClubThemePalette theme) {
    final disabled = _isSaving;
    return AuthPressable(
      onTap: disabled
          ? null
          : () {
              selectImgFromCameraOrGallery(context, (file) async {
                final compressed = await _compressImage(file) ?? file;
                if (!mounted) return;
                setState(() {
                  _selectedFile = compressed;
                });
              });
            },
      builder: (context, pressed) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: theme.primaryTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_rounded,
              size: 17,
              color: theme.primaryHover,
            ),
            const SizedBox(width: 8),
            Text(
              'Velg bilde', // TODO(l10n)
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 14 * -0.01,
                color: theme.primaryHover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    if (lastIndex == -1) return file;
    final outPath = "${filePath.substring(0, lastIndex)}_small${filePath.substring(lastIndex)}";
    final compressed = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: 85,
    );
    if (compressed == null) return file;
    return File(compressed.path);
  }

  Future<void> _updateProfileImage() async {
    if (_selectedFile == null) {
      openSimpleSnackbar(languages.editPicSelectFirst);
      return;
    }
    setState(() {
      _isSaving = true;
      _progress = 0;
    });
    try {
      final multipart = await MultipartFile.fromFile(_selectedFile!.path,
          filename: _selectedFile!.path.split('/').last);
      final response = LoginPojo.fromJson(await EditProfileRepo().editProfileApi(
          prefGetString(prefUserName),
          prefGetString(prefCountryCode),
          prefGetString(prefContactNumber),
          prefGetString(prefEmail),
          prefGetString(prefEmergencyContact),
          multipartFile: multipart,
          progress: (double value) {
            if (mounted) {
              setState(() {
                _progress = value;
              });
            }
          }));
      if (!mounted) return;
      if (response.status == 1) {
        prefSetString(prefUserName, response.userName);
        prefSetString(prefProfileImage, response.profileImage);
        prefSetString(prefCountryCode, response.selectCountryCode);
        prefSetString(prefContactNumber, response.contactNumber);
        prefSetString(prefEmail, response.email);
        prefSetString(prefEmergencyContact, response.emergencyContact);
        openSimpleSnackbar(languages.profileUpdateSuccessfully);
        Navigator.pop(context, true);
      } else {
        openSimpleSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      openSimpleSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
