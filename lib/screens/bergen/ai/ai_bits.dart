// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import 'ai_copy.dart';

/// Customer plan Step 14 — the small parts every AI sheet shares (design
/// `AI_M`, `AI_IK`, the handshake header `aiHs`): the assistant marks
/// (Claude and ChatGPT as logos, Gemini and Siri drawn), the icon paths, the
/// handshake header in its four modes, and the dark-sheet helpers.
abstract final class AiNavn {
  static const List<String> alle = ['Claude', 'ChatGPT', 'Gemini', 'Siri'];

  static String vendor(String navn) => switch (navn) { 'Claude' => 'claude', 'ChatGPT' => 'chatgpt', 'Gemini' => 'gemini', 'Siri' => 'siri', _ => 'other' };

  static String fraVendor(String vendor) => switch (vendor) { 'claude' => 'Claude', 'chatgpt' => 'ChatGPT', 'gemini' => 'Gemini', 'siri' => 'Siri', _ => vendor };

  static String clientId(String navn) => vendor(navn);

  /// The assistant's own app or site (the «Bytter app» overlay opens it where known).
  static Uri? app(String navn) => switch (navn) {
    'Claude' => Uri.parse('https://claude.ai/'),
    'ChatGPT' => Uri.parse('https://chatgpt.com/'),
    'Gemini' => Uri.parse('https://gemini.google.com/'),
    _ => null,
  };
}

abstract final class AiIk {
  static const String pose = 'M6 8h12l-1.2 12H7.2zM9 8V6.5a3 3 0 0 1 6 0V8';
  static const String sykkel = 'M5.5 17.5a3 3 0 1 0 0-.1M18.5 17.5a3 3 0 1 0 0-.1M5.5 17.5l3.5-7h5l4.5 7M9 10.5L8 7.5H6M14 10.5l1.5-3H18';
  static const String klokke = 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2';
  static const String pin = 'M12 21s-6.5-6-6.5-11a6.5 6.5 0 0 1 13 0c0 5-6.5 11-6.5 11zM12 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z';
  static const String skjold = 'M12 3l7.5 3v5.5c0 4.5-3.2 8.2-7.5 9.5-4.3-1.3-7.5-5-7.5-9.5V6zM9 12l2 2 4-4';
  static const String bok = 'M5 4h10a4 4 0 0 1 4 4v12H9a4 4 0 0 1-4-4zM5 16a4 4 0 0 1 4-4h10';
  static const String hist = 'M3 12a9 9 0 1 0 3-6.7M3 4v4h4M12 8v4l3 2';
  static const String person = 'M12 11.5a3.8 3.8 0 1 0 0-7.6 3.8 3.8 0 0 0 0 7.6zM4.5 20c1.3-3.8 4-5.6 7.5-5.6s6.2 1.8 7.5 5.6';
  static const String lommebok = 'M4 7h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4zM4 7l11-3v3M16 13.5h.01';
  static const String kal = 'M4 6h16v14H4zM4 10h16M8 3v4M16 3v4';
  static const String kort = 'M3 6h18v12H3zM3 10h18M7 15h4';
  static const String hjerte = 'M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z';
  static const String kobling = 'M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1';
  static const String oppdater = 'M3 12a9 9 0 1 0 3-6.7M3 4v4h4';
  static const String sok = 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20.5 20.5l-4.3-4.3';
  static const String kryss = 'M6 6l12 12M18 6L6 18';
  static const String advarsel = 'M12 4l9 16H3zM12 10v4M12 17h.01';
  static const String hus = 'M3 11l9-7 9 7M5 10v10h14V10M10 20v-6h4v6';
  static const String hake = 'M4.5 12.5l5 5 10-11';
  static const String pil = 'M9 6l6 6-6 6';
  static const String kopier = 'M8 8h11v11H8zM5 16V5h11';
  static const String qr = 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h2v2h-2zM18 14h2v2h-2zM14 18h2v2h-2zM18 18h2v2h-2z';
  static const String mobil = 'M7 3h10a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM11 18h2';
  static const String lyn = 'M13 2L4 14h7l-1 8 9-12h-7z';
  static const String bjelle = 'M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15zM10 20a2 2 0 0 0 4 0';
  static const String laas = 'M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4';
  static const String ut = 'M10 7H5v12h5M15 16l4-4-4-4M19 12H9';
  static const String pluss = 'M12 5v14M5 12h14';
  static const String minus = 'M5 12h14';
}

/// The assistant mark (design `aiM`): a logo for Claude and ChatGPT, a
/// drawn mark for Gemini (gold) and Siri (violet), initials for the rest.
class AiMerke extends StatelessWidget {
  const AiMerke(this.navn, {super.key, this.size = 36, this.radius});

  final String navn;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? size * .33);
    final (bg, ink, tx, rot) = switch (navn) {
      'Claude' => (const [Color(0xFFFFFFFF), Color(0xFFF7F1E6), Color(0xFFEADFCB)], const Color(0xFFC2603F), 'Cl', 0.0),
      'ChatGPT' => (const [Color(0xFFFFFFFF), Color(0xFFF2F4F4), Color(0xFFDDE3E4)], const Color(0xFF0D0D0D), 'Ch', 0.0),
      'Gemini' => (const [Color(0xFFFFF0C2), Color(0xFFF2C14E), Color(0xFFE0A93A)], const Color(0xFF4A3308), 'Ge', -3.0),
      'Siri' => (const [Color(0xFFEEE7FB), Color(0xFFC7B8E8), Color(0xFFA996D9)], const Color(0xFF3A2E5C), 'Si', 4.0),
      _ => (const [Color(0xFFFFFFFF), Color(0xFFDCE9EC), Color(0xFFDCE9EC)], const Color(0xFF1E4F5C), '', 0.0),
    };
    final logo = switch (navn) { 'Claude' => 'assets/images/ai/claude.png', 'ChatGPT' => 'assets/images/ai/chatgpt.png', _ => null };
    return Transform.rotate(
      angle: rot * 3.14159 / 180,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: bg, stops: const [0, .62, 1]),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 255, 255, .55), offset: Offset(0, 1)), BoxShadow(color: Color.fromRGBO(4, 18, 26, .55), offset: Offset(0, 8), blurRadius: 14 / 2 / .57735, spreadRadius: -7)],
        ),
        alignment: Alignment.center,
        child: logo != null
            ? Padding(padding: EdgeInsets.all(size * .18), child: Image.asset(logo, fit: BoxFit.contain))
            : Text(tx.isEmpty ? (navn.isEmpty ? 'Æ' : navn.substring(0, navn.length < 2 ? 1 : 2)) : tx, style: jakarta(size * .4, weight: FontWeight.w800, color: ink)),
      ),
    );
  }
}

/// The handshake header (design `aiHs`): Ærend — the link — the assistant,
/// in `kobler` (dots travelling), `koblet` (the snap), `brutt` (the tear) or
/// `ukoblet` (a question mark), with its line.
class AiHandshake extends StatelessWidget {
  const AiHandshake({super.key, required this.modus, required this.navn, required this.linje, this.merkeTx});

  /// `kobler` | `koblet` | `brutt` | `ukoblet`
  final String modus;
  final String navn;
  final String linje;

  /// A number instead of the mark («Koble fra alle»: how many).
  final String? merkeTx;

  @override
  Widget build(BuildContext context) {
    final koblet = modus == 'koblet';
    final brutt = modus == 'brutt';
    final linjeC = koblet ? const Color(0xFF7FF0CB) : (brutt ? const Color(0xFFFFC8A8) : (modus == 'kobler' ? Colors.white : const Color.fromRGBO(255, 255, 255, .75)));
    final glod = brutt ? const Color.fromRGBO(242, 109, 61, .22) : (modus == 'ukoblet' ? const Color.fromRGBO(255, 255, 255, .1) : const Color.fromRGBO(92, 224, 184, .26));
    return Column(
      key: Key('cus-ai-hs-$modus'),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .04)]),
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
            boxShadow: [BoxShadow(color: glod, blurRadius: 36 / 2 / .57735, spreadRadius: -6)],
          ),
          child: Row(
            children: [
              Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 44, height: 44, alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF58A55), Color(0xFFE95C2C)])),
                  child: Text('Æ', style: jakarta(20, weight: FontWeight.w800, color: const Color(0xFF23201D))),
                ),
                const SizedBox(height: 6),
                Text('Ærend', style: inter(11, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .8))),
              ]),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: switch (modus) {
                      'koblet' => AeOnce(kind: AeInn.stigOpp, ms: 700, child: Row(mainAxisSize: MainAxisSize.min, children: [_strek(const Color(0xFF7FF0CB)), _node(const Color(0xFF5CE0B8), AiIk.kobling, const Color(0xFF0F2B33)), _strek(const Color(0xFF7FF0CB))])),
                      'brutt' => Row(mainAxisSize: MainAxisSize.min, children: [_strek(const Color(0xFFFFC8A8)), const SizedBox(width: 6), _node(const Color.fromRGBO(242, 109, 61, .9), AiIk.kryss, Colors.white), const SizedBox(width: 6), _strek(const Color(0xFFFFC8A8))]),
                      'ukoblet' => Row(mainAxisSize: MainAxisSize.min, children: [_strek(const Color.fromRGBO(255, 255, 255, .3)), Container(width: 26, height: 26, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .12)), child: Text('?', style: inter(13, weight: FontWeight.w800))), _strek(const Color.fromRGBO(255, 255, 255, .3))]),
                      _ => const _Prikker(),
                    },
                  ),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (merkeTx != null)
                  Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFDCE9EC)])), child: Text(merkeTx!, style: jakarta(18, weight: FontWeight.w800, color: const Color(0xFF1E4F5C))))
                else
                  AiMerke(navn, size: 44),
                const SizedBox(height: 6),
                Text(navn, style: inter(11, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .8))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: linjeC, boxShadow: [BoxShadow(color: linjeC.withValues(alpha: .8), blurRadius: 8 / 2 / .57735)])),
          const SizedBox(width: 7),
          Flexible(child: Text(linje, key: const Key('cus-ai-hs-linje'), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w800, color: linjeC))),
        ]),
        const SizedBox(height: 12),
      ],
    );
  }

  static Widget _strek(Color c) => Container(width: 22, height: 2, color: c);

  static Widget _node(Color bg, String d, Color ink) => Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: bg), child: AeIkon(d, size: 13, stroke: 2.4, color: ink));
}

/// Three dots travelling Ærend → the assistant (`kobler`).
class _Prikker extends StatefulWidget {
  const _Prikker();

  @override
  State<_Prikker> createState() => _PrikkerState();
}

class _PrikkerState extends State<_Prikker> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Opacity(
            opacity: (0.3 + 0.7 * ((1 - ((_c.value - i * .22) % 1.0 - .5).abs() * 2).clamp(0.0, 1.0))),
            child: Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 5), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7FF0CB))),
          ),
      ],
    ),
  );
}

/// A section head inside the dark sheets: the mint dot and capitals, with an optional right text.
class AiSeksjon extends StatelessWidget {
  const AiSeksjon(this.navn, {super.key, this.hoyre});

  final String navn;
  final String? hoyre;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
    child: Row(
      children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8), boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .8), blurRadius: 8 / 2 / .57735)])),
        const SizedBox(width: 7),
        Expanded(child: Text(navn.toUpperCase(), style: inter(11, weight: FontWeight.w800, em: .1, color: const Color(0xFF7FF0CB)))),
        if (hoyre != null) Text(hoyre!, style: inter(12, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7))),
      ],
    ),
  );
}

/// A glass pill with a stroked icon and a line (the privacy lists, the flow rows, the «Koble fra» facts).
class AiLinjeRad extends StatelessWidget {
  const AiLinjeRad({super.key, required this.ikon, required this.tekst, this.farge = const Color(0xFF7FF0CB), this.delayMs = 0});

  final String ikon;
  final String tekst;
  final Color farge;
  final double delayMs;

  @override
  Widget build(BuildContext context) => AeOnce(
    kind: AeInn.stigOpp,
    ms: 420,
    delay: delayMs,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16))), child: AeIkon(ikon, size: 14, stroke: 2.2, color: farge)),
        const SizedBox(width: 10),
        Expanded(child: Text(tekst, style: inter(13, weight: FontWeight.w700, height: 1.35))),
      ]),
    ),
  );
}

/// The dark glass card the sheets use for groups.
class AiKort extends StatelessWidget {
  const AiKort({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.mint = false});

  final Widget child;
  final EdgeInsets padding;
  final bool mint;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: mint ? const [Color.fromRGBO(92, 224, 184, .18), Color.fromRGBO(92, 224, 184, .05)] : const [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .04)]),
      border: Border.all(color: mint ? const Color.fromRGBO(127, 240, 203, .45) : const Color.fromRGBO(255, 255, 255, .14)),
    ),
    child: child,
  );
}

/// The mint / amber / red banner inside «Tilbudet ditt» (design `aiBanner`).
class AiBanner extends StatelessWidget {
  const AiBanner({super.key, required this.tone, required this.tittel, required this.tekst, required this.ikon});

  /// `gul` | `rod` | `graa`
  final String tone;
  final String tittel;
  final String tekst;
  final String ikon;

  @override
  Widget build(BuildContext context) {
    final (bg, bd, c) = switch (tone) {
      'gul' => (const Color.fromRGBO(245, 196, 81, .14), const Color.fromRGBO(245, 196, 81, .5), const Color(0xFFFFE08A)),
      'rod' => (const Color.fromRGBO(242, 109, 61, .16), const Color.fromRGBO(249, 162, 115, .55), const Color(0xFFFFC8A8)),
      _ => (const Color.fromRGBO(255, 255, 255, .1), const Color.fromRGBO(255, 255, 255, .22), Colors.white),
    };
    return AeOnce(
      kind: AeInn.stigOpp,
      ms: 450,
      child: Container(
        key: Key('cus-ai-banner-$tone'),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: bg, border: Border.all(color: bd)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AeIkon(ikon, size: 18, stroke: 2.2, color: c),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tittel, style: inter(13.5, weight: FontWeight.w800, color: c)),
            const SizedBox(height: 2),
            Text(tekst, style: inter(12, weight: FontWeight.w600, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .8))),
          ])),
        ]),
      ),
    );
  }
}

/// «Via {AI}» (design `aiKilde` chip): the mark and the name on a teal pill.
class AiViaChip extends StatelessWidget {
  const AiViaChip(this.navn, {super.key, this.lys = false});

  final String navn;

  /// On a light surface (Ordrer cards on the light list) the pill is teal; on dark it is glass.
  final bool lys;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('cus-ai-via-${AiNavn.vendor(navn)}'),
    padding: const EdgeInsets.fromLTRB(5, 3, 9, 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: lys ? const Color(0xFF1E4F5C) : const Color.fromRGBO(255, 255, 255, .1),
      border: Border.all(color: lys ? const Color(0xFF1E4F5C) : const Color.fromRGBO(255, 255, 255, .22)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      AiMerke(navn, size: 16, radius: 5),
      const SizedBox(width: 6),
      Text(AiCopy.cus_ai_via(navn), style: inter(11, weight: FontWeight.w800, color: Colors.white)),
    ]),
  );
}

/// «i dag 17:40», «12. oktober», «nå».
String aiTid(DateTime? t, {DateTime? naa}) {
  if (t == null) return AiCopy.cus_ai_aldri;
  final n = naa ?? DateTime.now();
  final d = n.difference(t);
  if (d.inMinutes < 2 && d.inMinutes >= 0) return AiCopy.cus_ai_naa;
  final kl = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  if (t.year == n.year && t.month == n.month && t.day == n.day) return '${AiCopy.cus_ai_i_dag} $kl';
  const m = ['januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'];
  return '${t.day}. ${m[t.month - 1]} $kl';
}

/// «12. oktober» (no time).
String aiDato(DateTime? t) {
  if (t == null) return '';
  const m = ['januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'];
  return '${t.day}. ${m[t.month - 1]}';
}
