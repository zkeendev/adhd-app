import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final Future<void> Function(String text) onSendMessage;

  const ChatInputField({super.key, required this.onSendMessage});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  Future<void> _handleSend() async {
    final String textToSend = _textController.text.trim();
    if (textToSend.isEmpty) return; // Guard against empty sends

    // Clear the controller before calling onSendMessage
    _textController.clear(); 
    _focusNode.requestFocus();

    await widget.onSendMessage(textToSend);
  }

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      textCapitalization: TextCapitalization.none,
      autocorrect: true,
      enableSuggestions: true,
      decoration: InputDecoration(
        hintText: 'Type a message...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
      ),
      onSubmitted: (_) => _handleSend(),
    );
  }

  Widget _buildSendButton() {
    return IconButton.filled(
      icon: Icon(Icons.send, color: Colors.white),
      onPressed: _handleSend,
      tooltip: 'Send Message',
      iconSize: 26.0,
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _buildTextField()),
            const SizedBox(width: 8.0),
            SizedBox(
              width: 48.0,
              height: 48.0,
              child: _buildSendButton(),
            ),
          ],
        ),
      ),
    );
  }
}
