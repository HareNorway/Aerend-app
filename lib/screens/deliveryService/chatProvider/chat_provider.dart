import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'chat_provider_dl.dart';
import '../../../utils/utils.dart';

class ChatProvider extends StatefulWidget {
  final String providerName;
  const ChatProvider({super.key, required this.providerName});

  @override
  State<ChatProvider> createState() => _ChatProviderState();
}

class _ChatProviderState extends State<ChatProvider> {
  // Status: 0 - sent, 1 - arrived to provider, 2 - read
  List<ChatHistoryListItem> chatHistory = [
    ChatHistoryListItem(
        isProvider: false,
        status: 2,
        spentAt: '13:00',
        content:
            'Hi, I just realized that I forgot to add extra cheese to my burger order. Can you help me with that?'),
    ChatHistoryListItem(
        isProvider: true,
        status: 0,
        spentAt: '13:00',
        content: 'Of course! I can definitely help you with that. '),
    ChatHistoryListItem(
        isProvider: true,
        status: 0,
        spentAt: '13:00',
        content:
            'I have added extra cheese to your burger order. Is there anything else you would like to add or modify?'),
    ChatHistoryListItem(
        isProvider: false,
        status: 1,
        spentAt: '13:00',
        content:
            'Thank you so much for your help! That\'s all I needed to change.'),
    ChatHistoryListItem(
        isProvider: false,
        status: 0,
        spentAt: '13:00',
        content:
            'Hi, I just realized that I forgot to add extra cheese to my burger order'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorPrimary,
      appBar: AppBar(
        backgroundColor: colorMainBackground,
        automaticallyImplyLeading: false,
        foregroundColor: colorBlack,
        toolbarHeight: 80,
        elevation: 0,
        title: Stack(
          children: [
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  widget.providerName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              left: 5,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorWhite,
                    elevation: 1,
                    padding: const EdgeInsets.all(10),
                    shape: const CircleBorder()),
                child: SvgPicture.asset('assets/svgs/icons/back.svg',
                    height: 18, width: 18),
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorMainBackground,
              borderRadius: BorderRadiusDirectional.vertical(
                  top: Radius.circular(deviceAverageSize * 0.0)),
            ),
            child: ListView(
              children: chatHistory
                  .map((historyItem) => MessageBox(historyItem))
                  .toList(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
              decoration: BoxDecoration(
                color: colorWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: const Offset(3, 0),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorMainBackground,
                  hintText: languages.chatTypeMessage,
                  hintStyle: const TextStyle(color: colorMainGray),
                  prefixIcon: SvgPicture.asset('assets/svgs/attach.svg',
                      fit: BoxFit.scaleDown),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 25,
            bottom: 32,
            child: LoadImageSimple(
                width: 40, image: 'assets/images/icons/send_btn.png'),
          )
        ],
      ),
    );
  }

  Widget MessageBox(ChatHistoryListItem historyItem) {
    final double leftMargin = historyItem.isProvider ? 0 : deviceWidth * .2;
    final double rightMargin = historyItem.isProvider ? deviceWidth * .2 : 0;
    final boxColor = historyItem.isProvider ? colorWhite : colorRed;
    final textColor = historyItem.isProvider ? colorBlack : colorWhite;
    Widget statusIcon = Container();

    if (!historyItem.isProvider) {
      switch (historyItem.status) {
        case 1:
          statusIcon = const Icon(Icons.done_all, color: colorRipple, size: 20);
          break;
        case 2:
          statusIcon =
              const Icon(Icons.done_all, color: colorSelected, size: 20);
          break;
        case 0:
        default:
          statusIcon = const Icon(Icons.check, color: colorRipple, size: 20);
          break;
      }
    }
    return Container(
      margin: EdgeInsets.fromLTRB(leftMargin, 8, rightMargin, 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(historyItem.content,
              style: TextStyle(fontSize: 15, color: textColor)),
          Row(
            children: [
              const Spacer(),
              Text(historyItem.spentAt,
                  style: TextStyle(fontSize: 13, color: textColor)),
              const SizedBox(width: 8),
              statusIcon
            ],
          )
        ],
      ),
    );
  }
}
