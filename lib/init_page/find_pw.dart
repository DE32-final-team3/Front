import 'package:flutter/material.dart';

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

  void _findPassword() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String email = _emailController.text;

    // 이메일이 존재하는지 확인
    // if (!_existingEmails.contains(email)) {
    //   ScaffoldMessenger.of(context)
    //       .showSnackBar(const SnackBar(content: Text('이 이메일로 가입된 계정이 없습니다')));
    //   return;
    // }

    // 이메일로 비밀번호 전송 (여기서는 비밀번호를 보여주는 방식으로 처리)
    // String password = _userPasswords[email]!;
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('비밀번호가 이메일로 전송되었습니다: $password')),
    // );
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
