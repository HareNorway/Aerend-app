import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/brand_scrub.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../account/account_widgets.dart';

class SupportDetailPage extends StatelessWidget {
  final String title, pageDetail;

  const SupportDetailPage({
    super.key,
    required this.title,
    required this.pageDetail,
  });

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final isDark = materialTheme.brightness == Brightness.dark;
    final clubTheme = context.dugnadTheme;

    final String html =
        '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      :root {
        --bg-color: ${isDark ? '#0F0F0F' : '#FFFFFF'};
        --text-color: ${isDark ? '#FFFFFF' : '#2D1B5B'};
        --muted-color: ${isDark ? '#B3B3B3' : '#4B4458'};
        --heading-color: ${isDark ? '#FFFFFF' : '#2D1B5B'};
        --accent-color: ${_cssHex(clubTheme.primaryHover)};
        --rule-color: ${isDark ? '#333333' : '#E8E2F4'};
      }
      html, body {
        margin: 0;
        padding: 0;
        background-color: var(--bg-color);
        color: var(--text-color);
        font-family: "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, "Roboto", "Helvetica Neue", sans-serif;
        line-height: 1.55;
        -webkit-text-size-adjust: 100%;
      }
      body {
        padding: 18px 16px 28px 16px;
        box-sizing: border-box;
      }
      h1, h2, h3, h4, h5, h6, strong {
        color: var(--heading-color);
        margin: 18px 0 8px 0;
        font-weight: 700;
      }
      p, li, span, div {
        color: var(--text-color);
        font-size: 15px;
      }
      p {
        margin: 0 0 10px 0;
      }
      small {
        color: var(--muted-color);
      }
      a {
        color: var(--accent-color);
        font-weight: 700;
        text-decoration: none;
      }
      hr, .MsoNormal + div {
        border-color: var(--rule-color);
      }
      ul, ol {
        padding-left: 20px;
        margin: 8px 0;
      }
      table {
        width: 100%;
        border-collapse: collapse;
      }
      th, td {
        border: 1px solid var(--rule-color);
        padding: 8px;
        text-align: left;
      }
      img {
        max-width: 100%;
        height: auto;
      }
    </style>
  </head>
  <body>
    ${_sanitizeHtml(pageDetail)}
  </body>
</html>
''';

    final controller = WebViewController()
      ..loadHtmlString(html)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
    }
    return Scaffold(
      backgroundColor: clubTheme.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: scrubLegacyBrandHtml(title),
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: ScSaasThemeTokens.shadowCard,
                      ),
                      child: WebViewWidget(controller: controller),
                    ),
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

String _cssHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

String _sanitizeHtml(String html) => scrubLegacyBrandHtml(html);
