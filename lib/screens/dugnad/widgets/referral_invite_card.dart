import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_club_crest.dart';

/// `.reg-invite` / `.reg-applied` — club invite card under login referral tabs.
///
/// Pre-club Reen glass + coral border (Design `.reen-pre .reg-invite`).
class ReferralInviteCard extends StatelessWidget {
  final String clubName;
  final String? clubLogoUrl;
  final String recruitedBy;
  final VoidCallback? onClear;

  const ReferralInviteCard({
    super.key,
    required this.clubName,
    required this.clubLogoUrl,
    required this.recruitedBy,
    this.onClear,
  });

  static String stripCheckGlyph(String s) =>
      s.replaceAll(RegExp(r'\s*✓\s*$'), '');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.dp(16)),
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(15),
        vertical: context.dp(13),
      ),
      decoration: BoxDecoration(
        color: const Color(0x1AE86657), // rgba(232,102,87,.10)
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(
          color: const Color(0x57E86657), // rgba(232,102,87,.34)
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AeClubCrest(
            name: clubName,
            logoUrl: clubLogoUrl,
            size: context.dp(44),
            backgroundColor: Colors.white,
          ),
          SizedBox(width: context.dp(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadReferralInvitedToClub(clubName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.dp(14.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: context.dp(14.5) * -0.01,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: context.dp(4)),
                Row(
                  children: [
                    Container(
                      width: context.dp(17),
                      height: context.dp(17),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: ReenPreClubTokens.coral,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: context.dp(11),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: context.dp(6)),
                    Expanded(
                      child: Text(
                        stripCheckGlyph(
                          languages.dugnadReferralInvitedBy(recruitedBy),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.dp(12.5),
                          fontWeight: FontWeight.w700,
                          color: ReenPreClubTokens.textSubtitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onClear != null) ...[
            SizedBox(width: context.dp(8)),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(context.dp(2)),
                child: Icon(
                  Icons.close_rounded,
                  size: context.dp(16),
                  color: ReenPreClubTokens.textSoft,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
