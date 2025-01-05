import 'dart:typed_data';
import 'package:cinetalk/features/custom_widget.dart';
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

  Future<List<Map<String, dynamic>>> fetchUserDetails(
      List<String> followingIds) async {
    try {
      // API 호출하여 프로필 및 정보 가져오기
      List<Map<String, dynamic>> userDetails = await Future.wait(
        followingIds.map((id) async {
          try {
            Uint8List? profileImage =
                await UserApi.getProfile(id); // Fetch profile image
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
      return userDetails;
    } catch (e) {
      print("Error fetching following details: $e");
      return [];
    }
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
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.settings),
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
                  Text(
                    userProvider.nickname, // provider 사용해서 data load
                    style: const TextStyle(
                      fontSize: 30, // 폰트 크기
                      fontWeight: FontWeight.bold, // 볼드체
                    ),
                  ),
                  const SizedBox(height: 5), // 닉네임과 이메일 사이 여백
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
            Selector<UserProvider, List<String>>(
                selector: (context, provider) => provider.following,
                builder: (context, followingList, child) {
                  return Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchUserDetails(
                          Provider.of<UserProvider>(context).following),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(
                              child: Text("Error loading following details"));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "팔로우한 유저가 없습니다.",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          );
                        } else {
                          List<Map<String, dynamic>> followingDetails =
                              snapshot.data!;
                          return ListView.separated(
                            itemCount: followingDetails.length,
                            itemBuilder: (context, index) {
                              var user = followingDetails[index];

                              return GestureDetector(
                                onTap: () => CustomWidget.showUserProfile(
                                    user['id'], context),
                                child: Card(
                                  color: Color.fromARGB(255, 163, 206, 254),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                        horizontal: 20.0), // Card 내부 공백 설정
                                    child: Row(children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: user['profile'] != null
                                            ? MemoryImage(user['profile'])
                                            : null,
                                        child: user['profile'] == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          user['nickname'], // 닉네임
                                          style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16.0),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      CustomWidget.chatButton(context, user)
                                    ]),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 4.0); // 아이템 간 간격 설정
                            },
                          );
                        }
                      },
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
