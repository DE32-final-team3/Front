import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatRoom extends StatefulWidget { // 클래스 이름 수정
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

class _ChatRoomState extends State<ChatRoom> { // 클래스 이름 수정에 따른 변경
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late WebSocketChannel _channel;
  final List<Map<String, String>> _messages = [];
  String _statusMessage = 'Connecting to server...';
  String? servIP = dotenv.env['CHAT_IP'];
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://${servIP}:8000/ws/${widget.user1}/${widget.user2}'),
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
    if (_controller.text.trim().isEmpty) return;

    final message = _controller.text.trim();
    _channel.sink.add(message);

    try {
      _channel.sink.add(message);
      _focusNode.requestFocus();
      _scrollToBottom();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.user2Nickname}님과의 채팅'),
          backgroundColor: const Color.fromARGB(255, 145, 115, 214),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            Icon(
              _isConnected ? Icons.link : Icons.link_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              color: _isConnected ? Colors.green : Colors.red,
              onPressed: _isConnected ? _disconnectWebSocket : null,
            ),
          ],
        ),
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
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isUser)
                            CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Text(
                                message['sender']![0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.blue
                                    : const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message']!,
                                    style: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
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
