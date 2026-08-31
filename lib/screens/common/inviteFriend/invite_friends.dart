import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/screens/common/account/terms_statement.dart';

import '../../../utils/utils.dart';
import '../../dugnad/dugnad_sheet.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../account/settings_design_kit.dart';

/// «Inviter venner» — design `settings-screens.jsx` `ReferralCodeScreen`
/// language: `.tk-head` + `.dgr-hero` + primary CTA + `.dga-cancel` terms link.
class InviteFriends extends StatefulWidget {
  const InviteFriends({super.key});

  @override
  State<InviteFriends> createState() => _InviteFriendsState();
}

class _InviteFriendsState extends State<InviteFriends> {
  static const String _inviteLink = 'https://reen.io/invite/';

  static const List<(String, String)> _channels = [
    ('assets/svgs/icons/x.svg', 'X'),
    ('assets/svgs/icons/instagram.svg', 'Instagram'),
    ('assets/svgs/icons/telegram.svg', 'Telegram'),
    ('assets/svgs/icons/whatsapp.svg', 'Whatsapp'),
    ('assets/svgs/icons/facebook.svg', 'Facebook'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDgPageBackground,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: languages.inviteTitle,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: DgrHero(
                          icon: Icons.card_giftcard_rounded,
                          title: languages.inviteHeading,
                          subtitle: [
                            TextSpan(text: languages.inviteDescription),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: DgPrimaryButton(
                          label: languages.inviteButton,
                          icon: Icons.ios_share_rounded,
                          onPressed: showInviteFriendModal,
                        ),
                      ),
                      DgCancelButton(
                        label: languages.inviteTerms,
                        onTap: () => openScreenWithResult(
                          context,
                          const TermsOfService(),
                        ),
                      ),
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

  /// Share sheet — `.dg-msheet` shell with the channel row and copy-link field.
  void showInviteFriendModal() {
    showDugnadSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 22 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DugnadSheetHandle(),
              AccountSheetHead(
                icon: Icons.ios_share_rounded,
                title: languages.inviteTitle,
                // TODO(l10n)
                blurb: 'Del lenken der vennene dine allerede er.',
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (asset, label) in _channels)
                      Padding(
                        padding: const EdgeInsets.only(right: 22),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 35,
                              height: 35,
                              child: SvgPicture.asset(asset),
                            ),
                            const SizedBox(height: 8),
                            Text(label, style: dgText(11.5, FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const DgLabel('Kopier lenken'), // TODO(l10n)
              DgrCodeRow(
                code: _inviteLink,
                copyLabel: 'Kopier', // TODO(l10n)
                onCopy: () {
                  Clipboard.setData(
                    const ClipboardData(text: _inviteLink),
                  );
                  Navigator.pop(sheetContext);
                  openSimpleSnackbar(languages.referralCopied);
                },
              ),
              AccountSheetCancelButton(
                label: languages.cancel,
                onTap: () {
                  dugnadSheetCloseHaptic();
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
