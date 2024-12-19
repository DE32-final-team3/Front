import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/user_provider.dart';
// chatroom.dart 가져오기
import 'package:cinetalk/pages/chatroom.dart';

class Cinemates extends StatefulWidget {
  const Cinemates({super.key});

  @override
  State<StatefulWidget> createState() => _CinamatesState();
}

class _CinamatesState extends State<Cinemates> {
  List<dynamic>? similarUser;

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

      setState(() {
        similarUser = users;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinemates')),
      body: similarUser == null
          ? const Center(
              child: CircularProgressIndicator(), // 로딩 중 상태
            )
          : similarUser!.isEmpty
              ? const Center(
                  child: Text(
                    'No similar users found',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: similarUser!.length,
                  itemBuilder: (context, index) {
                    final user = similarUser![index];
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
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person), // 기본 프로필 이미지
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
                                        user1: Provider.of<UserProvider>(
                                                context,
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
