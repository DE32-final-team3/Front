import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 사용자 ID 가져오기 위해 추가
import 'package:cinetalk/features/api.dart'; // FastAPI 호출
import 'package:cinetalk/features/user_provider.dart'; // 사용자 정보 관리
import 'package:cinetalk/pages/chatroom.dart';

class Talk extends StatefulWidget {
  const Talk({super.key});

  @override
  _TalkState createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  List<Map<String, dynamic>> chatList = []; // 채팅방 목록
  bool isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _fetchChatRooms(); // 채팅방 목록 가져오기
  }

  Future<void> _fetchChatRooms() async {
    try {
      // 현재 사용자의 ID 가져오기
      String userId = Provider.of<UserProvider>(context, listen: false).id;

      // FastAPI 호출
      var response = await UserApi.getParameters(
        '/api/chat_rooms/$userId', // API 경로
        '', // 쿼리 파라미터 없음
        '', // 빈 값 전달
      );

      if (response['status'] == 'success') {
        var fetchedChatRooms = response['data'];

        // chatList 업데이트
        setState(() {
          chatList = (fetchedChatRooms as List<dynamic>).map((room) {
            return {
              "profileImage": "", // 프로필 이미지는 없으므로 기본값
              "nickname": room['partner_nickname'] ?? "Unknown", // 상대방 닉네임
              "lastMessage": "최근 메시지가 없습니다.", // 마지막 메시지
              "user_id": room['partner_id'], // 상대방 ID
              "unreadCount": 0, // 미확인 메시지
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load chat rooms');
      }
    } catch (e) {
      print("Error fetching chat rooms: $e");
      setState(() {
        isLoading = false; // 로딩 중단
      });
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // 로딩 중
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
          : Padding(
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
                        MaterialPageRoute(
                          builder: (context) => ChatRoom(
                            user1: Provider.of<UserProvider>(context,
                                    listen: false)
                                .id, // 현재 사용자 ID
                            user2: chatList[index]['user_id'], // 상대방 사용자 ID
                            user2Nickname: chatList[index]
                                ['nickname'], // 상대방 닉네임
                          ),
                        ),
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
