import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/account/account_widgets.dart';
import 'package:aerend_customer/screens/common/editProfile/edit_profile_repo.dart';
import 'package:aerend_customer/screens/common/login/login_dl.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_sheet.dart';

import '../../../utils/utils.dart';

/// "Endre navn" — design bottom sheet (prototype: `EditFieldSheet` in
/// account.jsx, field `name`). Keeps the original `EditUserName` save logic;
/// only the presentation changed from a full screen to a sheet.
///
/// Resolves with `true` when the name was saved.
Future<bool?> showEditUserNameSheet(BuildContext context) {
  return showDugnadSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => AccountEditFieldSheet(
      icon: Icons.person_outline_rounded,
      title: 'Endre navn', // TODO(l10n)
      blurb: 'Navnet vises på tabellene og i ordrene dine.', // TODO(l10n)
      current: prefGetString(prefUserName),
      label: languages.editNameNewLabel,
      hint: 'Ditt fulle navn', // TODO(l10n)
      saveLabel: 'Lagre endringer', // TODO(l10n)
      cancelLabel: languages.cancel,
      keyboardType: TextInputType.name,
      isValid: (value) => value.trim().length > 1,
      onSave: (sheetContext, value) async {
        final response = LoginPojo.fromJson(
          await EditProfileRepo().editProfileApi(
            value,
            prefGetString(prefCountryCode),
            prefGetString(prefContactNumber),
            prefGetString(prefEmail),
            prefGetString(prefEmergencyContact),
          ),
        );
        if (response.status == 1) {
          prefSetString(prefUserName, response.userName);
          if (sheetContext.mounted) Navigator.pop(sheetContext, true);
        } else {
          openSimpleSnackbar(response.message);
        }
      },
    ),
  );
}
