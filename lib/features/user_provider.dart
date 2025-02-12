import 'package:flutter/material.dart';
import 'dart:typed_data';

class UserProvider with ChangeNotifier {
  String _id = "";
  String _email = "";
  String _nickname = "";
  Uint8List? _profile;
  List<String> _following = [];
  List<int> _movieList = [];

  // Getter
  String get id => _id;
  String get email => _email;
  String get nickname => _nickname;
  Uint8List? get profile => _profile;
  List<String> get following => _following;
  List<int> get movieList => _movieList;

  // Setter
  void setUserId(String id) {
    _id = id;
    notifyListeners(); // 상태 변경 시 구독된 위젯에 알림
  }

  void setUserEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setUserNickname(String nickname) {
    _nickname = nickname;
    notifyListeners();
  }

  void setUserProfile(Uint8List? profile) {
    if (_profile != null) {
      // 기존 프로필 이미지 캐시 제거
      imageCache.evict(MemoryImage(_profile!));
    }
    _profile = profile;
    notifyListeners();
  }

  void setFollowingList(List<dynamic> following) {
    _following = List<String>.from(following);
    notifyListeners();
  }

  void follow(String id) {
    _following.add(id);
    notifyListeners();
  }

  void unfollow(String id) {
    _following.remove(id);
    notifyListeners();
  }

  void setMovieList(List<int> movieList) {
    _movieList = movieList;
    notifyListeners();
  }

  Future<void> clearUser() async {
    _id = "";
    _email = "";
    _nickname = "";
    _profile = null;
    _following = [];
    _movieList = [];
    notifyListeners();
  }
}
