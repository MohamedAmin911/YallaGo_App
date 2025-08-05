import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/chat/chat_states.dart';
import 'package:taxi_app/data_models/chat_model.dart';

class ChatCubit extends Cubit<ChatState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _messagesSubscription;

  ChatCubit() : super(ChatInitial());

  /// Listens to the message sub-collection for a specific trip in real-time.
  void listenToMessages(String tripId) {
    emit(ChatLoading());
    _messagesSubscription?.cancel();

    final messagesRef = _db
        .collection('trips')
        .doc(tripId)
        .collection('messages')
        .orderBy('timestamp',
            descending: true); // Show newest messages at the bottom

    _messagesSubscription = messagesRef.snapshots().listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
          .toList();
      emit(ChatLoaded(messages: messages));
    }, onError: (error) {
      emit(ChatError(message: "Failed to load messages: ${error.toString()}"));
    });
  }

  /// Sends a new message to the chat.
  Future<void> sendMessage({
    required String tripId,
    required String text,
    required String senderUid,
  }) async {
    if (text.trim().isEmpty) {
      return; // Don't send empty messages
    }
    try {
      final message = ChatMessageModel(
        messageId: '', // Firestore will generate this
        senderUid: senderUid,
        text: text.trim(),
        timestamp: Timestamp.now(),
      );

      await _db
          .collection('trips')
          .doc(tripId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      // Optionally emit an error state if sending fails
      print("Error sending message: $e");
    }
  }

  @override
  Future<void> close() {
    // Cancel the subscription when the cubit is no longer needed to prevent memory leaks
    _messagesSubscription?.cancel();
    return super.close();
  }
}
