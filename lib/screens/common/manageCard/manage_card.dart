import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../dialogs/simple_dialog_util.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../auth/auth_style.dart';
import '../base_dl.dart';
import 'manage_card_bloc.dart';
import 'manage_card_dl.dart';
import 'manage_card_shimmer.dart';

// `.dgp-card` border (--ae-gray-200) and `.dn-addteam` dashed border
// (--ae-purple-200) from dugnad.css.
const Color _cardBorder = Color(0xFFE2DDF0);
const Color _dashedBorder = Color(0xFFD9CEF0);

class ManageCard extends StatefulWidget {
  const ManageCard({super.key});

  @override
  State<StatefulWidget> createState() => _ManageCardState();
}

class _ManageCardState extends State<ManageCard> {
  late ManageCardBloc _bloc;

  @override
  void didChangeDependencies() {
    _bloc = ManageCardBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: ScSaasThemeTokens.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 120),
                      child: Padding(
                        // .dg-label margin override: 2px 2px 0 + body gap 12
                        padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
                        child: Text(
                          'BETALINGSMÅTER', // TODO(l10n)
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 11 * 0.08,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ),
                    ),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 190),
                      child: _vippsCard(),
                    ),
                    const SizedBox(height: 12),
                    _cardList(),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 260),
                      child: _addCardRow(),
                    ),
                    const SizedBox(height: 16),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 330),
                      child: _infoBox(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.tk-head` — back, centred h1, 38px spacer.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 8,
        22,
        14,
      ),
      child: Row(
        children: [
          DugnadLbBackButton(onPressed: () => Navigator.maybePop(context)),
          Expanded(
            child: Text(
              'Betaling', // TODO(l10n)
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 20 * -0.015,
                color: ScSaasThemeTokens.text,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  /// `.dgp-card.vipps` — Vipps first, "Standard" pill.
  Widget _vippsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScSaasThemeTokens.primary, width: 1.5),
      ),
      child: Row(
        children: [
          // .dgp-card.vipps .lg: 46×32, radius 8, white, 22px mark
          Container(
            width: 46,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/vipps_mark.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'V',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF5B24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // .dgp-card .nm: 15/800 midnight
                    Text(
                      'Vipps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ScSaasThemeTokens.text,
                      ),
                    ),
                    const SizedBox(width: 7),
                    // .dgp-card .nm .def: 10/800 uppercase pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'STANDARD', // TODO(l10n)
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10 * 0.05,
                          color: ScSaasThemeTokens.primaryHover,
                        ),
                      ),
                    ),
                  ],
                ),
                // .dgp-card .s: 12.5/700 gray-500, padding-top 2
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Betal med Vipps', // TODO(l10n)
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Saved cards from the existing bloc stream.
  Widget _cardList() {
    return StreamBuilder<ApiResponse<CardModel>>(
      stream: _bloc.subject,
      builder: (context, snap) {
        var isLoading = snap.hasData && snap.data?.status == Status.loading;
        var isError = snap.hasData && snap.data?.status == Status.error;
        List<CardListItem> cardList = snap.data?.data?.cardList ?? [];

        if (isLoading) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ManageCardShimmer(enabled: isLoading),
          );
        }
        if (isError || cardList.isEmpty) {
          // No saved cards — the design simply shows no rows here.
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final card in cardList)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _savedCard(card),
              ),
          ],
        );
      },
    );
  }

  /// `.oh-wrap`: `.dgp-card` + `.oh-acts` remove action.
  Widget _savedCard(CardListItem card) {
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final isVisa = digits.startsWith('4');
    final last4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              // .dgp-card .lg: 46×32, radius 8, midnight, brand text
              Container(
                width: 46,
                height: 32,
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.text,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isVisa ? 'VISA' : 'MC',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 11 * 0.04,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVisa ? 'Visa' : 'Mastercard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ScSaasThemeTokens.text,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '•••• $last4 · ${card.cardHolderName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ScSaasThemeTokens.gray500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // .oh-acts: padding 0 2px 4px, margin-top -2 → 6px effective gap
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
          child: Row(
            children: [
              AuthPressable(
                onTap: () => _confirmRemove(card),
                builder: (context, pressed) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: ScSaasThemeTokens.danger.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 13,
                        color: ScSaasThemeTokens.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Fjern kort', // TODO(l10n)
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: ScSaasThemeTokens.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmRemove(CardListItem card) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StreamBuilder<ApiResponse<BaseModel>>(
          stream: _bloc.subjectDeleteCard,
          builder: (context, snapLoading) {
            var isLoading = snapLoading.hasData &&
                snapLoading.data?.status == Status.loading;
            return SimpleDialogUtil(
              isLoading: isLoading,
              title: languages.remove,
              message: languages.sureToRemove,
              positiveButtonTxt: languages.remove,
              negativeButtonTxt: languages.cancel,
              onPositivePress: () {
                _bloc.deleteCard(card.cardId);
              },
              onNegativePress: () {
                Navigator.pop(context, true);
              },
            );
          },
        );
      },
    );
  }

  /// `.dn-addteam` — dashed "Legg til kort" row.
  Widget _addCardRow() {
    return AuthPressable(
      onTap: () => _bloc.openAddCard(),
      builder: (context, pressed) => CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: pressed ? ScSaasThemeTokens.primary : _dashedBorder,
          strokeWidth: 1.5,
          radius: 16,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              // .dn-addteam: 0 2px 4px rgba(45,27,91,.04)
              BoxShadow(
                color: Color(0x0A2D1B5B),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // .dn-addteam .ic: 42px, radius 12, purple-100 bg
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 19,
                  color: ScSaasThemeTokens.primaryHover,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // .dn-addteam .t: 14.5/800/-0.01em
                    Text(
                      languages.addCard,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 14.5 * -0.01,
                        color: ScSaasThemeTokens.text,
                      ),
                    ),
                    // .dn-addteam .s: 11.5/600 gray-500, margin-top 2
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Visa eller Mastercard', // TODO(l10n)
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // .dn-addteam .go: gray-300 chevron
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: ScSaasThemeTokens.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.dg-info` — encrypted storage note.
  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.primaryTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: ScSaasThemeTokens.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              // TODO(l10n)
              'Kortdetaljer lagres kryptert hos betalingsleverandøren — aldri hos Reen Dugnad.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: ScSaasThemeTokens.primaryHover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1.5px dashed rounded border (`border: 1.5px dashed var(--ae-purple-200)`)
/// — Flutter has no dashed BorderSide, so it is painted manually.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashLength = 5.0;
    const gapLength = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
