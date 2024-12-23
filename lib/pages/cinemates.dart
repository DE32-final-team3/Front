import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// pages
import 'package:cinetalk/pages/chatroom.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/user_provider.dart';

class Cinemates extends StatefulWidget {
  const Cinemates({super.key});

  @override
  State<StatefulWidget> createState() => _CinamatesState();
}

class _CinamatesState extends State<Cinemates> {
  List<Map<String, dynamic>> similarUser = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSimilarUser(); // didChangeDependencies()에서 호출
  }

  Future<void> _loadSimilarUser() async {
    String userId = Provider.of<UserProvider>(context).id;
    try {
      List<dynamic> users =
          await UserApi.getParameters("/similarity/details", "index", userId);

      // 프로필 이미지 추가 로직
      List<Map<String, dynamic>> updatedUsers = await Future.wait(
        users.map((user) async {
          Uint8List? profileImage = await _fetchProfileImage(user['user_id']);
          return {
            "user_id": user['user_id'],
            "nickname": user['nickname'],
            "profileImage": profileImage,
          };
        }).toList(),
      );

      setState(() {
        similarUser = updatedUsers;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<Uint8List?> _fetchProfileImage(String userId) async {
    try {
      return await UserApi.getProfile(userId);
    } catch (e) {
      print("Error fetching profile image for $userId: $e");
      return null; // 기본 빈 값
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinemates')),
      body: similarUser.isEmpty
          ? const Center(
              child: CircularProgressIndicator(), // 로딩 중 상태
            )
          : ListView.builder(
              itemCount: similarUser.length,
              itemBuilder: (context, index) {
                final user = similarUser[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0), // 카드 간격
                  child: Card(
                    elevation: 4, // 그림자 효과
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 둥근 모서리
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // 카드 내부 여백
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: user['profileImage'] != null
                                ? MemoryImage(user['profileImage']!)
                                : const AssetImage('assets/default_profile.png')
                                    as ImageProvider,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(width: 10), // 프로필 사진과 텍스트 간격
                          Expanded(
                            child: Text(
                              user['nickname'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatRoom(
                                    user1: Provider.of<UserProvider>(context,
                                            listen: false)
                                        .id, // 현재 사용자 id
                                    user2: user['user_id'], // 클릭된 사용자 id
                                    user2Nickname: user['nickname'],
                                  ),
                                ),
                              );
                            },
                            child: const Text('채팅하기'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
