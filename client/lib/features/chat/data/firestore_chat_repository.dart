import 'package:adhd_app/features/chat/domain/chat_message.dart';
import 'package:adhd_app/features/chat/domain/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String _conversationsCollection = 'user_conversations';
const String _messagesSubcollection = 'messages';
const String _timestampField = 'timestamp';

class FirestoreChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;

  FirestoreChatRepository(this._firestore);

  // HELPER: Get the CollectionReference for a user's messages
  CollectionReference<Map<String, dynamic>> _userMessagesCollectionRef(String userId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(userId)
        .collection(_messagesSubcollection);
  }

  // HELPER: Transform a single DocumentSnapshot into a ChatMessage
  ChatMessage _documentToChatMessage(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return ChatMessage.fromJson(doc.data(), doc.id);
  }

  // HELPER: Transform a QuerySnapshot into a List<ChatMessage>
  List<ChatMessage> _querySnapshotToChatMessages(QuerySnapshot<Map<String, dynamic>> querySnapshot) {
    // Use a try-catch within the map to prevent a single malformed document
    // from crashing the entire stream.
    return querySnapshot.docs.map((doc) {
      try {
        return _documentToChatMessage(doc);
      } catch (e) {
        print('Error parsing a chat message document: ${doc.id}, error: $e');
        // Return null for invalid documents and filter them out later.
        return null;
      }
    }).whereType<ChatMessage>().toList(); // whereType<T>() filters out nulls.
  }

  @override
  Stream<List<ChatMessage>> getMessages(String userId) {
    try {
      return _userMessagesCollectionRef(userId)
          .orderBy(_timestampField, descending: false)
          .snapshots()
          .map(_querySnapshotToChatMessages)
          .handleError((error, stackTrace) {
            // This handles errors in the stream itself (e.g., permission denied).
            print('Error in Firestore getMessages stream: $error');
            // Propagate the error through the stream.
            throw Exception('Error fetching messages: $error');
          });
    } on FirebaseException catch (e) {
      print('Failed to set up message stream: ${e.message}');
      throw Exception('Failed to set up message stream: ${e.message}');
    } catch (e) {
      print('An unexpected error occurred while setting up message stream: $e');
      throw Exception('An unexpected error occurred while setting up message stream: $e');
    }
  }
}