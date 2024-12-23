import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cinetalk/features/api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ChatRoom extends StatefulWidget {
  final String user1;
  final String user2;
  final String user2Nickname;

  const ChatRoom({
    required this.user1,
    required this.user2,
    required this.user2Nickname,
    super.key,
  });

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late WebSocketChannel _channel;
  final List<Map<String, String>> _messages = [];
  String _statusMessage = 'Connecting to server...';
  bool _isConnected = true;
  Uint8List? _user2ProfileImage;

  @override
  void initState() {
    super.initState();
    _fetchUser2ProfileImage();
    _connectWebSocket();
  }

  Future<void> _fetchUser2ProfileImage() async {
    try {
      final profileImage = await UserApi.getProfile(widget.user2);
      setState(() {
        _user2ProfileImage = profileImage;
      });
    } catch (e) {
      print("Error fetching profile image for ${widget.user2}: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _connectWebSocket() {
    String websocketIP = dotenv.env['CHAT_IP']!;
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://$websocketIP/ws/${widget.user1}/${widget.user2}'),
    );

    _channel.stream.listen(
      (message) {
        try {
          final decodedMessage = jsonDecode(message);

          String? formattedTime;
          if (decodedMessage['timestamp'] != null) {
            final DateTime parsedTime = DateTime.parse(decodedMessage['timestamp']);
            final DateTime kstTime = parsedTime.add(const Duration(hours: 9));
            formattedTime = DateFormat('MM/dd HH:mm').format(kstTime);
          }

          setState(() {
            _messages.add({
              "sender": decodedMessage['sender'],
              "message": decodedMessage['message'],
              "timestamp": formattedTime ?? 'Unknown time',
            });
          });

          _scrollToBottom();
        } catch (_) {}
      },
      onDone: () {
        setState(() {
          _statusMessage = 'Disconnected from the server';
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'Error: $error';
        });
      },
    );

    _scrollToBottom();
  }

  void _disconnectWebSocket() {
    setState(() {
      _isConnected = false;
      _statusMessage = 'Disconnected from the server';
    });
    _channel.sink.close();
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final message = _controller.text;
      _controller.clear();

      try {
        _channel.sink.add(message);
        _focusNode.requestFocus();
        _scrollToBottom();
      } catch (_) {}
    }
  }

  Future<void> _updateOffset() async {
    try {
      final users = [widget.user1, widget.user2]..sort();
      final topic = "${users[0]}-${users[1]}";

      final response = await UserApi.postBodyChat(
        "/api/chat_rooms/update_offset",
        {"user_id": widget.user1, "topic": topic},
      );

      if (response.statusCode != 200 || jsonDecode(response.body)['status'] != 'success') {}
    } catch (_) {}
  }

  @override
  void dispose() {
    _updateOffset().whenComplete(() {
      _controller.dispose();
      _focusNode.dispose();
      _scrollController.dispose();
      super.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _updateOffset();
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (_user2ProfileImage != null)
                CircleAvatar(
                  backgroundImage: MemoryImage(_user2ProfileImage!),
                ),
              const SizedBox(width: 8),
              Text(widget.user2Nickname),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _updateOffset();
              Navigator.of(context).pop(true);
            },
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 193, 178, 227),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  bool isUser = message['sender'] == widget.user1;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isUser && _user2ProfileImage != null) ...[
                            CircleAvatar(
                              backgroundImage: MemoryImage(_user2ProfileImage!),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.blue
                                      : const Color.fromARGB(255, 255, 255, 255),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  message['message']!,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  message['timestamp'] ?? 'Unknown time',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(hintText: 'Enter message'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
