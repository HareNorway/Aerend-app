import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../networking/api_constant.dart';
import '../screens/common/auth/auth_style.dart';
import '../screens/common/login/vipps_login_helper.dart';
import '../utils/utils.dart';

class SocialLogin extends StatelessWidget {
  final Function({
    required String loginType,
    required String name,
    required String email,
    required String id,
  }) function;

  final Function({required String error})? errorFunction;
  final VoidCallback? onVippsTap;
  final bool showVipps;
  final double spacing;

  const SocialLogin({
    super.key,
    required this.function,
    this.errorFunction,
    this.onVippsTap,
    this.showVipps = AppFeatureFlags.showVippsLogin,
    this.spacing = 14,
    this.wrapButton,
  });

  /// Lets the host stagger each button separately — the design gives Google
  /// and Apple their own `au-rise` delays.
  final Widget Function(Widget child, int index)? wrapButton;

  Widget _wrap(Widget child, int index) =>
      wrapButton == null ? child : wrapButton!(child, index);

  @override
  Widget build(BuildContext context) {
    var index = 0;
    return Column(
      children: [
        if (showVipps) ...[
          _wrap(
            AuthSocialButton(
              type: AuthSocialButtonType.vipps,
              label: 'Vipps',
              onTap: onVippsTap ??
                  () {
                    VippsLoginHelper.signInWithVipps(
                      context,
                      onSuccess: (response) async {
                        if (!context.mounted) return;
                        await manageLoginResponse(context, response);
                      },
                      onError: (message) => openSimpleSnackbar(message),
                    );
                  },
            ),
            index++,
          ),
          SizedBox(height: spacing),
        ],
        _wrap(
          AuthSocialButton(
            type: AuthSocialButtonType.google,
            label: languages.signInWithGoogle,
            onTap: _signInWithGoogle,
          ),
          index++,
        ),
        if (Platform.isIOS)
          Padding(
            padding: EdgeInsets.only(top: spacing),
            child: _wrap(
              AuthSocialButton(
                type: AuthSocialButtonType.apple,
                label: languages.signInWithApple,
                onTap: _signInWithApple,
              ),
              index++,
            ),
          ),
      ],
    );
  }

  Future<void> _signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    var id = credential.userIdentifier ?? "";
    var email = credential.email ?? "";

    String givenName = credential.givenName ?? "";
    String familyName = credential.familyName ?? "";
    String fullName = "$givenName $familyName";
    if (givenName.trim().isEmpty && familyName.trim().isEmpty) {
      fullName = "N/A";
    }

    function.call(
      loginType: loginTypeApple,
      name: fullName,
      email: email,
      id: id,
    );
  }

  Future<void> _signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
    try {
      bool isSignedIn = await googleSignIn.isSignedIn();
      if (isSignedIn) {
        await googleSignIn.signOut();
      }
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        var id = googleSignInAccount.id;
        var email = googleSignInAccount.email;
        var name = googleSignInAccount.displayName ?? "-";

        function.call(
            loginType: loginTypeGoogle, name: name, email: email, id: id);
      }
    } catch (error) {
      debugPrint("_signInWithGoogle $error");
    }
  }

}
