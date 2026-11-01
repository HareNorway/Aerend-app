// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../services/customer/client_flags.dart';
import '../../../utils/utils.dart';
import '../kit/bergen_kit.dart';
import 'meg_ark.dart';

/// Customer v2 Step 6 (spec §4.11): «Fast ukeshandel» in Meg — the own opt-in
/// screen (explicit consent with the versioned wording, delivery day and
/// window, the weekly cap, Vipps agreement or the saved card), the Vipps
/// hand-off and its «Jeg har bekreftet», then the overview with the week's
/// state, «Endre» (the basket until the cut-off), «Pause» / «Fortsett» and
/// «Avslutt» always visible, and the failed-payment state. Behind
/// `cus.aegil.level4`; the backend is Customer v2 Step 5.
abstract final class FastCopy {
  static String get standing_order_title => languages.standing_order_title;
  static String get standing_order_notice => languages.standing_order_notice;
  static String get standing_order_pause => languages.standing_order_pause;
  static String get standing_order_cancel => languages.standing_order_cancel;
  static String get cus_fast_fortsett => languages.cus_fast_fortsett;
  static String get cus_fast_sett_opp => languages.cus_fast_sett_opp;
  static String get cus_fast_start => languages.cus_fast_start;
  static String get cus_fast_dag => languages.cus_fast_dag;
  static String get cus_fast_vindu => languages.cus_fast_vindu;
  static String get cus_fast_tak => languages.cus_fast_tak;
  static String get cus_fast_betaling => languages.cus_fast_betaling;
  static String get cus_fast_vipps => languages.cus_fast_vipps;
  static String get cus_fast_kort => languages.cus_fast_kort;
  static String get cus_fast_samtykke => languages.cus_fast_samtykke;
  static String get cus_fast_samtykke_kreves => languages.cus_fast_samtykke_kreves;
  static String get cus_fast_venter_tittel => languages.cus_fast_venter_tittel;
  static String get cus_fast_venter_linje => languages.cus_fast_venter_linje;
  static String get cus_fast_aapne_vipps => languages.cus_fast_aapne_vipps;
  static String get cus_fast_sjekk => languages.cus_fast_sjekk;
  static String get cus_fast_ikke_aktiv_enna => languages.cus_fast_ikke_aktiv_enna;
  static String get cus_fast_neste => languages.cus_fast_neste;
  static String get cus_fast_neste_ingen => languages.cus_fast_neste_ingen;
  static String get cus_fast_endre => languages.cus_fast_endre;
  static String cus_fast_run_noticed(String total, String cutoff) => languages.cus_fast_run_noticed(total, cutoff);
  static String get cus_fast_run_locked => languages.cus_fast_run_locked;
  static String get cus_fast_run_placed => languages.cus_fast_run_placed;
  static String get cus_fast_run_paid => languages.cus_fast_run_paid;
  static String get cus_fast_run_failed => languages.cus_fast_run_failed;
  static String get cus_fast_run_skipped => languages.cus_fast_run_skipped;
  static String get cus_fast_pauset => languages.cus_fast_pauset;
  static String get cus_fast_betaling_feilet => languages.cus_fast_betaling_feilet;
  static String get cus_fast_avslutt_sporsmal => languages.cus_fast_avslutt_sporsmal;
  static String get cus_fast_avslutt_linje => languages.cus_fast_avslutt_linje;
  static String get cus_fast_avsluttet => languages.cus_fast_avsluttet;
  static String get cus_fast_pauset_toast => languages.cus_fast_pauset_toast;
  static String get cus_fast_fortsatt_toast => languages.cus_fast_fortsatt_toast;
  static String get cus_fast_startet => languages.cus_fast_startet;
  static String get cus_fast_feil => languages.cus_fast_feil;
  static String get cus_fast_avbryt => languages.cus_fast_avbryt;
  static String get cus_fast_ingen_kort => languages.cus_fast_ingen_kort;
  static String get cus_fast_avbryt_oppsett => languages.cus_fast_avbryt_oppsett;
  static String get cus_fast_paa => languages.cus_fast_paa;
  static String get cus_fast_pause_merke => languages.cus_fast_pause_merke;
  static String cus_fast_kr(int kr) => languages.cus_fast_kr(kr);
  static List<String> get dager => languages.cus_fast_dager.split(',');
  static String dag(int iso) => iso >= 1 && iso <= dager.length ? dager[iso - 1] : '';
  static String vindu(String w) => w.replaceAll('-', '–');
}

abstract final class FastUkeshandel {
  /// The wording the customer agrees to (T13 owns the text; the version travels with the opt-in).
  static const String consentVersion = 'app-2026-11';

  static const List<String> vinduer = ['11-14', '14-17', '17-20', '18-21'];
  static const List<int> takKr = [500, 750, 1000, 1500];

  /// Opens Vipps' confirmation page; tests swap it.
  static Future<void> Function(Uri uri) launcher = (uri) async {
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  };

  /// Meg's entry: the overview when a standing order exists, else the opt-in.
  static Future<void> vis(BuildContext context, {required AegilAppApi api, VoidCallback? onKurv, VoidCallback? onEndret}) async {
    final s = await api.standing();
    if (!context.mounted) return;
    if (s == null) {
      await _oppsett(context, api: api, onKurv: onKurv, onEndret: onEndret);
    } else {
      await _oversikt(context, api: api, start: s, onKurv: onKurv, onEndret: onEndret);
    }
  }

  // ── The opt-in (its own screen) ──────────────────────────────────────────

  static Future<void> _oppsett(BuildContext context, {required AegilAppApi api, VoidCallback? onKurv, VoidCallback? onEndret}) {
    var dag = 4;
    var vindu = '17-20';
    var tak = 1000;
    var betaling = 'vipps_recurring';
    var samtykke = false;
    var travelt = false;
    final kort = ClientFlags.on(ClientFlags.aiLinkedCheckout);
    return showMegArk<void>(
      context,
      key: const Key('meg-fast-oppsett'),
      title: FastCopy.standing_order_title,
      subtitle: FastCopy.standing_order_notice,
      body: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegArkRow(
            key: const Key('fast-dag'),
            title: FastCopy.cus_fast_dag,
            value: FastCopy.dag(dag),
            onTap: () async {
              final v = await _velg<int>(ctx, FastCopy.cus_fast_dag, [for (var i = 1; i <= 7; i++) (i, FastCopy.dag(i))], dag);
              if (v != null && ctx.mounted) setState(() => dag = v);
            },
          ),
          MegArkRow(
            key: const Key('fast-vindu'),
            title: FastCopy.cus_fast_vindu,
            value: FastCopy.vindu(vindu),
            onTap: () async {
              final v = await _velg<String>(ctx, FastCopy.cus_fast_vindu, [for (final w in vinduer) (w, FastCopy.vindu(w))], vindu);
              if (v != null && ctx.mounted) setState(() => vindu = v);
            },
          ),
          MegArkRow(
            key: const Key('fast-tak'),
            title: FastCopy.cus_fast_tak,
            value: FastCopy.cus_fast_kr(tak),
            onTap: () async {
              final v = await _velg<int>(ctx, FastCopy.cus_fast_tak, [for (final k in takKr) (k, FastCopy.cus_fast_kr(k))], tak);
              if (v != null && ctx.mounted) setState(() => tak = v);
            },
          ),
          MegArkRow(
            key: const Key('fast-betaling'),
            title: FastCopy.cus_fast_betaling,
            value: betaling == 'card' ? FastCopy.cus_fast_kort : FastCopy.cus_fast_vipps,
            onTap: !kort
                ? null
                : () async {
                    final v = await _velg<String>(ctx, FastCopy.cus_fast_betaling, [('vipps_recurring', FastCopy.cus_fast_vipps), ('card', FastCopy.cus_fast_kort)], betaling);
                    if (v != null && ctx.mounted) setState(() => betaling = v);
                  },
          ),
          const SizedBox(height: 6),
          MegArkRow(
            key: const Key('fast-samtykke'),
            title: FastCopy.cus_fast_samtykke,
            selected: samtykke,
            trailing: Icon(samtykke ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: samtykke ? MegArkInk.teal : MegArkInk.faint),
            onTap: () => setState(() => samtykke = !samtykke),
          ),
        ],
      ),
      primaryBuilder: (ctx) => MegArkButton(
        key: const Key('fast-start'),
        label: FastCopy.cus_fast_start,
        av: !samtykke,
        onTap: () async {
          if (!samtykke) {
            showBergenToast(ctx, FastCopy.cus_fast_samtykke_kreves);
            return;
          }
          if (travelt) return;
          travelt = true;
          final r = await api.standingCreate(scheduleDow: dag, window: vindu, capKr: tak, paymentMethod: betaling, consentVersion: consentVersion);
          travelt = false;
          if (!ctx.mounted) return;
          final s = r.standing;
          if (s == null) {
            showBergenToast(ctx, r.feil == 'NO_SAVED_CARD' ? FastCopy.cus_fast_ingen_kort : (r.feil ?? FastCopy.cus_fast_feil), icon: Icons.error_outline_rounded);
            return;
          }
          onEndret?.call();
          Navigator.of(ctx).pop();
          if (!context.mounted) return;
          if (s.pending) {
            final url = r.confirmationUrl ?? s.confirmationUrl;
            if (url != null) await launcher(Uri.parse(url));
            if (context.mounted) await _venter(context, api: api, start: s, onKurv: onKurv, onEndret: onEndret);
          } else {
            showBergenToast(context, FastCopy.cus_fast_startet, icon: Icons.check_rounded);
            await _oversikt(context, api: api, start: s, onKurv: onKurv, onEndret: onEndret);
          }
        },
      ),
    );
  }

  static Future<T?> _velg<T>(BuildContext context, String title, List<(T, String)> valg, T current) => showMegArk<T>(
        context,
        key: const Key('meg-fast-velg'),
        title: title,
        body: (ctx, _) => Column(
          children: [for (final (v, label) in valg) MegArkRow(key: Key('fast-velg-$v'), title: label, selected: v == current, onTap: () => Navigator.of(ctx).pop(v))],
        ),
      );

  // ── Waiting for Vipps ────────────────────────────────────────────────────

  static Future<void> _venter(BuildContext context, {required AegilAppApi api, required StandingView start, VoidCallback? onKurv, VoidCallback? onEndret}) {
    return showMegArk<void>(
      context,
      key: const Key('meg-fast-venter'),
      title: FastCopy.cus_fast_venter_tittel,
      subtitle: FastCopy.cus_fast_venter_linje,
      body: (ctx, _) => Column(children: [
        MegArkRow(key: const Key('fast-avbryt-oppsett'), title: FastCopy.cus_fast_avbryt_oppsett, onTap: () async {
          final r = await api.standingEnd();
          if (!ctx.mounted) return;
          if (r.feil != null) return showBergenToast(ctx, r.feil!);
          onEndret?.call();
          Navigator.of(ctx).pop();
        }),
      ]),
      secondary: MegArkButton(
        key: const Key('fast-aapne-vipps'),
        label: FastCopy.cus_fast_aapne_vipps,
        onTap: () {
          final url = start.confirmationUrl;
          if (url != null) launcher(Uri.parse(url));
        },
      ),
      primary: MegArkButton(
        key: const Key('fast-sjekk'),
        label: FastCopy.cus_fast_sjekk,
        onTap: () async {
          final s = await api.standingSync();
          if (!context.mounted) return;
          if (s == null || !s.active) {
            showBergenToast(context, FastCopy.cus_fast_ikke_aktiv_enna);
            return;
          }
          onEndret?.call();
          Navigator.of(context).pop();
          showBergenToast(context, FastCopy.cus_fast_startet, icon: Icons.check_rounded);
          await _oversikt(context, api: api, start: s, onKurv: onKurv, onEndret: onEndret);
        },
      ),
    );
  }

  // ── The overview ─────────────────────────────────────────────────────────

  static String runLine(StandingView s) {
    final r = s.run;
    if (r == null) return FastCopy.cus_fast_neste_ingen;
    return switch (r.state) {
      'noticed' => FastCopy.cus_fast_run_noticed(r.total, s.nextCutoffLine),
      'locked' => FastCopy.cus_fast_run_locked,
      'placed' => FastCopy.cus_fast_run_placed,
      'paid' => FastCopy.cus_fast_run_paid,
      'failed' => FastCopy.cus_fast_run_failed,
      'skipped' => FastCopy.cus_fast_run_skipped,
      _ => FastCopy.cus_fast_neste_ingen,
    };
  }

  static Future<void> _oversikt(BuildContext context, {required AegilAppApi api, required StandingView start, VoidCallback? onKurv, VoidCallback? onEndret}) {
    var s = start;
    return showMegArk<void>(
      context,
      key: const Key('meg-fast-oversikt'),
      title: FastCopy.standing_order_title,
      subtitleBuilder: () => s.paused ? (s.paymentFailed ? FastCopy.cus_fast_betaling_feilet : FastCopy.cus_fast_pauset) : (s.pending ? FastCopy.cus_fast_venter_linje : s.line),
      body: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.paymentFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(FastCopy.cus_fast_betaling_feilet, key: const Key('fast-betaling-feilet'), style: BergenTokens.text(12.5, weight: FontWeight.w700, color: const Color(0xFFB4452B), height: 1.35)),
            ),
          MegArkRow(
            key: const Key('fast-neste'),
            title: FastCopy.cus_fast_neste,
            sub: runLine(s),
            value: s.run?.state == 'noticed' && !s.paused ? FastCopy.cus_fast_endre : null,
            onTap: s.run?.state == 'noticed' && !s.paused && onKurv != null
                ? () {
                    Navigator.of(ctx).pop();
                    onKurv();
                  }
                : null,
          ),
          MegArkRow(key: const Key('fast-levering'), title: FastCopy.cus_fast_dag, value: '${s.scheduleDay} ${FastCopy.vindu(s.window)}'),
          MegArkRow(key: const Key('fast-tak-rad'), title: FastCopy.cus_fast_tak, value: s.cap),
          MegArkRow(key: const Key('fast-betaling-rad'), title: FastCopy.cus_fast_betaling, value: s.paymentMethod == 'card' ? FastCopy.cus_fast_kort : FastCopy.cus_fast_vipps),
          if (s.pending)
            MegArkRow(
              key: const Key('fast-aapne-vipps-rad'),
              title: FastCopy.cus_fast_aapne_vipps,
              onTap: () {
                final url = s.confirmationUrl;
                if (url != null) launcher(Uri.parse(url));
              },
            ),
        ],
      ),
      secondary: MegArkButton(
        key: const Key('fast-avslutt'),
        label: FastCopy.standing_order_cancel,
        rod: true,
        onTap: () async {
          final ja = await showDialog<bool>(
            context: context,
            builder: (d) => AlertDialog(
              title: Text(FastCopy.cus_fast_avslutt_sporsmal),
              content: Text(FastCopy.cus_fast_avslutt_linje),
              actions: [
                TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(FastCopy.cus_fast_avbryt)),
                TextButton(key: const Key('fast-avslutt-ja'), onPressed: () => Navigator.of(d).pop(true), child: Text(FastCopy.standing_order_cancel)),
              ],
            ),
          );
          if (ja != true || !context.mounted) return;
          final r = await api.standingEnd();
          if (!context.mounted) return;
          if (r.feil != null) return showBergenToast(context, r.feil!, icon: Icons.error_outline_rounded);
          onEndret?.call();
          Navigator.of(context).pop();
          showBergenToast(context, FastCopy.cus_fast_avsluttet);
        },
      ),
      primaryBuilder: (ctx) => s.pending
          ? MegArkButton(
              key: const Key('fast-sjekk'),
              label: FastCopy.cus_fast_sjekk,
              onTap: () async {
                final ny = await api.standingSync();
                if (!ctx.mounted) return;
                if (ny == null || !ny.active) return showBergenToast(ctx, FastCopy.cus_fast_ikke_aktiv_enna);
                onEndret?.call();
                showBergenToast(ctx, FastCopy.cus_fast_startet, icon: Icons.check_rounded);
                Navigator.of(ctx).pop();
                if (context.mounted) _oversikt(context, api: api, start: ny, onKurv: onKurv, onEndret: onEndret);
              },
            )
          : MegArkButton(
              key: Key(s.paused ? 'fast-fortsett' : 'fast-pause'),
              label: s.paused ? FastCopy.cus_fast_fortsett : FastCopy.standing_order_pause,
              onTap: () async {
                final r = s.paused ? await api.standingResume() : await api.standingPause();
                if (!ctx.mounted) return;
                if (r.standing == null) return showBergenToast(ctx, r.feil ?? FastCopy.cus_fast_feil, icon: Icons.error_outline_rounded);
                onEndret?.call();
                showBergenToast(ctx, s.paused ? FastCopy.cus_fast_fortsatt_toast : FastCopy.cus_fast_pauset_toast);
                // Redraw with the new state: close and reopen.
                Navigator.of(ctx).pop();
                if (context.mounted) _oversikt(context, api: api, start: r.standing!, onKurv: onKurv, onEndret: onEndret);
              },
            ),
    );
  }
}
