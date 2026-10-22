// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../networking/ops/cus_api.dart';
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_routes.dart';
import 'ai_bits.dart';
import 'ai_copy.dart';

/// Customer plan Step 14 — the three overlays of design 9612–9643:
/// «Bytter app» (Ærend ↔ the assistant, out and back), the push «{AI} vil
/// bestille» as an in-app banner, and «Face ID» / «Åpner Vipps …» before
/// paying.
abstract final class AiOverlays {
  /// «Bytter app»: `Åpner {AI} …` → (opens the assistant where known) → «Tilbake i Ærend».
  /// The `kurv` variant («Fortsetter i {AI} …» + the prompt + «Bygger handlekurv hos Ærend …»).
  static Future<void> bytt(BuildContext context, String navn, {bool kurv = false, bool apne = true, Duration? ut, Duration? inn}) async {
    final nav = Navigator.of(context, rootNavigator: true);
    final done = Completer<void>();
    final faseUt = ValueNotifier<bool>(true);
    unawaited(showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color.fromRGBO(4, 18, 26, .92),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _Bytt(navn: navn, kurv: kurv, faseUt: faseUt),
    ).whenComplete(() {
      if (!done.isCompleted) done.complete();
    }));
    await Future<void>.delayed(ut ?? Duration(milliseconds: kurv ? 2900 : 1600));
    if (apne) {
      final uri = AiNavn.app(navn);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }
    faseUt.value = false;
    await Future<void>.delayed(inn ?? const Duration(milliseconds: 1300));
    if (nav.canPop()) nav.pop();
    await done.future;
  }

  static OverlayEntry? _push;
  static Timer? _pushT;

  /// The push «{AI} vil bestille» as an in-app banner (auto-hides after 8 s): «Se bestillingen» → the request; «Avvis».
  static void push(BuildContext context, CusAiRequest r, {Duration hide = const Duration(seconds: 8), VoidCallback? onAvvis}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    lukkPush();
    _push = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 10,
        right: 10,
        top: MediaQuery.paddingOf(ctx).top + 6,
        child: _PushBanner(
          r: r,
          onApne: () {
            lukkPush();
            BergenRoutes.push<void>(ctx, '/bergen/ai/foresporsel/${r.id}');
          },
          onAvvis: () {
            lukkPush();
            onAvvis?.call();
          },
          onLukk: lukkPush,
        ),
      ),
    );
    overlay.insert(_push!);
    _pushT = Timer(hide, lukkPush);
  }

  static void lukkPush() {
    _pushT?.cancel();
    _pushT = null;
    _push?.remove();
    _push = null;
  }

  /// «Face ID» / «Åpner Vipps …» with «Ærend · {sum}» under it; closes when [until] completes.
  static Future<T> face<T>(BuildContext context, {required bool vipps, required String sum, required String under, required Future<T> until}) async {
    final nav = Navigator.of(context, rootNavigator: true);
    unawaited(showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color.fromRGBO(4, 18, 26, .86),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _Face(vipps: vipps, sum: sum, under: under),
    ));
    try {
      return await until;
    } finally {
      if (nav.canPop()) nav.pop();
    }
  }
}

class _Bytt extends StatelessWidget {
  const _Bytt({required this.navn, required this.kurv, required this.faseUt});

  final String navn;
  final bool kurv;
  final ValueNotifier<bool> faseUt;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Center(
      child: ValueListenableBuilder<bool>(
        valueListenable: faseUt,
        builder: (_, ut, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            key: Key('cus-ai-bytt-${ut ? 'ut' : 'inn'}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedScale(scale: ut ? .9 : 1.08, duration: const Duration(milliseconds: 500), child: AnimatedOpacity(opacity: ut ? .55 : 1, duration: const Duration(milliseconds: 400), child: Container(width: 54, height: 54, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFFF58A55), Color(0xFFE95C2C)])), child: Text('Æ', style: jakarta(24, weight: FontWeight.w800, color: const Color(0xFF23201D)))))),
                const SizedBox(width: 18),
                const _Prikker(),
                const SizedBox(width: 18),
                AnimatedScale(scale: ut ? 1.08 : .9, duration: const Duration(milliseconds: 500), child: AnimatedOpacity(opacity: ut ? 1 : .55, duration: const Duration(milliseconds: 400), child: AiMerke(navn, size: 54))),
              ]),
              const SizedBox(height: 22),
              if (ut) ...[
                Text(kurv ? AiCopy.cus_ai_bytt_fortsetter(navn) : AiCopy.cus_ai_bytt_apner(navn), textAlign: TextAlign.center, style: jakarta(20, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(kurv ? AiCopy.cus_ai_bytt_si(navn) : AiCopy.cus_ai_bytt_godkjenn(navn), textAlign: TextAlign.center, style: inter(13.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .78))),
                if (kurv) ...[
                  const SizedBox(height: 16),
                  AiKort(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('«${AiCopy.cus_ai_prompt}»', style: inter(13.5, weight: FontWeight.w700, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(children: [const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7FF0CB))), const SizedBox(width: 8), Text(AiCopy.cus_ai_bygger_kurv, style: inter(12, weight: FontWeight.w700, color: const Color(0xFF7FF0CB)))]),
                  ])),
                ],
              ] else ...[
                Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8)), child: const AeIkon(AiIk.hake, size: 20, stroke: 3, color: Color(0xFF0F2B33))),
                const SizedBox(height: 12),
                Text(AiCopy.cus_ai_tilbake_i, style: jakarta(20, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(kurv ? AiCopy.cus_ai_bytt_inn_kurv(navn) : AiCopy.cus_ai_bytt_inn_sam(navn), textAlign: TextAlign.center, style: inter(13.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .78))),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _Prikker extends StatefulWidget {
  const _Prikker();

  @override
  State<_Prikker> createState() => _PrikkerState();
}

class _PrikkerState extends State<_Prikker> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 3; i++) Opacity(opacity: (0.3 + 0.7 * ((1 - ((_c.value - i * .25) % 1.0 - .5).abs() * 2).clamp(0.0, 1.0))), child: Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7FF0CB)))),
    ]),
  );
}

class _PushBanner extends StatelessWidget {
  const _PushBanner({required this.r, required this.onApne, required this.onAvvis, required this.onLukk});

  final CusAiRequest r;
  final VoidCallback onApne;
  final VoidCallback onAvvis;
  final VoidCallback onLukk;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: AeOnce(
      kind: AeInn.stigOpp,
      ms: 420,
      child: GestureDetector(
        onTap: onApne,
        child: Container(
          key: const Key('cus-ai-push'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF22596A), Color(0xFF122F3A)]),
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(4, 18, 26, .7), offset: Offset(0, 18), blurRadius: 32 / 2 / .57735, spreadRadius: -14)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AiMerke(r.assistant, size: 38),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text('ÆREND', style: inter(10, weight: FontWeight.w800, em: .1, color: const Color(0xFF7FF0CB))), Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .5))), Text(AiCopy.cus_ai_push_naa, style: inter(10, weight: FontWeight.w800, em: .1, color: const Color.fromRGBO(255, 255, 255, .6)))]),
                const SizedBox(height: 2),
                Text(AiCopy.cus_ai_push_tittel(r.assistant), style: inter(14.5, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(AiCopy.cus_ai_push_tx(r.assistant, r.total.display, r.store), style: inter(12.5, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .8))),
              ])),
              const SizedBox(width: 6),
              AePress(onTap: onLukk, dy: 1, child: const Padding(padding: EdgeInsets.all(4), child: AeIkon(AiIk.kryss, size: 14, stroke: 2.4, color: Color.fromRGBO(255, 255, 255, .7)))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: AePress(onTap: onApne, dy: 2, child: Container(key: const Key('cus-ai-push-se'), height: 38, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)])), child: Row(mainAxisSize: MainAxisSize.min, children: [const AeIkon(AiIk.pose, size: 14, stroke: 2.4), const SizedBox(width: 6), Text(AiCopy.cus_ai_se_bestillingen, style: inter(13, weight: FontWeight.w800))])))),
              const SizedBox(width: 8),
              AePress(onTap: onAvvis, dy: 1.5, child: Container(key: const Key('cus-ai-push-avvis'), height: 38, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2))), child: Text(AiCopy.cus_ai_avvis, style: inter(13, weight: FontWeight.w800)))),
            ]),
          ]),
        ),
      ),
    ),
  );
}

class _Face extends StatelessWidget {
  const _Face({required this.vipps, required this.sum, required this.under});

  final bool vipps;
  final String sum;
  final String under;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Center(
      child: Column(
        key: Key(vipps ? 'cus-ai-face-vipps' : 'cus-ai-face-id'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120, height: 120, alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22))),
            child: vipps
                ? Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 46, height: 46, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFFFF5B24)), alignment: Alignment.center, child: Text('V', style: jakarta(26, weight: FontWeight.w800))), const SizedBox(height: 8), Text('Vipps', style: inter(13, weight: FontWeight.w800))])
                : const Icon(Icons.face_retouching_natural_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(vipps ? AiCopy.cus_ai_apner_vipps : AiCopy.cus_ai_face_id, style: jakarta(20, weight: FontWeight.w800)),
          const SizedBox(height: 18),
          Text(AiCopy.cus_ai_aerend_sum(sum), style: inter(14, weight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(under, style: inter(12.5, color: const Color.fromRGBO(255, 255, 255, .7))),
        ],
      ),
    ),
  );
}
