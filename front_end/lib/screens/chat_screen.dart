import 'dart:async';
import 'package:flutter/material.dart';
import 'package:front_end/l10n/app_localizations.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../enums/user_role.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final UserRole myRole;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    required this.myRole,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll every 3 seconds for near-instant feel
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchMessages(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    final msgs = await _api.getChatMessages(widget.otherUserId, widget.myRole);

    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      if (!isBackground) {
        _scrollToBottom();
        // Mark as read if I am the midwife (since backend endpoint exists for midwife)
        if (widget.myRole == UserRole.midwife) {
          _api.markChatRead(widget.otherUserId);
        } else if (widget.myRole == UserRole.mother) {
          _api.markChatReadMother(widget.otherUserId);
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Small delay to allow list to render
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final content = _controller.text.trim();
    _controller.clear();

    // Optimistic Update? Ideally yes, but let's stick to safe API call first
    final success = await _api.sendMessage(
      widget.otherUserId,
      content,
      widget.myRole,
    );

    if (success) {
      _fetchMessages();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToSend)),
      );
    }
  }

  bool _isMe(Message msg) {
    if (widget.myRole == UserRole.midwife) {
      return msg.senderRole == "midwife";
    } else {
      return msg.senderRole == "mother";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Text(widget.otherUserName[0].toUpperCase()),
              radius: 16,
            ),
            SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.sayHello,
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = _isMe(msg);

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? theme.colorScheme.primary
                                : theme.cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                              bottomLeft: isMe
                                  ? Radius.circular(12)
                                  : Radius.zero,
                              bottomRight: isMe
                                  ? Radius.zero
                                  : Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            msg.content,
                            style: TextStyle(
                              color: isMe
                                  ? theme.colorScheme.onPrimary
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.typeMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send_rounded),
                  color: theme.colorScheme.primary,
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
