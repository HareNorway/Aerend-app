import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/sc_saas_theme.dart';
import '../../../../commonView/surface_decorations.dart';
import '../../../../utils/utils.dart';

/// Ærend purple gradient hero header with location selector and search pill.
///
/// Design spec: Home.jsx — purple hero (170° gradient), location selector,
/// circular action buttons, shiny search pill.
class PurpleHero extends StatelessWidget {
  final String locationLabel;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;
  final VoidCallback? onNotificationTap;

  const PurpleHero({
    super.key,
    required this.locationLabel,
    required this.onLocationTap,
    required this.onSearchTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B4FA8), // Purple 700
            Color(0xFF7F5FC4), // Purple 600
            Color(0xFF9B7FD4), // Purple 500
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back (if pushed) + location + action buttons
              Row(
                children: [
                  // Back button — shown only when this screen can pop
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  // Location selector
                  Expanded(
                    child: GestureDetector(
                      onTap: onLocationTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languages.heroDeliveryTo,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.005 * 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notification button
                  if (onNotificationTap != null)
                    _circleButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: onNotificationTap!,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Shiny search pill
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  height: 48,
                  decoration: AeSurface.shiny(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: ScSaasThemeTokens.gray500, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          languages.heroSearchStoresProducts,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ),
                      const Icon(Icons.auto_awesome,
                          color: ScSaasThemeTokens.primary, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
