import 'package:flutter/material.dart';
import 'dart:typed_data';

class UserProvider with ChangeNotifier {
  String _id = "";
  String _email = "";
  String _nickname = "";
  Uint8List? _profile;

  // Getter
  String get id => _id;
  String get email => _email;
  String get nickname => _nickname;
  Uint8List? get profile => _profile;

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
    _profile = profile;
    notifyListeners();
  }
}
