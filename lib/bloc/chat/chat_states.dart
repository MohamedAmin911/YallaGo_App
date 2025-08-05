import 'package:equatable/equatable.dart';
import 'package:taxi_app/data_models/chat_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

/// The initial state before any messages are loaded.
class ChatInitial extends ChatState {}

/// State while the chat history is being loaded.
class ChatLoading extends ChatState {}

/// State when messages have been successfully loaded.
/// It carries the list of messages to be displayed in the UI.
class ChatLoaded extends ChatState {
  final List<ChatMessageModel> messages;

  const ChatLoaded({required this.messages});

  @override
  List<Object> get props => [messages];
}

/// State for when an error occurs.
class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object> get props => [message];
}
