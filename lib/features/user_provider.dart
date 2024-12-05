import 'package:flutter/material.dart';
import 'dart:io';

class UserProvider with ChangeNotifier {
  String _id = "";
  String _email = "";
  String _nickname = "";
  File? _profile;

  // Getter
  String get id => _id;
  String get email => _email;
  String get nickname => _nickname;
  File? get profile => _profile;

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

  void setUserProfile(File? profile) {
    _profile = profile;
    notifyListeners();
  }
}
