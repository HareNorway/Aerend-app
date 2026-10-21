// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../kit/bergen_kit.dart';
import '../meg/meg_ark.dart';
import 'sporing_bits.dart' show rgba;
import 'sporing_copy.dart';

/// The thank-you note's strings (Customer Step 2, `cus_takk_*`).
abstract final class CusTakkCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String cus_takk_til(String navn) => _t('Takk til $navn', 'Thank $navn');
  static String cus_takk_linje(String navn) => _t('$navn ser hilsenen din etter turen. Frivillig, og én gang per levering.', '$navn sees your note after the run. Voluntary, and once per delivery.');
  static List<String> get cus_takk_forslag => [
    _t('Takk for raskt levert!', 'Thanks for the quick delivery!'),
    _t('Alt kom fram perfekt — takk!', 'Everything arrived perfectly — thanks!'),
    _t('Takk for at du tok det helt opp!', 'Thanks for bringing it all the way up!'),
  ];
  static String get cus_takk_hint => _t('Skriv en hilsen …', 'Write a note …');
  static String get cus_takk_send => _t('Send takk', 'Send thanks');
  static String cus_takk_sendt(String navn) => _t('Takken er sendt til $navn', 'Your thanks went to $navn');
  static String cus_takk_sendt_kort(String navn) => _t('Takk sendt til $navn', 'Thanks sent to $navn');
}

/// The note's limit (`ThanksNote::MAX_LENGTH`).
const int kTakkMaks = 140;

/// The pref that remembers a sent note on this device.
String takkPref(int orderId) => 'cus_takk_$orderId';

/// **Takk til budet** (NEW UI, plan §9 Step 2.5): the dark Ark with three
/// suggestions, a 140-character note and «Send takk» →
/// `POST api/customer/orders/{id}/thanks`. True when the note is stored.
Future<bool> visTakkArk(BuildContext context, {required int orderId, required String navn, CusApi? cus}) async {
  final api = cus ?? CusApi();
  final felt = TextEditingController();
  var sender = false;
  try {
    final ok = await showMegArk<bool>(
      context,
      key: const Key('cus-takk-ark'),
      mork: true,
      tastatur: true,
      title: CusTakkCopy.cus_takk_til(navn),
      subtitle: CusTakkCopy.cus_takk_linje(navn),
      body: (ctx, setState) => TakkKropp(felt: felt, onEndret: () => setState(() {})),
      secondary: MegArkButton(key: const Key('cus-takk-ikke-naa'), label: SporingCopy.a1_sporing_ikke_naa, onTap: () => Navigator.of(context).maybePop()),
      primaryBuilder: (ctx) => MegArkButton(
        key: const Key('cus-takk-send'),
        label: CusTakkCopy.cus_takk_send,
        av: felt.text.trim().isEmpty,
        onTap: () async {
          final tekst = felt.text.trim();
          if (tekst.isEmpty || sender) return;
          sender = true;
          final lagret = await api.takk(orderId, tekst);
          sender = false;
          if (!ctx.mounted) return;
          if (!lagret) {
            showBergenToast(ctx, BergenRoutes.ikkeSendt);
            return;
          }
          Navigator.of(ctx).pop(true);
        },
      ),
    );
    if (ok == true) {
      prefSetString(takkPref(orderId), '1');
      if (context.mounted) showBergenToast(context, CusTakkCopy.cus_takk_sendt(navn));
    }
    return ok == true;
  } finally {
    felt.dispose();
  }
}

/// The suggestions and the note field with its count.
class TakkKropp extends StatelessWidget {
  const TakkKropp({super.key, required this.felt, required this.onEndret});

  final TextEditingController felt;
  final VoidCallback onEndret;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final (i, f) in CusTakkCopy.cus_takk_forslag.indexed)
            LfPress(
              key: Key('cus-takk-forslag-$i'),
              onTap: () {
                felt.text = f;
                felt.selection = TextSelection.collapsed(offset: f.length);
                onEndret();
              },
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
                  widthFactor: 1,
                  child: Text(f, style: inter(12.5, weight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      CssBox(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
        radius: BorderRadius.circular(20),
        bg: [
          CssLinear(180, [rgba(6, 22, 30, .42), rgba(6, 22, 30, .42)]),
        ],
        shadows: [CssShadow.inset(0, 2, 4, 0, rgba(0, 0, 0, .35)), CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14))],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('cus-takk-felt'),
              controller: felt,
              minLines: 3,
              maxLines: 4,
              inputFormatters: [LengthLimitingTextInputFormatter(kTakkMaks)],
              onChanged: (_) => onEndret(),
              cursorColor: const Color(0xFF7FF0CB),
              style: jakarta(14, weight: FontWeight.w700, height: 1.4),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
                hintText: CusTakkCopy.cus_takk_hint,
                hintStyle: jakarta(14, weight: FontWeight.w600, color: const Color(0xFF9A9188)),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${felt.text.characters.length}/$kTakkMaks',
                key: const Key('cus-takk-teller'),
                style: inter(11, weight: FontWeight.w700, color: rgba(255, 255, 255, .55)).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
