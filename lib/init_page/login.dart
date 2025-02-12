import 'package:cinetalk/init_page/page_list.dart';
import 'package:flutter/material.dart';
// pages
import 'package:cinetalk/init_page/find_pw.dart';
import 'package:cinetalk/init_page/sign_up.dart';
// features
import 'package:cinetalk/features/api.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false; // 비밀번호 가시성 상태 관리

  // 이메일 유효성 검사
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return '유효한 이메일 주소를 입력해주세요';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (value.length < 8 || value.length > 16) {
      return '비밀번호는 8자 이상 16자 이하이어야 합니다';
    }

    return null;
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text;
      final password = _passwordController.text;

      try {
        var response = await UserApi.login(email, password);
        if (response) {
          await UserApi.userInfo(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PageList()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("이메일 또는 비밀번호가 일치하지 않습니다.")),
          );
          _passwordController.clear();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("네트워크 에러가 발생했습니다. 다시 시도해주세요."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Connect the form with the key
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/logo.png', // 로고 파일 경로
                height: 200, // 원하는 높이
                fit: BoxFit.contain, // 이미지 비율 유지
              ),
              const SizedBox(height: 50.0),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail, // Add the validator for email
                  onFieldSubmitted: (_) => _login()), // 엔터 키가 눌렸을 때 로그인 시도
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible, // 비밀번호 숨김/표시 토글
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible; // 비밀번호 가시성 토글
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => _login(), // 엔터 키가 눌렸을 때 로그인 시도
              ),
              const SizedBox(height: 16.0),
              // 로그인 버튼
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // 버튼의 크기 설정
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindPassword(),
                        ),
                      );
                    },
                    child: const Text("비밀번호 찾기"),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUp()),
                      );
                    },
                    child: const Text("회원가입"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
