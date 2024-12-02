import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
// features
import 'package:cinetalk/features/user_provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // 임시 데이터
  String nickname = 'Name'; // 닉네임
  String password = 'password123'; // 비밀번호
  String confirmPassword = 'password123'; // 비밀번호 확인

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  String? _validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return '닉네임을 입력해주세요';
    }
    return null;
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
    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
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
                    radius: 70, // 원형의 반지름
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

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // 닉네임 입력란
                  TextFormField(
                    initialValue: nickname,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      border: OutlineInputBorder(),
                      hintText: '새 닉네임을 입력하세요',
                    ),
                    validator: _validateNickname,
                    onSaved: (value) {
                      if (value != null) {
                        nickname = value;
                      }
                    },
                  ),
                  const SizedBox(height: 10), // 닉네임과 비밀번호 입력란 사이 여백

                  // 비밀번호 입력란
                  TextFormField(
                    initialValue: password,
                    obscureText: true, // 비밀번호 숨기기
                    decoration: InputDecoration(
                        labelText: '비밀번호',
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
                        hintText: password),
                    validator: _validatePassword,
                    onSaved: (value) {
                      if (value != null) {
                        password = value;
                      }
                    },
                  ),
                  const SizedBox(height: 10), // 비밀번호와 비밀번호 확인 입력란 사이 여백

                  // 비밀번호 확인 입력란
                  TextFormField(
                    initialValue: confirmPassword,
                    obscureText: true, // 비밀번호 숨기기
                    decoration: InputDecoration(
                        labelText: '비밀번호 확인',
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
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            });
                          },
                        ),
                        hintText: confirmPassword),
                    validator: _validateConfirmPassword,
                    onSaved: (value) {
                      if (value != null) {
                        confirmPassword = value;
                      }
                    },
                  ),
                  const SizedBox(height: 10), // 비밀번호 확인과 저장 버튼 사이 여백

                  // 저장 버튼
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('수정이 완료되었습니다.')),
                          );
                        }
                      },
                      child: const Text('Save'),
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
