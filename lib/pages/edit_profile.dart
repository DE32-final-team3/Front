import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
// pages
import 'package:cinetalk/main.dart';
// features
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/movie_provider.dart';
import 'package:cinetalk/features/auth.dart';
import 'package:cinetalk/features/api.dart';

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

  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nicknameController.text =
        Provider.of<UserProvider>(context, listen: false).nickname;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // 최대 가로 크기
      maxHeight: 800, // 최대 세로 크기
      imageQuality: 80, // 이미지 품질 (0~100, 100이 최상)
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      try {
        // setProfile 함수 호출 및 프로필 이미지 업데이트
        String userId = context.read<UserProvider>().id;
        Uint8List imageBytes =
            await UserApi.setProfile(userId, imageFile, context);

        Provider.of<UserProvider>(context, listen: false)
            .setUserProfile(imageBytes);
      } catch (e) {
        // 오류 처리
        print('이미지 업로드 실패: $e');
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 서버에 비동기 요청
      var res = await UserApi.update("", "password", _passwordController.text);
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
    var statusCode = await UserApi.postParameters(
        "/user/check/nickname", "nickname", nickname);
    if (statusCode == 200) {
      var res = await UserApi.update("", "nickname", nickname);

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
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Provider.of<UserProvider>(context, listen: false)
                        .clearUser();
                    await Provider.of<MovieProvider>(context, listen: false)
                        .clearMovie();
                    await Auth.clearToken();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => MyApp()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
            //const SizedBox(height: 10),
            // 프로필 사진과 편집 버튼을 가운데 정렬
            Center(
              child: Column(
                children: [
                  // Consumer를 사용하여 profile 상태 변경 시 이미지 자동 갱신
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return CircleAvatar(
                        radius: 80,
                        backgroundImage: userProvider.profile != null
                            ? MemoryImage(userProvider.profile as Uint8List)
                            : null,
                        child: userProvider.profile == null
                            ? const Icon(Icons.person, size: 80)
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 10), // 프로필 사진과 버튼 사이 여백
                  ElevatedButton(
                    onPressed: _pickImage,
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
                      onFieldSubmitted: (_) => _validateNickname()),
                ),
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
                    focusNode: _passwordFocusNode,
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
                      // Enter 키를 누르면 "Confirm Password"로 이동
                      FocusScope.of(context)
                          .requestFocus(_confirmPasswordFocusNode);
                    },
                  ),
                  const SizedBox(height: 10),
                  // 비밀번호 확인 입력란
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    focusNode: _confirmPasswordFocusNode,
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
                    onFieldSubmitted: (_) => _updatePassword(),
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
