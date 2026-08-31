import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../commonView/custom_text_field.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../chatHistory/chat_history_dl.dart';
import '../splash/splash.dart';
import 'chatting_bloc.dart';
import 'item_chatting.dart';

class Chatting extends StatefulWidget {
  final String chatWithImage, chatWithName, chatWithId, chatWithServicesName;
  final int chatWithUserType;

  const Chatting({
    super.key,
    required this.chatWithId,
    required this.chatWithName,
    required this.chatWithImage,
    required this.chatWithServicesName,
    this.chatWithUserType = -1,
  });

  @override
  ChattingState createState() => ChattingState();
}

class ChattingState extends State<Chatting> {
  late ChattingBloc _bloc;
  String serviceName = '';
  final _controller = ScrollController();

  @override
  void initState() {
    isChatOpen = true;
    chatState = this;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pushNotificationService.clearChatAppBadge();
    });
  }

  @override
  void didChangeDependencies() async {
    isChatOpen = true;
    _bloc = ChattingBloc(
      widget.chatWithId,
      widget.chatWithName,
      widget.chatWithImage,
      widget.chatWithServicesName,
      widget.chatWithUserType,
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    _controller.dispose();
    isChatOpen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        backgroundColor: context.aeTheme.background,
        body: AeFixedTypography(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AccountTkHead(
                  title: languages.liveChat,
                  onBack: () => Navigator.maybePop(context),
                ),
                Expanded(child: _buildChatting()),
              ],
            ),
          ),
        ),
      ),
      onWillPop: () {
        if (!Navigator.canPop(context)) {
          openScreenWithClearPrevious(context, const Splash());
        }
        return Future.value(true);
      },
    );
  }

  scrollToBottom() {
    Timer(
      const Duration(milliseconds: 500),
      () => _controller.animateTo(
        _controller.position.maxScrollExtent + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      ),
    );
  }

  _buildChatting() {
    final theme = context.aeTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: theme.shinyGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: LoadImageWithPlaceHolder(
                  image: widget.chatWithUserType == -1
                      ? ""
                      : widget.chatWithImage,
                  width: 44,
                  height: 44,
                  defaultAssetImage: getChatWithDefaultProfile(
                    widget.chatWithUserType,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatWithUserType == -1
                          ? "Admin"
                          : widget.chatWithName,
                      style: aeTitle(color: Colors.white),
                    ),
                    if (getChatWithService(widget.chatWithUserType).isNotEmpty)
                      Text(
                        getChatWithService(widget.chatWithUserType),
                        style: aeCaption(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        /*Expanded(
            flex: 1,
            child: StreamBuilder(
                stream: _bloc.getChatList().onValue,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.active) {
                    scrollToBottom();
                  }
                  return FirebaseAnimatedList(
                    query: _bloc.getChatList(),
                    reverse: false,
                    shrinkWrap: true,
                    controller: _controller,
                    defaultChild: const ChattingShimmer(
                      enabled: true,
                    ),
                    itemBuilder: (BuildContext context, DataSnapshot snapshot, Animation<double> animation, int index) {
                      ModelChatting modelChatList = ModelChatting.fromSnapshot(snapshot);
                      return SizeTransition(
                        sizeFactor: animation,
                        child: ItemChatting(
                          userId: _bloc.userId,
                          modelChatting: modelChatList,
                        ),
                      );
                    },
                  );
                }),
          ),*/
        Expanded(
          flex: 1,
          child: StreamBuilder<List<ModelChatting>>(
            stream: _bloc.subjectChatList,
            builder: (context, snap) {
              List<ModelChatting> chatList = snap.data ?? [];

              if (chatList.isNotEmpty) {
                _controller.jumpTo(0);
              }

              return ListView.builder(
                controller: _controller,
                itemCount: chatList.length,
                reverse: true,
                itemBuilder: (context, index) {
                  ModelChatting modelChatList = chatList[index];
                  return ItemChatting(
                    userId: _bloc.userId,
                    modelChatting: modelChatList,
                  );
                },
              );
            },
          ),
        ),
        Divider(height: 1, color: ScSaasThemeTokens.gray100),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(child: msgField(_bloc)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _bloc.sendMsg(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ScSaasThemeTokens.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(isRtl() ? pi : 0),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  msgField(ChattingBloc bloc) {
    return TextFormFieldCustom(
      backgroundColor: colorWhite,
      controller: bloc.msgController,
      hint: languages.writeAMessageHere,
      keyboardType: TextInputType.multiline,
      maxLine: 4,
      minLine: 1,
    );
  }
}
