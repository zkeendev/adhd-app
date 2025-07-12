import 'package:adhd_app/features/chat/application/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:adhd_app/core/providers/firebase_providers.dart';
import 'package:adhd_app/features/auth/auth_providers.dart';
import 'package:adhd_app/features/chat/domain/chat_message.dart';
import 'package:adhd_app/features/chat/domain/chat_repository.dart';
import 'package:adhd_app/features/chat/data/firestore_chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final FirebaseFirestore firestoreInstance = ref.watch(firebaseFirestoreProvider);
  return FirestoreChatRepository(firestoreInstance);
});

final chatMessagesStreamProvider = StreamProvider.autoDispose<List<ChatMessage>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  final ChatRepository chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getMessages(userId);
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Manages the local state of chat messages for the UI.
/// It combines optimistic messages with confirmed messages from Firestore.
final chatMessagesProvider = StateNotifierProvider.autoDispose<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(ref);
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;

  ChatMessagesNotifier(this._ref) : super([]) {
    // Listen to the Firestore stream and update the local state whenever
    // new messages arrive.
    _ref.listen<AsyncValue<List<ChatMessage>>>(chatMessagesStreamProvider, (_, next) {
      next.whenData((messagesFromDb) {
        // This is the core logic for merging DB state with local state.
        // We create a new list to ensure immutability.
        final updatedMessages = List<ChatMessage>.from(state);

        // A map for quick lookups of messages from the database.
        final dbMessagesMap = {for (var msg in messagesFromDb) msg.id: msg};

        // Iterate backwards to safely remove/replace elements.
        for (int i = updatedMessages.length - 1; i >= 0; i--) {
          final localMessage = updatedMessages[i];

          // If a local message now exists in the database, replace it
          // with the confirmed version from the DB.
          if (dbMessagesMap.containsKey(localMessage.id)) {
            updatedMessages[i] = dbMessagesMap[localMessage.id]!;
            // Remove it from the map so we don't add it again.
            dbMessagesMap.remove(localMessage.id);
          }
        }

        // Add any remaining new messages from the DB that weren't
        // part of the optimistic UI updates (e.g., the AI's response).
        updatedMessages.addAll(dbMessagesMap.values);

        // Sort the final list by timestamp to ensure correct order.
        // Handle null timestamps by treating them as the newest.
        updatedMessages.sort((a, b) {
          final aTimestamp = a.timestamp?.millisecondsSinceEpoch ?? double.maxFinite.toInt();
          final bTimestamp = b.timestamp?.millisecondsSinceEpoch ?? double.maxFinite.toInt();
          return aTimestamp.compareTo(bTimestamp);
        });

        state = updatedMessages;
      });
    }, fireImmediately: true);
  }

  /// Adds a new message optimistically to the local state.
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  /// Updates the status of an existing message in the local state.
  void updateMessageStatus(String messageId, MessageStatus status) {
    state = [
      for (final message in state)
        if (message.id == messageId) message.copyWith(status: status) else message,
    ];
  }
}
