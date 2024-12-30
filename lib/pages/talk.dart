import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider를 사용하기 위해 추가
// features
import 'package:cinetalk/features/user_provider.dart'; // 사용자 정보 관리
import 'package:cinetalk/pages/chatroom.dart';
import 'package:cinetalk/features/chat_provider.dart'; // ChatProvider 추가

class Talk extends StatelessWidget {
  const Talk({super.key});

  Future<void> showDeleteConfirmationDialog(
      BuildContext context, int index) async {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                context.read<ChatProvider>().chatList.removeAt(index);
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
    final chatProvider = Provider.of<ChatProvider>(context);
    final userId = Provider.of<UserProvider>(context, listen: false).id;

    if (chatProvider.isLoading) {
      chatProvider.fetchChatRooms(userId);
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Talk"),
      ),
      body: chatProvider.chatList.isEmpty
          ? const Center(
              child: Text(
                '생성된 채팅방이 없습니다.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: chatProvider.chatList.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chatList[index];
                return GestureDetector(
                  onLongPress: () =>
                      showDeleteConfirmationDialog(context, index),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoom(
                          user1: userId,
                          user2: chat['user_id'],
                          user2Nickname: chat['nickname'],
                        ),
                      ),
                    );

                    if (result == true) {
                      await chatProvider.fetchChatRooms(userId);
                    }
                  },
                  child: ChatBox(
                    profileImage: chat['profileImage'],
                    nickname: chat['nickname'],
                    lastMessage: chat['lastMessage'],
                    unreadCount: chat['unreadCount'],
                  ),
                );
              },
            ),
    );
  }
}

class ChatBox extends StatelessWidget {
  final Uint8List profileImage;
  final String nickname;
  final String lastMessage;
  final int unreadCount;

  const ChatBox({
    required this.profileImage,
    required this.nickname,
    required this.lastMessage,
    required this.unreadCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: profileImage.isNotEmpty
              ? MemoryImage(profileImage)
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        title: Text(
          nickname,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle:
            Text(lastMessage.contains('poster_path') ? '[영화 공유]' : lastMessage),
        trailing: unreadCount > 0
            ? CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : null,
      ),
    );
  }
}
