import 'package:flutter/material.dart';

import '../../../dialogs/simple_dialog_util.dart';
import '../../../screens/common/home/home_repo.dart';
import '../../../utils/utils.dart';
import '../../common/editProfile/edit_profile.dart';
import '../../common/manageAddress/add_new_address.dart';
import '../../common/manageAddress/manage_address.dart';
import '../../common/manageCard/manage_card.dart';
import 'a3_scaffold.dart';
import 'a3_services.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';

const String kPrefA3KrysningAv = 'a3_konto_krysning_varsler_av';
const String kPrefA3Rolig = 'a3_konto_rolig';

/// Konto (design `konto` ≈L5860): the profile line (Vipps-verifisert),
/// Adresser, Betaling (Vipps standard), Innstillinger (varsler om krysningen,
/// roligere bevegelse), Hjelp og personvern, and Logg ut. The existing
/// address / card / profile screens do the editing.
class KontoScreen extends StatefulWidget {
  const KontoScreen({super.key});

  @override
  State<KontoScreen> createState() => _KontoScreenState();
}

class _KontoScreenState extends State<KontoScreen> {
  bool _krysning = true;
  bool _rolig = false;

  @override
  void initState() {
    super.initState();
    try {
      _krysning = !prefGetBool(kPrefA3KrysningAv);
      _rolig = prefGetBool(kPrefA3Rolig);
    } catch (_) {}
    A3Services.reducedMotion.value = _rolig;
  }

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  Future<void> _logout() async {
    await showBergenSheet<void>(
      context,
      builder: (ctx) => LogoutSheet(
        onConfirm: () async {
          try {
            await HomeRepo().callLogoutApi();
          } catch (_) {}
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          if (!mounted) return;
          logout(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = a3Pref(prefUserName);
    final email = a3Pref(prefEmail);

    return A3Scaffold(
      title: A3MegCopy.a3_meg_konto_title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BergenCard(
            onDark: true,
            onTap: () => _push(const EditProfile()),
            child: Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: BergenTokens.tealLight, child: Icon(Icons.person_rounded, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'Deg' : name, style: BergenTokens.display(BergenTokens.textSection, color: Colors.white)),
                      Text(email.isEmpty ? A3MegCopy.a3_meg_konto_verifisert : email, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
                    ],
                  ),
                ),
                const BergenChip(label: A3MegCopy.a3_meg_konto_verifisert, selected: true, icon: Icons.verified_rounded),
              ],
            ),
          ),
          const A3Kicker(A3MegCopy.a3_meg_konto_adresser),
          A3Row(key: const Key('konto-adresser'), title: A3MegCopy.a3_meg_konto_adresser, icon: Icons.home_rounded, onTap: () => _push(const ManageAddress())),
          A3Row(key: const Key('konto-legg-adresse'), title: A3MegCopy.a3_meg_konto_legg_adresse, icon: Icons.add_location_alt_rounded, onTap: () => _push(const AddNewAddress())),
          const A3Kicker(A3MegCopy.a3_meg_konto_betaling),
          A3Row(key: const Key('konto-betaling'), title: 'Vipps', subtitle: A3MegCopy.a3_meg_konto_vipps_std, icon: Icons.payments_rounded, onTap: () => _push(const ManageCard())),
          const A3Kicker(A3MegCopy.a3_meg_konto_innstillinger),
          A3Row(
            key: const Key('konto-krysning'),
            title: A3MegCopy.a3_meg_konto_varsler,
            subtitle: A3MegCopy.a3_meg_konto_varsler_sub,
            icon: Icons.sailing_rounded,
            trailing: Switch.adaptive(
              value: _krysning,
              activeThumbColor: BergenTokens.mint,
              onChanged: (v) {
                setState(() => _krysning = v);
                prefSetBool(kPrefA3KrysningAv, !v);
              },
            ),
          ),
          A3Row(
            key: const Key('konto-rolig'),
            title: A3MegCopy.a3_meg_konto_rolig,
            subtitle: A3MegCopy.a3_meg_konto_rolig_sub,
            icon: Icons.slow_motion_video_rounded,
            trailing: Switch.adaptive(
              key: const Key('konto-rolig-switch'),
              value: _rolig,
              activeThumbColor: BergenTokens.mint,
              onChanged: (v) {
                setState(() => _rolig = v);
                A3Services.reducedMotion.value = v;
                prefSetBool(kPrefA3Rolig, v);
              },
            ),
          ),
          const A3Kicker(A3MegCopy.a3_meg_konto_hjelp),
          A3Row(title: A3MegCopy.a3_meg_konto_hjelp, subtitle: A3MegCopy.a3_meg_konto_data, icon: Icons.privacy_tip_rounded, onTap: () => showBergenToast(context, A3MegCopy.a3_meg_konto_data, icon: Icons.flag_rounded)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('konto-logg-ut'),
            onPressed: _logout,
            style: OutlinedButton.styleFrom(foregroundColor: BergenTokens.orangeLight, side: const BorderSide(color: BergenTokens.glassBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton))),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(A3MegCopy.a3_meg_konto_logg_ut),
          ),
        ],
      ),
    );
  }
}
