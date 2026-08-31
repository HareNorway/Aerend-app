import 'package:flutter/material.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../chatHistory/chat_history_dl.dart';

class ItemChatting extends StatelessWidget {
  final ModelChatting modelChatting;
  final String userId;

  const ItemChatting({
    super.key,
    required this.userId,
    required this.modelChatting,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSent = userId.trim() == modelChatting.senderId;
    final String timeLabel = getChatDateTime(
      modelChatting.date ?? "",
      format: "MMM d yyyy hh:mm aa",
    );

    return Container(
      alignment: isSent
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSent
                  ? ScSaasThemeTokens.primary
                  : ScSaasThemeTokens.gray50,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isSent ? 18 : 4),
                bottomRight: Radius.circular(isSent ? 4 : 18),
              ),
            ),
            child: Text(
              modelChatting.message ?? "",
              style: aeBody(
                color: isSent ? Colors.white : ScSaasThemeTokens.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(timeLabel, style: aeCaption()),
        ],
      ),
    );
  }
}
