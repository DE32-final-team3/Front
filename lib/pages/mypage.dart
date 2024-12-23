import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// pages
import 'package:cinetalk/pages/edit_profile.dart';
// features
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/api.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  List<Map<String, dynamic>> followingDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowingDetails();
  }

  Future<void> _fetchFollowingDetails() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Following ID 리스트
      List<String> followingIds = userProvider.following;

      // API 호출하여 프로필 및 정보 가져오기
      List<Map<String, dynamic>> userDetails = await Future.wait(
        followingIds.map((id) async {
          try {
            Uint8List profileImage = await UserApi.getProfile(id);
            Map<String, dynamic> followInfo = await UserApi.getFollowInfo(id);

            return {
              'id': id,
              'nickname': followInfo['nickname'] ?? 'Unknown',
              'profile': profileImage,
            };
          } catch (e) {
            print("Error fetching details for $id: $e");
            return {
              'id': id,
              'nickname': 'Unknown',
              'profile': null,
            };
          }
        }).toList(),
      );

      setState(() {
        followingDetails = userDetails;
      });
    } catch (e) {
      print("Error fetching following details: $e");
    }
  }

  Widget _buildFollowingList() {
    return followingDetails.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: followingDetails.length,
            itemBuilder: (context, index) {
              final user = followingDetails[index];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profile'] != null
                        ? MemoryImage(user['profile'])
                        : null,
                    child: user['profile'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user['nickname']),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: user['profile'] != null
                                    ? MemoryImage(user['profile'])
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                user['nickname'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Page')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // 전체 여백 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfile()),
                  );
                },
              ),
            ),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: userProvider.profile != null
                        ? MemoryImage(userProvider.profile as Uint8List)
                        : null,
                    child: userProvider.profile == null
                        ? const Icon(Icons.person, size: 60) // 기본 아이콘
                        : null,
                  ),
                  //const SizedBox(height: 1),
                  Text(
                    userProvider.nickname, // provider 사용해서 data load
                    style: const TextStyle(
                      fontSize: 30, // 폰트 크기
                      fontWeight: FontWeight.bold, // 볼드체
                    ),
                  ),
                  const SizedBox(height: 5), // 닉네임과 이메일 사이 여백
                  // 이메일
                  Text(
                    userProvider.email,
                    style: const TextStyle(
                      fontSize: 15, // 폰트 크기
                      color: Colors.grey, // 이메일 텍스트 색상
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Following',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildFollowingList()),
          ],
        ),
      ),
    );
  }
}
