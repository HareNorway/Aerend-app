import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/sc_saas_theme.dart';
import 'components/feed_bottom_nav_bar.dart';
import 'components/feed_branded_header.dart';
import 'feedHome/feed_home.dart';
import 'search/feed_search_screen.dart';

class FeedShellScreen extends StatefulWidget {
  const FeedShellScreen({
    super.key,
    this.initialTab = FeedShellTab.home,
  });

  final FeedShellTab initialTab;

  @override
  State<FeedShellScreen> createState() => _FeedShellScreenState();
}

class _FeedShellScreenState extends State<FeedShellScreen> {
  late FeedShellTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  void _selectTab(FeedShellTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  void _stubSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeedBrandedHeader(
              onBackTap: Navigator.canPop(context)
                  ? () => Navigator.of(context).pop()
                  : null,
              onHeartTap: () => _stubSnack(l10n.feed_coming_soon),
              onMessageTap: () => _stubSnack(l10n.feed_coming_soon),
            ),
            Expanded(
              child: IndexedStack(
                index: _activeTab.index,
                children: [
                  FeedHome(
                    embedInShell: true,
                    onExploreTap: () => _selectTab(FeedShellTab.explore),
                  ),
                  const FeedSearchScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
      // Show feed sub-nav only when there are multiple sub-tabs to switch.
      bottomNavigationBar: FeedBottomNavBar(
        activeTab: _activeTab,
        onTabSelected: _selectTab,
      ),
    );
  }
}
