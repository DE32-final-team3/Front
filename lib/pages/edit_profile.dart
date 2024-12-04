import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:io';
// features
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/auth.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nicknameController.text =
        Provider.of<UserProvider>(context, listen: false).nickname;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<int> _api_p(String param, String value) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.http(
      serverIP, // 호스트 주소
      '/api/user/$param', // 경로
      {param: value},
    );

    var response = await http.post(url);
    return response.statusCode;
  }

  Future<int> update(String param, String value) async {
    String? serverIP = dotenv.env['SERVER_IP']!;
    String? token = await Auth.getToken();

    var url = Uri.http(serverIP, '/api/user/update');

    var response = await http.put(
      url,
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({param: value}),
    );
    return response.statusCode;
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 서버에 비동기 요청
      var res = await update("password", _passwordController.text);
      if (res == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호가 변경되었습니다.'),
            duration: Duration(milliseconds: 500),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호 변경 실패. 다시 시도해주세요.'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  void _validateNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('닉네임을 입력해주세요'),
            duration: Duration(milliseconds: 500)),
      );
      return;
    }

    // nickname 변경
    var statusCode = await _api_p("nickname", nickname);
    if (statusCode == 200) {
      var res = await update("nickname", nickname);

      if (res == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('닉네임이 변경되었습니다.'),
              duration: Duration(milliseconds: 500)),
        );
        Provider.of<UserProvider>(context, listen: false)
            .setUserNickname(nickname);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('닉네임 변경 실패'),
              duration: Duration(milliseconds: 500)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("이미 사용 중인 닉네임입니다."),
            duration: Duration(milliseconds: 500)),
      );
    }
    return;
  }

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

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 다시 입력하세요';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  // 메모리 관리를 위해 controller 정리
  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이메일
            Center(
              child: Text(
                Provider.of<UserProvider>(context).email,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 20), // 이메일과 프로필 사진 사이 여백

            // 프로필 사진과 편집 버튼을 가운데 정렬
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 80, // 원형의 반지름
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                  ),
                  const SizedBox(height: 10), // 프로필 사진과 버튼 사이 여백
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text('프로필 사진 변경'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // 프로필 사진과 입력 필드 사이 여백
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
                )),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () {
                      _validateNickname();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('닉네임 변경')),
              ],
            ),
            // 닉네임 입력란
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // 비밀번호 입력란
                  TextFormField(
                    controller: _passwordController,
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
                  ),
                  const SizedBox(height: 10),
                  // 비밀번호 확인 입력란
                  TextFormField(
                    controller: _confirmPasswordController,
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
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updatePassword,
                      child: const Text('비밀번호 변경'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
