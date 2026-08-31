import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../networking/api_constant.dart';
import '../../networking/feed/feed_api_constant.dart';
import '../../theme/sc_saas_theme.dart';

class DevEnvScreen extends StatefulWidget {
  const DevEnvScreen({super.key});

  @override
  State<DevEnvScreen> createState() => _DevEnvScreenState();
}

class _DevEnvScreenState extends State<DevEnvScreen> {
  final _customController = TextEditingController();
  final _feedCustomController = TextEditingController();
  String _selected = '';
  String _currentUrl = '';
  String _feedSelected = '';
  String _feedCurrentUrl = '';

  static const _options = {
    'Prod': BaseUrl.prodDomain,
    'Dev tunnel (Vipps webhooks)': BaseUrl.devTunnelDomain,
    'Local (iOS sim)': BaseUrl.localIOS,
    'Local (Android emu)': BaseUrl.localAndroid,
    'Local (LAN)': BaseUrl.localLan,
  };

  static final _feedOptions = {
    'Prod': FeedBaseUrl.prodDomain,
    'Local (iOS sim)': FeedBaseUrl.localIOS,
    'Local (Android emu)': FeedBaseUrl.localAndroid,
    'Local (LAN)': FeedBaseUrl.localLan,
  };

  @override
  void initState() {
    super.initState();
    _currentUrl = BaseUrl.domain;
    _selected = _currentUrl;
    if (!_options.containsValue(_selected)) {
      _customController.text = _selected;
    }
    _feedCurrentUrl = FeedBaseUrl.domain;
    _feedSelected = _feedCurrentUrl;
    if (!_feedOptions.containsValue(_feedSelected)) {
      _feedCustomController.text = _feedSelected;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _feedCustomController.dispose();
    super.dispose();
  }

  Future<void> _applyFeed() async {
    final url = _feedCustomController.text.isNotEmpty
        ? _feedCustomController.text.trim()
        : _feedSelected;

    if (url.isEmpty) return;

    if (url == FeedBaseUrl.prodDomain) {
      FeedBaseUrl.clearOverride();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dev_feed_api_override');
    } else {
      FeedBaseUrl.setOverride(url);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dev_feed_api_override', url);
    }

    setState(() {
      _feedCurrentUrl = FeedBaseUrl.domain;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feed API set to: ${FeedBaseUrl.domain}\nForce-close and reopen the app to apply everywhere.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _apply() async {
    final url = _customController.text.isNotEmpty
        ? _customController.text.trim()
        : _selected;

    if (url.isEmpty) return;

    if (url == BaseUrl.prodDomain) {
      // Clear override — go back to prod
      BaseUrl.clearOverride();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dev_api_override');
    } else {
      // Persist AND update in-memory immediately (synchronous)
      BaseUrl.setOverride(url);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dev_api_override', url);
    }

    setState(() {
      _currentUrl = BaseUrl.domain;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'API set to: ${BaseUrl.domain}\nForce-close and reopen the app to apply everywhere.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dev Environment',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live current URL display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ScSaasThemeTokens.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE API BASE URL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ScSaasThemeTokens.accent,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 4),
                  SelectableText(
                    _currentUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: ScSaasThemeTokens.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preset options
            ..._options.entries.map((e) => RadioListTile<String>(
                  title: Text(e.key,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  subtitle: Text(e.value,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: ScSaasThemeTokens.muted)),
                  value: e.value,
                  groupValue: _selected,
                  activeColor: ScSaasThemeTokens.primary,
                  onChanged: (v) => setState(() {
                    _selected = v!;
                    _customController.clear();
                  }),
                )),
            const SizedBox(height: 12),

            // Custom URL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Dev tunnel: enable anonymous access on the tunnel, or run with '
                '--dart-define=DEV_TUNNEL_CONNECT_TOKEN=... from '
                'devtunnel token <id> --scopes connect. '
                'Easier on a physical phone: use Local (LAN) with '
                'php artisan serve --host=0.0.0.0 --port=8000.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ScSaasThemeTokens.gray500,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customController,
              decoration: InputDecoration(
                labelText: 'Custom URL',
                hintText: 'http://192.168.x.x:8000/',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 28),
            Text(
              'Feed API (apifeed.ailogistics.no)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ScSaasThemeTokens.text,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: ScSaasThemeTokens.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE FEED API BASE URL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ScSaasThemeTokens.accent,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 4),
                  SelectableText(
                    _feedCurrentUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: ScSaasThemeTokens.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ..._feedOptions.entries.map((e) => RadioListTile<String>(
                  title: Text(e.key,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  subtitle: Text(e.value,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: ScSaasThemeTokens.muted)),
                  value: e.value,
                  groupValue: _feedSelected,
                  activeColor: ScSaasThemeTokens.primary,
                  onChanged: (v) => setState(() {
                    _feedSelected = v!;
                    _feedCustomController.clear();
                  }),
                )),
            const SizedBox(height: 12),
            TextField(
              controller: _feedCustomController,
              decoration: InputDecoration(
                labelText: 'Custom Feed URL',
                hintText: 'http://192.168.x.x:3000/',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _feedSelected = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScSaasThemeTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _applyFeed,
                child: Text('Apply Feed API',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScSaasThemeTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _apply,
                child: Text('Apply Laravel API',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
