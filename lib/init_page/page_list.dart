import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as custom_badge;
import 'package:provider/provider.dart';
// pages
import 'package:cinetalk/pages/mypage.dart';
import 'package:cinetalk/pages/curator.dart';
import 'package:cinetalk/pages/talk.dart';
import 'package:cinetalk/pages/cinemates.dart';
// features
import 'package:cinetalk/features/chat_provider.dart';

class PageList extends StatelessWidget {
  const PageList({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Pages(),
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFD9EAFD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent, // AppBar 배경 색상
          foregroundColor: Colors.white, // AppBar 텍스트/아이콘 색상
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 30, 84, 179), // 버튼 색상
            foregroundColor: Colors.white, // 버튼 텍스트 색상
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue, // TextButton 텍스트 색상
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue, // FloatingActionButton 색상
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue, // 선택된 아이템 색상
          unselectedItemColor: Color(0xFF9AA6B2), // 선택되지 않은 아이템 색상
        ),
      ),
    );
  }
}

class Pages extends StatefulWidget {
  @override
  _PageListState createState() => _PageListState();
}

class _PageListState extends State<Pages> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [MyPage(), Curator(), Talk(), Cinemates()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // 현재 선택된 페이지를 보여줌
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons
                .account_box_rounded), //FaIcon(FontAwesomeIcons.circleUser),
            label: 'My Page',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_movies),
            label: 'Curator',
          ),
          BottomNavigationBarItem(
            icon: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                int unreadCount =
                    chatProvider.totalUnreadCount; // unread count 가져오기

                if (unreadCount > 0) {
                  return custom_badge.Badge(
                    badgeContent: Text(
                      unreadCount.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                    child: Icon(Icons.chat_rounded),
                  );
                } else {
                  return Icon(Icons.chat_rounded);
                }
              },
            ),
            label: 'Talk',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Cinemates',
          ),
        ],
      ),
    );
  }
}
