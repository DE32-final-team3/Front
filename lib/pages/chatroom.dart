import 'package:flutter/material.dart';

// 채팅 메시지 모델 (메시지와 시간을 저장)
class ChatMessage {
  final String message;
  final String time;

  ChatMessage({required this.message, required this.time});
}

class ChatRoom extends StatefulWidget {
  const ChatRoom({super.key});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  bool isMenuOpen = false;
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  List<ChatMessage> chatMessages = []; // 채팅 메시지 리스트
  String userNickname = "User123"; // 예시로 사용자 닉네임 설정
  String profileImageUrl = ""; // 예시 프로필 이미지 URL

  String _getFormattedTime() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final day = now.day;
    final hour = now.hour;
    final minute = now.minute;
    return '$year년 $month월 $day일 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // 메시지를 보내는 함수
  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        String currentTime = _getFormattedTime();
        chatMessages.add(
            ChatMessage(message: _messageController.text, time: currentTime));
        _messageController.clear();
        _isTyping = false;
      });
    }
  }

  // 메시지 입력시 타이핑 상태에 따른 아이콘 변경
  void _onMessageChange(String text) {
    setState(() {
      _isTyping = text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userNickname), // 대화 상대의 닉네임
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              setState(() {
                isMenuOpen = !isMenuOpen; // 메뉴 버튼 클릭 시 사이드바 열고 닫기
              });
            },
          ),
        ],
        backgroundColor: Colors.deepPurple, // 앱바 배경색을 설정
        foregroundColor: Colors.white, // 앱바의 텍스트와 아이콘 색상 설정
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 채팅 메시지 영역
              Expanded(
                child: ListView.builder(
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    bool isUserMessage =
                        index % 2 == 0; // 임의로 사용자 메시지를 짝수 인덱스에 설정
                    final chatMessage = chatMessages[index];
                    return Align(
                      alignment: isUserMessage
                          ? Alignment.centerRight // 내 메시지는 오른쪽
                          : Alignment.centerLeft, // 상대방 메시지는 왼쪽
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isUserMessage)
                              CircleAvatar(
                                backgroundImage: NetworkImage(profileImageUrl),
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isUserMessage
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chatMessage.message,
                                      style: TextStyle(
                                        color: isUserMessage
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chatMessage.time,
                                      style: TextStyle(
                                        color: isUserMessage
                                            ? Colors.white
                                            : Colors.black.withOpacity(0.6),
                                        fontSize: 12,
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

              // 하단 바 영역
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onMessageChange,
                        onSubmitted: (_) {
                          _sendMessage(); // 엔터키를 눌러서 메시지 전송
                        },
                        decoration: const InputDecoration(
                          hintText: 'Enter your message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: _isTyping ? Colors.blue : Colors.grey,
                      ),
                      onPressed: _isTyping ? _sendMessage : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 어두운 오버레이 배경
          if (isMenuOpen)
            GestureDetector(
              onTap: () {
                // 사이드바 닫기
                setState(() {
                  isMenuOpen = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5), // 반투명한 어두운 배경
              ),
            ),
          // 사이드바 화면을 오른쪽에 표시
          if (isMenuOpen)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: _buildSideBar(),
            ),
        ],
      ),
    );
  }

  // 사이드바 화면 (Spotify 음악 리스트)
  Widget _buildSideBar() {
    return Container(
      width: 300,
      color: Colors.blueGrey,
      child: const Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Shared Music List',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
