import 'package:flutter/material.dart';
// page
import 'package:cinetalk/pages/chatroom.dart';
import 'package:cinetalk/pages/cinemates.dart';

class Talk extends StatefulWidget {
  const Talk({super.key});

  @override
  _TalkState createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  // 채팅방 목록
  List<Map<String, dynamic>> chatList = [];

  // 새로운 채팅방 추가
  void addChatRoom(String userId, String nickname) {
    // 중복 방지
    if (!chatList.any((room) => room['user_id'] == userId)) {
      setState(() {
        chatList.add({
          'user_id': userId, // 고유 ID
          'profileImage': '', // 기본 이미지
          'nickname': nickname, // 닉네임
          'lastMessage': '', // 마지막 메시지
          'unreadCount': 0, // 미확인 메시지 수
        });
      });
    }
  }

  void updateChatRoom(String userId, String lastMessage) {
    setState(() {
      for (var room in chatList) {
        if (room['user_id'] == userId) {
          room['lastMessage'] = lastMessage;
          room['unreadCount'] += 1; // 새로운 메시지 도착 시 카운트 증가
          break; // 더 이상의 반복을 방지
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Talk"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 예시: Cinemates 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Cinemates(), // Cinemates 페이지 연결
                ),
              ).then((result) {
                if (result != null && result is Map<String, String>) {
                  // Cinemates에서 선택된 사용자 정보 추가
                  addChatRoom(result['user_id']!, result['nickname']!);
                }
              });
            },
          ),
        ],
      ),
      body: chatList.isEmpty
          ? const Center(
              child: Text(
                '생성된 채팅방이 없습니다.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: chatList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onLongPress: () {
                      // 삭제 확인 팝업
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('채팅방을 나가시겠습니까?'),
                            content:
                                const Text('이 채팅방을 삭제하면 복구할 수 없습니다.'),
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
                                  setState(() {
                                    chatList.removeAt(index);
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onTap: () {
                      // 기존 채팅방으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoom(
                            user1: "MyUserId", // 현재 사용자 ID
                            user2: chatList[index]['user_id'], // 상대방 사용자 ID
                            user2Nickname: chatList[index]['nickname'], // 상대방 닉네임
                          ),
                        ),
                      ).then((lastMessage) {
                        if (lastMessage != null && lastMessage is String) {
                          updateChatRoom(chatList[index]['user_id'], lastMessage);
                        }
                      });
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

class ChatBox extends StatelessWidget {
  final String profileImageUrl;
  final String nickname;
  final String lastMessage;
  final int unreadCount;

  const ChatBox({
    required this.profileImageUrl,
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
          backgroundImage: profileImageUrl.isNotEmpty
              ? NetworkImage(profileImageUrl)
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        title: Text(nickname),
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
