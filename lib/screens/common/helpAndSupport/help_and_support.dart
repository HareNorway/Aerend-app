import 'package:flutter/material.dart';

import '../../../commonView/no_record_found.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/brand_scrub.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../account/settings_design_kit.dart';
import 'contact_us_screen.dart';
import 'help_and_support_bloc.dart';
import 'help_and_support_dl.dart';
import 'help_and_support_shimmer.dart';
import 'support_detail_page.dart';

/// «Hjelp og støtte» — `.tk-head` header, `.dn-addteam` chat card, a `.dgs-list`
/// contact card and a `.dgs-list` of help-article rows (design card language).
class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  late HelpAndSupportBloc _bloc;

  static const String _address = ContactUsScreen.address;
  static const String _phone = ContactUsScreen.phoneDisplay;
  static const String _email = ContactUsScreen.email;

  @override
  void didChangeDependencies() {
    _bloc = HelpAndSupportBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.aeTheme.background,
      body: AeFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: languages.helpSupport,
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Live chat hidden for now — re-enable when support chat ships.
                      // AeRiseIn(
                      //   delay: const Duration(milliseconds: 120),
                      //   child: DnAddCard(
                      //     icon: Icons.chat_bubble_outline_rounded,
                      //     title: languages.liveChat,
                      //     subtitle: 'Chat med kundeservice',
                      //     onTap: () => openScreen(context, const ChatHistory()),
                      //   ),
                      // ),
                      // const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: _contactSection(),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: _articleSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.dg-label` + `.dgs-list` — company, phone and e-mail contact rows.
  Widget _contactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DgLabel('Kontakt oss'), // TODO(l10n)
        DgsList(
          rows: [
            DgsInfoRow(
              leading: _icon(Icons.location_on_outlined),
              title: 'Ai Logistics AS',
              subtitle: _address,
            ),
            DgsInfoRow(
              leading: _icon(Icons.phone_outlined),
              title: 'Telefon', // TODO(l10n)
              subtitle: _phone,
              onTap: () => openUrl('tel:${ContactUsScreen.phoneTel}'),
              trailing: _chevron(),
            ),
            DgsInfoRow(
              leading: _icon(Icons.email_outlined),
              title: 'E-post', // TODO(l10n)
              subtitle: _email,
              onTap: () => openUrl('mailto:$_email'),
              trailing: _chevron(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _icon(IconData icon) =>
      Icon(icon, size: 18, color: context.aeTheme.primaryHover);

  Widget _chevron() => Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: context.aeTheme.primary.withValues(alpha: 0.55),
      );

  /// `.dg-label` + `.dgs-list` — help articles. Bodies are server-rendered HTML,
  /// so a row opens the existing WebView detail page.
  Widget _articleSection() {
    return StreamBuilder<ApiResponse<SupportPojo>>(
      stream: _bloc.subject,
      builder: (context, snap) {
        final isLoading = snap.hasData && snap.data?.status == Status.loading;
        final isError = snap.hasData && snap.data?.status == Status.error;
        // API sometimes returns a page with blank page_name/title — that became
        // the empty last row (icon + chevron, no label). Drop those entries.
        final pageList = (snap.data?.data?.pages ?? <Pages>[])
            .where((p) => _pageLabel(p).isNotEmpty)
            .toList();

        if (isLoading) {
          return const HelpAndSupportShimmer(enabled: true);
        }
        if (isError || pageList.isEmpty) {
          return NoRecordFound(message: snap.data?.message ?? "");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DgLabel('Hjelpeartikler'), // TODO(l10n)
            DgsList(
              rows: pageList
                  .map(
                    (page) {
                      final label = _pageLabel(page);
                      return DgsInfoRow(
                        leading: _icon(
                          _isContactPage(page)
                              ? Icons.mail_outline_rounded
                              : Icons.help_outline_rounded,
                        ),
                        title: label,
                        onTap: () {
                          if (_isContactPage(page)) {
                            openScreen(context, const ContactUsScreen());
                            return;
                          }
                          openScreen(
                            context,
                            SupportDetailPage(
                              title: label,
                              pageDetail: page.description,
                            ),
                          );
                        },
                        trailing: _chevron(),
                      );
                    },
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  /// Prefer display title; fall back to slug-ish page_name.
  String _pageLabel(Pages page) {
    final title = page.pageTitle.trim();
    final raw = title.isNotEmpty ? title : page.pageName.trim();
    return scrubLegacyBrandHtml(raw);
  }

  bool _isContactPage(Pages page) {
    final key =
        '${page.pageName} ${page.pageTitle} ${_pageLabel(page)}'.toLowerCase();
    return key.contains('kontakt') || key.contains('contact');
  }
}
