import 'package:firebase_database/firebase_database.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';

class ChatHistoryBloc extends Bloc {
  final DatabaseReference _chatHistoryRef = FirebaseDatabase.instance
      .ref()
      .child(ChatConstant.chat)
      .child(ChatConstant.users)
      .child(ChatConstant.userIdCode + prefGetInt(prefUserId).toString());

  DatabaseReference getChatHistory() {
    return _chatHistoryRef;
  }

  deleteChatHistory(String userRefId) {
    _chatHistoryRef.child(userRefId).remove();
  }

  @override
  void dispose() {}
}
