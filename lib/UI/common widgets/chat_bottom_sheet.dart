import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/chat/chat_cubit.dart';
import 'package:taxi_app/bloc/chat/chat_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/chat_model.dart';

class ChatBottomSheet extends StatefulWidget {
  final String tripId;

  const ChatBottomSheet({super.key, required this.tripId});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final _messageController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // --- THE FIX IS HERE ---
    // We now call this after the UI has been built for the first time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Use the context's ChatCubit, which is provided below.
        context.read<ChatCubit>().markMessagesAsRead(widget.tripId, user.uid);
      }
    });
  }

  void _sendMessage(BuildContext context) {
    // Get the user directly from FirebaseAuth for reliability
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<ChatCubit>().sendMessage(
            tripId: widget.tripId,
            text: _messageController.text,
            senderUid: user.uid,
          );
      _messageController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit()..listenToMessages(widget.tripId),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            Flexible(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return Center(
                        child: CircularProgressIndicator(
                      color: KColor.primary,
                    ));
                  }
                  if (state is ChatLoaded) {
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) {
                      return const Center(
                          child: Text("Error: User not found."));
                    }

                    return state.messages.isEmpty
                        ? SizedBox.fromSize(
                            size: Size(400.w, 100.h),
                            child: Center(
                                child: Text(
                              "No messages yet",
                              style: appStyle(
                                  size: 15.sp,
                                  color: KColor.lightGray,
                                  fontWeight: FontWeight.bold),
                            )),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            reverse: true,
                            shrinkWrap: true,
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              final isMyMessage =
                                  message.senderUid == currentUserId;
                              return _buildMessageBubble(message, isMyMessage);
                            },
                          );
                  }
                  return const SizedBox.shrink(
                    child: Center(child: Text("No messages")),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
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
                decoration: InputDecoration(
                  hintStyle: appStyle(
                      size: 15.sp,
                      color: KColor.placeholder,
                      fontWeight: FontWeight.w600),
                  hintText: "  Type a message...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: KColor.primary,
                size: 30.sp,
              ),
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
          color:
              isMyMessage ? KColor.primary.withOpacity(0.5) : KColor.lightGray,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft:
                isMyMessage ? Radius.circular(20.r) : Radius.circular(0.r),
            bottomRight:
                isMyMessage ? Radius.circular(0.r) : Radius.circular(20.r),
          ),
        ),
        child: Text(
          message.text,
          style: appStyle(
              size: 15.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
