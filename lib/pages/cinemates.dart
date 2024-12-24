import 'dart:typed_data';
import 'package:cinetalk/features/custom_widget.dart';
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
    _loadSimilarUser(); // Fetch users when dependencies change
  }

  Future<void> _loadSimilarUser() async {
    String userId = Provider.of<UserProvider>(context).id;
    try {
      List<dynamic> users =
          await UserApi.getParameters("/similarity/details", "index", userId);

      // Add profile images to the user list
      List<Map<String, dynamic>> updatedUsers = await Future.wait(
        users.map((user) async {
          Uint8List? profileImage = await UserApi.getProfile(user['user_id']);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load similar users")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinemates')),
      body: similarUser.isEmpty
          ? const Center(
              child: Text(
                "추천 유저가 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: similarUser.length,
              itemBuilder: (context, index) {
                final user = similarUser[index];

                // 조건부로 배경색 설정
                Color? backgroundColor;
                if (index == 0) {
                  backgroundColor =
                      const Color.fromARGB(255, 197, 179, 88); // 금색
                } else if (index == 1) {
                  backgroundColor = const Color.fromARGB(255, 192, 192, 192);
                } else if (index == 2) {
                  backgroundColor =
                      const Color.fromARGB(255, 205, 127, 50); // 동색
                } else {
                  backgroundColor = Colors.grey[300]; // 기본 흰색
                }

                return GestureDetector(
                  onTap: () =>
                      CustomWidget.showUserProfile(user['user_id'], context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: backgroundColor, // Card의 배경색 설정
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: user['profileImage'] != null
                                  ? MemoryImage(user['profileImage']!)
                                  : const AssetImage(
                                          'assets/default_profile.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 10),
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
                                          .id,
                                      user2: user['user_id'],
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
                  ),
                );
              },
            ),
    );
  }
}
