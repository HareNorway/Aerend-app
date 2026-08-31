import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';

import '../../../utils/utils.dart';
import '../../../ui/kit/ae_club_crest.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_models.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';
import '../../../ui/kit/ae_theme.dart';

/// Shows localized "Vervet av X ✓" after account creation when the user was referred.
///
/// When [summary] is provided by a parent that already fetched referral data,
/// the banner renders without an extra network call.
class IncomingReferralBanner extends StatefulWidget {
  const IncomingReferralBanner({super.key, this.summary});

  final ReferralSummary? summary;

  @override
  State<IncomingReferralBanner> createState() => _IncomingReferralBannerState();
}

class _IncomingReferralBannerState extends State<IncomingReferralBanner> {
  final DugnadRepo _repo = DugnadRepo();
  ReferralRecord? _incoming;
  String? _organizationLogo;
  String? _organizationName;
  bool _loading = true;
  bool _dismissed = false;

  bool get _usesExternalSummary => widget.summary != null;

  bool _isDismissed(ReferralRecord? incoming) {
    if (incoming == null || incoming.id <= 0) return false;
    return prefGetString(prefDugnadIncomingReferralDismissedId) ==
        incoming.id.toString();
  }

  Future<void> _dismiss() async {
    final id = _incoming?.id;
    if (id == null || id <= 0) return;
    HapticFeedback.lightImpact();
    await prefSetString(prefDugnadIncomingReferralDismissedId, id.toString());
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  void initState() {
    super.initState();
    if (_usesExternalSummary) {
      _applySummary(widget.summary);
    } else {
      _load();
      DugnadState.instance.revision.addListener(_loadSilent);
    }
  }

  @override
  void didUpdateWidget(covariant IncomingReferralBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.summary != oldWidget.summary && _usesExternalSummary) {
      _applySummary(widget.summary);
    }
  }

  @override
  void dispose() {
    if (!_usesExternalSummary) {
      DugnadState.instance.revision.removeListener(_loadSilent);
    }
    super.dispose();
  }

  void _loadSilent() {
    if (mounted) _load();
  }

  void _applySummary(ReferralSummary? summary) {
    final incoming = summary?.incomingReferral;
    setState(() {
      _incoming = incoming;
      _organizationLogo = summary?.organizationLogo;
      _organizationName = summary?.organizationName;
      _loading = false;
      _dismissed = _isDismissed(incoming);
    });
  }

  Future<void> _load() async {
    if (!isLoggedIn() || !DugnadState.instance.hasClub) {
      if (mounted) {
        setState(() {
          _incoming = null;
          _loading = false;
        });
      }
      return;
    }

    final summary = await _repo.getReferralSummary(
      organizationId: DugnadState.instance.clubId,
    );
    if (!mounted) return;

    _applySummary(summary);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _incoming == null || _dismissed) {
      return const SizedBox.shrink();
    }

    final referrerName = _incoming!.referrerDisplayName?.trim();
    if (referrerName == null || referrerName.isEmpty) {
      return const SizedBox.shrink();
    }

    final clubName = (_organizationName?.trim().isNotEmpty == true
            ? _organizationName!.trim()
            : _incoming!.organizationName?.trim())
        ?? DugnadClubBranding.compactName();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.dp(16)),
      padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE3F7),
        borderRadius: BorderRadius.circular(context.dp(12)),
        border: Border.all(color: const Color(0xFFDCCAF1)),
      ),
      child: Row(
        children: [
          AeClubCrest(
            name: clubName,
            logoUrl: _organizationLogo ?? DugnadState.instance.clubLogo,
            size: context.dp(40),
            backgroundColor: Colors.white,
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadReferralInvitedToClub(clubName),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2E1F58),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: context.dp(3)),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF21A669),
                      size: context.dp(16),
                    ),
                    SizedBox(width: context.dp(5)),
                    Text(
                      languages.dugnadReferralInvitedBy(referrerName),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.aeTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.dp(8)),
          Semantics(
            button: true,
            label: languages.dugnadSeasonFinaleDismiss,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _dismiss,
                child: SizedBox(
                  width: context.dp(24),
                  height: context.dp(24),
                  child: Icon(
                    Icons.close_rounded,
                    size: context.dp(15),
                    color: const Color(0xFF2E1F58).withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
