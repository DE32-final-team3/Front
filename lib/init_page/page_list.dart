import 'package:flutter/material.dart';
// pages
import 'package:cinetalk/pages/mypage.dart';
import 'package:cinetalk/pages/curation.dart';
import 'package:cinetalk/pages/talk.dart';
import 'package:cinetalk/pages/cinema.dart';
import 'package:cinetalk/pages/follow.dart';

class PageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Pages());
  }
}

class Pages extends StatefulWidget {
  @override
  _PageListState createState() => _PageListState();
}

class _PageListState extends State<Pages> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MyPage(),
    Curation(),
    Talk(),
    Cinema(),
    Follow()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎞️CineTalk')),
      body: _pages[_currentIndex], // 현재 선택된 페이지를 보여줌
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 7, 19, 254),
        unselectedItemColor: const Color.fromARGB(255, 106, 106, 106),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box_outlined),
            label: 'My Page',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Curation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Talk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom_outlined),
            label: 'Cinema',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outlined),
            label: 'Follow',
          ),
        ],
      ),
    );
  }
}
