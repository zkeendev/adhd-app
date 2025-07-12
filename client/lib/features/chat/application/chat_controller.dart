import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:adhd_app/features/chat/application/ai_service.dart';
import 'package:adhd_app/features/chat/domain/chat_message.dart';
import 'package:adhd_app/features/auth/auth_providers.dart';
import 'package:adhd_app/features/chat/chat_providers.dart';

final chatControllerProvider = AsyncNotifierProvider.autoDispose<ChatController, void>(ChatController.new);

class ChatController extends AutoDisposeAsyncNotifier<void> {
  late final AIService _aiService;
  late final ChatMessagesNotifier _messagesNotifier;

  @override
  Future<void> build() async {
    _aiService = ref.read(aiServiceProvider);
    _messagesNotifier = ref.read(chatMessagesProvider.notifier);
    return;
  }

  /// Sends a message with optimistic UI updates.
  Future<void> sendMessage(String messageText) async {
    final user = ref.read(currentUserProvider);
    final userId = ref.read(currentUserIdProvider);

    // 1. Guard clauses for authentication and empty messages
    if (user == null || userId == null) {
      state = AsyncValue.error(Exception("User not authenticated."), StackTrace.current);
      return;
    }
    if (messageText.trim().isEmpty) {
      return; // Silently ignore empty messages
    }

    // 2. Create an optimistic message
    final messageId = const Uuid().v4();
    final optimisticMessage = ChatMessage(
      id: messageId,
      text: messageText.trim(),
      senderId: userId,
      timestamp: Timestamp.now(),
      status: MessageStatus.sending,
    );

    // 3. Add the message to the local state immediately
    _messagesNotifier.addMessage(optimisticMessage);

    // 4. Attempt to send the message to the backend
    try {
      // The controller's state is not used for loading, as the UI
      // now relies on the message's own status.
      await _aiService.sendMessage(
        user: user,
        message: optimisticMessage,
      );
      // On success, we don't need to do anything here. The message status
      // will be updated to `sent` by the Firestore stream listener in
      // the ChatMessagesNotifier.
    } catch (e, s) {
      // 5. On failure, update the message status to 'failed'
      print("[ChatController] Error sending message: $e\n$s");
      _messagesNotifier.updateMessageStatus(messageId, MessageStatus.failed);

      // Also set the controller's state to error so the UI (e.g., a SnackBar)
      // can show a general error message.
      state = AsyncValue.error(e, s);
    }
  }
}