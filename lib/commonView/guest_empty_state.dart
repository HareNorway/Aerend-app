import 'package:flutter/material.dart';
import 'package:aerend_customer/main.dart';
import 'package:aerend_customer/screens/common/login/login.dart';
import 'package:aerend_customer/screens/common/signUp/sign_up.dart';
import 'package:aerend_customer/screens/snurre/snurre_launcher_policy.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

/// Empty state with sign-in / create-account CTAs for guest users.
class GuestEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final String? imageAsset;

  const GuestEmptyState({
    super.key,
    required this.title,
    this.message,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null) ...[
              Image.asset(imageAsset!, width: 160, fit: BoxFit.contain),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(
                        name: snurreLauncherRouteNameFor(const Login()),
                      ),
                      builder: (_) => const Login(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScSaasThemeTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  languages.signIn,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(
                        name: snurreLauncherRouteNameFor(const SignUp()),
                      ),
                      builder: (_) => const SignUp(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScSaasThemeTokens.primary,
                  side: const BorderSide(color: ScSaasThemeTokens.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  languages.createAccount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
