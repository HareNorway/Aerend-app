import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aerend_customer/screens/common/account/account_widgets.dart';
import 'package:aerend_customer/screens/common/editProfile/edit_profile_repo.dart';
import 'package:aerend_customer/screens/common/login/login_dl.dart';
import 'package:aerend_customer/screens/common/otpVerify/otp_verify.dart';
import 'package:aerend_customer/ui/kit/ae_sheet.dart';

import '../../../utils/utils.dart';

/// "Endre telefonnummer" — design bottom sheet (prototype: `EditFieldSheet`
/// in account.jsx, field `phone`, with the `.dga-phone` 🇳🇴 +47 prefix chip).
/// Keeps the original `EditPhoneNumber` save flow (profile API → OTP verify);
/// only the presentation changed from a full screen to a sheet.
///
/// Resolves with `true` when the number was submitted (OTP screen follows).
Future<bool?> showEditPhoneNumberSheet(BuildContext context) {
  final storedCode = prefGetString(prefCountryCode);
  final countryCode = storedCode.isEmpty ? '+47' : storedCode;

  return showAeSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => AccountEditFieldSheet(
      icon: Icons.phone_rounded,
      title: 'Endre telefonnummer', // TODO(l10n)
      blurb: 'Vi sender en engangskode til det nye nummeret.', // TODO(l10n)
      current: prefGetString(prefContactNumber).isEmpty
          ? null
          : '$countryCode ${prefGetString(prefContactNumber)}',
      label: 'Nytt nummer', // TODO(l10n)
      hint: '400 00 000', // TODO(l10n)
      saveLabel: 'Send kode', // TODO(l10n)
      cancelLabel: languages.cancel,
      phonePrefix: countryCode,
      initialValue: prefGetString(prefContactNumber),
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      isValid: (value) =>
          value.replaceAll(RegExp(r'\D'), '').length >= 8,
      onSave: (sheetContext, value) async {
        final response = LoginPojo.fromJson(
          await EditProfileRepo().editProfileApi(
            prefGetString(prefUserName),
            countryCode,
            value,
            prefGetString(prefEmail),
            prefGetString(prefEmergencyContact),
          ),
        );
        if (response.status == 1) {
          prefSetString(prefCountryCode, response.selectCountryCode);
          prefSetString(prefContactNumber, response.contactNumber);
          if (sheetContext.mounted) Navigator.pop(sheetContext, true);
          if (context.mounted) {
            openScreenWithResult(context, const OtpVerify());
          }
        }
      },
    ),
  );
}
