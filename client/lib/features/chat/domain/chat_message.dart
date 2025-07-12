import 'package:cloud_firestore/cloud_firestore.dart';

const String aiSenderId = 'AI_ASSISTANT';

enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final Timestamp? timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    this.timestamp,
    this.status = MessageStatus.sent, // Default to sent for messages from Firestore
  });

  // This method is used by the server, but good to keep for consistency.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> data, String documentId) {
    final String text = data['text'] as String;
    final String senderId = data['senderId'] as String;
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;

    return ChatMessage(
      id: documentId,
      text: text,
      senderId: senderId,
      timestamp: timestamp,
      // Messages from Firestore are always considered 'sent'.
      status: MessageStatus.sent,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    String? senderId,
    Timestamp? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}