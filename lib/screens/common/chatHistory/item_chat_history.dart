import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../account/settings_design_kit.dart';
import 'chat_history_bloc.dart';
import 'chat_history_dl.dart';

/// Chat list row in the design's card language — white shadow-card
/// (radius 16, padding 14, gap 12), `.dgs-list .row .tx` type scale.
class ItemChatHistory extends StatelessWidget {
  final ModelChatList modelChatList;
  final ChatHistoryBloc bloc;
  final DataSnapshot snapshot;

  const ItemChatHistory({
    super.key,
    required this.modelChatList,
    required this.bloc,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final rawTime = getChatDateTime(modelChatList.lastMsgTime);
    final time = rawTime.trim().isNotEmpty
        ? getChatDateTime(modelChatList.lastMsgTime, format: "hh:mm aa")
        : modelChatList.lastMsgTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        children: [
          LoadImageWithPlaceHolder(
            image: modelChatList.userType == -1 ? "" : modelChatList.userProfile,
            width: 44,
            height: 44,
            defaultAssetImage: getChatWithDefaultProfile(
              modelChatList.userType,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelChatList.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dgText(14.5, FontWeight.w800),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    modelChatList.lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: dgText(11, FontWeight.w700, color: kDgGray400),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => bloc.deleteChatHistory(snapshot.key ?? ""),
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.primaryHover,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
