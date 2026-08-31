import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import '../../../utils/utils.dart';
import '../../../commonView/icon_surface.dart';

class ReferralTerm extends StatefulWidget {
  const ReferralTerm({super.key});

  @override
  State<ReferralTerm> createState() => _ReferralTermState();
}

class _ReferralTermState extends State<ReferralTerm> {
  bool isCopied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final bodyColor = theme.colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white70 : ScSaasThemeTokens.muted;
    final accentColor = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        foregroundColor: titleColor,
        toolbarHeight: 80,
        elevation: 0,
        title: Stack(
          children: [
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'How it Works',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 5,
              child: BackIconSurface(
                onPressed: () => Navigator.pop(context),
                icon: SvgPicture.asset(
                  'assets/svgs/icons/back.svg',
                  height: 18,
                  width: 18,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(deviceAverageSize * 0.0),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.only(bottom: deviceHeight * 0.02),
          children: [
            Text(
              'Share your referral code',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your friends receive NOK 75 in Ærend credits for each of their first 3 deliveries when they use your referral code when registering on Ærend.',
              style: TextStyle(fontSize: 15, color: mutedColor, height: 1.1),
            ),
            Divider(height: 35, color: theme.dividerColor),
            Text(
              'Get Credit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'You receive NOK 75 in Ærend credits each time a friend has completed one of his first 3 deliveries. You can earn up to NOK 750 Ærend credits by recruiting your friends.',
              style: TextStyle(fontSize: 15, color: mutedColor, height: 1),
            ),
            Divider(height: 25, color: theme.dividerColor),
            Text(
              'Take a Note',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Remember that your credit expires after 30 days. We\'ll let you know because it happens! Join in and spread the joy!',
              style: TextStyle(fontSize: 15, color: mutedColor, height: 1),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {},
              child: Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
