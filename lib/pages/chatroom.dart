import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatRoom extends StatefulWidget {
  // 클래스 이름 수정
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
  // 클래스 이름 수정에 따른 변경
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
    // 스크롤 이동 함수
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
    String websocketIP = dotenv.env['WEBSOCKET_IP']!;
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
        _focusNode.requestFocus(); // 메시지 전송 후 Focus 다시 설정
        _scrollToBottom();
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  // Widget _buildProfileImage({double radius = 20}) {
  //   return CircleAvatar(
  //     radius: radius,
  //     backgroundColor: Colors.grey[300],
  //     child: ClipOval(
  //       child: Image.asset(
  //         'assets/default_profile.jpg',
  //         width: radius * 2,
  //         height: radius * 2,
  //         fit: BoxFit.cover,
  //       ),
  //     ),
  //   );
  // }

  // void _showOpponentProfileDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20.0),
  //         ),
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               _buildProfileImage(radius: 50),
  //               const SizedBox(height: 16),
  //               Text(
  //                 widget.user2Nickname,
  //                 style: const TextStyle(
  //                   fontSize: 24,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: const Color.fromARGB(255, 145, 115, 214),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(30),
  //                   ),
  //                 ),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: const Padding(
  //                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
  //                   child: Text(
  //                     '닫기',
  //                     style: TextStyle(fontSize: 16, color: Colors.white),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

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
          title: Text(widget.user2Nickname), // 중앙에 닉네임 표시
          centerTitle: true, // 닉네임을 정중앙으로 배치
          backgroundColor: const Color.fromARGB(255, 145, 115, 214),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              color: _isConnected ? Colors.green : Colors.red,
              onPressed: _isConnected ? _disconnectWebSocket : null,
            ),
            const SizedBox(width: 15),
          ],
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
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isUser) ...[
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.person), // 기본 프로필 이미지
                            ),
                            const SizedBox(width: 8), // 프로필 사진과 메시지 간격
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
