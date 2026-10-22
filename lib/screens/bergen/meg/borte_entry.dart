import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../aegil/cus_level3.dart';
import '../hjem/hjem_harness.dart';
import 'a3_services.dart';
import 'aegil_logg.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';

List<AwayItem> _away = const [];

/// Customer Step 7: the push invitation is due (level ≥ 2, not paused, never answered).
bool _inviteDue = false;

/// Ægil's settings for the invitation (tests swap it).
Future<AegilSettings?> Function() borteSettings = () async => (await AegilRepo().fetchSettings()).settings;

/// Refreshes the cache behind [mensDuVarBorteCard] from `agent/me/away`
/// (≤3 unseen actions). The Hjem calls it on cold start / resume. Customer
/// Step 7: the settings too, for [pushInviteCard].
Future<List<AwayItem>> refreshMensDuVarBorte({AegilAppApi? api}) async {
  try {
    _away = await (api ?? A3Services.aegil()).away();
  } catch (_) {
    _away = const [];
  }
  try {
    final s = await borteSettings();
    _inviteDue = s != null && !s.pushInvited && !s.paused && s.level >= 2;
  } catch (_) {
    _inviteDue = false;
  }
  return _away;
}

@visibleForTesting
void setPushInviteForTest(bool due) => _inviteDue = due;

/// Customer Step 7: the invitation to let Ægil notify (Ægil spec §25 P4,
/// existing customers), in «Mens du var borte»'s slot when that card has
/// nothing to say. Null when answered. Not in the design: needs sign-off.
Widget? pushInviteCard(BuildContext context) {
  if (!_inviteDue && !(kDebugMode && HjemHarness.hjemInvitasjon)) return null;
  return const _InviteCard();
}

@visibleForTesting
void setMensDuVarBorteForTest(List<AwayItem> items) => _away = items;

/// The cold-start "Mens du var borte" card at the top of the Hjem sheet
/// (seam, design `borte` ≈L2010). Returns null when Ægil has nothing to say.
Widget? mensDuVarBorteCard(BuildContext context) {
  if (_away.isEmpty) return null;
  return _BorteCard(items: _away);
}

class _BorteCard extends StatefulWidget {
  const _BorteCard({required this.items});

  final List<AwayItem> items;

  @override
  State<_BorteCard> createState() => _BorteCardState();
}

class _BorteCardState extends State<_BorteCard> {
  late List<AwayItem> _items = widget.items;

  /// Customer Step 7: the receipts undone from here (`agent/me/agent_actions/{id}/undo`).
  final Set<int> _angret = {};

  void _lukk() {
    setState(() => _items = const []);
    _away = const [];
  }

  Future<void> _angre(AwayItem a) async {
    final ok = await A3Services.aegil().undoAgentAction(a.id);
    if (!mounted) return;
    if (!ok) {
      showBergenToast(context, CusLevel3Copy.cus_angre_feil);
      return;
    }
    setState(() => _angret.add(a.id));
    showBergenToast(context, CusLevel3Copy.cus_angret_toast);
  }

  // Launch design "Mens du var borte" (L9017): a teal card with Ægil, a
  // close key, one line per thing and "Se de siste 30 dagene".
  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    const hvit = Color(0xFFF5F3EF);
    return LfOnce(
      // skjermInn .34s cubic(.2,.9,.3,1)
      ms: 340,
      builder: (context, t, child) {
        final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 340));
        final sk = .985 + .015 * e;
        return Opacity(
          opacity: e,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(0, 10 * (1 - e), 0, 1)
              ..scaleByDouble(sk, sk, 1, 1),
            child: child,
          ),
        );
      },
      child: CssBox(
        key: const Key('borte-card'),
        radius: BorderRadius.circular(24),
        bg: const [CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1])],
        shadows: const [CssShadow(0, 24, 44, -22, Color.fromRGBO(8, 24, 32, .6))],
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/images/dashboard/invitation.png', width: 38, height: 38, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(A3MegCopy.a3_meg_borte_kicker, style: inter(11, weight: FontWeight.w800, color: const Color(0xFFB9CBD5))),
                      Text(
                        _items.length == 3 ? A3MegCopy.a3_meg_borte_title : '${_items.length} ting fra Ægil',
                        style: jakarta(16, color: hvit),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _lukk,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .14), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text('✕', style: inter(13, color: hvit)),
                  ),
                ),
              ],
            ),
            for (final a in _items)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .14)))),
                // Customer Step 7: «Angre» on a level-3 merge (the undo route exists now);
                // undone, the line stays with «Angret» so the receipt is still readable.
                child: Row(
                  children: [
                    Expanded(child: Text(a.text, style: inter(13, color: a.undone || _angret.contains(a.id) ? const Color.fromRGBO(245, 243, 239, .55) : hvit))),
                    if (a.undone || _angret.contains(a.id)) ...[
                      const SizedBox(width: 8),
                      Text(CusLevel3Copy.cus_angret, key: Key('borte-angret-${a.id}'), style: inter(11.5, weight: FontWeight.w800, color: const Color.fromRGBO(245, 243, 239, .55))),
                    ] else if (a.undoable) ...[
                      const SizedBox(width: 8),
                      LfPress(
                        key: Key('borte-angre-${a.id}'),
                        onTap: () => _angre(a),
                        scale: .94,
                        ms: 140,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: const Color(0xFFDCE9EC), borderRadius: BorderRadius.circular(999)),
                          child: Text(CusLevel3Copy.cus_angre, style: inter(12, weight: FontWeight.w800, color: const Color(0xFF173E48))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 6),
            GestureDetector(
              key: const Key('borte-logg'),
              onTap: () => AegilLogg.vis(context),
              child: Text(A3MegCopy.a3_meg_borte_se, style: inter(12, weight: FontWeight.w800, color: const Color(0xFF5CE0B8))),
            ),
          ],
        ),
      ),
    );
  }
}

/// The push invitation (Customer Step 7): the «Mens du var borte» card's
/// teal glass, Ægil, two keys. «Ja takk» keeps the alert setting, «Nei takk»
/// turns Ægil's pushes off; either way it is asked once (`me/push-invite`).
class _InviteCard extends StatefulWidget {
  const _InviteCard();

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool _borte = false;

  Future<void> _svar(bool ja) async {
    setState(() => _borte = true);
    _inviteDue = false;
    HjemHarness.hjemInvitasjon = false;
    await A3Services.aegil().pushInvite(accept: ja);
    if (mounted) showBergenToast(context, ja ? CusLevel3Copy.cus_invit_ja_toast : CusLevel3Copy.cus_invit_nei_toast);
  }

  @override
  Widget build(BuildContext context) {
    if (_borte) return const SizedBox.shrink();
    const hvit = Color(0xFFF5F3EF);
    Widget knapp(String tx, bool ja) => Expanded(
      child: LfPress(
        key: Key(ja ? 'invit-ja' : 'invit-nei'),
        onTap: () => _svar(ja),
        scale: .96,
        ms: 140,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: ja ? null : const Color.fromRGBO(255, 255, 255, .14),
            gradient: ja ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], stops: [0, .56, 1]) : null,
          ),
          child: Text(tx, style: inter(13, weight: FontWeight.w800, color: hvit)),
        ),
      ),
    );
    return LfOnce(
      ms: 340,
      builder: (context, t, child) {
        final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 340));
        return Opacity(opacity: e, child: Transform.translate(offset: Offset(0, 10 * (1 - e)), child: child));
      },
      child: CssBox(
        key: const Key('invit-card'),
        radius: BorderRadius.circular(24),
        bg: const [CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1])],
        shadows: const [CssShadow(0, 24, 44, -22, Color.fromRGBO(8, 24, 32, .6))],
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/images/dashboard/invitation.png', width: 38, height: 38, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(CusLevel3Copy.cus_invit_kicker, style: inter(11, weight: FontWeight.w800, color: const Color(0xFFB9CBD5))),
                      Text(CusLevel3Copy.cus_invit_tittel, style: jakarta(16, color: hvit)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(CusLevel3Copy.cus_invit_linje, style: inter(12.5, height: 1.4, color: const Color.fromRGBO(245, 243, 239, .82))),
            const SizedBox(height: 12),
            Row(children: [knapp(CusLevel3Copy.cus_invit_nei, false), const SizedBox(width: 8), knapp(CusLevel3Copy.cus_invit_ja, true)]),
          ],
        ),
      ),
    );
  }
}

