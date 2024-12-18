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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 닉네임 텍스트
                              Text(
                                user['nickname'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // 우측 버튼
                              ElevatedButton(
                                onPressed: () {
                                  // 버튼 클릭 시 동작
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
