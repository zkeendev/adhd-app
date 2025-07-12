import 'package:adhd_app/features/chat/domain/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> getMessages(String userId);
}