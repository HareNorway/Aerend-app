import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aerend_customer/screens/common/account/referral_term.dart';
import 'package:aerend_customer/screens/common/home/home_repo.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';

import '../../../utils/utils.dart';
import '../../dugnad/dugnad_models.dart';
import '../../dugnad/dugnad_repo.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import 'account_widgets.dart';
import 'settings_design_kit.dart';

/// «Vervekode» — mirrors design `settings-screens.jsx` `ReferralCodeScreen`
/// (`.tk-head` + `.dgr-hero` + `.dg-label`/`.dgr-code` + primary
/// "Del vervelenken" + `.dg-label`/`.dgr-redeem` + `.dg-label`/`.dgs-list`).
class ReferralCode extends StatefulWidget {
  const ReferralCode({super.key});

  @override
  State<ReferralCode> createState() => _ReferralCodeState();
}

class _ReferralCodeState extends State<ReferralCode> {
  bool isCopied = false;

  final TextEditingController _redeemController = TextEditingController();
  bool _redeeming = false;

  /// `.dgs-list` "Dine vervede" — read-only reuse of the existing referral
  /// summary endpoint. Failures return null and the section stays hidden.
  ReferralSummary? _summary;

  @override
  void initState() {
    super.initState();
    _redeemController.addListener(() => setState(() {}));
    _loadSummary();
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final clubId = prefGetInt(prefSelectedClubId);
    final summary = await DugnadRepo().getReferralSummary(
      organizationId: clubId > 0 ? clubId : null,
    );
    if (!mounted || summary == null) return;
    setState(() => _summary = summary);
  }

  String get _code => prefGetString(prefReferralCode);

  String get _clubShortName {
    final short = prefGetString(prefSelectedClubShortName).trim();
    if (short.isNotEmpty) return short;
    final name = prefGetString(prefSelectedClubName).trim();
    return name.isNotEmpty ? name : 'Ærend';
  }

  String get _inviteLink => 'https://reen.io/invite?code=$_code';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDgPageBackground,
      body: AeFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: languages.referralCode,
                onBack: () => openScreenWithResult(
                  context,
                  const HomeMainV1(homeIndex: 3),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AeRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: _hero(),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: _codeSection(),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 260),
                        child: DgPrimaryButton(
                          label: 'Del vervelenken', // TODO(l10n)
                          icon: Icons.ios_share_rounded,
                          onPressed: showInviteFriendModal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 330),
                        child: _redeemSection(),
                      ),
                      if (_recruits.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AeRiseIn(
                          delay: const Duration(milliseconds: 400),
                          child: _recruitSection(),
                        ),
                      ],
                      _howItWorksLink(),
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

  /// `.dgr-hero` — 52px icon circle, title, sub with the bold points figure.
  Widget _hero() {
    final points = _summary?.referralPoints ?? 100;
    return DgrHero(
      icon: Icons.ios_share_rounded,
      title: 'Verv venner til $_clubShortName', // TODO(l10n)
      subtitle: [
        const TextSpan(text: 'Du får '), // TODO(l10n)
        TextSpan(
          text: '$points poeng', // TODO(l10n)
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const TextSpan(
          // TODO(l10n)
          text: ' per venn som blir med — og klubben får en andel av alt de '
              'kjøper.',
        ),
      ],
    );
  }

  /// `.dg-label` "Din kode" + `.dgr-code` copy row.
  Widget _codeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DgLabel('Din kode'), // TODO(l10n)
        DgrCodeRow(
          code: _code.isEmpty ? '—' : _code,
          copyLabel: isCopied ? languages.referralCopied : 'Kopier', // TODO(l10n)
          onCopy: () {
            Clipboard.setData(ClipboardData(text: _code));
            setState(() => isCopied = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => isCopied = false);
            });
          },
        ),
      ],
    );
  }

  /// `.dg-label` "Har du fått en kode?" + `.dgr-redeem` input + Innløs button.
  Widget _redeemSection() {
    final value = _redeemController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DgLabel('Har du fått en kode?', top: 6), // TODO(l10n)
        DgRedeemRow(
          controller: _redeemController,
          hint: 'SKRIV INN KODE', // TODO(l10n)
          buttonLabel: 'Innløs', // TODO(l10n)
          onSubmit:
              (value.length < 4 || _redeeming) ? null : () => _redeem(value),
        ),
      ],
    );
  }

  /// Existing redeem API (`HomeRepo().checkingRedeemCode`) — same call the
  /// dedicated «Innløs kode» screen makes.
  Future<void> _redeem(String code) async {
    setState(() => _redeeming = true);
    try {
      final response = await HomeRepo().checkingRedeemCode(code);
      if (!mounted) return;
      openSimpleSnackbar(response['message']?.toString() ?? '');
      if (response['status'] == 1) {
        _redeemController.clear();
      } else if (response['status'] == 4) {
        logout(context);
      }
    } catch (e) {
      if (!mounted) return;
      openSimpleSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  List<ReferralRecord> get _recruits => _summary?.recentReferrals ?? const [];

  /// `.dg-label` "Dine vervede" + `.dgs-list` of `.row.tgl` with `.pts` pills.
  Widget _recruitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DgLabel('Dine vervede'), // TODO(l10n)
        DgsList(
          rows: _recruits.map((record) {
            final converted = record.status == 'converted';
            final waiting = !converted;
            return DgsInfoRow(
              title: record.referredDisplayName ??
                  languages.dugnadReferralPendingInvite,
              subtitle: converted
                  ? languages.dugnadReferralActive
                  : (record.referredIsVerified
                      ? languages.dugnadReferralWaitingFirstPurchase
                      : languages.dugnadReferralPending),
              trailing: DgsPointsPill(
                label: waiting
                    ? 'Venter' // TODO(l10n)
                    : '+${_summary?.referralPoints ?? 100}',
                waiting: waiting,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Existing «Slik fungerer det» link — kept from the previous screen.
  Widget _howItWorksLink() => DgCancelButton(
        label: languages.referralHowItWorks,
        onTap: () => openScreenWithResult(context, const ReferralTerm()),
      );

  /// Share sheet — `.dg-msheet` shell, copy-link field. Same link and clipboard
  /// behaviour as before.
  void showInviteFriendModal() {
    showAeSheet<void>(
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
              const AeSheetHandle(),
              AccountSheetHead(
                icon: Icons.ios_share_rounded,
                title: languages.inviteTitle,
                blurb: 'Del lenken — vennen din får koden ferdig utfylt.',
                // TODO(l10n)
              ),
              const SizedBox(height: 12),
              const DgLabel('Vervelenke'), // TODO(l10n)
              DgrCodeRow(
                code: _inviteLink,
                copyLabel: 'Kopier', // TODO(l10n)
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: _inviteLink));
                  Navigator.pop(sheetContext);
                  openSimpleSnackbar(languages.referralCopied);
                },
              ),
              const SizedBox(height: 16),
              DgInfoBox(
                icon: Icons.card_giftcard_rounded,
                text: languages.inviteCopyLink,
              ),
              AccountSheetCancelButton(
                label: languages.cancel,
                onTap: () {
                  aeSheetCloseHaptic();
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
