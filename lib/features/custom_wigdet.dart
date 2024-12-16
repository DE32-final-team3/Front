import 'package:flutter/material.dart';

class CustomWigdet {
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부를 터치해도 닫히지 않도록 설정
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
