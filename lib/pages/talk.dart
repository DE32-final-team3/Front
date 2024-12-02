import 'package:flutter/material.dart';
// page
import 'package:cinetalk/pages/chatroom.dart';

class Talk extends StatefulWidget {
  const Talk({super.key});

  @override
  _TalkState createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  List<Map<String, dynamic>> chatList = List.generate(
      5,
      (index) => {
            'profileImage': '',
            'nickname': 'User $index',
            'lastMessage': '최근 메시지',
            'unreadCount': index + 1, // 미확인 메시지 수
          });

  void deleteChat(int index) {
    setState(() {
      chatList.removeAt(index);
    });
  }

  Future<void> showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('채팅방을 나가시겠습니까?'),
          content: const Text('이 채팅방을 삭제하면 복구할 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                deleteChat(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Talk"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: chatList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () {
                showDeleteConfirmationDialog(index);
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatRoom()),
                );
              },
              child: ChatBox(
                profileImageUrl: chatList[index]['profileImage']!,
                nickname: chatList[index]['nickname']!,
                lastMessage: chatList[index]['lastMessage']!,
                unreadCount: chatList[index]['unreadCount'],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatBox extends StatefulWidget {
  final String profileImageUrl;
  final String nickname;
  String lastMessage;
  final int unreadCount;

  ChatBox({
    required this.profileImageUrl,
    required this.nickname,
    required this.lastMessage,
    required this.unreadCount,
    super.key,
  });

  @override
  _ChatBoxState createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  void updateLastMessage(String newMessage) {
    setState(() {
      widget.lastMessage = newMessage; // 최근 메시지 업데이트
    });
  }

  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: widget.profileImageUrl.isNotEmpty
              ? NetworkImage(widget.profileImageUrl)
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        title: Text(widget.nickname),
        subtitle: Text(widget.lastMessage),
        trailing: widget.unreadCount > 0
            ? CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Text(
                  '${widget.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : null,
      ),
    );
  }
}
