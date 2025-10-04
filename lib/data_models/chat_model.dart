import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String messageId;
  final String senderUid;
  final String text;
  final Timestamp timestamp;

  final List<String> readBy;

  ChatMessageModel({
    required this.messageId,
    required this.senderUid,
    required this.text,
    required this.timestamp,
    this.readBy = const [],
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
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
