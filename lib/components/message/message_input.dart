import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final String receiverName;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.receiverName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Écrire un message...',
                border: InputBorder.none,
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  onSend(receiverName);
                  controller.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSend(receiverName);
              }
            },
          ),
        ],
      ),
    );
  }
}
