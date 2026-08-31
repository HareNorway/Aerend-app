import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../commonView/customCountryCodePicker/custom_country_code_picker.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../auth/auth_style.dart';
import '../login/login_dl.dart';
import 'create_profile_bloc.dart';

/// Your Profile / register phone — AuthScaffold layout matching ConsumerLogin
/// field + primary CTA styling (`auth_style.dart` / Login.jsx tokens).
class CreateProfile extends StatefulWidget {
  final bool returnOnSuccess;

  const CreateProfile({super.key, this.returnOnSuccess = false});

  @override
  CreateProfileState createState() => CreateProfileState();
}

class CreateProfileState extends State<CreateProfile> {
  CreateProfileBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc ??= CreateProfileBloc(context, this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc?.buttonHide();
    });
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  Widget _rise(Widget child, int ms) {
    return AeRiseIn(
      delay: Duration(milliseconds: ms),
      offsetY: 16,
      child: child,
    );
  }

  // `SignUpScreen` (dugnad/auth-screens.jsx) — fixed px on the 375×812 frame.
  // Note this screen has **no** `.dg-auth-bottom`: the primary CTA flows
  // inline after the terms row with `margin-top: 18`, it is not pinned.
  static const double _backMarginTop = 6; // .ae-back inline margin-top
  static const double _headMarginTop = 10; // .dg-auth-head margin-top
  static const double _titleMarginBottom = 8; // h1 margin-bottom
  static const double _headMarginBottom = 22; // .dg-auth-head margin-bottom
  static const double _fieldGap = 12; // .ae-field inline margin-top
  static const double _ackMarginTop = 16; // .dga-ack inline margin-top
  static const double _ctaMarginTop = 18; // .ae-btn inline margin-top

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      // `.dg-auth` inline override: padding "0 26px 30px"
      padding: EdgeInsets.fromLTRB(
        context.dp(26),
        0,
        context.dp(26),
        context.dp(30),
      ),
      child: Form(
        key: _bloc!.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: context.dp(_backMarginTop)),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: AuthBackButton(),
            ),
            SizedBox(height: context.dp(_headMarginTop)),
            _rise(
              Text(
                languages.profileYourProfile,
                textAlign: TextAlign.center,
                style: authTitleStyle(context),
              ),
              120,
            ),
            SizedBox(height: context.dp(_titleMarginBottom)),
            _rise(
              Center(
                child: ConstrainedBox(
                  // .dg-auth-head p { max-width: 30ch } ≈ 268px at 14px
                  constraints: BoxConstraints(maxWidth: context.dp(268)),
                  child: Text(
                    kAoProfileSubtitle,
                    textAlign: TextAlign.center,
                    style: authSubtitleStyle(context),
                  ),
                ),
              ),
              190,
            ),
            SizedBox(height: context.dp(_headMarginBottom)),
            _rise(
              AuthField(
                label: '${languages.fullName}*',
                hint: languages.profileEnterFullName,
                controller: _bloc!.fullNameController,
                validator: (value) => fullNameValidate(value),
                onValidate: _bloc!.buttonHide,
              ),
              260,
            ),
            SizedBox(height: context.dp(_fieldGap)),
            _rise(
              AuthField(
                label: '${languages.emailAddress}*',
                hint: languages.profileEnterEmail,
                controller: _bloc!.emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmailOrNumber,
                onValidate: _bloc!.buttonHide,
              ),
              330,
            ),
            SizedBox(height: context.dp(_fieldGap)),
            _rise(_buildMobileField(context), 390),
            SizedBox(height: context.dp(_ackMarginTop)),
            _rise(_buildTerms(context), 440),
            SizedBox(height: context.dp(_ctaMarginTop)),
            _buildSubmit(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileField(BuildContext context) {
    return StreamBuilder<CountryCode>(
      stream: _bloc!.countryCodeStream,
      initialData: _bloc!.selectedCountryCode,
      builder: (context, countrySnap) {
        final CountryCode selected =
            countrySnap.data ?? _bloc!.selectedCountryCode;
        final dial = selected.dialCode ?? defaultCountryCode.dialCode ?? '+47';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${languages.mobileNumber}*',
              style: authLabelStyle(context),
            ),
            SizedBox(height: context.dp(8)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `.dga-phone .cc { border-radius: 13px; padding: 13px;
                // font-size: 15px; font-weight: 800 }`
                Container(
                  padding: EdgeInsets.all(context.dp(13)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F4),
                    borderRadius: BorderRadius.circular(context.dp(13)),
                  ),
                  alignment: Alignment.center,
                  child: CustomCountryCodePicker(
                    showDropDownButton: true,
                    flagWidth: context.dp(22),
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontSize: context.dp(15),
                      fontWeight: FontWeight.w800,
                      color: ScSaasThemeTokens.text,
                    ),
                    onChanged: (countryCode) {
                      _bloc!.onCountryCodeChanged(countryCode);
                      _bloc!.formKey.currentState?.validate();
                    },
                    onInit: (countryCode) {
                      if (countryCode != null) {
                        _bloc!.onCountryCodeChanged(countryCode);
                      }
                    },
                    initialSelection: dial,
                  ),
                ),
                SizedBox(width: context.dp(9)),
                Expanded(
                  child: AuthField(
                    label: '',
                    hint: languages.enterMobileNumber,
                    controller: _bloc!.mobileController,
                    keyboardType: TextInputType.phone,
                    onValidate: _bloc!.buttonHide,
                    validator: (value) {
                      _bloc!.buttonHide();
                      return validateSignupMobileNumber(
                        value,
                        dialCode: selected.dialCode,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTerms(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _bloc?.acceptTermsStream,
      builder: (context, snap) {
        return AuthCheckRow(
          checked: snap.data ?? false,
          onChanged: (value) {
            _bloc?.changeTerms(value);
            _bloc?.buttonHide();
          },
          label: TextSpan(
            text: languages.signUpText,
            children: [
              TextSpan(
                text: ' ${languages.termAndConditionUse}',
                style: const TextStyle(
                  color: ScSaasThemeTokens.primaryHover,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    openUrl(
                      BaseUrl.domain + ApiConst.endPointTermsAndConditions,
                    );
                  },
              ),
              TextSpan(text: ' ${languages.ofUse}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmit(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _bloc!.submitValid,
      builder: (context, snapshot) {
        final bool isEnable = snapshot.data ?? false;
        return StreamBuilder<bool>(
          stream: _bloc!.submitting,
          builder: (context, submittingSnap) {
            final bool isLoading = submittingSnap.data ?? false;
            return StreamBuilder<ApiResponse<LoginPojo>>(
              stream: _bloc!.subject,
              builder: (context, snapLoading) {
                final String? errorMessage = snapLoading.hasData &&
                        snapLoading.data?.status == Status.error
                    ? snapLoading.data?.message
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null && errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.dp(10)),
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ScSaasThemeTokens.danger,
                            fontSize: context.dp(13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    AuthPrimaryButton(
                      label: languages.next,
                      isLoading: isLoading,
                      onPressed: (isLoading || !isEnable)
                          ? null
                          : _bloc!.submit,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

const String kAoProfileSubtitle =
    'Fyll inn detaljene dine for å fullføre registreringen.'; // TODO(l10n)
