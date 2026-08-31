import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/surface_decorations.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../../ui/kit/ae_club_crest.dart';
import 'dugnad_club_branding.dart';
import '../../ui/kit/ae_sheet.dart';
import 'dugnad_state.dart';
import '../../ui/kit/ae_theme.dart';

/// Membership number editor bottom sheet.
///
/// Prefilled with current membership number (if any). "Lagre" saves,
/// "Fjern" clears. Returns after save so callers can refresh.
Future<void> showMembershipSheet(BuildContext context) {
  return showAeSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _MembershipSheetBody(),
  );
}

class _MembershipSheetBody extends StatefulWidget {
  const _MembershipSheetBody();

  @override
  State<_MembershipSheetBody> createState() => _MembershipSheetBodyState();
}

class _MembershipSheetBodyState extends State<_MembershipSheetBody> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = DugnadState.instance.membershipNumber;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(12), context.dp(18), bottomInset + context.dp(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AeSheetHandle(),
          // Header — crest + "Medlem av {club}?" + unlock value (prototype
          // `.dg-mem-head`). Reads as unlocking member value, not billing.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AeClubCrest(
                name: DugnadClubBranding.fullName(),
                logoUrl: DugnadState.instance.clubLogo.isEmpty
                    ? null
                    : DugnadState.instance.clubLogo,
                size: context.dp(40),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.dugnadMemberOfClub(
                        DugnadClubBranding.fullName(),
                      ),
                      style: aeH2().copyWith(fontSize: 18),
                    ),
                    SizedBox(height: context.dp(4)),
                    Text(
                      languages.dugnadMembershipSheetDesc,
                      style: aeCaption(color: ScSaasThemeTokens.gray500)
                          .copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(18)),
          // Field label (prototype `.ae-flabel`).
          Text(
            DugnadState.instance.hasMembership
                ? languages.dugnadMembershipNumber
                : languages.dugnadMembershipOptionalLabel,
            style: aeCaption(color: ScSaasThemeTokens.gray500)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: context.dp(8)),
          // Numeric field
          Container(
            decoration: AeSurface.card(
              borderRadius: BorderRadius.circular(context.dp(14)),
            ),
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: aeBody(),
              decoration: InputDecoration(
                hintText: languages.dugnadMembershipNumber,
                hintStyle: aeCaption(color: ScSaasThemeTokens.gray500),
                prefixIcon: Icon(Icons.vpn_key_rounded,
                    color: ScSaasThemeTokens.gray500, size: context.dp(20)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(14)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.dp(14)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: context.dp(20)),
          // Primary — "Lås opp rabatter" (new) / "Lagre endring" (editing).
          GestureDetector(
            onTap: () async {
              aeSheetSaveHaptic();
              final nr = _ctrl.text.trim();
              if (nr.isNotEmpty) {
                await DugnadState.instance.setMembershipNumber(nr);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.dp(16)),
              decoration: BoxDecoration(
                color: context.aeTheme.primary,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: ScSaasThemeTokens.shadowButton,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key_rounded,
                      color: Colors.white, size: context.dp(17)),
                  SizedBox(width: context.dp(8)),
                  Text(
                    DugnadState.instance.hasMembership
                        ? languages.dugnadSaveChange
                        : languages.dugnadUnlockDiscounts,
                    style: aeLabel(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.dp(10)),
          // Ghost — "Fjern medlemsnummer" (editing) / "Ikke nå" (new).
          GestureDetector(
            onTap: () async {
              aeSheetCloseHaptic();
              if (DugnadState.instance.hasMembership) {
                await DugnadState.instance.clearMembership();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.dp(14)),
              alignment: Alignment.center,
              child: Text(
                DugnadState.instance.hasMembership
                    ? languages.dugnadRemoveMembership
                    : languages.dugnadNotNow,
                style: aeLabel(
                  color: DugnadState.instance.hasMembership
                      ? ScSaasThemeTokens.danger
                      : ScSaasThemeTokens.gray500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
