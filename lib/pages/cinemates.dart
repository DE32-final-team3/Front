import 'dart:typed_data';
import 'package:cinetalk/features/custom_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// pages
import 'package:cinetalk/pages/chatroom.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load similar users")),
      );
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

  Future<void> _showUserMovies(String userId) async {
    try {
      // 유저의 영화 리스트와 닉네임 가져오기
      final response =
          await UserApi.getParameters("/user/follow/info", "follow_id", userId);

      if (response == null || !response.containsKey('movie_list') || !response.containsKey('nickname')) {
        throw Exception("Failed to fetch user info.");
      }

      final movieIds = response['movie_list'] as List<dynamic>;
      final nickname = response['nickname'] as String;

      if (movieIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No movies found for this user")),
        );
        return;
      }

      // 영화 상세 정보 가져오기
      final movies = await MovieApi.fetchMovies(movieIds.cast<int>());

      if (movies == null || movies.isEmpty) {
        throw Exception("Failed to fetch movie details.");
      }

      // CustomWidget을 사용해 다이얼로그 표시
      CustomWidget.showMovieListDialog(context, nickname, movies);
    } catch (e) {
      print("Error fetching movies for user $userId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch movies for user $userId")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinemates')),
      body: similarUser.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: similarUser.length,
              itemBuilder: (context, index) {
                final user = similarUser[index];
                return GestureDetector(
                  onTap: () => _showUserMovies(user['user_id']),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: user['profileImage'] != null
                                  ? MemoryImage(user['profileImage']!)
                                  : const AssetImage('assets/default_profile.png')
                                      as ImageProvider,
                              backgroundColor: Colors.grey[300],
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
                                      user1: Provider.of<UserProvider>(context, listen: false).id,
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
