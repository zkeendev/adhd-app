import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:adhd_app/features/auth/auth_providers.dart';
import 'package:adhd_app/features/chat/domain/chat_message.dart';
import 'package:adhd_app/features/chat/chat_providers.dart';
import 'package:adhd_app/features/chat/presentation/widgets/message_bubble.dart';

class MessageListView extends ConsumerStatefulWidget {
  const MessageListView({super.key});

  @override
  ConsumerState<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends ConsumerState<MessageListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use a small delay to ensure the ListView has finished building
      // its new items before we try to scroll.
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the local list of messages from our StateNotifier.
    final List<ChatMessage> messages = ref.watch(chatMessagesProvider);

    // Watch for changes in the message list to trigger a scroll to the bottom.
    ref.listen(chatMessagesProvider, (previous, next) {
      // If a new message was added, scroll down.
      if ((previous?.length ?? 0) < next.length) {
        _scrollToBottom();
      }
    });

    // Watch the current user's ID to determine the sender for bubbles.
    final String? currentUserId = ref.watch(currentUserIdProvider);

    // Handle the case where the stream is still loading for the first time
    // or the user is not yet available.
    final initialLoad = ref.watch(chatMessagesStreamProvider);
    if (initialLoad.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (initialLoad.hasError) {
      print('[MessageListView] Error loading messages: ${initialLoad.error}');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load messages. Please try again later.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No messages yet. Say something!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final bool isCurrentUserMessage = (currentUserId != null && message.senderId == currentUserId);
        return Row(
          mainAxisAlignment: isCurrentUserMessage 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          children: [
            MessageBubble(message: message, isCurrentUser: isCurrentUserMessage)
          ],
        );
      },
    );
  }
}