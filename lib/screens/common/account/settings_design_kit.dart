import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/surface_decorations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../auth/auth_style.dart';

/// Shared Ærend design primitives for the "Innstillinger og støtte" screens
/// (prototype: `dugnad/settings-screens.jsx` + `dugnad/dugnad.css`).
///
/// Every value here is a fixed px from the 375×812 design frame — never scale
/// by device size.

// ---------------------------------------------------------------------------
// Raw tokens that have no `ScSaasThemeTokens` equivalent (CSS wins).
// ---------------------------------------------------------------------------

/// `.dgs-list .row + .row` separator / `--ae-lavender`.
const Color kDgHairline = Color(0xFFF4F0FB);

/// `--ae-gray-400` (`.dgx-city .go`, `.dn-addteam` placeholders).
const Color kDgGray400 = Color(0xFFA9A4BB);

/// `--ae-gray-200` (`.dgs-themes .tm` border).
const Color kDgGray200 = Color(0xFFE2DDF0);

/// `--ae-gray-300` as rendered in `.dr-toggle` (#d5cfe4, not the neutral grey).
const Color kDgToggleTrack = Color(0xFFD5CFE4);

/// `--ae-purple-200` (`.dn-addteam` dashed border).
const Color kDgPurple200 = Color(0xFFD9CEF0);

/// `--ae-purple-300` (`.dgr-code` dashed border).
const Color kDgPurple300 = Color(0xFFC9B8EC);

/// `.dgs-list .row .pts` — earned points pill.
const Color kDgPtsText = Color(0xFF1F8A5B);
const Color kDgPtsBackground = Color(0xFFEAFAF0);

TextStyle dgText(
  double size,
  FontWeight weight, {
  Color? color,
  double? height,
  double? letterSpacingEm,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacingEm != null ? size * letterSpacingEm : null,
    color: color ?? ScSaasThemeTokens.text,
  );
}

// ---------------------------------------------------------------------------
// `.dg-label` — section label above a block.
// ---------------------------------------------------------------------------

/// `.dg-label` — 11/800/0.08em uppercase gray-500, margin 2px 2px 10px.
/// The JSX overrides the bottom margin to 8 on most settings screens.
class DgLabel extends StatelessWidget {
  const DgLabel(this.text, {super.key, this.bottom = 8, this.top = 2});

  final String text;
  final double bottom;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, top, 2, bottom),
      child: Text(
        text.toUpperCase(),
        style: dgText(
          11,
          FontWeight.w800,
          letterSpacingEm: 0.08,
          color: ScSaasThemeTokens.gray500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.dg-info` — light purple info box.
// ---------------------------------------------------------------------------

/// `.dg-info` — purple-100 bg, radius 14, padding 13×14, gap 11.
class DgInfoBox extends StatelessWidget {
  const DgInfoBox({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 17, color: theme.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: dgText(
                12.5,
                FontWeight.w600,
                height: 1.45,
                color: theme.primaryHover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.dgs-list` — white rounded card whose rows are hairline-separated.
// ---------------------------------------------------------------------------

/// `.dgs-list` — #fff, radius 16, padding 2px 16px, `--ae-shadow-card`.
class DgsList extends StatelessWidget {
  const DgsList({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      // `.dgs-list .row + .row { border-top: 1px solid #f4f0fb }`
      if (i > 0) children.add(const _DgsSeparator());
      children.add(rows[i]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _DgsSeparator extends StatelessWidget {
  const _DgsSeparator();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: kDgHairline);
}

/// `.dgs-list .row` in its "pick one" form — `.fl` glyph, `.nm` label and a
/// purple `.ck` check circle when selected.
class DgsChoiceRow extends StatelessWidget {
  const DgsChoiceRow({
    super.key,
    required this.glyph,
    required this.name,
    required this.selected,
    required this.onTap,
    this.glyphIsSymbol = false,
  });

  /// `.fl` content — a flag emoji, or a currency symbol when [glyphIsSymbol].
  final String glyph;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  /// `.fl.sym` — 16/800 purple-700 instead of the 20px emoji.
  final bool glyphIsSymbol;

  @override
  Widget build(BuildContext context) {
    return AuthPressable(
      onTap: onTap,
      builder: (context, pressed) => Padding(
        // .dgs-list .row { padding: 14px 0; gap: 12px }
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                glyph,
                textAlign: TextAlign.center,
                style: glyphIsSymbol
                    ? dgText(
                        16,
                        FontWeight.w800,
                        height: 1,
                        color: ScSaasThemeTokens.primaryHover,
                      )
                    : const TextStyle(fontSize: 20, height: 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // .row .nm 15/700 → .row.on .nm 15/800
                style: dgText(
                  15,
                  selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 12),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: ScSaasThemeTokens.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `.dgs-list .row.tgl` — `.tx` title/sub block plus an arbitrary trailing
/// widget (toggle, points pill, chevron).
class DgsInfoRow extends StatelessWidget {
  const DgsInfoRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            SizedBox(width: 26, child: Center(child: leading!)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // .row .tx .t — 14.5/800 club text
                Text(
                  title,
                  style: dgText(
                    14.5,
                    FontWeight.w800,
                    color: context.dugnadTheme.text,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    // .row .tx .s — padding-top 2, 12.5/600 lh 1.4 gray-500
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: dgText(
                        12.5,
                        FontWeight.w600,
                        height: 1.4,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    // `.row.tgl { cursor: default }` — only tappable rows get press feedback.
    if (onTap == null) return row;
    return AuthPressable(onTap: onTap, builder: (context, pressed) => row);
  }
}

/// `.dgs-list .row .pts` / `.pts.wait` — points pill on the referred-people list.
class DgsPointsPill extends StatelessWidget {
  const DgsPointsPill({super.key, required this.label, this.waiting = false});

  final String label;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: waiting ? kDgHairline : kDgPtsBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: dgText(
          12.5,
          FontWeight.w800,
          color: waiting ? ScSaasThemeTokens.gray500 : kDgPtsText,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.dr-toggle` — 46×26 pill switch.
// ---------------------------------------------------------------------------

/// `.dr-toggle` — 46×26 track, 20px knob, 3px inset, 160ms transitions.
class DrToggle extends StatelessWidget {
  const DrToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.ease,
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          color: value ? theme.primary : kDgToggleTrack,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 160),
              curve: Curves.ease,
              top: 3,
              left: value ? 23 : 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.text.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.dgs-themes` — three theme preview tiles.
// ---------------------------------------------------------------------------

enum DgThemePreview { light, dark, auto }

/// `.dgs-themes` — flex row, gap 10.
class DgThemePicker extends StatelessWidget {
  const DgThemePicker({
    super.key,
    required this.tiles,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  /// (preview style, label) pairs, in prototype order Lyst / Mørkt / System.
  final List<(DgThemePreview, String)> tiles;
  final DgThemePreview selected;
  final ValueChanged<DgThemePreview> onSelected;

  /// Dark/system are not shipped yet — dim the unavailable tiles.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 10));
      final (preview, label) = tiles[i];
      children.add(
        Expanded(
          child: _DgThemeTile(
            preview: preview,
            label: label,
            selected: selected == preview,
            onTap: () => onSelected(preview),
          ),
        ),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _DgThemeTile extends StatelessWidget {
  const _DgThemeTile({
    required this.preview,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final DgThemePreview preview;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuthPressable(
      onTap: onTap,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1.5,
            color: selected ? ScSaasThemeTokens.primary : kDgGray200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _preview(),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: dgText(13, FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  /// `.dgs-themes .pv` — 46px tall swatch, radius 10.
  Widget _preview() {
    switch (preview) {
      case DgThemePreview.light:
        return Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDgGray200),
            gradient: const LinearGradient(
              // 160deg
              begin: Alignment(-0.34, -1),
              end: Alignment(0.34, 1),
              colors: [Color(0xFFF4F0FB), Color(0xFFFFFFFF)],
            ),
          ),
        );
      case DgThemePreview.dark:
        return Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment(-0.34, -1),
              end: Alignment(0.34, 1),
              colors: [Color(0xFF2D1B5B), Color(0xFF171029)],
            ),
          ),
        );
      case DgThemePreview.auto:
        return Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              // 110deg hard split at 50%
              begin: Alignment(-1, -0.36),
              end: Alignment(1, 0.36),
              colors: [Color(0xFFF4F0FB), Color(0xFFF4F0FB), Color(0xFF2D1B5B)],
              stops: [0, 0.5, 0.5],
            ),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// `.dgr-hero` / `.dgr-code` / `.dgr-redeem` — vervekode blocks.
// ---------------------------------------------------------------------------

/// `.dgr-hero` — shiny-purple gradient card, 52px icon circle, title + sub.
class DgrHero extends StatelessWidget {
  const DgrHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;

  /// `.s` — rich text so the prototype's `<b>` points read bold.
  final List<InlineSpan> subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          // --ae-shiny-purple, 150deg
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [Color(0xFFA98FE0), Color(0xFF7F5FC4), Color(0xFF6B4FA8)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB37F5FC4), // rgba(127,95,196,.7)
            blurRadius: 32,
            offset: Offset(0, 14),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(bottom: 14),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0x33FFFFFF), // rgba(255,255,255,.2)
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: dgText(
              19,
              FontWeight.w800,
              letterSpacingEm: -0.02,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text.rich(
              TextSpan(children: subtitle),
              textAlign: TextAlign.center,
              style: dgText(
                13.5,
                FontWeight.w600,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dgr-code` — dashed white card holding the code plus a Kopier chip.
class DgrCodeRow extends StatelessWidget {
  const DgrCodeRow({
    super.key,
    required this.code,
    required this.copyLabel,
    required this.onCopy,
  });

  final String code;
  final String copyLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: 1.5, color: kDgPurple300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dgText(
                17,
                FontWeight.w800,
                letterSpacingEm: 0.08,
                color: ScSaasThemeTokens.primaryHover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AuthPressable(
            onTap: onCopy,
            builder: (context, pressed) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded,
                      size: 15, color: ScSaasThemeTokens.primaryHover),
                  const SizedBox(width: 6),
                  Text(
                    copyLabel,
                    style: dgText(
                      12.5,
                      FontWeight.w800,
                      color: ScSaasThemeTokens.primaryHover,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.ae-input` — white, radius 14, 1.5px border, 56px tall, purple focus ring.
class DgInput extends StatefulWidget {
  const DgInput({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.letterSpacingEm,
    this.fontWeight = FontWeight.w400,
    this.trailingReserve = 0,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final double? letterSpacingEm;
  final FontWeight fontWeight;

  /// Extra right padding so an overlaid button (`.gpsic`) never covers text.
  final double trailingReserve;
  final bool readOnly;

  @override
  State<DgInput> createState() => _DgInputState();
}

class _DgInputState extends State<DgInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: widget.fontWeight,
      color: ScSaasThemeTokens.ink,
      letterSpacing:
          widget.letterSpacingEm != null ? 15 * widget.letterSpacingEm! : null,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.ease,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: 1.5,
          color: _focused ? ScSaasThemeTokens.primary : Colors.transparent,
        ),
        boxShadow: _focused
            ? const [BoxShadow(color: Color(0x1F7F5FC4), spreadRadius: 4)]
            : null,
      ),
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: TextField(
          controller: widget.controller,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textCapitalization: widget.textCapitalization,
          textAlignVertical: TextAlignVertical.center,
          style: style,
          cursorColor: ScSaasThemeTokens.primary,
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.fromLTRB(
              16.5,
              14,
              16.5 + widget.trailingReserve,
              14,
            ),
            hintText: widget.hint,
            hintStyle: style.copyWith(color: ScSaasThemeTokens.gray500),
          ),
        ),
      ),
    );
  }
}

/// `.dgr-redeem` — input + purple Innløs button, gap 9.
class DgRedeemRow extends StatelessWidget {
  const DgRedeemRow({
    super.key,
    required this.controller,
    required this.hint,
    required this.buttonLabel,
    required this.onSubmit,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final String buttonLabel;

  /// Null disables the button (`.dgr-redeem button:disabled { opacity: .4 }`).
  final VoidCallback? onSubmit;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DgInput(
            controller: controller,
            hint: hint,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.characters,
            letterSpacingEm: 0.06,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 9),
        AuthPressable(
          onTap: onSubmit,
          builder: (context, pressed) => Opacity(
            opacity: onSubmit == null ? 0.4 : 1,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                buttonLabel,
                style: dgText(14, FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// `.dgm-locwrap` — search input with an inset GPS button.
// ---------------------------------------------------------------------------

/// `.dgm-locwrap` — `.ae-input` (padding-right 46) + 32px `.gpsic` at right 8.
class DgLocationSearchField extends StatelessWidget {
  const DgLocationSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onLocate,
    this.locateTooltip,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onLocate;
  final String? locateTooltip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        DgInput(
          controller: controller,
          hint: hint,
          onChanged: onChanged,
          trailingReserve: 46 - 16.5,
        ),
        if (onLocate != null)
          Positioned(
            right: 8,
            child: Semantics(
              button: true,
              label: locateTooltip,
              child: AuthPressable(
                onTap: onLocate,
                builder: (context, pressed) => Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.near_me_outlined,
                    size: 16,
                    color: ScSaasThemeTokens.primaryHover,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// `.dgx-city` — city row card.
// ---------------------------------------------------------------------------

/// `.dgx-city` (+ `.soon`) — pin chip, name, "{area} · {n} klubber",
/// chevron when live, `.soonpill` otherwise.
class DgxCityRow extends StatelessWidget {
  const DgxCityRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.live,
    required this.onTap,
    required this.soonLabel,
  });

  final String name;
  final String subtitle;
  final bool live;
  final VoidCallback onTap;
  final String soonLabel;

  @override
  Widget build(BuildContext context) {
    return AuthPressable(
      onTap: onTap,
      builder: (context, pressed) => Opacity(
        opacity: live ? 1 : 0.62,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 19,
                  color: ScSaasThemeTokens.primaryHover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dgText(15.5, FontWeight.w800),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dgText(
                          12.5,
                          FontWeight.w600,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (live)
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: kDgGray400)
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    soonLabel.toUpperCase(),
                    style: dgText(
                      11,
                      FontWeight.w800,
                      letterSpacingEm: 0.04,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.dgv-burst` — Vipps return success/failure circle.
// ---------------------------------------------------------------------------

/// `.dgv-burst.ok` / `.dgv-burst.bad` — 84px gradient circle, 34px white glyph.
class DgvBurst extends StatelessWidget {
  const DgvBurst({super.key, required this.ok});

  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      margin: const EdgeInsets.only(bottom: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          // 140deg
          begin: const Alignment(-0.64, -1),
          end: const Alignment(0.64, 1),
          colors: ok
              ? const [Color(0xFF22A769), Color(0xFF12734A)]
              : const [Color(0xFFE0645F), Color(0xFFC0433F)],
        ),
        boxShadow: [
          BoxShadow(
            color: ok
                ? const Color(0xB31F8A5B) // rgba(31,138,91,.7)
                : const Color(0xB3D9534F), // rgba(217,83,79,.7)
            blurRadius: 32,
            offset: const Offset(0, 14),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Icon(
        ok ? Icons.check_rounded : Icons.close_rounded,
        size: 34,
        color: Colors.white,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.dn-addteam` — dashed "add / open" call-to-action card.
// ---------------------------------------------------------------------------

/// `.dn-addteam` — dashed purple-200 white card, 42px icon chip, title/sub,
/// gray-300 chevron.
class DnAddCard extends StatelessWidget {
  const DnAddCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return AuthPressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1.5,
            color: Color.alphaBlend(
              theme.primary.withValues(alpha: 0.28),
              Colors.white,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.text.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: theme.primaryHover),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: dgText(
                      14.5,
                      FontWeight.w800,
                      letterSpacingEm: -0.01,
                      color: theme.text,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: dgText(
                        11.5,
                        FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: ScSaasThemeTokens.gray300),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.ae-btn.ae-btn--primary` with a leading icon (gap 10).
// ---------------------------------------------------------------------------

/// Same geometry/colours as [AuthPrimaryButton], plus the prototype's leading
/// icon. 56px tall, radius 14. Uses club theme in dugnad mode.
class DgPrimaryButton extends StatelessWidget {
  const DgPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final theme = context.dugnadTheme;
    return AuthPressable(
      onTap: disabled ? null : onPressed,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.ease,
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: disabled
              ? theme.primaryDisabled
              : pressed
                  ? theme.primaryHover
                  : theme.primary,
          boxShadow: disabled ? null : theme.shadowButton,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: authButtonTextStyle(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// `.dga-cancel` — plain-text secondary action under a primary button.
// ---------------------------------------------------------------------------

/// `.dga-cancel` — full-width text button, margin-top 10, 14.5/700 gray-500.
class DgCancelButton extends StatelessWidget {
  const DgCancelButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Center(
            child: Text(
              label,
              style: dgText(
                14.5,
                FontWeight.w700,
                color: ScSaasThemeTokens.gray500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legal / article card (LegalDocScreen language, shared conventions).
// ---------------------------------------------------------------------------

/// White shadow-card body used by the legal documents and article screens.
class DgDocCard extends StatelessWidget {
  const DgDocCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Legal document heading — 17/800/-0.01em club text (`aeH3` scale).
TextStyle dgDocHeading([BuildContext? context]) => dgText(
      17,
      FontWeight.w800,
      height: 1.2,
      letterSpacingEm: -0.01,
      color: context?.dugnadTheme.text,
    );

/// Legal document paragraph — 13.5/600, lh 1.55, gray-700.
TextStyle dgDocBody() => dgText(
      13.5,
      FontWeight.w600,
      height: 1.55,
      color: ScSaasThemeTokens.gray700,
    );

/// Default page background when no [BuildContext] is available.
/// Prefer `context.dugnadTheme.background` on screens.
const Color kDgPageBackground = ScSaasThemeTokens.background;

/// Shiny back-button decoration re-exported so screens don't import the
/// surface helpers directly.
BoxDecoration dgShinyCircle() => AeSurface.shiny(isCircle: true);
