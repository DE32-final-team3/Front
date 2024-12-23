import 'package:flutter/material.dart';
// pages
import 'package:cinetalk/init_page/login.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/custom_widget.dart';

class FindPassword extends StatefulWidget {
  const FindPassword({super.key});

  @override
  _FindPasswordState createState() => _FindPasswordState();
}

class _FindPasswordState extends State<FindPassword> {
  final _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "이메일을 입력해주세요";
    }
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(pattern);
    if (!regExp.hasMatch(value)) {
      return '유효한 이메일 형식을 입력해주세요';
    }
    return null;
  }

  Future<void> _findPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    CustomWidget.showLoadingDialog(context);

    try {
      String email = _emailController.text;
      var statusCode = await UserApi.postParameters(
          "/user/password/reset", {"email": email});

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      if (statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("임시 비밀번호가 전송되었습니다."),
              content: const Text("이메일을 확인해주세요."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const Login()));
                  },
                  child: const Text("확인"),
                ),
              ],
            );
          },
        );
      } else if (statusCode == 404) {
        // 이메일 불일치 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("일치하는 이메일이 없습니다."),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // 기타 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("알 수 없는 에러가 발생했습니다. 다시 시도해주세요."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("네트워크 에러가 발생했습니다. 다시 시도해주세요."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _findPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // 버튼의 크기 설정
                ),
                child: const Text('비밀번호 찾기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
