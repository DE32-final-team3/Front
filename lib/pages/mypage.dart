import 'dart:typed_data';
import 'package:cinetalk/features/movie_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// pages
import 'package:cinetalk/pages/edit_profile.dart';
import 'package:cinetalk/main.dart';
// features
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/auth.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 전체 여백 설정
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
                  radius: 80,
                  backgroundImage: Provider.of<UserProvider>(context).profile !=
                          null
                      ? MemoryImage(Provider.of<UserProvider>(context).profile
                          as Uint8List)
                      : null,
                  child: Provider.of<UserProvider>(context).profile == null
                      ? const Icon(Icons.person, size: 80) // 기본 아이콘
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  Provider.of<UserProvider>(context)
                      .nickname, // provider 사용해서 data load
                  style: const TextStyle(
                    fontSize: 35, // 폰트 크기
                    fontWeight: FontWeight.bold, // 볼드체
                  ),
                ),
                const SizedBox(height: 5), // 닉네임과 이메일 사이 여백
                // 이메일
                Text(
                  Provider.of<UserProvider>(context).email,
                  style: const TextStyle(
                    fontSize: 18, // 폰트 크기
                    color: Colors.grey, // 이메일 텍스트 색상
                  ),
                ),
                const SizedBox(height: 20), // 이메일과 로그아웃 사이 여백
                ElevatedButton(
                  onPressed: () async {
                    await Provider.of<UserProvider>(context, listen: false)
                        .clearUser();
                    await Provider.of<MovieProvider>(context, listen: false)
                        .clearMovie();
                    Auth.clearToken();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MyApp()),
                    );
                  },
                  child: Text("Logout"),
                )
              ],
            ))
          ],
        ),
      ),
    );
  }
}
