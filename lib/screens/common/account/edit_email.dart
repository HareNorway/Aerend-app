import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/account/account_widgets.dart';
import 'package:aerend_customer/screens/common/editProfile/edit_profile_repo.dart';
import 'package:aerend_customer/screens/common/login/login_dl.dart';
import 'package:aerend_customer/ui/kit/ae_sheet.dart';

import '../../../utils/utils.dart';

final RegExp _emailPattern = RegExp(r'.+@.+\..+');

/// "Endre e-post" — design bottom sheet (prototype: `EditFieldSheet` in
/// account.jsx, field `email`). Keeps the original `EditEmail` save logic;
/// only the presentation changed from a full screen to a sheet.
///
/// Resolves with `true` when the e-mail was saved.
Future<bool?> showEditEmailSheet(BuildContext context) {
  return showAeSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => AccountEditFieldSheet(
      icon: Icons.send_rounded,
      title: languages.editEmailTitle,
      blurb: 'Vi sender ordrebekreftelser hit.', // TODO(l10n)
      current: prefGetString(prefEmail),
      label: languages.editEmailNewLabel,
      hint: 'deg@eksempel.no', // TODO(l10n)
      saveLabel: 'Lagre endringer', // TODO(l10n)
      cancelLabel: languages.cancel,
      keyboardType: TextInputType.emailAddress,
      isValid: (value) => _emailPattern.hasMatch(value.trim()),
      onSave: (sheetContext, value) async {
        final response = LoginPojo.fromJson(
          await EditProfileRepo().editProfileApi(
            prefGetString(prefUserName),
            prefGetString(prefCountryCode),
            prefGetString(prefContactNumber),
            value,
            prefGetString(prefEmergencyContact),
          ),
        );
        if (response.status == 1) {
          prefSetString(prefEmail, response.email);
          if (sheetContext.mounted) Navigator.pop(sheetContext, true);
        } else {
          openSimpleSnackbar(response.message);
        }
      },
    ),
  );
}
