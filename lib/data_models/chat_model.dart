import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single message in a chat between a customer and a driver.
class ChatMessageModel {
  final String messageId;
  final String senderUid; // The UID of the person who sent the message
  final String text;
  final Timestamp timestamp;

  ChatMessageModel({
    required this.messageId,
    required this.senderUid,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'text': text,
      'timestamp': timestamp,
    };
  }

  factory ChatMessageModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return ChatMessageModel(
      messageId: documentId,
      senderUid: map['senderUid'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
