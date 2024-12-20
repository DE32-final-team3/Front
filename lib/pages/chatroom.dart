import 'package:cinetalk/features/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
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
        setState(() {
          final decodedMessage = message.split(': ');
          _messages.add({
            "sender": decodedMessage[0],
            "message": decodedMessage[1],
          });
          _scrollToBottom();
        });
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

    setState(() {
      _statusMessage = 'Connected to server';
    });
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
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  Future<void> _updateOffset() async {
    try {
      // user1과 user2를 정렬하여 topic 생성
      final users = [widget.user1, widget.user2]..sort();
      final topic = "${users[0]}-${users[1]}";

      print("Attempting to update offset for topic: $topic and user: ${widget.user1}");

      // postBodyChat 함수 호출
      final response = await UserApi.postBodyChat(
        "/api/chat_rooms/update_offset",
        {"user_id": widget.user1, "topic": topic},
      );

      // 상태 코드와 응답 본문 처리
      print("API Response Status Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          print("Offset updated successfully.");
        } else {
          print("Failed to update offset: ${responseData['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update: ${responseData['message']}")),
          );
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("HTTP Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error updating offset: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating message offset.")),
      );
    }
  }

  @override
  void dispose() {
    // dispose에서 updateOffset 호출
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
        // Update offset first, then navigate back
        await _updateOffset();
        Navigator.of(context).pop(true);
        return false; // Prevent default back action
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.user2Nickname),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Update offset before navigating back
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
                          if (!isUser) ...[
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.person),
                            ),
                            const SizedBox(width: 8),
                          ],
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
                      decoration:
                          const InputDecoration(hintText: 'Enter message'),
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
