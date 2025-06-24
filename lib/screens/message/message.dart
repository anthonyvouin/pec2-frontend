import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/components/message/conversation_item.dart';
import 'package:firstflutterapp/components/message/conversation_list.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/components/message/disabled_message_input.dart';
import 'package:firstflutterapp/components/message/message_bubble.dart';
import 'package:firstflutterapp/components/message/message_input.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();

  List<PrivateMessage> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  PrivateMessage? _selectedConversation;
  final Map<String, List<PrivateMessage>> _conversationMessages = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/private-messages',
        withAuth: true,
      );

      if (response.success) {
        final List<dynamic> data = response.data;
        final messages =
            data.map((item) => PrivateMessage.fromJson(item)).toList();

        _organizeConversations(messages);

        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage =
              response.error ?? 'Erreur lors du chargement des messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Erreur lors du chargement des messages: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  void _organizeConversations(List<PrivateMessage> messages) {
    _conversationMessages.clear();

    for (var message in messages) {
      final otherPersonId =
          message.isCurrentUser ? message.receiverId : message.senderId;

      if (!_conversationMessages.containsKey(otherPersonId)) {
        _conversationMessages[otherPersonId] = [];
      }

      _conversationMessages[otherPersonId]!.add(message);
    }

    _conversationMessages.forEach((key, value) {
      value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  List<PrivateMessage> _getConversationPreviews() {
    final Map<String, PrivateMessage> latestMessages = {};

    for (var message in _messages) {
      final otherPersonId =
          message.isCurrentUser ? message.receiverId : message.senderId;

      if (!latestMessages.containsKey(otherPersonId) ||
          message.createdAt.isAfter(latestMessages[otherPersonId]!.createdAt)) {
        latestMessages[otherPersonId] = message;
      }
    }

    final result = latestMessages.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> _openConversation(PrivateMessage message) async {
    setState(() {
      _selectedConversation = message;
    });
  }

  void _backToConversations() {
    setState(() {
      _selectedConversation = null;
    });
  }

  Future<void> _sendMessage(String receiverName) async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      final response = await _apiService.request(
        method: 'POST',
        endpoint: '/private-messages',
        withAuth: true,
        body: {'receiverUserName': receiverName, 'content': content},
      );

      if (response.success) {
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${response.error ?? "Impossible d\'envoyer le message"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      developer.log('Erreur lors de l\'envoi du message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedConversation == null
              ? 'Messages'
              : (_selectedConversation!.isCurrentUser
                  ? _selectedConversation!.receiverName
                  : _selectedConversation!.senderName),
        ),
        leading:
            _selectedConversation != null
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _backToConversations,
                )
                : null,
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage ?? 'Une erreur est survenue'),
                      ElevatedButton(
                        onPressed: _loadMessages,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
                : _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_selectedConversation == null) {
      return ConversationList(
        conversations: _getConversationPreviews(),
        onConversationTap: _openConversation,
      );
    } else {
      final otherPersonId =
          _selectedConversation!.isCurrentUser
              ? _selectedConversation!.receiverId
              : _selectedConversation!.senderId;

      final messages = _conversationMessages[otherPersonId] ?? [];
      final otherPersonName =
          _selectedConversation!.isCurrentUser
              ? _selectedConversation!.receiverName
              : _selectedConversation!.senderName;
              
      // Détermine si l'autre personne a activé les messages
      final bool messageEnabled = _selectedConversation!.isCurrentUser
          ? _selectedConversation!.receiverMessageEnable
          : _selectedConversation!.senderMessageEnable;
          
      developer.log('Building message UI with messageEnabled: $messageEnabled for user: $otherPersonId');

      return Column(
        children: [
          Expanded(
            child: 
                messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Commencez à discuter',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(message: messages[index]);
                        },
                      ),
          ),
          messageEnabled
              ? MessageInput(
                  controller: _messageController,
                  onSend: _sendMessage,
                  receiverName: otherPersonName,
                )
              : const DisabledMessageInput(),
        ],
      );
    }
  }
}
