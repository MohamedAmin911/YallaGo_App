import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/chat/chat_states.dart';
import 'package:taxi_app/data_models/chat_model.dart';

class ChatCubit extends Cubit<ChatState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _messagesSubscription;

  ChatCubit() : super(ChatInitial());

  void listenToMessages(String tripId) {
    emit(ChatLoading());
    _messagesSubscription?.cancel();

    final messagesRef = _db
        .collection('trips')
        .doc(tripId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    _messagesSubscription = messagesRef.snapshots().listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
          .toList();
      emit(ChatLoaded(messages: messages));
    }, onError: (error) {
      emit(ChatError(message: "Failed to load messages: ${error.toString()}"));
    });
  }

  Future<void> sendMessage({
    required String tripId,
    required String text,
    required String senderUid,
  }) async {
    if (text.trim().isEmpty) return;
    try {
      final message = ChatMessageModel(
        messageId: '',
        senderUid: senderUid,
        text: text.trim(),
        timestamp: Timestamp.now(),
        readBy: [senderUid], // The sender has automatically "read" it
      );

      await _db
          .collection('trips')
          .doc(tripId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // --- NEW FUNCTION ---
  /// Marks all unread messages in a chat as read by the current user.
  Future<void> markMessagesAsRead(String tripId, String currentUserId) async {
    try {
      final messagesRef =
          _db.collection('trips').doc(tripId).collection('messages');
      // Get all messages where the current user's ID is NOT in the 'readBy' array
      final unreadMessages = await messagesRef.where('readBy', whereNotIn: [
        [currentUserId]
      ]).get();

      final WriteBatch batch = _db.batch();
      for (final doc in unreadMessages.docs) {
        // Add the current user's ID to the 'readBy' array for each unread message
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUserId])
        });
      }
      await batch.commit();
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
