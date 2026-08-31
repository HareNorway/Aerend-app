import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Design-value manifest for `letter-spacing`.
///
/// Every other tracking guard in this repo asks *"is this value converted
/// correctly"* — which cannot see a value that is not there. Two findings came
/// from that blind spot: the rank chip's `-0.02em` and `.scl-sto`'s `+0.01em`
/// were both **absent**, not mis-converted, and every guard passed.
///
/// This inverts the question to *"does this value exist at all"*, which is the
/// only form that catches absence. It is deliberately incomplete: it holds the
/// values already read from the CSS, and each screen adds its own as it is
/// audited. A partial manifest still catches a deletion.
///
/// An entry passes if some `letterSpacing:` expression in the file mentions
/// both the font size and the em value, in either order — the codebase writes
/// both `16 * -0.02` and `-0.025 * 19`.
void main() {
  const manifest = <_Tracked>[
    // ---- Toppliste (gamify.css) --------------------------------------
    _Tracked('.lb-tablehead .ttl', _lb, 19, -0.025),
    _Tracked('.lb-zone-tag', _lb, 10.5, 0.04),
    _Tracked('.lb-trow .pts b', _lb, 16, -0.02),
    _Tracked('.lb-trow .pts small', _lb, 8.5, 0.04),
    _Tracked('.scl-stat b', _lb, 17, -0.02),
    _Tracked('.scl-stat small', _lb, 8.5, 0.04),
    // Table-driven: the size is a variant flag, so the literals never sit
    // in one expression. Matched by its parts instead.
    _Tracked('.scl-sto', _lb, 9.5, 0.01,
        via: ['large ? 10.5 : 9.5', '* 0.01']),
    _Tracked('.mine-tag', _lb, 9, 0.02),
    _Tracked('.scl-divider', _lb, 10.5, 0.04),

    // ---- Dine poeng / home (dugnad.css) ------------------------------
    _Tracked('.lb-level .pts', _pts, 30, -0.03),
    _Tracked('rank chip #N', _pts, 17, -0.02),
    _Tracked('Din plass label', _pts, 8, 0.05),
    _Tracked('STO rating label', _pts, 10.5, 0.08),
    _Tracked('kaptein badge', _pts, 10, 0.04),
    _Tracked('.dg-season-tag', _pts, 10, 0.04),
    _Tracked('points unit suffix', _pts, 12, 0.02),

    // ---- Kampanjer / Matkasse (dugnad.css) ---------------------------
    _Tracked('.mk-camp2-body .club', _mk, 11, 0.03),
    _Tracked('.mk-camp2-body .ttl', _mk, 19, -0.02),
    _Tracked('.mk-pricetag .lbl', _mk, 9, 0.03),
    _Tracked('.mk-pricetag b', _mk, 15, -0.02),

    // ---- Home feed banners -------------------------------------------
    // Also table-driven, and deliberately so — _EntryStyle converts once at
    // the use site for all five variants, which is what rule 3 concluded the
    // seven 10x-under sites were the cost of not doing.
    _Tracked('.lb-entry title', _banner, 16, -0.02,
        via: ['titleSize: 16', 'titleTracking: -0.02']),

    // ---- Del din støtte / share card (gamify.css .dg-share*) ----------
    // The tracking-error cluster that exposed the manifest's coverage hole:
    // every one of these was written 10–20x too wide and none was pinned.
    _Tracked('.sc-eyebrow', _ss, 10, 0.08),
    _Tracked('.sc-team', _ss, 17, -0.02),
    _Tracked('.sc-msg', _ss, 19, -0.02),
    _Tracked('.dg-sharebtn--row .lbl', _ss, 15, -0.01),

    // ---- Synlighet / privacy (gamify.css .vis-*) ---------------------
    _Tracked('.vis-demo .lbl', _priv, 11, 0.03),
    _Tracked('.vis-preview .cap', _priv, 10, 0.06),

    // ---- Screens the >0.1 magnitude sweep corrected ------------------
    // Verified against the CSS while fixing the decimal shifts; pinned here so
    // absence is caught too (the magnitude guard only catches the shift).
    _Tracked('.rc-hero .eyebrow', _recap, 11, 0.08),
    _Tracked('.rc-hero .ttl', _recap, 24, -0.025),
    _Tracked('.rc-stat .v', _recap, 22, -0.03),
    _Tracked('.dg-transfer-opt .t .rec', _transfer, 9.5, 0.04),
    _Tracked('.dg-moveup-card .mu-q', _transfer, 18, -0.02),
    _Tracked('.dg-deadline .dl-t', _transfer, 14.5, -0.01),
    _Tracked('.dn-confirm h2', _confirm, 26, -0.02),
    _Tracked('.lb-prize .eyebrow', _prize, 10.5, 0.09),
  ];

  for (final t in manifest) {
    test('${t.selector} declares ${t.em}em at ${t.size}px', () {
      final src = File(t.file).readAsStringSync();
      final size = _num(t.size);
      final em = _num(t.em);

      final found = t.via != null
          ? t.via!.every(src.contains)
          : RegExp(r'letterSpacing:[^,\n]*')
              .allMatches(src)
              .map((m) => m.group(0)!)
              .any((e) => e.contains(size) && e.contains(em));

      expect(
        found,
        isTrue,
        reason: 'No letterSpacing in ${t.file} derives $em em from $size px.\n'
            'The design gives ${t.selector} `letter-spacing: ${t.em}em` at '
            '${t.size}px. If the style was refactored, update this entry; if '
            'the value was dropped, restore it — absence is invisible to '
            'every other guard here.',
      );
    });
  }
}

/// `16` not `16.0`, `8.5` stays `8.5` — matches how the source is written.
String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

const _lb = 'lib/screens/dugnad/leaderboard_screen.dart';
const _pts = 'lib/screens/dugnad/dugnad_points_widgets.dart';
const _banner = 'lib/screens/dugnad/widgets/dugnad_feed_entry_banner.dart';
const _mk = 'lib/screens/dugnad/widgets/mk_campaign_card.dart';
const _ss = 'lib/screens/dugnad/widgets/dugnad_support_share.dart';
const _priv = 'lib/screens/dugnad/dugnad_privacy_screen.dart';
const _recap = 'lib/screens/dugnad/season_recap_screen.dart';
const _transfer = 'lib/screens/dugnad/transfer_window_screen.dart';
const _confirm = 'lib/screens/dugnad/donation_confirm_screen.dart';
const _prize = 'lib/screens/dugnad/widgets/dugnad_prize_banner.dart';

class _Tracked {
  const _Tracked(this.selector, this.file, this.size, this.em, {this.via});

  final String selector;
  final String file;
  final double size;

  /// CSS `letter-spacing` in em, exactly as authored.
  final double em;

  /// For values assembled from a variant table rather than written as one
  /// expression: every substring here must appear in the file. Being
  /// table-driven is the *preferred* shape, so the manifest accommodates it
  /// rather than pushing values back to per-call-site literals.
  final List<String>? via;
}
