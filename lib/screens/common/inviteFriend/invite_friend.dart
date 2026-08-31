import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/utils.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../account/settings_design_kit.dart';
import 'invite_friend_bloc.dart';

/// «Inviter venn» — the share half of design `settings-screens.jsx`
/// `ReferralCodeScreen` (`.tk-head` + `.dgr-hero` + `.dg-label`/`.dgr-code`
/// + primary "Del vervelenken").
class InviteFriend extends StatefulWidget {
  const InviteFriend({super.key});

  @override
  State<StatefulWidget> createState() => _InviteFriendState();
}

class _InviteFriendState extends State<InviteFriend> {
  late InviteFriendBloc _bloc;
  bool isFirstClick = true;
  bool isCopied = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    _bloc = InviteFriendBloc(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _bloc.dispose();
    super.dispose();
  }

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
                title: languages.inviteFriend,
                onBack: () => Navigator.maybePop(context),
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
                          icon: Icons.ios_share_rounded,
                          title: languages.inviteFriendAnd,
                          subtitle: [
                            TextSpan(text: languages.inviteFriendMessage),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: _codeSection(),
                      ),
                      const SizedBox(height: 16),
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 260),
                        child: DgPrimaryButton(
                          label: languages.shareCode,
                          icon: Icons.ios_share_rounded,
                          onPressed: _share,
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

  /// `.dg-label` + `.dgr-code` — the referral code with a Kopier chip.
  Widget _codeSection() => StreamBuilder<String>(
        stream: _bloc.referralCode,
        initialData: prefGetString(prefReferralCode),
        builder: (context, snap) {
          final code = (snap.data ?? '').trim();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DgLabel(languages.referralCode),
              DgrCodeRow(
                code: code.isEmpty ? '—' : code,
                copyLabel:
                    isCopied ? languages.referralCopied : 'Kopier', // TODO(l10n)
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: code));
                  setState(() => isCopied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => isCopied = false);
                  });
                },
              ),
            ],
          );
        },
      );

  /// Existing debounced share — unchanged behaviour.
  void _share() {
    if (!isFirstClick) return;
    setState(() => isFirstClick = false);
    _bloc.shareReferralCode();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => isFirstClick = true);
    });
  }
}
