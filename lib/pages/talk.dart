import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider를 사용하기 위해 추가
// features
import 'package:cinetalk/features/user_provider.dart'; // 사용자 정보 관리
import 'package:cinetalk/pages/chatroom.dart';
import 'package:cinetalk/features/chat_provider.dart'; // ChatProvider 추가

class Talk extends StatelessWidget {
  const Talk({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Talk"),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            chatProvider.setChatList(userId);
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return chatProvider.chatList.isEmpty
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
                          await chatProvider.setChatList(userId);
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
