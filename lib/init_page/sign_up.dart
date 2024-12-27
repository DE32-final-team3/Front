import 'package:flutter/material.dart';
// pages
import 'package:cinetalk/init_page/login.dart';
// features
import 'package:cinetalk/features/api.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  bool _isEmailChecked = false;
  bool _isNicknameChecked = false;

  final _formKey = GlobalKey<FormState>();

  void _validateEmail() async {
    final email = _emailController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('이메일을 입력해주세요.'),
            duration: Duration(milliseconds: 500)),
      );
      return;
    }

    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(pattern);
    if (!regExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('유효한 이메일 형식을 입력해주세요.'),
            duration: Duration(milliseconds: 500)),
      );
      return;
    }

    // API 호출 코드
    var statusCode =
        await UserApi.postParameters("/user/check/email", {"email": email});
    if (statusCode == 200) {
      setState(() {
        _isEmailChecked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('사용 가능한 이메일입니다'),
            duration: Duration(milliseconds: 500)),
      );
    } else {
      setState(() {
        _isEmailChecked = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("이미 사용 중인 이메일입니다."),
            duration: Duration(milliseconds: 500)),
      );
    }
    return;
  }

  void _validateNickname() async {
    final nickname = _nicknameController.text;

    if (nickname.isEmpty || nickname.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('닉네임을 입력해주세요'),
            duration: Duration(milliseconds: 500)),
      );
      return;
    }

    // API 호출 코드
    var statusCode = await UserApi.postParameters(
        "user/check/nickname", {"nickname": nickname});
    if (statusCode == 200) {
      setState(() {
        _isNicknameChecked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('사용 가능한 닉네임입니다'),
            duration: Duration(milliseconds: 500)),
      );
    } else {
      setState(() {
        _isNicknameChecked = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("이미 사용 중인 닉네임입니다."),
            duration: Duration(milliseconds: 500)),
      );
    }
    return;
  }

  // 비밀번호 유효성 검사
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (value.length < 8 || value.length > 16) {
      return '비밀번호는 8자 이상 16자 이하이어야 합니다';
    }

    // 정규식으로 각 조건 확인
    bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value); // 영문자 포함 여부
    bool hasDigit = RegExp(r'\d').hasMatch(value); // 숫자 포함 여부
    bool hasSpecial =
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value); // 특수문자 포함 여부

    // 최소 2가지 조건 만족 여부
    int conditionsMet =
        (hasLetter ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSpecial ? 1 : 0);
    if (conditionsMet < 2) {
      return '비밀번호는 영문, 숫자, 특수문자 중 최소 2가지를 포함해야 합니다';
    }

    return null; // 검증 통과
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다.';
    }
    return null;
  }

  // 회원가입 처리 함수
  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final nickname = _nicknameController.text;
      final password = _passwordController.text;

      Map<String, dynamic> params = {
        'email': email,
        'nickname': nickname,
        'profile': '',
        'password': password
      };

      var statusCode = await UserApi.postBody("/user/create", params);
      if (statusCode == 200) {
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => Dialog.fullscreen(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "회원가입 완료!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "$nickname님 회원이 되신 것을 환영합니다.",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const Login()));
                  },
                  child: const Text(
                    "로그인하러 가기",
                    selectionColor: Colors.red,
                  ),
                )
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("회원가입 실패"), duration: Duration(milliseconds: 500)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 이메일 입력
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isEmailChecked = false;
                      });
                    },
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (_) => _validateEmail(),
                  )),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _validateEmail();
                    }, //_checkEmail,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('중복 체크'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isNicknameChecked = false;
                        });
                      },
                      onFieldSubmitted: (_) => _validateNickname(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _validateNickname();
                    }, //  _checkNickname,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("중복 체크"),
                  )
                ],
              ),

              const SizedBox(height: 16),
              // 비밀번호 입력
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: !_passwordVisible,
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
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) {
                  FocusScope.of(context)
                      .requestFocus(_confirmPasswordFocusNode);
                },
              ),
              const SizedBox(height: 16),
              // 비밀번호 확인 입력
              TextFormField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.check),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_) {
                  _isEmailChecked && _isNicknameChecked ? _signUp : null;
                },
              ),
              const SizedBox(height: 16),
              // 회원가입 버튼
              ElevatedButton(
                onPressed: // 이메일, 닉네임 중복 체크 완료 후 회원가입 버튼 활성화
                    _isEmailChecked && _isNicknameChecked ? _signUp : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // 버튼의 크기 설정
                ),
                child: const Text('회원가입하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
