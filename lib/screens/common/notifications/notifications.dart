import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../commonView/no_record_found.dart';
import '../../../networking/api_response.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../account/settings_design_kit.dart';
import 'item_notifications.dart';
import 'notifications_bloc.dart';
import 'notifications_dl.dart';
import 'notifications_shimmer.dart';

/// «Varsler» — `.tk-head` header over a lavender page of notification cards
/// (design card language, 12px gaps, `.ae-body` padding).
class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  late NotificationsBloc _bloc;

  @override
  void initState() {
    notificationState = this;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _bloc = NotificationsBloc(context, this);
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
      backgroundColor: kDgPageBackground,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: languages.notifications,
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(child: notificationsList()),
            ],
          ),
        ),
      ),
    );
  }

  notificationsList() {
    return StreamBuilder<ApiResponse<NotificationsPojo>>(
      stream: _bloc.subject,
      builder: (context, snap) {
        if (snap.hasData) {
          switch (snap.data?.status ?? Status.loading) {
            case Status.loading:
              return const NotificationsShimmer(enabled: true);
            case Status.completed:
              return PagedListView<int, MassNotificationItem>.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                pagingController: _bloc.pagingController,
                // .ae-body { padding: 0 18px 120px }
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                builderDelegate:
                    PagedChildBuilderDelegate<MassNotificationItem>(
                  itemBuilder: (context, item, index) =>
                      ItemNotifications(massNotificationItem: item),
                  newPageProgressIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Center(
                      child: CommonCircularProgressIndicator(
                        strokeWidth: 2,
                        size: 22,
                        color: ScSaasThemeTokens.primary,
                      ),
                    ),
                  ),
                ),
              );
            case Status.error:
              return NoRecordFound(message: snap.data?.message ?? "");
          }
        }

        return const NotificationsShimmer(enabled: true);
      },
    );
  }
}
