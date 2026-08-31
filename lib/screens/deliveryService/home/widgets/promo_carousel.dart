import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/sc_saas_theme.dart';

/// Ærend auto-rotating promo carousel with dot navigation.
///
/// Design spec: Home.jsx — warm-gradient cards, auto-rotate ~3.4s, dots.
/// Binds to [ServiceSliderData] from the existing home API.
/// If no data is provided, renders nothing (no placeholder).
class PromoCarousel extends StatefulWidget {
  final List<PromoSlide> slides;
  final ValueChanged<int>? onSlideTap;

  const PromoCarousel({
    super.key,
    required this.slides,
    this.onSlideTap,
  });

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.slides.length,
          options: CarouselOptions(
            height: 160,
            autoPlay: true,
            autoPlayInterval: const Duration(milliseconds: 3400),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            enlargeCenterPage: true,
            viewportFraction: 0.88,
            onPageChanged: (index, _) {
              setState(() => _current = index);
            },
          ),
          itemBuilder: (context, index, _) {
            final slide = widget.slides[index];
            return GestureDetector(
              onTap: () => widget.onSlideTap?.call(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18), // --ae-r-lg
                  gradient: _warmGradient(index),
                  boxShadow: ScSaasThemeTokens.shadowCard,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner image if available
                    if (slide.imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.network(
                            slide.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    // Text overlay
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (slide.eyebrow.isNotEmpty)
                            Text(
                              slide.eyebrow.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.08 * 10.5,
                                color: Colors.white70,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            slide.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.02 * 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.slides.length, (i) {
            final bool active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active
                    ? ScSaasThemeTokens.primary
                    : ScSaasThemeTokens.gray300,
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Warm gradient palette cycling through peach → amber → terracotta.
  LinearGradient _warmGradient(int index) {
    const palettes = [
      [Color(0xFFE8956D), Color(0xFFD4724A)], // peach
      [Color(0xFFD4A03C), Color(0xFFC07828)], // amber
      [Color(0xFF9B7FD4), Color(0xFF6B4FA8)], // purple
      [Color(0xFF5BAD8A), Color(0xFF22A769)], // green
    ];
    final colors = palettes[index % palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}

/// Simple data holder for a promo slide.
class PromoSlide {
  final String title;
  final String eyebrow;
  final String imageUrl;
  final int? storeId;

  const PromoSlide({
    required this.title,
    this.eyebrow = '',
    this.imageUrl = '',
    this.storeId,
  });
}
