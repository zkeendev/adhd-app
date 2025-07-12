import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:adhd_app/features/chat/application/chat_controller.dart';
import 'package:adhd_app/features/chat/presentation/widgets/chat_input_field.dart';
import 'package:adhd_app/features/chat/presentation/widgets/message_list_view.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for errors from ChatController operations (e.g., sendMessage)
    // to display a SnackBar.
    ref.listen<AsyncValue<void>>(chatControllerProvider, (_, nextState) {
      nextState.whenOrNull(
        error: (error, stackTrace) {
          if (!context.mounted) return; // Ensure widget is still in the tree
          
          // Truncate error message for display if it's too long
          final displayError = error.toString();
          final shortError = displayError.length > 100 
              ? '${displayError.substring(0, 97)}...' 
              : displayError;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $shortError'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    });

    // Callback for the ChatInputField to trigger sending a message.
    Future<void> handleSendMessage(String text) async {
      // Invoke the sendMessage action on the ChatController.
      // The controller handles its async state (loading/error), and ref.listen
      // handles UI feedback like SnackBars for those states.
      await ref.read(chatControllerProvider.notifier).sendMessage(text);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with AI'),
      ),
      body: Column(
        children: [
          // Displays the list of messages.
          const Expanded(
            child: MessageListView(),
          ),
          // Input field for typing and sending messages.
          ChatInputField(onSendMessage: handleSendMessage),
        ],
      ),
    );
  }
}