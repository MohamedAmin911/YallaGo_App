import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String messageId;
  final String senderUid;
  final String text;
  final Timestamp timestamp;
  // --- NEW FIELD ---
  // A list of UIDs of users who have read this message.
  final List<String> readBy;

  ChatMessageModel({
    required this.messageId,
    required this.senderUid,
    required this.text,
    required this.timestamp,
    this.readBy = const [], // Default to an empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'text': text,
      'timestamp': timestamp,
      'readBy': readBy,
    };
  }

  factory ChatMessageModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return ChatMessageModel(
      messageId: documentId,
      senderUid: map['senderUid'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      // Read the list from Firestore, defaulting to an empty list if it doesn't exist
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
