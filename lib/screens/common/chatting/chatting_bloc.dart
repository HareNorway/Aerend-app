import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../chatHistory/chat_history_dl.dart';

class ChattingBloc extends Bloc {
  String tag = "ChattingBloc>>>";
  late String chatWithId, chatWithName, chatWithImage, chatWithServicesName, userId, userName;
  int chatWithUserType;
  late FirebaseDatabase firebaseDatabase;
  late DatabaseReference _refUserToChatWith, _refChatWithToUser, _referenceUser, _referenceChatWith, _referenceServerTimeZone;

  final subjectChatList = BehaviorSubject<List<ModelChatting>>();

  ChattingBloc(this.chatWithId, this.chatWithName, this.chatWithImage, this.chatWithServicesName, this.chatWithUserType) {
    userName = prefGetString(prefUserName);
    userId = ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
    firebaseDatabase = FirebaseDatabase.instance;
    _refUserToChatWith = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.messages).child("${userId}_$chatWithId");
    _refChatWithToUser = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.messages).child("${chatWithId}_$userId");
    _referenceUser = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.users).child(userId);
    _referenceChatWith = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.users).child(chatWithId);
    _referenceServerTimeZone = firebaseDatabase.ref().child(ChatConstant.chat).child(ChatConstant.serverTimezone).child(ChatConstant.timestamp);
    ensureAuth().then((_) async {
      setFCMToken();
      setChatList();
    });
  }

  TextEditingController msgController = TextEditingController();

  setChatList() {
    _refUserToChatWith.onValue.forEach((element) {
      logd(tag, "_refUserToChatWith.onValue");
      DataSnapshot dataSnapshot = element.snapshot;
      Map? data = dataSnapshot.value as Map<dynamic, dynamic>?;
      List<ModelChatting> chatList = [];
      data?.forEach((key, value) {
        logd(tag, "data?.forEach: ${value.toString()}");
        ModelChatting modelChatList = ModelChatting.fromJson(value);
        chatList.add(modelChatList);
      });
      if (chatList.isNotEmpty) {
        chatList.sort((a, b) {
          String aDate = getChatDateTime(a.date ?? "", format: "yyyy-MM-dd HH:mm:ss");
          String bDate = getChatDateTime(b.date ?? "", format: "yyyy-MM-dd HH:mm:ss");

          return bDate.compareTo(aDate);
        });
      }

      subjectChatList.add(chatList);
    });
  }

  DatabaseReference getChatList() {
    return _refUserToChatWith;
  }

  Future<void> ensureAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> sendMsg() async {
    await ensureAuth();
    final String msg = msgController.text.trim();
    if (msg.isEmpty) return;
    msgController.text = "";
    try {
      await _referenceServerTimeZone.set(ServerValue.timestamp);
      final snap = await _referenceServerTimeZone.once();
      final String key = "${snap.snapshot.value}";
      FocusManager.instance.primaryFocus?.unfocus();
      final map = <String, String>{
        ChatConstant.fbSenderId: userId,
        ChatConstant.fbMessage: msg,
        ChatConstant.fbSenderName: userName,
        ChatConstant.fbMessageTime: getCurrentTimeEnglish(),
      };
      await _refUserToChatWith.child(key).set(map);
      await _refChatWithToUser.child(key).set(map);
      checkAndSetUser(msg);
      await callNotificationApi(msg);
    } catch (e) {
      logd(tag, "sendMsg / push failed: $e");
    }
  }

  //Please do not edit admin seen and user type code until you have proper knowledge...
  checkAndSetUser(String msg) {
    String key = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    _referenceUser.orderByChild(ChatConstant.userId).equalTo(chatWithId).once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value == null) {
        var map = <String, dynamic>{};
        map[ChatConstant.userId] = chatWithId;
        map[ChatConstant.userName] = chatWithName;
        map[ChatConstant.userProfile] = chatWithImage;
        map[ChatConstant.userServicesName] = chatWithServicesName;
        map[ChatConstant.userDateTime] = getCurrentTimeEnglish();
        map[ChatConstant.userLastMessage] = msg;
        map[ChatConstant.userType] = chatWithUserType;
        if (chatWithId.contains(ChatConstant.adminIdCode)) {
          map[ChatConstant.adminSeen] = false;
        }
        return _referenceUser.child(key).set(map);
      } else {
        Map data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
        var updateMap = <String, dynamic>{};
        updateMap[ChatConstant.userDateTime] = getCurrentTimeEnglish();
        updateMap[ChatConstant.userLastMessage] = msg;
        updateMap[ChatConstant.userType] = chatWithUserType;
        if (chatWithId.contains(ChatConstant.adminIdCode)) {
          updateMap[ChatConstant.adminSeen] = false;
        }
        return _referenceUser.orderByChild(ChatConstant.userId).equalTo(chatWithId).ref.child(data.keys.elementAt(0)).update(updateMap);
      }
    });

    _referenceChatWith.orderByChild(ChatConstant.userId).equalTo(userId).once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value == null) {
        var map = <String, dynamic>{};
        map[ChatConstant.userId] = userId;
        map[ChatConstant.userName] = userName;
        map[ChatConstant.userProfile] = prefGetString(prefProfileImage);
        map[ChatConstant.userServicesName] = "Customer";
        map[ChatConstant.userDateTime] = getCurrentTimeEnglish();
        map[ChatConstant.userLastMessage] = msg;
        map[ChatConstant.userType] = chatWithTypeUser;
        if (chatWithId.contains(ChatConstant.adminIdCode)) {
          map[ChatConstant.adminSeen] = false;
        }
        return _referenceChatWith.child(key).set(map);
      } else {
        Map data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
        var updateMap = <String, dynamic>{};
        updateMap[ChatConstant.userDateTime] = getCurrentTimeEnglish();
        updateMap[ChatConstant.userLastMessage] = msg;
        updateMap[ChatConstant.userType] = chatWithTypeUser;
        if (chatWithId.contains(ChatConstant.adminIdCode)) {
          updateMap[ChatConstant.adminSeen] = false;
        }
        return _referenceChatWith.orderByChild(ChatConstant.userId).equalTo(userId).ref.child(data.keys.elementAt(0)).update(updateMap);
      }
    });
  }

  Future<void> callNotificationApi(String msg) async {
    try {
      final dynamic response = await ApiBaseHelper().post(
        ApiConst.endPointChatFcmRelay,
        body: {
          ApiParam.paramUserId: prefGetInt(prefUserId),
          ApiParam.paramAccessToken: prefGetString(prefAccessToken),
          'recipient_peer_id': chatWithId,
          'message': msg,
          'sender_chat_id': userId,
          'sender_name': userName,
          'sender_img': prefGetString(prefProfileImage),
          'sender_service_name': 'Customer',
          'sender_user_type': chatWithTypeUser.toString(),
        },
      );
      logd(tag, 'chat-fcm-relay: $response');
    } catch (e, st) {
      logd(tag, "callNotificationApi failed: $e");
      logd(tag, "callNotificationApi stack: $st");
    }
  }

  @override
  void dispose() {
    msgController.dispose();
    subjectChatList.close();
  }
}
