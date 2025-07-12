import 'package:adhd_app/features/chat/domain/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  Widget _buildStatusIndicator(BuildContext context) {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(
          Icons.watch_later_outlined,
          size: 14,
        );
      case MessageStatus.failed:
        return Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(width: 4.0),
            Text('Failed to send', style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            )),
          ],
        );
      case MessageStatus.sent:
        // For 'sent', we can either show nothing or a single checkmark.
        // Let's show nothing for a cleaner look.
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bubbleColor = isCurrentUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    final textColor = isCurrentUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    final crossAxisAlignment =
        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16.0),
      topRight: const Radius.circular(16.0),
      bottomLeft: isCurrentUser ? const Radius.circular(16.0) : Radius.zero,
      bottomRight: isCurrentUser ? Radius.zero : const Radius.circular(16.0),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 16.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show timestamp only if it exists (i.e., confirmed by server)
                if (message.timestamp != null)
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp!.toDate()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                // Add a small spacer if both timestamp and status are visible
                if (message.timestamp != null && isCurrentUser && message.status != MessageStatus.sent)
                  const SizedBox(width: 6),
                
                // Show status indicator only for the current user's messages
                if (isCurrentUser) _buildStatusIndicator(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}