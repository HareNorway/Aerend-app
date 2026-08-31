import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../blocs/bloc.dart';
import '../../commonView/surface_decorations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../commonView/common_circular_progress_indicator.dart';
import '../../utils/utils.dart';
import 'bloc/campaign_list_bloc.dart';
import 'campaign_detail_screen.dart';
import 'campaign_strings.dart';
import 'models/campaign_list_pojo.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  CampaignListBloc? _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CampaignListBloc(context, this);
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      appBar: AppBar(
        backgroundColor: ScSaasThemeTokens.background,
        foregroundColor: ScSaasThemeTokens.text,
        elevation: 0,
        title: Text(CampaignStrings.matkasser, style: aeH2()),
      ),
      body: StreamBuilder<ApiResponse<CampaignListPojo>>(
        stream: _bloc?.campaignsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.status == Status.loading) {
            return Center(
              child: CommonCircularProgressIndicator(
                color: ScSaasThemeTokens.primary,
                size: 36,
                strokeWidth: 3,
              ),
            );
          }
          if (snapshot.hasData && snapshot.data?.status == Status.error) {
            return _buildError(snapshot.data?.message ?? CampaignStrings.somethingWentWrong);
          }
          final campaigns = snapshot.data?.data?.campaigns ?? [];
          if (campaigns.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            color: ScSaasThemeTokens.primary,
            onRefresh: () => _bloc!.refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: campaigns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) =>
                  _buildCampaignCard(campaigns[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(CampaignListItem campaign) {
    String deadlineLabel = '';
    try {
      final deadline = DateTime.parse(campaign.salesWindowEnd);
      deadlineLabel = DateFormat('d. MMM', 'nb_NO').format(deadline);
    } catch (_) {
      deadlineLabel = campaign.salesWindowEnd;
    }

    String distLabel = '';
    try {
      final dist = DateTime.parse(campaign.distributionDate);
      distLabel = DateFormat('d. MMM', 'nb_NO').format(dist);
    } catch (_) {
      distLabel = campaign.distributionDate;
    }

    // Deadline urgency: less than 3 days = urgent
    bool isUrgent = false;
    try {
      final deadline = DateTime.parse(campaign.salesWindowEnd);
      isUrgent = deadline.difference(DateTime.now()).inDays < 3;
    } catch (_) {}

    final displayOrg = [
      if ((campaign.clubName ?? '').trim().isNotEmpty) campaign.clubName!.trim(),
      if ((campaign.teamName ?? '').trim().isNotEmpty) campaign.teamName!.trim(),
    ].join(' · ');
    final displayLogo = (campaign.teamLogoUrl ?? '').isNotEmpty
        ? campaign.teamLogoUrl
        : campaign.logoUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CampaignDetailScreen(
              slug: campaign.slug,
              campaignName: campaign.name,
            ),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: AeSurface.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner with club logo ──
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (campaign.heroImageUrl != null &&
                      campaign.heroImageUrl!.isNotEmpty)
                    Image.network(
                      campaign.heroImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  // Purple gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xE07F5FC4), // primary @ 88%
                          Color(0xC76B4FA8), // primaryHover @ 78%
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Club logo
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: displayLogo != null &&
                                  displayLogo.isNotEmpty
                              ? Image.network(
                                  displayLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: ScSaasThemeTokens.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: ScSaasThemeTokens.primary,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campaign.name,
                                style: aeTitle(color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (displayOrg.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  displayOrg,
                                  style: aeCaption(color: Colors.white70),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Urgency badge
                  if (isUrgent)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ScSaasThemeTokens.warning,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(languages.campaignLastChance,
                            style: aeCaption(color: Colors.white).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                ],
              ),
            ),
            // ── Info section ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club earnings banner
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ScSaasThemeTokens.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.volunteer_activism_rounded,
                            size: 16, color: ScSaasThemeTokens.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            CampaignStrings.clubEarns,
                            style: aeCaption(color: ScSaasThemeTokens.success)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Deadline + delivery pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoPill(Icons.calendar_today_rounded,
                          '${CampaignStrings.orderBefore} $deadlineLabel'),
                      _infoPill(Icons.local_shipping_outlined,
                          '${CampaignStrings.deliveryDay} $distLabel'),
                    ],
                  ),
                  if (campaign.distributionLocation != null &&
                      campaign.distributionLocation!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 14, color: ScSaasThemeTokens.gray500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            campaign.distributionLocation!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aeCaption(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Price + arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${CampaignStrings.from} ${campaign.minPrice.toInt()} kr',
                        style: aeH3(color: ScSaasThemeTokens.primary),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: ScSaasThemeTokens.gray500),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ScSaasThemeTokens.primaryHover),
          const SizedBox(width: 5),
          Text(text,
              style: aeCaption(color: ScSaasThemeTokens.primaryHover)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: ScSaasThemeTokens.gray300),
          const SizedBox(height: 16),
          Text(CampaignStrings.noActiveCampaigns,
              style: aeBody(color: ScSaasThemeTokens.gray500)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: ScSaasThemeTokens.danger),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: aeBody(color: ScSaasThemeTokens.gray500)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _bloc?.refresh(),
            child: Text(CampaignStrings.tryAgain,
                style: aeLabel(color: ScSaasThemeTokens.primary)),
          ),
        ],
      ),
    );
  }
}
