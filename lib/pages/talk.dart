import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 사용자 ID 가져오기 위해 추가
// features
import 'package:cinetalk/features/api.dart'; // FastAPI 호출
import 'package:cinetalk/features/user_provider.dart'; // 사용자 정보 관리
import 'package:cinetalk/pages/chatroom.dart';

class Talk extends StatefulWidget {
  const Talk({super.key});

  @override
  _TalkState createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  List<Map<String, dynamic>> chatList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).id;

      final response = await UserApi.getParametersChat(
        '/api/chat_rooms/$userId/unread',
        '',
        '',
      );

      if (response?['status'] == 'success') {
        final fetchedChatRooms = response['data'] as List<dynamic>? ?? [];
        final updatedChatList = await Future.wait(
          fetchedChatRooms.map((room) async {
            final partnerId = room['partner_id'];
            final profileImageBytes = await _fetchProfileImage(partnerId);

            return {
              "profileImage": profileImageBytes,
              "nickname": room['partner_nickname'] ?? "Unknown",
              "lastMessage": room['last_message']?['text'] ?? "No messages yet",
              "timestamp": room['last_message']?['timestamp'],
              "user_id": partnerId,
              "unreadCount": room['unread_count'] ?? 0,
            };
          }).toList(),
        );

        updatedChatList.sort((a, b) =>
            (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

        setState(() {
          chatList = updatedChatList;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load chat rooms: ${response?['message']}');
      }
    } catch (e) {
      print("Error fetching chat rooms: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Uint8List> _fetchProfileImage(String partnerId) async {
    try {
      return await UserApi.getProfile(partnerId);
    } catch (e) {
      print("Error fetching profile image for $partnerId: $e");
      return Uint8List(0); // 기본 빈 값
    }
  }

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
              onPressed: () => Navigator.of(context).pop(),
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Talk"),
      ),
      body: chatList.isEmpty
          ? const Center(
              child: Text(
                '생성된 채팅방이 없습니다.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: chatList.length,
              itemBuilder: (context, index) {
                final chat = chatList[index];
                return GestureDetector(
                  onLongPress: () => showDeleteConfirmationDialog(index),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoom(
                          user1: Provider.of<UserProvider>(context, listen: false).id,
                          user2: chat['user_id'],
                          user2Nickname: chat['nickname'],
                        ),
                      ),
                    );

                    if (result == true) {
                      await _fetchChatRooms();
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
        subtitle: Text(lastMessage.isEmpty ? '새 메시지가 없습니다.' : lastMessage),
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