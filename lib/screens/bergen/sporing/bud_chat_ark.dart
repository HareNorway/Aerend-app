// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../networking/ops/cus_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../kit/bergen_kit.dart';
import '../meg/meg_ark.dart';
import 'sporing_bits.dart';

/// The bud chat's strings (21 Oct, `cus_budchat_*`).
abstract final class CusBudchatCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String cus_budchat_ditt_bud(String navn) => _t('$navn · ditt bud', '$navn · your courier');

  /// The design's «Svarer mens hun kjører …», without guessing the courier's gender.
  static String get cus_budchat_linje => _t('Svarer underveis · meldinger gjelder bare denne leveringen', 'Replies on the way · messages are for this delivery only');
  static String get cus_budchat_paa_vei => _t('På vei med bestillingen din', 'On the way with your order');
  static String get cus_budchat_henter => _t('Henter bestillingen din', 'Picking up your order');
  static String get cus_budchat_privat => _t('Privat', 'Private');
  static List<String> get cus_budchat_chips => [
    _t('Jeg møter deg i porten', 'I’ll meet you at the gate'),
    _t('Ring på — jeg er hjemme', 'Ring the bell — I’m home'),
    _t('Sett den utenfor døra', 'Leave it outside the door'),
  ];
  static String cus_budchat_skriv_til(String navn) => _t('Skriv til $navn …', 'Write to $navn …');
  static String get cus_budchat_send => _t('Send melding', 'Send message');
  static String cus_budchat_ring(String navn) => _t('Ring $navn', 'Call $navn');
}

const String _kIkonSykkel = 'M5.5 17.5a3 3 0 1 0 0-.1M18.5 17.5a3 3 0 1 0 0-.1M5.5 17.5l3.5-7h5l4.5 7M9 10.5L8 7.5H6M14 10.5l1.5-3H18';
const String _kIkonLaas = 'M6 11h12v9H6zM8.5 11V8a3.5 3.5 0 0 1 7 0v3';
const String _kIkonSend = 'M4 12l16-7-6.5 16-2.2-6.3z';
const String _kIkonLest = 'M3 12.5l4 4L15 8.5M10 16.5l1 1L21 8';
const Color _kMint = Color(0xFF7FF0CB);
const Color _kInk = Color(0xFF0F2B33);
const List<FontFeature> _kTab = [FontFeature.tabularFigures()];

/// The order's chat with the courier: the server's lines (both directions,
/// `GET api/customer/orders/{id}/messages`) plus what was sent from this sheet
/// and has not come back yet. Polls while the sheet is open.
class BudChatTraad extends ChangeNotifier {
  BudChatTraad({required this.orderId, required this.api, CusApi? cus}) : cus = cus ?? CusApi();

  final int orderId;
  final OpsCustomerApi api;
  final CusApi cus;
  final TextEditingController tekst = TextEditingController();

  List<CusMelding> _server = const [];
  final List<CusMelding> _sendt = [];
  Timer? _poll;
  bool _lukket = false;

  /// Oldest first.
  List<CusMelding> get meldinger => [
    ..._server,
    for (final m in _sendt)
      if (!_server.any((s) => s.fraMeg && s.tekst == m.tekst)) m,
  ];

  void start({Duration hvert = const Duration(seconds: 8)}) {
    hent();
    _poll = Timer.periodic(hvert, (_) => hent());
  }

  Future<void> hent() async {
    final liste = await cus.meldinger(orderId);
    if (_lukket) return;
    if (liste.isEmpty && _server.isNotEmpty) return;
    _server = liste;
    notifyListeners();
  }

  /// Sends one line (`ops/customer/orders/{id}/contact kind=message`). False
  /// when it did not go; the line is taken back and left in the field.
  Future<bool> send(String linje) async {
    final t = linje.trim();
    if (t.isEmpty) return true;
    final m = CusMelding(fraMeg: true, tekst: t, at: DateTime.now());
    _sendt.add(m);
    if (tekst.text.trim() == t) tekst.clear();
    notifyListeners();
    final res = await api.contact(orderId, kind: 'message', message: t);
    if (_lukket) return res != null;
    if (res == null) {
      _sendt.remove(m);
      if (tekst.text.isEmpty) tekst.text = t;
      notifyListeners();
      return false;
    }
    await hent();
    return true;
  }

  @override
  void dispose() {
    _lukket = true;
    _poll?.cancel();
    tekst.dispose();
    super.dispose();
  }
}

/// **Budchat** (21 Oct L10327–10357, `kArk type 'budchat'`): the dark Ark
/// with the courier's card («{navn} · ditt bud», «Privat»), the messages
/// (the courier's on the left with the initial, the customer's in mint on the
/// right), the quick chips, «Skriv til {navn} …» and «Ring {navn}».
Future<void> visBudChat(BuildContext context, {required int orderId, required OpsTracking tracking, required OpsCustomerApi api, required VoidCallback onRing, CusApi? cus}) async {
  final navn = tracking.courier?.firstName ?? 'Bud';
  final traad = BudChatTraad(orderId: orderId, api: api, cus: cus)..start();
  Future<void> send(BuildContext ctx, String linje) async {
    final ok = await traad.send(linje);
    if (!ok && ctx.mounted) showBergenToast(ctx, BergenRoutes.ikkeSendt);
  }

  try {
    await showMegArk<void>(
      context,
      key: const Key('cus-budchat'),
      mork: true,
      tastatur: true,
      title: navn,
      subtitle: CusBudchatCopy.cus_budchat_linje,
      body: (ctx, _) => ListenableBuilder(
        listenable: traad,
        builder: (ctx, _) => BudChatKropp(navn: navn, underveis: tracking.state == 'picked_up' || tracking.state == 'arrived_customer', meldinger: traad.meldinger),
      ),
      fot: (ctx, _) => BudChatFot(navn: navn, tekst: traad.tekst, onSend: (l) => send(ctx, l)),
      primary: MegArkButton(
        key: const Key('cus-budchat-ring'),
        label: CusBudchatCopy.cus_budchat_ring(navn),
        onTap: () {
          Navigator.of(context).maybePop();
          onRing();
        },
      ),
    );
  } finally {
    traad.dispose();
  }
}

/// The card and the messages (`Budchat · bud` + `Budchat · meldinger`). A new
/// line scrolls the sheet down to it.
class BudChatKropp extends StatefulWidget {
  const BudChatKropp({super.key, required this.navn, required this.underveis, required this.meldinger});

  final String navn;

  /// The courier has the order (picked up / at the door): «På vei med
  /// bestillingen din»; before that «Henter bestillingen din».
  final bool underveis;
  final List<CusMelding> meldinger;

  @override
  State<BudChatKropp> createState() => _BudChatKroppState();
}

class _BudChatKroppState extends State<BudChatKropp> {
  final GlobalKey _siste = GlobalKey();

  String get _initial => widget.navn.isEmpty ? '?' : widget.navn.characters.first.toUpperCase();

  @override
  void didUpdateWidget(BudChatKropp old) {
    super.didUpdateWidget(old);
    if (widget.meldinger.length > old.meldinger.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = _siste.currentContext;
        if (c != null && c.mounted) Scrollable.ensureVisible(c, alignment: 1, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navn = widget.navn, underveis = widget.underveis, meldinger = widget.meldinger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LfOnce(
          ms: 400,
          builder: (context, t, child) {
            final p = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 400));
            return Opacity(
              opacity: p.clamp(0.0, 1.0),
              child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 18 * (1 - p), 0)..scaleByDouble(.97 + .03 * p, .97 + .03 * p, 1, 1), child: child),
            );
          },
          child: _BudKort(navn: navn, initial: _initial, underveis: underveis),
        ),
        Padding(
          key: const Key('cus-budchat-meldinger'),
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, m) in meldinger.indexed) ...[
                const SizedBox(height: 10),
                KeyedSubtree(
                  key: i == meldinger.length - 1 ? _siste : null,
                  child: _Boble(key: ValueKey('cus-budchat-boble-$i-${m.fraMeg}-${m.tekst.hashCode}'), melding: m, initial: _initial),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BudKort extends StatelessWidget {
  const _BudKort({required this.navn, required this.initial, required this.underveis});

  final String navn, initial;
  final bool underveis;

  @override
  Widget build(BuildContext context) => CssBox(
    key: const Key('cus-budchat-bud'),
    radius: BorderRadius.circular(20),
    padding: const EdgeInsets.fromLTRB(13, 12, 13, 12), // 11 12 + the CSS border
    border: Border.all(color: rgba(255, 255, 255, .16)),
    bg: [
      CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .05)]),
    ],
    shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .22)), CssShadow(0, 12, 20, -14, rgba(0, 10, 16, .85))],
    child: Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _Avatar(initial: initial, size: 44)),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF5CE0B8),
                    border: Border.all(color: const Color(0xFF1D4C5A), width: 2.5, strokeAlign: BorderSide.strokeAlignOutside),
                    boxShadow: [BoxShadow(color: rgba(92, 224, 184, .8), blurRadius: 10)],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CusBudchatCopy.cus_budchat_ditt_bud(navn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(14.5, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  spIkon(_kIkonSykkel, size: 13, color: _kMint),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      underveis ? CusBudchatCopy.cus_budchat_paa_vei : CusBudchatCopy.cus_budchat_henter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(11.5, weight: FontWeight.w700, color: _kMint),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: rgba(6, 22, 30, .35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: rgba(255, 255, 255, .14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              spIkon(_kIkonLaas, size: 11, color: const Color(0xFFDCE9EC), width: 2.4),
              const SizedBox(width: 5),
              Text(
                CusBudchatCopy.cus_budchat_privat,
                style: inter(11, weight: FontWeight.w800, color: const Color(0xFFDCE9EC)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The courier's round initial (`#DCE9EC → #9FC9D4 → #7FB4C4`).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final stor = size > 30;
    return CssBox(
      width: size,
      height: size,
      radius: BorderRadius.circular(size),
      bg: const [
        CssLinear(160, [Color(0xFFDCE9EC), Color(0xFF9FC9D4), Color(0xFF7FB4C4)], [0, .7, 1]),
      ],
      shadows: stor
          ? [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .7)), CssShadow(0, 0, 0, 2, rgba(255, 255, 255, .9)), CssShadow(0, 8, 14, -6, rgba(0, 0, 0, .6))]
          : [CssShadow(0, 0, 0, 1.5, rgba(255, 255, 255, .85))],
      child: Center(
        child: Text(
          initial,
          style: stor ? jakarta(17, color: const Color(0xFF123A45)) : inter(11.5, weight: FontWeight.w800, color: const Color(0xFF123A45)),
        ),
      ),
    );
  }
}

/// One message (`bobleInn .3s`): the courier's glass on the left with the
/// initial, the customer's mint on the right with the time and the ticks.
class _Boble extends StatelessWidget {
  const _Boble({super.key, required this.melding, required this.initial});

  final CusMelding melding;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final meg = melding.fraMeg;
    final tid = melding.at == null ? '' : spKlokke(melding.at!);
    // `max-width: 76%` — measured in the 21 Oct render as 76 % of the 390 px
    // sheet (≈ 296), not of the row; the bubble shrinks to its text.
    Widget boble(double maks) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maks),
        child: LfOnce(
          ms: 300,
          builder: (context, t, child) {
            final p = const Cubic(.25, 1.25, .45, 1).transform(kfP(t, 0, 300));
            return Opacity(
              opacity: kfP(t, 0, 300).clamp(0.0, 1.0),
              child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 8 * (1 - p), 0)..scaleByDouble(.6 + .4 * p, .6 + .4 * p, 1, 1), child: child),
            );
          },
          child: CssBox(
            padding: meg ? const EdgeInsets.fromLTRB(13, 10, 13, 10) : const EdgeInsets.fromLTRB(14, 11, 14, 11),
            radius: meg
                ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(6))
                : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(6), bottomRight: Radius.circular(18)),
            border: meg ? null : Border.all(color: rgba(255, 255, 255, .18)),
            bg: meg
                ? const [
                    CssLinear(180, [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]),
                  ]
                : [
                    CssLinear(180, [rgba(255, 255, 255, .18), rgba(255, 255, 255, .08)]),
                  ],
            shadows: meg
                ? [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .6)), CssShadow(0, 2, 0, 0, rgba(20, 90, 70, .5)), CssShadow(0, 10, 16, -10, rgba(0, 0, 0, .6))]
                : [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .22)), CssShadow(0, 10, 16, -12, rgba(0, 0, 0, .7))],
            child: Column(
              crossAxisAlignment: meg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  melding.tekst,
                  style: inter(13.5, weight: meg ? FontWeight.w700 : FontWeight.w600, height: 1.4, color: meg ? _kInk : Colors.white),
                ),
                if (tid.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  if (meg)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tid,
                          style: inter(10, weight: FontWeight.w700, color: rgba(15, 43, 51, .6)).copyWith(fontFeatures: _kTab),
                        ),
                        const SizedBox(width: 3),
                        spIkon(_kIkonLest, size: 12, color: rgba(15, 43, 51, .6), width: 2.6),
                      ],
                    )
                  else
                    Text(
                      tid,
                      style: inter(10, weight: FontWeight.w700, color: rgba(255, 255, 255, .55)).copyWith(fontFeatures: _kTab),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    final maks = MediaQuery.sizeOf(context).width * .76;
    return Row(
      key: Key(meg ? 'cus-budchat-fra-meg' : 'cus-budchat-fra-bud'),
      mainAxisAlignment: meg ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!meg) ...[_Avatar(initial: initial, size: 28), const SizedBox(width: 8)],
        Flexible(child: boble(maks)),
      ],
    );
  }
}

/// `Budchat · skriv`: the quick chips and the input with its send key.
class BudChatFot extends StatelessWidget {
  const BudChatFot({super.key, required this.navn, required this.tekst, required this.onSend});

  final String navn;
  final TextEditingController tekst;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 2),
            clipBehavior: Clip.none,
            children: [
              for (final (i, c) in CusBudchatCopy.cus_budchat_chips.indexed) ...[
                if (i > 0) const SizedBox(width: 7),
                LfPress(
                  key: Key('cus-budchat-chip-$i'),
                  onTap: () => onSend(c),
                  scale: .95,
                  dy: 0,
                  child: CssBox(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    radius: BorderRadius.circular(999),
                    bg: [
                      CssLinear(180, [rgba(255, 255, 255, .16), rgba(255, 255, 255, .06)]),
                    ],
                    shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .22)), CssShadow(0, 0, 0, 1, rgba(255, 255, 255, .2))],
                    child: Center(
                      child: Text(c, style: inter(12.5, weight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 9),
        CssBox(
          padding: const EdgeInsets.fromLTRB(16, 5, 5, 5),
          radius: BorderRadius.circular(999),
          bg: [
            CssLinear(180, [rgba(6, 22, 30, .42), rgba(6, 22, 30, .42)]),
          ],
          shadows: [CssShadow.inset(0, 2, 4, 0, rgba(0, 0, 0, .35)), CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14))],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('cus-budchat-felt'),
                  controller: tekst,
                  textInputAction: TextInputAction.send,
                  onSubmitted: onSend,
                  cursorColor: _kMint,
                  style: jakarta(14, weight: FontWeight.w700),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                    hintText: CusBudchatCopy.cus_budchat_skriv_til(navn),
                    hintStyle: jakarta(14, weight: FontWeight.w600, color: const Color(0xFF9A9188)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: CusBudchatCopy.cus_budchat_send,
                child: LfPress(
                  key: const Key('cus-budchat-send'),
                  onTap: () => onSend(tekst.text),
                  scale: .9,
                  dy: 0,
                  child: CssBox(
                    width: 42,
                    height: 42,
                    radius: BorderRadius.circular(999),
                    bg: const [
                      CssLinear(180, [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]),
                    ],
                    shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .6)), CssShadow(0, 2, 0, 0, rgba(20, 90, 70, .5)), CssShadow(0, 8, 14, -6, rgba(0, 0, 0, .6))],
                    child: Center(child: spIkon(_kIkonSend, size: 17, color: _kInk, width: 2.3)),
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
