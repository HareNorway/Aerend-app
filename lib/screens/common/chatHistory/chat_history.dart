import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

import '../../../commonView/no_record_found.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../chatting/chatting.dart';
import 'chat_history_bloc.dart';
import 'chat_history_dl.dart';
import 'chat_history_shimmer.dart';
import 'item_chat_history.dart';

/// «Meldinger» — `.tk-head` header over a lavender page of chat cards
/// (design card language). Message bubbles are out of scope.
class ChatHistory extends StatelessWidget {
  const ChatHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = ChatHistoryBloc();
    return Scaffold(
      backgroundColor: context.dugnadTheme.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: languages.liveChat,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(child: _list(context, bloc)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, ChatHistoryBloc bloc) {
    return StreamBuilder(
      stream: bloc.getChatHistory().onValue,
      builder: (context, snap) {
        const shimmer = ChatHistoryShimmer(enabled: true);
        if (snap.connectionState == ConnectionState.waiting) {
          return shimmer;
        }

        if (snap.hasData && !snap.hasError && snap.data != null) {
          final event = snap.data as DatabaseEvent;
          // When there is no chat history yet, snapshot.value is null.
          if (event.snapshot.value == null) {
            return NoRecordFound(
              image: "assets/svgs/empty_chat.svg",
              message: languages.chatHistoryEmpty,
            );
          }

          return FirebaseAnimatedList(
            query: bloc.getChatHistory(),
            reverse: true,
            shrinkWrap: true,
            // .ae-body { padding: 0 18px 120px } — rows carry their own 12 gap.
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
            sort: (DataSnapshot a, DataSnapshot b) {
              Map<String, dynamic> resultA =
                  Map<String, dynamic>.from(a.value as Map<dynamic, dynamic>);
              Map<String, dynamic> resultB =
                  Map<String, dynamic>.from(b.value as Map<dynamic, dynamic>);
              return resultA[ChatConstant.userDateTime]
                  .compareTo(resultB[ChatConstant.userDateTime]);
            },
            defaultChild: shimmer,
            itemBuilder: (BuildContext context, DataSnapshot snapshot,
                Animation<double> animation, int index) {
              ModelChatList modelChatList =
                  ModelChatList.fromSnapshot(snapshot);
              return GestureDetector(
                onTap: () {
                  openScreen(
                      context,
                      Chatting(
                        chatWithId: modelChatList.userId,
                        chatWithImage: modelChatList.userProfile,
                        chatWithName: modelChatList.userName,
                        chatWithServicesName: modelChatList.userServicesName,
                        chatWithUserType: modelChatList.userType,
                      ));
                },
                child: SizeTransition(
                  sizeFactor: animation,
                  child: ItemChatHistory(
                    modelChatList: modelChatList,
                    bloc: bloc,
                    snapshot: snapshot,
                  ),
                ),
              );
            },
          );
        }

        return NoRecordFound(
          image: "assets/svgs/empty_chat.svg",
          message: languages.chatHistoryEmpty,
        );
      },
    );
  }
}
