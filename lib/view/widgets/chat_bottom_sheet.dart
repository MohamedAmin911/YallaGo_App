import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/chat/chat_cubit.dart';
import 'package:taxi_app/bloc/chat/chat_states.dart';
import 'package:taxi_app/data_models/chat_model.dart';

class ChatBottomSheet extends StatefulWidget {
  final String tripId;

  const ChatBottomSheet({super.key, required this.tripId});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final _messageController = TextEditingController();

  void _sendMessage(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthLoggedIn) {
      context.read<ChatCubit>().sendMessage(
            tripId: widget.tripId,
            text: _messageController.text,
            senderUid: authState.user.uid,
          );
      _messageController.clear();
      FocusScope.of(context).unfocus(); // Hide keyboard after sending
    }
  }

  @override
  Widget build(BuildContext context) {
    // This provides the ChatCubit specifically to this bottom sheet.
    return BlocProvider(
      create: (context) => ChatCubit()..listenToMessages(widget.tripId),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Make the sheet only as tall as its content
          children: [
            // Handle to indicate the sheet can be dragged
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // The list of messages
            Flexible(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ChatLoaded) {
                    final currentUserId =
                        (context.read<AuthCubit>().state as AuthLoggedIn)
                            .user
                            .uid;
                    return ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isMyMessage = message.senderUid == currentUserId;
                        return _buildMessageBubble(message, isMyMessage);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // The input field
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Builder(builder: (context) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _sendMessage(context),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMyMessage) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text),
      ),
    );
  }
}
