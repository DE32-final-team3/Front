import 'dart:typed_data';
import 'package:cinetalk/features/custom_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/user_provider.dart';

class Cinemates extends StatefulWidget {
  const Cinemates({super.key});

  @override
  State<StatefulWidget> createState() => _CinamatesState();
}

class _CinamatesState extends State<Cinemates> {
  late Future<List<Map<String, dynamic>>> _similarUserFuture;

  @override
  void initState() {
    super.initState();
    _similarUserFuture = _loadSimilarUser(); // 데이터 로드 작업을 initState에서 처리
  }

  Future<List<Map<String, dynamic>>> _loadSimilarUser() async {
    String userId = Provider.of<UserProvider>(context, listen: false).id;
    // listen: false로 변경하여 rebuild 방지
    try {
      List<dynamic> users =
          await UserApi.getParameters("/similarity/details", "index", userId);

      // 프로필 이미지를 추가한 유저 리스트 생성
      List<Map<String, dynamic>> updatedUsers = await Future.wait(
        users.map((user) async {
          Uint8List? profileImage = await UserApi.getProfile(user['user_id']);
          return {
            "id": user['user_id'],
            "nickname": user['nickname'],
            "profileImage": profileImage,
          };
        }).toList(),
      );

      return updatedUsers;
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load similar users")),
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinemates')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _similarUserFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                "추천 유저를 불러오는 중 오류가 발생했습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "추천 유저가 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            final similarUser = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(4.0),
              itemCount: similarUser.length,
              itemBuilder: (context, index) {
                final user = similarUser[index];
                return GestureDetector(
                  onTap: () =>
                      CustomWidget.showUserProfile(user['id'], context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.grey[50], // Card의 배경색 설정
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            SizedBox.square(
                              dimension: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xFFD9EAFD),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: user['profileImage'] != null
                                  ? MemoryImage(user['profileImage']!)
                                  : const Icon(Icons.person) as ImageProvider,
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Text(
                                user['nickname'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            CustomWidget.chatButton(context, user),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
